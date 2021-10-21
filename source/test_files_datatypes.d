void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    
    MPI_Datatype datatype1;
    {
        int[3] blockLengths = 1;
        int[3] displacements = [0, info.size, info.size * 2];
        MPI_Type_indexed(3, blockLengths.ptr, displacements.ptr, MPI_INT, &datatype1);
        MPI_Type_commit(&datatype1);
    }

    MPI_Datatype datatype2;
    {
        int blockLength = 1;
        int[3] displacements = [0, info.size, info.size * 2];
        MPI_Type_create_indexed_block(3, blockLength, displacements.ptr, MPI_INT, &datatype2); 
        MPI_Type_commit(&datatype2);
    }

    MPI_Datatype datatype3;
    {
        int blockLength = 1;
        int count = 3;
        int stride = info.size;
        MPI_Type_vector(count, blockLength, stride, MPI_INT, &datatype3);
        MPI_Type_commit(&datatype3);
    }

    // MPI_Datatype datatype3
    // {
    //     MPI_Type_create_indexed_block(
    //     MPI_Type_contiguous(
    // }

    enum flags = mh.AccessMode.Create | mh.AccessMode.ReadWrite | mh.AccessMode.DeleteOnClose;
    auto file = mh.openFile!flags("array.dat");
    scope(exit) file.close();
    
    void test(MPI_Datatype datatype)
    {
        auto view = mh.createView!int(file);
        view.preallocate(info.size * 3);

        view.bind(datatype, info.rank);
        int[3] bufferWrite; 
        foreach (i; 0..3)
            bufferWrite[i] = (i) * 10 + info.rank * 1;
        // NOTE: 
        // This actually moves the buffer to the very end.
        // So you must reabind it when you read. Otherwise you'd get trash.
        view.write(bufferWrite[]);

        view.sync();

        int[] readBuffer = new int[](3);
        view.bind(datatype, info.rank);
        view.read(readBuffer[]);
        writeln("Process ", info.rank, " received (part) ", readBuffer);

        view.bind(0);
        int[] readBuffer2 = new int[](9);
        view.read(readBuffer2[]);
        writeln("Process ", info.rank, " received (whole) ", readBuffer2);

        mh.barrier();
    }

//    test(datatype1);
    // test(datatype2);
    test(datatype3);

    // auto view = mh.createView!int(file);
    // view.bind(info.rank * 3);
    // view.preallocate(info.size * 3);
    // int[3] bufferWrite = info.rank;
    // view.write(bufferWrite[]);
    // view.sync();
    // view.bind(0);
    // int[] readBuffer = new int[](info.size * 3);
    // view.read(readBuffer[]);
    // writeln("Process ", info.rank, " recieved ", readBuffer);


    // TODO: Future plans for datatypes and lab 4
    enum blockSize = 2;
    int[2] blockCounts = 2;
    int[2] blockStrides = 6;
    int[2] lastBlockSizes = 1;
    
    auto wholeBlockDatatype = mh.createVectorDatatype!int(blockSize, blockCounts[0], blockStrides[0]);
    auto lastBlockDatatype = mh.createDynamicArrayDatatype!int(lastBlockSize[0]);
    auto myRowType = mh.createStructDatatype(
        [wholeBlockDatatype, lastBlockDatatype], 
        [mycoords[1] * blockSize, wholeBlockDatatype.diameter + mycoords[1] * blockSize]);
    auto wholeRowsDatatype = mh.createVectorDatatype(myRowType, blockSize, blockCounts[1], blockStrides[1]);
    auto myWholeTableType = mh.createStructDatatype(
        [wholeRowsDatatype, myRowType], 
        [0, wholeRowsDatatype.diameter]);
    
    auto view = mh.createView!int(file);
    view.bind(myWholeTableType, 0);
    
    auto buffer = new int[](myWholeTable.dataSize);
    if (writing) view.write(buffer[]);
    mh.barrier(MPI_COMM_WORLD);
    view.sync();
    if (reading) view.read(buffer[]);
}