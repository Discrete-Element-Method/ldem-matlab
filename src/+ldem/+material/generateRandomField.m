function [field, info] = generateRandomField(barCentres, cv, correlationLength, seed)
%GENERATERANDOMFIELD  Spatially correlated Weibull field of critical-strain multipliers.
%
%   [field, info] = ldem.material.generateRandomField(barCentres, cv,
%   correlationLength, seed) returns one positive multiplier per bar, so
%   that bars close to each other get similar values. It replaces the
%   external script Aleat_novo4.m and its text file: the field is computed
%   in memory, in a fraction of a second, and ldem.runSimulation keeps it in
%   the results.
%
%   Method (the one of Aleat_novo4.m):
%
%     1. A regular grid of "poles" with spacing correlationLength covers
%        the bar centres, with one extra pole on each side.
%     2. Each pole gets an independent Weibull value with mean 1 and
%        coefficient of variation cv. The shape k solves
%            Gamma(1+2/k) / Gamma(1+1/k)^2 = 1 + cv^2
%        and the scale is 1/Gamma(1+1/k).
%     3. The value of a bar is the trilinear interpolation of the 8 poles
%        of the grid cell that contains its centre.
%
%   The interpolation averages neighbouring poles, so the coefficient of
%   variation of the bars (info.fieldCv) is somewhat smaller than cv; the
%   larger the correlation length compared with the bars, the closer the
%   values of neighbouring bars.
%
%   Inputs:
%     barCentres         nBars-by-3 bar midpoints [m] (mesh.barCentres).
%     cv                 Coefficient of variation of the pole values, > 0.
%     correlationLength  Pole spacing [m], a scalar or [lx ly lz].
%     seed               Seed of the random numbers (non-negative integer).
%
%   Outputs:
%     field  nBars-by-1 vector of positive multipliers.
%     info   Struct describing the field:
%              source             "generated"
%              cv                 cv requested
%              correlationLength  1-by-3 pole spacing [m]
%              seed               seed used
%              weibullShape       shape k of the pole distribution
%              weibullScale       scale of the pole distribution
%              nPoles             1-by-3 number of poles along x, y, z
%              fieldMean          mean of field
%              fieldCv            coefficient of variation of field
%
%   The random numbers come from a private stream (Mersenne Twister seeded
%   with seed), so the global random state is not touched and the same seed
%   always gives the same field. No toolbox is needed.
%
%   Differences with Aleat_novo4.m, see docs/known-issues/KNOWN_ISSUES.md:
%   the legacy script used the scale Gamma(1+1/k) (mean Gamma(1+1/k)^2,
%   below 1) and had two typos in the interpolation formula. Its rotation of
%   the pole grid (angles that were always zero) is not implemented.
%
%   Example:
%       params = ldem.Parameters(nModules=[6 3 3]);
%       mesh = ldem.mesh.buildMesh(params);
%       field = ldem.material.generateRandomField(mesh.barCentres, 0.05, ...
%           3 * params.moduleLength, 515);
%
%   Legacy: Aleat_novo4.m (outside the main program; it wrote the file read
%   by ldem.io.readRandomField).
%
%   See also ldem.material.buildBarProperties, ldem.io.readRandomField.

arguments
    barCentres (:,3) double {mustBeFinite}
    cv (1,1) double {mustBePositive, mustBeFinite}
    correlationLength (1,:) double {mustBePositive, mustBeFinite}
    seed (1,1) double {mustBeInteger, mustBeNonnegative}
end

if isscalar(correlationLength)
    correlationLength = repmat(correlationLength, 1, 3);
elseif numel(correlationLength) ~= 3
    error('ldem:material:badCorrelationLength', ...
        'correlationLength must be a scalar or have 3 values [lx ly lz], got %d values.', ...
        numel(correlationLength));
end

[shape, scale] = weibullForUnitMean(cv);

% Pole grid: one cell beyond the bars on each side, as in Aleat_novo4.m.
nBars = size(barCentres, 1);
first  = floor(min(barCentres, [], 1) ./ correlationLength) - 1;
last   = ceil(max(barCentres, [], 1) ./ correlationLength) + 1;
nPoles = last - first + 1;

% Weibull values by inverse transform: scale * (-log(U))^(1/shape).
stream = RandStream('mt19937ar', 'Seed', seed);
uniform = rand(stream, nPoles);
poles = scale * (-log(uniform)) .^ (1 / shape);

% Cell containing each bar centre and local coordinates t in [0, 1].
position = barCentres ./ correlationLength - first;     % in pole spacings
corner = floor(position);
corner = min(max(corner, 0), nPoles - 2);                % bars on the last pole
t = position - corner;
ix = corner(:, 1) + 1;  iy = corner(:, 2) + 1;  iz = corner(:, 3) + 1;
tx = t(:, 1);  ty = t(:, 2);  tz = t(:, 3);

pole = @(dx, dy, dz) poles(sub2ind(nPoles, ix + dx, iy + dy, iz + dz));
field = zeros(nBars, 1);
for dx = 0:1
    wx = (1 - dx) * (1 - tx) + dx * tx;
    for dy = 0:1
        wy = (1 - dy) * (1 - ty) + dy * ty;
        for dz = 0:1
            wz = (1 - dz) * (1 - tz) + dz * tz;
            field = field + wx .* wy .* wz .* pole(dx, dy, dz);
        end
    end
end

info = struct( ...
    'source',            "generated", ...
    'cv',                cv, ...
    'correlationLength', correlationLength, ...
    'seed',              seed, ...
    'weibullShape',      shape, ...
    'weibullScale',      scale, ...
    'nPoles',            nPoles, ...
    'fieldMean',         mean(field), ...
    'fieldCv',           std(field) / mean(field));
end

function [shape, scale] = weibullForUnitMean(cv)
%WEIBULLFORUNITMEAN  Weibull shape and scale with mean 1 and the given CV.
%   The squared CV of a Weibull distribution is
%   Gamma(1+2/k)/Gamma(1+1/k)^2 - 1, which decreases with k.
target = log1p(cv^2);
excess = @(k) gammaln(1 + 2 ./ k) - 2 * gammaln(1 + 1 ./ k) - target;
bounds = [0.02 1e5];
if excess(bounds(2)) > 0
    error('ldem:material:randomFieldCvTooSmall', ...
        'cv = %g is too small for a Weibull field; use at least 1e-4.', cv);
end
if excess(bounds(1)) < 0
    error('ldem:material:randomFieldCvTooLarge', ...
        'cv = %g is too large for a Weibull field.', cv);
end
shape = fzero(excess, bounds);
scale = 1 / gamma(1 + 1 / shape);
end
