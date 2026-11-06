Introduction
============

The **Lattice Discrete Element Method (LDEM)** models a continuum as a
regular lattice of nodes connected by bars arranged in cubic modules
(edges plus diagonals). Nodal masses are lumped, bar constitutive laws
include damage/fracture, and the equations of motion are integrated with an
explicit central-difference scheme. Energies (external, kinetic, elastic,
dissipated) are tracked at every step.

Main parts of the ``ldem`` package (see :doc:`../api/index`):

* ``ldem.Parameters`` / ``ldem.io.readInputFile`` – validated input data.
* ``ldem.mesh`` – nodes, bars, masses and bar geometry.
* ``ldem.material`` – bar stiffness, critical strain and the bilinear damage law.
* ``ldem.scenarios`` – supports, loads and reactions of each test.
* ``ldem.solver`` – time integration and energy balance.
* ``ldem.runSimulation`` – the whole simulation, with ``results.mat``, ANSYS and
  VTK output.

The routines of the original program (``ini_DEM3``, ``read_dat0``, ``RMEC``,
``BOUND``, ``CALOAD``, ``ENERG2``, ...) are kept in the git history under the tag
``legacy-reference``; the ``Legacy:`` line of each help text names the routine it
replaces.
