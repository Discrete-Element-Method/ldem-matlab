function [state, files] = runLegacyCase(c, workDir)
%RUNLEGACYCASE  Run the frozen legacy driver for one case in a child MATLAB.
%
%   [state, files] = runLegacyCase(c, workDir) executes legacy/main1.m with
%   the input described by case c, inside the (empty) folder workDir.
%
%   The legacy driver starts with "clear all" and keeps everything in global
%   variables, so it cannot be called from inside a running test. It is
%   therefore executed in a separate "matlab -batch" process whose final
%   workspace is saved and read back.
%
%   Inputs:
%     c        Case struct, see referenceCases.
%     workDir  Existing folder where the simulation runs and writes output.
%
%   Outputs:
%     state  Struct with the final legacy state, trimmed to the real mesh
%            size (the legacy code preallocates INT=168000 nodes and
%            INB=2300000 bars). Node arrays are 1-by-NNT, bar arrays
%            1-by-NBT, CN is 1-by-2*NBT. Scalars are kept unchanged.
%     files  Struct with the text of every output file, keyed by a valid
%            field name (dots replaced by underscores).
%
%   See also referenceCases, generateReference.

root       = fileparts(fileparts(fileparts(mfilename('fullpath'))));
legacyDir  = fullfile(root, 'legacy');
exampleDir = fullfile(root, 'examples', 'beam_102');

writeDataFile(fullfile(workDir, 'DATA0.DAT'), c);
copyfile(fullfile(exampleDir, 'LET.AN1'), workDir);
copyfile(fullfile(exampleDir, 'arquivo_3lc_rnao_cv05'), workDir);

batchCmd = sprintf('addpath(''%s''); main1; save(''final_state.mat'');', legacyDir);
matlabExe = fullfile(matlabroot, 'bin', 'matlab');
logFile = fullfile(workDir, 'legacy_run.log');
cmd = sprintf('"%s" -batch "%s" > "%s" 2>&1', matlabExe, batchCmd, logFile);

oldFolder = cd(workDir);
folderRestore = onCleanup(@() cd(oldFolder));
status = system(cmd);
if status ~= 0 || ~isfile(fullfile(workDir, 'final_state.mat'))
    error('ldem:tools:legacyRunFailed', ...
        'Legacy run of case "%s" failed (exit %d). See %s.', c.name, status, logFile);
end

raw   = load(fullfile(workDir, 'final_state.mat'));
state = trimLegacyState(raw);
files = collectTextFiles(workDir);
end

function state = trimLegacyState(raw)
%TRIMLEGACYSTATE  Cut the preallocated legacy arrays down to the real mesh.
nNodes = raw.NNT;
nBars  = raw.NBT;
keep = {'U','V','W','U0','V0','W0','BDX','BDY','BDZ','VLX','VLY','VLZ', ...
        'ACX','ACY','ACZ','FRX','FRY','FRZ','FX','FY','FZ','MAS','MSS', ...
        'CN','XB','YB','ZB','UBAR','VBAR','WBAR', ...
        'LI','E1','E2','EP','EM','KR','SS','DSS','F','DM','FS','DEQB', ...
        'EDG','ENR','YNGB','GFRB','LCRB','EPRB','EN', ...
        'TIME','STEP','NSTEP','NNT','NBT','M','N','L','LCO','DT', ...
        'ENEX','ENCN','ENEL','ENGD','ENDP','ENIN','DEN','DERIV', ...
        'REACAOX','REACAOY','REACAOZ','EPMAX','EPMIN','MEAN','COEV'};
state = struct();
for k = 1:numel(keep)
    name = keep{k};
    if ~isfield(raw, name)
        continue
    end
    value = raw.(name);
    if isnumeric(value) || islogical(value)
        nCols = size(value, 2);
        if nCols == raw.INT
            value = value(:, 1:nNodes);
        elseif nCols == raw.INB
            value = value(:, 1:nBars);
        elseif nCols == 2 * raw.INB
            value = value(:, 1:2*nBars);
        end
    end
    state.(name) = value;
end
end

function files = collectTextFiles(workDir)
%COLLECTTEXTFILES  Read every generated output file into a struct of strings.
files = struct();
listing = dir(workDir);
skip = {'DATA0.DAT','LET.AN1','arquivo_3lc_rnao_cv05','final_state.mat','legacy_run.log'};
for k = 1:numel(listing)
    if listing(k).isdir || any(strcmp(listing(k).name, skip))
        continue
    end
    field = matlab.lang.makeValidName(listing(k).name);
    files.(field) = fileread(fullfile(workDir, listing(k).name));
end
end
