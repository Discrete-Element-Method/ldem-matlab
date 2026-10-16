# LDEM-MATLAB

[English](#english) · [Español](#español)

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
