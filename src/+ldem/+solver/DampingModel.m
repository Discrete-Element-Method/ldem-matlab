classdef (Abstract) DampingModel
    %DAMPINGMODEL  Base class of the damping models of the nodes.
    %
    %   The integrator damps the motion of every node with the term
    %   c*m*velocity, where c [1/s] may change from step to step. A damping
    %   model only has to return c for a step. The solver asks the object chosen
    %   by params.dampingModel (the key "type" of the [damping] section of a case
    %   file).
    %
    %   To add a model:
    %     1. Create a subclass in this folder and set the constant property name
    %        (snake_case, the word used in the case file).
    %     2. Implement coefficient.
    %     3. Add a line to ldem.solver.dampingRegistry, with the keys of the
    %        [damping] section that the model uses.
    %
    %   See also ldem.solver.MassProportionalDamping, ldem.solver.NoDamping,
    %   ldem.solver.dampingRegistry, ldem.solver.integrateStep.

    properties (Abstract, Constant)
        % Name used in the case file ("mass_proportional").
        name
    end

    methods (Abstract)
        % COEFFICIENT  Mass-proportional damping coefficient of a step [1/s].
        %
        %   c = model.coefficient(step, params), with step = 1, 2, ... and
        %   params an ldem.Parameters (the model reads the parameters it needs).
        c = coefficient(obj, step, params)
    end
end
