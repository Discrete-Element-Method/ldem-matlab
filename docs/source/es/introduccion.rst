Introducción
============

El **Método de Elementos Discretos tipo Reticulado (LDEM)** modela un
continuo como un reticulado regular de nodos conectados por barras
dispuestas en módulos cúbicos (aristas más diagonales). Las masas son
concentradas en los nodos, las leyes constitutivas de las barras incluyen
daño/fractura y las ecuaciones de movimiento se integran con un esquema
explícito de diferencias centrales. Las energías (externa, cinética,
elástica, disipada) se controlan en cada paso.

Rutinas principales (ver :doc:`../api/index`):

* ``ini_DEM3`` – inicializa las variables globales.
* ``read_dat0`` – lee el archivo de datos de entrada.
* ``CONECTI`` / ``INTCO1`` / ``EXTCO1`` – conectividad de barras.
* ``RMEC`` – propiedades mecánicas de las barras.
* ``BOUND`` / ``CALOAD`` – condiciones de contorno y cargas.
* ``ENERG2`` – balance de energía.
