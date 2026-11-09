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

Case files (``.ldem``)
----------------------

A *case file* describes the whole model in one readable text file: named keys
instead of positions, units next to the numbers, comments, and the test, the
random scatter and the output files together. It replaces ``DATA0.DAT``.

.. code-block:: text

   format = 1
   title  = "Small tension test"

   [mesh]
   module_size = 3 mm
   modules     = [5, 2, 2]        # cubic modules along x, y and z

   [material]
   young_modulus = 32 GPa
   density       = 2000 kg/m3

   [time]
   step     = auto                # 0.9 times the critical step
   duration = 40 us

   [scenario]
   type = "uniaxial_tension"

   [output]
   folder = "output"

.. code-block:: matlab

   >> ldem.io.writeTemplate("my_test.ldem", "clamped_beam");  % a commented file to edit
   >> ldem.check("my_test.ldem")                              % validate and report, no simulation
   >> results = ldem.run("my_test.ldem");                     % run it
   >> ldem.io.convertLegacyInput("DATA0.DAT", "case.ldem");   % convert an old input file

Rules of the format:

* Keys are read by **name**; the order of the lines does not matter. Keys that
  are missing take the default of ``ldem.Parameters``. Only ``scenario.type``,
  ``mesh.modules`` and ``time.duration`` are required.
* A number may carry a **unit**: ``3.87 GPa``, ``0.35 us``, ``1500 kg/m3``,
  ``2 kN/s``. Without a unit the value is in SI. The wrong unit for the key is
  an error that lists the valid ones.
* ``#`` starts a comment, ``[section]`` opens a table, ``[[monitor.node]]``
  starts the next element of a repeated table, lists are written ``[5, 5, 50]``.
* ``mesh.modules`` counts **modules**: the ``M N L`` of ``DATA0.DAT`` count
  nodes, one more.
* ``time.step = auto`` (or no ``step``) takes 0.9 times the critical step.
* Every error names the file, the line, the section and the key, and suggests
  the closest valid name for a mistyped one.
* Relative paths (the random-field file, the output folder) are relative to
  the case file.
* A JSON file with the same structure (values with units as strings) is also
  read.

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Section
     - Keys
   * - (top)
     - ``format`` (1), ``title``, ``authors``
   * - ``[mesh]``
     - ``module_size``, ``modules``, ``perturbation`` (random displacement of
       the nodes, fraction of the module), ``seed`` (of the perturbation)
   * - ``[material]``
     - ``law`` (``bilinear``, the legacy law, or ``linear_elastic``: no damage and no
       rupture), ``young_modulus``, ``poisson_ratio``, ``density``,
       ``fracture_energy``, ``critical_distance``, ``failure_area_factor``
   * - ``[material.scatter]``
     - Scatter of the critical strain of the bars. ``type = "none"``;
       ``"file"`` with ``file`` (one multiplier per bar); or ``"generated"``
       with ``cv``, ``correlation_length`` (in modules) and ``seed`` (the
       field is computed in memory)
   * - ``[time]``
     - ``step`` (or ``auto``), ``duration``
   * - ``[damping]``
     - ``type`` (``mass_proportional``, the legacy damping, or ``none``),
       ``initial``, ``final``, ``switch_time`` (not allowed with ``none``),
       ``constitutive``
   * - ``[scenario]``
     - ``type`` (``uniaxial_tension``, ``four_point_bending``,
       ``clamped_beam`` or ``custom``, see below) and the properties of that scenario in snake_case,
       for example ``force_rate``, ``ramp_time``, ``load_position`` (``"midspan"``
       is allowed)
   * - ``[[monitor.node]]``
     - One element per control node: ``id`` (node number) or ``at = [x, y, z]``
       (position in modules, the nearest node is used), and ``name``
   * - ``[monitor.bar]``
     - ``tracked``: bar whose strain history is stored at every step
   * - ``[output]``
     - ``folder``, ``mat``, ``ansys``, ``vtk`` (true or false)
   * - ``[output.snapshots]``, ``[output.control_nodes]``, ``[output.energy]``
     - ``every``: ``1000 steps`` or a time such as ``0.1 ms`` (converted to
       steps); ``0`` means never

``ldem.io.readCase`` returns the parameters, the scenario and the output
options; ``ldem.Parameters.fromFile`` also accepts a case file. The list of
keys lives in one table, ``ldem.schema.caseSchema``, which drives the reader,
the writer and the template. To add a scenario, add a line to
``ldem.scenarios.registry``. A new constitutive law is a subclass of
``ldem.material.MaterialLaw`` registered in ``ldem.material.lawRegistry``; a new
damping model is a subclass of ``ldem.solver.DampingModel`` registered in
``ldem.solver.dampingRegistry``.

Your own test: supports and loads
---------------------------------

With ``type = "custom"`` the test is described in the case file by
``[[support]]`` and ``[[load]]`` blocks, without writing a class. This is the
uniaxial test (``testId = 101``) as blocks:

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

**Nodes** are chosen with ``nodes`` (``all``, ``grid`` for the corners of the
modules or ``centre`` for their centres), ``ids`` (node numbers) and ``x``,
``y``, ``z``. A position is in modules (centre nodes lie at half-integers, grid
nodes at integers), a range ``[lo, hi]``, or a text with the references
``min``, ``max`` and ``mid`` and an offset, such as ``"max - 0.5"``. A node must
satisfy every condition. The positions refer to the regular lattice, so they do
not change when ``mesh.perturbation`` moves the nodes.

**Supports** hold the directions listed in ``fix``. **Loads** act on one
``direction`` as a ``force`` (newtons on each selected node) or as a prescribed
``displacement`` (metres from the initial position, and the solver holds that
direction). The value follows ``time_function``: ``constant`` (``value``),
``linear`` (``rate``), ``ramp`` (``rate`` until the time ``until``, then
constant) or ``table`` (``times`` and ``values`` in SI units, linear between
points and constant outside).

A block with ``reaction = true`` adds its force to the reaction of the test
(the sum of the bar forces on its held directions); with none, the reaction is
NaN. A block that selects no node is an error that names it. The three built-in
tests written this way give exactly the same results as their classes.

Reuse a case: extends
---------------------

A case file can start from another one and change only what differs:

.. code-block:: text

   extends = "base.ldem"              # or a list: ["base.ldem", "material.ldem"]

   [material]
   fracture_energy = 1 N/m            # only what changes

The keys of the file replace the inherited ones. A repeated table (``[[support]]``,
``[[load]]``, ``[[monitor.node]]``, ``[[sweep]]``) replaces the whole inherited
list. When the ``type`` of the scenario, of ``[material.scatter]`` or of
``[damping]`` changes, the keys of the old type that are not set again are
dropped. With a list, later files win. Relative paths (the random-field file, the
output folder) are relative to the file that contains them, and an error names the
file and line where the problem is written. ``results.info.case.parents`` keeps
the hash of every inherited file.

Parameter sweeps
----------------

To study how the result depends on a value, list the values in ``[[sweep]]``
blocks and run ``ldem.sweep``:

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

Several blocks give every combination; ``sweep_mode = "zip"`` (a key at the top of
the file) takes them one by one. Any key with a single value can be varied, and
the keys of the scenario as ``scenario.<key>``. Values are numbers or texts with
units. Every run is validated before the first one starts. The runs go to
``run_001``, ``run_002``, ... (each with its resolved ``case.ldem``) and the
table ``sweep_summary.csv`` lists them, with the number of damaged and broken
bars; a run that fails is recorded and the sweep goes on.

Reference of every key
----------------------

The tables below are generated from ``ldem.schema.caseSchema``, the same table
that the reader uses, so they always agree with it.

.. include:: case-keys.inc

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

To add a new test, create a subclass of ``ldem.scenarios.Scenario`` (see :doc:`model`).

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
