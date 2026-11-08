function reg = dampingRegistry()
%DAMPINGREGISTRY  List of the available damping models.
%
%   reg = ldem.solver.dampingRegistry() returns one element per damping class.
%   It is the only place to edit to register a new model: ldem.solver.dampingFromName,
%   the validation of ldem.Parameters and the case-file reader all read it.
%
%   Fields of every element:
%
%     name         Word used in the case file, "type = ..." in [damping].
%     className    Class, a subclass of ldem.solver.DampingModel.
%     description  One line for the messages and the documentation.
%     keys         Keys of [damping] the model uses (the others are an error in a case file): initial, final, switch_time.
%
%   Output:
%     reg  Struct array.
%
%   Example:
%       [ldem.solver.dampingRegistry().name]     % "mass_proportional" "none"
%
%   See also ldem.solver.DampingModel, ldem.solver.dampingFromName.

reg = struct('name', {}, 'className', {}, 'description', {}, 'keys', {});
reg(end+1) = makeEntry("mass_proportional", "ldem.solver.MassProportionalDamping", ...
    "Constant coefficient that switches once (legacy damping)", ...
    ["initial" "final" "switch_time"]);
reg(end+1) = makeEntry("none", "ldem.solver.NoDamping", ...
    "No damping of the nodes", strings(1, 0));
end

function entry = makeEntry(name, className, description, keys)
entry = struct('name', name, 'className', className, 'description', description, 'keys', keys);
end
