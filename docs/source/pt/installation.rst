Instalação
==========

Requisitos: MATLAB R2022b ou superior (desenvolvido e testado na R2023b). O
pacote usa o bloco ``arguments`` e a sintaxe nome=valor; a suíte de testes e o
``buildtool`` exigem a R2022b. Nenhum toolbox é necessário.

.. code-block:: bash

   git clone <url-do-repositorio> ldem-matlab
   cd ldem-matlab

.. code-block:: matlab

   >> setup_path

Verifique a instalação com os testes rápidos:

.. code-block:: matlab

   >> buildtool test

Tarefas para desenvolvedores (``buildtool`` é executado a partir da raiz do
repositório):

.. code-block:: matlab

   >> buildtool             % análise estática + testes rápidos (padrão)
   >> buildtool check       % somente o analisador de código
   >> buildtool testAll     % todos os testes, inclusive os lentos
   >> buildtool docs        % construir esta documentação (requer Python)
   >> buildtool clean       % apagar os arquivos gerados

``buildtool test`` escreve ``test-results/results.xml`` (JUnit) e
``code-coverage/coverage.xml`` (Cobertura).

Para construir esta documentação sem MATLAB, veja :doc:`docs`.
