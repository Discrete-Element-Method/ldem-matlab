function energy = computeEnergies(state, mesh, barProps, params, law)
%COMPUTEENERGIES  Energies of the system at the current state.
%
%   energy = ldem.solver.computeEnergies(state, mesh, barProps, params)
%   returns the energies [J], all of them scalars. The elastic, damage and
%   broken-bar energies come from the constitutive law (ldem.material.MaterialLaw,
%   by default the one named by params.constitutiveLaw; pass another as law).
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
%   In a scenario loaded with forces (ldem.scenarios.ClampedBeam) the work of
%   the applied forces on the free degrees of freedom is part of the external
%   work. The balance does not close when a prescribed motion is not held by
%   the scenario, as happened in the legacy tension test (fixed here, see
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
    law = []
end

if isempty(law)
    law = ldem.material.lawFromName(params.constitutiveLaw);
end

% Kinetic energy.
kinetic = sum(ldem.solver.nodalKineticEnergy(state, mesh));

% Elastic, damage and fracture energy of the bars: they depend on the law.
barEnergy = law.energies(state.strain, barProps, state.history, mesh.barLength);
elastic = barEnergy.elastic;
damage = barEnergy.damage;
brokenBars = barEnergy.brokenBars;

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
