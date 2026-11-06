classdef TestSolver < LdemTestCase
    %TESTSOLVER  Unit tests of the solver routines with analytical solutions.
    %
    %   The main model is a single bar: node 1 is fixed and node 2 (mass m)
    %   moves along x. The bar force is E1*strain, so it behaves as a spring
    %   of constant k = E1/L and natural frequency  omega = sqrt(k/m).

    properties (Constant)
        E1 = 1e6        % bar stiffness [N]
        L  = 0.01       % bar length [m]
        Mass = 0.1      % mass of the free node [kg]
        Stretch = 1e-6  % initial elongation [m]
    end

    methods (Access = private)
        function [mesh, barProps, history] = oscillator(testCase)
            mesh = struct( ...
                'nodes0',    [0 0 0; testCase.L 0 0], ...
                'bars',      [1 2], ...
                'barLength', testCase.L, ...
                'mass',      [testCase.Mass; testCase.Mass], ...
                'fixed',     [true true true; false true true]);
            barProps = struct( ...
                'stiffness',      testCase.E1, ...
                'criticalStrain', 1, ...
                'ruptureRatio',   10, ...
                'ruptureStrain',  10);
            history = struct('tensionStiffness', testCase.E1, 'maxStrain', 1, ...
                'isUndamaged', true, 'isUnbroken', true);
        end

        function omega = naturalFrequency(testCase)
            omega = sqrt(testCase.E1 / testCase.L / testCase.Mass);
        end

        function [x, states, params] = runOscillator(testCase, damping, nSteps)
            % Release node 2 from rest at x = L + Stretch and integrate.
            params = ldem.Parameters(dt=2e-7, dampingInitial=damping, dampingFinal=damping, ...
                dampingSwitchTime=1);
            [mesh, barProps, history] = testCase.oscillator();
            state = ldem.solver.initialState(mesh, history);

            omega = testCase.naturalFrequency();
            c = damping;
            omegaD = sqrt(omega^2 - c^2 / 4);
            u0 = testCase.Stretch;
            % Exact position one step before time zero, for zero initial velocity.
            previous = @(t) u0 * exp(-c * t / 2) * (cos(omegaD * t) + c / (2 * omegaD) * sin(omegaD * t));
            state.displacement(2, 1) = testCase.L + u0;
            state.previousDisplacement(2, 1) = testCase.L + previous(-params.dt);

            x = zeros(nSteps, 1);
            states = cell(nSteps, 1);
            for n = 1:nSteps
                state.step = n;
                state.time = state.time + params.dt;
                state = ldem.solver.computeBarForces(state, mesh, barProps, params);
                state = ldem.solver.integrateStep(state, mesh, barProps, params);
                x(n) = state.displacement(2, 1) - testCase.L;
                states{n} = state;
            end
        end
    end

    methods (Test, TestTags = {'Unit'})
        function constantForceGivesTheDiscreteParabola(testCase)
            % u_n = a*dt^2*n*(n+1)/2 for the scheme started from rest.
            params = ldem.Parameters(dampingInitial=0, dampingFinal=0);
            mesh = struct('nodes0', [0 0 0], 'bars', zeros(0, 2), 'barLength', zeros(0, 1), ...
                'mass', 2, 'fixed', false(1, 3));
            barProps = struct('stiffness', zeros(0, 1));
            history = struct();
            state = ldem.solver.initialState(mesh, history);
            force = 6;
            a = force / 2;

            for n = 1:20
                state.step = n;
                state.force = [force 0 0];
                state.strain = zeros(0, 1);
                state.history = struct('tensionStiffness', zeros(0, 1));
                state = ldem.solver.integrateStep(state, mesh, barProps, params);
                testCase.verifyEqual(state.displacement(1), a * params.dt^2 * n * (n + 1) / 2, ...
                    'RelTol', 1e-12);
            end
            testCase.verifyEqual(state.displacement(2:3), [0 0]);
        end

        function undampedOscillatorFollowsTheCosine(testCase)
            nSteps = 2000;                         % about two periods
            [x, ~, params] = testCase.runOscillator(0, nSteps);
            t = (1:nSteps).' * params.dt;
            expected = testCase.Stretch * cos(testCase.naturalFrequency() * t);
            testCase.verifyEqual(x, expected, 'AbsTol', 1e-3 * testCase.Stretch);
        end

        function dampedOscillatorDecaysAsExpected(testCase)
            damping = 4000;                        % [1/s]
            nSteps = 2500;
            [x, ~, params] = testCase.runOscillator(damping, nSteps);
            t = (1:nSteps).' * params.dt;
            omegaD = sqrt(testCase.naturalFrequency()^2 - damping^2 / 4);
            expected = testCase.Stretch * exp(-damping * t / 2) .* ...
                (cos(omegaD * t) + damping / (2 * omegaD) * sin(omegaD * t));
            testCase.verifyEqual(x, expected, 'AbsTol', 1e-3 * testCase.Stretch);
            testCase.verifyLessThan(abs(x(end)), 0.7 * testCase.Stretch);
        end

        function energyIsConservedWithoutDamping(testCase)
            nSteps = 2000;
            [~, states, params] = testCase.runOscillator(0, nSteps);
            [mesh, barProps, ~] = testCase.oscillator();
            initial = 0.5 * testCase.E1 / testCase.L * testCase.Stretch^2;
            for n = [1 500 1000 2000]
                e = ldem.solver.computeEnergies(states{n}, mesh, barProps, params);
                testCase.verifyEqual(e.kinetic + e.elastic, initial, 'RelTol', 2e-3);
                testCase.verifyEqual(e.damping, 0);
            end
        end

        function dampingEnergyBalancesTheLostEnergy(testCase)
            damping = 4000;
            nSteps = 2500;
            [~, states, params] = testCase.runOscillator(damping, nSteps);
            [mesh, barProps, ~] = testCase.oscillator();
            initial = 0.5 * testCase.E1 / testCase.L * testCase.Stretch^2;
            for n = [500 1500 2500]
                e = ldem.solver.computeEnergies(states{n}, mesh, barProps, params);
                testCase.verifyEqual(e.kinetic + e.elastic + e.damping, initial, 'RelTol', 5e-3);
            end
            testCase.verifyGreaterThan(e.damping, 0);
        end

        function fixedDofsDoNotMove(testCase)
            [~, states, ~] = testCase.runOscillator(1000, 50);
            last = states{end};
            testCase.verifyEqual(last.displacement(1, :), [0 0 0]);
            testCase.verifyEqual(last.displacement(2, 2:3), [0 0]);
        end

        function movingSupportBalancesTheEnergy(testCase)
            % Node 1 is held but moves with constant velocity (prescribed motion);
            % node 2 is free. The work done at node 1 must equal the energy stored.
            params = ldem.Parameters(dt=2e-7, dampingInitial=0, dampingFinal=0);
            [mesh, barProps, history] = testCase.oscillator();
            mesh.fixed(1, :) = true;
            % The kinetic energy of a prescribed node is not supplied by the work
            % of the bar force, so make it negligible (a real lattice has the same
            % property: the prescribed nodes are a tiny part of the mass).
            mesh.mass(1) = 1e-12;
            state = ldem.solver.initialState(mesh, history);
            velocity = 1e-3;                                  % [m/s]

            nSteps = 3000;
            for n = 1:nSteps
                state.step = n;
                state.time = state.time + params.dt;
                state.displacement(1, 1) = velocity * state.time;     % prescribed
                state = ldem.solver.computeBarForces(state, mesh, barProps, params);
                state = ldem.solver.integrateStep(state, mesh, barProps, params);
            end
            e = ldem.solver.computeEnergies(state, mesh, barProps, params);

            testCase.verifyGreaterThan(e.external, 0, 'Pushing the structure is positive work.');
            testCase.verifyEqual(e.internal, e.external, 'RelTol', 5e-3);
            testCase.verifyEqual(e.balance, e.external - e.internal);
        end

        function aSupportThatDoesNotMoveDoesNoWork(testCase)
            [~, states, ~] = testCase.runOscillator(1000, 500);
            testCase.verifyEqual(states{end}.externalEnergy, 0);
        end

        function integrateRejectsZeroMass(testCase)
            params = ldem.Parameters();
            [mesh, barProps, history] = testCase.oscillator();
            mesh.mass(2) = 0;
            state = ldem.solver.initialState(mesh, history);
            testCase.verifyError(@() ldem.solver.integrateStep(state, mesh, barProps, params), ...
                'ldem:solver:zeroMass');
        end

        function stretchedBarPullsItsNodesTogether(testCase)
            params = ldem.Parameters();
            [mesh, barProps, history] = testCase.oscillator();
            state = ldem.solver.initialState(mesh, history);
            state.displacement(2, 1) = testCase.L + testCase.Stretch;
            state = ldem.solver.computeBarForces(state, mesh, barProps, params);

            expectedForce = testCase.E1 * testCase.Stretch / testCase.L;
            testCase.verifyEqual(state.axialForce, expectedForce, 'RelTol', 1e-9);
            testCase.verifyEqual(state.force(1, :), [expectedForce 0 0], 'RelTol', 1e-9, 'AbsTol', 1e-12);
            testCase.verifyEqual(state.force(2, :), [-expectedForce 0 0], 'RelTol', 1e-9, 'AbsTol', 1e-12);
        end

        function compressedBarPushesItsNodesApart(testCase)
            params = ldem.Parameters();
            [mesh, barProps, history] = testCase.oscillator();
            state = ldem.solver.initialState(mesh, history);
            state.displacement(2, 1) = testCase.L - testCase.Stretch;
            state = ldem.solver.computeBarForces(state, mesh, barProps, params);

            testCase.verifyLessThan(state.axialForce, 0);
            testCase.verifyLessThan(state.force(1, 1), 0);
            testCase.verifyGreaterThan(state.force(2, 1), 0);
        end

        function barDirectionIsFollowedWhenItRotates(testCase)
            params = ldem.Parameters();
            [mesh, barProps, history] = testCase.oscillator();
            state = ldem.solver.initialState(mesh, history);
            state.displacement(2, :) = [testCase.L, 0, 0] + testCase.L * 1e-3 * [0.6 0.8 0];
            state = ldem.solver.computeBarForces(state, mesh, barProps, params);
            direction = state.force(1, :) / norm(state.force(1, :));
            delta = state.displacement(2, :) - state.displacement(1, :);
            testCase.verifyEqual(direction, delta / norm(delta), 'AbsTol', 1e-12);
        end

        function forcesOnTheLatticeAddUpToZero(testCase)
            % Internal forces are in equilibrium: Newton's third law.
            params = ldem.Parameters(nModules=[4 3 3]);
            mesh = ldem.mesh.buildMesh(params);
            [barProps, history] = ldem.material.buildBarProperties(mesh, params);
            state = ldem.solver.initialState(mesh, history);
            rng(1);
            state.displacement = mesh.nodes0 + 1e-6 * randn(size(mesh.nodes0));
            state = ldem.solver.computeBarForces(state, mesh, barProps, params);

            testCase.verifyGreaterThan(max(abs(state.force), [], 'all'), 0);
            testCase.verifyLessThan(max(abs(sum(state.force, 1))), 1e-9 * max(abs(state.force), [], 'all'));
        end

        function latticeAtRestHasNoForce(testCase)
            params = ldem.Parameters(nModules=[4 3 3]);
            mesh = ldem.mesh.buildMesh(params);
            [barProps, history] = ldem.material.buildBarProperties(mesh, params);
            state = ldem.solver.initialState(mesh, history);
            state = ldem.solver.computeBarForces(state, mesh, barProps, params);
            testCase.verifyEqual(state.force, zeros(size(state.force)), 'AbsTol', 1e-9);
            testCase.verifyEqual(state.strain, zeros(size(state.strain)), 'AbsTol', 1e-14);
        end

        function coincidentNodesAreReported(testCase)
            params = ldem.Parameters();
            [mesh, barProps, history] = testCase.oscillator();
            state = ldem.solver.initialState(mesh, history);
            state.displacement(2, :) = state.displacement(1, :);
            testCase.verifyError(@() ldem.solver.computeBarForces(state, mesh, barProps, params), ...
                'ldem:solver:zeroLengthBar');
        end

        function dampingCoefficientSwitchesAtTheSwitchStep(testCase)
            params = ldem.Parameters(dt=2e-7, dampingInitial=100, dampingFinal=50, ...
                dampingSwitchTime=1e-5);                  % switch step 50
            testCase.verifyEqual(ldem.solver.dampingCoefficient(1, params), 100);
            testCase.verifyEqual(ldem.solver.dampingCoefficient(49, params), 100);
            testCase.verifyEqual(ldem.solver.dampingCoefficient(50, params), 50);
            testCase.verifyEqual(ldem.solver.dampingCoefficient(500, params), 50);
        end

        function dampingNeverSwitchesWhenTheSwitchStepIsZero(testCase)
            % Same behaviour as the legacy code (STEP == NDAMF with NDAMF = 0).
            params = ldem.Parameters(dt=2e-7, dampingInitial=100, dampingFinal=50, ...
                dampingSwitchTime=0);
            testCase.verifyEqual(ldem.solver.dampingCoefficient(1, params), 100);
            testCase.verifyEqual(ldem.solver.dampingCoefficient(1000, params), 100);
        end
    end
end
