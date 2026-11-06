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
results = ldem.runSimulation(c.params, Scenario = c.scenario, ...
    OutputFolder = folder, Formats = formats, Verbose = options.Verbose);
end
