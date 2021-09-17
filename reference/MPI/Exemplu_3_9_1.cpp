/*
          Sample Array Program
• In parallel, write out a 4x8 array of integers to a file. Use 3 MPI processes
• Filled file will contain each row of the array in consecutive order
• Individual MPI process views:
 – P0 write out first two rows
 – P1 write out shifted third row
 – P2 write out (more) shifted fourth row
• File pointer positioning done by making derived datatypes for ftype
• Program illustrates other MPI-I/O features   as well …
p3 va citi din fisier primele 2 randui si le va tipari 
p4 va citi din fisier rindul al treilea si le va tipari
p5 va citi din fisier rindul al treilea si le va tipari
*/
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc,char**argv) {
int rank,count,x,amode,i,j;
MPI_File OUT,IN;
MPI_Aint rowsize;
MPI_Datatype etype,ftype0,ftype1,ftype2;
MPI_Status *status;
int value[4][8];
MPI_Status state;
MPI_Datatype MPI_ROW;
int blengths[2]={0,1};
MPI_Datatype types[2];
MPI_Aint disps[2];
MPI_Init(&argc,&argv);
MPI_Comm_rank(MPI_COMM_WORLD,&rank);
if (rank ==0)
printf("\n=====REZULTATUL PROGRAMULUI '%s' \n",argv[0]); 
MPI_Barrier(MPI_COMM_WORLD);
MPI_Type_contiguous(8,MPI_INT,&MPI_ROW);
MPI_Type_commit(&MPI_ROW);
etype=MPI_ROW;
ftype0=MPI_ROW;
types[0]=types[1]=MPI_ROW;
disps[0]=(MPI_Aint) 0;
MPI_Type_extent(MPI_ROW,&rowsize);
disps[1]=2*rowsize;
MPI_Type_struct(2,blengths,disps,types,&ftype1);
MPI_Type_commit(&ftype1);
disps[1]=3*rowsize;
MPI_Type_struct(2,blengths,disps,types,&ftype2);
MPI_Type_commit(&ftype2);
	amode=MPI_MODE_DELETE_ON_CLOSE;
	MPI_File_open(MPI_COMM_WORLD,"array.dat",amode,MPI_INFO_NULL,&OUT);
	MPI_File_close(&OUT);
	//amode=MPI_MODE_CREATE | MPI_MODE_WRONLY;
amode=MPI_MODE_CREATE|MPI_MODE_RDWR;
	MPI_File_open(MPI_COMM_WORLD,"array.dat",amode,MPI_INFO_NULL,&OUT);
	if (rank==0) {
	MPI_File_set_view(OUT,0,etype,ftype0,"native",MPI_INFO_NULL);
			}
	if (rank==1) {
	MPI_File_set_view(OUT,0,etype,ftype1,"native",MPI_INFO_NULL);
			}
	if (rank==2) {
	MPI_File_set_view(OUT,0,etype,ftype2,"native",MPI_INFO_NULL);
			}
	for (i=1;i<=4;++i)
	for (j=1;j<=8;++j)
	value[i-1][j-1]= 10*i+j;
	count=0;
//sleep(2*rank);
	if (rank==0) 
	{
	MPI_File_write(OUT,&value[rank][0],1,MPI_ROW,&state);
	MPI_Get_count(&state,MPI_ROW,&x);
	count=count+x;
	MPI_File_write(OUT,&value[rank+1][0],1,MPI_ROW,&state);
	MPI_Get_count(&state,MPI_ROW,&x);
	count=count+x;
	printf("Procesul %d a realizat %d inscrieri(etypes) \n",rank,count);
	}
	if(rank > 0 && rank <3)
	{
	MPI_File_write(OUT,&value[rank+1][0],1,MPI_ROW,&state);
	MPI_Get_count(&state,MPI_ROW,&count);
	printf("Procesul %d a realizat %d inscrieri(etypes) \n",rank,count);
	}
//	MPI_File_close(&OUT);
//amode=MPI_MODE_RDONLY;
//MPI_File_open(MPI_COMM_WORLD,"array.dat",amode,MPI_INFO_NULL,&OUT);

	if (rank==3) {
	MPI_File_set_view(OUT,0,etype,ftype0,"native",MPI_INFO_NULL);
	//int buff1[16];
	int *buff1 = (int*)malloc(sizeof(int)*16);
	MPI_File_read(OUT,buff1,2,MPI_ROW,status);
	printf("===Procesul %d a citit din fisier rindurile\n",rank);
	for(int i = 0; i!=2; ++i)
	{
	for(int j = 0; j != 8; ++j)
		printf("%5d",buff1[i*8 + j]);
	printf("\n");
	}
			}
	if (rank==4) {
	MPI_File_set_view(OUT,0,etype,ftype1,"native",MPI_INFO_NULL);
	int buff2[8];
	MPI_File_read(OUT,buff2,1,MPI_ROW,status);
	printf("===Procesul %d a citit din fisier rindurile\n",rank);
	for(int j = 0; j != 8; ++j)
		printf("%5d",buff2[j]);
	printf("\n");
			  }
	if (rank==5) {
	MPI_File_set_view(OUT,0,etype,ftype2,"native",MPI_INFO_NULL);
	//int buff3[8];
	int *buff3 = (int*)malloc(sizeof(int)*8);
	MPI_File_read(OUT,buff3,1,MPI_ROW,status);
	printf("===Procesul %d a citit din fisier rindurile\n",rank);
	for(int j = 0; j != 8; ++j)
		printf("%5d",buff3[j]);
	printf("\n");
			   }
	MPI_File_close(&OUT);
MPI_Finalize(); 
}
/* ============ Rezultatele posibile 
[Hancu_B_S@hpc Notate_Exemple]$ /opt/openmpi/bin/mpiCC -o Exemplu_3_9_1.exe Exemplu_3_9_1.cpp
[Hancu_B_S@hpc Notate_Exemple]$ /opt/openmpi/bin/mpirun -n 6 -machinefile ~/nodes4  Exemplu_3_9_1.exe

=====REZULTATUL PROGRAMULUI 'Exemplu_3_9_1.exe' 
Procesul 1 a realizat 1 inscrieri(etypes) 
Procesul 2 a realizat 1 inscrieri(etypes) 
Procesul 0 a realizat 2 inscrieri(etypes) 
===Procesul 4 a citit din fisier rindurile
   31   32   33   34   35   36   37   38
===Procesul 5 a citit din fisier rindurile
   41   42   43   44   45   46   47   48
===Procesul 3 a citit din fisier rindurile
   11   12   13   14   15   16   17   18
   21   22   23   24   25   26   27   28

[Hancu_B_S@hpc Notate_Exemple]$ od -d array.dat
0000000    11     0    12     0    13     0    14     0
0000020    15     0    16     0    17     0    18     0
0000040    21     0    22     0    23     0    24     0
0000060    25     0    26     0    27     0    28     0
0000100    31     0    32     0    33     0    34     0
0000120    35     0    36     0    37     0    38     0
0000140    41     0    42     0    43     0    44     0
0000160    45     0    46     0    47     0    48     0
0000200

*/

