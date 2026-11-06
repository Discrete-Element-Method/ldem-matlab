Installazione
=============

Requisiti: MATLAB R2022b o successivo (sviluppato e testato su R2023b). Il
pacchetto usa il blocco ``arguments`` e la sintassi nome=valore; la suite di
test e ``buildtool`` richiedono R2022b. Non serve alcun toolbox.

.. code-block:: bash

   git clone <url-del-repository> ldem-matlab
   cd ldem-matlab

.. code-block:: matlab

   >> setup_path

Verificare l'installazione con i test rapidi:

.. code-block:: matlab

   >> buildtool test

Attività per sviluppatori (``buildtool`` si esegue dalla radice del
repository):

.. code-block:: matlab

   >> buildtool             % analisi statica + test rapidi (predefinito)
   >> buildtool check       % solo l'analizzatore di codice
   >> buildtool testAll     % tutti i test, compresi quelli lenti
   >> buildtool docs        % costruire questa documentazione (richiede Python)
   >> buildtool clean       % eliminare i file generati

``buildtool test`` scrive ``test-results/results.xml`` (JUnit) e
``code-coverage/coverage.xml`` (Cobertura).

Per costruire questa documentazione senza MATLAB vedi :doc:`docs`.
