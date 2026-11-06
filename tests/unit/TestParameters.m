classdef TestParameters < LdemTestCase
    %TESTPARAMETERS  Unit tests of ldem.Parameters.

    methods (Test, TestTags = {'Unit'})
        function defaultsAreValid(testCase)
            p = ldem.Parameters();
            testCase.verifyEqual(p.testId, 101);
            testCase.verifyEqual(p.nModules, [6 3 3]);
        end

        function nameValueOverridesProperties(testCase)
            p = ldem.Parameters(testId=102, nModules=[70 4 3], dt=1e-7);
            testCase.verifyEqual(p.testId, 102);
            testCase.verifyEqual(p.nModules, [70 4 3]);
            testCase.verifyEqual(p.dt, 1e-7);
        end

        function dependentValues(testCase)
            p = ldem.Parameters(nModules=[3 3 3], dt=2e-7, totalTime=4e-5, ...
                dampingSwitchTime=1e-5, youngModulus=32e9, density=2000);
            testCase.verifyEqual(p.nSteps, 200);
            testCase.verifyEqual(p.dampingSwitchStep, 50);
            testCase.verifyEqual(p.nNodes, 27 + 8);
            testCase.verifyEqual(p.waveSpeed, 4000, 'RelTol', 1e-12);
            testCase.verifyEqual(p.criticalTimeStep, ...
                p.moduleLength * sqrt(3) / 2 / 4000, 'RelTol', 1e-12);
        end

        function dependentPropertiesCannotBeSet(testCase)
            testCase.verifyError(@() ldem.Parameters(nSteps=10), ?MException);
        end

        function rejectsInvalidValues(testCase)
            testCase.verifyError(@() ldem.Parameters(moduleLength=-1), ?MException);
            testCase.verifyError(@() ldem.Parameters(nModules=[1 3 3]), ?MException);
            testCase.verifyError(@() ldem.Parameters(nModules=[2.5 3 3]), ?MException);
            testCase.verifyError(@() ldem.Parameters(poissonRatio=-0.1), ?MException);
            testCase.verifyError(@() ldem.Parameters(youngModulus=0), ?MException);
            testCase.verifyError(@() ldem.Parameters(dt=NaN), ?MException);
        end

        function poissonRatioMustBeBelowOneHalf(testCase)
            testCase.verifyError(@() ldem.Parameters(poissonRatio=0.5), ...
                'ldem:params:badPoissonRatio');
            p = ldem.Parameters(poissonRatio=0.499);
            testCase.verifyEqual(p.poissonRatio, 0.499);
        end

        function unstableTimeStepIsRejected(testCase)
            testCase.verifyError(@() ldem.Parameters(dt=1e-5), ...
                'ldem:params:unstableTimeStep');
        end

        function timeStepJustBelowLimitIsAccepted(testCase)
            probe = ldem.Parameters();
            p = ldem.Parameters(dt=0.999 * probe.criticalTimeStep, ...
                totalTime=probe.criticalTimeStep);
            testCase.verifyLessThan(p.dt, p.criticalTimeStep);
        end

        function totalTimeShorterThanStepIsRejected(testCase)
            testCase.verifyError(@() ldem.Parameters(dt=2e-7, totalTime=1e-7), ...
                'ldem:params:totalTimeTooShort');
        end

        function controlNodeMustExist(testCase)
            testCase.verifyError(@() ldem.Parameters(nModules=[2 2 2], controlNodes=[1 99]), ...
                'ldem:params:controlNodeOutOfRange');
        end

        function atMostTenControlNodes(testCase)
            testCase.verifyError(@() ldem.Parameters(controlNodes=1:11), ...
                'ldem:params:tooManyControlNodes');
        end

        function outputSettingsAreChecked(testCase)
            bad = struct('snapshotEvery', -1, 'controlNodesEvery', 1, ...
                'energyEvery', 1, 'trackedBarEvery', 0);
            testCase.verifyError(@() ldem.Parameters(output=bad), 'ldem:params:badOutput');

            missing = struct('snapshotEvery', 1);
            testCase.verifyError(@() ldem.Parameters(output=missing), 'ldem:params:badOutput');

            tooOften = struct('snapshotEvery', 1, 'controlNodesEvery', 1, ...
                'energyEvery', 1, 'trackedBarEvery', 5);
            testCase.verifyError(@() ldem.Parameters(output=tooOften), 'ldem:params:badOutput');
        end

        function meshPerturbationIsOffByDefaultAndMustBeNonNegative(testCase)
            testCase.verifyEqual(ldem.Parameters().meshPerturbation, 0);
            testCase.verifyEqual(ldem.Parameters(meshPerturbation=0.05).meshPerturbation, 0.05);
            testCase.verifyError(@() ldem.Parameters(meshPerturbation=-0.1), ?MException);
            testCase.verifyError(@() ldem.Parameters(meshPerturbation=Inf), ?MException);
        end

        function valueSemantics(testCase)
            a = ldem.Parameters();
            b = a;
            b.seed = 999;
            testCase.verifyEqual(a.seed, 123, 'Parameters must be a value class.');
        end

        function validateCatchesChangesAfterConstruction(testCase)
            p = ldem.Parameters();
            p.dt = 1e-5;
            testCase.verifyError(@() p.validate(), 'ldem:params:unstableTimeStep');
        end
    end
end
