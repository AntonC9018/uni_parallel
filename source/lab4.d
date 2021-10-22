/// Same idea as in lab3, but using groups of processes, MPI datatypes and IO API's.
/// `SimpleTest` version flag sets the values to ones easy to interpret (see lab3)
void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.random : uniform;
    import std.algorithm : fold;
    import std.range : iota, array;
    import core.thread;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    // Make sure there's an even number of processes.
    mh.abortIf(info.size & 1, "The number of processes must be even.");

    // Initialize variables
    int[2] matrixDimensions;
    matrixDimensions[0] = mh.bcastUniform!uint(10, 30);
    matrixDimensions[1] = 40 - matrixDimensions[0];

    int[2] computeGridDimensions;
    mh.getDimensions(info.size / 2, computeGridDimensions[]); 

    int blockSize = mh.bcastUniform!uint(2, 4);

    version (SimpleTest)
    {
        mh.abortIf(info.size != 12, "For the simple test the expected number of processes is 12");
        matrixDimensions[] = [9, 9];
        computeGridDimensions[] = [2, 3];
        blockSize = 2;
    }

    if (info.rank == 0)
    {
        writeln("MatrixDimensions: ", matrixDimensions);
        writeln("ComputeGridDimensions: ", computeGridDimensions);
        writeln("BlockSize: ", blockSize);
    }

    // Split the processes in 2 groups.
    MPI_Group worldGroup  = mh.getGroup();
    int[] writeGroupRanks = iota(info.size / 2).array;

    auto writeGroup     = mh.createGroupInclude(worldGroup, writeGroupRanks);
    auto writeComm      = mh.createComm(MPI_COMM_WORLD, writeGroup);
    auto writeGroupInfo = mh.getGroupInfo(writeGroup);
    scope(exit) mh.free(&writeGroup);

    auto readGroup      = mh.createGroupExclude(worldGroup, writeGroupRanks);
    auto readComm       = mh.createComm(MPI_COMM_WORLD, readGroup);
    auto readGroupInfo  = mh.getGroupInfo(readGroup);
    scope(exit) mh.free(&readGroup);
    
    // Create the active topology. Write for writes, read for reads.
    int[2] repeats = 0;
    auto activeComm      = writeGroupInfo.belongs ? writeComm : readComm;
    auto activeGroupInfo = writeGroupInfo.belongs ? writeGroupInfo : readGroupInfo;
    auto topologyComm    = mh.createCartesianTopology(computeGridDimensions[], repeats[], activeComm);
    
    int[2] mycoords = void;
    mh.getCartesianCoordinates(topologyComm, activeGroupInfo.rank, mycoords[]);

    version (CyclicInitialization)
    {
        // Create the datatype used for interpreting the file
        auto layoutInfo = mh.getCyclicLayoutInfo(matrixDimensions, computeGridDimensions, blockSize);
        int[2] blockStrides = blockSize * computeGridDimensions[];

        foreach (dimIndex, numWholeBlocks; layoutInfo.wholeBlockCountsPerProcess)
        {
            import std.format;
            mh.abortIf(numWholeBlocks == 0, 
                "Please select a higher dimension %s of the matrix. 
                The program does not support the case when there is not at least 1 whole block per each process."
                    .format(dimIndex == 0 ? "Y" : "X"));
        }

        // All blocks but the last.
        auto wholeBlocksDatatype = mh.createVectorDatatype!int(
            blockSize, layoutInfo.wholeBlockCountsPerProcess[1], blockStrides[1]);
        auto myRowType = wholeBlocksDatatype;
        
        // Variable size, because it may not fit completely into the matrix.
        auto lastBlockSize1 = layoutInfo.getLastBlockSizeAtDimension(1, mycoords[1]);
        if (lastBlockSize1 > 0)
        {
            auto lastBlockDatatype = mh.createDynamicArrayDatatype!int(lastBlockSize1);
            // Concatenation of the two.
            myRowType = mh.createStructDatatype(
                [&wholeBlocksDatatype, &lastBlockDatatype],
                [0, blockStrides[1] * layoutInfo.wholeBlockCountsPerProcess[1]]);
        }
        myRowType = mh.resizeDatatype(myRowType, matrixDimensions[1]);

        // All rows but the last.
        auto wholeRowsDatatype = mh.createVectorDatatype(
            myRowType, blockSize, layoutInfo.wholeBlockCountsPerProcess[0], blockStrides[0]);
        auto myWholeTableType = wholeRowsDatatype;

        auto lastBlockSize0 = layoutInfo.getLastBlockSizeAtDimension(0, mycoords[0]);
        if (lastBlockSize0 > 0)
        {
            // The last rows may be incomplete.
            auto lastRowsDatatype = mh.createDynamicArrayDatatype(myRowType, lastBlockSize0);

            // Concatenate the rows into a table.
            myWholeTableType = mh.createStructDatatype(
                [&wholeRowsDatatype, &lastRowsDatatype],
                [0, layoutInfo.wholeBlockCountsPerProcess[0] * blockStrides[0] * matrixDimensions[1]]);
        }
        
        auto viewOffset = mycoords[0] * blockSize * matrixDimensions[1] + mycoords[1] * blockSize;
        mh.abortIf(myWholeTableType.elementCount != layoutInfo.getWorkSizeForProcessAt(mycoords), "Algorithm is wrong!");
    }
    else
    {
        // Share the randomly generated layout with all processes.
        import matrix_random_layout;
        RandomWorkLayout layout;
        const numSlots = activeGroupInfo.size;
        const averageNumberOfSubmatricesPerProcess = 4; 
        const numBuckets = numSlots * averageNumberOfSubmatricesPerProcess;
        mh.createDatatype!Bucket();
        mh.createDatatype!Slot();
        if (info.rank == 0)
        {
            layout = getRandomWorkLayout(matrixDimensions, numSlots, numBuckets);
        }
        else
        {
            layout.buckets = new Bucket[](numBuckets);
            layout.slots = new Slot[](numSlots);
        }
        mh.bcast(layout.buckets, 0);
        mh.bcast(layout.slots, 0);

        int mySlotIndex = activeGroupInfo.rank;
        MPI_Datatype[] datatypeIds;
        MPI_Aint[] offsets;
        int[] blockLengths;

        mh.TypedDynamicDatatype!int myWholeTableType;
        myWholeTableType.diameter = matrixDimensions.fold!`a * b`(1);

        int currentBucketIndex = layout.slots[mySlotIndex].firstBucketIndex;
        while (currentBucketIndex != -1)
        {
            const(Bucket)* bucket = &layout.buckets[currentBucketIndex];
            auto dt = mh.createDynamicArrayDatatype!int(bucket.dimensions[1]);

            myWholeTableType.elementCount += dt.elementCount * bucket.dimensions[0];

            foreach (rowOffset; 0..bucket.dimensions[0])
            {
                datatypeIds ~= dt.id;
                offsets ~= cast(MPI_Aint) (((rowOffset + bucket.coords[0]) * matrixDimensions[1] + bucket.coords[1]) * int.sizeof);
                blockLengths ~= 1;
            }

            currentBucketIndex = bucket.nextBucketIndex;
        }

        // NOTE: 
        // Apparently, the arrays must be sorted.
        // Also, no overlapping gaps are allowed.
        // So if two vectors overlap, it won't work correcty (it segfaults).
        // Apparently, the gaps from the vectors override the actual data within other vectors,
        // so it segfaults, because the write buffer is too long.
        size_t[] sortedIndices = iota(offsets.length).array;
        import std.algorithm : sort, map;
        sortedIndices.sort!((a, b) => offsets[a] < offsets[b]);
        offsets     = sortedIndices[].map!(index => offsets[index]).array;
        datatypeIds = sortedIndices[].map!(index => datatypeIds[index]).array;

        myWholeTableType.id = mh.createStructDatatype(datatypeIds, offsets, blockLengths);
        int viewOffset = 0;

        void printMask()
        {
            writeln("Process mask:");
            int[] maskBuffer = new int[](matrixDimensions[].fold!`a * b`(1));
            foreach (slotIndex, slot; layout.slots)
            {
                int bucketIndex = slot.firstBucketIndex;
                while (bucketIndex != -1)
                {
                    const(Bucket)* bucket = &layout.buckets[bucketIndex];
                    foreach (rowIndex; 0..bucket.dimensions[0])
                    foreach (colIndex; 0..bucket.dimensions[1])
                    {
                        int index = (rowIndex + bucket.coords[0]) * matrixDimensions[1] + colIndex + bucket.coords[1];
                        maskBuffer[index] = cast(int) slotIndex;
                    }
                    bucketIndex = bucket.nextBucketIndex;
                }
            }
            mh.printAsMatrix(maskBuffer, matrixDimensions[1]);
        }

        if (info.rank == 0)
            printMask();
    }

    // The data transfer is made via this file.
    mh.AccessMode accessMode;
    with (mh.AccessMode)
    {
        accessMode = Create | DeleteOnClose;
        if (writeGroupInfo.belongs)
            accessMode |= WriteOnly;
        else
            accessMode |= ReadWrite;
    }
    auto file = mh.openFile(accessMode, "array.dat", topologyComm);
    scope(exit) file.close();

    auto view = mh.createView!int(file);
    view.preallocate(matrixDimensions[0] * matrixDimensions[1]);
    view.bind(myWholeTableType, viewOffset);

    int[] buffer = new int[](myWholeTableType.elementCount);

    void showMatrix()
    {
        Thread.sleep(dur!"msecs"(20 * activeGroupInfo.rank));
        writeln("Matrix of process ", info.rank, " at ", mycoords);
        version (CyclicInitialization)
            mh.printAsMatrix(buffer, layoutInfo.getWorkSizeAtDimension(1, mycoords[1]));
        else
            writeln(buffer);
    }

    if (writeGroupInfo.belongs)
    {
        foreach (ref element; buffer)
            element = uniform!uint % 50 + 1;
            // element = info.rank;
        showMatrix();
        view.write(buffer[]);
        view.sync();
    }
    mh.barrier();

    if (readGroupInfo.belongs)
    {
        view.sync();
        view.read(buffer[]);
        showMatrix();

        view.bind(0);
        if (readGroupInfo.rank == 0)
        {
            Thread.sleep(dur!"msecs"(20 * readGroupInfo.size));
            writeln("Entire matrix: ");
            int[] bufferAll = new int[](matrixDimensions[].fold!`a * b`(1));
            view.read(bufferAll[]);
            mh.printAsMatrix(bufferAll, matrixDimensions[1]);
            
            version (CyclicInitialization) {} else
                printMask();
        }

        import std.algorithm : maxElement;
        int maxElem = buffer.maxElement;
        mh.intraReduce(&maxElem, MPI_MAX, readGroupInfo.rank, 0, topologyComm);
        if (readGroupInfo.rank == 0)
            writeln("Overall max element is ", maxElem);
    }
    mh.barrier();
}