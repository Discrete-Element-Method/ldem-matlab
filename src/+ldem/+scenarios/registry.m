function reg = registry()
%REGISTRY  List of the available scenarios (test cases).
%
%   reg = ldem.scenarios.registry() returns one element per scenario class.
%   It is the only place that has to be edited to register a new scenario:
%   ldem.scenarios.fromTestId, ldem.scenarios.fromName and the case-file
%   reader (the [scenario] section) all read it.
%
%   Fields of every element:
%
%     name       Name used in the case file, "type = ..." (snake_case).
%     className  Name of the class, a subclass of ldem.scenarios.Scenario.
%     testId     Value of the constant property testId of the class.
%     units      Struct mapping each property a case file may set to its dimension (key in the file: snake_case, forceRate is force_rate).
%     keywords   Struct mapping a property to a word that stands for NaN in the file (ClampedBeam.loadPosition: "midspan").
%
%   Output:
%     reg  Struct array.
%
%   Example:
%       reg = ldem.scenarios.registry();
%       [reg.name]                % "uniaxial_tension" "four_point_bending" ...
%
%   See also ldem.scenarios.Scenario, ldem.scenarios.fromTestId,
%   ldem.scenarios.fromName.

reg = struct('name', {}, 'className', {}, 'testId', {}, 'units', {}, 'keywords', {});

reg(end+1) = makeEntry("uniaxial_tension", "ldem.scenarios.UniaxialTension", 101, ...
    struct('loadingVelocity', "velocity"), struct());

reg(end+1) = makeEntry("four_point_bending", "ldem.scenarios.FourPointBending", 102, ...
    struct('loadingVelocity', "velocity", 'supportPosition', "modules", ...
           'loadPosition', "modules"), struct());

reg(end+1) = makeEntry("custom", "ldem.scenarios.Declarative", 900, struct(), struct());

reg(end+1) = makeEntry("clamped_beam", "ldem.scenarios.ClampedBeam", 103, ...
    struct('forceRate', "forcerate", 'rampTime', "time", ...
           'loadPosition', "modules", 'loadHeight', "modules"), ...
    struct('loadPosition', "midspan"));
end

function entry = makeEntry(name, className, testId, units, keywords)
entry = struct('name', name, 'className', className, 'testId', testId, ...
    'units', units, 'keywords', keywords);
end
