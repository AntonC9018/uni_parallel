module example_3_6_1;

static double piApproximationDerivative(double a) { return (4.0 / (1.0 + a * a)); }
const root = 0;

import mpi;
import mh = mpihelper;
import std.stdio : writeln;

version(Standalone)
int main()
{
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    int numberOfIterations;
    double calculatedPi;

    mh.MemoryWindow!int numberOfIterationsWindow;
    mh.MemoryWindow!double calculatedPiWindow;
    scope(exit) numberOfIterationsWindow.free();
    scope(exit) calculatedPiWindow.free();

    bool isRoot() { return info.rank == root; }
    if (isRoot)
    {
        numberOfIterationsWindow = mh.createMemoryWindow(&numberOfIterations);
        calculatedPiWindow = mh.createMemoryWindow(&calculatedPi);
    }
    else
    {
        numberOfIterationsWindow = mh.acquireMemoryWindow!int(1);
        calculatedPiWindow = mh.acquireMemoryWindow!double(1);
    }

    while (true)
    {
        if (isRoot)
        {
            writeln("=== Program ", info.args.argv[0], " results ===");
            writeln("Enter the number of iterations: (0 quits)");
            numberOfIterations = mh.readInt();
        }

        numberOfIterationsWindow.fence();
        if (!isRoot)
            numberOfIterationsWindow.get(&numberOfIterations, 0, root);
        numberOfIterationsWindow.fence();

        if (numberOfIterations == 0)
            break;
        
        double h = 1.0 / cast(double) numberOfIterations;
        double sum = 0;
        for (int i = info.rank + 1; i <= numberOfIterations; i += info.size)
        {
            double x = h * (cast(double) i - 0.5);
            sum += piApproximationDerivative(x);
        }

        calculatedPi = h * sum;
        writeln("Process' ", info.rank, " caclulated pi part = ", calculatedPi);

        calculatedPiWindow.fence();
        if (!isRoot)
            calculatedPiWindow.accumulate(&calculatedPi, 0, root, MPI_SUM);
        calculatedPiWindow.fence();

        if (isRoot)
        {
            import std.math : PI, abs;
            writeln("Pi ~= ", calculatedPi, "; error = ", abs(calculatedPi - PI));
        }
    }
    return 0;
}

else
double calculatePi(in InitInfo info, int numberOfIterations)
{
    double calculatedPi;
    mh.MemoryWindow!double calculatedPiWindow;
    scope(exit) calculatedPiWindow.free();
    
    bool isRoot() { return info.rank == root; }
    if (isRoot)
        calculatedPiWindow = mh.createMemoryWindow(&calculatedPi);
    else
        calculatedPiWindow = mh.acquireMemoryWindow!double(1);

    double h = 1.0 / cast(double) numberOfIterations;
    double sum = 0;
    for (int i = info.rank + 1; i <= numberOfIterations; i += info.size)
    {
        double x = h * (cast(double) i - 0.5);
        sum += piApproximationDerivative(x);
    }

    calculatedPi = h * sum;
    calculatedPiWindow.fence();
    if (!isRoot)
        calculatedPiWindow.accumulate(&calculatedPi, 0, root, MPI_SUM);
    calculatedPiWindow.fence();

    return calculatedPi;
}