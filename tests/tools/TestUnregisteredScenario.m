classdef TestUnregisteredScenario < ldem.scenarios.Scenario
    %TESTUNREGISTEREDSCENARIO  A scenario that is not in ldem.scenarios.registry (for the tests).
    %
    %   It fixes nothing and applies no load. The tests use it to check that
    %   code which needs the registry refuses a scenario that is not in it.
    %
    %   See also ldem.scenarios.Scenario, ldem.scenarios.registry.

    properties (Constant)
        testId = 999
    end

    methods
        function fixed = fixedDofs(~, nodes0, ~)
            fixed = false(size(nodes0));
        end

        function state = applyLoads(~, state, ~, ~)
        end
    end
end
