module matrix_random_distribution;

struct Bucket
{
    int[2] coords;
    int[2] dimensions;
    Bucket* nextBucket;
}

struct Slot
{
    Bucket* firstBucket;
    int totalArea;

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
    bucketAllocator[nextBucketIndex++] = Bucket([0, 0], dimensions, null);

    Slot[] slots = new Slot[](numSlots);
    slots[0] = Slot(&bucketAllocator[0], dimensions.fold!`a * b`(1));

    while (nextBucketIndex < bucketAllocator.length)
    {
        auto totalAreas = slots[].map!`a.totalArea`;
        size_t minIndex = totalAreas.minIndex;
        size_t maxIndex = totalAreas.maxIndex;

        uint randomSize = uniform!uint;
        uint randomDimensionIndex = uniform!uint % 2;

        Bucket* currentBucket = slots[maxIndex].firstBucket;
        int smallestAreaDifference = int.max;
        Bucket* smallestAreaDifferenceBucket = null;

        bool changedDirection = false;

        while (currentBucket)
        {
            void endIteration()
            {
                currentBucket = currentBucket.nextBucket;

                if (!currentBucket && !smallestAreaDifferenceBucket)
                {
                    assert(currentBucket.dimensions[randomDimensionIndex] == 1);
                    assert(!changedDirection);
                    changedDirection = true;

                    randomDimensionIndex = 1 - randomDimensionIndex;
                    currentBucket = slots[maxIndex].firstBucket;
                }
            }

            // Cannot split any more
            if (currentBucket.dimensions[randomDimensionIndex] == 1)
            {
                endIteration();
                continue;
            }

            const sideLength = randomSize % (currentBucket.dimensions[randomDimensionIndex] - 1) + 1;
            int areaChange = currentBucket.dimensions[1 - randomDimensionIndex] * sideLength;
            
            const updatedAreaMax = slots[maxIndex].totalArea - areaChange;
            const updatedAreaMin = slots[minIndex].totalArea + areaChange;
            import std.math : abs;
            const areaDifference = abs(updatedAreaMax - updatedAreaMin);
            if (areaDifference < smallestAreaDifference)
            {
                smallestAreaDifference = areaDifference;
                smallestAreaDifferenceBucket = currentBucket;
            }

            endIteration();
        }

        assert(smallestAreaDifferenceBucket);
        assert(smallestAreaDifferenceBucket < &bucketAllocator[$ - 1]);

        const newBucketLength = randomSize % (smallestAreaDifferenceBucket.dimensions[randomDimensionIndex] - 1) + 1;
        assert(newBucketLength >= 1);
        const areaChange = smallestAreaDifferenceBucket.dimensions[1 - randomDimensionIndex] * newBucketLength;
        assert(areaChange > 0);

        slots[maxIndex].totalArea -= areaChange;
        assert(slots[maxIndex].totalArea > 0);
        slots[minIndex].totalArea += areaChange;
        assert(slots[minIndex].totalArea > 0);

        Bucket* newBucket = &bucketAllocator[nextBucketIndex++];
        *newBucket = *smallestAreaDifferenceBucket;
        newBucket.coords[randomDimensionIndex] += smallestAreaDifferenceBucket.dimensions[randomDimensionIndex] - newBucketLength;
        newBucket.dimensions[randomDimensionIndex] = newBucketLength;
        newBucket.nextBucket = slots[minIndex].firstBucket;
        slots[minIndex].firstBucket = newBucket;

        smallestAreaDifferenceBucket.dimensions[randomDimensionIndex] -= newBucketLength;
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
        const(Bucket)* bucket = slot.firstBucket;
        while (bucket)
        {
            foreach (rowIndex; iota(bucket.dimensions[0]).map!(y => y + bucket.coords[0]))
            foreach (colIndex; iota(bucket.dimensions[1]).map!(x => x + bucket.coords[1]))
            {
                size_t index = rowIndex * dimensions[1] + colIndex;
                assert(buffer[index] == -1);
                buffer[index] = cast(int) slotIndex;
            }
            bucket = bucket.nextBucket;
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
