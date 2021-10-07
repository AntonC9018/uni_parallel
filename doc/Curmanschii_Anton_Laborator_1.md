 Lucrarea de laborator nr.1 la Programarea Paraelelă și Distribuită

Tema: **Jocuri bimatriceale si situatii Nash de echilibru.**
A realizat: **Curmanschii Anton, IA1901**

- [Sarcina](#sarcina)
- [Realizarea](#realizarea)
  - [Matrice](#matrice)
  - [1.a) Procesul 0 inițializează și distribuie.](#1a-procesul-0-inițializează-și-distribuie)
  - [1.b) Fiecare proces își inițializează linia din matrice.](#1b-fiecare-proces-își-inițializează-linia-din-matrice)
  - [Fără MPI_Reduce](#fără-mpi_reduce)
  - [Executarea](#executarea)
  - [Matricea de orice dimensiune, toate maximuri](#matricea-de-orice-dimensiune-toate-maximuri)
  - [Executarea (matricea arbitrară, toate punctele de echilibru)](#executarea-matricea-arbitrară-toate-punctele-de-echilibru)
  - [Inputul în procesul 0, distribuirea valorilor la celelalte procese](#inputul-în-procesul-0-distribuirea-valorilor-la-celelalte-procese)
  - [Executarea (tăstătură — reparat)](#executarea-tăstătură--reparat)

## Sarcina

Fie dat un joc bimatriceal $ \gamma = \langle I, J, A, B \rangle $, unde $I$ — mulțimea de indici ai liniilor matricelor, $J$ — a coloanelor, $ A = {|| a_{ij} ||} _ {j \in J} ^ {i \in I}, B = {|| b_{ij} ||} _ {j \in J} ^ {i \in I} $ reprezintă matricele de câștig ale jucătorilor.

Elementul $ i \in I $ ($ j \in J $), se numește **strategia pură a jucătorului 1 (2)**. 
Perechea de indici $ \(i, j\) $ reprezintă o situație în strategii pure. 
Jocul se realizează astfel: fiecare jucator independent si "concomitent" (adică alegerile de strategii nu depind de timp) 
alege strategia sa, după care se obține o situație în baza căreia jucătorii calculează câștigurile care reprezintă elementul $ a_{ij} $ pentru jucătorul 1 și, respectiv, $ b_{ij} $ pentru jucătorul 2 și cu aceasta jocul ia sfârșit.

Situația de echilibru este perechea de indici $ \(i ^ {\star}, j ^ {\star}\) $ pentru care se verifică sistemul de inegalități:

$$
\(i^\star, j^\star\) \Leftrightarrow
\begin{cases} 
    a_{i^\star j^\star} \geq a_{i j^\star} & \forall i \in I \\\\
    b_{i^\star j^\star} \geq b_{i^\star j} & \forall j \in J
\end{cases}$$

Vom spune că linia $ i $ strict domină linia $ k $ în matricea $ A $ dacă și numai dacă $ a_{ij} > a_{kj}, \forall j \in J $. 
Dacă există $ j $ pentru care inegalitatea nu este strictă, atunci vom spune că linia $ i $ domină (nestrict) linia $ k $. 

Similar, vom spune: coloana $ j $ strict domină coloana $ l $ în matricea $ B $ dacă și numai dacă $ b_{ij} > b_{il}, \forall i \in I $.
Dacă există $ i $ pentru care inegalitatea nu este strictă, atunci vom spune: *coloana $ j $ domină (nestrict) coloana $ l $*.

În baza definiției prezentăm următorul algoritm secvential pentru determinarea situației de echilibru.

**Algoritm 6.1**

- a. În cazul în care **nu se dorește** determinarea tuturor situațiilor de echilibru, se elimină din matricea $ A $ și $ B $ liniile care sunt dominate în matricea $ A $ și se elimină din matricea $ A $ și $ B $ coloanele care sunt dominate în matricea $ B $.
- b. În cazul în care **se dorește** determinarea tuturor situațiilor de echilibru, se elimină din matricea $ A $ și $ B $ liniile care sunt strict dominate în matricea $ A $ și se elimină din matricea $ A $ și $ B $ coloanele care sunt strict dominate în matricea $ B $.
- c. Se determină situațiile de echilibru pentru matricele:
    $ (A^\prime, B^\prime), A^\prime = {|| a^\prime_{ij} ||} ^ {i \in I^\prime} _ {j \in J^\prime},$ și $ B^\prime = {|| b^\prime_{ij} ||} ^ {i \in I^\prime} _ {j \in J^\prime}, $
    obținute din pasul a sau b. Este clar că $| I^\prime | \leq | I |,  | J^\prime | \leq | J |$

    * Pentru orice coloană fixată în matricea $ A $, notăm (evidențiem) toate elementele maximale după linie. 
      Cu alte cuvinte, se determină $ i^\star (j) = Arg \max_{ i \in I^\prime } a^\prime_{ij}, \forall j \in J^\prime $.

    * Pentru orice linie fixată în matricea $ B $, notăm (evidențiem) toate elementele maximale după coloană. 
      Cu alte cuvinte, se determină $ j^\star (i) = Arg \max_{ j \in J^\prime } b^\prime_{ij}, \forall i \in I^\prime $.

    * Selectăm acele perechi de indici care concomitent sunt selectate atât în matricea $ A $ cât și în matricea $ B $.
      Altfel spus, se determină 
      $ \begin{cases} 
        i^\star \equiv i^\star (j^\star) \\\\ 
        j^\star \equiv j^\star (i^\star) 
      \end{cases} $. Pentru aceasta se poate proceda astfel. Se construiește graficul aplicației 
      $ i^\star $, adică $ gr_{i^\star} = \\{ (i,j) : i = i^\star (j), \forall j \in J \\} $ 
      și corespunzător graficul aplicației $ j $, adică
      $ j^\star $, adică $ gr_{j^\star} = \\{ (i,j) : j = j^\star (i), \forall i \in I \\} $.  
      Situațiile de echilibru sunt toate situațiile cate aparțin intersecției acestor doua grafice, 
      adică $ NE = gr_{i^\star} \cap gr_{j^\star} $                 
- d. Se construiesc situațiile de echilibru pentru jocul cu matricele $ A $ și $ B $.

**Exemplul 6.1.**  

Situația de echilibru se determină numai în baza eliminării liniilor și a coloanelor dominate. 
Considerăm următoarele matrici:

$$
A = \begin{pmatrix}
 4  &  0  &  0  &  0  &  0  &  0 \\\\
 3  &  3  &  0  &  0  &  0  &  0 \\\\
 2  &  2  &  2  &  0  &  0  &  0 \\\\
 1  &  1  &  1  &  1  &  0  &  0 \\\\
 0  &  0  &  0  &  0  &  0  &  0 \\\\
-1  & -1  & -1  & -1  & -1  & -1
\end{pmatrix}.
B = \begin{pmatrix}
 0  &  2  &  1  &  0  & -1  & -2 \\\\
 0  &  0  &  1  &  0  & -1  & -2 \\\\
 0  &  0  &  0  &  0  & -1  & -2 \\\\
 0  &  0  &  0  &  0  & -1  & -2 \\\\
 0  &  0  &  0  &  0  &  0  & -2 \\\\
 0  &  0  &  0  &  0  &  0  &  0
\end{pmatrix}.
$$

Vom elimina liniile și coloanele dominate în următoarea ordine: linia 5, coloana 5, linia 4, coloana 4, 
coloana 3, linia 3, coloana 0, linia 0, coloana 1, linia 1. 
Astfel obținem matricele $ A^\prime = (2) $ și $ B^\prime = (0) $, 
și situația de echilibru este $ (i^\star, j^\star) = (2, 2) $ și câștigul jucătorului 1 este 2, al jucătorului 2 este 0. 


**Exemplul 6.2**. 
Considerăm următoarele matrici 
$
A = \begin{pmatrix}
 2 & 0 & 1 \\\\
 1 & 2 & 0 \\\\
 0 & 1 & 2
\end{pmatrix},
B = \begin{pmatrix}
 1 & 0 & 2 \\\\
 2 & 1 & 0 \\\\
 0 & 2 & 1
\end{pmatrix}.
$
În matricea A nu există linii dominate, în matricea B nu există colane dominate.

**Exemplul 6.3.** Considerăm următoarele matrici:
$  A = {|| a_{ij} ||} _ {j \in J} ^ {i \in I} , B = {|| b_{ij} ||} _ {j \in J} ^ {i \in I} ,$
unde $ a_{ij} = c, b_{ij} = k, \forall i \in I, \forall j \in J $ și orice constante $ c $ și $ k. $
Atunci mulțimea de situații de echilibru este $ \\{ (i, j): \forall i \in I, \forall j \in J \\} $.


**6.2 Algoritmul paralel pentru determinarea situatiilor Nash de echilibru.**

Structura algoritmului paralel construit va fi determinată de modul de paralelizare la nivel de date. 
Adică se pot utiliza urmatoarele modalități de divizare și distribuire a matricilor $ A $ si $ B $:

- Matricile se divizează în submatrici dreptunghiulare de orice dimensiune.  
  În acest caz se complică foarte tare modalitatea de construire a situațiilor de echilibru petru jocul cu matricele 
  inițiale. Pentru lucrarea de laborator nu este obligatoriul utilizarea acestui mod de divizare a matricelor; 
- Matricile se divizează în submatrici de tip linii sau submatrici de tip coloană. În acest caz 
  construirea situațiilor de echilibru pentru jocul inițial este destul de simplă. 

Vom descrie matematic algoritmul paralel pentru determinarea situațiilor Nash de echilibru în strategii 
pure pentru jocul bimatriceal $ G = \langle I, J, A, B \rangle $, unde $ A = {|| a_{ij} ||} _ {j \in J} ^ {i \in I}, B = {|| b_{ij} ||} _ {j \in J} ^ {i \in I} $
Vom presupune că matricea $ A $ este divizată în submatrici de tip coloană și matricea $ B $ este divizată în submatrici de tip linii.
Adică vom obține un șir de submatrici $ Sub_{A^t} = {|| a_{ij} ||} ^ {j \in J_k} _ {i \in I} $ și $ Sub_{A^t} = {|| b_{ij} ||} ^ {j \in J} _ {i \in I_k} $, 
unde $ J_k = \\{ i_k, i _ {k + 1}, \cdots, i _ {k + p} \\} $ și $ I_k = \\{ j_k, j _ {k + 1}, \cdots, j _ {k + p} \\} $.
$ Sub_{A^t} $ este o submatrice care constă din $ p $ coloane ale matricei $ A $ incepând cu coloana numarul $ k $ și este "distribuită" procesului cu rancul $ t $. 
Similar este o submatrice care constă din $ p $ linii ale matricei B incepând cu linia $ k $ și este la fel distribuită procesului cu 
rancul $ t $.
Folosind algoritmul 6.1 descris mai sus procesul cu rancul $ t $ va determina pentru orice $ j_k \in J_k $ 
graficul aplicației mutivoce $ i^\star (j_k) = Arg \max _ {i \in I} a_{ij_k} $, 
adică $ {gr} ^ {k} _ {i^\star} = \\{ (i, j): i = i ^ \star (j_k), j = j_k \\} $.
Similar, procesul cu rancul $ t $ va determina pentru orice $ i_k \in I_k $ graficul aplicației mutivoce 
$ j^\prime (i_k) = Arg \max _ {j \in J} b _ {i_k j} $, 
adică $ gr ^ {k} _ { j^\prime } = \\{ (i, j): i = i_k, j = j^\star(i_k) \\} $
În final același proces $ t $ va determina $ {LineGr} ^ t = \cup _ k { gr } ^ k _ { i ^ \prime } $ 
și $ {ColGr} ^ t = \cup _ k { gr } ^ k _ { j ^ \prime } $. 
*Se observa ca această modalitate de divizare a matricelor permite ca fiecare proces să determine $ LineGr^t $ și $ ColGr^t $ fără a executa alte operații suplimentare*.
*Ușor se poate arăta că există modalități de divizare a matricelor în care deja procesul cu rancul $ t $ nu poate determina "de unul singur" $ i^\star (j_k) $ și $ j^\star (i_k) $ (de exemplu daca matricile sunt divizate in submatrici linii)*.

Vom exemplifica algoritmul descris mai sus. Considerăm jocul din Exemplu 6.1 și fie ca $t=0,1,2$. 
Atunci submatricile corespunzătoare proceselor vor fi:

$$
A^0 = \begin{pmatrix}
 \underline{4}  &  0  \\\\
 3              &  \underline{3}  \\\\
 2              &  2  \\\\
 1              &  1  \\\\
 0              &  0  \\\\
-1              & -1 
\end{pmatrix},
A^1 = \begin{pmatrix}
 0              &  0 \\\\
 0              &  0 \\\\
 \underline{2}  &  0 \\\\
 1              &  \underline{1} \\\\
 0              &  0 \\\\
-1              & -1
\end{pmatrix},
A^2 = \begin{pmatrix}
 \underline{0}  &  \underline{0} \\\\
 \underline{0}  &  \underline{0} \\\\
 \underline{0}  &  \underline{0} \\\\
 \underline{0}  &  \underline{0} \\\\
 \underline{0}  &  \underline{0} \\\\
-1              & -1
\end{pmatrix}.
$$

$$
B^0 = \begin{pmatrix}
 0  &  \underline{2}  &  1              &  0  & -1  & -2 \\\\
 0  &  0              &  \underline{1}  &  0  & -1  & -2
\end{pmatrix},
B^1 = \begin{pmatrix}
 \underline{0}  & \underline{0}  & \underline{0}  & \underline{0}  & -1  & -2 \\\\
 \underline{0}  & \underline{0}  & \underline{0}  & \underline{0}  & -1  & -2
\end{pmatrix},
B^2 = \begin{pmatrix}
 \underline{0}  &  \underline{0}  &  \underline{0}  &  \underline{0}  &  \underline{0}  & -2 \\\\
 \underline{0}  &  \underline{0}  &  \underline{0}  &  \underline{0}  &  \underline{0}  &  \underline{0}
\end{pmatrix}.
$$

Procesul cu **rancul 0** determină:

$
  {gr} ^ 0 _ {i^\star} = \\{ (0, 0) \\}, \\\\
  {gr} ^ 1 _ {i^\star} = \\{ (1, 1) \\}, \\\\
  {LineGr} ^ 0 = \\{ (0, 0), (1, 1) \\}; \\\\
  {gr} ^ 0 _ {j^\star} = \\{ (0, 1) \\}, \\\\
  {gr} ^ 1 _ {j^\star} = \\{ (1, 2) \\}, \\\\
  {ColGr} ^ 0 = \\{ (0, 1), (1, 2) \\}.
$

Procesul cu **rancul 1** determină:

$ 
  {gr} ^ 0 _ {i^\star} = \\{ (2, 0) \\}, \\\\
  {gr} ^ 1 _ {i^\star} = \\{ (3, 1) \\}, \\\\
  {LineGr} ^ 1 = \\{ (2, 0), (3, 1) \\}; \\\\

  {gr} ^ 0 _ {j^\star} = \\{ (0, 0), (0, 1), (0, 2), (0, 3) \\}, \\\\
  {gr} ^ 1 _ {j^\star} = \\{ (1, 0), (1, 1), (1, 2), (1, 3) \\}, \\\\
  {ColGr} ^ 1 = \\{ (0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1), (1, 2), (1, 3) \\}.
$

**În indici "globali":**

$
  {LineGr} ^ 1 = \\{ (2, 2), (3, 3) \\}, \\\\
  {ColGr} ^ 1  = \\{ (2, 0), (2, 1), (2, 2), (2, 3), (3, 0), (3, 1), (3, 2), (3, 3) \\},
$

Procesul cu **rancul 2** determină:

$
  {gr} ^ 0 _ {i^\star} = \\{ (0, 0), (1, 0), (2, 0), (3, 0), (4, 0) \\}, \\\\
  {gr} ^ 1 _ {i^\star} = \\{ (0, 1), (1, 1), (2, 1), (3, 1) \\}, \\\\
  {LineGr} ^ 2 = \\{ (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (0, 1), (1, 1), (2, 1), (3, 1) \\}; \\\\
  {gr} ^ 0 _ {j^\star} = \\{ (0, 0), (0, 1), (0, 2), (0, 3), (0, 4) \\}, \\\\
  {gr} ^ 1 _ {j^\star} = \\{ (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5) \\}, \\\\
  {ColGr} ^ 2 = \\{ (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5) \\}.
$

**În indici "globali":**

$
  {LineGr} ^ 2 = \\{ (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (0, 5), (1, 5), (2, 5), (3, 5) \\}, \\\\
  {ColGr} ^ 2  = \\{ (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5) \\},
$

Procesul cu rancul 0 va determina $ LineGr $ și $ ColGr $ pentru indici globali:

$ 
  {LineGr} = {LineGr} ^ 0 \cup {LineGr} ^ 1 \cup {LineGr} ^ 2 = 
  \left. 
    \begin{cases} 
      (0, 0), (1, 1), (2, 2), (3, 3), (0, 4), \\\\ 
      (1, 4), (2, 4), (3, 4), (4, 4), (0, 5), \\\\ 
      (1, 5), (2, 5), (3, 5), (4, 5) 
    \end{cases}
  \right \\}
$

și 

$ 
  {ColGr} = {ColGr} ^ 0 \cup {ColGr} ^ 1 \cup {ColGr} ^ 2 = 
  \left. 
    \begin{cases} 
      (0, 1), (1, 2), (2, 0), (2, 1), (2, 2), \\\\ 
      (2, 3), (3, 0), (3, 1), (3, 2), (3, 3), \\\\  
      (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), \\\\  
      (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), \\\\ 
      (5, 5) 
    \end{cases} 
  \right \\}
$

Atunci $ NE = LineGr \cap ColGr = \\{ (2, 2), (3, 3), (4, 4) \\} $.


**Algoritmul paralel pentru determinarea situațiilor de echilibru trebuie sa conțină urmatoarele:**

- a. Eliminarea, în paralel, din matricea $A$ și $B$ a liniilor care sunt (strict) dominate în matricea $A$ și din matricea 
$A$ și $B$ a coloanelor care sunt (strict) dominate în matricea $B$. 

- b. Pentru orice proces $ t $ se determină submatricele $ {SubA}^t $ și $ {SubB}^t $.

- c. Fiecare proces $ t $ determină $i^\star (j_k)$ și $j^\star (i_k)$ pentru orice $k$.  
  Pentru aceasta se va folosi funcția `MPI_Reduce` și operația `ALLMAXLOC` (în cazul utilizării `MAXLOC` rezultatele pot fi incorecte) care determină toate indicile elementelor maximale și este creată cu ajutorul funcției MPI `MPI_Op_create`. 
  După procesul $ t $ determină și în indici globali, adică indicii elementelor din matricea A și B. 

- d. Procesul cu rankul 0 va determina mulțimea de situații Nash de echilibru care este $ NE = (\cup _ t {LineGr} ^ t) \cap (\cup _ t {ColGr} ^ t) $.
 
**Pentru realizarea acestui algoritm pe clustere paralele sunt obligatorii următoarele:**

1. Paralelizarea la nivel de date se realizează in urmatoarele moduri: 
     - a) Procesul cu rankul 0 inițializează valorile matricelor $ A $ și $ B $, 
          construiește submatricele $ {SubA}^t $ și $ {SubB}^t $, 
          și le distribuie tuturor proceselor mediului de comunicare. 
     - b) Fiecare proces din mediul de comunicare construiește submatricele $ {SubA}^t $ și $ {SubB}^t $, 
          și le inițializează cu valori. 
     - c) Distribuirea matricelor pe procese se face astfel încât să se realizeze principiul load balancing.  
  
2. Paralelizarea la nivel de operații se realizează: 
     - a) Prin utilizarea funcției `MPI_Reduce` și a operațiilor nou create.  
     - b) Nu se utilizeaza funcția `MPI_Reduce`.  
 
3. Să se realizeze o analiză comparativă a timpului de execuție a programelor realizate când paralelizarea la nivel 
   de date se realizează in baza punctelor 1.a) si 1.b) 
   și paralelizarea la nivel de operații se realizează în baza punctelor 2.a) si 2.b). 
   
Mai jos vom prezenta codurile de programe in care se realizează variante simple ale lucrării de laborator cu utilizarea funcției `MPI_Reduce`, si anume:  

- În programul `Laborator_1_var_0_a.cpp` se realizează paralelizarea descrisă în a), matricele sunt de dimensiunea  
  `numtask * numtask`, sunt inițializate de procesul cu rancul 0 și submatricele sunt numai dintr-o singură linie (coloană). 
- În programul `Laborator_1_var_0_b.cpp` se realizează paralelizarea descrisă în b), matricele sunt de dimensiunea 
  `numtask * numtask`, sunt inițializate de procesul cu rankul 0 ți submatricele sunt numai dintr-o singură linie (coloană).


## Realizarea

Vom realiza toate sarcinile după module — bucăți de cod independente. 
Paralel voi explica unele concepte ale limbajului D în care am realizat lucrarea de laborator. 


### Matrice

Pentru început, vom realiza funcția ce ar lua o matrice arbitrară și ar determina indicii liniilor (coloanelor) (strict) dominate.

Pentru aceasta avem nevoie de următoarele lucruri:
- Să putem păstra și adresa matricile arbitrare în cod. 
  Vom face un wrapper, esențial pentru o adresă de memorie și un set de indici cu capacitățile de indexare.
  Ideal, am dori lucra cu indicii "în mod relativ", decât "global".
- S-o putem ușor transpune.
- Să putem păstra o mulțime de indici.

> Ca atare, puteți deodată trece la următoarea secțiune. 
> Aici construiesc un API care de fapt nu s-a dovedit util, deoarece tablouri simple sunt destul de suficiente pentru rezolvări.
> Această abstracție nu este necesară pentru problema, și doar o complică (pentru varianta inițială simplă, totuși am utilizat codul pentru varianta cu matricea de dimensiuni arbitrare).
> 
> Însă, în această secțiune descriu unele concepte limbajului D, deci dacă sunt interesați de aceasta, atunci citiți.

Fiind dat faptul că matricile sunt doar bidimensionale, nu vom primi multă performanță decă utilizăm un *vector definitor*, deci voi implementa ceva foarte simplu.

Sunt și librării pentru așa lucruri în D, de exemplu `mir`, însă pentru demonstrare și controlul maximal o voi realiza singur.

Deci vom avea nevoie de o structură wrapper pentru un pointer, dimensiunile matricei și un set de indici permisibile.

Vom începe cu cel mai simplu moment: setul de indici. Vom defini o structură ce va ține 2 element de tip `size_t` — 64 de biți pe mașini de 64 de biți și 32 pe cei de 32 de biți. 
D nu permite compilarea pentru 16 de biți și alte arhitecture neconvenționale.

```d
struct Range
{
    size_t[2] arrayof;
}
```

Am dori ca această structură să fie indexabilă.
Cel mai ușor ar fi să transferăm toate apelări la funcții inexistente pe structura noastră la tabloul subiacent.

```d
Range range;
range.arrayof[0]; // Lucrează
range[0]; // Eroare, însă am dori să cheme `range.arrayof[0]`
```

Putem face acest lucru prin `alias this`:

```d
struct Range
{
    size_t[2] arrayof;
    alias arrayof this;
}
```

Acum dacă avem o variabilă de tip `Range` indexarea directă este posibilă (se indexează arrayof).

Vom dori încă să supraîncărcăm proprietatea `length`, deoarece la moment `length` este readreasat la tabloul subiacent.

```
Range range;
range[0] = 0;
range[1] = 5;
range.length; // ne dă 2, adică range.arrayof.length, însă am dori să ne dea 6.
```

Adăugăm funcția `length()`.

```d
// `const` înseamnă că intervalul nostru nu se schimbă după operație.
size_t length() const { return arrayof[1] - arrayof[0] + 1; }
```

În D parantezele la apelarea funcțiilor sunt opționale, deci `range.length` este semantic echivalent cu `range.length()`.

Am dori să putem construi un Range dându-i valorile pentru capetele intervalului.
D de fapt definește implicit un constructor care atribuie valorile tuturor membrilor după tipurile lor, deci constructorul este deja definit.
Mie nu-mi place să fac validarea sau logica complicată în constructorul, deci constructorii mei în alte limbaje sunt ori inexistenți dacă posibil, ori echivalenți cu constructori care D ar defini implicit.
Eu prefer funcții fabrici.

```d
Range range = Range([1, 2]);
// este echivalent cu
Range range;
range.arrayof = [1, 2];
```

Aici evident nu se face validarea (capetele din dreapta trebuie să fie mai mare sau egal cu capetele din stânga).

Am mai adăugat 2 funcții care verifică dacă un alt interval este în intervalul nostru, și dacă un număr este în intervalul nostru:

```d
bool contains(size_t a) const { return a >= arrayof[0] && a <= arrayof[1]; }
bool contains(Range a) const { return a[0] >= arrayof[0] && a[1] <= arrayof[1]; }
```

Mai am definit o funcție șablon care permite să facem orice operații aritmetice cu intervalul nostru și un obiect care conține elementele după indici 0 și 1.

```d
// Prima pereche de paranteze conține argumentele șablon.
// `string op` este o operație aritmetică, ca un șir. Poate fi "+", "-", "*" etc.
// `R` este orice tip.
// `(const auto ref R rhs)` înseamnă că nu vom modifica `rhs` 
// și că acceptăm orice tip de valori: rvalue, lvalue, după referință sau cu copiere.
// Compilatorul singur decide ce funcție se va executa.
Range opBinary(string op, R)(const auto ref R rhs) const
{
    // `mixin` inserează șirul dat ca cod.
    // ` în acest caz denotează un șir, este echivalent cu ".
    // ~ este operatorul de concatenare. 
    mixin(`return Range([arrayof[0] `~op~` rhs[0], arrayof[1] `~op~` rhs[1]]);`);
}
```

Acum facem structura ce va ține o matrice.
Am decis deodată să-i dau un argument șablon care indică dacă este inversată ori nu.
Inversarea am implementat-o fără realocarea tabloului adiacent.
Este utilizat tot același tablou, însă ordinea indicilor se schimbă.
Probabil va trebui să mai adaug transpunerea cu copiere, însă vom vedea.

```d
struct Matrix(T, bool Transposed = false)
{
    T* array;

    /// The actual width of the underlying matrix.
    size_t _width;
    /// The actual height of the underlying matrix.
    size_t _height;
    /// The width of the source matrix, as seen after transposition.
    size_t allWidth()  const { return Transposed ? _height : _width;  }
    /// The height of the source matrix, as seen after transposition.
    size_t allHeight() const { return Transposed ? _width  : _height; }

    Range _rowRange;
    Range _colRange;

    /// The width of the matrix, as available to the user.
    /// The user may provide as the second index the values in range [0, width).
    size_t width()  const { return Transposed ? _rowRange.length : _colRange.length; }
    /// The height of the matrix, as available to the user.
    /// The user may provide as the first index the values in range [0, height).
    size_t height() const { return Transposed ? _colRange.length : _rowRange.length; }
}
```

Deci avem 5 membrii și 4 funcții getter. `T* array` conține pointer la tabloul subiacent, `_width` și `_height` — dimensiunile lui, `_rowRange` și `_colRange` — deplasările indicilor și conțin de fapt lungimea părții de tablou inițial pe care îl reprezintă matricea dată. 
Funcțiile getter sunt pentru comoditate a utilizatorului (iterarea etc.)

Așa ca proprietatea transpusului este controlată numai de variabila `Transposed`, operația de transpunere este trivială:
```d
// `auto` înțelege tipul implicit ca Matrix!(T, !Transposed)
auto transposed() inout
{
    // Prin primul semn al exclamării îi dăm matricei valorile șablon.
    // `Struct!(a, b)` este ca `Struct<a, b>` în C++.
    return inout(Matrix!(T, !Transposed))(array, _width, _height, _rowRange, _colRange);
}
```

Vom defini o funcție ce află indexul elementului în memorie subiacentă.
Aici se presupune că `rowIndex` și `colIndex` sunt deja conform proprietății transpusului, adică sunt schimbate cu locuri dacă matricea este transpusă. 

```d
/// Returns the internal index into the underlying array.
private size_t getLinearIndex(size_t rowIndex, size_t colIndex) const
{
    assert(rowIndex >= 0 && rowIndex < _rowRange.length); 
    assert(colIndex >= 0 && colIndex < _colRange.length); 
    rowIndex = rowIndex + _rowRange[0]; 
    colIndex = colIndex + _colRange[0];
    return rowIndex * _width + colIndex;
}
```

Pentru a supraîncărca operația de indexare vom folosi funcția `opIndex`:

```d
// auto ref înseamnă returnează lvalue ori rvalue, în dependența de contextul în care
// a fost utilizată operația.
auto ref inout opIndex(size_t rowIndex, size_t colIndex)
{
    // funcția `swap` este echivalentă cu clasicul `auto t = a; a = b; b = t;`
    if (Transposed)
        swap(rowIndex, colIndex);
    return array[getLinearIndex(rowIndex, colIndex)];
}
```

Acum definim operațiile care ar permite să luăm părți arbitrare de matricea inițială: orice număr de linii și orice număr de coloane.
În D aceasta se face prin operații de slicing. Exemplu cu un tablou 1-d.
```d
int[10] arr;
arr[0];     // doar primul element.
arr[0..2];  // elementele 0 și 1.
arr[1..3];  // elementele 1 și 2.
arr[$ - 1]; // $ este echivalent cu arr.length, deci obținem ultimul element.
arr[0..$];  // întregul tablou.
```

Aceasta poate fi generalizat la mai multe dimensiuni. Deci, conceptual:
```d
Matrix!(5, 5) m; // o matrice 5 pe 5.
m[0, 0]; 	// primul element
m[0, 0..$]; // prima linie
m[0..$, 0]; // prima coloană
m[1..3, 2..$]; // liniile 1 și 2, coloanele 2, 3, 4
```

Deci această modalitate ne-ar permite să luăm părți dreptunghulare arbitrare a matricii inițiale.

Funcția `opDollar` permite să definim acea variabilă $ implicită:
```d
size_t opDollar(size_t dim : 0)() const { return height; }
size_t opDollar(size_t dim : 1)() const { return width;  }
```

Funcția `opIndex` lucrează cu tablouri de 2 elemente ca indici:
```d
auto inout opIndex(size_t[2] row, size_t[2] col)
{
    if (Transposed)
        swap(row, col);

    Range newRowRange = Range([_rowRange[0] + row[0], _rowRange[0] + row[1] - 1]);
    assert(_rowRange.contains(newRowRange));

    Range newColRange = Range([_colRange[0] + col[0], _colRange[0] + col[1] - 1]);
    assert(_colRange.contains(newColRange));

    return inout(Matrix!(T, Transposed))(array, _width, _height, newRowRange, newColRange);        
}
```

Și pentru a transforma `a..b` în `size_t[2]` mai avem nevoie să definim funcția `opSlice`:
```d
// Support for `x..y` notation in slicing operator for the given dimension.
size_t[2] opSlice(size_t dim)(size_t start, size_t end) const if (dim >= 0 && dim < 2)
{
    return [start, end];
}
```

Mai avem nevoie să acoperim cazurile când unul din indicii nu este un interval:
```d
// m[a..b, c] = m[a..b, c .. c + 1]
auto inout opIndex(size_t[2] rows, size_t colIndex) { return opIndex(rows, [colIndex, colIndex + 1]); }
// m[a, b..c] = m[a .. a + 1, b..c]
auto inout opIndex(size_t rowIndex, size_t[2] cols) { return opIndex([rowIndex, rowIndex + 1], cols); }
```

Atât cu matricea!

Am definit o funcție fabrică ce returnează o matrice construită din valorile unui tablou dinamic. 
(Sau a unui view într-un tablou static. În D aceasta se numește `slice`).

```d
auto matrixFromArray(T)(T[] array, size_t width)
{
    auto height = array.length / width;
    return Matrix!T(array.ptr, width, height, Range([0, height - 1]), Range([0, width - 1]));
}
```

Am mai definit niște teste, pentru a mă asigura că lucrează corect.
Vedeți [codul pe github](https://github.com/AntonC9018/uni_parallel/blob/26831202b5a3c6e6d7e6ebba3e69c8f19c571886/source/lab1.d#L97-L181), nu-l plasez aici.
Am mai modificat codul ceva nesemnificativ, tot nu inserez aici.

> Funcțiile descrise în restul acestei secțiuni nu le-am folosit.

Acum voi scrie codul care ar opera pe așa matrice arbitrară, selectând indicii minimului după coloanele într-un tablou, zicem dinamic, pentru fiecare coloană.

Voi face acest lucru în stilul TDD (Test Driven Development).
Avem cetințe concrete, deci putem scrie un unit test.

```d
size_t[][] getIndicesOfMinInColumns(M)(ref const(M))
{
    return null;
}
unittest
{
    Matrix!int m = matrixFromArray([ 1, 2, 3,
                                     4, 5, 6,
                                     1, 2, 3, ], 3);
    auto indices = getIndicesOfMinInColumns(m);

    assert(indices.length == 3);
    foreach (i; 0..3)
        assert(indices[i][] == [0, 2]); 
}
```

Acum încercăm să satisfacem testul. Voi face cea mai simplă implementarea posibilă.
Deja putem scrie cod verificând dacă lucrează apasând butonul care face testarea (l-am setat la F5).

```d
size_t[][] getIndicesOfMinInColumns(M)(ref const(M) matrix)
{
    auto result = new size_t[][](matrix.width);
    if (matrix.height == 0)
        return result;

    foreach (columnIndex; 0 .. matrix.width)
    {
        result[columnIndex] = [0];
        // `cast()` scoate `const` de la element
        auto minElement = cast() matrix[0, columnIndex];
        foreach (rowIndex; 1 .. matrix.height)
        {
            auto element = matrix[rowIndex, columnIndex];
            if (element < minElement)
            {
                result[columnIndex][0] = rowIndex;
                result[columnIndex].length = 1;
                minElement = element;
            }
            else if (minElement == element)
            {
                result[columnIndex] ~= rowIndex;
            }
        }
    }
    return result;
}
```

Codul este foarte ușor de înțeles. 
Am hotărât să solicit ca numărul de elemente în coloana să fie mai mare ca 0, începând calculările cu 0.

Acum facem o funcție ce returnează un singur indice ce indică prima apariție a maximului.

```d
size_t[] getIndexOfFirstMinInColumns(M)(ref const(M) matrix)
{
    auto result = new size_t[](matrix.width);
    if (matrix.height == 0)
        return result;
        
    foreach (columnIndex; 0 .. matrix.width)
    {
        result[columnIndex] = 0;
        auto minElement = cast() matrix[0, columnIndex];
        foreach (rowIndex; 1 .. matrix.height)
        {
            auto element = matrix[rowIndex, columnIndex];
            if (element < minElement)
            {
                result[columnIndex] = rowIndex;
                minElement = element;
            }
        }
    }
    return result;
}
unittest
{
    Matrix!int m = matrixFromArray([ 1, 2, 3,
                                     4, 5, 6,
                                     1, 2, 3, ], 3);
    auto indices = getIndicesOfMinInColumns(m);

    assert(indices.length == 3);
    foreach (i; 0..3)
        assert(indices[i] == 0); 
}
```

Aici de fapt s-ar putea folosi și ceva mai interesant, de exemplu `Range`-urile și `std.algorithm`.
Citiți dacă este interesant. În scurt, ele permit iterarea leneșă.

Acum vom face o funcție ce mișcă acești indici în "coordonatele globale".
Mai necesită niște teste, însă testul propus simplu lucrează corect.
Încă o problemă este că accesează `_rowRange` ce după design probabil trebuie să fie privat, însă vom vedea și vom schimba aceasta după necesitate. 

```d
struct IndexPair
{
    size_t row;
    size_t col;
}

IndexPair[] getGlobalIndices(M : Matrix!(T, Transposed), T, bool Transposed)(size_t[] indices, ref const(M) matrix)
{
    auto result = new IndexPair[](indices.length);
    foreach (colIndex, rowIndex; indices)
    {
        if (Transposed)
            swap(colIndex, rowIndex);
        result[colIndex].row = matrix._rowRange[0] + rowIndex;
        result[colIndex].col = matrix._colRange[0] + colIndex;
    }
    return result;
}

unittest
{
    Matrix!int m = matrixFromArray([ 1, 2, 3,
                                     4, 5, 6,
                                     1, 2, 3, ], 3);
    // [  5, 6,
    //    2, 3,  ]
    Matrix!int shifted = m[1..$, 1..$];

    auto indices = getIndexOfFirstMinInColumns(shifted);

    assert(indices.length == 2);
    assert(indices[0] == 1);
    assert(indices[1] == 1);

    auto globalIndices = getGlobalIndices(indices, shifted);

    assert(globalIndices.length == 2);
    assert(globalIndices[0] == IndexPair(2, 1));
    assert(globalIndices[1] == IndexPair(2, 2));
}
```


### 1.a) Procesul 0 inițializează și distribuie.

Am făcut o funcție ajutătoare de inițializare pentru a simplifica acest proces în fiecare program:

```d
struct InitInfo
{
    int size;
    int rank;
    CArgs args;
}

InitInfo initialize()
{
    InitInfo result;
    // `with` înseamnă câmpurile lui result acum sunt vizibile fără calificare,
    // adică `size` acum se referă la `result.size`.
    with (result)
    {
        args = Runtime.cArgs;
        MPI_Init(&args.argc, &args.argv);
        MPI_Comm_size(MPI_COMM_WORLD, &size);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    }
    return result;
}

void finalize()
{
    MPI_Finalize();
}
```

Și o utilizăm astfel:

```d
int main()
{
    import mh = mpihelper;

    auto info = mh.initialize();
    scope(exit) mh.finalize(); // este invocat când main se termină
    // ...
}
```

Declarăm tablourile pentru copiere:

```d
// `enum` înseamnă constanta cunoscută în timpul compilării
enum DataWidth = 6;
immutable AData = [
    4,  0,  0,  0,  0,  0,
    3,  3,  0,  0,  0,  0,
    2,  2,  2,  0,  0,  0,
    1,  1,  1,  1,  0,  0,
    0,  0,  0,  0,  0,  0,
    -1, -1, -1, -1, -1, -1,
];
immutable BData = [
    0,  2,  1,  0, -1, -2,
    0,  0,  1,  0, -1, -2,
    0,  0,  0,  0, -1, -2,
    0,  0,  0,  0, -1, -2,
    0,  0,  0,  0,  0, -2,
    0,  0,  0,  0,  0,  0,
];
// Matricele trebuie să fie pătratice. 
// `static assert` verifică condiția în timpul compilării.
static assert(AData.length == DataWidth^^2);
static assert(BData.length == DataWidth^^2);
```

Evident, pentru acest caz simplist se consideră că matricile sunt pătratice și de o lungime fixă.
În acest caz fiecare proces va primi câte o linie sau câte o coloană (o singură).
De aceea numărul de procese trebuie să fie numaidecât egal cu numărul de coloane (linii).
```d
// `lazy` este util pentru șiruri care necesită formatare. 
// Înseamnă că valoarea mesajului va fi evaluată doar atunci când ea este accesată în corpul funcției. 
void abortIf(bool condition, lazy string message = null, MPI_Comm comm = MPI_COMM_WORLD)
{
    if (condition)
    {
        import std.stdio : writeln;
        writeln("The process has been aborted: ", message);
        MPI_Abort(comm, 1);
    }
}
abortIf(info.size != DataWidth, "Number of processes must be equal to the matrix dimension");
```

Pentru cazul simplist trebuie să inițializez matricile de către procesul cu rancul 0.
Aici deja devine clar în ce context s-a trebuit transpusul — pentru a transpune B când o inițializăm.
Deci ideea mea cu transpusul virtual până când nu este tare utilă.

```d
T[] transpose(T)(const(T)[] elements, size_t width)
{
    auto height = elements.length / width;
    auto result = new T[](width * height);
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        result[rowIndex * width + colIndex] = elements[colIndex * height + rowIndex];
    }
    return result;
}
unittest
{
    auto t = transpose([ 1, 2, 3, 
                         4, 5, 6, 
                         7, 8, 9, ], 3, 3);
    assert(t[] == [ 1, 4, 7,
                    2, 5, 8,
                    3, 6, 9, ]);
}
```

Putem afișa datele inițiale direct de la tabouri, însă atunci nu primim "tabelarea".
Deci voi face o funcție ce afișează o matrice având de fapt lungimea și lațimea.

```d
void printMatrix(T)(const(T)[] matrix, size_t width)
{
    const height = matrix.length / width;

    import std.stdio : write;
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        write(matrix[rowIndex * width + colIndex]);
        if (colIndex != width - 1)
            write(" ");
        else
            write("\n");
    }
}
```

Urmează utilizarea funcțiilor descriși până acum în main.
În funcția scatter folosim parametrul special [`MPI_IN_PLACE`](https://www.mpi-forum.org/docs/mpi-4.0/mpi40-report.pdf#page=248&zoom=180,34,598) pentru a nu aloca un bufer nou pentru procesul root.
În loc de asta, facem variabila `scatterReceiveBuffer` să se refere la segmentul buferului cu datele procesului `root`, în cazul în care este inițializată de către root.

```d
const root = 0;
int[] A;
int[] BTranspose;
int[] scatterReceiveBuffer;

bool isRoot() { return info.rank == root; }
auto rootBufferStartIndex() { return root * DataWidth; }

if (isRoot)
{
    // `dup` alocă memoria și copiează buferul.
    A = AData.dup; 
    BTranspose = transpose(BData, DataWidth);
    printMatrix(A, DataWidth);
    printMatrix(BTranspose, DataWidth);
    scatterReceiveBuffer = A[rootBufferStartIndex .. (rootBufferStartIndex + DataWidth)];
}
else
{
    scatterReceiveBuffer = new int[](DataWidth);
}
```

MPI_Scatter nu este o funcție bună după părerea mea, deoarece ea după prototipul său standart primește 3 parametri care sunt actuali numai la root. 
De aceea am separat MPI_Scatter în 2 funcții mai specifice, `intraScatterSend` și `intraScatterRecv`.
După [specificarea MPI](https://www.mpi-forum.org/docs/mpi-4.0/mpi40-report.pdf#page=352&zoom=180,-4,310), *intra*comunicare înseamnă că procesele sunt în același grup.

Am definit funcțiile astfel:
```d
/// Does an inplace scatter as the root process - the process' share of buffer is left in the buffer
int intraScatterSend(T)(T buffer, in InitInfo info, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias sendBufferInfo = BufferInfo!buffer;
    return MPI_Scatter(sendBufferInfo.ptr, sendBufferInfo.length / info.size, sendBufferInfo.datatype,
        MPI_IN_PLACE, 0, null, info.rank, comm);
}

/// Receives data from the root process using MPI_Scatter
int intraScatterRecv(T)(T buffer, int root, MPI_Comm comm = MPI_COMM_WORLD)
{
    return MPI_Scatter(null, 0, null, UnrollBuffer!buffer, root, comm);
}
```

`BufferInfo!buffer` și `UnrollBuffer!buffer` permit deducerea implicită a 3 parametri: pointer, lungimea și tipul de date.
Sunt ceva avansate, deci pentru simplitate nu le includ aici, însă [vedeți codul](https://github.com/AntonC9018/uni_parallel/blob/026dd2d29a70b4f5d697d4cface782ddb4453ba9/source/mpihelper.d#L118-L143).

Urmează utilizarea funcțiilor în program. 
Cum puteți vedea, buferul de ieșire este eliminat pentru procesul root, iar buferul de intrare este eliminat pentru celelalte procese.

```d
// Sort of does this, except does no copying at root.
// MPI_Scatter(
//    A.ptr, scatterReceiveBuffer.length, MPI_INT, 
//    scatterReceiveBuffer.ptr, scatterReceiveBuffer.length, MPI_INT, 
//    root, MPI_COMM_WORLD);
if (isRoot)
    mh.intraScatterSend(A, info);
else
    mh.intraScatterRecv(scatterReceiveBuffer, root);
```

Acum putem prepara buferul pentru operația de reducere.
Pentru cazul simplu este necesar să folosim operația MPI_MAXLOC, pentru care avem nevoie să împletim valorile rândurilor la fiecare proces cu rancul lui.
La mine am numere întregi în tablouri, de aceea am definit structura care va ține perechea valoare - indice în așa mod:
```d
struct IntInt
{
    int value;
    int rank;
}
```

Și funcția respectivă pentru împletirea în program (am definit-o ca o funcție deoarece o utilizăm de mai multe ori):

```d
// Este definită local în scopul funcției main, de aceea "vede" variabile ei.
void interweaveReduceBuffer(mh.IntInt[] buffer)
{
    foreach (i, ref pair; buffer)
    {
        pair.rank  = info.rank;
        pair.value = scatterReceiveBuffer[i];
    }
}
auto reduceBufferA = new mh.IntInt[](DataWidth);
interweaveReduceBuffer(reduceBufferA);
```

Acum funcția Reduce. 
Tot am definit un wrapper care determină tipul și lungimea buferului din tipurile parametrilor.
Iarăși folosim `MPI_IN_PLACE` pentru parametrul `sendBuf` la root ca să nu alocăm un bufer nou pentru aceasta în root.
```d
int intraReduce(T)(T buffer, MPI_Op opHandle, int rank, int root, MPI_Comm comm = MPI_COMM_WORLD)
{
    alias bufferInfo = BufferInfo!buffer;
    return MPI_Reduce(rank == root ? MPI_IN_PLACE : bufferInfo.ptr, UnrollBuffer!buffer, opHandle, root, comm);
}
```

Am făcut o funcție pentru afișare a rezultatelor intermediare (o apelăm de două ori).
Această funcție o putem scoate din main și s-o folosim și în alte variante.
```d
void printReduceBuffer(string matrixName, mh.IntInt[] buffer)
{
    writeln("Reduce buffer data for matrix`", matrixName, "`:");
    foreach (colIndex, pair; buffer)
        writeln("Maximum element's row index in the column ", colIndex, " is ", pair.rank, " with value ", pair.value);
}

if (isRoot)
{
    printReduceBuffer("A", reduceBufferA);
}
```

Acum facem același lucru pentru `BTranspose`:
```d
if (isRoot)
{
    scatterReceiveBuffer = BTranspose[rootBufferStartIndex .. (rootBufferStartIndex + DataWidth)];
    mh.intraScatterSend(BTranspose, info);
}
else
{
    mh.intraScatterRecv(scatterReceiveBuffer, root);
}
auto reduceBufferB = new mh.IntInt[](DataWidth);
interweaveReduceBuffer(reduceBufferB);
mh.intraReduce(reduceBufferB, MPI_MAXLOC, info.rank, root);

if (isRoot)
{
    printReduceBuffer("BTraspose", reduceBufferB);
}
```

Și în final verificăm dacă avem perechi de indici egale:
```d
if (isRoot)
{
    int hitCount = 0;
    foreach (colIndexA; 0..DataWidth)
    foreach (rowIndexB; 0..DataWidth)
    {
        auto colIndexB = reduceBufferB[rowIndexB].rank;
        auto rowIndexA = reduceBufferA[colIndexA].rank;
        if (colIndexA == colIndexB && rowIndexA == rowIndexB)
        {
            hitCount++;
            writeln("Nash Equilibrium: (", colIndexA, ", ", rowIndexA, ")."); 
        }
    }
    if (hitCount == 0)
        writeln("No Nash Equilibrium.");
}
```


### 1.b) Fiecare proces își inițializează linia din matrice.

Aceasta este foarte ușor de făcut, și cod se va primi și mai simplu decât este la moment.
Trebuie să scoatem apeluri la MPI_Reduce și să inițializăm vectorii direct din datele de intrare.

Pentru început presupunem că fiecare proces cunoaște datele de intrare apriori, pe urmă vom schimba codul să admită input de la tăstătură.

Ca să nu duplic codul, void realiza programul cu compilarea condițională.
Voi include codul de inițializare într-un bloc `version`, deci acest cod se va compila numai dacă "versiunea" este definită în timpul compilării (variabila mediului).

```d
version(RootDistributesValues)
{
    // Codul de inițializare ...
}
```

În alt caz, se va executa codul nou de inițializare:

```d
else
{
    // Initialize buffer for A
    foreach (colIndex, ref pair; reduceBufferA)
    {
        // AData conține tabloul, cunoscut pentru fiecărui proces.
        pair.value = AData[colIndex + rank * DataWidth];
        pair.rank = rank;
    }
}
```

Și asemănător pentru matricea B:

```d
version(RootDistributesValues)
{
    // Inițializarea veche a lui B ...
}
else
{
    // Initialize buffer for B
    foreach (rowIndex, ref pair; reduceBufferB)
    {
        pair.value = BData[rowIndex * DataWidth + rank];
        pair.rank = rank;
    }
}
```

Restul codului rămâne aproape neschimbat. Ca să nu-l inserez din nou, uitați-vă după [link](https://github.com/AntonC9018/uni_parallel/blob/2324ace89f713a46bd106baf7fbcf13bbf173399/source/lab1.d#L23-L157).

Evident, codul la moment admite doar matrici pătratice.
Însă n-ar fi atât de greu de modificat codul ca să permită matrici de dimensiuni arbitrari (am scris deja un wrapper pentru matrici cu indexarea deplasată).

Acum facem cu inputul de la tăstătură. 
Aici nu știu dacă ar lucra dacă luăm input de la mai multe procese (și nu am posibilitate să-mi verific codul), însă, conceptual, am avea un ciclu unde vom trece prin fiecare proces, și dacă rancul lui este egal cu variabila de iterare, vom citi o linie de valori.

```d
else version(KeyboardInput)
{
    char[] keyboardInputBuffer;
    foreach (processIndex; 0..info.size)
    {
        if (processIndex == info.rank)
        {
            foreach (colIndex, ref pair; reduceBufferA)
            {
                import std.stdio : write, readln;
                import std.conv : to;
                write("Enter A[", processIndex, ", ", colIndex, "] = ");
                readln(keyboardInputBuffer);
                pair.value = keyboardInputBuffer.to!int;
                pair.rank = info.rank;
            }
        }
        // Apelează MPI_Barrier(MPI_COMM_WORLD)
        mh.barrier();
    }
}
```

Putem refactoriza acest ciclu într-o funcție, deoarece o vom mai utiliza. 

```d
char[] keyboardInputBuffer;
// `delegate` înseamnă un pointer la funcție + context (de fapt variabilele lui main).
// `scope` înseamnă că contextul nu va fi copiat pe heap.
void inputForEveryProcess(scope void delegate() loop)
{
    foreach (processIndex; 0..info.size)
    {
        if (processIndex == info.rank)
        {
            loop();
        }
        mh.barrier();
    }
}

inputForEveryProcess(
{
    foreach (colIndex, ref pair; reduceBufferA)
    {
        import std.stdio : write, readln;
        import std.conv : to;
        write("Enter A[", info.rank, ", ", colIndex, "] = ");
        readln(keyboardInputBuffer);
        pair.value = keyboardInputBuffer.to!int;
        pair.rank = info.rank;
    }
});
```

Și inițializarea pentru B:
```d
else version(KeyboardInput)
{
    inputForEveryProcess(
    {
        foreach (colIndex, ref pair; reduceBufferB)
        {
            import std.stdio : write, readln;
            import std.conv : to;
            write("Enter B[", colIndex, ", ", info.rank, "] = ");
            readln(keyboardInputBuffer);
            pair.value = keyboardInputBuffer.to!int;
            pair.rank = rank;
        }
    });
}
```

### Fără MPI_Reduce

Deci vom avea nevoie să simulăm modul în care lucrează `MPI_Reduce` utilizând alte operații de comunicare.

Propun să împărțim procesele în grupuri câte 2.
Primul proces din grup ar primi datele de la celălalt proces, pe urmă va aplica operația la vectorul săl și vectorul primit de la celălalt proces.
Acum putem elimina din grupuri celelalte procese, și repetăm.

```d
// Process 0 gets the result (the values array gets mutated).
// The input values array most likely will be mutated.
// Assumes op is commutative.
void customIntraReduce(T)(T[] values, in InitInfo info, void delegate(const(T)[] input, T[] inputOutput) op)
{
    int processesLeft = info.size;
    const tag = 15;

    // Only half of the processes will be getting values.
    T[] recvBuffer;
    if (info.rank <= info.size / 2)
        recvBuffer = new T[](values.length);

    while (processesLeft > 1)
    {
        // Examples:
        // 0, 1, 2 -> (0, 2), (1, _)        gap = 2, numActive = 2
        // 0, 1, 2, 3 -> (0, 2), (1, 3)     gap = 2, numActive = 2
        // 0, 1 -> (0, 1)                   gap = 1, numActive = 1

        // Round up
        int activeProcessesCount = (processesLeft + 1) / 2;

        // If there's an odd number of processes, the last active does nothing
        if ((processesLeft & 1) && info.rank == activeProcessesCount - 1)
        {
            processesLeft = activeProcessesCount;
            continue;
        }

        // We're the first process (the active one) in a group
        if (info.rank < activeProcessesCount)
        {
            // Skip over other processes.
            int partnerId = activeProcessesCount + info.rank;
            mh.recv(recvBuffer, partnerId, tag);
            // Values now contain the result of the operation.
            op(recvBuffer, values);
        }
        // We're the second process in a group
        else
        {
            int partnerId = info.rank - activeProcessesCount;
            mh.send(values, partnerId, tag);
            break;
        }

        processesLeft = activeProcessesCount;
    }
}
```

De exemplu, avem 3 procese, operația max, și inputurile $i$ pentru proces cu rancul $i$.

Primul proces cu rancul 0 intră ciclul, calculează `activeProcessesCount = 2`, trece peste condiția `if ((processesLeft & 1) && info.rank == activeProcessesCount - 1)`.
Rancul este mai mic decât `activeProcessesCount` (0 < 2), de aceea procede în prima ramură.
Calculează `partnerId = 0 + 2 = 2` și acum așteaptă buferul de intrare procesului 1.

Al doilea proces intră ciclul, verifică condiția `if ((processesLeft & 1) && info.rank == activeProcessesCount - 1)`, actualizează valoarea lui `processesLeft` la `2` și intră ciclul din nou.
Acum `activeProcessesCount = 1`, trece peste condiția. 
Condiția `if (info.rank < activeProcessesCount)` nu se verifică (1 == 1), de aceea intră a doua ramură.
Procesul calculează `partnerId = 1 - 1 = 0`, și execută `send`.
Modul de executare nu este necesar sincronizat, de aceea există 2 posibilități: ori procesul se blochează așteptând momentul când partenerul primește datele, ori datele sunt buferizate și prin urmare procesul iese din ciclu și din funcție.

Al treilea proces tot intră în a doua ramură în prima iterare, trimite datele procesului 0 și iese din ciclu.

Procesul 0 aplică operația `max(recvBuff, values) = max(2, 0)`, primind 2 stocat în values.
Actualizează `processesLeft` la 2, intră din nou în ciclu, calculează `activeProcessesCount = 1`, trece peste `if ((processesLeft & 1) && info.rank == activeProcessesCount - 1)` deoarece `processesLeft` este par.
Intră în prima ramură (0 < 1), `partnerId = 0 + 1 = 1`, primește datele de la procesul 1 care deja probabil a terminat execuția, execută `max(1, 2) = 2`.
Procesul actualizează `processesLeft` la 1, și iese din cauza condiției ciclului `while (processesLeft > 1)`.

Pentru a preveni invalidarea buferului de ieșire la fiecare proces, am putea lucra cu `recvBuffer`, copiindu-l în `values` numai pentru procesul 0.

Datorită naturii recursive a acestui algoritm ușor se observă că el va lucra și pentru un număr mai mare de procese.

> Notez o detalie despre cod. În D este normal să nu șterg buferuri intemediare, deoarece D are un GC (opțional, pornit după default). 
> În principiu am putea șterge acest bufer cu `scope(exit) delete recvBuffer;` (însă aceasta nu ar face nimic) sau chiar să utilizez `malloc` și `free`, sau mai bine să utilizăm un alocator personalizat, însă nu-mi complic sarcina.

Funcția realizată este un "drop-in replacement" pentru `mh.intraReduce` (cu excepția faptului că presupune că root-ul este 0):
```d
// Am schimba
mh.intraReduce(reduceBufferA, MPI_MAXLOC, info.rank, root);
// la
mh.intraCustomReduce(reduceBufferA, info, (inputBuffer, inoutBuffer) 
{ 
    import std.agorithm.comparison : max;
    foreach (i, ref elem; inoutBuffer)
        elem = max(elem, inputBuffer[i]);
});
```

### Executarea 

Serverul m-a scos din ban, deci la sfărșit pot testa programele.

```
$ ./compile.sh lab1 -version=RootDistributesValues
$ mpirun -np 6 lab1.out
4 0 0 0 0 0
3 3 0 0 0 0
2 2 2 0 0 0
1 1 1 1 0 0
0 0 0 0 0 0
-1 -1 -1 -1 -1 -1
0 0 0 0 0 0
2 0 0 0 0 0
1 1 0 0 0 0
0 0 0 0 0 0
-1 -1 -1 -1 0 0
-2 -2 -2 -2 -2 0
Reduce buffer data for matrix `A`:
Maximum element's row index in the column 0 is 0 with value 4
Maximum element's row index in the column 1 is 1 with value 3
Maximum element's row index in the column 2 is 2 with value 2
Maximum element's row index in the column 3 is 3 with value 1
Maximum element's row index in the column 4 is 0 with value 0
Maximum element's row index in the column 5 is 0 with value 0
Reduce buffer data for matrix `BTraspose`:
Maximum element's row index in the column 0 is 1 with value 2
Maximum element's row index in the column 1 is 2 with value 1
Maximum element's row index in the column 2 is 0 with value 0
Maximum element's row index in the column 3 is 0 with value 0
Maximum element's row index in the column 4 is 0 with value 0
Maximum element's row index in the column 5 is 0 with value 0
No Nash Equilibrium.
```

Cum ați explicat la lecție de laborator, algoritmul nu lucrează pentru orice input, deoarece calculăm numai un maxim în fiecare linie (coloană). 
Soluția este (2, 2), (3, 3), (4, 4), însă în toate cazurile în matricea B un indice precedent ia prioritate.

Pentru al doilea variant de program cu input de la tăstătură am modificat un pic codul inițial cu input, deoarece nu lucra corect (MPI-ul nu transmite output-ul programei dacă nu scrieți și un newline în finalul buferului, readln returnează buferul cu newline, dacă dați un input incorect programul nici nu se termină, deoarece MPI nu înțelege excepții, etc., chestii mici).

Clasicul `readInt()`:
```d
char[] keyboardInputBuffer;
int readInt()
{
    import std.stdio : readln, stdin;
    import std.conv : to;
    import std.string : strip;
    while (true)
    {
        try
        {
            readln(keyboardInputBuffer);
            int result = keyboardInputBuffer[].strip.to!int;
            return result;
        }
        catch (Exception err)
        {
        }
    }
    return 0;
}
```

```
$ ./compile.sh lab1 -version=KeyboardInput   
$ mpirun -np 6 lab1.out                      
Enter A[0, 0] =
1
Enter A[0, 1] =
2
Enter A[0, 2] =
3
Enter A[0, 3] =
4
Enter A[0, 4] =
5
Enter A[0, 5] =
6
Enter A[1, 0] =
1
2
3
```
 
Nu lucrează. Clar că aceasta este deoarece input-ul merge la primul proces. Asta am anticipat.

> Realizez o funcție care lucrează după următoatea secțiune.


### Matricea de orice dimensiune, toate maximuri

Fie matricea $ A $ de dimensiunea $ NumRows \times NumCols $. 

Pentru a distribui liniile (coloanele) acestei matrici egal (cât mai egal) între procese, procesul cu rancul $ i $ va primi $ \left \lfloor{P * (i + 1) - P * i}\right \rceil  $ linii, unde $ P = NumRows / Size $ (sau $ NumCols / Size $), $ Size $ — numărul de procese în grup.

Am realizat un test care asigură că formula este corectă:
```d
unittest
{
    foreach (int numRows; 1..100)
    foreach (int numProcesses; 1..100)
    {
        int sum;
     	foreach (i; 0..numProcesses)
        {
            sum += numRows * (i + 1) / numProcesses - numRows * i / numProcesses;
        }
        assert(sum == numRows);
    }
}
```

Acum întrebarea este cum să facem astfel încât fiecare proces să aibă N număr de linii?
Adică cum să realizăm aceasta în cod? 
Voi utiliza codul meu pentru matrici. 
L-am modificat să nu aibă deplasare la linii și coloane dacă nu este o submatrice.

Deci ne întoarcem la algoritmul meu. 

1. Distribuim fiecărui proces porțiunea lui de linii sau coloane;
2. Calculăm maximuri după aceste linii sau coloane;
3. Împărțim (point-to-point) informația necesară cu celelalte procese, primim informația de la celelalte procese;
4. Calculăm, cu ajutorul informației primite, punctele Nash de echilibru.

Detalii:

La primul punct, distribuim proceselor (sau inițializăm procele cu) *coloanele* din matricea $ A $ și *rândurile* din matricea $ B $.

La al doilea punct, procesele perform operația de aflarea maximului iterând pe vectorii săi.

Mai departe, fiecare proces va necesita informația de la fiecare alt proces.
Aici trebuie să utilizăm ori funcțiile de comunicare point-to-point buferizate, ori funcția `sendrecv`, ca să nu ne nimerim într-un deadlock unde fiecare proces încearcă să trasmită sincron simultan.

> O altă idee este de colectat informații de la toate procesele în memoria tuturor proceselor, sau și mai bine, să utilizăm memoria partajată pentru rezultatele.
> Încă o idee este să folosim scatter la fiecare proces.
> Încă o idee este să stocăm rezultatele într-un bitmap pentru a minimiza memoria necesară (indicii biților să indice dacă elementul din matrice pe acel indice este maxim).

Acum fiecare proces verifică datele primite și determină punctele de echilibru.


La **pasul 1** toate procesele își umplă matricile.

Copierea în acest caz nu a fost numaidecât necesară, deoarece putem citi matricile direct din memoria programului (nu le schimbăm, de aceea am putea lucra cu matricile constante). 
Am putea face aceasta ușor utilizând wrapperul meu pentru submatrici deplasate pe rând sau coloană.
Astfel cum am făcut încă este mai ușor de realizat input-ul de la tăstătură dacă va trebui.
Însă dacă am folosi matricile peste tot, am elimina aceste calculări urâte ale inidicilor lineare.

```d
int offsetForProcess(int processIndex, int vectorCount)
{
    return processIndex * vectorCount / info.size;
}
enum DataHeight = AData.length / DataWidth;

// ================================================
//      Step 1: Distribute rows / columns.
// ================================================
// The number of columns = width of the matrix.
const columnIndexStartA = offsetForProcess(info.rank, DataWidth);
const columnIndexEndA = offsetForProcess(info.rank + 1, DataWidth);
const numAllocatedColumnsA = cast(size_t) columnIndexEndA - columnIndexStartA;
int[] ABuffer = new int[](numAllocatedColumnsA);
// Does not allocate!
Matrix!int AMatrix = matrixFromArray(ABuffer, numAllocatedColumnsA); 
foreach (rowIndex; 0..DataHeight)
foreach (colIndex; 0..numAllocatedColumnsA)
{
    AMatrix[rowIndex, colIndex] = AData[rowIndex * DataWidth + columnIndexStartA + colIndex];
}

// The number of rows = height of the matrix.
const rowIndexStartB = offsetForProcess(info.rank, DataHeight);
const rowIndexEndB = offsetForProcess(info.rank + 1, DataHeight);
const numAllocatedRowsB = cast(size_t) rowIndexEndB - rowIndexStartB;
int[] BBuffer = new int[](numAllocatedColumnsA);
// Does not allocate!
Matrix!int BMatrix = matrixFromArray(BBuffer, DataWidth);
foreach (rowIndex; 0..numAllocatedRowsB)
foreach (colIndex; 0..DataWidth)
{
    BMatrix[rowIndex, colIndex] = BData[(rowIndex + rowIndexStartB) * DataWidth + colIndex];
}
```

La **pasul 2**, calculăm valorile maximale în coloanele lui A și în rândurile lui B.
Ideal ar trebui de folosit un bitmap, însă eu am procedat simplu pentru început și stochez valorile booleene ca intregi.
Putem realiza un bitmap și substitui, aproape fără schimbări, BOOL[] la această structură. 
(Însă atunci mai trebuie să ajustăm și `Matrix`). 
A este transpusă de 2 ori ca să putem folosi o singură funcție pentru determinarea valorilor maximale.
Transpunerea dublă o aduce pe A în sistemul de indexare inițial.

```d
// ================================================
//          Step 2: Find all maximums.
// ================================================
// Go with a true / false list for now (stored as ints).
alias BOOL = int;
BOOL TRUE = 1;
BOOL FALSE = 0;
Matrix!BOOL getMaximums(M)(M matrix)
{
    BOOL[] result = new BOOL[](matrix.width * matrix.height);
    auto resultMatrix = matrixFromArray(result, matrix.width);
    foreach (rowIndex; 0..matrix.height)
    {
        // Find the max, then mark true all cells with that values
        int maxValue = int.min;
        foreach (colIndex; 0..matrix.width)
        {
            import std.algorithm.comparison : max;
            maxValue = max(maxValue, matrix[rowIndex, colIndex]);
        }
        foreach (colIndex; 0..matrix.width)
        {
            if (matrix[rowIndex, colIndex] == maxValue)
                resultMatrix[rowIndex, colIndex] = TRUE;
        }
    }
    return resultMatrix;
}
// We transpose A twice so in the end it's normal again
auto matrixOfWhetherIndexIsMaximumA = getMaximums(AMatrix.transposed).transposed;
auto matrixOfWhetherIndexIsMaximumB = getMaximums(BMatrix);

version (unittest)
{
    if (info.rank == 0)
    {
        assert(matrixOfWhetherIndexIsMaximumA[0, 0] == TRUE);
        assert(matrixOfWhetherIndexIsMaximumB[0, 1] == TRUE);
    }
    else if (info.rank == 1)
    {
        // Don't forget it's transposed!
        assert(matrixOfWhetherIndexIsMaximumA[1, 0] == TRUE);
        assert(matrixOfWhetherIndexIsMaximumB[0, 2] == TRUE);
    }
}
```

**Etapa 3 și 4** este cea mai interesantă din punct de vedere comunicării între procese.
Utilizez funcția `sendRecv` pentru a executa schimbul de date între procese.
Problema evidentă cu aceasta abordare este faptul că primul proces este mereu în fața celorlalte procese, și aceasta tendință are loc peste toate procesele: procesul 0 termină mai repede decât procesul 1, procesul 1 termină mai repede decât procesul 2, etc.

Aceasta ușor se observă dacă încercăm să ne imaginăm ce se întâmplă când algoritmul se execută.

* Primul proces sare peste prima iterare, deoarece `processIndex == 0`.
* Celelalte procese se blochează la prima iterație, încercând să-i trimită procesului 0 și simultan să primească datele de la el. Deci ele de fapt vor aștepta până când primul procesul intră în ciclul unde `processIndex` este egal cu indexul lor. Prin urmare, procesul cu indexul maxim nu va putea proceda înainte ca procesul 0 să intre ultimul ciclu.
* Primul proces intră ciclul unde `processIndex == 1`, permitând procesului 1 să-și transmite datele și să procede la următoare iterație.
* Procesul cu indexul 1 iar se va bloca la a doua iterația, așteptând până când procesul cu rancul 2 își termină comunicare cu procesul cu rancul 0. etc.
  
Sper că descrierea problemei a fost clară.

Deci, ideal, am dori să construim perechile unice de indici $ P_i $ pentru fiecare proces $ i $, unde $ P_i[j] = P_j[i] $ pentru fiecare proces.
De fapt, este o problema cunoscută în matematică și îmi pare că nu există algoritmi eficiente de rezolvare a acestei probleme pentru un număr de procese arbitrar (nu țin minte denumirea problemei de aceea nu pot da link).

```d
// ================================================
//     Step 3 & 4: Share values & Calculate Nash 
// ================================================
size_t maxPossibleAllocatedAColumns = (info.size + DataHeight - 1) / DataHeight;
size_t maxPossibleAllocatedBRows = (info.size + DataWidth - 1) / DataWidth;
// We need to send a rectangular submatrix.
BOOL[] sendBuffer = new BOOL[](numAllocatedRowsB * maxPossibleAllocatedAColumns);
BOOL[] receiveBuffer = new BOOL[](maxPossibleAllocatedBRows * numAllocatedColumnsA);
struct Point { size_t row; size_t column; }
Point[] results;

foreach (processIndex; 0..info.size)
{
    if (info.rank == processIndex)
        continue;

    const partnerRowIndexStartB = offsetForProcess(processIndex, DataHeight);
    const partnerRowIndexEndB = offsetForProcess(processIndex + 1, DataHeight);
    const partnerNumAllocatedRowsB = cast(size_t) partnerRowIndexEndB - partnerRowIndexStartB;

    // Calculate the index that the other proccess wants to receive.
    const partnerColumnIndexStartA = offsetForProcess(processIndex, DataWidth);
    const partnerColumnIndexEndA = offsetForProcess(processIndex + 1, DataWidth);
    const partnerNumAllocatedColumnsA = cast(size_t) partnerColumnIndexEndA - partnerColumnIndexStartA;
    const tag = 10;

    // No allocations!
    auto sendBufferSlice = sendBuffer[0..(partnerNumAllocatedColumnsA * numAllocatedRowsB)];
    auto sendMatrix = matrixFromArray(sendBufferSlice, partnerNumAllocatedColumnsA);
    // Copy the needed indices into the send buffer
    foreach (rowIndex; 0..numAllocatedRowsB)
    foreach (colIndex; 0..partnerNumAllocatedColumnsA)
    {
        sendMatrix[rowIndex, colIndex] = matrixOfWhetherIndexIsMaximumB[rowIndex, colIndex];
    }

    auto receiveBufferSlice = receiveBuffer[0..(partnerNumAllocatedRowsB * numAllocatedColumnsA)];
    mh.sendRecv(sendBufferSlice, processIndex, tag, receiveBufferSlice, processIndex, tag);

    auto receiveMatrix = matrixFromArray(receiveBufferSlice, numAllocatedColumnsA);
    foreach (rowIndex; 0..partnerNumAllocatedRowsB)
    foreach (colIndex; 0..numAllocatedColumnsA)
    {
        // Check if the cells in both A and B are max
        if (matrixOfWhetherIndexIsMaximumA[rowIndex + partnerRowIndexStartB, colIndex] 
            && receiveMatrix[rowIndex, colIndex])
        {
            results ~= Point(rowIndex, colIndex);
        }
    }
}
```

Și la **pasul 6** afișăm rezultatele:

```d
// ================================================
//            Step 5: Print results 
// ================================================
foreach (processIndex; 0..info.size)
{
    if (processIndex == info.rank)
    {
        foreach (result; results)
        {
            writeln("Process ", processIndex, " found (", result.row, ", ", result.col, ")");
        }
    }
    mh.barrier();
}
```

Întregul cod vedeți [aici](https://github.com/AntonC9018/uni_parallel/blob/7f39da6ba236b9ebc394b930e15f2e95260b85fa/source/lab1.d):

### Executarea (matricea arbitrară, toate punctele de echilibru)

Am intrat pe server și el imediat m-a blocat din nou, de aceea nu pot verifica rezultatele.


### Inputul în procesul 0, distribuirea valorilor la celelalte procese

Înțelegerea mea a problemei este că numai la procesul cu rancul 0 stdin este deschis.
Datorită acestui el reușea să primească inputul, iar când încerca procesul 1, el se afla într-un ciclu infinit aici:

```d
while (true)
{
    try
    {
        // stdin este închis, de aceea o excepție este aruncată.
        readln(keyboardInputBuffer);
        int result = keyboardInputBuffer[].strip.to!int;
        return result;
    }
    // excepția este prinsă și ciclul se începe din nou.
    catch (Exception err)
    {
    }
}
```

Deci trebuie să schimbăm ciclul în așa mod ca procesul 0 să ia valorile de la tăstătură și să le trimită celuilalt proces.
Pentru aceasta vom executa funcția dacă este root:
```d
if (processIndex == info.rank 
    || isRoot)
{
    loop(processIndex);
}
```


Și vom modifica funcțiile de intrare.
```d
inputForEveryProcess((int processIndex)
{
    foreach (colIndex, ref pair; reduceBufferA)
    {
        if (processIndex == info.rank)
        {
            writeln("Enter A[", processIndex, ", ", colIndex, "] = ");
            pair.rank = info.rank;
        }

        const tag = 10;
        if (processIndex == info.rank && info.rank == 0)
        {
            pair.value = readInt();
        }
        else if (processIndex == info.rank)
        {
            mh.recv(&pair.value, 0, tag);
        }
        else // if (info.rank == 0)
        {
            auto value = readInt();
            mh.send(&value, processIndex, tag);
        }
    }
});
```

Logica a devenit prea complicată, iar diferă de fapt numai ce bufer umplăm și ce mesaj afișăm.
Vom face o funcție-șablon care poate fi utilizată în loc de aceasta.

```d
void integerInputHandlerFunction(string messageFormatString, alias buffer)(int processIndex)
{
    foreach (i, ref pair; buffer)
    {
        if (processIndex == info.rank)
        {
            mixin("writeln(", messageString, ");");
            pair.rank = info.rank;
        }

        const tag = 10;
        if (processIndex == info.rank && info.rank == 0)
        {
            pair.value = readInt();
        }
        else if (processIndex == info.rank)
        {
            mh.recv(&pair.value, 0, tag);
        }
        else // if (info.rank == 0)
        {
            auto value = readInt();
            mh.send(&value, processIndex, tag);
        }
    }
}

inputForEveryProcess(
    // Îi transmitem șablonului un șir care va fi plasat în `writeln` în cod.
    &integerInputHandlerFunction!(`"Enter A[", processIndex, ", ", i, "] = "`, reduceBufferA));
```

Invocarea pentru B tot se simplifică:
```d
inputForEveryProcess(
    &integerInputHandlerFunction!(`"Enter B[", i, ", ", processIndex, "] = "`, reduceBufferB));
```

### Executarea (tăstătură — reparat)

La moment sunt blocat...