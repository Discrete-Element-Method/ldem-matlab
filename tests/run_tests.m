function results = run_tests()
%RUN_TESTS  Executa a suite de testes matlab.unittest.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src', 'ldem'));
suite = matlab.unittest.TestSuite.fromFolder(fileparts(mfilename('fullpath')));
results = run(suite);
disp(table(results));
assertSuccess(results);
end
