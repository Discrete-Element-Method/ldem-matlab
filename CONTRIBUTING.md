# Contributing / Contribuir

## Docstring convention
The API docs are generated from the comments of the `.m` files
(`sphinxcontrib-matlabdomain`). The docstring is the comment block placed
**immediately after the `function` line** (no blank line in between):

```matlab
function [barLength, barCentres] = computeBarGeometry(nodes, bars)
%COMPUTEBARGEOMETRY  One-line summary.
%
%   [barLength, barCentres] = ldem.mesh.computeBarGeometry(nodes, bars)
%   explains in a few lines what the function does.
%
%   Inputs:
%     nodes  nNodes-by-3 coordinates [m].
%     bars   nBars-by-2 node numbers.
%
%   Outputs:
%     barLength   nBars-by-1 vector of lengths [m].
%     barCentres  nBars-by-3 matrix of midpoints [m].
%
%   Example:
%       [len, mid] = ldem.mesh.computeBarGeometry(nodes, bars);
%
%   Legacy: CALAUX.
%
%   See also ldem.mesh.buildBars.
```

Rules that keep the Sphinx build free of warnings:
- Write each entry of *Inputs/Outputs* on **one line**; put longer
  explanations in a paragraph after the list.
- Leave a blank comment line before an indented block (list, example, table).

Comments in new code are written in English (the legacy code keeps its original
Portuguese comments). Names: `lowerCamelCase` for functions and variables,
`UpperCamelCase` for classes. Validate inputs with an `arguments` block and throw
errors with an identifier of the form `ldem:<area>:<problem>`.

## Workflow
1. Branch from `dev`.
2. Add or adjust tests in `tests/` (`Test*.m`, `matlab.unittest`): `tests/unit`
   for new code, `tests/regression` for comparisons with the legacy results.
3. Run `buildtool` in MATLAB from the repository root. It runs the Code
   Analyzer (`check`, which must report nothing) and the fast tests with
   coverage (`test`). Before opening the pull request also run
   `buildtool testAll` and `buildtool docs`.
4. Open a pull request. CI runs `check` and `test` on every push and builds the
   documentation with warnings as errors.

| Command | What it does |
|---------|--------------|
| `buildtool` | `check` and `test` (default) |
| `buildtool check` | Code Analyzer on `src/`, `tests/` and `examples/`; any warning fails |
| `buildtool test` | Fast tests; writes `test-results/results.xml` and `code-coverage/coverage.xml` |
| `buildtool testAll` | Also the slow tests (re-run the legacy simulations, ~5 min) |
| `buildtool docs` | Sphinx HTML in `docs/build/html` (needs Python and `docs/requirements.txt`) |
| `buildtool clean` | Delete the generated files |

`run_tests` (in `tests/`) is a lighter alternative that only runs the tests.

Files excluded from docs/tests: backups (`*.asv`) and the scratch scripts in `sandbox/`.

## Repository layout during the refactoring
- `src/+ldem/` is the `ldem` package: the refactored code. New work goes here.
- `legacy/` is the **frozen** original code. Do not change its numerics: the
  regression tests compare the refactored code against it. Known problems are
  listed in `legacy/KNOWN_ISSUES.md`.
- `tests/fixtures/*.mat` are golden-master results produced by the legacy code.
  Regenerate them only if the legacy code is changed on purpose:
  `addpath('tests/tools'); generateReference`.
- Slow tests (tag `Slow`) are skipped by `buildtool test` and `run_tests`; use
  `buildtool testAll` or `run_tests(IncludeSlow=true)`.
