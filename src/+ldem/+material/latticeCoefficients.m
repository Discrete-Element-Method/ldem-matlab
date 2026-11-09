function [delta, alpha] = latticeCoefficients(poissonRatio)
%LATTICECOEFFICIENTS  Coefficients that make the lattice equivalent to a continuum.
%
%   [delta, alpha] = ldem.material.latticeCoefficients(poissonRatio)
%   returns the two coefficients of the Nayfeh-Hefzy equivalence between the
%   cubic lattice (edges plus diagonals) and an isotropic elastic continuum
%   with the given Poisson's ratio:
%
%       delta = 9*nu / (4 - 8*nu)
%       alpha = (9 + 8*delta) / (18 + 24*delta)
%
%   alpha scales the stiffness of the edge bars, EA = alpha*E*L^2, and delta
%   scales the diagonals relative to the edges.
%
%   Input:
%     poissonRatio  Poisson's ratio, 0 <= nu < 0.5.
%
%   Outputs:
%     delta, alpha  Dimensionless coefficients.
%
%   Example:
%       [delta, alpha] = ldem.material.latticeCoefficients(0.25);
%       % delta = 1.125, alpha = 0.4
%
%   Legacy: first lines of NAYFES0.
%
%   See also ldem.material.computeBarStiffness.

arguments
    poissonRatio (1,1) double {mustBeNonnegative, mustBeFinite}
end

if poissonRatio >= 0.5
    error('ldem:params:badPoissonRatio', ...
        'poissonRatio must be smaller than 0.5, got %g.', poissonRatio);
end

delta = 9.0 * poissonRatio / (4.0 - 8.0 * poissonRatio);
alpha = (9.0 + 8.0 * delta) / (18.0 + 24.0 * delta);
end
