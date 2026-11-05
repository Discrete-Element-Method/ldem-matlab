function nodes = buildNodes(nModules, moduleLength)
%BUILDNODES  Coordinates of the nodes of the regular lattice.
%
%   nodes = ldem.mesh.buildNodes(nModules, moduleLength) returns the
%   initial coordinates of all nodes of a prism of (M-1)*(N-1)*(L-1) cubic
%   modules, where nModules = [M N L] is the number of nodes along x, y, z.
%
%   The lattice has two kinds of nodes, numbered in this order:
%     1. Grid nodes, M*N*L of them, at the corners of the modules. Node
%        number = (k-1)*M*N + (j-1)*M + i, so x varies fastest.
%     2. Centre nodes, (M-1)*(N-1)*(L-1) of them, one in the middle of each
%        module. Numbered after the grid nodes, also with x fastest.
%
%   Inputs:
%     nModules      [M N L], integers >= 2.
%     moduleLength  Edge length of a module [m].
%
%   Output:
%     nodes  nNodes-by-3 matrix [x y z] in metres.
%
%   Example:
%       nodes = ldem.mesh.buildNodes([3 3 3], 0.01);
%       size(nodes)    % 27 + 8 = 35 nodes
%
%   Legacy: COORD, COORDSUB.
%
%   See also ldem.mesh.buildBars, ldem.mesh.buildMesh.

arguments
    nModules (1,3) double {mustBeInteger, mustBeGreaterThanOrEqual(nModules, 2)}
    moduleLength (1,1) double {mustBePositive, mustBeFinite}
end

M = nModules(1);  N = nModules(2);  L = nModules(3);

% Grid nodes: coordinates are (index - 1) * moduleLength.
[i, j, k] = ndgrid(1:M, 1:N, 1:L);
gridNodes = [i(:) - 1, j(:) - 1, k(:) - 1] * moduleLength;

% Centre nodes: halfway between grid nodes, (index - 0.5) * moduleLength.
[i, j, k] = ndgrid(1:M-1, 1:N-1, 1:L-1);
centreNodes = [i(:) - 0.5, j(:) - 0.5, k(:) - 0.5] * moduleLength;

nodes = [gridNodes; centreNodes];
end
