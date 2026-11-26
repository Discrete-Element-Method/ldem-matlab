classdef Parameters
    %PARAMETERS  Validated input parameters of an LDEM simulation.
    %
    %   p = ldem.Parameters() creates a parameter set with default values
    %   (a small tension test that runs in seconds).
    %
    %   p = ldem.Parameters(Name=Value, ...) overrides any property, for
    %   example:
    %
    %       p = ldem.Parameters(testId=102, nModules=[70 4 3], dt=2e-7);
    %
    %   A case file (.ldem) gives the same object: ldem.io.readCase(path).params.
    %
    %   Every property is validated when it is assigned (type, size and
    %   range). Rules that involve several properties, such as the
    %   stability of the time step, are checked by validate(), which the
    %   constructor and ldem.runSimulation call for you.
    %
    %   Units are SI (m, s, kg, Pa, N) unless stated otherwise.
    %
    %   See also ldem.io.readCase, ldem.runSimulation.

    properties
        % Test identifier selecting the boundary conditions and loads
        % (101 = uniaxial tension, 102 = four-point bending, 103 = beam
        % clamped at both ends loaded with a force).
        testId (1,1) double {mustBeInteger, mustBePositive} = 101

        % Seed of the random number generator used for the optional mesh
        % perturbation.
        seed (1,1) double {mustBeInteger, mustBeNonnegative} = 123

        % Edge length of the cubic module [m].
        moduleLength (1,1) double {mustBePositive, mustBeFinite} = 0.003

        % Number of nodes along x, y and z of the prism, [M N L]; the prism
        % has (M-1)*(N-1)*(L-1) cubic modules.
        nModules (1,3) double {mustBeInteger, mustBeGreaterThanOrEqual(nModules, 2)} = [6 3 3]

        % Mass-proportional damping coefficient before the switch time
        % [1/s].
        dampingInitial (1,1) double {mustBeNonnegative, mustBeFinite} = 25000

        % Mass-proportional damping coefficient after the switch time
        % [1/s].
        dampingFinal (1,1) double {mustBeNonnegative, mustBeFinite} = 25000

        % Time at which the damping changes from dampingInitial to
        % dampingFinal [s].
        dampingSwitchTime (1,1) double {mustBeNonnegative, mustBeFinite} = 0.015

        % Damping coefficient inside the constitutive law, proportional to
        % the stiffness [s].
        constitutiveDamping (1,1) double {mustBeNonnegative, mustBeFinite} = 0

        % Constitutive law of the bars: a name of ldem.material.lawRegistry
        % ("bilinear" or "linear_elastic"). Checked by validate().
        constitutiveLaw (1,1) string = "bilinear"

        % Damping model of the nodes: a name of ldem.solver.dampingRegistry
        % ("mass_proportional" or "none"). Checked by validate().
        dampingModel (1,1) string = "mass_proportional"

        % Integration time step [s].
        dt (1,1) double {mustBePositive, mustBeFinite} = 2e-7

        % Total simulated time [s].
        totalTime (1,1) double {mustBePositive, mustBeFinite} = 4e-5

        % Node numbers of the control points whose motion is recorded, as a
        % row vector (at most 10).
        controlNodes (1,:) double {mustBeInteger, mustBePositive} = [1 2]

        % Young's modulus [Pa].
        youngModulus (1,1) double {mustBePositive, mustBeFinite} = 32e9

        % Mass density [kg/m^3].
        density (1,1) double {mustBePositive, mustBeFinite} = 2000

        % Poisson's ratio, from 0 up to (not including) 0.5. The upper
        % limit is checked by validate().
        poissonRatio (1,1) double {mustBeNonnegative, mustBeFinite} = 0.25

        % Specific fracture energy [N/m].
        fractureEnergy (1,1) double {mustBePositive, mustBeFinite} = 50

        % Equivalent (critical) distance [m].
        criticalDistance (1,1) double {mustBePositive, mustBeFinite} = 0.028

        % Fraction of the module face that fails per bar (area of failure is
        % failureAreaFactor*length).
        failureAreaFactor (1,1) double {mustBePositive, mustBeFinite} = 0.1385

        % Number of the bar whose strain history is recorded.
        trackedBar (1,1) double {mustBeInteger, mustBePositive} = 7014

        % Text file with one multiplier of the critical strain per bar
        % (random field). Empty means "no random field" (all multipliers 1)
        % unless randomFieldCv is positive.
        randomFieldFile (1,1) string = ""

        % Coefficient of variation of the random field generated in memory
        % (see ldem.material.generateRandomField). 0 (the default) generates
        % nothing; a positive value, between 1e-4 and 3, generates the field
        % and cannot be combined with randomFieldFile.
        randomFieldCv (1,1) double {mustBeNonnegative, mustBeFinite} = 0

        % Correlation length of the generated random field, that is the
        % spacing of its pole grid, in module lengths (multiples of
        % moduleLength): a scalar or [x y z].
        randomFieldCorrelationLength (1,:) double {mustBePositive, mustBeFinite} = 3

        % Seed of the random numbers of the generated random field.
        randomFieldSeed (1,1) double {mustBeInteger, mustBeNonnegative} = 515

        % Random perturbation of the node coordinates, as the standard
        % deviation expressed as a fraction of the module length. 0 (the
        % default) switches the perturbation off; any positive value
        % switches it on with that value (for example 0.02 displaces the
        % nodes by about 2 % of the module length).
        meshPerturbation (1,1) double {mustBeNonnegative, mustBeFinite} = 0

        % How often each result is stored, in time steps (0 = never):
        %
        % * snapshotEvery: ANSYS/VTK files and full-field snapshots.
        % * controlNodesEvery: control nodes and reactions.
        % * energyEvery: global energies.
        % * trackedBarEvery: tracked bar, 0 (off) or 1 (every step).
        output (1,1) struct = struct('snapshotEvery', 0, ...
            'controlNodesEvery', 10, 'energyEvery', 10, 'trackedBarEvery', 0)
    end

    properties (Dependent, SetAccess = private)
        % Number of time steps, round(totalTime/dt).
        nSteps

        % Step at which the damping changes, round(dampingSwitchTime/dt).
        dampingSwitchStep

        % Total number of nodes: grid nodes plus module-centre nodes.
        nNodes

        % Elastic wave speed sqrt(E/rho) [m/s].
        waveSpeed

        % Largest stable time step for a regular (unperturbed) lattice [s].
        % The shortest bar joins a module centre to a corner and measures
        % sqrt(3)/2 times the module length.
        criticalTimeStep
    end

    methods
        function obj = Parameters(props)
            %PARAMETERS  Create and validate a parameter set.
            arguments
                props.?ldem.Parameters
            end
            names = fieldnames(props);
            for k = 1:numel(names)
                obj.(names{k}) = props.(names{k});
            end
            obj.validate();
        end

        function validate(obj)
            %VALIDATE  Check the rules that involve several properties.
            %
            %   p.validate() throws an error with an identifier of the form
            %   "ldem:params:<problem>" and a message that says how to fix
            %   it. It returns silently when the parameters are consistent.

            % The lattice stiffness formulas diverge as the ratio approaches 1/2.
            if obj.poissonRatio >= 0.5
                error('ldem:params:badPoissonRatio', ...
                    'poissonRatio must be smaller than 0.5, got %g.', obj.poissonRatio);
            end

            % The law and the damping model must be registered.
            if ~any([ldem.material.lawRegistry().name] == lower(obj.constitutiveLaw))
                error('ldem:params:unknownLaw', ...
                    'constitutiveLaw "%s" does not exist. Available: %s.', obj.constitutiveLaw, ...
                    strjoin([ldem.material.lawRegistry().name], ', '));
            end
            if ~any([ldem.solver.dampingRegistry().name] == lower(obj.dampingModel))
                error('ldem:params:unknownDampingModel', ...
                    'dampingModel "%s" does not exist. Available: %s.', obj.dampingModel, ...
                    strjoin([ldem.solver.dampingRegistry().name], ', '));
            end

            % Control nodes must exist and be few.
            if numel(obj.controlNodes) > 10
                error('ldem:params:tooManyControlNodes', ...
                    'At most 10 control nodes are supported, got %d.', ...
                    numel(obj.controlNodes));
            end
            if any(obj.controlNodes > obj.nNodes)
                error('ldem:params:controlNodeOutOfRange', ...
                    ['Control node %d does not exist: the mesh has only ' ...
                     '%d nodes.'], max(obj.controlNodes), obj.nNodes);
            end

            % Output settings.
            required = {'snapshotEvery','controlNodesEvery','energyEvery','trackedBarEvery'};
            if ~all(isfield(obj.output, required)) || numel(fieldnames(obj.output)) ~= numel(required)
                error('ldem:params:badOutput', ...
                    'output must have exactly the fields: %s.', strjoin(required, ', '));
            end
            for k = 1:numel(required)
                v = obj.output.(required{k});
                if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0 && v == fix(v))
                    error('ldem:params:badOutput', ...
                        'output.%s must be a non-negative integer.', required{k});
                end
            end
            if obj.output.trackedBarEvery > 1
                error('ldem:params:badOutput', ...
                    'output.trackedBarEvery must be 0 or 1 (the tracked bar is stored at every step).');
            end

            % Random field: from a file or generated, not both.
            if obj.randomFieldCv > 0 && strlength(obj.randomFieldFile) > 0
                error('ldem:params:twoRandomFields', ...
                    ['Set either randomFieldFile (read the field) or randomFieldCv ' ...
                     '(generate it), not both.']);
            end
            if obj.randomFieldCv > 0 && (obj.randomFieldCv < 1e-4 || obj.randomFieldCv > 3)
                error('ldem:params:badRandomFieldCv', ...
                    'randomFieldCv must be 0 or between 1e-4 and 3, got %g.', obj.randomFieldCv);
            end
            if ~any(numel(obj.randomFieldCorrelationLength) == [1 3])
                error('ldem:params:badCorrelationLength', ...
                    ['randomFieldCorrelationLength must be a scalar or have 3 values ' ...
                     '[x y z], got %d values.'], numel(obj.randomFieldCorrelationLength));
            end

            % Time integration.
            if obj.totalTime < obj.dt
                error('ldem:params:totalTimeTooShort', ...
                    'totalTime (%g s) must be at least one time step (dt = %g s).', ...
                    obj.totalTime, obj.dt);
            end
            if obj.meshPerturbation == 0 && obj.dt > obj.criticalTimeStep
                error('ldem:params:unstableTimeStep', ...
                    ['The time step dt = %g s is unstable. For moduleLength = %g m, ' ...
                     'youngModulus = %g Pa and density = %g kg/m^3 it must not exceed ' ...
                     '%g s. Reduce dt or increase moduleLength.'], ...
                    obj.dt, obj.moduleLength, obj.youngModulus, obj.density, obj.criticalTimeStep);
            end
        end

        function s = toStruct(obj)
            %TOSTRUCT  Convert the parameters (and derived values) to a plain struct.
            %
            %   s = p.toStruct() returns a struct with one field per property,
            %   derived values included. Unlike the object it can be loaded
            %   from a MAT-file without the ldem package on the path, so it
            %   is what ldem.runSimulation stores in the results.
            names = properties(obj);
            s = struct();
            for k = 1:numel(names)
                s.(names{k}) = obj.(names{k});
            end
        end

        function value = get.nSteps(obj)
            value = round(obj.totalTime / obj.dt);
        end

        function value = get.dampingSwitchStep(obj)
            value = round(obj.dampingSwitchTime / obj.dt);
        end

        function value = get.nNodes(obj)
            gridNodes   = prod(obj.nModules);
            centreNodes = prod(obj.nModules - 1);
            value = gridNodes + centreNodes;
        end

        function value = get.waveSpeed(obj)
            value = sqrt(obj.youngModulus / obj.density);
        end

        function value = get.criticalTimeStep(obj)
            shortestBar = obj.moduleLength * sqrt(3) / 2;
            value = shortestBar / obj.waveSpeed;
        end
    end
end
