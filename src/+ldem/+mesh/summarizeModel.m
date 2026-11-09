function summary = summarizeModel(mesh, params)
%SUMMARIZEMODEL  Size and mass of the model, for the results file.
%
%   summary = ldem.mesh.summarizeModel(mesh, params) collects the counts that
%   describe the lattice, so that a results file documents the model that was
%   simulated.
%
%   Fields of summary:
%
%     testId          Test number.
%     nModules        [Mx My Mz], number of cubic modules along x, y and z.
%     moduleLength    Edge of a module [m].
%     nNodes          Total number of nodes.
%     nGridNodes      Nodes at the corners of the modules.
%     nCentreNodes    Nodes at the centre of the modules.
%     nBars           Total number of bars.
%     nGridEdges      Bars along the edges of the modules.
%     nCentreBars     Bars between neighbouring centre nodes.
%     nDiagonals      Bars from a centre node to a corner.
%     nFixedDofs      Number of degrees of freedom held by the scenario.
%     totalMass       Sum of the nodal masses [kg].
%     prismVolume     Volume of the prism [m^3].
%     controlNodes    Control nodes of the output.
%
%   Inputs:
%     mesh    Struct from ldem.mesh.buildMesh.
%     params  ldem.Parameters.
%
%   Output:
%     summary  Struct with the fields above.
%
%   Example:
%       model = ldem.mesh.summarizeModel(mesh, params);
%
%   Legacy: the geometry and counting block of WRICON.
%
%   See also ldem.mesh.buildMesh, ldem.material.summarizeMaterial.

arguments
    mesh (1,1) struct
    params (1,1) ldem.Parameters
end

modules = params.nModules - 1;

summary = struct();
summary.testId       = params.testId;
summary.nModules     = modules;
summary.moduleLength = params.moduleLength;
summary.nNodes       = size(mesh.nodes0, 1);
summary.nGridNodes   = mesh.nGridNodes;
summary.nCentreNodes = size(mesh.nodes0, 1) - mesh.nGridNodes;
summary.nBars        = size(mesh.bars, 1);
summary.nGridEdges   = nnz(mesh.barType == 1);
summary.nCentreBars  = nnz(mesh.barType == 2);
summary.nDiagonals   = nnz(mesh.barType == 3);
summary.nFixedDofs   = nnz(mesh.fixed);
summary.totalMass    = sum(mesh.mass);
summary.prismVolume  = prod(modules) * params.moduleLength^3;
summary.controlNodes = params.controlNodes;
end
