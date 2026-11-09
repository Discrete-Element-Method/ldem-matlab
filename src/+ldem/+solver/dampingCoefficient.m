function coefficient = dampingCoefficient(step, params)
%DAMPINGCOEFFICIENT  Mass-proportional damping coefficient of a time step.
%
%   coefficient = ldem.solver.dampingCoefficient(step, params) returns
%   params.dampingInitial before the switch step and params.dampingFinal
%   from the switch step on (params.dampingSwitchStep = round(TDAF/dt)).
%
%   If the switch step is zero (dampingSwitchTime shorter than half a time
%   step) the coefficient never changes and dampingInitial is used. This
%   reproduces the legacy code, which only switched when STEP == NDAMF and
%   steps start at 1.
%
%   Inputs:
%     step    Time step number (1, 2, ...).
%     params  ldem.Parameters.
%
%   Output:
%     coefficient  Damping coefficient [1/s].
%
%   Example:
%       c = ldem.solver.dampingCoefficient(100, params);
%
%   Legacy: the damping change at the top of the time loop of the main
%   program (DF1 = DF2 when STEP == NDAMF).
%
%   See also ldem.solver.integrateStep.

arguments
    step (1,1) double {mustBeInteger, mustBePositive}
    params (1,1) ldem.Parameters
end

switchStep = params.dampingSwitchStep;
if switchStep >= 1 && step >= switchStep
    coefficient = params.dampingFinal;
else
    coefficient = params.dampingInitial;
end
end
