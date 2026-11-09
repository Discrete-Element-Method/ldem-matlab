classdef TestMesh < LdemTestCase
    %TESTMESH  Unit tests of the ldem.mesh package using analytical results.

    properties (TestParameter)
        % Sizes [M N L] covering cubes, prisms and the 2-node minimum.
        sizes = {[2 2 2], [3 3 3], [4 3 2], [5 2 3], [6 4 5]}
    end

    methods (Test, TestTags = {'Unit'})
        function nodeCount(testCase, sizes)
            nodes = ldem.mesh.buildNodes(sizes, 0.01);
            expected = prod(sizes) + prod(sizes - 1);
            testCase.verifySize(nodes, [expected 3]);
        end

        function nodeCoordinates(testCase)
            lco = 0.5;
            nodes = ldem.mesh.buildNodes([3 2 2], lco);
            % Grid nodes: x runs fastest.
            testCase.verifyEqual(nodes(1, :), [0 0 0]);
            testCase.verifyEqual(nodes(2, :), [1 0 0] * lco);
            testCase.verifyEqual(nodes(3, :), [2 0 0] * lco);
            testCase.verifyEqual(nodes(4, :), [0 1 0] * lco);
            testCase.verifyEqual(nodes(7, :), [0 0 1] * lco);
            % Centre nodes come after the 12 grid nodes, at half-integer positions.
            testCase.verifyEqual(nodes(13, :), [0.5 0.5 0.5] * lco);
            testCase.verifyEqual(nodes(14, :), [1.5 0.5 0.5] * lco);
        end

        function barCount(testCase, sizes)
            M = sizes(1);  N = sizes(2);  L = sizes(3);
            gridEdges   = (M-1)*N*L + M*(N-1)*L + M*N*(L-1);
            centreBars  = (M-2)*(N-1)*(L-1) + (M-1)*(N-2)*(L-1) + (M-1)*(N-1)*(L-2);
            diagonals   = 8 * (M-1)*(N-1)*(L-1);
            bars = ldem.mesh.buildBars(sizes);
            testCase.verifySize(bars, [gridEdges + centreBars + diagonals, 2]);
        end

        function barClassification(testCase)
            % In a 4x4x4 prism: 144 grid edges (36 inside, 72 on faces, 36 on
            % prism edges), 3*2*3*3 = 54 centre bars and 8*27 = 216 diagonals.
            [bars, type, faces] = ldem.mesh.buildBars([4 4 4]);
            testCase.verifySize(type, [size(bars, 1) 1]);
            testCase.verifySize(faces, [size(bars, 1) 1]);
            testCase.verifyEqual(nnz(type == 1), 144);
            testCase.verifyEqual(nnz(type == 2), 54);
            testCase.verifyEqual(nnz(type == 3), 216);
            testCase.verifyEqual(nnz(type == 1 & faces == 0), 36);
            testCase.verifyEqual(nnz(type == 1 & faces == 1), 72);
            testCase.verifyEqual(nnz(type == 1 & faces == 2), 36);
            testCase.verifyTrue(all(faces(type ~= 1) == 0));
        end

        function singleModuleHasTwentyBars(testCase)
            bars = ldem.mesh.buildBars([2 2 2]);
            testCase.verifySize(bars, [20 2]);
        end

        function barsAreValidAndUnique(testCase, sizes)
            bars = ldem.mesh.buildBars(sizes);
            nNodes = prod(sizes) + prod(sizes - 1);
            testCase.verifyGreaterThanOrEqual(min(bars, [], 'all'), 1);
            testCase.verifyLessThanOrEqual(max(bars, [], 'all'), nNodes);
            testCase.verifyTrue(all(bars(:, 1) ~= bars(:, 2)), 'A bar joins a node to itself.');
            unordered = sort(bars, 2);
            testCase.verifySize(unique(unordered, 'rows'), size(bars), ...
                'The same pair of nodes is joined by more than one bar.');
        end

        function everyNodeIsConnected(testCase, sizes)
            bars = ldem.mesh.buildBars(sizes);
            nNodes = prod(sizes) + prod(sizes - 1);
            testCase.verifyEqual(numel(unique(bars)), nNodes);
        end

        function barLengthsAreEdgesAndDiagonals(testCase)
            lco = 0.02;
            nodes = ldem.mesh.buildNodes([4 3 3], lco);
            bars = ldem.mesh.buildBars([4 3 3]);
            len = ldem.mesh.computeBarGeometry(nodes, bars);
            allowed = [lco, lco * sqrt(3) / 2];
            distance = min(abs(len - allowed), [], 2);
            testCase.verifyLessThan(max(distance), 1e-14);
            testCase.verifyEqual(min(len), lco * sqrt(3) / 2, 'RelTol', 1e-12);
        end

        function barMidpointsLieBetweenEndNodes(testCase)
            nodes = ldem.mesh.buildNodes([3 3 3], 1);
            bars = ldem.mesh.buildBars([3 3 3]);
            [~, mid] = ldem.mesh.computeBarGeometry(nodes, bars);
            testCase.verifyEqual(mid, (nodes(bars(:, 1), :) + nodes(bars(:, 2), :)) / 2);
        end

        function totalMassEqualsDensityTimesVolume(testCase, sizes)
            lco = 0.01;  rho = 2500;
            mass = ldem.mesh.computeNodalMasses(sizes, lco, rho);
            volume = prod(sizes - 1) * lco^3;
            testCase.verifyEqual(sum(mass), rho * volume, 'RelTol', 1e-12);
        end

        function massReductionAtFacesEdgesAndCorners(testCase)
            lco = 1;  rho = 2;
            full = lco^3 * rho / 2;
            mass = ldem.mesh.computeNodalMasses([4 4 4], lco, rho);
            nodeAt = @(i, j, k) (k-1)*16 + (j-1)*4 + i;
            testCase.verifyEqual(mass(nodeAt(2, 2, 2)), full);        % interior
            testCase.verifyEqual(mass(nodeAt(1, 2, 2)), full / 2);    % face
            testCase.verifyEqual(mass(nodeAt(1, 1, 2)), full / 4);    % edge
            testCase.verifyEqual(mass(nodeAt(1, 1, 1)), full / 8);    % corner
            testCase.verifyEqual(mass(65), full);                     % centre node
        end

        function zeroLengthBarIsDetected(testCase)
            nodes = [0 0 0; 0 0 0; 1 0 0];
            testCase.verifyError(@() ldem.mesh.computeBarGeometry(nodes, [1 2; 2 3]), ...
                'ldem:mesh:zeroLengthBar');
        end

        function barReferringToMissingNodeIsDetected(testCase)
            nodes = [0 0 0; 1 0 0];
            testCase.verifyError(@() ldem.mesh.computeBarGeometry(nodes, [1 3]), ...
                'ldem:mesh:badConnectivity');
        end

        function buildMeshAssemblesEverything(testCase)
            params = ldem.Parameters(testId=101, nModules=[6 3 3]);
            mesh = ldem.mesh.buildMesh(params);

            nNodes = params.nNodes;
            testCase.verifySize(mesh.nodes0, [nNodes 3]);
            testCase.verifySize(mesh.fixed, [nNodes 3]);
            testCase.verifyClass(mesh.fixed, 'logical');
            testCase.verifySize(mesh.mass, [nNodes 1]);
            testCase.verifyEqual(mesh.nGridNodes, 54);
            nBars = size(mesh.bars, 1);
            testCase.verifySize(mesh.barLength, [nBars 1]);
            testCase.verifySize(mesh.barCentres, [nBars 3]);
        end

        function buildMeshRejectsUnknownTest(testCase)
            params = ldem.Parameters(testId=999);
            testCase.verifyError(@() ldem.mesh.buildMesh(params), ...
                'ldem:scenarios:unknownTest');
        end
    end
end
