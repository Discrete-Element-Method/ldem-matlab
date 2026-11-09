classdef TestAnsysAgainstLegacy < LdemTestCase
    %TESTANSYSAGAINSTLEGACY  The new ANSYS files equal the ones of the legacy code.
    %
    %   Runs ldem.runSimulation on the reference cases, writing ANSYS files at
    %   the same steps as the legacy run, and compares them line by line with
    %   the files stored in the golden-master fixtures (time zero and the
    %   later snapshots).
    %
    %   Intentional differences, removed before comparing (see
    %   ldem.io.exportAnsys):
    %     * the legacy line "ET,IFILE,4" is an invalid command and the new
    %       file writes "ET,3,4";
    %     * for TEST 101 the legacy file has no constraint lines ("D,..."),
    %       the new one lists the fixed degrees of freedom;
    %     * the new applied-loads section lists the imposed displacements
    %       ("D,node,direction,value"), the legacy one is empty.
    %
    %   See also TestSolverAgainstLegacy, ldem.io.exportAnsys.

    properties (TestParameter)
        caseName = {'tension101_elastic', 'tension101_damage', 'bending102'}
    end

    methods (Test, TestTags = {'Regression'})
        function ansysFilesMatchLegacy(testCase, caseName)
            fixture = load(fullfile(testCase.RepoRoot, 'tests', 'fixtures', caseName + ".mat"));
            c = fixture.caseDef;
            folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);

            params = testCase.parametersOf(c);
            ldem.runSimulation(params, OutputFolder=folder, Formats="ansys");

            nFiles = floor(c.nSteps / c.ansysEvery) + 1;
            for k = 0:nFiles - 1
                legacyName = sprintf('ANSYS%02d_MAC', k);
                testCase.assertTrue(isfield(fixture.files, legacyName), "Fixture lacks " + legacyName);
                legacyText = testCase.normalize(fixture.files.(legacyName), c.test);
                newText = testCase.normalize( ...
                    fileread(fullfile(folder, sprintf('snapshot_%04d.mac', k))), c.test);
                testCase.verifyEqual(newText, legacyText, ...
                    sprintf('Snapshot %d of %s differs from the legacy ANSYS file.', k, caseName));
            end
        end
    end

    methods (Access = private)
        function lines = normalize(~, text, testId)
            lines = splitlines(string(text));
            lines = strip(lines, 'right', char(13));
            lines(lines == "ET,IFILE,4") = "ET,3,4";
            if testId == 101
                lines(startsWith(lines, "D,")) = [];
            end
            % The new applied-loads section lists the imposed displacements
            % ("D,node,dir,value"); the legacy section is empty.
            lines(startsWith(lines, "D,") & count(lines, ",") == 3) = [];
            lines(startsWith(lines, "!CARGAS APLICADAS")) = "!CARGAS APLICADAS";
            % Trailing empty lines are not significant.
            while ~isempty(lines) && lines(end) == ""
                lines(end) = [];
            end
        end

        function params = parametersOf(testCase, c)
            fieldFile = fullfile(testCase.RepoRoot, 'examples', 'beam_102', 'arquivo_3lc_rnao_cv05');
            params = ldem.Parameters( ...
                testId = c.test, seed = c.seed, moduleLength = c.moduleLength, ...
                nModules = c.modules, dampingInitial = c.damping1, dampingFinal = c.damping2, ...
                dampingSwitchTime = c.dampingSwitchTime, constitutiveDamping = c.con, ...
                dt = c.dt, totalTime = c.nSteps * c.dt, controlNodes = c.controlNodes, ...
                youngModulus = c.youngModulus, density = c.density, poissonRatio = c.poisson, ...
                fractureEnergy = c.fractureEnergy, criticalDistance = c.criticalDistance, ...
                randomFieldFile = fieldFile, ...
                output = struct('snapshotEvery', c.ansysEvery, 'controlNodesEvery', 0, ...
                    'energyEvery', 0, 'trackedBarEvery', 0));
        end
    end
end
