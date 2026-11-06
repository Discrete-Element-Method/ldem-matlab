Instalación
===========

Requisitos: MATLAB R2022b o superior (desarrollado y probado en R2023b). El
paquete usa el bloque ``arguments`` y la sintaxis nombre=valor; la suite de
tests y ``buildtool`` requieren R2022b. No hace falta ningún toolbox.

.. code-block:: bash

   git clone <url-del-repositorio> ldem-matlab
   cd ldem-matlab

.. code-block:: matlab

   >> setup_path

Comprobar la instalación con los tests rápidos:

.. code-block:: matlab

   >> buildtool test

Tareas para desarrolladores (``buildtool`` se ejecuta desde la raíz del
repositorio):

.. code-block:: matlab

   >> buildtool             % análisis estático + tests rápidos (por defecto)
   >> buildtool check       % solo el analizador de código
   >> buildtool testAll     % todos los tests, incluidos los lentos
   >> buildtool docs        % construir esta documentación (requiere Python)
   >> buildtool clean       % borrar los archivos generados

``buildtool test`` escribe ``test-results/results.xml`` (JUnit) y
``code-coverage/coverage.xml`` (Cobertura).

Para construir esta documentación sin MATLAB ver :doc:`docs`.
