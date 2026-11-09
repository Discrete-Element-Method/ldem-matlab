classdef BilinearBarLaw < ldem.material.MaterialLaw
    %BILINEARBARLAW  Linear elastic in compression, bilinear with softening in tension.
    %
    %   The law of the legacy code: every bar is linear elastic with stiffness
    %   E1 up to the critical strain EP, then softens linearly down to zero
    %   force at the rupture strain ER = KR*EP, after which it is broken and
    %   carries no load. Unloading follows the secant stiffness. The details
    %   and the history fields are in ldem.material.bilinearLaw (the function
    %   this class calls); the case-file name is "bilinear".
    %
    %   See also ldem.material.MaterialLaw, ldem.material.bilinearLaw.

    properties (Constant)
        name = "bilinear"
    end

    methods
        function [force, history] = evaluate(~, strain, strainRate, barProps, history, params)
            %EVALUATE  See ldem.material.bilinearLaw.
            [force, history] = ldem.material.bilinearLaw( ...
                strain, strainRate, barProps, history, params.constitutiveDamping);
        end

        function energy = energies(~, strain, barProps, history, barLength)
            %ENERGIES  Elastic, damage and broken-bar energy of the bilinear bars.
            %
            %   For a damaged bar with critical strain EP, largest strain EM and
            %   stiffnesses E1 (compression) and E2 (tension) the energy
            %   dissipated is L/2 times E1*EP^2 - E2*EM^2 + (E1*EP + E2*EM)*(EM - EP);
            %   for a broken bar the fracture energy is L/2 * E1*EP^2*KR.
            E1 = barProps.stiffness;
            E2 = history.tensionStiffness;
            stiffness = E1;
            stiffness(strain >= 0.0) = E2(strain >= 0.0);
            elastic = sum(stiffness .* (strain .* strain .* barLength ./ 2));

            EP = barProps.criticalStrain;
            EM = history.maxStrain;
            damaged = ~history.isUndamaged;
            area = E1 .* EP .* EP - E2 .* EM .* EM + (E1 .* EP + E2 .* EM) .* (EM - EP);
            damage = sum(barLength(damaged) .* area(damaged) ./ 2);

            broken = damaged & ~history.isUnbroken;
            brokenBars = sum(E1(broken) .* EP(broken) .* EP(broken) .* barProps.ruptureRatio(broken) ...
                .* barLength(broken) ./ 2);

            energy = struct('elastic', elastic, 'damage', damage, 'brokenBars', brokenBars);
        end

        function value = barDamageEnergy(~, bar, barProps, history, barLength)
            %BARDAMAGEENERGY  Energy dissipated by damage in one bar (zero if undamaged).
            if history.isUndamaged(bar)
                value = 0.0;
                return
            end
            E1 = barProps.stiffness(bar);
            E2 = history.tensionStiffness(bar);
            EP = barProps.criticalStrain(bar);
            EM = history.maxStrain(bar);
            area = E1 * EP * EP - E2 * EM * EM + (E1 * EP + E2 * EM) * (EM - EP);
            value = barLength(bar) * area / 2;
        end

        function stiffness = viscousStiffness(~, strain, barProps, history)
            %VISCOUSSTIFFNESS  Compression stiffness for compressed bars, tension stiffness otherwise.
            isCompressed = strain < 0.0;
            stiffness = history.tensionStiffness;
            stiffness(isCompressed) = barProps.stiffness(isCompressed);
        end
    end
end
