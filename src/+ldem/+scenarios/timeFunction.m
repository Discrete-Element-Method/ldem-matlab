function value = timeFunction(fn, t)
%TIMEFUNCTION  Value of a load at time t.
%
%   value = ldem.scenarios.timeFunction(fn, t) evaluates the time function of
%   a [[load]] block. fn is a struct whose field type selects the function:
%
%     constant  value
%     linear    rate*t
%     ramp      rate*min(t, until): grows at rate until the time "until", then stays constant
%     table     piecewise-linear interpolation of values at times; the end values are kept outside
%
%   The result is in newtons for a force load and in metres (the movement from
%   the initial position) for a displacement load.
%
%   Inputs:
%     fn  Struct with the fields type, value, rate, until, times and values.
%     t   Time [s].
%
%   Output:
%     value  Scalar.
%
%   Errors:
%     ldem:scenarios:badTimeFunction  The type is not one of the above.
%
%   Example:
%       fn = ldem.scenarios.Declarative.makeFunction("ramp", rate=1000, until=3.5e-4);
%       ldem.scenarios.timeFunction(fn, 1e-3)     % 0.35 N
%
%   See also ldem.scenarios.Declarative.

arguments
    fn (1,1) struct
    t (1,1) double
end

switch fn.type
    case "constant"
        value = fn.value;
    case "linear"
        value = fn.rate * t;
    case "ramp"
        value = fn.rate * min(t, fn.until);
    case "table"
        clamped = min(max(t, fn.times(1)), fn.times(end));
        value = interp1(fn.times, fn.values, clamped, 'linear');
    otherwise
        error('ldem:scenarios:badTimeFunction', ...
            'Unknown time function "%s"; use constant, linear, ramp or table.', fn.type);
end
end
