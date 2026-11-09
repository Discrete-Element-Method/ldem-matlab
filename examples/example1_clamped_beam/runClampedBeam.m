%% Example 1: beam clamped at both ends, loaded with a force at mid-span
% Model by Rodrigo (branch dev_rodrigo). A small beam of 5 x 5 x 50 modules
% of 1 mm is clamped at both ends and loaded at mid-span with a force that
% grows during 0.35 ms and then stays constant. The run simulates 2.8 ms
% (8000 steps).
%
% What it does
%   1. Reads the input file DATA0.DAT of this folder (test 103, see
%      ldem.scenarios.ClampedBeam) and adds what the file does not contain.
%   2. Runs the simulation, writing results.mat, ANSYS macro files and a VTK
%      series (open snapshots.pvd in ParaView).
%   3. Plots the force carried by the clamped ends, the vertical displacement
%      of the control nodes and the energies.
%
% The model has 3086 nodes and 18085 bars. Output goes to the folder
% "output" next to this script, or to "outputFolder" if that variable
% already exists in the workspace.

here = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(here));
addpath(fullfile(repoRoot, 'src'));
if ~exist('outputFolder', 'var')
    outputFolder = fullfile(here, 'output');
end

%% 1. Parameters
% fromFile reads DATA0.DAT. The random field that varies the critical strain
% of each bar is shared with the beam_102 example; trackedBar selects the bar
% whose strain and force are stored at every step.
params = ldem.Parameters.fromFile(fullfile(here, 'DATA0.DAT'), ...
    randomFieldFile = fullfile(repoRoot, 'examples', 'beam_102', 'arquivo_3lc_rnao_cv05'), ...
    trackedBar      = 14398);

fprintf('Clamped beam with %d nodes, %d steps.\n', params.nNodes, params.nSteps);

%% 2. Scenario
% Test 103 is registered for testId = 103, so runSimulation would find it by
% itself. It is created here to show the load: a force of
% forceRate*min(t, rampTime) newtons on each node of the loaded line. Change
% the values to try other loads, for example forceRate=2000.
scenario = ldem.scenarios.ClampedBeam(forceRate=1000, rampTime=0.00035);

%% 3. Run
results = ldem.runSimulation(params, ...
    Scenario     = scenario, ...
    OutputFolder = outputFolder, ...
    Formats      = ["mat" "ansys" "vtk"], ...
    Verbose      = true);

%% 4. Look at the results
counts = results.snapshots.barCounts(end, :);
fprintf('\nAfter %.3g s: %d intact, %d damaged and %d broken bars.\n', ...
    results.final.time, counts(1), counts(2), counts(3));
fprintf('Files written to %s\n', outputFolder);

fig = figure('Name', 'Force on the clamped ends');
ldem.post.plotReaction(results, axes(fig));

fig = figure('Name', 'Vertical displacement of the control nodes');
ax = axes(fig);
% The stored values are positions; subtract the initial ones to get displacements.
y0 = results.mesh.nodes0(params.controlNodes, 2).';
plot(ax, results.controlNodes.time, ...
    1e3 * (results.controlNodes.displacement(:, :, 2) - y0));
xlabel(ax, 'Time [s]');
ylabel(ax, 'Vertical displacement [mm]');
legend(ax, "node " + string(params.controlNodes), 'Location', 'best');
grid(ax, 'on');

fig = figure('Name', 'Energies');
ldem.post.plotEnergy(results, axes(fig));
