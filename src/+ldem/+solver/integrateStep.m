function state = integrateStep(state, mesh, barProps, params)
%INTEGRATESTEP  Advance the node positions one time step.
%
%   state = ldem.solver.integrateStep(state, mesh, barProps, params) solves
%   the equation of motion of every free degree of freedom with the explicit
%   central-difference scheme
%
%       m * (u_next - 2*u + u_prev)/dt^2 + c*m * (u_next - u_prev)/(2*dt) = F
%
%   where F is the bar force on the node, m its lumped mass and c the
%   mass-proportional damping coefficient of the step, which gives
%
%       u_next = (dt^2/m * F + 2*u - (1 - c*dt/2)*u_prev) / (1 + c*dt/2)
%
%   F is the sum of the bar force (state.force) and of the force applied by the
%   scenario (state.appliedForce, zero when the scenario imposes displacements).
%   Degrees of freedom fixed by the scenario keep their current value. After
%   the update the velocity and acceleration are obtained with central
%   differences, the energy dissipated by damping is accumulated and the two
%   stored positions are shifted (current -> previous, next -> current).
%
%   External work. A degree of freedom fixed by the scenario follows a
%   prescribed path (a support does not move, a loaded node moves with the
%   loading velocity). The force that the outside world exerts on it is minus
%   the bar force, so the work done on the structure in the step is
%   -F*(u - u_prev), with F the average of the bar force of this step and of the
%   previous one (trapezoidal rule). It is summed over the fixed degrees of
%   freedom: zero for a support that does not move, positive when a prescribed
%   motion pushes the structure. The inertia of the prescribed nodes is not
%   included; it is negligible against the energy of the structure. Adding up
%   the steps gives the external work, which balances the kinetic, elastic,
%   damage and damping energies (see ldem.solver.computeEnergies).
%
%   A force applied to a free degree of freedom does work on the structure as
%   the node moves: the average of the applied force of this step and of the
%   previous one times the displacement of the step, summed over the free
%   degrees of freedom and added to the same external work.
%
%   The energy dissipated in the step has two parts: the mass-proportional
%   damping of the nodes, c*(m/2)*v*(u_next - u_prev), and the viscous term
%   of the constitutive law, E*CON*rate^2*dt*L for every bar (E is the
%   compression stiffness for compressed bars and the tension stiffness
%   otherwise).
%
%   Inputs:
%     state     Solver state after ldem.solver.computeBarForces.
%     mesh      Struct from ldem.mesh.buildMesh (mass, fixed, barLength).
%     barProps  Struct from ldem.material.buildBarProperties.
%     params    ldem.Parameters.
%
%   Output:
%     state  Updated: displacement, previousDisplacement, velocity,
%            acceleration, dampingEnergy, externalEnergy, previousForce and
%            previousAppliedForce.
%
%   Errors:
%     ldem:solver:zeroMass  A node has zero mass.
%
%   Legacy: IGN012 (nested function ign012). The legacy acceleration in y
%   used a wrong index (V(2,I) instead of V(2,:)); here it is computed like
%   the other two components.
%
%   See also ldem.solver.computeBarForces, ldem.solver.dampingCoefficient.

arguments
    state (1,1) struct
    mesh (1,1) struct
    barProps (1,1) struct
    params (1,1) ldem.Parameters
end

if any(mesh.mass == 0)
    error('ldem:solver:zeroMass', 'Node %d has zero mass.', find(mesh.mass == 0, 1));
end

dt  = params.dt;
ddt = 2.0 * dt;
sdt = dt * dt;

c = ldem.solver.dampingCoefficient(state.step, params);
dampingPrevious = 1.0 - c * dt / 2.0;
dampingNext     = 1.0 + c * dt / 2.0;

u     = state.displacement;
uPrev = state.previousDisplacement;
timeFactor = sdt ./ mesh.mass;                 % nNodes-by-1, applies to x, y and z

totalForce = state.force + state.appliedForce;
uNext = (timeFactor .* totalForce + 2.0 .* u - dampingPrevious .* uPrev) ./ dampingNext;
uNext(mesh.fixed) = u(mesh.fixed);

velocity     = (uNext - uPrev) ./ ddt;
acceleration = (uNext - u .* 2.0 + uPrev) ./ sdt;

% Energy dissipated by mass-proportional damping (all nodes and directions).
nodeDamping = (c .* (mesh.mass ./ 2.0)) .* velocity .* (uNext - uPrev);
dissipated = sum(nodeDamping, 'all');

% Energy dissipated by the viscous term of the constitutive law.
isCompressed = state.strain < 0.0;
stiffness = state.history.tensionStiffness;
stiffness(isCompressed) = barProps.stiffness(isCompressed);
barViscous = 2.0 * (stiffness .* params.constitutiveDamping .* state.strainRate .* ...
    state.strainRate .* dt .* mesh.barLength ./ 2.0);
dissipated = dissipated + sum(barViscous);

% Work of the outside world on the fixed degrees of freedom (trapezoidal rule).
averageForce = (state.force(mesh.fixed) + state.previousForce(mesh.fixed)) / 2.0;
externalWork = -sum(averageForce .* (u(mesh.fixed) - uPrev(mesh.fixed)));

% Work of the applied forces on the free degrees of freedom.
averageApplied = (state.appliedForce + state.previousAppliedForce) / 2.0;
free = ~mesh.fixed;
externalWork = externalWork + sum(averageApplied(free) .* (u(free) - uPrev(free)));

state.externalEnergy       = state.externalEnergy + externalWork;
state.previousForce        = state.force;
state.previousAppliedForce = state.appliedForce;
state.dampingEnergy        = state.dampingEnergy + dissipated;
state.previousDisplacement = u;
state.displacement         = uNext;
state.velocity             = velocity;
state.acceleration         = acceleration;
end
