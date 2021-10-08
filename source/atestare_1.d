// ========================================
//          Exercițiul 24 (L9Ex1)
// ========================================
// Să se realizeze o analiză comparativă a timpului de execuție 
// pentru programele MPI descrise în exemplul 3.6.1 
// (determinarea numărului π folosind comunicări doi-direcționate) 
// și exemplul 3.4.4 (determinarea numărului π folosind comunicări 
// unu-direcționate).
// ========================================
//
// Am rescris codul acelor programe în D și am scos partea computațională
// în funcții aparte. Așa programe mici va fi dificil de profilat corect,
// în special în întregime, de aceea cel puțin am făcut acest lucru.
// 
// Codul sursă care este profilat de către acest program găsiți aici:
// `example_3_4_4.d`: 
// `example_3_6_1.d`:
//
// Codul trebuie compilat cam astfel (utilizând scriptul meu, fiind în mapa mea): 
/*
    ./compile.sh Curmanschii_L9Ex1 example_3_4_4.d example_3_6_1.d
*/

// Importăm codul din fișierele cu funcțiile care trebuie fi profilate.
static import example_3_4_4;
static import example_3_6_1;

// În scurt, conține ciclul și un MPI_Reduce
alias twoDirectionalCalculatePi = example_3_4_4.calculatePi;
// În scurt, conține ciclul, alocarea ferestrei (opțional), și un fence + accumulate
alias oneDirectionalCalculatePi = example_3_6_1.calculatePi;

int main()
{
    import mpi;
    import mh = mpihelper;
    import std.stdio : writeln;

    // Inițializăm MPI de o singură dată. Eu profilez doar funcțiile, nu programe întregi.
    // Funcțiile sunt mai ușor de profilat de mai multe ori, nu trebuie să creăm procese 
    // noi de fiecare dată. Doar facem un ciclu de N iterații.
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    // Am adăugat aceasta pentru a estima constul creării ferestrelor.
    version(SingleWindow)
    {
        example_3_6_1.initializeWindow(info);
        scope(exit) example_3_6_1.freeWindow();
    }

    struct TestData
    {
        int outerNumIterations;
        int piAlgorithmNumIterationsStart;
        int piAlgorithmNumIterationsEnd;

        double twoDirectionalTotalSeconds = 0;
        double oneDirectionalTotalSeconds = 0;
    }
    
    auto testData = [
        // Cât de costisitoare este alocarea ferestrelor?

        // Se verifică cât de eficientă este comunicarea.
        TestData(100000, 1, 2),
        // Se verifică presiunea computațională.
        TestData(5, 19999990, 20000000)
    ];

    foreach (ref t; testData) with (t)
    {
        foreach (outerIterationCount; 0..outerNumIterations)
        {
            // if (info.rank == 0)
            //     writeln("Computing outer iteration ", outerIterationCount);

            double profile(alias func)()
            {
                double startSeconds = MPI_Wtime();
                foreach (piNumIterations; piAlgorithmNumIterationsStart..piAlgorithmNumIterationsEnd)
                {
                    func(info, piNumIterations);
                }
                return MPI_Wtime() - startSeconds;
            }
            
            twoDirectionalTotalSeconds += profile!twoDirectionalCalculatePi;
            oneDirectionalTotalSeconds += profile!oneDirectionalCalculatePi;
        }
    }

    if (info.rank == 0)
    {
        foreach (ref t; testData) with (t)
        {
            writeln("Test data: ", t);
            void report(string name, double seconds)
            {
                writeln(name, " communication took ", seconds / outerNumIterations, " seconds per iteration");
            }
            report("Two-directional", twoDirectionalTotalSeconds);
            report("One-directional", oneDirectionalTotalSeconds);
        }
    }

    return 0;
}


/*
    $ ./compile.sh atestare_1 example_3_4_4.d example_3_6_1.d

    $ mpirun -np 5 atestare_1.out
    Test data: TestData(100000, 1, 2, 0.483459, 7.34522)
    Two-directional communication took 4.83459e-06 seconds per iteration
    One-directional communication took 7.34522e-05 seconds per iteration
    Test data: TestData(5, 19999990, 20000000, 4.00964, 4.07417)
    Two-directional communication took 0.801928 seconds per iteration
    One-directional communication took 0.814834 seconds per iteration

    $ mpirun -np 15 atestare_1.out
    Test data: TestData(100000, 1, 2, 3.92491, 25.4672)
    Two-directional communication took 3.92491e-05 seconds per iteration
    One-directional communication took 0.000254672 seconds per iteration
    Test data: TestData(5, 19999990, 20000000, 2.85035, 2.9979)
    Two-directional communication took 0.57007 seconds per iteration
    One-directional communication took 0.59958 seconds per iteration
*/

// Pentru un număr mai mic de procese, comunicarea unidirecționată a avut un cost
// 15.3 ori mai mare decât comunicarea doi-direcționată, deci constul alocării ferestrelor 
// a fost de ~15 ori mai mare decât costul comunicării.

// Pentru un număr sporit de procese, această cifră este mai mică (6.48).

// Voi colecta mai multe date, alocând fereastra global doar o singură dată (version=SingleWindow)
/*
    $ ./compile.sh atestare_1 example_3_4_4.d example_3_6_1.d -version=SingleWindow

    $ mpirun -np 5 atestare_1.out
    Test data: TestData(100000, 1, 2, 0.361329, 1.3687)
    Two-directional communication took 3.61329e-06 seconds per iteration
    One-directional communication took 1.3687e-05 seconds per iteration
    Test data: TestData(5, 19999990, 20000000, 4.01696, 4.03641)
    Two-directional communication took 0.803393 seconds per iteration
    One-directional communication took 0.807283 seconds per iteration
    
    $ mpirun -np 15 atestare_1.out
    Test data: TestData(100000, 1, 2, 1.78642, 5.87108)
    Two-directional communication took 1.78642e-05 seconds per iteration
    One-directional communication took 5.87108e-05 seconds per iteration
    Test data: TestData(5, 19999990, 20000000, 2.74271, 2.83585)
    Two-directional communication took 0.548543 seconds per iteration
    One-directional communication took 0.567171 seconds per iteration
*/

// Deci alocarea ferestrei era de fapt costisitoare, însă schimbul de date este oricum mai lent.