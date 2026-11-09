Building this documentation
===========================

The documentation is written in English, which is the only set of source pages,
and translated into Spanish, Portuguese and Italian with gettext catalogs
(``.po`` files in ``docs/locale/``). Each language is built as its own site and
the sidebar has a language selector. A text that is not translated yet is shown
in English. The API reference is generated from the comments of the ``.m``
files and is in English only.

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

   python docs/tools/build_docs.py

.. code-block:: bash

   cd docs && make html

.. code-block:: matlab

   >> buildtool docs

This builds the four languages into ``docs/build/html/en``, ``es``, ``pt`` and
``it``; ``docs/build/html/index.html`` sends the reader to the English site. Open
it in a browser. To build only some languages use for example
``python docs/tools/build_docs.py --languages en es``. Warnings are errors: the
documentation must build without any. ``buildtool clean`` deletes the result.

Where things are
----------------

``docs/source/``
   The pages, in English.
``docs/locale/es/``, ``pt/``, ``it/``
   Translations: one ``.po`` file per page in ``LC_MESSAGES/``, with each English
   text and its translation.
``docs/source/api/``
   API reference, generated from the ``.m`` comments.
``docs/tools/build_docs.py``
   Builds every language and the page that sends the reader to the English site.
``docs/tools/update_translations.py``
   Updates the ``.po`` files after the English text changes, and reports what is
   left to translate.
``docs/tools/generate_authors.py``
   Writes the authors page and ``AUTHORS.md`` (run by the build).
``docs/source/case-keys.inc``
   Reference of the case-file keys, generated from the schema. After changing
   ``ldem.schema.caseSchema`` regenerate it from MATLAB with
   ``ldem.schema.writeKeyReference("docs/source/case-keys.inc")``; a test fails
   if it is out of date.

Write or change a page
----------------------

1. Edit the English page in ``docs/source/``. A new page also goes in the list of
   ``index.rst``.
2. Run ``python docs/tools/update_translations.py``. It extracts the texts and
   updates the ``.po`` files: new texts appear untranslated and changed texts are
   marked as fuzzy, both shown in English until they are translated.
3. Translate the new entries in ``docs/locale/<language>/LC_MESSAGES/<page>.po``
   (with any text editor or a tool such as Poedit) and remove the fuzzy marks you
   have reviewed. ``python docs/tools/update_translations.py --status`` shows how
   much is left in each language.
4. Build with ``python docs/tools/build_docs.py`` and fix any warning.

Publishing
----------

The workflow ``.github/workflows/docs.yml`` builds the documentation on every
pull request and publishes the four languages to GitHub Pages when ``main``
changes.
