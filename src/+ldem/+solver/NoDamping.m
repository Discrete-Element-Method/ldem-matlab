classdef NoDamping < ldem.solver.DampingModel
    %NODAMPING  No damping of the nodes (c = 0).
    %
    %   For free vibration and wave problems. The viscous term inside the law
    %   (params.constitutiveDamping) is independent and still applies. The
    %   case-file name is "none"; the keys initial, final and switch_time of
    %   [damping] do not apply.
    %
    %   See also ldem.solver.DampingModel.

    properties (Constant)
        name = "none"
    end

    methods
        function c = coefficient(~, ~, ~)
            %COEFFICIENT  Always zero.
            c = 0;
        end
    end
end
