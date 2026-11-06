Construir um modelo diferente
=============================

Um modelo é definido por três coisas: a **geometria** do reticulado, o
**material** e o **ensaio** (apoios e cargas). As duas primeiras são
parâmetros; a terceira é uma classe *cenário*. Qualquer uma pode ser alterada
sem tocar no solver.

1. Alterar a geometria e o material
-----------------------------------

Tudo é uma propriedade de ``ldem.Parameters``:

.. code-block:: matlab

   >> params = ldem.Parameters(testId=101, ...
          moduleLength=0.002, ...          % aresta do módulo cúbico [m]
          nModules=[21 6 6], ...           % nós em x, y e z
          youngModulus=30e9, density=2400, poissonRatio=0.2, ...
          fractureEnergy=80, criticalDistance=0.02, ...
          meshPerturbation=0.02);          % malha irregular (opcional)

* ``nModules = [M N L]`` é o número de nós da grade em cada eixo, de modo que
  o prisma tem ``(M-1)*(N-1)*(L-1)`` módulos.
* ``randomFieldFile`` multiplica a deformação crítica de cada barra por um
  valor lido de um arquivo de texto (campo aleatório da resistência).
* ``dt`` deve ser menor que ``params.criticalTimeStep``; ``Parameters``
  rejeita um valor instável e explica o motivo.

Os mesmos dados podem vir de um arquivo de entrada no formato do programa
original: ``ldem.Parameters.fromFile("DATA0.DAT", ...)``; os pares
nome=valor adicionais substituem os do arquivo. A malha pode ser construída e
inspecionada antes de executar qualquer coisa:

.. code-block:: matlab

   >> mesh = ldem.mesh.buildMesh(params);
   >> fprintf("%d nós, %d barras\n", size(mesh.nodes0, 1), size(mesh.bars, 1));

2. Alterar o ensaio: escrever um cenário
----------------------------------------

Um *cenário* diz quais graus de liberdade estão fixos, como a carga é
aplicada a cada passo de tempo e qual reação é informada. O solver nunca
consulta o número do ensaio; ele pergunta ao cenário. Para modelar um ensaio
novo, crie uma subclasse de ``ldem.scenarios.Scenario`` em
``src/+ldem/+scenarios/``.

O exemplo é uma viga em balanço segundo :math:`z`: a primeira camada de nós
centrais é engastada e, na extremidade livre, aplica-se em :math:`y` uma força
que cresce linearmente.

.. code-block:: matlab

   classdef Cantilever < ldem.scenarios.Scenario
       properties (Constant)
           testId = 104                 % número novo, único
       end
       properties
           forceRate (1,1) double = 500 % [N/s] em cada nó carregado
       end
       methods
           function fixed = fixedDofs(~, nodes0, params)
               z = nodes0(:, 3);
               atStart = abs(z - 0.5*params.moduleLength) < 0.01*params.moduleLength;
               fixed = false(size(nodes0));
               fixed(atStart, :) = true;          % x, y e z fixos
           end
           function state = applyLoads(obj, state, mesh, params)
               L1 = params.nModules(3) - 1;
               z  = mesh.nodes0(:, 3);
               atEnd = abs(z - (L1 - 0.5)*params.moduleLength) < 0.01*params.moduleLength;
               state.appliedForce(:) = 0;
               state.appliedForce(atEnd, 2) = obj.forceRate * state.time;
           end
       end
   end

Regras:

* ``fixedDofs`` devolve uma matriz lógica de ``nNodes`` por 3, verdadeira onde
  o nó não pode se mover (``1 = x``, ``2 = y``, ``3 = z``).
* ``applyLoads`` é executado a cada passo. Um ensaio **controlado por
  deslocamento** atribui ``state.displacement`` dos nós carregados (ver
  ``UniaxialTension``); um **controlado por força** atribui
  ``state.appliedForce`` em newtons (ver ``ClampedBeam``) e o solver conta seu
  trabalho na energia externa.
* Redefina ``reactions`` se o ensaio informar uma força de reação (padrão:
  ``NaN``).
* Os nós centrais dos módulos estão em múltiplos semi-inteiros de
  ``moduleLength``; selecione os nós com uma tolerância pequena, nunca com
  ``==``.

3. Registrar e executar
-----------------------

O objeto pode ser passado diretamente, sem registrar nada:

.. code-block:: matlab

   >> scenario = ldem.scenarios.Cantilever(forceRate=1000);
   >> results = ldem.runSimulation(params, Scenario=scenario, ...
          OutputFolder="output", Formats=["mat" "vtk"]);

ou adicioná-lo à lista de ``ldem.scenarios.fromTestId`` para que
``testId = 104`` o encontre, que é o que faz um arquivo de entrada. Depois,
adicione um teste em ``tests/unit`` e, se for um caso de referência, um
exemplo em ``examples/`` (ver ``examples/example1_clamped_beam``).

O resultado é a mesma estrutura ``results`` de qualquer outro ensaio, ver
:doc:`usage`.
