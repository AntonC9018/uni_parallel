/* In acest program:
1) se creaza un comunicator cu topologie carteziana de tip cub;
2) se fixeaza oriace dintre 6 fatete ale cubului si se determina vecinii pentru procesele care apartin muchiilor
   acestei fatete (in directia miscarii acelor de ceas pe planul fatetei).
3) pentru cubul de dimensiunea 2 ( adica size=8) se realizeaza transmiterea datelor pe cerc intre procesele de pe muchiile fatetei fixate ale cubului.
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
	MPI_Status status;  
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
	MPI_Cart_create(MPI_COMM_WORLD, ndims, dims, periods, reorder, &comm);
	MPI_Cart_coords(comm, rank, ndims, coords); 
	
// Variabilele pentru alegerea fatetelor cubului
int axa_fateta;// indica valoarea fixata a ordonate (x,sau y sau z)
int v;
char axa,Y,Z;
int axa1,axa2;//indica axele pentru deplasarea de date
// se fixeaza o fateta a cubukui
int numar_fateta;
if(rank == 0){
printf("\n===== REZULTATUL PROGRAMULUI '%s' \n",argv[0]); 
printf(" Alegeti numarul fatetei cubului (un numar de la 1 la 6)\n"); 
printf(" fateta YZ pentru x maximal-> 1;  fateta YZ pentru x minimal-> 2; fateta XY pentru z maximal-> 3; fateta XY pentru z minimal-> 4; fateta XZ pentru y maximal-> 5; fateta XZ pentru y minimal-> 6;\n"); 
 cin >> numar_fateta;
}
 MPI_Bcast(&numar_fateta, 1, MPI_INT, 0, MPI_COMM_WORLD);
if (numar_fateta==1)// fateta YZ pentru x maximal
	{
	axa_fateta=0;
	v=1;
	axa1=1;
	axa2=2;
	axa='x';
	Y='Y'; Z='Z';
	} 
if (numar_fateta==2)// fateta YZ pentru x minimal
	{
	axa_fateta=0;
	v=dims[axa_fateta];
	axa1=1;
	axa2=2;
	axa='x';
	Y='Y'; Z='Z';
	} 	
if (numar_fateta==3)// fateta XY pentru z maximal
	{
	axa_fateta=2;
	v=1;
	axa1=1;
	axa2=0;
	axa='z';
	Y='Y'; Z='X';
	} 
	
if (numar_fateta==4)// fateta XY pentru z minimal
	{
	axa_fateta=2;
	v=dims[axa_fateta];
	axa1=1;
	axa2=0;
	axa='z';
	Y='Y'; Z='X';
	} 
if (numar_fateta==5)// fateta XZ pentru y maximal
	{
	axa_fateta=1;
	v=1;
	axa1=2;
	axa2=0;
	axa='y';
	Y='Z'; Z='X';
	} 
if (numar_fateta==6)// fateta XZ pentru yminimal
	{
	axa_fateta=1;
	v=dims[axa_fateta];
	axa1=2;
	axa2=0;
	axa='y';
	Y='Z'; Z='X';
	} 						
	if(rank == 0)
	{
			 	
		for ( int i = 0; i < 3; i++ )
		{
			cout << "Numarul de procese pe axa "<< i<< " este "<< dims[i] << "; ";
			cout << endl;
		}	
		cout << "===Rankul si coordonatele proceselor de pe fateta laterala a paralelepipedului pentru " <<axa<< "= " << dims[axa_fateta]-v << " ";
		cout << endl; 
	}
	MPI_Barrier(MPI_COMM_WORLD);
	
	if(coords[axa_fateta] == dims[axa_fateta]-v)
		cout << "Procesul cu rankul " << rank << " are coordonatele (" << coords[0] << "," << coords[1] << "," << coords[2] <<")"<< endl;   
	MPI_Barrier(MPI_COMM_WORLD);
	if(rank == 0)
	{
		cout << "===Vecinii proceselor de pe muchiile fatetei laterali a paralelepipedului pentru " <<axa<< "= "<< dims[axa_fateta]-v << " ";
		cout << endl;
	}
	sleep(rank);
	if(coords[axa_fateta] == dims[axa_fateta]-v)
	{
// in "if" este conditia pentru procesele de pe muchii (se exclud cele din interiorul fatetei)
		if (!(((0<coords[axa1])&&(0<coords[axa2]))&&((coords[axa1]<dims[axa1]-1)&&(coords[axa2]<dims[axa2]-1))))
		{
			printf("Sunt procesul cu rankul %d (%d,%d,%d) vecinii mei sunt: \n",rank,coords[0],coords[1],coords[2]);

// se determina vecinii pe muchia y,pentru x=dims[0]-1 si z=0 si pe muchia y,pentru x=dims[0]-1 si z=dims[2]-1
			if ((coords[axa2]==0)||(coords[axa2]==dims[axa2]-1))
			{
				MPI_Cart_shift(comm,axa1,-1,&left_y,&right_y);
			
	
			if (left_y<0) {coords_left_y[0]=-1; coords_left_y[1]=-1;coords_left_y[2]=-1;}
			else {MPI_Cart_coords(comm, left_y, ndims, coords_left_y); }
			if (right_y<0) {coords_right_y[0]=-1;coords_right_y[1]=-1;coords_right_y[2]=-1;}
			else {MPI_Cart_coords(comm, right_y, ndims, coords_right_y); }
			printf("   pe directia axei %c : la stanga %d(%d,%d,%d) la dreapta %d(%d,%d,%d) \n",Y,left_y,coords_left_y[0],coords_left_y[1],coords_left_y[2],right_y,coords_right_y[0],coords_right_y[1],coords_right_y[2]);
			}

// se determina vecinii pe muchia z,pentru x=dims[0]-1 si y=0 si pe muchia z,pentru x=dims[0]-1 si y=dims[1]-1 
			if ((coords[axa1]==0)||(coords[axa1]==dims[axa1]-1)) 
			{ 
				MPI_Cart_shift(comm,axa2,-1,&up_z,&down_z);

			if (up_z<0) {coords_up_z[0]=-1; coords_up_z[1]=-1;coords_up_z[2]=-1;}
			else {MPI_Cart_coords(comm, up_z, ndims, coords_up_z); }
			if (down_z<0) {coords_down_z[0]=-1;coords_down_z[1]=-1;coords_down_z[2]=-1;}
			else {MPI_Cart_coords(comm, down_z, ndims, coords_down_z); }
			printf("   pe directia axei %c : sus  %d(%d,%d,%d) jos %d(%d,%d,%d) \n",Z,up_z,coords_up_z[0],coords_up_z[1],coords_up_z[2],down_z,coords_down_z[0],coords_down_z[1],coords_down_z[2]); 
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
