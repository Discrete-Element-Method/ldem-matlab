classdef TestSimulate < LdemTestCase
    %TESTSIMULATE  Unit tests of the scenario loads and of ldem.solver.simulate.

    methods (Access = private)
        function [params, mesh, barProps, history, scenario] = smallModel(~, varargin)
            params = ldem.Parameters(varargin{:});
            mesh = ldem.mesh.buildMesh(params);
            [barProps, history] = ldem.material.buildBarProperties(mesh, params);
            scenario = ldem.scenarios.fromTestId(params.testId);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function tensionLoadMovesTheLastColumnOfCentreNodes(testCase)
            [params, mesh, ~, history, scenario] = testCase.smallModel(testId=101);
            state = ldem.solver.initialState(mesh, history);
            state.time = 1e-4;
            state = scenario.applyLoads(state, mesh, params);

            loaded = scenario.loadedNodes(mesh.nodes0, params);
            testCase.verifyEqual(nnz(loaded), (params.nModules(2) - 1) * (params.nModules(3) - 1));
            testCase.verifyEqual(state.displacement(loaded, 1), ...
                mesh.nodes0(loaded, 1) - 400e-5 * 1e-4, 'RelTol', 1e-14);
            % Everything else is untouched, and y, z of the loaded nodes too.
            testCase.verifyEqual(state.displacement(~loaded, :), mesh.nodes0(~loaded, :));
            testCase.verifyEqual(state.displacement(loaded, 2:3), mesh.nodes0(loaded, 2:3));
        end

        function loadingVelocityCanBeChanged(testCase)
            [params, mesh, ~, history, ~] = testCase.smallModel(testId=101);
            scenario = ldem.scenarios.UniaxialTension(loadingVelocity=-1e-3);
            state = ldem.solver.initialState(mesh, history);
            state.time = 2e-4;
            state = scenario.applyLoads(state, mesh, params);
            loaded = scenario.loadedNodes(mesh.nodes0, params);
            % Negative velocity pulls the loaded nodes away from the fixed end.
            testCase.verifyGreaterThan(min(state.displacement(loaded, 1) - mesh.nodes0(loaded, 1)), 0);
        end

        function bendingLoadMovesOnlyTheRightLoadPoint(testCase)
            [params, mesh, ~, history, scenario] = testCase.smallModel(testId=102, nModules=[70 4 3]);
            state = ldem.solver.initialState(mesh, history);
            state.time = 1e-4;
            state = scenario.applyLoads(state, mesh, params);

            loaded = scenario.loadedNodes(mesh.nodes0, params);
            testCase.verifyEqual(nnz(loaded), params.nModules(3) - 1);
            testCase.verifyEqual(state.displacement(loaded, 2), ...
                mesh.nodes0(loaded, 2) - 400e-5 * 1e-4, 'RelTol', 1e-14);
            testCase.verifyTrue(all(mesh.fixed(loaded, 2)), 'Loaded nodes must be held in y.');
            testCase.verifyEqual(state.displacement(~loaded, :), mesh.nodes0(~loaded, :));
        end

        function reactionIsUndefinedForTensionAndSummedForBending(testCase)
            [params, mesh, ~, history, tension] = testCase.smallModel(testId=101);
            state = ldem.solver.initialState(mesh, history);
            testCase.verifyTrue(all(isnan(tension.reactions(state, mesh, params))));

            [params, mesh, ~, history, bending] = testCase.smallModel(testId=102, nModules=[70 4 3]);
            state = ldem.solver.initialState(mesh, history);
            atTop = mesh.fixed(:, 2) & mesh.nodes0(:, 2) >= params.moduleLength * (params.nModules(2) - 1.51);
            state.force(atTop, 2) = 1.5;
            r = bending.reactions(state, mesh, params);
            testCase.verifyEqual(r, [0, 1.5 * nnz(atTop), 0]);
        end

        function simulateStoresTheRequestedResults(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel( ...
                nModules=[4 3 3], totalTime=4e-6, controlNodes=[1 2 3], ...
                output=struct('snapshotEvery', 0, 'controlNodesEvery', 4, ...
                    'energyEvery', 5, 'trackedBarEvery', 0));
            [state, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario);

            testCase.verifyEqual(state.step, 20);
            testCase.verifyEqual(state.time, 20 * params.dt, 'RelTol', 1e-12);
            testCase.verifySize(record.controlNodes.time, [5 1]);
            testCase.verifySize(record.controlNodes.displacement, [5 3 3]);
            testCase.verifySize(record.controlNodes.acceleration, [5 3 3]);
            testCase.verifySize(record.reactions.force, [5 3]);
            testCase.verifySize(record.energy.time, [4 1]);
            testCase.verifyEqual(record.controlNodes.time, (4:4:20).' * params.dt, 'RelTol', 1e-12);
            testCase.verifyEqual(record.energy.time, (5:5:20).' * params.dt, 'RelTol', 1e-12);
            testCase.verifyEmpty(record.trackedBar.time);
            testCase.verifyEqual(record.controlNodes.displacement(end, :, :), ...
                reshape(state.displacement(params.controlNodes, :), 1, 3, 3));
        end

        function simulateRecordsTheTrackedBarAtEveryStep(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel( ...
                nModules=[4 3 3], totalTime=2e-6, trackedBar=5, ...
                output=struct('snapshotEvery', 0, 'controlNodesEvery', 0, ...
                    'energyEvery', 0, 'trackedBarEvery', 1));
            [state, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario);

            testCase.verifySize(record.trackedBar.time, [10 1]);
            testCase.verifyEqual(record.trackedBar.bar, 5);
            testCase.verifyEqual(record.trackedBar.strain(end), state.strain(5));
            testCase.verifyEqual(record.trackedBar.force(end), state.axialForce(5));
            testCase.verifyEqual(record.trackedBar.criticalStrain(1), barProps.criticalStrain(5));
            testCase.verifyEmpty(record.controlNodes.time);
            testCase.verifyEmpty(record.energy.time);
        end

        function aTrackedBarThatDoesNotExistIsIgnored(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel( ...
                nModules=[3 3 3], totalTime=1e-6, trackedBar=999999, ...
                output=struct('snapshotEvery', 0, 'controlNodesEvery', 0, ...
                    'energyEvery', 0, 'trackedBarEvery', 1));
            [~, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario);
            testCase.verifyEmpty(record.trackedBar.time);
        end

        function snapshotFunctionIsCalledAtTimeZeroAndPeriodically(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel( ...
                nModules=[3 3 3], totalTime=4e-6, ...
                output=struct('snapshotEvery', 5, 'controlNodesEvery', 0, ...
                    'energyEvery', 0, 'trackedBarEvery', 0));
            snapshotLog("reset");
            ldem.solver.simulate(params, mesh, barProps, history, scenario, ...
                SnapshotFcn=@(state) snapshotLog("add", state));
            steps = snapshotLog("read");
            testCase.verifyEqual(steps, [0 5 10 15 20]);
        end

        function simulateIsDeterministic(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel(nModules=[4 3 3], totalTime=4e-6);
            a = ldem.solver.simulate(params, mesh, barProps, history, scenario);
            b = ldem.solver.simulate(params, mesh, barProps, history, scenario);
            testCase.verifyEqual(a.displacement, b.displacement);
            testCase.verifyEqual(a.force, b.force);
        end

        function loadedModelDeformsAndStaysFinite(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel(nModules=[6 3 3], totalTime=2e-5);
            state = ldem.solver.simulate(params, mesh, barProps, history, scenario);
            testCase.verifyTrue(all(isfinite(state.displacement), 'all'));
            testCase.verifyGreaterThan(max(abs(state.velocity), [], 'all'), 0);
            % Free nodes move too, not only the loaded ones (the equation of motion is integrated).
            moved = any(state.displacement ~= mesh.nodes0, 2) & ~scenario.loadedNodes(mesh.nodes0, params);
            testCase.verifyTrue(any(moved));
        end

        function nonFiniteResultsAreReported(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel(nModules=[3 3 3], totalTime=1e-6);
            barProps.stiffness(:) = NaN;
            history.tensionStiffness(:) = NaN;
            testCase.verifyError( ...
                @() ldem.solver.simulate(params, mesh, barProps, history, scenario), ...
                'ldem:solver:nonFinite');
        end

        function unstableTimeStepForTheMeshIsReported(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel(nModules=[3 3 3], totalTime=1e-6);
            mesh.barLength(1) = mesh.barLength(1) / 100;      % an unusually short bar
            testCase.verifyError( ...
                @() ldem.solver.simulate(params, mesh, barProps, history, scenario), ...
                'ldem:params:unstableTimeStep');
        end

        function aDamagedTrackedBarReportsItsDissipatedEnergy(testCase)
            output = struct('snapshotEvery', 0, 'controlNodesEvery', 0, ...
                'energyEvery', 0, 'trackedBarEvery', 0);
            base = {'nModules', [6 3 3], 'totalTime', 2e-4, 'fractureEnergy', 0.1};

            % First find a bar that softens in this simulation.
            probe = ldem.runSimulation(ldem.Parameters(base{:}, 'output', output));
            bar = find(~probe.final.damage.isUndamaged, 1);
            testCase.assumeNotEmpty(bar, 'The probe run must damage at least one bar.');

            output.trackedBarEvery = 1;
            results = ldem.runSimulation(ldem.Parameters(base{:}, 'trackedBar', bar, 'output', output));
            tracked = results.trackedBar;

            testCase.verifyEqual(tracked.damageEnergy(1), 0, 'A bar starts undamaged.');
            testCase.verifyGreaterThan(tracked.damageEnergy(end), 0);
            testCase.verifyTrue(all(diff(tracked.damageEnergy) >= -1e-18), ...
                'Dissipated energy cannot decrease.');

            % Same formula as ldem.solver.computeEnergies, for this bar only.
            h = results.final.damage;
            E1 = results.barProps.stiffness(bar);
            E2 = h.tensionStiffness(bar);
            EP = results.barProps.criticalStrain(bar);
            EM = h.maxStrain(bar);
            expected = results.mesh.barLength(bar) / 2 * ...
                (E1*EP^2 - E2*EM^2 + (E1*EP + E2*EM) * (EM - EP));
            testCase.verifyEqual(tracked.damageEnergy(end), expected, 'RelTol', 1e-12);
        end

        function bendingScenarioAcceptsALoadingVelocity(testCase)
            scenario = ldem.scenarios.FourPointBending(loadingVelocity=1e-3);
            testCase.verifyEqual(scenario.loadingVelocity, 1e-3);
            testCase.verifyEqual(ldem.scenarios.FourPointBending().loadingVelocity, 400e-5);
        end

        function verboseModePrintsProgress(testCase)
            [params, mesh, barProps, history, scenario] = testCase.smallModel(nModules=[3 3 3], totalTime=2e-6); %#ok<ASGLU>
            text = evalc('ldem.solver.simulate(params, mesh, barProps, history, scenario, Verbose=true);');
            testCase.verifySubstring(text, 'step 10 / 10');
        end
    end
end

function steps = snapshotLog(command, state)
%SNAPSHOTLOG  Collect the step numbers passed to a snapshot callback.
persistent log
if command == "reset"
    log = [];
elseif command == "add"
    log(end + 1) = state.step;
end
steps = log;
end
