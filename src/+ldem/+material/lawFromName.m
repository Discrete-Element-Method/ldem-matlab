function law = lawFromName(name)
%LAWFROMNAME  Create the constitutive-law object with a name used in the case files.
%
%   law = ldem.material.lawFromName(name) returns an instance of the class
%   registered under name in ldem.material.lawRegistry.
%
%   Input:
%     name  Law name, for example "bilinear" (case is ignored).
%
%   Output:
%     law  Object of a subclass of ldem.material.MaterialLaw.
%
%   Errors:
%     ldem:material:unknownLaw  No law has that name.
%
%   See also ldem.material.lawRegistry, ldem.material.MaterialLaw.

arguments
    name (1,1) string
end

reg = ldem.material.lawRegistry();
k = find([reg.name] == lower(name), 1);
if isempty(k)
    error('ldem:material:unknownLaw', ...
        'There is no constitutive law named "%s".%s Available: %s.', name, ...
        ldem.schema.suggest(name, [reg.name]), strjoin([reg.name], ', '));
end
law = feval(reg(k).className);
end
