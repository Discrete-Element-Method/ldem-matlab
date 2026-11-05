# Known issues of the legacy code

`legacy/` is the frozen reference implementation. The regression tests compare
the refactored code against it, so its numerics must not change. Issues found
while freezing it are listed here and are **resolved explicitly in the new
code** (each one has a test that documents the decision).

## Fixed in legacy (no effect on the physics)

| File | Problem | Fix |
|------|---------|-----|
| `main1.m` | Scratch lines `a=1, b=2, c=3` at the top | Removed |
| `main1.m` | Closing section used undefined `fid12/fid15/fid19/fid20` and crashed at the end of every run | Closes the file ids that were really opened |
| `main1.m` | `ARMANS(I3)` (parentheses) and `[...] = ini==ANSYS(...)` crashed when ANSYS output was enabled | `ARMANS{I3}`, plain call |
| `BOUND.m` | `ini` only assigned when `TEST == 102`, so `TEST 101` failed | Assigned unconditionally |

## Not fixed (would change results or output) - decide in the new code

1. **`ENERG2.m` lines 172-174: kinetic energy is not summed.**
   `ENCN = ENCN + (MAS.*VLX.^2)/2` is element-wise, so `ENCN` is a
   1-by-`INT` vector (kinetic energy per node) instead of a scalar. `ENIN`,
   `DEN` and the energy balance inherit this shape.
   *New code:* `energy.kinetic = sum(...)` (scalar). The regression test
   compares `sum(ENCN)` with the new scalar.
2. **`WRIENE.m` line 35: invalid format `%25.12` (missing `e`).**
   `fprintf` stops at the invalid conversion, so `LET.ENE` is truncated and
   garbled. Correcting only the format would write one row per element of the
   `ENCN` vector (90 MB for 200 steps), so it depends on issue 1.
   *New code:* one well-formed row per saved step.
3. **`BOUND.m`, `TEST == 101`: operator precedence.**
   `mask2` uses `U0 > (M1 - 0.51*LCO)` instead of `(M1 - 0.51)*LCO`; it
   selects no node, so the right end is never fixed in x.
   *New code:* decide with the author whether this support was intended.
4. **`CABAR.m` / `ENERG2.m`: tracked bar hardcoded to 7014.**
   *New code:* `params.trackedBar`.
5. **`CALOAD.m` / `BOUND.m` / `CALRES.m` / `ANSYS.m` (`TEST == 102`):**
   geometry hardcoded in module units (`33.49`, `4.51`, `50.5`...), so the
   scenario only works for meshes with `M >= ~70`.
   *New code:* scenario parameters.
6. **`IMPERF.m`: `LABELN` is set to 1 and then immediately to 0,** so the mesh
   perturbation is never applied (the random generator seed has no effect).
7. **Preallocation `INT = 168000`, `INB = 2300000`** limits the mesh size.
