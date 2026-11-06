classdef TestWriteCase < LdemTestCase
    %TESTWRITECASE  Unit tests of ldem.io.writeCase, writeTemplate and convertLegacyInput.

    properties (Access = private)
        Folder (1,1) string
    end

    methods (TestMethodSetup)
        function makeFolder(testCase)
            testCase.Folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function roundTripKeepsParametersAndScenario(testCase)
            output = struct('snapshotEvery', 400, 'controlNodesEvery', 3, ...
                'energyEvery', 7, 'trackedBarEvery', 1);
            p = ldem.Parameters(testId = 103, seed = 77, moduleLength = 0.002, ...
                nModules = [6 6 21], dt = 3.5e-7, totalTime = 1.4e-4, ...
                dampingInitial = 2500, dampingFinal = 1800, dampingSwitchTime = 5e-5, ...
                constitutiveDamping = 1e-6, controlNodes = [3 40 100], ...
                youngModulus = 3.87e9, density = 1500, poissonRatio = 0.2, ...
                fractureEnergy = 0.5, criticalDistance = 4.5e-3, failureAreaFactor = 0.14, ...
                trackedBar = 33, meshPerturbation = 0.02, ...
                randomFieldCv = 0.05, randomFieldCorrelationLength = [2 3 4], randomFieldSeed = 9, ...
                output = output);
            scenario = ldem.scenarios.ClampedBeam(forceRate = 1234.5, rampTime = 2e-4, ...
                loadPosition = 7.5, loadHeight = 1.5);
            path = fullfile(testCase.Folder, "round.ldem");

            ldem.io.writeCase(path, p, scenario);
            c = ldem.io.readCase(path);

            testCase.verifyEqual(c.params.toStruct(), p.toStruct());
            testCase.verifyEqual(c.scenario.forceRate, 1234.5);
            testCase.verifyEqual(c.scenario.rampTime, 2e-4);
            testCase.verifyEqual(c.scenario.loadPosition, 7.5);
            testCase.verifyEqual(c.scenario.loadHeight, 1.5);
        end

        function defaultsAndMidspanRoundTrip(testCase)
            p = ldem.Parameters(testId = 103);
            path = fullfile(testCase.Folder, "defaults.ldem");
            text = ldem.io.writeCase(path, p);
            testCase.verifySubstring(text, 'load_position = "midspan"');
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.params.toStruct(), p.toStruct());
            testCase.verifyTrue(isnan(c.scenario.loadPosition));
        end

        function randomFieldFileIsWrittenRelativeToTheCase(testCase)
            file = fullfile(testCase.Folder, "data", "field.txt");
            p = ldem.Parameters(randomFieldFile = file);
            path = fullfile(testCase.Folder, "case.ldem");
            text = ldem.io.writeCase(path, p);
            testCase.verifySubstring(text, 'file = "data/field.txt"');
            testCase.verifyEqual(string(ldem.io.readCase(path).params.randomFieldFile), ...
                string(fullfile(testCase.Folder, "data/field.txt")));
        end

        function randomFieldFileOfAnotherFolderUsesDotDot(testCase)
            file = fullfile(testCase.Folder, "shared", "field.txt");
            p = ldem.Parameters(randomFieldFile = file);
            path = fullfile(testCase.Folder, "a", "b", "case.ldem");
            text = ldem.io.writeCase(path, p);
            testCase.verifySubstring(text, 'file = "../../shared/field.txt"');
            testCase.verifyEqual(strrep(string(ldem.io.readCase(path).params.randomFieldFile), '\', '/'), ...
                strrep(string(fullfile(testCase.Folder, "a", "b", "../../shared/field.txt")), '\', '/'));
        end

        function exampleCaseFilesMatchTheirDataFiles(testCase)
            examples = fullfile(testCase.RepoRoot, "examples");
            field = fullfile(examples, "beam_102", "arquivo_3lc_rnao_cv05");
            legacy = ldem.Parameters.fromFile(fullfile(examples, "beam_102", "DATA0.DAT"), ...
                randomFieldFile = field);
            c = ldem.io.readCase(fullfile(examples, "beam_102", "case.ldem"));
            testCase.verifyEqual(testCase.normalizePaths(c.params.toStruct()), ...
                testCase.normalizePaths(legacy.toStruct()));
            testCase.verifyClass(c.scenario, 'ldem.scenarios.FourPointBending');

            legacy = ldem.Parameters.fromFile(fullfile(examples, "example1_clamped_beam", "DATA0.DAT"), ...
                randomFieldFile = field, trackedBar = 14398);
            c = ldem.io.readCase(fullfile(examples, "example1_clamped_beam", "case.ldem"));
            testCase.verifyEqual(testCase.normalizePaths(c.params.toStruct()), ...
                testCase.normalizePaths(legacy.toStruct()));
            testCase.verifyClass(c.scenario, 'ldem.scenarios.ClampedBeam');
            testCase.verifyEqual(c.scenario.forceRate, 1000);
            testCase.verifyEqual(c.scenario.rampTime, 0.00035);
        end

        function trackedBarIsACommentWhenOff(testCase)
            p = ldem.Parameters(trackedBar = 55);
            text = ldem.io.writeCase("", p);
            testCase.verifySubstring(text, '# tracked = 55');
            output = p.output;
            output.trackedBarEvery = 1;
            p.output = output;
            text = ldem.io.writeCase("", p);
            testCase.verifyTrue(contains(text, newline + "tracked = 55") || contains(text, "tracked  = 55"));
        end

        function filesAreOnlyEnabledWhenThereAreSnapshots(testCase)
            p = ldem.Parameters();                       % snapshotEvery = 0
            c = testCase.readBack(ldem.io.writeCase("", p), "none.ldem");
            testCase.verifyEqual(c.options.Formats, "mat");
            output = p.output;
            output.snapshotEvery = 10;
            p.output = output;
            c = testCase.readBack(ldem.io.writeCase("", p), "some.ldem");
            testCase.verifyEqual(c.options.Formats, ["mat" "ansys" "vtk"]);
            c = testCase.readBack(ldem.io.writeCase("", p, [], Formats = "vtk", OutputFolder = "out"), "vtk.ldem");
            testCase.verifyEqual(c.options.Formats, "vtk");
            testCase.verifyEqual(c.options.OutputFolder, string(fullfile(testCase.Folder, "out")));
        end

        function commentsCanBeOmitted(testCase)
            p = ldem.Parameters();
            withComments = ldem.io.writeCase("", p);
            without = ldem.io.writeCase("", p, [], Comments = false);
            testCase.verifySubstring(withComments, "Legacy: YNG");
            testCase.verifyFalse(contains(without, "#"));
            c = testCase.readBack(without, "plain.ldem");
            testCase.verifyEqual(c.params.toStruct(), p.toStruct());
        end

        function titleAuthorsHeaderAndNodeNames(testCase)
            p = ldem.Parameters(controlNodes = [1 2]);
            text = ldem.io.writeCase("", p, [], Title = "My test", Authors = ["Ana" "Luis"], ...
                Header = "Line one", ControlNodeNames = ["left" "right"]);
            c = testCase.readBack(text, "meta.ldem");
            testCase.verifyEqual(c.info.title, "My test");
            testCase.verifyEqual(c.info.authors, ["Ana" "Luis"]);
            testCase.verifyEqual(c.info.controlNodeNames, ["left" "right"]);
            testCase.verifySubstring(text, "# Line one");
        end

        function writesTheFileInAnewFolder(testCase)
            path = fullfile(testCase.Folder, "new", "deeper", "case.ldem");
            ldem.io.writeCase(path, ldem.Parameters());
            testCase.verifyTrue(isfile(path));
        end

        function everyTemplateReadsBack(testCase)
            for entry = ldem.scenarios.registry()
                path = fullfile(testCase.Folder, entry.name + ".ldem");
                ldem.io.writeTemplate(path, entry.name);
                c = ldem.io.readCase(path);
                testCase.verifyClass(c.scenario, entry.className);
                testCase.verifyEqual(c.params.testId, entry.testId);
            end
            testCase.verifyError(@() ldem.io.writeTemplate("", "rocket"), 'ldem:scenarios:unknownName');
        end

        function everyKeyOfTheSchemaAppearsInATemplate(testCase)
            text = ldem.io.writeTemplate("", "uniaxial_tension");
            schema = ldem.schema.caseSchema();
            onlyWithAnOption = ["material.scatter.file" "material.scatter.cv" ...
                "material.scatter.correlation_length" "material.scatter.seed" ...
                "monitor.bar.tracked" "format" "title" "authors" "scenario.type"];
            for row = schema.'
                if startsWith(row.path, "monitor.node") || any(row.path == onlyWithAnOption)
                    continue
                end
                key = string(regexprep(row.path, '^.*\.', ''));
                testCase.verifyTrue(contains(text, key + " "), row.path);
            end
        end

        function legacyExamplesConvertToTheSameParameters(testCase)
            for name = ["beam_102" "example1_clamped_beam"]
                dataFile = fullfile(testCase.RepoRoot, "examples", name, "DATA0.DAT");
                path = fullfile(testCase.Folder, name + ".ldem");
                ldem.io.convertLegacyInput(dataFile, path);
                fromCase = ldem.io.readCase(path);
                legacy = ldem.Parameters.fromFile(dataFile);
                testCase.verifyEqual(fromCase.params.toStruct(), legacy.toStruct(), name);
                testCase.verifyClass(fromCase.scenario, class(ldem.scenarios.fromTestId(legacy.testId)));
                testCase.verifyEqual(ldem.Parameters.fromFile(path).toStruct(), legacy.toStruct(), name);
            end
        end

        function theConverterNeverGuessesTheTrackedBar(testCase)
            dataFile = fullfile(testCase.RepoRoot, "examples", "example1_clamped_beam", "DATA0.DAT");
            text = ldem.io.convertLegacyInput(dataFile, "");
            testCase.verifySubstring(text, "The legacy value OU2 was 14398");
            c = testCase.readBack(text, "ou2.ldem");
            testCase.verifyEqual(c.params.trackedBar, ldem.Parameters().trackedBar);
        end

        function converterOptionsAreApplied(testCase)
            dataFile = fullfile(testCase.RepoRoot, "examples", "example1_clamped_beam", "DATA0.DAT");
            field = fullfile(testCase.Folder, "field.txt");
            path = fullfile(testCase.Folder, "conv.ldem");
            ldem.io.convertLegacyInput(dataFile, path, RandomFieldFile = field, TrackedBar = 14398, ...
                Title = "Beam", Authors = "Rodrigo", OutputFolder = "out");
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.params.trackedBar, 14398);
            testCase.verifyEqual(c.params.output.trackedBarEvery, 1);
            testCase.verifyEqual(string(c.params.randomFieldFile), string(fullfile(testCase.Folder, "field.txt")));
            testCase.verifyEqual(c.info.title, "Beam");
            testCase.verifyEqual(c.info.authors, "Rodrigo");
        end

        function aScenarioOutsideTheRegistryIsRefused(testCase)
            testCase.verifyError(@() ldem.io.writeCase("", ldem.Parameters(), TestWriteCase.unregistered()), ...
                'ldem:io:unregisteredScenario');
        end
    end

    methods (Access = private)
        function s = normalizePaths(~, s)
            % The random-field path may differ in separators (\ or /) and in ..
            s.randomFieldFile = string(java.io.File(char(s.randomFieldFile)).getCanonicalPath());
        end

        function c = readBack(testCase, text, name)
            path = fullfile(testCase.Folder, name);
            writeTextFile(path, splitlines(string(text)));
            c = ldem.io.readCase(path);
        end
    end

    methods (Static, Access = private)
        function s = unregistered()
            s = TestUnregisteredScenario();
        end
    end
end
