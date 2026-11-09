function stiffness = computeBarStiffness(mesh, params)
%COMPUTEBARSTIFFNESS  Axial stiffness of every bar of the lattice.
%
%   stiffness = ldem.material.computeBarStiffness(mesh, params) returns the
%   stiffness E1 [N] of each bar, defined so that the axial force is
%   force = stiffness * strain.
%
%   The reference value of an edge bar is  EA = alpha*E*L^2  (L = bar
%   length, see ldem.material.latticeCoefficients). It is modified by the
%   type of bar (ldem.mesh.buildBars):
%
%     * Grid edges inside the prism: EA.
%     * Grid edges on a face of the prism: EA/2 (they are shared by fewer
%       modules); on an edge of the prism: EA/4.
%     * Centre-to-centre bars: EA.
%     * Diagonals: EA * 2*delta*(4/3)/sqrt(3).
%
%   Inputs:
%     mesh    Struct from ldem.mesh.buildMesh.
%     params  ldem.Parameters (uses youngModulus and poissonRatio).
%
%   mesh must contain barLength, barType and barBoundaryFaces.
%
%   Output:
%     stiffness  nBars-by-1 vector [N].
%
%   Example:
%       params = ldem.Parameters();
%       mesh = ldem.mesh.buildMesh(params);
%       E1 = ldem.material.computeBarStiffness(mesh, params);
%
%   Legacy: NAYFES0 (ENR, EDG) and RMEC, RMECEX, RMECIN, RMECDI, DEFEP (E1).
%
%   See also ldem.material.latticeCoefficients, ldem.material.buildBarProperties.

arguments
    mesh (1,1) struct
    params (1,1) ldem.Parameters
end

[delta, alpha] = ldem.material.latticeCoefficients(params.poissonRatio);

edgeStiffness     = (params.youngModulus .* (mesh.barLength .^ 2)) .* alpha;
diagonalFactor    = (2.0 * delta * (4.0 / 3.0)) / sqrt(3.0);
diagonalStiffness = edgeStiffness * diagonalFactor;

% Reduction of the grid edges that lie on the surface of the prism:
% 0 faces -> 1, 1 face -> 1/2, 2 faces (an edge of the prism) -> 1/4.
reduction = ones(size(edgeStiffness));
reduction(mesh.barBoundaryFaces == 1)  = 0.50;
reduction(mesh.barBoundaryFaces >= 2)  = 0.25;

stiffness = edgeStiffness .* reduction;                       % grid edges
stiffness(mesh.barType == 2) = edgeStiffness(mesh.barType == 2);   % centre-to-centre
stiffness(mesh.barType == 3) = diagonalStiffness(mesh.barType == 3);   % diagonals
end
