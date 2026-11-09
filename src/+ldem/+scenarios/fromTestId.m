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
%   To register a new scenario, add a line to ldem.scenarios.registry.
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
%   See also ldem.scenarios.Scenario, ldem.scenarios.registry.

arguments
    testId (1,1) double
end

reg = ldem.scenarios.registry();
k = find([reg.testId] == testId, 1);
if isempty(k)
    error('ldem:scenarios:unknownTest', ...
        'There is no scenario for testId = %g. Available: %s.', ...
        testId, strjoin(string([reg.testId]), ', '));
end
scenario = feval(reg(k).className);
end
