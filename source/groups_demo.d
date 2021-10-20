/*
    Example execution:

    $ mpirun -np 4 -host "compute-0-0" groups_demo.out
    Process with rank 0 is part of group 1 and the rank in that group is 0
    Process with rank 1 is part of group 1 and the rank in that group is 1
    Process with rank 2 is part of group 2 and the rank in that group is 0
    Process with rank 3 is part of group 2 and the rank in that group is 1
*/
void main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.range : iota, array;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    // Creates an array with ranks from 0 to numProcesses / 2
    int[] firstHalfRanks = iota(0, info.size / 2).array;

    auto commGroup       = mh.getGroup();

    auto groupFirstHalf  = mh.createGroupInclude(commGroup, firstHalfRanks);
    auto firstGroupInfo  = mh.getGroupInfo(groupFirstHalf);

    auto groupSecondHalf = mh.createGroupExclude(commGroup, firstHalfRanks); 
    auto secondGroupInfo = mh.getGroupInfo(groupSecondHalf);

    // Belongs checks if the current process is part of (belongs to) a given group
    if (firstGroupInfo.belongs)
    {
        writeln(
            "Process with rank ", info.rank, 
            " is part of group 1 and the rank in that group is ", firstGroupInfo.rank);
    }
    if (secondGroupInfo.belongs)
    {
        writeln(
            "Process with rank ", info.rank, 
            " is part of group 2 and the rank in that group is ", secondGroupInfo.rank);
    }
}