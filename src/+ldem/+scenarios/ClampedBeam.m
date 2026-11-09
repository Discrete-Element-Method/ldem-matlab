classdef ClampedBeam < ldem.scenarios.Scenario
    %CLAMPEDBEAM  Beam clamped at both ends with a force at mid-span (TEST 103).
    %
    %   The beam axis is z. The centre nodes of the first and of the last layer
    %   of modules are clamped (x, y and z fixed). A line of centre nodes at
    %   mid-span, on the face y = 0, is loaded with a force in the +y direction
    %   that grows linearly with time and stays constant after rampTime:
    %
    %       F(t) = forceRate * min(t, rampTime)      [N on each loaded node]
    %
    %   This test loads with a force, not with a displacement: the scenario
    %   sets state.appliedForce and the solver counts its work in the external
    %   energy.
    %
    %   The load position is measured in modules from the first clamped end
    %   and selects the line of centre nodes closest to it (a window of +-0.01
    %   modules). The centre nodes lie at half-integer positions, so use values
    %   such as 24.5. The default, NaN, is half the beam length minus half a
    %   module, the position used by the original model.
    %
    %   Create it with other values using
    %       scenario = ldem.scenarios.ClampedBeam(forceRate=2000, rampTime=2e-4);
    %
    %   Origin: the bi-clamped beam model of Rodrigo (branch dev_rodrigo), which
    %   modified BOUND, CALOAD and ANSYS of the original code under TEST 102.
    %
    %   See also ldem.scenarios.Scenario, ldem.scenarios.FourPointBending.

    properties (Constant)
        testId = 103
    end

    properties
        % Force growth rate on each loaded node [N/s].
        forceRate (1,1) double {mustBeFinite} = 1000

        % Time at which the force stops growing and stays constant [s].
        rampTime (1,1) double {mustBePositive, mustBeFinite} = 0.00035

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
            %FIXEDDOFS  The two clamped end layers (x, y and z of their centre nodes).
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
            fixed = false(size(nodes0));
            fixed(atStart | atEnd, :) = true;
        end

        function loaded = loadedNodes(obj, nodes0, params)
            %LOADEDNODES  Logical vector of the nodes that carry the force.
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
            %APPLYLOADS  Set the force of the current time on the loaded nodes.
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            loaded = obj.loadedNodes(mesh.nodes0, params);
            state.appliedForce(:) = 0;
            state.appliedForce(loaded, 2) = obj.forceRate * min(state.time, obj.rampTime);
        end

        function reaction = reactions(obj, state, mesh, params)
            %REACTIONS  Force that the beam exerts on the clamped ends, [Rx Ry Rz].
            %
            %   The sum of the bar forces on the clamped degrees of freedom. At
            %   rest it equals the total applied force.
            arguments
                obj (1,1) ldem.scenarios.ClampedBeam %#ok<INUSA>
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters %#ok<INUSA>
            end
            reaction = sum(state.force .* mesh.fixed, 1);
        end
    end
end
