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
.. mat:autofunction:: ldem.run
.. mat:autofunction:: ldem.check
.. mat:autofunction:: ldem.sweep
.. mat:autofunction:: ldem.version

Input and output / Entrada y salida
-----------------------------------

.. mat:module:: ldem.io

.. mat:autofunction:: ldem.io.readCase
.. mat:autofunction:: ldem.io.writeCase
.. mat:autofunction:: ldem.io.writeTemplate
.. mat:autofunction:: ldem.io.convertLegacyInput
.. mat:autofunction:: ldem.io.parseCaseText
.. mat:autofunction:: ldem.io.parseCaseJson
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
.. mat:autoclass:: ldem.material.MaterialLaw
.. mat:autoclass:: ldem.material.BilinearBarLaw
.. mat:autoclass:: ldem.material.LinearElasticBarLaw
.. mat:autofunction:: ldem.material.lawRegistry
.. mat:autofunction:: ldem.material.lawFromName
.. mat:autofunction:: ldem.material.summarizeMaterial

Scenarios / Escenarios de ensayo
--------------------------------

.. mat:module:: ldem.scenarios

.. mat:autoclass:: ldem.scenarios.Scenario
.. mat:autoclass:: ldem.scenarios.UniaxialTension
.. mat:autoclass:: ldem.scenarios.FourPointBending
.. mat:autoclass:: ldem.scenarios.ClampedBeam
.. mat:autofunction:: ldem.scenarios.fromTestId
.. mat:autofunction:: ldem.scenarios.fromName
.. mat:autoclass:: ldem.scenarios.Declarative
.. mat:autofunction:: ldem.scenarios.selectNodes
.. mat:autofunction:: ldem.scenarios.parseCoordinate
.. mat:autofunction:: ldem.scenarios.coordinateText
.. mat:autofunction:: ldem.scenarios.timeFunction
.. mat:autofunction:: ldem.scenarios.registry

Case-file schema / Esquema de los archivos de caso
--------------------------------------------------

.. mat:module:: ldem.schema

.. mat:autofunction:: ldem.schema.caseSchema
.. mat:autofunction:: ldem.schema.parseQuantity
.. mat:autofunction:: ldem.schema.formatQuantity
.. mat:autofunction:: ldem.schema.unitTable
.. mat:autofunction:: ldem.schema.shortestText
.. mat:autofunction:: ldem.schema.suggest
.. mat:autofunction:: ldem.schema.raise
.. mat:autofunction:: ldem.schema.writeKeyReference

Solver
------

.. mat:module:: ldem.solver

.. mat:autofunction:: ldem.solver.simulate
.. mat:autofunction:: ldem.solver.initialState
.. mat:autoclass:: ldem.solver.DampingModel
.. mat:autoclass:: ldem.solver.MassProportionalDamping
.. mat:autoclass:: ldem.solver.NoDamping
.. mat:autofunction:: ldem.solver.dampingRegistry
.. mat:autofunction:: ldem.solver.dampingFromName
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
