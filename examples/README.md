# Examples

Three models that run from start to finish. Each has its inputs and a script that runs
it and plots the results. The full description, with the model, the files and the
results to expect, is in the user guide: *Examples* (`docs/source/examples.rst`).

| Folder | What it shows | Size | Time |
|--------|---------------|------|------|
| `example1_clamped_beam/` | Beam clamped at both ends and loaded with a prescribed displacement at mid-span (model by Rodrigo) | 3,086 nodes | about 35 s |
| `tension_101/` | Small prism under a uniaxial load, with damage and every output format | 74 nodes | about 6 s |
| `beam_102/` | The 101x41x21-node four-point bending beam of the paper (demo of the first 50 steps) | 166,961 nodes | about 30 s for 50 steps; about 20 h for the full run |

Run an example from MATLAB, from any folder:

```matlab
>> run('examples/example1_clamped_beam/runClampedBeam.m')
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');   % from the case file
```

Outputs are written to an `output/` folder next to the script (ignored by git):

- `results.mat` - one struct, `results`, with everything that was recorded.
  Load it with `data = load('results.mat'); results = data.results;`.
- `snapshot_0000.mac`, ... - ANSYS macro files of the deformed lattice.
- `snapshot_0000.vtu`, ... and `snapshots.pvd` - open `snapshots.pvd` in
  [ParaView](https://www.paraview.org/) to see the damage evolve in time.

## Case files

The two beam examples are described by a `case.ldem`: the model in the readable
case-file format (named keys, units, comments, the scenario and the output files in one
place).

```matlab
>> ldem.check('examples/example1_clamped_beam/case.ldem')    % what would be simulated
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');
```

## Files

| Folder | File | Purpose |
|--------|------|---------|
| `example1_clamped_beam/` | `case.ldem` | The model as a case file |
| | `runClampedBeam.m` | Reads `case.ldem`, runs, and plots the force on the clamped ends, the vertical displacement of the control nodes and the energies |
| `tension_101/` | `runTension.m` | Describes the model with `ldem.Parameters`, runs it and plots the energies |
| `beam_102/` | `case.ldem` | The model as a case file |
| | `runBeam.m` | Reads `case.ldem`, runs the first 50 steps and plots the reaction |

The random field of the critical strain of the two beams is generated in memory from the
`[material.scatter]` section of their `case.ldem` (coefficient of variation 0.05,
correlated over 3 modules); no file is needed.

The mid-span line of the clamped beam is pushed up with a constant velocity of 4 mm/s
(`loading = "displacement"`, `loading_velocity` in `case.ldem`); at the end a few bars
have started to soften. Raise the velocity (20 mm/s breaks the beam) or lower the
fracture energy to see more damage, or set `loading = "force"` to load it with a force
(`force_rate`, `ramp_time`) instead.
