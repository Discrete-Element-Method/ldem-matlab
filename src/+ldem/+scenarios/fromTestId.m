function scenario = fromTestId(testId)
%FROMTESTID  Create the scenario object for a test number.
%
%   scenario = ldem.scenarios.fromTestId(testId) returns an instance of the
%   scenario class registered for testId:
%
%       101  ldem.scenarios.UniaxialTension
%       102  ldem.scenarios.FourPointBending
%       103  ldem.scenarios.ClampedBeam
%
%   To register a new scenario, add a line to the list inside this file.
%
%   Input:
%     testId  Test number (Parameters.testId).
%
%   Output:
%     scenario  Object of a subclass of ldem.scenarios.Scenario.
%
%   Errors:
%     ldem:scenarios:unknownTest  No scenario has that number.
%
%   See also ldem.scenarios.Scenario.

arguments
    testId (1,1) double
end

registered = {ldem.scenarios.UniaxialTension(), ldem.scenarios.FourPointBending(), ...
              ldem.scenarios.ClampedBeam()};

for k = 1:numel(registered)
    if registered{k}.testId == testId
        scenario = registered{k};
        return
    end
end

known = cellfun(@(s) s.testId, registered);
error('ldem:scenarios:unknownTest', ...
    'There is no scenario for testId = %g. Available: %s.', ...
    testId, strjoin(string(known), ', '));
end
