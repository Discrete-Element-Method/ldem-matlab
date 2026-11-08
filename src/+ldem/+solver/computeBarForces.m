function state = computeBarForces(state, mesh, barProps, params, law)
%COMPUTEBARFORCES  Axial force of every bar and resulting nodal forces.
%
%   state = ldem.solver.computeBarForces(state, mesh, barProps, params)
%   measures the strain and strain rate of every bar in the current
%   configuration, evaluates the constitutive law (damage included) and
%   adds each bar force to its two end nodes.
%
%   For a bar from node i to node j with current length L, direction
%   cosines c = (xj - xi)/L and axial force F (tension positive), the bar
%   pulls node i toward j with +F*c and node j toward i with -F*c.
%   The strain is (L - L0)/L0 and the rate is the strain change since the
%   previous step divided by dt.
%
%   Inputs:
%     state     Solver state, see ldem.solver.initialState.
%     mesh      Struct from ldem.mesh.buildMesh.
%     barProps  Struct from ldem.material.buildBarProperties.
%     params    ldem.Parameters.
%     law       Optional ldem.material.MaterialLaw (default: the one named by params.constitutiveLaw).
%
%   Output:
%     state  The input state with force, strain, strainRate, axialForce and
%            history updated.
%
%   Errors:
%     ldem:solver:zeroLengthBar  Two end nodes coincide in the current
%                                configuration.
%
%   Legacy: CABAR.
%
%   See also ldem.material.MaterialLaw, ldem.material.bilinearLaw, ldem.solver.integrateStep.

arguments
    state (1,1) struct
    mesh (1,1) struct
    barProps (1,1) struct
    params (1,1) ldem.Parameters
    law = []
end

if isempty(law)
    law = ldem.material.lawFromName(params.constitutiveLaw);
end

first  = mesh.bars(:, 1);
second = mesh.bars(:, 2);
initialLength = mesh.barLength;

% Current configuration and the one of the previous step.
delta = state.displacement(second, :) - state.displacement(first, :);
currentLength = sqrt(delta(:, 1) .* delta(:, 1) + delta(:, 2) .* delta(:, 2) + delta(:, 3) .* delta(:, 3));

deltaPrevious = state.previousDisplacement(second, :) - state.previousDisplacement(first, :);
previousLength = sqrt(deltaPrevious(:, 1) .* deltaPrevious(:, 1) + ...
    deltaPrevious(:, 2) .* deltaPrevious(:, 2) + deltaPrevious(:, 3) .* deltaPrevious(:, 3));

if any(currentLength == 0)
    error('ldem:solver:zeroLengthBar', ...
        'Bar %d has zero length at step %d: its two nodes coincide.', ...
        find(currentLength == 0, 1), state.step);
end

directionCosines = delta ./ currentLength;

strain     = (currentLength  - initialLength) ./ initialLength;
oldStrain  = (previousLength - initialLength) ./ initialLength;
strainRate = (strain - oldStrain) / params.dt;

[axialForce, history] = law.evaluate(strain, strainRate, barProps, state.history, params);

% Add the bar forces to the nodes. The contributions are listed bar by bar
% (start node +, end node -) so that, for every node, they are summed in the
% same order as a loop over the bars; this keeps the rounding identical to
% the legacy code.
nNodes = size(state.displacement, 1);
nodeIndex = reshape([first, second].', [], 1);
nodalForce = zeros(nNodes, 3);
for direction = 1:3
    component = axialForce .* directionCosines(:, direction);
    contributions = reshape([component, -component].', [], 1);
    nodalForce(:, direction) = accumarray(nodeIndex, contributions, [nNodes, 1]);
end

state.force      = nodalForce;
state.strain     = strain;
state.strainRate = strainRate;
state.axialForce = axialForce;
state.history    = history;
end
