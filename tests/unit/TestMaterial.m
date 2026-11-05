classdef TestMaterial < LdemTestCase
    %TESTMATERIAL  Unit tests of the stiffness and bar-property computation.

    methods (Access = private)
        function path = writeNumbers(testCase, values)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, 'field.txt');
            fid = fopen(path, 'w');
            fprintf(fid, '%.10g\n', values);
            fclose(fid);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function latticeCoefficientsForKnownPoissonRatios(testCase)
            [delta, alpha] = ldem.material.latticeCoefficients(0.25);
            testCase.verifyEqual(delta, 1.125, 'RelTol', 1e-14);
            testCase.verifyEqual(alpha, 0.4, 'RelTol', 1e-14);

            [delta, alpha] = ldem.material.latticeCoefficients(0);
            testCase.verifyEqual(delta, 0);
            testCase.verifyEqual(alpha, 0.5, 'RelTol', 1e-14);
        end

        function latticeCoefficientsRejectIncompressibleLimit(testCase)
            testCase.verifyError(@() ldem.material.latticeCoefficients(0.5), ...
                'ldem:params:badPoissonRatio');
        end

        function stiffnessDependsOnTheTypeOfBar(testCase)
            params = ldem.Parameters(nModules=[4 4 4]);
            mesh = ldem.mesh.buildMesh(params);
            E1 = ldem.material.computeBarStiffness(mesh, params);

            [delta, alpha] = ldem.material.latticeCoefficients(params.poissonRatio);
            reference = alpha * params.youngModulus * mesh.barLength.^2;
            diagonalFactor = 2 * delta * (4/3) / sqrt(3);

            isGrid = mesh.barType == 1;
            testCase.verifyEqual(E1(isGrid & mesh.barBoundaryFaces == 0), ...
                reference(isGrid & mesh.barBoundaryFaces == 0), 'RelTol', 1e-14);
            testCase.verifyEqual(E1(isGrid & mesh.barBoundaryFaces == 1), ...
                reference(isGrid & mesh.barBoundaryFaces == 1) / 2, 'RelTol', 1e-14);
            testCase.verifyEqual(E1(isGrid & mesh.barBoundaryFaces == 2), ...
                reference(isGrid & mesh.barBoundaryFaces == 2) / 4, 'RelTol', 1e-14);
            testCase.verifyEqual(E1(mesh.barType == 2), reference(mesh.barType == 2), 'RelTol', 1e-14);
            testCase.verifyEqual(E1(mesh.barType == 3), ...
                reference(mesh.barType == 3) * diagonalFactor, 'RelTol', 1e-14);
        end

        function stiffnessIsPositiveAndScalesWithYoungModulus(testCase)
            p1 = ldem.Parameters(nModules=[3 3 3], youngModulus=30e9);
            p2 = ldem.Parameters(nModules=[3 3 3], youngModulus=60e9);
            mesh = ldem.mesh.buildMesh(p1);
            e1 = ldem.material.computeBarStiffness(mesh, p1);
            e2 = ldem.material.computeBarStiffness(mesh, p2);
            testCase.verifyGreaterThan(min(e1), 0);
            testCase.verifyEqual(e2, 2 * e1, 'RelTol', 1e-14);
        end

        function barPropertiesWithoutRandomField(testCase)
            params = ldem.Parameters(nModules=[3 3 3]);
            mesh = ldem.mesh.buildMesh(params);
            [props, history] = ldem.material.buildBarProperties(mesh, params);

            nBars = size(mesh.bars, 1);
            expectedEP = sqrt(params.fractureEnergy / (params.youngModulus * params.criticalDistance));
            testCase.verifyEqual(props.criticalStrain, repmat(expectedEP, nBars, 1), 'RelTol', 1e-14);

            [~, alpha] = ldem.material.latticeCoefficients(params.poissonRatio);
            criticalLength = params.criticalDistance * 2 * params.failureAreaFactor / alpha;
            testCase.verifyEqual(props.ruptureRatio, criticalLength ./ mesh.barLength, 'RelTol', 1e-14);
            testCase.verifyEqual(props.ruptureStrain, props.ruptureRatio .* props.criticalStrain);
            testCase.verifyEqual(props.criticalStrainCv, 0, 'AbsTol', 1e-12);

            testCase.verifyEqual(history.tensionStiffness, props.stiffness);
            testCase.verifyEqual(history.maxStrain, props.criticalStrain);
            testCase.verifyTrue(all(history.isUndamaged));
            testCase.verifyTrue(all(history.isUnbroken));
        end

        function randomFieldScalesTheCriticalStrain(testCase)
            params = ldem.Parameters(nModules=[3 3 3]);
            mesh = ldem.mesh.buildMesh(params);
            nBars = size(mesh.bars, 1);
            field = linspace(0.8, 1.2, nBars).';

            [base, ~] = ldem.material.buildBarProperties(mesh, params);
            [props, history] = ldem.material.buildBarProperties(mesh, params, RandomField=field);

            testCase.verifyEqual(props.criticalStrain, field .* base.criticalStrain, 'RelTol', 1e-14);
            testCase.verifyEqual(history.maxStrain, props.criticalStrain);
            testCase.verifyEqual(props.criticalStrainMean, mean(props.criticalStrain));
            testCase.verifyEqual(props.criticalStrainCv, ...
                std(props.criticalStrain) / mean(props.criticalStrain), 'RelTol', 1e-14);
            testCase.verifyGreaterThan(props.criticalStrainCv, 0);
        end

        function randomFieldIsReadFromTheParametersFile(testCase)
            probe = ldem.Parameters(nModules=[3 3 3]);
            nBars = size(ldem.mesh.buildBars(probe.nModules), 1);
            field = 1 + 0.1 * sin((1:nBars).');
            path = testCase.writeNumbers(field);

            params = ldem.Parameters(nModules=[3 3 3], randomFieldFile=path);
            mesh = ldem.mesh.buildMesh(params);
            [props, ~] = ldem.material.buildBarProperties(mesh, params);
            [base, ~] = ldem.material.buildBarProperties(mesh, probe);
            testCase.verifyEqual(props.criticalStrain, field .* base.criticalStrain, 'RelTol', 1e-9);
        end

        function randomFieldOfWrongSizeIsRejected(testCase)
            params = ldem.Parameters(nModules=[3 3 3]);
            mesh = ldem.mesh.buildMesh(params);
            testCase.verifyError( ...
                @() ldem.material.buildBarProperties(mesh, params, RandomField=ones(5, 1)), ...
                'ldem:material:randomFieldSize');
        end

        function tooShortCriticalLengthIsRejected(testCase)
            params = ldem.Parameters(nModules=[3 3 3], criticalDistance=0.001);
            mesh = ldem.mesh.buildMesh(params);
            testCase.verifyError(@() ldem.material.buildBarProperties(mesh, params), ...
                'ldem:material:criticalLengthTooShort');
        end

        function longerFractureEnergyDelaysDamage(testCase)
            lowG  = ldem.Parameters(nModules=[3 3 3], fractureEnergy=10);
            highG = ldem.Parameters(nModules=[3 3 3], fractureEnergy=40);
            mesh = ldem.mesh.buildMesh(lowG);
            a = ldem.material.buildBarProperties(mesh, lowG);
            b = ldem.material.buildBarProperties(mesh, highG);
            testCase.verifyEqual(b.criticalStrain, 2 * a.criticalStrain, 'RelTol', 1e-12);
        end
    end
end
