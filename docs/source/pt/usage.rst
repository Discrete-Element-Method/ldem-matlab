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

Arquivos de caso (``.ldem``)
----------------------------

Um *arquivo de caso* descreve todo o modelo em um único texto legível: chaves
com nome em vez de posições, unidades junto aos números, comentários, e o
ensaio, a dispersão aleatória e os arquivos de saída juntos. Ele substitui o
``DATA0.DAT``.

.. code-block:: text

   format = 1
   title  = "Pequeno ensaio de tração"

   [mesh]
   module_size = 3 mm
   modules     = [5, 2, 2]        # módulos cúbicos em x, y e z

   [material]
   young_modulus = 32 GPa
   density       = 2000 kg/m3

   [time]
   step     = auto                # 0.9 vezes o passo crítico
   duration = 40 us

   [scenario]
   type = "uniaxial_tension"

   [output]
   folder = "output"

.. code-block:: matlab

   >> ldem.io.writeTemplate("meu_ensaio.ldem", "clamped_beam");  % arquivo comentado para editar
   >> ldem.check("meu_ensaio.ldem")                              % valida e informa, sem simular
   >> results = ldem.run("meu_ensaio.ldem");                     % executa
   >> ldem.io.convertLegacyInput("DATA0.DAT", "caso.ldem");      % converte um arquivo antigo

Regras do formato:

* As chaves são lidas por **nome**; a ordem das linhas não importa. As chaves
  ausentes assumem o valor padrão de ``ldem.Parameters``. Só são obrigatórias
  ``scenario.type``, ``mesh.modules`` e ``time.duration``.
* Um número pode ter **unidade**: ``3.87 GPa``, ``0.35 us``, ``1500 kg/m3``,
  ``2 kN/s``. Sem unidade o valor está em SI. Uma unidade incorreta para a
  chave é um erro que lista as válidas.
* ``#`` inicia um comentário, ``[seção]`` abre uma tabela, ``[[monitor.node]]``
  inicia o próximo elemento de uma tabela repetida e as listas são escritas
  ``[5, 5, 50]``.
* ``mesh.modules`` conta **módulos**: os ``M N L`` do ``DATA0.DAT`` contam nós,
  um a mais.
* ``time.step = auto`` (ou sem ``step``) assume 0.9 vez o passo crítico.
* Cada erro indica o arquivo, a linha, a seção e a chave, e sugere o nome
  válido mais parecido quando há erro de digitação.
* Os caminhos relativos (arquivo do campo aleatório, pasta de saída) são
  relativos ao arquivo de caso.
* Também é lido um arquivo JSON com a mesma estrutura (os valores com unidades,
  como texto).

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Seção
     - Chaves
   * - (início)
     - ``format`` (1), ``title``, ``authors``
   * - ``[mesh]``
     - ``module_size``, ``modules``, ``perturbation`` (deslocamento aleatório
       dos nós, fração do módulo), ``seed`` (da perturbação)
   * - ``[material]``
     - ``law`` (``bilinear``, a lei original, ou ``linear_elastic``: sem dano nem
       ruptura), ``young_modulus``, ``poisson_ratio``, ``density``,
       ``fracture_energy``, ``critical_distance``, ``failure_area_factor``
   * - ``[material.scatter]``
     - Dispersão da deformação crítica das barras. ``type = "none"``;
       ``"file"`` com ``file`` (um multiplicador por barra); ou ``"generated"``
       com ``cv``, ``correlation_length`` (em módulos) e ``seed`` (o campo é
       calculado na memória)
   * - ``[time]``
     - ``step`` (ou ``auto``), ``duration``
   * - ``[damping]``
     - ``type`` (``mass_proportional``, o amortecimento original, ou ``none``),
       ``initial``, ``final``, ``switch_time`` (não aceitos com ``none``),
       ``constitutive``
   * - ``[scenario]``
     - ``type`` (``uniaxial_tension``, ``four_point_bending``,
       ``clamped_beam`` ou ``custom``, veja abaixo) e as propriedades desse cenário em snake_case, por
       exemplo ``force_rate``, ``ramp_time``, ``load_position`` (é aceito
       ``"midspan"``)
   * - ``[[monitor.node]]``
     - Um elemento por nó de controle: ``id`` (número do nó) ou
       ``at = [x, y, z]`` (posição em módulos, usa-se o nó mais próximo), e
       ``name``
   * - ``[monitor.bar]``
     - ``tracked``: barra cuja história de deformação é guardada a cada passo
   * - ``[output]``
     - ``folder``, ``mat``, ``ansys``, ``vtk`` (true ou false)
   * - ``[output.snapshots]``, ``[output.control_nodes]``, ``[output.energy]``
     - ``every``: ``1000 steps`` ou um tempo como ``0.1 ms`` (convertido em
       passos); ``0`` significa nunca

``ldem.io.readCase`` devolve os parâmetros, o cenário e as opções de saída;
``ldem.Parameters.fromFile`` também aceita um arquivo de caso. A lista de chaves
está em uma única tabela, ``ldem.schema.caseSchema``, que governa o leitor, o
escritor e o modelo. Para adicionar um cenário, adiciona-se uma linha a
``ldem.scenarios.registry``. Uma nova lei constitutiva é uma subclasse de
``ldem.material.MaterialLaw`` registrada em ``ldem.material.lawRegistry``; um novo
modelo de amortecimento, uma subclasse de ``ldem.solver.DampingModel`` registrada
em ``ldem.solver.dampingRegistry``.

Reutilizar um caso: extends
---------------------------

Um arquivo de caso pode partir de outro e mudar só o que difere:

.. code-block:: text

   extends = "base.ldem"              # or a list: ["base.ldem", "material.ldem"]

   [material]
   fracture_energy = 1 N/m            # only what changes

As chaves do arquivo substituem as herdadas. Uma tabela repetida
(``[[support]]``, ``[[load]]``, ``[[monitor.node]]``, ``[[sweep]]``) substitui
toda a lista herdada. Quando muda o ``type`` do cenário, de
``[material.scatter]`` ou de ``[damping]``, as chaves do tipo anterior que não
são definidas de novo são descartadas. Com uma lista, os últimos arquivos
vencem. Os caminhos relativos (arquivo do campo aleatório, pasta de saída) são
relativos ao arquivo que os contém, e um erro indica o arquivo e a linha onde o
problema está escrito. ``results.info.case.parents`` guarda o hash de cada
arquivo herdado.

Varreduras de parâmetros
------------------------

Para estudar como o resultado depende de um valor, listam-se os valores em
blocos ``[[sweep]]`` e executa-se ``ldem.sweep``:

.. code-block:: text

   [[sweep]]
   key    = "material.fracture_energy"
   values = ["0.1 N/m", "0.5 N/m", "1 N/m"]

   [[sweep]]
   key    = "time.duration"
   values = ["20 us", "40 us"]

.. code-block:: matlab

   >> summary = ldem.sweep("case.ldem");                 % 3 x 2 = 6 runs, one folder each
   >> ldem.sweep("case.ldem", DryRun=true);              % only validate and list the runs
   >> ldem.sweep("case.ldem", Vary={"scenario.force_rate", ["1 kN/s" "2 kN/s"]});
   >> results = ldem.run("case.ldem", Overrides=struct("path", "material.fracture_energy", "value", "2 N/m"));

Vários blocos dão todas as combinações; ``sweep_mode = "zip"`` (uma chave no
início do arquivo) toma-os um a um. Pode-se variar qualquer chave de valor
único, e as do cenário como ``scenario.<chave>``. Os valores são números ou
textos com unidades. Cada execução é validada antes de começar a primeira. As
execuções vão para ``run_001``, ``run_002``, ... (cada uma com o seu
``case.ldem`` resolvido) e a tabela ``sweep_summary.csv`` as lista, com o número
de barras danificadas e rompidas; uma execução que falha fica registrada e a
varredura continua.

Referência de todas as chaves
-----------------------------

As tabelas a seguir são geradas a partir de ``ldem.schema.caseSchema``, a mesma
tabela que o leitor usa, portanto sempre coincidem com ele. As descrições estão
em inglês.

.. include:: ../case-keys.inc

O seu próprio ensaio: apoios e cargas
--------------------------------------

Com ``type = "custom"`` o ensaio é descrito no arquivo de caso com blocos
``[[support]]`` e ``[[load]]``, sem escrever uma classe. Este é o ensaio
uniaxial (``testId = 101``) como blocos:

.. code-block:: text

   [scenario]
   type = "custom"

   [[support]]
   name = "left end"
   x    = 0.5                 # the layer of centre nodes at x = 0.5 modules
   fix  = ["x"]               # directions that cannot move

   [[load]]
   name          = "right end"
   x             = "max - 0.5"
   direction     = "x"
   type          = "displacement"    # or "force"
   time_function = "linear"
   rate          = -4 mm/s
   reaction      = true              # its force is the reaction of the test

Os **nós** são escolhidos com ``nodes`` (``all``, ``grid`` para os cantos dos
módulos ou ``centre`` para os seus centros), ``ids`` (números de nó) e ``x``,
``y``, ``z``. Uma posição é em módulos (os nós centrais ficam em semi-inteiros,
os de canto em inteiros), um intervalo ``[lo, hi]``, ou um texto com as
referências ``min``, ``max`` e ``mid`` e um deslocamento, como ``"max - 0.5"``.
Um nó deve satisfazer todas as condições. As posições referem-se à malha
regular, portanto não mudam quando ``mesh.perturbation`` move os nós.

Os **apoios** fixam as direções de ``fix``. As **cargas** atuam em uma
``direction`` como ``force`` (newtons em cada nó escolhido) ou como
``displacement`` imposto (metros a partir da posição inicial; o solver fixa essa
direção). O valor segue ``time_function``: ``constant`` (``value``), ``linear``
(``rate``), ``ramp`` (``rate`` até o tempo ``until``, depois constante) ou
``table`` (``times`` e ``values`` em unidades SI, linear entre pontos e constante
fora).

Um bloco com ``reaction = true`` soma sua força à reação do ensaio (a soma das
forças de barra nas suas direções fixas); se nenhum a pedir, a reação é NaN. Um
bloco que não escolhe nenhum nó é um erro que o nomeia. Os três ensaios
incorporados escritos assim dão exatamente os mesmos resultados que as suas
classes.

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
