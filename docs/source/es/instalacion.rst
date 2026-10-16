Instalación
===========

Requisitos: MATLAB R2021b o superior.

.. code-block:: bash

   git clone <url-del-repositorio> ldem-matlab
   cd ldem-matlab

.. code-block:: matlab

   >> setup_path

Para construir esta documentación:

.. code-block:: bash

   pip install -r docs/requirements.txt
   sphinx-build -b html docs/source docs/build/html
