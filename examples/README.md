# Examples

| Folder | What it shows | Time |
|--------|---------------|------|
| `tension_101/` | Small prism under uniaxial load, all output formats, energy plot | seconds |
| `beam_102/` | The 101x41x21-module beam read from `DATA0.DAT` | ~20 s for 50 steps; ~20 h for the full run |
| `example1_clamped_beam/` | Beam clamped at both ends and loaded with a force at mid-span (model by Rodrigo) | see below |

Run an example from MATLAB, from any folder:

```matlab
>> run('examples/tension_101/runTension.m')
```

Outputs are written to an `output/` folder next to the script (ignored by git):

- `results.mat` - one struct, `results`, with everything that was recorded.
  Load it with `data = load('results.mat'); results = data.results;`.
- `snapshot_0000.mac`, ... - ANSYS macro files of the deformed lattice.
- `snapshot_0000.vtu`, ... and `snapshots.pvd` - open `snapshots.pvd` in
  [ParaView](https://www.paraview.org/) to see the damage evolve in time.

## Case files

Each beam example has a `case.ldem` next to its `DATA0.DAT`: the same model in
the readable case-file format (named keys, units, comments, the scenario and
the output files in one place; see the user guide). It is generated from the
`DATA0.DAT` and gives the same parameters.

```matlab
>> ldem.check('examples/example1_clamped_beam/case.ldem')    % what would be simulated
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');
```

## beam_102 input files

| File | Purpose |
|------|---------|
| `case.ldem` | The same parameters as a case file (`ldem.io.readCase`, `ldem.run`) |
| `DATA0.DAT` | Simulation parameters (format of the original program, read by `ldem.Parameters.fromFile`) |
| `arquivo_3lc_rnao_cv05` | Random field applied to the critical strain of each bar (11 MB) |

## example1_clamped_beam

A beam of 5 x 5 x 50 modules (1 mm each) clamped at both ends and loaded at
mid-span with a force, by Rodrigo (branch `dev_rodrigo`). It runs the 8000 steps
(2.8 ms) of the original model in about one minute.

| File | Purpose |
|------|---------|
| `case.ldem` | The same model as a case file (run it with `ldem.run`) |
| `runClampedBeam.m` | Reads `DATA0.DAT`, runs the simulation, plots the force on the clamped ends, the vertical displacement of the control nodes and the energies |
| `DATA0.DAT` | Parameters of the model (`TEST 103`, see `ldem.scenarios.ClampedBeam`) |

The random field of the critical strain is shared with `beam_102`.

How the model maps to the input file and the scenario:

- The centre nodes of the first and of the last layer of modules are clamped.
- A line of centre nodes at mid-span (z = 24.5 modules, y = 0.5 modules) carries a
  force in +y that grows as `forceRate * t` (1000 N/s per node) up to `rampTime`
  (0.35 ms) and then stays constant. Change them with
  `ldem.scenarios.ClampedBeam(forceRate=..., rampTime=...)`.
- Control nodes: the original file listed five, but nodes 6870 and 14398 do not
  exist in this 3086-node mesh, so `DATA0.DAT` keeps nodes 2441 (a loaded node)
  and 884 (a grid node at mid-span). The tracked bar is 14398, as in the original.
- With these values the beam stays elastic (no bar softens). Raise `forceRate` or
  lower the fracture energy (`GFR` in `DATA0.DAT`) to see damage.
