API reference / Referencia de la API
====================================

Generated automatically from the comments of the ``.m`` files /
Generada automáticamente desde los comentarios de los ``.m``.

The ``ldem`` package (``src/+ldem``) is the refactored code. It replaces the
routines of ``legacy/`` step by step; the original routines are kept as a
frozen reference and are not part of this API (their known problems are in
``legacy/KNOWN_ISSUES.md``) / El paquete ``ldem`` (``src/+ldem``) es el código
refactorizado. Las rutinas originales de ``legacy/`` se conservan como
referencia congelada y no forman parte de esta API.

Running a simulation / Ejecutar una simulación
----------------------------------------------

.. mat:module:: ldem

.. mat:autofunction:: ldem.runSimulation
.. mat:autoclass:: ldem.Parameters
   :members:
.. mat:autofunction:: ldem.version

Input and output / Entrada y salida
-----------------------------------

.. mat:module:: ldem.io

.. mat:autofunction:: ldem.io.readInputFile
.. mat:autofunction:: ldem.io.readRandomField
.. mat:autofunction:: ldem.io.saveResults
.. mat:autofunction:: ldem.io.exportAnsys
.. mat:autofunction:: ldem.io.exportVtk
.. mat:autofunction:: ldem.io.writePvd
.. mat:autoclass:: ldem.io.SnapshotWriter
   :members:

Mesh / Malla
------------

.. mat:module:: ldem.mesh

.. mat:autofunction:: ldem.mesh.buildMesh
.. mat:autofunction:: ldem.mesh.buildNodes
.. mat:autofunction:: ldem.mesh.perturbNodes
.. mat:autofunction:: ldem.mesh.buildBars
.. mat:autofunction:: ldem.mesh.computeNodalMasses
.. mat:autofunction:: ldem.mesh.computeBarGeometry

Material
--------

.. mat:module:: ldem.material

.. mat:autofunction:: ldem.material.latticeCoefficients
.. mat:autofunction:: ldem.material.computeBarStiffness
.. mat:autofunction:: ldem.material.buildBarProperties
.. mat:autofunction:: ldem.material.bilinearLaw

Scenarios / Escenarios de ensayo
--------------------------------

.. mat:module:: ldem.scenarios

.. mat:autoclass:: ldem.scenarios.Scenario
.. mat:autoclass:: ldem.scenarios.UniaxialTension
.. mat:autoclass:: ldem.scenarios.FourPointBending
.. mat:autofunction:: ldem.scenarios.fromTestId

Solver
------

.. mat:module:: ldem.solver

.. mat:autofunction:: ldem.solver.simulate
.. mat:autofunction:: ldem.solver.initialState
.. mat:autofunction:: ldem.solver.computeBarForces
.. mat:autofunction:: ldem.solver.integrateStep
.. mat:autofunction:: ldem.solver.dampingCoefficient
.. mat:autofunction:: ldem.solver.computeEnergies
.. mat:autofunction:: ldem.solver.checkStability

Post-processing / Postproceso
-----------------------------

.. mat:module:: ldem.post

.. mat:autofunction:: ldem.post.plotEnergy
.. mat:autofunction:: ldem.post.plotReaction
