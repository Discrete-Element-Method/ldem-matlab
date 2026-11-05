classdef TestReadRandomField < LdemTestCase
    %TESTREADRANDOMFIELD  Unit tests of ldem.io.readRandomField.

    methods (Access = private)
        function path = writeText(testCase, text)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, 'field.txt');
            fid = fopen(path, 'w');
            fprintf(fid, '%s', text);
            fclose(fid);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function readsTheRequestedNumberOfValues(testCase)
            path = testCase.writeText(sprintf('0.5\n1.0\n1.5\n2.0\n'));
            field = ldem.io.readRandomField(path, 3);
            testCase.verifyEqual(field, [0.5; 1.0; 1.5]);
        end

        function acceptsValuesSeparatedByBlanks(testCase)
            path = testCase.writeText('0.9 1.1   1.0');
            testCase.verifyEqual(ldem.io.readRandomField(path, 3), [0.9; 1.1; 1.0]);
        end

        function missingFile(testCase)
            testCase.verifyError(@() ldem.io.readRandomField("nope.txt", 3), ...
                'ldem:io:fileNotFound');
        end

        function fileWithTooFewValues(testCase)
            path = testCase.writeText(sprintf('1\n1\n'));
            testCase.verifyError(@() ldem.io.readRandomField(path, 5), ...
                'ldem:io:randomFieldTooShort');
        end

        function nonPositiveValue(testCase)
            path = testCase.writeText(sprintf('1\n0\n1\n'));
            testCase.verifyError(@() ldem.io.readRandomField(path, 3), ...
                'ldem:io:randomFieldInvalid');
        end

        function readsTheBundledExample(testCase)
            path = fullfile(testCase.RepoRoot, 'examples', 'beam_102', 'arquivo_3lc_rnao_cv05');
            field = ldem.io.readRandomField(path, 1000);
            testCase.verifySize(field, [1000 1]);
            testCase.verifyGreaterThan(min(field), 0);
        end
    end
end
