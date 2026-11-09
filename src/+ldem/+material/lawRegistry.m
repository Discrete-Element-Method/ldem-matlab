function reg = lawRegistry()
%LAWREGISTRY  List of the available constitutive laws.
%
%   reg = ldem.material.lawRegistry() returns one element per law class. It is
%   the only place to edit to register a new law: ldem.material.lawFromName,
%   the validation of ldem.Parameters and the case-file reader all read it.
%
%   Fields of every element:
%
%     name         Word used in the case file, "law = ..." (snake_case).
%     className    Class, a subclass of ldem.material.MaterialLaw.
%     description  One line for the messages and the documentation.
%
%   Output:
%     reg  Struct array.
%
%   Example:
%       [ldem.material.lawRegistry().name]      % "bilinear" "linear_elastic"
%
%   See also ldem.material.MaterialLaw, ldem.material.lawFromName.

reg = struct('name', {}, 'className', {}, 'description', {});
reg(end+1) = makeEntry("bilinear", "ldem.material.BilinearBarLaw", ...
    "Linear elastic, softening in tension down to rupture (legacy law)");
reg(end+1) = makeEntry("linear_elastic", "ldem.material.LinearElasticBarLaw", ...
    "Linear elastic, no damage and no rupture");
end

function entry = makeEntry(name, className, description)
entry = struct('name', name, 'className', className, 'description', description);
end
