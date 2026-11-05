classdef FourPointBending < ldem.scenarios.Scenario
    %FOURPOINTBENDING  Beam with two supports and a load point (TEST 102).
    %
    %   The beam is supported near both ends. A load point on the top face,
    %   33.5 modules from the right end, is moved down with a constant
    %   velocity.
    %
    %   The positions are expressed in module units, as in the legacy code
    %   (supports at 4 modules from each end, load points at 33.5 modules
    %   from each end), so the scenario only makes sense for beams longer
    %   than about 70 modules.
    %
    %   Behaviour reproduced from the legacy code (see
    %   legacy/KNOWN_ISSUES.md, items 5 and 11): there are two load points
    %   and both are held in y, but only the right one is actually moved;
    %   the left one stays at its initial height and acts as a support.
    %
    %   Create it with a different velocity using
    %       scenario = ldem.scenarios.FourPointBending(loadingVelocity=1e-3);
    %
    %   Legacy: the "TEST == 102" branches of BOUND, CALOAD and CALRES.
    %
    %   See also ldem.scenarios.Scenario.

    properties (Constant)
        testId = 102
    end

    properties
        % Downward velocity of the loaded nodes [m/s]. Legacy: VF2 = 400e-5.
        loadingVelocity (1,1) double {mustBeFinite} = 400e-5
    end

    methods
        function obj = FourPointBending(props)
            %FOURPOINTBENDING  Create the scenario, optionally with a new velocity.
            arguments
                props.?ldem.scenarios.FourPointBending
            end
            names = fieldnames(props);
            for k = 1:numel(names)
                obj.(names{k}) = props.(names{k});
            end
        end

        function fixed = fixedDofs(obj, nodes0, params)
            %FIXEDDOFS  Supports and load points of the beam.
            %
            %   Fixes x and y at the left support, y at the right support,
            %   and y at the two load points on the top face (the y-motion
            %   of the right one is then imposed by applyLoads).
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

        function loaded = loadedNodes(obj, nodes0, params)
            %LOADEDNODES  Logical vector of the nodes that are moved down.
            %
            %   Only the load point at 33.5 modules from the right end (see the
            %   class description).
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
            loaded = (x < (M1 - 33.49) * LCO) & (x > (M1 - 33.51) * LCO) & ...
                     (y < (N1 - 0.49) * LCO)  & (y > (N1 - 0.51) * LCO);
        end

        function state = applyLoads(obj, state, mesh, params)
            %APPLYLOADS  Move the loaded nodes to y0 - loadingVelocity*time.
            arguments
                obj (1,1) ldem.scenarios.FourPointBending
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            loaded = obj.loadedNodes(mesh.nodes0, params);
            state.displacement(loaded, 2) = mesh.nodes0(loaded, 2) - obj.loadingVelocity * state.time;
        end

        function reaction = reactions(obj, state, mesh, params)
            %REACTIONS  Vertical force carried by the nodes held in y at the top.
            %
            %   Returns [0 Ry 0] where Ry is the sum of the y-component of the
            %   bar forces on the nodes held in y whose initial height is
            %   (N-1.51) modules or more, that is, the load points.
            arguments
                obj (1,1) ldem.scenarios.FourPointBending %#ok<INUSA>
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            N1 = params.nModules(2) - 1;
            atTop = mesh.fixed(:, 2) & (mesh.nodes0(:, 2) >= params.moduleLength * (N1 - 0.51));
            reaction = [0, sum(state.force(atTop, 2)), 0];
        end
    end
end
