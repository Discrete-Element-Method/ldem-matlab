Introdução
==========

O **Método dos Elementos Discretos tipo Treliça (LDEM)** modela um contínuo
como um reticulado regular de nós ligados por barras dispostas em módulos
cúbicos (arestas mais diagonais). As massas são concentradas nos nós, as leis
constitutivas das barras incluem dano/fratura e as equações de movimento são
integradas com um esquema explícito de diferenças centrais. As energias
(externa, cinética, elástica, dissipada) são acompanhadas a cada passo.

Principais partes do pacote ``ldem`` (ver :doc:`../api/index`):

* ``ldem.Parameters`` / ``ldem.io.readInputFile`` – dados de entrada validados.
* ``ldem.mesh`` – nós, barras, massas e geometria das barras.
* ``ldem.material`` – rigidez das barras, deformação crítica e lei bilinear de dano.
* ``ldem.scenarios`` – apoios, cargas e reações de cada ensaio.
* ``ldem.solver`` – integração no tempo e balanço de energia.
* ``ldem.runSimulation`` – a simulação completa, com saída ``results.mat``,
  ANSYS e VTK.

As rotinas do programa original (``ini_DEM3``, ``read_dat0``, ``RMEC``,
``BOUND``, ``CALOAD``, ``ENERG2``, ...) são mantidas no histórico do git, com
a tag ``legacy-reference``; a linha ``Legacy:`` de cada ajuda indica a rotina
que ela substitui.
