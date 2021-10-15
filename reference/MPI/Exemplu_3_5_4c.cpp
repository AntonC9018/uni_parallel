/* In acest program:
1) se creaza un comunicator cu topologie carteziana de tip paralelepiped;
2) se fixeaza o fateta a paralepipedului si se determina vecinii pentru procesele care apartin muchiilor
   acestei fatete.
3)se realizeaza transmiterea pe cerc a datelor intre procesele care apartin muchiilor fatetei cu schimbarea directiei de transmitere
*/
#include <mpi.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	MPI_Init(&argc, &argv);

	int myrank;
	MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
	int worldSize;
	MPI_Comm_size(MPI_COMM_WORLD, &worldSize);

	int numDims = 3;
	int dims[3] = {0};
	MPI_Dims_create(worldSize, numDims, dims);
	if (myrank == 0)
	{
		printf("\n ===== REZULTATUL PROGRAMULUI '%s' \n", argv[0]);
		for (int i = 0; i < 3; i++)
		{
			printf("Numarul de procese pe axa %d = %d", i, dims[i]);
		}
		printf("\n");
	}

	MPI_Comm cartesianComm;
	int periods[3] = {0};
	int reorder = 0;
	MPI_Cart_create(MPI_COMM_WORLD, numDims, dims, periods, reorder, &cartesianComm);

	int mycoords[3];
	MPI_Cart_coords(cartesianComm, myrank, numDims, mycoords);

	int test_rank = 2;
	int D1, D2;
	MPI_Status status;
	char processor_name[MPI_MAX_PROCESSOR_NAME];
	int source, dest;
	int left_y, right_y, right_x, left_x, up_z, down_z;
	int coords_left_x[3] = {0, 0, 0}, coords_right_x[3] = {0, 0, 0},
		coords_left_y[3] = {0, 0, 0}, coords_right_y[3] = {0, 0, 0},
		coords_up_z[3] = {0, 0, 0}, coords_down_z[3] = {0, 0, 0};

	// YZ plane for X = max?
	if (mycoords[0] == dims[0] - 1)
	{
		bool oneIsFirst = mycoords[1] == 0 || mycoords[2] == 0;
		bool noneAreLast = (mycoords[1] != dims[1] - 1) && (mycoords[2] != dims[2] - 1);
		if (oneIsFirst && noneAreLast)
		{
			printf("Sunt procesul cu rankul %d (%d,%d,%d) vecinii mei sunt: \n", myrank, mycoords[0], mycoords[1], mycoords[2]);
			/*
MPI_Cart_shift(comm,0,1,&left_x,&right_x);
if (left_x<0) {coords_left_x[0]=-1; coords_left_x[1]=-1;coords_left_x[2]=-1;}
else {MPI_Cart_coords(comm, left_x, ndims, coords_left_x); }
if (right_x<0) {coords_right_x[0]=-1;coords_right_x[1]=-1;coords_right_x[2]=-1;}
else {MPI_Cart_coords(comm, right_x, ndims, coords_right_x); }
printf("   pe directia axei X : stanga %d(%d,%d,%d) dreapta %d(%d,%d,%d) \n",left_x,coords_left_x[0],coords_left_x[1],coords_left_x[2],right_x,coords_right_x[0],coords_right_x[1],coords_right_x[2]);
*/
			if (mycoords[2] == 0 && mycoords[1] == dims[1] - 1)
			{
				MPI_Cart_shift(comm, 1, 1, &left_y, &right_y);
				MPI_Cart_shift(comm, 2, 1, &up_z, &down_z);
				if (left_y > 0 && right_y > 0)
				{
					D1 = D1 + rank;
					MPI_Sendrecv(&D1, 1, MPI_INT, left_y, 12, &D2, 1, MPI_INT, right_y, 12, comm, &status);
					printf("Process %d, received from proces %d the value %d and send to proces %d the 			value %d\n", rank, left_y, D2, right_y, D1);
					printf("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send 		to proces %d (%d,%d,%d) the value %d\n", rank, coords[0], coords[1], coords[2], left_y, coords_left_y[0], coords_left_y[1], coords_left_y[2], D2, right_y, coords_right_y[0], coords_right_y[1], coords_right_y[2], D1);
				}
				if (left_y < 0 && right_y > 0)
				{
					D1 = D1 + rank;
					MPI_Sendrecv(&D1, 1, MPI_INT, up_z, 12, &D2, 1, MPI_INT, right_y, 12, comm, &status);
					printf("Process %d, received from proces %d the value %d and send to proces %d the 	value %d	\n", rank, right_y, D2, up_z, D1);
					printf("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send to proces %d (%d,%d,%d) the value %d\n", rank, coords[0], coords[1], coords[2], right_y, coords_right_y[0], coords_right_y[1], coords_right_y[2], D2, up_z, coords_up_z[0], coords_up_z[1], coords_up_z[2], D1);
				}
				if (left_y > 0 && right_y < 0)
				{
					D1 = D1 + rank;
					MPI_Sendrecv(&D1, 1, MPI_INT, left_y, 12, &D2, 1, MPI_INT, down_z, 12, comm, &status);
					printf("Process %d, received from proces %d the value %d and send to proces %d the value %d\n", rank, down_z, D2, left_y, D1);
					printf("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send to proces %d (%d,%d,%d) the value %d\n", rank, coords[0], coords[1], coords[2], down_z, coords_down_z[0], coords_down_z[1], coords_down_z[2], D2, left_y, coords_left_y[0], coords_left_y[1], coords_left_y[2], D1);
				}
			}
			/*
if (coords[2]=dims[2]-1)
MPI_Cart_shift(comm,1,-1,&left_y,&right_y);
MPI_Cart_coords(comm, left_y, ndims, coords_left_y); 
MPI_Cart_coords(comm, right_y, ndims, coords_right_y); }


 if (coords[1]=0)  
 MPI_Cart_shift(comm,2,-1,&up_z,&down_z);
if (coords[1]=dims[1]-1)  
 MPI_Cart_shift(comm,2,1,&up_z,&down_z);
 if (up_z<0) {coords_up_z[0]=-1; coords_up_z[1]=-1;coords_up_z[2]=-1;}
else {MPI_Cart_coords(comm, up_z, ndims, coords_up_z); }
if (down_z<0) {coords_down_z[0]=-1;coords_down_z[1]=-1;coords_down_z[2]=-1;}
else {MPI_Cart_coords(comm, down_z, ndims, coords_down_z); }
printf("   pe directia axei Z : jos %d(%d,%d,%d) sus %d(%d,%d,%d) \n",up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],down_z,coords_down_z[0],coords_down_z[1],coords_down_z[2]);   

if(left_y<0 && right_y>0)
{
D1 = D1 + rank;
MPI_Sendrecv(&D1, 1, MPI_INT, up_z, 12, &D2, 1, MPI_INT, right_y, 12, comm, &status);
	printf ("Process %d, received from proces %d the value %d and send to proces %d the value %d	\n",rank,right_y,D2,up_z,D1);
printf ("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send to proces %d (%d,%d,%d) the value %d\n",rank,coords[0],coords[1],coords[2],right_y,coords_right_y[0], coords_right_y[1], coords_right_y[2],D2,up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],D1);
}
if(left_y>0 && right_y<0)
{
D1 = D1 + rank;
MPI_Sendrecv(&D1, 1, MPI_INT, left_y, 12, &D2, 1, MPI_INT, down_z, 12, comm, &status);
	printf ("Process %d, received from proces %d the value %d and send to proces %d the value %d\n",rank,down_z,D2,left_y,D1);
printf ("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send to proces %d (%d,%d,%d) the value %d\n",rank,coords[0],coords[1],coords[2],down_z,coords_down_z[0], coords_down_z[1], coords_down_z[2],D2,left_y,coords_left_y[0],coords_left_y[1],coords_left_y[2],D1);
}
*/
			/*
if(up_z>0 && down_z>0)
{
D1 = D1 + rank;
MPI_Sendrecv(&D1, 1, MPI_INT, down_z, 12, &D2, 1, MPI_INT, up_z, 12, comm, &status);
	printf ("Process %d, received from proces %d the value %d and send to proces %d the value %d\n",rank,up_z,D2,down_z,D1);
printf ("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send to proces %d (%d,%d,%d) the value %d\n",rank,coords[0],coords[1],coords[2],down_z,coords_down_z[0], coords_down_z[1], coords_down_z[2],D2,up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],D1);
}
if(up_z<0 && down_z>0)
{
D1 = D1 + rank;
MPI_Sendrecv(&D1, 1, MPI_INT, down_z, 12, &D2, 1, MPI_INT, left_y, 12, comm, &status);
printf ("Process %d, received from proces %d the value %d and send to proces %d the value %d\n",rank,up_z,D2,down_z,D1);

}
if(up_z>0 && down_z<0)
{
D1 = D1 + rank;
MPI_Sendrecv(&D1, 1, MPI_INT, right_y, 12, &D2, 1, MPI_INT, up_z, 12, comm, &status);
	printf ("Process %d, received from proces %d the value %d and send to proces %d the value %d\n",rank,up_z,D2,down_z,D1);
printf ("Process %d (%d,%d,%d), received from proces %d (%d,%d,%d)the value %d and send to proces %d (%d,%d,%d) the value %d\n",rank,coords[0],coords[1],coords[2],down_z,coords_down_z[0], coords_down_z[1], coords_down_z[2],D2,up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],D1);

}
*/
		}
	}
	if (rank == 0)
		printf("===Valorile negative semnifica lipsa procesului vecin!\n");
	MPI_Finalize();
	return 0;
}
/*

*/
