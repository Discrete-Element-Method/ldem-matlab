# Contributing / Contribuir

## Docstring convention
The API docs are generated from the comments of the `.m` files
(`sphinxcontrib-matlabdomain`). The docstring must be the comment block
placed **immediately after the `function` line** (before `global` blocks):

```matlab
function ini = CALOAD()
% CALOAD  One-line summary (English).
% Longer description of what the routine does.
global ...
```

Comments in new code are written in English (the legacy code keeps its original Portuguese comments).

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
