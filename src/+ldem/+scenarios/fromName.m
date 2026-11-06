function scenario = fromName(name)
%FROMNAME  Create the scenario object with a name used in the case files.
%
%   scenario = ldem.scenarios.fromName(name) returns an instance, with its
%   default values, of the scenario registered under name in
%   ldem.scenarios.registry: "uniaxial_tension", "four_point_bending" or
%   "clamped_beam".
%
%   Input:
%     name  Scenario name (case is ignored).
%
%   Output:
%     scenario  Object of a subclass of ldem.scenarios.Scenario.
%
%   Errors:
%     ldem:scenarios:unknownName  No scenario has that name.
%
%   See also ldem.scenarios.registry, ldem.scenarios.fromTestId.

arguments
    name (1,1) string
end

reg = ldem.scenarios.registry();
k = find([reg.name] == lower(name), 1);
if isempty(k)
    error('ldem:scenarios:unknownName', ...
        'There is no scenario named "%s".%s Available: %s.', name, ...
        ldem.schema.suggest(name, [reg.name]), strjoin([reg.name], ', '));
end
scenario = feval(reg(k).className);
end
