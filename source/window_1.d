module window_1;

int main()
{
    import mpi;
    import mh = mpihelper;
    import core.thread;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    int buffer;
    mh.MemoryWindow!int memoryWindow = mh.createMemoryWindow(&buffer);
    scope(exit) memoryWindow.free();

    buffer = (info.rank == 0) ? 1 : 0;

    if (info.rank == 1)
    {
        Thread.sleep(dur!"msecs"(500));
    }

    memoryWindow.fence();

    writeln("Process ", info.rank, " entered.");
    // int result;
    // memoryWindow.get(&result, 0, 0);
    memoryWindow.put(&info.rank, 0, 0);
    Thread.sleep(dur!"msecs"(500));
    writeln("Process ", info.rank, " done.");

    memoryWindow.fence();
    writeln("Process ", info.rank, " left.");

    if (info.rank == 0)
    {
        writeln("Value at root = ", buffer);
    }

    return 0;
}