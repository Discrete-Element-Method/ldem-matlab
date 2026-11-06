function text = writeCase(path, params, scenario, options)
%WRITECASE  Write the case file (.ldem) of a parameter set and a scenario.
%
%   text = ldem.io.writeCase(path, params, scenario) writes a complete,
%   commented case file that ldem.io.readCase reads back into the same
%   parameters and scenario, and returns its text. Every key is written, with
%   units, so the file documents the model by itself. Use it to save what was
%   run, to build a template, and (through ldem.io.convertLegacyInput) to
%   convert a DATA0.DAT.
%
%   text = ldem.io.writeCase("", params, scenario) only returns the text.
%
%   Inputs:
%     path      Path of the file to create ("" to only return the text).
%     params    ldem.Parameters.
%     scenario  Scenario object (default: the one of params.testId).
%
%   Name-value options:
%     Title             Text of the "title" key.
%     Authors           String array for the "authors" key.
%     Header            Extra comment lines at the top (without the #).
%     OutputFolder      Value of output.folder (default "output").
%     Formats           Files to enable in [output]: "mat", "ansys", "vtk"
%                       (default all; ansys and vtk are switched off when
%                       snapshots are never taken).
%     ControlNodeNames  One label per control node (default "node_<number>").
%     Comments          false to omit the explanatory comments (default true).
%
%   Output:
%     text  The content of the file, a string scalar.
%
%   Errors:
%     ldem:io:unregisteredScenario  The scenario class is not in
%                                   ldem.scenarios.registry.
%     ldem:io:cannotOpenFile        The file cannot be created.
%
%   Example:
%       p = ldem.Parameters(testId=101, nModules=[6 3 3]);
%       ldem.io.writeCase("tension.ldem", p, ldem.scenarios.UniaxialTension());
%
%   See also ldem.io.readCase, ldem.io.convertLegacyInput,
%   ldem.io.writeTemplate.

arguments
    path (1,1) string
    params (1,1) ldem.Parameters
    scenario = []
    options.Title (1,1) string = ""
    options.Authors (1,:) string = string.empty
    options.Header (1,:) string = string.empty
    options.OutputFolder (1,1) string = "output"
    options.Formats (1,:) string {mustBeMember(options.Formats, ["mat" "ansys" "vtk"])} = ["mat" "ansys" "vtk"]
    options.ControlNodeNames (1,:) string = string.empty
    options.Comments (1,1) logical = true
end

if isempty(scenario)
    scenario = ldem.scenarios.fromTestId(params.testId);
end
reg = ldem.scenarios.registry();
k = find([reg.className] == string(class(scenario)), 1);
if isempty(k)
    error('ldem:io:unregisteredScenario', ...
        'The scenario class %s is not in ldem.scenarios.registry.', class(scenario));
end
spec = reg(k);

schema = ldem.schema.caseSchema();
paths = string({schema.path});
withComments = options.Comments;
doc = @(key) docText(schema(paths == key));

lines = strings(0, 1);
for h = options.Header
    lines(end+1, 1) = "# " + h; %#ok<AGROW>
end
if options.Title ~= ""
    lines(end+1, 1) = "# " + options.Title;
end
if ~isempty(lines)
    lines(end+1, 1) = "";
end
rows = {"format", "1", doc("format")};
if options.Title ~= ""
    rows(end+1, :) = {"title", quote(options.Title), doc("title")};
end
if ~isempty(options.Authors)
    rows(end+1, :) = {"authors", "[" + strjoin(quote(options.Authors), ", ") + "]", doc("authors")};
end
lines = [lines; block(rows, withComments); ""];

q = @ldem.schema.formatQuantity;
num = @ldem.schema.shortestText;

% [mesh]
rows = {
    "module_size", q(params.moduleLength, "length"), doc("mesh.module_size")
    "modules", listText(params.nModules - 1), doc("mesh.modules")
    "perturbation", num(params.meshPerturbation), doc("mesh.perturbation")
    "seed", num(params.seed), doc("mesh.seed")};
lines = [lines; section("mesh", rows, withComments)];

% [material]
rows = {
    "law", quote("bilinear"), doc("material.law")
    "young_modulus", q(params.youngModulus, "pressure"), doc("material.young_modulus")
    "poisson_ratio", num(params.poissonRatio), doc("material.poisson_ratio")
    "density", q(params.density, "density"), doc("material.density")
    "fracture_energy", q(params.fractureEnergy, "toughness"), doc("material.fracture_energy")
    "critical_distance", q(params.criticalDistance, "length"), doc("material.critical_distance")
    "failure_area_factor", num(params.failureAreaFactor), doc("material.failure_area_factor")};
lines = [lines; section("material", rows, withComments)];

% [material.scatter]
if strlength(params.randomFieldFile) > 0
    rows = {
        "type", quote("file"), doc("material.scatter.type")
        "file", quote(relativeTo(params.randomFieldFile, path)), doc("material.scatter.file")};
elseif params.randomFieldCv > 0
    rows = {
        "type", quote("generated"), doc("material.scatter.type")
        "cv", num(params.randomFieldCv), doc("material.scatter.cv")
        "correlation_length", listOrScalar(params.randomFieldCorrelationLength), ...
            doc("material.scatter.correlation_length")
        "seed", num(params.randomFieldSeed), doc("material.scatter.seed")};
else
    rows = {"type", quote("none"), doc("material.scatter.type")};
end
lines = [lines; section("material.scatter", rows, withComments)];

% [time]
rows = {
    "step", q(params.dt, "time"), doc("time.step")
    "duration", q(params.totalTime, "time"), doc("time.duration")};
lines = [lines; section("time", rows, withComments)];

% [damping]
rows = {
    "type", quote("mass_proportional"), doc("damping.type")
    "initial", q(params.dampingInitial, "rate"), doc("damping.initial")
    "final", q(params.dampingFinal, "rate"), doc("damping.final")
    "switch_time", q(params.dampingSwitchTime, "time"), doc("damping.switch_time")
    "constitutive", q(params.constitutiveDamping, "time"), doc("damping.constitutive")};
lines = [lines; section("damping", rows, withComments)];

% [scenario]
rows = {"type", quote(spec.name), doc("scenario.type")};
for prop = string(fieldnames(spec.units)).'
    key = lower(regexprep(prop, '([a-z0-9])([A-Z])', '$1_$2'));
    value = scenario.(prop);
    if isnan(value) && isfield(spec.keywords, prop)
        valueText = quote(spec.keywords.(prop));
    else
        valueText = q(value, spec.units.(prop));
    end
    rows(end+1, :) = {key, valueText, "Property " + prop + " of " + string(class(scenario)) + "."}; %#ok<AGROW>
end
lines = [lines; section("scenario", rows, withComments)];

% [[monitor.node]]
names = options.ControlNodeNames;
if numel(names) ~= numel(params.controlNodes)
    names = "node_" + string(params.controlNodes);
end
nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength) / params.moduleLength;
for j = 1:numel(params.controlNodes)
    id = params.controlNodes(j);
    where = "";
    if id <= size(nodes, 1)
        where = "(x, y, z) = (" + strjoin(string(nodes(id, :)), ", ") + ") modules";
    end
    rows = {
        "name", quote(names(j)), doc("monitor.node.name")
        "id", num(id), where};
    lines = [lines; "[[monitor.node]]"; block(rows, withComments); ""]; %#ok<AGROW>
end

% [monitor.bar]
if params.output.trackedBarEvery > 0
    rows = {"tracked", num(params.trackedBar), doc("monitor.bar.tracked")};
    lines = [lines; section("monitor.bar", rows, withComments)];
elseif withComments
    lines = [lines; "[monitor.bar]"; ...
        "# tracked = " + num(params.trackedBar) + "    # uncomment to store the strain history of this bar"; ""];
end

% [output]
formats = options.Formats;
if params.output.snapshotEvery == 0
    formats = setdiff(formats, ["ansys" "vtk"], 'stable');
end
rows = {
    "folder", quote(options.OutputFolder), doc("output.folder")
    "mat", boolText(any(formats == "mat")), doc("output.mat")
    "ansys", boolText(any(formats == "ansys")), doc("output.ansys")
    "vtk", boolText(any(formats == "vtk")), doc("output.vtk")};
lines = [lines; section("output", rows, withComments)];
lines = [lines; section("output.snapshots", ...
    {"every", stepsText(params.output.snapshotEvery), doc("output.snapshots.every")}, withComments)];
lines = [lines; section("output.control_nodes", ...
    {"every", stepsText(params.output.controlNodesEvery), doc("output.control_nodes.every")}, withComments)];
lines = [lines; section("output.energy", ...
    {"every", stepsText(params.output.energyEvery), doc("output.energy.every")}, withComments)];

text = strjoin(lines, newline);
text = regexprep(text, '\n+$', '') + newline;

if strlength(path) > 0
    folder = fileparts(path);
    if strlength(folder) > 0 && ~isfolder(folder)
        mkdir(folder);
    end
    fid = fopen(path, 'w', 'n', 'UTF-8');
    if fid == -1
        error('ldem:io:cannotOpenFile', 'Cannot create "%s".', path);
    end
    fprintf(fid, '%s', text);
    fclose(fid);
end
end

function note = docText(row)
%DOCTEXT  Comment of a key: its description and the legacy variable it replaces.
note = string(row.doc);
if row.legacy ~= ""
    note = note + " Legacy: " + string(row.legacy) + ".";
end
end

function lines = section(name, rows, withComments)
lines = ["[" + name + "]"; block(rows, withComments); ""];
end

function lines = block(rows, withComments)
%BLOCK  Aligned "key = value  # comment" lines.
n = size(rows, 1);
keyWidth = max(strlength(string(rows(:, 1))));
texts = strings(n, 1);
for r = 1:n
    texts(r) = string(sprintf('%-*s', keyWidth, rows{r, 1})) + " = " + string(rows{r, 2});
end
width = max(strlength(texts));
lines = texts;
if withComments
    for r = 1:n
        comment = string(rows{r, 3});
        if comment ~= ""
            lines(r) = string(sprintf('%-*s', width, texts(r))) + "   # " + comment;
        end
    end
end
end

function t = quote(s)
if any(contains(s, '"'))
    error('ldem:io:badText', 'Texts written to a case file cannot contain double quotes: %s', s(1));
end
t = '"' + s + '"';
end

function t = listText(v)
parts = strings(size(v));
for k = 1:numel(v)
    parts(k) = ldem.schema.shortestText(v(k));
end
t = "[" + strjoin(parts, ", ") + "]";
end

function t = listOrScalar(v)
if isscalar(v)
    t = ldem.schema.shortestText(v);
else
    t = listText(v);
end
end

function t = boolText(flag)
if flag
    t = "true";
else
    t = "false";
end
end

function t = stepsText(n)
if n == 0
    t = "0";
elseif n == 1
    t = "1 step";
else
    t = string(n) + " steps";
end
end

function t = relativeTo(file, casePath)
%RELATIVETO  Path of a file relative to the folder of the case file, with / separators.
file = strrep(string(file), '\', '/');
folder = strrep(string(fileparts(absoluteOf(casePath))), '\', '/');
if folder == "" || isempty(regexp(file, '^([A-Za-z]:|/)', 'once'))
    t = file;      % no case folder to compare with, or already relative
    return
end
fileParts = split(file, "/");
folderParts = split(folder, "/");
n = 0;
while n < min(numel(fileParts) - 1, numel(folderParts)) && ...
        strcmpi(fileParts(n + 1), folderParts(n + 1))
    n = n + 1;
end
if n == 0
    t = file;      % another drive
    return
end
up = repmat("..", 1, numel(folderParts) - n);
t = strjoin([up, fileParts(n + 1:end).'], "/");
end

function p = absoluteOf(path)
path = string(path);
if path == ""
    p = "";
elseif isempty(regexp(path, '^([A-Za-z]:|[\\/])', 'once'))
    p = string(fullfile(pwd, path));
else
    p = path;
end
end
