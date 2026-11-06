classdef TestScenarios < LdemTestCase
    %TESTSCENARIOS  Unit tests of ldem.scenarios and ldem.solver.checkStability.

    methods (Test, TestTags = {'Unit'})
        function factoryReturnsTheRightClass(testCase)
            testCase.verifyClass(ldem.scenarios.fromTestId(101), ...
                'ldem.scenarios.UniaxialTension');
            testCase.verifyClass(ldem.scenarios.fromTestId(102), ...
                'ldem.scenarios.FourPointBending');
        end

        function factoryRejectsUnknownTest(testCase)
            testCase.verifyError(@() ldem.scenarios.fromTestId(7), ...
                'ldem:scenarios:unknownTest');
        end

        function everyScenarioIsRegisteredUnderItsOwnId(testCase)
            for id = [101 102]
                testCase.verifyEqual(ldem.scenarios.fromTestId(id).testId, id);
            end
        end

        function tensionHoldsTheCentreNodesOfBothEndColumnsInX(testCase)
            params = ldem.Parameters(testId=101, nModules=[6 3 3]);
            nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            scenario = ldem.scenarios.UniaxialTension();
            fixed = scenario.fixedDofs(nodes, params);
            loaded = scenario.loadedNodes(nodes, params);

            testCase.verifySize(fixed, [params.nNodes 3]);
            testCase.verifyFalse(any(fixed(:, 2:3), 'all'), 'Only x may be fixed.');
            % Centre nodes of the first and of the last column of modules:
            % 2 columns of (N-1)*(L-1) = 4 nodes.
            testCase.verifyEqual(nnz(fixed(:, 1)), 8);
            lco = params.moduleLength;
            testCase.verifyEqual(unique(round(nodes(fixed(:, 1), 1) / lco * 2) / 2).', [0.5, 4.5]);
            % The loaded nodes are the right column, and they are held (exact prescribed motion).
            testCase.verifyEqual(nnz(loaded), 4);
            testCase.verifyTrue(all(fixed(loaded, 1)));
        end

        function bendingFixesYAtEverySupportAndLoadPoint(testCase)
            params = ldem.Parameters(testId=102, nModules=[70 4 3]);
            nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            fixed = ldem.scenarios.FourPointBending().fixedDofs(nodes, params);

            testCase.verifySize(fixed, [params.nNodes 3]);
            testCase.verifyFalse(any(fixed(:, 3)), 'z must stay free.');
            testCase.verifyTrue(all(fixed(fixed(:, 1), 2)), ...
                'A node fixed in x must also be fixed in y (left support).');
            testCase.verifyGreaterThan(nnz(fixed(:, 2)), nnz(fixed(:, 1)));
        end

        function bendingLoadsBothPointsOnTheTopFace(testCase)
            params = ldem.Parameters(testId=102, nModules=[70 4 3]);
            nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            scenario = ldem.scenarios.FourPointBending();
            loaded = scenario.loadedNodes(nodes, params);
            lco = params.moduleLength;

            % Two lines of (L-1) centre nodes, at 33.5 modules from each end.
            testCase.verifyEqual(nnz(loaded), 2 * (params.nModules(3) - 1));
            testCase.verifyEqual(unique(round(nodes(loaded, 1) / lco * 2) / 2).', [33.5, 35.5]);
            testCase.verifyEqual(unique(round(nodes(loaded, 2) / lco * 2) / 2).', 2.5);
            fixed = scenario.fixedDofs(nodes, params);
            testCase.verifyTrue(all(fixed(loaded, 2)), 'Loaded nodes must be held in y.');
        end

        function bendingPositionsAreParameters(testCase)
            % A short beam with supports and load points placed by the user.
            params = ldem.Parameters(testId=102, nModules=[30 4 3]);
            nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            scenario = ldem.scenarios.FourPointBending(supportPosition=2.5, loadPosition=10.5);
            lco = params.moduleLength;

            loaded = scenario.loadedNodes(nodes, params);
            testCase.verifyEqual(unique(round(nodes(loaded, 1) / lco * 2) / 2).', [10.5, 18.5]);
            fixed = scenario.fixedDofs(nodes, params);
            testCase.verifyEqual(unique(round(nodes(fixed(:, 1), 1) / lco * 2) / 2).', 2.5);
            testCase.verifyEqual(scenario.supportPosition, 2.5);
            testCase.verifyEqual(ldem.scenarios.FourPointBending().supportPosition, 4.5, ...
                'The defaults must be the legacy values.');
        end

        function bendingReportsPositionsThatMatchNoNode(testCase)
            % The default positions need a beam longer than about 70 modules.
            params = ldem.Parameters(testId=102, nModules=[30 4 3]);
            nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            testCase.verifyError( ...
                @() ldem.scenarios.FourPointBending().fixedDofs(nodes, params), ...
                'ldem:scenarios:noNodesSelected');
            % Positions that fall between two lines of centre nodes.
            scenario = ldem.scenarios.FourPointBending(supportPosition=2.0, loadPosition=10.5);
            testCase.verifyError(@() scenario.fixedDofs(nodes, params), ...
                'ldem:scenarios:noNodesSelected');
        end

        function stabilityCheckReturnsCriticalStep(testCase)
            params = ldem.Parameters();
            lengths = [0.003; 0.0026; 0.003];
            critical = ldem.solver.checkStability(lengths, params);
            testCase.verifyEqual(critical, 0.0026 / params.waveSpeed, 'RelTol', 1e-12);
        end

        function stabilityCheckRejectsShortBars(testCase)
            params = ldem.Parameters();
            testCase.verifyError( ...
                @() ldem.solver.checkStability([1e-5; 0.003], params), ...
                'ldem:params:unstableTimeStep');
        end

        function regularLatticeMatchesParametersEstimate(testCase)
            params = ldem.Parameters(nModules=[4 3 3]);
            mesh = ldem.mesh.buildMesh(params);
            critical = ldem.solver.checkStability(mesh.barLength, params);
            testCase.verifyEqual(critical, params.criticalTimeStep, 'RelTol', 1e-12);
        end
    end
end
