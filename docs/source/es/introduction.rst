Introducción
============

El **Método de Elementos Discretos tipo Reticulado (LDEM)** modela un
continuo como un reticulado regular de nodos conectados por barras
dispuestas en módulos cúbicos (aristas más diagonales). Las masas son
concentradas en los nodos, las leyes constitutivas de las barras incluyen
daño/fractura y las ecuaciones de movimiento se integran con un esquema
explícito de diferencias centrales. Las energías (externa, cinética,
elástica, disipada) se controlan en cada paso.

Partes principales del paquete ``ldem`` (ver :doc:`../api/index`):

* ``ldem.Parameters`` / ``ldem.io.readInputFile`` – datos de entrada validados.
* ``ldem.mesh`` – nodos, barras, masas y geometría de las barras.
* ``ldem.material`` – rigidez de las barras, deformación crítica y ley bilineal de daño.
* ``ldem.scenarios`` – apoyos, cargas y reacciones de cada ensayo.
* ``ldem.solver`` – integración en el tiempo y balance de energía.
* ``ldem.runSimulation`` – la simulación completa, con salida ``results.mat``,
  ANSYS y VTK.

Las rutinas del programa original (``ini_DEM3``, ``read_dat0``, ``RMEC``,
``BOUND``, ``CALOAD``, ``ENERG2``, ...) se conservan en el historial de git, con
la etiqueta ``legacy-reference``; la línea ``Legacy:`` de cada ayuda nombra la
rutina que reemplaza.
