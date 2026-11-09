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

Comments are written in English. Names: `lowerCamelCase` for functions and variables,
`UpperCamelCase` for classes. Validate inputs with an `arguments` block and throw
errors with an identifier of the form `ldem:<area>:<problem>`.

## Workflow
1. Branch from `dev`.
2. Add or adjust tests in `tests/` (`Test*.m`, `matlab.unittest`): `tests/unit`
   for the behaviour of each function, `tests/regression` for comparisons with
   the golden-master results of the original code.
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
| `buildtool testAll` | Also the slow tests (complete beam model) |
| `buildtool docs` | Sphinx HTML in every language, in `docs/build/html/<language>` (needs Python and `docs/requirements.txt`) |
| `buildtool clean` | Delete the generated files |

`run_tests` (in `tests/`) is a lighter alternative that only runs the tests.

Files excluded from docs/tests: backups (`*.asv`).

## Repository layout
- `src/+ldem/` is the `ldem` package. All the code goes here.
- `tests/fixtures/*.mat` are golden-master results produced by the original
  (Fortran-derived) MATLAB code, after correcting its obvious bugs. The original
  code is not in the working tree; it is in the git history under the tag
  `legacy-reference` (`git checkout legacy-reference`, which also contains the
  tools that generated the fixtures). The problems found in it are listed in
  `docs/known-issues/KNOWN_ISSUES.md`. Change a fixture only on purpose, and
  say in the pull request why the reference result changed.
- Slow tests (tag `Slow`) are skipped by `buildtool test` and `run_tests`; use
  `buildtool testAll` or `run_tests(IncludeSlow=true)`.
