classdef TestExporters < LdemTestCase
    %TESTEXPORTERS  Unit tests of the ANSYS and VTK exporters and SnapshotWriter.

    properties
        Params
        Mesh
        State
    end

    methods (TestMethodSetup)
        function buildSmallState(testCase)
            % A small model advanced far enough to have damaged and broken bars.
            params = ldem.Parameters(nModules=[4 3 3], totalTime=2e-4, fractureEnergy=0.1);
            mesh = ldem.mesh.buildMesh(params);
            [barProps, history] = ldem.material.buildBarProperties(mesh, params);
            scenario = ldem.scenarios.fromTestId(params.testId);
            params.validate();
            state = ldem.solver.simulate(params, mesh, barProps, history, scenario);
            testCase.Params = params;
            testCase.Mesh = mesh;
            testCase.State = state;
        end

        function makeSureSomeBarsAreDamaged(testCase)
            h = testCase.State.history;
            testCase.assumeTrue(any(~h.isUndamaged), ...
                'The test state must contain damaged bars to be meaningful.');
        end
    end

    methods (Access = private)
        function folder = tempFolder(testCase)
            folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function ansysFileHasTheExpectedStructure(testCase)
            path = fullfile(testCase.tempFolder(), "state.mac");
            counts = ldem.io.exportAnsys(path, testCase.Mesh, testCase.State);
            lines = splitlines(string(fileread(path)));
            nNodes = size(testCase.Mesh.nodes0, 1);
            nBars = size(testCase.Mesh.bars, 1);

            testCase.verifyEqual(nnz(startsWith(lines, "N,")), nNodes);
            testCase.verifyEqual(nnz(startsWith(lines, "E,")), nBars);
            testCase.verifyEqual(nnz(startsWith(lines, "TYPE,")), nBars);
            testCase.verifyEqual(counts.intact + counts.damaged + counts.broken, nBars);
            testCase.verifyEqual(counts.intact, nnz(testCase.State.history.isUndamaged));
            testCase.verifyEqual(counts.broken, nnz(~testCase.State.history.isUnbroken));
            testCase.verifyGreaterThan(counts.damaged + counts.broken, 0);
            testCase.verifyTrue(any(lines == sprintf("!BARRAS ROMPIDAS =    %d", counts.broken)));
            testCase.verifyTrue(startsWith(lines(1), "!ARQUIVO NO TEMPO = "));
            testCase.verifyFalse(any(contains(lines, "IFILE")), 'The invalid ET,IFILE,4 line must not appear.');
            testCase.verifyTrue(any(lines == "ET,3,4"));
        end

        function ansysConstraintsListTheFixedDofs(testCase)
            path = fullfile(testCase.tempFolder(), "state.mac");
            ldem.io.exportAnsys(path, testCase.Mesh, testCase.State);
            lines = splitlines(string(fileread(path)));
            constraints = lines(startsWith(lines, "D,"));
            testCase.verifyEqual(numel(constraints), nnz(testCase.Mesh.fixed));
            testCase.verifyTrue(all(endsWith(constraints, "UX")), 'Tension fixes x only.');
        end

        function ansysCoordinatesAreTheCurrentPositions(testCase)
            path = fullfile(testCase.tempFolder(), "state.mac");
            ldem.io.exportAnsys(path, testCase.Mesh, testCase.State);
            lines = splitlines(string(fileread(path)));
            node = split(lines(find(startsWith(lines, "N,"), 1, 'last')), ",");
            last = size(testCase.State.displacement, 1);
            testCase.verifyEqual(str2double(node(2)), last);
            testCase.verifyEqual(str2double(node(3:5)).', ...
                double(single(testCase.State.displacement(last, :))), 'RelTol', 1e-5);
        end

        function ansysCannotWriteToAnInvalidPath(testCase)
            testCase.verifyError( ...
                @() ldem.io.exportAnsys(fullfile(testCase.tempFolder(), "missing", "x.mac"), ...
                    testCase.Mesh, testCase.State), 'ldem:io:cannotOpenFile');
        end

        function vtkFileIsValidXml(testCase)
            path = fullfile(testCase.tempFolder(), "state.vtu");
            ldem.io.exportVtk(path, testCase.Mesh, testCase.State);

            doc = xmlread(char(path));
            nNodes = size(testCase.Mesh.nodes0, 1);
            nBars = size(testCase.Mesh.bars, 1);

            piece = doc.getElementsByTagName('Piece').item(0);
            testCase.verifyEqual(double(string(piece.getAttribute('NumberOfPoints'))), nNodes);
            testCase.verifyEqual(double(string(piece.getAttribute('NumberOfCells'))), nBars);

            arrays = doc.getElementsByTagName('DataArray');
            names = strings(arrays.getLength(), 1);
            for k = 1:numel(names)
                names(k) = string(arrays.item(k - 1).getAttribute('Name'));
            end
            for expected = ["displacement", "velocity", "damageState", "strain", ...
                    "axialForce", "barType", "position", "connectivity", "offsets", "types"]
                testCase.verifyTrue(any(names == expected), "Missing array " + expected);
            end
        end

        function vtkArraysHaveTheRightNumberOfValues(testCase)
            path = fullfile(testCase.tempFolder(), "state.vtu");
            ldem.io.exportVtk(path, testCase.Mesh, testCase.State);
            doc = xmlread(char(path));
            nNodes = size(testCase.Mesh.nodes0, 1);
            nBars = size(testCase.Mesh.bars, 1);

            expected = dictionary("position", 3 * nNodes, "displacement", 3 * nNodes, ...
                "velocity", 3 * nNodes, "connectivity", 2 * nBars, "offsets", nBars, ...
                "types", nBars, "damageState", nBars, "strain", nBars, "axialForce", nBars);
            arrays = doc.getElementsByTagName('DataArray');
            for k = 0:arrays.getLength() - 1
                node = arrays.item(k);
                name = string(node.getAttribute('Name'));
                if isKey(expected, name)
                    values = sscanf(char(node.getTextContent()), '%f');
                    testCase.verifyEqual(numel(values), expected(name), "Wrong size of " + name);
                end
            end
        end

        function vtkConnectivityIsZeroBasedAndOffsetsAreCumulative(testCase)
            path = fullfile(testCase.tempFolder(), "state.vtu");
            ldem.io.exportVtk(path, testCase.Mesh, testCase.State);
            doc = xmlread(char(path));
            arrays = doc.getElementsByTagName('DataArray');
            data = struct();
            for k = 0:arrays.getLength() - 1
                node = arrays.item(k);
                data.(char(node.getAttribute('Name'))) = sscanf(char(node.getTextContent()), '%f');
            end
            testCase.verifyEqual(reshape(data.connectivity, 2, []).', testCase.Mesh.bars - 1);
            testCase.verifyEqual(data.offsets, 2 * (1:size(testCase.Mesh.bars, 1)).');
            testCase.verifyTrue(all(data.types == 3), 'Every cell must be a VTK_LINE (3).');
        end

        function vtkDamageStateMatchesTheBars(testCase)
            path = fullfile(testCase.tempFolder(), "state.vtu");
            ldem.io.exportVtk(path, testCase.Mesh, testCase.State);
            doc = xmlread(char(path));
            arrays = doc.getElementsByTagName('DataArray');
            for k = 0:arrays.getLength() - 1
                if string(arrays.item(k).getAttribute('Name')) == "damageState"
                    values = sscanf(char(arrays.item(k).getTextContent()), '%d');
                end
            end
            h = testCase.State.history;
            testCase.verifyEqual(nnz(values == 0), nnz(h.isUndamaged));
            testCase.verifyEqual(nnz(values == 2), nnz(~h.isUnbroken));
            testCase.verifyEqual(nnz(values == 1), nnz(~h.isUndamaged & h.isUnbroken));
        end

        function pvdListsTheFilesWithTheirTimes(testCase)
            path = fullfile(testCase.tempFolder(), "series.pvd");
            ldem.io.writePvd(path, [0; 1e-4; 2e-4], ["a.vtu"; "b.vtu"; "c.vtu"]);
            doc = xmlread(char(path));
            items = doc.getElementsByTagName('DataSet');
            testCase.verifyEqual(items.getLength(), 3);
            testCase.verifyEqual(string(items.item(1).getAttribute('file')), "b.vtu");
            testCase.verifyEqual(str2double(string(items.item(2).getAttribute('timestep'))), 2e-4);
        end

        function pvdRejectsMismatchedInputs(testCase)
            testCase.verifyError( ...
                @() ldem.io.writePvd(fullfile(testCase.tempFolder(), "x.pvd"), [0; 1], "a.vtu"), ...
                'ldem:io:sizeMismatch');
        end

        function snapshotWriterWritesFilesAndACollection(testCase)
            folder = fullfile(testCase.tempFolder(), "out");
            writer = ldem.io.SnapshotWriter(testCase.Mesh, folder, ["ansys" "vtk"]);
            writer.write(testCase.State);
            later = testCase.State;
            later.step = 10;
            later.time = 2e-6;
            writer.write(later);
            snapshots = writer.finish();

            for name = ["snapshot_0000.mac", "snapshot_0001.mac", "snapshot_0000.vtu", ...
                    "snapshot_0001.vtu", "snapshots.pvd"]
                testCase.verifyTrue(isfile(fullfile(folder, name)), name + " was not written.");
            end
            testCase.verifyEqual(snapshots.step, [testCase.State.step; 10]);
            testCase.verifySize(snapshots.barCounts, [2 3]);
            testCase.verifyEqual(sum(snapshots.barCounts, 2), repmat(size(testCase.Mesh.bars, 1), 2, 1));
            testCase.verifyClass(snapshots.displacement{1}, 'single');
            testCase.verifyClass(snapshots.damageState{1}, 'uint8');
        end

        function snapshotWriterKeepsSnapshotsInMemoryWithoutFiles(testCase)
            writer = ldem.io.SnapshotWriter(testCase.Mesh);
            writer.write(testCase.State);
            snapshots = writer.finish();
            testCase.verifyEqual(numel(snapshots.time), 1);
            testCase.verifyEqual(sum(snapshots.barCounts), size(testCase.Mesh.bars, 1));
        end

        function snapshotWriterNeedsAFolderToExport(testCase)
            testCase.verifyError(@() ldem.io.SnapshotWriter(testCase.Mesh, "", "vtk"), ...
                'ldem:io:noFolder');
        end

        function saveResultsRoundTrip(testCase)
            results = struct('a', magic(3), 'nested', struct('b', "text", 'c', {{1, 'x'}}));
            path = fullfile(testCase.tempFolder(), "sub", "results.mat");
            ldem.io.saveResults(path, results);
            loaded = load(path);
            testCase.verifyEqual(loaded.results, results);
        end
    end
end
