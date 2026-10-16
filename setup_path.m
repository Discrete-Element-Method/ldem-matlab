function setup_path()
%SETUP_PATH  Adiciona src/ldem ao path do MATLAB.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src', 'ldem'));
end
