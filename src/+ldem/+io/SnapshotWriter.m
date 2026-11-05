classdef SnapshotWriter < handle
    %SNAPSHOTWRITER  Collect snapshots of the state and export them to files.
    %
    %   A snapshot is the full state of the lattice at one instant. The solver
    %   calls the writer at the steps chosen by params.output.snapshotEvery.
    %   For every snapshot the writer does the following:
    %
    %   * keeps a compact copy (displacement and damage state), stored in the results;
    %   * writes an ANSYS macro file if "ansys" is among the formats;
    %   * writes a VTK file if "vtk" is among the formats.
    %
    %   When the simulation ends, finish() writes the ParaView collection that
    %   groups the VTK files in time.
    %
    %   Typical use (done by ldem.runSimulation):
    %       writer = ldem.io.SnapshotWriter(mesh, "output", ["ansys" "vtk"]);
    %       ldem.solver.simulate(..., SnapshotFcn=@writer.write);
    %       snapshots = writer.finish();
    %
    %   Files are written inside the given folder, named snapshot_0000.vtu,
    %   snapshot_0001.vtu, ... and snapshot_0000.mac, ... (zero is the state
    %   at time zero); the collection is called snapshots.pvd.
    %
    %   See also ldem.io.exportAnsys, ldem.io.exportVtk, ldem.io.writePvd,
    %   ldem.solver.simulate.

    properties (SetAccess = private)
        % Folder where the files are written ("" if no files are written).
        Folder (1,1) string = ""
        % Export formats: any of "ansys" and "vtk".
        Formats (1,:) string = string.empty
        % Number of snapshots taken so far.
        Count (1,1) double = 0
    end

    properties (Access = private)
        Mesh (1,1) struct
        Steps = zeros(0, 1)
        Times = zeros(0, 1)
        BarCounts = zeros(0, 3)
        Displacements = {}
        DamageStates = {}
        VtkFiles = strings(0, 1)
    end

    methods
        function obj = SnapshotWriter(mesh, folder, formats)
            %SNAPSHOTWRITER  Create a writer for a mesh.
            %
            %   writer = ldem.io.SnapshotWriter(mesh, folder, formats) prepares
            %   the writer. folder may be "" when formats is empty, to only keep
            %   the in-memory snapshots.
            arguments
                mesh (1,1) struct
                folder (1,1) string = ""
                formats (1,:) string {mustBeMember(formats, ["ansys", "vtk"])} = string.empty
            end
            if ~isempty(formats) && strlength(folder) == 0
                error('ldem:io:noFolder', 'A folder is needed to export %s files.', strjoin(formats, ' and '));
            end
            if strlength(folder) > 0 && ~isfolder(folder)
                mkdir(folder);
            end
            obj.Mesh = mesh;
            obj.Folder = folder;
            obj.Formats = formats;
        end

        function write(obj, state)
            %WRITE  Take one snapshot (callback for ldem.solver.simulate).
            arguments
                obj (1,1) ldem.io.SnapshotWriter
                state (1,1) struct
            end
            index = obj.Count;
            baseName = sprintf('snapshot_%04d', index);

            if any(obj.Formats == "ansys")
                counts = ldem.io.exportAnsys(fullfile(obj.Folder, baseName + ".mac"), obj.Mesh, state);
            else
                counts = ldem.io.SnapshotWriter.countBars(state);
            end
            if any(obj.Formats == "vtk")
                ldem.io.exportVtk(fullfile(obj.Folder, baseName + ".vtu"), obj.Mesh, state);
                obj.VtkFiles(end + 1, 1) = baseName + ".vtu";
            end

            damageState = uint8(2 * ones(size(state.history.isUndamaged)));
            damageState(state.history.isUnbroken) = 1;
            damageState(state.history.isUndamaged) = 0;

            obj.Count = obj.Count + 1;
            obj.Steps(end + 1, 1) = state.step;
            obj.Times(end + 1, 1) = state.time;
            obj.BarCounts(end + 1, :) = [counts.intact, counts.damaged, counts.broken];
            obj.Displacements{end + 1} = single(state.displacement);
            obj.DamageStates{end + 1} = damageState;
        end

        function snapshots = finish(obj)
            %FINISH  Write the ParaView collection and return the snapshots.
            %
            %   snapshots = writer.finish() returns a struct with the fields
            %   step, time (n-by-1), barCounts (n-by-3: intact, damaged,
            %   broken), and displacement (n-by-1 cell of nNodes-by-3 single)
            %   and damageState (n-by-1 cell of nBars-by-1 uint8: 0 intact,
            %   1 damaged, 2 broken).
            arguments
                obj (1,1) ldem.io.SnapshotWriter
            end
            if ~isempty(obj.VtkFiles)
                ldem.io.writePvd(fullfile(obj.Folder, "snapshots.pvd"), ...
                    obj.Times(1:numel(obj.VtkFiles)), obj.VtkFiles);
            end
            snapshots = struct( ...
                'step',         obj.Steps, ...
                'time',         obj.Times, ...
                'barCounts',    obj.BarCounts, ...
                'displacement', {obj.Displacements(:)}, ...
                'damageState',  {obj.DamageStates(:)});
        end
    end

    methods (Static, Access = private)
        function counts = countBars(state)
            intact  = nnz(state.history.isUndamaged);
            broken  = nnz(~state.history.isUnbroken);
            counts  = struct('intact', intact, 'damaged', numel(state.history.isUndamaged) - intact - broken, ...
                'broken', broken);
        end
    end
end
