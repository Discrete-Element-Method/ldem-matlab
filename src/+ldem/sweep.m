function [summary, results] = sweep(casePath, options)
%SWEEP  Run a case once for every combination of values of some keys.
%
%   summary = ldem.sweep(casePath) runs the case file once for each value of the
%   keys listed in its [[sweep]] blocks and returns a table with one row per run:
%
%       [[sweep]]
%       key    = "material.fracture_energy"
%       values = ["0.1 N/m", "0.5 N/m", "1 N/m"]
%
%       [[sweep]]
%       key    = "scenario.force_rate"
%       values = ["1 kN/s", "2 kN/s"]
%
%   Several blocks give every combination (3 x 2 = 6 runs); with sweep_mode =
%   "zip" they are taken one by one instead (all lists must have the same
%   length). A key can be any single-valued key of the case file, or a key of the
%   scenario ("scenario.<key>"); values are numbers or texts with units, as in
%   the file. Every run is validated before the first one starts, so a bad value
%   stops the sweep at once.
%
%   Each run writes its files to <OutputFolder>/run_001, run_002, ... with the
%   resolved case as case.ldem, and the table is saved as sweep_summary.csv in
%   OutputFolder. A run that fails is recorded in the table (status "failed",
%   with the message) and the sweep goes on.
%
%   Inputs:
%     casePath  Path of the case file.
%
%   Name-value options:
%     Vary          Cell {key1, values1, key2, values2, ...} with more keys to vary besides the [[sweep]] blocks.
%     Mode          "product" or "zip" (default: sweep_mode of the file, product).
%     OutputFolder  Folder of the runs (default "<case name>_sweep" next to the file).
%     Formats       Files to write in each run, for example "mat" (default: the ones of the case).
%     Verbose       Print one line per run (default true).
%     DryRun        Only validate and list the runs, without running them.
%     KeepResults   Return the results struct of every run as the second output.
%
%   Outputs:
%     summary  Table: run, one column per varied key, folder, status, message, seconds, damagedBars, brokenBars.
%     results  Cell with the results of each run (empty cells unless KeepResults).
%
%   Errors:
%     ldem:sweep:noKeys        There is nothing to vary.
%     ldem:sweep:zipLengths    The lists have different lengths in zip mode.
%     ldem:sweep:invalidRun    A combination makes an invalid case.
%
%   Example:
%       summary = ldem.sweep("examples/sweeps/fracture_energy.ldem");
%       plot(summary.material_fracture_energy, summary.brokenBars)
%
%   See also ldem.run, ldem.io.readCase.

arguments
    casePath (1,1) string
    options.Vary = {}
    options.Mode (1,1) string {mustBeMember(options.Mode, ["" "product" "zip"])} = ""
    options.OutputFolder = []
    options.Formats = []
    options.Verbose (1,1) logical = true
    options.DryRun (1,1) logical = false
    options.KeepResults (1,1) logical = false
end

base = ldem.io.readCase(casePath);
blocks = base.info.sweep;
extra = options.Vary;
if ~iscell(extra) || mod(numel(extra), 2) ~= 0
    error('ldem:sweep:invalidRun', 'Vary must be a cell {key1, values1, key2, values2, ...}.');
end
for k = 1:2:numel(extra)
    values = extra{k + 1};
    if isnumeric(values)
        items = num2cell(reshape(values, 1, []));
    else
        items = num2cell(reshape(string(values), 1, []));
    end
    blocks(end+1) = struct('key', string(extra{k}), 'values', {items}); %#ok<AGROW>
end
if isempty(blocks)
    error('ldem:sweep:noKeys', ...
        'There is nothing to vary: add [[sweep]] blocks to the case file or use the Vary option.');
end
mode = base.info.sweepMode;
if options.Mode ~= ""
    mode = options.Mode;
end

combinations = combine(blocks, mode);          % nRuns-by-nKeys indices into the lists
nRuns = size(combinations, 1);
keys = string({blocks.key});

if isempty(options.OutputFolder)
    [folder, name] = fileparts(base.info.source);
    outputBase = string(fullfile(folder, name + "_sweep"));
else
    outputBase = string(options.OutputFolder);
end

% Build and validate every run before running any.
overrides = cell(nRuns, 1);
for r = 1:nRuns
    list = struct('path', {}, 'value', {});
    for k = 1:numel(keys)
        list(end+1) = struct('path', keys(k), 'value', blocks(k).values(combinations(r, k))); %#ok<AGROW>
    end
    overrides{r} = list;
    try
        ldem.io.readCase(casePath, Overrides = list);
    catch err
        error('ldem:sweep:invalidRun', 'Run %d (%s) is not a valid case: %s', ...
            r, describe(list), err.message);
    end
end

summary = table((1:nRuns).', 'VariableNames', {'run'});
for k = 1:numel(keys)
    column = strings(nRuns, 1);
    for r = 1:nRuns
        column(r) = string(overrides{r}(k).value);
    end
    summary.(matlab.lang.makeValidName(replace(keys(k), ".", "_"))) = column;
end
summary.folder = strings(nRuns, 1);
summary.status = repmat("planned", nRuns, 1);
summary.message = strings(nRuns, 1);
summary.seconds = NaN(nRuns, 1);
summary.damagedBars = NaN(nRuns, 1);
summary.brokenBars = NaN(nRuns, 1);
results = cell(nRuns, 1);

if options.DryRun
    summary.folder = outputBase + filesep + compose("run_%03d", (1:nRuns).');
    return
end

for r = 1:nRuns
    runFolder = outputBase + filesep + compose("run_%03d", r);
    summary.folder(r) = runFolder;
    if options.Verbose
        fprintf('Run %d of %d: %s\n', r, nRuns, describe(overrides{r}));
    end
    timer = tic;
    try
        runResults = ldem.run(casePath, Overrides = overrides{r}, OutputFolder = runFolder, ...
            Formats = options.Formats, Verbose = false);
        summary.status(r) = "done";
        summary.damagedBars(r) = nnz(~runResults.final.damage.isUndamaged);
        summary.brokenBars(r) = nnz(~runResults.final.damage.isUnbroken);
        if options.KeepResults
            results{r} = runResults;
        end
    catch err
        summary.status(r) = "failed";
        summary.message(r) = string(strtok(err.message, newline));
        if options.Verbose
            fprintf('  failed: %s\n', summary.message(r));
        end
    end
    summary.seconds(r) = toc(timer);
end

if ~isfolder(outputBase)
    mkdir(outputBase);
end
writetable(summary, fullfile(outputBase, "sweep_summary.csv"));
end

function combinations = combine(blocks, mode)
%COMBINE  Index of the value of every key in each run.
lengths = arrayfun(@(b) numel(b.values), blocks);
if mode == "zip"
    if any(lengths ~= lengths(1))
        error('ldem:sweep:zipLengths', ...
            'In zip mode all the lists must have the same length, got %s.', mat2str(lengths));
    end
    combinations = repmat((1:lengths(1)).', 1, numel(blocks));
else
    ranges = arrayfun(@(n) 1:n, lengths, 'UniformOutput', false);
    grids = cell(1, numel(blocks));
    [grids{:}] = ndgrid(ranges{:});
    combinations = zeros(numel(grids{1}), numel(blocks));
    for k = 1:numel(blocks)
        combinations(:, k) = grids{k}(:);
    end
end
end

function text = describe(list)
parts = strings(1, numel(list));
for k = 1:numel(list)
    parts(k) = string(list(k).path) + " = " + string(list(k).value);
end
text = strjoin(parts, ", ");
end
