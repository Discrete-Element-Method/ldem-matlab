classdef TestRunCase < LdemTestCase
    %TESTRUNCASE  Unit tests of ldem.run and ldem.check.

    properties (Access = private)
        Folder (1,1) string
        CasePath (1,1) string
    end

    methods (TestMethodSetup)
        function makeCase(testCase)
            testCase.Folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
            testCase.CasePath = fullfile(testCase.Folder, "small.ldem");
            writeTextFile(testCase.CasePath, [ ...
                "format = 1"
                "[mesh]"
                "module_size = 3 mm"
                "modules = [5, 2, 2]"
                "[time]"
                "step = 0.2 us"
                "duration = 20 us"
                "[scenario]"
                "type = ""uniaxial_tension"""
                "[output]"
                "folder = ""out"""
                "mat = true"
                "ansys = false"
                "vtk = true"
                "[output.snapshots]"
                "every = 50 steps"
                "[output.control_nodes]"
                "every = 10 steps"
                "[output.energy]"
                "every = 10 steps"]);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function runMatchesRunSimulation(testCase)
            viaCase = ldem.run(testCase.CasePath, OutputFolder = "", Verbose = false);

            c = ldem.io.readCase(testCase.CasePath);
            direct = ldem.runSimulation(c.params, Scenario = c.scenario);

            testCase.verifyEqual(viaCase.final.displacement, direct.final.displacement);
            testCase.verifyEqual(viaCase.energy, direct.energy);
            testCase.verifyEqual(viaCase.controlNodes.displacement, direct.controlNodes.displacement);
            testCase.verifyEqual(viaCase.params.dt, 2e-7);
            testCase.verifyEqual(viaCase.final.step, 100);
        end

        function runWritesTheFilesOfTheOutputSection(testCase)
            ldem.run(testCase.CasePath, Verbose = false);
            out = fullfile(testCase.Folder, "out");
            testCase.verifyTrue(isfile(fullfile(out, "results.mat")));
            testCase.verifyTrue(isfile(fullfile(out, "snapshots.pvd")));
            testCase.verifyTrue(isfile(fullfile(out, "snapshot_0000.vtu")));
            testCase.verifyFalse(isfile(fullfile(out, "snapshot_0000.mac")));
        end

        function resultsKeepTheCaseThatWasRun(testCase)
            results = ldem.run(testCase.CasePath, Formats = "mat", Verbose = false);
            info = results.info.case;

            fid = fopen(testCase.CasePath, 'r');
            bytes = fread(fid, Inf, '*uint8');
            fclose(fid);
            digest = java.security.MessageDigest.getInstance('SHA-256');
            expected = string(lower(reshape(dec2hex(typecast(digest.digest(bytes), 'uint8'), 2).', 1, [])));
            testCase.verifyEqual(info.sha256, expected);
            testCase.verifyEqual(info.original, string(fileread(testCase.CasePath)));
            testCase.verifyEqual(strlength(info.sha256), 64);

            % The resolved case reads back into the parameters that ran.
            path = fullfile(testCase.Folder, "resolved.ldem");
            writeTextFile(path, splitlines(info.resolved));
            again = ldem.io.readCase(path);
            testCase.verifyEqual(again.params.toStruct(), results.params);
        end

        function theResolvedCaseIsSavedNextToTheResults(testCase)
            results = ldem.run(testCase.CasePath, Verbose = false);
            saved = fullfile(testCase.Folder, "out", "case.ldem");
            testCase.verifyTrue(isfile(saved));
            again = ldem.io.readCase(saved);
            testCase.verifyEqual(again.params.toStruct(), results.params);
            data = load(fullfile(testCase.Folder, "out", "results.mat"));
            testCase.verifyEqual(data.results.info.case.sha256, results.info.case.sha256);
        end

        function runSimulationWithoutACaseHasNoCaseInfo(testCase)
            results = ldem.runSimulation(ldem.Parameters(totalTime = 2e-6));
            testCase.verifyFalse(isfield(results.info, 'case'));
        end

        function runOptionsOverrideTheCase(testCase)
            other = fullfile(testCase.Folder, "other");
            ldem.run(testCase.CasePath, OutputFolder = other, Formats = "mat", Verbose = false);
            testCase.verifyTrue(isfile(fullfile(other, "results.mat")));
            testCase.verifyFalse(isfolder(fullfile(testCase.Folder, "out")));
        end

        function checkReportsTheModelWithoutSimulating(testCase)
            report = ldem.check(testCase.CasePath);
            testCase.verifyEqual(report.model.nNodes, 6 * 3 * 3 + 5 * 2 * 2);
            testCase.verifyEqual(report.nSteps, 100);
            testCase.verifyEqual(report.nSnapshots, 3);
            testCase.verifyGreaterThan(report.snapshotMemoryMB, 0);
            testCase.verifyEqual(report.randomField, "none");
            testCase.verifyEqual(report.timeStepRatio, 2e-7 / report.params.criticalTimeStep);
            testCase.verifyEqual([report.controlNodes.number], [1 2]);
            testCase.verifyEqual(report.controlNodes(1).position, [0 0 0]);
        end

        function checkPrintsWhenThereIsNoOutput(testCase)
            text = evalc('ldem.check(testCase.CasePath)');
            testCase.verifySubstring(text, 'UniaxialTension');
        end

        function checkSaysWhetherTheRandomFieldFileIsUsable(testCase)
            path = fullfile(testCase.Folder, "scatter.ldem");
            lines = splitlines(string(fileread(testCase.CasePath)));
            writeTextFile(path, [lines(1:end-1); "[material.scatter]"; "type = ""file"""; "file = ""missing.txt"""]);
            report = ldem.check(path);
            testCase.verifySubstring(report.randomField, "PROBLEM");

            writeTextFile(fullfile(testCase.Folder, "field.txt"), string(ones(1000, 1)));
            writeTextFile(path, [lines(1:end-1); "[material.scatter]"; "type = ""file"""; "file = ""field.txt"""]);
            report = ldem.check(path);
            testCase.verifySubstring(report.randomField, "file OK");

            writeTextFile(path, [lines(1:end-1); "[material.scatter]"; "type = ""generated"""; "cv = 0.1"]);
            testCase.verifySubstring(ldem.check(path).randomField, "generated");
        end
    end
end
