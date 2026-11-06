Construir esta documentação
===========================

A documentação é escrita em inglês e traduzida para espanhol, português e
italiano; as quatro versões formam um único site e a barra lateral permite
trocar de idioma. A referência da API é gerada a partir dos comentários dos
``.m``.

Requisitos
----------

* Python 3.9 ou superior.
* ``git`` (a lista de autores é gerada a partir do histórico de commits; com um
  clone superficial execute antes ``git fetch --unshallow``).
* Não é necessário MATLAB; a API é lida do texto das fontes.

.. code-block:: bash

   pip install -r docs/requirements.txt

Construção
----------

A partir da raiz do repositório, com qualquer uma destas opções:

.. code-block:: bash

   sphinx-build -W --keep-going -b html docs/source docs/build/html

.. code-block:: bash

   cd docs && make html

.. code-block:: matlab

   >> buildtool docs

Abra ``docs/build/html/index.html`` em um navegador. ``-W`` transforma os
avisos em erros: a documentação deve ser construída sem nenhum.
``buildtool clean`` apaga o resultado.

Onde fica cada coisa
--------------------

``docs/source/en/``
   O texto de referência, em inglês.
``docs/source/es/``, ``pt/``, ``it/``
   Traduções. Cada página tem o mesmo nome de arquivo que em ``en/`` para que
   a lista de idiomas da barra lateral leve à mesma página.
``docs/source/api/``
   Referência da API, gerada a partir dos comentários dos ``.m``.
``docs/tools/generate_authors.py``
   Escreve a página de autores e ``AUTHORS.md`` (executado pela construção).

Escrever ou alterar uma página
------------------------------

1. Edite a página em inglês em ``docs/source/en/``.
2. Aplique a mesma alteração às traduções. Uma página nova precisa de um
   arquivo com o mesmo nome em cada idioma e de uma entrada em cada
   ``index.rst``.
3. Construa com ``-W`` e corrija qualquer aviso.

Publicação
----------

O workflow ``.github/workflows/docs.yml`` constrói a documentação a cada pull
request e a publica no GitHub Pages quando ``main`` muda.
