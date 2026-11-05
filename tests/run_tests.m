function results = run_tests(options)
%RUN_TESTS  Run the matlab.unittest suite of the repository.
%
%   results = run_tests() runs every test in tests/ and its subfolders,
%   except those tagged "Slow", and throws an error if any test fails.
%
%   results = run_tests(IncludeSlow=true) also runs the slow tests (for
%   example the ones that execute the legacy simulations, ~1 minute).
%
%   Outputs:
%     results  matlab.unittest.TestResult array.
%
%   Example:
%       >> addpath tests
%       >> run_tests
%       >> run_tests(IncludeSlow=true)
%
%   See also matlab.unittest.TestSuite, generateReference.

arguments
    options.IncludeSlow (1,1) logical = false
end

testsFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(testsFolder), 'legacy'));

suite = matlab.unittest.TestSuite.fromFolder(testsFolder, ...
    'IncludingSubfolders', true);
if ~options.IncludeSlow
    suite = suite.selectIf(~matlab.unittest.selectors.HasTag('Slow'));
end

results = run(suite);
disp(table(results));
assertSuccess(results);
end
