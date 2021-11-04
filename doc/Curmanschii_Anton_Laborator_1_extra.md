# Lucrarea de laborator nr.1 la Programarea Paralelă și Distribuită

Tema: **Jocuri bimatriceale si situații Nash de echilibru. EXTRA**

A realizat: **Curmanschii Anton, IA1901**

Vedeți [github-ul](https://github.com/AntonC9018/uni_parallel).


## Sarcina

Vedeți descrierea problemei [aici](https://github.com/AntonC9018/uni_parallel/blob/master/doc/Curmanschii_Anton_Laborator_1.md), ea nu s-a schimbat. 
S-a adăugat doar o restricție: pentru determinarea indicilor elementelor maximale din $ A $ și $ B $ trebuie de folosit operațiile personalizate, create cu `MPI_Op_create` și funcția `MPI_Reduce`.

## Algoritmul

Voi descrie în scurt toate etapele algoritmului elaborat:

1. Rândurile se distribuie între procese, utilizând metrica [creată anterior](https://github.com/AntonC9018/uni_parallel/blob/master/doc/Curmanschii_Anton_Laborator_1.md#matricea-de-orice-dimensiune-toate-maximuri).

2. Datele se amplasează într-un bufer cu un format personalizat. 
   Conține toate numerele destinate procesului, și un vector cu contorii aparițiilor numerelor maximale pentru fiecare coloană.

3. Se creează operația de reducere, utilizând `MPI_Op_create`, care, în urma executării prin `MPI_Reduce`, va calcula numărul 
   de apariții ale elementelor maximale în fiecare coloană, păstrat în vectorul corespunzător, și înșiși valorile maximale după coloană, păstrate în prima linie de intrare, inițial copiată din matrice. 

4. Se execută operația din punctul 3. pentru matricile $ A $ și $ B ^ T $. 
   Rezultatul va ajunge la procesul root.
   Procesul root distribuie aceste valori la celelalte procese, utilizând funcția `MPI_BCast`.

5. Utilizând iarăși datele din matrice, și datele primite în urma primilor pași, se definește mai un format al buferului.
   Conține $ N $ vectori, unde $ N $ este lațimea, care stă unul după altul în memorie, și valorile din matrice, combinate cu indicii după linie asociate lor. 
   Fiecare vector are lungimea, egală cu numărul de elemente maximale pentru coloana asociată lui, și mai un număr pe prima poziție ce ține cont de câte indici deja au fost adăugate în vector.

6. Se creeză încă o operație personalizată, ce performă filtrarea indicelor și amplasarea lor în vectorii menționați.
   Se adaugă în vectori numai indicii acelor elemente, care au fost egale cu elementul maximal pentru coloana dată.

7. Se execută operația dată cu `MPI_Reduce`, umplută cu datele din matricile $ A $ și $ B ^ T $.
   După ce rezultatele ajung la procesul root, el găsește toate punctele de echilibru Nash și le afișează.

8. Aici dacă folosim algoritmul simplu, verificând toate perechile una câte una, algoritmul ar fi $ O(N^2) $.
   Eu am folosit un tablou asociativ, în care la început adaug toate perechile (rând, coloană) maximale din $ A $,
   iar pe urmă, datorită faptului că căutarea este $ O(1) $, mă uit dacă indicii există în tablou.
   Aceasta va fi mai lent pentru tablouri mici, însă pentru tablouri mari cu multe elemente maximale, are sens de folosit așa ceva.
   (Și mai bine ar fi fost să am mai multe așa tablouri pentru fiecare coloană din A, deoarece unul de indici de căutare mereu se cunoaște).


## Realizarea

Nu voi descrie codul, doar voi evidenția momentele legate de operații MPI.

În codul de mai jos, definesc operația personalizată.

Funcția `mh.createOp` apelează `MPI_Op_create`, transmitând pointerul la funcția `firstPassOperationFunction`, și `true` ca valoarea pentru `commute` (este o operație comutativă).

`scope(exit) mh.free` șterge operația apelând `MPI_Op_free`, în momentul când se termină execuția funcția `main` (`scope(exit)` lucrează ca destructori în C++).

```d
auto firstPassOperation = mh.createOp!firstPassOperationFunction(true);
scope(exit) mh.free(firstPassOperation);
```

În codul de mai jos, vedeți executarea primei operații de reducere. 

`stuff` conține multiple date, legate de o matrice dată, $ A $ sau $ B ^ T $.
Setez 2 variabile globale, folosite pentru a afla dimensiunile de intrare.
Funcția `mh.intraReduce` apelează `MPI_Reduce`, iar `firstPassOperation` este operația personalizată.
Funcția `mh.bcast` se apelează de 2 ori, și distribuie datele relevante culese de procesul root la celelalte procese.

```d
void doFirstPass(Stuff)(ref Stuff stuff)
{
    // Set global variables for the function to work properly
    g_currentWidth = stuff.matrix.width;
    g_currentReduceBufferNumRows = stuff.maxRowsPerProcess;
    mh.intraReduce(stuff.reduceBuffer1, firstPassOperation, info.rank, 0);
    mh.bcast(stuff.getFirstPassBufferInfo().maxElementCounts, 0);
    mh.bcast(stuff.getFirstPassBufferInfo().maxElementsRow, 0);
    mh.barrier();
}
doFirstPass(AStuff);
doFirstPass(BStuff);
```

La al doilea pas avem apelări asemănătoare.


## Executarea

Iată un exemplu de executare pe 4 procese, deci procesele primesc un număr diferit de linii.
Matricile sunt ca la exemplu dvs, dar am mai adăugat o linie de -1. Aceste numere nu schimbă rezultatul, ci doar arată că programul nu eșuează și cu dimensiuni neegale la matrici.

```
$ ./compile.sh lab1_op matrix.d
$ mpirun -np 4 -host "compute-0-0" lab1_op.out
Process 0
Whole matrix A:
  4  0  0  0  0  0
  3  3  0  0  0  0
  2  2  2  0  0  0
  1  1  1  1  0  0
  0  0  0  0  0  0
 -1 -1 -1 -1 -1 -1
 -1 -1 -1 -1 -1 -1
Whole matrix B (transposed):
  0  0  0  0  0  0 -1
  2  0  0  0  0  0 -1
  1  1  0  0  0  0 -1
  0  0  0  0  0  0 -1
 -1 -1 -1 -1  0  0 -1
 -2 -2 -2 -2 -2  0 -1
Max rows per process A:
2
Max rows per process B:
2

Number of maximums A:
[1, 1, 1, 1, 5, 5]
Maximums A:
[4, 3, 2, 1, 0, 0]
Number of maximums B:
[1, 1, 4, 4, 5, 6, 6]
Maximums B:
[2, 1, 0, 0, 0, 0, -1]

Process 1
Number of maximums A:
[1, 1, 1, 1, 5, 5]
Maximums A:
[4, 3, 2, 1, 0, 0]
Number of maximums B:
[1, 1, 4, 4, 5, 6, 6]
Maximums B:
[2, 1, 0, 0, 0, 0, -1]

Process 2
Number of maximums A:
[1, 1, 1, 1, 5, 5]
Maximums A:
[4, 3, 2, 1, 0, 0]
Number of maximums B:
[1, 1, 4, 4, 5, 6, 6]
Maximums B:
[2, 1, 0, 0, 0, 0, -1]

Process 3
Number of maximums A:
[1, 1, 1, 1, 5, 5]
Maximums A:
[4, 3, 2, 1, 0, 0]
Number of maximums B:
[1, 1, 4, 4, 5, 6, 6]
Maximums B:
[2, 1, 0, 0, 0, 0, -1]

Indices of max elements on columns of A:
0: [0]
1: [1]
2: [2]
3: [3]
4: [3, 4, 1, 2, 0]
5: [3, 4, 1, 2, 0]
Indices of max elements on rows (columns) of B (B transposed):
0: [1]
1: [2]
2: [3, 1, 2, 0]
3: [3, 1, 2, 0]
4: [4, 3, 1, 2, 0]
5: [4, 5, 3, 1, 2, 0]
6: [4, 5, 3, 1, 2, 0]

Nash equilibrium points:
(2, 2)
(3, 3)
(4, 4)
```

## Întregul code

Întregul cod vedeți [pe github](https://github.com/AntonC9018/uni_parallel/blob/c13c45f21bd80abf968d419beab2340834e68747/source/lab1_op.d).