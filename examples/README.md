# Examples

## beam_102

Input files of the beam (TEST 102) example:

| File | Purpose |
|------|---------|
| `DATA0.DAT` | Simulation parameters (read by `read_dat0`) |
| `LET.AN1` | Names of the ANSYS files to write |
| `arquivo_3lc_rnao_cv05` | Random field applied to the critical strain of each bar (11 MB) |

The legacy driver reads these files from the **current folder** and writes its
outputs (`LET.*`, `*.TXT`, `ANSYS*.MAC`, ...) there too, so run it from a
scratch copy:

```matlab
>> setup_path                       % from the repository root
>> mkdir('run'); copyfile('examples/beam_102/*', 'run'); cd run
>> main1
```
