function [barLength, barCentres] = computeBarGeometry(nodes, bars)
%COMPUTEBARGEOMETRY  Length and midpoint of every bar.
%
%   [barLength, barCentres] = ldem.mesh.computeBarGeometry(nodes, bars)
%   returns the initial length [m] and the coordinates of the midpoint of
%   each bar.
%
%   Inputs:
%     nodes  nNodes-by-3 coordinates.
%     bars   nBars-by-2 node numbers, from ldem.mesh.buildBars.
%
%   Outputs:
%     barLength   nBars-by-1 vector of lengths [m].
%     barCentres  nBars-by-3 matrix of midpoints [x y z].
%
%   Errors:
%     ldem:mesh:zeroLengthBar  A bar has zero length (coincident nodes).
%
%   Example:
%       nodes = ldem.mesh.buildNodes([2 2 2], 1);
%       bars  = ldem.mesh.buildBars([2 2 2]);
%       [len, mid] = ldem.mesh.computeBarGeometry(nodes, bars);
%
%   Legacy: CALAUX.
%
%   See also ldem.mesh.buildBars.

arguments
    nodes (:,3) double
    bars (:,2) double {mustBeInteger, mustBePositive}
end

if max(bars, [], 'all') > size(nodes, 1)
    error('ldem:mesh:badConnectivity', ...
        'bars refers to node %d but there are only %d nodes.', ...
        max(bars, [], 'all'), size(nodes, 1));
end

first  = nodes(bars(:, 1), :);
second = nodes(bars(:, 2), :);
delta  = second - first;

barLength  = sqrt(delta(:, 1).^2 + delta(:, 2).^2 + delta(:, 3).^2);
barCentres = (second + first) / 2.0;

if any(barLength == 0)
    error('ldem:mesh:zeroLengthBar', ...
        '%d bar(s) have zero length (first one: bar %d).', ...
        nnz(barLength == 0), find(barLength == 0, 1));
end
end
