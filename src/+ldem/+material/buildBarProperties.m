function [barProps, history] = buildBarProperties(mesh, params, options)
%BUILDBARPROPERTIES  Material properties and initial damage state of every bar.
%
%   [barProps, history] = ldem.material.buildBarProperties(mesh, params)
%   computes everything the constitutive law of the bars needs.
%
%   Every bar behaves as follows (see ldem.material.bilinearLaw): linear
%   elastic with stiffness E1 up to the critical strain EP, then linear
%   softening down to zero force at the rupture strain ER = KR*EP. The
%   fracture energy is what fixes EP and KR:
%
%       EP0 = sqrt(Gf / (E * deq))            critical strain
%       Lcr = 2 * deq * CAF / alpha           critical length
%       KR  = Lcr / L                         rupture strain / critical strain
%
%   with the material data of ldem.Parameters, the failure-area factor CAF
%   and the lattice coefficient alpha. EP is EP0 times a random field when
%   params.randomFieldFile is set.
%
%   Inputs:
%     mesh    Struct from ldem.mesh.buildMesh.
%     params  ldem.Parameters.
%
%   Name-value options:
%     RandomField  nBars-by-1 vector of multipliers of the critical strain.
%                  Overrides params.randomFieldFile. Default: use the file
%                  if there is one, otherwise all ones.
%
%   Outputs:
%     barProps  Struct of properties that stay constant during the simulation.
%     history   Struct with the initial damage state of every bar.
%
%   Fields of barProps (nBars-by-1 unless stated otherwise):
%
%     stiffness           E1, axial stiffness [N]
%     criticalStrain      EP, strain at which damage starts
%     ruptureRatio        KR, ratio between rupture and critical strain
%     ruptureStrain       ER = KR*EP, strain at which the bar breaks
%     criticalStrainMean  scalar, mean of EP
%     criticalStrainCv    scalar, coefficient of variation of EP
%
%   Fields of history (nBars-by-1), updated by ldem.material.bilinearLaw:
%
%     tensionStiffness    E2, secant stiffness in tension (starts at E1)
%     maxStrain           EM, largest strain reached (starts at EP)
%     isUndamaged         DM, false once the bar has started to soften
%     isUnbroken          FS, false once the bar has broken
%
%   Errors:
%     ldem:material:criticalLengthTooShort  KR is below 1.01 for some bar;
%         the softening branch needs KR > 1. Increase params.criticalDistance
%         or reduce params.moduleLength.
%
%   Example:
%       params = ldem.Parameters();
%       mesh = ldem.mesh.buildMesh(params);
%       [barProps, history] = ldem.material.buildBarProperties(mesh, params);
%
%   Legacy: NAYFES0, RMEC, the random-field loop of the main program, CALCOEV.
%
%   See also ldem.material.bilinearLaw, ldem.material.computeBarStiffness,
%   ldem.io.readRandomField.

arguments
    mesh (1,1) struct
    params (1,1) ldem.Parameters
    options.RandomField (:,1) double = []
end

nBars = numel(mesh.barLength);
[~, alpha] = ldem.material.latticeCoefficients(params.poissonRatio);

stiffness = ldem.material.computeBarStiffness(mesh, params);

baseCriticalStrain = sqrt(params.fractureEnergy ./ (params.youngModulus .* params.criticalDistance));
criticalLength     = params.criticalDistance * 2.0 * params.failureAreaFactor / alpha;
ruptureRatio       = criticalLength ./ mesh.barLength;

if any(ruptureRatio < 1.01)
    error('ldem:material:criticalLengthTooShort', ...
        ['The critical length (%g m) is too short compared with the bar length ' ...
         '(%g m): rupture ratio KR = %g < 1.01. Increase criticalDistance or ' ...
         'reduce moduleLength.'], criticalLength, max(mesh.barLength), min(ruptureRatio));
end

% Random scatter of the critical strain.
if ~isempty(options.RandomField)
    field = options.RandomField;
elseif strlength(params.randomFieldFile) > 0
    field = ldem.io.readRandomField(params.randomFieldFile, nBars);
else
    field = ones(nBars, 1);
end
if numel(field) ~= nBars
    error('ldem:material:randomFieldSize', ...
        'The random field has %d values but the mesh has %d bars.', numel(field), nBars);
end
criticalStrain = field .* baseCriticalStrain;

barProps = struct();
barProps.stiffness          = stiffness;
barProps.criticalStrain     = criticalStrain;
barProps.ruptureRatio       = ruptureRatio;
barProps.ruptureStrain      = ruptureRatio .* criticalStrain;
barProps.criticalStrainMean = mean(criticalStrain);
barProps.criticalStrainCv   = std(criticalStrain) / mean(criticalStrain);

history = struct();
history.tensionStiffness = stiffness;
history.maxStrain        = criticalStrain;
history.isUndamaged      = true(nBars, 1);
history.isUnbroken       = true(nBars, 1);
end
