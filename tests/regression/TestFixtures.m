classdef TestFixtures < matlab.unittest.TestCase
    %TESTFIXTURES  Fast sanity checks of the golden-master fixtures.
    %
    %   Verifies that the fixtures exist, are consistent with their case
    %   definitions and exercise the interesting branches (damage), so they
    %   are useful as references. Does not run any simulation.
    %
    %   See also TestLegacyReproducibility, generateReference.

    properties (TestParameter)
        caseName = {'tension101_elastic', 'tension101_damage', 'bending102'}
    end

    properties
        FixtureDir
    end

    methods (TestClassSetup)
        function addTools(testCase)
            testsDir = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsDir, 'tools')));
            testCase.FixtureDir = fullfile(testsDir, 'fixtures');
        end
    end

    methods (Test, TestTags = {'Regression'})
        function caseListIsCurrent(testCase)
            % Keeps the hardcoded lists of the regression tests in sync.
            expected = sort(string({referenceCases().name}));
            listed = sort(string(TestFixtures.caseName_));
            testCase.verifyEqual(listed, expected, ...
                'Update the caseName lists in the regression tests.');
        end

        function fixtureIsConsistent(testCase, caseName)
            fixture = load(fullfile(testCase.FixtureDir, caseName + ".mat"));
            c = fixture.caseDef;
            s = fixture.state;

            testCase.verifyEqual(c.name, char(caseName));
            testCase.verifyEqual(s.M, c.modules(1));
            testCase.verifyEqual(double(s.NSTEP), c.nSteps);
            testCase.verifyEqual(size(s.U, 2), s.NNT, 'Node arrays must be trimmed.');
            testCase.verifyEqual(numel(s.CN), 2 * s.NBT, 'CN must be trimmed.');
            testCase.verifyTrue(all(isfinite(s.U), 'all'));
        end

        function fixturesIncludeTheTimeIntegration(testCase, caseName)
            % The legacy driver once skipped the integration (nodes stayed
            % at rest). Free nodes must have moved in every reference case.
            fixture = load(fullfile(testCase.FixtureDir, caseName + ".mat"));
            s = fixture.state;
            speed = max(abs([s.VLX(:); s.VLY(:); s.VLZ(:)]));
            testCase.verifyGreaterThan(speed, 0, ...
                'Velocities are zero: the equations of motion were not integrated.');
        end

        function damageCaseActuallyDamages(testCase)
            elastic = load(fullfile(testCase.FixtureDir, 'tension101_elastic.mat'));
            damaged = load(fullfile(testCase.FixtureDir, 'tension101_damage.mat'));
            testCase.verifyEqual(nnz(~elastic.state.DM), 0);
            testCase.verifyGreaterThan(nnz(~damaged.state.DM), 0, 'No bar softened.');
            testCase.verifyGreaterThan(nnz(~damaged.state.FS), 0, 'No bar broke.');
        end
    end

    methods (Static, Access = private)
        function names = caseName_()
            names = {'tension101_elastic', 'tension101_damage', 'bending102'};
        end
    end
end
