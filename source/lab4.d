/// Same idea as in lab3, but using groups of processes, MPI datatypes and IO API's.
/// `SimpleTest` version flag sets the values to ones easy to interpret (see lab3)
void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.random : uniform;
    import std.algorithm : fold, max;
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

    // The data transfer is made via this file.
    mh.AccessMode accessMode;
    with (mh.AccessMode)
    {
        accessMode = Create;
        if (writeGroupInfo.belongs)
            accessMode |= WriteOnly;
        else
            accessMode |= ReadWrite;
    }
    auto file = mh.openFile(accessMode, "array.dat", topologyComm);
    scope(exit) file.close();

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
    
    // Variable size, because it may not fit completely into the matrix.
    auto myRowType = wholeBlocksDatatype;
    
    auto lastBlockSize1 = layoutInfo.getLastBlockSizeAtDimension(1, mycoords[1]);
    if (lastBlockSize1 > 0)
    {
        auto lastBlockDatatype = mh.createDynamicArrayDatatype!int(lastBlockSize1);
        // Concatenation of the two.
        myRowType = mh.createStructDatatype(
            [&wholeBlocksDatatype, &lastBlockDatatype],
            [0, blockStrides[1] * layoutInfo.wholeBlockCountsPerProcess[1]], 
            [1, 1]);
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
            [0, layoutInfo.wholeBlockCountsPerProcess[0] * blockStrides[0] * matrixDimensions[1]], 
            [1, 1]);
    }
    
    auto viewOffset = mycoords[0] * blockSize * myRowType.diameter + mycoords[1] * blockSize;
    mh.abortIf(myWholeTableType.elementCount != layoutInfo.getWorkSizeForProcessAt(mycoords), "Algorithm is wrong!");

    auto view = mh.createView!int(file);
    view.preallocate(matrixDimensions[0] * matrixDimensions[1]);

    view.bind(myWholeTableType, viewOffset);
    int[] buffer = new int[](myWholeTableType.elementCount);

    void showMatrix()
    {
        Thread.sleep(dur!"msecs"(20 * activeGroupInfo.rank));
        writeln("Matrix of process ", info.rank, " at ", mycoords);
        mh.printAsMatrix(buffer, layoutInfo.getWorkSizeAtDimension(1, mycoords[1]));
    }

    if (writeGroupInfo.belongs)
    {
        foreach (ref element; buffer)
            element = uniform!uint % 5 + 1;
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
        }
        
        int maxElement = buffer.fold!max(int.min);
        mh.intraReduce(&maxElement, MPI_MAX, readGroupInfo.rank, 0, topologyComm);
        if (readGroupInfo.rank == 0)
            writeln("Overall max element is ", maxElement);
    }
    mh.barrier();

}