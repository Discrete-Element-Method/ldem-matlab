# Changelog

## [Unreleased]
### Added
- Repository structure: README, LICENSE, CITATION, CONTRIBUTING.
- Sphinx documentation (English/Spanish) with API generated from `.m` files.
- `matlab.unittest` test suite and GitHub Actions workflows.
- Golden-master regression infrastructure (`tests/tools`, `tests/fixtures`,
  `tests/regression`): three small reference simulations generated from the
  original code.
- `docs/known-issues/KNOWN_ISSUES.md` (and `.es.md`): bugs found in the original
  code and how each one was resolved.

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
- External work and energy balance: `energy.external` is the work done on the degrees
  of freedom held by the scenario and `energy.balance = external - internal`
  (0.01-0.5 % of the external work in the reference tests, also with softening
  and rupture).
- Kinetic energy of every node (`ldem.solver.nodalKineticEnergy`, stored in
  `results.final` and in the snapshots) besides the total of the model.
- `results.model` and `results.material`: counts, mass, material data, lattice
  coefficients and statistics of the critical strain (what `WRICON` printed).
- `FourPointBending(supportPosition=, loadPosition=)`: the positions of the beam
  test are parameters (the legacy values are the defaults); an error is raised when
  a position matches no node.
- Spanish translation of the known issues: `docs/known-issues/KNOWN_ISSUES.es.md`.
- Example 1, `examples/example1_clamped_beam`: the beam clamped at both ends and
  loaded with a force at mid-span, by Rodrigo (branch `dev_rodrigo`). It adds
  `ldem.scenarios.ClampedBeam` (test 103), the first scenario loaded with a force:
  a scenario can now set `state.appliedForce`, which the solver adds to the bar
  forces and whose work is counted in the external energy. The new code
  reproduces the original routines of the branch with no difference
  (`tests/regression/TestClampedBeamAgainstLegacy`).
- ANSYS files list the displacement imposed on the loaded nodes
  (`D,node,direction,value`) in the applied-loads section.
- `Parameters.meshPerturbation`: one number that switches the mesh perturbation
  off (`0`, the default) or on with that coefficient of variation (`> 0`).
- Unit tests (`tests/unit`) and a regression test that compares the new mesh
  with the legacy one (`tests/regression/TestMeshAgainstLegacy`).
- `ldem.io.exportAnsys` writes the applied forces (`F,node,FX|FY|FZ,value`) of force-controlled
  scenarios (test 103); before, the ANSYS files of that test had no load.
- Documentation brought in line with the code: the introductions (EN/ES) describe the `ldem` package
  instead of the legacy routines, `Parameters.testId` and `Scenario` mention test 103, the results tables
  include `brokenBars` and the reaction of test 103, and the Portuguese and Spanish READMEs translate the
  `buildtool` comments.
- Random field generated in memory: `ldem.material.generateRandomField` ports the
  external script `Aleat_novo4.m` (Weibull values on a grid of poles, trilinear
  interpolation to the bar centres), vectorised and without toolboxes. It is
  switched on with `Parameters.randomFieldCv > 0`, with
  `randomFieldCorrelationLength` (in module lengths, default 3) and
  `randomFieldSeed` (default 515); no text file is needed. The multiplier of each
  bar is stored in `results.barProps.randomField` and its origin and statistics in
  `results.material.randomField`, also for a field read from a file.

### Changed
- Example inputs moved to `examples/beam_102/`.
- `.gitignore` now targets MATLAB and LDEM output files.
- `run_tests` searches subfolders and skips tests tagged `Slow` by default.
- The generated API documentation covers the `ldem` package only.

### Fixed in the original code (kept in the git tag `legacy-reference`)
- `legacy/main1.m`: removed scratch lines; fixed the end-of-run file closing
  (undefined `fid12/fid15/fid19/fid20`) and the ANSYS output call.
- `legacy/BOUND.m`: `TEST 101` failed because `ini` was not assigned, and its
  right-end support had a misplaced parenthesis (the loaded nodes were not held,
  so the tension test did not conserve energy).
- `legacy/CALOAD.m`: the second load point of the beam test was never loaded.
- `legacy/IGN012.m`: the acceleration in y used a wrong index.
- `legacy/IGN012.m`: the time integration was never executed (the nested function
  `ign012` was not called), so free nodes never moved. Fixed; the golden-master
  fixtures were regenerated and the damage case re-tuned (1000 steps, Gf = 0.1).

### Removed
- The original routines (`legacy/`) and the scratch scripts (`sandbox/`), with the
  tools and tests that ran them (`generateReference`, `runLegacyCase`,
  `TestLegacyReproducibility`, `TestLdemPath`). They remain in the git history
  under the tag `legacy-reference`; the reference results they produced are kept
  in `tests/fixtures/`.
- `examples/beam_102/LET.AN1`, which only the original driver read.
- Duplicate files (`* - Copia.m`, `Copy_of_*`), empty `initialization_DEM`, and
  generated output files that were tracked by mistake (`LET.*`, `*.TXT`,
  `SIM01.DAT`, `BARR_ROMP.dat`).
