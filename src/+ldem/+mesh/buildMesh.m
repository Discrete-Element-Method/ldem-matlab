function mesh = buildMesh(params, scenario)
%BUILDMESH  Assemble the complete lattice model from the parameters.
%
%   mesh = ldem.mesh.buildMesh(params) builds nodes, supports, masses, bars
%   and bar geometry, using the scenario that matches params.testId.
%
%   mesh = ldem.mesh.buildMesh(params, scenario) uses the given scenario
%   object (a subclass of ldem.scenarios.Scenario).
%
%   Inputs:
%     params    ldem.Parameters.
%     scenario  (optional) ldem.scenarios.Scenario.
%
%   Output:
%     mesh  Struct with the fields
%       nodes0        nNodes-by-3 initial coordinates [m]
%       nGridNodes    number of grid nodes (they come first, then the centres)
%       fixed         nNodes-by-3 logical, true where the motion is fixed
%       mass          nNodes-by-1 lumped masses [kg]
%       bars          nBars-by-2 end-node numbers
%       barLength     nBars-by-1 initial lengths [m]
%       barCentres    nBars-by-3 midpoints [m]
%
%   Example:
%       params = ldem.Parameters(testId=101, nModules=[6 3 3]);
%       mesh = ldem.mesh.buildMesh(params);
%       fprintf("%d nodes, %d bars\n", size(mesh.nodes0, 1), size(mesh.bars, 1));
%
%   Legacy: the assembly stage of the main program (COORD, IMPERF, BOUND,
%   NODMASS, CONECTI, CALAUX).
%
%   See also ldem.mesh.buildNodes, ldem.mesh.buildBars, ldem.Parameters.

arguments
    params (1,1) ldem.Parameters
    scenario (1,1) ldem.scenarios.Scenario = ldem.scenarios.fromTestId(params.testId)
end

nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
if params.meshPerturbation.enabled
    nodes = ldem.mesh.perturbNodes(nodes, params.nModules, params.moduleLength, ...
        params.seed, params.meshPerturbation.cv);
end

mesh = struct();
mesh.nodes0     = nodes;
mesh.nGridNodes = prod(params.nModules);
mesh.fixed      = scenario.fixedDofs(nodes, params);
mesh.mass       = ldem.mesh.computeNodalMasses(params.nModules, ...
                      params.moduleLength, params.density);
mesh.bars       = ldem.mesh.buildBars(params.nModules);
[mesh.barLength, mesh.barCentres] = ldem.mesh.computeBarGeometry(nodes, mesh.bars);
end
