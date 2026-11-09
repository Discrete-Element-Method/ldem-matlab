function text = formatQuantity(value, dimension)
%FORMATQUANTITY  Write an SI value as a readable number with a unit.
%
%   text = ldem.schema.formatQuantity(value, dimension) is the inverse of
%   ldem.schema.parseQuantity. Lengths, times and pressures use the unit that
%   gives a mantissa of at least 0.1 ("3 mm", "0.35 us", "3.87 GPa"); the other
%   dimensions are written in their SI unit. The text always converts back to
%   exactly the same value: if a unit would lose a digit, a longer mantissa or
%   the SI unit is used.
%
%   Inputs:
%     value      Value in SI units, finite.
%     dimension  Dimension, see ldem.schema.unitTable.
%
%   Output:
%     text  String scalar.
%
%   Example:
%       ldem.schema.formatQuantity(3.5e-7, "time")    % "0.35 us"
%
%   See also ldem.schema.parseQuantity.

arguments
    value (1,1) double {mustBeFinite}
    dimension (1,1) string
end

[names, exps] = ldem.schema.unitTable(dimension);
base = find(exps == 0, 1);

order = base;
if any(dimension == ["length" "time" "pressure"]) && value ~= 0
    ratios = abs(value) ./ 10.^exps;
    usable = find(ratios >= 0.1 & exps ~= -2);
    if isempty(usable)
        [~, preferred] = max(ratios);
    else
        [~, i] = min(ratios(usable));
        preferred = usable(i);
    end
    order = unique([preferred, base], 'stable');
end

for k = order
    mantissa = value / str2double("1e" + string(exps(k)));
    for digits = 1:17
        shown = ldem.schema.shortestText(str2double(sprintf('%.*g', digits, mantissa)));
        candidate = joinUnit(shown, names(k));
        if ldem.schema.parseQuantity(candidate, dimension) == value
            text = candidate;
            return
        end
    end
end
text = joinUnit(string(sprintf('%.17g', value)), names(base));
end

function text = joinUnit(number, unit)
if unit == ""
    text = number;
else
    text = number + " " + unit;
end
end
