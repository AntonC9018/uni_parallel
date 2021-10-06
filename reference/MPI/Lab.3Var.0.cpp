/*
       

*/
#include <mpi.h>
#include <stdio.h>
#include <string>
#include <iostream>
#include <stdlib.h>
using namespace std;
int main(int argc, char **argv)
{
	int rank, count, x, amode, i, j, size, n, m, rank_gr1, rank_gr2;
	MPI_File OUT;
	MPI_Aint rowsize;
	MPI_Datatype etype, ftype0, ftype;
	MPI_Status state;
	MPI_Datatype MPI_ROW;
	int blengths[2] = {0, 1};
	MPI_Datatype types[2];
	MPI_Aint disps[2];
	MPI_Init(&argc, &argv);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	int ranks_gr1[size / 2];
	int ranks_gr2[size / 2];
	MPI_Group MPI_GROUP_WORLD, Group_write, Group_read;
	MPI_Comm Comm_write, Comm_read;
	if (rank == 0)
	{
		printf("Enter number of rows\n");
		scanf("%d", &n);
		printf("Enter number of collumns\n");
		scanf("%d", &m);
	}
	MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
	MPI_Bcast(&m, 1, MPI_INT, 0, MPI_COMM_WORLD);
	int l = 2 * n / size;
	int value[n][m];
	int myval[n][m];
	amode = MPI_MODE_DELETE_ON_CLOSE;
	MPI_File_open(MPI_COMM_WORLD, "array.dat", amode, MPI_INFO_NULL, &OUT);
	MPI_File_close(&OUT);
	// Se creaza doua grupe (Group_write, Gropu_read) de procese si doua comunicatoare
	j = 0;
	for (int i = 0; i < size / 2; i++)
		ranks_gr1[j++] = i;
	j = 0;
	for (int i = size / 2; i < size; i++)
		ranks_gr2[j++] = i;

	MPI_Comm_group(MPI_COMM_WORLD, &MPI_GROUP_WORLD);
	MPI_Group_incl(MPI_GROUP_WORLD, size / 2, ranks_gr1, &Group_write);
	MPI_Comm_create(MPI_COMM_WORLD, Group_write, &Comm_write);
	MPI_Group_incl(MPI_GROUP_WORLD, size / 2, ranks_gr2, &Group_read);
	MPI_Comm_create(MPI_COMM_WORLD, Group_read, &Comm_read);
	MPI_Group_rank(Group_write, &rank_gr1);
	if (rank_gr1 != MPI_UNDEFINED)
	{
		amode = MPI_MODE_CREATE | MPI_MODE_WRONLY;
		MPI_File_open(Comm_write, "array.dat", amode, MPI_INFO_NULL, &OUT);
		// Array Program (derived datatypes)
		MPI_Type_contiguous(l * m, MPI_INT, &MPI_ROW);
		MPI_Type_commit(&MPI_ROW);
		etype = MPI_ROW;
		ftype0 = MPI_ROW;
		types[0] = types[1] = MPI_ROW;
		disps[0] = (MPI_Aint)0;
		MPI_Type_extent(MPI_ROW, &rowsize); //<==> l*m*sizeof(int)
		if (rank_gr1 > 0)
			disps[1] = rank_gr1 * rowsize;
		MPI_Type_struct(2, blengths, disps, types, &ftype);
		MPI_Type_commit(&ftype);
		for (i = 1; i <= n; ++i)
			for (j = 1; j <= m; ++j)
				value[i - 1][j - 1] = 10 * i + j;
		if (rank_gr1 == 0)
		{
			cout << "Matricea initiala" << endl;
			for (int i = 0; i < n; i++)
			{
				for (int j = 0; j < m; j++)
					cout << value[i][j] << " ";
				cout << endl;
			}
			cout << endl;
		}
		count = 0;
		// Procesul 0 inscrie in fisier plimele l randuri ale matricei
		if (rank_gr1 == 0)
		{
			MPI_File_set_view(OUT, 0, etype, ftype0, "native", MPI_INFO_NULL);
			MPI_File_write(OUT, &value[0][0], 1, MPI_ROW, &state);
			MPI_Get_count(&state, MPI_ROW, &count);
			printf("Procesul %d din grupul 1 (%d din grupul parinte) a inscris in fisier %d etypes ( %d linii) \n", rank_gr1, rank, count, count * l);
		}
		else
		//Procesele rank=1,2,...,(size/2)-1 inscriu in fisier urmatoarele l linii
		{
			MPI_File_set_view(OUT, 0, etype, ftype, "native", MPI_INFO_NULL);
			MPI_File_write(OUT, &value[rank * l][0], 1, MPI_ROW, &state);
			MPI_Get_count(&state, MPI_ROW, &count);
			printf("Procesul %d din grupul 1 (%d din grupul parinte) a inscris in fisier %d etypes ( %d linii) \n", rank_gr1, rank, count, count * l);
		}
	}
	//MPI_Barrier(MPI_COMM_WORLD);
	//Procesele rank=size/2,...,size-1  citesc liniile din fisier
	MPI_Group_rank(Group_read, &rank_gr2);
	if (rank_gr2 != MPI_UNDEFINED)
	{
		amode = MPI_MODE_CREATE | MPI_MODE_RDWR;
		MPI_File_open(Comm_read, "array.dat", amode, MPI_INFO_NULL, &OUT);
		// Array Program (derived datatypes)
		MPI_Type_contiguous(l * m, MPI_INT, &MPI_ROW);
		MPI_Type_commit(&MPI_ROW);
		etype = MPI_ROW;
		ftype0 = MPI_ROW;
		types[0] = types[1] = MPI_ROW;
		disps[0] = (MPI_Aint)0;
		MPI_Type_extent(MPI_ROW, &rowsize); //<==> l*m*sizeof(int)
		if (rank_gr2 > 0)
			disps[1] = rank_gr2 * rowsize;
		MPI_Type_struct(2, blengths, disps, types, &ftype);
		MPI_Type_commit(&ftype);
		if (rank_gr2 == 0)
		{
			MPI_File_set_view(OUT, 0, etype, ftype0, "native", MPI_INFO_NULL);
			MPI_File_read(OUT, &myval[0][0], 1, MPI_ROW, &state);
			printf("===Procesul %d din grupul 2 (%d din grupul parinte) a citit din fisier rindurile:\n", rank_gr2, rank);
			for (int i = 0; i < l; i++)
			{
				for (int j = 0; j < m; j++)
				{
					printf("%d\t", myval[i][j]);
				}
				printf("\n");
			}
		}
		else
		{
			MPI_File_set_view(OUT, 0, etype, ftype, "native", MPI_INFO_NULL);
			MPI_File_read(OUT, &myval[0][0], 1, MPI_ROW, &state);
			printf("===Procesul %d din grupul 2 (%d din grupul parinte) a citit din fisier rindurile:\n", rank_gr2, rank);
			for (int i = 0; i < l; i++)
			{
				for (int j = 0; j < m; j++)
				{
					printf("%d\t", myval[i][j]);
				}
				printf("\n");
			}
		}
	}

	MPI_File_close(&OUT);
	MPI_Finalize();
}
