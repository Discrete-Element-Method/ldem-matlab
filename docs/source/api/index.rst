API reference / Referencia de la API
====================================

Generated automatically from the comments of the ``.m`` files /
Generada automáticamente desde los comentarios de los ``.m``.

Refactored package ``ldem`` / Paquete refactorizado ``ldem``
------------------------------------------------------------

New code in ``src/+ldem`` (English comments). It replaces the routines of
``legacy/`` step by step; see ``legacy/KNOWN_ISSUES.md``.

.. mat:module:: ldem

Parameters / Parámetros
~~~~~~~~~~~~~~~~~~~~~~~

.. mat:autoclass:: ldem.Parameters
   :members:

.. mat:module:: ldem.io

.. mat:autofunction:: ldem.io.readInputFile
.. mat:autofunction:: ldem.io.readRandomField

Mesh / Malla
~~~~~~~~~~~~

.. mat:module:: ldem.mesh

.. mat:autofunction:: ldem.mesh.buildMesh
.. mat:autofunction:: ldem.mesh.buildNodes
.. mat:autofunction:: ldem.mesh.perturbNodes
.. mat:autofunction:: ldem.mesh.buildBars
.. mat:autofunction:: ldem.mesh.computeNodalMasses
.. mat:autofunction:: ldem.mesh.computeBarGeometry

Material / Material
~~~~~~~~~~~~~~~~~~~

.. mat:module:: ldem.material

.. mat:autofunction:: ldem.material.latticeCoefficients
.. mat:autofunction:: ldem.material.computeBarStiffness
.. mat:autofunction:: ldem.material.buildBarProperties
.. mat:autofunction:: ldem.material.bilinearLaw

Scenarios / Escenarios de ensayo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. mat:module:: ldem.scenarios

.. mat:autoclass:: ldem.scenarios.Scenario
.. mat:autoclass:: ldem.scenarios.UniaxialTension
.. mat:autoclass:: ldem.scenarios.FourPointBending
.. mat:autofunction:: ldem.scenarios.fromTestId

Solver
~~~~~~

.. mat:module:: ldem.solver

.. mat:autofunction:: ldem.solver.checkStability

Legacy routines / Rutinas originales
------------------------------------

The original routines live in ``legacy/`` as a frozen reference and are not
part of the generated API. Their known problems are listed in
``legacy/KNOWN_ISSUES.md`` / Las rutinas originales están en ``legacy/`` como
referencia congelada y no forman parte de la API generada.
