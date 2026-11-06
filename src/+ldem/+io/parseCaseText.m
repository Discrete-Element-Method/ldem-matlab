function entries = parseCaseText(text, source)
%PARSECASETEXT  Parse the text of a case file (.ldem) into a list of entries.
%
%   entries = ldem.io.parseCaseText(text, source) reads the TOML-like syntax
%   of the case files. It only checks the syntax: it does not know which keys
%   exist (see ldem.io.readCase for that).
%
%   Syntax:
%
%       # a comment, from # to the end of the line (not inside quotes)
%       title = "Text in double quotes"
%       [section]                    a table; names may be dotted: [a.b]
%       key = 3.87 GPa               a number with an optional unit
%       key = [5, 5, 50]             a list of numbers or of quoted strings
%       key = true                   true or false
%       [[monitor.node]]             starts the next element of a repeated table
%
%   A value that is neither quoted, a list nor true/false is a number when it
%   is a plain number and otherwise kept as text ("3.87 GPa", "1000 steps",
%   "auto"); ldem.io.readCase interprets it according to the key. Lists must
%   fit in one line. There are no escape sequences in quoted strings.
%
%   Inputs:
%     text    Content of the file.
%     source  Name used in the error messages, usually the file name.
%
%   Output:
%     entries  Struct array with the fields
%                section  Table name ("" before the first table).
%                index    0 for [section]; k for the k-th [[section]].
%                key      Key name.
%                value    double, double row, logical, string or string row.
%                line     Line number in the text.
%
%   Errors:
%     ldem:case:syntax  The text does not follow the syntax above.
%
%   Example:
%       e = ldem.io.parseCaseText("[time]" + newline + "duration = 2.8 ms");
%       e.value      % "2.8 ms"
%
%   See also ldem.io.readCase, ldem.io.parseCaseJson.

arguments
    text (1,1) string
    source (1,1) string = "case"
end

utf8Bom = string(char([239 187 191]));   % a UTF-8 file read with an 8-bit encoding
if startsWith(text, utf8Bom)
    text = extractAfter(text, 3);
elseif startsWith(text, string(char(65279)))
    text = extractAfter(text, 1);
end

lines = splitlines(text);
entries = struct('section', {}, 'index', {}, 'key', {}, 'value', {}, 'line', {});
section = "";
index = 0;
tablesSeen = strings(0, 1);
arrayCount = struct();
keysSeen = strings(0, 1);
namePattern = '^[A-Za-z_]\w*(\.[A-Za-z_]\w*)*$';

for n = 1:numel(lines)
    where = source + ":" + string(n);
    line = strtrim(stripComment(char(lines(n))));
    if isempty(line)
        continue
    end

    if startsWith(line, "[[")
        if ~endsWith(line, "]]")
            ldem.schema.raise('ldem:case:syntax', where, 'The header "%s" must end with ]].', line);
        end
        name = strtrim(string(extractBetween(string(line), 3, strlength(line) - 2)));
        checkName(name, namePattern, where);
        field = regexprep(char(name), '\W', '_');
        if ~isfield(arrayCount, field)
            arrayCount.(field) = 0;
        end
        arrayCount.(field) = arrayCount.(field) + 1;
        section = name;
        index = arrayCount.(field);
        keysSeen = strings(0, 1);
    elseif startsWith(line, "[")
        if ~endsWith(line, "]")
            ldem.schema.raise('ldem:case:syntax', where, 'The header "%s" must end with ].', line);
        end
        name = strtrim(string(extractBetween(string(line), 2, strlength(line) - 1)));
        checkName(name, namePattern, where);
        if any(tablesSeen == name)
            ldem.schema.raise('ldem:case:syntax', where, 'The section [%s] appears twice.', name);
        end
        tablesSeen(end+1, 1) = name; %#ok<AGROW>
        section = name;
        index = 0;
        keysSeen = strings(0, 1);
    else
        eq = find(line == '=', 1);
        if isempty(eq)
            ldem.schema.raise('ldem:case:syntax', where, ...
                'Expected "key = value" or a [section] header, found "%s".', line);
        end
        key = strtrim(string(line(1:eq-1)));
        if isempty(regexp(key, '^[A-Za-z_]\w*$', 'once'))
            ldem.schema.raise('ldem:case:syntax', where, ...
                '"%s" is not a valid key name (letters, digits and _, not starting with a digit).', key);
        end
        if any(keysSeen == key)
            ldem.schema.raise('ldem:case:syntax', where, ...
                'The key "%s" appears twice in the same section.', key);
        end
        keysSeen(end+1, 1) = key; %#ok<AGROW>
        value = parseValue(strtrim(string(line(eq+1:end))), where);
        entries(end+1) = struct('section', section, 'index', index, 'key', key, ...
            'value', {value}, 'line', n); %#ok<AGROW>
    end
end
end

function checkName(name, pattern, where)
if isempty(regexp(name, pattern, 'once'))
    ldem.schema.raise('ldem:case:syntax', where, ...
        '"%s" is not a valid section name (words separated by dots).', name);
end
end

function text = stripComment(text)
%STRIPCOMMENT  Remove a # comment that is not inside double quotes.
inQuote = false;
for k = 1:numel(text)
    if text(k) == '"'
        inQuote = ~inQuote;
    elseif text(k) == '#' && ~inQuote
        text = text(1:k-1);
        return
    end
end
end

function value = parseValue(text, where)
%PARSEVALUE  Interpret the right-hand side of "key = value".
if strlength(text) == 0
    ldem.schema.raise('ldem:case:syntax', where, 'The key has no value.');
end
chars = char(text);
if chars(1) == '"'
    closing = find(chars == '"');
    if numel(closing) < 2
        ldem.schema.raise('ldem:case:syntax', where, 'The quoted text %s is not closed.', text);
    end
    if closing(2) ~= numel(chars)
        ldem.schema.raise('ldem:case:syntax', where, ...
            'Unexpected text after the closing quote: %s.', text);
    end
    value = string(chars(2:closing(2)-1));
elseif chars(1) == '['
    if chars(end) ~= ']'
        ldem.schema.raise('ldem:case:syntax', where, ...
            'The list %s must close with ] on the same line.', text);
    end
    value = parseList(chars(2:end-1), where);
elseif text == "true"
    value = true;
elseif text == "false"
    value = false;
elseif ~isempty(regexp(text, '^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$', 'once'))
    value = str2double(text);
else
    value = text;
end
end

function value = parseList(inner, where)
%PARSELIST  Items of a one-line list, separated by commas outside quotes.
items = strings(0, 1);
current = '';
inQuote = false;
for k = 1:numel(inner)
    c = inner(k);
    if c == '"'
        inQuote = ~inQuote;
        current(end+1) = c; %#ok<AGROW>
    elseif c == ',' && ~inQuote
        items(end+1, 1) = strtrim(string(current)); %#ok<AGROW>
        current = '';
    else
        current(end+1) = c; %#ok<AGROW>
    end
end
if inQuote
    ldem.schema.raise('ldem:case:syntax', where, 'A quoted text in the list is not closed.');
end
last = strtrim(string(current));
if last ~= "" || ~isempty(items)
    items(end+1, 1) = last;
end
if ~isempty(items) && items(end) == "" && numel(items) > 1
    items(end) = [];     % trailing comma
end

if isempty(items) || (isscalar(items) && items == "")
    value = zeros(1, 0);
    return
end

isText = startsWith(items, '"');
if any(isText) && ~all(isText)
    ldem.schema.raise('ldem:case:syntax', where, 'A list cannot mix numbers and quoted texts.');
end
if all(isText)
    if any(~endsWith(items, '"') | strlength(items) < 2)
        ldem.schema.raise('ldem:case:syntax', where, 'A quoted text in the list is not closed.');
    end
    value = reshape(extractBetween(items, 2, strlength(items) - 1), 1, []);
else
    numbers = str2double(items);
    bad = find(isnan(numbers), 1);
    if ~isempty(bad)
        ldem.schema.raise('ldem:case:syntax', where, ...
            '"%s" in the list is not a number.', items(bad));
    end
    value = reshape(numbers, 1, []);
end
end
