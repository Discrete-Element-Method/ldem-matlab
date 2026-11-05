function counts = exportAnsys(path, mesh, state)
%EXPORTANSYS  Write an ANSYS macro file (.mac) with the current state.
%
%   counts = ldem.io.exportAnsys(path, mesh, state) writes a text file that
%   ANSYS can read to draw the deformed lattice. It contains the node
%   positions, the bars coloured by damage state, and the constraints.
%
%   The bars are written as elements of three types:
%
%     TYPE 1  intact bars (never softened)
%     TYPE 2  damaged bars (softening but not broken)
%     TYPE 5  broken bars
%
%   The element type numbers are the ones used by the colour commands of the
%   file, so the damaged zone is easy to see.
%
%   The constraint section lists the degrees of freedom held by the scenario
%   (mesh.fixed). Node positions are written in single precision, like the
%   legacy code.
%
%   Inputs:
%     path   Path of the file to create.
%     mesh   Struct from ldem.mesh.buildMesh.
%     state  Solver state (current displacement and damage state).
%
%   Output:
%     counts  Struct with the number of bars in each state: intact, damaged
%             and broken.
%
%   Errors:
%     ldem:io:cannotOpenFile  The file cannot be created.
%
%   Differences from the legacy file: the line "ET,IFILE,4" (an invalid
%   command caused by a translation slip) is written as "ET,3,4"; the
%   constraints are written for every scenario, not only for TEST 102; and
%   the hardcoded "applied loads" of TEST 102 are not written (they did not
%   match any node of the beam).
%
%   Example:
%       counts = ldem.io.exportAnsys("step100.mac", mesh, state);
%
%   Legacy: ANSYS.
%
%   See also ldem.io.exportVtk, ldem.io.SnapshotWriter.

arguments
    path (1,1) string
    mesh (1,1) struct
    state (1,1) struct
end

fid = fopen(path, 'w');
if fid == -1
    error('ldem:io:cannotOpenFile', 'Cannot create the ANSYS file "%s".', path);
end
closer = onCleanup(@() fclose(fid));

nNodes = size(state.displacement, 1);
nBars  = size(mesh.bars, 1);

fprintf(fid, '!ARQUIVO NO TEMPO = %g\n', state.time);
fprintf(fid, '/PREP7\n');
fprintf(fid, '/TITLE, TEMPO =%g\n', state.time);
for typeNumber = [1 2 3 4 5 6 8 9 10 11 12]
    fprintf(fid, 'ET,%d,4\n', typeNumber);
end
fprintf(fid, 'MP,EX,1,2E10\n');
fprintf(fid, 'MP,PRXY,1,0.25\n');
fprintf(fid, 'MP,DENS,1,2500\n');
fprintf(fid, 'R,1,0.13,0.0014,0.36\n');
fprintf(fid, '\n');

% Node coordinates, in single precision.
fprintf(fid, '!COORDENADAS NODAIS\n');
coordinates = double(single(state.displacement));
fprintf(fid, 'N,%d,%g,%g,%g\n', [(1:nNodes); coordinates.']);
fprintf(fid, '\n');

% Bars as elements, typed by damage state.
fprintf(fid, '!CONECTIVIDADES DOS ELEMENTOS\n');
elementType = 5 * ones(nBars, 1);                         % broken
elementType(state.history.isUnbroken) = 2;                % damaged
elementType(state.history.isUndamaged) = 1;               % intact
fprintf(fid, 'TYPE,%d\nE,%d,%d,!EL%d\n', [elementType.'; mesh.bars.'; (1:nBars)]);
fprintf(fid, '\n');

counts = struct('intact', nnz(elementType == 1), ...
                'damaged', nnz(elementType == 2), ...
                'broken', nnz(elementType == 5));

% Colours.
fprintf(fid, '!CORES DOS ELEMENTOS\n');
colours = {1, 'GCYA'; 2, 'ORAN'; 5, 'RED'; 6, 'GREE'};
for k = 1:size(colours, 1)
    fprintf(fid, 'ESEL,S,TYPE,,%d\n', colours{k, 1});
    fprintf(fid, '/COLOR,ELEM,%s\n', colours{k, 2});
    fprintf(fid, '/PNUM,TYPE,0\n');
    fprintf(fid, '/NUMBER,1\n');
    fprintf(fid, 'ESEL,ALL\n');
end

% Constraints.
fprintf(fid, '!CONDIÇÕES DE CONTORNO\n');
directions = ["UX", "UY", "UZ"];
for node = find(any(mesh.fixed, 2)).'
    for direction = find(mesh.fixed(node, :))
        fprintf(fid, 'D,%d,%s\n', node, directions(direction));
    end
end
fprintf(fid, '\n');

fprintf(fid, '!CARGAS APLICADAS\n');
fprintf(fid, '\n');

fprintf(fid, '/VIEW,1,0,-1,0\n');
fprintf(fid, 'EPLOT\n');
fprintf(fid, '\n');

fprintf(fid, '!ESTADO DAS BARRAS\n');
fprintf(fid, '!BARRAS INTACTAS =    %d\n', counts.intact);
fprintf(fid, '!BARRAS DANIFICADAS = %d\n', counts.damaged);
fprintf(fid, '!BARRAS ROMPIDAS =    %d\n', counts.broken);
fprintf(fid, '\n');
end
