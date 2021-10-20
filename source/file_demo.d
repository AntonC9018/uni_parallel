void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    // Incorrect flag combinations will fail at compile time.
    // The file must be set to a specific mode initially (read, write etc.). 
    // I have not made a "generic" file wrapper, look into the code youself if you need that.
    enum flags = mh.AccessMode.ReadWrite | mh.AccessMode.Create | mh.AccessMode.DeleteOnClose;
    auto file = mh.openFile!(flags)("array1.dat");
    scope(exit) file.close();

    static if (0)
    {
        // This part is type unsafe and not very convenient.
        // For example, file.read() allows reading floats, even if the view is set to ints.
        // Below, see the typesafe version, with view wrappers.

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
    }

    static if (1)
    {
        /* Example output:
        
            $ mpirun -np 5 -host "compute-0-0" file_demo.out
            Process 1 read [0, 1, 2, 3, 4]
            Process 2 read [0, 1, 2, 3, 4]
            Process 3 read [0, 1, 2, 3, 4]
            Process 4 read [0, 1, 2, 3, 4]
            Process 0 read [0, 1, 2, 3, 4]
        */

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