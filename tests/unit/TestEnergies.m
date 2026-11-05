classdef TestEnergies < LdemTestCase
    %TESTENERGIES  Unit tests of ldem.solver.computeEnergies with hand-made states.

    methods (Access = private)
        function [mesh, barProps, history, state, params] = oneBar(~)
            % One bar of length 1 between two nodes of mass 2 kg and 3 kg.
            params = ldem.Parameters();
            mesh = struct('nodes0', [0 0 0; 1 0 0], 'bars', [1 2], 'barLength', 1, ...
                'mass', [2; 3], 'fixed', false(2, 3));
            barProps = struct('stiffness', 100, 'criticalStrain', 1e-3, ...
                'ruptureRatio', 5, 'ruptureStrain', 5e-3);
            history = struct('tensionStiffness', 100, 'maxStrain', 1e-3, ...
                'isUndamaged', true, 'isUnbroken', true);
            state = ldem.solver.initialState(mesh, history);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function everythingIsZeroAtRest(testCase)
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            for name = {'kinetic', 'elastic', 'damage', 'damping', 'internal', 'brokenBars', 'damageRate'}
                testCase.verifyEqual(e.(name{1}), 0, name{1});
            end
        end

        function kineticEnergyIsHalfMassTimesSpeedSquared(testCase)
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.velocity = [3 4 0; 0 0 2];             % speeds 5 and 2
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            testCase.verifyEqual(e.kinetic, 0.5 * 2 * 25 + 0.5 * 3 * 4, 'RelTol', 1e-14);
        end

        function elasticEnergyOfATensionedBar(testCase)
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.strain = 5e-4;
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            testCase.verifyEqual(e.elastic, 0.5 * 100 * (5e-4)^2 * 1, 'RelTol', 1e-14);
        end

        function elasticEnergyOfACompressedBarUsesTheCompressionStiffness(testCase)
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.history.tensionStiffness = 10;          % damaged in tension
            state.strain = -5e-4;
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            testCase.verifyEqual(e.elastic, 0.5 * 100 * (5e-4)^2, 'RelTol', 1e-14);
        end

        function damageEnergyOfASofteningBar(testCase)
            % Bar loaded to strain 2e-3 on the softening branch (see TestBilinearLaw):
            % work 1.375e-4 minus stored energy 7.5e-5.
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.strain = 2e-3;
            state.history.tensionStiffness = 37.5;
            state.history.maxStrain = 2e-3;
            state.history.isUndamaged = false;
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            testCase.verifyEqual(e.damage, 6.25e-5, 'RelTol', 1e-12);
            testCase.verifyEqual(e.elastic, 0.5 * 37.5 * (2e-3)^2, 'RelTol', 1e-12);
            testCase.verifyEqual(e.brokenBars, 0);
        end

        function brokenBarDissipatesTheWholeFractureEnergy(testCase)
            % Area under the whole softening curve: E1*EP*ER/2 per unit length.
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.strain = 6e-3;
            state.history.tensionStiffness = 0;
            state.history.maxStrain = 5e-3;               % ER
            state.history.isUndamaged = false;
            state.history.isUnbroken = false;
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            expected = 0.5 * 100 * 1e-3 * 5e-3;
            testCase.verifyEqual(e.damage, expected, 'RelTol', 1e-12);
            testCase.verifyEqual(e.brokenBars, expected, 'RelTol', 1e-12);
        end

        function internalEnergyIsTheSumOfItsParts(testCase)
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.velocity = [1 0 0; 0 0 0];
            state.strain = 5e-4;
            state.dampingEnergy = 0.25;
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            testCase.verifyEqual(e.internal, e.kinetic + e.elastic + e.damage + 0.25, 'RelTol', 1e-14);
            testCase.verifyEqual(e.damping, 0.25);
        end

        function damageRateUsesThePreviousStep(testCase)
            [mesh, barProps, ~, state, params] = testCase.oneBar();
            state.strain = 2e-3;
            state.history.tensionStiffness = 37.5;
            state.history.maxStrain = 2e-3;
            state.history.isUndamaged = false;
            state.previousDamageEnergy = 6.25e-5 - 1e-6;
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);
            testCase.verifyEqual(e.damageRate, 1e-6 / params.dt, 'RelTol', 1e-6);
        end
    end
end
