Installation
============

Requirements: MATLAB R2022b or newer (developed and tested on R2023b). The
package itself uses the ``arguments`` block and name=value syntax; the test
suite and ``buildtool`` need R2022b. No toolbox is required.

.. code-block:: bash

   git clone <repository-url> ldem-matlab
   cd ldem-matlab

.. code-block:: matlab

   >> setup_path

Check the installation with the fast tests:

.. code-block:: matlab

   >> buildtool test

Developer tasks (``buildtool`` is run from the repository root):

.. code-block:: matlab

   >> buildtool             % static analysis + fast tests (the default)
   >> buildtool check       % Code Analyzer only
   >> buildtool testAll     % all tests, including the slow ones
   >> buildtool docs        % build this documentation (needs Python)
   >> buildtool clean       % delete generated files

``buildtool test`` writes ``test-results/results.xml`` (JUnit) and
``code-coverage/coverage.xml`` (Cobertura).

To build this documentation without MATLAB:

.. code-block:: bash

   pip install -r docs/requirements.txt
   sphinx-build -b html docs/source docs/build/html
