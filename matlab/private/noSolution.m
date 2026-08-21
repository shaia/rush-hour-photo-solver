function [moves, stats] = noSolution(expanded, limitHit)
%NOSOLUTION The empty result every solver returns when it comes back empty.
%   [moves, stats] = NOSOLUTION(expanded, limitHit) covers both endings —
%   the search space was exhausted, or a cap stopped it. limitHit ("",
%   "expanded" or "time") is what tells them apart, and it matters: a capped
%   run must never be read as proof that no solution exists.
    moves = struct('letter', {}, 'dir', {}, 'squares', {});
    stats = struct('solved', false, 'length', 0, 'cost', 0, ...
        'expanded', expanded, 'timeMs', 0, 'limitHit', limitHit);
end
