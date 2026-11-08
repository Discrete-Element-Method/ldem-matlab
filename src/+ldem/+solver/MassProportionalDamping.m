classdef MassProportionalDamping < ldem.solver.DampingModel
    %MASSPROPORTIONALDAMPING  Constant coefficient that switches once (legacy damping).
    %
    %   The coefficient is params.dampingInitial before the switch step and
    %   params.dampingFinal from then on, see ldem.solver.dampingCoefficient. The
    %   case-file name is "mass_proportional", with the keys initial, final and
    %   switch_time.
    %
    %   See also ldem.solver.DampingModel, ldem.solver.dampingCoefficient.

    properties (Constant)
        name = "mass_proportional"
    end

    methods
        function c = coefficient(~, step, params)
            %COEFFICIENT  dampingInitial before the switch, dampingFinal after.
            c = ldem.solver.dampingCoefficient(step, params);
        end
    end
end
