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
2. Add/adjust tests in `tests/` (`Test*.m`, `matlab.unittest`).
3. Run `run_tests` in MATLAB and build the docs (`docs/`) locally.
4. Open a pull request.

Files excluded from docs/tests: backups (`*.asv`) and the scratch scripts in `sandbox/`.

## Repository layout during the refactoring
- `legacy/` is the **frozen** original code. Do not change its numerics: the
  regression tests compare the refactored code against it. Known problems are
  listed in `legacy/KNOWN_ISSUES.md`.
- `tests/fixtures/*.mat` are golden-master results produced by the legacy code.
  Regenerate them only if the legacy code is changed on purpose:
  `addpath('tests/tools'); generateReference`.
- `run_tests` skips slow tests by default; use `run_tests(IncludeSlow=true)`
  before opening a pull request.
