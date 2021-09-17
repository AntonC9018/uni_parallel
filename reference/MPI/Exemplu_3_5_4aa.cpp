/* In acest program:
1) se creaza un comunicator cu topologie carteziana de tip paralelepiped;
2) se fixeaza o fateta a paralepipedului si se determina vecinii pentru procesele care apartin muchiilor
   acestei fatete (in directia miscarii acelor de ceas pe planul fatetei).
3) se realizeaza transmiterea datelor pe cerc intre procesele de pe muchiile fatetei
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
int message;  
int source, dest;
MPI_Status status;
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
if (!(((0<coords[1])&&(0<coords[2]))&&((coords[1]<dims[1]-1)&&(coords[2]<dims[2]-1))))
{
printf("Sunt procesul cu rankul %d (%d,%d,%d) vecinii mei sunt: \n",rank,coords[0],coords[1],coords[2]);

// se determina vecinii pe muchia y,pentru x=dims[0]-1 si z=0
			if (coords[2]==0)
			{
				MPI_Cart_shift(comm,1,-1,&left_y,&right_y);
			
	
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
				MPI_Cart_shift(comm,2,1,&up_z,&down_z);

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

// Transmiterea de date pe cerc
int stanga = left_y;
int dreapta = right_y;	
int jos = up_z;
int sus = down_z;
sleep(rank);
if(dreapta<0 && jos<0){
	MPI_Sendrecv(&rank,1,MPI_INT,sus,10,&message,1,MPI_INT,stanga,10,comm,&status);
	MPI_Cart_coords(comm, down_z, ndims, coords_down_z); 
	MPI_Cart_coords(comm, left_y, ndims, coords_left_y); 
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<sus<<"(" << coords_down_z[0] << "," << coords_down_z[1] << "," << coords_down_z[2] <<") Received from "<<stanga<<"(" << coords_left_y[0] << "," << coords_left_y[1] << "," << coords_left_y[2] <<")"<< endl;
	}
if(sus>0 && jos>0 && stanga>0){
	MPI_Sendrecv(&rank,1,MPI_INT,jos,10,&message,1,MPI_INT,sus,10,comm,&status); 
	MPI_Cart_coords(comm, up_z, ndims, coords_up_z); 
	MPI_Cart_coords(comm, down_z, ndims, coords_down_z);  
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<jos<<"(" << coords_up_z[0] << "," << coords_up_z[1] << "," << coords_up_z[2] <<") Received from "<<sus<<"(" << coords_down_z[0] << "," << coords_down_z[1] << "," << coords_down_z[2] <<")"<< endl;
	}
if(sus<0 && dreapta<0){
	MPI_Sendrecv(&rank,1,MPI_INT,stanga,10,&message,1,MPI_INT,jos,10,comm,&status);
	MPI_Cart_coords(comm, up_z, ndims, coords_up_z); 
	MPI_Cart_coords(comm, left_y, ndims, coords_left_y); 
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<stanga<<"(" << coords_left_y[0] << "," << coords_left_y[1] << "," << coords_left_y[2] <<") Received from "<<jos<<"(" << coords_up_z[0] << "," << coords_up_z[1] << "," << coords_up_z[2] <<")"<< endl;
	}
if(dreapta>0 && stanga>0 && jos>0){
	MPI_Sendrecv(&rank,1,MPI_INT,stanga,10,&message,1,MPI_INT,dreapta,10,comm,&status);
	MPI_Cart_coords(comm, right_y, ndims, coords_right_y); 
	MPI_Cart_coords(comm, left_y, ndims, coords_left_y); 
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<stanga<<"(" << coords_left_y[0] << "," << coords_left_y[1] << "," << coords_left_y[2] <<") Received from "<<dreapta<<"(" << coords_right_y[0] << "," << coords_right_y[1] << "," << coords_right_y[2] <<")"<< endl;
	}
if(stanga<0 && sus<0){
	MPI_Sendrecv(&rank,1,MPI_INT,jos,10,&message,1,MPI_INT,dreapta,10,comm,&status);
	MPI_Cart_coords(comm, up_z, ndims, coords_up_z); 
	MPI_Cart_coords(comm, right_y, ndims, coords_right_y); 
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<jos<<"(" << coords_up_z[0] << "," << coords_up_z[1] << "," << coords_up_z[2] <<") Received from "<<dreapta<<"(" << coords_right_y[0] << "," << coords_right_y[1] << "," << coords_right_y[2] <<")"<< endl;
	}
if(sus>0 && jos>0 && dreapta>0){
	MPI_Sendrecv(&rank,1,MPI_INT,jos,10,&message,1,MPI_INT,sus,10,comm,&status);
	MPI_Cart_coords(comm, up_z, ndims, coords_up_z); 
	MPI_Cart_coords(comm, down_z, ndims, coords_down_z);  
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<jos<<"(" << coords_up_z[0] << "," << coords_up_z[1] << "," << coords_up_z[2] <<") Received from "<<sus<<"(" << coords_down_z[0] << "," << coords_down_z[1] << "," << coords_down_z[2] <<")"<< endl;
	}
if(stanga<0 && jos<0){
	MPI_Sendrecv(&rank,1,MPI_INT,dreapta,10,&message,1,MPI_INT,sus,10,comm,&status);
	MPI_Cart_coords(comm, right_y, ndims, coords_right_y); 
	MPI_Cart_coords(comm, down_z, ndims, coords_down_z);  
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<dreapta<<"(" << coords_right_y[0] << "," << coords_right_y[1] << "," << coords_right_y[2] <<") Received from "<<sus<<"(" << coords_down_z[0] << "," << coords_down_z[1] << "," << coords_down_z[2] <<")"<< endl;
	}
if(stanga>0 && dreapta>0 && sus>0){
	MPI_Sendrecv(&rank,1,MPI_INT,dreapta,10,&message,1,MPI_INT,stanga,10,comm,&status);
	MPI_Cart_coords(comm, right_y, ndims, coords_right_y); 
	MPI_Cart_coords(comm, left_y, ndims, coords_left_y);  
	cout<<"Transmitere de date : Rank = "<<rank<<"("<< coords[0] << "," << coords[1] << "," << coords[2] <<"): Send to "<<dreapta<<"(" << coords_right_y[0] << "," << coords_right_y[1] << "," << coords_right_y[2] <<") Received from "<<stanga<<"(" << coords_left_y[0] << "," << coords_left_y[1] << "," << coords_left_y[2] <<")"<< endl;
	}
}
}		

MPI_Barrier(MPI_COMM_WORLD);
if(rank == 0)
printf("===Valorile negative semnifica lipsa procesului vecin!\n");
MPI_Finalize();
return 0;
}

