classdef TestParseCase < LdemTestCase
    %TESTPARSECASE  Unit tests of the syntax of the case files (.ldem and .json).

    methods (Access = private)
        function e = parse(~, varargin)
            e = ldem.io.parseCaseText(strjoin(string(varargin), newline), "t.ldem");
        end
    end

    methods (Test, TestTags = {'Unit'})
        function readsSectionsKeysAndValueTypes(testCase)
            e = testCase.parse( ...
                'title = "A # not a comment"   # but this is', ...
                '[mesh]', ...
                'modules = [5, 5, 50]', ...
                'module_size = 1 mm', ...
                'perturbation = 0.02', ...
                'seed = 123', ...
                '[output]', ...
                'mat = true', ...
                'vtk = false', ...
                'formats = ["mat", "vtk"]');
            testCase.verifyEqual([e.section], ["" "mesh" "mesh" "mesh" "mesh" "output" "output" "output"]);
            testCase.verifyEqual(e(1).value, "A # not a comment");
            testCase.verifyEqual(e(2).value, [5 5 50]);
            testCase.verifyEqual(e(3).value, "1 mm");
            testCase.verifyEqual(e(4).value, 0.02);
            testCase.verifyEqual(e(5).value, 123);
            testCase.verifyTrue(e(6).value);
            testCase.verifyFalse(e(7).value);
            testCase.verifyEqual(e(8).value, ["mat" "vtk"]);
            testCase.verifyEqual([e.line], [1 3 4 5 6 8 9 10]);
        end

        function ignoresBlankLinesCommentsAndWindowsLineEnds(testCase)
            text = "# header" + string(char([13 10])) + string(char([13 10])) + ...
                "[time]   # section" + string(char([13 10])) + "duration = 2.8 ms" + string(char([13 10]));
            e = ldem.io.parseCaseText(text, "t.ldem");
            testCase.verifySize(e, [1 1]);
            testCase.verifyEqual(e.value, "2.8 ms");
        end

        function repeatedTablesGetAnIndex(testCase)
            e = testCase.parse('[[monitor.node]]', 'id = 2', '[[monitor.node]]', 'id = 5', 'name = "x"');
            testCase.verifyEqual([e.index], [1 2 2]);
            testCase.verifyEqual([e.section], repmat("monitor.node", 1, 3));
        end

        function skipsAUtf8ByteOrderMark(testCase)
            text = string(char([239 187 191])) + "format = 1";
            e = ldem.io.parseCaseText(text, "t.ldem");
            testCase.verifyEqual(e.key, "format");
        end

        function emptyAndTrailingCommaLists(testCase)
            e = testCase.parse('a = []', 'b = [1, 2,]');
            testCase.verifyEmpty(e(1).value);
            testCase.verifyEqual(e(2).value, [1 2]);
        end

        function reportsSyntaxErrorsWithTheLine(testCase)
            bad = { ...
                "[mesh", ...
                "[[mesh]", ...
                "novalue", ...
                "key = ", ...
                "1key = 3", ...
                "k = ""open", ...
                "k = ""a"" b", ...
                "k = [1, 2", ...
                "k = [1, ""a""]", ...
                "k = [1, x]", ...
                "[a b]"};
            for k = 1:numel(bad)
                try
                    ldem.io.parseCaseText("# first" + newline + bad{k}, "t.ldem");
                    testCase.verifyFail("No error for: " + bad{k});
                catch err
                    testCase.verifyEqual(err.identifier, 'ldem:case:syntax', bad{k});
                    testCase.verifySubstring(err.message, "t.ldem:2");
                end
            end
        end

        function rejectsRepeatedKeysAndSections(testCase)
            testCase.verifyError(@() testCase.parse('[a]', 'x = 1', 'x = 2'), 'ldem:case:syntax');
            testCase.verifyError(@() testCase.parse('[a]', '[a]'), 'ldem:case:syntax');
        end

        function jsonGivesTheSameEntries(testCase)
            json = '{"format": 1, "mesh": {"module_size": "1 mm", "modules": [5, 5, 50]}, "output": {"mat": true}, "monitor": {"node": [{"id": 2441}, {"id": 884, "name": "b"}]}}';
            e = ldem.io.parseCaseJson(json, "t.json");
            keys = [e.section] + "." + [e.key];
            testCase.verifyEqual(keys, [".format" "mesh.module_size" "mesh.modules" "output.mat" ...
                "monitor.node.id" "monitor.node.id" "monitor.node.name"]);
            testCase.verifyEqual([e.index], [0 0 0 0 1 2 2]);
            testCase.verifyEqual(e(3).value, [5 5 50]);
            testCase.verifyEqual(e(2).value, "1 mm");
        end

        function jsonErrorsAreSyntaxErrors(testCase)
            testCase.verifyError(@() ldem.io.parseCaseJson('{"a": ', "t.json"), 'ldem:case:syntax');
            testCase.verifyError(@() ldem.io.parseCaseJson('[1, 2]', "t.json"), 'ldem:case:syntax');
        end
    end
end
