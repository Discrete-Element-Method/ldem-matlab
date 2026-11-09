classdef TestReadInputFile < LdemTestCase
    %TESTREADINPUTFILE  Unit tests of ldem.io.readInputFile and Parameters.fromFile.

    methods (Access = private)
        function path = writeFile(testCase, lines)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, 'DATA.DAT');
            fid = fopen(path, 'w');
            fprintf(fid, '%s\n', lines{:});
            fclose(fid);
        end

        function lines = validLines(~)
            % Same layout as DATA0.DAT, with two control nodes.
            lines = {"101 ' TEST '", "123 ' SEED '", "0.003 ' LCO '", ...
                "6 ' M '", "3 ' N '", "3 ' L '", ...
                "25000.00E+0 ' DF1 '", "30000 ' DF2 '", "0.015 ' TDAF '", ...
                "0.00E-00 ' CON '", "2.00E-7 ' DT '", "4.0E-5 ' TTOT '", ...
                "2 ' INCO '", "1 ' N1 '", "2 ' N2 '", ...
                "9999999 ' OU2 '", "100 ' OU3 '", "0 ' OU4 '", "0 ' OU5 '", ...
                "10 ' OU6 '", "10 ' OU7 '", "20 ' OU8 '", "5 ' OU9 '", ...
                "2.50E-01 ' PSN '", "2000.0E+0 ' ROH '", "32.00E+9 ' YNG '", ...
                "50.0E+00 ' GFR '", "0.028 ' DEQ '"};
        end
    end

    methods (Test, TestTags = {'Unit'})
        function readsEveryValue(testCase)
            v = ldem.io.readInputFile(testCase.writeFile(testCase.validLines()));

            testCase.verifyEqual(v.testId, 101);
            testCase.verifyEqual(v.seed, 123);
            testCase.verifyEqual(v.moduleLength, 0.003);
            testCase.verifyEqual(v.nModules, [6 3 3]);
            testCase.verifyEqual(v.dampingInitial, 25000);
            testCase.verifyEqual(v.dampingFinal, 30000);
            testCase.verifyEqual(v.dampingSwitchTime, 0.015);
            testCase.verifyEqual(v.constitutiveDamping, 0);
            testCase.verifyEqual(v.dt, 2e-7);
            testCase.verifyEqual(v.totalTime, 4e-5);
            testCase.verifyEqual(v.controlNodes, [1 2]);
            testCase.verifyEqual(v.poissonRatio, 0.25);
            testCase.verifyEqual(v.density, 2000);
            testCase.verifyEqual(v.youngModulus, 32e9);
            testCase.verifyEqual(v.fractureEnergy, 50);
            testCase.verifyEqual(v.criticalDistance, 0.028);
        end

        function mapsOutputCodes(testCase)
            v = ldem.io.readInputFile(testCase.writeFile(testCase.validLines()));
            testCase.verifyEqual(v.output.snapshotEvery, 100);      % OU3
            testCase.verifyEqual(v.output.controlNodesEvery, 10);   % OU6
            testCase.verifyEqual(v.output.energyEvery, 20);         % OU8
            testCase.verifyEqual(v.output.trackedBarEvery, 1);      % OU9 > 0
        end

        function ignoresBlankLinesAndTrailingText(testCase)
            lines = testCase.validLines();
            lines = [lines(1:5), {""}, lines(6:end), {"", "   "}];
            v = ldem.io.readInputFile(testCase.writeFile(lines));
            testCase.verifyEqual(v.nModules, [6 3 3]);
        end

        function readsTheBundledBeamExample(testCase)
            path = fullfile(testCase.RepoRoot, 'examples', 'beam_102', 'DATA0.DAT');
            v = ldem.io.readInputFile(path);
            testCase.verifyEqual(v.testId, 102);
            testCase.verifyEqual(v.nModules, [101 41 21]);
            testCase.verifyEqual(v.controlNodes, 1:5);
            testCase.verifyEqual(v.output.snapshotEvery, 10000);
        end

        function fromFileReturnsValidatedParameters(testCase)
            path = fullfile(testCase.RepoRoot, 'examples', 'beam_102', 'DATA0.DAT');
            p = ldem.Parameters.fromFile(path, trackedBar=42);
            testCase.verifyClass(p, 'ldem.Parameters');
            testCase.verifyEqual(p.trackedBar, 42);
            testCase.verifyEqual(p.nNodes, 101*41*21 + 100*40*20);
        end

        function missingFile(testCase)
            testCase.verifyError(@() ldem.io.readInputFile("does_not_exist.dat"), ...
                'ldem:io:fileNotFound');
        end

        function tooFewValues(testCase)
            lines = testCase.validLines();
            path = testCase.writeFile(lines(1:8));
            testCase.verifyError(@() ldem.io.readInputFile(path), 'ldem:io:malformedInput');
        end

        function controlNodeCountDoesNotMatch(testCase)
            % INCO says 3 but only 2 control nodes are listed.
            lines = testCase.validLines();
            lines{13} = "3 ' INCO '";
            path = testCase.writeFile(lines);
            testCase.verifyError(@() ldem.io.readInputFile(path), 'ldem:io:malformedInput');
        end

        function nonNumericValue(testCase)
            lines = testCase.validLines();
            lines{3} = "abc ' LCO '";
            path = testCase.writeFile(lines);
            testCase.verifyError(@() ldem.io.readInputFile(path), 'ldem:io:malformedInput');
        end

        function invalidControlNodeCount(testCase)
            lines = testCase.validLines();
            lines{13} = "0 ' INCO '";
            path = testCase.writeFile(lines);
            testCase.verifyError(@() ldem.io.readInputFile(path), 'ldem:io:malformedInput');
        end
    end
end
