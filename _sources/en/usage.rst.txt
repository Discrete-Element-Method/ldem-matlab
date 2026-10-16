Usage
=====

.. code-block:: matlab

   >> setup_path
   >> main        % default simulation

Input data files (``DATA0.DAT``, ``SIM01.DAT``) are read by ``read_dat0``.
Results are written to ``LET.*`` and ``*.TXT`` files in the working
directory.

Run the tests:

.. code-block:: matlab

   >> addpath tests
   >> run_tests
