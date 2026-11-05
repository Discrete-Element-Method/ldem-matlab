function generateReference(caseNames)
%GENERATEREFERENCE  Create the golden-master fixtures from the legacy code.
%
%   generateReference() runs every case of referenceCases with the frozen
%   legacy driver and stores the result in tests/fixtures/<name>.mat.
%   generateReference("bending102") regenerates only the named case(s).
%
%   Each fixture contains the variables:
%     caseDef  The case definition (see referenceCases).
%     state    Final legacy state, trimmed to the real mesh size.
%     files    Text of every output file written by the legacy code.
%
%   Run this ONLY when the legacy code is intentionally changed; the
%   fixtures are the reference that all refactored code is compared with.
%
%   See also referenceCases, runLegacyCase, TestGoldenMaster.

arguments
    caseNames (1,:) string = string.empty
end

cases = referenceCases();
if ~isempty(caseNames)
    cases = cases(ismember({cases.name}, caseNames));
    if isempty(cases)
        error('ldem:tools:unknownCase', 'No reference case matches the given names.');
    end
end

fixtureDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'fixtures');
if ~isfolder(fixtureDir)
    mkdir(fixtureDir);
end

for k = 1:numel(cases)
    caseDef = cases(k);
    fprintf('Running legacy case "%s" ... ', caseDef.name);
    workDir = tempname;
    mkdir(workDir);
    cleaner = onCleanup(@() rmdir(workDir, 's'));
    timer = tic;
    [state, files] = runLegacyCase(caseDef, workDir); %#ok<ASGLU>
    save(fullfile(fixtureDir, caseDef.name + ".mat"), 'caseDef', 'state', 'files');
    fprintf('done in %.1f s (%d nodes, %d bars, %d damaged bars).\n', ...
        toc(timer), state.NNT, state.NBT, nnz(~state.DM));
    clear cleaner
end
end
