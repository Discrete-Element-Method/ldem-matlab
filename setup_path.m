function setup_path()
%SETUP_PATH  Add the LDEM code to the MATLAB path.
%
%   setup_path() adds the folder that contains the LDEM routines to the
%   MATLAB path for the current session. At the moment this is the
%   frozen reference implementation in legacy/; the refactored package
%   (src/+ldem) will be added here as it replaces it.
%
%   Example:
%       >> setup_path
%
%   See also addpath.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'legacy'));
end
