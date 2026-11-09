classdef TestLawsAndDamping < LdemTestCase
    %TESTLAWSANDDAMPING  Unit tests of the constitutive laws and damping models.

    properties (Constant)
        E1 = 1e6        % bar stiffness [N]
        L  = 0.01       % bar length [m]
        Mass = 0.1      % mass of the free node [kg]
    end

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
        function [mesh, barProps, history] = oscillator(testCase)
            % One bar: node 1 fixed, node 2 free along x (a spring of constant E1/L).
            mesh = struct( ...
                'nodes0',    [0 0 0; testCase.L 0 0], ...
                'bars',      [1 2], ...
                'barLength', testCase.L, ...
                'mass',      [testCase.Mass; testCase.Mass], ...
                'fixed',     [true true true; false true true]);
            barProps = struct('stiffness', testCase.E1, 'criticalStrain', 1, ...
                'ruptureRatio', 10, 'ruptureStrain', 10);
            history = struct('tensionStiffness', testCase.E1, 'maxStrain', 1, ...
                'isUndamaged', true, 'isUnbroken', true);
        end

        function [barProps, history, length] = threeBars(testCase)
            % Bars 1-3 at strain 0.5e-3 (elastic), 2e-3 (softening) and 5e-3 (broken).
            barProps = struct('stiffness', testCase.E1 * [1; 1; 1], ...
                'criticalStrain', 1e-3 * [1; 1; 1], 'ruptureRatio', 5 * [1; 1; 1], ...
                'ruptureStrain', 5e-3 * [1; 1; 1]);
            history = struct('tensionStiffness', testCase.E1 * [1; 1; 1], ...
                'maxStrain', 1e-3 * [1; 1; 1], 'isUndamaged', true(3, 1), 'isUnbroken', true(3, 1));
            length = 0.01 * [1; 1; 1];
        end

        function path = writeCase(testCase, extra)
            path = fullfile(testCase.Folder, "case.ldem");
            writeTextFile(path, [ ...
                "format = 1"
                "[mesh]"
                "module_size = 3 mm"
                "modules = [5, 2, 2]"
                "[time]"
                "step = 0.2 us"
                "duration = 40 us"
                "[scenario]"
                "type = ""uniaxial_tension"""
                string(extra(:))]);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function registriesAgreeWithTheirClasses(testCase)
            laws = ldem.material.lawRegistry();
            testCase.verifyEqual(numel(unique([laws.name])), numel(laws));
            for entry = laws
                law = feval(entry.className);
                testCase.verifyEqual(law.name, entry.name);
                testCase.verifyInstanceOf(law, 'ldem.material.MaterialLaw');
                testCase.verifyClass(ldem.material.lawFromName(entry.name), entry.className);
                testCase.verifyClass(ldem.material.lawFromName(upper(entry.name)), entry.className);
            end
            models = ldem.solver.dampingRegistry();
            testCase.verifyEqual(numel(unique([models.name])), numel(models));
            for entry = models
                model = feval(entry.className);
                testCase.verifyEqual(model.name, entry.name);
                testCase.verifyInstanceOf(model, 'ldem.solver.DampingModel');
                testCase.verifyClass(ldem.solver.dampingFromName(entry.name), entry.className);
                testCase.verifyTrue(all(ismember(entry.keys, ["initial" "final" "switch_time"])));
            end
        end

        function unknownNamesAreSuggested(testCase)
            testCase.verifyError(@() ldem.material.lawFromName("bilinar"), 'ldem:material:unknownLaw');
            try
                ldem.material.lawFromName("bilinar");
            catch err
                testCase.verifySubstring(err.message, "Did you mean 'bilinear'?");
            end
            testCase.verifyError(@() ldem.solver.dampingFromName("mass"), 'ldem:solver:unknownDamping');
        end

        function parametersCheckTheNames(testCase)
            p = ldem.Parameters();
            testCase.verifyEqual(p.constitutiveLaw, "bilinear");
            testCase.verifyEqual(p.dampingModel, "mass_proportional");
            testCase.verifyError(@() ldem.Parameters(constitutiveLaw = "plastic"), 'ldem:params:unknownLaw');
            testCase.verifyError(@() ldem.Parameters(dampingModel = "viscous"), 'ldem:params:unknownDampingModel');
            q = ldem.Parameters(constitutiveLaw = "linear_elastic", dampingModel = "none");
            testCase.verifyEqual(q.constitutiveLaw, "linear_elastic");
        end

        function bilinearObjectMatchesTheFunction(testCase)
            [barProps, history] = testCase.threeBars();
            strain = [0.5e-3; 2e-3; 5e-3];
            rate = [1; -2; 3];
            params = ldem.Parameters(constitutiveDamping = 1e-6);
            [expectedForce, expectedHistory] = ldem.material.bilinearLaw(strain, rate, barProps, history, 1e-6);
            [force, after] = ldem.material.BilinearBarLaw().evaluate(strain, rate, barProps, history, params);
            testCase.verifyEqual(force, expectedForce);
            testCase.verifyEqual(after, expectedHistory);
        end

        function bilinearEnergiesOfHandMadeBars(testCase)
            [barProps, history, len] = testCase.threeBars();
            law = ldem.material.BilinearBarLaw();
            E = testCase.E1;

            % Elastic bar: only strain energy.
            e = law.energies([0.5e-3; 0; 0], barProps, history, len);
            testCase.verifyEqual(e.elastic, E * (0.5e-3)^2 * len(1) / 2, 'RelTol', 1e-12);
            testCase.verifyEqual(e.damage, 0);
            testCase.verifyEqual(e.brokenBars, 0);

            % Evaluate the softening and the broken bar, then read the energies.
            params = ldem.Parameters();
            [~, history] = law.evaluate([0.5e-3; 2e-3; 5e-3], zeros(3, 1), barProps, history, params);
            e = law.energies([0.5e-3; 2e-3; 5e-3], barProps, history, len);
            EP = 1e-3;
            EM = 2e-3;
            E2 = history.tensionStiffness(2);
            area = E * EP^2 - E2 * EM^2 + (E * EP + E2 * EM) * (EM - EP);
            damageSoftening = len(2) * area / 2;
            fractureEnergy = E * EP^2 * 5 * len(3) / 2;
            testCase.verifyEqual(law.barDamageEnergy(2, barProps, history, len), damageSoftening, 'RelTol', 1e-12);
            testCase.verifyEqual(law.barDamageEnergy(1, barProps, history, len), 0);
            testCase.verifyEqual(e.brokenBars, fractureEnergy, 'RelTol', 1e-12);
            testCase.verifyGreaterThan(e.damage, damageSoftening);     % the broken bar adds its own
            testCase.verifyEqual(law.viscousStiffness([-1; 1; 1], barProps, history), ...
                [E; E2; history.tensionStiffness(3)]);
        end

        function linearElasticLawHasNoDamage(testCase)
            [barProps, history, len] = testCase.threeBars();
            law = ldem.material.LinearElasticBarLaw();
            params = ldem.Parameters(constitutiveDamping = 2e-6);
            strain = [-1e-3; 2e-3; 9e-3];                   % past the rupture strain of the bilinear law
            rate = [3; -1; 2];
            [force, after] = law.evaluate(strain, rate, barProps, history, params);
            testCase.verifyEqual(force, testCase.E1 * (strain + 2e-6 * rate), 'RelTol', 1e-12);
            testCase.verifyEqual(after, history);
            e = law.energies(strain, barProps, after, len);
            testCase.verifyEqual(e.elastic, sum(testCase.E1 * strain.^2 .* len / 2), 'RelTol', 1e-12);
            testCase.verifyEqual(e.damage, 0);
            testCase.verifyEqual(e.brokenBars, 0);
            testCase.verifyEqual(law.barDamageEnergy(3, barProps, after, len), 0);
            testCase.verifyEqual(law.viscousStiffness(strain, barProps, after), barProps.stiffness);
        end

        function aLawOutsideTheRegistryPlugsIntoTheSolver(testCase)
            [mesh, barProps, history] = testCase.oscillator();
            params = ldem.Parameters(dt = 2e-7);
            state = ldem.solver.initialState(mesh, history);
            state.displacement(2, 1) = testCase.L * (1 + 1e-4);
            state.previousDisplacement = state.displacement;

            elastic = ldem.solver.computeBarForces(state, mesh, barProps, params, ldem.material.LinearElasticBarLaw());
            half = ldem.solver.computeBarForces(state, mesh, barProps, params, TestHalfStiffnessLaw());
            testCase.verifyEqual(half.axialForce, 0.5 * elastic.axialForce, 'RelTol', 1e-12);
            testCase.verifyEqual(half.force, 0.5 * elastic.force, 'RelTol', 1e-12);

            e = ldem.solver.computeEnergies(half, mesh, barProps, params, TestHalfStiffnessLaw());
            testCase.verifyEqual(e.elastic, 0.5 * testCase.E1 * (1e-4)^2 * testCase.L / 2, 'RelTol', 1e-9);
        end

        function dampingModels(testCase)
            p = ldem.Parameters(dt = 5e-7, dampingInitial = 100, dampingFinal = 40, dampingSwitchTime = 2.5e-6);
            mp = ldem.solver.MassProportionalDamping();
            testCase.verifyEqual(mp.coefficient(1, p), ldem.solver.dampingCoefficient(1, p));
            testCase.verifyEqual(mp.coefficient(1, p), 100);
            testCase.verifyEqual(mp.coefficient(10, p), 40);
            none = ldem.solver.NoDamping();
            testCase.verifyEqual(none.coefficient(1, p), 0);
            testCase.verifyEqual(none.coefficient(10, p), 0);
        end

        function noDampingKeepsTheOscillatorUndamped(testCase)
            [mesh, barProps, history] = testCase.oscillator();
            params = ldem.Parameters(dt = 2e-7, dampingModel = "none", dampingInitial = 5000, dampingFinal = 5000);
            law = ldem.material.LinearElasticBarLaw();
            damping = ldem.solver.dampingFromName(params.dampingModel);
            state = ldem.solver.initialState(mesh, history);
            u0 = 1e-6;
            omega = sqrt(testCase.E1 / testCase.L / testCase.Mass);
            state.displacement(2, 1) = testCase.L + u0;
            state.previousDisplacement(2, 1) = testCase.L + u0 * cos(omega * params.dt);
            nSteps = 2000;
            x = zeros(nSteps, 1);
            for n = 1:nSteps
                state.step = n;
                state.time = state.time + params.dt;
                state = ldem.solver.computeBarForces(state, mesh, barProps, params, law);
                state = ldem.solver.integrateStep(state, mesh, barProps, params, law, damping);
                x(n) = state.displacement(2, 1) - testCase.L;
            end
            t = params.dt * (1:nSteps).';
            testCase.verifyEqual(x, u0 * cos(omega * t), 'AbsTol', 2e-3 * u0);
            testCase.verifyEqual(state.dampingEnergy, 0);
        end

        function simulationsWithTheOtherLawAndDamping(testCase)
            damaging = {'testId', 101, 'nModules', [6 3 3], 'totalTime', 2e-4, 'fractureEnergy', 0.1};
            bilinear = ldem.runSimulation(ldem.Parameters(damaging{:}));
            elastic = ldem.runSimulation(ldem.Parameters(damaging{:}, constitutiveLaw = "linear_elastic"));

            testCase.verifyGreaterThan(bilinear.energy.damage(end), 0);
            testCase.verifyEqual(elastic.energy.damage, zeros(size(elastic.energy.damage)));
            testCase.verifyEqual(elastic.energy.brokenBars, zeros(size(elastic.energy.brokenBars)));
            testCase.verifyEqual(elastic.final.damage.isUnbroken, true(size(elastic.final.damage.isUnbroken)));
            % The elastic model keeps the energy balance closed.
            testCase.verifyLessThan(abs(elastic.energy.balance(end)), 0.01 * abs(elastic.energy.external(end)));

            undamped = ldem.runSimulation(ldem.Parameters(damaging{:}, dampingModel = "none"));
            damped = ldem.runSimulation(ldem.Parameters(damaging{:}));
            testCase.verifyEqual(undamped.energy.damping, zeros(size(undamped.energy.damping)));
            testCase.verifyGreaterThan(damped.energy.damping(end), 0);
        end

        function caseFilesChooseTheLawAndTheDamping(testCase)
            c = ldem.io.readCase(testCase.writeCase(strings(0, 1)));
            testCase.verifyEqual(c.params.constitutiveLaw, "bilinear");
            testCase.verifyEqual(c.params.dampingModel, "mass_proportional");

            c = ldem.io.readCase(testCase.writeCase(["[material]"; "law = ""Linear_Elastic"""; ...
                "[damping]"; "type = ""none"""; "constitutive = 1 us"]));
            testCase.verifyEqual(c.params.constitutiveLaw, "linear_elastic");
            testCase.verifyEqual(c.params.dampingModel, "none");
            testCase.verifyEqual(c.params.constitutiveDamping, 1e-6);
        end

        function caseFileErrorsForLawAndDamping(testCase)
            try
                ldem.io.readCase(testCase.writeCase(["[material]"; "law = ""bilinar"""]));
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:case:badValue');
                testCase.verifySubstring(err.message, "Did you mean 'bilinear'?");
                testCase.verifySubstring(err.message, 'linear_elastic');
            end
            try
                ldem.io.readCase(testCase.writeCase(["[damping]"; "type = ""none"""; "initial = 100"]));
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifyEqual(err.identifier, 'ldem:case:inconsistentKey');
                testCase.verifySubstring(err.message, 'type = "none"');
            end
            % The default model accepts all three keys.
            c = ldem.io.readCase(testCase.writeCase(["[damping]"; "initial = 100"; "final = 50"; "switch_time = 10 us"]));
            testCase.verifyEqual(c.params.dampingFinal, 50);
        end

        function writerKeepsTheLawAndTheDamping(testCase)
            p = ldem.Parameters(constitutiveLaw = "linear_elastic", dampingModel = "none", ...
                constitutiveDamping = 3e-6);
            path = fullfile(testCase.Folder, "w.ldem");
            text = ldem.io.writeCase(path, p);
            testCase.verifySubstring(text, '"linear_elastic"');
            testCase.verifyFalse(contains(text, "switch_time"));
            c = ldem.io.readCase(path);
            testCase.verifyEqual(c.params.constitutiveLaw, "linear_elastic");
            testCase.verifyEqual(c.params.dampingModel, "none");
            testCase.verifyEqual(c.params.constitutiveDamping, 3e-6);

            q = ldem.Parameters(dampingInitial = 1200, dampingFinal = 800, dampingSwitchTime = 2e-5);
            ldem.io.writeCase(path, q);
            r = ldem.io.readCase(path);
            testCase.verifyEqual(r.params.toStruct(), q.toStruct());
        end
    end
end
