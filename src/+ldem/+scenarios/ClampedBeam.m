classdef ClampedBeam < ldem.scenarios.Scenario
    %CLAMPEDBEAM  Beam clamped at both ends, loaded at mid-span (TEST 103).
    %
    %   The beam axis is z. The centre nodes of the first and of the last layer
    %   of modules are clamped (x, y and z fixed). A line of centre nodes at
    %   mid-span, on the face y = 0, is loaded in the +y direction. The
    %   property loading selects how:
    %
    %     "force"         (default) A force that grows linearly with time and
    %                     stays constant after rampTime:
    %
    %                         F(t) = forceRate * min(t, rampTime)   [N on each loaded node]
    %
    %                     The scenario sets state.appliedForce and the solver
    %                     counts its work in the external energy.
    %
    %     "displacement"  A prescribed displacement at constant velocity:
    %
    %                         y(t) = y0 + loadingVelocity * t       [m]
    %
    %                     The y-motion of the loaded nodes is held by the solver
    %                     (like the load points of ldem.scenarios.FourPointBending),
    %                     so the beam can be driven past its peak load; the work
    %                     done on it is counted in the external energy.
    %
    %   forceRate and rampTime only apply to "force", loadingVelocity only to
    %   "displacement". In both cases the reaction is the force carried by the
    %   clamped ends.
    %
    %   The load position is measured in modules from the first clamped end
    %   and selects the line of centre nodes closest to it (a window of +-0.01
    %   modules). The centre nodes lie at half-integer positions, so use values
    %   such as 24.5. The default, NaN, is half the beam length minus half a
    %   module, the position used by the original model.
    %
    %   Create it with other values using
    %       scenario = ldem.scenarios.ClampedBeam(forceRate=2000, rampTime=2e-4);
    %       scenario = ldem.scenarios.ClampedBeam(loading="displacement", loadingVelocity=4e-3);
    %
    %   Origin: the bi-clamped beam model of Rodrigo (branch dev_rodrigo), which
    %   modified BOUND, CALOAD and ANSYS of the original code under TEST 102.
    %
    %   See also ldem.scenarios.Scenario, ldem.scenarios.FourPointBending.

    properties (Constant)
        testId = 103
    end

    properties
        % How the load line is loaded: "force" or "displacement".
        loading (1,1) string {mustBeMember(loading, ["force" "displacement"])} = "force"

        % Force growth rate on each loaded node [N/s] (loading = "force").
        forceRate (1,1) double {mustBeFinite} = 1000

        % Time at which the force stops growing and stays constant [s]
        % (loading = "force").
        rampTime (1,1) double {mustBePositive, mustBeFinite} = 0.00035

        % Velocity of the loaded nodes along +y [m/s] (loading = "displacement").
        loadingVelocity (1,1) double {mustBeFinite} = 400e-5

        % Position of the load along the beam, from the first clamped end
        % [modules]. NaN means mid-span, (L-1)/2 - 0.5.
        loadPosition (1,1) double = NaN

        % Height of the loaded line above the face y = 0 [modules].
        loadHeight (1,1) double {mustBeNonnegative, mustBeFinite} = 0.5
    end

    methods
        function obj = ClampedBeam(props)
            %CLAMPEDBEAM  Create the scenario, optionally with other values.
            arguments
                props.?ldem.scenarios.ClampedBeam
            end
            names = fieldnames(props);
            for k = 1:numel(names)
                obj.(names{k}) = props.(names{k});
            end
        end

        function fixed = fixedDofs(obj, nodes0, params)
            %FIXEDDOFS  The clamped end layers, and the load line when it is displaced.
            %
            %   x, y and z of the centre nodes of both end layers. With
            %   loading = "displacement" also y of the loaded nodes (their
            %   y-motion is then imposed by applyLoads).
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            fixed = false(size(nodes0));
            fixed(obj.clampedNodes(nodes0, params), :) = true;
            if obj.loading == "displacement"
                fixed(obj.loadedNodes(nodes0, params), 2) = true;
            end
        end

        function clamped = clampedNodes(obj, nodes0, params)
            %CLAMPEDNODES  Logical vector of the centre nodes of both end layers.
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam %#ok<INUSA>
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            LCO = params.moduleLength;
            L1  = params.nModules(3) - 1;
            z = nodes0(:, 3);
            tol = 0.01;
            atStart = (z > (0.5 - tol) * LCO) & (z < (0.5 + tol) * LCO);
            atEnd   = (z > (L1 - 0.5 - tol) * LCO) & (z < (L1 - 0.5 + tol) * LCO);
            clamped = atStart | atEnd;
        end

        function loaded = loadedNodes(obj, nodes0, params)
            %LOADEDNODES  Logical vector of the nodes that carry the load.
            %
            %   The centre nodes of the line at loadPosition along the beam
            %   and loadHeight above the face y = 0. Throws
            %   ldem:scenarios:noNodesSelected when there is none.
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            LCO = params.moduleLength;
            L1  = params.nModules(3) - 1;
            position = obj.loadPosition;
            if isnan(position)
                position = L1 / 2 - 0.5;
            end
            tol = 0.01;
            loaded = (nodes0(:, 3) > (position - tol) * LCO) & (nodes0(:, 3) < (position + tol) * LCO) & ...
                     (nodes0(:, 2) > (obj.loadHeight - tol) * LCO) & (nodes0(:, 2) < (obj.loadHeight + tol) * LCO);
            if ~any(loaded)
                error('ldem:scenarios:noNodesSelected', ...
                    ['The load line of the clamped beam matches no node. The beam has %d ' ...
                     'modules along z; loadPosition = %g and loadHeight = %g (modules) must ' ...
                     'fall on a line of centre nodes, e.g. 24.5 or 0.5, and lie inside the beam.'], ...
                    L1, position, obj.loadHeight);
            end
        end

        function state = applyLoads(obj, state, mesh, params)
            %APPLYLOADS  Set the force or the displacement of the current time.
            %
            %   "force": forceRate*min(t, rampTime) in +y on each loaded node.
            %   "displacement": moves the loaded nodes to y0 + loadingVelocity*t.
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            loaded = obj.loadedNodes(mesh.nodes0, params);
            if obj.loading == "displacement"
                state.displacement(loaded, 2) = mesh.nodes0(loaded, 2) + obj.loadingVelocity * state.time;
            else
                state.appliedForce(:) = 0;
                state.appliedForce(loaded, 2) = obj.forceRate * min(state.time, obj.rampTime);
            end
        end

        function reaction = reactions(obj, state, mesh, params)
            %REACTIONS  Force that the beam exerts on the clamped ends, [Rx Ry Rz].
            %
            %   The sum of the bar forces on the centre nodes of both end
            %   layers (the held y of a displaced load line is not included).
            %   At rest it equals the total load on the beam.
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            clamped = obj.clampedNodes(mesh.nodes0, params);
            reaction = sum(state.force(clamped, :), 1);
        end
    end
end
