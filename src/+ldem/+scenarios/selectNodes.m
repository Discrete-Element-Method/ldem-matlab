function mask = selectNodes(selector, params, nodes)
%SELECTNODES  Nodes picked by the selector of a [[support]] or [[load]] block.
%
%   mask = ldem.scenarios.selectNodes(selector, params) returns an nNodes-by-1
%   logical vector. The selector is a struct with the fields nodes, ids, x, y
%   and z:
%
%     nodes  "all", "grid" (corners of the modules) or "centre" (middle of each module).
%     ids    Row of node numbers; empty for no restriction.
%     x      A range from ldem.scenarios.parseCoordinate, or [] for no restriction (same for y and z).
%
%   Positions are in modules, within 0.01 modules.
%
%   A node is selected when it passes every restriction. The positions are
%   those of the regular lattice, even when the mesh is perturbed, so a
%   selection does not depend on the random displacement of the nodes. In the
%   lattice the grid nodes are at integer positions and the centre nodes at
%   half-integer ones, for example the first layer of centre nodes along z is
%   z = 0.5.
%
%   Inputs:
%     selector  Struct as above.
%     params    ldem.Parameters (nModules and moduleLength).
%     nodes     Optional nNodes-by-3 coordinates of the regular lattice [m] (default: ldem.mesh.buildNodes).
%
%   Output:
%     mask  nNodes-by-1 logical.
%
%   Example:
%       sel = ldem.scenarios.Declarative.makeSelector(nodes="centre", x=0.5);
%       mask = ldem.scenarios.selectNodes(sel, ldem.Parameters());
%
%   See also ldem.scenarios.Declarative, ldem.scenarios.parseCoordinate.

arguments
    selector (1,1) struct
    params (1,1) ldem.Parameters
    nodes = []
end

if isempty(nodes)
    nodes = ldem.mesh.buildNodes(params.nModules, params.moduleLength);
end
nNodes = size(nodes, 1);
nGrid = prod(params.nModules);

mask = true(nNodes, 1);
switch selector.nodes
    case "grid"
        mask(nGrid+1:end) = false;
    case "centre"
        mask(1:nGrid) = false;
end
if ~isempty(selector.ids)
    mask = mask & ismember((1:nNodes).', selector.ids);
end

extent = params.nModules - 1;           % length of the prism in modules
tolerance = 0.01;
axisNames = ["x" "y" "z"];
for k = 1:3
    range = selector.(axisNames(k));
    if isempty(range)
        continue
    end
    lo = resolve(range.lo, extent(k));
    hi = resolve(range.hi, extent(k));
    position = nodes(:, k) / params.moduleLength;
    mask = mask & position >= lo - tolerance & position <= hi + tolerance;
end
end

function value = resolve(spec, extent)
switch spec.base
    case "min"
        value = spec.offset;
    case "max"
        value = extent + spec.offset;
    case "mid"
        value = extent / 2 + spec.offset;
    otherwise
        value = spec.offset;
end
end
