void main(string[] args)
{
    import mpi;
    import mh = mpihelper;

    auto info = mh.initialize();
    scope(exit) mh.finalize();
}