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

        function tensionFixesOnlyXOfTheLeftEndCentres(testCase)
            params = ldem.Parameters(testId=101, nModules=[6 3 3]);
            nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
            fixed = ldem.scenarios.UniaxialTension().fixedDofs(nodes, params);

            testCase.verifySize(fixed, [params.nNodes 3]);
            testCase.verifyFalse(any(fixed(:, 2:3), 'all'), 'Only x may be fixed.');
            % Centre nodes of the first module column: (N-1)*(L-1) = 4 nodes.
            testCase.verifyEqual(nnz(fixed(:, 1)), 4);
            testCase.verifyEqual(max(nodes(fixed(:, 1), 1)), 0.5 * params.moduleLength, ...
                'RelTol', 1e-12);
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
