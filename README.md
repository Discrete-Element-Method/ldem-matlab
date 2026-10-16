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
| `src/ldem/` | LDEM source code (`.m`) |
| `tests/` | `matlab.unittest` test suite |
| `docs/` | Sphinx documentation (English and Spanish), API generated from the `.m` files |
| `examples/` | How to run the example simulations |

### Quick start

```matlab
>> setup_path          % adds src/ldem to the MATLAB path
>> main                % runs the default simulation
```

Run the tests:

```matlab
>> addpath tests
>> run_tests
```

### Documentation

The API reference is generated automatically from the comments of the
`.m` files with [Sphinx](https://www.sphinx-doc.org/) and
`sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs/source docs/build/html
```

Source-code comments are written in Portuguese; the guides are available in
English and Spanish. See [CONTRIBUTING.md](CONTRIBUTING.md) for the docstring
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
| `src/ldem/` | Código-fonte LDEM (`.m`) |
| `tests/` | Suíte de testes com `matlab.unittest` |
| `docs/` | Documentação Sphinx (espanhol e inglês), API gerada a partir dos `.m` |
| `examples/` | Como executar as simulações de exemplo |

### Início rápido

```matlab
>> setup_path          % adiciona src/ldem ao path do MATLAB
>> main                % executa a simulação padrão
```

Executar os testes:

```matlab
>> addpath tests
>> run_tests
```

### Documentação

A referência da API é gerada automaticamente a partir dos comentários dos
`.m` com Sphinx e `sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs/source docs/build/html
```

Os comentários do código estão em português; os guias estão em espanhol e
inglês. Veja [CONTRIBUTING.md](CONTRIBUTING.md) para a convenção de docstrings.

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
| `src/ldem/` | Código fuente LDEM (`.m`) |
| `tests/` | Suite de tests con `matlab.unittest` |
| `docs/` | Documentación Sphinx (español e inglés), API generada desde los `.m` |
| `examples/` | Cómo ejecutar las simulaciones de ejemplo |

### Inicio rápido

```matlab
>> setup_path          % agrega src/ldem al path de MATLAB
>> main                % ejecuta la simulación por defecto
```

Ejecutar los tests:

```matlab
>> addpath tests
>> run_tests
```

### Documentación

La referencia de la API se genera automáticamente desde los comentarios de
los `.m` con Sphinx y `sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs/source docs/build/html
```

Los comentarios del código están en portugués; las guías están en español e
inglés. Ver [CONTRIBUTING.md](CONTRIBUTING.md) para la convención de docstrings.

### Cita

Ver [CITATION.cff](CITATION.cff). Licencia: [MIT](LICENSE).
