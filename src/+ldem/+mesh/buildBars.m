function [bars, barType, boundaryFaces] = buildBars(nModules)
%BUILDBARS  Connectivity and classification of the bars of the lattice.
%
%   bars = ldem.mesh.buildBars(nModules) returns, for every bar, the numbers
%   of its two end nodes. Node numbering is the one of ldem.mesh.buildNodes.
%
%   [bars, barType, boundaryFaces] = ldem.mesh.buildBars(nModules) also
%   classifies each bar, which the material model needs to assign
%   stiffness.
%
%   Each cubic module has 12 edges, shared with its neighbours, plus 8
%   diagonals that join the centre node to the 8 corners. The bars are
%   listed in this order:
%
%     1. Grid edges parallel to x, then to y, then to z.
%     2. Centre-to-centre bars parallel to x, then to y, then to z.
%     3. Diagonals: 8 consecutive bars per module (centre -> each corner),
%        modules in node order.
%
%   Input:
%     nModules  [M N L], integers >= 2.
%
%   Outputs:
%     bars           nBars-by-2 matrix of node numbers [startNode endNode].
%     barType        nBars-by-1 codes: 1 grid edge, 2 centre bar, 3 diagonal.
%     boundaryFaces  nBars-by-1 faces of the prism a grid edge lies on (0, 1, 2).
%
%   boundaryFaces is 0 for a grid edge inside the prism, 1 for one on a face
%   and 2 for one on an edge of the prism. It is 0 for the other bar types.
%
%   Example:
%       bars = ldem.mesh.buildBars([2 2 2]);
%       size(bars, 1)    % 12 edges + 8 diagonals = 20 bars
%
%   Legacy: CONECTI, EXTCO1, INTCO1, DIACO1 (connectivity) and the
%   TYPES counter of RMECEX (classification).
%
%   See also ldem.mesh.buildNodes, ldem.mesh.computeBarGeometry,
%   ldem.material.buildBarProperties.

arguments
    nModules (1,3) double {mustBeInteger, mustBeGreaterThanOrEqual(nModules, 2)}
end

M = nModules(1);  N = nModules(2);  L = nModules(3);
M1 = M - 1;  N1 = N - 1;  L1 = L - 1;
nGrid = M * N * L;

% Grid-edge bars: node (i,j,k) joined to its neighbour along one axis. A bar
% along x lies on the surface of the prism when its j or k index is on a
% boundary, and so on for the other axes.
gridNode = @(i, j, k) (k - 1) * M * N + (j - 1) * M + i;
[edgesX, facesX] = edgeBars(gridNode, M1, N,  L,  1,     [M N L], [false true true]);
[edgesY, facesY] = edgeBars(gridNode, M,  N1, L,  M,     [M N L], [true false true]);
[edgesZ, facesZ] = edgeBars(gridNode, M,  N,  L1, M * N, [M N L], [true true false]);

% Centre-to-centre bars: centre (i,j,k) joined to its neighbour.
centreNode = @(i, j, k) nGrid + (k - 1) * M1 * N1 + (j - 1) * M1 + i;
[centresX, ~] = edgeBars(centreNode, M - 2, N1,    L1,    1,       [M N L], [false false false]);
[centresY, ~] = edgeBars(centreNode, M1,    N - 2, L1,    M1,      [M N L], [false false false]);
[centresZ, ~] = edgeBars(centreNode, M1,    N1,    L - 2, M1 * N1, [M N L], [false false false]);

% Diagonals: centre of every module to its 8 corners.
[i, j, k] = ndgrid(1:M1, 1:N1, 1:L1);
corner0 = gridNode(i(:), j(:), k(:));            % lowest corner of each module
centre  = centreNode(i(:), j(:), k(:));
offsets = [0, 1, M, M + 1, M * N, M * N + 1, M * N + M, M * N + M + 1];
corners = (corner0 + offsets).';                 % 8-by-nModulesTotal
starts  = repmat(centre.', 8, 1);
diagonals = [starts(:), corners(:)];

bars = [edgesX; edgesY; edgesZ; centresX; centresY; centresZ; diagonals];

nGridEdges = size(edgesX, 1) + size(edgesY, 1) + size(edgesZ, 1);
nCentreBars = size(centresX, 1) + size(centresY, 1) + size(centresZ, 1);
barType = [ones(nGridEdges, 1); 2 * ones(nCentreBars, 1); 3 * ones(size(diagonals, 1), 1)];
boundaryFaces = [facesX; facesY; facesZ; zeros(nCentreBars + size(diagonals, 1), 1)];
end

function [bars, boundaryFaces] = edgeBars(nodeNumber, nx, ny, nz, stride, nModules, countAxes)
%EDGEBARS  Bars [n, n+stride] for every node n of an nx-by-ny-by-nz block.
%
%   boundaryFaces counts, over the axes flagged in countAxes, how many of the
%   indices i, j, k lie on the first or last node of the prism.
[i, j, k] = ndgrid(1:nx, 1:ny, 1:nz);
first = nodeNumber(i(:), j(:), k(:));
bars = [first, first + stride];

index = [i(:), j(:), k(:)];
onBoundary = index == 1 | index == nModules;       % implicit expansion over columns
boundaryFaces = sum(onBoundary(:, countAxes), 2);
end
