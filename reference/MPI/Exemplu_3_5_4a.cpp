/* In acest program:
1) se creaza un comunicator cu topologie carteziana de tip paralelepiped;
2) se fixeaza o fateta a paralepipedului si se determina vecinii pentru procesele care apartin muchiilor
   acestei fatete (in directia miscarii acelor de ceas pe planul fatetei).
*/
#include <mpi.h>
#include <stdio.h>
#include <iostream>
#include <vector>
using namespace std;
int main(int argc, char *argv[])
{
	int rank,test_rank=2;
	int size;
	int ndims = 3;    
	int source, dest;
	int left_y,right_y,right_x,left_x,up_z, down_z;
	int dims[3]={0,0,0},coords[3]={0,0,0}; 
	int coords_left_x[3]={0,0,0},coords_right_x[3]={0,0,0},
	coords_left_y[3]={0,0,0},coords_right_y[3]={0,0,0},  
	coords_up_z[3]={0,0,0},coords_down_z[3]={0,0,0};  
	int periods[3]={0,0,0},reorder = 0;
	MPI_Comm comm;
	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Dims_create(size, ndims, dims);
	if(rank == 0)
	{
		printf("\n===== REZULTATUL PROGRAMULUI '%s' \n",argv[0]); 	 	
		for ( int i = 0; i < 3; i++ )
		{
			cout << "Numarul de procese pe axa "<< i<< " este "<< dims[i] << "; ";
			cout << endl;
		}	
		cout << "===Rankul si coordonatele proceselor de pe fateta laterala a paralelepipedului pentru x= " << dims[0]-1 << " ";
		cout << endl; 
	}
	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Cart_create(MPI_COMM_WORLD, ndims, dims, periods, reorder, &comm);
	MPI_Cart_coords(comm, rank, ndims, coords);  
	sleep(rank); 

	if(coords[0] == dims[0]-1)
		cout << "Procesul cu rankul " << rank << " are coordonatele (" << coords[0] << "," << coords[1] << "," << coords[2] <<")"<< endl;   
	MPI_Barrier(MPI_COMM_WORLD);
	if(rank == 0)
	{
		cout << "===Vecinii proceselor de pe muchiile fatetei laterali a paralelepipedului pentru x= "<< dims[0]-1 << " ";
		cout << endl;
	}
	sleep(rank);
	if(coords[0] == dims[0]-1)
	{
// in "if" este conditia pentru procesele de pe muchii (se exclud cele din interiorul fatetei)
		if (!(((0<coords[1])&&(0<coords[2]))&&((coords[1]<dims[1]-1)&&(coords[2]<dims[2]-1))))
		{
			printf("Sunt procesul cu rankul %d (%d,%d,%d) vecinii mei sunt: \n",rank,coords[0],coords[1],coords[2]);

// se determina vecinii pe muchia y,pentru x=dims[0]-1 si z=0
			if (coords[2]==0)
			{
				MPI_Cart_shift(comm,1,1,&left_y,&right_y);
			
	
			if (left_y<0) {coords_left_y[0]=-1; coords_left_y[1]=-1;coords_left_y[2]=-1;}
			else {MPI_Cart_coords(comm, left_y, ndims, coords_left_y); }
			if (right_y<0) {coords_right_y[0]=-1;coords_right_y[1]=-1;coords_right_y[2]=-1;}
			else {MPI_Cart_coords(comm, right_y, ndims, coords_right_y); }
			printf("   pe directia axei Y : stanga %d(%d,%d,%d) dreapta %d(%d,%d,%d) \n",left_y,coords_left_y[0],coords_left_y[1],coords_left_y[2],right_y,coords_right_y[0],coords_right_y[1],coords_right_y[2]);
			}
// se determina vecinii pe muchia y,pentru x=dims[0]-1 si z=dims[2]-1
			if (coords[2]==dims[2]-1)
			{
				MPI_Cart_shift(comm,1,-1,&left_y,&right_y);
				if (left_y<0) {coords_left_y[0]=-1; coords_left_y[1]=-1;coords_left_y[2]=-1;}
			else {MPI_Cart_coords(comm, left_y, ndims, coords_left_y); }
			if (right_y<0) {coords_right_y[0]=-1;coords_right_y[1]=-1;coords_right_y[2]=-1;}
			else {MPI_Cart_coords(comm, right_y, ndims, coords_right_y); }
			printf("   pe directia axei Y : stanga %d(%d,%d,%d) dreapta %d(%d,%d,%d) \n",left_y,coords_left_y[0],coords_left_y[1],coords_left_y[2],right_y,coords_right_y[0],coords_right_y[1],coords_right_y[2]);
			}
// se determina vecinii pe muchia z,pentru x=dims[0]-1 si y=0
			if (coords[1]==0) 
			{ 
				MPI_Cart_shift(comm,2,-1,&up_z,&down_z);

			if (up_z<0) {coords_up_z[0]=-1; coords_up_z[1]=-1;coords_up_z[2]=-1;}
			else {MPI_Cart_coords(comm, up_z, ndims, coords_up_z); }
			if (down_z<0) {coords_down_z[0]=-1;coords_down_z[1]=-1;coords_down_z[2]=-1;}
			else {MPI_Cart_coords(comm, down_z, ndims, coords_down_z); }
			printf("   pe directia axei Z : jos %d(%d,%d,%d) sus %d(%d,%d,%d) \n",up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],down_z,coords_down_z[0],coords_down_z[1],coords_down_z[2]); 
			} 
// se determina vecinii pe muchia z,pentru x=dims[0]-1 si y=dims[1]-1 
			if (coords[1]==dims[1]-1)  
			{
				MPI_Cart_shift(comm,2,1,&up_z,&down_z);
			if (up_z<0) {coords_up_z[0]=-1; coords_up_z[1]=-1;coords_up_z[2]=-1;}
			else {MPI_Cart_coords(comm, up_z, ndims, coords_up_z); }
			if (down_z<0) {coords_down_z[0]=-1;coords_down_z[1]=-1;coords_down_z[2]=-1;}
			else {MPI_Cart_coords(comm, down_z, ndims, coords_down_z); }
			printf("   pe directia axei Z : jos %d(%d,%d,%d) sus %d(%d,%d,%d) \n",up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],down_z,coords_down_z[0],coords_down_z[1],coords_down_z[2]); 
				}
		}

	}
	MPI_Barrier(MPI_COMM_WORLD);
	if(rank == 0)
		printf("===Valorile negative semnifica lipsa procesului vecin!\n");
	MPI_Finalize();
	return 0;
}
/*
[Hancu_B_S@hpc MPI]$ /opt/openmpi/bin/mpiCC -o Exemplu_3_5_4a_HB1.exe Exemplu_3_5_4a_HB1.cpp
[Hancu_B_S@hpc MPI]$ /opt/openmpi/bin/mpirun -n 64  -host compute-0-0,compute-0-1,compute-0-2,compute-0-3,compute-0-4,compute-0-5 Exemplu_3_5_4a_HB1.exe 

===== REZULTATUL PROGRAMULUI 'Exemplu_3_5_4a_HB1.exe' 
Numarul de procese pe axa 0 este 4; 
Numarul de procese pe axa 1 este 4; 
Numarul de procese pe axa 2 este 4; 
===Rankul si coordonatele proceselor de pe fateta laterala a paralelepipedului pentru x= 3 
Procesul cu rankul 48 are coordonatele (3,0,0)
Procesul cu rankul 49 are coordonatele (3,0,1)
Procesul cu rankul 50 are coordonatele (3,0,2)
Procesul cu rankul 51 are coordonatele (3,0,3)
Procesul cu rankul 52 are coordonatele (3,1,0)
Procesul cu rankul 53 are coordonatele (3,1,1)
Procesul cu rankul 54 are coordonatele (3,1,2)
Procesul cu rankul 55 are coordonatele (3,1,3)
Procesul cu rankul 56 are coordonatele (3,2,0)
Procesul cu rankul 57 are coordonatele (3,2,1)
Procesul cu rankul 58 are coordonatele (3,2,2)
Procesul cu rankul 59 are coordonatele (3,2,3)
Procesul cu rankul 60 are coordonatele (3,3,0)
Procesul cu rankul 61 are coordonatele (3,3,1)
Procesul cu rankul 62 are coordonatele (3,3,2)
Procesul cu rankul 63 are coordonatele (3,3,3)
===Vecinii proceselor de pe muchiile fatetei laterali a paralelepipedului pentru x= 3 
Sunt procesul cu rankul 48 (3,0,0) vecinii mei sunt: 
   pe directia axei Y : stanga -2(-1,-1,-1) dreapta 52(3,1,0) 
   pe directia axei Z : jos 49(3,0,1) sus -2(-1,-1,-1) 
Sunt procesul cu rankul 49 (3,0,1) vecinii mei sunt: 
   pe directia axei Z : jos 50(3,0,2) sus 48(3,0,0) 
Sunt procesul cu rankul 50 (3,0,2) vecinii mei sunt: 
   pe directia axei Z : jos 51(3,0,3) sus 49(3,0,1) 
Sunt procesul cu rankul 51 (3,0,3) vecinii mei sunt: 
   pe directia axei Y : stanga 55(3,1,3) dreapta -2(-1,-1,-1) 
   pe directia axei Z : jos -2(-1,-1,-1) sus 50(3,0,2) 
Sunt procesul cu rankul 52 (3,1,0) vecinii mei sunt: 
   pe directia axei Y : stanga 48(3,0,0) dreapta 56(3,2,0) 
Sunt procesul cu rankul 55 (3,1,3) vecinii mei sunt: 
   pe directia axei Y : stanga 59(3,2,3) dreapta 51(3,0,3) 
Sunt procesul cu rankul 56 (3,2,0) vecinii mei sunt: 
   pe directia axei Y : stanga 52(3,1,0) dreapta 60(3,3,0) 
Sunt procesul cu rankul 59 (3,2,3) vecinii mei sunt: 
   pe directia axei Y : stanga 63(3,3,3) dreapta 55(3,1,3) 
Sunt procesul cu rankul 60 (3,3,0) vecinii mei sunt: 
   pe directia axei Y : stanga 56(3,2,0) dreapta -2(-1,-1,-1) 
   pe directia axei Z : jos -2(-1,-1,-1) sus 61(3,3,1) 
Sunt procesul cu rankul 61 (3,3,1) vecinii mei sunt: 
   pe directia axei Z : jos 60(3,3,0) sus 62(3,3,2) 
Sunt procesul cu rankul 62 (3,3,2) vecinii mei sunt: 
   pe directia axei Z : jos 61(3,3,1) sus 63(3,3,3) 
Sunt procesul cu rankul 63 (3,3,3) vecinii mei sunt: 
   pe directia axei Y : stanga -2(-1,-1,-1) dreapta 59(3,2,3) 
   pe directia axei Z : jos 62(3,3,2) sus -2(-1,-1,-1) 
===Valorile negative semnifica lipsa procesului vecin!
[Hancu_B_S@hpc MPI]$ 

*/
