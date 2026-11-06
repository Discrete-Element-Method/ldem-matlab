classdef TestPerturbNodes < LdemTestCase
    %TESTPERTURBNODES  Unit tests of ldem.mesh.perturbNodes.

    properties
        Nodes
        Sizes = [8 6 6]
        Lco = 0.01
    end

    methods (TestMethodSetup)
        function createNodes(testCase)
            testCase.Nodes = ldem.mesh.buildNodes(testCase.Sizes, testCase.Lco);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function sameSeedGivesSameResult(testCase)
            a = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 7, 0.02);
            b = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 7, 0.02);
            testCase.verifyEqual(a, b);
        end

        function differentSeedGivesDifferentResult(testCase)
            a = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 1, 0.02);
            b = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 2, 0.02);
            testCase.verifyNotEqual(a, b);
        end

        function zeroVariationLeavesNodesUnchanged(testCase)
            out = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 1, 0);
            testCase.verifyEqual(out, testCase.Nodes);
        end

        function nodesNearTheFacesDoNotMove(testCase)
            out = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 1, 0.05);
            moved = any(out ~= testCase.Nodes, 2);
            lco = testCase.Lco;
            M1 = testCase.Sizes(1) - 1;  N1 = testCase.Sizes(2) - 1;  L1 = testCase.Sizes(3) - 1;
            x = testCase.Nodes(:, 1);  y = testCase.Nodes(:, 2);  z = testCase.Nodes(:, 3);
            nearFace = z >= (L1 - 1.01)*lco | z <= 1.01*lco | ...
                       x >= (M1 - 1.01)*lco | x <= 1.01*lco | ...
                       y >= (N1 - 1.01)*lco | y <= 1.01*lco;
            testCase.verifyFalse(any(moved & nearFace));
            testCase.verifyTrue(any(moved), 'Some interior node should have moved.');
        end

        function displacementsHaveTheRequestedScale(testCase)
            cv = 0.02;
            out = ldem.mesh.perturbNodes(testCase.Nodes, testCase.Sizes, testCase.Lco, 3, cv);
            d = out - testCase.Nodes;
            d = d(any(d ~= 0, 2), :);
            testCase.verifyEqual(std(d(:)), cv * testCase.Lco, 'RelTol', 0.3);
        end

        function enabledThroughParametersChangesTheMesh(testCase)
            base = ldem.Parameters(nModules=testCase.Sizes);
            perturbed = ldem.Parameters(nModules=testCase.Sizes, meshPerturbation=0.02);
            a = ldem.mesh.buildMesh(base);
            b = ldem.mesh.buildMesh(perturbed);
            testCase.verifyNotEqual(a.nodes0, b.nodes0);
            testCase.verifyEqual(a.bars, b.bars, 'Connectivity must not change.');
        end

        function zeroKeepsTheRegularLattice(testCase)
            p = ldem.Parameters(nModules=testCase.Sizes, meshPerturbation=0);
            mesh = ldem.mesh.buildMesh(p);
            testCase.verifyEqual(mesh.nodes0, ...
                ldem.mesh.buildNodes(testCase.Sizes, p.moduleLength));
        end

        function theValueIsTheScaleOfTheDisplacement(testCase)
            small = ldem.mesh.buildMesh(ldem.Parameters(nModules=testCase.Sizes, meshPerturbation=0.01));
            large = ldem.mesh.buildMesh(ldem.Parameters(nModules=testCase.Sizes, meshPerturbation=0.04));
            regular = ldem.mesh.buildNodes(testCase.Sizes, 1);
            regular = regular * ldem.Parameters().moduleLength;
            testCase.verifyEqual(norm(large.nodes0 - regular), ...
                4 * norm(small.nodes0 - regular), 'RelTol', 1e-9);
        end
    end
end
