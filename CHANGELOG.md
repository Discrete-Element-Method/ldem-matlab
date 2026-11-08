# Changelog

## [Unreleased]
### Added
- Case files (`.ldem`): a readable, commented input file that replaces
  `DATA0.DAT` and describes the whole model (mesh, material, random scatter,
  time, damping, scenario, control nodes, output). Keys are read by name, numbers
  carry units (`3.87 GPa`, `0.35 us`), `time.step = auto` takes 0.9 times the
  critical step, output cadence can be given in steps or in time, control nodes
  can be given by position, and every error names the file, line, section and key
  (with "did you mean ...?"). JSON with the same structure is also read.
  `ldem.io.readCase`, `ldem.io.writeCase`, `ldem.io.writeTemplate`,
  `ldem.io.convertLegacyInput` (DATA0.DAT to `.ldem`, same `Parameters`),
  `ldem.run`, `ldem.check` (dry run: size of the model, stability margin, random
  field file, snapshot memory), and `ldem.Parameters.fromFile` reads `.ldem` and
  `.json` too. The keys live in one table, `ldem.schema.caseSchema`, with
  `ldem.schema.parseQuantity` / `formatQuantity` for the units.
- `ldem.run` makes every run reproducible: `results.info.case` keeps the SHA-256
  of the case file, its text and the resolved case (all defaults and overrides),
  and the resolved case is saved as `case.ldem` in the output folder
  (`ldem.runSimulation` has a new `CaseInfo` option for this).
- Pluggable constitutive law and damping model, chosen by name in the case file
  (`[material] law`, `[damping] type`) and in `ldem.Parameters`
  (`constitutiveLaw`, `dampingModel`). `ldem.material.MaterialLaw` is the
  interface of a law (force, energies, damage energy of a bar, viscous
  stiffness); `bilinear` (the legacy law, results unchanged) and the new
  `linear_elastic` implement it, registered in `ldem.material.lawRegistry`.
  `ldem.solver.DampingModel` is the interface of a damping model; `mass_proportional`
  (legacy) and the new `none` are in `ldem.solver.dampingRegistry`. The solver
  functions take the law and the model as optional last arguments.
- Case files can inherit: `extends = "base.ldem"` (or a list) starts from other files; keys
  replace the inherited ones, repeated tables replace the whole list, a change of scenario,
  scatter or damping type drops the keys of the old type, relative paths follow the file
  that writes them, and errors name that file. Loops and missing parents are errors.
- Parameter sweeps: `[[sweep]]` blocks (`key`, `values`; `sweep_mode = "product"` or
  `"zip"`) and `ldem.sweep`, which validates every run first, runs each in
  `run_NNN` with its resolved `case.ldem`, and returns a table (also written as
  `sweep_summary.csv`) with the varied values, status, time and damaged and broken bars.
  `ldem.io.readCase` has an `Overrides` option and `ldem.run` too; `results.info.case` also
  keeps `parents` (with hashes) and `overrides`.
- The key reference of the user guide (`docs/source/case-keys.inc`) is generated from
  `ldem.schema.caseSchema` by `ldem.schema.writeKeyReference`; a test fails if it is out of date.
- Tests defined in the case file, without a class: `[scenario] type = "custom"` with
  `[[support]]` and `[[load]]` blocks. Nodes are selected by kind (all, grid, centre),
  by number and by coordinate ranges in modules with `min`, `max` and `mid`; a load is a
  force or a prescribed displacement following `constant`, `linear`, `ramp` or `table`;
  blocks can join the reaction of the test. `ldem.scenarios.Declarative` (test 900) is
  the class behind it, with `selectNodes`, `parseCoordinate`, `coordinateText` and
  `timeFunction`. The three built-in tests written as blocks give exactly the same
  results. `Scenario.prepare` lets a scenario compute its node lists once; they are
  stored in `mesh.scenarioData`. New unit `force` (N, kN, MN).
- `ldem.scenarios.registry` is the single list of scenarios;
  `ldem.scenarios.fromTestId` reads it and `ldem.scenarios.fromName` is new.
- `case.ldem` next to the `DATA0.DAT` of `examples/beam_102` and
  `examples/example1_clamped_beam`; user guide (EN/ES/IT/PT) and API pages.
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
