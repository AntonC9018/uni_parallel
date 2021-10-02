#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

int main(int argc, char *argv[])
{
	MPI_Init(&argc, &argv);

	int size, rank;
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	
	int namelen;
	char processor_name[MPI_MAX_PROCESSOR_NAME];
	MPI_Get_processor_name(processor_name, &namelen);
	
	if (rank == 0)
	{
		printf("=====REZULTATUL PROGRAMULUI '%s' \n", argv[0]);
		printf("Rankurile proceselor din comunicatorului 'MPI_COMM_WOLD' au fost repartizate astfel: \n");
	}
	MPI_Barrier(MPI_COMM_WORLD);
	printf("Rankul %d de pe nodul %s. \n", rank, processor_name);

	// Se determina numarul de noduri (care este si numarul de procese in grupul creat
	int local_rank = atoi(getenv("OMPI_COMM_WORLD_LOCAL_RANK"));
	int process_count_contribution = local_rank == 0 ? 1 : 0;
	int num_nodes;
	MPI_Allreduce(&process_count_contribution, &num_nodes, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);

	// Se construieste vectorul new_group
	int* new_group = (int*) malloc(num_nodes * sizeof(int));
	int* ranks = (int*) malloc(size * sizeof(int));
	ranks[rank] = (local_rank == 0) ? rank : -1;
	for (int i = 0; i < size; ++i)
		MPI_Bcast(&ranks[i], 1, MPI_INT, i, MPI_COMM_WORLD);
	for (int i = 0, j = 0; i < size; ++i)
	{
		if (ranks[i] != -1)
		{
			new_group[j] = ranks[i];
			++j;
		}
	}

	MPI_Group world_group, group;
	MPI_Comm com_new;
	MPI_Comm_group(MPI_COMM_WORLD, &world_group);
	MPI_Group_incl(world_group, num_nodes, new_group, &group);
	MPI_Comm_create(MPI_COMM_WORLD, newgr, &com_new);

	int rankNew;
	MPI_Group_rank(group, &rankNew);
	if (rankNew != MPI_UNDEFINED)
		printf("Procesul cu rankul %d al comunicatorului 'com_new'(%d com. 'MPI_COMM_WOLD') de pe nodul %s. \n", rankNew, rank, processor_name);
	MPI_Finalize();
	return 0;
}
