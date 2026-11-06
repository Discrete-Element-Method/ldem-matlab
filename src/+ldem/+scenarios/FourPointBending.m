classdef FourPointBending < ldem.scenarios.Scenario
    %FOURPOINTBENDING  Beam with two supports and two load points (TEST 102).
    %
    %   The beam is supported near both ends on the bottom face. Two load
    %   points on the top face are moved down with a constant velocity.
    %
    %   Positions are measured in modules along the beam axis, from the nearest
    %   end of the beam, and select the line of centre nodes closest to that
    %   position (windows of +-0.01 modules). Because the centre nodes lie at
    %   half-integer positions, use values such as 4.5 or 33.5. The defaults are
    %   the values of the legacy code, which only fit a beam longer than about
    %   70 modules. If a position does not match any node, fixedDofs throws
    %   ldem:scenarios:noNodesSelected.
    %
    %   Create it with other values using
    %       scenario = ldem.scenarios.FourPointBending( ...
    %           supportPosition=2.5, loadPosition=10.5, loadingVelocity=1e-3);
    %
    %   Legacy: the "TEST == 102" branches of BOUND, CALOAD and CALRES. The
    %   legacy CALOAD only moved the right load point (a wrong condition left the
    %   other one acting as a support); this was corrected in the original code and here
    %   (docs/known-issues/KNOWN_ISSUES.md, item 15).
    %
    %   See also ldem.scenarios.Scenario.

    properties (Constant)
        testId = 102
    end

    properties
        % Downward velocity of the loaded nodes [m/s]. Legacy: VF2 = 400e-5.
        loadingVelocity (1,1) double {mustBeFinite} = 400e-5

        % Distance from each end of the beam to the support [modules].
        supportPosition (1,1) double {mustBePositive, mustBeFinite} = 4.5

        % Distance from each end of the beam to the load point [modules].
        loadPosition (1,1) double {mustBePositive, mustBeFinite} = 33.5
    end

    methods
        function obj = FourPointBending(props)
            %FOURPOINTBENDING  Create the scenario, optionally with other values.
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
            %   Fixes x and y at the left support, y at the right support and
            %   y at the two load points on the top face (the y-motion of the
            %   load points is then imposed by applyLoads).
            arguments
                obj (1,1) ldem.scenarios.FourPointBending
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            s = obj.selectNodes(nodes0, params);
            fixed = false(size(nodes0));
            fixed(s.leftSupport, 1) = true;
            fixed(s.leftSupport | s.rightSupport | s.loadLeft | s.loadRight, 2) = true;
        end

        function loaded = loadedNodes(obj, nodes0, params)
            %LOADEDNODES  Logical vector of the nodes that are moved down.
            %
            %   The centre nodes of the two load lines on the top face.
            arguments
                obj (1,1) ldem.scenarios.FourPointBending
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            s = obj.selectNodes(nodes0, params);
            loaded = s.loadLeft | s.loadRight;
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

    methods (Access = private)
        function s = selectNodes(obj, nodes0, params)
            %SELECTNODES  Masks of the support and load nodes; errors if one is empty.
            LCO = params.moduleLength;
            M1  = params.nModules(1) - 1;
            N1  = params.nModules(2) - 1;
            x = nodes0(:, 1);
            y = nodes0(:, 2);
            tol = 0.01;

            atBottom = (y > (0.5 - tol) * LCO) & (y < (0.5 + tol) * LCO);
            atTop    = (y > (N1 - 0.5 - tol) * LCO) & (y < (N1 - 0.5 + tol) * LCO);
            nearLeft  = @(position) (x > (position - tol) * LCO) & (x < (position + tol) * LCO);
            nearRight = @(position) (x > (M1 - position - tol) * LCO) & (x < (M1 - position + tol) * LCO);

            s.leftSupport  = atBottom & nearLeft(obj.supportPosition);
            s.rightSupport = atBottom & nearRight(obj.supportPosition);
            s.loadLeft     = atTop & nearLeft(obj.loadPosition);
            s.loadRight    = atTop & nearRight(obj.loadPosition);

            for name = fieldnames(s).'
                if ~any(s.(name{1}))
                    error('ldem:scenarios:noNodesSelected', ...
                        ['The %s of the beam test matches no node. The beam has %d modules ' ...
                         'along x; supportPosition = %g and loadPosition = %g (modules from ' ...
                         'each end) must fall on a line of centre nodes, e.g. 4.5 or 33.5, ' ...
                         'and lie inside the beam.'], ...
                        name{1}, M1, obj.supportPosition, obj.loadPosition);
                end
            end
        end
    end
end
