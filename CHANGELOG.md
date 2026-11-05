# Changelog

## [Unreleased]
### Added
- Repository structure: README, LICENSE, CITATION, CONTRIBUTING.
- Sphinx documentation (English/Spanish) with API generated from `.m` files.
- `matlab.unittest` test suite and GitHub Actions workflows.
- Golden-master regression infrastructure (`tests/tools`, `tests/fixtures`,
  `tests/regression`): three small reference simulations generated from the
  legacy code, plus a slow test that checks the legacy code still reproduces
  them (`run_tests(IncludeSlow=true)`).
- `legacy/KNOWN_ISSUES.md`: bugs found in the original code and how the
  refactored code will resolve each one.

- New package `src/+ldem` (refactoring in progress), validated against the
  legacy fixtures: `ldem.Parameters` (validated input), `ldem.io.readInputFile`,
  `ldem.mesh.*` (nodes, bars, masses, geometry, optional perturbation),
  `ldem.scenarios.*` (test cases 101 and 102) and `ldem.solver.checkStability`.
- Material model in `ldem.material`: lattice coefficients, bar stiffness by bar
  type, critical strain with optional random field (`ldem.io.readRandomField`),
  and the bilinear constitutive law as a pure function (`bilinearLaw`).
  `ldem.mesh.buildBars` now also returns the bar type and boundary faces.
- Solver in `ldem.solver`: `simulate` (time loop), `computeBarForces`,
  `integrateStep` (central differences with damping), `computeEnergies`,
  `dampingCoefficient` and `initialState`. `Scenario` now also defines the
  loading (`applyLoads`, with a configurable `loadingVelocity`) and the
  reaction force (`reactions`).
- `TestSolverAgainstLegacy`: the new solver reproduces the corrected legacy
  simulation (displacements, velocities, damage, energies, reactions) in the
  three reference cases; unit tests with analytical solutions (damped
  oscillator, energy balance, Newton's third law).
- `ldem.runSimulation`: complete simulation returning one `results` struct and
  writing `results.mat`, ANSYS macro files (`ldem.io.exportAnsys`, equal to the
  legacy files except for two intended fixes) and a VTK series for ParaView
  (`ldem.io.exportVtk`, `ldem.io.writePvd`), driven by `ldem.io.SnapshotWriter`.
- `ldem.post.plotEnergy` and `ldem.post.plotReaction`; `ldem.Parameters.toStruct`.
- Runnable examples: `examples/tension_101/runTension.m` and
  `examples/beam_102/runBeam.m`; user guides rewritten (EN/ES).
- `buildfile.m` (`buildtool`): `check` (Code Analyzer, any warning fails), `test`
  (fast tests, JUnit report, Cobertura coverage), `testAll`, `docs` and `clean`.
  Coverage of the `ldem` package is 99.9 %.
- CI: `tests` runs `check` and `test` on R2023b and keeps the reports; `tests-all`
  (manual) also runs the slow tests; `docs` builds Sphinx with warnings as errors.
- Unit tests (`tests/unit`) and a regression test that compares the new mesh
  with the legacy one (`tests/regression/TestMeshAgainstLegacy`).

### Changed
- Original routines moved from `src/ldem` to `legacy/` (frozen reference).
- Experimental scripts moved to `sandbox/`; example inputs to `examples/beam_102/`.
- `.gitignore` now targets MATLAB and LDEM output files.
- `run_tests` searches subfolders and skips tests tagged `Slow` by default.
- `setup_path` adds both `src/` and `legacy/`; the generated API documentation
  now covers the `ldem` package only.

### Fixed
- `legacy/main1.m`: removed scratch lines; fixed the end-of-run file closing
  (undefined `fid12/fid15/fid19/fid20`) and the ANSYS output call.
- `legacy/BOUND.m`: `TEST 101` failed because `ini` was not assigned.
- `legacy/IGN012.m`: the time integration was never executed (the nested function
  `ign012` was not called), so free nodes never moved. Fixed; the golden-master
  fixtures were regenerated and the damage case re-tuned (1000 steps, Gf = 0.1).

### Removed
- Duplicate files (`* - Copia.m`, `Copy_of_*`), empty `initialization_DEM`, and
  generated output files that were tracked by mistake (`LET.*`, `*.TXT`,
  `SIM01.DAT`, `BARR_ROMP.dat`).
