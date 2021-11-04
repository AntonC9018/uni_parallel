// DATA processed by the processes
static if (0)
{
    enum DataWidth = 6;
    immutable AData = [
        4,  0,  0,  0,  0,  0,
        3,  3,  0,  0,  0,  0,
        2,  2,  2,  0,  0,  0,
        1,  1,  1,  1,  0,  0,
        0,  0,  0,  0,  0,  0,
        -1, -1, -1, -1, -1, -1,
        // -1, -1, -1, -1, -1, -1,
    ];
    immutable BData = [
        0,  2,  1,  0, -1, -2,
        0,  0,  1,  0, -1, -2,
        0,  0,  0,  0, -1, -2,
        0,  0,  0,  0, -1, -2,
        0,  0,  0,  0,  0, -2,
        0,  0,  0,  0,  0,  0,
        // -1, -1, -1, -1, -1, -1,
    ];
}
else static if (1)
{
    enum DataWidth = 3;
    immutable AData = [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ];
    immutable BData = [ 2, 2, 2, 2, 2, 2, 2, 2, 2 ];
}

static assert(AData.length == BData.length);

int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.range;
    import std.algorithm;
    import matrix;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    int offsetForProcess(int processIndex, int vectorCount)
    {
        return processIndex * vectorCount / info.size;
    }

    // 1. Distribute rows
    // 2. Create a buffer format. It will be just like in maxloc (index + value).
    //    we may not use maxloc because we may have more than one row per process.
    //    Fill the unused rows with int.min.
    // 3. Count the number of max elements with another custom op. 
    //    This will need to have just the numbers + the current counts per each column in the buffer.
    // 4. Create a vector of that many elements per each column.
    //    They shall stay one right after the other in memory and their lengths will be set globally.
    //    The vector will also include the current position.
    //    Also we will need a flag, initially false everywhere, of whether the inout vector has been ever processed,
    //    or needs to be considered (whether the indices of max elements need to be saved).
    //    After those vectors, we will have the initial maxloc data to actually find the indices of the max elements.
    // 5. Store the indices from the first matrix in an associative array (otherwise the algo is O(n^2)).
    // 6. Check if the inverses of the vectors of the second matrix are in that array.
    //    Ones that are, are our answers.

    // So, for the first two custom ops, we need:
    // 1. ~An integer of whether a given vector has been processed. 
    //    This will make sure the inout vector is processed exactly once.~ [processed]
    //    Instead, maxElementCount of -1 indicates that the vector has not been processed.
    // 2. A buffer with IntInt, storing ~the index of the element~ + the value. [indexValue]
    //    Actually, only the last step needs the indices. So this stores [value] instead
    // 3. ~A buffer with the current max element (no, this will be stored in the 2.)~
    // 4. A buffer with the max element count. [maxElementCount]
    /// I will even combine the first two custom ops, so it finds max + count at once.
    // 
    // For the third op, we need:
    // 1. The vectors and the current max element index indices thing.
    // Also, [processed] and [indexValue].
    //
    // We cannot really combine the first two and the last buffer, because we can't apriori
    // know the length of the last buffer.
    // So we'll just combine the first two.
    static struct FirstPassReduceBufferInfo
    {
        int* reduceBuffer;
        size_t numRows;
        size_t width;

        // ref int processed() { return reduceBuffer[0]; }
        int[] maxElementCount() { return reduceBuffer[0..width]; }
        int[] getValues(size_t rowIndex) 
        { 
            assert(rowIndex < numRows);
            size_t startIndex = width + rowIndex * width;
            return reduceBuffer[startIndex .. startIndex + width];
        }
        size_t length() { return width * numRows + width; }

        auto iterateRows(size_t startingIndex) 
        {
            return iota(startingIndex, numRows)
                .map!getValues
                .until(a => a[0] == int.min);
        }
    }

    struct Stuff(TMatrix)
    {
        TMatrix dataMatrix;
        /// The starting and the ending index for the process, inclusive.
        Range rowIndexRange;
        /// The maximum number of rows per process.
        size_t maxRowsPerProcess;
        /// Stores 
        /// 1 x maxElementCount[height],
        /// reduceBufferBlockLength x value[height]
        int[] reduceBuffer12;

        FirstPassReduceBufferInfo getFirstPassBufferInfo()
        {
            return FirstPassReduceBufferInfo(reduceBuffer12.ptr, maxRowsPerProcess, dataMatrix.width);
        }
    }

    auto getStuff(TMatrix)(TMatrix matrix)
    {
        Stuff!TMatrix stuff;
        stuff.matrix = matrix;

        const rowIndexStart = offsetForProcess(info.rank, matrix.height);
        const rowIndexEnd = offsetForProcess(info.rank + 1, matrix.height);
        stuff.range = Range(rowIndexStart, rowIndexEnd - 1);
        stuff.maxRowsPerProcess = cast(size_t) (matrix.height + matrix.height - 1) / (info.size);

        FirstPassReduceBufferInfo reduceBufferInfo;
        reduceBufferInfo.numRows = stuff.maxRowsPerProcess;
        reduceBufferInfo.width = matrix.width;
        stuff.reduceBuffer12 = new int[](reduceBufferInfo.length);
        reduceBufferInfo.reduceBuffer = stuff.reduceBuffer12.ptr;

        // Now set up the buffer
        reduceBufferInfo.maxElementCount[0] = -1;
        foreach (rowIndex; 0..matrix.height)
        foreach (colIndex; 0..matrix.width)
        {
            reduceBufferInfo.getValues(rowIndex)[colIndex] = matrix[rowIndex, colIndex];
        }
        foreach (rowIndex; matrix.height..stuff.maxRowsPerProcess)
        {
            reduceBufferInfo.getValues(rowIndex)[] = int.min;
        }

        return stuff;
    }

    auto AFullMatrix = matrixFromArray(AData, DataWidth);
    auto AStuff = getStuff(AFullMatrix);
    auto BFullMatrix = matrixFromArray(BData, DataWidth).transposed;
    auto BStuff = getStuff(BFullMatrix);

    static shared size_t currentWidth;
    static shared size_t currentReduceBufferNumRows;
    static void firstPassOperationFunction(int* inReduceBuffer, int* inoutReduceBuffer, int length)
    {
        // We will be making use of the global variables currentHeight and currentReduceBufferWidth,
        // which will have to be set prior to calling this op reduction.
        // We will use the length parameter only for error checking.
        auto inBufferInfo = FirstPassReduceBufferInfo(inReduceBuffer, currentReduceBufferNumRows, currentWidth);
        auto inoutBufferInfo = FirstPassReduceBufferInfo(inoutReduceBuffer, currentReduceBufferNumRows, currentWidth);
        assert(inBufferInfo.length == length, "Oh crap, the length is wrong. Probably forgot to set globals.");
        auto firstRowValues = inoutBufferInfo.getValues(0); 

        void update(int[] rowValues)
        {
            foreach (colIndex; 0..inoutBufferInfo.width)
            {
                if (rowValues[colIndex] == firstRowValues[colIndex])
                    inoutBufferInfo.maxElementCount[colIndex]++;
                else if (rowValues[colIndex] > firstRowValues[colIndex])
                {
                    inoutBufferInfo.maxElementCount[colIndex] = 1;
                    firstRowValues[colIndex] = rowValues[colIndex];
                }
            }
        }

        // If the inout buffer has not been processed, do it.
        if (inoutBufferInfo.maxElementCount[0] == -1)
        {
            inoutBufferInfo.maxElementCount[] = 1;
            inoutBufferInfo.iterateRows(1).each!update;
        }
        inBufferInfo.iterateRows(0).each!update;
    }

    // Debugging: print matrices
    static if (1)
    {
        import core.thread;
        if (info.rank == 0)
        {
            writeln("Whole matrix A:");
            matrix.printMatrix(AStuff.matrix);
            writeln("Whole matrix B:");
            matrix.printMatrix(BStuff.matrix);
            writeln();
        }
        mh.barrier();
    }

    return 0;
}
