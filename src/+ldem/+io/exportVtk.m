function exportVtk(path, mesh, state)
%EXPORTVTK  Write the current state as a VTK unstructured grid (.vtu).
%
%   ldem.io.exportVtk(path, mesh, state) writes an XML VTK file that opens in
%   ParaView (or any VTK reader). The lattice is drawn as line cells.
%
%   Points are the current node positions. Data stored:
%
%     Point data   displacement (current minus initial position [m]) and
%                  velocity [m/s], both 3-component vectors.
%     Cell data    damageState (0 intact, 1 damaged, 2 broken), strain,
%                  axialForce [N] (tension positive) and barType (1 grid
%                  edge, 2 centre bar, 3 diagonal).
%
%   The file is ASCII so that it can be inspected and diffed. To follow a
%   whole simulation, ldem.io.SnapshotWriter writes one file per snapshot
%   and a .pvd collection that ParaView opens as a time series.
%
%   Inputs:
%     path   Path of the .vtu file to create.
%     mesh   Struct from ldem.mesh.buildMesh.
%     state  Solver state.
%
%   Errors:
%     ldem:io:cannotOpenFile  The file cannot be created.
%
%   Example:
%       ldem.io.exportVtk("step100.vtu", mesh, state);
%
%   See also ldem.io.exportAnsys, ldem.io.SnapshotWriter, ldem.io.writePvd.

arguments
    path (1,1) string
    mesh (1,1) struct
    state (1,1) struct
end

fid = fopen(path, 'w');
if fid == -1
    error('ldem:io:cannotOpenFile', 'Cannot create the VTK file "%s".', path);
end
closer = onCleanup(@() fclose(fid));

nNodes = size(state.displacement, 1);
nBars  = size(mesh.bars, 1);

damageState = 2 * ones(nBars, 1);                         % broken
damageState(state.history.isUnbroken) = 1;                % damaged
damageState(state.history.isUndamaged) = 0;               % intact

fprintf(fid, '<?xml version="1.0"?>\n');
fprintf(fid, '<VTKFile type="UnstructuredGrid" version="0.1" byte_order="LittleEndian">\n');
fprintf(fid, '<UnstructuredGrid>\n');
fprintf(fid, '<Piece NumberOfPoints="%d" NumberOfCells="%d">\n', nNodes, nBars);

fprintf(fid, '<PointData Vectors="displacement">\n');
writeArray(fid, 'Float64', 'displacement', 3, '%.9g', state.displacement - mesh.nodes0);
writeArray(fid, 'Float64', 'velocity', 3, '%.9g', state.velocity);
fprintf(fid, '</PointData>\n');

fprintf(fid, '<CellData Scalars="damageState">\n');
writeArray(fid, 'Int32',   'damageState', 1, '%d', damageState);
writeArray(fid, 'Float64', 'strain', 1, '%.9g', state.strain);
writeArray(fid, 'Float64', 'axialForce', 1, '%.9g', state.axialForce);
if isfield(mesh, 'barType')
    writeArray(fid, 'Int32', 'barType', 1, '%d', mesh.barType);
end
fprintf(fid, '</CellData>\n');

fprintf(fid, '<Points>\n');
writeArray(fid, 'Float64', 'position', 3, '%.9g', state.displacement);
fprintf(fid, '</Points>\n');

fprintf(fid, '<Cells>\n');
writeArray(fid, 'Int32', 'connectivity', 1, '%d', mesh.bars - 1);      % VTK counts from 0
writeArray(fid, 'Int32', 'offsets', 1, '%d', 2 * (1:nBars).');
writeArray(fid, 'UInt8', 'types', 1, '%d', 3 * ones(nBars, 1));        % 3 = VTK_LINE
fprintf(fid, '</Cells>\n');

fprintf(fid, '</Piece>\n');
fprintf(fid, '</UnstructuredGrid>\n');
fprintf(fid, '</VTKFile>\n');
end

function writeArray(fid, type, name, nComponents, format, data)
%WRITEARRAY  Write one ASCII <DataArray>; rows of data are the tuples.
fprintf(fid, '<DataArray type="%s" Name="%s" NumberOfComponents="%d" format="ascii">\n', ...
    type, name, nComponents);
rowFormat = [strjoin(repmat({format}, 1, nComponents), ' ') '\n'];
fprintf(fid, rowFormat, data.');
fprintf(fid, '</DataArray>\n');
end
