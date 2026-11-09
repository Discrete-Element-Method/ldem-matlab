classdef Declarative < ldem.scenarios.Scenario
    %DECLARATIVE  A test defined by supports and loads instead of by a class (type "custom").
    %
    %   The built-in scenarios (ldem.scenarios.UniaxialTension, ...) are fixed
    %   tests. This one is assembled from blocks, which is what the
    %   [[support]] and [[load]] sections of a case file read, so a new test is
    %   written as text, without programming:
    %
    %     support  Holds some degrees of freedom of the selected nodes at their
    %              initial position (a clamp, a roller, a symmetry plane).
    %     load     Acts on one direction of the selected nodes, either as a force
    %              (N) or as a prescribed displacement (m, measured from the
    %              initial position). The value is a function of time:
    %              constant, linear, ramp or table (ldem.scenarios.timeFunction).
    %
    %   Nodes are selected by kind ("all", "grid", "centre"), by number, and by
    %   coordinate ranges in modules, with the references min, max and mid
    %   (ldem.scenarios.selectNodes). A degree of freedom with a prescribed
    %   displacement is held by the solver, like the loaded nodes of the other
    %   tests. A block can ask to be part of the reaction: the reaction of the
    %   test is then, for each direction, the sum of the bar forces on the
    %   degrees of freedom of the blocks that asked for it; without any, the
    %   reaction is NaN.
    %
    %   Build the blocks with the static methods makeSelector, makeSupport,
    %   makeLoad and makeFunction. For example, a beam clamped at z = 0.5 and
    %   pushed by a force that grows for 0.35 ms:
    %
    %       import ldem.scenarios.Declarative
    %       end1 = Declarative.makeSelector(z = 0.5);
    %       mid  = Declarative.makeSelector(y = 0.5, z = "mid - 0.5");
    %       ramp = Declarative.makeFunction("ramp", rate = 1000, until = 3.5e-4);
    %       support = Declarative.makeSupport(end1, "xyz", reaction = true);
    %       load = Declarative.makeLoad(mid, "y", "force", ramp);
    %       scenario = Declarative(supports = support, loads = load);
    %
    %   Selections use the regular lattice, so they do not change when the mesh
    %   is perturbed. A block that selects no node is an error
    %   (ldem:scenarios:noNodesSelected).
    %
    %   See also ldem.scenarios.Scenario, ldem.scenarios.selectNodes,
    %   ldem.scenarios.timeFunction, ldem.scenarios.registry.

    properties (Constant)
        testId = 900
    end

    properties
        % Struct row of the supports, from makeSupport (fields name, selector, fix, reaction).
        supports (1,:) struct = ldem.scenarios.Declarative.emptySupports()

        % Struct row of the loads, from makeLoad (fields name, selector, direction, type, fn, reaction).
        loads (1,:) struct = ldem.scenarios.Declarative.emptyLoads()
    end

    methods
        function obj = Declarative(props)
            %DECLARATIVE  Create the scenario from lists of supports and loads.
            arguments
                props.?ldem.scenarios.Declarative
            end
            names = fieldnames(props);
            for k = 1:numel(names)
                obj.(names{k}) = props.(names{k});
            end
            obj.check();
        end

        function check(obj)
            %CHECK  Verify the structure of the supports and loads.
            %
            %   Throws ldem:scenarios:badDefinition when a block is malformed.
            supportFields = ["name" "selector" "fix" "reaction"];
            loadFields = ["name" "selector" "direction" "type" "fn" "reaction"];
            if ~isempty(obj.supports) && ~isequal(sort(string(fieldnames(obj.supports)).'), sort(supportFields))
                error('ldem:scenarios:badDefinition', ...
                    'supports must be built with Declarative.makeSupport (fields %s).', strjoin(supportFields, ', '));
            end
            if ~isempty(obj.loads) && ~isequal(sort(string(fieldnames(obj.loads)).'), sort(loadFields))
                error('ldem:scenarios:badDefinition', ...
                    'loads must be built with Declarative.makeLoad (fields %s).', strjoin(loadFields, ', '));
            end
        end

        function fixed = fixedDofs(obj, nodes0, params)
            %FIXEDDOFS  Degrees of freedom held by the supports and by the displacement loads.
            arguments
                obj (1,1) ldem.scenarios.Declarative
                nodes0 (:,3) double
                params (1,1) ldem.Parameters
            end
            lattice = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            fixed = false(size(nodes0));
            for k = 1:numel(obj.supports)
                block = obj.supports(k);
                mask = obj.select(block, "support", k, params, lattice);
                fixed(mask, block.fix) = true;
            end
            for k = 1:numel(obj.loads)
                block = obj.loads(k);
                if block.type == "displacement"
                    mask = obj.select(block, "load", k, params, lattice);
                    fixed(mask, block.direction) = true;
                end
            end
        end

        function data = prepare(obj, nodes0, ~, params)
            %PREPARE  Nodes of every load and of the reaction, found once.
            %
            %   Returns a struct with loadNodes (cell, the node numbers of each
            %   load), reactionNodes (1-by-3 cell, the nodes whose force is
            %   summed in each direction) and hasReaction.
            lattice = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            loadNodes = cell(1, numel(obj.loads));
            marked = false(size(nodes0));
            for k = 1:numel(obj.supports)
                block = obj.supports(k);
                if block.reaction
                    mask = obj.select(block, "support", k, params, lattice);
                    marked(mask, block.fix) = true;
                end
            end
            for k = 1:numel(obj.loads)
                block = obj.loads(k);
                mask = obj.select(block, "load", k, params, lattice);
                loadNodes{k} = find(mask);
                if block.reaction
                    marked(mask, block.direction) = true;
                end
            end
            data = struct('loadNodes', {loadNodes}, ...
                'reactionNodes', {{find(marked(:, 1)), find(marked(:, 2)), find(marked(:, 3))}}, ...
                'hasReaction', any(marked, 'all'));
        end

        function state = applyLoads(obj, state, mesh, params)
            %APPLYLOADS  Set the forces and the prescribed displacements of the current time.
            arguments
                obj (1,1) ldem.scenarios.Declarative
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            if isempty(obj.loads)
                return
            end
            data = obj.dataOf(mesh, params);
            hasForce = false;
            for k = 1:numel(obj.loads)
                hasForce = hasForce || obj.loads(k).type == "force";
            end
            if hasForce
                state.appliedForce(:) = 0;
            end
            for k = 1:numel(obj.loads)
                block = obj.loads(k);
                nodes = data.loadNodes{k};
                value = ldem.scenarios.timeFunction(block.fn, state.time);
                if block.type == "force"
                    state.appliedForce(nodes, block.direction) = state.appliedForce(nodes, block.direction) + value;
                else
                    state.displacement(nodes, block.direction) = mesh.nodes0(nodes, block.direction) + value;
                end
            end
        end

        function reaction = reactions(obj, state, mesh, params)
            %REACTIONS  Sum of the bar forces on the degrees of freedom marked with reaction = true.
            arguments
                obj (1,1) ldem.scenarios.Declarative
                state (1,1) struct
                mesh (1,1) struct
                params (1,1) ldem.Parameters
            end
            data = obj.dataOf(mesh, params);
            if ~data.hasReaction
                reaction = NaN(1, 3);
                return
            end
            reaction = zeros(1, 3);
            for direction = 1:3
                reaction(direction) = sum(state.force(data.reactionNodes{direction}, direction));
            end
        end
    end

    methods (Access = private)
        function mask = select(~, block, kind, index, params, lattice)
            %SELECT  Selected nodes of a block; an empty selection is an error.
            mask = ldem.scenarios.selectNodes(block.selector, params, lattice);
            if ~any(mask)
                label = "[[" + kind + "]] number " + string(index);
                if block.name ~= ""
                    label = label + " (""" + block.name + """)";
                end
                message = sprintf(['The %s matches no node. The prism has %d x %d x %d modules; ' ...
                    'positions are in modules (centre nodes lie at half-integer positions ' ...
                    'such as 0.5, grid nodes at integers), and "min", "max" and "mid" refer ' ...
                    'to the ends and the middle of the prism.'], label, params.nModules - 1);
                error('ldem:scenarios:noNodesSelected', '%s', message);
            end
        end

        function data = dataOf(obj, mesh, params)
            if isfield(mesh, 'scenarioData') && isfield(mesh.scenarioData, 'loadNodes')
                data = mesh.scenarioData;
            else
                data = obj.prepare(mesh.nodes0, mesh.fixed, params);
            end
        end
    end

    methods (Static)
        function selector = makeSelector(options)
            %MAKESELECTOR  Selector of nodes for a support or a load.
            %
            %   selector = Declarative.makeSelector(Name=Value) with
            %
            %     nodes  "all" (default), "grid" or "centre".
            %     ids    Node numbers.
            %     x, y, z  Coordinate or range in modules, see
            %              ldem.scenarios.parseCoordinate: 0.5, "max - 0.5",
            %              [0 5].
            arguments
                options.nodes (1,1) string {mustBeMember(options.nodes, ["all" "grid" "centre"])} = "all"
                options.ids (1,:) double {mustBeInteger, mustBePositive} = zeros(1, 0)
                options.x = []
                options.y = []
                options.z = []
            end
            selector = struct('nodes', options.nodes, 'ids', options.ids, ...
                'x', coordinate(options.x), 'y', coordinate(options.y), 'z', coordinate(options.z));
        end

        function block = makeSupport(selector, fix, options)
            %MAKESUPPORT  Support block: the directions in fix are held.
            %
            %   support = Declarative.makeSupport(selector, fix, Name=Value). fix
            %   is the directions to hold, as text ("xyz", "x", "xz") or a
            %   string array (["x" "z"]). Options: name (label) and reaction
            %   (true to include the block in the reaction of the test).
            arguments
                selector (1,1) struct
                fix (1,:) string
                options.name (1,1) string = ""
                options.reaction (1,1) logical = false
            end
            block = struct('name', options.name, 'selector', selector, ...
                'fix', directions(fix), 'reaction', options.reaction);
        end

        function block = makeLoad(selector, direction, type, fn, options)
            %MAKELOAD  Load block: a force or a displacement along one direction.
            %
            %   load = Declarative.makeLoad(selector, direction, type, fn, Name=Value)
            %   with direction "x", "y" or "z", type "force" or "displacement",
            %   fn from Declarative.makeFunction. Options: name and reaction.
            arguments
                selector (1,1) struct
                direction (1,1) string {mustBeMember(direction, ["x" "y" "z"])}
                type (1,1) string {mustBeMember(type, ["force" "displacement"])}
                fn (1,1) struct
                options.name (1,1) string = ""
                options.reaction (1,1) logical = false
            end
            block = struct('name', options.name, 'selector', selector, ...
                'direction', directions(direction), 'type', type, 'fn', fn, ...
                'reaction', options.reaction);
        end

        function fn = makeFunction(type, options)
            %MAKEFUNCTION  Time function of a load, see ldem.scenarios.timeFunction.
            %
            %   fn = Declarative.makeFunction("constant", value=...)
            %   fn = Declarative.makeFunction("linear", rate=...)
            %   fn = Declarative.makeFunction("ramp", rate=..., until=...)
            %   fn = Declarative.makeFunction("table", times=[...], values=[...])
            %
            %   All in SI units (N or m, N/s or m/s, s).
            arguments
                type (1,1) string {mustBeMember(type, ["constant" "linear" "ramp" "table"])}
                options.value (1,1) double {mustBeFinite} = 0
                options.rate (1,1) double {mustBeFinite} = 0
                options.until (1,1) double {mustBePositive} = Inf
                options.times (1,:) double {mustBeFinite} = zeros(1, 0)
                options.values (1,:) double {mustBeFinite} = zeros(1, 0)
            end
            if type == "ramp" && ~isfinite(options.until)
                error('ldem:scenarios:badDefinition', 'A ramp needs the time "until" at which it stops growing.');
            end
            if type == "table"
                if numel(options.times) < 2 || numel(options.times) ~= numel(options.values) ...
                        || any(diff(options.times) <= 0)
                    error('ldem:scenarios:badDefinition', ...
                        ['A table needs at least two strictly increasing times and one value per ' ...
                         'time (got %d times and %d values).'], numel(options.times), numel(options.values));
                end
            end
            fn = struct('type', type, 'value', options.value, 'rate', options.rate, ...
                'until', options.until, 'times', options.times, 'values', options.values);
        end

        function s = emptySupports()
            %EMPTYSUPPORTS  Zero supports.
            s = repmat(struct('name', "", 'selector', [], 'fix', [], 'reaction', false), 1, 0);
        end

        function s = emptyLoads()
            %EMPTYLOADS  Zero loads.
            s = repmat(struct('name', "", 'selector', [], 'direction', [], 'type', "", 'fn', [], 'reaction', false), 1, 0);
        end
    end
end

function range = coordinate(value)
if isempty(value)
    range = [];
else
    range = ldem.scenarios.parseCoordinate(value);
end
end

function indices = directions(text)
%DIRECTIONS  Direction letters ("xz" or ["x" "z"]) as column indices 1..3.
letters = char(join(text, ""));
indices = zeros(1, 0);
for c = lower(letters)
    k = find('xyz' == c, 1);
    if isempty(k)
        error('ldem:scenarios:badDefinition', 'Directions are x, y and z, got "%s".', c);
    end
    indices(end+1) = k; %#ok<AGROW>
end
indices = unique(indices);
if isempty(indices)
    error('ldem:scenarios:badDefinition', 'At least one direction (x, y or z) is needed.');
end
end
