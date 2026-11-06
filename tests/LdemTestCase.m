classdef (Abstract) LdemTestCase < matlab.unittest.TestCase
    %LDEMTESTCASE  Base class of the tests of the refactored ldem package.
    %
    %   Adds src/ (the ldem package) to the MATLAB path for the duration of
    %   the test class and exposes the repository folders. Derive a test
    %   from it with:
    %
    %       classdef TestSomething < LdemTestCase
    %
    %   The tests/ folder must be on the path (run_tests does it).

    properties (Access = protected)
        % Absolute path of the repository root.
        RepoRoot (1,1) string
    end

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            here = fileparts(mfilename('fullpath'));
            testCase.RepoRoot = string(fileparts(here));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RepoRoot, 'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RepoRoot, 'tests', 'tools')));
        end
    end
end
