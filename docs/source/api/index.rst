API reference / Referencia de la API
====================================

Generated automatically from the comments of the ``.m`` files in
``src/ldem`` (comments are written in Portuguese) /
Generada automáticamente desde los comentarios de los ``.m``.

.. note::

   Only routines that already have a docstring (comment block right below
   the ``function`` line) are listed. To add another routine, document it
   and append it to this list / Para añadir otra rutina, documentarla y
   agregarla a esta lista.

.. mat:module:: ldem

Initialisation / Inicialización
-------------------------------

.. mat:autofunction:: ldem.ini_DEM3
.. mat:autofunction:: ldem.read_dat0
.. mat:autofunction:: ldem.prepvar

Geometry and connectivity / Geometría y conectividad
----------------------------------------------------

.. mat:autofunction:: ldem.CONECTI
.. mat:autofunction:: ldem.INTCO1

Mechanics, loads and boundary conditions / Mecánica, cargas y contorno
----------------------------------------------------------------------

.. mat:autofunction:: ldem.RMEC
.. mat:autofunction:: ldem.BOUND
.. mat:autofunction:: ldem.CALOAD

Results and energy / Resultados y energía
-----------------------------------------

.. mat:autofunction:: ldem.CALRES
.. mat:autofunction:: ldem.ENERG2
