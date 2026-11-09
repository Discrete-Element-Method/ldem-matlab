classdef LinearElasticBarLaw < ldem.material.MaterialLaw
    %LINEARELASTICLAW  Linear elastic bars that never damage or break.
    %
    %   The force of a bar is E1*strain in tension and in compression, plus the
    %   viscous term E1*constitutiveDamping*strainRate. There is no softening
    %   and no rupture, so the damage energy is zero and every bar stays intact.
    %   It is useful to verify a model against elastic solutions (waves,
    %   vibration, static deflection) and to separate geometry and loading
    %   problems from damage. The case-file name is "linear_elastic".
    %
    %   The fracture parameters (fractureEnergy, criticalDistance,
    %   failureAreaFactor) and the random scatter are still read and computed
    %   by ldem.material.buildBarProperties, but this law does not use them.
    %
    %   See also ldem.material.MaterialLaw, ldem.material.BilinearBarLaw.

    properties (Constant)
        name = "linear_elastic"
    end

    methods
        function [force, history] = evaluate(~, strain, strainRate, barProps, history, params)
            %EVALUATE  E1*(strain + constitutiveDamping*strainRate), history unchanged.
            force = barProps.stiffness .* strain ...
                + barProps.stiffness .* params.constitutiveDamping .* strainRate;
        end

        function energy = energies(~, strain, barProps, ~, barLength)
            %ENERGIES  Sum of E1*strain^2*L/2; no damage and no broken bars.
            elastic = sum(barProps.stiffness .* (strain .* strain .* barLength ./ 2));
            energy = struct('elastic', elastic, 'damage', 0, 'brokenBars', 0);
        end

        function value = barDamageEnergy(~, ~, ~, ~, ~)
            %BARDAMAGEENERGY  Always zero.
            value = 0.0;
        end

        function stiffness = viscousStiffness(~, ~, barProps, ~)
            %VISCOUSSTIFFNESS  E1 for every bar.
            stiffness = barProps.stiffness;
        end
    end
end
