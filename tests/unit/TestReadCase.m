classdef TestReadCase < LdemTestCase
    %TESTREADCASE  Unit tests of ldem.io.readCase and of the case-file keys.

    properties (Access = private)
        Folder (1,1) string
        Last = []
    end

    methods (TestMethodSetup)
        function makeFolder(testCase)
            testCase.Folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
        end
    end

    methods (Access = private)
        function lines = minimal(~)
            lines = [ ...
                "format = 1"
                "[mesh]"
                "module_size = 3 mm"
                "modules = [5, 2, 2]"
                "[time]"
                "step = 0.2 us"
                "duration = 40 us"
                "[scenario]"
                "type = ""uniaxial_tension"""];
        end

        function c = read(testCase, extra, name)
            % Minimal case plus extra lines (which may open new sections).
            if nargin < 3
                name = "case.ldem";
            end
            path = fullfile(testCase.Folder, name);
            writeTextFile(path, [testCase.minimal(); string(extra(:))]);
            c = ldem.io.readCase(path);
        end

        function storeRead(testCase, extra)
            % Keeps the result in Last, to read it after verifyWarning.
            testCase.Last = testCase.read(extra);
        end

        function verifyCaseError(testCase, extra, id, fragment)
            path = fullfile(testCase.Folder, "bad.ldem");
            writeTextFile(path, [testCase.minimal(); string(extra(:))]);
            try
                ldem.io.readCase(path);
                testCase.verifyFail("An error was expected for: " + strjoin(string(extra), " / "));
            catch err
                testCase.verifyEqual(string(err.identifier), string(id));
                testCase.verifySubstring(err.message, fragment);
            end
        end
    end

    methods (Test, TestTags = {'Unit'})
        function minimalCaseTakesTheDefaults(testCase)
            c = testCase.read(strings(0, 1));
            p = c.params;
            d = ldem.Parameters();
            testCase.verifyEqual(p.nModules, [6 3 3]);
            testCase.verifyEqual(p.moduleLength, 0.003);
            testCase.verifyEqual(p.dt, 2e-7);
            testCase.verifyEqual(p.totalTime, 4e-5);
            testCase.verifyEqual(p.testId, 101);
            testCase.verifyEqual(p.youngModulus, d.youngModulus);
            testCase.verifyEqual(p.output, d.output);
            testCase.verifyEqual(p.controlNodes, d.controlNodes);
            testCase.verifyClass(c.scenario, 'ldem.scenarios.UniaxialTension');
            testCase.verifyEqual(c.options.OutputFolder, "");
            testCase.verifyEqual(c.options.Formats, "mat");
        end

        function convertsUnitsOfTheMaterial(testCase)
            c = testCase.read([ ...
                "[material]"
                "young_modulus = 3.87 GPa"
                "density = 1.5 g/cm3"
                "fracture_energy = 0.5 N/m"
                "critical_distance = 4.5 mm"
                "poisson_ratio = 0.2"
                "failure_area_factor = 0.2"
                "[damping]"
                "initial = 2.5 1/ms"
                "final = 1000"
                "switch_time = 15 ms"
                "constitutive = 1 us"]);
            p = c.params;
            testCase.verifyEqual(p.youngModulus, 3.87e9);
            testCase.verifyEqual(p.density, 1500);
            testCase.verifyEqual(p.fractureEnergy, 0.5);
            testCase.verifyEqual(p.criticalDistance, 4.5e-3);
            testCase.verifyEqual(p.poissonRatio, 0.2);
            testCase.verifyEqual(p.failureAreaFactor, 0.2);
            testCase.verifyEqual(p.dampingInitial, 2500);
            testCase.verifyEqual(p.dampingFinal, 1000);
            testCase.verifyEqual(p.dampingSwitchTime, 0.015);
            testCase.verifyEqual(p.constitutiveDamping, 1e-6);
        end

        function autoStepIsNinetyPercentOfTheCriticalOne(testCase)
            path = fullfile(testCase.Folder, "auto.ldem");
            lines = testCase.minimal();
            writeTextFile(path, lines(~startsWith(lines, "step")));    % no step key
            p = ldem.io.readCase(path).params;
            testCase.verifyEqual(p.dt, 0.9 * p.criticalTimeStep, 'RelTol', 1e-12);

            lines(startsWith(lines, "step")) = "step = ""auto""";      % explicit
            writeTextFile(path, lines);
            testCase.verifyEqual(ldem.io.readCase(path).params.dt, p.dt);
        end

        function outputCadenceInStepsOrTime(testCase)
            c = testCase.read([ ...
                "[output.snapshots]"
                "every = 10 us"
                "[output.control_nodes]"
                "every = 5 steps"
                "[output.energy]"
                "every = 1 step"]);
            testCase.verifyEqual(c.params.output.snapshotEvery, 50);
            testCase.verifyEqual(c.params.output.controlNodesEvery, 5);
            testCase.verifyEqual(c.params.output.energyEvery, 1);
            c = testCase.read(["[output.snapshots]"; "every = 0"; "[output.energy]"; "every = 20"]);
            testCase.verifyEqual(c.params.output.snapshotEvery, 0);
            testCase.verifyEqual(c.params.output.energyEvery, 20);
        end

        function cadenceThatIsNotAMultipleWarns(testCase)
            testCase.verifyWarning(@() testCase.storeRead(["[output.snapshots]"; "every = 10.05 us"]), ...
                'ldem:case:cadenceNotMultiple');
        end

        function badCadences(testCase)
            testCase.verifyCaseError(["[output.snapshots]"; "every = 0.05 us"], 'ldem:case:badValue', 'shorter than the time step');
            testCase.verifyCaseError(["[output.snapshots]"; "every = -3"], 'ldem:case:badValue', 'non-negative');
            testCase.verifyCaseError(["[output.snapshots]"; "every = 2.5 steps"], 'ldem:case:badValue', 'whole number');
        end

        function trackedBarSwitchesTheStrainHistoryOn(testCase)
            c = testCase.read(["[monitor.bar]"; "tracked = 5"]);
            testCase.verifyEqual(c.params.trackedBar, 5);
            testCase.verifyEqual(c.params.output.trackedBarEvery, 1);
            c = testCase.read(strings(0, 1));
            testCase.verifyEqual(c.params.output.trackedBarEvery, 0);
        end

        function controlNodesByNumberAndByPosition(testCase)
            c = testCase.read([ ...
                "[[monitor.node]]"
                "id = 2"
                "[[monitor.node]]"
                "name = ""first module"""
                "at = [0.5, 0.5, 0.5]"]);
            % The prism has 6*3*3 = 54 grid nodes; the first centre node is 55.
            testCase.verifyEqual(c.params.controlNodes, [2 55]);
            testCase.verifyEqual(c.info.controlNodeNames, ["node_2" "first module"]);
            testCase.verifyEmpty(c.info.nodeNotes);
        end

        function aPositionThatIsNotANodeWarnsAndNamesTheChosenOne(testCase)
            extra = ["[[monitor.node]]"; "at = [0.45, 0.5, 0.5]"];
            testCase.verifyWarning(@() testCase.storeRead(extra), 'ldem:case:nodeApproximated');
            c = testCase.Last;
            testCase.verifyEqual(c.params.controlNodes, 55);
            testCase.verifySubstring(c.info.nodeNotes, "using node 55");
        end

        function badControlNodes(testCase)
            testCase.verifyCaseError(["[[monitor.node]]"; "name = ""x"""], 'ldem:case:missingKey', 'either "id" or "at"');
            testCase.verifyCaseError(["[[monitor.node]]"; "id = 2"; "at = [1, 1, 1]"], ...
                'ldem:case:inconsistentKey', 'not both');
            testCase.verifyCaseError(["[[monitor.node]]"; "id = 0"], 'ldem:case:badValue', 'node number');
            testCase.verifyCaseError(["[[monitor.node]]"; "at = [1, 1]"], 'ldem:case:badValue', 'three numbers');
            testCase.verifyCaseError(["[[monitor.node]]"; "id = 5000"], 'ldem:params:controlNodeOutOfRange', 'bad.ldem');
        end

        function scenarioKeysBelongToTheScenarioClass(testCase)
            lines = testCase.minimal();
            lines = lines(~startsWith(lines, ["[scenario]" "type"]));
            path = fullfile(testCase.Folder, "beam.ldem");
            writeTextFile(path, [lines; "[scenario]"; "type = ""clamped_beam"""; ...
                "force_rate = 2 kN/s"; "ramp_time = 1 ms"; "load_position = 2.5 modules"; ...
                "load_height = 1.5"]);
            c = ldem.io.readCase(path);
            testCase.verifyClass(c.scenario, 'ldem.scenarios.ClampedBeam');
            testCase.verifyEqual(c.params.testId, 103);
            testCase.verifyEqual(c.scenario.forceRate, 2000);
            testCase.verifyEqual(c.scenario.rampTime, 1e-3);
            testCase.verifyEqual(c.scenario.loadPosition, 2.5);
            testCase.verifyEqual(c.scenario.loadHeight, 1.5);

            writeTextFile(path, [lines; "[scenario]"; "type = ""clamped_beam"""; "load_position = ""midspan"""]);
            c = ldem.io.readCase(path);
            testCase.verifyTrue(isnan(c.scenario.loadPosition));
        end

        function everyScenarioCanBeNamed(testCase)
            lines = testCase.minimal();
            lines = lines(~startsWith(lines, ["[scenario]" "type"]));
            path = fullfile(testCase.Folder, "any.ldem");
            for entry = ldem.scenarios.registry()
                writeTextFile(path, [lines; "[scenario]"; "type = """ + entry.name + """"]);
                c = ldem.io.readCase(path);
                testCase.verifyClass(c.scenario, entry.className);
                testCase.verifyEqual(c.params.testId, entry.testId);
            end
        end

        function scatterFromAFileIsRelativeToTheCase(testCase)
            c = testCase.read(["[material.scatter]"; "type = ""file"""; "file = ""sub/field.txt"""]);
            testCase.verifyEqual(c.params.randomFieldFile, string(fullfile(testCase.Folder, "sub/field.txt")));
            testCase.verifyEqual(c.params.randomFieldCv, 0);
        end

        function scatterGeneratedInMemory(testCase)
            c = testCase.read([ ...
                "[material.scatter]"
                "type = ""generated"""
                "cv = 0.05"
                "correlation_length = [2, 3, 4]"
                "seed = 7"]);
            p = c.params;
            testCase.verifyEqual(p.randomFieldCv, 0.05);
            testCase.verifyEqual(p.randomFieldCorrelationLength, [2 3 4]);
            testCase.verifyEqual(p.randomFieldSeed, 7);
            testCase.verifyEqual(p.randomFieldFile, "");
            c = testCase.read(["[material.scatter]"; "type = ""none"""]);
            testCase.verifyEqual(c.params.randomFieldCv, 0);
        end

        function scatterKeysMustFitTheType(testCase)
            testCase.verifyCaseError(["[material.scatter]"; "cv = 0.1"], 'ldem:case:missingKey', 'type');
            testCase.verifyCaseError(["[material.scatter]"; "type = ""none"""; "seed = 1"], ...
                'ldem:case:inconsistentKey', 'type = "none"');
            testCase.verifyCaseError(["[material.scatter]"; "type = ""file"""; "cv = 0.1"], ...
                'ldem:case:inconsistentKey', 'type = "file"');
            testCase.verifyCaseError(["[material.scatter]"; "type = ""file"""], 'ldem:case:missingKey', '"file"');
            testCase.verifyCaseError(["[material.scatter]"; "type = ""generated"""; "file = ""f"""], ...
                'ldem:case:inconsistentKey', 'generated');
            testCase.verifyCaseError(["[material.scatter]"; "type = ""generated"""], 'ldem:case:missingKey', '"cv"');
            testCase.verifyCaseError(["[material.scatter]"; "type = ""lognormal"""], 'ldem:case:badValue', 'Allowed');
        end

        function outputFolderAndFormats(testCase)
            c = testCase.read([ ...
                "[output]"
                "folder = ""results"""
                "mat = true"
                "ansys = false"
                "vtk = true"
                "[output.snapshots]"
                "every = 100 steps"]);
            testCase.verifyEqual(c.options.OutputFolder, string(fullfile(testCase.Folder, "results")));
            testCase.verifyEqual(c.options.Formats, ["mat" "vtk"]);
            c = testCase.read(["[output]"; "mat = false"]);
            testCase.verifyEmpty(c.options.Formats);
        end

        function requestingFilesWithoutSnapshotsWarns(testCase)
            testCase.verifyWarning(@() testCase.storeRead(["[output]"; "folder = ""o"""; "vtk = true"]), ...
                'ldem:case:noSnapshots');
        end

        function titleAndAuthorsAreKept(testCase)
            lines = testCase.minimal();
            path = fullfile(testCase.Folder, "meta.ldem");
            writeTextFile(path, [lines(1); "title = ""My beam"""; "authors = [""A"", ""B""]"; lines(2:end)]);
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.info.title, "My beam");
            testCase.verifyEqual(c.info.authors, ["A" "B"]);
            testCase.verifyEqual(c.info.format, 1);
        end

        function jsonGivesTheSameAsTheTextFormat(testCase)
            json = ['{"format":1,"mesh":{"module_size":"3 mm","modules":[5,2,2]},' ...
                '"time":{"step":"0.2 us","duration":"40 us"},' ...
                '"material":{"young_modulus":"30 GPa"},' ...
                '"monitor":{"node":[{"id":2},{"id":7}]},' ...
                '"scenario":{"type":"uniaxial_tension"}}'];
            jsonPath = fullfile(testCase.Folder, "case.json");
            writeTextFile(jsonPath, string(json));
            fromJson = ldem.io.readCase(jsonPath);
            fromText = testCase.read(["[material]"; "young_modulus = 30 GPa"; ...
                "[[monitor.node]]"; "id = 2"; "[[monitor.node]]"; "id = 7"]);
            testCase.verifyEqual(fromJson.params.toStruct(), fromText.params.toStruct());
            testCase.verifyEqual(ldem.Parameters.fromFile(jsonPath).toStruct(), fromText.params.toStruct());
        end

        function fromFileReadsCaseFilesAndAppliesOverrides(testCase)
            path = fullfile(testCase.Folder, "o.ldem");
            writeTextFile(path, testCase.minimal());
            p = ldem.Parameters.fromFile(path, trackedBar = 11, seed = 9);
            testCase.verifyEqual(p.trackedBar, 11);
            testCase.verifyEqual(p.seed, 9);
            testCase.verifyEqual(p.nModules, [6 3 3]);
        end

        function unknownKeysAreSuggested(testCase)
            testCase.verifyCaseError(["[material]"; "young_modulos = 3 GPa"], ...
                'ldem:case:unknownKey', "Did you mean 'young_modulus'?");
            testCase.verifyCaseError(["[matrial]"; "x = 1"], 'ldem:case:unknownKey', "Did you mean 'material'?");
            testCase.verifyCaseError("speed = 3", 'ldem:case:unknownKey', 'no key "speed"');
            testCase.verifyCaseError("flavour = 3", 'ldem:case:unknownKey', 'flavour');
        end

        function errorsNameTheLineSectionAndKey(testCase)
            try
                testCase.read(["[material]"; "young_modulus = 3 mm"]);
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:case:badUnit');
                testCase.verifySubstring(err.message, 'case.ldem:11 [material] young_modulus');
            end
        end

        function valuesRejectedByParametersNameTheirLine(testCase)
            testCase.verifyCaseError(["[material]"; "young_modulus = -3 GPa"], 'ldem:case:invalidValue', ...
                'bad.ldem:11 [material] young_modulus');
            testCase.verifyCaseError(["[mesh2]"; "x = 1"], 'ldem:case:unknownKey', 'mesh2');
        end

        function crossChecksOfParametersKeepTheirIdentifier(testCase)
            testCase.verifyCaseError(["[material]"; "poisson_ratio = 0.5"], 'ldem:params:badPoissonRatio', 'bad.ldem');
        end

        function typeErrors(testCase)
            testCase.verifyCaseError(["[material]"; "poisson_ratio = ""high"""], 'ldem:case:badValue', 'Expected a number');
            testCase.verifyCaseError("[mesh]", 'ldem:case:syntax', 'appears twice');
            testCase.verifyCaseError(["[output]"; "mat = 1"], 'ldem:case:badValue', 'true or false');
            testCase.verifyCaseError(["[material]"; "law = ""exponential"""], 'ldem:case:badValue', 'bilinear');
            testCase.verifyCaseError(["[damping]"; "type = ""rayleigh"""], 'ldem:case:badValue', 'mass_proportional');
        end

        function requiredKeysAreChecked(testCase)
            path = fullfile(testCase.Folder, "r.ldem");
            for drop = ["type" "modules" "duration"]
                lines = testCase.minimal();
                lines = lines(~startsWith(lines, drop));
                writeTextFile(path, lines);
                try
                    ldem.io.readCase(path);
                    testCase.verifyFail("Missing " + drop + " must fail.");
                catch err
                    testCase.verifyEqual(err.identifier, 'ldem:case:missingKey');
                    testCase.verifySubstring(err.message, drop);
                end
            end
        end

        function badModulesAndFormat(testCase)
            path = fullfile(testCase.Folder, "m.ldem");
            lines = testCase.minimal();
            lines(startsWith(lines, "modules")) = "modules = [5, 2]";
            writeTextFile(path, lines);
            testCase.verifyError(@() ldem.io.readCase(path), 'ldem:case:badValue');
            lines(startsWith(lines, "modules")) = "modules = [5, 0, 2]";
            writeTextFile(path, lines);
            testCase.verifyError(@() ldem.io.readCase(path), 'ldem:case:badValue');
            lines = testCase.minimal();
            lines(1) = "format = 2";
            writeTextFile(path, lines);
            testCase.verifyError(@() ldem.io.readCase(path), 'ldem:case:unsupportedFormat');
        end

        function missingFileAndWrongExtension(testCase)
            testCase.verifyError(@() ldem.io.readCase(fullfile(testCase.Folder, "none.ldem")), 'ldem:io:fileNotFound');
            path = fullfile(testCase.Folder, "case.txt");
            writeTextFile(path, testCase.minimal());
            testCase.verifyError(@() ldem.io.readCase(path), 'ldem:io:unknownExtension');
        end

        function unstableTimeStepNamesTheFile(testCase)
            lines = testCase.minimal();
            lines(startsWith(lines, "step")) = "step = 4 ms";
            lines(startsWith(lines, "duration")) = "duration = 40 ms";
            path = fullfile(testCase.Folder, "u.ldem");
            writeTextFile(path, lines);
            try
                ldem.io.readCase(path);
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:params:unstableTimeStep');
                testCase.verifySubstring(err.message, 'u.ldem');
            end
        end

        function theRegistryAgreesWithTheScenarioClasses(testCase)
            reg = ldem.scenarios.registry();
            testCase.verifyEqual(numel(unique([reg.name])), numel(reg));
            testCase.verifyEqual(numel(unique([reg.testId])), numel(reg));
            for entry = reg
                scenario = feval(entry.className);
                testCase.verifyEqual(scenario.testId, entry.testId);
                testCase.verifyClass(ldem.scenarios.fromName(entry.name), entry.className);
                testCase.verifyClass(ldem.scenarios.fromTestId(entry.testId), entry.className);
                for prop = string(fieldnames(entry.units)).'
                    testCase.verifyTrue(isprop(scenario, prop), entry.className + "." + prop);
                end
            end
            testCase.verifyError(@() ldem.scenarios.fromName("rocket"), 'ldem:scenarios:unknownName');
        end

        function everyKeyOfTheSchemaIsConsistent(testCase)
            schema = ldem.schema.caseSchema();
            testCase.verifyEqual(numel(unique(string({schema.path}))), numel(schema));
            kinds = ["integer" "number" "quantity" "string" "stringlist" "path" "intlist" ...
                "numberlist" "bool" "enum" "stepOrAuto" "cadence" "coordinate" "loadQuantity"];
            props = string(properties('ldem.Parameters'));
            for row = schema.'
                testCase.verifyTrue(any(row.kind == kinds), row.path);
                [~, ~] = ldem.schema.unitTable(row.dimension);    % the dimension exists
                if row.prop ~= "" && row.kind ~= "cadence"    % cadences are fields of Parameters.output
                    testCase.verifyTrue(any(props == row.prop), row.path + " -> " + row.prop);
                end
            end
        end
    end
end
