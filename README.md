# LDEM-MATLAB

[English](#english) · [Português (BR)](#português-br) · [Español](#español)

---

## English

MATLAB implementation of the **Lattice Discrete Element Method (LDEM)**, a
numerical method that represents a continuum as a regular lattice of nodes
and bars (cubic modules with diagonals) and integrates the dynamics
explicitly. Typical applications are fracture and damage simulation of
quasi-brittle materials (concrete, rocks).

### Repository layout

| Path | Content |
|------|---------|
| `src/+ldem/` | The `ldem` package: all the code |
| `tests/` | `matlab.unittest` test suite |
| `docs/` | Sphinx documentation in English, translated into Spanish, Portuguese and Italian; the API is generated from the `.m` files |
| `examples/` | Three example models, each with its case file or script |

### Quick start

```matlab
>> setup_path          % adds src/ to the MATLAB path
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');   % run a case file
>> run('examples/tension_101/runTension.m')   % small example written in MATLAB, output in examples/tension_101/output
```

Run the tests:

```matlab
>> buildtool          % static analysis + fast tests (needs R2022b or newer)
>> buildtool testAll  % also the slow tests
```

### Documentation

The API reference is generated automatically from the comments of the
`.m` files with [Sphinx](https://www.sphinx-doc.org/) and
`sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
python docs/tools/build_docs.py
```

Comments are written in English (the original code is in the git history under
the tag `legacy-reference`); the guides are in English, translated into Spanish, Portuguese and Italian. See [CONTRIBUTING.md](CONTRIBUTING.md) for the docstring
convention.

### Citation

See [CITATION.cff](CITATION.cff). License: [MIT](LICENSE).

---

## Português (BR)

Implementação em MATLAB do **Método dos Elementos Discretos do tipo Treliça
(LDEM)**: o meio contínuo é representado por um reticulado regular de nós e
barras (módulos cúbicos com diagonais) e a dinâmica é integrada de forma
explícita. Aplicações típicas: simulação de fratura e dano em materiais
quase-frágeis (concreto, rochas).

### Estrutura do repositório

| Caminho | Conteúdo |
|---------|----------|
| `src/+ldem/` | O pacote `ldem`: todo o código |
| `tests/` | Suíte de testes com `matlab.unittest` |
| `docs/` | Documentação Sphinx em inglês, traduzida para espanhol, português e italiano; a API é gerada a partir dos `.m` |
| `examples/` | Três modelos de exemplo, cada um com seu arquivo de caso ou script |

### Início rápido

```matlab
>> setup_path          % adiciona src/ ao path do MATLAB
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');   % executa um arquivo de caso
>> run('examples/tension_101/runTension.m')   % exemplo pequeno escrito em MATLAB, saída em examples/tension_101/output
```

Executar os testes:

```matlab
>> buildtool          % análise estática + testes rápidos (requer R2022b ou superior)
>> buildtool testAll  % inclui também os testes lentos
```

### Documentação

A referência da API é gerada automaticamente a partir dos comentários dos
`.m` com Sphinx e `sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
python docs/tools/build_docs.py
```

Os comentários estão em inglês (o código original está no histórico do git, na
tag `legacy-reference`); os guias estão em inglês, traduzidos para espanhol, português e italiano. Veja [CONTRIBUTING.md](CONTRIBUTING.md) para a convenção de docstrings.

### Citação

Veja [CITATION.cff](CITATION.cff). Licença: [MIT](LICENSE).

---

## Español

Implementación en MATLAB del **Método de Elementos Discretos tipo Reticulado
(LDEM)**: el continuo se representa como un reticulado regular de nodos y
barras (módulos cúbicos con diagonales) y la dinámica se integra de forma
explícita. Aplicaciones típicas: simulación de fractura y daño en materiales
cuasi-frágiles (hormigón, rocas).

### Estructura del repositorio

| Ruta | Contenido |
|------|-----------|
| `src/+ldem/` | El paquete `ldem`: todo el código |
| `tests/` | Suite de tests con `matlab.unittest` |
| `docs/` | Documentación Sphinx en inglés, traducida al español, portugués e italiano; la API se genera desde los `.m` |
| `examples/` | Tres modelos de ejemplo, cada uno con su archivo de caso o script |

### Inicio rápido

```matlab
>> setup_path          % agrega src/ al path de MATLAB
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');   % ejecuta un archivo de caso
>> run('examples/tension_101/runTension.m')   % ejemplo pequeño escrito en MATLAB, salida en examples/tension_101/output
```

Ejecutar los tests:

```matlab
>> buildtool          % análisis estático + tests rápidos (requiere R2022b o posterior)
>> buildtool testAll  % incluye también los tests lentos
```

### Documentación

La referencia de la API se genera automáticamente desde los comentarios de
los `.m` con Sphinx y `sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
python docs/tools/build_docs.py
```

Los comentarios están en inglés (el código original está en el historial de git,
etiqueta `legacy-reference`); las guías están en inglés, traducidas al español, portugués e italiano. Ver [CONTRIBUTING.md](CONTRIBUTING.md) para la convención de docstrings.

### Cita

Ver [CITATION.cff](CITATION.cff). Licencia: [MIT](LICENSE).
