module matrix_random_layout;

/// Aka a submatrix
struct Bucket
{
    int[2] coords;
    int[2] dimensions;
    int nextBucketIndex;
}

/// Aka a process' submatrices linked list
struct Slot
{
    /// Index into the buckets array where the linked list starts.
    int firstBucketIndex = -1;
    int totalArea = 0;

    int opCmp(const Slot other) const
    {
        return totalArea - other.totalArea;
    }
}

struct RandomWorkLayout
{
    Bucket[] buckets;
    Slot[] slots;
}

import std.random;
import std.range : iota;
import std.algorithm;

/// Splits a matrix (a `dimensions[0]` by `dimensions[1]` area) into `numBuckets` submatrices.
/// The submatrices are distributed in `numSlots` slots in such a way that every slot is
/// assigned an approximately equal amount of work size (load balancing).
/// I think it is less stable (balances the load less) but more random when passed 
/// the template argument `SplitLargestFirst` = true.
/// It may fail when passed too big a bucket count, but it's highly unlikely.
RandomWorkLayout getRandomWorkLayout(bool SplitLargestFirst = false)(
    int[2] dimensions, size_t numSlots, size_t numBuckets)
{
    Bucket[] bucketAllocator = new Bucket[](numBuckets);
    size_t nextBucketIndex = 0;
    bucketAllocator[nextBucketIndex++] = Bucket([0, 0], dimensions, -1);

    Slot[] slots = new Slot[](numSlots);
    slots[0] = Slot(0, dimensions.fold!`a * b`(1));

    while (nextBucketIndex < bucketAllocator.length)
    {
        auto totalAreas = slots[].map!`a.totalArea`;
        size_t minIndex = totalAreas.minIndex;
        size_t maxIndex = totalAreas.maxIndex;

        import std.math : abs, floor;
        float randomSize = (-abs(uniform01!float * 2 - 1) + 1);
        uint randomDimensionIndex = uniform!uint % 2;
        bool whetherMaxBucketKeepsSecondHalf = cast(bool) (uniform!uint % 2);

        int currentBucketIndex = slots[maxIndex].firstBucketIndex;
        const(Bucket)* currentBucket() { return &bucketAllocator[currentBucketIndex]; }
        int selectedBucketIndex = -1;

        bool changedDirection = false;

        int mapSize(const(Bucket*) bucket) 
        { 
            return cast(int) floor(randomSize * (bucket.dimensions[randomDimensionIndex] - 2)) + 1; 
        }

        int getAreaChange(const(Bucket*) bucket, int sideLength)
        {
            int areaChange = bucket.dimensions[1 - randomDimensionIndex];
            if (whetherMaxBucketKeepsSecondHalf)
                areaChange *= sideLength;
            else
                areaChange *= bucket.dimensions[randomDimensionIndex] - sideLength;
            return areaChange;
        }
        
        void endIteration()
        {
            if (currentBucket.nextBucketIndex == -1 && selectedBucketIndex == -1)
            {
                assert(currentBucket.dimensions[randomDimensionIndex] == 1);
                assert(!changedDirection);
                changedDirection = true;

                randomDimensionIndex = 1 - randomDimensionIndex;
                currentBucketIndex = slots[maxIndex].firstBucketIndex;
            }
            else
            {
                currentBucketIndex = currentBucket.nextBucketIndex;
            }
        }

        static if (SplitLargestFirst)
            int largestBucketArea = 0;
        else
            int smallestAreaDifference = int.max;
                
        while (currentBucketIndex != -1)
        {
            // Cannot split any more
            if (currentBucket.dimensions[randomDimensionIndex] == 1)
            {
                endIteration();
                continue;
            }

            static if (SplitLargestFirst)
            {
                const area = currentBucket.dimensions.fold!`a * b`(1);
                if (area > largestBucketArea)
                {
                    largestBucketArea = area;
                    selectedBucketIndex = currentBucketIndex;
                }
            }
            else
            {
                const sideLength = mapSize(currentBucket);
                const areaChange = getAreaChange(currentBucket, sideLength);

                const updatedAreaMax = slots[maxIndex].totalArea - areaChange;
                const updatedAreaMin = slots[minIndex].totalArea + areaChange;
                const areaDifference = abs(updatedAreaMax - updatedAreaMin);
                if (areaDifference < smallestAreaDifference)
                {
                    smallestAreaDifference = areaDifference;
                    selectedBucketIndex = currentBucketIndex;
                }
            }

            endIteration();
        }

        assert(selectedBucketIndex != -1);
        assert(selectedBucketIndex < nextBucketIndex);
        Bucket* selectedBucket = &bucketAllocator[selectedBucketIndex];

        const newBucketLength = mapSize(selectedBucket);
        assert(newBucketLength >= 1);
        const areaChange = getAreaChange(selectedBucket, newBucketLength);
        assert(areaChange > 0);

        slots[maxIndex].totalArea -= areaChange;
        assert(slots[maxIndex].totalArea > 0);
        slots[minIndex].totalArea += areaChange;
        assert(slots[minIndex].totalArea > 0);

        Bucket newBucket = *selectedBucket;
        int shiftAmount = selectedBucket.dimensions[randomDimensionIndex] - newBucketLength;
        if (whetherMaxBucketKeepsSecondHalf)
        {
            newBucket.coords[randomDimensionIndex] += shiftAmount;
            newBucket.dimensions[randomDimensionIndex] = newBucketLength;
            selectedBucket.dimensions[randomDimensionIndex] -= newBucketLength;
        }
        else
        {
            selectedBucket.coords[randomDimensionIndex] += shiftAmount;
            newBucket.dimensions[randomDimensionIndex] = shiftAmount;
            selectedBucket.dimensions[randomDimensionIndex] = newBucketLength;
        }
        newBucket.nextBucketIndex = slots[minIndex].firstBucketIndex;
        slots[minIndex].firstBucketIndex = cast(int) nextBucketIndex;
        bucketAllocator[nextBucketIndex++] = newBucket;
    }

    return RandomWorkLayout(bucketAllocator, slots);
}

unittest
{
    int[2] dimensions = [8, 8];
    auto layout = getRandomWorkLayout(dimensions, 5, 16);

    int[64] buffer = -1;
    foreach (slotIndex, slot; layout.slots)
    {
        int bucketIndex = slot.firstBucketIndex;
        while (bucketIndex != -1)
        {
            const(Bucket)* bucket = &layout.buckets[bucketIndex];
            foreach (rowIndex; iota(bucket.dimensions[0]).map!(y => y + bucket.coords[0]))
            foreach (colIndex; iota(bucket.dimensions[1]).map!(x => x + bucket.coords[1]))
            {
                int index = rowIndex * dimensions[1] + colIndex;
                assert(buffer[index] == -1);
                buffer[index] = cast(int) slotIndex;
            }
            bucketIndex = bucket.nextBucketIndex;
        }
    }
    static void printAsMatrix(int[] data, int width)
    {
        import std.stdio : writef, writeln;
        import std.range : iota;
        
        foreach (rowStartIndex; iota(0, data.length, width))
        {
            foreach (i; 0..width)
                writef("%3d", data[rowStartIndex + i]);
            writeln();
        }
    }
    printAsMatrix(buffer[], dimensions[1]);
    import std.stdio;
    writeln(layout.slots[].map!(a => a.totalArea));

    foreach (item; buffer)
        assert(item != -1);
}
