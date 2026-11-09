classdef TestMaterialAgainstLegacy < LdemTestCase
    %TESTMATERIALAGAINSTLEGACY  The new bar properties equal the legacy ones.
    %
    %   Compares ldem.material.buildBarProperties with the stiffness,
    %   critical strain, rupture ratio and statistics stored in the
    %   golden-master fixtures. The legacy random field file is used, so
    %   the comparison also covers the scatter of the critical strain.
    %
    %   For the elastic case no bar ever softens, so the damage state at the
    %   end of the legacy run is still the initial one and it is compared
    %   too.
    %
    %   See also TestMeshAgainstLegacy.

    properties (TestParameter)
        caseName = {'tension101_elastic', 'tension101_damage', 'bending102'}
    end

    methods (Test, TestTags = {'Regression'})
        function barPropertiesMatchLegacy(testCase, caseName)
            [fixture, params] = testCase.loadCase(caseName);
            s = fixture.state;
            mesh = ldem.mesh.buildMesh(params);

            [props, ~] = ldem.material.buildBarProperties(mesh, params);

            tight = {'RelTol', 1e-14, 'AbsTol', 1e-30};
            testCase.verifyEqual(props.stiffness,      s.E1(:), tight{:});
            testCase.verifyEqual(props.criticalStrain, s.EP(:), tight{:});
            testCase.verifyEqual(props.ruptureRatio,   s.KR(:), tight{:});
            testCase.verifyEqual(props.criticalStrainMean, s.MEAN, tight{:});
        end

        function initialStateMatchesLegacyWhenNothingDamaged(testCase)
            [fixture, params] = testCase.loadCase('tension101_elastic');
            s = fixture.state;
            mesh = ldem.mesh.buildMesh(params);
            [~, history] = ldem.material.buildBarProperties(mesh, params);

            tight = {'RelTol', 1e-14, 'AbsTol', 1e-30};
            testCase.verifyEqual(history.tensionStiffness, s.E2(:), tight{:});
            testCase.verifyEqual(history.maxStrain, s.EM(:), tight{:});
            testCase.verifyEqual(history.isUndamaged, logical(s.DM(:)));
            testCase.verifyEqual(history.isUnbroken, logical(s.FS(:)));
        end
    end

    methods (Access = private)
        function [fixture, params] = loadCase(testCase, caseName)
            fixture = load(fullfile(testCase.RepoRoot, 'tests', 'fixtures', caseName + ".mat"));
            c = fixture.caseDef;
            fieldFile = fullfile(testCase.RepoRoot, 'examples', 'beam_102', 'arquivo_3lc_rnao_cv05');
            params = ldem.Parameters( ...
                testId = c.test, ...
                seed = c.seed, ...
                moduleLength = c.moduleLength, ...
                nModules = c.modules, ...
                dampingInitial = c.damping1, ...
                dampingFinal = c.damping2, ...
                dampingSwitchTime = c.dampingSwitchTime, ...
                constitutiveDamping = c.con, ...
                dt = c.dt, ...
                totalTime = c.nSteps * c.dt, ...
                controlNodes = c.controlNodes, ...
                youngModulus = c.youngModulus, ...
                density = c.density, ...
                poissonRatio = c.poisson, ...
                fractureEnergy = c.fractureEnergy, ...
                criticalDistance = c.criticalDistance, ...
                randomFieldFile = fieldFile);
        end
    end
end
