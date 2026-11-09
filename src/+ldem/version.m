function v = version()
%VERSION  Version of the ldem package.
%
%   v = ldem.version() returns the version string that is stored in the
%   results of every simulation, so that a result file can be traced back to
%   the code that produced it.
%
%   Example:
%       disp(ldem.version())
%
%   See also ldem.runSimulation.

v = "0.2.0-dev";
end
