
## Jocuri bimatriceale si situatii Nash de echilibru. 

Fie dat un joc bimatriceal $ \gamma = \langle I, J, A, B \rangle $, unde $I$ — mulțimea de indici ai liniilor matricelor, $J$ — a coloanelor, $ A = || a_{ij} ||, i \in I, j \in J $, $ B = || b_{ij} ||, i \in I, j \in J $ reprezintă matricele de câștig ale jucătorilor.

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
Dacă există j pentru care inegalitatea nu este strictă, atunci vom spune că linia $ i $ domină (nestrict) linia $ k $. 

Similar, vom spune: coloana $ j $ strict domină coloana $ l $ în matricea $ B $ dacă şi numai dacă $ b_{ij} > b_{il}, \forall i \in I $.
Dacă există $ i $ pentru care inegalitatea nu este strictă, atunci vom spune: *coloana $ j $ domină (nestrict) coloana $ l $*.

In baza definiției prezentăm următorul algoritm secvential pentru determinarea situației de echilibru.

**Algoritm 6.1**

- a. În cazul în care **nu se dorește** determinarea tuturor situațiilor de echilibru, se elimină din matricea $ A $ şi $ B $ liniile care sunt dominate în matricea $ A $ și se elimină din matricea $ A $ și $ B $ coloanele care sunt dominate în matricea $ B $.
- b. În cazul în care **se dorește** determinarea tuturor situațiilor de echilibru, se elimină din matricea $ A $ și $ B $ liniile care sunt strict dominate în matricea $ A $ şi se elimină din matricea $ A $ şi $ B $ coloanele care sunt strict dominate în matricea $ B $.
- c. Se determină situațiile de echilibru pentru matricele:
    $ (A^\prime, B^\prime), A^\prime = || a^\prime_{ij} ||, i \in I^\prime, j \in J^\prime,$ și $ B^\prime = || b^\prime_{ij} ||, i \in I^\prime, j \in J^\prime, $
    obținute din pasul a sau b. Este clar că $| I^\prime | \leq | I |,  | J^\prime | \leq | J |$

    * Pentru orice coloană fixată în matricea $ A $, notăm (evidenţiem) toate elementele maximale după linie. 
      Cu alte cuvinte, se determină $ i^\star (j) = Arg \max_{ i \in I^\prime } a^\prime_{ij}, \forall j \in J^\prime $.

    * Pentru orice linie fixată în matricea $ A $, notăm (evidenţiem) toate elementele maximale după coloană. 
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