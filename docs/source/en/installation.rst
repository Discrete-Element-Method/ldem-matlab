Installation
============

Requirements: MATLAB R2021b or newer.

.. code-block:: bash

   git clone <repository-url> ldem-matlab
   cd ldem-matlab

.. code-block:: matlab

   >> setup_path

To build this documentation:

.. code-block:: bash

   pip install -r docs/requirements.txt
   sphinx-build -b html docs/source docs/build/html
