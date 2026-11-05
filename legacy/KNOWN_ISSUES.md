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
| `IGN012.m` | **Critical.** The central-difference integration was in a nested function `ign012` that was never called, so no node moved except those with a prescribed displacement (velocities and accelerations were exactly 0) | Added the call `ign012;`. Results change: the fixtures were regenerated and cases that damaged because of the frozen neighbours no longer do |

## Not fixed (would change results or output) - decide in the new code

1. **`ENERG2.m` lines 172-174: kinetic energy is not summed.** *(Resolved in the new code.)*
   `ENCN = ENCN + (MAS.*VLX.^2)/2` is element-wise, so `ENCN` is a
   1-by-`INT` vector (kinetic energy per node) instead of a scalar. `ENIN`,
   `DEN` and the energy balance inherit this shape.
   *New code:* `energy.kinetic = sum(...)` (scalar). The regression test
   compares `sum(ENCN)` with the new scalar.
2. **`WRIENE.m` line 35: invalid format `%25.12` (missing `e`).** *(Output to be written by the new exporters.)*
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
7. **`CALCOEV.m`: the coefficient of variation is never stored.**
   It computes `COEF = std(EP)/MEAN` but the global variable is `COEV`, which
   therefore stays 0 (and is printed as 0 in the input echo).
   *New code:* `barProps.criticalStrainCv` holds the real value.
8. **`DEFEP.m`: unused safety check.** `DEFEP` stops when `KR < 1.01`, but
   `RMEC` no longer calls it (the formulas are inlined), so the check never
   runs and the softening branch could divide by `KR - 1 ~ 0`.
   *New code:* `buildBarProperties` raises `ldem:material:criticalLengthTooShort`.
9. **Random field is mandatory.** The main program fails if the file
   `arquivo_3lc_rnao_cv05` is missing, with no way to run a homogeneous
   material. *New code:* `params.randomFieldFile` is optional (empty = all
   multipliers equal to 1).
10. **Preallocation `INT = 168000`, `INB = 2300000`** limits the mesh size.
11. **`ign012` (IGN012.m): acceleration in y uses a wrong index.**
    `ACY = (V(3,:) - V(2,I).*2.0 + V(1,:))./SDT` uses `V(2,I)` (a scalar, with
    `I` left over from the node loop) instead of `V(2,:)`. Only the reported
    acceleration is affected, not the motion.
    *New code:* the three components use the same formula
    (`ldem.solver.integrateStep`); the regression test skips `ACY`.
12. **`ign012`: damping energy mixes vectors and scalars.**
    `ENDP` becomes a per-node vector, and the viscous dissipation of every bar
    (a scalar) is added to every node entry, so `sum(ENDP)` counts the bar
    terms `NNT` times. The reference cases have `CON = 0`, where the two
    definitions coincide.
    *New code:* `state.dampingEnergy` is a scalar.
13. **`ENERG2.m` / `IGN012.m`: `KL` is always 2.** The test `B > NBA` (or
    `B <= NBS`) selecting `KL = 4` for the diagonals never holds because
    `NBA = NBS = NBT`. `KL = 2` gives the exact bar energy
    (`E*strain^2*L/2`), so the results are right; the dead branch was removed.
14. **`ENEX` (external work) is never computed.** It stays 0 and the energy
    balance `ENEX - ENIN` is not available.
    *New code:* not provided yet; `energy.internal` is.
15. **`CALOAD.m`, `TEST == 102`: the second load point is never loaded.**
    The condition is `LOGIC1 && LOGIC2`, two conditions on the x coordinate
    that can only both hold for `M1 = 67`; `BOUND` holds both load points in y,
    so the left one acts as a support.
    *New code:* reproduced (`FourPointBending.loadedNodes`); decide with the
    author whether both points should be loaded.
16. **`TDAF` shorter than half a time step never switches the damping.**
    The switch is done when `STEP == NDAMF` and `NDAMF` would be 0.
    *New code:* reproduced (`ldem.solver.dampingCoefficient`).
17. **`TEST == 101` sign convention.** The loaded nodes move to
    `x0 - VF2*TIME`, which compresses the prism for `VF2 > 0` although the
    comment says "tension". *New code:* same convention, documented in
    `UniaxialTension`.
18. **`ANSYS.m`: three problems in the macro files.**
    (a) The line `ET,IFILE,4` is an invalid ANSYS command (a translation slip
    for `ET,3,4`); (b) constraints (`D,node,UX`...) are only written for
    `TEST == 102`; (c) the "applied loads" section writes `F,node,Fx,-10` for
    nodes selected with hardcoded coordinates (`50.5*LCO`...) that match no
    node of the beam.
    *New code (`ldem.io.exportAnsys`):* writes `ET,3,4`, writes the constraints
    of every scenario and leaves the loads section empty. The regression test
    normalizes (a) and (b) before comparing with the legacy files.
