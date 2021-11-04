import mpi;
import mh = mpihelper;
import std.stdio : writeln;
import std.range;
import std.algorithm;
import matrix;

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
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    size_t offsetForProcess(int processIndex, size_t vectorCount)
    {
        return cast(size_t) processIndex * vectorCount / info.size;
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
    // 1. ~~An integer of whether a given vector has been processed. 
    //    This will make sure the inout vector is processed exactly once.~~ [processed]
    //    Instead, maxElementCount of -1 indicates that the vector has not been processed.
    // 2. A buffer with IntInt, storing ~~the index of the element~~ + the value. [indexValue]
    //    Actually, only the last step needs the indices. So this stores [value] instead
    // 3. ~~A buffer with the current max element (no, this will be stored in the 2.)~~
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
    auto getStuff(TMatrix)(TMatrix matrix)
    {
        Stuff!TMatrix stuff;
        stuff.matrix = matrix;

        const rowIndexStart = offsetForProcess(info.rank, matrix.height);
        const rowIndexEnd = offsetForProcess(info.rank + 1, matrix.height);
        stuff.rowIndexRange = Range([rowIndexStart, rowIndexEnd - 1]);
        stuff.maxRowsPerProcess = cast(size_t) (matrix.height + matrix.height - 1) / (info.size);

        FirstPassReduceBufferInfo reduceBufferInfo;
        reduceBufferInfo.numRows = stuff.maxRowsPerProcess;
        reduceBufferInfo.width = matrix.width;
        stuff.reduceBuffer1 = new int[](reduceBufferInfo.length);
        reduceBufferInfo.reduceBuffer = stuff.reduceBuffer1.ptr;

        // Now set up the buffer
        reduceBufferInfo.maxElementCounts[0] = -1;
        foreach (rowIndex; 0..stuff.rowIndexRange.length)
        {
            auto row = reduceBufferInfo.getRow(rowIndex);
            foreach (colIndex; 0..matrix.width)
                row[colIndex] = matrix[rowIndex + stuff.rowIndexRange.arrayof[0], colIndex];
        }
        if (stuff.rowIndexRange.length != stuff.maxRowsPerProcess)
            reduceBufferInfo.getRow(stuff.rowIndexRange.length)[0] = int.min;

        return stuff;
    }

    auto AFullMatrix = matrixFromArray(AData, DataWidth);
    auto BFullMatrix = matrixFromArray(BData, DataWidth).transposed;
    auto AStuff = getStuff(AFullMatrix);
    auto BStuff = getStuff(BFullMatrix);

    // Debugging: print matrices
    void debugPrint()
    {
        static if (1)
        {
            import core.thread;
            Thread.sleep(dur!"msecs"(30 * info.rank));
            writeln("Process ", info.rank);
            if (info.rank == 0)
            {
                writeln("Whole matrix A:");
                matrix.printMatrix(AStuff.matrix);
                writeln("Whole matrix B:");
                matrix.printMatrix(BStuff.matrix);
                writeln();
            }
            writeln("Number of maximums A:");
            writeln(AStuff.getFirstPassBufferInfo().maxElementCounts);
            writeln("Maximums A:");
            writeln(AStuff.getFirstPassBufferInfo().maxElementsRow);
            writeln("Number of maximums B:");
            writeln(BStuff.getFirstPassBufferInfo().maxElementCounts);
            writeln("Maximums B:");
            writeln(BStuff.getFirstPassBufferInfo().maxElementsRow);
            writeln();
            mh.barrier();
        }
    }

    auto firstPassOperation = mh.createOp!firstPassOperationFunction(true);
    scope(exit) mh.free(firstPassOperation);

    void doFirstPass(Stuff)(ref Stuff stuff)
    {
        // Set global variables for the function to work properly
        g_currentWidth = stuff.matrix.width;
        g_currentReduceBufferNumRows = stuff.maxRowsPerProcess;
        mh.intraReduce(stuff.reduceBuffer1, firstPassOperation, info.rank, 0);
        mh.bcast(stuff.getFirstPassBufferInfo().maxElementCounts, 0);
        mh.bcast(stuff.getFirstPassBufferInfo().maxElementsRow, 0);
        mh.barrier();
    }
    doFirstPass(AStuff);
    doFirstPass(BStuff);


    void adjustStuffForSecondPass(Stuff)(ref Stuff stuff)
    {
        SecondPassReduceBufferInfo secondPass;
        secondPass.numRows = stuff.maxRowsPerProcess;
        secondPass.width = stuff.matrix.width;

        FirstPassReduceBufferInfo firstPass = stuff.getFirstPassBufferInfo();
        size_t maxElementCountSoFar = 0;
        stuff.indexBufferOffsets2 = new size_t[](stuff.matrix.width + 1);
        secondPass.indexBufferOffsets = stuff.indexBufferOffsets2;

        foreach (index, count; firstPass.maxElementCounts)
        {
            // The 1 int is the header which indicates the current index.
            maxElementCountSoFar += count + 1;
            stuff.indexBufferOffsets2[index + 1] = maxElementCountSoFar;
        }
        
        stuff.reduceBuffer2 = new int[](secondPass.length);
        secondPass.reduceBuffer = stuff.reduceBuffer2.ptr;
        secondPass.markUnprocessed();

        foreach (rowIndex; 0..stuff.rowIndexRange.length)
        {
            mh.IntInt[] row = secondPass.getRow(rowIndex);
            size_t actualRowIndex = rowIndex + stuff.rowIndexRange.arrayof[0];
            foreach (colIndex; 0..stuff.matrix.width)
            {
                row[colIndex].value = stuff.matrix[actualRowIndex, colIndex];
                row[colIndex].rank = cast(int) actualRowIndex;
            }
        }
        if (stuff.rowIndexRange.length != stuff.maxRowsPerProcess)
            (cast(int[]) firstPass.getRow(stuff.rowIndexRange.length))[0] = int.min;
    }
    adjustStuffForSecondPass(AStuff);
    adjustStuffForSecondPass(BStuff);
    
    auto secondPassOperation = mh.createOp!secondPassOperationFunction(true);
    scope(exit) mh.free(firstPassOperation);

    void doSecondPass(Stuff)(ref Stuff stuff)
    {
        g_currentWidth = stuff.matrix.width;
        g_currentReduceBufferNumRows = stuff.maxRowsPerProcess;
        g_maxElements = stuff.getFirstPassBufferInfo().maxElementsRow;
        g_indexBufferOffsets = stuff.indexBufferOffsets2;

        mh.intraReduce(stuff.reduceBuffer2, secondPassOperation, info.rank, 0);
        // mh.bcast(stuff.reduceBuffer2[0..stuff.indexBufferOffsets[$ - 1]], 0);
        mh.barrier();
    }
    doSecondPass(AStuff);
    doSecondPass(BStuff);

    if (info.rank == 0)
    {
        struct Position { int colIndex; int rowIndex; }
        bool[Position] hashSet;
        auto ASecondPassBufferInfo = AStuff.getSecondPassBufferInfo();
        foreach (colIndex; 0..AStuff.matrix.width)
        foreach (rowIndex; ASecondPassBufferInfo.getIndexBufferHead(colIndex))
        {
            hashSet[Position(cast(int) colIndex, rowIndex)] = true;
        }

        Position[] points;
        auto BSecondPassBufferInfo = AStuff.getSecondPassBufferInfo();
        // B is transposed
        foreach (rowIndex; 0..BStuff.matrix.width)
        foreach (colIndex; BSecondPassBufferInfo.getIndexBufferHead(rowIndex))
        {
            auto pos = Position(colIndex, cast(int) rowIndex);
            if (pos in hashSet)
                points ~= pos;
        }

        writeln(points);
    }

    return 0;
}

struct Stuff(TMatrix)
{
    TMatrix matrix;
    /// The starting and the ending index for the process, inclusive.
    Range rowIndexRange;
    /// The maximum number of rows per process.
    size_t maxRowsPerProcess;
    /// Stores 
    /// 1 x maxElementCount[height],
    /// reduceBufferBlockLength x value[height]
    int[] reduceBuffer1;
    /// See below
    int[] reduceBuffer2;
    size_t[] indexBufferOffsets2;
}

struct FirstPassReduceBufferInfo
{
    int* reduceBuffer;
    size_t numRows;
    size_t width;

    int[] maxElementCounts() { return reduceBuffer[0..width]; }
    int[] getRow(size_t rowIndex) 
    { 
        assert(rowIndex < numRows);
        size_t startIndex = width + rowIndex * width;
        return reduceBuffer[startIndex .. startIndex + width];
    }
    int[] maxElementsRow() { return getRow(0); }
    size_t length() { return width * numRows + width; }
}

FirstPassReduceBufferInfo getFirstPassBufferInfo(Stuff)(ref Stuff stuff)
{
    with (stuff)
    return FirstPassReduceBufferInfo(reduceBuffer1.ptr, maxRowsPerProcess, matrix.width);
}

struct SecondPassReduceBufferInfo
{
    int* reduceBuffer;
    size_t numRows;
    size_t width;
    size_t[] indexBufferOffsets;

    void addIndex(size_t indexBufferIndex, int index)
    {
        int* buffer = reduceBuffer + indexBufferOffsets[indexBufferIndex];
        buffer[0]++;
        buffer[buffer[0]] = index;
    }

    ref int getIndexBufferLength(size_t indexBufferIndex)
    {
        return reduceBuffer[indexBufferOffsets[indexBufferIndex]];
    }

    int[] getIndexBufferHead(size_t indexBufferIndex)
    {
        int* buffer = reduceBuffer + indexBufferOffsets[indexBufferIndex];
        return buffer[1 .. (buffer[0] + 1)];
    }

    int[] getIndexBufferTail(size_t indexBufferIndex)
    {
        int* buffer = reduceBuffer + indexBufferOffsets[indexBufferIndex];
        return buffer[(buffer[0] + 1) .. indexBufferOffsets[indexBufferIndex + 1]];
    }

    mh.IntInt[] getRow(size_t rowIndex) 
    { 
        size_t index = rowIndex * width * 2;
        return cast(mh.IntInt[]) (reduceBuffer + indexBufferOffsets[$ - 1])[index .. index + width * 2];
    }

    size_t length() 
    { 
        return cast(size_t)((cast(int*) getRow(numRows).ptr) - reduceBuffer); 
    }

    bool isUnprocessed() { return reduceBuffer[0] == -1; }

    // Here we indicate that we have not been processed yet.
    // -1 in the header of the first index buffer indicates that.
    void markUnprocessed() { reduceBuffer[0] = -1; }
}

SecondPassReduceBufferInfo getSecondPassBufferInfo(Stuff)(ref Stuff stuff)
{
    with(stuff)
    return SecondPassReduceBufferInfo(
        reduceBuffer2.ptr, 
        maxRowsPerProcess, 
        matrix.width, 
        indexBufferOffsets2);
}

// UFCS functions must be defined outside local functions
auto iterateRows(BufferInfo)(ref BufferInfo info, size_t startingIndex) 
{
    return iota(startingIndex, info.numRows)
        .map!(i => info.getRow(i))
        .until!(a => (cast(int*)&a)[0] == int.min);
}

__gshared size_t g_currentWidth;
__gshared size_t g_currentReduceBufferNumRows;
void firstPassOperationFunction(int* inReduceBuffer, int* inoutReduceBuffer, int length)
{
    // We will be making use of the global variables currentWidth and currentReduceBufferNumRows,
    // which will have to be set prior to calling this op reduction.
    // We will use the length parameter only for error checking.
    auto inBufferInfo = FirstPassReduceBufferInfo(inReduceBuffer, g_currentReduceBufferNumRows, g_currentWidth);
    auto inoutBufferInfo = FirstPassReduceBufferInfo(inoutReduceBuffer, g_currentReduceBufferNumRows, g_currentWidth);
    assert(inBufferInfo.length == length, "Oh crap, the length is wrong. Probably forgot to set globals.");
    int[] firstRow = inoutBufferInfo.getRow(0); 

    void update(int[] rowValues)
    {
        foreach (colIndex; 0..inoutBufferInfo.width)
        {
            if (rowValues[colIndex] == firstRow[colIndex])
                inoutBufferInfo.maxElementCounts[colIndex]++;
            else if (rowValues[colIndex] > firstRow[colIndex])
            {
                inoutBufferInfo.maxElementCounts[colIndex] = 1;
                firstRow[colIndex] = rowValues[colIndex];
            }
        }
    }

    // If the inout buffer has not been processed, do it.
    if (inoutBufferInfo.maxElementCounts[0] == -1)
    {
        inoutBufferInfo.maxElementCounts[] = 1;
        inoutBufferInfo.iterateRows(1).each!update;
    }
    
    // The in buffer has previously been modified.
    // In this case we just need to check the row with the maximums, and adjust
    // the counts accordingly.
    if (inBufferInfo.maxElementCounts[0] != -1)
    {
        int[] otherFirstRow = inBufferInfo.getRow(0);
        foreach (colIndex; 0..inoutBufferInfo.width)
        {
            if (otherFirstRow[colIndex] == firstRow[colIndex])
                inoutBufferInfo.maxElementCounts[colIndex] += inBufferInfo.maxElementCounts[colIndex];
            else if (otherFirstRow[colIndex] < firstRow[colIndex])
            {
                inoutBufferInfo.maxElementCounts[colIndex] = inBufferInfo.maxElementCounts[colIndex];
                firstRow[colIndex] = otherFirstRow[colIndex];
            }
        }
    }
    // The buffer has never been an inout buffer, and it will never be.
    else
    {
        inBufferInfo.iterateRows(0).each!update;
    }
}

__gshared size_t[] g_indexBufferOffsets;
__gshared int[] g_maxElements;
void secondPassOperationFunction(int* inReduceBuffer, int* inoutReduceBuffer, int length)
{
    auto inBufferInfo = SecondPassReduceBufferInfo(
        inReduceBuffer, g_currentReduceBufferNumRows, g_currentWidth, g_indexBufferOffsets);
    auto inoutBufferInfo = SecondPassReduceBufferInfo(
        inoutReduceBuffer, g_currentReduceBufferNumRows, g_currentWidth, g_indexBufferOffsets);
    assert(inBufferInfo.length == length, "Again");

    void update(mh.IntInt[] pairs)
    {
        foreach (colIndex, pair; pairs)
        {
            if (pair.value == g_maxElements[colIndex])
                inoutBufferInfo.addIndex(colIndex, pair.rank);
        }
    }

    if (inoutBufferInfo.isUnprocessed)
    {
        inoutBufferInfo.reduceBuffer[0] = 0;
        inoutBufferInfo.iterateRows(0).each!update;
    }
    if (!inBufferInfo.isUnprocessed)
    {
        foreach (colIndex; 0..inoutBufferInfo.width)
        {
            auto tail = inoutBufferInfo.getIndexBufferTail(colIndex);
            auto adjustment = inBufferInfo.getIndexBufferHead(colIndex);
            tail[0..adjustment.length] = adjustment[];
            inoutBufferInfo.getIndexBufferLength(colIndex) += inBufferInfo.getIndexBufferLength(colIndex);
        }
    }
    else
    {
        inBufferInfo.iterateRows(1).each!update;
    }
}