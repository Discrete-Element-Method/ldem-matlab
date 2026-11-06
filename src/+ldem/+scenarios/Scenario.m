classdef (Abstract) Scenario
    %SCENARIO  Base class of the test cases (supports, loads and reactions).
    %
    %   A scenario defines everything that is specific to one kind of test:
    %   which degrees of freedom are fixed, how the load is applied at every
    %   time step and which reaction force is reported. The solver never
    %   checks the test number; it asks the scenario.
    %
    %   To add a new test, create a subclass in this folder:
    %     1. Set the constant property testId to a new number.
    %     2. Implement fixedDofs and applyLoads.
    %     3. Optionally override reactions.
    %     4. Register the class in ldem.scenarios.fromTestId.
    %
    %   See also ldem.scenarios.UniaxialTension,
    %   ldem.scenarios.FourPointBending, ldem.scenarios.fromTestId.

    properties (Abstract, Constant)
        % Number that identifies the scenario in the input file (TEST).
        testId
    end

    methods (Abstract)
        % FIXEDDOFS  Degrees of freedom held at their initial position.
        %
        %   fixed = scenario.fixedDofs(nodes0, params) returns an
        %   nNodes-by-3 logical matrix; fixed(n, d) is true when node n is
        %   not allowed to move in direction d (1 = x, 2 = y, 3 = z).
        %
        %   Inputs:
        %     nodes0  nNodes-by-3 initial coordinates [m].
        %     params  ldem.Parameters.
        fixed = fixedDofs(obj, nodes0, params)

        % APPLYLOADS  Impose the loading of the current time step.
        %
        %   state = scenario.applyLoads(state, mesh, params) modifies the
        %   current displacements (state.displacement) of the loaded nodes
        %   for the time state.time. It is called once per step, before the
        %   bar forces are computed.
        %
        %   A scenario that loads with forces instead of displacements sets
        %   state.appliedForce (nNodes-by-3, in N) here; the solver adds it
        %   to the bar forces and counts its work in the external energy.
        %   Displacement-controlled scenarios leave it untouched (zeros).
        %
        %   Inputs:
        %     state   Solver state, see ldem.solver.initialState.
        %     mesh    Struct from ldem.mesh.buildMesh.
        %     params  ldem.Parameters.
        state = applyLoads(obj, state, mesh, params)
    end

    methods
        function reaction = reactions(obj, state, mesh, params) %#ok<INUSD>
            %REACTIONS  Reaction force of the test as [Rx Ry Rz] [N].
            %
            %   reaction = scenario.reactions(state, mesh, params) returns the
            %   force that the test reports for the current step. The
            %   default is NaN(1,3), meaning "not defined for this test";
            %   subclasses override it.
            reaction = NaN(1, 3);
        end
    end
end
