classdef TestExamples < LdemTestCase
    %TESTEXAMPLES  The example scripts run and produce their files.
    %
    %   The tension example is run completely. The clamped beam of example 1
    %   (3086 nodes, 8000 steps, about 1 minute) is also run completely and is
    %   tagged "Slow". The beam_102 example has about 167,000 nodes and 1.1
    %   million bars, so its test only builds the model (reading DATA0.DAT and
    %   the random field) without integrating; it is tagged "Slow" too.

    methods (Test, TestTags = {'Unit'})
        function tensionExampleRunsAndWritesItsFiles(testCase)
            folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
            script = fullfile(testCase.RepoRoot, 'examples', 'tension_101', 'runTension.m');
            testCase.assertTrue(isfile(script));
            testCase.addTeardown(@() close('all', 'hidden'));

            output = runScript(script, fullfile(folder, "output"));

            testCase.verifySubstring(output, 'bars');
            for name = ["results.mat", "snapshots.pvd", "snapshot_0000.mac", ...
                    "snapshot_0004.mac", "snapshot_0000.vtu", "snapshot_0004.vtu"]
                testCase.verifyTrue(isfile(fullfile(folder, "output", name)), name + " is missing.");
            end

            data = load(fullfile(folder, "output", "results.mat"));
            counts = data.results.snapshots.barCounts(end, :);
            testCase.verifyGreaterThan(counts(2) + counts(3), 0, ...
                'The example is meant to show damage, but no bar softened.');
        end
    end

    methods (Test, TestTags = {'Slow'})
        function clampedBeamExampleRunsAndCarriesItsLoad(testCase)
            folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
            script = fullfile(testCase.RepoRoot, 'examples', 'example1_clamped_beam', 'runClampedBeam.m');
            testCase.assertTrue(isfile(script));
            testCase.addTeardown(@() close('all', 'hidden'));

            output = runScript(script, fullfile(folder, "output"));

            testCase.verifySubstring(output, 'Clamped beam with 3086 nodes, 8000 steps');
            for name = ["results.mat", "snapshots.pvd", "snapshot_0000.mac", "snapshot_0008.vtu"]
                testCase.verifyTrue(isfile(fullfile(folder, "output", name)), name + " is missing.");
            end

            data = load(fullfile(folder, "output", "results.mat"));
            results = data.results;
            % Five loaded nodes carry 1000 N/s * 0.35 ms = 0.35 N each; the
            % clamped ends carry the total once the beam is at rest.
            testCase.verifyEqual(results.reactions.force(end, 2), 5 * 0.35, 'RelTol', 5e-2);
            e = results.energy;
            testCase.verifyLessThan(max(abs(e.balance)) / e.external(end), 1e-2);
        end

        function beamExampleModelIsBuiltFromItsInputFile(testCase)
            here = fullfile(testCase.RepoRoot, 'examples', 'beam_102');
            params = ldem.Parameters.fromFile(fullfile(here, 'DATA0.DAT'), ...
                randomFieldFile = fullfile(here, 'arquivo_3lc_rnao_cv05'));
            mesh = ldem.mesh.buildMesh(params);
            [barProps, history] = ldem.material.buildBarProperties(mesh, params);

            nBars = size(mesh.bars, 1);
            testCase.verifyEqual(size(mesh.nodes0, 1), params.nNodes);
            testCase.verifyLessThanOrEqual(nBars, 1126960, ...
                'The random field file has one value per bar.');
            testCase.verifySize(barProps.criticalStrain, [nBars 1]);
            testCase.verifyGreaterThan(barProps.criticalStrainCv, 0);
            testCase.verifyTrue(all(history.isUnbroken));
            testCase.verifyGreaterThan(nnz(mesh.fixed), 0);
        end
    end
end

function output = runScript(script, outputFolder) %#ok<INUSD>
%RUNSCRIPT  Run an example script with "outputFolder" defined, capturing its text.
% The examples use outputFolder when it exists in the workspace they run in,
% which here is the workspace of this function.
output = evalc('run(script)');
end
