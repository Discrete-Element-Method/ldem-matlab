classdef (Abstract) Scenario
    %SCENARIO  Base class of the test cases (boundary conditions and loads).
    %
    %   A scenario defines everything that is specific to one kind of test:
    %   which degrees of freedom are fixed, and (in later versions of the
    %   package) how the load is applied and which results are extracted.
    %   The solver never checks the test number; it asks the scenario.
    %
    %   To add a new test, create a subclass in this folder:
    %     1. Set the constant property testId to a new number.
    %     2. Implement fixedDofs.
    %     3. Register the class in ldem.scenarios.fromTestId.
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
    end
end
