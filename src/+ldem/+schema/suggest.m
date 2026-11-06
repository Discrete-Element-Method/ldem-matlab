function text = suggest(word, candidates)
%SUGGEST  Ask "did you mean ...?" for a mistyped word.
%
%   text = ldem.schema.suggest(word, candidates) returns a sentence such as
%   " Did you mean 'young_modulus'?" when one of the candidates is close to
%   word (small edit distance), and "" otherwise. The sentence starts with a
%   space so it can be appended to an error message.
%
%   Inputs:
%     word        The word that was written.
%     candidates  String array of valid words.
%
%   Output:
%     text  String scalar.
%
%   Example:
%       ldem.schema.suggest("young_modulos", ["young_modulus" "density"])
%
%   See also ldem.io.readCase.

arguments
    word (1,1) string
    candidates (1,:) string
end

best = "";
bestDistance = inf;
for candidate = candidates
    d = editDistance(char(lower(word)), char(lower(candidate)));
    if d < bestDistance
        bestDistance = d;
        best = candidate;
    end
end
limit = max(2, floor(strlength(word) / 3));
if bestDistance <= limit
    text = " Did you mean '" + best + "'?";
else
    text = "";
end
end

function d = editDistance(a, b)
%EDITDISTANCE  Levenshtein distance between two char vectors.
previous = 0:numel(b);
for i = 1:numel(a)
    current = zeros(1, numel(b) + 1);
    current(1) = i;
    for j = 1:numel(b)
        cost = double(a(i) ~= b(j));
        current(j + 1) = min([previous(j + 1) + 1, current(j) + 1, previous(j) + cost]);
    end
    previous = current;
end
d = previous(end);
end
