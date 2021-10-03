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

enum MPI_Datatype INVALID_DATATYPE = null;

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

template BufferInfo(alias buffer)
{
    static if (is(typeof(buffer) : T[], T))
    {
        T* ptr() { return buffer.ptr; }
        int length() { return cast(int) buffer.length; }
    }
    else static if (is(typeof(buffer) == T*, T))
    {
        T* ptr() { return buffer; }
        int length() { return 1; }
    }
    else static assert(0, "Type `" ~ typeof(buffer).stringof ~ "` must be a pointer or a slice.");
    
    alias ElementType = typeof(buffer[0]);
    auto datatype() { return getDatatypeId!ElementType; }
}

/// Unrolls a buffer argument (an array or a pointer to an element) 
/// into a sequence of pointer, length and mpi type.
template UnrollBuffer(alias buffer)
{
    alias Info = BufferInfo!buffer;
    import std.meta : AliasSeq;
    alias UnrollBuffer = AliasSeq!(Info.ptr, Info.length, Info.datatype); 
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
    alias sendBufferInfo = BufferInfo!sendBuffer;
    
    // Make sure the recv buffer can hold all input of all processes combined.
    assert(recvBuffer.length / groupSize >= sendBufferInfo.length);
    // The types must match.
    static assert(__traits(isSame, sendBufferInfo.datatype, Datatype!U));

    return MPI_Gather(UnrollBuffer!sendBuffer, recvBuffer.ptr, sendBufferInfo.length, sendBufferInfo.datatype, root, comm);
}

/// `nullOrReceive` must be the size of the communicator group if `root == myrank`, otherwise it can be null.
/// This is stupid since one parameter is superfluous most of the time.
int gatherNoAlloc(T, U)(T sendBuffer, U[] nullOrReceive, int root, int myrank, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias sendBufferInfo = BufferInfo!sendBuffer;
    static assert(__traits(isSame, sendBufferInfo.datatype, Datatype!U));

    if (root == myrank)
    {
        // Must be receiving.
        assert(nullOrReceive);

        return MPI_Gather(
            sendBufferInfo.ptr, sendBufferInfo.length, Datatype!T, 
            nullOrReceive.ptr,  sendBufferInfo.length, Datatype!T,
            root, comm);
    }
    return MPI_Gather(
        sendBufferInfo.ptr, sendBufferInfo.length, Datatype!T,
        // TODO: this should work with dummy values too, i.e. zeros.
        // https://www.mpi-forum.org/docs/mpi-4.0/mpi40-report.pdf#page=236&zoom=180,65,600
        // "significant only at root".
        null, sendBufferInfo.length, Datatype!T,
        root, comm);
}

// template ElementType(T)
// {
//     static if (is(T : E[], E) || is(T : E*, E))
//         alias ElementType = E;
//     else static assert(0);
// }
// template ElementType(alias buffer)
// {
//     alias ElementType = typeof(buffer[0]);
// }

/// Allocates `receiveBuffer` if `root` == the rank of the current process. 
/// Executes gather after that. This function makes it impossible to make mistakes with the size of the buffer.
/// If the buffer is already allocated, prefer `gatherNoAlloc()`.
int gatherWithAlloc(T, U)(T sendBuffer, out U[] receiveBuffer, int root, in InitInfo info, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias sendBufferInfo = BufferInfo!sendBuffer;
    static assert(__traits(isSame, sendBufferInfo.ElementType, U));

    if (root == info.rank)
    {
        receiveBuffer = new U[](sendBufferInfo.length * info.size);
        return MPI_Gather(UnrollBuffer!sendBuffer, 
            receiveBuffer.ptr, sendBufferInfo.length, sendBufferInfo.datatype, 
            root, comm);
    }

    return MPI_Gather(UnrollBuffer!sendBuffer, null, sendBufferInfo.length, sendBufferInfo.datatype, root, comm);
}


/// Does an inplace scatter as the root process - the process' share of buffer is left in the buffer
int intraScatterSend(T)(T buffer, in InitInfo info, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias sendBufferInfo = BufferInfo!buffer;
    return MPI_Scatter(sendBufferInfo.ptr, sendBufferInfo.length / info.size, sendBufferInfo.datatype,
        MPI_IN_PLACE, 0, null, info.rank, comm);
}

/// Receives data from the root process using MPI_Scatter
int intraScatterRecv(T)(T buffer, int root, MPI_Comm comm = MPI_COMM_WORLD)
{
    return MPI_Scatter(null, 0, null, UnrollBuffer!buffer, root, comm);
}

/// Gets data from all processes into the `recvBuffer` using MPI_Allgather.
/// The buffer is assumed to be long enough to hold data gathered form all other processes,
/// more precisely, `sendBuffer.length * groupSize`.
int allgather(T, U)(const(T) sendBuffer, U[] recvBuffer, MPI_Comm comm = MPI_COMM_WORLD) 
{
    alias sendBufferInfo = BufferInfo!sendBuffer;
    static assert(is(sendBufferInfo.ElementType == U));
    return MPI_Allgather(UnrollBuffer!sendBuffer, recvBuffer.ptr, 
        sendBufferInfo.length, sendBufferInfo.datatype, comm);
}

/// Gets data from all processes into `recvBuffer`, returned as the second argument.
int allgatherAlloc(T, U)(const(T) sendBuffer, out U[] recvBuffer, int groupSize, MPI_Comm comm = MPI_COMM_WORLD) 
{
    alias sendBufferInfo = BufferInfo!sendBuffer;
    static assert(is(sendBufferInfo.ElementType == U));
    recvBuffer = new U[](groupSize * sendBufferInfo.length);
    return MPI_Allgather(UnrollBuffer!sendBuffer, recvBuffer.ptr, 
        sendBufferInfo.length, sendBufferInfo.datatype, comm);
}

template OperationInfo(alias operation)
{
    static if (is(typeof(&operation) : void function(T*, T*, int*), T))
    {
        enum HasRequiredType = true;
        alias RequiredType = T;
        static void func(void* invec, void* inoutvec, int* length, MPI_Datatype* datatype)
        {
            return operation(cast(T*) invec, cast(T*) inoutvec, length);
        }
    }
    else static if (is(typeof(&operation) : void function(T*, T*, int), T))
    {
        enum HasRequiredType = true;
        alias RequiredType = T;
        static void func(void* invec, void* inoutvec, int* length, MPI_Datatype* datatype)
        {
            return operation(cast(T*) invec, cast(T*) inoutvec, *length);
        }
    }
    else static if (is(typeof(&operation) : void function(T[], T[]), T))
    {
        enum HasRequiredType = true;
        alias RequiredType = T;
        static void func(void* invec, void* inoutvec, int* length, MPI_Datatype* datatype)
        {
            return operation((cast(T*) invec)[0..*length], (cast(T*) inoutvec)[0..*length]);
        }
    }
    else
    {
        enum HasRequiredType = false;
        static void func(void* invec, void* inoutvec, int* length, MPI_Datatype* datatype)
        {
            return operation(invec, inoutvec, length, datatype);
        }
    }
}

struct Operation(alias operation)
{
    static if (is(operation == function))
    {
        MPI_Op opHandle;
        mixin OperationInfo!operation;
    }
    else
    {
        enum MPI_Op opHandle = operation;
        enum HasRequiredType = false;
    }
}


// https://www.open-mpi.org/doc/v3.0/man3/MPI_Reduce_local.3.php
// MPI_MAX             maximum
// MPI_MIN             minimum
// MPI_SUM             sum
// MPI_PROD            product
// MPI_LAND            logical and
// MPI_BAND            bit-wise and
// MPI_LOR             logical or
// MPI_BOR             bit-wise or
// MPI_LXOR            logical xor
// MPI_BXOR            bit-wise xor
// MPI_MAXLOC          max value and location
// MPI_MINLOC          min value and location
enum Operation!MPI_MAX       opMax;
enum Operation!MPI_MIN       opMin;
enum Operation!MPI_SUM       opSum;
enum Operation!MPI_PROD      opProd;
enum Operation!MPI_LAND      opLand;
enum Operation!MPI_BAND      opBand;
enum Operation!MPI_LOR       opLor;
enum Operation!MPI_BOR       opBor;
enum Operation!MPI_LXOR      opLxor;
enum Operation!MPI_BXOR      opBxor;
enum Operation!MPI_MAXLOC    opMaxloc;
enum Operation!MPI_MINLOC    opMinloc;

auto createOp(alias operation)(int commute) 
{
    Operation!operation op;
    MPI_Op_create(&(op.func), commute, &(op.handle));
    return op;
}

int freeOp(Op)(Op op)
{
    return MPI_Op_free(&(op.handle));
}

// /// Op must be duck-compatible with Operation!func.
// int intraReduceSend(T, Op)(T buffer, Op op, int root, MPI_Comm comm = MPI_COMM_WORLD)
// {
//     alias bufferInfo = BufferInfo!buffer;
//     static if (Op.HasRequiredType)
//         static assert(is(bufferInfo.ElementType == Op.RequiredType));
//     return MPI_Reduce(bufferInfo.ptr, null, bufferInfo.length, bufferInfo.datatype, op.handle, root, comm);
// }

// /// Must be called by root.
// int intraReduceRecv(T, Op)(T buffer, Op op, int root, MPI_Comm comm = MPI_COMM_WORLD)
// {
//     alias bufferInfo = BufferInfo!buffer;
//     static if (Op.HasRequiredType)
//         static assert(is(bufferInfo.ElementType == Op.RequiredType));
//     return MPI_Reduce(bufferInfo.ptr, MPI_IN_PLACE, bufferInfo.length, bufferInfo.datatype, op.handle, root, comm);
// }

/// Op must be duck-compatible with Operation!func.
int intraReduce(T, Op)(T buffer, Op op, int root, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias bufferInfo = BufferInfo!buffer;
    static assert(!Op.HasRequiredType || is(bufferInfo.ElementType == Op.RequiredType));
    return MPI_Reduce(bufferInfo.ptr, MPI_IN_PLACE, bufferInfo.length, bufferInfo.datatype, op.handle, root, comm);
}