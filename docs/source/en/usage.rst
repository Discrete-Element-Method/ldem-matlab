Usage
=====

Run a simulation
----------------

.. code-block:: matlab

   >> setup_path                        % adds src/ to the MATLAB path
   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], totalTime=2e-4, ...
          fractureEnergy=0.1, ...
          output=struct('snapshotEvery', 250, 'controlNodesEvery', 10, ...
                        'energyEvery', 10, 'trackedBarEvery', 0));
   >> results = ldem.runSimulation(params, OutputFolder="output", ...
          Formats=["mat" "ansys" "vtk"]);
   >> ldem.post.plotEnergy(results);

``ldem.Parameters`` checks every value when it is set and explains what is
wrong (for example an unstable time step). The complete, ready-to-run version
of this script is ``examples/tension_101/runTension.m``.

To use an input file in the format of the original program:

.. code-block:: matlab

   >> params = ldem.Parameters.fromFile("DATA0.DAT");

Tests available
---------------

``testId = 101``
   Uniaxial load: the centre nodes of the last column of modules move along
   :math:`x` with a prescribed velocity.
``testId = 102``
   Beam with two supports and two load points. The positions are parameters of
   ``ldem.scenarios.FourPointBending`` (``supportPosition``, ``loadPosition``,
   in modules from each end); the defaults need a beam longer than about 70
   modules. See ``examples/beam_102``.
``testId = 103``
   Beam clamped at both ends, loaded at mid-span with a force that grows
   linearly and then stays constant (``ldem.scenarios.ClampedBeam``). It is the
   only test loaded with a force instead of a displacement. See
   ``examples/example1_clamped_beam``.

To add a new test, create a subclass of ``ldem.scenarios.Scenario``.

Mesh perturbation
-----------------

The parameter ``meshPerturbation`` randomly displaces the interior nodes. Its
value is the standard deviation as a fraction of the module length: ``0`` (the
default) keeps the lattice regular and any positive value activates the
perturbation with that value. The random numbers follow ``seed``.

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], meshPerturbation=0.02);

What you get: the ``results`` struct
------------------------------------

.. list-table::
   :header-rows: 1
   :widths: 22 78

   * - Field
     - Content
   * - ``info``
     - ldem version, date, MATLAB release, run time [s].
   * - ``params``
     - The parameters used, as a plain struct (derived values included).
   * - ``model``
     - Counts and mass of the model: modules, nodes, bars by type, fixed degrees
       of freedom, total mass and volume.
   * - ``material``
     - Material data (E, Gf, ...), lattice coefficients, critical length and the
       statistics of the critical strain (mean, coefficient of variation, minimum
       and maximum).
   * - ``mesh``
     - Initial node positions, supports (``fixed``), masses, bars, bar lengths
       and bar types.
   * - ``barProps``
     - Stiffness, critical strain and rupture strain of every bar.
   * - ``controlNodes``
     - Time and displacement, velocity and acceleration of the control nodes.
   * - ``reactions``
     - Time and reaction force ``[Rx Ry Rz]`` of the test: vertical force at the load points
       (test 102), force on the clamped ends (test 103); ``NaN`` where the test defines none.
   * - ``energy``
     - Time, kinetic, elastic, damage and damping energies [J], their sum
       (``internal``), the energy of the broken bars (``brokenBars``), the external work,
       the ``balance`` (external minus internal) and the damage rate.
   * - ``trackedBar``
     - Strain, force and damage energy of one bar at every step (optional).
   * - ``snapshots``
     - Step, time, number of intact/damaged/broken bars, and compact copies of
       the displacements, the damage state and the nodal kinetic energy at the
       snapshot steps.
   * - ``final``
     - Final displacement, velocity, force and damage state, and the kinetic
       energy of every node.

The energy ``balance`` is a check of the simulation: it should be a small
fraction (below 1 %) of the final external work. The total kinetic energy is
``energy.kinetic``; the kinetic energy of each node is in ``final.kineticEnergy``.

``results.mat`` contains this struct and loads without the package:

.. code-block:: matlab

   >> data = load("output/results.mat");
   >> results = data.results;

Output files
------------

``results.mat``
   The ``results`` struct (format v7.3, readable from Python with ``h5py``).
``snapshot_0000.mac``, ``snapshot_0001.mac``, ...
   ANSYS macro files with the deformed lattice. Bars are element types 1
   (intact), 2 (damaged) and 5 (broken). The held degrees of freedom are
   listed as ``D,node,direction`` and the displacement imposed on the loaded
   nodes, measured from their initial position, as
   ``D,node,direction,value``. In test 103 the applied forces are listed as
   ``F,node,direction,value``.
``snapshot_0000.vtu``, ... and ``snapshots.pvd``
   VTK files. Open ``snapshots.pvd`` in `ParaView <https://www.paraview.org>`_;
   colour by ``damageState`` (cell data) to see the cracks and use the time
   slider to follow them. Displacement and velocity are point data.

ANSYS and VTK files are written at time zero and every
``params.output.snapshotEvery`` steps.

Run the tests
-------------

.. code-block:: matlab

   >> addpath tests
   >> run_tests                          % fast tests
   >> run_tests(IncludeSlow=true)        % also the slow tests
