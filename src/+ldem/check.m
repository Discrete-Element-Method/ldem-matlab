function report = check(casePath)
%CHECK  Dry run of a case file: validate it and report the model without simulating.
%
%   ldem.check(casePath) reads the case file, builds the lattice (without
%   integrating in time) and prints what the simulation would do: size of the
%   model, stability margin of the time step, where each "at" control node
%   landed, the state of the random-field file, and the memory that the
%   snapshots will need.
%
%   report = ldem.check(casePath) returns the same information in a struct
%   and prints nothing.
%
%   Input:
%     casePath  Path of the case file (.ldem or .json).
%
%   Output:
%     report  Struct with the fields
%               params, scenario   As returned by ldem.io.readCase.
%               model              ldem.mesh.summarizeModel of the lattice.
%               timeStepRatio      dt divided by the critical time step.
%               nSteps             Number of time steps.
%               nSnapshots         Snapshots taken (0 if never).
%               snapshotMemoryMB   Memory of the snapshots kept in results.
%               randomField        Text: "none", "generated" or the state of the file.
%               controlNodes       Struct array: number, name and position
%                                  [x y z] in modules.
%
%   Errors:
%     The ones of ldem.io.readCase, and ldem:scenarios:noNodesSelected when
%     the scenario selects no node of the lattice.
%
%   Example:
%       ldem.check("examples/example1_clamped_beam/case.ldem")
%
%   See also ldem.run, ldem.io.readCase.

arguments
    casePath (1,1) string
end

c = ldem.io.readCase(casePath);
p = c.params;
mesh = ldem.mesh.buildMesh(p, c.scenario);
model = ldem.mesh.summarizeModel(mesh, p);

report = struct();
report.params = p;
report.scenario = c.scenario;
report.model = model;
report.timeStepRatio = p.dt / p.criticalTimeStep;
report.nSteps = p.nSteps;

every = p.output.snapshotEvery;
if every > 0
    report.nSnapshots = floor(p.nSteps / every) + 1;
else
    report.nSnapshots = 0;
end
bytesPerSnapshot = 4 * 3 * model.nNodes + model.nBars + 4 * model.nNodes;
report.snapshotMemoryMB = report.nSnapshots * bytesPerSnapshot / 2^20;

if strlength(p.randomFieldFile) > 0
    try
        ldem.io.readRandomField(p.randomFieldFile, model.nBars);
        report.randomField = "file OK: " + p.randomFieldFile + " has at least " + string(model.nBars) + " values";
    catch err
        report.randomField = "file PROBLEM: " + string(err.message);
    end
elseif p.randomFieldCv > 0
    report.randomField = "generated in memory (cv " + string(p.randomFieldCv) + ")";
else
    report.randomField = "none";
end

nodes = mesh.nodes0 / p.moduleLength;
report.controlNodes = struct('number', num2cell(p.controlNodes), ...
    'name', cellstr(c.info.controlNodeNames), ...
    'position', num2cell(nodes(p.controlNodes, :), 2).');

if nargout == 0
    printReport(report, c, casePath);
    clear report
end
end

function printReport(report, c, casePath)
p = report.params;
m = report.model;
fprintf('Case file      %s\n', casePath);
if strlength(c.info.title) > 0
    fprintf('Title          %s\n', c.info.title);
end
fprintf('Scenario       %s (testId %d)\n', class(report.scenario), p.testId);
fprintf('Model          %d x %d x %d modules of %g m, %d nodes, %d bars, mass %.4g kg\n', ...
    m.nModules, p.moduleLength, m.nNodes, m.nBars, m.totalMass);
fprintf('Time           %d steps of %g s (%.0f %% of the critical step %g s), %g s in total\n', ...
    report.nSteps, p.dt, 100 * report.timeStepRatio, p.criticalTimeStep, p.totalTime);
fprintf('Random field   %s\n', report.randomField);
fprintf('Snapshots      %d (about %.1f MB kept in results)\n', ...
    report.nSnapshots, report.snapshotMemoryMB);
for node = report.controlNodes
    fprintf('Control node   %-12s number %d at [%g %g %g] modules\n', ...
        node.name, node.number, node.position);
end
for note = c.info.nodeNotes.'
    fprintf('Note           %s\n', note);
end
end
