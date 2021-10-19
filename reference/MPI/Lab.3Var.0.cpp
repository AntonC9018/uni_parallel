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
	int rank, x, commSize, myRankInWriteGroup, myRankInReadGroup;
	MPI_File outFileHandle;
	MPI_Datatype elementaryType, ftype0, ftype;
	MPI_Status state;
	MPI_Datatype rowDatatype;

	MPI_Init(&argc, &argv);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &commSize);

	MPI_Group mpi_group_world, groupWrite, groupRead;
	MPI_Comm commWrite, commRead;

	int numRows;
	int numCols;
	if (rank == 0)
	{
		printf("Enter number of rows\n");
		scanf("%d", &numRows);
		printf("Enter number of collumns\n");
		scanf("%d", &numCols);
	}
	MPI_Bcast(&numRows, 1, MPI_INT, 0, MPI_COMM_WORLD);
	MPI_Bcast(&numCols, 1, MPI_INT, 0, MPI_COMM_WORLD);

	int doubledRowCountPerProcess = 2 * numRows / commSize;
	int matrixWriteBuffer[numRows][numCols];
	int matrixReadBuffer[doubledRowCountPerProcess][numCols];
	{
		int accessMode = MPI_MODE_DELETE_ON_CLOSE;
		MPI_File_open(MPI_COMM_WORLD, "array.dat", accessMode, MPI_INFO_NULL, &outFileHandle);
	}
	MPI_File_close(&outFileHandle);

	{ // TODO: too much duplicate logic. factor out a function, or at least a macro!
		int firstHalfGroup[commSize / 2];
		int secondHalfGroup[commSize / 2];

		// Se creaza doua grupe (Group_write, Gropu_read) de procese si doua comunicatoare
		for (int processIndex = 0; processIndex < commSize / 2; processIndex++)
			firstHalfGroup[processIndex] = processIndex;
		for (int processIndex = commSize / 2; processIndex < commSize; processIndex++)
			secondHalfGroup[processIndex - commSize / 2] = processIndex;

		MPI_Comm_group(MPI_COMM_WORLD, &mpi_group_world);

		MPI_Group_incl(mpi_group_world, commSize / 2, firstHalfGroup, &groupWrite);
		MPI_Comm_create(MPI_COMM_WORLD, groupWrite, &commWrite);

		MPI_Group_incl(mpi_group_world, commSize / 2, secondHalfGroup, &groupRead);
		MPI_Comm_create(MPI_COMM_WORLD, groupRead, &commRead);

		MPI_Group_rank(groupWrite, &myRankInWriteGroup);
	}

	MPI_Aint rowsize;
	MPI_Type_extent(rowDatatype, &rowsize); //<==> l*m*sizeof(int)

	if (myRankInWriteGroup != MPI_UNDEFINED)
	{
		accessMode = MPI_MODE_CREATE | MPI_MODE_WRONLY;
		MPI_File_open(commWrite, "array.dat", accessMode, MPI_INFO_NULL, &outFileHandle);
		// Array Program (derived datatypes)
		MPI_Type_contiguous(doubledRowCountPerProcess * numCols, MPI_INT, &rowDatatype);
		MPI_Type_commit(&rowDatatype);

		MPI_Datatype types[2];
		MPI_Aint displs[2];
		elementaryType = rowDatatype;
		ftype0 = rowDatatype;
		types[0] = rowDatatype;
		types[1] = rowDatatype;
		displs[0] = (MPI_Aint)0;
		MPI_Aint rowsize;
		MPI_Type_extent(rowDatatype, &rowsize); //<==> l*m*sizeof(int)

		if (myRankInWriteGroup > 0)
			displs[1] = myRankInWriteGroup * rowsize;
		int blengths[2] = {0, 1};
		MPI_Type_struct(2, blengths, displs, types, &ftype);
		MPI_Type_commit(&ftype);

		for (int i = 1; i <= numRows; ++i)
		{
			for (int j = 1; j <= numCols; ++j)
				matrixWriteBuffer[i - 1][j - 1] = 10 * i + j;
		}
		if (myRankInWriteGroup == 0)
		{
			cout << "Matricea initiala" << endl;
			for (int i = 0; i < numRows; i++)
			{
				for (int j = 0; j < numCols; j++)
					cout << matrixWriteBuffer[i][j] << " ";
				cout << endl;
			}
			cout << endl;
		}

		// Procesul 0 inscrie in fisier plimele l randuri ale matricei
		// Procesele rank=1,2,...,(size/2)-1 inscriu in fisier urmatoarele l linii
		MPI_Datatype writeDatatype = myRankInWriteGroup == 0 ? ftype0 : ftype;
		MPI_File_set_view(outFileHandle, 0, elementaryType, writeDatatype, "native", MPI_INFO_NULL);
		MPI_File_write(outFileHandle, &matrixWriteBuffer[myRankInWriteGroup * doubledRowCountPerProcess][0], 1, rowDatatype, &state);
		int count;
		MPI_Get_count(&state, rowDatatype, &count);
		printf("Procesul %d din grupul 1 (%d din grupul parinte) a inscris in fisier %d etypes ( %d linii) \n", 
			myRankInWriteGroup, rank, count, count * doubledRowCountPerProcess);
	}
	//MPI_Barrier(MPI_COMM_WORLD);
	//Procesele rank=size/2,...,size-1  citesc liniile din fisier
	MPI_Group_rank(groupRead, &myRankInReadGroup);
	if (myRankInReadGroup != MPI_UNDEFINED)
	{
		MPI_Type_contiguous(doubledRowCountPerProcess * numCols, MPI_INT, &rowDatatype);
		MPI_Type_commit(&rowDatatype);

		MPI_Datatype readDatatype;
		if (myRankInReadGroup == 0)
		{
			readDatatype = rowDatatype
		}
		else
		{
			MPI_Datatype types[2] = { rowDatatype, rowDatatype };
			MPI_Aint displs[2] = { 0, myRankInReadGroup * rowsize };
			MPI_Type_struct(2, blengths, displs, types, &readDatatype);
			MPI_Type_commit(&readDatatype);
		}

		int accessMode = MPI_MODE_CREATE | MPI_MODE_RDWR;
		MPI_File_open(commRead, "array.dat", accessMode, MPI_INFO_NULL, &outFileHandle);
		MPI_File_set_view(outFileHandle, 0, elementaryType, readDatatype, "native", MPI_INFO_NULL);
		MPI_File_read(outFileHandle, &matrixReadBuffer[0][0], 1, rowDatatype, &state);
		printf("===Procesul %d din grupul 2 (%d din grupul parinte) a citit din fisier liniile:\n", myRankInReadGroup, rank);
		for (int i = 0; i < doubledRowCountPerProcess; i++)
		{
			for (int j = 0; j < numCols; j++)
			{
				printf("%d\t", matrixReadBuffer[i][j]);
			}
			printf("\n");
		}
	}

	MPI_File_close(&outFileHandle);
	MPI_Finalize();
	return 0;
}
