Uso
===

.. code-block:: matlab

   >> setup_path
   >> main        % simulación por defecto

Los archivos de entrada (``DATA0.DAT``, ``SIM01.DAT``) son leídos por
``read_dat0``. Los resultados se escriben en archivos ``LET.*`` y ``*.TXT``
en el directorio de trabajo.

Ejecutar los tests:

.. code-block:: matlab

   >> addpath tests
   >> run_tests
