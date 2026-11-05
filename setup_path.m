function setup_path()
%SETUP_PATH  Add the LDEM code to the MATLAB path.
%
%   setup_path() adds to the MATLAB path, for the current session:
%     src/     the refactored package, used as ldem.<function>
%     legacy/  the frozen original routines (reference implementation)
%
%   Example:
%       >> setup_path
%       >> params = ldem.Parameters();
%
%   See also addpath.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'legacy'));
end
