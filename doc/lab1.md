# Lucrarea de laborator nr.1 la Programarea Paraelelă și Distribuită

Tema: **Jocuri bimatriceale si situatii Nash de echilibru.**
A realizat: **Curmanschii Anton, IA1901**

- [Lucrarea de laborator nr.1 la Programarea Paraelelă și Distribuită](#lucrarea-de-laborator-nr1-la-programarea-paraelelă-și-distribuită)
	- [Sarcina](#sarcina)
	- [Realizarea](#realizarea)
		- [Matrice](#matrice)

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
  {gr} ^ 0 _ {i^\star} = \\{ (0, 0) \\}, 
  {gr} ^ 1 _ {i^\star} = \\{ (1, 1) \\}, 
  {LineGr} ^ 0 = \\{ (0, 0), (1, 1) \\}; 
$
$ 
  {gr} ^ 0 _ {j^\star} = \\{ (0, 1) \\}, 
  {gr} ^ 1 _ {j^\star} = \\{ (1, 2) \\}, 
  {ColGr} ^ 0 = \\{ (0, 1), (1, 2) \\}.
$

Procesul cu **rancul 1** determină:
$ 
  {gr} ^ 0 _ {i^\star} = \\{ (2, 0) \\}, 
  {gr} ^ 1 _ {i^\star} = \\{ (3, 1) \\}, 
  {LineGr} ^ 1 = \\{ (2, 0), (3, 1) \\}; 
$
$ 
  {gr} ^ 0 _ {j^\star} = \\{ (0, 0), (0, 1), (0, 2), (0, 3) \\}, 
  {gr} ^ 1 _ {j^\star} = \\{ (1, 0), (1, 1), (1, 2), (1, 3) \\}, 
  {ColGr} ^ 1 = \\{ (0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1), (1, 2), (1, 3) \\}.
$
**În indici "globali":**
$
  {LineGr} ^ 1 = \\{ (2, 2), (3, 3) \\},
  {ColGr} ^ 1  = \\{ (2, 0), (2, 1), (2, 2), (2, 3), (3, 0), (3, 1), (3, 2), (3, 3) \\},
$

Procesul cu **rancul 2** determină:
$ 
  {gr} ^ 0 _ {i^\star} = \\{ (0, 0), (1, 0), (2, 0), (3, 0), (4, 0) \\}, 
  {gr} ^ 1 _ {i^\star} = \\{ (0, 1), (1, 1), (2, 1), (3, 1) \\}, 
  {LineGr} ^ 2 = \\{ (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (0, 1), (1, 1), (2, 1), (3, 1) \\}; 
$
$ 
  {gr} ^ 0 _ {j^\star} = \\{ (0, 0), (0, 1), (0, 2), (0, 3), (0, 4) \\}, 
  {gr} ^ 1 _ {j^\star} = \\{ (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5) \\}, 
  {ColGr} ^ 2 = \\{ (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5) \\}.
$
**În indici "globali":**
$
  {LineGr} ^ 2 = \\{ (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (0, 5), (1, 5), (2, 5), (3, 5) \\},
  {ColGr} ^ 2  = \\{ (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5) \\},
$

Procesul cu rancul 0 va determina $ LineGr $ și $ ColGr $ pentru indici globali:

$$ 
  {LineGr} = {LineGr} ^ 0 \cup {LineGr} ^ 1 \cup {LineGr} ^ 2 = 
  \left. 
    \begin{cases} 
      (0, 0), (1, 1), (2, 2), (3, 3), (0, 4), \\\\ 
      (1, 4), (2, 4), (3, 4), (4, 4), (0, 5), \\\\ 
      (1, 5),  (2, 5), (3, 5), (4, 5) 
    \end{cases}
  \right \\}
$$

și 

$$ 
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
$$

Atunci $ NE = LineGr \cap ColGr = \\{ (2, 2), (3, 3), (4, 4) \\} $.


**Algoritmul paralel pentru determinarea situațiilor de echilibru trebuie sa conțină urmatoarele:**

- a. Eliminarea, în paralel, din matricea $A$ și $B$ a liniilor care sunt (strict) dominate în matricea $A$ și din matricea 
$A$ și $B$ a coloanelor care sunt (strict) dominate în matricea $B$. 

- b. Pentru orice proces $ t $ se determina submatricele $ {SubA}^t $ și $ {SubB}^t $.

- c. Fiecare proces $ t $ determină $i^\star (j_k)$ și $j^\star (i_k)$ pentru orice $k$.  
  Pentru aceasta se va folosi funcția `MPI_Reduce` și operația `ALLMAXLOC` (în cazul utilizării `MAXALLOC` rezultatele pot fi incorecte) care determină toate indicile elementelor maximale și este creată cu ajutorul funcției MPI `MPI_Op_create`. 
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
     - b) Nu se utilizeaza functia `MPI_Reduce`.  
 
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

Fiind dat faptul că matricile sunt doar bidimensionale, nu vom primi multă performanță decă utilizăm un *vector definitor*, deci voi implementa ceva foarte simplu.

Sunt și librării pentru așa lucruri în D, de exemplu `mir`, însă pentru simplitate voi realiza singur.

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

Vom dori încă să supraîncărcăm proprietatea `length`, deoarece la moment `length` este readreasat lui tabloului subiacent.

```
Range range;
range[0] = 0;
range[1] = 5;
range.length; // ne dă 2, adică range.arrayof.length, însă am dori să ne dea 6.
```

Adăugăm funcția `length()`.

```
size_t length() { return arrayof[1] - arrayof[0] + 1; }
```

În D parantezele la apelarea funcțiilor sunt opționale, deci `range.length` este semantic echivalent cu `range.length()`.

Am dori să putem construi un Range dându-i valorile pentru capetele intervalului.
D de fapt definește implicit un constructor care atribuie valorile tuturor membrilor după tipurile lor, deci constructorul este deja definit.
Mie nu-mi place să fac validarea sau logica complicată în constructorul, deci constructorii mei în alte limbaje sunt ori inexistente dacă posibil, ori echivalente la constructori care D ar defini implicit.
Eu prefer funcții fabrici.

```d
Range range = Range([1, 2]);
// este echivalent cu
Range range;
range.arrayof = [1, 2];
```

Aici evident nu se face validarea, deoarece capetele din dreapta trebuie să fie mai mare sau egal cu capetele din stânga.

Am mai adăugat 2 funcții care verifică dacă un alt interval este în intervalul nostru, și dacă un număr este în intervalul nostru:

```d
bool contains(size_t a) { return a >= arrayof[0] && a <= arrayof[1]; }
bool contains(Range a) { return a[0] >= arrayof[0] && a[1] <= arrayof[1]; }
```

Mai am definit o funcție șablon care permite să facem orice operații aritmetice cu intervalul nostru și un obiect care conține elementele după indici 0 și 1.

```d
// Prima pereche de paranteze conține argumentele șablon.
// `string op` este o operație aritmetică, ca un șir. Poate fi "+", "-", "*" etc.
// `R` este orice tip.
// `(const auto ref R rhs)` înseamnă că nu vom modifica `rhs` 
// și că acceptăm orice tip de valori: rvalue, lvalue, după referință sau cu copiere.
// Compilatorul singur decide ce funcție se va executa.
// `const` înseamnă că intrvalul nostru nu se schimbă după operație.
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
    size_t allWidth()  { return Transposed ? _height : _width;  }
    /// The height of the source matrix, as seen after transposition.
    size_t allHeight() { return Transposed ? _width  : _height; }

    Range _rowRange;
    Range _colRange;

    /// The width of the matrix, as available to the user.
    /// The user may provide as the second index the values in range [0, width).
    size_t width()  { return Transposed ? _rowRange.length : _colRange.length; }
    /// The height of the matrix, as available to the user.
    /// The user may provide as the first index the values in range [0, height).
    size_t height() { return Transposed ? _colRange.length : _rowRange.length; }
}
```

Deci avem 5 membrii și 4 funcții getter. `T* array` conține pointer la tabloul subiacent, `_width` și `_height` — dimensiunile lui, `_rowRange` și `_colRange` — deplasările indicilor și conțin de fapt lungimea părții de tablou inițial pe care îl reprezintă matricea dată. 
Funcțiile getter sunt pentru comoditate a utilizatorului (iterarea etc.)

Așa ca proprietatea transpusului este controlată numai de variabila `Transposed`, operația de transpunere este trivială:
```d
// `auto` înțelege tipul implicit ca Matrix!(T, !Transposed)
auto transposed()
{
    // Prin primul semn al exclamării îi dăm matricei valorile șablon.
    // `Struct!(a, b)` este ca ca `Struct<a, b>` în C++.
    return Matrix!(T, !Transposed)(array, _width, _height, _rowRange, _colRange);
}
```

Vom defini o funcție ce află indexul elementului în memorie subiacentă.
Aici se presupune că `rowIndex` și `colIndex` sunt deja conform proprietății transpusului, adică sunt schimbate cu locuri dacă matricea este transpusă. 

```d
/// Returns the internal index into the underlying array.
private size_t getLinearIndex(size_t rowIndex, size_t colIndex)
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
auto ref opIndex(size_t rowIndex, size_t colIndex)
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
size_t opDollar(size_t dim : 0)() { return height; }
size_t opDollar(size_t dim : 1)() { return width;  }
```

Funcția `opIndex` lucrează cu tablouri de 2 elemente ca indici:
```d
auto opIndex(size_t[2] row, size_t[2] col)
{
    if (Transposed)
        swap(row, col);

    Range newRowRange = Range([_rowRange[0] + row[0], _rowRange[0] + row[1] - 1]);
    assert(_rowRange.contains(newRowRange));

    Range newColRange = Range([_colRange[0] + col[0], _colRange[0] + col[1] - 1]);
    assert(_colRange.contains(newColRange));

    return Matrix!(T, Transposed)(array, _width, _height, newRowRange, newColRange);        
}
```

Și pentru a transforma `a..b` în `size_t[2]` mai avem nevoie să definim funcția `opSlice`:
```d
// Support for `x..y` notation in slicing operator for the given dimension.
size_t[2] opSlice(size_t dim)(size_t start, size_t end) if (dim >= 0 && dim < 2)
{
    return [start, end];
}
```

Mai avem nevoie să acoperim cazurile când unul din indicii nu este un interval:
```d
// m[a..b, c] = m[a..b, c .. c + 1]
auto opIndex(size_t[2] rows, size_t colIndex) { return opIndex(rows, [colIndex, colIndex + 1]); }
// m[a, b..c] = m[a .. a + 1, b..c]
auto opIndex(size_t rowIndex, size_t[2] cols) { return opIndex([rowIndex, rowIndex + 1], cols); }
```

Atât cu matricea!

Am definit o funcție fabrică ce returnează o matrice construită din valorile unui tablou dinamic. 
(Sau a unui view într-un tablou static. În D aceasta se numește `slice`).

```d
auto matrixFromArray(T)(T[] array, size_t width)
{
    auto height = array.length / width;
    return Matrix!T(array.ptr, width, height, Range([0, height]), Range([0, width]));
}
```

Am mai definit niște teste, pentru a mă asigura că lucrează corect.
Vedeți [codul pe github](https://github.com/AntonC9018/uni_parallel/blob/26831202b5a3c6e6d7e6ebba3e69c8f19c571886/source/lab1.d#L97-L181), nu-l plasez aici.