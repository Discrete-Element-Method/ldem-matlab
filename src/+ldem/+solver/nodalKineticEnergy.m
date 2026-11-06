function energy = nodalKineticEnergy(state, mesh)
%NODALKINETICENERGY  Kinetic energy of every node.
%
%   energy = ldem.solver.nodalKineticEnergy(state, mesh) returns the kinetic
%   energy [J] of each node, m*|v|^2/2, with the lumped mass of the node and
%   its current velocity. The kinetic energy of the whole model is the sum of
%   the vector (it is energy.kinetic of ldem.solver.computeEnergies).
%
%   Inputs:
%     state  Solver state (uses velocity).
%     mesh   Struct from ldem.mesh.buildMesh (uses mass).
%
%   Output:
%     energy  nNodes-by-1 vector [J].
%
%   Example:
%       perNode = ldem.solver.nodalKineticEnergy(state, mesh);
%       total = sum(perNode);
%
%   Legacy: ENCN of ENERG2, which was left as a vector and never summed.
%
%   See also ldem.solver.computeEnergies.

arguments
    state (1,1) struct
    mesh (1,1) struct
end

speedSquared = state.velocity(:, 1).^2 + state.velocity(:, 2).^2 + state.velocity(:, 3).^2;
energy = mesh.mass .* speedSquared ./ 2.0;
end
