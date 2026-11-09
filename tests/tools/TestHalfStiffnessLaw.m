classdef TestHalfStiffnessLaw < ldem.material.MaterialLaw
    %TESTHALFSTIFFNESSLAW  A constitutive law that is not in the registry (for the tests).
    %
    %   The force of a bar is half of the linear elastic one, E1*strain/2. The
    %   tests pass an object of this class to the solver to check that a new law
    %   plugs in without touching the solver.
    %
    %   See also ldem.material.MaterialLaw.

    properties (Constant)
        name = "half_stiffness"
    end

    methods
        function [force, history] = evaluate(~, strain, ~, barProps, history, ~)
            force = 0.5 * barProps.stiffness .* strain;
        end

        function energy = energies(~, strain, barProps, ~, barLength)
            elastic = sum(0.5 * barProps.stiffness .* (strain .* strain .* barLength ./ 2));
            energy = struct('elastic', elastic, 'damage', 0, 'brokenBars', 0);
        end

        function value = barDamageEnergy(~, ~, ~, ~, ~)
            value = 0;
        end

        function stiffness = viscousStiffness(~, ~, barProps, ~)
            stiffness = 0.5 * barProps.stiffness;
        end
    end
end
