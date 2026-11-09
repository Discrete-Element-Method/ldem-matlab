# Examples

Three models that run from start to finish. Each has its inputs and a script that runs
it and plots the results. The full description, with the model, the files and the
results to expect, is in the user guide: *Examples* (`docs/source/examples.rst`).

| Folder | What it shows | Size | Time |
|--------|---------------|------|------|
| `example1_clamped_beam/` | Beam clamped at both ends and loaded with a force at mid-span (model by Rodrigo) | 3,086 nodes | about 35 s |
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

The two beam examples have a `case.ldem` next to their `DATA0.DAT`: the same model in
the readable case-file format (named keys, units, comments, the scenario and the output
files in one place). It is generated from the `DATA0.DAT` and gives the same parameters.

```matlab
>> ldem.check('examples/example1_clamped_beam/case.ldem')    % what would be simulated
>> results = ldem.run('examples/example1_clamped_beam/case.ldem');
```

## Files

| Folder | File | Purpose |
|--------|------|---------|
| `example1_clamped_beam/` | `case.ldem` | The model as a case file |
| | `runClampedBeam.m` | Reads `DATA0.DAT`, runs, and plots the force on the clamped ends, the vertical displacement of the control nodes and the energies |
| | `DATA0.DAT` | Parameters in the format of the original program (`TEST 103`) |
| `tension_101/` | `runTension.m` | Describes the model with `ldem.Parameters`, runs it and plots the energies |
| `beam_102/` | `case.ldem` | The model as a case file |
| | `runBeam.m` | Reads the input, runs the first 50 steps and plots the reaction |
| | `DATA0.DAT` | Parameters in the format of the original program (`TEST 102`) |
| | `arquivo_3lc_rnao_cv05` | Random field of the critical strain of each bar (11 MB); `example1_clamped_beam` uses it too |

With the default values the clamped beam stays elastic (no bar softens). Raise the
force (`force_rate` in `case.ldem`, `forceRate` in the scenario) or lower the fracture
energy to see damage.
