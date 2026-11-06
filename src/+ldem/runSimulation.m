function results = runSimulation(params, options)
%RUNSIMULATION  Run a complete LDEM simulation.
%
%   results = ldem.runSimulation(params) builds the lattice model described
%   by params, integrates it in time and returns all the useful information
%   in one struct.
%
%   results = ldem.runSimulation(params, Name=Value) accepts options, for
%   example
%
%       results = ldem.runSimulation(params, OutputFolder="output", ...
%           Formats=["mat" "ansys" "vtk"]);
%
%   writes results.mat, ANSYS macro files and a VTK series (to open in
%   ParaView) to the folder "output".
%
%   Name-value options:
%
%     OutputFolder  Folder for the output files (empty: nothing is written).
%     Formats       Files to write: "mat", "ansys" and/or "vtk" (default "mat").
%     Scenario      Scenario object (default: the one registered for params.testId).
%     Verbose       Print the progress (default false).
%
%   With an empty OutputFolder the results are only returned. The ANSYS and
%   VTK files are written at time zero and every params.output.snapshotEvery
%   steps, so that value must be positive to obtain them.
%
%   Output:
%     results  Struct with the parts listed below.
%
%   Fields of results:
%
%     info          Version of ldem, date, MATLAB release, run time.
%     params        Input parameters (plain struct, derived values included).
%     model         Counts and mass of the model (ldem.mesh.summarizeModel).
%     material      Material data and statistics (ldem.material.summarizeMaterial).
%     mesh          Nodes, supports, masses, bars and bar geometry.
%     barProps      Constant properties of the bars.
%     controlNodes  Motion of the control nodes versus time.
%     reactions     Reaction force of the test versus time.
%     energy        Energies versus time.
%     trackedBar    History of the bar params.trackedBar (may be empty).
%     snapshots     Compact copies of the state at the snapshot steps.
%     final         Final state of nodes and bars, with the kinetic energy of each node.
%
%   The fields of each part are described in ldem.solver.simulate,
%   ldem.mesh.buildMesh, ldem.material.buildBarProperties and
%   ldem.io.SnapshotWriter.
%
%   Example:
%       params = ldem.Parameters(testId=101, nModules=[6 3 3], totalTime=2e-4);
%       results = ldem.runSimulation(params);
%       ldem.post.plotEnergy(results);
%
%   Legacy: the main program (main1) and its input/output routines.
%
%   See also ldem.Parameters, ldem.solver.simulate, ldem.io.saveResults.

arguments
    params (1,1) ldem.Parameters
    options.OutputFolder (1,1) string = ""
    options.Formats (1,:) string {mustBeMember(options.Formats, ["mat", "ansys", "vtk"])} = "mat"
    options.Scenario = []
    options.Verbose (1,1) logical = false
end

params.validate();
if isempty(options.Scenario)
    scenario = ldem.scenarios.fromTestId(params.testId);
else
    scenario = options.Scenario;
end

writeFiles = strlength(options.OutputFolder) > 0;
snapshotFormats = intersect(options.Formats, ["ansys", "vtk"], 'stable');
if ~writeFiles
    snapshotFormats = string.empty;
elseif ~isempty(snapshotFormats) && params.output.snapshotEvery == 0
    warning('ldem:output:noSnapshots', ...
        ['%s files were requested but params.output.snapshotEvery is 0, so ' ...
         'none will be written. Set snapshotEvery to the number of steps ' ...
         'between files.'], strjoin(upper(snapshotFormats), ' and '));
end
if writeFiles && ~isfolder(options.OutputFolder)
    mkdir(options.OutputFolder);
end

timer = tic;
if options.Verbose
    fprintf('Building the model (%d nodes) ...\n', params.nNodes);
end
mesh = ldem.mesh.buildMesh(params, scenario);
[barProps, history] = ldem.material.buildBarProperties(mesh, params);

writer = ldem.io.SnapshotWriter(mesh, options.OutputFolder, snapshotFormats);
if options.Verbose
    fprintf('Integrating %d steps ...\n', params.nSteps);
end
[state, record] = ldem.solver.simulate(params, mesh, barProps, history, scenario, ...
    SnapshotFcn=@writer.write, Verbose=options.Verbose);

results = struct();
results.info = struct( ...
    'version',        ldem.version(), ...
    'date',           string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
    'matlabRelease',  string(version('-release')), ...
    'elapsedSeconds', toc(timer));
results.params       = params.toStruct();
results.model        = ldem.mesh.summarizeModel(mesh, params);
results.material     = ldem.material.summarizeMaterial(barProps, params);
results.mesh         = mesh;
results.barProps     = barProps;
results.controlNodes = record.controlNodes;
results.reactions    = record.reactions;
results.energy       = record.energy;
results.trackedBar   = record.trackedBar;
results.snapshots    = writer.finish();
results.final        = finalState(state, mesh);

if writeFiles && any(options.Formats == "mat")
    ldem.io.saveResults(fullfile(options.OutputFolder, "results.mat"), results);
end
if options.Verbose
    fprintf('Done in %.1f s.\n', results.info.elapsedSeconds);
end
end

function final = finalState(state, mesh)
%FINALSTATE  Fields of the solver state worth keeping after the run.
final = struct( ...
    'step',         state.step, ...
    'time',         state.time, ...
    'displacement', state.displacement, ...
    'velocity',     state.velocity, ...
    'acceleration', state.acceleration, ...
    'kineticEnergy', ldem.solver.nodalKineticEnergy(state, mesh), ...
    'force',        state.force, ...
    'strain',       state.strain, ...
    'axialForce',   state.axialForce, ...
    'damage',       state.history);
end
