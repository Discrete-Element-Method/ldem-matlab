Construir esta documentación
============================

La documentación está escrita en inglés y traducida al español, portugués e
italiano; las cuatro versiones forman un solo sitio y la barra lateral permite
cambiar de idioma. La referencia de la API se genera desde los comentarios de
los ``.m``.

Requisitos
----------

* Python 3.9 o superior.
* ``git`` (la lista de autores se genera desde el historial de commits; con un
  clon superficial ejecutar antes ``git fetch --unshallow``).
* No se necesita MATLAB; la API se lee del texto de las fuentes.

.. code-block:: bash

   pip install -r docs/requirements.txt

Construcción
------------

Desde la raíz del repositorio, con cualquiera de estas opciones:

.. code-block:: bash

   sphinx-build -W --keep-going -b html docs/source docs/build/html

.. code-block:: bash

   cd docs && make html

.. code-block:: matlab

   >> buildtool docs

Abrir ``docs/build/html/index.html`` en un navegador. ``-W`` convierte las
advertencias en errores: la documentación debe construirse sin ninguna.
``buildtool clean`` borra el resultado.

Dónde está cada cosa
--------------------

``docs/source/en/``
   El texto de referencia, en inglés.
``docs/source/es/``, ``pt/``, ``it/``
   Traducciones. Cada página tiene el mismo nombre de archivo que en ``en/``
   para que la lista de idiomas de la barra lateral enlace a la misma página.
``docs/source/api/``
   Referencia de la API, generada desde los comentarios de los ``.m``.
``docs/tools/generate_authors.py``
   Escribe la página de autores y ``AUTHORS.md`` (lo ejecuta la construcción).

Escribir o cambiar una página
-----------------------------

1. Editar la página en inglés en ``docs/source/en/``.
2. Aplicar el mismo cambio a las traducciones. Una página nueva necesita un
   archivo con el mismo nombre en cada idioma y una entrada en cada
   ``index.rst``.
3. Construir con ``-W`` y corregir cualquier advertencia.

Publicación
-----------

El workflow ``.github/workflows/docs.yml`` construye la documentación en cada
pull request y la publica en GitHub Pages cuando cambia ``main``.
