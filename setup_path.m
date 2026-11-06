function setup_path()
%SETUP_PATH  Add the LDEM code to the MATLAB path.
%
%   setup_path() adds src/ to the MATLAB path for the current session, so
%   the package can be used as ldem.<function>.
%
%   Example:
%       >> setup_path
%       >> params = ldem.Parameters();
%
%   See also addpath.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
end
