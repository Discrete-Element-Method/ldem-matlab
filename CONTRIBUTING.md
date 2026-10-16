# Contributing / Contribuir

## Docstring convention
The API docs are generated from the comments of the `.m` files
(`sphinxcontrib-matlabdomain`). The docstring must be the comment block
placed **immediately after the `function` line** (before `global` blocks):

```matlab
function ini = CALOAD()
% CALOAD  One-line summary (Portuguese).
% Longer description of what the routine does.
global ...
```

Comments in the source code are written in Portuguese.

## Workflow
1. Branch from `dev`.
2. Add/adjust tests in `tests/` (`Test*.m`, `matlab.unittest`).
3. Run `run_tests` in MATLAB and build the docs (`docs/`) locally.
4. Open a pull request.

Files excluded from docs/tests: backups (`*.asv`), copies (`*Copia*`,
`Copy_of_*`) and scratch scripts (`Teste_*`, `main1`, ...).
