#include<mpi.h>
#include<stdio.h>
#include<stdlib.h>
//j - indicele coloanelor
//i - indicele liniilor
/* Paralelizarea la nivel de date se face astfel:
procesul cu rankul i initializeaza linia i a matricei A si coloana j a matricei B
*/
void invertMatrix(double *m, int mRows, int mCols, double *rez)
{
	for (int i = 0; i < mRows; ++i)
		for (int j = 0; j < mCols; ++j)
			rez[j * mRows + i] = m[i * mCols + j];
}

int main(int argc, char *argv[])
{
  	int numtask,sendcount,reccount,source;
	double *A, *B, *Btr;
	int i, myrank, root=1;
	MPI_Init(&argc,&argv);
	MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
	MPI_Comm_size(MPI_COMM_WORLD, &numtask);
	double rows[numtask],col[numtask];
double ain[numtask], aout[numtask];
int ind_A[numtask], ind_B[numtask];
struct {
double val;
int rank;
	   } in[numtask], out[numtask];
		sendcount=numtask;
		reccount=numtask;
  if(myrank==root)
  {
printf("===== Rezultatele programului '%s' =====\n",argv[0]);
  A=(double*)malloc(numtask*numtask*sizeof(double));
  B=(double*)malloc(numtask*numtask*sizeof(double));
  Btr=(double*)malloc(numtask*numtask*sizeof(double));}
srand ( time(NULL) );
  for(int i=0;i<numtask;i++){
  	  rows[i]=rand()/1000000000.0;
  	  col[i]=rand()/1000000000.0;
  }


  MPI_Gather(rows, sendcount, MPI_DOUBLE, A, reccount, MPI_DOUBLE, root, MPI_COMM_WORLD);
  MPI_Gather(col, sendcount, MPI_DOUBLE, B, reccount, MPI_DOUBLE, root, MPI_COMM_WORLD);
  if (myrank==root)
  {
    
  invertMatrix(B, numtask, numtask, Btr);
  printf("Tipar datele initiale\n");
  for(int i=0;i<numtask;i++)
	{
	printf("\n");
	for(int j=0;j<numtask;j++)
	printf("A[%d,%d]=%.2f ",i,j,A[i*numtask+j]);
	}
	printf("\n");

	for(int i=0;i<numtask;i++)
	{
	printf("\n");
	for(int j=0;j<numtask;j++)
	printf("Btr[%d,%d]=%.2f ",i,j,Btr[i*numtask+j]);
	}
	printf("\n");

	MPI_Barrier(MPI_COMM_WORLD);
  }
  else MPI_Barrier(MPI_COMM_WORLD);
for (i=0; i<numtask; ++i) 
	{
	in[i].val = rows[i];
	in[i].rank = myrank;
	}
MPI_Reduce(in,out,numtask,MPI_DOUBLE_INT,MPI_MAXLOC,root,MPI_COMM_WORLD);
if (myrank == root) 
	{printf("\n");
	printf("Valorile maximale de pe coloane si indicele liniei:\n");
	for (int j=0;j<numtask; ++j) {
	aout[j] = out[j].val;
	ind_A[j] = out[j].rank; 
	printf("Coloana %d, valoarea=  %.2f, linia= %d\n",j, aout[j],ind_A[j]); }
	}

for (i=0; i<numtask; ++i) 
	{
	in[i].val = col[i];
	in[i].rank = myrank;
	}
MPI_Reduce(in,out,numtask,MPI_DOUBLE_INT,MPI_MAXLOC,root,MPI_COMM_WORLD);
if (myrank == root) 
	{printf("\n");
	printf("Valorile maximale de pe coloane si indicele liniei:\n");
	for (i=0; i<numtask; ++i) {
	aout[i] = out[i].val;
	ind_B[i] = out[i].rank; 
	printf("Coloana %d, valoarea=  %.2f, linia= %d\n",i, aout[i],ind_B[i]); }
	}

if(myrank == root){
	int num_resolve = 0;
	for(int j=0; j<numtask; j++){
		for(int i=0; i < numtask; i++){
			if(i == ind_A[j] && j == ind_B[i]){
				printf("Situatiile Nash de echilibru sunt:(%d , %d) \n", ind_A[j], ind_B[i]);
				num_resolve++;
			}
		}
	}

	if(num_resolve == 0){
		printf("%s\n", "Nu exista situatii Nash de echilibru");
	}
}
MPI_Finalize();
return 0;
}

