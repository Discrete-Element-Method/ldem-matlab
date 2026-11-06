function writeTextFile(path, lines)
%WRITETEXTFILE  Write a text file from a list of lines (for the tests).
%
%   writeTextFile(path, lines) writes the lines, separated by line feeds,
%   creating the folder if needed.
%
%   Inputs:
%     path   Full path of the file.
%     lines  String array or cell array of lines.
%
%   See also writeDataFile.

arguments
    path (1,1) string
    lines (:,1) string
end

folder = fileparts(path);
if strlength(folder) > 0 && ~isfolder(folder)
    mkdir(folder);
end
fid = fopen(path, 'w');
if fid == -1
    error('ldem:tools:cannotOpenFile', 'Cannot create "%s".', path);
end
fprintf(fid, '%s\n', lines);
fclose(fid);
end
