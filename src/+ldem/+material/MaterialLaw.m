classdef (Abstract) MaterialLaw
    %MATERIALLAW  Base class of the constitutive laws of the bars.
    %
    %   A law says how the axial force of a bar depends on its strain, its
    %   strain rate and its history, and how much energy that state stores or
    %   dissipates. The solver never names a law: it asks the object chosen by
    %   params.constitutiveLaw (the key "law" of the [material] section of a
    %   case file).
    %
    %   To add a law:
    %     1. Create a subclass in this folder and set the constant property
    %        name (snake_case, the word used in the case file).
    %     2. Implement evaluate, energies, barDamageEnergy and viscousStiffness.
    %     3. Add a line to ldem.material.lawRegistry.
    %
    %   What every law can rely on and must respect:
    %
    %   * barProps is the struct of ldem.material.buildBarProperties (stiffness,
    %     criticalStrain, ruptureStrain, ruptureRatio, ...); history starts as
    %     its second output.
    %   * history must always keep the logical fields isUndamaged and
    %     isUnbroken: the bar counts, the ANSYS and VTK files and the snapshots
    %     read them. The other fields are private to the law.
    %   * evaluate is called once per step, with all the bars at once
    %     (vectors of nBars-by-1), and returns the history after the step.
    %
    %   See also ldem.material.BilinearBarLaw, ldem.material.LinearElasticBarLaw,
    %   ldem.material.lawRegistry, ldem.material.lawFromName.

    properties (Abstract, Constant)
        % Name used in the case file ("bilinear").
        name
    end

    methods (Abstract)
        % EVALUATE  Axial force of every bar and the history after the step.
        %
        %   [force, history] = law.evaluate(strain, strainRate, barProps, history, params)
        %
        %   Inputs:
        %     strain      nBars-by-1 strain (L - L0)/L0, tension positive.
        %     strainRate  nBars-by-1 strain rate [1/s].
        %     barProps    Struct from ldem.material.buildBarProperties.
        %     history     Struct with the state of every bar before the step.
        %     params      ldem.Parameters (params.constitutiveDamping is the
        %                 viscous coefficient of the law, in s).
        %
        %   Outputs:
        %     force    nBars-by-1 axial force [N], tension positive.
        %     history  The history after the step.
        [force, history] = evaluate(obj, strain, strainRate, barProps, history, params)

        % ENERGIES  Energies of all the bars, as scalars [J].
        %
        %   energy = law.energies(strain, barProps, history, barLength) returns a
        %   struct with the fields
        %     elastic     Strain energy stored in the bars.
        %     damage      Energy dissipated by softening in the damaged bars.
        %     brokenBars  Total fracture energy of the bars that have broken.
        energy = energies(obj, strain, barProps, history, barLength)

        % BARDAMAGEENERGY  Energy dissipated by damage in one bar [J].
        %
        %   value = law.barDamageEnergy(bar, barProps, history, barLength)
        %   for the bar with that number (zero if it is undamaged).
        value = barDamageEnergy(obj, bar, barProps, history, barLength)

        % VISCOUSSTIFFNESS  Stiffness of every bar in the viscous term [N].
        %
        %   stiffness = law.viscousStiffness(strain, barProps, history) is the
        %   stiffness E that multiplies the strain rate in the force of the law,
        %   E*constitutiveDamping*strainRate; the solver uses it to account for
        %   the energy dissipated by that term.
        stiffness = viscousStiffness(obj, strain, barProps, history)
    end
end
