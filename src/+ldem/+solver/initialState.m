function state = initialState(mesh, history)
%INITIALSTATE  State of the simulation at time zero.
%
%   state = ldem.solver.initialState(mesh, history) creates the struct that
%   the time-stepping routines update. All nodes start at their initial
%   position, at rest and without forces; the bars start undamaged.
%
%   The explicit central-difference scheme needs the displacement of two
%   consecutive times, so the state holds both (at time zero they are equal).
%
%   Inputs:
%     mesh     Struct from ldem.mesh.buildMesh.
%     history  Initial damage state from ldem.material.buildBarProperties.
%
%   Output:
%     state  Struct with the fields listed below.
%
%   Fields of state:
%
%     step                  Number of the last completed step (0).
%     time                  Simulated time [s].
%     displacement          nNodes-by-3 current positions [m] (legacy U(2,:), V(2,:), W(2,:)).
%     previousDisplacement  nNodes-by-3 positions one step before (legacy U(1,:), V(1,:), W(1,:)).
%     velocity              nNodes-by-3 velocities [m/s].
%     acceleration          nNodes-by-3 accelerations [m/s^2].
%     force                 nNodes-by-3 force of the bars on the nodes [N] (legacy FRX, FRY, FRZ).
%     strain                nBars-by-1 axial strain (legacy SS).
%     strainRate            nBars-by-1 strain rate [1/s] (legacy DSS).
%     axialForce            nBars-by-1 axial force [N], tension positive (legacy F).
%     history               Damage state of the bars.
%     dampingEnergy         Energy dissipated by damping so far [J].
%     externalEnergy        Work done by the supports and the prescribed motion so far [J].
%     previousForce         nNodes-by-3 nodal force of the previous step [N].
%     previousDamageEnergy  Energy dissipated by damage at the previous step [J].
%
%   Example:
%       state = ldem.solver.initialState(mesh, history);
%
%   Legacy: INI_DEM3 (allocation) and the initial values set by COORDSUB.
%
%   See also ldem.solver.simulate.

arguments
    mesh (1,1) struct
    history (1,1) struct
end

nNodes = size(mesh.nodes0, 1);
nBars  = size(mesh.bars, 1);

state = struct();
state.step                 = 0;
state.time                 = 0.0;
state.displacement         = mesh.nodes0;
state.previousDisplacement = mesh.nodes0;
state.velocity             = zeros(nNodes, 3);
state.acceleration         = zeros(nNodes, 3);
state.force                = zeros(nNodes, 3);
state.strain               = zeros(nBars, 1);
state.strainRate           = zeros(nBars, 1);
state.axialForce           = zeros(nBars, 1);
state.history              = history;
state.dampingEnergy        = 0.0;
state.externalEnergy       = 0.0;
state.previousForce        = zeros(nNodes, 3);
state.previousDamageEnergy = 0.0;
end
