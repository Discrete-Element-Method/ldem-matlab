function [force, history] = bilinearLaw(strain, strainRate, barProps, history, constitutiveDamping)
%BILINEARLAW  Axial force of the bars: elastic, softening and rupture.
%
%   [force, history] = ldem.material.bilinearLaw(strain, strainRate, ...
%   barProps, history, constitutiveDamping) evaluates the constitutive law
%   of all bars at once and updates their damage state.
%
%   The force follows one of four branches, chosen per bar:
%
%     1. Rupture      strain >= ER: force is zero, the bar is broken for
%                     good (tension stiffness becomes zero).
%     2. Softening    strain >= EM (a new largest strain, above EP): the
%                     force decreases linearly with strain, reaching zero
%                     at ER. The tension stiffness becomes the secant
%                     stiffness F/strain and EM is updated.
%     3. Tension      0 <= strain < EM: linear with the current tension
%                     stiffness E2. This is the elastic response of an
%                     undamaged bar and the unloading/reloading of a damaged
%                     one (damage is irreversible).
%     4. Compression  strain < 0: linear with stiffness E1, damage has no
%                     effect (contact).
%
%   A viscous term  stiffness*constitutiveDamping*strainRate  is added in
%   branches 2, 3 and 4.
%
%   Inputs:
%     strain               nBars-by-1 axial strains (tension positive).
%     strainRate           nBars-by-1 strain rates [1/s].
%     barProps             Struct from ldem.material.buildBarProperties.
%     history              Damage state of the previous call or the initial one.
%     constitutiveDamping  Damping coefficient [s] (params.constitutiveDamping).
%
%   Outputs:
%     force    nBars-by-1 axial forces [N], tension positive.
%     history  Updated damage state.
%
%   Example:
%       [barProps, history] = ldem.material.buildBarProperties(mesh, params);
%       damping = params.constitutiveDamping;
%       [force, history] = ldem.material.bilinearLaw(strain, rate, barProps, history, damping);
%
%   Legacy: the constitutive branches inside CABAR (and CONSTIT).
%
%   See also ldem.material.buildBarProperties.

arguments
    strain (:,1) double
    strainRate (:,1) double
    barProps (1,1) struct
    history (1,1) struct
    constitutiveDamping (1,1) double {mustBeNonnegative}
end

nBars = numel(strain);
if numel(strainRate) ~= nBars || numel(barProps.stiffness) ~= nBars
    error('ldem:material:sizeMismatch', ...
        'strain (%d), strainRate (%d) and the bar properties (%d) must have one entry per bar.', ...
        nBars, numel(strainRate), numel(barProps.stiffness));
end

E1 = barProps.stiffness;
EP = barProps.criticalStrain;
KR = barProps.ruptureRatio;
ER = KR .* EP;

E2 = history.tensionStiffness;
EM = history.maxStrain;
isUndamaged = history.isUndamaged;
isUnbroken  = history.isUnbroken;

% Select the branch of every bar. The branches are mutually exclusive.
broken      = strain >= ER;
softening   = ~broken & (strain >= EM);
tension     = ~broken & ~softening & (strain >= 0.0);
compression = ~broken & ~softening & ~tension;

force = zeros(nBars, 1);

% 1. Rupture.
E2(broken) = 0.0;
EM(broken) = ER(broken);
isUndamaged(broken & isUnbroken) = false;
isUnbroken(broken)               = false;
% force stays 0.

% 2. Softening.
s = softening;
aux = (strain(s) - EP(s)) ./ (KR(s) - 1.0);
aux = E1(s) .* (EP(s) - aux);
E2(s) = aux ./ strain(s);
EM(s) = strain(s);
force(s) = aux + E2(s) .* constitutiveDamping .* strainRate(s);
isUndamaged(s) = false;

% 3. Tension (elastic or unloading).
t = tension;
force(t) = E2(t) .* strain(t) + E2(t) .* constitutiveDamping .* strainRate(t);

% 4. Compression.
c = compression;
force(c) = E1(c) .* strain(c) + E1(c) .* constitutiveDamping .* strainRate(c);

history.tensionStiffness = E2;
history.maxStrain        = EM;
history.isUndamaged      = isUndamaged;
history.isUnbroken       = isUnbroken;
end
