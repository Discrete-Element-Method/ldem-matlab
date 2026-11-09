Building a different model
==========================

A model is defined by three things: the **geometry** of the lattice, the
**material** and the **test** (supports and loads). The first two are
parameters; the third is a *scenario* class. You can change any of them
without touching the solver.

1. Change the geometry and the material
---------------------------------------

Everything is a property of ``ldem.Parameters``:

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, ...
          moduleLength=0.002, ...          % edge of the cubic module [m]
          nModules=[21 6 6], ...           % nodes along x, y and z
          youngModulus=30e9, density=2400, poissonRatio=0.2, ...
          fractureEnergy=80, criticalDistance=0.02, ...
          meshPerturbation=0.02);          % optional irregular mesh

* ``nModules = [M N L]`` is the number of grid nodes along each axis, so the
  prism has ``(M-1)*(N-1)*(L-1)`` modules.
* ``randomFieldFile`` multiplies the critical strain of each bar by a value
  read from a text file (a random field of the material strength).
* ``randomFieldCv`` generates that random field in memory instead, with no
  file: Weibull values with mean 1 and that coefficient of variation on a grid
  of poles spaced ``randomFieldCorrelationLength`` module lengths apart (default
  3), interpolated to each bar; ``randomFieldSeed`` fixes the random numbers.
  The value of each bar is kept in ``results.barProps.randomField``.
* ``dt`` must be below ``params.criticalTimeStep``; ``Parameters`` rejects an
  unstable value and says so.

The same data can come from a case file (``ldem.io.readCase``, see
:doc:`usage`) or from an input file in the format of the original
program with ``ldem.Parameters.fromFile("DATA0.DAT", ...)``; extra
name=value pairs override the file. The mesh can be built and inspected
before running anything:

.. code-block:: matlab

   >> mesh = ldem.mesh.buildMesh(params);
   >> fprintf("%d nodes, %d bars\n", size(mesh.nodes0, 1), size(mesh.bars, 1));

2. Change the test: write a scenario
------------------------------------

A *scenario* says which degrees of freedom are fixed, how the load is
applied at every time step and which reaction is reported. The solver never
checks the test number, it only asks the scenario. To model a new test,
create a subclass of ``ldem.scenarios.Scenario`` in ``src/+ldem/+scenarios/``.

The example below is a cantilever beam along :math:`z`: the first layer of
centre nodes is clamped and a force that grows linearly is applied in
:math:`y` at the free end.

.. code-block:: matlab

   classdef Cantilever < ldem.scenarios.Scenario
       properties (Constant)
           testId = 104                 % new number, unique
       end
       properties
           forceRate (1,1) double = 500 % [N/s] on each loaded node
       end
       methods
           function fixed = fixedDofs(~, nodes0, params)
               z = nodes0(:, 3);
               atStart = abs(z - 0.5*params.moduleLength) < 0.01*params.moduleLength;
               fixed = false(size(nodes0));
               fixed(atStart, :) = true;          % x, y and z held
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

Rules to follow:

* ``fixedDofs`` returns an ``nNodes``-by-3 logical matrix, true where the node
  cannot move (``1 = x``, ``2 = y``, ``3 = z``).
* ``applyLoads`` runs once per step. A **displacement-controlled** test sets
  ``state.displacement`` of the loaded nodes (see ``UniaxialTension``); a
  **force-controlled** test sets ``state.appliedForce`` in newtons (see
  ``ClampedBeam``) and the solver counts its work in the external energy.
* Override ``reactions`` if the test reports a reaction force (default:
  ``NaN``).
* The centre nodes of the modules lie at half-integer multiples of
  ``moduleLength``; select nodes with a small tolerance, never with ``==``.

3. Register and run it
----------------------

Either pass the object directly, with no registration:

.. code-block:: matlab

   >> scenario = ldem.scenarios.Cantilever(forceRate=1000);
   >> results = ldem.runSimulation(params, Scenario=scenario, ...
          OutputFolder="output", Formats=["mat" "vtk"]);

or add one line to ``ldem.scenarios.registry`` so that
``testId = 104`` finds it and a case file can name it with ``type``. Then add a
test in ``tests/unit`` and, if it is a reference case, an example in
``examples/`` (see ``examples/example1_clamped_beam``).

The result is the same ``results`` struct as for any other test, see
:doc:`usage`.
