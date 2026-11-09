%% Uniaxial test (TEST 101) on a small prism
% This script runs a complete simulation in a few seconds and writes every
% kind of output file. It is the best place to start: copy it and change the
% parameters.
%
% What it does
%   1. Describes the model with ldem.Parameters (a 5x2x2-module prism).
%   2. Runs it with ldem.runSimulation, writing results.mat, ANSYS macro files
%      and a VTK series (open snapshots.pvd in ParaView).
%   3. Plots the energies.
%
% Output goes to the folder "output" next to this script, or to
% "outputFolder" if that variable already exists in the workspace.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'src'));
if ~exist('outputFolder', 'var')
    outputFolder = fullfile(here, 'output');
end

%% 1. Parameters
% The fracture energy is low on purpose so that bars soften and break within
% the 1000 steps (0.2 ms) of the run.
params = ldem.Parameters( ...
    testId        = 101, ...          % prism loaded along x
    nModules      = [6 3 3], ...      % nodes along x, y, z
    moduleLength  = 0.003, ...        % [m]
    dt            = 2e-7, ...         % [s]
    totalTime     = 2e-4, ...         % [s] -> 1000 steps
    fractureEnergy = 0.1, ...         % [N/m]
    controlNodes  = [1 2], ...
    output        = struct( ...
        'snapshotEvery',     250, ... % ANSYS/VTK file every 250 steps
        'controlNodesEvery', 10, ...  % control nodes and reactions
        'energyEvery',       10, ...  % energies
        'trackedBarEvery',   0));     % tracked bar off

%% 2. Run
results = ldem.runSimulation(params, ...
    OutputFolder = outputFolder, ...
    Formats      = ["mat" "ansys" "vtk"], ...
    Verbose      = true);

%% 3. Look at the results
counts = results.snapshots.barCounts(end, :);
fprintf('\nAfter %.2g s: %d intact, %d damaged and %d broken bars.\n', ...
    results.final.time, counts(1), counts(2), counts(3));
fprintf('Files written to %s\n', outputFolder);

fig = figure('Name', 'Energies');
ldem.post.plotEnergy(results, axes(fig));
