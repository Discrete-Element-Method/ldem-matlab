classdef TestExtendsAndSweep < LdemTestCase
    %TESTEXTENDSANDSWEEP  Unit tests of case-file inheritance (extends) and of parameter sweeps.

    properties (Access = private)
        Folder (1,1) string
    end

    methods (TestMethodSetup)
        function makeFolder(testCase)
            testCase.Folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
        end
    end

    methods (Access = private)
        function lines = base(~)
            lines = [ ...
                "format = 1"
                "[mesh]"
                "module_size = 3 mm"
                "modules = [5, 2, 2]"
                "[time]"
                "step = 0.2 us"
                "duration = 20 us"
                "[material]"
                "fracture_energy = 0.1 N/m"
                "[scenario]"
                "type = ""uniaxial_tension"""];
        end

        function path = put(testCase, relative, lines)
            path = fullfile(testCase.Folder, relative);
            writeTextFile(path, string(lines(:)));
        end

        function verifyCaseError(testCase, path, id, fragment)
            try
                ldem.io.readCase(path);
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(string(err.identifier), string(id));
                testCase.verifySubstring(err.message, fragment);
            end
        end
    end

    methods (Test, TestTags = {'Unit'})
        function aChildOverridesAndInherits(testCase)
            testCase.put("base.ldem", testCase.base());
            child = testCase.put("child.ldem", [ ...
                "extends = ""base.ldem"""
                "[material]"
                "young_modulus = 10 GPa"
                "[time]"
                "duration = 40 us"]);
            c = ldem.io.readCase(child);
            testCase.verifyEqual(c.params.youngModulus, 10e9);           % set by the child
            testCase.verifyEqual(c.params.totalTime, 40e-6);             % replaced by the child
            testCase.verifyEqual(c.params.fractureEnergy, 0.1);          % inherited, same section
            testCase.verifyEqual(c.params.dt, 2e-7);                     % inherited
            testCase.verifyEqual(c.params.nModules, [6 3 3]);
            testCase.verifyEqual(c.info.parents, string(fullfile(testCase.Folder, "base.ldem")));
        end

        function theChildCanLeaveOutRequiredKeys(testCase)
            testCase.put("base.ldem", testCase.base());
            child = testCase.put("child.ldem", ["extends = ""base.ldem"""; "title = ""Only the title"""]);
            c = ldem.io.readCase(child);
            testCase.verifyEqual(c.info.title, "Only the title");
            testCase.verifyEqual(c.params.totalTime, 20e-6);
        end

        function relativePathsFollowTheFileThatWritesThem(testCase)
            testCase.put("parent/base.ldem", [testCase.base(); "[material.scatter]"; "type = ""file"""; ...
                "file = ""field.txt"""; "[output]"; "folder = ""out"""]);
            child = testCase.put("child/child.ldem", ["extends = ""../parent/base.ldem"""; ...
                "[material]"; "young_modulus = 10 GPa"]);
            c = ldem.io.readCase(child);
            testCase.verifyEqual(string(c.params.randomFieldFile), ...
                string(fullfile(testCase.Folder, "parent", "field.txt")));
            testCase.verifyEqual(c.options.OutputFolder, string(fullfile(testCase.Folder, "parent", "out")));
        end

        function repeatedTablesAreReplacedAsAWhole(testCase)
            testCase.put("base.ldem", [testCase.base(); "[[monitor.node]]"; "id = 2"; "[[monitor.node]]"; "id = 3"]);
            keep = testCase.put("keep.ldem", ["extends = ""base.ldem"""; "[material]"; "density = 1500 kg/m3"]);
            testCase.verifyEqual(ldem.io.readCase(keep).params.controlNodes, [2 3]);
            replace = testCase.put("replace.ldem", ["extends = ""base.ldem"""; "[[monitor.node]]"; "id = 5"]);
            testCase.verifyEqual(ldem.io.readCase(replace).params.controlNodes, 5);
        end

        function changingTheTypeDropsTheKeysOfTheOldOne(testCase)
            lines = testCase.base();
            lines = lines(~startsWith(lines, ["[scenario]" "type"]));
            testCase.put("beam.ldem", [lines; "[scenario]"; "type = ""clamped_beam"""; "force_rate = 2 kN/s"; ...
                "[damping]"; "type = ""mass_proportional"""; "initial = 100"; "final = 100"; ...
                "[material.scatter]"; "type = ""generated"""; "cv = 0.1"]);
            child = testCase.put("child.ldem", [ ...
                "extends = ""beam.ldem"""
                "[scenario]"
                "type = ""uniaxial_tension"""
                "[damping]"
                "type = ""none"""
                "[material.scatter]"
                "type = ""none"""]);
            c = ldem.io.readCase(child);
            testCase.verifyClass(c.scenario, 'ldem.scenarios.UniaxialTension');
            testCase.verifyEqual(c.params.dampingModel, "none");
            testCase.verifyEqual(c.params.randomFieldCv, 0);

            % Same type: the inherited keys stay.
            same = testCase.put("same.ldem", ["extends = ""beam.ldem"""; "[scenario]"; "type = ""clamped_beam"""]);
            testCase.verifyEqual(ldem.io.readCase(same).scenario.forceRate, 2000);
        end

        function severalParentsApplyInOrder(testCase)
            testCase.put("a.ldem", testCase.base());
            testCase.put("b.ldem", ["[material]"; "young_modulus = 10 GPa"; "density = 1000 kg/m3"]);
            testCase.put("c.ldem", ["[material]"; "young_modulus = 20 GPa"]);
            child = testCase.put("child.ldem", ["extends = [""a.ldem"", ""b.ldem"", ""c.ldem""]"; ...
                "[material]"; "poisson_ratio = 0.2"]);
            c = ldem.io.readCase(child);
            testCase.verifyEqual(c.params.youngModulus, 20e9);       % the last parent wins
            testCase.verifyEqual(c.params.density, 1000);
            testCase.verifyEqual(c.params.poissonRatio, 0.2);
            testCase.verifyEqual(numel(c.info.parents), 3);
        end

        function chainsOfParentsWork(testCase)
            testCase.put("a.ldem", testCase.base());
            testCase.put("b.ldem", ["extends = ""a.ldem"""; "[material]"; "young_modulus = 10 GPa"]);
            child = testCase.put("c.ldem", ["extends = ""b.ldem"""; "[material]"; "density = 1000 kg/m3"]);
            c = ldem.io.readCase(child);
            testCase.verifyEqual(c.params.youngModulus, 10e9);
            testCase.verifyEqual(c.params.density, 1000);
            testCase.verifyEqual(c.params.fractureEnergy, 0.1);
            testCase.verifyEqual(c.info.parents, string(fullfile(testCase.Folder, ["a.ldem"; "b.ldem"])));
        end

        function loopsAndMissingParentsAreErrors(testCase)
            testCase.put("a.ldem", "extends = ""b.ldem""");
            testCase.put("b.ldem", "extends = ""a.ldem""");
            testCase.verifyCaseError(fullfile(testCase.Folder, "a.ldem"), 'ldem:case:extendsLoop', 'in a loop');
            lonely = testCase.put("lonely.ldem", "extends = ""missing.ldem""");
            testCase.verifyCaseError(lonely, 'ldem:io:fileNotFound', 'lonely.ldem:1 extends');
            bad = testCase.put("bad.ldem", "extends = 3");
            testCase.verifyCaseError(bad, 'ldem:case:badValue', 'in quotes');
        end

        function errorsNameTheFileWhereTheyAreWritten(testCase)
            lines = testCase.base();
            lines(lines == "step = 0.2 us") = "step = 0.2 kg";
            testCase.put("base.ldem", lines);
            child = testCase.put("child.ldem", "extends = ""base.ldem""");
            testCase.verifyCaseError(child, 'ldem:case:badUnit', 'base.ldem:6 [time] step');
        end

        function runKeepsTheParentsAndTheirHashes(testCase)
            testCase.put("base.ldem", testCase.base());
            child = testCase.put("child.ldem", "extends = ""base.ldem""");
            results = ldem.run(child, OutputFolder = "", Verbose = false);
            info = results.info.case;
            testCase.verifyEqual(numel(info.parents), 1);
            testCase.verifyEqual(strlength(info.parents.sha256), 64);
            testCase.verifyEqual(info.original, string(fileread(child)));
            % The resolved case has everything and needs no parent.
            path = fullfile(testCase.Folder, "resolved.ldem");
            writeTextFile(path, splitlines(info.resolved));
            testCase.verifyEqual(ldem.io.readCase(path).params.toStruct(), results.params);
        end

        function sweepBlocksAreReadAndChecked(testCase)
            % sweep_mode is a key at the top of the file, before the first table.
            path = fullfile(testCase.Folder, "sweep.ldem");
            writeTextFile(path, ["sweep_mode = ""zip"""; testCase.base(); ...
                "[[sweep]]"; "key = ""material.fracture_energy"""; "values = [""0.1 N/m"", ""0.5 N/m""]"; ...
                "[[sweep]]"; "key = ""time.duration"""; "values = [2e-5, 4e-5]"]);
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.info.sweepMode, "zip");
            testCase.verifyEqual(numel(c.info.sweep), 2);
            testCase.verifyEqual(c.info.sweep(1).key, "material.fracture_energy");
            testCase.verifyEqual(c.info.sweep(1).values, {"0.1 N/m", "0.5 N/m"});
            testCase.verifyEqual(c.info.sweep(2).values, {2e-5, 4e-5});
        end

        function badSweepBlocks(testCase)
            bad = @(lines) testCase.put("bad.ldem", [testCase.base(); string(lines(:))]);
            testCase.verifyCaseError(bad(["[[sweep]]"; "key = ""time.duration"""]), 'ldem:case:missingKey', 'needs "key"');
            testCase.verifyCaseError(bad(["[[sweep]]"; "key = ""time.duraton"""; "values = [1]"]), ...
                'ldem:case:badValue', "Did you mean 'time.duration'?");
            testCase.verifyCaseError(bad(["[[sweep]]"; "key = ""mesh.modules"""; "values = [1]"]), ...
                'ldem:case:badValue', 'cannot be swept');
            testCase.verifyCaseError(bad(["[[sweep]]"; "key = ""load.rate"""; "values = [1]"]), ...
                'ldem:case:badValue', 'cannot be swept');
            testCase.verifyCaseError(bad(["[[sweep]]"; "key = 3"; "values = [1]"]), 'ldem:case:badValue', 'in quotes');
            testCase.verifyCaseError(bad(["[[sweep]]"; "key = ""time.duration"""; "values = []"]), ...
                'ldem:case:badValue', 'non-empty list');
            testCase.verifyCaseError(bad(["[sweep]"; "key = ""time.duration"""; "values = [1]"]), ...
                'ldem:case:syntax', 'double brackets');
        end

        function overridesChangeKeysOfTheCase(testCase)
            path = testCase.put("case.ldem", testCase.base());
            overrides = struct('path', {"material.fracture_energy", "time.duration"}, ...
                'value', {"2 N/m", 3e-5});
            c = ldem.io.readCase(path, Overrides = overrides);
            testCase.verifyEqual(c.params.fractureEnergy, 2);
            testCase.verifyEqual(c.params.totalTime, 3e-5);

            testCase.verifyError(@() ldem.io.readCase(path, Overrides = struct('path', "mesh.nonsense", 'value', 1)), ...
                'ldem:sweep:unknownKey');
            testCase.verifyError(@() ldem.io.readCase(path, Overrides = struct('path', "support.fix", 'value', "x")), ...
                'ldem:sweep:unsupportedKey');
            % A bad value is reported where it is used.
            try
                ldem.io.readCase(path, Overrides = struct('path', "material.fracture_energy", 'value', "2 kg"));
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:case:badUnit');
                testCase.verifySubstring(err.message, 'sweep [material] fracture_energy');
            end
        end

        function overridesCanSetScenarioKeys(testCase)
            lines = testCase.base();
            lines = lines(~startsWith(lines, ["[scenario]" "type"]));
            path = testCase.put("beam.ldem", [lines; "[scenario]"; "type = ""clamped_beam"""]);
            c = ldem.io.readCase(path, Overrides = struct('path', "scenario.force_rate", 'value', "3 kN/s"));
            testCase.verifyEqual(c.scenario.forceRate, 3000);
        end

        function dryRunListsTheCombinations(testCase)
            path = testCase.put("sweep.ldem", [testCase.base(); ...
                "[[sweep]]"; "key = ""material.fracture_energy"""; "values = [""0.1 N/m"", ""0.5 N/m"", ""1 N/m""]"; ...
                "[[sweep]]"; "key = ""time.duration"""; "values = [2e-5, 4e-5]"]);
            summary = ldem.sweep(path, DryRun = true, Verbose = false);
            testCase.verifySize(summary, [6 9]);
            testCase.verifyEqual(summary.status, repmat("planned", 6, 1));
            testCase.verifyEqual(summary.material_fracture_energy, ["0.1 N/m"; "0.5 N/m"; "1 N/m"; "0.1 N/m"; "0.5 N/m"; "1 N/m"]);
            testCase.verifyEqual(summary.time_duration, ["2e-05"; "2e-05"; "2e-05"; "4e-05"; "4e-05"; "4e-05"]);
            testCase.verifyTrue(all(endsWith(summary.folder, "run_" + compose("%03d", (1:6).'))));
            testCase.verifyFalse(isfolder(fullfile(testCase.Folder, "sweep_sweep")));      % nothing was created

            % The mode of the file can be overridden: the lists of 3 and 2 values cannot be zipped.
            testCase.verifyError(@() ldem.sweep(path, DryRun = true, Verbose = false, Mode = "zip"), ...
                'ldem:sweep:zipLengths');
        end

        function varyAddsKeysAndZipNeedsEqualLengths(testCase)
            path = testCase.put("case.ldem", testCase.base());
            summary = ldem.sweep(path, DryRun = true, Verbose = false, ...
                Vary = {"material.fracture_energy", [0.1 0.5], "time.duration", ["20 us", "30 us"]}, Mode = "zip");
            testCase.verifyEqual(height(summary), 2);
            testCase.verifyError(@() ldem.sweep(path, DryRun = true, Verbose = false, Mode = "zip", ...
                Vary = {"material.fracture_energy", [0.1 0.5], "time.duration", ["20 us", "30 us", "40 us"]}), ...
                'ldem:sweep:zipLengths');
            testCase.verifyError(@() ldem.sweep(path, DryRun = true, Verbose = false), 'ldem:sweep:noKeys');
            testCase.verifyError(@() ldem.sweep(path, DryRun = true, Vary = {"a"}), 'ldem:sweep:invalidRun');
        end

        function invalidRunsStopTheSweepBeforeItStarts(testCase)
            path = testCase.put("case.ldem", testCase.base());
            try
                ldem.sweep(path, Verbose = false, OutputFolder = fullfile(testCase.Folder, "out"), ...
                    Vary = {"time.step", ["0.2 us", "50 us"]});
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:sweep:invalidRun');
                testCase.verifySubstring(err.message, 'Run 2');
                testCase.verifySubstring(err.message, 'time.step = 50 us');
            end
            testCase.verifyFalse(isfolder(fullfile(testCase.Folder, "out")));
            try
                ldem.sweep(path, DryRun = true, Vary = {"mesh.nonsense", [1 2]});
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:sweep:invalidRun');
                testCase.verifySubstring(err.message, 'does not exist');
            end
        end

        function aSweepRunsEveryCaseAndSummarisesThem(testCase)
            lines = testCase.base();
            lines(lines == "duration = 20 us") = "duration = 200 us";
            path = testCase.put("case.ldem", lines);
            out = fullfile(testCase.Folder, "runs");
            [summary, results] = ldem.sweep(path, Verbose = false, OutputFolder = out, Formats = "mat", ...
                KeepResults = true, ...
                Vary = {"material.fracture_energy", ["0.1 N/m", "50 N/m"]});

            testCase.verifyEqual(summary.status, ["done"; "done"]);
            testCase.verifyEqual(summary.run, [1; 2]);
            for r = 1:2
                testCase.verifyTrue(isfile(fullfile(out, sprintf("run_%03d", r), "results.mat")));
                testCase.verifyTrue(isfile(fullfile(out, sprintf("run_%03d", r), "case.ldem")));
            end
            testCase.verifyTrue(isfile(fullfile(out, "sweep_summary.csv")));
            testCase.verifyEqual(results{1}.params.fractureEnergy, 0.1);
            testCase.verifyEqual(results{2}.params.fractureEnergy, 50);
            testCase.verifyEqual(results{1}.info.case.overrides, "material.fracture_energy = 0.1 N/m");
            testCase.verifyGreaterThanOrEqual(summary.damagedBars(1), summary.damagedBars(2));
            testCase.verifyGreaterThan(summary.damagedBars(1), 0);
            testCase.verifyTrue(all(summary.seconds > 0));

            % The resolved case of a run has the varied value in it.
            again = ldem.io.readCase(fullfile(out, "run_001", "case.ldem"));
            testCase.verifyEqual(again.params.fractureEnergy, 0.1);

            table = readtable(fullfile(out, "sweep_summary.csv"), 'TextType', 'string');
            testCase.verifyEqual(height(table), 2);
            testCase.verifyEqual(table.status, ["done"; "done"]);
        end

        function resultsAreNotKeptUnlessAsked(testCase)
            path = testCase.put("case.ldem", testCase.base());
            [summary, results] = ldem.sweep(path, Verbose = false, ...
                OutputFolder = fullfile(testCase.Folder, "runs"), Formats = "mat", ...
                Vary = {"time.duration", ["4 us", "6 us"]});
            testCase.verifyEqual(summary.status, ["done"; "done"]);
            testCase.verifyEqual(results, cell(2, 1));
        end

        function runWarnsWhenTheCaseDefinesASweep(testCase)
            path = testCase.put("sweep.ldem", [testCase.base(); ...
                "[[sweep]]"; "key = ""material.fracture_energy"""; "values = [0.1, 0.5]"]);
            testCase.verifyWarning(@() ldem.run(path, OutputFolder = "", Verbose = false), 'ldem:run:sweepIgnored');
        end
    end
end
