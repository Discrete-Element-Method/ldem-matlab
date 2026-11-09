# Known issues of the legacy code

*Versión en español: [KNOWN_ISSUES.es.md](KNOWN_ISSUES.es.md).*

The original MATLAB routines (the `legacy/` folder, translated from the
Fortran program) were the reference implementation of the regression tests.
They were removed from the working tree once the refactored code reproduced
them; they remain in the git history under the tag `legacy-reference`
(`git checkout legacy-reference`). The golden-master results they produced are
stored in `tests/fixtures/`.

Problems found in the original code are listed here with the decision taken.
Where a problem was an obvious programming error it was **corrected in the
original code as well**, and the fixtures were regenerated from the corrected
version (the tag holds that version).

Status of each item: **Corrected** (in the original code and in the new code),
**Resolved** (in the new code; the original kept the old behaviour),
**Reviewed** (checked, no change needed) or **Accepted** (the original
behaviour is kept). No item is open.

## Corrected in the original code

| File | Problem | Fix |
|------|---------|-----|
| `main1.m` | Scratch lines `a=1, b=2, c=3` at the top | Removed |
| `main1.m` | Closing section used undefined `fid12/fid15/fid19/fid20` and crashed at the end of every run | Closes the file ids that were really opened |
| `main1.m` | `ARMANS(I3)` (parentheses) and `[...] = ini==ANSYS(...)` crashed when ANSYS output was enabled | `ARMANS{I3}`, plain call |
| `BOUND.m` | `ini` only assigned when `TEST == 102`, so `TEST 101` failed | Assigned unconditionally |
| `IGN012.m` | **Critical.** The central-difference integration was in a nested function `ign012` that was never called, so no node moved except those with a prescribed displacement (velocities and accelerations were exactly 0) | Added the call `ign012;` |
| `IGN012.m` | Acceleration in y used `V(2,I)` (a scalar left over from the node loop) instead of `V(2,:)` (item 11) | `V(2,:)` |
| `BOUND.m` | `TEST 101`: misplaced parenthesis in the right-end support (items 3 and 19) | `(M1 - 0.51)*LCO` |
| `CALOAD.m` | `TEST 102`: wrong condition, the second load point was never loaded (item 15) | `LOGIC2 && LOGIC3` |

## Items

1. **`ENERG2.m` lines 172-174: kinetic energy is not summed.** `ENCN` is a
   per-node vector instead of a scalar. **Resolved.** The new code gives both:
   the kinetic energy of every node (`results.final.kineticEnergy`, and
   `results.snapshots.kineticEnergy` at the snapshot steps) and the total of
   the model (`results.energy.kinetic`).
2. **`WRIENE.m` line 35: invalid format `%25.12` (missing `e`).** `LET.ENE` was
   truncated and garbled. **Resolved.** The energy history is part of the
   results file (`results.energy`); there is no text file.
3. **`BOUND.m`, `TEST == 101`: operator precedence.** `mask2` used
   `U0 > (M1 - 0.51*LCO)` instead of `(M1 - 0.51)*LCO` and selected no node.
   **Corrected.** The right-end column of centre nodes is the loaded one, and it
   is now held in x (same bug as item 19).
4. **`CABAR.m` / `ENERG2.m`: tracked bar hardcoded to 7014.** **Resolved**:
   `params.trackedBar`.
5. **`TEST == 102`: geometry hardcoded in module units** (`33.49`, `4.51`,
   `50.5`...), so the test only worked for `M >= ~70`. **Resolved**:
   `FourPointBending(supportPosition=, loadPosition=)`, with the legacy values
   as defaults, and an error when a position matches no node.
6. **`IMPERF.m`: `LABELN` is set to 1 and then immediately to 0,** so the mesh
   perturbation is never applied and the seed has no effect. **Resolved** in
   the new code: the user sets it with one number, `meshPerturbation`: 0 (the
   default) leaves the lattice regular, and any positive value activates the
   perturbation with that coefficient of variation (for example `0.02` for 2 %
   of the module length). It is no longer a flag edited in the code. The time-step
   stability check uses the real (perturbed) bar lengths.
7. **`CALCOEV.m`: the coefficient of variation is never stored** (`COEF` instead
   of `COEV`). **Resolved**: `results.barProps.criticalStrainCv` and
   `results.material`, which also stores E, Gf, the lattice coefficients and
   the mean, minimum and maximum critical strain (what `WRICON` printed).
8. **`DEFEP.m`: unused safety check** (`KR < 1.01`). **Resolved**:
   `buildBarProperties` raises `ldem:material:criticalLengthTooShort`.
9. **Random field is mandatory.** **Resolved**: `params.randomFieldFile` is
   optional (empty = all multipliers equal to 1).
10. **Preallocation `INT = 168000`, `INB = 2300000`** limited the mesh size.
    **Resolved**: every size follows from the number of modules.
11. **`ign012`: acceleration in y uses a wrong index.** **Corrected** in
    the original code and in the new code (`ldem.solver.integrateStep`); the regression
    test now compares the three components.
12. **`ign012`: damping energy mixes vectors and scalars.** **Resolved**:
    `state.dampingEnergy` is a scalar. (The reference cases have `CON = 0`,
    where both definitions coincide.)
13. **`ENERG2.m` / `IGN012.m`: `KL` is always 2.** The test `B > NBA` that
    would give `KL = 4` to the diagonals never holds because `NBA = NBS = NBT`.
    **Reviewed.** The bar type is known from how the model is built (grid
    edge, centre-to-centre bar or diagonal, `mesh.barType`), but `KL = 2` is
    right for every type: it gives the bar energy `E*strain^2*L/2`, consistent
    with the force law. With `KL = 4` for the diagonals the energy balance
    would be off by 13.5 % (elastic beam test; the diagonals hold 36 % of the
    elastic energy) and 4.6 % (beam with damage), against 0.05-0.1 % with
    `KL = 2`.
14. **`ENEX` (external work) is never computed.** **Resolved**:
    `energy.external` is the work done on the degrees of freedom held by the
    scenario and `energy.balance = external - internal`. The balance is below
    1 % of the external work (0.01-0.5 % in the reference tests), also with
    softening and rupture (tests in `TestSimulate` and `TestSolver`).
15. **`CALOAD.m`, `TEST == 102`: the second load point is never loaded.** The
    condition `LOGIC1 && LOGIC2` cannot hold. **Corrected**: both load points
    move (`LOGIC2 && LOGIC3`).
16. **`TDAF` shorter than half a time step never switches the damping.**
    **Accepted** (`ldem.solver.dampingCoefficient` reproduces it).
17. **`TEST == 101` sign convention.** The loaded nodes move to `x0 - VF2*TIME`,
    which compresses the prism for `VF2 > 0` although the comment says
    "tension". **Accepted**: same convention, documented in `UniaxialTension`;
    use a negative `loadingVelocity` to pull.
18. **`ANSYS.m`: three problems in the macro files.** (a) The line `ET,IFILE,4`
    is an invalid ANSYS command (a slip for `ET,3,4`); (b) constraints
    (`D,node,UX`...) are only written for `TEST == 102`; (c) the "applied
    loads" section writes `F,node,Fx,-10` for nodes selected with hardcoded
    coordinates (`50.5*LCO`...) that match no node of the beam.
    **Resolved.** `ldem.io.exportAnsys` writes `ET,3,4` (a) and the zero-valued
    constraints of every scenario (b). For (c) the loads section lists the
    displacement imposed on the loaded nodes as `D,node,UY,value`, measured
    from their initial position (nothing at time zero). ANSYS keeps the last
    constraint of a degree of freedom, so these lines replace the zero ones.
    The node coordinates of the file are still the current positions, so the
    file shows the state of the simulation; it is not a restart from the
    undeformed lattice.
19. **`CALOAD.m`, `TEST == 101`: the loaded nodes were not held** (the same bug
    as item 3): their position was overwritten at every step and then moved
    freely, so no force did work on them and the energy balance could not
    close. **Corrected** together with item 3.
20. **`Aleat_novo4.m` (external generator of the random field file): the mean is
    not 1 and the interpolation has two typos.** The Weibull scale is
    `Gamma(1+1/k)` instead of `1/Gamma(1+1/k)`, so the mean of the field is
    `Gamma(1+1/k)^2` (0.957 for `Cv = 0.05`, the mean of
    `arquivo_3lc_rnao_cv05`). In the trilinear interpolation the x-z term uses
    `V6-V5-V3+V1` instead of `V6-V5-V2+V1` and `ZZp(ii)` instead of `ZZp(iip)`,
    which adds scatter: the bundled file has a CV of 0.054 although the poles
    had 0.05, while a correct interpolation always lowers it. The script also
    needed `BARI.txt` (bar centres), which no code of the repository writes.
    **Resolved**: `ldem.material.generateRandomField` (enabled with
    `params.randomFieldCv`) uses mean 1 and the exact trilinear interpolation
    and takes the bar centres from the mesh. Its fields are therefore not equal
    to the legacy files; to reproduce a legacy run keep `randomFieldFile`.
