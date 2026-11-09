function results = run(casePath, options)
%RUN  Run a simulation described by a case file (.ldem or .json).
%
%   results = ldem.run(casePath) reads the case file with ldem.io.readCase and
%   runs it with ldem.runSimulation, writing the files requested in its
%   [output] section (relative to the case file). It is the one-line way to
%   run a model:
%
%       results = ldem.run("examples/example1_clamped_beam/case.ldem");
%
%   results = ldem.run(casePath, Name=Value) overrides parts of the case:
%
%     OutputFolder  Other output folder ("" writes nothing).
%     Formats       Other files to write, for example "mat".
%     Verbose       Print the progress (default true).
%     Overrides     Struct array (fields path = "section.key" and value) that replaces keys of the case.
%
%   To make the run reproducible, results.info.case keeps
%
%     source    Path of the case file.
%     sha256    SHA-256 hash of the file that was read (text, 64 hex digits).
%     original  Text of that file.
%     resolved  Complete case with every default and the overrides, as ldem.io.writeCase writes it.
%     parents   Struct array (source, sha256) of the case files inherited through extends.
%     overrides Text lines "key = value" of the Overrides option.
%
%   and, when files are written, the resolved case is also saved as
%   "case.ldem" in the output folder, so a result folder can be run again with
%   ldem.run(fullfile(folder, "case.ldem")).
%
%   Input:
%     casePath  Path of the case file.
%
%   Output:
%     results  Struct returned by ldem.runSimulation.
%
%   Example:
%       results = ldem.run("my_test.ldem", OutputFolder=tempname);
%
%   See also ldem.check, ldem.io.readCase, ldem.runSimulation.

arguments
    casePath (1,1) string
    options.OutputFolder = []
    options.Formats = []
    options.Verbose (1,1) logical = true
    options.Overrides = []
end

c = ldem.io.readCase(casePath, Overrides = options.Overrides);
if ~isempty(c.info.sweep) && isempty(options.Overrides)
    warning('ldem:run:sweepIgnored', ...
        '%s defines a sweep of %d key(s); ldem.run runs only the base case. Use ldem.sweep to run them all.', ...
        casePath, numel(c.info.sweep));
end
folder = c.options.OutputFolder;
formats = c.options.Formats;
if ~isempty(options.OutputFolder)
    folder = string(options.OutputFolder);
end
if ~isempty(options.Formats)
    formats = string(options.Formats);
end

original = string(fileread(c.info.source));
resolvedFormats = formats;
if isempty(resolvedFormats)
    resolvedFormats = "mat";
end
resolved = ldem.io.writeCase("", c.params, c.scenario, ...
    Title = c.info.title, Authors = c.info.authors, ...
    ControlNodeNames = c.info.controlNodeNames, ...
    Header = "Resolved from " + c.info.source + " by ldem.run.", ...
    Formats = resolvedFormats);
parents = struct('source', {}, 'sha256', {});
for parent = c.info.parents.'
    parents(end+1) = struct('source', parent, 'sha256', sha256Of(string(fileread(parent)))); %#ok<AGROW>
end
overrideLines = strings(0, 1);
for k = 1:numel(options.Overrides)
    overrideLines(end+1, 1) = string(options.Overrides(k).path) + " = " + string(options.Overrides(k).value); %#ok<AGROW>
end
caseInfo = struct('source', c.info.source, 'sha256', sha256Of(original), ...
    'original', original, 'resolved', resolved, 'parents', parents, 'overrides', overrideLines);

results = ldem.runSimulation(c.params, Scenario = c.scenario, ...
    OutputFolder = folder, Formats = formats, Verbose = options.Verbose, ...
    CaseInfo = caseInfo);

if strlength(folder) > 0
    ldem.io.writeCase(fullfile(folder, "case.ldem"), c.params, c.scenario, ...
        Title = c.info.title, Authors = c.info.authors, ...
        ControlNodeNames = c.info.controlNodeNames, ...
        Header = "Resolved from " + c.info.source + " by ldem.run.", ...
        OutputFolder = ".", Formats = resolvedFormats);
end
end

function hash = sha256Of(text)
%SHA256OF  SHA-256 of a text as 64 lower-case hexadecimal digits.
digest = java.security.MessageDigest.getInstance('SHA-256');
bytes = typecast(digest.digest(uint8(char(text))), 'uint8');
hash = string(lower(reshape(dec2hex(bytes, 2).', 1, [])));
end
