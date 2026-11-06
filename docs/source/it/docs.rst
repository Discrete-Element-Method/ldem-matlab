Costruire questa documentazione
===============================

La documentazione è scritta in inglese e tradotta in spagnolo, portoghese e
italiano; le quattro versioni formano un unico sito e la barra laterale
permette di cambiare lingua. Il riferimento dell'API è generato dai commenti
dei ``.m``.

Requisiti
---------

* Python 3.9 o successivo.
* ``git`` (l'elenco degli autori è generato dalla cronologia dei commit; con
  un clone superficiale eseguire prima ``git fetch --unshallow``).
* MATLAB non è necessario; l'API viene letta dal testo dei sorgenti.

.. code-block:: bash

   pip install -r docs/requirements.txt

Costruzione
-----------

Dalla radice del repository, con una qualsiasi di queste opzioni:

.. code-block:: bash

   sphinx-build -W --keep-going -b html docs/source docs/build/html

.. code-block:: bash

   cd docs && make html

.. code-block:: matlab

   >> buildtool docs

Aprire ``docs/build/html/index.html`` in un browser. ``-W`` trasforma gli
avvisi in errori: la documentazione deve essere costruita senza alcun avviso.
``buildtool clean`` elimina il risultato.

Dove si trova ogni cosa
-----------------------

``docs/source/en/``
   Il testo di riferimento, in inglese.
``docs/source/es/``, ``pt/``, ``it/``
   Traduzioni. Ogni pagina ha lo stesso nome di file che in ``en/``, così
   l'elenco delle lingue nella barra laterale porta alla stessa pagina.
``docs/source/api/``
   Riferimento dell'API, generato dai commenti dei ``.m``.
``docs/tools/generate_authors.py``
   Scrive la pagina degli autori e ``AUTHORS.md`` (eseguito dalla costruzione).

Scrivere o modificare una pagina
--------------------------------

1. Modificare la pagina in inglese in ``docs/source/en/``.
2. Applicare la stessa modifica alle traduzioni. Una pagina nuova richiede un
   file con lo stesso nome in ogni lingua e una voce in ogni ``index.rst``.
3. Costruire con ``-W`` e correggere ogni avviso.

Pubblicazione
-------------

Il workflow ``.github/workflows/docs.yml`` costruisce la documentazione a ogni
pull request e la pubblica su GitHub Pages quando cambia ``main``.
