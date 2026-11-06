function text = writeTemplate(path, scenarioName)
%WRITETEMPLATE  Write a commented case file to start a new model from.
%
%   text = ldem.io.writeTemplate(path) writes a complete case file with the
%   default values of ldem.Parameters for the "uniaxial_tension" scenario,
%   with one comment per key (taken from ldem.schema.caseSchema), ready to
%   edit.
%
%   text = ldem.io.writeTemplate(path, scenarioName) uses another scenario:
%   "uniaxial_tension", "four_point_bending" or "clamped_beam". The keys of
%   the [scenario] section are those of that scenario.
%
%   Inputs:
%     path          Path of the file to create ("" to only return the text).
%     scenarioName  Name in ldem.scenarios.registry (default "uniaxial_tension").
%
%   Output:
%     text  Content of the file.
%
%   Example:
%       ldem.io.writeTemplate("my_test.ldem", "clamped_beam");
%
%   See also ldem.io.writeCase, ldem.io.readCase, ldem.scenarios.fromName.

arguments
    path (1,1) string
    scenarioName (1,1) string = "uniaxial_tension"
end

scenario = ldem.scenarios.fromName(scenarioName);
params = ldem.Parameters(testId = scenario.testId);
text = ldem.io.writeCase(path, params, scenario, ...
    Title = "New case (template for " + scenarioName + ")", ...
    Header = "Edit the values; every key has a comment. Units go after the number.");
end
