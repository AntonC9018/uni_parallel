module example_3_4_4;

import mpi;
import mh = mpihelper;
import std.stdio : writeln;

// Some derivative I suppose? 
// Or is it the polygon-corner-cutting thing?
static double piApproximationDerivative(double a) { return (4.0 / (1.0 + a * a)); }
const root = 0;

version(Standalone)
int main()
{
    double startwtime;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    while (true)
    {
        int numberOfIterations;
        bool isRoot() { return info.rank == root; }

        if (isRoot)
        {
            writeln("=== Program ", info.args.argv[0], " results ===");
            writeln("Enter the number of iterations: (0 quits)");
            numberOfIterations = mh.readInt();
        }
        mh.barrier();

        if (isRoot)
        {
            startwtime = MPI_Wtime();
        }

        mh.bcast(&numberOfIterations, 0);
        
        if (numberOfIterations == 0)
            break;

        double h = 1.0 / cast(double) numberOfIterations;
        double sum = 0;
        for (int i = info.rank + 1; i <= numberOfIterations; i += info.size)
        {
            double x = h * (cast(double) i - 0.5);
            sum += piApproximationDerivative(x);
        }
        
        double calculatedPi = h * sum;
        writeln("Process' ", info.rank, " caclulated pi part = ", calculatedPi);
        mh.intraReduce(&calculatedPi, MPI_SUM, info.rank, root);

        if (isRoot)
        {
            import std.math : PI, abs;
            writeln("Pi ~= ", calculatedPi, "; error = ", abs(calculatedPi - PI));
            writeln("Time passed: ", MPI_Wtime() - startwtime);
        }
    }
    return 0;
}

else
void calculatePi(in mh.InitInfo info, int numberOfIterations)
{
    mh.bcast(&numberOfIterations, root);
    
    double h = 1.0 / cast(double) numberOfIterations;
    double sum = 0;
    for (int i = info.rank + 1; i <= numberOfIterations; i += info.size)
    {
        double x = h * (cast(double) i - 0.5);
        sum += piApproximationDerivative(x);
    }

    double calculatedPi = h * sum;
    mh.intraReduce(&calculatedPi, MPI_SUM, info.rank, root);
}