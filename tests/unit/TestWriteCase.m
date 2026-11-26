classdef TestWriteCase < LdemTestCase
    %TESTWRITECASE  Unit tests of ldem.io.writeCase and ldem.io.writeTemplate.

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
            testCase.verifyEqual(c.scenario.loading, "force");

            scenario = ldem.scenarios.ClampedBeam(loading = "displacement", loadingVelocity = 2.5e-3);
            ldem.io.writeCase(path, p, scenario);
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.scenario.loading, "displacement");
            testCase.verifyEqual(c.scenario.loadingVelocity, 2.5e-3);
        end

        function defaultsAndMidspanRoundTrip(testCase)
            p = ldem.Parameters(testId = 103);
            path = fullfile(testCase.Folder, "defaults.ldem");
            text = ldem.io.writeCase(path, p);
            testCase.verifyMatches(text, 'load_position\s+=\s+"midspan"');
            testCase.verifyMatches(text, 'loading +=\s+"force"');
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
                strrep(string(fullfile(testCase.Folder, "shared", "field.txt")), '\', '/'));
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
            testCase.verifySubstring(withComments, "# Young's modulus.");
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
                "monitor.bar.tracked" "format" "title" "authors" "scenario.type" ...
                "extends" "sweep_mode"];
            for row = schema.'
                if startsWith(row.path, ["monitor.node" "support." "load." "sweep."]) || any(row.path == onlyWithAnOption)
                    continue
                end
                key = string(regexprep(row.path, '^.*\.', ''));
                testCase.verifyTrue(contains(text, key + " "), row.path);
            end
        end

        function aScenarioOutsideTheRegistryIsRefused(testCase)
            testCase.verifyError(@() ldem.io.writeCase("", ldem.Parameters(), TestWriteCase.unregistered()), ...
                'ldem:io:unregisteredScenario');
        end
    end

    methods (Access = private)
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
