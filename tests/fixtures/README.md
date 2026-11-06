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
