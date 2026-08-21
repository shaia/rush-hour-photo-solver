function [moves, stats] = solveDfid(puzzle, pos0, opts)
%SOLVEDFID Depth-first iterative deepening, the paper's baseline.
%   [moves, stats] = SOLVEDFID(puzzle, pos0, opts) runs a depth-bounded
%   depth-first search at bound 0, 1, 2, ... until a solution turns up, so
%   the first one found has the fewest possible *moves*.
%
%   Note what that does and does not promise: DFID minimises length, not
%   cost, and under this cost model those are different objectives — one
%   three-square slide costs 4 where three one-square slides cost 6. They
%   happen to coincide on all four bundled puzzles, which is why the paper's
%   DFID rows match its Uniform-Cost rows.
%
%   Cycles are cut by the keys on the current path rather than a closed set:
%   that is what keeps DFID's memory linear in the depth, which is its only
%   real advantage over the best-first searches.
    MAX_DEPTH = 64;                        % puzzle 3 needs 49; past this it is hopeless anyway

    expanded = 0;
    limitHit = "";
    found = false;
    ticker = tic;

    pathKeys = zeros(1, MAX_DEPTH + 1);
    pathVeh = zeros(1, MAX_DEPTH);
    pathDelta = zeros(1, MAX_DEPTH);
    pathKeys(1) = stateKey(puzzle, pos0);
    solDepth = 0;
    solCost = 0;
    bound = 0;

    for bound = 0:MAX_DEPTH
        found = descend(pos0, 0, 0);
        if found || limitHit ~= ""
            break
        end
    end

    if ~found
        if limitHit == ""
            limitHit = "depth";
        end
        [moves, stats] = noSolution(expanded, limitHit);
        return
    end

    moves = reconstructPath(puzzle, pathVeh(1:solDepth), pathDelta(1:solDepth));
    stats = struct('solved', true, 'length', solDepth, 'cost', solCost, ...
        'expanded', expanded, 'timeMs', 0, 'limitHit', limitHit);


    function ok = descend(dfsPos, dfsDepth, dfsG)
        ok = false;
        if dfsPos(1) >= puzzle.exitPos
            solDepth = dfsDepth;
            solCost = dfsG;
            ok = true;
            return
        end
        if dfsDepth >= bound
            return
        end

        expanded = expanded + 1;
        if expanded >= opts.maxExpanded
            limitHit = "expanded";
            return
        end
        if mod(expanded, 512) == 0 && toc(ticker) > opts.maxTime
            limitHit = "time";
            return
        end

        [posList, veh, delta, cost] = expandState(puzzle, dfsPos, occupancyGrid(puzzle, dfsPos));
        for k = 1:numel(veh)
            childPos = posList(k, :);
            childKey = stateKey(puzzle, childPos);
            if any(pathKeys(1:dfsDepth + 1) == childKey)
                continue                    % already standing on this state
            end
            pathKeys(dfsDepth + 2) = childKey;
            pathVeh(dfsDepth + 1) = veh(k);
            pathDelta(dfsDepth + 1) = delta(k);
            ok = descend(childPos, dfsDepth + 1, dfsG + cost(k));
            if ok || limitHit ~= ""
                return
            end
        end
    end
end
