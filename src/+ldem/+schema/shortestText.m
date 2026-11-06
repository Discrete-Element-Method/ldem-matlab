function text = shortestText(x)
%SHORTESTTEXT  Shortest decimal text that converts back to exactly x.
%
%   text = ldem.schema.shortestText(x) returns, for example, "0.1" for 0.1,
%   "32" for 32 and "3.5e-07" for 3.5e-7. str2double(text) == x always holds
%   for a finite x.
%
%   Input:
%     x  Finite real scalar.
%
%   Output:
%     text  String scalar.
%
%   See also ldem.schema.formatQuantity.

arguments
    x (1,1) double
end

if x == fix(x) && abs(x) < 1e15
    text = string(sprintf('%d', x));
    return
end
for digits = 1:17
    candidate = sprintf('%.*g', digits, x);
    if str2double(candidate) == x
        text = string(candidate);
        return
    end
end
text = string(sprintf('%.17g', x));
end
