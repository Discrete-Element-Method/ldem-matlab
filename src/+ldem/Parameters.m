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
    %   p = ldem.Parameters.fromFile("DATA0.DAT") reads the legacy input
    %   file format, see ldem.io.readInputFile.
    %
    %   Every property is validated when it is assigned (type, size and
    %   range). Rules that involve several properties, such as the
    %   stability of the time step, are checked by validate(), which the
    %   constructor and ldem.runSimulation call for you.
    %
    %   Units are SI (m, s, kg, Pa, N) unless stated otherwise.
    %
    %   Legacy names: the comment on each property gives the variable of the
    %   original code (DATA0.DAT / global variables) it replaces.
    %
    %   See also ldem.io.readInputFile, ldem.runSimulation.

    properties
        % Test identifier selecting the boundary conditions and loads
        % (101 = uniaxial tension, 102 = four-point bending, 103 = beam
        % clamped at both ends loaded with a force). Legacy: TEST.
        testId (1,1) double {mustBeInteger, mustBePositive} = 101

        % Seed of the random number generator used for the optional mesh
        % perturbation. Legacy: SEED.
        seed (1,1) double {mustBeInteger, mustBeNonnegative} = 123

        % Edge length of the cubic module [m]. Legacy: LCO.
        moduleLength (1,1) double {mustBePositive, mustBeFinite} = 0.003

        % Number of nodes along x, y and z of the prism, [M N L]; the prism
        % has (M-1)*(N-1)*(L-1) cubic modules. Legacy: M, N, L.
        nModules (1,3) double {mustBeInteger, mustBeGreaterThanOrEqual(nModules, 2)} = [6 3 3]

        % Mass-proportional damping coefficient before the switch time
        % [1/s]. Legacy: DF1.
        dampingInitial (1,1) double {mustBeNonnegative, mustBeFinite} = 25000

        % Mass-proportional damping coefficient after the switch time
        % [1/s]. Legacy: DF2.
        dampingFinal (1,1) double {mustBeNonnegative, mustBeFinite} = 25000

        % Time at which the damping changes from dampingInitial to
        % dampingFinal [s]. Legacy: TDAF.
        dampingSwitchTime (1,1) double {mustBeNonnegative, mustBeFinite} = 0.015

        % Damping coefficient inside the constitutive law, proportional to
        % the stiffness [s]. Legacy: CON.
        constitutiveDamping (1,1) double {mustBeNonnegative, mustBeFinite} = 0

        % Integration time step [s]. Legacy: DT.
        dt (1,1) double {mustBePositive, mustBeFinite} = 2e-7

        % Total simulated time [s]. Legacy: TTOT.
        totalTime (1,1) double {mustBePositive, mustBeFinite} = 4e-5

        % Node numbers of the control points whose motion is recorded, as a
        % row vector (at most 10). Legacy: INCO, NCON.
        controlNodes (1,:) double {mustBeInteger, mustBePositive} = [1 2]

        % Young's modulus [Pa]. Legacy: YNG.
        youngModulus (1,1) double {mustBePositive, mustBeFinite} = 32e9

        % Mass density [kg/m^3]. Legacy: ROH.
        density (1,1) double {mustBePositive, mustBeFinite} = 2000

        % Poisson's ratio, from 0 up to (not including) 0.5. The upper
        % limit is checked by validate(). Legacy: PSN.
        poissonRatio (1,1) double {mustBeNonnegative, mustBeFinite} = 0.25

        % Specific fracture energy [N/m]. Legacy: GFR.
        fractureEnergy (1,1) double {mustBePositive, mustBeFinite} = 50

        % Equivalent (critical) distance [m]. Legacy: DEQ.
        criticalDistance (1,1) double {mustBePositive, mustBeFinite} = 0.028

        % Fraction of the module face that fails per bar (area of failure is
        % failureAreaFactor*length). Legacy: CAF, hardcoded to 0.1385.
        failureAreaFactor (1,1) double {mustBePositive, mustBeFinite} = 0.1385

        % Number of the bar whose strain history is recorded.
        % Legacy: hardcoded 7014 in CABAR and ENERG2.
        trackedBar (1,1) double {mustBeInteger, mustBePositive} = 7014

        % Text file with one multiplier of the critical strain per bar
        % (random field). Empty means "no random field" (all multipliers 1).
        % Legacy: file "arquivo_3lc_rnao_cv05".
        randomFieldFile (1,1) string = ""

        % Random perturbation of the node coordinates, as the standard
        % deviation expressed as a fraction of the module length. 0 (the
        % default) switches the perturbation off; any positive value
        % switches it on with that value (for example 0.02 displaces the
        % nodes by about 2 % of the module length). Legacy: LABELN (always
        % 0, so the legacy results have no perturbation) and CVUVW = 0.02.
        meshPerturbation (1,1) double {mustBeNonnegative, mustBeFinite} = 0

        % How often each result is stored, in time steps (0 = never):
        %
        % * snapshotEvery: ANSYS/VTK files and full-field snapshots (OU3).
        % * controlNodesEvery: control nodes and reactions (OU6).
        % * energyEvery: global energies (OU8).
        % * trackedBarEvery: tracked bar, 0 or 1; the legacy code stores it
        %   at every step when OU9 > 0 (OU9).
        output (1,1) struct = struct('snapshotEvery', 0, ...
            'controlNodesEvery', 10, 'energyEvery', 10, 'trackedBarEvery', 0)
    end

    properties (Dependent, SetAccess = private)
        % Number of time steps, round(totalTime/dt). Legacy: NSTEP.
        nSteps

        % Step at which the damping changes, round(dampingSwitchTime/dt).
        % Legacy: NDAMF.
        dampingSwitchStep

        % Total number of nodes: grid nodes plus module-centre nodes.
        % Legacy: NNT.
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

    methods (Static)
        function obj = fromFile(path, overrides)
            %FROMFILE  Read the legacy input file (DATA0.DAT format).
            %
            %   p = ldem.Parameters.fromFile(path) reads the file and
            %   returns a validated parameter set.
            %
            %   p = ldem.Parameters.fromFile(path, Name=Value) additionally
            %   overrides properties that are not stored in the file, for
            %   example randomFieldFile or trackedBar.
            %
            %   See also ldem.io.readInputFile.
            arguments
                path (1,1) string
                overrides.?ldem.Parameters
            end
            fromFile = ldem.io.readInputFile(path);
            names = fieldnames(overrides);
            for k = 1:numel(names)
                fromFile.(names{k}) = overrides.(names{k});
            end
            args = namedargs2cell(fromFile);
            obj = ldem.Parameters(args{:});
        end
    end
end
