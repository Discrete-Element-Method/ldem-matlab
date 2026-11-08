function text = coordinateText(range)
%COORDINATETEXT  Write a coordinate range as it appears in a case file.
%
%   text = ldem.scenarios.coordinateText(range) is the inverse of
%   ldem.scenarios.parseCoordinate: 0.5, "max - 0.5", [0, 5] or
%   ["min + 0.5", "max - 0.5"]. The text can be written after "x = ".
%
%   Input:
%     range  Struct with lo and hi, from ldem.scenarios.parseCoordinate.
%
%   Output:
%     text  String scalar.
%
%   Example:
%       r = ldem.scenarios.parseCoordinate("mid - 0.5");
%       ldem.scenarios.coordinateText(r)      % "mid - 0.5" (with quotes)
%
%   See also ldem.scenarios.parseCoordinate.

arguments
    range (1,1) struct
end

if isequal(range.lo, range.hi)
    text = scalarText(range.lo);
    return
end
if range.lo.base == "" && range.hi.base == ""
    text = "[" + ldem.schema.shortestText(range.lo.offset) + ", " ...
        + ldem.schema.shortestText(range.hi.offset) + "]";
else
    text = "[" + quoted(range.lo) + ", " + quoted(range.hi) + "]";
end
end

function text = scalarText(spec)
if spec.base == ""
    text = ldem.schema.shortestText(spec.offset);
else
    text = quoted(spec);
end
end

function text = quoted(spec)
if spec.base == ""
    body = ldem.schema.shortestText(spec.offset);
elseif spec.offset == 0
    body = spec.base;
elseif spec.offset > 0
    body = spec.base + " + " + ldem.schema.shortestText(spec.offset);
else
    body = spec.base + " - " + ldem.schema.shortestText(-spec.offset);
end
text = '"' + body + '"';
end
