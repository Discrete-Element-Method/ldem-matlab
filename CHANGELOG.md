# Changelog

## [Unreleased]
### Added
- Repository structure: README, LICENSE, CITATION, CONTRIBUTING.
- Sphinx documentation (English/Spanish) with API generated from `.m` files.
- `matlab.unittest` test suite and GitHub Actions workflows.
- Golden-master regression infrastructure (`tests/tools`, `tests/fixtures`,
  `tests/regression`): three small reference simulations generated from the
  legacy code, plus a slow test that checks the legacy code still reproduces
  them (`run_tests(IncludeSlow=true)`).
- `legacy/KNOWN_ISSUES.md`: bugs found in the original code and how the
  refactored code will resolve each one.

### Changed
- Original routines moved from `src/ldem` to `legacy/` (frozen reference).
- Experimental scripts moved to `sandbox/`; example inputs to `examples/beam_102/`.
- `.gitignore` now targets MATLAB and LDEM output files.
- `run_tests` searches subfolders and skips tests tagged `Slow` by default.

### Fixed
- `legacy/main1.m`: removed scratch lines; fixed the end-of-run file closing
  (undefined `fid12/fid15/fid19/fid20`) and the ANSYS output call.
- `legacy/BOUND.m`: `TEST 101` failed because `ini` was not assigned.

### Removed
- Duplicate files (`* - Copia.m`, `Copy_of_*`), empty `initialization_DEM`, and
  generated output files that were tracked by mistake (`LET.*`, `*.TXT`,
  `SIM01.DAT`, `BARR_ROMP.dat`).
