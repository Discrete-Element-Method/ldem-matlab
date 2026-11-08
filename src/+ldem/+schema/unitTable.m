function [names, exps] = unitTable(dimension)
%UNITTABLE  Units accepted for a physical dimension in the case files.
%
%   [names, exps] = ldem.schema.unitTable(dimension) returns the unit names
%   and the decimal exponent of each one with respect to the SI unit, so that
%   1 <unit> = 10^exps SI units. The SI unit is the one with exponent 0.
%
%   Dimensions:
%
%     length     m, cm, mm, um, km
%     time       s, ms, us, ns
%     pressure   Pa, kPa, MPa, GPa
%     density    kg/m3, g/cm3
%     rate       1/s, 1/ms          (damping coefficient)
%     toughness  N/m, kN/m          (fracture energy)
%     velocity   m/s, mm/s
%     forcerate  N/s, kN/s
%     force      N, kN, MN
%     modules    modules            (length in module lengths)
%     number     no unit
%
%   Input:
%     dimension  One of the names above.
%
%   Outputs:
%     names  1-by-n string array of unit names ("" for a dimensionless value).
%     exps   1-by-n decimal exponents.
%
%   Errors:
%     ldem:schema:unknownDimension  The dimension does not exist.
%
%   Example:
%       [names, exps] = ldem.schema.unitTable("pressure");
%
%   See also ldem.schema.parseQuantity, ldem.schema.formatQuantity.

arguments
    dimension (1,1) string
end

switch dimension
    case "length"
        names = ["m" "cm" "mm" "um" "km"];
        exps  = [0 -2 -3 -6 3];
    case "time"
        names = ["s" "ms" "us" "ns"];
        exps  = [0 -3 -6 -9];
    case "pressure"
        names = ["Pa" "kPa" "MPa" "GPa"];
        exps  = [0 3 6 9];
    case "density"
        names = ["kg/m3" "g/cm3"];
        exps  = [0 3];
    case "rate"
        names = ["1/s" "1/ms"];
        exps  = [0 3];
    case "toughness"
        names = ["N/m" "kN/m"];
        exps  = [0 3];
    case "velocity"
        names = ["m/s" "mm/s"];
        exps  = [0 -3];
    case "forcerate"
        names = ["N/s" "kN/s"];
        exps  = [0 3];
    case "force"
        names = ["N" "kN" "MN"];
        exps  = [0 3 6];
    case "modules"
        names = "modules";
        exps  = 0;
    case "number"
        names = "";
        exps  = 0;
    otherwise
        error('ldem:schema:unknownDimension', 'Unknown dimension "%s".', dimension);
end
end
