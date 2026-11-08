classdef TestKeyReference < LdemTestCase
    %TESTKEYREFERENCE  The key reference of the user guide is generated from the schema.

    methods (Test, TestTags = {'Unit'})
        function theGuideAgreesWithTheSchema(testCase)
            file = fullfile(testCase.RepoRoot, "docs", "source", "case-keys.inc");
            testCase.assertTrue(isfile(file), ...
                'docs/source/case-keys.inc is missing: run ldem.schema.writeKeyReference("docs/source/case-keys.inc").');
            written = strrep(string(fileread(file)), char(13), "");
            generated = ldem.schema.writeKeyReference();
            testCase.verifyTrue(isequal(written, generated), ...
                ['docs/source/case-keys.inc is out of date with ldem.schema.caseSchema: from the repository ' ...
                 'root run  ldem.schema.writeKeyReference("docs/source/case-keys.inc")  and commit it.']);
        end

        function everyKeyOfTheSchemaIsListed(testCase)
            text = ldem.schema.writeKeyReference();
            schema = ldem.schema.caseSchema();
            for row = schema.'
                key = string(regexprep(row.path, '^.*\.', ''));
                testCase.verifySubstring(text, "``" + key + "``", row.path);
            end
        end

        function theTextHasTheExpectedShape(testCase)
            text = ldem.schema.writeKeyReference();
            testCase.verifySubstring(text, ".. rubric:: ``[mesh]``");
            testCase.verifySubstring(text, ".. rubric:: ``[[support]]``");
            testCase.verifySubstring(text, "number + unit (m, cm, mm, um, km)");
            testCase.verifySubstring(text, "3 mm");                      % default of module_size
            testCase.verifySubstring(text, "required");
            testCase.verifyTrue(endsWith(text, newline));
        end

        function writesTheFile(testCase)
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, "keys.inc");
            text = ldem.schema.writeKeyReference(path);
            testCase.verifyEqual(strrep(string(fileread(path)), char(13), ""), text);
        end
    end
end
