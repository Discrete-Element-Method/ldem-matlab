API reference / Referencia de la API
====================================

Generated automatically from the comments of the ``.m`` files /
Generada automáticamente desde los comentarios de los ``.m``.

The ``ldem`` package (``src/+ldem``) is the refactored code. It replaces the
original routines, which are kept in the git history (tag
``legacy-reference``); the problems found in them are listed in
``docs/known-issues/KNOWN_ISSUES.md`` / El paquete ``ldem`` (``src/+ldem``) es
el código refactorizado. Reemplaza a las rutinas originales, que se conservan
en el historial de git (etiqueta ``legacy-reference``).

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
.. mat:autofunction:: ldem.mesh.summarizeModel

Material
--------

.. mat:module:: ldem.material

.. mat:autofunction:: ldem.material.latticeCoefficients
.. mat:autofunction:: ldem.material.computeBarStiffness
.. mat:autofunction:: ldem.material.buildBarProperties
.. mat:autofunction:: ldem.material.generateRandomField
.. mat:autofunction:: ldem.material.bilinearLaw
.. mat:autofunction:: ldem.material.summarizeMaterial

Scenarios / Escenarios de ensayo
--------------------------------

.. mat:module:: ldem.scenarios

.. mat:autoclass:: ldem.scenarios.Scenario
.. mat:autoclass:: ldem.scenarios.UniaxialTension
.. mat:autoclass:: ldem.scenarios.FourPointBending
.. mat:autoclass:: ldem.scenarios.ClampedBeam
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
.. mat:autofunction:: ldem.solver.nodalKineticEnergy
.. mat:autofunction:: ldem.solver.checkStability

Post-processing / Postproceso
-----------------------------

.. mat:module:: ldem.post

.. mat:autofunction:: ldem.post.plotEnergy
.. mat:autofunction:: ldem.post.plotReaction
