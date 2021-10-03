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
    MPI_Type_commit(&(Datatype!T));
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
    MPI_Type_commit(&(Datatype!T));
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

/// ditto
int bcast(T)(T buffer, int root, MPI_Comm comm = MPI_COMM_WORLD)
{
    return MPI_Bcast(UnrollBuffer!buffer, root, comm);
}

enum gatherTag = 717;

/// https://www.mpi-forum.org/docs/mpi-4.0/mpi40-report.pdf#page=237&zoom=180,55,524
int intraGatherSend(T)(T buffer, int root, MPI_Comm comm = MPI_COMM_WORLD)
{
    return send(buffer, root, gatherTag, comm);
}

/// This should be called by the root process to receive messages from the processes that called `gatherSend()`
/// into the buffer. The rank in InitInfo must correspond to the root rank specified in the `gatherSend()` calls.
/// It will most likely hang infinitely otherwise.
void intraGatherRecv(T)(T[] buffer, in InitInfo info, MPI_Comm comm = MPI_COMM_WORLD)
{
    size_t currentReceiveIndex = 0;
    size_t singleReceiveSize = buffer.length / (info.size - 1);

    assert(buffer.sizeof >= singleReceiveSize);

    foreach (i; info.size)
    {
        if (i != info.rank)
        {
            recv(buffer[currentReceiveIndex .. currentReceiveIndex + singleReceiveSize], i, gatherTag, MPI_STATUS_IGNORE, comm);
            currentReceiveIndex += singleReceiveSize;
        }
    }
} 

/// This is a stupid function because it assumes non-root processes also allocate the array
/// which is just wrong. But otherwise it makes all processes compute what the root would compute.
/// Gather is just meaningless imo.
int gather(T, U)(T sendBuffer, U[] recvBuffer, int root, int groupSize, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias sendBufferTuple = UnrollBuffer!sendBuffer;
    
    // Make sure the recv buffer can hold all input of all processes combined.
    assert(recvBuffer.length / groupSize >= sendBufferTuple[1]);
    // The types must match.
    static assert(__traits(isSame, sendBufferTuple[2], Datatype!U));

    return MPI_Gather(sendBufferTuple, recvBuffer.ptr, sendBufferTuple[1], sendBufferTuple[2], root, comm);
}

/// `nullOrReceive` must be the size of the communicator group if `root == myrank`, otherwise it can be null.
/// This is stupid since one parameter is superfluous most of the time.
int gatherNoAlloc(T)(T[] sendBuffer, T[] nullOrReceive, int root, int myrank, MPI_Comm comm = MPI_COMM_WORLD)
{
    if (root == myrank)
    {
        // Must be receiving.
        assert(nullOrReceive);

        return MPI_Gather(
            sendBuffer.ptr,    sendBuffer.length, Datatype!T, 
            nullOrReceive.ptr, sendBuffer.length, Datatype!T,
            root, comm);
    }
    return MPI_Gather(
        sendBuffer.ptr, sendBuffer.length, Datatype!T,
        null,           sendBuffer.length, Datatype!T,
        root, comm);
}

// template ElementType(T)
// {
//     static if (is(T : E[], E) || is(T : E*, E))
//         alias ElementType = E;
//     else static assert(0);
// }

template ElementType(alias buffer)
{
    alias ElementType = typeof(buffer[0]);
}

/// Allocates `receiveBuffer` if `root` == the rank of the current process. 
/// Executes gather after that. This function makes it impossible to make mistakes with the size of the buffer.
/// If the buffer is already allocated, prefer `gatherNoAlloc()`.
int gatherWithAlloc(T, U)(T sendBuffer, out U[] receiveBuffer, int root, in InitInfo info, MPI_Comm comm = MPI_COMM_WORLD)
{
    static assert(__traits(isSame, ElementType!sendBuffer, U));
    alias sendTuple = UnrollBuffer!sendBuffer;

    if (root == info.rank)
    {
        receiveBuffer = new U[](sendTuple[1] * info.size);
        return MPI_Gather(sendTuple, receiveBuffer.ptr, sendTuple[1], sendTuple[2], root, comm);
    }

    return MPI_Gather(sendTuple, null, sendTuple[1], sendTuple[2], root, comm);
}