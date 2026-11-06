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
%
%   To make the run reproducible, results.info.case keeps
%
%     source    Path of the case file.
%     sha256    SHA-256 hash of the file that was read (text, 64 hex digits).
%     original  Text of that file.
%     resolved  Complete case with every default and the overrides, as ldem.io.writeCase writes it.
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
end

c = ldem.io.readCase(casePath);
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
caseInfo = struct('source', c.info.source, 'sha256', sha256Of(original), ...
    'original', original, 'resolved', resolved);

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
