classdef TestClampedBeamAgainstLegacy < LdemTestCase
    %TESTCLAMPEDBEAMAGAINSTLEGACY  The clamped beam (test 103) reproduces the original code.
    %
    %   The fixture tests/fixtures/clamped103.mat was produced by running the
    %   original program with the BOUND and CALOAD routines of the bi-clamped
    %   beam model of Rodrigo (branch dev_rodrigo, commit 3249300), which
    %   modify TEST 102. The legacy input file therefore says TEST 102, while
    %   the new code registers the same model as test 103
    %   (ldem.scenarios.ClampedBeam).
    %
    %   The fixture is a reduced version of the model (5x5x21 nodes, 1600
    %   steps, fracture energy 0.02 N/m so that bars soften and break). The
    %   comparison covers the final state, the bar state and the energies.
    %   In the original code the force applied at mid-span is added to the
    %   nodal force array (FRY), so the new nodal force is compared after
    %   adding state.appliedForce.
    %
    %   Not compared: the external energy and the balance, which the original
    %   code never computed (see docs/known-issues/KNOWN_ISSUES.md).
    %
    %   See also TestSolverAgainstLegacy, ldem.scenarios.ClampedBeam.

    properties (Constant)
        RelTol = 1e-9
    end

    methods (Test, TestTags = {'Regression'})
        function fixtureExercisesDamageAndTheLoadRamp(testCase)
            fixture = testCase.loadFixture();
            c = fixture.caseDef;
            testCase.verifyGreaterThan(nnz(~fixture.state.DM), 0, 'The fixture needs damaged bars.');
            % The 0.35 ms ramp ends inside the simulated time.
            testCase.verifyGreaterThan(c.nSteps * c.dt, 3.5e-4);
        end

        function finalStateMatchesLegacy(testCase)
            [fixture, state, ~] = testCase.runCase();
            s = fixture.state;
            nodal = @(x, y, z) [x(:), y(:), z(:)];

            testCase.compare(state.time, s.TIME, 'time');
            testCase.compare(state.displacement, nodal(s.U(2, :), s.V(2, :), s.W(2, :)), 'displacement');
            testCase.compare(state.previousDisplacement, nodal(s.U(1, :), s.V(1, :), s.W(1, :)), 'previous displacement');
            testCase.compare(state.velocity, nodal(s.VLX, s.VLY, s.VLZ), 'velocity');
            testCase.compare(state.acceleration, nodal(s.ACX, s.ACY, s.ACZ), 'acceleration');
            testCase.compare(state.force + state.appliedForce, nodal(s.FRX, s.FRY, s.FRZ), 'nodal force');
        end

        function barStateMatchesLegacy(testCase)
            [fixture, state, ~] = testCase.runCase();
            s = fixture.state;

            testCase.compare(state.strain, s.SS(:), 'strain');
            testCase.compare(state.strainRate, s.DSS(:), 'strain rate');
            testCase.compare(state.axialForce, s.F(:), 'axial force');
            testCase.compare(state.history.tensionStiffness, s.E2(:), 'tension stiffness');
            testCase.compare(state.history.maxStrain, s.EM(:), 'largest strain');
            testCase.verifyEqual(state.history.isUndamaged, logical(s.DM(:)), 'Damage flags differ.');
            testCase.verifyEqual(state.history.isUnbroken, logical(s.FS(:)), 'Rupture flags differ.');
        end

        function energiesMatchLegacy(testCase)
            [fixture, ~, record] = testCase.runCase();
            s = fixture.state;
            last = numel(record.energy.time);

            testCase.compare(record.energy.time(last), s.TIME, 'energy time');
            testCase.compare(record.energy.kinetic(last), sum(s.ENCN), 'kinetic energy');
            testCase.compare(record.energy.elastic(last), s.ENEL, 'elastic energy');
            testCase.compare(record.energy.damage(last), s.ENGD, 'damage energy');
            testCase.compare(record.energy.brokenBars(last), s.DEN, 'energy of broken bars');
            testCase.compare(record.energy.damageRate(last), s.DERIV, 'damage rate');
            testCase.compare(record.energy.damping(last), sum(s.ENDP), 'damping energy');
        end

        function energyBalanceClosesWithTheAppliedForce(testCase)
            [~, ~, record] = testCase.runCase();
            testCase.verifyGreaterThan(record.energy.external(end), 0);
            testCase.verifyLessThan(max(abs(record.energy.balance)) / record.energy.external(end), 1e-2);
        end
    end

    methods (Access = private)
        function fixture = loadFixture(testCase)
            fixture = load(fullfile(testCase.RepoRoot, 'tests', 'fixtures', 'clamped103.mat'));
        end

        function [fixture, state, record] = runCase(testCase)
            fixture = testCase.loadFixture();
            c = fixture.caseDef;
            fieldFile = fullfile(testCase.RepoRoot, 'examples', 'beam_102', 'arquivo_3lc_rnao_cv05');
            params = ldem.Parameters( ...
                testId = 103, ...      % the legacy file says 102, see the class help
                seed = c.seed, ...
                moduleLength = c.moduleLength, ...
                nModules = c.modules, ...
                dampingInitial = c.damping1, ...
                dampingFinal = c.damping2, ...
                dampingSwitchTime = c.dampingSwitchTime, ...
                constitutiveDamping = c.con, ...
                dt = c.dt, ...
                totalTime = c.nSteps * c.dt, ...
                controlNodes = c.controlNodes, ...
                youngModulus = c.youngModulus, ...
                density = c.density, ...
                poissonRatio = c.poisson, ...
                fractureEnergy = c.fractureEnergy, ...
                criticalDistance = c.criticalDistance, ...
                randomFieldFile = fieldFile, ...
                output = struct('snapshotEvery', 0, 'controlNodesEvery', c.everyN, ...
                    'energyEvery', c.everyN, 'trackedBarEvery', 0));

            mesh = ldem.mesh.buildMesh(params);
            [barProps, history] = ldem.material.buildBarProperties(mesh, params);
            scenario = ldem.scenarios.fromTestId(params.testId);
            [state, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario);
        end

        function compare(testCase, actual, expected, name)
            % Relative comparison with an absolute floor tied to the data scale.
            scale = max(abs(expected(:)));
            floor = 1e-12 * scale + realmin;
            testCase.verifyEqual(actual, expected, 'RelTol', testCase.RelTol, 'AbsTol', floor, ...
                sprintf('%s differs from the original result.', name));
        end
    end
end
