Uso
===

Executar uma simulação
----------------------

.. code-block:: matlab

   >> setup_path                        % adiciona src/ ao path do MATLAB
   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], totalTime=2e-4, ...
          fractureEnergy=0.1, ...
          output=struct('snapshotEvery', 250, 'controlNodesEvery', 10, ...
                        'energyEvery', 10, 'trackedBarEvery', 0));
   >> results = ldem.runSimulation(params, OutputFolder="output", ...
          Formats=["mat" "ansys" "vtk"]);
   >> ldem.post.plotEnergy(results);

``ldem.Parameters`` valida cada valor ao atribuí-lo e explica o que está
errado (por exemplo, um passo de tempo instável). A versão completa e pronta
para executar está em ``examples/tension_101/runTension.m``.

Para usar um arquivo de entrada no formato do programa original:

.. code-block:: matlab

   >> params = ldem.Parameters.fromFile("DATA0.DAT");

Ensaios disponíveis
-------------------

``testId = 101``
   Carga uniaxial: os nós centrais da última coluna de módulos se movem em
   :math:`x` com velocidade imposta.
``testId = 102``
   Viga com dois apoios e dois pontos de carga. As posições são parâmetros de
   ``ldem.scenarios.FourPointBending`` (``supportPosition``, ``loadPosition``,
   em módulos a partir de cada extremidade); os valores padrão exigem uma viga
   com mais de uns 70 módulos. Ver ``examples/beam_102``.
``testId = 103``
   Viga engastada nas duas extremidades, carregada no meio do vão com uma
   força que cresce linearmente e depois se mantém constante
   (``ldem.scenarios.ClampedBeam``). É o único ensaio carregado com força em
   vez de deslocamento. Ver ``examples/example1_clamped_beam``.

Para adicionar um ensaio novo, crie uma subclasse de
``ldem.scenarios.Scenario`` (ver :doc:`model`).

Perturbação da malha
--------------------

O parâmetro ``meshPerturbation`` desloca aleatoriamente os nós interiores. Seu
valor é o desvio padrão como fração do comprimento do módulo: ``0`` (o padrão)
mantém o reticulado regular e qualquer valor positivo ativa a perturbação com
esse valor. Os números aleatórios seguem ``seed``.

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, nModules=[6 3 3], meshPerturbation=0.02);

O que se obtém: a estrutura ``results``
---------------------------------------

.. list-table::
   :header-rows: 1
   :widths: 22 78

   * - Campo
     - Conteúdo
   * - ``info``
     - Versão do ldem, data, versão do MATLAB, tempo de execução [s].
   * - ``params``
     - Os parâmetros usados, como estrutura simples (com valores derivados).
   * - ``model``
     - Contagens e massa do modelo: módulos, nós, barras por tipo, graus de
       liberdade fixos, massa total e volume.
   * - ``material``
     - Dados do material (E, Gf, ...), coeficientes do reticulado, comprimento
       crítico e estatísticas da deformação crítica (média, coeficiente de
       variação, mínimo e máximo).
   * - ``mesh``
     - Posições iniciais dos nós, apoios (``fixed``), massas, barras,
       comprimentos e tipos de barra.
   * - ``barProps``
     - Rigidez, deformação crítica e deformação de ruptura de cada barra.
   * - ``controlNodes``
     - Tempo e deslocamento, velocidade e aceleração dos nós de controle.
   * - ``reactions``
     - Tempo e força de reação ``[Rx Ry Rz]`` do ensaio: força vertical nos
       pontos de carga (ensaio 102), força nas extremidades engastadas
       (ensaio 103); ``NaN`` onde o ensaio não a define.
   * - ``energy``
     - Tempo, energias cinética, elástica, de dano e de amortecimento [J], sua
       soma (``internal``), a energia das barras rompidas (``brokenBars``), o
       trabalho externo, o balanço (``balance``, externo menos interno) e a
       taxa de dano.
   * - ``trackedBar``
     - Deformação, força e energia de dano de uma barra a cada passo
       (opcional).
   * - ``snapshots``
     - Passo, tempo, número de barras intactas/danificadas/rompidas e cópias
       compactas dos deslocamentos, do estado de dano e da energia cinética
       nodal nos passos salvos.
   * - ``final``
     - Deslocamento, velocidade, força e estado de dano finais, e a energia
       cinética de cada nó.

O ``balance`` de energia é uma verificação da simulação: deve ser uma fração
pequena (menos de 1 %) do trabalho externo final. A energia cinética total é
``energy.kinetic``; a de cada nó está em ``final.kineticEnergy``.

``results.mat`` contém esta estrutura e carrega-se sem o pacote:

.. code-block:: matlab

   >> data = load("output/results.mat");
   >> results = data.results;

Arquivos de saída
-----------------

``results.mat``
   A estrutura ``results`` (formato v7.3, legível em Python com ``h5py``).
``snapshot_0000.mac``, ``snapshot_0001.mac``, ...
   Macros do ANSYS com o reticulado deformado. As barras são elementos do tipo
   1 (intactas), 2 (danificadas) e 5 (rompidas). Os graus de liberdade fixos
   são listados como ``D,nó,direção`` e o deslocamento imposto aos nós
   carregados, medido a partir da posição inicial, como
   ``D,nó,direção,valor``. No ensaio 103 as forças aplicadas são listadas como
   ``F,nó,direção,valor``.
``snapshot_0000.vtu``, ... e ``snapshots.pvd``
   Arquivos VTK. Abra ``snapshots.pvd`` no `ParaView <https://www.paraview.org>`_;
   colora por ``damageState`` (dados de célula) para ver as fissuras e use o
   controle de tempo para acompanhá-las. Deslocamento e velocidade são dados
   de ponto.

Os arquivos ANSYS e VTK são escritos no tempo zero e a cada
``params.output.snapshotEvery`` passos.

Executar os testes
------------------

.. code-block:: matlab

   >> addpath tests
   >> run_tests                          % testes rápidos
   >> run_tests(IncludeSlow=true)        % também os testes lentos
