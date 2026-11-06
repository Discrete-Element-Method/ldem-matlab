Introduzione
============

Il **Metodo degli Elementi Discreti a Reticolo (LDEM)** modella un continuo
come un reticolo regolare di nodi collegati da barre disposte in moduli cubici
(spigoli più diagonali). Le masse sono concentrate nei nodi, le leggi
costitutive delle barre includono danno/frattura e le equazioni del moto sono
integrate con uno schema esplicito alle differenze centrali. Le energie
(esterna, cinetica, elastica, dissipata) sono monitorate a ogni passo.

Parti principali del pacchetto ``ldem`` (vedi :doc:`../api/index`):

* ``ldem.Parameters`` / ``ldem.io.readInputFile`` – dati di ingresso validati.
* ``ldem.mesh`` – nodi, barre, masse e geometria delle barre.
* ``ldem.material`` – rigidezza delle barre, deformazione critica e legge bilineare di danno.
* ``ldem.scenarios`` – vincoli, carichi e reazioni di ogni prova.
* ``ldem.solver`` – integrazione nel tempo e bilancio energetico.
* ``ldem.runSimulation`` – la simulazione completa, con uscita ``results.mat``,
  ANSYS e VTK.

Le routine del programma originale (``ini_DEM3``, ``read_dat0``, ``RMEC``,
``BOUND``, ``CALOAD``, ``ENERG2``, ...) sono conservate nella cronologia di
git, con il tag ``legacy-reference``; la riga ``Legacy:`` di ogni guida indica
la routine che sostituisce.
