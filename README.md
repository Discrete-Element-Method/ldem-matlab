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
| `src/+ldem/` | The `ldem` package (refactored code) |
| `tests/` | `matlab.unittest` test suite |
| `docs/` | Sphinx documentation (English and Spanish), API generated from the `.m` files |
| `examples/` | How to run the example simulations |

### Quick start

```matlab
>> setup_path          % adds src/ to the MATLAB path
>> run('examples/tension_101/runTension.m')   % small example, output in examples/tension_101/output
>> run('examples/example1_clamped_beam/runClampedBeam.m')   % beam clamped at both ends
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
sphinx-build -b html docs/source docs/build/html
```

Comments are written in English (the original code is in the git history under
the tag `legacy-reference`); the guides are available in English and Spanish. See [CONTRIBUTING.md](CONTRIBUTING.md) for the docstring
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
| `src/+ldem/` | O pacote `ldem` (código refatorado) |
| `tests/` | Suíte de testes com `matlab.unittest` |
| `docs/` | Documentação Sphinx (espanhol e inglês), API gerada a partir dos `.m` |
| `examples/` | Como executar as simulações de exemplo |

### Início rápido

```matlab
>> setup_path          % adiciona src/ ao path do MATLAB
>> run('examples/tension_101/runTension.m')   % exemplo pequeno, saída em examples/tension_101/output
>> run('examples/example1_clamped_beam/runClampedBeam.m')   % viga biengastada
```

Executar os testes:

```matlab
>> buildtool          % static analysis + fast tests (needs R2022b or newer)
>> buildtool testAll  % also the slow tests
```

### Documentação

A referência da API é gerada automaticamente a partir dos comentários dos
`.m` com Sphinx e `sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs/source docs/build/html
```

Os comentários estão em inglês (o código original está no histórico do git, na
tag `legacy-reference`); os guias estão em espanhol e inglês. Veja [CONTRIBUTING.md](CONTRIBUTING.md) para a convenção de docstrings.

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
| `src/+ldem/` | El paquete `ldem` (código refactorizado) |
| `tests/` | Suite de tests con `matlab.unittest` |
| `docs/` | Documentación Sphinx (español e inglés), API generada desde los `.m` |
| `examples/` | Cómo ejecutar las simulaciones de ejemplo |

### Inicio rápido

```matlab
>> setup_path          % agrega src/ al path de MATLAB
>> run('examples/tension_101/runTension.m')   % ejemplo pequeño, salida en examples/tension_101/output
>> run('examples/example1_clamped_beam/runClampedBeam.m')   % viga empotrada en ambos extremos
```

Ejecutar los tests:

```matlab
>> buildtool          % static analysis + fast tests (needs R2022b or newer)
>> buildtool testAll  % also the slow tests
```

### Documentación

La referencia de la API se genera automáticamente desde los comentarios de
los `.m` con Sphinx y `sphinxcontrib-matlabdomain`:

```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs/source docs/build/html
```

Los comentarios están en inglés (el código original está en el historial de git,
etiqueta `legacy-reference`); las guías están en español e inglés. Ver [CONTRIBUTING.md](CONTRIBUTING.md) para la convención de docstrings.

### Cita

Ver [CITATION.cff](CITATION.cff). Licencia: [MIT](LICENSE).
