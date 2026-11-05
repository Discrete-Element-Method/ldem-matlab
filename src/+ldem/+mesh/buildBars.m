function bars = buildBars(nModules)
%BUILDBARS  Connectivity of the bars of the lattice.
%
%   bars = ldem.mesh.buildBars(nModules) returns, for every bar, the numbers
%   of its two end nodes. Node numbering is the one of ldem.mesh.buildNodes.
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
%   Output:
%     bars  nBars-by-2 matrix of node numbers [startNode endNode].
%
%   Example:
%       bars = ldem.mesh.buildBars([2 2 2]);
%       size(bars, 1)    % 12 edges + 8 diagonals = 20 bars
%
%   Legacy: CONECTI, EXTCO1, INTCO1, DIACO1.
%
%   See also ldem.mesh.buildNodes, ldem.mesh.computeBarGeometry.

arguments
    nModules (1,3) double {mustBeInteger, mustBeGreaterThanOrEqual(nModules, 2)}
end

M = nModules(1);  N = nModules(2);  L = nModules(3);
M1 = M - 1;  N1 = N - 1;  L1 = L - 1;
nGrid = M * N * L;

% Grid-edge bars: node (i,j,k) joined to its neighbour along one axis.
gridNode = @(i, j, k) (k - 1) * M * N + (j - 1) * M + i;
edgesX = edgeBars(gridNode, M1, N,  L,  1);
edgesY = edgeBars(gridNode, M,  N1, L,  M);
edgesZ = edgeBars(gridNode, M,  N,  L1, M * N);

% Centre-to-centre bars: centre (i,j,k) joined to its neighbour.
centreNode = @(i, j, k) nGrid + (k - 1) * M1 * N1 + (j - 1) * M1 + i;
centresX = edgeBars(centreNode, M - 2, N1,    L1,    1);
centresY = edgeBars(centreNode, M1,    N - 2, L1,    M1);
centresZ = edgeBars(centreNode, M1,    N1,    L - 2, M1 * N1);

% Diagonals: centre of every module to its 8 corners.
[i, j, k] = ndgrid(1:M1, 1:N1, 1:L1);
corner0 = gridNode(i(:), j(:), k(:));            % lowest corner of each module
centre  = centreNode(i(:), j(:), k(:));
offsets = [0, 1, M, M + 1, M * N, M * N + 1, M * N + M, M * N + M + 1];
corners = (corner0 + offsets).';                 % 8-by-nModulesTotal
starts  = repmat(centre.', 8, 1);
diagonals = [starts(:), corners(:)];

bars = [edgesX; edgesY; edgesZ; centresX; centresY; centresZ; diagonals];
end

function bars = edgeBars(nodeNumber, nx, ny, nz, stride)
%EDGEBARS  Bars [n, n+stride] for every node n of an nx-by-ny-by-nz block.
[i, j, k] = ndgrid(1:nx, 1:ny, 1:nz);
first = nodeNumber(i(:), j(:), k(:));
bars = [first, first + stride];
end
