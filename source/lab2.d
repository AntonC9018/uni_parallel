
int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.algorithm : count, countUntil, any;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    int[3] dimensions; 
    mh.getDimensions(info.size, dimensions[]);
    if (info.rank == 0)
        writeln("Computed dimensions: ", dimensions);
    
    auto numberOfOnes = dimensions[].count(1);
    // We cannot do the snake thing if there is only one non-1 dimension
    mh.abortIf(numberOfOnes >= 2, "At least two of the dimensions were 1. Please select a non-prime number.");

    int[3] dimensionsLoopAround = 0;
    MPI_Comm topologyComm = mh.createCartesianTopology(dimensions[], dimensionsLoopAround[]);

    size_t fixedAxisIndex;
    int fixedCoordinate;
    // The dimension that had that one is selected
    if (numberOfOnes == 1)
    {
        fixedAxisIndex = dimensions[].countUntil(1);
        fixedCoordinate = 0;
    }
    else
    {
        int sideIndex;
        if (info.rank == 0)
        {
            import std.random : uniform;
            sideIndex = uniform!size_t % 6;
        }
        mh.bcast(&sideIndex, 0);
        
        // `sideIndex` will be in range [0..6]
        // for 0, 1 the axis is 0, x
        // for 2, 3 the axis is 1, y
        // for 4, 5 the axis is 2, z 
        fixedAxisIndex = sideIndex / 2;
        // Whether the side is max (or min) along fixedAxisIndex
        bool isMax = sideIndex % 2 == 0;

        fixedCoordinate = isMax ? (dimensions[fixedAxisIndex] - 1) : 0;
    }

    if (info.rank == 0)
        writeln("Selected fixed axis index is ", fixedAxisIndex, " with coordinate ", fixedCoordinate);

    // These two will change
    int[2] otherAxes = [(fixedAxisIndex + 1) % 3, (fixedAxisIndex + 2) % 3];

    // Get my own coords
    int[3] mycoords;
    mh.getCartesianCoordinates(topologyComm, info.rank, mycoords[]);

    // We only continue if we're part of that side
    if (mycoords[fixedAxisIndex] != fixedCoordinate)
        return 0;

    // And we must not be in the center of that side.
    // We quit if none of the coords are at the side.
    if (!otherAxes[].any!(axisIndex => 
        mycoords[axisIndex] == 0 || mycoords[axisIndex] == dimensions[axisIndex] - 1))
    {
        return 0;
    }
    
    int row = mycoords[otherAxes[0]];
    int col = mycoords[otherAxes[1]];
    int[2] otherDimsLengths = [dimensions[otherAxes[0]], dimensions[otherAxes[1]]];
    int lastRowIndex = otherDimsLengths[0] - 1;
    int lastColIndex = otherDimsLengths[1] - 1;

    int[2] getNextDirection()
    {
        if (row == 0 && col < lastColIndex)
            return [0, 1];
        if (row == lastRowIndex && col > 0)
            return [0, -1];
        if (col == 0 && row > 0)
            return [-1, 0];
        // else if (col == lastColIndex && row < lastRowIndex)
            return [1, 0];
    }
    int[2] getPrevDirection()
    {
        if (row == 0 && col > 0)
            return [0, -1];
        if (row == lastRowIndex && col < lastColIndex)
            return [0, 1];
        if (col == 0 && row < lastRowIndex)
            return [1, 0];
        // else if (col == lastColIndex && row > 0)
            return [-1, 0];
    }

    int[2] nextDirection = getNextDirection();
    int[3] nextNodeCoords;
    nextNodeCoords[fixedAxisIndex] = fixedCoordinate;
    nextNodeCoords[otherAxes[0]] = row + nextDirection[0];
    nextNodeCoords[otherAxes[1]] = col + nextDirection[1];

    int[2] prevDirection = getPrevDirection();
    int[3] prevNodeCoords;
    prevNodeCoords[fixedAxisIndex] = fixedCoordinate;
    prevNodeCoords[otherAxes[0]] = row + prevDirection[0];
    prevNodeCoords[otherAxes[1]] = col + prevDirection[1];
    
    int nextRank = mh.getCartesianRank(topologyComm, nextNodeCoords[]);
    int prevRank = mh.getCartesianRank(topologyComm, prevNodeCoords[]);

    int sentMessage = info.rank;
    int receivedMessage;
    mh.sendRecv(&sentMessage, nextRank, 12, &receivedMessage, prevRank, 12);

    writeln(
        "Process with rank ", info.rank,
        " and coordinates ", mycoords, 
        " sent message ", sentMessage, 
        " to process ", nextRank,
        " at coordinates ", nextNodeCoords,
        " and received ", receivedMessage, 
        " from ", prevRank,
        " at coordinates ", prevNodeCoords);

    return 0;
}