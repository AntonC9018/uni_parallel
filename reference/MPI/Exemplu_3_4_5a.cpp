/*====
In acest program se determina elementele maximale de pe coloanele unei matrici patrate (dimensiunea este egala cu 
numarul de procese). Liniile matricei sunt initializate de fiecare proces in parte. Procesul cu rankul 0 in baza 
acestor linii "construieste" matricea.
Se utilizeaza functia MPI_Reduce si operatia MPI_MAX 
====*/
#include<mpi.h>
#include<stdio.h>
#include<stdlib.h>
int main(int argc, char *argv[])
{
int numtask,sendcount,reccount,source;
double *A,*Max_Col;
int i, myrank, root=0;
MPI_Init(&argc,&argv);
MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
MPI_Comm_size(MPI_COMM_WORLD, &numtask);
double Rows[numtask];	
sendcount=numtask;
reccount=numtask;
	if(myrank==root)
	{
    printf("\n=====REZULTATUL PROGRAMULUI '%s' \n",argv[0]); 
	A=(double*)malloc(numtask*numtask*sizeof(double));
    Max_Col=(double*)malloc(numtask*sizeof(double));
	}
	sleep(myrank);//pentru numere aleatoare diferite
srand(time(NULL));
	for(int i=0;i<numtask;i++)
	Rows[i]=rand()/1000000000.0;
	printf("Tipar datele initiale ale procesului cu rankul %d \n",myrank);
	for(int i=0;i<numtask;i++)
	{
	printf("Rows[%d]=%5.2f ",i,Rows[i]);
	}
	printf("\n");
	MPI_Barrier(MPI_COMM_WORLD); 
	MPI_Gather(Rows, sendcount, MPI_DOUBLE, A, reccount, MPI_DOUBLE, root, MPI_COMM_WORLD);
if(myrank==root){
printf("\n");
printf("Resultatele f-tiei MPI_Gather ");
for(int i=0;i<numtask;i++)
        {
        printf("\n");
        for(int j=0;j<numtask;j++)
        printf("A[%d,%d]=%5.2f ",i,j,A[i*numtask+j]);
        }
        printf("\n");
        MPI_Barrier(MPI_COMM_WORLD);
        }
        else MPI_Barrier(MPI_COMM_WORLD);   
MPI_Reduce(Rows,Max_Col,numtask,MPI_DOUBLE,MPI_MAX,root,MPI_COMM_WORLD);
if (myrank==root) {
for(int i=0;i<numtask;i++)
       {
         printf("\n");
         printf("Elementul maximal de pe coloana %d = %5.2f ",i,Max_Col[i]);
        }
        printf("\n");
        MPI_Barrier(MPI_COMM_WORLD); }
        else MPI_Barrier(MPI_COMM_WORLD);  
 MPI_Finalize();
return 0;
}
