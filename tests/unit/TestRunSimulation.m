classdef TestRunSimulation < LdemTestCase
    %TESTRUNSIMULATION  End-to-end tests of ldem.runSimulation and the post-processing.

    methods (Access = private)
        function params = quickParams(~, output)
            % A 100-step model on a small prism; output: how often to store results.
            if nargin < 2
                output = struct('snapshotEvery', 25, 'controlNodesEvery', 10, ...
                    'energyEvery', 10, 'trackedBarEvery', 0);
            end
            params = ldem.Parameters(nModules=[4 3 3], totalTime=2e-5, output=output);
        end

        function folder = tempFolder(testCase)
            folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function resultsHaveAllTheDocumentedParts(testCase)
            results = ldem.runSimulation(testCase.quickParams());
            for name = ["info", "params", "mesh", "barProps", "controlNodes", "reactions", ...
                    "energy", "trackedBar", "snapshots", "final"]
                testCase.verifyTrue(isfield(results, name), "Missing results." + name);
            end
            testCase.verifyEqual(results.info.version, ldem.version());
            testCase.verifyGreaterThan(results.info.elapsedSeconds, 0);
            testCase.verifyEqual(results.params.nSteps, 100);
            testCase.verifyEqual(results.final.step, 100);
            testCase.verifySize(results.controlNodes.time, [10 1]);
            testCase.verifySize(results.energy.time, [10 1]);
            testCase.verifyEqual(numel(results.snapshots.time), 5);        % 0, 25, 50, 75, 100
            testCase.verifyEqual(results.snapshots.step, (0:25:100).');
        end

        function resultsContainNoObjectsSoTheyLoadWithoutThePackage(testCase)
            results = ldem.runSimulation(testCase.quickParams());
            testCase.verifyFalse(containsObject(results), ...
                'results must not hold ldem class instances.');
        end

        function energyPartsAddUp(testCase)
            results = ldem.runSimulation(testCase.quickParams());
            e = results.energy;
            testCase.verifyEqual(e.internal, e.kinetic + e.elastic + e.damage + e.damping, 'RelTol', 1e-12);
            testCase.verifyGreaterThan(max(e.kinetic), 0);
        end

        function nothingIsWrittenWithoutAnOutputFolder(testCase)
            folder = testCase.tempFolder();
            oldFolder = cd(folder);
            restore = onCleanup(@() cd(oldFolder));
            ldem.runSimulation(testCase.quickParams(), Formats=["mat" "ansys" "vtk"]);
            listing = dir(folder);
            testCase.verifyEqual(nnz(~[listing.isdir]), 0);
        end

        function outputFilesAreWrittenForTheRequestedFormats(testCase)
            folder = fullfile(testCase.tempFolder(), "run");
            results = ldem.runSimulation(testCase.quickParams(), OutputFolder=folder, ...
                Formats=["mat" "ansys" "vtk"]);

            testCase.verifyTrue(isfile(fullfile(folder, "results.mat")));
            testCase.verifyTrue(isfile(fullfile(folder, "snapshots.pvd")));
            for k = 0:4
                testCase.verifyTrue(isfile(fullfile(folder, sprintf('snapshot_%04d.mac', k))));
                testCase.verifyTrue(isfile(fullfile(folder, sprintf('snapshot_%04d.vtu', k))));
            end
            loaded = load(fullfile(folder, "results.mat"));
            testCase.verifyEqual(loaded.results.final.displacement, results.final.displacement);
            testCase.verifyEqual(loaded.results.energy.kinetic, results.energy.kinetic);
            testCase.verifyEqual(loaded.results.params.nSteps, 100);
        end

        function onlyTheRequestedFormatsAreWritten(testCase)
            folder = fullfile(testCase.tempFolder(), "run");
            ldem.runSimulation(testCase.quickParams(), OutputFolder=folder, Formats="vtk");
            testCase.verifyTrue(isfile(fullfile(folder, "snapshot_0000.vtu")));
            testCase.verifyFalse(isfile(fullfile(folder, "snapshot_0000.mac")));
            testCase.verifyFalse(isfile(fullfile(folder, "results.mat")));
        end

        function snapshotFormatsWithoutSnapshotStepsWarn(testCase)
            params = ldem.Parameters(nModules=[3 3 3], totalTime=2e-6);   % snapshotEvery = 0
            folder = fullfile(testCase.tempFolder(), "run");
            testCase.verifyWarning( ...
                @() ldem.runSimulation(params, OutputFolder=folder, Formats="vtk"), ...
                'ldem:output:noSnapshots');
            testCase.verifyFalse(isfile(fullfile(folder, "snapshot_0000.vtu")));
        end

        function unknownFormatIsRejected(testCase)
            testCase.verifyError(@() ldem.runSimulation(ldem.Parameters(), Formats="docx"), ?MException);
        end

        function invalidParametersAreCaughtBeforeRunning(testCase)
            params = ldem.Parameters();
            params.dt = 1e-5;                                    % unstable, set after construction
            testCase.verifyError(@() ldem.runSimulation(params), 'ldem:params:unstableTimeStep');
        end

        function aCustomScenarioIsUsed(testCase)
            params = testCase.quickParams();
            still = ldem.scenarios.UniaxialTension(loadingVelocity=0);
            results = ldem.runSimulation(params, Scenario=still);
            testCase.verifyEqual(max(abs(results.final.velocity), [], 'all'), 0);
            testCase.verifyEqual(results.final.displacement, results.mesh.nodes0);
        end

        function runsAreDeterministic(testCase)
            a = ldem.runSimulation(testCase.quickParams());
            b = ldem.runSimulation(testCase.quickParams());
            testCase.verifyEqual(a.final, b.final);
            testCase.verifyEqual(a.energy, b.energy);
        end

        function aRunFromAnInputFileMatchesTheEquivalentParameters(testCase)
            testsDir = fullfile(testCase.RepoRoot, 'tests', 'tools');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(testsDir));
            cases = referenceCases();
            c = cases(strcmp({cases.name}, 'tension101_elastic'));
            path = fullfile(testCase.tempFolder(), "DATA0.DAT");
            writeDataFile(path, c);

            fromFile = ldem.runSimulation(ldem.Parameters.fromFile(path));
            direct = ldem.runSimulation(ldem.Parameters( ...
                testId = c.test, seed = c.seed, moduleLength = c.moduleLength, ...
                nModules = c.modules, dampingInitial = c.damping1, dampingFinal = c.damping2, ...
                dampingSwitchTime = c.dampingSwitchTime, constitutiveDamping = c.con, ...
                dt = c.dt, totalTime = c.nSteps * c.dt, controlNodes = c.controlNodes, ...
                youngModulus = c.youngModulus, density = c.density, poissonRatio = c.poisson, ...
                fractureEnergy = c.fractureEnergy, criticalDistance = c.criticalDistance, ...
                output = struct('snapshotEvery', c.ansysEvery, 'controlNodesEvery', c.everyN, ...
                    'energyEvery', c.everyN, 'trackedBarEvery', 1)));
            testCase.verifyEqual(fromFile.final.displacement, direct.final.displacement);
            testCase.verifyEqual(fromFile.energy.kinetic, direct.energy.kinetic);
        end

        function plotEnergyDrawsFiveCurves(testCase)
            results = ldem.runSimulation(testCase.quickParams());
            fig = figure('Visible', 'off');
            testCase.addTeardown(@close, fig);
            ax = ldem.post.plotEnergy(results, axes(fig));
            testCase.verifyEqual(numel(ax.Children), 5);
            testCase.verifyEqual(ax.XLabel.String, 'Time [s]');
        end

        function plotEnergyNeedsAnEnergyHistory(testCase)
            params = testCase.quickParams(struct('snapshotEvery', 0, ...
                'controlNodesEvery', 0, 'energyEvery', 0, 'trackedBarEvery', 0));
            results = ldem.runSimulation(params);
            testCase.verifyError(@() ldem.post.plotEnergy(results), 'ldem:post:noData');
        end

        function plotReactionShowsTheBeamReaction(testCase)
            params = ldem.Parameters(testId=102, nModules=[70 4 3], totalTime=2e-6, ...
                output=struct('snapshotEvery', 0, 'controlNodesEvery', 2, ...
                    'energyEvery', 0, 'trackedBarEvery', 0));
            results = ldem.runSimulation(params);
            fig = figure('Visible', 'off');
            testCase.addTeardown(@close, fig);
            ax = ldem.post.plotReaction(results, axes(fig));
            testCase.verifyEqual(numel(ax.Children), 1);                 % only Ry is defined
        end

        function plotReactionIsNotAvailableForTension(testCase)
            results = ldem.runSimulation(testCase.quickParams());
            testCase.verifyError(@() ldem.post.plotReaction(results), 'ldem:post:noData');
        end
    end
end

function tf = containsObject(value)
%CONTAINSOBJECT  True if a struct tree holds an instance of a class of the ldem package.
tf = false;
if isstruct(value)
    for element = value(:).'
        for name = fieldnames(element).'
            if containsObject(element.(name{1}))
                tf = true;
                return
            end
        end
    end
elseif iscell(value)
    for k = 1:numel(value)
        if containsObject(value{k})
            tf = true;
            return
        end
    end
else
    tf = startsWith(string(class(value)), "ldem.");
end
end
