
## Jocuri bimatriceale si situatii Nash de echilibru. 

Fie dat un joc bimatriceal $ \gamma = \langle I, J, A, B \rangle $, unde $I$ — mulțimea de indici ai liniilor matricelor, $J$ — a coloanelor, $ A = {|| a_{ij} ||} _ {j \in J} ^ {i \in I}, B = {|| b_{ij} ||} _ {j \in J} ^ {i \in I} $ reprezintă matricele de câștig ale jucătorilor.

Elementul $ i \in I $ ($ j \in J $), se numește **strategia pură a jucătorului 1 (2)**. 
Perechea de indici $ \(i, j\) $ reprezintă o situație în strategii pure. 
Jocul se realizează astfel: fiecare jucator independent si "concomitent" (adică alegerile de strategii nu depind de timp) 
alege strategia sa, după care se obține o situație în baza căreia jucătorii calculează câștigurile care reprezintă elementul $ a_{ij} $ pentru jucătorul 1 și, respectiv, $ b_{ij} $ pentru jucătorul 2 și cu aceasta jocul ia sfârșit.

Situaţia de echilibru este perechea de indici $ \(i ^ {\star}, j ^ {\star}\) $ pentru care se verifică sistemul de inegalităţi:

$$
\(i^\star, j^\star\) \Leftrightarrow
\begin{cases} 
    a_{i^\star j^\star} \geq a_{i j^\star} & \forall i \in I \\\\
    b_{i^\star j^\star} \geq b_{i^\star j} & \forall j \in J
\end{cases}$$

Vom spune că linia $ i $ strict domină linia $ k $ în matricea $ A $ dacă şi numai dacă $ a_{ij} > a_{kj}, \forall j \in J $. 
Dacă există $ j $ pentru care inegalitatea nu este strictă, atunci vom spune că linia $ i $ domină (nestrict) linia $ k $. 

Similar, vom spune: coloana $ j $ strict domină coloana $ l $ în matricea $ B $ dacă şi numai dacă $ b_{ij} > b_{il}, \forall i \in I $.
Dacă există $ i $ pentru care inegalitatea nu este strictă, atunci vom spune: *coloana $ j $ domină (nestrict) coloana $ l $*.

În baza definiției prezentăm următorul algoritm secvential pentru determinarea situației de echilibru.

**Algoritm 6.1**

- a. În cazul în care **nu se dorește** determinarea tuturor situațiilor de echilibru, se elimină din matricea $ A $ şi $ B $ liniile care sunt dominate în matricea $ A $ și se elimină din matricea $ A $ și $ B $ coloanele care sunt dominate în matricea $ B $.
- b. În cazul în care **se dorește** determinarea tuturor situațiilor de echilibru, se elimină din matricea $ A $ și $ B $ liniile care sunt strict dominate în matricea $ A $ şi se elimină din matricea $ A $ şi $ B $ coloanele care sunt strict dominate în matricea $ B $.
- c. Se determină situațiile de echilibru pentru matricele:
    $ (A^\prime, B^\prime), A^\prime = {|| a^\prime_{ij} ||} ^ {i \in I^\prime} _ {j \in J^\prime},$ și $ B^\prime = {|| b^\prime_{ij} ||} ^ {i \in I^\prime} _ {j \in J^\prime}, $
    obținute din pasul a sau b. Este clar că $| I^\prime | \leq | I |,  | J^\prime | \leq | J |$

    * Pentru orice coloană fixată în matricea $ A $, notăm (evidenţiem) toate elementele maximale după linie. 
      Cu alte cuvinte, se determină $ i^\star (j) = Arg \max_{ i \in I^\prime } a^\prime_{ij}, \forall j \in J^\prime $.

    * Pentru orice linie fixată în matricea $ B $, notăm (evidenţiem) toate elementele maximale după coloană. 
      Cu alte cuvinte, se determină $ j^\star (i) = Arg \max_{ j \in J^\prime } b^\prime_{ij}, \forall i \in I^\prime $.

    * Selectăm acele perechi de indici care concomitent sunt selectate atât în matricea $ A $ cât şi în matricea $ B $.
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

Situaţia de echilibru se determină numai în baza eliminării liniilor şi a coloanelor dominate. 
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

Vom elimina liniile şi coloanele dominate în următoarea ordine: linia 5, coloana 5, linia 4, coloana 4, 
coloana 3, linia 3, coloana 0, linia 0, coloana 1, linia 1. 
Astfel obţinem matricele $ A^\prime = (2) $ și $ B^\prime = (0) $, 
şi situația de echilibru este $ (i^\star, j^\star) = (2, 2) $ şi câştigul jucătorului 1 este 2, al jucătorului 2 este 0. 


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
$ Sub_{A^t} $ este o submatrice care consta din $ p $ coloane ale matricii $ A $ incepând cu coloana numarul $ k $ și este "distribuită" procesulul cu rancul $ t $. 
Similar este o submatrice care constă din $ p $ linii ale matricei B incepând cu linia $ k $ si este la fel distribuită procesului cu 
rancul $ t $.
Folosind algoritmul 6.1 descris mai sus procesul cu rancul $ t $ va determină pentru orice $ j_k \in J_k $ 
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


**Algoritmul paralel pentru determinarea situaţiilor de echilibru trebuie sa contină urmatoarele:**

- a. Eliminarea, în paralel, din matricea $A$ şi $B$ a liniilor care sunt (strict) dominate în matricea $A$ și din matricea 
$A$ şi $B$ a coloanelor care sunt (strict) dominate în matricea $B$. 

- b. Pentru orice proces $ t $ se determina submatricele $ {SubA}^t $ și $ {SubB}^t $.

- c. Fiecare proces $ t $ determină $i^\star (j_k)$ și $j^\star (i_k)$ pentru orice $k$.  
  Pentru aceasta se va folosi funcţia `MPI_Reduce` şi operația `ALLMAXLOC` (în cazul utilizării `MAXALLOC` rezultatele pot fi incorecte) care determină toate indicile elementelor maximale și este creată cu ajutorul funcției MPI `MPI_Op_create`. 
  După procesul $ t $ determină și în indici globali, adică indicii elementelor din matricea A și B. 

- d. Procesul cu rankul 0 va determina mulțimea de situații Nash de echilibru care este $ NE = (\cup _ t {LineGr} ^ t) \cap (\cup _ t {ColGr} ^ t) $.
 
**Pentru realizarea acestui algoritm pe clustere paralele sunt obligatorii următoarele:**

1. Paralelizarea la nivel de date se realizează in urmatoarele moduri: 
     - a) Procesul cu rankul 0 iniţializează valorile matricelor $ A $ şi $ B $, 
          construiește submatricele $ {SubA}^t $ și $ {SubB}^t $, 
          și le distribuie tuturor proceselor mediului de comunicare. 
     - b) Fiecare proces din mediul de comunicare construiește submatricele $ {SubA}^t $ și $ {SubB}^t $, 
          și le inițializează cu valori. 
     - c) Distribuirea matricelor pe procese se face astfel încât să se realizeze principiul load balancing.  
  
2. Paralelizarea la nivel de operaţii se realizează: 
     - a) prin utilizarea funcţiei `MPI_Reduce` şi a operaţiilor nou create.  
     - b) Nu se utilizeaza functia `MPI_Reduce`.  
 
3. Să se realizeze o analiză comparativă a timpului de execuție a programelor realizate când paralelizarea la nivel 
   de date se realizează in baza punctelor 1.a) si 1.b) 
   și paralelizarea la nivel de operații se realizează în baza punctelor 2.a) si 2.b). 
   
Mai jos vom prezenta codurile de programe in care se realizează variante simple ale lucrării de laborator cu utilizarea funcției `MPI_Reduce`, si anume:  

- În programul `Laborator_1_var_0_a.cpp` se realizează paralelizarea descrisă în a), matricele sunt de dimensiunea  
  `numtask * numtask`, sunt inițializate de procesul cu rancul 0 și submatricele sunt numai dintr-o singură linie (coloană). 
- În programul `Laborator_1_var_0_b.cpp` se realizează paralelizarea descrisă în b), matricele sunt de dimensiunea 
  `numtask * numtask`, sunt inițializate de procesul cu rankul 0 ți submatricele sunt numai dintr-o singură linie (coloană).