%% Bending test (TEST 102) on the 101x41x21-module beam of the paper
% Reads the case file case.ldem of this folder and runs the beam.
%
% The full beam has about 167,000 nodes and 1.1 million bars. A full run is
% 150,000 steps (see the time estimate below), so this script runs only the first
% "nStepsDemo" steps. Increase it (or remove the totalTime override) for the
% real simulation. Measured on a laptop: about 20 s to build the model and 0.5 s
% per step, so the 150,000 steps of the real run need roughly 20 hours.
%
% Output goes to the folder "output" next to this script, or to
% "outputFolder" if that variable already exists in the workspace.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'src'));
if ~exist('outputFolder', 'var')
    outputFolder = fullfile(here, 'output');
end
nStepsDemo = 50;

%% 1. Read the case file
% readCase returns the parameters and the scenario; the demo replaces the
% simulated time and stores the snapshots at the end only.
c = ldem.io.readCase(fullfile(here, 'case.ldem'));
params = c.params;
params.totalTime = nStepsDemo * params.dt;
params.output.snapshotEvery = nStepsDemo;
params.output.controlNodesEvery = 5;
params.output.energyEvery = 5;

fprintf('Beam with %d nodes, %d steps.\n', params.nNodes, params.nSteps);

%% 2. Run
results = ldem.runSimulation(params, ...
    Scenario     = c.scenario, ...
    OutputFolder = outputFolder, ...
    Formats      = ["mat" "vtk"], ...
    Verbose      = true);

%% 3. Plot
fig = figure('Name', 'Reaction force');
ldem.post.plotReaction(results, axes(fig));
