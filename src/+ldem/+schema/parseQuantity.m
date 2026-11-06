function value = parseQuantity(input, dimension, where)
%PARSEQUANTITY  Convert a number with a unit, such as "3.87 GPa", to SI.
%
%   value = ldem.schema.parseQuantity(input, dimension) returns the value in
%   SI units (m, s, kg, Pa, N). The input is either
%
%     * a number, taken as already being in SI units, or
%     * text made of a number and, optionally, a unit: "3.87 GPa", "0.35 us",
%       "1e-3 m", "3.87e9".
%
%   The decimal exponent of the unit is appended to the digits of the text
%   before converting ("0.35" and "e-6" become 0.35e-6), so the result is the
%   double nearest to the decimal value that was written. "0.35 us" is
%   exactly 3.5e-7.
%
%   Inputs:
%     input      Number or text.
%     dimension  Dimension of the quantity, see ldem.schema.unitTable.
%     where      Optional location text for the error messages.
%
%   Output:
%     value  Value in SI units.
%
%   Errors:
%     ldem:case:badQuantity  The text is not a number with a unit.
%     ldem:case:badUnit      The unit does not belong to the dimension.
%
%   Example:
%       E = ldem.schema.parseQuantity("3.87 GPa", "pressure");   % 3.87e9
%
%   See also ldem.schema.formatQuantity, ldem.schema.unitTable.

arguments
    input
    dimension (1,1) string
    where (1,1) string = ""
end

[names, exps] = ldem.schema.unitTable(dimension);

if isnumeric(input) || islogical(input)
    if ~isscalar(input) || ~isfinite(double(input))
        ldem.schema.raise('ldem:case:badQuantity', where, ...
            'Expected a single finite number.');
    end
    value = double(input);
    return
end

if ~(isstring(input) || ischar(input)) || ~isscalar(string(input))
    ldem.schema.raise('ldem:case:badQuantity', where, ...
        'Expected a number with an optional unit, for example "3 mm".');
end

text = strtrim(string(input));
pattern = '^([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)\s*(\S*)$';
tokens = regexp(text, pattern, 'tokens', 'once');
if isempty(tokens)
    ldem.schema.raise('ldem:case:badQuantity', where, ...
        '"%s" is not a number with an optional unit.', text);
end
mantissa = string(tokens{1});
unit = string(tokens{2});

if unit == ""
    k = find(exps == 0, 1);
else
    k = find(names == unit, 1);
    if isempty(k)
        if all(names == "")
            allowed = "no unit";
        else
            allowed = strjoin(names, ", ");
        end
        ldem.schema.raise('ldem:case:badUnit', where, ...
            'Unit "%s" is not valid here; use %s.', unit, allowed);
    end
end

e = exps(k);
if e == 0
    value = str2double(mantissa);
elseif ~contains(mantissa, ["e" "E"])
    value = str2double(mantissa + "e" + string(e));
else
    value = str2double(mantissa) * 10^e;
end
end
