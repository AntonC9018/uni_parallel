// DATA processed by the processes
enum DataWidth = 6;
immutable AData = [
    4,  0,  0,  0,  0,  0,
    3,  3,  0,  0,  0,  0,
    2,  2,  2,  0,  0,  0,
    1,  1,  1,  1,  0,  0,
    0,  0,  0,  0,  0,  0,
    -1, -1, -1, -1, -1, -1,
];
immutable BData = [
    0,  2,  1,  0, -1, -2,
    0,  0,  1,  0, -1, -2,
    0,  0,  0,  0, -1, -2,
    0,  0,  0,  0, -1, -2,
    0,  0,  0,  0,  0, -2,
    0,  0,  0,  0,  0,  0,
];
// Ensure matrices are square at compile time.
static assert(AData.length == DataWidth^^2);
static assert(BData.length == DataWidth^^2);

int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    auto info = mh.initialize();
    scope(exit) mh.finalize();
    mh.abortIf(info.size != DataWidth, "Number of processes must be equal to the matrix dimension");

    const root = 0;

    bool isRoot() { return info.rank == root; }
    auto rootBufferStartIndex() { return root * DataWidth; }

    auto reduceBufferA = new mh.IntInt[](DataWidth);

    version(RootDistributesValues)
    {
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
    else
    {
        // Initialize buffer for A
        foreach (colIndex, ref pair; reduceBufferA)
        {
            pair.value = AData[colIndex + rank * DataWidth];
            pair.rank = rank;
        }
    }

    // Reduce in-place. Does this, but with compile-time deduction of some parameters:
    // MPI_Reduce(reduceBuffer.ptr, 
    //     MPI_IN_PLACE, reduceBuffer.length, MPI_INT2, MPI_MAXLOC, 
    //     root, MPI_COMM_WORLD);
    mh.intraReduce(reduceBufferA, MPI_MAXLOC, root);

    void printReduceBuffer(string matrixName, mh.IntInt[] buffer)
    {
        writeln("Reduce buffer data for matrix`", matrixName, "`:");
        foreach (colIndex, pair; buffer)
            writeln("Maximum element's row index in the column ", colIndex, " is ", pair.rank, " with value ", pair.value);
    }

    if (isRoot)
    {
        printReduceBuffer("A", reduceBufferA);
    }

    auto reduceBufferB = new mh.IntInt[](DataWidth);
    
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
    else
    {
        // Initialize buffer for B
        foreach (rowIndex, ref pair; reduceBufferB)
        {
            pair.value = BData[rowIndex * DataWidth + rank];
            pair.rank = rank;
        }
    }
    mh.intraReduce(reduceBufferB, MPI_MAXLOC, root);

    if (isRoot)
    {
        printReduceBuffer("BTraspose", reduceBufferB);
    }

    if (isRoot)
    {
        int hitCount = 0;
        foreach (colIndexA; 0..DataWidth)
        foreach (rowIndexB; 0..DataWidth)
        {
            auto colIndexB = reduceBufferB[rowIndexB].rank;
            auto rowIndexA = reduceBufferA[colIndexA].rank;
            if (colIndexA == colIndexB && rowIndexA == colIndexB)
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

    import std.stdio : write;
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        write(matrix[rowIndex * width + colIndex]);
        if (colIndex != width - 1)
            write(" ");
        else
            write("\n");
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
                         7, 8, 9, ], 3, 3);
    assert(t[] == [ 1, 4, 7,
                    2, 5, 8,
                    3, 6, 9, ]);
}