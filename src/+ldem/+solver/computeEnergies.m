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
%     external    Work done so far by the supports and the prescribed motion (state.externalEnergy).
%     balance     external - internal: the part of the work that is not accounted for.
%
%   Energy balance. In a model whose loading acts on degrees of freedom fixed
%   by the scenario, the balance is close to zero: the external work becomes
%   kinetic, elastic, damage or damping energy. It is not exactly zero because
%   the scheme is second-order accurate and because the kinetic energy of the
%   prescribed nodes (which the outside world supplies) is included in
%   kinetic like in the legacy code; both effects are small. Judge the balance
%   relative to the final external work: in the reference tests it is between
%   0.01 % and 0.5 % (it shrinks with the number of steps, because the scheme
%   compares the work of the last step with the energy at its end, an error of
%   about 1/N for energies that grow like t^2).
%
%   The balance does not close when the loaded nodes are not held by the
%   scenario, as in the legacy tension test (see
%   ldem.scenarios.UniaxialTension).
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
%   external work (ENEX) was never computed in the legacy code.
%
%   The kinetic energy of each node is available from
%   ldem.solver.nodalKineticEnergy.
%
%   See also ldem.solver.simulate, ldem.solver.nodalKineticEnergy.

arguments
    state (1,1) struct
    mesh (1,1) struct
    barProps (1,1) struct
    params (1,1) ldem.Parameters
end

% Kinetic energy.
kinetic = sum(ldem.solver.nodalKineticEnergy(state, mesh));

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
energy.external   = state.externalEnergy;
energy.balance    = state.externalEnergy - energy.internal;
end
