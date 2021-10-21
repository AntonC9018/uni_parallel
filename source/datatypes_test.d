void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    mh.initialize();
    scope(exit) mh.finalize();

    auto zeroLengthArray = mh.createDynamicArrayDatatype!int(0);
    auto twoZeroLengthArraysInAStruct = mh.createStructDatatype(
        [&zeroLengthArray, &zeroLengthArray], [0, 10], [1, 1]);
    
    MPI_Aint extent, lb;
    MPI_Type_get_extent(twoZeroLengthArraysInAStruct, &lb, &extent);
    writeln("Extent: ", extent, " lb: ", lb);
}