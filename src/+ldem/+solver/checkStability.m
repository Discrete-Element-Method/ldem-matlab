function criticalDt = checkStability(barLength, params)
%CHECKSTABILITY  Verify that the time step is stable for the actual mesh.
%
%   criticalDt = ldem.solver.checkStability(barLength, params) computes the
%   largest stable time step of the explicit scheme, minimum bar length
%   divided by the elastic wave speed, and throws an error if params.dt is
%   larger.
%
%   This uses the real bar lengths, so it also covers perturbed meshes. For
%   a regular lattice the value equals params.criticalTimeStep.
%
%   Inputs:
%     barLength  Vector of initial bar lengths [m].
%     params     ldem.Parameters.
%
%   Output:
%     criticalDt  Largest stable time step [s].
%
%   Errors:
%     ldem:params:unstableTimeStep  params.dt exceeds the critical value.
%
%   Example:
%       criticalDt = ldem.solver.checkStability(mesh.barLength, params);
%
%   Legacy: stability check at the end of NAYFES0.
%
%   See also ldem.Parameters, ldem.mesh.computeBarGeometry.

arguments
    barLength (:,1) double {mustBePositive}
    params (1,1) ldem.Parameters
end

criticalDt = min(barLength) / params.waveSpeed;
if criticalDt < params.dt
    error('ldem:params:unstableTimeStep', ...
        ['The time step dt = %g s is unstable for this mesh: the shortest ' ...
         'bar (%g m) requires dt <= %g s. Reduce dt.'], ...
        params.dt, min(barLength), criticalDt);
end
end
