void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    enum flags = mh.AccessMode.ReadWrite | mh.AccessMode.Create | mh.AccessMode.DeleteOnClose;
    auto file = mh.openFile!(flags)("array1.dat");
    scope(exit) file.close();

    static if (0)
    {
        // auto datatype = mh.createDatatype!(int[32]);

        file.preallocate(int.sizeof * info.size);
        file.setView!int(MPI_INT, info.rank);
        
        int[] buf = new int[](info.size);
        file.write(&info.rank);
        writeln("Process ", info.rank, " wrote ", info.rank);
        file.sync();
        
        file.setView!int(MPI_INT, 0);
        file.readAt(buf[], 0);
        file.sync();
        writeln("Process ", info.rank, " read ", buf);
        
        int[] buffer32 = new int[](32);
        auto _32intArrayDatatype = mh.createDynamicArrayDatatype(buffer32[]);
        assert(_32intArrayDatatype.elementCount == 32);
    }

    static if (1)
    {
        // Create a typesafe wrapper over file containing ints.
        auto intView = mh.createView!int(file);
        // auto intView = file.createView!int();
        
        // Offset it.
        // Each process writes to the index, corresponding to its rank.
        intView.bind(info.rank);

        // It will work only on ints
        int[] buf = new int[](info.size);
        intView.write(&info.rank);
        intView.sync();

        // Read the entire buffer.
        // Again, will only work with ints.
        // With e.g. floats, it's a compile-time error.
        intView.bind(0);
        intView.read(buf[]);

        writeln("Process ", info.rank, " read ", buf);
    }
}