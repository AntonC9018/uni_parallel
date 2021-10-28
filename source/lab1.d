/**
    A demo program, implementing Nash Equilibrium solution finder.

    Optional version flags      Constraints
    =======================================================================
    `ArbitraryMatrix`           When compiling with this flag, also compile the file `matrix.d`.
    
    `RootDistributesValues`     ArbitraryMatrix flag is ignored. 
                                Only square matrices are allowed. 
                                The immutable data matrices are used. 

    `KeyboardInput`             ArbitraryMatrix flag is ignored. Any matrices, but don't use large ones.

    default                     The immutable data matrices are used.
*/

// DATA processed by the processes
static if (1)
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

version(ArbitraryMatrix) 
int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import matrix;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    const root = 0;
    bool isRoot() { return info.rank == root; }
    
    int offsetForProcess(int processIndex, int vectorCount)
    {
        return processIndex * vectorCount / info.size;
    }
    enum DataHeight = AData.length / DataWidth;
    
    // ================================================
    //      Step 1: Distribute rows / columns.
    // ================================================
    // The number of columns = width of the matrix.
    const columnIndexStartA = offsetForProcess(info.rank, DataWidth);
    const columnIndexEndA = offsetForProcess(info.rank + 1, DataWidth);
    const numAllocatedColumnsA = cast(size_t) columnIndexEndA - columnIndexStartA;
    int[] ABuffer = new int[](numAllocatedColumnsA * DataHeight);
    // Does not allocate!
    Matrix!int AMatrix = matrixFromArray(ABuffer, numAllocatedColumnsA); 
    foreach (rowIndex; 0..DataHeight)
    foreach (colIndex; 0..numAllocatedColumnsA)
    {
        AMatrix[rowIndex, colIndex] = AData[rowIndex * DataWidth + columnIndexStartA + colIndex];
    }

    // The number of rows = height of the matrix.
    const rowIndexStartB = offsetForProcess(info.rank, DataHeight);
    const rowIndexEndB = offsetForProcess(info.rank + 1, DataHeight);
    const numAllocatedRowsB = cast(size_t) rowIndexEndB - rowIndexStartB;
    int[] BBuffer = new int[](numAllocatedRowsB * DataWidth);
    // Does not allocate!
    Matrix!int BMatrix = matrixFromArray(BBuffer, DataWidth);
    foreach (rowIndex; 0..numAllocatedRowsB)
    foreach (colIndex; 0..DataWidth)
    {
        BMatrix[rowIndex, colIndex] = BData[(rowIndex + rowIndexStartB) * DataWidth + colIndex];
    }

    // ================================================
    //          Step 2: Find all maximums.
    // ================================================
    // Go with a true / false list for now (stored as ints).
    alias BOOL = int;
    BOOL TRUE = 1;
    BOOL FALSE = 0;
    Matrix!BOOL getMaximums(M)(M matrix)
    {
        BOOL[] result = new BOOL[](matrix.width * matrix.height);
        auto resultMatrix = matrixFromArray(result, matrix.width);
        foreach (rowIndex; 0..matrix.height)
        {
            // Find the max, then mark true all cells with that values
            int maxValue = int.min;
            foreach (colIndex; 0..matrix.width)
            {
                import std.algorithm.comparison : max;
                maxValue = max(maxValue, matrix[rowIndex, colIndex]);
            }
            foreach (colIndex; 0..matrix.width)
            {
                if (matrix[rowIndex, colIndex] == maxValue)
                    resultMatrix[rowIndex, colIndex] = TRUE;
            }
        }
        return resultMatrix;
    }
    // We transpose A twice so in the end it's normal again
    auto matrixOfWhetherIndexIsMaximumA = getMaximums(AMatrix.transposed).transposed;
    auto matrixOfWhetherIndexIsMaximumB = getMaximums(BMatrix);

    if (info.size == 6 && DataWidth == 6 && DataHeight == 6)
    {
        if (info.rank == 0)
        {
            mh.abortIf(matrixOfWhetherIndexIsMaximumA[0, 0] != TRUE, "1");
            mh.abortIf(matrixOfWhetherIndexIsMaximumB[0, 1] != TRUE, "2");
        }
        else if (info.rank == 1)
        {
            // Don't forget it's transposed!
            mh.abortIf(matrixOfWhetherIndexIsMaximumA[1, 0] != TRUE, "3");
            mh.abortIf(matrixOfWhetherIndexIsMaximumB[0, 2] != TRUE, "4");
        }
    }

    // Debugging: print matrices
    static if (1)
    {
        import core.thread;
        if (info.rank == 0)
        {
            writeln("Whole matrix A:");
            printMatrix(AData, DataWidth);
            writeln("Whole matrix B:");
            printMatrix(BData, DataWidth);
            writeln();
        }
        Thread.sleep(dur!"msecs"(20 * info.rank));
        writeln("Process ", info.rank);
        writeln("Matrix subA:");
        matrix.printMatrix(AMatrix);
        writeln("Matrix subB:");
        matrix.printMatrix(BMatrix);
        writeln("Matrix isMax(subA):");
        matrix.printMatrix(matrixOfWhetherIndexIsMaximumA);
        writeln("Matrix isMax(subB):");
        matrix.printMatrix(matrixOfWhetherIndexIsMaximumB);
        writeln();
        Thread.sleep(dur!"msecs"(20));
        mh.barrier();
    }

    // ================================================
    //     Step 3 & 4: Share values & Calculate Nash 
    // ================================================
    size_t maxPossibleAllocatedAColumns = (DataWidth + DataWidth - 1) / (info.size);
    size_t maxPossibleAllocatedBRows = (DataHeight + DataHeight - 1) / (info.size);
    // We need to send a rectangular submatrix.
    BOOL[] sendBuffer = new BOOL[](numAllocatedRowsB * maxPossibleAllocatedAColumns);
    BOOL[] receiveBuffer = new BOOL[](maxPossibleAllocatedBRows * numAllocatedColumnsA);
    struct Point { size_t row; size_t column; }
    Point[] results;

    foreach (processIndex; 0..info.size)
    {
        const partnerRowIndexStartB = offsetForProcess(processIndex, DataHeight);
        const partnerRowIndexEndB = offsetForProcess(processIndex + 1, DataHeight);
        const partnerNumAllocatedRowsB = cast(size_t) partnerRowIndexEndB - partnerRowIndexStartB;

        // Calculate the index that the other proccess wants to receive.
        const partnerColumnIndexStartA = offsetForProcess(processIndex, DataWidth);
        const partnerColumnIndexEndA = offsetForProcess(processIndex + 1, DataWidth);
        const partnerNumAllocatedColumnsA = cast(size_t) partnerColumnIndexEndA - partnerColumnIndexStartA;
        const tag = 10;

        // No allocations!
        auto sendBufferSlice = sendBuffer[0..(partnerNumAllocatedColumnsA * numAllocatedRowsB)];
        auto sendMatrix = matrixFromArray(sendBufferSlice, partnerNumAllocatedColumnsA);
        // Copy the needed indices into the send buffer
        foreach (rowIndex; 0..numAllocatedRowsB)
        foreach (colIndex; 0..partnerNumAllocatedColumnsA)
        {
            sendMatrix[rowIndex, colIndex] = matrixOfWhetherIndexIsMaximumB[rowIndex, colIndex + partnerColumnIndexStartA];
        }

        auto receiveBufferSlice = receiveBuffer[0..(partnerNumAllocatedRowsB * numAllocatedColumnsA)];
        mh.sendRecv(sendBufferSlice, processIndex, tag, receiveBufferSlice, processIndex, tag);
        // writeln("Proccess ", info.rank, " sent ", sendBufferSlice, " and received ", receiveBufferSlice);

        auto receiveMatrix = matrixFromArray(receiveBufferSlice, numAllocatedColumnsA);
        foreach (rowIndex; 0..partnerNumAllocatedRowsB)
        foreach (colIndex; 0..numAllocatedColumnsA)
        {
            // Check if the cells in both A and B are max
            if (matrixOfWhetherIndexIsMaximumA[rowIndex + partnerRowIndexStartB, colIndex] 
                && receiveMatrix[rowIndex, colIndex])
            {
                results ~= Point(rowIndex + partnerRowIndexStartB, colIndex + columnIndexStartA);
            }
        }
    }

    // ================================================
    //            Step 5: Print results 
    // ================================================
    foreach (processIndex; 0..info.size)
    {
        if (processIndex == info.rank)
        {
            foreach (result; results)
            {
                writeln("Process ", processIndex, " found (", result.row, ", ", result.column, ")");
            }
        }
        mh.barrier();
    }

    return 0;
}

else // version(!ArbitraryMatrix)
int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    const root = 0;
    bool isRoot() { return info.rank == root; }
    auto reduceBufferA = new mh.IntInt[](info.size);

    version(RootDistributesValues)
    {
        // Ensure matrices are square at compile time.
        static assert(AData.length == DataWidth^^2);
        static assert(BData.length == DataWidth^^2);
        mh.abortIf(info.size != DataWidth, "Number of processes must be equal to the matrix dimension");

        auto rootBufferStartIndex() { return root * DataWidth; }

        int[] A;
        int[] BTranspose;
        int[] scatterReceiveBuffer;

        if (isRoot)
        {
            A = AData.dup;
            BTranspose = transpose(BData, DataWidth);
            printMatrix(A, DataWidth);
            printMatrix(BTranspose, DataWidth);
            scatterReceiveBuffer = A[rootBufferStartIndex .. (rootBufferStartIndex + DataWidth)];
        }
        else
        {
            scatterReceiveBuffer = new int[](DataWidth);
        }

        // Sort of does this, except does no copying at root.
        // MPI_Scatter(
        //    A.ptr, scatterReceiveBuffer.length, MPI_INT, 
        //    scatterReceiveBuffer.ptr, scatterReceiveBuffer.length, MPI_INT, 
        //    root, MPI_COMM_WORLD);
        if (isRoot)
            mh.intraScatterSend(A, info);
        else
            mh.intraScatterRecv(scatterReceiveBuffer, root);

        // Now interveave the indices with the input data in the reduce buffer.
        void interweaveReduceBuffer(mh.IntInt[] buffer)
        {
            foreach (i, ref pair; buffer)
            {
                pair.rank  = info.rank;
                pair.value = scatterReceiveBuffer[i];
            }
        }
        interweaveReduceBuffer(reduceBufferA);
    }
    else version(KeyboardInput)
    {
        char[] keyboardInputBuffer;
        int readInt()
        {
            import std.stdio : readln, stdin;
            import std.conv : to;
            import std.string : strip;
            while (true)
            {
                try
                {
                    readln(keyboardInputBuffer);
                    int result = keyboardInputBuffer[].strip.to!int;
                    return result;
                }
                catch (Exception err)
                {
                }
            }
            return 0;
        }

        void inputForEveryProcess(scope void delegate(int processIndex) loop)
        {
            foreach (processIndex; 0..info.size)
            {
                if (processIndex == info.rank || info.rank == 0)
                {
                    loop(processIndex);
                }
                mh.barrier();
            }
        }

        auto integerInputHandlerFunction(string messageFormatString)(mh.IntInt[] buffer)
        {
            return (int processIndex)
            {
                foreach (i, ref pair; buffer)
                {
                    if (processIndex == info.rank)
                    {
                        mixin("writeln(" ~ messageFormatString ~ ");");
                        pair.rank = info.rank;
                    }

                    const tag = 10;
                    if (processIndex == info.rank && info.rank == 0)
                    {
                        pair.value = readInt();
                    }
                    else if (processIndex == info.rank)
                    {
                        mh.recv(&pair.value, 0, tag);
                    }
                    else // if (info.rank == 0)
                    {
                        auto value = readInt();
                        mh.send(&value, processIndex, tag);
                    }
                }
            };
        }

        inputForEveryProcess(
            integerInputHandlerFunction!(`"Enter A[", processIndex, ", ", i, "] = "`)(reduceBufferA));
    }
    else
    {
        foreach (colIndex, ref pair; reduceBufferA)
        {
            pair.value = AData[colIndex + info.rank * DataWidth];
            pair.rank = info.rank;
        }
    }

    // Reduce in-place. Does this, but with compile-time deduction of some parameters:
    // MPI_Reduce(reduceBuffer.ptr, 
    //     MPI_IN_PLACE, reduceBuffer.length, MPI_INT2, MPI_MAXLOC, 
    //     root, MPI_COMM_WORLD);
    mh.intraReduce(reduceBufferA, MPI_MAXLOC, info.rank, root);

    void printReduceBuffer(string matrixName, mh.IntInt[] buffer)
    {
        writeln("Reduce buffer data for matrix `", matrixName, "`:");
        foreach (colIndex, pair; buffer)
            writeln("Maximum element's row index in the column ", colIndex, " is ", pair.rank, " with value ", pair.value);
    }

    if (isRoot)
    {
        printReduceBuffer("A", reduceBufferA);
    }

    auto reduceBufferB = new mh.IntInt[](info.size);

    version(RootDistributesValues)
    {
        if (isRoot)
        {
            scatterReceiveBuffer = BTranspose[rootBufferStartIndex .. (rootBufferStartIndex + DataWidth)];
            mh.intraScatterSend(BTranspose, info);
        }
        else
        {
            mh.intraScatterRecv(scatterReceiveBuffer, root);
        }
        interweaveReduceBuffer(reduceBufferB);
    }
    else version(KeyboardInput)
    {
        inputForEveryProcess(
            integerInputHandlerFunction!(`"Enter B[", i, ", ", processIndex, "] = "`)(reduceBufferB));
    }
    else 
    {
        // Initialize buffer for B
        foreach (rowIndex, ref pair; reduceBufferB)
        {
            pair.value = BData[rowIndex * DataWidth + info.rank];
            pair.rank = info.rank;
        }
    }
    mh.intraReduce(reduceBufferB, MPI_MAXLOC, info.rank, root);

    if (isRoot)
    {
        printReduceBuffer("BTranspose", reduceBufferB);
    }

    if (isRoot)
    {
        int hitCount = 0;
        foreach (colIndexA; 0..info.size)
        foreach (rowIndexB; 0..info.size)
        {
            auto colIndexB = reduceBufferB[rowIndexB].rank;
            auto rowIndexA = reduceBufferA[colIndexA].rank;
            if (colIndexA == colIndexB && rowIndexA == rowIndexB)
            {
                hitCount++;
                writeln("Nash Equilibrium: (", colIndexA, ", ", rowIndexA, ")."); 
            }
        }
        if (hitCount == 0)
            writeln("No Nash Equilibrium.");
    }
    return 0;
}

void printMatrix(T)(const(T)[] matrix, size_t width)
{
    const height = matrix.length / width;

    import std.stdio : writef, writeln;
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        writef("%3d", matrix[rowIndex * width + colIndex]);
        if (colIndex == width - 1)
            writeln();
    }
}

T[] transpose(T)(const(T)[] elements, size_t width)
{
    auto height = elements.length / width;
    auto result = new T[](width * height);
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        result[rowIndex * width + colIndex] = elements[colIndex * height + rowIndex];
    }
    return result;
}
unittest
{
    auto t = transpose([ 1, 2, 3, 
                         4, 5, 6, 
                         7, 8, 9, ], 3);
    assert(t[] == [ 1, 4, 7,
                    2, 5, 8,
                    3, 6, 9, ]);
}