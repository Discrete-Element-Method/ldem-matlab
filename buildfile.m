function plan = buildfile
%BUILDFILE  Build plan of the repository, run with MATLAB's buildtool.
%
%   From the repository root:
%
%       >> buildtool                 % default: check + test
%       >> buildtool check           % static analysis (Code Analyzer)
%       >> buildtool test            % fast tests, with coverage and JUnit report
%       >> buildtool testAll         % also the slow tests (full beam model)
%       >> buildtool docs            % Sphinx documentation (needs Python)
%       >> buildtool clean           % remove generated files
%       >> buildtool -tasks          % list the tasks
%
%   Tasks
%     check    Fails if the Code Analyzer reports any warning or error in
%              src/, tests/ or examples/.
%     test     Runs every test not tagged "Slow", writes
%              test-results/results.xml (JUnit) and code-coverage/coverage.xml
%              (Cobertura) and prints the coverage of the ldem package.
%     testAll  Same as test but including the slow tests (they build the
%              complete beam model of the example, about 167,000 nodes).
%     docs     Builds the HTML documentation, in every language, in docs/build/html.
%     clean    Deletes test-results/, code-coverage/ and docs/build/.
%
%   See also run_tests, buildplan.

import matlab.buildtool.tasks.CodeIssuesTask

plan = buildplan(localfunctions);

plan("check") = CodeIssuesTask(["src", "tests", "examples"], ...
    IncludeSubfolders = true, ...
    ErrorThreshold = 0, ...
    WarningThreshold = 0, ...
    Results = "code-issues/results.sarif");

plan("test").Dependencies = "check";
plan("testAll").Dependencies = "check";

plan.DefaultTasks = ["check", "test"];
end

function testTask(context)
% Fast tests, coverage and JUnit report.
runTests(context, false);
end

function testAllTask(context)
% All tests, including the slow ones.
runTests(context, true);
end

function docsTask(context)
% Build the Sphinx documentation.
root = context.Plan.RootFolder;
script = fullfile(root, 'docs', 'tools', 'build_docs.py');
target = fullfile(root, 'docs', 'build', 'html');
command = sprintf('python "%s"', script);
[status, output] = system(command);
if status ~= 0
    error('build:docs', ['Sphinx failed (is Python with docs/requirements.txt installed?):' newline '%s'], output);
end
fprintf('Documentation written to %s\n', target);
end

function cleanTask(context)
% Remove the generated files.
root = context.Plan.RootFolder;
for folder = {'test-results', 'code-coverage', 'code-issues', fullfile('docs', 'build')}
    target = fullfile(root, folder{1});
    if isfolder(target)
        rmdir(target, 's');
        fprintf('Deleted %s\n', target);
    end
end
end

function runTests(context, includeSlow)
%RUNTESTS  Run the test suite with a JUnit report and code coverage.
import matlab.unittest.TestRunner
import matlab.unittest.TestSuite
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.selectors.HasTag

root = context.Plan.RootFolder;

% Source code and tests on the path for this run.
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'src'), fullfile(root, 'tests'));

resultsFolder = fullfile(root, 'test-results');
coverageFolder = fullfile(root, 'code-coverage');
for folder = {resultsFolder, coverageFolder}
    if ~isfolder(folder{1})
        mkdir(folder{1});
    end
end

suite = TestSuite.fromFolder(fullfile(root, 'tests'), 'IncludingSubfolders', true);
if ~includeSlow
    suite = suite.selectIf(~HasTag('Slow'));
end

runner = TestRunner.withTextOutput;
runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(resultsFolder, 'results.xml')));
runner.addPlugin(CodeCoveragePlugin.forPackage('ldem', 'IncludingSubpackages', true, ...
    'Producing', CoberturaFormat(fullfile(coverageFolder, 'coverage.xml'))));

results = runner.run(suite);

fprintf('\n%d tests: %d passed, %d failed, %d incomplete.\n', ...
    numel(results), nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]));
assertSuccess(results);
end
