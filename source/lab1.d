import core.stdc.stdio;
import std.conv : to;
import std.process;
import mpi;
import mh = mpihelper;

int main(string[] args)
{
    int local_rank = environment["OMPI_COMM_WORLD_LOCAL_RANK"].to!int;
    char[MPI_MAX_PROCESSOR_NAME] processor_name;
    int namelen;
    MPI_Status status;

    auto info = mh.initialize();
    scope(exit) mh.finalize();

    if (info.rank == 0)
        printf("\n=====REZULTATUL PROGRAMULUI '%s' \n", info.argv[0]);

    MPI_Barrier(MPI_COMM_WORLD);

    MPI_Get_processor_name(processor_name.ptr, &namelen);
    import std.string : toStringz;
    if (local_rank == 0)
        printf("==Au fost generate %s MPI processes pe nodul %s ===\n", environment["OMPI_COMM_WORLD_LOCAL_SIZE"].toStringz, processor_name.ptr);

    MPI_Barrier(MPI_COMM_WORLD);

    if (info.rank == 0)
        printf("==Procesele comunicatorului MPI_COMM_WORLD au fost 'distribuite' pe noduri astfel: \n");

    MPI_Barrier(MPI_COMM_WORLD);

    printf("Hello, I am the process number %d (local rank %d) on the compute hostname `%s`, from total number of process %d\n",     
        info.rank, local_rank, processor_name.ptr, info.size);
        
    return 0;
}