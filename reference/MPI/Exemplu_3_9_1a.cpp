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

*/
#include <mpi.h>
#include <stdio.h>
int main(int argc,char**argv) {
	int rank,count,x,amode,i,j;
	MPI_File OUT;
	MPI_Aint rowsize;
	MPI_Datatype etype,ftype0,ftype1,ftype2;
	int value[4][8];
	int myval[4][8];
	MPI_Status state;
	MPI_Datatype MPI_ROW;
	int blengths[2]={0,1};
	MPI_Datatype types[2];
	MPI_Aint disps[2];
	MPI_Init(&argc,&argv);
		MPI_Comm_rank(MPI_COMM_WORLD,&rank);
		amode=MPI_MODE_DELETE_ON_CLOSE;
			MPI_File_open(MPI_COMM_WORLD,"array.dat",amode,MPI_INFO_NULL,&OUT);
			MPI_File_close(&OUT);
		//amode=MPI_MODE_CREATE | MPI_MODE_WRONLY;
amode=MPI_MODE_CREATE|MPI_MODE_RDWR;
			MPI_File_open(MPI_COMM_WORLD,"array.dat",amode,MPI_INFO_NULL,&OUT);
		// Array Program (derived datatypes)
		MPI_Type_contiguous(8,MPI_INT,&MPI_ROW); 
		MPI_Type_commit(&MPI_ROW);
		etype=MPI_ROW;
		ftype0=MPI_ROW;
		types[0]=types[1]=MPI_ROW;
		disps[0]=(MPI_Aint) 0;
		MPI_Type_extent(MPI_ROW,&rowsize); //<==> 8*sizeof(int)
		disps[1]=2*rowsize;
		MPI_Type_struct(2,blengths,disps,types,&ftype1);
		MPI_Type_commit(&ftype1);
		disps[1]=3*rowsize;
		MPI_Type_struct(2,blengths,disps,types,&ftype2);
		MPI_Type_commit(&ftype2);
		if (rank==0) {
			MPI_File_set_view(OUT,0,etype,ftype0,"native",MPI_INFO_NULL);}
		if (rank==1) {
			MPI_File_set_view(OUT,0,etype,ftype1,"native",MPI_INFO_NULL);}
		if (rank==2) {
			MPI_File_set_view(OUT,0,etype,ftype2,"native",MPI_INFO_NULL);}
		// Array Program (parallel writes)
		for (i=1;i<=4;++i)
			for (j=1;j<=8;++j)
				value[i-1][j-1]= 10*i+j;
		count=0;
		
		if (rank==0) {
			MPI_File_write(OUT,&value[rank][0],1,MPI_ROW,&state);
			MPI_Get_count(&state,MPI_ROW,&x);
			count=count+x;
			MPI_File_write(OUT,&value[rank+1][0],1,MPI_ROW,&state);
			MPI_Get_count(&state,MPI_ROW,&x);
			count=count+x;
			printf("P:%d %d etypes written\n",rank,count);
		}
		if (rank==1)
			{
				MPI_File_write(OUT,&value[rank+1][0],1,MPI_ROW,&state);
				MPI_Get_count(&state,MPI_ROW,&count);
				printf("P:%d %d etypes written\n",rank,count);
			}
		if (rank==2)
			{
				MPI_File_write(OUT,&value[rank+1][0],1,MPI_ROW,&state);
				MPI_Get_count(&state,MPI_ROW,&count);
				printf("P:%d %d etypes written\n",rank,count);
			}
		if (rank==3) {
			MPI_File_set_view(OUT,0,etype,ftype0,"native",MPI_INFO_NULL);}
		if (rank==4) {
			MPI_File_set_view(OUT,0,etype,ftype1,"native",MPI_INFO_NULL);}
		if (rank==5) {
			MPI_File_set_view(OUT,0,etype,ftype2,"native",MPI_INFO_NULL);}

		// Array Program (parallel reads)
		if (rank==3) {
			MPI_File_read(OUT,&myval[0][0],1,MPI_ROW,&state);
			MPI_File_read(OUT,&myval[1][0],1,MPI_ROW,&state);
		}
		if (rank==4) {
			MPI_File_read(OUT,&myval[2][0],1,MPI_ROW,&state);
		}
		if (rank==5) {
			MPI_File_read(OUT,&myval[3][0],1,MPI_ROW,&state);
		}
		MPI_Barrier(MPI_COMM_WORLD);
if(rank > 2 && rank <6)
{
		if(rank==3)
		{
			printf("===Procesul %d a citit din fisier rindurile\n",rank);
			for(int i = 0; i<2; i++)
			{
				for(int j = 0; j<8; j++)
					printf("%d\t", myval[i][j]);
				printf("\n");
			}
		}
		if(rank==4)
		{
			printf("===Procesul %d a citit din fisier rindurile\n",rank);
			for(int j = 0; j<8; j++)
			{
				printf("%d\t", myval[2][j]);
			}
			printf("\n");
		}	
		if(rank==5)
		{
			printf("===Procesul %d a citit din fisier rindurile\n",rank);
			for(int j = 0; j<8; j++)
			{
				printf("%d\t", myval[3][j]);
			}
			printf("\n");
		}		
}
	MPI_File_close(&OUT);
	MPI_Finalize(); 
}
/* ============ Rezultatele posibile 
[hancu@hpc hancu_2008]$ /opt/openmpi/bin/mpirun -np 3 -host compute-0-1 MPI_io.exe
P:0 2etypeswritten
P:1 1etypeswritten
P:2 1etypeswritten
[hancu@hpc hancu_2008]$ od -dx array.dat
0000000    11     0    12     0    13     0    14     0
        000b 0000 000c 0000 000d 0000 000e 0000
0000020    15     0    16     0    17     0    18     0
        000f 0000 0010 0000 0011 0000 0012 0000
0000040    21     0    22     0    23     0    24     0
        0015 0000 0016 0000 0017 0000 0018 0000
0000060    25     0    26     0    27     0    28     0
        0019 0000 001a 0000 001b 0000 001c 0000
0000100    31     0    32     0    33     0    34     0
        001f 0000 0020 0000 0021 0000 0022 0000
0000120    35     0    36     0    37     0    38     0
        0023 0000 0024 0000 0025 0000 0026 0000
0000140    41     0    42     0    43     0    44     0
        0029 0000 002a 0000 002b 0000 002c 0000
0000160    45     0    46     0    47     0    48     0
        002d 0000 002e 0000 002f 0000 0030 0000
0000200
[hancu@hpc hancu_2008]$ od -d array.dat
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

