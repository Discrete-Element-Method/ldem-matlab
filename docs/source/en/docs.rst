Building this documentation
===========================

The documentation is written in English and translated into Spanish,
Portuguese and Italian; the four versions are in one site and the sidebar
lets the reader switch language. The API reference is generated from the
comments of the ``.m`` files.

Requirements
------------

* Python 3.9 or newer.
* ``git`` (the list of authors is generated from the commit history; with a
  shallow clone use ``git fetch --unshallow`` first).
* No MATLAB is needed; the API is read from the source text.

.. code-block:: bash

   pip install -r docs/requirements.txt

Build
-----

From the repository root, with any of these:

.. code-block:: bash

   sphinx-build -W --keep-going -b html docs/source docs/build/html

.. code-block:: bash

   cd docs && make html

.. code-block:: matlab

   >> buildtool docs

Open ``docs/build/html/index.html`` in a browser. ``-W`` turns warnings into
errors: the documentation must build without any. ``buildtool clean`` deletes
the result.

Where things are
----------------

``docs/source/en/``
   The reference text, in English.
``docs/source/es/``, ``pt/``, ``it/``
   Translations. Each page has the same file name as in ``en/`` so that the
   language list in the sidebar links to the same page.
``docs/source/api/``
   API reference, generated from the ``.m`` comments.
``docs/tools/generate_authors.py``
   Writes the authors page and ``AUTHORS.md`` (run by the build).

Write or change a page
----------------------

1. Edit the English page in ``docs/source/en/``.
2. Apply the same change to the translations. A new page needs a file with
   the same name in each language and an entry in each ``index.rst``.
3. Build with ``-W`` and fix any warning.

Publishing
----------

The workflow ``.github/workflows/docs.yml`` builds the documentation on every
pull request and publishes it to GitHub Pages when ``main`` changes.
