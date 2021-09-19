import core.stdc.stdio;
import std.conv : to;
import std.process;
import mpi;

int main(string[] args)
{
    int size, rank, namelen;
    int local_rank = environment["OMPI_COMM_WORLD_LOCAL_RANK"].to!int;
    char[MPI_MAX_PROCESSOR_NAME] processor_name;
    MPI_Status status;

    char** argv;
    int argc;
    {
        import std.string, std.algorithm, std.array;
        argv = cast(char**) map!toStringz(args).array.ptr;
        argc = cast(int) args.length;
        MPI_Init(&argc, &argv);
        MPI_Comm_size(MPI_COMM_WORLD, &size);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    }


    if (rank == 0)
        printf("\n=====REZULTATUL PROGRAMULUI '%s' \n", argv[0]);

    MPI_Barrier(MPI_COMM_WORLD);

    MPI_Get_processor_name(processor_name.ptr, &namelen);
    import std.string : toStringz;
    if (local_rank == 0)
        printf("==Au fost generate %s MPI processes pe nodul %s ===\n", environment["OMPI_COMM_WORLD_LOCAL_SIZE"].toStringz, processor_name.ptr);

    MPI_Barrier(MPI_COMM_WORLD);

    if (rank == 0)
        printf("==Procesele comunicatorului MPI_COMM_WORLD au fost 'distribuite' pe noduri astfel: \n");

    MPI_Barrier(MPI_COMM_WORLD);

    printf("Hello, I am the process number %d (local rank %d) on the compute hostname `%s`, from total number of process %d\n",     
        rank, local_rank, processor_name.ptr, size);
    MPI_Finalize();
    return 0;
}