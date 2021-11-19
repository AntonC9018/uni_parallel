/*
==========================================================================
|                       Sarcina 8 (L11Ex3)                               |
==========================================================================
| Să se elaboreze un program în care se construieşte o matrice transpusă |
| utilizând proceduri de generare a tipurilor de date.                   |
==========================================================================

Dacă înțeleg sarcina corect, se cere să fac următorul lucru:
1. Să construiesc un tip de date pentru N coloane.
2. Să le primesc ca rânduri la root.

Astfel matricea ar veni la root transpusă.

Problemele de implementare sunt următoarele:
1. Numărul de linii sau coloane poate să nu fie egal la procese,
2. Cum să transmitem mai multe coloane deoadată? 
   Cum să le scriem în buferul în care le primim în mod secvențial?

La început am încercat să soluționez problema creând un tip de date vector,
pentru toate rândurile destinate procesului. Însă întrebarea atunci este cum să le primim
liniar? Am încercat să folosesc funcția MPI_Gatherv, însă ea scria elementele în mod incorect.

Deci un exemplu. Presupunem că avem matricea:

  0  1  2
  3  4  5
  6  7  8

Procesul 0 primește prima coloană, iar procesul doi primește coloanele 1 și 2.

 p0 p1 p1
  0  1  2
  3  4  5
  6  7  8

În urma operației MPI_Gatherv, p0 își scrie coloana corect:

  0  3  6
  -  -  -
  -  -  -

Iar procesul p1 își scrie coloanele în mod linia - coloana, adică indicii de coloană schimbă primii.

  -  -  -
  1  2  4
  5  7  8

Evident, rezultatul este incorect.

Am citit acest punct din specificație din nou, și îmi pare că este imposibil de făcut acest lucru 
cu mai multe coloane print-o singură apelare la Gather. Sau o soluție există, dar ceva foarte neintuitiv.

Altele idei sunt: 
1. De creat un tip de date prin concatenarea de așa două vectori, care reprezintă câte o
coloană fiecare, însă atunci (probabil, intuitiv) datele vor fi oricum trimise în ordinea în care ele 
stau în memorie. 
2. De transmis liniile, iar de primit coloanele, dar aceasta probabil nu va lucra, deoarece
dacă primim mai multe coloane, poziția coloanei 2 ar fi considerată 0 + extent(coloana), deci
de fapt va ieși imediat din limitele matricii. 
3. De transmis mai multe coloane cu parametrul count. Iarăși, probabil nu va lucra din cauză lui extent(coloana).

Am soluționat problema transmitând câte o coloană de fiecare dată (pare că este imposibil să transmit mai multe).
(Tipul de date utilizat este deja doar o singură coloană, dar nu toate cele alocate procesului.)
Fac un ciclu la fiecare proces, transmitând cu gather o singură coloană de pe indice curent.

Clar că problema în acest caz este ultima iterație, unde nu toate procese pot transmite datele.
Așa că funcția Gather este colectivă, nu pot simplu să nu o apelez la toate procesele.
Încă, aparent este imposibil s-o apelez cu 0 ca count-ul lui send buffer (îmi dădea o eroare).
Deci am soluționat prin crearea unui comunicator, constituit din acele procese care vor face ultima iterație.
Ultima iterație o consider inexistentă dacă numărul de coloane este divizibil cu numărul de procese.

*/

immutable height = 4;
immutable width = 5;
int[height * width] createMatrix()
{
    typeof(return) result;
    size_t index = 0;
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        result[index++] = rowIndex * 10 + colIndex;
    }
    return result;
}
immutable MatrixData = createMatrix();

void main()
{
    import mpi;
    import std.stdio;
    import std.algorithm;
    import std.range;
    static import mh = mpihelper;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    if (info.rank == 0)
    {
        writeln("Initial matrix:");
        mh.printAsMatrix(MatrixData, width);
    }

    // MPI_Type_vector(blockLength, blockCount, stride)
    auto singleColumnType = mh.createVectorDatatype!int(1, height, width);
    
    int[] rootReceiveBuffer;
    if (info.rank == 0)
        rootReceiveBuffer = new int[](width * height);

    // We must only have the last couple of processes sending the last batch of columns.
    int[] ranks = iota(0, width % info.size).array; // [0, 1, .. width % info.size]
    MPI_Group group = mh.createGroupInclude(mh.getGroup(), ranks);
    MPI_Comm lastIterationGroup = mh.createComm(MPI_COMM_WORLD, group);

    size_t counter = 0;
    // for (int columnIndex = info.rank; columnIndex < width; columnIndex += info.size)
    foreach (columnIndex; iota(info.rank, width, info.size))
    {
        MPI_Comm comm = {
            if (columnIndex + info.size > width && info.rank < ranks.length)
                return lastIterationGroup;
            return MPI_COMM_WORLD;
        }();
            
        if (info.rank == 0)
        {
            writeln("Matrix at root at iteration ", counter);
            mh.printAsMatrix(rootReceiveBuffer, height);
            writeln();
        }

        MPI_Gather(
            cast(void*) &MatrixData.ptr[columnIndex], 1, singleColumnType.id,
            cast(void*) &rootReceiveBuffer.ptr[columnIndex * height], height, MPI_INT, 
            0, comm);
        counter++;
    }
    mh.barrier();
    if (info.rank == 0)
    {
        writeln("Final matrix:");
        mh.printAsMatrix(rootReceiveBuffer, height);
    }
}

/*

Numărul de procese nu este divizibil cu numărul de coloane:

$ ./compile.sh atestare_2
$ mpirun -np 3 -host "compute-0-0" atestare_2.out
Initial matrix:
  0  1  2  3  4
 10 11 12 13 14
 20 21 22 23 24
 30 31 32 33 34
Matrix at root at iteration 0
  0  0  0  0
  0  0  0  0
  0  0  0  0
  0  0  0  0
  0  0  0  0

Matrix at root at iteration 1
  0 10 20 30
  1 11 21 31
  2 12 22 32
  0  0  0  0
  0  0  0  0

Final matrix:
  0 10 20 30
  1 11 21 31
  2 12 22 32
  3 13 23 33
  4 14 24 34                                                               



Numărul de procese este mai mare decât numărul de coloane:

$ mpirun -np 6 -host "compute-0-0" atestare_2.out
Initial matrix:
  0  1  2  3  4
 10 11 12 13 14
 20 21 22 23 24
 30 31 32 33 34
Matrix at root at iteration 0
  0  0  0  0
  0  0  0  0
  0  0  0  0
  0  0  0  0
  0  0  0  0

Final matrix:
  0 10 20 30
  1 11 21 31
  2 12 22 32
  3 13 23 33
  4 14 24 34

Numărul de procese este egal numărul de coloane:
$ mpirun -np 5 -host "compute-0-0" atestare_2.out
... același output.

*/