function [moves, stats] = solveIdaStar(puzzle, pos0, opts)
%SOLVEIDASTAR Iterative deepening A*: DFID with a cost bound instead of a
%   depth bound.
%   [moves, stats] = SOLVEIDASTAR(puzzle, pos0, opts) searches depth-first
%   while f = g + h stays within the current bound, remembering the
%   smallest f that overshot it. That value becomes the next bound, so no
%   iteration is wasted on a threshold no state actually sits at.
%
%   Optimal when the heuristic is admissible — which the paper's default is
%   not, quite (../../docs/design.md section 3), so the acceptance set
%   anchors optimality on Uniform-Cost instead.
%
%   An exhausted search returns bound = Inf, which is a genuine proof that
%   no solution exists, and is reported with limitHit = "" to distinguish it
%   from a capped run.
    MAX_DEPTH = 256;                       % every move costs >= 2, so a bound of B
                                           % cannot reach deeper than B/2
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

    bound = rushHourHeuristic(puzzle, pos0, occupancyGrid(puzzle, pos0), opts.blockerPenalty);
    while ~isinf(bound)
        [found, nextBound] = descend(pos0, 0, 0);
        if found || limitHit ~= ""
            break
        end
        bound = nextBound;
    end

    if ~found
        [moves, stats] = noSolution(expanded, limitHit);
        return
    end

    moves = reconstructPath(puzzle, pathVeh(1:solDepth), pathDelta(1:solDepth));
    stats = struct('solved', true, 'length', solDepth, 'cost', solCost, ...
        'expanded', expanded, 'timeMs', 0, 'limitHit', limitHit);


    function [ok, minExceeded] = descend(dfsPos, dfsDepth, dfsG)
        ok = false;
        minExceeded = Inf;

        grid = occupancyGrid(puzzle, dfsPos);   % built once and used twice: this is the
        hVal = rushHourHeuristic(puzzle, dfsPos, grid, opts.blockerPenalty);
        if dfsG + hVal > bound
            minExceeded = dfsG + hVal;
            return
        end
        if dfsPos(1) >= puzzle.exitPos
            solDepth = dfsDepth;
            solCost = dfsG;
            ok = true;
            return
        end
        if dfsDepth >= MAX_DEPTH
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

        [posList, veh, delta, cost] = expandState(puzzle, dfsPos, grid);  % hottest loop in the file
        for k = 1:numel(veh)
            childPos = posList(k, :);
            childKey = stateKey(puzzle, childPos);
            if any(pathKeys(1:dfsDepth + 1) == childKey)
                continue
            end
            pathKeys(dfsDepth + 2) = childKey;
            pathVeh(dfsDepth + 1) = veh(k);
            pathDelta(dfsDepth + 1) = delta(k);
            [ok, childExceeded] = descend(childPos, dfsDepth + 1, dfsG + cost(k));
            if ok || limitHit ~= ""
                return
            end
            minExceeded = min(minExceeded, childExceeded);
        end
    end
end
