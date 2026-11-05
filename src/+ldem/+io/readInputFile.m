function values = readInputFile(path)
%READINPUTFILE  Read a legacy input file (DATA0.DAT format).
%
%   values = ldem.io.readInputFile(path) parses the file and returns a
%   struct whose field names are properties of ldem.Parameters. The struct
%   can be passed to the constructor with namedargs2cell.
%
%   File format. Only the FIRST WORD of each line is read; whatever follows
%   (usually a quoted label) is a comment. The values appear in this order:
%
%       TEST, SEED, LCO, M, N, L,
%       DF1, DF2, TDAF, CON, DT, TTOT,
%       INCO, NCON(1) ... NCON(INCO),
%       OU2, OU3, OU4, OU5, OU6, OU7, OU8, OU9,
%       PSN, ROH, YNG, GFR, DEQ
%
%   Output codes OU2..OU9 of the legacy code are mapped to
%   Parameters.output as follows:
%
%       OU3 -> snapshotEvery        OU6 -> controlNodesEvery
%       OU8 -> energyEvery          OU9 -> trackedBarEvery (0 or 1)
%
%   OU2 (echo of the input), OU4, OU5 and OU7 only opened files in the
%   legacy driver and have no meaning in the new code; they are ignored.
%
%   Input:
%     path  Path of the input file.
%
%   Output:
%     values  Struct with the fields testId, seed, moduleLength, nModules,
%             dampingInitial, dampingFinal, dampingSwitchTime,
%             constitutiveDamping, dt, totalTime, controlNodes, output,
%             poissonRatio, density, youngModulus, fractureEnergy and
%             criticalDistance.
%
%   Errors:
%     ldem:io:fileNotFound   The file does not exist.
%     ldem:io:malformedInput The file has missing or non-numeric values.
%
%   Example:
%       values = ldem.io.readInputFile("examples/beam_102/DATA0.DAT");
%
%   Legacy: READ_DAT0.
%
%   See also ldem.Parameters.fromFile.

arguments
    path (1,1) string
end

if ~isfile(path)
    error('ldem:io:fileNotFound', 'Input file "%s" does not exist.', path);
end

tokens = firstWordOfEachLine(path);
nFixedBefore = 13;   % TEST .. INCO
if numel(tokens) < nFixedBefore
    error('ldem:io:malformedInput', ...
        '"%s" has %d values but at least %d are required.', ...
        path, numel(tokens), nFixedBefore);
end

nControl = str2double(tokens(13));
if ~isfinite(nControl) || nControl < 1 || nControl ~= fix(nControl)
    error('ldem:io:malformedInput', ...
        'Value 13 (INCO, number of control nodes) of "%s" must be a positive integer.', path);
end

expected = 26 + nControl;
if numel(tokens) < expected
    error('ldem:io:malformedInput', ...
        ['"%s" has %d values but %d are required for INCO = %d ' ...
         '(13 + INCO + 13).'], path, numel(tokens), expected, nControl);
end

numbers = str2double(tokens(1:expected));
bad = find(isnan(numbers), 1);
if ~isempty(bad)
    error('ldem:io:malformedInput', ...
        'Value %d of "%s" ("%s") is not a number.', bad, path, tokens(bad));
end

at = @(k) numbers(k);
afterControl = 13 + nControl;     % index of the last control node

values = struct();
values.testId              = at(1);
values.seed                = at(2);
values.moduleLength        = at(3);
values.nModules            = [at(4) at(5) at(6)];
values.dampingInitial      = at(7);
values.dampingFinal        = at(8);
values.dampingSwitchTime   = at(9);
values.constitutiveDamping = at(10);
values.dt                  = at(11);
values.totalTime           = at(12);
values.controlNodes        = reshape(numbers(14:afterControl), 1, []);

ou = numbers(afterControl + (1:8));   % OU2 ... OU9
values.output = struct( ...
    'snapshotEvery',     ou(2), ...    % OU3
    'controlNodesEvery', ou(5), ...    % OU6
    'energyEvery',       ou(7), ...    % OU8
    'trackedBarEvery',   double(ou(8) > 0));   % OU9

values.poissonRatio     = at(afterControl + 9);
values.density          = at(afterControl + 10);
values.youngModulus     = at(afterControl + 11);
values.fractureEnergy   = at(afterControl + 12);
values.criticalDistance = at(afterControl + 13);
end

function tokens = firstWordOfEachLine(path)
%FIRSTWORDOFEACHLINE  First whitespace-delimited word of every non-empty line.
lines = splitlines(string(fileread(path)));
tokens = strings(0, 1);
for k = 1:numel(lines)
    word = strtok(strtrim(lines(k)));
    if strlength(word) > 0
        tokens(end+1, 1) = word; %#ok<AGROW>
    end
end
end
