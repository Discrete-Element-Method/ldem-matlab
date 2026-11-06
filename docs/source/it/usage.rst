Uso
===

Eseguire una simulazione
------------------------

.. code-block:: matlab

   >> setup_path                        % aggiunge src/ al path di MATLAB
   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], totalTime=2e-4, ...
          fractureEnergy=0.1, ...
          output=struct('snapshotEvery', 250, 'controlNodesEvery', 10, ...
                        'energyEvery', 10, 'trackedBarEvery', 0));
   >> results = ldem.runSimulation(params, OutputFolder="output", ...
          Formats=["mat" "ansys" "vtk"]);
   >> ldem.post.plotEnergy(results);

``ldem.Parameters`` valida ogni valore quando viene assegnato e spiega cosa
non va (per esempio un passo di tempo instabile). La versione completa e
pronta all'uso è in ``examples/tension_101/runTension.m``.

Per usare un file di ingresso nel formato del programma originale:

.. code-block:: matlab

   >> params = ldem.Parameters.fromFile("DATA0.DAT");

Prove disponibili
-----------------

``testId = 101``
   Carico uniassiale: i nodi centrali dell'ultima colonna di moduli si
   muovono in :math:`x` con velocità imposta.
``testId = 102``
   Trave con due appoggi e due punti di carico. Le posizioni sono parametri di
   ``ldem.scenarios.FourPointBending`` (``supportPosition``, ``loadPosition``,
   in moduli da ciascuna estremità); i valori predefiniti richiedono una trave
   di oltre 70 moduli circa. Vedi ``examples/beam_102``.
``testId = 103``
   Trave incastrata alle due estremità, caricata in mezzeria con una forza che
   cresce linearmente e poi resta costante (``ldem.scenarios.ClampedBeam``). È
   l'unica prova caricata con una forza invece che con uno spostamento. Vedi
   ``examples/example1_clamped_beam``.

Per aggiungere una prova nuova si crea una sottoclasse di
``ldem.scenarios.Scenario`` (vedi :doc:`model`).

Perturbazione della mesh
------------------------

Il parametro ``meshPerturbation`` sposta in modo casuale i nodi interni. Il
suo valore è la deviazione standard come frazione della lunghezza del modulo:
``0`` (il predefinito) mantiene il reticolo regolare e qualsiasi valore
positivo attiva la perturbazione con quel valore. I numeri casuali seguono
``seed``.

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], meshPerturbation=0.02);

Cosa si ottiene: la struttura ``results``
-----------------------------------------

.. list-table::
   :header-rows: 1
   :widths: 22 78

   * - Campo
     - Contenuto
   * - ``info``
     - Versione di ldem, data, versione di MATLAB, tempo di esecuzione [s].
   * - ``params``
     - I parametri usati, come struttura semplice (con i valori derivati).
   * - ``model``
     - Conteggi e massa del modello: moduli, nodi, barre per tipo, gradi di
       libertà bloccati, massa totale e volume.
   * - ``material``
     - Dati del materiale (E, Gf, ...), coefficienti del reticolo, lunghezza
       critica e statistiche della deformazione critica (media, coefficiente
       di variazione, minimo e massimo).
   * - ``mesh``
     - Posizioni iniziali dei nodi, vincoli (``fixed``), masse, barre,
       lunghezze e tipi di barra.
   * - ``barProps``
     - Rigidezza, deformazione critica e deformazione di rottura di ogni barra.
   * - ``controlNodes``
     - Tempo e spostamento, velocità e accelerazione dei nodi di controllo.
   * - ``reactions``
     - Tempo e forza di reazione ``[Rx Ry Rz]`` della prova: forza verticale
       nei punti di carico (prova 102), forza alle estremità incastrate
       (prova 103); ``NaN`` dove la prova non la definisce.
   * - ``energy``
     - Tempo, energie cinetica, elastica, di danno e di smorzamento [J], la
       loro somma (``internal``), l'energia delle barre rotte
       (``brokenBars``), il lavoro esterno, il bilancio (``balance``, esterno
       meno interno) e la velocità di danno.
   * - ``trackedBar``
     - Deformazione, forza ed energia di danno di una barra a ogni passo
       (opzionale).
   * - ``snapshots``
     - Passo, tempo, numero di barre intatte/danneggiate/rotte e copie
       compatte degli spostamenti, dello stato di danno e dell'energia
       cinetica nodale nei passi salvati.
   * - ``final``
     - Spostamento, velocità, forza e stato di danno finali, e l'energia
       cinetica di ogni nodo.

Il ``balance`` energetico è un controllo della simulazione: deve essere una
piccola frazione (meno dell'1 %) del lavoro esterno finale. L'energia cinetica
totale è ``energy.kinetic``; quella di ogni nodo è in ``final.kineticEnergy``.

``results.mat`` contiene questa struttura e si carica senza il pacchetto:

.. code-block:: matlab

   >> data = load("output/results.mat");
   >> results = data.results;

File di uscita
--------------

``results.mat``
   La struttura ``results`` (formato v7.3, leggibile da Python con ``h5py``).
``snapshot_0000.mac``, ``snapshot_0001.mac``, ...
   Macro ANSYS con il reticolo deformato. Le barre sono elementi di tipo 1
   (intatte), 2 (danneggiate) e 5 (rotte). I gradi di libertà bloccati sono
   elencati come ``D,nodo,direzione`` e lo spostamento imposto ai nodi
   caricati, misurato dalla posizione iniziale, come
   ``D,nodo,direzione,valore``. Nella prova 103 le forze applicate sono
   elencate come ``F,nodo,direzione,valore``.
``snapshot_0000.vtu``, ... e ``snapshots.pvd``
   File VTK. Aprire ``snapshots.pvd`` in `ParaView <https://www.paraview.org>`_;
   colorare per ``damageState`` (dati di cella) per vedere le fessure e usare
   il cursore del tempo per seguirle. Spostamento e velocità sono dati di
   punto.

I file ANSYS e VTK vengono scritti al tempo zero e ogni
``params.output.snapshotEvery`` passi.

Eseguire i test
---------------

.. code-block:: matlab

   >> addpath tests
   >> run_tests                          % test rapidi
   >> run_tests(IncludeSlow=true)        % anche i test lenti
