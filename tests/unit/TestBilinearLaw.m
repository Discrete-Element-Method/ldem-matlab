classdef TestBilinearLaw < LdemTestCase
    %TESTBILINEARLAW  Unit tests of ldem.material.bilinearLaw with hand-made bars.
    %
    %   One bar with stiffness E1 = 100 N, critical strain EP = 1e-3 and
    %   rupture ratio KR = 5, so the rupture strain is ER = 5e-3. The
    %   expected forces are computed by hand from the law:
    %       softening force = E1 * (EP - (strain - EP)/(KR - 1))

    properties (Constant)
        E1 = 100
        EP = 1e-3
        KR = 5
    end

    methods (Access = private)
        function [props, history] = makeBars(testCase, n)
            props = struct( ...
                'stiffness',      repmat(testCase.E1, n, 1), ...
                'criticalStrain', repmat(testCase.EP, n, 1), ...
                'ruptureRatio',   repmat(testCase.KR, n, 1), ...
                'ruptureStrain',  repmat(testCase.KR * testCase.EP, n, 1));
            history = struct( ...
                'tensionStiffness', repmat(testCase.E1, n, 1), ...
                'maxStrain',        repmat(testCase.EP, n, 1), ...
                'isUndamaged',      true(n, 1), ...
                'isUnbroken',       true(n, 1));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function elasticTensionBelowCriticalStrain(testCase)
            [props, history] = testCase.makeBars(1);
            [force, after] = ldem.material.bilinearLaw(5e-4, 0, props, history, 0);
            testCase.verifyEqual(force, 100 * 5e-4, 'RelTol', 1e-14);
            testCase.verifyEqual(after, history, 'An elastic bar must not change state.');
        end

        function compressionIsAlwaysElastic(testCase)
            [props, history] = testCase.makeBars(1);
            [force, after] = ldem.material.bilinearLaw(-0.02, 0, props, history, 0);
            testCase.verifyEqual(force, 100 * -0.02, 'RelTol', 1e-14);
            testCase.verifyEqual(after, history);
        end

        function softeningFollowsTheDescendingLine(testCase)
            [props, history] = testCase.makeBars(1);
            strain = 2e-3;
            expected = 100 * (1e-3 - (strain - 1e-3) / 4);   % 0.075
            [force, after] = ldem.material.bilinearLaw(strain, 0, props, history, 0);

            testCase.verifyEqual(force, expected, 'RelTol', 1e-12);
            testCase.verifyEqual(after.tensionStiffness, expected / strain, 'RelTol', 1e-12);
            testCase.verifyEqual(after.maxStrain, strain);
            testCase.verifyFalse(after.isUndamaged);
            testCase.verifyTrue(after.isUnbroken);
        end

        function forceIsContinuousAtTheCriticalStrain(testCase)
            [props, history] = testCase.makeBars(1);
            elastic = ldem.material.bilinearLaw(1e-3 * (1 - 1e-9), 0, props, history, 0);
            softening = ldem.material.bilinearLaw(1e-3 * (1 + 1e-9), 0, props, history, 0);
            testCase.verifyEqual(softening, elastic, 'RelTol', 1e-6);
            testCase.verifyEqual(elastic, 100 * 1e-3, 'RelTol', 1e-6);   % peak force
        end

        function forceVanishesAtTheRuptureStrain(testCase)
            [props, history] = testCase.makeBars(1);
            force = ldem.material.bilinearLaw(5e-3 * (1 - 1e-9), 0, props, history, 0);
            testCase.verifyEqual(force, 0, 'AbsTol', 1e-9);
        end

        function unloadingIsLinearTowardTheOrigin(testCase)
            [props, history] = testCase.makeBars(1);
            [~, history] = ldem.material.bilinearLaw(2e-3, 0, props, history, 0);
            peakForce = 0.075;

            [force, after] = ldem.material.bilinearLaw(1e-3, 0, props, history, 0);
            testCase.verifyEqual(force, peakForce * (1e-3 / 2e-3), 'RelTol', 1e-12);
            testCase.verifyEqual(after.maxStrain, 2e-3, 'Unloading must not reduce maxStrain.');
            testCase.verifyEqual(after.tensionStiffness, history.tensionStiffness);
        end

        function reloadingReturnsToTheSofteningLine(testCase)
            [props, history] = testCase.makeBars(1);
            [f1, history] = ldem.material.bilinearLaw(2e-3, 0, props, history, 0);
            [~, history] = ldem.material.bilinearLaw(1e-3, 0, props, history, 0);
            f2 = ldem.material.bilinearLaw(2e-3, 0, props, history, 0);
            testCase.verifyEqual(f2, f1, 'RelTol', 1e-12);
        end

        function ruptureIsPermanent(testCase)
            [props, history] = testCase.makeBars(1);
            [force, history] = ldem.material.bilinearLaw(6e-3, 0, props, history, 0);
            testCase.verifyEqual(force, 0);
            testCase.verifyFalse(history.isUnbroken);
            testCase.verifyFalse(history.isUndamaged);
            testCase.verifyEqual(history.tensionStiffness, 0);

            % A broken bar carries no tension even when the strain goes back down...
            force = ldem.material.bilinearLaw(1e-3, 0, props, history, 0);
            testCase.verifyEqual(force, 0);
            % ...but still resists compression (contact).
            force = ldem.material.bilinearLaw(-1e-3, 0, props, history, 0);
            testCase.verifyEqual(force, -0.1, 'RelTol', 1e-14);
        end

        function viscousTermIsAddedExceptWhenBroken(testCase)
            [props, history] = testCase.makeBars(1);
            damping = 0.1;  rate = 10;
            force = ldem.material.bilinearLaw(5e-4, rate, props, history, damping);
            testCase.verifyEqual(force, 100 * 5e-4 + 100 * damping * rate, 'RelTol', 1e-14);

            force = ldem.material.bilinearLaw(-5e-4, rate, props, history, damping);
            testCase.verifyEqual(force, -100 * 5e-4 + 100 * damping * rate, 'RelTol', 1e-14);

            force = ldem.material.bilinearLaw(6e-3, rate, props, history, damping);
            testCase.verifyEqual(force, 0, 'A broken bar has no viscous force either.');
        end

        function vectorizedResultEqualsBarByBar(testCase)
            strains = [5e-4; 2e-3; 6e-3; -1e-3; 3e-3];
            rates   = [1; -2; 3; 0.5; -1];
            [props, history] = testCase.makeBars(numel(strains));

            [forceAll, historyAll] = ldem.material.bilinearLaw(strains, rates, props, history, 0.05);

            for k = 1:numel(strains)
                [p, h] = testCase.makeBars(1);
                [f, hk] = ldem.material.bilinearLaw(strains(k), rates(k), p, h, 0.05);
                testCase.verifyEqual(forceAll(k), f);
                testCase.verifyEqual(historyAll.tensionStiffness(k), hk.tensionStiffness);
                testCase.verifyEqual(historyAll.maxStrain(k), hk.maxStrain);
                testCase.verifyEqual(historyAll.isUndamaged(k), hk.isUndamaged);
                testCase.verifyEqual(historyAll.isUnbroken(k), hk.isUnbroken);
            end
        end

        function tensionForceNeverExceedsThePeak(testCase)
            [props, history] = testCase.makeBars(1);
            strains = linspace(0, 0.01, 200).';
            peak = 100 * 1e-3;
            for k = 1:numel(strains)
                [f, history] = ldem.material.bilinearLaw(strains(k), 0, props, history, 0);
                testCase.verifyLessThanOrEqual(f, peak * (1 + 1e-12));
            end
        end

        function sizeMismatchIsReported(testCase)
            [props, history] = testCase.makeBars(3);
            testCase.verifyError( ...
                @() ldem.material.bilinearLaw([1e-3; 2e-3], [0; 0], props, history, 0), ...
                'ldem:material:sizeMismatch');
        end
    end
end
