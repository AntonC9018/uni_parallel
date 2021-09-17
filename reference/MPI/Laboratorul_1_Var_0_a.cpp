#include<mpi.h>
#include<stdio.h>
#include<stdlib.h>
/*i- linia j- coloana
 Paralelizarea la nivel de date se face astfel:
 Procesul cu rankul root initializeaza cu valori matricele A si B
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
double ain[numtask], aout[numtask];
int ind_A[numtask];
int ind_B[numtask];
struct {
double val;
int rank;
	   } in[numtask], out[numtask];
		sendcount=numtask;
		reccount=numtask;
srand ( time(NULL) );
  if(myrank==root)
  {
printf("===== Rezultatele programului '%s' =====\n",argv[0]);
  A=(double*)malloc(numtask*numtask*sizeof(double));
  B=(double*)malloc(numtask*numtask*sizeof(double));
  Btr=(double*)malloc(numtask*numtask*sizeof(double));
   /*for(int i=0;i<numtask*numtask;i++){
  A[i]=rand()/1000000000.0;
  B[i]=rand()/1000000000.0;
	A[i]=1;
	B[i]=1;
   }*/
/*A[0]=2;
A[1]=0;
A[2]=1;
A[3]=1;
A[4]=2;
A[5]=0;
A[6]=0;
A[7]=1;
A[8]=2;
B[0]=1;
B[1]=0;
B[2]=2;
B[3]=2;
B[4]=1;
B[5]=0;
B[6]=0;
B[7]=2;
B[8]=1;*/ 
A[0]=400;
A[1]=0;
A[2]=0;
A[3]=0;
A[4]=0;
A[5]=0;
A[6]=300;
A[7]=300;
A[8]=0;
A[9]=0;
A[10]=0;
A[11]=0;
A[12]=200;
A[13]=200;
A[14]=200;
A[15]=0;
A[16]=0;
A[17]=0;
A[18]=100;
A[19]=100;
A[20]=100;
A[21]=100;
A[22]=0;
A[23]=0;
A[24]=0;
A[25]=0;
A[26]=0;
A[27]=0;
A[28]=0;
A[29]=0;
A[30]=-100;
A[31]=-100;
A[32]=-100;
A[33]=-100;
A[34]=-100;
A[35]=-100;
B[0]=0;
B[1]=200;
B[2]=100;
B[3]=0;
B[4]=-100;
B[5]=-200;
B[6]=0;
B[7]=0;
B[8]=100;
B[9]=0;
B[10]=-100;
B[11]=-200;
B[12]=0;
B[13]=0;
B[14]=0;
B[15]=0;
B[16]=-100;
B[17]=-200;
B[18]=0;
B[19]=0;
B[20]=0;
B[21]=0;
B[22]=-100;
B[23]=-200;
B[24]=0;
B[25]=0;
B[26]=0;
B[27]=0;
B[28]=0;
B[29]=-200;
B[30]=0;
B[31]=0;
B[32]=0;
B[33]=0;
B[34]=0;
B[35]=0;
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
	printf("B[%d,%d]=%.2f ",i,j,B[i*numtask+j]);
	}
	printf("\n");
	MPI_Barrier(MPI_COMM_WORLD);
  }
  else MPI_Barrier(MPI_COMM_WORLD);
MPI_Scatter(A, sendcount, MPI_DOUBLE,ain, reccount, MPI_DOUBLE, root, MPI_COMM_WORLD);
for (i=0; i<numtask; ++i) 
	{
	in[i].val = ain[i];
	in[i].rank = myrank;
	}
MPI_Reduce(in,out,numtask,MPI_DOUBLE_INT,MPI_MAXLOC,root,MPI_COMM_WORLD);
if (myrank == root) 
	{printf("\n");
	printf("Valorile maximale de pe coloane si indicele liniei:\n");
	for (int j=0; j<numtask; ++j) {
	aout[j] = out[j].val;
	ind_A[j] = out[j].rank; 
	printf("Coloana %d, valoarea=  %.2f, linia= %d\n",j, aout[j],ind_A[j]); }
	}
	MPI_Scatter(Btr, sendcount, MPI_DOUBLE,ain, reccount, MPI_DOUBLE, root, MPI_COMM_WORLD);
for (i=0; i<numtask; ++i) 
	{
	in[i].val = ain[i];
	in[i].rank = myrank;
	}
MPI_Reduce(in,out,numtask,MPI_DOUBLE_INT,MPI_MAXLOC,root,MPI_COMM_WORLD);
if (myrank == root) 
	{printf("\n");
	printf("Valorile maximale de pe linii si indicele coloanei:\n");
	for (i=0; i<numtask; ++i) {
	aout[i] = out[i].val;
	ind_B[i] = out[i].rank; 
	printf("Linii %d, valoarea=  %.2f, coloane= %d\n",i, aout[i],ind_B[i]); }
	}
	if(myrank == root){
	int k = 0;
	for(int j=0; j<numtask; j++)
	{
		for(i=0;i<numtask;i++){
			if(j==ind_B[i] && i==ind_A[j]){
				k=k+1;
				printf("Situatiile Nash de  ecilibru sunt: (%d.%d),\n", ind_A[j], ind_B[i]);
				
			}
		}
	}
	if(k==0) printf("Nu exista situatii Nash de echilibru\n");
}
MPI_Finalize();
return 0;
}

