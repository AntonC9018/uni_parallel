void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    enum flags = mh.FileMode.ReadWrite;
    auto file = mh.openFile!(flags)("array.dat");
    scope(exit) mh.closeFile(&file);

    // auto datatype = mh.createDatatype!(int[32]);

    file.setView!int(0);
    
    int[3] buf;
    file.write(buf[]);
    file.read(buf[]);
}