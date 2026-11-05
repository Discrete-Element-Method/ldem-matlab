classdef UniaxialTension < ldem.scenarios.Scenario
    %UNIAXIALTENSION  Prism loaded by a prescribed axial displacement (TEST 101).
    %
    %   The prism is pulled (or compressed) along x by imposing a
    %   displacement velocity on the last column of centre nodes. This class
    %   defines the supports; the loading is added with the solver.
    %
    %   Legacy: the "TEST == 101" branches of BOUND and CALOAD.
    %
    %   See also ldem.scenarios.Scenario.

    properties (Constant)
        testId = 101
    end

    methods
        function fixed = fixedDofs(obj, nodes0, params)
            %FIXEDDOFS  Fix the x-motion of the centre nodes of both end faces.
            %
            %   NOTE (reproduces the legacy code): the right-end condition
            %   is written with the legacy operator precedence,
            %   (M1 - 0.51*LCO) instead of (M1 - 0.51)*LCO, so it selects no
            %   node and only the left end is fixed. See
            %   legacy/KNOWN_ISSUES.md, item 3.
            arguments
                obj (1,1) ldem.scenarios.UniaxialTension %#ok<INUSA>
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            LCO = params.moduleLength;
            M1  = params.nModules(1) - 1;
            x   = nodes0(:, 1);

            leftEnd  = (x < (0.51 * LCO)) & (x > (0.49 * LCO));
            rightEnd = (x > (M1 - 0.51 * LCO)) & (x < (M1 - 0.49 * LCO));

            fixed = false(size(nodes0));
            fixed(leftEnd | rightEnd, 1) = true;
        end
    end
end
