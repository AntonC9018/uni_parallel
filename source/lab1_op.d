// DATA processed by the processes
static if (0)
{
    enum DataWidth = 6;
    immutable AData = [
        4,  0,  0,  0,  0,  0,
        3,  3,  0,  0,  0,  0,
        2,  2,  2,  0,  0,  0,
        1,  1,  1,  1,  0,  0,
        0,  0,  0,  0,  0,  0,
        -1, -1, -1, -1, -1, -1,
        // -1, -1, -1, -1, -1, -1,
    ];
    immutable BData = [
        0,  2,  1,  0, -1, -2,
        0,  0,  1,  0, -1, -2,
        0,  0,  0,  0, -1, -2,
        0,  0,  0,  0, -1, -2,
        0,  0,  0,  0,  0, -2,
        0,  0,  0,  0,  0,  0,
        // -1, -1, -1, -1, -1, -1,
    ];
}
else static if (1)
{
    enum DataWidth = 3;
    immutable AData = [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ];
    immutable BData = [ 2, 2, 2, 2, 2, 2, 2, 2, 2 ];
}

static assert(AData.length == BData.length);

int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;
    import std.range;
    import std.algorithm;
    import matrix;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    const root = 0;
    bool isRoot() { return info.rank == root; }
    
    int offsetForProcess(int processIndex, int vectorCount)
    {
        return processIndex * vectorCount / info.size;
    }
    enum DataHeight = AData.length / DataWidth;

    // ================================================
    //      Step 1: Distribute rows / columns.
    // ================================================
    // The number of columns = width of the matrix.

    const columnIndexStartA = offsetForProcess(info.rank, DataWidth);
    const columnIndexEndA = offsetForProcess(info.rank + 1, DataWidth);
    const numAllocatedColumnsA = cast(size_t) columnIndexEndA - columnIndexStartA;
    int[] ABuffer = new int[](numAllocatedColumnsA * DataHeight);
    size_t AIndex = 0; 
    foreach (rowIndex; 0..DataHeight)
    foreach (colIndex; 0..numAllocatedColumnsA)
    {
        ABuffer[AIndex++] = AData[rowIndex * DataWidth + columnIndexStartA + colIndex];
    }

    // The number of rows = height of the matrix.
    const rowIndexStartB = offsetForProcess(info.rank, DataHeight);
    const rowIndexEndB = offsetForProcess(info.rank + 1, DataHeight);
    const numAllocatedRowsB = cast(size_t) rowIndexEndB - rowIndexStartB;
    int[] BBuffer = new int[](numAllocatedRowsB * DataWidth);
    size_t BIndex = 0; 
    foreach (rowIndex; 0..numAllocatedRowsB)
    foreach (colIndex; 0..DataWidth)
    {
        BBuffer[BIndex++] = BData[(rowIndex + rowIndexStartB) * DataWidth + colIndex];
    }
    
    static struct MaxIndexVectorInfo
    {
        int size;
        int maxValue;
        int numMaxIndices;
    }

    static struct MaxIndexVector
    {
        MaxIndexVectorInfo* info;
        alias info this;

        size_t sizeOfVectorBuffer() { return cast(size_t) info.size; }
        size_t sizeOfVectorType() { return sizeOfVectorBuffer + MaxIndexVectorInfo.tupleof.length; }
        int[] indexBuffer() { return (cast(int*)(info + 1))[0..sizeOfVectorBuffer]; }
        int[] indices() { return indexBuffer[0..info.numMaxIndices]; }
        
        this(int* basePtr, size_t vectorIndex)
        {
            info = cast(MaxIndexVectorInfo*) (basePtr + vectorIndex * basePtr[0]);
        }
    }

    // The data buffer is assumed to be transposed???
    // So it's shortDimension columns and longDimension rows.
    int[] makeReduceBuffer(size_t longDimension, size_t shortDimension, size_t shortDimensionStretched, const int[] dataBuffer)
    {
        int[] reduceBuffer = new int[]((3 + shortDimensionStretched) * longDimension);
        const vectorLengthInInts = (3 + shortDimensionStretched);

        foreach (vectorIndex; 0..longDimension)
        {
            auto vector = MaxIndexVector(reduceBuffer.ptr, vectorIndex);
            vector.size = cast(int) shortDimensionStretched;
            vector.maxValue = int.min;
            vector.numMaxIndices = 0;

            const startIntIndex = vectorIndex * shortDimension;
            if (dataBuffer.length > startIntIndex)
            {
                auto bufferSlice = dataBuffer[startIntIndex .. startIntIndex + vectorLengthInInts];
                auto maxIndex = dataBuffer.maxIndex();
                
                foreach (valueIndex, value; bufferSlice[maxIndex..$])
                {
                    if (value == vector.maxValue)
                    {
                        vector.indexBuffer[vector.numMaxIndices] = cast(int) (valueIndex % shortDimension);
                        vector.numMaxIndices++;
                    }
                }
            }
            else
            {
                assert(info.rank != 0, "Root cannot reach this case since it has most things");
            }
        }
        return reduceBuffer;
    }

    size_t maxPossibleAllocatedAColumns = (DataWidth + DataWidth - 1) / (info.size);
    int[] reduceBufferA = makeReduceBuffer(DataHeight, maxPossibleAllocatedAColumns, DataWidth, ABuffer);

    size_t maxPossibleAllocatedBRows = (DataHeight + DataHeight - 1) / (info.size);
    int[] reduceBufferB = makeReduceBuffer(DataWidth, maxPossibleAllocatedBRows, DataHeight, BBuffer);

    static void allmaxOperationFunction(int* inVectors, int* inoutVectors, int numInts)
    {
        auto inoutVector0 = MaxIndexVector(inoutVectors, 0);
        size_t numVectors = (numInts / inoutVector0.sizeOfVectorType);
        
        foreach (vectorIndex; 0..numVectors)
        {
            auto inVector    = MaxIndexVector(inVectors, vectorIndex);
            auto inoutVector = MaxIndexVector(inoutVectors, vectorIndex);
            if (inVector.maxValue < inoutVector.maxValue)
                continue;
            if (inVector.maxValue == inoutVector.maxValue)
            {
                inoutVector.indexBuffer[inoutVector.numMaxIndices..inoutVector.numMaxIndices + inVector.numMaxIndices] = 
                    inVector.indices;
                inoutVector.numMaxIndices += inVector.numMaxIndices;
            }
            else
            {
                inoutVector.indices[] = inVector.indices[];
                inoutVector.numMaxIndices = inVector.numMaxIndices;
                inoutVector.maxValue = inVector.maxValue;
            }
        }
    }

    auto op = mh.createOp!allmaxOperationFunction(true);
    scope(exit) mh.freeOp(op);
    mh.intraReduce(reduceBufferA, op, info.rank, 0);
    mh.intraReduce(reduceBufferB, op, info.rank, 0);

    if (info.rank == 0)
    {
        import std.typecons;
        // Tuple!(int, int)[] points;
        foreach (vectorIndex; 0..maxPossibleAllocatedAColumns)
        {
            auto vectorA = MaxIndexVector(reduceBufferA.ptr, vectorIndex);
            foreach (rowIndex; vectorA.inoutIndices[0..vector.numMaxIndices])
            {
                auto vectorB = MaxIndexVector(reduceBufferB.ptr, rowIndex);
                auto matchingIndexPosition = vectorB.indices.countUntil!(i => i == vectorIndex);
                if (matchingIndexPosition < vectorB.numMaxIndices)
                    writeln("Found equilibrium point (", vectorIndex, ", ", rowIndex); 
            }
        }
    }

    // Debugging: print matrices
    static if (1)
    {
        import core.thread;
        if (info.rank == 0)
        {
            writeln("Whole matrix A:");
            printMatrix(AData, DataWidth);
            writeln("Whole matrix B:");
            printMatrix(BData, DataWidth);
            writeln();
        }
        mh.barrier();
    }

    return 0;
}
