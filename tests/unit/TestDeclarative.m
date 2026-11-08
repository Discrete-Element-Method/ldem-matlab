classdef TestDeclarative < LdemTestCase
    %TESTDECLARATIVE  Unit tests of the declarative scenario ([[support]] and [[load]] blocks).

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
        function path = writeCase(testCase, scenarioLines, extra)
            % A small case whose [scenario] section is scenarioLines.
            if nargin < 3
                extra = strings(0, 1);
            end
            path = fullfile(testCase.Folder, "custom.ldem");
            writeTextFile(path, [ ...
                "format = 1"
                "[mesh]"
                "module_size = 3 mm"
                "modules = [5, 2, 2]"
                "[time]"
                "step = 0.2 us"
                "duration = 20 us"
                string(extra(:))
                "[scenario]"
                string(scenarioLines(:))]);
        end

        function verifyCaseError(testCase, scenarioLines, id, fragment)
            path = testCase.writeCase(scenarioLines);
            try
                ldem.io.readCase(path);
                testCase.verifyFail("An error was expected for: " + strjoin(string(scenarioLines), " / "));
            catch err
                testCase.verifyEqual(string(err.identifier), string(id));
                testCase.verifySubstring(err.message, fragment);
            end
        end
    end

    methods (Test, TestTags = {'Unit'})
        function coordinatesAreParsedInEveryForm(testCase)
            parse = @ldem.scenarios.parseCoordinate;
            r = parse(0.5);
            testCase.verifyEqual(r.lo, struct('base', "", 'offset', 0.5));
            testCase.verifyEqual(r.hi, r.lo);
            r = parse("max - 0.5");
            testCase.verifyEqual(r.lo, struct('base', "max", 'offset', -0.5));
            r = parse("  MID  ");
            testCase.verifyEqual(r.lo, struct('base', "mid", 'offset', 0));
            r = parse("min + 1.5 modules");
            testCase.verifyEqual(r.lo, struct('base', "min", 'offset', 1.5));
            r = parse("2.5 modules");
            testCase.verifyEqual(r.lo, struct('base', "", 'offset', 2.5));
            r = parse([0 5]);
            testCase.verifyEqual([r.lo.offset r.hi.offset], [0 5]);
            r = parse(["min + 0.5" "max - 0.5"]);
            testCase.verifyEqual([r.lo.base r.hi.base], ["min" "max"]);
        end

        function badCoordinatesAreRefused(testCase)
            for bad = {"maximum", "max * 2", "max -", "abc", [1 2 3], "", Inf}
                testCase.verifyError(@() ldem.scenarios.parseCoordinate(bad{1}), 'ldem:case:badValue');
            end
        end

        function coordinateTextRoundTrips(testCase)
            for value = {0.5, "max - 0.5", "mid", "min + 1", [0 5], ["min + 0.5" "max - 0.5"], 2.25}
                range = ldem.scenarios.parseCoordinate(value{1});
                text = ldem.scenarios.coordinateText(range);
                testCase.verifyEqual(ldem.scenarios.parseCoordinate(testCase.evaluate(text)), range);
            end
            testCase.verifyEqual(ldem.scenarios.coordinateText(ldem.scenarios.parseCoordinate("max - 0.5")), """max - 0.5""");
            testCase.verifyEqual(ldem.scenarios.coordinateText(ldem.scenarios.parseCoordinate(0.5)), "0.5");
        end

        function selectionByKindIdsAndCoordinates(testCase)
            p = ldem.Parameters(nModules = [6 3 3]);      % 5 x 2 x 2 modules, 54 grid + 20 centre nodes
            sel = @(varargin) ldem.scenarios.Declarative.makeSelector(varargin{:});
            select = @(s) ldem.scenarios.selectNodes(s, p);

            testCase.verifyEqual(nnz(select(sel())), 74);
            testCase.verifyEqual(nnz(select(sel(nodes = "grid"))), 54);
            testCase.verifyEqual(nnz(select(sel(nodes = "centre"))), 20);
            testCase.verifyEqual(find(select(sel(ids = [3 60]))).', [3 60]);
            % First layer of centre nodes along x: 2 x 2 of them.
            testCase.verifyEqual(nnz(select(sel(x = 0.5))), 4);
            % Last layer, with the reference max.
            testCase.verifyEqual(find(select(sel(x = "max - 0.5"))), find(select(sel(x = 4.5))));
            % Grid nodes at the ends of the prism (x = 0 and x = max): 2 * 3 * 3.
            testCase.verifyEqual(nnz(select(sel(x = "min"))) + nnz(select(sel(x = "max"))), 2 * 3 * 3);
            % mid is half of the length: x = 2.5 is a layer of centre nodes.
            testCase.verifyEqual(nnz(select(sel(x = "mid"))), 4);
            % A range includes both ends.
            testCase.verifyEqual(nnz(select(sel(nodes = "centre", x = [0.5 1.5]))), 8);
            % Combined restrictions intersect.
            testCase.verifyEqual(nnz(select(sel(nodes = "centre", x = 0.5, y = 0.5, z = 0.5))), 1);
            testCase.verifyEqual(nnz(select(sel(nodes = "grid", x = 0.5))), 0);
        end

        function selectionIgnoresThePerturbationOfTheMesh(testCase)
            plain = ldem.Parameters(nModules = [6 3 3]);
            shaken = ldem.Parameters(nModules = [6 3 3], meshPerturbation = 0.02);
            sel = ldem.scenarios.Declarative.makeSelector(x = 2.5);
            testCase.verifyEqual(ldem.scenarios.selectNodes(sel, plain), ldem.scenarios.selectNodes(sel, shaken));
        end

        function timeFunctions(testCase)
            make = @ldem.scenarios.Declarative.makeFunction;
            value = @(fn, t) ldem.scenarios.timeFunction(fn, t);
            testCase.verifyEqual(value(make("constant", value = 3), 7), 3);
            testCase.verifyEqual(value(make("linear", rate = -2), 5), -10);
            ramp = make("ramp", rate = 1000, until = 0.35e-3);
            testCase.verifyEqual(value(ramp, 0.1e-3), 0.1);
            testCase.verifyEqual(value(ramp, 1), 0.35);
            tab = make("table", times = [0 1 3], values = [0 10 0]);
            testCase.verifyEqual(value(tab, 0.5), 5);
            testCase.verifyEqual(value(tab, 2), 5);
            testCase.verifyEqual(value(tab, -1), 0);          % before the first time
            testCase.verifyEqual(value(tab, 99), 0);          % after the last one
            bad = make("constant");
            bad.type = "spline";
            testCase.verifyError(@() ldem.scenarios.timeFunction(bad, 0), 'ldem:scenarios:badTimeFunction');
        end

        function malformedBlocksAreRefused(testCase)
            make = @ldem.scenarios.Declarative.makeFunction;
            testCase.verifyError(@() make("ramp", rate = 1), 'ldem:scenarios:badDefinition');
            testCase.verifyError(@() make("table", times = [0 1], values = 1), 'ldem:scenarios:badDefinition');
            testCase.verifyError(@() make("table", times = [1 0], values = [1 2]), 'ldem:scenarios:badDefinition');
            sel = ldem.scenarios.Declarative.makeSelector();
            testCase.verifyError(@() ldem.scenarios.Declarative.makeSupport(sel, "q"), 'ldem:scenarios:badDefinition');
            testCase.verifyError(@() ldem.scenarios.Declarative.makeSupport(sel, ""), 'ldem:scenarios:badDefinition');
            support = ldem.scenarios.Declarative.makeSupport(sel, "zx");
            testCase.verifyEqual(support.fix, [1 3]);
            testCase.verifyError(@() ldem.scenarios.Declarative(supports = struct('a', 1)), 'ldem:scenarios:badDefinition');
            testCase.verifyError(@() ldem.scenarios.Declarative(loads = struct('a', 1)), 'ldem:scenarios:badDefinition');
        end

        function emptySelectionNamesTheBlock(testCase)
            sel = ldem.scenarios.Declarative.makeSelector(x = 99);
            scenario = ldem.scenarios.Declarative( ...
                supports = ldem.scenarios.Declarative.makeSupport(sel, "x", name = "ghost"));
            p = ldem.Parameters(testId = 900, nModules = [6 3 3]);
            try
                ldem.mesh.buildMesh(p, scenario);
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:scenarios:noNodesSelected');
                testCase.verifySubstring(err.message, '[[support]] number 1 ("ghost")');
            end
        end

        function scenarioDataIsPreparedOnlyWhenNeeded(testCase)
            p = ldem.Parameters(testId = 101, nModules = [6 3 3]);
            testCase.verifyFalse(isfield(ldem.mesh.buildMesh(p), 'scenarioData'));

            left = ldem.scenarios.Declarative.makeSelector(x = 0.5);
            scenario = ldem.scenarios.Declarative( ...
                supports = ldem.scenarios.Declarative.makeSupport(left, "x", reaction = true));
            mesh = ldem.mesh.buildMesh(ldem.Parameters(testId = 900, nModules = [6 3 3]), scenario);
            testCase.verifyTrue(isfield(mesh, 'scenarioData'));
            testCase.verifyTrue(mesh.scenarioData.hasReaction);
            testCase.verifyEqual(numel(mesh.scenarioData.reactionNodes{1}), 4);
            testCase.verifyEmpty(mesh.scenarioData.reactionNodes{2});
        end

        function reactionIsNaNUnlessMarked(testCase)
            sel = ldem.scenarios.Declarative.makeSelector(x = 0.5);
            plain = ldem.scenarios.Declarative(supports = ldem.scenarios.Declarative.makeSupport(sel, "x"));
            p = ldem.Parameters(testId = 900, nModules = [6 3 3]);
            mesh = ldem.mesh.buildMesh(p, plain);
            state = struct('force', ones(size(mesh.nodes0)));
            testCase.verifyTrue(all(isnan(plain.reactions(state, mesh, p))));

            marked = ldem.scenarios.Declarative(supports = ldem.scenarios.Declarative.makeSupport(sel, "xy", reaction = true));
            mesh = ldem.mesh.buildMesh(p, marked);
            testCase.verifyEqual(marked.reactions(state, mesh, p), [4 4 0]);
        end

        function forceLoadsAddUpAndDisplacementLoadsSetThePosition(testCase)
            p = ldem.Parameters(testId = 900, nModules = [6 3 3]);
            import ldem.scenarios.Declarative
            node = Declarative.makeSelector(ids = 60);
            half = Declarative.makeFunction("constant", value = 5);
            scenario = ldem.scenarios.Declarative(loads = [ ...
                Declarative.makeLoad(node, "y", "force", half), ...
                Declarative.makeLoad(node, "y", "force", Declarative.makeFunction("linear", rate = 100)), ...
                Declarative.makeLoad(Declarative.makeSelector(ids = 61), "z", "displacement", Declarative.makeFunction("linear", rate = -2))]);
            mesh = ldem.mesh.buildMesh(p, scenario);
            testCase.verifyTrue(mesh.fixed(61, 3));         % a prescribed displacement is held
            testCase.verifyFalse(any(mesh.fixed(60, :)));   % a force load leaves the node free

            state = ldem.solver.initialState(mesh, struct('tensionStiffness', 1, 'maxStrain', 1, ...
                'isUndamaged', true, 'isUnbroken', true));
            state.time = 0.5;
            state.appliedForce(:) = 99;                     % must be reset
            state = scenario.applyLoads(state, mesh, p);
            testCase.verifyEqual(state.appliedForce(60, 2), 5 + 50);
            testCase.verifyEqual(nnz(state.appliedForce), 1);
            testCase.verifyEqual(state.displacement(61, 3), mesh.nodes0(61, 3) - 1);
        end

        function reproducesTheBuiltInScenarios(testCase)
            import ldem.scenarios.Declarative

            % Uniaxial tension (test 101).
            params = {'nModules', [6 3 3], 'totalTime', 2e-5, 'fractureEnergy', 0.1};
            reference = ldem.runSimulation(ldem.Parameters(params{:}, testId = 101));
            scenario = ldem.scenarios.Declarative( ...
                supports = Declarative.makeSupport(Declarative.makeSelector(x = 0.5), "x"), ...
                loads = Declarative.makeLoad(Declarative.makeSelector(x = "max - 0.5"), "x", "displacement", ...
                    Declarative.makeFunction("linear", rate = -400e-5)));
            result = ldem.runSimulation(ldem.Parameters(params{:}, testId = 900), Scenario = scenario);
            testCase.verifyEqual(result.final.displacement, reference.final.displacement);
            testCase.verifyEqual(result.energy, reference.energy);

            % Four-point bending (test 102): a short run of the 70-module beam.
            params = {'nModules', [70 4 3], 'totalTime', 3e-5, 'fractureEnergy', 0.5};
            reference = ldem.runSimulation(ldem.Parameters(params{:}, testId = 102));
            pull = Declarative.makeFunction("linear", rate = -400e-5);
            scenario = ldem.scenarios.Declarative( ...
                supports = [Declarative.makeSupport(Declarative.makeSelector(y = 0.5, x = 4.5), "xy"), ...
                            Declarative.makeSupport(Declarative.makeSelector(y = 0.5, x = "max - 4.5"), "y")], ...
                loads = [Declarative.makeLoad(Declarative.makeSelector(y = "max - 0.5", x = 33.5), "y", "displacement", pull, reaction = true), ...
                         Declarative.makeLoad(Declarative.makeSelector(y = "max - 0.5", x = "max - 33.5"), "y", "displacement", pull, reaction = true)]);
            result = ldem.runSimulation(ldem.Parameters(params{:}, testId = 900), Scenario = scenario);
            testCase.verifyEqual(result.final.displacement, reference.final.displacement);
            testCase.verifyEqual(result.energy, reference.energy);
            testCase.verifyEqual(result.reactions.force, reference.reactions.force);

            % Beam clamped at both ends and loaded with a force (test 103).
            params = {'nModules', [6 6 21], 'moduleLength', 0.001, 'dt', 3.5e-7, 'totalTime', 4e-5, ...
                'youngModulus', 3.87e9, 'density', 1500, 'fractureEnergy', 0.5, 'criticalDistance', 4.5e-3};
            reference = ldem.runSimulation(ldem.Parameters(params{:}, testId = 103), ...
                Scenario = ldem.scenarios.ClampedBeam(forceRate = 1000, rampTime = 0.00035));
            scenario = ldem.scenarios.Declarative( ...
                supports = [Declarative.makeSupport(Declarative.makeSelector(z = 0.5), "xyz", reaction = true), ...
                            Declarative.makeSupport(Declarative.makeSelector(z = "max - 0.5"), "xyz", reaction = true)], ...
                loads = Declarative.makeLoad(Declarative.makeSelector(y = 0.5, z = "mid - 0.5"), "y", "force", ...
                    Declarative.makeFunction("ramp", rate = 1000, until = 0.00035)));
            result = ldem.runSimulation(ldem.Parameters(params{:}, testId = 900), Scenario = scenario);
            testCase.verifyEqual(result.final.displacement, reference.final.displacement);
            testCase.verifyEqual(result.energy, reference.energy);
            scale = max(abs(reference.reactions.force(:)));
            testCase.verifyEqual(result.reactions.force, reference.reactions.force, ...
                'RelTol', 1e-12, 'AbsTol', 1e-12 * scale);
        end

        function caseFileBlocksReproduceTheUniaxialTest(testCase)
            path = testCase.writeCase([ ...
                "type = ""custom"""
                "[[support]]"
                "name = ""left end"""
                "x = 0.5"
                "fix = [""x""]"
                "[[load]]"
                "x = ""max - 0.5"""
                "direction = ""x"""
                "type = ""displacement"""
                "time_function = ""linear"""
                "rate = -4 mm/s"], ["[material]"; "fracture_energy = 0.1 N/m"]);
            c = ldem.io.readCase(path);
            testCase.verifyClass(c.scenario, 'ldem.scenarios.Declarative');
            testCase.verifyEqual(c.params.testId, 900);
            testCase.verifyEqual(c.scenario.supports.name, "left end");
            testCase.verifyEqual(c.scenario.loads.fn.rate, -4e-3);

            viaCase = ldem.runSimulation(c.params, Scenario = c.scenario);
            builtin = ldem.runSimulation(ldem.Parameters(testId = 101, nModules = [6 3 3], ...
                moduleLength = 0.003, dt = 2e-7, totalTime = 20e-6, fractureEnergy = 0.1));
            testCase.verifyEqual(viaCase.final.displacement, builtin.final.displacement);
        end

        function caseFilesRoundTripTheBlocks(testCase)
            import ldem.scenarios.Declarative
            sel = Declarative.makeSelector(nodes = "centre", ids = [3 5], x = [0.5 "max - 0.5"], z = "mid");
            scenario = ldem.scenarios.Declarative( ...
                supports = [Declarative.makeSupport(Declarative.makeSelector(x = 0.5), "xz", name = "wall", reaction = true), ...
                            Declarative.makeSupport(sel, "y")], ...
                loads = [Declarative.makeLoad(Declarative.makeSelector(y = "max - 0.5"), "y", "force", ...
                            Declarative.makeFunction("ramp", rate = 2500, until = 1e-5), name = "push", reaction = true), ...
                         Declarative.makeLoad(Declarative.makeSelector(x = [0.5 1.5]), "z", "displacement", ...
                            Declarative.makeFunction("table", times = [0 1e-5 2e-5], values = [0 1e-4 1e-4])), ...
                         Declarative.makeLoad(Declarative.makeSelector(nodes = "grid"), "x", "force", Declarative.makeFunction("constant", value = 3))]);
            p = ldem.Parameters(testId = 900, nModules = [6 3 3], totalTime = 2e-5);
            path = fullfile(testCase.Folder, "blocks.ldem");

            text = ldem.io.writeCase(path, p, scenario);
            testCase.verifySubstring(text, '[[support]]');
            testCase.verifySubstring(text, '[[load]]');
            testCase.verifySubstring(text, '"mid"');
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.scenario.supports, scenario.supports);
            testCase.verifyEqual(c.scenario.loads, scenario.loads);
            testCase.verifyEqual(c.params.toStruct(), p.toStruct());
        end

        function theCustomTemplateReadsBack(testCase)
            path = fullfile(testCase.Folder, "template.ldem");
            text = ldem.io.writeTemplate(path, "custom");
            testCase.verifySubstring(text, '[[support]]');
            c = ldem.io.readCase(path);
            testCase.verifyEqual(numel(c.scenario.supports), 1);
            testCase.verifyEqual(numel(c.scenario.loads), 1);
            report = ldem.check(path);       % builds the mesh: the blocks select nodes
            testCase.verifyEqual(report.params.testId, 900);
        end

        function aCustomCaseWithoutBlocksIsReadable(testCase)
            c = ldem.io.readCase(testCase.writeCase("type = ""custom"""));
            testCase.verifyEmpty(c.scenario.supports);
            testCase.verifyEmpty(c.scenario.loads);
        end

        function blockErrorsNameTheirLine(testCase)
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "x = 0.5"], ...
                'ldem:case:missingKey', 'needs "fix"');
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "fix = [""x""]"; "flavour = 1"], ...
                'ldem:case:unknownKey', 'flavour');
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "fix = [""q""]"], ...
                'ldem:case:badValue', 'Directions are x, y and z');
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "fix = [""x""]"; "x = ""max *"""], ...
                'ldem:case:badValue', 'not a coordinate');
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "fix = [""x""]"; "ids = [0]"], ...
                'ldem:case:badValue', 'node numbers');
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "fix = [""x""]"; "nodes = ""cntre"""], ...
                'ldem:case:badValue', "Did you mean 'centre'?");
            testCase.verifyCaseError(["type = ""custom"""; "[[support]]"; "fix = [""x""]"; "reaction = 1"], ...
                'ldem:case:badValue', 'true or false');
            testCase.verifyCaseError(["type = ""custom"""; "[[load]]"; "direction = ""x"""], ...
                'ldem:case:missingKey', 'needs "type"');
        end

        function loadFunctionKeysMustMatchTheFunction(testCase)
            head = ["type = ""custom"""; "[[load]]"; "direction = ""y"""; "type = ""force"""];
            testCase.verifyCaseError([head; "time_function = ""constant"""], 'ldem:case:missingKey', 'needs the key "value"');
            testCase.verifyCaseError([head; "time_function = ""constant"""; "value = 1 N"; "rate = 2 N/s"], ...
                'ldem:case:inconsistentKey', 'does not apply when time_function = "constant"');
            testCase.verifyCaseError([head; "time_function = ""ramp"""; "rate = 2 N/s"], 'ldem:case:missingKey', '"until"');
            testCase.verifyCaseError([head; "time_function = ""linear"""; "rate = 2 mm/s"], 'ldem:case:badUnit', 'N/s');
            testCase.verifyCaseError([head; "time_function = ""constant"""; "value = 2 mm"], 'ldem:case:badUnit', 'N, kN, MN');
            testCase.verifyCaseError([head; "time_function = ""table"""; "times = [0, 1]"; "values = [1]"], ...
                'ldem:case:badValue', 'table needs');
            testCase.verifyCaseError([head; "time_function = ""spline"""], 'ldem:case:badValue', 'Allowed');
            % The right unit for a displacement load is a length.
            c = ldem.io.readCase(testCase.writeCase(["type = ""custom"""; "[[load]]"; "direction = ""y"""; ...
                "type = ""displacement"""; "time_function = ""constant"""; "value = 2 mm"]));
            testCase.verifyEqual(c.scenario.loads.fn.value, 2e-3);
        end

        function blocksNeedTheCustomType(testCase)
            testCase.verifyCaseError(["type = ""uniaxial_tension"""; "[[support]]"; "fix = [""x""]"], ...
                'ldem:case:inconsistentKey', 'type = "custom"');
            testCase.verifyCaseError(["type = ""custom"""; "[support]"; "fix = [""x""]"], ...
                'ldem:case:syntax', 'double brackets');
        end
    end

    methods (Static, Access = private)
        function value = evaluate(text)
            % The right-hand side of "key = value" as the parser reads it.
            entries = ldem.io.parseCaseText("k = " + text, "t");
            value = entries.value;
        end
    end
end
