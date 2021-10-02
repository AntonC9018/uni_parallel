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
    else static assert(0, "Type `" ~ T.stringof ~ "` is unsupported");
}

/// Unrolls a buffer argument (an array or a pointer to an element) 
/// into a sequence of pointer, length and mpi type.
template UnrollBuffer(alias buffer)
{
    import std.meta : AliasSeq;
    static if (is(typeof(buffer) : T[], T))
    {
        T* ptr() { return buffer.ptr; }
        int len() { return cast(int) buffer.length; } 
        alias UnrollBuffer = AliasSeq!(ptr, len, getMpiType!T);
    }
    else static if (is(typeof(buffer) == T*, T))
    {
        auto ptr() { return &buffer; }
        alias UnrollBuffer = AliasSeq!(ptr, 1, getMpiType!T);
    }
    else static assert(0, "Type `" ~ typeof(buffer).stringof ~ "` must be a pointer or a slice.");
}

/// Buffer can be either a slice or a pointer to the single element.
int send(T)(T buffer, int dest, int tag, MPI_COMM comm = MPI_COMM_WORLD)
{
    return MPI_Send(UnrollBuffer!buffer, dest, tag, comm);
}

/// ditto
int recv(T)(T buffer, int source, int tag, MPI_STATUS* status, MPI_COMM comm = MPI_COMM_WORLD)
{
    return MPI_Recv(UnrollBuffer!buffer, source, tag, comm, status);
}

/// ditto
int sendRecv(T, U)(
    T sendBuffer, int dest, int sendtag, 
    U recvBuffer, int source, int recvtag, 
    MPI_Status* status, MPI_COMM comm = MPI_COMM_WORLD)
{
    return MPI_Sendrecv(
        UnrollBuffer!sendBuffer, dest,   sendtag, 
        UnrollBuffer!recvBuffer, source, recvtag, 
        comm, status);
}