function mass = computeNodalMasses(nModules, moduleLength, density)
%COMPUTENODALMASSES  Lumped mass of every node.
%
%   mass = ldem.mesh.computeNodalMasses(nModules, moduleLength, density)
%   returns the mass [kg] associated with each node.
%
%   Every module has a volume moduleLength^3 and contains one centre node
%   and shares its 8 corners. A full-size mass is  density*moduleLength^3/2
%   (half of the module volume per node type). Grid nodes on the surface of
%   the prism have less material around them, so their mass is divided by 2
%   for each face they lie on: 1/2 on a face, 1/4 on an edge, 1/8 at a
%   corner of the prism. Centre nodes always have the full mass.
%
%   Inputs:
%     nModules      [M N L], integers >= 2.
%     moduleLength  Module edge length [m].
%     density       Mass density [kg/m^3].
%
%   Output:
%     mass  nNodes-by-1 vector, in the node order of ldem.mesh.buildNodes.
%
%   Example:
%       m = ldem.mesh.computeNodalMasses([3 3 3], 0.01, 2000);
%       sum(m)    % total mass, close to density * volume
%
%   Legacy: NODMASS.
%
%   See also ldem.mesh.buildNodes.

arguments
    nModules (1,3) double {mustBeInteger, mustBeGreaterThanOrEqual(nModules, 2)}
    moduleLength (1,1) double {mustBePositive, mustBeFinite}
    density (1,1) double {mustBePositive, mustBeFinite}
end

M = nModules(1);  N = nModules(2);  L = nModules(3);
fullMass = moduleLength * moduleLength * moduleLength * density / 2.0;

% Grid nodes: halve the mass once for each face of the prism they touch.
[i, j, k] = ndgrid(1:M, 1:N, 1:L);
facesTouched = (k == 1 | k == L) + (j == 1 | j == N) + (i == 1 | i == M);
gridMass = fullMass * 2 .^ (-facesTouched(:));

% Centre nodes: full mass.
nCentres = prod(nModules - 1);
centreMass = fullMass * ones(nCentres, 1);

mass = [gridMass; centreMass];
end
