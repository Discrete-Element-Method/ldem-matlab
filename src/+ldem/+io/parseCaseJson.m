function entries = parseCaseJson(text, source)
%PARSECASEJSON  Parse a case file written in JSON into a list of entries.
%
%   entries = ldem.io.parseCaseJson(text, source) gives the same list as
%   ldem.io.parseCaseText for the same case, so ldem.io.readCase treats both
%   formats alike. The JSON has one object per section and the values that
%   carry a unit are strings:
%
%       {"format": 1, "mesh": {"module_size": "1 mm", "modules": [5, 5, 50]}}
%
%   A repeated table such as [[monitor.node]] is an array of objects. JSON has
%   no comments; use the .ldem format for files written by hand.
%
%   Inputs:
%     text    Content of the file.
%     source  Name used in the error messages.
%
%   Output:
%     entries  Struct array, see ldem.io.parseCaseText (line is 0).
%
%   Errors:
%     ldem:case:syntax  The text is not valid JSON or has an unsupported shape.
%
%   See also ldem.io.readCase, ldem.io.parseCaseText.

arguments
    text (1,1) string
    source (1,1) string = "case"
end

try
    data = jsondecode(text);
catch err
    ldem.schema.raise('ldem:case:syntax', source, 'Invalid JSON: %s', err.message);
end
if ~isstruct(data) || ~isscalar(data)
    ldem.schema.raise('ldem:case:syntax', source, 'The JSON must be an object at the top level.');
end

entries = struct('section', {}, 'index', {}, 'key', {}, 'value', {}, 'line', {});
entries = addObject(entries, data, "", 0, source);
end

function entries = addObject(entries, object, section, index, source)
names = string(fieldnames(object)).';
for name = names
    value = object.(name);
    childSection = joinSection(section, name);
    if isstruct(value) && isscalar(value)
        entries = addObject(entries, value, childSection, 0, source);
    elseif isstruct(value) || (iscell(value) && ~isempty(value) && all(cellfun(@isstruct, value)))
        if iscell(value)
            items = value;
        else
            items = num2cell(value);
        end
        for k = 1:numel(items)
            entries = addObject(entries, items{k}, childSection, k, source);
        end
    else
        entries(end+1) = struct('section', section, 'index', index, 'key', name, ...
            'value', {leafValue(value, section, name, source)}, 'line', 0); %#ok<AGROW>
    end
end
end

function value = leafValue(raw, section, name, source)
if ischar(raw)
    value = string(raw);
elseif iscell(raw) && all(cellfun(@ischar, raw))
    value = reshape(string(raw), 1, []);
elseif isnumeric(raw) || islogical(raw)
    value = reshape(raw, 1, []);
    if isscalar(value)
        value = value(1);
    end
else
    ldem.schema.raise('ldem:case:syntax', source, ...
        'The value of "%s" in section "%s" has an unsupported type.', name, section);
end
end

function name = joinSection(section, name)
if section ~= ""
    name = section + "." + name;
end
end
