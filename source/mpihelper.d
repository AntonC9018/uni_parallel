module mpihelper;

import mpi;

struct InitInfo
{
    int size;
    int rank;
    int argc;
    char** argv;

    char*[] args() { return argv[0..argc]; }
}

InitInfo initialize(string[] programArgs)
{
    InitInfo result;
    with (result)
    {
        import std.string, std.algorithm, std.array;
        argv = cast(char**) map!toStringz(programArgs).array.ptr;
        argc = cast(int) args.length;
        MPI_Init(&argc, &argv);
        MPI_Comm_size(MPI_COMM_WORLD, &size);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    }
    return result;
}

void finalize()
{
    MPI_Finalize();
}