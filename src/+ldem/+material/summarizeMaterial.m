function summary = summarizeMaterial(barProps, params)
%SUMMARIZEMATERIAL  Material data and derived quantities, for the results file.
%
%   summary = ldem.material.summarizeMaterial(barProps, params) collects the
%   material parameters, the lattice coefficients and the statistics of the
%   critical strain in one struct, so that a results file documents the
%   material that was simulated.
%
%   Fields of summary:
%
%     youngModulus        E [Pa]
%     poissonRatio        nu
%     density             rho [kg/m^3]
%     waveSpeed           sqrt(E/rho) [m/s]
%     fractureEnergy      Gf [N/m]
%     criticalDistance    equivalent distance deq [m]
%     failureAreaFactor   CAF
%     delta               lattice coefficient delta
%     alpha               lattice coefficient alpha
%     normalStiffness     alpha*E*L^2 of a bar with the length of a module [N]
%     diagonalStiffness   normalStiffness times the diagonal factor [N]
%     criticalLength      Lcr = 2*deq*CAF/alpha [m]
%     ruptureRatioNormal  Lcr divided by the module length (KR of a normal bar)
%     baseCriticalStrain  sqrt(Gf/(E*deq)), before the random field
%     criticalStrainMean  mean of the critical strain EP of all bars
%     criticalStrainCv    coefficient of variation of EP
%     criticalStrainMin   smallest EP
%     criticalStrainMax   largest EP
%     randomField         where the random field came from and its
%                         statistics (barProps.randomFieldInfo); the value
%                         of each bar is barProps.randomField
%
%   Input:
%     barProps  Struct from ldem.material.buildBarProperties.
%     params    ldem.Parameters.
%
%   Output:
%     summary  Struct with the fields above.
%
%   Example:
%       material = ldem.material.summarizeMaterial(barProps, params);
%
%   Legacy: the material block of WRICON (EPMAX and EPMIN were never updated
%   there and COEV was never stored, see docs/known-issues/KNOWN_ISSUES.md).
%
%   See also ldem.material.buildBarProperties, ldem.mesh.summarizeModel.

arguments
    barProps (1,1) struct
    params (1,1) ldem.Parameters
end

[delta, alpha] = ldem.material.latticeCoefficients(params.poissonRatio);
normalStiffness = alpha * params.youngModulus * params.moduleLength^2;
diagonalFactor = (2.0 * delta * (4.0 / 3.0)) / sqrt(3.0);
criticalLength = params.criticalDistance * 2.0 * params.failureAreaFactor / alpha;

summary = struct();
summary.youngModulus       = params.youngModulus;
summary.poissonRatio       = params.poissonRatio;
summary.density            = params.density;
summary.waveSpeed          = params.waveSpeed;
summary.fractureEnergy     = params.fractureEnergy;
summary.criticalDistance   = params.criticalDistance;
summary.failureAreaFactor  = params.failureAreaFactor;
summary.delta              = delta;
summary.alpha              = alpha;
summary.normalStiffness    = normalStiffness;
summary.diagonalStiffness  = normalStiffness * diagonalFactor;
summary.criticalLength     = criticalLength;
summary.ruptureRatioNormal = criticalLength / params.moduleLength;
summary.baseCriticalStrain = sqrt(params.fractureEnergy / (params.youngModulus * params.criticalDistance));
summary.criticalStrainMean = barProps.criticalStrainMean;
summary.criticalStrainCv   = barProps.criticalStrainCv;
summary.criticalStrainMin  = min(barProps.criticalStrain);
summary.criticalStrainMax  = max(barProps.criticalStrain);
summary.randomField        = barProps.randomFieldInfo;
end
