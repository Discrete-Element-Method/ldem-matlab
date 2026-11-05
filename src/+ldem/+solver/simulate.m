function [state, record] = simulate(params, mesh, barProps, history, scenario, options)
%SIMULATE  Run the explicit time integration of an LDEM model.
%
%   [state, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario)
%   advances the model from time zero to params.totalTime and returns the
%   final state and the results recorded along the way.
%
%   Every step does, in this order:
%     1. advance the time,
%     2. impose the loading of the scenario,
%     3. compute the bar forces (damage included),
%     4. integrate the equations of motion,
%     5. compute the energies and store the requested results.
%
%   Inputs:
%     params    ldem.Parameters.
%     mesh      Struct from ldem.mesh.buildMesh.
%     barProps  Struct from ldem.material.buildBarProperties.
%     history   Initial damage state, second output of buildBarProperties.
%     scenario  Object of a subclass of ldem.scenarios.Scenario.
%
%   Name-value options:
%
%     SnapshotFcn  Function handle f(state) for the snapshots (see below).
%     Verbose      Print the progress every 10 % (default false).
%
%   SnapshotFcn is called at time zero and every params.output.snapshotEvery
%   steps, and never if that value is 0.
%
%   Outputs:
%     state   Final solver state, see ldem.solver.initialState.
%     record  Struct with the results stored along the run, see below.
%
%   Fields of record:
%
%     controlNodes  time (n-by-1) and displacement, velocity, acceleration (n-by-k-by-3 for k nodes).
%     reactions     time (n-by-1) and force (n-by-3), the scenario reaction.
%     energy        time and the energies of ldem.solver.computeEnergies as column vectors.
%     trackedBar    bar number, time, strain, criticalStrain, ruptureStrain, force, damageEnergy.
%
%   controlNodes and reactions are stored every params.output.controlNodesEvery
%   steps and energy every energyEvery steps. trackedBar is stored at every
%   step, only when trackedBarEvery is 1 and the bar exists in the mesh.
%
%   Errors:
%     ldem:solver:nonFinite  A displacement became NaN or Inf (unstable
%                            time step or coincident nodes).
%
%   Example:
%       params = ldem.Parameters();
%       mesh = ldem.mesh.buildMesh(params);
%       [barProps, history] = ldem.material.buildBarProperties(mesh, params);
%       scenario = ldem.scenarios.fromTestId(params.testId);
%       [state, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario);
%
%   Legacy: the time loop of the main program (main1) with CALOAD, CABAR,
%   IGN012, CALRES, WRIDIPO, ENERG2 and WRIENE.
%
%   See also ldem.solver.computeBarForces, ldem.solver.integrateStep,
%   ldem.solver.computeEnergies.

arguments
    params (1,1) ldem.Parameters
    mesh (1,1) struct
    barProps (1,1) struct
    history (1,1) struct
    scenario (1,1) ldem.scenarios.Scenario
    options.SnapshotFcn = []
    options.Verbose (1,1) logical = false
end

ldem.solver.checkStability(mesh.barLength, params);

nSteps = params.nSteps;
controlEvery  = params.output.controlNodesEvery;
energyEvery   = params.output.energyEvery;
snapshotEvery = params.output.snapshotEvery;
trackBar = params.output.trackedBarEvery > 0 && params.trackedBar <= size(mesh.bars, 1);

nControl = numel(params.controlNodes);
nControlRows = floor(nSteps / max(controlEvery, 1)) * (controlEvery > 0);
nEnergyRows  = floor(nSteps / max(energyEvery, 1)) * (energyEvery > 0);

record = struct();
record.controlNodes = struct( ...
    'time',         zeros(nControlRows, 1), ...
    'displacement', zeros(nControlRows, nControl, 3), ...
    'velocity',     zeros(nControlRows, nControl, 3), ...
    'acceleration', zeros(nControlRows, nControl, 3));
record.reactions = struct('time', zeros(nControlRows, 1), 'force', zeros(nControlRows, 3));
record.energy = struct('time', zeros(nEnergyRows, 1), 'kinetic', zeros(nEnergyRows, 1), ...
    'elastic', zeros(nEnergyRows, 1), 'damage', zeros(nEnergyRows, 1), ...
    'damping', zeros(nEnergyRows, 1), 'internal', zeros(nEnergyRows, 1), ...
    'brokenBars', zeros(nEnergyRows, 1), 'damageRate', zeros(nEnergyRows, 1));
nTracked = nSteps * trackBar;
record.trackedBar = struct('bar', params.trackedBar, 'time', zeros(nTracked, 1), ...
    'strain', zeros(nTracked, 1), 'criticalStrain', zeros(nTracked, 1), ...
    'ruptureStrain', zeros(nTracked, 1), 'force', zeros(nTracked, 1), ...
    'damageEnergy', zeros(nTracked, 1));

state = ldem.solver.initialState(mesh, history);
if snapshotEvery > 0 && ~isempty(options.SnapshotFcn)
    options.SnapshotFcn(state);
end

controlRow = 0;
energyRow = 0;
progressStep = max(1, floor(nSteps / 10));

for step = 1:nSteps
    state.step = step;
    state.time = state.time + params.dt;

    state = scenario.applyLoads(state, mesh, params);
    state = ldem.solver.computeBarForces(state, mesh, barProps, params);
    state = ldem.solver.integrateStep(state, mesh, barProps, params);

    if ~all(isfinite(state.displacement), 'all')
        error('ldem:solver:nonFinite', ...
            ['Displacements are not finite at step %d (time %g s). The time ' ...
             'step may be unstable or two nodes coincide.'], step, state.time);
    end

    energy = ldem.solver.computeEnergies(state, mesh, barProps, params);
    state.previousDamageEnergy = energy.damage;

    if controlEvery > 0 && mod(step, controlEvery) == 0
        controlRow = controlRow + 1;
        record.controlNodes.time(controlRow) = state.time;
        record.controlNodes.displacement(controlRow, :, :) = reshape(state.displacement(params.controlNodes, :), 1, nControl, 3);
        record.controlNodes.velocity(controlRow, :, :)     = reshape(state.velocity(params.controlNodes, :), 1, nControl, 3);
        record.controlNodes.acceleration(controlRow, :, :) = reshape(state.acceleration(params.controlNodes, :), 1, nControl, 3);
        record.reactions.time(controlRow) = state.time;
        record.reactions.force(controlRow, :) = scenario.reactions(state, mesh, params);
    end

    if energyEvery > 0 && mod(step, energyEvery) == 0
        energyRow = energyRow + 1;
        names = fieldnames(record.energy);
        for k = 1:numel(names)
            record.energy.(names{k})(energyRow) = energy.(names{k});
        end
    end

    if trackBar
        b = params.trackedBar;
        record.trackedBar.time(step)           = state.time;
        record.trackedBar.strain(step)         = state.strain(b);
        record.trackedBar.criticalStrain(step) = barProps.criticalStrain(b);
        record.trackedBar.ruptureStrain(step)  = barProps.ruptureStrain(b);
        record.trackedBar.force(step)          = state.axialForce(b);
        record.trackedBar.damageEnergy(step)   = trackedDamageEnergy(state, mesh, barProps, b);
    end

    if snapshotEvery > 0 && mod(step, snapshotEvery) == 0 && ~isempty(options.SnapshotFcn)
        options.SnapshotFcn(state);
    end

    if options.Verbose && mod(step, progressStep) == 0
        fprintf('  step %d / %d  (t = %.4g s)\n', step, nSteps, state.time);
    end
end
end

function value = trackedDamageEnergy(state, mesh, barProps, b)
%TRACKEDDAMAGEENERGY  Energy dissipated by damage in one bar (zero if undamaged).
if state.history.isUndamaged(b)
    value = 0.0;
    return
end
E1 = barProps.stiffness(b);
E2 = state.history.tensionStiffness(b);
EP = barProps.criticalStrain(b);
EM = state.history.maxStrain(b);
area = E1 * EP * EP - E2 * EM * EM + (E1 * EP + E2 * EM) * (EM - EP);
value = mesh.barLength(b) * area / 2;
end
