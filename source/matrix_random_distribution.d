module matrix_random_distribution;

struct Bucket
{
    int[2] coords;
    int[2] dimensions;
    int nextBucketIndex;
}

struct Slot
{
    int firstBucketIndex = -1;
    int totalArea = 0;

    int opCmp(const Slot other) const
    {
        return totalArea - other.totalArea;
    }
}

struct DistributionResult
{
    Bucket[] buckets;
    Slot[] slots;
}

import std.random;
import std.range : iota;
import std.algorithm;

DistributionResult getRandomWorkLayout(int[2] dimensions, size_t numSlots, size_t numBuckets, ref Random rnd = rndGen)
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

        uint randomSize = uniform!uint;
        uint randomDimensionIndex = uniform!uint % 2;

        int currentBucketIndex = slots[maxIndex].firstBucketIndex;
        int smallestAreaDifference = int.max;
        int smallestAreaDifferenceBucketIndex = -1;

        bool changedDirection = false;

        while (currentBucketIndex != -1)
        {
            Bucket* bucket = &bucketAllocator[currentBucketIndex];

            void endIteration()
            {
                currentBucketIndex = bucket.nextBucketIndex;

                if (currentBucketIndex == -1 && smallestAreaDifferenceBucketIndex == -1)
                {
                    assert(bucket.dimensions[randomDimensionIndex] == 1);
                    assert(!changedDirection);
                    changedDirection = true;

                    randomDimensionIndex = 1 - randomDimensionIndex;
                    currentBucketIndex = slots[maxIndex].firstBucketIndex;
                }
            }

            // Cannot split any more
            if (bucket.dimensions[randomDimensionIndex] == 1)
            {
                endIteration();
                continue;
            }

            const sideLength = randomSize % (bucket.dimensions[randomDimensionIndex] - 1) + 1;
            int areaChange = bucket.dimensions[1 - randomDimensionIndex] * sideLength;

            const updatedAreaMax = slots[maxIndex].totalArea - areaChange;
            const updatedAreaMin = slots[minIndex].totalArea + areaChange;
            import std.math : abs;
            const areaDifference = abs(updatedAreaMax - updatedAreaMin);
            if (areaDifference < smallestAreaDifference)
            {
                smallestAreaDifference = areaDifference;
                smallestAreaDifferenceBucketIndex = currentBucketIndex;
            }

            endIteration();
        }

        assert(smallestAreaDifferenceBucketIndex != -1);
        assert(smallestAreaDifferenceBucketIndex < nextBucketIndex);
        Bucket* smallestDifferenceBucket = &bucketAllocator[smallestAreaDifferenceBucketIndex];

        const newBucketLength = randomSize % (smallestDifferenceBucket.dimensions[randomDimensionIndex] - 1) + 1;
        assert(newBucketLength >= 1);
        const areaChange = smallestDifferenceBucket.dimensions[1 - randomDimensionIndex] * newBucketLength;
        assert(areaChange > 0);

        slots[maxIndex].totalArea -= areaChange;
        assert(slots[maxIndex].totalArea > 0);
        slots[minIndex].totalArea += areaChange;
        assert(slots[minIndex].totalArea > 0);

        Bucket newBucket = *smallestDifferenceBucket;
        newBucket.coords[randomDimensionIndex] += smallestDifferenceBucket.dimensions[randomDimensionIndex] - newBucketLength;
        newBucket.dimensions[randomDimensionIndex] = newBucketLength;
        newBucket.nextBucketIndex = slots[minIndex].firstBucketIndex;
        slots[minIndex].firstBucketIndex = cast(int) nextBucketIndex;
        bucketAllocator[nextBucketIndex++] = newBucket;

        smallestDifferenceBucket.dimensions[randomDimensionIndex] -= newBucketLength;
    }

    return DistributionResult(bucketAllocator, slots);
}

unittest
{
    int[2] dimensions = [8, 8];
    auto layout = getRandomWorkLayout(dimensions, 4, 16);

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
