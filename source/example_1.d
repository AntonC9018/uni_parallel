import mpi;
import mpihelper = mh;
import std.stdio;
import std.string;

void main(string[] args)
{
	MPI_Status status;

    auto info = mh.initialize(args);
    scope(exit) mh.finalize();
    auto processorName = mh.getProcessorName();

    MPI_Comm parentComm;
	MPI_Comm_get_parent(&parentComm);
    if (parentComm == MPI_COMM_NULL)
        writeln("No parent!");

    int groupSize;
	MPI_Comm_remote_size(parentComm, &groupSize);
    if (groupSize != 1)
        writeln("Something's wrong with the parent");

    string processName = info.processName.fromStringZ;

    writeln(
        "Module ", processName, 
        ". Start on the processor rank ", info.rank, 
        " of the node named `", processorName.get, 
        "` of world size ", groupSize);

    // writefln("Module %s. Start on the processor rank %d of the node named `%s` of world size %d",
    //     processName, info.rank, processorName.get, groupSize);
        
    mh.barrier();

    enum incepIdkWhatThisIs = 3;
    // random unique constant
    enum tag = 10;
    int receiveBuffer;

    int nextRank() { return (info.rank + 1) % groupSize; }
    int prevRank() { return (info.rank + groupSize - 1) % groupSize; }

    if (info.rank == incepIdkWhatThisIs)
    {
        mh.send(info.rank, nextRank(), tag);
        mh.recv(receiveBuffer, prevRank(), tag, &status);
    }
    else
    {
        mh.recv(receiveBuffer, prevRank(), tag, &status);
        mh.send(info.rank, nextRank(), tag);
    }

    writeln(
        "== Module `", processName, 
        "`. Proccess number ", info.rank, 
        " at ", processorName.get, 
        " received ", receiveBuffer, " from ", receiveBuffer);
    
    return 0;
}