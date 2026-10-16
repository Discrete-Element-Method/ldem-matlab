classdef TestLdemPath < matlab.unittest.TestCase
    %TESTLDEMPATH  Verifica que as rotinas principais estão no path e documentadas.
    properties (TestParameter)
        routine = {'ini_DEM3','CALOAD','CALRES','BOUND','CONECTI', ...
                   'INTCO1','RMEC','ENERG2','read_dat0','prepvar'}
    end
    methods (TestClassSetup)
        function addSource(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, 'src', 'ldem')));
        end
    end
    methods (Test)
        function routineExists(testCase, routine)
            testCase.verifyEqual(exist(routine, 'file'), 2);
        end
        function routineHasHelp(testCase, routine)
            testCase.verifyNotEmpty(help(routine));
        end
    end
end
