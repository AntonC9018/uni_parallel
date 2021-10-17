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
        if (info.rank == 0)
            matrixDimensions[0] = uniform!uint % 900 + 100;
        mh.bcast(&matrixDimensions[0], 0);
        matrixDimensions[1] = 1000 - matrixDimensions[0];
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
        if (info.rank == 0)
            blockSize = uniform!uint % 16 + 2;
        mh.bcast(&blockSize, 0);
    }
    
    if (info.rank == 0)
    {
        writeln("Compute grid dimensions: ", computeGridDimensions);
        writeln("Matrix dimensions: ", matrixDimensions);
        writeln("Block size: ", blockSize);
    }

    // Ceiling. Includes the last block.
    int[NUM_DIMS] blockCounts = (matrixDimensions[] + blockSize - 1) / blockSize;
    // Last column or row may be incomplete
    int[NUM_DIMS] lastBlockSizes = matrixDimensions[] - (blockCounts[] - 1) * blockSize;

    // If the block size divides the width (height), the last block will be nonexistent.
    // For the sake of symmetry, we prevent that. 
    // lastBlockSizes[] += blockSize;
    int[NUM_DIMS] wholeBlocksCounts = blockCounts[] / computeGridDimensions[];
    int[NUM_DIMS] wholeBlocksRemainders = blockCounts[] % computeGridDimensions[];
    
    int getWorkSizeForProcessAt(int[NUM_DIMS] coords)
    {
        int workSize = 1;
        foreach (dimIndex, wholeBlocksCount; wholeBlocksCounts)
        {
            int dimWorkSize = wholeBlocksCount * blockSize;

            // Check if the last block is ours
            // Say there are 10 blocks and 4 processes:
            // [][][][][][][][][][]  ()()()()
            // Every process gets 2 blocks each, 2 more blocks remain:
            // [][] ()()()()
            // So if we take the remainder of 10 / 4 we get 2, 
            // and the second process gets the last block.
            // The other processes that are to the right of it essentially get one less block.
            int remainder1 = wholeBlocksRemainders[dimIndex] - 1;
            if (coords[dimIndex] < remainder1)
            {
                dimWorkSize += blockSize;
            }
            else if (coords[dimIndex] == remainder1)
            {
                dimWorkSize += lastBlockSizes[dimIndex];
            }

            workSize *= dimWorkSize;
        }
        return workSize;
    }


    // The random computation that each process has to do.
    static int crunch(int[] buf)
    {
        // return buf.fold!`a * b`(1);
        return buf.fold!`a + b`(0);
    }


    version (WithActualMatrix)
    {
        // Let's make use of RMA, because it's neat.
        mh.MemoryWindow!int matrixWindow;
        scope(exit) matrixWindow.free();
        if (myComputeRank == rootRankInComputeGrid)
            matrixWindow = mh.createMemoryWindow(matrixData, MPI_INFO_NULL, topologyComm);
        else
            matrixWindow = mh.acquireMemoryWindow!int(MPI_INFO_NULL, topologyComm);

        int[] buffer = new int[](getWorkSizeForProcessAt(mycoords));

        matrixWindow.fence();

        size_t bufferIndex = 0;
        foreach (int rowIndex; iota(mycoords[0] * blockSize, matrixDimensions[0], computeGridDimensions[0] * blockSize))
        foreach (int colIndex; iota(mycoords[1] * blockSize, matrixDimensions[1], computeGridDimensions[1] * blockSize))
        foreach (int actualRowIndex; rowIndex..min(rowIndex + blockSize, matrixDimensions[0]))
        {
            int colRecvSize = min(blockSize, matrixDimensions[1] - colIndex);
            int linearIndexInMatrix = actualRowIndex * blockSize + colIndex;
            matrixWindow.get(
                buffer[bufferIndex .. bufferIndex += colRecvSize], 
                linearIndexInMatrix, rootRankInComputeGrid);
        }
        assert(bufferIndex == buffer.length);

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
            prepareBuffer(buffer, mycoords);
        }
        else
        {
            mh.recv(buffer, rootRankInComputeGrid, tag, MPI_STATUS_IGNORE, topologyComm);
        }
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