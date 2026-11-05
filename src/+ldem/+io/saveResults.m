function saveResults(path, results)
%SAVERESULTS  Save the results struct of a simulation to a MAT-file.
%
%   ldem.io.saveResults(path, results) stores the struct in a MAT-file that
%   is loaded with
%
%       data = load(path);
%       results = data.results;
%
%   The file uses the v7.3 format, which supports variables larger than 2 GB
%   and is readable from Python (h5py) and other languages. The results
%   contain only plain structs and arrays, so no ldem class is needed to load
%   them.
%
%   Inputs:
%     path     Path of the .mat file; its folder is created if needed.
%     results  Struct returned by ldem.runSimulation.
%
%   Example:
%       ldem.io.saveResults("output/results.mat", results);
%
%   See also ldem.runSimulation.

arguments
    path (1,1) string
    results (1,1) struct
end

folder = fileparts(path);
if strlength(folder) > 0 && ~isfolder(folder)
    mkdir(folder);
end
save(path, 'results', '-v7.3');
end
