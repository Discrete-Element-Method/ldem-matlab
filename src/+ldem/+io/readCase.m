function c = readCase(path, options)
%READCASE  Read a case file (.ldem or .json) and build the simulation inputs.
%
%   c = ldem.io.readCase(path) reads a case file, checks every key against
%   ldem.schema.caseSchema, converts the units to SI and returns the objects
%   that ldem.runSimulation needs. The format is described in
%   docs/source/usage.rst and in the template written by
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
%   A case file may inherit from others with extends = "base.ldem" (or a list):
%   its keys replace the inherited ones, a repeated table ([[support]], [[load]],
%   [[monitor.node]], [[sweep]]) replaces the whole inherited list, and when the
%   scenario, scatter or damping type changes the keys of the old type are dropped.
%   Relative paths are relative to the file that contains them.
%
%   Input:
%     path  Path of a .ldem file or of a .json file with the same structure.
%
%   Name-value options:
%     Overrides  Struct array with the fields path ("section.key") and value that
%                replace keys of the file; ldem.sweep uses it to vary a key.
%
%   Output:
%     c  Struct with the fields
%          params    Validated ldem.Parameters.
%          scenario  Scenario object with the values of the [scenario] section.
%          options   Struct with OutputFolder and Formats, for runSimulation.
%          info      Struct: source, format, title, authors, controlNodeNames, nodeNotes, parents, sweep, sweepMode.
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
    options.Overrides = []
end

if ~isfile(path)
    error('ldem:io:fileNotFound', 'Case file "%s" does not exist.', path);
end
absPath = absolutePath(path);
[folder, name, ext] = fileparts(absPath);
ctx = struct('source', string(name) + string(ext), 'folder', string(folder));

[entries, parents] = loadEntries(absPath, strings(0, 1));
entries = applyOverrides(entries, options.Overrides, ctx);

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
[values, origin] = readEnumKeys(values, origin, entries, schema, ctx);
checkDampingKeys(entries, values, ctx);
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

[sweepBlocks, sweepMode] = readSweep(entries, schema, ctx);

c = struct();
c.params = p;
c.scenario = scenario;
c.options = readOutputOptions(entries, output, ctx);
c.info = struct('source', string(absPath), 'format', 1, ...
    'title', stringValue(entries, "", "title", ""), ...
    'authors', stringValue(entries, "", "authors", strings(1, 0)), ...
    'controlNodeNames', names, 'nodeNotes', nodeNotes, ...
    'parents', parents, 'sweep', sweepBlocks, 'sweepMode', sweepMode);
end

% ------------------------------------------------------------------------

function [entries, parents] = loadEntries(absPath, chain)
%LOADENTRIES  Entries of a case file with the ones it inherits through "extends".
%   Every entry also carries the file it was written in (file) and its folder
%   (folder), for the error messages and for relative paths.
[folder, name, ext] = fileparts(absPath);
source = string(name) + string(ext);
text = string(fileread(absPath));
switch lower(string(ext))
    case ".ldem"
        entries = ldem.io.parseCaseText(text, source);
    case ".json"
        entries = ldem.io.parseCaseJson(text, source);
    otherwise
        error('ldem:io:unknownExtension', ...
            'Case files must be .ldem or .json, got "%s".', ext);
end
if isempty(entries)
    entries = struct('section', {}, 'index', {}, 'key', {}, 'value', {}, 'line', {}, ...
        'file', {}, 'folder', {});
else
    for k = 1:numel(entries)
        entries(k).file = source;
        entries(k).folder = string(folder);
    end
end

parents = strings(0, 1);
eExtends = findEntry(entries, "", "extends");
if isempty(eExtends)
    return
end
entries(string({entries.section}) == "" & string({entries.key}) == "extends") = [];

where = source + ":" + string(eExtends.line) + " extends";
if ~(isstring(eExtends.value) && ~isempty(eExtends.value))
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected the path of a case file or a list of them, in quotes.');
end
chain = [chain; string(absPath)];
merged = entries([]);
for relative = reshape(eExtends.value, 1, [])
    parentPath = relative;
    if isempty(regexp(parentPath, '^([A-Za-z]:|[\\/])', 'once'))
        parentPath = joinPath(folder, parentPath);
    end
    if ~isfile(parentPath)
        ldem.schema.raise('ldem:io:fileNotFound', where, ...
            'The case file "%s" that this one extends does not exist.', relative);
    end
    parentPath = absolutePath(parentPath);
    if any(lower(chain) == lower(parentPath))
        ldem.schema.raise('ldem:case:extendsLoop', where, ...
            'Case files extend each other in a loop: %s.', strjoin([chain; parentPath], ' -> '));
    end
    [parentEntries, grandParents] = loadEntries(parentPath, chain);
    merged = mergeEntries(merged, parentEntries);
    parents = [parents; grandParents; parentPath]; %#ok<AGROW>
end
entries = mergeEntries(merged, entries);
parents = unique(parents, 'stable');
end

function merged = mergeEntries(base, over)
%MERGEENTRIES  Entries of "over" replace those of "base" that set the same thing.
%   A key replaces the same key; a repeated table ([[support]], [[load]],
%   [[monitor.node]], [[sweep]]) replaces the whole list of that table; and when
%   the type of the scenario, of the scatter or of the damping model changes, the
%   keys of the old type that are not set again are dropped.
if isempty(base)
    merged = over;
    return
end
baseSections = string({base.section});
baseKeys = string({base.key});
baseIndices = [base.index];
overSections = string({over.section});
overKeys = string({over.key});
overIndices = [over.index];

drop = false(size(base));
for k = 1:numel(base)
    if baseIndices(k) == 0
        drop(k) = any(overSections == baseSections(k) & overKeys == baseKeys(k) & overIndices == 0);
    else
        drop(k) = any(overSections == baseSections(k) & overIndices > 0);
    end
end
for section = ["scenario" "material.scatter" "damping"]
    newType = typeOf(over, section);
    oldType = typeOf(base, section);
    if newType ~= "" && oldType ~= "" && newType ~= oldType
        drop = drop | (baseSections == section & baseKeys ~= "type");
    end
end
merged = [base(~drop), over];
end

function word = typeOf(entries, section)
e = findEntry(entries, section, "type");
if isempty(e) || ~isstring(e.value) || ~isscalar(e.value)
    word = "";
else
    word = lower(strtrim(e.value));
end
end

function entries = applyOverrides(entries, overrides, ctx)
%APPLYOVERRIDES  Set keys from outside the file (a sweep): struct array with path and value.
if isempty(overrides)
    return
end
schema = ldem.schema.caseSchema();
paths = string({schema.path});
for k = 1:numel(overrides)
    target = string(overrides(k).path);
    section = sectionOf(target);
    key = keyOf(target);
    if ~any(paths == target) && section ~= "scenario"
        ldem.schema.raise('ldem:sweep:unknownKey', "sweep", ...
            'The key "%s" does not exist.%s', target, ldem.schema.suggest(target, paths));
    end
    if any(section == arrayTables())
        ldem.schema.raise('ldem:sweep:unsupportedKey', "sweep", ...
            'The key "%s" belongs to a repeated table and cannot be swept.', target);
    end
    if ~isempty(entries)
        entries(string({entries.section}) == section & string({entries.key}) == key ...
            & [entries.index] == 0) = [];
    end
    entry = struct('section', section, 'index', 0, 'key', key, 'value', {overrides(k).value}, ...
        'line', 0, 'file', "sweep", 'folder', ctx.folder);
    if isempty(entries)
        entries = entry;
    else
        entries = [entries, entry]; %#ok<AGROW>
    end
end
end

function tables = arrayTables()
tables = ["monitor.node" "support" "load" "sweep"];
end

function [blocks, mode] = readSweep(entries, schema, ctx)
%READSWEEP  The [[sweep]] blocks and sweep_mode: what ldem.sweep varies.
blocks = struct('key', {}, 'values', {});
paths = string({schema.path});
kinds = string({schema.kind});
scalarKinds = ["integer" "number" "quantity" "string" "path" "enum" "stepOrAuto" "cadence"];
sections = string({entries.section});
indices = [entries.index];
for k = unique(indices(sections == "sweep"))
    block = entries(sections == "sweep" & indices == k);
    if k == 0
        ldem.schema.raise('ldem:case:syntax', location(block(1), ctx), ...
            'Write [[sweep]] (double brackets): there can be several.');
    end
    eKey = pickKey(block, "key");
    eValues = pickKey(block, "values");
    if isempty(eKey) || isempty(eValues)
        ldem.schema.raise('ldem:case:missingKey', location(block(1), ctx), ...
            'A [[sweep]] needs "key" (what to vary) and "values" (a list).');
    end
    if ~(isstring(eKey.value) && isscalar(eKey.value))
        ldem.schema.raise('ldem:case:badValue', location(eKey, ctx), ...
            'Expected the name of a key in quotes, such as "material.fracture_energy".');
    end
    target = eKey.value;
    j = find(paths == target, 1);
    isScenarioKey = sectionOf(target) == "scenario" && keyOf(target) ~= "type";
    if isempty(j) && ~isScenarioKey
        ldem.schema.raise('ldem:case:badValue', location(eKey, ctx), ...
            '"%s" is not a key of the case file.%s', target, ldem.schema.suggest(target, paths));
    end
    if ~isScenarioKey && (~any(kinds(j) == scalarKinds) || any(sectionOf(target) == arrayTables()))
        ldem.schema.raise('ldem:case:badValue', location(eKey, ctx), ...
            '"%s" cannot be swept: only keys with a single value and outside repeated tables.', target);
    end
    v = eValues.value;
    if isempty(v) || ~((isnumeric(v) || isstring(v)) && isvector(v))
        ldem.schema.raise('ldem:case:badValue', location(eValues, ctx), ...
            'Expected a non-empty list of numbers or of quoted texts such as ["0.1 N/m", "0.5 N/m"].');
    end
    items = num2cell(reshape(v, 1, []));
    blocks(end+1) = struct('key', target, 'values', {items}); %#ok<AGROW>
end
mode = "product";
eMode = findEntry(entries, "", "sweep_mode");
if ~isempty(eMode)
    mode = enumWord(eMode, ["product" "zip"], ctx);
end
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
    entryCtx = ctx;
    entryCtx.folder = e.folder;
    values.(row.prop) = convertValue(e.value, row, where, entryCtx);
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
            value = joinPath(ctx.folder, v);   % ctx.folder is the folder of the entry's file
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

function [values, origin] = readEnumKeys(values, origin, entries, schema, ctx)
%READENUMKEYS  Enum keys that set a Parameters property (the law, the damping model).
for row = schema(string({schema.kind}) == "enum" & string({schema.prop}) ~= "").'
    word = readEnum(entries, schema, row.path, ctx);
    if word ~= ""
        values.(row.prop) = word;
        origin.(row.prop) = location(findEntry(entries, sectionOf(row.path), keyOf(row.path)), ctx);
    end
end
end

function checkDampingKeys(entries, values, ctx)
%CHECKDAMPINGKEYS  Keys of [damping] that the chosen model does not use are an error.
reg = ldem.solver.dampingRegistry();
model = "mass_proportional";
if isfield(values, 'dampingModel')
    model = values.dampingModel;
end
spec = reg([reg.name] == model);
for key = ["initial" "final" "switch_time"]
    e = findEntry(entries, "damping", key);
    if ~isempty(e) && ~any(spec.keys == key)
        ldem.schema.raise('ldem:case:inconsistentKey', location(e, ctx), ...
            'The key "%s" does not apply when type = "%s".', key, model);
    end
end
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
if name == "custom"
    scenario = readBlocks(entries, ctx);
else
    for e = entries
        if any(e.section == ["support" "load"])
            ldem.schema.raise('ldem:case:inconsistentKey', location(e, ctx), ...
                '[[%s]] blocks only apply when [scenario] type = "custom".', e.section);
        end
    end
end
testId = spec.testId;
end

function scenario = readBlocks(entries, ctx)
%READBLOCKS  Build the declarative scenario from the [[support]] and [[load]] blocks.
supports = ldem.scenarios.Declarative.emptySupports();
loads = ldem.scenarios.Declarative.emptyLoads();
sections = string({entries.section});
indices = [entries.index];
for kind = ["support" "load"]
    for k = unique(indices(sections == kind))
        block = entries(sections == kind & indices == k);
        if k == 0
            ldem.schema.raise('ldem:case:syntax', location(block(1), ctx), ...
                'Write [[%s]] (double brackets): there can be several.', kind);
        end
        if kind == "support"
            supports(end+1) = readSupport(block, ctx); %#ok<AGROW>
        else
            loads(end+1) = readLoad(block, ctx); %#ok<AGROW>
        end
    end
end
try
    scenario = ldem.scenarios.Declarative(supports = supports, loads = loads);
catch err
    ldem.schema.raise('ldem:case:invalidValue', ctx.source + " [scenario]", '%s', firstLine(err.message));
end
end

function block = readSupport(entries, ctx)
selector = readSelector(entries, ctx);
eFix = pickKey(entries, "fix");
if isempty(eFix)
    ldem.schema.raise('ldem:case:missingKey', location(entries(1), ctx), ...
        'A [[support]] needs "fix": the directions to hold, for example ["x", "y"].');
end
try
    block = ldem.scenarios.Declarative.makeSupport(selector, reshape(string(eFix.value), 1, []), ...
        name = textOf(entries, "name", ctx), reaction = boolOf(entries, "reaction", ctx));
catch err
    ldem.schema.raise('ldem:case:badValue', location(eFix, ctx), '%s', firstLine(err.message));
end
end

function block = readLoad(entries, ctx)
selector = readSelector(entries, ctx);
for key = ["direction" "type" "time_function"]
    if isempty(pickKey(entries, key))
        ldem.schema.raise('ldem:case:missingKey', location(entries(1), ctx), ...
            'A [[load]] needs "%s".', key);
    end
end
direction = enumWord(pickKey(entries, "direction"), ["x" "y" "z"], ctx);
type = enumWord(pickKey(entries, "type"), ["force" "displacement"], ctx);
kind = enumWord(pickKey(entries, "time_function"), ["constant" "linear" "ramp" "table"], ctx);

if type == "force"
    valueDimension = "force";
    rateDimension = "forcerate";
else
    valueDimension = "length";
    rateDimension = "velocity";
end
needs = struct('constant', "value", 'linear', "rate", 'ramp', ["rate" "until"], ...
    'table', ["times" "values"]);
needed = needs.(kind);
for key = ["value" "rate" "until" "times" "values"]
    e = pickKey(entries, key);
    if ~isempty(e) && ~any(needed == key)
        ldem.schema.raise('ldem:case:inconsistentKey', location(e, ctx), ...
            'The key "%s" does not apply when time_function = "%s".', key, kind);
    end
    if isempty(e) && any(needed == key)
        ldem.schema.raise('ldem:case:missingKey', location(entries(1), ctx), ...
            'time_function = "%s" needs the key "%s".', kind, key);
    end
end
args = struct();
for key = needed
    e = pickKey(entries, key);
    where = location(e, ctx);
    switch key
        case "value"
            args.value = ldem.schema.parseQuantity(e.value, valueDimension, where);
        case "rate"
            args.rate = ldem.schema.parseQuantity(e.value, rateDimension, where);
        case "until"
            args.until = ldem.schema.parseQuantity(e.value, "time", where);
        otherwise
            if ~(isnumeric(e.value) && ~isempty(e.value))
                ldem.schema.raise('ldem:case:badValue', where, ...
                    'Expected a list of numbers (SI units), found %s.', describe(e.value));
            end
            args.(key) = reshape(e.value, 1, []);
    end
end
try
    argList = namedargs2cell(args);
    fn = ldem.scenarios.Declarative.makeFunction(kind, argList{:});
catch err
    ldem.schema.raise('ldem:case:badValue', location(pickKey(entries, "time_function"), ctx), ...
        '%s', firstLine(err.message));
end
block = ldem.scenarios.Declarative.makeLoad(selector, direction, type, fn, ...
    name = textOf(entries, "name", ctx), reaction = boolOf(entries, "reaction", ctx));
end

function selector = readSelector(entries, ctx)
args = struct();
e = pickKey(entries, "nodes");
if ~isempty(e)
    args.nodes = enumWord(e, ["all" "centre" "grid"], ctx);
end
e = pickKey(entries, "ids");
if ~isempty(e)
    if ~(isnumeric(e.value) && ~isempty(e.value) && all(e.value >= 1) && all(e.value == fix(e.value)))
        ldem.schema.raise('ldem:case:badValue', location(e, ctx), ...
            'Expected node numbers (integers >= 1), found %s.', describe(e.value));
    end
    args.ids = reshape(e.value, 1, []);
end
for axis = ["x" "y" "z"]
    e = pickKey(entries, axis);
    if ~isempty(e)
        ldem.scenarios.parseCoordinate(e.value, location(e, ctx));    % checks the form
        args.(axis) = e.value;
    end
end
argList = namedargs2cell(args);
selector = ldem.scenarios.Declarative.makeSelector(argList{:});
end

function e = pickKey(entries, key)
%PICKKEY  The entry of a key inside one block, or [].
k = find(string({entries.key}) == key, 1);
if isempty(k)
    e = [];
else
    e = entries(k);
end
end

function text = textOf(entries, key, ctx)
e = pickKey(entries, key);
if isempty(e)
    text = "";
elseif isstring(e.value) && isscalar(e.value)
    text = e.value;
else
    ldem.schema.raise('ldem:case:badValue', location(e, ctx), ...
        'Expected a text in quotes, found %s.', describe(e.value));
end
end

function flag = boolOf(entries, key, ctx)
e = pickKey(entries, key);
if isempty(e)
    flag = false;
elseif islogical(e.value) && isscalar(e.value)
    flag = e.value;
else
    ldem.schema.raise('ldem:case:badValue', location(e, ctx), ...
        'Expected true or false, found %s.', describe(e.value));
end
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
        folder = joinPath(eFolder.folder, folder);
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
if isfield(e, 'file') && e.file ~= ""
    w = e.file;
end
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

function p = joinPath(folder, relative)
%JOINPATH  Folder plus a relative path, with the "." and ".." parts removed.
full = strrep(string(fullfile(folder, relative)), '/', filesep);
parts = split(full, filesep).';
kept = strings(1, 0);
for part = parts
    if part == "."
        continue
    elseif part == ".." && ~isempty(kept) && kept(end) ~= "" && ~endsWith(kept(end), ":")
        kept(end) = [];
    else
        kept(end+1) = part; %#ok<AGROW>
    end
end
p = strjoin(kept, filesep);
end

function p = absolutePath(path)
if isempty(regexp(path, '^([A-Za-z]:|[\\/])', 'once'))
    p = string(fullfile(pwd, path));
else
    p = path;
end
end
