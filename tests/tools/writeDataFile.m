function writeDataFile(path, c)
%WRITEDATAFILE  Write a legacy DATA0.DAT input file from a case definition.
%
%   writeDataFile(path, c) creates the input file read by the legacy routine
%   READ_DAT0. Only the first token of each line is read by the legacy code;
%   the quoted label after it is a comment for humans.
%
%   Inputs:
%     path  Full path of the file to create.
%     c     Case struct, see referenceCases.
%
%   See also referenceCases, runLegacyCase.

fid = fopen(path, 'w');
if fid == -1
    error('ldem:tools:cannotOpenFile', 'Cannot create "%s".', path);
end
closer = onCleanup(@() fclose(fid));

nControl = numel(c.controlNodes);
totalTime = c.nSteps * c.dt;

fprintf(fid, '%d  '' TEST ''\n',   c.test);
fprintf(fid, '%d  '' SEED ''\n',   c.seed);
fprintf(fid, '%.6g  '' LCO ''\n',  c.moduleLength);
fprintf(fid, '%d  '' M ''\n',      c.modules(1));
fprintf(fid, '%d  '' N ''\n',      c.modules(2));
fprintf(fid, '%d  '' L ''\n',      c.modules(3));
fprintf(fid, '%.6g  '' DF1 ''\n',  c.damping1);
fprintf(fid, '%.6g  '' DF2 ''\n',  c.damping2);
fprintf(fid, '%.6g  '' TDAF ''\n', c.dampingSwitchTime);
fprintf(fid, '%.6g  '' CON ''\n',  c.con);
fprintf(fid, '%.6g  '' DT ''\n',   c.dt);
fprintf(fid, '%.15g  '' TTOT ''\n', totalTime);
fprintf(fid, '%d  '' INCO ''\n',   nControl);
for i = 1:nControl
    fprintf(fid, '%d  '' Ncon%d ''\n', c.controlNodes(i), i);
end
fprintf(fid, '9999999  '' OU2 ''\n');
fprintf(fid, '%d  '' OU3 ''\n', c.ansysEvery);
fprintf(fid, '0  '' OU4 ''\n');
fprintf(fid, '0  '' OU5 ''\n');
fprintf(fid, '%d  '' OU6 ''\n', c.everyN);
fprintf(fid, '%d  '' OU7 ''\n', c.everyN);
fprintf(fid, '%d  '' OU8 ''\n', c.everyN);
fprintf(fid, '%d  '' OU9 ''\n', c.everyN);
fprintf(fid, '%.6g  '' PSN ''\n', c.poisson);
fprintf(fid, '%.6g  '' ROH ''\n', c.density);
fprintf(fid, '%.6g  '' YNG ''\n', c.youngModulus);
fprintf(fid, '%.6g  '' GFR ''\n', c.fractureEnergy);
fprintf(fid, '%.6g  '' DEQ ''\n', c.criticalDistance);
end
