function range = parseCoordinate(value, where)
%PARSECOORDINATE  Read a coordinate or a range of coordinates, in modules.
%
%   range = ldem.scenarios.parseCoordinate(value) converts what a case file
%   gives for the key x, y or z of a [[support]] or [[load]] block into the
%   range of positions it selects. The value is
%
%     * a number, in modules: 0.5 (a plane of nodes);
%     * a text with a number: "0.5" or "0.5 modules";
%     * a text with a reference to the prism, "min", "max" or "mid", and an
%       optional offset: "max - 0.5", "mid", "min + 1" (min is 0, max is the
%       length of the prism along that axis in modules, mid is half of it);
%     * a pair of any of the above, [lo, hi], for the nodes in between (all
%       numbers, or all texts).
%
%   Inputs:
%     value  Number, text, or a 2-element numeric or string array.
%     where  Optional location text for the error messages.
%
%   Output:
%     range  Struct with the fields lo and hi (equal for a single value). Each
%            is a struct with base ("", "min", "max" or "mid") and offset
%            (modules).
%
%   Errors:
%     ldem:case:badValue  The value is not one of the forms above.
%
%   Example:
%       r = ldem.scenarios.parseCoordinate("max - 0.5");
%       r.lo.base      % "max"
%       r.lo.offset    % -0.5
%
%   See also ldem.scenarios.coordinateText, ldem.scenarios.selectNodes.

arguments
    value
    where (1,1) string = ""
end

if numel(value) == 1
    range = struct('lo', parseOne(value, where), 'hi', parseOne(value, where));
elseif numel(value) == 2 && (isnumeric(value) || isstring(value))
    range = struct('lo', parseOne(value(1), where), 'hi', parseOne(value(2), where));
else
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected a coordinate or a pair [lo, hi] in modules.');
end
end

function spec = parseOne(value, where)
if isnumeric(value) && isscalar(value) && isfinite(value)
    spec = struct('base', "", 'offset', double(value));
    return
end
if ~(isstring(value) && isscalar(value))
    ldem.schema.raise('ldem:case:badValue', where, ...
        'Expected a number or a text such as "max - 0.5" (modules).');
end
text = regexprep(lower(strtrim(value)), '\s*modules?$', '');
number = '[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?';
reference = regexp(text, '^(min|max|mid)(.*)$', 'tokens', 'once');
if ~isempty(reference)
    base = string(reference{1});
    rest = strtrim(string(reference{2}));
    offset = 0;
    if rest ~= ""
        parts = regexp(rest, ['^([+-])\s*(' number ')$'], 'tokens', 'once');
        if isempty(parts)
            ldem.schema.raise('ldem:case:badValue', where, ...
                '"%s" is not a coordinate; use "min", "max" or "mid" with an optional offset ("max - 0.5").', value);
        end
        offset = str2double(parts{2});
        if parts{1} == "-"
            offset = -offset;
        end
    end
    spec = struct('base', base, 'offset', offset);
elseif ~isempty(regexp(text, ['^' number '$'], 'once'))
    spec = struct('base', "", 'offset', str2double(text));
else
    ldem.schema.raise('ldem:case:badValue', where, ...
        '"%s" is not a coordinate; use a number or "min", "max" or "mid" with an optional offset ("max - 0.5").', value);
end
end
