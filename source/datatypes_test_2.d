module datatypes_test_2;



void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    mh.initialize();
    scope(exit) mh.finalize();

    int blocksize = 1;
    MPI_Aint displacement = 4;
    MPI_Datatype type = MPI_INT;
    MPI_Datatype testStructType;
    MPI_Type_create_struct(1, &blocksize, &displacement, &type, &testStructType);
    
    MPI_Aint extent, lb;
    MPI_Type_get_extent(testStructType, &lb, &extent);
    writeln("Extent: ", extent, " lb: ", lb);
}