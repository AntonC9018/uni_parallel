module mpihelper;

import mpi;
import core.runtime : Runtime, CArgs;

struct InitInfo
{
    int size;
    int rank;
    CArgs args;
}

InitInfo initialize()
{
    InitInfo result;
    with (result)
    {
        args = Runtime.cArgs;
        MPI_Init(&args.argc, &args.argv);
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
    inout(char)[] get() @property inout { return _buffer[0.._size]; }
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
void barrier(MPI_Comm comm = MPI_COMM_WORLD) { MPI_Barrier(comm); }

enum MPI_Datatype INVALID_DATATYPE = -1;

// We cannot 
template Datatype(T)
{
    static if (is(T == int))
        alias Datatype = MPI_INT;
    else static if (is(T == float))
        alias Datatype = MPI_FLOAT;
    else static if (is(T == double))
        alias Datatype = MPI_DOUBLE;
    else static if (IsCustomDatatype!T)
    {
        __gshared MPI_Datatype Datatype = INVALID_DATATYPE;
    }
    else static assert(0);
}

enum IsCustomDatatype(T) = is(T : TElement[N], TElement, size_t N) || is(T == struct);
enum IsValidDatatype(T) = is(T : int) || is(T : double) || IsCustomDatatype!T;

// Must have a getter to allow AliasSeq to work.
auto getDatatypeId(T)()
{
    assert(Datatype!T != INVALID_DATATYPE);
    return Datatype!T;
}

void createDatatype(T : TElement[N], TElement, size_t N)()
{
    MPI_Type_contiguous(cast(int) N, Datatype!TElement, &(Datatype!T));
}

void createDatatype(T)() if (is(T == struct))
{
    assert(Datatype!T == INVALID_DATATYPE);

    // We fill these completely in all cases.
    int[T.tupleof.length] counts = void;
    MPI_Aint[T.tupleof.length] offsets = void;
    MPI_Datatype[T.tupleof.length] datatypes = void;

    size_t index = 0;
    static foreach (t; T.tupleof)
    {{
        alias typeId = Datatype!(typeof(t));

        // If it's not a builtin type, create the type.
        // I'm not sure if I should do it like this or not.
        // Another thing, circular dependencies are obviously not allowed.
        static if (IsCustomDatatype!T)
        {
            if (typeId == INVALID_DATATYPE)
                .createDatatype!(typeof(t));
            assert(typeId != INVALID_DATATYPE);
        }

        datatypes[index] = typeId;
        offsets[index] = cast(MPI_Aint) t.offsetof;
        counts[index] = 1;
        index++;
    }}

    MPI_Type_create_struct(cast(int) T.tupleof.length, counts.ptr, offsets.ptr, datatypes.ptr, &(Datatype!T));
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
        alias UnrollBuffer = AliasSeq!(ptr, len, getDatatypeId!T);
    }
    else static if (is(typeof(buffer) == T*, T))
    {
        auto ptr() { return &buffer; }
        alias UnrollBuffer = AliasSeq!(ptr, 1, getDatatypeId!T);
    }
    else static assert(0, "Type `" ~ typeof(buffer).stringof ~ "` must be a pointer or a slice.");
}

/// Buffer can be either a slice or a pointer to the single element.
int send(T)(T buffer, int dest, int tag, MPI_Comm comm = MPI_COMM_WORLD)
{
    return MPI_Send(UnrollBuffer!buffer, dest, tag, comm);
}

/// ditto
int recv(T)(T buffer, int source, int tag, MPI_Status* status = MPI_STATUS_IGNORE, MPI_Comm comm = MPI_COMM_WORLD)
{
    return MPI_Recv(UnrollBuffer!buffer, source, tag, comm, status);
}

/// ditto
int sendRecv(T, U)(
    T sendBuffer, int dest, int sendtag, 
    U recvBuffer, int source, int recvtag, 
    MPI_Status* status = MPI_STATUS_IGNORE, MPI_Comm comm = MPI_COMM_WORLD)
{
    return MPI_Sendrecv(
        UnrollBuffer!sendBuffer, dest,   sendtag, 
        UnrollBuffer!recvBuffer, source, recvtag, 
        comm, status);
}