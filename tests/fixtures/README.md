# Golden-master fixtures

`tension101_elastic.mat`, `tension101_damage.mat` and `bending102.mat` hold the
results of three small simulations run with the original MATLAB code (the
`legacy/` folder, translated from Fortran), after correcting its obvious bugs
(see `docs/known-issues/KNOWN_ISSUES.md`). The case definitions are in
`tests/tools/referenceCases.m`.

`clamped103.mat` is the bi-clamped beam of Rodrigo (branch `dev_rodrigo`,
commit 3249300): it was produced with the same original code but with the
`BOUND` and `CALOAD` routines of that branch (they modify `TEST 102`; the new
code registers the model as test 103). It is a reduced version of the model
(5x5x21 nodes, 1600 steps, fracture energy 0.02 N/m so that bars soften).

The regression tests in `tests/regression` compare the `ldem` package with
these files (relative tolerance 1e-9). The original code is not in the working
tree; it is in the git history under the tag `legacy-reference`, together with
the tools that generated the fixtures (`tests/tools/generateReference.m`).
Change a fixture only on purpose, and say why in the pull request.

`arquivo_3lc_rnao_cv05` (11 MB) is the random field of the critical strain
that those simulations read: one multiplier per bar, written by the original
script `Aleat_novo4.m` (coefficient of variation 0.05, correlation length 3
modules). It has the defects of that script (mean 0.957, see
`KNOWN_ISSUES.md`), so the examples generate their field with
`ldem.material.generateRandomField` instead; it is kept only to reproduce
the legacy runs.
