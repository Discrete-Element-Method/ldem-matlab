# Examples

| Folder | What it shows | Time |
|--------|---------------|------|
| `tension_101/` | Small prism under uniaxial load, all output formats, energy plot | seconds |
| `beam_102/` | The 101x41x21-module beam read from `DATA0.DAT` | ~20 s for 50 steps; ~20 h for the full run |

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

## beam_102 input files

| File | Purpose |
|------|---------|
| `DATA0.DAT` | Simulation parameters (format of the original program, read by `ldem.Parameters.fromFile`) |
| `arquivo_3lc_rnao_cv05` | Random field applied to the critical strain of each bar (11 MB) |
