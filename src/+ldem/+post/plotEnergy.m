function ax = plotEnergy(results, ax)
%PLOTENERGY  Plot the energies of a simulation versus time.
%
%   ax = ldem.post.plotEnergy(results) draws the kinetic, elastic, damage and
%   damping energies, and their sum, in the current axes (a new figure if
%   there are none).
%
%   ax = ldem.post.plotEnergy(results, ax) draws in the given axes.
%
%   Inputs:
%     results  Struct returned by ldem.runSimulation.
%     ax       (optional) Axes object.
%
%   Output:
%     ax  The axes used.
%
%   Errors:
%     ldem:post:noData  The results contain no energy history (set
%                       params.output.energyEvery > 0).
%
%   Example:
%       results = ldem.runSimulation(ldem.Parameters());
%       ldem.post.plotEnergy(results);
%
%   See also ldem.post.plotReaction, ldem.runSimulation.

arguments
    results (1,1) struct
    ax = []
end

e = results.energy;
if isempty(e.time)
    error('ldem:post:noData', ...
        'The results contain no energy history. Set params.output.energyEvery to a positive number.');
end
if isempty(ax)
    ax = gca;
end

plot(ax, e.time, e.kinetic, e.time, e.elastic, e.time, e.damage, e.time, e.damping, ...
    e.time, e.internal, 'k--', 'LineWidth', 1.2);
legend(ax, 'Kinetic', 'Elastic', 'Damage', 'Damping', 'Total', 'Location', 'best');
xlabel(ax, 'Time [s]');
ylabel(ax, 'Energy [J]');
title(ax, 'Energies');
grid(ax, 'on');
end
