function c = readCase(path)
%READCASE  Read a case file (.ldem or .json) and build the simulation inputs.
%
%   c = ldem.io.readCase(path) reads a case file, checks every key against
%   ldem.schema.caseSchema, converts the units to SI and returns the objects
%   that ldem.runSimulation needs. The format is described in
%   docs/source/en/usage.rst and in the template written by
%   ldem.io.writeTemplate. A short example:
%
%       format = 1
%       [mesh]
%       module_size = 3 mm
%       modules     = [5, 2, 2]       # cubic modules along x, y and z
%       [time]
%       step     = auto
%       duration = 40 us
%       [scenario]
%       type = "uniaxial_tension"
%
%   Keys that are missing take the default of ldem.Parameters; the keys
%   scenario.type, mesh.modules and time.duration are required. Every error
%   names the file, the line, the section and the key.
%
%   Relative paths (the random-field file and the output folder) are relative
%   to the folder of the case file.
%
%   Input:
%     path  Path of a .ldem file or of a .json file with the same structure.
%
%   Output:
%     c  Struct with the fields
%          params    Validated ldem.Parameters.
%          scenario  Scenario object with the values of the [scenario] section.
%          options   Struct with OutputFolder and Formats, for runSimulation.
%          info      Struct: source, format, title, authors, controlNodeNames
%                    and nodeNotes (how each "at" position was resolved).
%
%   Errors:
%     ldem:io:fileNotFound        The file does not exist.
%     ldem:io:unknownExtension    The extension is not .ldem or .json.
%     ldem:case:syntax            The text is not valid.
%     ldem:case:unknownKey        A key or section does not exist.
%     ldem:case:missingKey        A required key is missing.
%     ldem:case:badValue          A value has the wrong type or unit.
%     ldem:case:invalidValue      ldem.Parameters rejects a value.
%     ldem:case:inconsistentKey   A key does not fit the chosen type.
%     ldem:params:*               The cross-checks of ldem.Parameters/validate.
%
%   Example:
%       c = ldem.io.readCase("examples/example1_clamped_beam/case.ldem");
%       results = ldem.runSimulation(c.params, Scenario=c.scenario);
%
%   See also ldem.run, ldem.check, ldem.io.writeCase,
%   ldem.io.convertLegacyInput, ldem.Parameters.fromFile.

arguments
    path (1,1) string
end

if ~isfile(path)
    error('ldem:io:fileNotFound', 'Case file "%s" does not exist.', path);
end
absPath = absolutePath(path);
[folder, name, ext] = fileparts(absPath);
ctx = struct('source', string(name) + string(ext), 'folder', string(folder));

text = string(fileread(absPath));
switch lower(string(ext))
    case ".ldem"
        entries = ldem.io.parseCaseText(text, ctx.source);
    case ".json"
        entries = ldem.io.parseCaseJson(text, ctx.source);
    otherwise
        error('ldem:io:unknownExtension', ...
            'Case files must be .ldem or .json, got "%s".', ext);
end

schema = ldem.schema.caseSchema();
reg = ldem.scenarios.registry();
defaults = ldem.Parameters();

checkKnownKeys(entries, schema, ctx);
checkRequired(entries, schema, ctx);
checkFormat(entries, ctx);

values = struct();
origin = struct();
[values, origin] = readSimpleKeys(values, origin, entries, schema, ctx);
[values, origin] = readModules(values, origin, entries, ctx);
readEnum(entries, schema, "material.law", ctx);
readEnum(entries, schema, "damping.type", ctx);
checkScatter(entries, schema, ctx);

% Time step: explicit, or "auto" (also when the key is absent).
[values, origin] = readTimeStep(values, origin, entries, defaults, ctx);

% Cadence of the outputs, in steps.
output = defaults.output;
for row = schema(string({schema.kind}) == "cadence").'
    e = findEntry(entries, sectionOf(row.path), keyOf(row.path));
    if ~isempty(e)
        output.(row.prop) = cadenceToSteps(e.value, values.dt, location(e, ctx));
    end
end
eTracked = findEntry(entries, "monitor.bar", "tracked");
output.trackedBarEvery = double(~isempty(eTracked));

% Scenario.
[scenario, testId] = readScenario(entries, reg, ctx);

% Control nodes.
nodeItems = readNodeItems(entries, ctx);

% Build the parameters, attributing every error to its line.
p = ldem.Parameters();
for field = string(fieldnames(values)).'
    try
        p.(field) = values.(field);
    catch err
        ldem.schema.raise('ldem:case:invalidValue', origin.(field), '%s', firstLine(err.message));
    end
end
p.testId = testId;

nodeNotes = strings(0, 1);
if ~isempty(nodeItems)
    [ids, nodeNotes] = resolveNodes(nodeItems, p, ctx);
    try
        p.controlNodes = ids;
    catch err
        ldem.schema.raise('ldem:case:invalidValue', ctx.source + " [monitor.node]", ...
            '%s', firstLine(err.message));
    end
    names = [nodeItems.name];
    emptyName = names == "";
    names(emptyName) = "node_" + string(ids(emptyName));
else
    names = "node_" + string(p.controlNodes);
end
p.output = output;

try
    p.validate();
catch err
    error(err.identifier, '%s', char(ctx.source + ": " + string(err.message)));
end

c = struct();
c.params = p;
c.scenario = scenario;
c.options = readOutputOptions(entries, output, ctx);
c.info = struct('source', string(absPath), 'format', 1, ...
    'title', stringValue(entries, "", "title", ""), ...
    'authors', stringValue(entries, "", "authors", strings(1, 0)), ...
    'controlNodeNames', names, 'nodeNotes', nodeNotes);
end

% ------------------------------------------------------------------------

function checkKnownKeys(entries, schema, ctx)
paths = string({schema.path});
pathSections = sectionsOf(paths);
known = unique(pathSections);
for e = entries
    if e.section == "scenario" && e.key ~= "type"
        continue     % keys of the scenario class, checked in readScenario
    end
    if any(paths == fullPath(e))
        continue
    end
    if ~any(known == e.section)
        ldem.schema.raise('ldem:case:unknownKey', location(e, ctx), ...
            'The section [%s] does not exist.%s Sections: %s.', e.section, ...
            ldem.schema.suggest(e.section, known(known ~= "")), strjoin([known(known ~= ""), "scenario"], ', '));
    end
    siblings = keysOf(paths(pathSections == e.section));
    ldem.schema.raise('ldem:case:unknownKey', location(e, ctx), ...
        'The key "%s" does not exist in [%s].%s Valid keys: %s.', e.key, e.section, ...
        ldem.schema.suggest(e.key, siblings), strjoin(siblings, ', '));
end
end

function checkRequired(entries, schema, ctx)
for row = schema([schema.required]).'
    if isempty(findEntry(entries, sectionOf(row.path), keyOf(row.path), true))
        ldem.schema.raise('ldem:case:missingKey', ctx.source, ...
            'Missing the required key "%s" in [%s].', keyOf(row.path), sectionOf(row.path));
    end
end
end

function checkFormat(entries, ctx)
e = findEntry(entries, "", "format");
if ~isempty(e) && ~(isnumeric(e.value) && isscalar(e.value) && e.value == 1)
    ldem.schema.raise('ldem:case:unsupportedFormat', location(e, ctx), ...
        'This version of ldem reads format = 1.');
end
end

function [values, origin] = readSimpleKeys(values, origin, entries, schema, ctx)
simple = ["integer" "number" "quantity" "path" "numberlist"];
for row = schema.'
    if row.prop == "" || ~any(row.kind == simple)
        continue
    end
    e = findEntry(entries, sectionOf(row.path), keyOf(row.path));
    if isempty(e)
        continue
    end
    where = location(e, ctx);
    values.(row.prop) = convertValue(e.value, row, where, ctx);
    origin.(row.prop) = where;
end
end

function value = convertValue(v, row, where, ctx)
switch row.kind
    case "integer"
        if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v == fix(v))
            ldem.schema.raise('ldem:case:badValue', where, ...
                'Expected an integer, found %s.', describe(v));
        end
        value = v;
    case "number"
        if ~(isnumeric(v) && isscalar(v) && isfinite(v))
            ldem.schema.raise('ldem:case:badValue', where, ...
                'Expected a number, found %s.', describe(v));
        end
        value = v;
    case "quantity"
        value = ldem.schema.parseQuantity(v, row.dimension, where);
    case "numberlist"
        if ~(isnumeric(v) && ~isempty(v) && all(isfinite(v)))
            ldem.schema.raise('ldem:case:badValue', where, ...
                'Expected a number or a list of numbers, found %s.', describe(v));
        end
        value = reshape(v, 1, []);
    case "path"
        if ~(isstring(v) && isscalar(v))
            ldem.schema.raise('ldem:case:badValue', where, ...
                'Expected a path in quotes, found %s.', describe(v));
        end
        if isempty(regexp(v, '^([A-Za-z]:|[\\/])', 'once')) && strlength(v) > 0
            value = string(fullfile(ctx.folder, v));
        else
            value = v;
        end
end
end

function [values, origin] = readModules(values, origin, entries, ctx)
e = findEntry(entries, "mesh", "modules");
where = location(e, ctx);
v = e.value;
if ~(isnumeric(v) && numel(v) == 3 && all(v >= 1) && all(v == fix(v)))
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected three integers >= 1 (modules along x, y and z), found %s.', describe(v));
end
values.nModules = reshape(v, 1, 3) + 1;     % the legacy M N L count nodes
origin.nModules = where;
end

function word = readEnum(entries, schema, path, ctx)
%READENUM  Value of an "enum" key, or "" if absent. Throws if not allowed.
e = findEntry(entries, sectionOf(path), keyOf(path));
if isempty(e)
    word = "";
    return
end
row = schema(string({schema.path}) == path);
choices = split(string(row.choices), "|").';
word = enumWord(e, choices, ctx);
end

function word = enumWord(e, choices, ctx)
where = location(e, ctx);
if ~(isstring(e.value) && isscalar(e.value))
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected one of %s in quotes, found %s.', strjoin(choices, ', '), describe(e.value));
end
word = lower(strtrim(e.value));
if ~any(choices == word)
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Unknown value "%s".%s Allowed: %s.', e.value, ldem.schema.suggest(word, choices), ...
        strjoin(choices, ', '));
end
end

function checkScatter(entries, schema, ctx)
keys = ["file" "cv" "correlation_length" "seed"];
present = false(size(keys));
for k = 1:numel(keys)
    present(k) = ~isempty(findEntry(entries, "material.scatter", keys(k)));
end
kind = readEnum(entries, schema, "material.scatter.type", ctx);
if kind == ""
    if any(present)
        ldem.schema.raise('ldem:case:missingKey', ctx.source, ...
            'Missing "type" in [material.scatter] (none, file or generated).');
    end
    return
end
switch kind
    case "none"
        allowed = strings(1, 0);
    case "file"
        allowed = "file";
    case "generated"
        allowed = ["cv" "correlation_length" "seed"];
end
for k = find(present)
    if ~any(allowed == keys(k))
        e = findEntry(entries, "material.scatter", keys(k));
        ldem.schema.raise('ldem:case:inconsistentKey', location(e, ctx), ...
            'The key "%s" does not apply when type = "%s".', keys(k), kind);
    end
end
if kind == "file" && ~present(1)
    ldem.schema.raise('ldem:case:missingKey', ctx.source, ...
        'type = "file" needs the key "file" in [material.scatter].');
end
if kind == "generated" && ~present(2)
    ldem.schema.raise('ldem:case:missingKey', ctx.source, ...
        'type = "generated" needs the key "cv" in [material.scatter].');
end
end

function [values, origin] = readTimeStep(values, origin, entries, defaults, ctx)
e = findEntry(entries, "time", "step");
isAuto = isempty(e) || (isstring(e.value) && isscalar(e.value) && lower(strtrim(e.value)) == "auto");
if isAuto
    L = valueOr(values, 'moduleLength', defaults.moduleLength);
    E = valueOr(values, 'youngModulus', defaults.youngModulus);
    rho = valueOr(values, 'density', defaults.density);
    values.dt = 0.9 * (sqrt(3) / 2 * L) / sqrt(E / rho);
    origin.dt = ctx.source + " [time] step";
else
    where = location(e, ctx);
    values.dt = ldem.schema.parseQuantity(e.value, "time", where);
    origin.dt = where;
end
end

function steps = cadenceToSteps(v, dt, where)
%CADENCETOSTEPS  Number of steps for "every = 1000 steps" or "every = 0.1 ms".
if isnumeric(v) && isscalar(v)
    steps = checkSteps(v, where);
    return
end
if ~(isstring(v) && isscalar(v))
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected a number of steps or a time, found %s.', describe(v));
end
tokens = regexp(strtrim(v), '^(\S+)\s*(\S*)$', 'tokens', 'once');
if isempty(tokens)
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected "1000 steps" or a time such as "0.1 ms", found "%s".', v);
end
unit = lower(string(tokens{2}));
if any(unit == ["" "step" "steps"])
    steps = checkSteps(str2double(tokens{1}), where);
    return
end
t = ldem.schema.parseQuantity(v, "time", where);
steps = round(t / dt);
if t > 0 && steps < 1
    ldem.schema.raise('ldem:case:badValue', where, ...
        '%s is shorter than the time step (%g s).', v, dt);
end
if abs(t / dt - steps) > 1e-6 * max(1, steps)
    warning('ldem:case:cadenceNotMultiple', ...
        '%s: %s is not a multiple of the time step (%g s); using %d steps.', where, v, dt, steps);
end
end

function steps = checkSteps(x, where)
if ~(isfinite(x) && x >= 0 && x == fix(x))
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected a non-negative whole number of steps, found %g.', x);
end
steps = x;
end

function [scenario, testId] = readScenario(entries, reg, ctx)
eType = findEntry(entries, "scenario", "type");
choices = [reg.name];
name = enumWord(eType, choices, ctx);
k = find(choices == name, 1);
spec = reg(k);

propNames = string(fieldnames(spec.units)).';
snake = lower(regexprep(propNames, '([a-z0-9])([A-Z])', '$1_$2'));
args = struct();
for e = entries
    if e.section ~= "scenario" || e.key == "type"
        continue
    end
    j = find(snake == e.key, 1);
    where = location(e, ctx);
    if isempty(j)
        ldem.schema.raise('ldem:case:unknownKey', where, ...
            'The scenario "%s" has no key "%s".%s Valid keys: %s.', name, e.key, ...
            ldem.schema.suggest(e.key, snake), strjoin(["type" snake], ', '));
    end
    prop = propNames(j);
    if isfield(spec.keywords, prop) && isstring(e.value) && isscalar(e.value) ...
            && lower(strtrim(e.value)) == spec.keywords.(prop)
        args.(prop) = NaN;
    else
        args.(prop) = ldem.schema.parseQuantity(e.value, spec.units.(prop), where);
    end
end
try
    argList = namedargs2cell(args);
    scenario = feval(spec.className, argList{:});
catch err
    ldem.schema.raise('ldem:case:invalidValue', location(eType, ctx) + " (scenario)", ...
        '%s', firstLine(err.message));
end
testId = spec.testId;
end

function items = readNodeItems(entries, ctx)
%READNODEITEMS  The [[monitor.node]] elements, as a struct array.
items = struct('id', {}, 'at', {}, 'name', {}, 'line', {});
sections = string({entries.section});
indices = [entries.index];
for k = unique(indices(sections == "monitor.node"))
    pick = entries(sections == "monitor.node" & indices == k);
    eId = pick(string({pick.key}) == "id");
    eAt = pick(string({pick.key}) == "at");
    eName = pick(string({pick.key}) == "name");
    where = location(pick(1), ctx);
    if isempty(eId) && isempty(eAt)
        ldem.schema.raise('ldem:case:missingKey', where, ...
            'A [[monitor.node]] needs either "id" or "at".');
    end
    if ~isempty(eId) && ~isempty(eAt)
        ldem.schema.raise('ldem:case:inconsistentKey', where, ...
            'A [[monitor.node]] takes either "id" or "at", not both.');
    end
    item = struct('id', NaN, 'at', zeros(1, 0), 'name', "", 'line', pick(1).line);
    if ~isempty(eId)
        v = eId.value;
        if ~(isnumeric(v) && isscalar(v) && v == fix(v) && v >= 1)
            ldem.schema.raise('ldem:case:badValue', location(eId, ctx), ...
                'Expected a node number (integer >= 1), found %s.', describe(v));
        end
        item.id = v;
    else
        v = eAt.value;
        if ~(isnumeric(v) && numel(v) == 3 && all(isfinite(v)))
            ldem.schema.raise('ldem:case:badValue', location(eAt, ctx), ...
                'Expected three numbers [x, y, z] in modules, found %s.', describe(v));
        end
        item.at = reshape(v, 1, 3);
    end
    if ~isempty(eName)
        item.name = string(eName.value);
    end
    items(end+1) = item; %#ok<AGROW>
end
end

function [ids, notes] = resolveNodes(items, p, ctx)
%RESOLVENODES  Node numbers of the control nodes; "at" positions use the nearest node.
ids = zeros(1, numel(items));
notes = strings(0, 1);
nodes = [];
for k = 1:numel(items)
    if ~isnan(items(k).id)
        ids(k) = items(k).id;
        continue
    end
    if isempty(nodes)
        nodes = ldem.mesh.buildNodes(p.nModules, p.moduleLength) / p.moduleLength;
    end
    [distance, ids(k)] = min(vecnorm(nodes - items(k).at, 2, 2));
    if distance > 1e-6
        notes(end+1, 1) = sprintf('%s:%d: the position [%g, %g, %g] modules is not a node; using node %d at [%g, %g, %g] modules.', ...
            ctx.source, items(k).line, items(k).at, ids(k), nodes(ids(k), :)); %#ok<AGROW>
        warning('ldem:case:nodeApproximated', '%s', notes(end));
    end
end
end

function options = readOutputOptions(entries, output, ctx)
eFolder = findEntry(entries, "output", "folder");
if isempty(eFolder)
    folder = "";
else
    folder = eFolder.value;
    if ~(isstring(folder) && isscalar(folder))
        ldem.schema.raise('ldem:case:badValue', location(eFolder, ctx), ...
            'Expected a folder name in quotes, found %s.', describe(folder));
    end
    if strlength(folder) > 0 && isempty(regexp(folder, '^([A-Za-z]:|[\\/])', 'once'))
        folder = string(fullfile(ctx.folder, folder));
    end
end
formats = strings(1, 0);
for format = ["mat" "ansys" "vtk"]
    e = findEntry(entries, "output", format);
    if isempty(e)
        wanted = format == "mat";
    else
        wanted = e.value;
        if ~(islogical(wanted) && isscalar(wanted))
            ldem.schema.raise('ldem:case:badValue', location(e, ctx), ...
                'Expected true or false, found %s.', describe(wanted));
        end
    end
    if wanted
        formats(end+1) = format; %#ok<AGROW>
    end
end
if any(formats == ["ansys"; "vtk"], 'all') && output.snapshotEvery == 0
    warning('ldem:case:noSnapshots', ...
        ['%s: ansys/vtk files are requested but [output.snapshots] every is 0, ' ...
         'so none will be written.'], ctx.source);
end
options = struct('OutputFolder', folder, 'Formats', formats);
end

% ------------------------------------------------------------------------

function e = findEntry(entries, section, key, anyIndex)
%FINDENTRY  The entry of a key of a plain table (index 0), or [] if absent.
if nargin < 4
    anyIndex = false;
end
if isempty(entries)
    e = [];
    return
end
match = string({entries.section}) == section & string({entries.key}) == key;
if ~anyIndex
    match = match & [entries.index] == 0;
end
k = find(match, 1);
if isempty(k)
    e = [];
else
    e = entries(k);
end
end

function section = sectionOf(path)
path = string(path);
dot = find(char(path) == '.', 1, 'last');
if isempty(dot)
    section = "";
else
    section = extractBefore(path, dot);
end
end

function sections = sectionsOf(paths)
sections = strings(size(paths));
for k = 1:numel(paths)
    sections(k) = sectionOf(paths(k));
end
end

function keys = keysOf(paths)
keys = strings(size(paths));
for k = 1:numel(paths)
    keys(k) = keyOf(paths(k));
end
end

function key = keyOf(path)
path = string(path);
dot = find(char(path) == '.', 1, 'last');
if isempty(dot)
    key = path;
else
    key = extractAfter(path, dot);
end
end

function p = fullPath(e)
if e.section == ""
    p = e.key;
else
    p = e.section + "." + e.key;
end
end

function w = location(e, ctx)
%LOCATION  "file:line [section] key" for the error messages.
w = ctx.source;
if e.line > 0
    w = w + ":" + string(e.line);
end
if e.section ~= ""
    w = w + " [" + e.section + "]";
end
w = w + " " + e.key;
end

function text = describe(v)
%DESCRIBE  Short text of a value for the error messages.
if isstring(v) || ischar(v)
    text = '"' + strjoin(string(v), '", "') + '"';
elseif islogical(v)
    text = strjoin(string(v), ", ");
else
    text = "[" + strjoin(string(v), ", ") + "]";
end
end

function value = valueOr(values, field, fallback)
if isfield(values, field)
    value = values.(field);
else
    value = fallback;
end
end

function value = stringValue(entries, section, key, fallback)
e = findEntry(entries, section, key);
if isempty(e)
    value = fallback;
else
    value = reshape(string(e.value), 1, []);
    if isscalar(fallback) || ischar(fallback)
        value = value(1);
    end
end
end

function line = firstLine(message)
line = strtok(string(message), newline);
end

function p = absolutePath(path)
if isempty(regexp(path, '^([A-Za-z]:|[\\/])', 'once'))
    p = string(fullfile(pwd, path));
else
    p = path;
end
end
