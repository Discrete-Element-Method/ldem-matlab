function model = dampingFromName(name)
%DAMPINGFROMNAME  Create the damping-model object with a name used in the case files.
%
%   model = ldem.solver.dampingFromName(name) returns an instance of the class
%   registered under name in ldem.solver.dampingRegistry.
%
%   Input:
%     name  Model name, for example "mass_proportional" (case is ignored).
%
%   Output:
%     model  Object of a subclass of ldem.solver.DampingModel.
%
%   Errors:
%     ldem:solver:unknownDamping  No model has that name.
%
%   See also ldem.solver.dampingRegistry, ldem.solver.DampingModel.

arguments
    name (1,1) string
end

reg = ldem.solver.dampingRegistry();
k = find([reg.name] == lower(name), 1);
if isempty(k)
    error('ldem:solver:unknownDamping', ...
        'There is no damping model named "%s".%s Available: %s.', name, ...
        ldem.schema.suggest(name, [reg.name]), strjoin([reg.name], ', '));
end
model = feval(reg(k).className);
end
