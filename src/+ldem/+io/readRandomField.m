function field = readRandomField(path, nBars)
%READRANDOMFIELD  Read the random field that scatters the critical strain.
%
%   field = ldem.io.readRandomField(path, nBars) reads the first nBars
%   numbers of a text file with one value per line (or separated by
%   blanks). Each value multiplies the critical strain of the bar with the
%   same number, so the material is not perfectly homogeneous.
%
%   The file may be longer than nBars; the extra values are ignored.
%
%   Inputs:
%     path   Path of the text file.
%     nBars  Number of bars of the mesh.
%
%   Output:
%     field  nBars-by-1 vector of positive multipliers.
%
%   Errors:
%     ldem:io:fileNotFound         The file does not exist.
%     ldem:io:randomFieldTooShort  The file has fewer than nBars values.
%     ldem:io:randomFieldInvalid   A value is not finite and positive.
%
%   Example:
%       field = ldem.io.readRandomField("examples/beam_102/arquivo_3lc_rnao_cv05", 6221);
%
%   Legacy: the loop that reads "arquivo_3lc_rnao_cv05" in the main program.
%
%   See also ldem.material.buildBarProperties.

arguments
    path (1,1) string
    nBars (1,1) double {mustBeInteger, mustBePositive}
end

if ~isfile(path)
    error('ldem:io:fileNotFound', 'Random field file "%s" does not exist.', path);
end

fid = fopen(path, 'r');
if fid == -1
    error('ldem:io:cannotOpenFile', 'Cannot open random field file "%s".', path);
end
closer = onCleanup(@() fclose(fid));
field = fscanf(fid, '%f', nBars);

if numel(field) < nBars
    error('ldem:io:randomFieldTooShort', ...
        '"%s" has %d values but the mesh has %d bars.', path, numel(field), nBars);
end
if any(~isfinite(field) | field <= 0)
    error('ldem:io:randomFieldInvalid', ...
        '"%s" contains values that are not finite and positive (first one: value %d).', ...
        path, find(~isfinite(field) | field <= 0, 1));
end
end
