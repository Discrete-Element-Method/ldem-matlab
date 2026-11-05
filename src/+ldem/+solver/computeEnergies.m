function energy = computeEnergies(state, mesh, barProps, params)
%COMPUTEENERGIES  Energies of the system at the current state.
%
%   energy = ldem.solver.computeEnergies(state, mesh, barProps, params)
%   returns the energies [J], all of them scalars.
%
%   Fields of energy:
%
%     time        Simulated time [s].
%     kinetic     Sum of m*|v|^2/2 over all nodes.
%     elastic     Sum of E*strain^2*L/2 over the bars (tension or compression stiffness).
%     damage      Energy dissipated by softening in the damaged bars.
%     damping     Energy dissipated by damping so far (state.dampingEnergy).
%     internal    kinetic + elastic + damage + damping.
%     brokenBars  Total fracture energy of the bars that have broken.
%     damageRate  Change of the damage energy per unit time since the previous step [W].
%
%   For a damaged bar with critical strain EP, largest strain EM and
%   stiffnesses E1 (compression) and E2 (tension), the energy dissipated is
%   L/2 times  E1*EP^2 - E2*EM^2 + (E1*EP + E2*EM)*(EM - EP).
%   For a broken bar the total fracture energy is L/2 * E1*EP^2*KR.
%
%   Inputs:
%     state     Solver state after ldem.solver.integrateStep.
%     mesh      Struct from ldem.mesh.buildMesh.
%     barProps  Struct from ldem.material.buildBarProperties.
%     params    ldem.Parameters.
%
%   Output:
%     energy  Struct with the fields above plus time.
%
%   Example:
%       energy = ldem.solver.computeEnergies(state, mesh, barProps, params);
%
%   Legacy: ENERG2. There the kinetic and damping energies were vectors (one
%   entry per node) that were never summed; here they are scalars. The
%   external work (ENEX) was never computed and is not provided.
%
%   See also ldem.solver.simulate.

arguments
    state (1,1) struct
    mesh (1,1) struct
    barProps (1,1) struct
    params (1,1) ldem.Parameters
end

% Kinetic energy.
speedSquared = state.velocity(:, 1).^2 + state.velocity(:, 2).^2 + state.velocity(:, 3).^2;
kinetic = sum(mesh.mass .* speedSquared ./ 2.0);

% Elastic energy of the bars.
E1 = barProps.stiffness;
E2 = state.history.tensionStiffness;
strain = state.strain;
stiffness = E1;
stiffness(strain >= 0.0) = E2(strain >= 0.0);
elastic = sum(stiffness .* (strain .* strain .* mesh.barLength ./ 2));

% Energy dissipated by damage.
EP = barProps.criticalStrain;
EM = state.history.maxStrain;
damaged = ~state.history.isUndamaged;
area = E1 .* EP .* EP - E2 .* EM .* EM + (E1 .* EP + E2 .* EM) .* (EM - EP);
damage = sum(mesh.barLength(damaged) .* area(damaged) ./ 2);

% Fracture energy of the bars that are completely broken.
broken = damaged & ~state.history.isUnbroken;
brokenBars = sum(E1(broken) .* EP(broken) .* EP(broken) .* barProps.ruptureRatio(broken) ...
    .* mesh.barLength(broken) ./ 2);

energy = struct();
energy.time       = state.time;
energy.kinetic    = kinetic;
energy.elastic    = elastic;
energy.damage     = damage;
energy.damping    = state.dampingEnergy;
energy.internal   = kinetic + elastic + damage + state.dampingEnergy;
energy.brokenBars = brokenBars;
energy.damageRate = (damage - state.previousDamageEnergy) / params.dt;
end
