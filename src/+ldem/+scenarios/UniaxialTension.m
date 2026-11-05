classdef UniaxialTension < ldem.scenarios.Scenario
    %UNIAXIALTENSION  Prism loaded by a prescribed axial displacement (TEST 101).
    %
    %   The centre nodes of the last column of the prism are moved along x
    %   with a constant velocity, while the centre nodes of the first column
    %   are held in x.
    %
    %   Sign convention (as in the legacy code): the loaded nodes move to
    %   x0 - loadingVelocity*time, so a positive loadingVelocity pushes them
    %   toward the fixed end and COMPRESSES the prism. Use a negative value
    %   to pull it. The comment of the legacy code says "tension".
    %
    %   Create it with a different velocity using
    %       scenario = ldem.scenarios.UniaxialTension(loadingVelocity=1e-3);
    %
    %   Legacy: the "TEST == 101" branches of BOUND and CALOAD.
    %
    %   See also ldem.scenarios.Scenario.

    properties (Constant)
        testId = 101
    end

    properties
        % Velocity of the loaded nodes along -x [m/s]. Legacy: VF2 = 400e-5.
        loadingVelocity (1,1) double {mustBeFinite} = 400e-5
    end

    methods
        function obj = UniaxialTension(props)
            %UNIAXIALTENSION  Create the scenario, optionally with a new velocity.
            arguments
                props.?ldem.scenarios.UniaxialTension
            end
            names = fieldnames(props);
            for k = 1:numel(names)
                obj.(names{k}) = props.(names{k});
            end
        end

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

        function loaded = loadedNodes(obj, nodes0, params)
            %LOADEDNODES  Logical vector of the nodes with prescribed motion.
            %
            %   They are the centre nodes of the last column of modules.
            arguments
                obj (1,1) ldem.scenarios.UniaxialTension %#ok<INUSA>
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            LCO = params.moduleLength;
            M1  = params.nModules(1) - 1;
            x   = nodes0(:, 1);
            loaded = (x < (M1 - 0.49) * LCO) & (x > (M1 - 0.51) * LCO);
        end

        function state = applyLoads(obj, state, mesh, params)
            %APPLYLOADS  Move the loaded nodes to x0 - loadingVelocity*time.
            arguments
                obj (1,1) ldem.scenarios.UniaxialTension
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            loaded = obj.loadedNodes(mesh.nodes0, params);
            state.displacement(loaded, 1) = mesh.nodes0(loaded, 1) - obj.loadingVelocity * state.time;
        end
    end
end
