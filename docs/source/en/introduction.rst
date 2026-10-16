Introduction
============

The **Lattice Discrete Element Method (LDEM)** models a continuum as a
regular lattice of nodes connected by bars arranged in cubic modules
(edges plus diagonals). Nodal masses are lumped, bar constitutive laws
include damage/fracture, and the equations of motion are integrated with an
explicit central-difference scheme. Energies (external, kinetic, elastic,
dissipated) are tracked at every step.

Main routines (see :doc:`../api/index`):

* ``ini_DEM3`` – initialises the global variables.
* ``read_dat0`` – reads the input data file.
* ``CONECTI`` / ``INTCO1`` / ``EXTCO1`` – bar connectivity.
* ``RMEC`` – mechanical properties of the bars.
* ``BOUND`` / ``CALOAD`` – boundary conditions and loads.
* ``ENERG2`` – energy balance.
