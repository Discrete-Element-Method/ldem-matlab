classdef TestGenerateRandomField < LdemTestCase
    %TESTGENERATERANDOMFIELD  Unit tests of ldem.material.generateRandomField.

    methods (Access = private)
        function centres = gridCentres(~, n, spacing)
            % Points of a regular n(1)-by-n(2)-by-n(3) grid with the given spacing.
            [x, y, z] = ndgrid((0:n(1)-1) * spacing, (0:n(2)-1) * spacing, (0:n(3)-1) * spacing);
            centres = [x(:), y(:), z(:)];
        end
    end

    methods (Test, TestTags = {'Unit'})
        function oneValuePerBarAllPositive(testCase)
            centres = testCase.gridCentres([10 6 6], 1e-3);
            field = ldem.material.generateRandomField(centres, 0.2, 3e-3, 1);
            testCase.verifySize(field, [size(centres, 1) 1]);
            testCase.verifyGreaterThan(min(field), 0);
            testCase.verifyTrue(all(isfinite(field)));
        end

        function weibullOfThePolesHasMeanOneAndTheRequestedCv(testCase)
            for cv = [0.01 0.05 0.2 1]
                [~, info] = ldem.material.generateRandomField([0 0 0], cv, 1, 1);
                k = info.weibullShape;
                lambda = info.weibullScale;
                m1 = lambda * gamma(1 + 1/k);
                m2 = lambda^2 * gamma(1 + 2/k);
                testCase.verifyEqual(m1, 1, 'RelTol', 1e-10);
                testCase.verifyEqual(sqrt(m2 - m1^2) / m1, cv, 'RelTol', 1e-8);
            end
        end

        function polesHaveTheRequestedStatistics(testCase)
            % Bars exactly on the poles take the pole values, so with a
            % correlation length equal to the spacing the field is the
            % (independent) pole values: check their sample mean and CV.
            centres = testCase.gridCentres([40 40 40], 1);
            field = ldem.material.generateRandomField(centres, 0.1, 1, 7);
            testCase.verifyEqual(mean(field), 1, 'AbsTol', 0.005);
            testCase.verifyEqual(std(field) / mean(field), 0.1, 'RelTol', 0.03);
        end

        function interpolationReducesTheScatter(testCase)
            centres = testCase.gridCentres([30 30 30], 1);
            [~, info] = ldem.material.generateRandomField(centres, 0.1, 6, 7);
            testCase.verifyLessThan(info.fieldCv, 0.1);
            testCase.verifyGreaterThan(info.fieldCv, 0);
        end

        function longerCorrelationMakesNeighboursMoreAlike(testCase)
            centres = testCase.gridCentres([60 4 4], 1);
            jump = @(f) mean(abs(diff(reshape(f, 60, []), 1, 1)), 'all') / mean(f);
            short = ldem.material.generateRandomField(centres, 0.2, 1.5, 3);
            long  = ldem.material.generateRandomField(centres, 0.2, 10, 3);
            testCase.verifyLessThan(jump(long), jump(short));
        end

        function fieldIsLinearBetweenTwoPoles(testCase)
            % Along a line between two poles the field is a straight line.
            centres = [linspace(0, 1, 11).', zeros(11, 1), zeros(11, 1)];
            field = ldem.material.generateRandomField(centres, 0.3, 1, 4);
            testCase.verifyEqual(diff(field, 2), zeros(9, 1), 'AbsTol', 1e-12);
        end

        function sameSeedSameFieldAndGlobalStreamUntouched(testCase)
            centres = testCase.gridCentres([8 5 5], 1e-3);
            rng(42);
            before = rand();
            rng(42);
            a = ldem.material.generateRandomField(centres, 0.1, 2e-3, 11);
            after = rand();
            b = ldem.material.generateRandomField(centres, 0.1, 2e-3, 11);
            c = ldem.material.generateRandomField(centres, 0.1, 2e-3, 12);
            testCase.verifyEqual(a, b);
            testCase.verifyNotEqual(a, c);
            testCase.verifyEqual(after, before, 'The global random stream must not be used.');
        end

        function anisotropicCorrelationLength(testCase)
            centres = testCase.gridCentres([10 10 10], 1);
            [~, info] = ldem.material.generateRandomField(centres, 0.1, [1 2 5], 1);
            testCase.verifyEqual(info.correlationLength, [1 2 5]);
            testCase.verifyEqual(info.nPoles, [12 8 5]);
        end

        function infoDescribesTheField(testCase)
            centres = testCase.gridCentres([5 5 5], 1);
            [field, info] = ldem.material.generateRandomField(centres, 0.05, 2, 515);
            testCase.verifyEqual(info.source, "generated");
            testCase.verifyEqual(info.cv, 0.05);
            testCase.verifyEqual(info.seed, 515);
            testCase.verifyEqual(info.fieldMean, mean(field));
            testCase.verifyEqual(info.fieldCv, std(field) / mean(field));
        end

        function badCorrelationLengthIsRejected(testCase)
            testCase.verifyError( ...
                @() ldem.material.generateRandomField([0 0 0], 0.1, [1 2], 1), ...
                'ldem:material:badCorrelationLength');
        end

        function tooSmallCvIsRejected(testCase)
            testCase.verifyError( ...
                @() ldem.material.generateRandomField([0 0 0], 1e-7, 1, 1), ...
                'ldem:material:randomFieldCvTooSmall');
        end
    end
end
