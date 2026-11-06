Uso
===

Ejecutar una simulación
-----------------------

.. code-block:: matlab

   >> setup_path                        % agrega src/ al path de MATLAB
   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], totalTime=2e-4, ...
          fractureEnergy=0.1, ...
          output=struct('snapshotEvery', 250, 'controlNodesEvery', 10, ...
                        'energyEvery', 10, 'trackedBarEvery', 0));
   >> results = ldem.runSimulation(params, OutputFolder="output", ...
          Formats=["mat" "ansys" "vtk"]);
   >> ldem.post.plotEnergy(results);

``ldem.Parameters`` valida cada valor al asignarlo y explica qué está mal
(por ejemplo, un paso de tiempo inestable). La versión completa y lista para
ejecutar está en ``examples/tension_101/runTension.m``.

Para usar un archivo de entrada con el formato del programa original:

.. code-block:: matlab

   >> params = ldem.Parameters.fromFile("DATA0.DAT");

Ensayos disponibles
-------------------

``testId = 101``
   Carga uniaxial: los nodos centrales de la última columna de módulos se
   mueven en :math:`x` con velocidad impuesta.
``testId = 102``
   Viga con dos apoyos y dos puntos de carga. Las posiciones son parámetros de
   ``ldem.scenarios.FourPointBending`` (``supportPosition``, ``loadPosition``,
   en módulos desde cada extremo); los valores por defecto requieren una viga de
   más de unos 70 módulos. Ver ``examples/beam_102``.
``testId = 103``
   Viga empotrada en los dos extremos, cargada a media luz con una fuerza que
   crece linealmente y luego se mantiene constante
   (``ldem.scenarios.ClampedBeam``). Es el único ensayo cargado con una fuerza
   en lugar de un desplazamiento. Ver ``examples/example1_clamped_beam``.

Para agregar un ensayo nuevo se crea una subclase de
``ldem.scenarios.Scenario``.

Perturbación de la malla
------------------------

El parámetro ``meshPerturbation`` desplaza al azar los nodos interiores. Su
valor es la desviación estándar como fracción de la longitud del módulo: ``0``
(el valor por defecto) deja el reticulado regular y cualquier valor positivo
activa la perturbación con ese valor. Los números aleatorios siguen a ``seed``.

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], meshPerturbation=0.02);

Qué se obtiene: la estructura ``results``
-----------------------------------------

.. list-table::
   :header-rows: 1
   :widths: 22 78

   * - Campo
     - Contenido
   * - ``info``
     - Versión de ldem, fecha, versión de MATLAB, tiempo de cálculo [s].
   * - ``params``
     - Los parámetros usados, como estructura simple (con valores derivados).
   * - ``model``
     - Cantidades y masa del modelo: módulos, nodos, barras por tipo, grados de
       libertad fijos, masa total y volumen.
   * - ``material``
     - Datos del material (E, Gf, ...), coeficientes del reticulado, longitud
       crítica y estadísticas de la deformación crítica (media, coeficiente de
       variación, mínimo y máximo).
   * - ``mesh``
     - Posiciones iniciales, apoyos (``fixed``), masas, barras, longitudes y
       tipos de barra.
   * - ``barProps``
     - Rigidez, deformación crítica y deformación de rotura de cada barra.
   * - ``controlNodes``
     - Tiempo y desplazamiento, velocidad y aceleración de los nodos de control.
   * - ``reactions``
     - Tiempo y fuerza de reacción ``[Rx Ry Rz]`` del ensayo: fuerza vertical en los puntos
       de carga (ensayo 102), fuerza en los extremos empotrados (ensayo 103); ``NaN``
       donde el ensayo no la define.
   * - ``energy``
     - Tiempo, energías cinética, elástica, de daño y de amortiguamiento [J],
       su suma (``internal``), la energía de las barras rotas (``brokenBars``), el trabajo
       externo, el balance (``balance``, externo menos interno) y la tasa de daño.
   * - ``trackedBar``
     - Deformación, fuerza y energía de daño de una barra en cada paso
       (opcional).
   * - ``snapshots``
     - Paso, tiempo, número de barras intactas/dañadas/rotas y copias
       compactas de los desplazamientos, del estado de daño y de la energía
       cinética de cada nodo.
   * - ``final``
     - Desplazamiento, velocidad, fuerza y estado de daño finales, y la energía
       cinética de cada nodo.

El ``balance`` de energía es una comprobación de la simulación: debe ser una
fracción pequeña (menos del 1 %) del trabajo externo final. La energía cinética
total es ``energy.kinetic``; la de cada nodo está en ``final.kineticEnergy``.

``results.mat`` contiene esta estructura y se carga sin el paquete:

.. code-block:: matlab

   >> data = load("output/results.mat");
   >> results = data.results;

Archivos de salida
------------------

``results.mat``
   La estructura ``results`` (formato v7.3, legible desde Python con ``h5py``).
``snapshot_0000.mac``, ``snapshot_0001.mac``, ...
   Macros de ANSYS con el reticulado deformado. Las barras son elementos de
   tipo 1 (intactas), 2 (dañadas) y 5 (rotas). Los grados de libertad fijos
   se listan como ``D,nodo,dirección`` y el desplazamiento impuesto a los
   nodos cargados, medido desde su posición inicial, como
   ``D,nodo,dirección,valor``. En el ensayo 103 las fuerzas aplicadas se listan como
   ``F,nodo,dirección,valor``.
``snapshot_0000.vtu``, ... y ``snapshots.pvd``
   Archivos VTK. Abrir ``snapshots.pvd`` en `ParaView <https://www.paraview.org>`_;
   colorear por ``damageState`` (datos de celda) para ver las fisuras y usar
   el control de tiempo para seguirlas. Desplazamiento y velocidad son datos
   de nodo.

Los archivos ANSYS y VTK se escriben en el tiempo cero y cada
``params.output.snapshotEvery`` pasos.

Ejecutar los tests
------------------

.. code-block:: matlab

   >> addpath tests
   >> run_tests                          % tests rápidos
   >> run_tests(IncludeSlow=true)        % también los tests lentos
