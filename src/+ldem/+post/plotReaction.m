function ax = plotReaction(results, ax)
%PLOTREACTION  Plot the reaction force of the test versus time.
%
%   ax = ldem.post.plotReaction(results) draws the components of the
%   reaction force that are defined for the test of the simulation (for the
%   beam test only the vertical one) in the current axes.
%
%   ax = ldem.post.plotReaction(results, ax) draws in the given axes.
%
%   Inputs:
%     results  Struct returned by ldem.runSimulation.
%     ax       (optional) Axes object.
%
%   Output:
%     ax  The axes used.
%
%   Errors:
%     ldem:post:noData  The test defines no reaction, or none was stored
%                       (set params.output.controlNodesEvery > 0).
%
%   Example:
%       results = ldem.runSimulation(ldem.Parameters(testId=102, nModules=[70 4 3]));
%       ldem.post.plotReaction(results);
%
%   See also ldem.post.plotEnergy, ldem.runSimulation.

arguments
    results (1,1) struct
    ax = []
end

r = results.reactions;
defined = ~all(isnan(r.force), 1) & any(r.force ~= 0, 1);
if isempty(r.time) || ~any(defined)
    error('ldem:post:noData', ...
        ['The simulation has no reaction force: the test does not define one or ' ...
         'params.output.controlNodesEvery is 0.']);
end
if isempty(ax)
    ax = gca;
end

names = ["Rx", "Ry", "Rz"];
plot(ax, r.time, r.force(:, defined), 'LineWidth', 1.2);
legend(ax, names(defined), 'Location', 'best');
xlabel(ax, 'Time [s]');
ylabel(ax, 'Reaction force [N]');
title(ax, 'Reaction force');
grid(ax, 'on');
end
