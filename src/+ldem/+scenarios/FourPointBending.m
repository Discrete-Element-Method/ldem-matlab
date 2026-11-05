classdef FourPointBending < ldem.scenarios.Scenario
    %FOURPOINTBENDING  Beam loaded at two points and supported at two points (TEST 102).
    %
    %   The beam is supported near both ends and loaded by prescribed
    %   vertical displacements at the quarter points. This class defines the
    %   supports; the loading is added with the solver.
    %
    %   The positions are expressed in module units, as in the legacy code
    %   (supports at 4 modules from each end, loads at 33.5 modules from
    %   each end), so the scenario only makes sense for beams longer than
    %   about 70 modules. See legacy/KNOWN_ISSUES.md, item 5.
    %
    %   Legacy: the "TEST == 102" branch of BOUND.
    %
    %   See also ldem.scenarios.Scenario.

    properties (Constant)
        testId = 102
    end

    methods
        function fixed = fixedDofs(obj, nodes0, params)
            %FIXEDDOFS  Supports and load points of the beam.
            %
            %   Fixes x and y at the left support, y at the right support,
            %   and y at the two load points on the top face (their
            %   y-motion is then imposed by the loading routine).
            arguments
                obj (1,1) ldem.scenarios.FourPointBending %#ok<INUSA>
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            LCO = params.moduleLength;
            M1  = params.nModules(1) - 1;
            N1  = params.nModules(2) - 1;
            x = nodes0(:, 1);
            y = nodes0(:, 2);

            leftSupport = (y > (0.49 * LCO)) & (y < (0.51 * LCO)) & ...
                          (x < (4.51 * LCO)) & (x > (4.49 * LCO));
            rightSupport = (x > ((M1 - 4.51) * LCO)) & (x < ((M1 - 4.49) * LCO)) & ...
                           (y < (0.51 * LCO)) & (y > (0.49 * LCO));

            loadRight = (x < ((M1 - 33.49) * LCO)) & (x > ((M1 - 33.51) * LCO)) & ...
                        (y < ((N1 - 0.49) * LCO)) & (y > ((N1 - 0.51) * LCO));
            loadLeft  = (x < (33.51 * LCO)) & (x > (33.49 * LCO)) & ...
                        (y < ((N1 - 0.49) * LCO)) & (y > ((N1 - 0.51) * LCO));

            fixed = false(size(nodes0));
            fixed(leftSupport, 1) = true;
            fixed(leftSupport | rightSupport | loadRight | loadLeft, 2) = true;
        end
    end
end
