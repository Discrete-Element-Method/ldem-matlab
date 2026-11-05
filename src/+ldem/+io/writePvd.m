function writePvd(path, times, files)
%WRITEPVD  Write a ParaView collection (.pvd) that groups VTK files in time.
%
%   ldem.io.writePvd(path, times, files) creates a small XML file that lists
%   the given .vtu files with their simulation times. Opening it in ParaView
%   loads the whole series and enables the time slider.
%
%   File names are stored relative to the .pvd file, so the folder can be
%   moved or zipped.
%
%   Inputs:
%     path   Path of the .pvd file to create.
%     times  Simulation times [s], one per file.
%     files  File names of the .vtu files (same folder as the .pvd).
%
%   Errors:
%     ldem:io:cannotOpenFile  The file cannot be created.
%
%   Example:
%       ldem.io.writePvd("series.pvd", [0 1e-4], ["a.vtu" "b.vtu"]);
%
%   See also ldem.io.exportVtk, ldem.io.SnapshotWriter.

arguments
    path (1,1) string
    times (:,1) double
    files (:,1) string
end

if numel(times) ~= numel(files)
    error('ldem:io:sizeMismatch', ...
        'times (%d) and files (%d) must have the same length.', numel(times), numel(files));
end

fid = fopen(path, 'w');
if fid == -1
    error('ldem:io:cannotOpenFile', 'Cannot create the PVD file "%s".', path);
end
closer = onCleanup(@() fclose(fid));

fprintf(fid, '<?xml version="1.0"?>\n');
fprintf(fid, '<VTKFile type="Collection" version="0.1" byte_order="LittleEndian">\n');
fprintf(fid, '<Collection>\n');
for k = 1:numel(files)
    fprintf(fid, '<DataSet timestep="%.12g" group="" part="0" file="%s"/>\n', times(k), files(k));
end
fprintf(fid, '</Collection>\n');
fprintf(fid, '</VTKFile>\n');
end
