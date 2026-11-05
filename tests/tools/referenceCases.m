function cases = referenceCases()
%REFERENCECASES  Definitions of the small simulations used as golden masters.
%
%   cases = referenceCases() returns a struct array. Each element describes
%   one LDEM run that is small enough to execute in seconds but exercises a
%   different part of the code:
%
%     tension101_elastic  TEST 101, elastic response only (no damage)
%     tension101_damage   TEST 101, low fracture energy -> softening + rupture
%     bending102          TEST 102, beam with supports and reaction output
%
%   Fields of every case:
%     name          Unique identifier (also the fixture file name).
%     test          Test number written to DATA0.DAT (101 or 102).
%     modules       [M N L] number of nodes along x, y, z.
%     nSteps        Number of time steps to integrate.
%     fractureEnergy  GFR, specific fracture energy [N/m].
%     ansysEvery    OU3: write an ANSYS file every n steps.
%     everyN        OU6..OU9: write the other outputs every n steps.
%
%   The remaining material and numerical parameters are shared (see below).
%
%   See also generateReference, runLegacyCase, writeDataFile.

shared = struct( ...
    'seed',          123, ...
    'moduleLength',  0.003, ...      % [m]
    'damping1',      25000, ...      % DF1 [1/s]
    'damping2',      15000, ...      % DF2 [1/s], differs from DF1 to test the switch
    'dampingSwitchTime', 2e-5, ...  % TDAF [s] -> switch at step 100
    'con',           0, ...
    'dt',            2e-7, ...       % [s]
    'controlNodes',  [1 2], ...
    'poisson',       0.25, ...
    'density',       2000, ...       % [kg/m^3]
    'youngModulus',  32e9, ...       % [Pa]
    'criticalDistance', 0.028);      % DEQ [m]

specs = { ...
    % name                  test  modules     nSteps  GFR   OU3  everyN
    'tension101_elastic',   101,  [6 3 3],     200,   50.0, 100, 10; ...
    'tension101_damage',    101,  [6 3 3],    1000,    0.1, 500, 20; ...
    'bending102',           102,  [70 4 3],    150,    0.5,  75, 10};

cases = repmat(shared, size(specs, 1), 1);
for k = 1:size(specs, 1)
    cases(k).name           = specs{k, 1};
    cases(k).test           = specs{k, 2};
    cases(k).modules        = specs{k, 3};
    cases(k).nSteps         = specs{k, 4};
    cases(k).fractureEnergy = specs{k, 5};
    cases(k).ansysEvery     = specs{k, 6};
    cases(k).everyN         = specs{k, 7};
end
end
