Construir un modelo distinto
============================

Un modelo se define con tres cosas: la **geometría** del reticulado, el
**material** y el **ensayo** (apoyos y cargas). Las dos primeras son
parámetros; la tercera es una clase *escenario*. Se puede cambiar cualquiera
sin tocar el solver.

1. Cambiar la geometría y el material
-------------------------------------

Todo es una propiedad de ``ldem.Parameters``:

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, ...
          moduleLength=0.002, ...          % arista del módulo cúbico [m]
          nModules=[21 6 6], ...           % nodos en x, y y z
          youngModulus=30e9, density=2400, poissonRatio=0.2, ...
          fractureEnergy=80, criticalDistance=0.02, ...
          meshPerturbation=0.02);          % malla irregular (opcional)

* ``nModules = [M N L]`` es el número de nodos de la grilla en cada eje, de
  modo que el prisma tiene ``(M-1)*(N-1)*(L-1)`` módulos.
* ``randomFieldFile`` multiplica la deformación crítica de cada barra por un
  valor leído de un archivo de texto (campo aleatorio de la resistencia).
* ``dt`` debe ser menor que ``params.criticalTimeStep``; ``Parameters``
  rechaza un valor inestable y lo explica.

Los mismos datos pueden venir de un archivo de entrada con el formato del
programa original: ``ldem.Parameters.fromFile("DATA0.DAT", ...)``; los pares
nombre=valor adicionales reemplazan a los del archivo. La malla se puede
construir e inspeccionar antes de ejecutar nada:

.. code-block:: matlab

   >> mesh = ldem.mesh.buildMesh(params);
   >> fprintf("%d nodos, %d barras\n", size(mesh.nodes0, 1), size(mesh.bars, 1));

2. Cambiar el ensayo: escribir un escenario
-------------------------------------------

Un *escenario* dice qué grados de libertad están fijos, cómo se aplica la
carga en cada paso de tiempo y qué reacción se informa. El solver nunca
consulta el número del ensayo; se lo pregunta al escenario. Para modelar un
ensayo nuevo se crea una subclase de ``ldem.scenarios.Scenario`` en
``src/+ldem/+scenarios/``.

El ejemplo es una viga en voladizo según :math:`z`: la primera capa de nodos
centrales está empotrada y en el extremo libre se aplica en :math:`y` una
fuerza que crece linealmente.

.. code-block:: matlab

   classdef Cantilever < ldem.scenarios.Scenario
       properties (Constant)
           testId = 104                 % número nuevo, único
       end
       properties
           forceRate (1,1) double = 500 % [N/s] en cada nodo cargado
       end
       methods
           function fixed = fixedDofs(~, nodes0, params)
               z = nodes0(:, 3);
               atStart = abs(z - 0.5*params.moduleLength) < 0.01*params.moduleLength;
               fixed = false(size(nodes0));
               fixed(atStart, :) = true;          % x, y y z fijos
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

Reglas:

* ``fixedDofs`` devuelve una matriz lógica de ``nNodes`` por 3, verdadera donde
  el nodo no puede moverse (``1 = x``, ``2 = y``, ``3 = z``).
* ``applyLoads`` se ejecuta en cada paso. Un ensayo **controlado por
  desplazamiento** asigna ``state.displacement`` de los nodos cargados (ver
  ``UniaxialTension``); uno **controlado por fuerza** asigna
  ``state.appliedForce`` en newtons (ver ``ClampedBeam``) y el solver cuenta su
  trabajo en la energía externa.
* Se redefine ``reactions`` si el ensayo informa una fuerza de reacción (por
  defecto: ``NaN``).
* Los nodos centrales de los módulos están en múltiplos semienteros de
  ``moduleLength``; los nodos se seleccionan con una tolerancia pequeña, nunca
  con ``==``.

3. Registrarlo y ejecutarlo
---------------------------

Se puede pasar el objeto directamente, sin registrar nada:

.. code-block:: matlab

   >> scenario = ldem.scenarios.Cantilever(forceRate=1000);
   >> results = ldem.runSimulation(params, Scenario=scenario, ...
          OutputFolder="output", Formats=["mat" "vtk"]);

o agregarlo a la lista de ``ldem.scenarios.fromTestId`` para que
``testId = 104`` lo encuentre, que es lo que hace un archivo de entrada.
Después se agrega un test en ``tests/unit`` y, si es un caso de referencia, un
ejemplo en ``examples/`` (ver ``examples/example1_clamped_beam``).

El resultado es la misma estructura ``results`` de cualquier otro ensayo, ver
:doc:`usage`.
