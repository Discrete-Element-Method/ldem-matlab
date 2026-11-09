function nodes = perturbNodes(nodes, nModules, moduleLength, seed, cv)
%PERTURBNODES  Add a random perturbation to the node coordinates.
%
%   nodes = ldem.mesh.perturbNodes(nodes, nModules, moduleLength, seed, cv)
%   displaces every node by a normally distributed random vector with
%   standard deviation cv*moduleLength in each direction. Nodes close to the
%   faces of the prism keep their original position, so the outer shape is
%   preserved.
%
%   The random numbers are generated with rng(seed) and drawn in the order
%   x, y, z, so the result is reproducible. The global random stream is
%   changed by this call.
%
%   Inputs:
%     nodes         nNodes-by-3 coordinates, from ldem.mesh.buildNodes.
%     nModules      [M N L].
%     moduleLength  Module edge length [m].
%     seed          Seed of the random number generator.
%     cv            Standard deviation as a fraction of moduleLength.
%
%   Output:
%     nodes  Perturbed coordinates (same size as the input).
%
%   Note: the legacy code contains this feature but disables it (it sets
%   LABELN=1 and immediately LABELN=0), so the legacy results correspond to
%   no perturbation. ldem.Parameters.meshPerturbation is 0 (off) by default
%   for the same reason; a positive value switches the perturbation on and is
%   used as cv.
%
%   Legacy: IMPERF.
%
%   See also ldem.mesh.buildNodes.

arguments
    nodes (:,3) double
    nModules (1,3) double
    moduleLength (1,1) double
    seed (1,1) double
    cv (1,1) double {mustBeNonnegative}
end

M1 = nModules(1) - 1;  N1 = nModules(2) - 1;  L1 = nModules(3) - 1;
nNodes = size(nodes, 1);

original = nodes;
rng(seed);
perturbed = nodes;
for axis = 1:3
    perturbed(:, axis) = nodes(:, axis) + randn(nNodes, 1) * cv * moduleLength;
end

% Keep the nodes near the faces of the prism where they were.
x = original(:, 1);  y = original(:, 2);  z = original(:, 3);
nearFace = (z >= (L1 - 1.01) * moduleLength) | (z <= 1.01 * moduleLength) | ...
           (x >= (M1 - 1.01) * moduleLength) | (x <= 1.01 * moduleLength) | ...
           (y >= (N1 - 1.01) * moduleLength) | (y <= 1.01 * moduleLength);
perturbed(nearFace, :) = original(nearFace, :);

nodes = perturbed;
end
