module mpihelper;

import mpi;

struct InitInfo
{
    int size;
    int rank;
    char[] _argsBuffer;
    char[][] _argPositions;

    scope char*[] args() { return argv[0..argc]; }
    scope char* processName() { return argv[0]; }
}

InitInfo initialize(string[] programArgs)
{
    InitInfo result;
    with (result)
    {
        import std.string, std.algorithm, std.array;
        int argv = cast(char**) map!toStringz(programArgs).array.ptr;
        char** argc = cast(int) args.length;
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

struct ProcessorName
{
    char[MPI_MAX_PROCESSOR_NAME] _buffer;
    int _size;
    scope inout(char)[] get() @property inout { return _buffer[0.._size]; }
    alias get this;
}

ProcessorName getProcessorName()
{
    ProcessorName result;
    MPI_Get_processor_name(result._buffer.ptr, &result._size);
    return result;
}

// We need this overload because MPI_COMM_WORLD is not a compile-time known constant.
// void barrier() { barrier(MPI_COMM_WORLD); }
void barrier(MPI_COMM comm = MPI_COMM_WORLD) { MPI_Barrier(comm); }


template getMpiType(T)
{
    static if (is(T == int))
        enum getMpiType = MPI_INT;
    else static if (is(T == float))
        enum getMpiType = MPI_FLOAT;
    else static assert(0);
}

template UnrolledCall(alias func)
{
    auto UnrolledCall(T, Args...)(T[] thing, Args args)
    {
    	return func(thing.ptr, cast(int) thing.length, getMpiType!T, args);
    }
    auto UnrolledCall(T, Args...)(T* thing, Args args) if (__traits(compiles, getMpiType!T))
    {
    	return func(thing, 1, getMpiType!T, args);
    }
}

int send(T)(T buffer, int dest, int tag, MPI_COMM comm = MPI_COMM_WORLD)
{
    return UnrolledCall!MPI_Send(buffer, dest, tag, comm);
}

int recv(T)(T buffer, int source, int tag, MPI_STATUS* status, MPI_COMM comm = MPI_COMM_WORLD)
{
    return UnrolledCall!MPI_Recv(buffer, source, tag, comm, status);
}