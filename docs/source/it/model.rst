Costruire un modello diverso
============================

Un modello è definito da tre cose: la **geometria** del reticolo, il
**materiale** e la **prova** (vincoli e carichi). Le prime due sono parametri;
la terza è una classe *scenario*. Ciascuna si può cambiare senza toccare il
solver.

1. Cambiare la geometria e il materiale
---------------------------------------

Tutto è una proprietà di ``ldem.Parameters``:

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, ...
          moduleLength=0.002, ...          % spigolo del modulo cubico [m]
          nModules=[21 6 6], ...           % nodi in x, y e z
          youngModulus=30e9, density=2400, poissonRatio=0.2, ...
          fractureEnergy=80, criticalDistance=0.02, ...
          meshPerturbation=0.02);          % mesh irregolare (opzionale)

* ``nModules = [M N L]`` è il numero di nodi della griglia lungo ogni asse,
  quindi il prisma ha ``(M-1)*(N-1)*(L-1)`` moduli.
* ``randomFieldFile`` moltiplica la deformazione critica di ogni barra per un
  valore letto da un file di testo (campo casuale della resistenza).
* ``dt`` deve essere minore di ``params.criticalTimeStep``; ``Parameters``
  rifiuta un valore instabile e ne spiega il motivo.

Gli stessi dati possono provenire da un file di ingresso nel formato del
programma originale: ``ldem.Parameters.fromFile("DATA0.DAT", ...)``; le
coppie nome=valore aggiuntive sostituiscono quelle del file. La mesh può
essere costruita e ispezionata prima di eseguire qualsiasi cosa:

.. code-block:: matlab

   >> mesh = ldem.mesh.buildMesh(params);
   >> fprintf("%d nodi, %d barre\n", size(mesh.nodes0, 1), size(mesh.bars, 1));

2. Cambiare la prova: scrivere uno scenario
-------------------------------------------

Uno *scenario* dice quali gradi di libertà sono bloccati, come viene applicato
il carico a ogni passo di tempo e quale reazione viene riportata. Il solver
non controlla mai il numero della prova: lo chiede allo scenario. Per
modellare una prova nuova si crea una sottoclasse di
``ldem.scenarios.Scenario`` in ``src/+ldem/+scenarios/``.

L'esempio è una trave a mensola lungo :math:`z`: il primo strato di nodi
centrali è incastrato e all'estremità libera si applica in :math:`y` una forza
che cresce linearmente.

.. code-block:: matlab

   classdef Cantilever < ldem.scenarios.Scenario
       properties (Constant)
           testId = 104                 % numero nuovo, univoco
       end
       properties
           forceRate (1,1) double = 500 % [N/s] su ogni nodo caricato
       end
       methods
           function fixed = fixedDofs(~, nodes0, params)
               z = nodes0(:, 3);
               atStart = abs(z - 0.5*params.moduleLength) < 0.01*params.moduleLength;
               fixed = false(size(nodes0));
               fixed(atStart, :) = true;          % x, y e z bloccati
           end
           function state = applyLoads(obj, state, mesh, params)
               L1 = params.nModules(3) - 1;
               z  = mesh.nodes0(:, 3);
               atEnd = abs(z - (L1 - 0.5)*params.moduleLength) < 0.01*params.moduleLength;
               state.appliedForce(:) = 0;
               state.appliedForce(atEnd, 2) = obj.forceRate * state.time;
           end
       end
   end

Regole:

* ``fixedDofs`` restituisce una matrice logica ``nNodes`` per 3, vera dove il
  nodo non può muoversi (``1 = x``, ``2 = y``, ``3 = z``).
* ``applyLoads`` viene eseguito a ogni passo. Una prova **a spostamento
  controllato** assegna ``state.displacement`` dei nodi caricati (vedi
  ``UniaxialTension``); una **a forza controllata** assegna
  ``state.appliedForce`` in newton (vedi ``ClampedBeam``) e il solver ne conta
  il lavoro nell'energia esterna.
* Ridefinire ``reactions`` se la prova riporta una forza di reazione
  (predefinito: ``NaN``).
* I nodi centrali dei moduli si trovano a multipli semi-interi di
  ``moduleLength``; selezionare i nodi con una piccola tolleranza, mai con
  ``==``.

3. Registrarlo ed eseguirlo
---------------------------

L'oggetto si può passare direttamente, senza registrare nulla:

.. code-block:: matlab

   >> scenario = ldem.scenarios.Cantilever(forceRate=1000);
   >> results = ldem.runSimulation(params, Scenario=scenario, ...
          OutputFolder="output", Formats=["mat" "vtk"]);

oppure aggiungerlo all'elenco di ``ldem.scenarios.fromTestId`` in modo che
``testId = 104`` lo trovi, come fa un file di ingresso. Poi si aggiunge un
test in ``tests/unit`` e, se è un caso di riferimento, un esempio in
``examples/`` (vedi ``examples/example1_clamped_beam``).

Il risultato è la stessa struttura ``results`` di qualsiasi altra prova, vedi
:doc:`usage`.
