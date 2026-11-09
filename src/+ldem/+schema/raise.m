function raise(id, where, message, varargin)
%RAISE  Throw an error that points at a place in a case file.
%
%   ldem.schema.raise(id, where, message, args...) formats the message with
%   sprintf and throws it with the identifier id. When where is not empty,
%   for example "case.ldem:14 [time] step", the message starts with it so the
%   user knows which line to edit.
%
%   Inputs:
%     id       Error identifier, for example "ldem:case:unknownKey".
%     where    Location text, or "" for none.
%     message  sprintf format.
%     args     Values for the format.
%
%   See also ldem.io.readCase.

text = sprintf(message, varargin{:});
if strlength(string(where)) > 0
    text = char(string(where) + ": " + string(text));
end
error(id, '%s', text);
end
