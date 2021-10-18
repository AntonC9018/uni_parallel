int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.random : uniform;
    import std.algorithm : fold, min;
    import std.range : iota;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    enum NUM_DIMS = 2;

    int[NUM_DIMS] computeGridDimensions = 0; 
    version (SimpleTest)
    {
        mh.abortIf(info.size != 6, "The number of processes for the simple case must be 6.");
        computeGridDimensions = [2, 3];
    }
    else
    {
        mh.getDimensions(info.size, computeGridDimensions[]);
    }
    int[NUM_DIMS] repeats = 0;
    MPI_Comm topologyComm = mh.createCartesianTopology(computeGridDimensions[], repeats[]);
    int[NUM_DIMS] mycoords = void;
    mh.getCartesianCoordinates(topologyComm, info.rank, mycoords[]);
    // We have passed reorder = false.
    int rootRankInComputeGrid = 0;
    int myComputeRank = info.rank;

    int[NUM_DIMS] matrixDimensions;
    version (SimpleTest)
    {
        matrixDimensions = [9, 9];
    }
    else
    {
        enum minDimension = 10;
        enum maxDimension = 40;
        if (info.rank == 0)
            matrixDimensions[0] = uniform!uint % (maxDimension - minDimension * 2) + minDimension;
        mh.bcast(&(matrixDimensions[0]), 0);
        matrixDimensions[1] = maxDimension - matrixDimensions[0];
    }

    version (PrintMatrix)
    {
        void printAsMatrix(int[] data, int width)
        {
            import std.stdio : writef;
            foreach (rowStartIndex; iota(0, data.length, width))
            {
                foreach (i; 0..width)
                    writef("%3d", data[rowStartIndex + i]);
                writeln();
            }
        }
    }

    version (WithActualMatrix)
    {
        int[] matrixData;
        if (myComputeRank == rootRankInComputeGrid)
        {
            matrixData = new int[](matrixDimensions.fold!`a * b`(1));
            foreach (ref element; matrixData)
                element = uniform!uint % 5 + 1;
        }
    }

    int blockSize;
    version (SimpleTest)
    {
        blockSize = 2;
    }
    else
    {
        enum minBlockSize = 2;
        enum maxBlockSize = 6;
        if (info.rank == 0)
            blockSize = uniform!uint % (maxBlockSize - minBlockSize) + minBlockSize;
        mh.bcast(&blockSize, 0);
    }
    
    if (info.rank == 0)
    {
        writeln("Compute grid dimensions: ", computeGridDimensions);
        writeln("Matrix dimensions: ", matrixDimensions);
        writeln("Block size: ", blockSize);
        
        version (WithActualMatrix) version (PrintMatrix)
        {
            writeln("Entire matrix: ");
            printAsMatrix(matrixData, matrixDimensions[1]);
        }
    }

    // Ceiling. Includes the last block.
    int[NUM_DIMS] blockCounts = (matrixDimensions[] + blockSize - 1) / blockSize;
    // Last column or row may be incomplete
    int[NUM_DIMS] lastBlockSizes = matrixDimensions[] - (blockCounts[] - 1) * blockSize;
    int[NUM_DIMS] wholeBlockCountsPerProcess = matrixDimensions[] / (blockSize * computeGridDimensions[]);
    int[NUM_DIMS] blockIndicesOfLastProcess = blockCounts[] - wholeBlockCountsPerProcess[] * computeGridDimensions[] - 1;

    int getWorkSizeAtDimension(size_t dimIndex, int coord)
    {
        int dimWorkSize = wholeBlockCountsPerProcess[dimIndex] * blockSize;

        // Check if the last block is ours
        // Say there are 10 blocks and 4 processes:
        // [][][][][][][][][][]  ()()()()
        // Every process gets 2 blocks each, 2 more blocks remain:
        // [][] ()()()()
        // So if we subtract 10 - 8 we get 2, 
        // and the second process gets the last block.
        // The other processes that are to the right of it essentially get one less block.
        int index = blockIndicesOfLastProcess[dimIndex];
        if (coord < index)
        {
            dimWorkSize += blockSize;
        }
        else if (coord == index)
        {
            dimWorkSize += lastBlockSizes[dimIndex];
        }

        return dimWorkSize;
    }

    int getWorkSizeForProcessAt(int[NUM_DIMS] coords)
    {
        int workSize = 1;
        foreach (dimIndex, coord; coords)
            workSize *= getWorkSizeAtDimension(dimIndex, coord);
        return workSize;
    }


    version (WithActualMatrix)
    {
        int[] buffer = new int[](getWorkSizeForProcessAt(mycoords));

        // Let's make use of RMA, because it's neat.
        mh.MemoryWindow!int matrixWindow;
        scope(exit) matrixWindow.free();
        if (myComputeRank == rootRankInComputeGrid)
            matrixWindow = mh.createMemoryWindow(matrixData, MPI_INFO_NULL, topologyComm);
        else
            matrixWindow = mh.acquireMemoryWindow!int(MPI_INFO_NULL, topologyComm);

        matrixWindow.fence();

        size_t bufferIndex = 0;
        foreach (int rowIndex; iota(mycoords[0] * blockSize, matrixDimensions[0], computeGridDimensions[0] * blockSize))
        foreach (int actualRowIndex; rowIndex..min(rowIndex + blockSize, matrixDimensions[0]))
        foreach (int colIndex; iota(mycoords[1] * blockSize, matrixDimensions[1], computeGridDimensions[1] * blockSize))
        {
            int colRecvSize = min(blockSize, matrixDimensions[1] - colIndex);
            int linearIndexInMatrix = actualRowIndex * matrixDimensions[1] + colIndex;
            matrixWindow.get(
                buffer[bufferIndex .. bufferIndex += colRecvSize], 
                linearIndexInMatrix, rootRankInComputeGrid);
        }
        assert(bufferIndex == buffer.length, "Not enough items");
        matrixWindow.fence();
    }
    else // version (!WithActualMatrix)
    {
        // At root, we allocate the max possible buffer.
        // The first process in the compute grid will always have most load.
        // Since the root always distributes, it must be able to handle a buffer of that size too.
        int[NUM_DIMS] targetProcessCoords = mycoords;
        if (myComputeRank == rootRankInComputeGrid) 
            targetProcessCoords = 0;
        int[] buffer = new int[](getWorkSizeForProcessAt(targetProcessCoords));
        
        // We will send the buffers individually to each process.
        const tag = 10;
        if (myComputeRank == rootRankInComputeGrid)
        {
            // This function may have arbitrary logic.
            // Currently, just fill the buffer with sane random numbers.
            static void prepareBuffer(int[] buffer, int[NUM_DIMS] coords)
            {
                foreach (ref item; buffer)
                    version (SimpleTest)
                        item = (coords[0] + 1) * (coords[1] + 1);
                    else
                        item = uniform!uint % 5 + 1;
            }

            // Another idea is to check out all coords
            // foreach (int[NUM_DIMS] coords; nDimensionalIndices(computeGridDimensions))
            // {
            //     if (coords == mycoords)
            //         continue;
            //     int destRank = mh.getCartesianRank(topologyComm, coords[]);

            // Implement the simpler idea: iterating over ranks rather than coords.
            foreach (int destRank; 0..info.size)
            {
                if (destRank == rootRankInComputeGrid)
                    continue;
                int[NUM_DIMS] coords;
                mh.getCartesianCoordinates(topologyComm, destRank, coords[]);
                int[] sendBuffer = buffer[0..getWorkSizeForProcessAt(coords)];
                prepareBuffer(sendBuffer, coords);
                mh.send(sendBuffer, destRank, tag, topologyComm);
            }
            // Prepare own share.
            buffer = buffer[0..getWorkSizeForProcessAt(mycoords)];
            prepareBuffer(buffer, mycoords);
        }
        else
        {
            mh.recv(buffer, rootRankInComputeGrid, tag, MPI_STATUS_IGNORE, topologyComm);
        }
    }

    version (PrintMatrix)
    {
        import core.thread;
        Thread.sleep(dur!"msecs"(20 * info.rank));
        writeln("Process' ", mycoords, " matrix");
        printAsMatrix(buffer, getWorkSizeAtDimension(1, mycoords[1]));
    }
    
    // The random computation that each process has to do.
    static int crunch(int[] buf)
    {
        // return buf.fold!`a * b`(1);
        return buf.fold!`a + b`(0);
    }
    int result = crunch(buffer);

    writeln(
        "Process ", info.rank,
        " at coordinates ", mycoords,
        " received ", buffer.length, " items.",
        " The crunched amount came out to ", result);

    return 0;
}

static void replace(T, Range)(Range range, T from, T to)
{
    foreach (ref el; range) if (el == from) el = to;
}

struct NDimensionalIndexRange(size_t NDims, TIndex = size_t)
{
    static assert(NDims != 0);
    TIndex[NDims] _limits;
    TIndex[NDims] front = 0;
    bool empty = false;

    void popFront()
    {
        foreach (indexIndex, ref index; front)
        {
            if (index < _limits[indexIndex] - 1)
            {
                index++;
                break;
            }
            index = 0;
            empty = indexIndex == NDims - 1;
        }
    }
}
unittest
{
    auto range = NDimensionalIndexRange!2([2, 2]);
    size_t[2][] expected = [
        [0, 0],
        [1, 0],
        [0, 1],
        [1, 1],
    ];
    import std.algorithm.comparison : equal;
    assert(equal(range, expected));
}

auto nDimensionalIndices(LimitsType : TIndex[NDims], size_t NDims, TIndex)(const ref LimitsType limits)
{
    return NDimensionalIndexRange!(NDims, TIndex)(limits);
}
unittest
{
    int[2] limits = [2, 2];
 	size_t[2][] expected = [
        [0, 0],
        [1, 0],
        [0, 1],
        [1, 1]
    ];   
    import std.algorithm.comparison : equal;
    assert(nDimensionalIndices(limits).equal(expected[]));
}