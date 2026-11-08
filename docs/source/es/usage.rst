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

Archivos de caso (``.ldem``)
----------------------------

Un *archivo de caso* describe todo el modelo en un único texto legible: claves
con nombre en lugar de posiciones, unidades junto a los números, comentarios, y
el ensayo, la dispersión aleatoria y los archivos de salida juntos. Reemplaza al
``DATA0.DAT``.

.. code-block:: text

   format = 1
   title  = "Ensayo de tracción pequeño"

   [mesh]
   module_size = 3 mm
   modules     = [5, 2, 2]        # módulos cúbicos en x, y y z

   [material]
   young_modulus = 32 GPa
   density       = 2000 kg/m3

   [time]
   step     = auto                # 0.9 veces el paso crítico
   duration = 40 us

   [scenario]
   type = "uniaxial_tension"

   [output]
   folder = "output"

.. code-block:: matlab

   >> ldem.io.writeTemplate("mi_ensayo.ldem", "clamped_beam");  % archivo comentado para editar
   >> ldem.check("mi_ensayo.ldem")                              % valida e informa, sin simular
   >> results = ldem.run("mi_ensayo.ldem");                     % lo ejecuta
   >> ldem.io.convertLegacyInput("DATA0.DAT", "caso.ldem");     % convierte un archivo antiguo

Reglas del formato:

* Las claves se leen por **nombre**; el orden de las líneas no importa. Las
  claves ausentes toman el valor por defecto de ``ldem.Parameters``. Solo son
  obligatorias ``scenario.type``, ``mesh.modules`` y ``time.duration``.
* Un número puede llevar **unidad**: ``3.87 GPa``, ``0.35 us``, ``1500 kg/m3``,
  ``2 kN/s``. Sin unidad el valor está en SI. Una unidad incorrecta para la
  clave es un error que lista las válidas.
* ``#`` inicia un comentario, ``[sección]`` abre una tabla, ``[[monitor.node]]``
  inicia el siguiente elemento de una tabla repetida y las listas se escriben
  ``[5, 5, 50]``.
* ``mesh.modules`` cuenta **módulos**: los ``M N L`` del ``DATA0.DAT`` cuentan
  nodos, uno más.
* ``time.step = auto`` (o sin ``step``) toma 0.9 veces el paso crítico.
* Cada error indica el archivo, la línea, la sección y la clave, y sugiere el
  nombre válido más parecido cuando hay un error de tipeo.
* Las rutas relativas (archivo del campo aleatorio, carpeta de salida) son
  relativas al archivo de caso.
* También se lee un archivo JSON con la misma estructura (los valores con
  unidades, como texto).

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Sección
     - Claves
   * - (inicio)
     - ``format`` (1), ``title``, ``authors``
   * - ``[mesh]``
     - ``module_size``, ``modules``, ``perturbation`` (desplazamiento aleatorio
       de los nodos, fracción del módulo), ``seed`` (de la perturbación)
   * - ``[material]``
     - ``law`` (``bilinear``, la ley original, o ``linear_elastic``: sin daño ni
       rotura), ``young_modulus``, ``poisson_ratio``, ``density``,
       ``fracture_energy``, ``critical_distance``, ``failure_area_factor``
   * - ``[material.scatter]``
     - Dispersión de la deformación crítica de las barras. ``type = "none"``;
       ``"file"`` con ``file`` (un multiplicador por barra); o ``"generated"``
       con ``cv``, ``correlation_length`` (en módulos) y ``seed`` (el campo se
       calcula en memoria)
   * - ``[time]``
     - ``step`` (o ``auto``), ``duration``
   * - ``[damping]``
     - ``type`` (``mass_proportional``, el amortiguamiento original, o ``none``),
       ``initial``, ``final``, ``switch_time`` (no se admiten con ``none``),
       ``constitutive``
   * - ``[scenario]``
     - ``type`` (``uniaxial_tension``, ``four_point_bending``,
       ``clamped_beam`` o ``custom``, ver más abajo) y las propiedades de ese escenario en snake_case, por
       ejemplo ``force_rate``, ``ramp_time``, ``load_position`` (se admite
       ``"midspan"``)
   * - ``[[monitor.node]]``
     - Un elemento por nodo de control: ``id`` (número de nodo) o
       ``at = [x, y, z]`` (posición en módulos, se usa el nodo más cercano), y
       ``name``
   * - ``[monitor.bar]``
     - ``tracked``: barra cuya historia de deformación se guarda en cada paso
   * - ``[output]``
     - ``folder``, ``mat``, ``ansys``, ``vtk`` (true o false)
   * - ``[output.snapshots]``, ``[output.control_nodes]``, ``[output.energy]``
     - ``every``: ``1000 steps`` o un tiempo como ``0.1 ms`` (se convierte a
       pasos); ``0`` significa nunca

``ldem.io.readCase`` devuelve los parámetros, el escenario y las opciones de
salida; ``ldem.Parameters.fromFile`` también acepta un archivo de caso. La lista
de claves está en una sola tabla, ``ldem.schema.caseSchema``, que gobierna el
lector, el escritor y la plantilla. Para agregar un escenario, se agrega una
línea a ``ldem.scenarios.registry``. Una ley constitutiva nueva es una subclase
de ``ldem.material.MaterialLaw`` registrada en ``ldem.material.lawRegistry``; un
modelo de amortiguamiento nuevo, una subclase de ``ldem.solver.DampingModel``
registrada en ``ldem.solver.dampingRegistry``.

Reutilizar un caso: extends
---------------------------

Un archivo de caso puede partir de otro y cambiar solo lo que difiere:

.. code-block:: text

   extends = "base.ldem"              # or a list: ["base.ldem", "material.ldem"]

   [material]
   fracture_energy = 1 N/m            # only what changes

Las claves del archivo reemplazan a las heredadas. Una tabla repetida
(``[[support]]``, ``[[load]]``, ``[[monitor.node]]``, ``[[sweep]]``) reemplaza
toda la lista heredada. Cuando cambia el ``type`` del escenario, de
``[material.scatter]`` o de ``[damping]``, se descartan las claves del tipo
anterior que no se vuelven a definir. Con una lista, los últimos archivos
ganan. Las rutas relativas (archivo del campo aleatorio, carpeta de salida) son
relativas al archivo que las contiene, y un error nombra el archivo y la línea
donde está escrito el problema. ``results.info.case.parents`` guarda el hash de
cada archivo heredado.

Barridos de parámetros
----------------------

Para estudiar cómo depende el resultado de un valor, se listan los valores en
bloques ``[[sweep]]`` y se ejecuta ``ldem.sweep``:

.. code-block:: text

   [[sweep]]
   key    = "material.fracture_energy"
   values = ["0.1 N/m", "0.5 N/m", "1 N/m"]

   [[sweep]]
   key    = "time.duration"
   values = ["20 us", "40 us"]

.. code-block:: matlab

   >> summary = ldem.sweep("case.ldem");                 % 3 x 2 = 6 runs, one folder each
   >> ldem.sweep("case.ldem", DryRun=true);              % only validate and list the runs
   >> ldem.sweep("case.ldem", Vary={"scenario.force_rate", ["1 kN/s" "2 kN/s"]});
   >> results = ldem.run("case.ldem", Overrides=struct("path", "material.fracture_energy", "value", "2 N/m"));

Varios bloques dan todas las combinaciones; ``sweep_mode = "zip"`` (una clave al
principio del archivo) los toma uno a uno. Se puede variar cualquier clave de un
solo valor, y las del escenario como ``scenario.<clave>``. Los valores son
números o textos con unidades. Cada corrida se valida antes de empezar la
primera. Las corridas van a ``run_001``, ``run_002``, ... (cada una con su
``case.ldem`` resuelto) y la tabla ``sweep_summary.csv`` las lista, con el
número de barras dañadas y rotas; una corrida que falla queda registrada y el
barrido continúa.

Referencia de todas las claves
------------------------------

Las tablas siguientes se generan desde ``ldem.schema.caseSchema``, la misma tabla
que usa el lector, así que siempre coinciden con él. Las descripciones están en
inglés.

.. include:: ../case-keys.inc

Su propio ensayo: apoyos y cargas
---------------------------------

Con ``type = "custom"`` el ensayo se describe en el archivo de caso con bloques
``[[support]]`` y ``[[load]]``, sin escribir una clase. Este es el ensayo
uniaxial (``testId = 101``) como bloques:

.. code-block:: text

   [scenario]
   type = "custom"

   [[support]]
   name = "left end"
   x    = 0.5                 # the layer of centre nodes at x = 0.5 modules
   fix  = ["x"]               # directions that cannot move

   [[load]]
   name          = "right end"
   x             = "max - 0.5"
   direction     = "x"
   type          = "displacement"    # or "force"
   time_function = "linear"
   rate          = -4 mm/s
   reaction      = true              # its force is the reaction of the test

Los **nodos** se eligen con ``nodes`` (``all``, ``grid`` para las esquinas de
los módulos o ``centre`` para sus centros), ``ids`` (números de nodo) y ``x``,
``y``, ``z``. Una posición está en módulos (los nodos centrales están en
semienteros, los de esquina en enteros), un rango ``[lo, hi]``, o un texto con
las referencias ``min``, ``max`` y ``mid`` y un desplazamiento, como
``"max - 0.5"``. Un nodo debe cumplir todas las condiciones. Las posiciones se
refieren a la malla regular, así que no cambian cuando ``mesh.perturbation``
mueve los nodos.

Los **apoyos** fijan las direcciones de ``fix``. Las **cargas** actúan en una
``direction`` como ``force`` (newtons en cada nodo elegido) o como
``displacement`` impuesto (metros desde la posición inicial; el solver fija esa
dirección). El valor sigue ``time_function``: ``constant`` (``value``),
``linear`` (``rate``), ``ramp`` (``rate`` hasta el tiempo ``until`` y luego
constante) o ``table`` (``times`` y ``values`` en unidades SI, lineal entre
puntos y constante fuera).

Un bloque con ``reaction = true`` suma su fuerza a la reacción del ensayo (la
suma de las fuerzas de barra en sus direcciones fijas); si ninguno la pide, la
reacción es NaN. Un bloque que no elige ningún nodo es un error que lo nombra.
Los tres ensayos incorporados escritos así dan exactamente los mismos
resultados que sus clases.

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
