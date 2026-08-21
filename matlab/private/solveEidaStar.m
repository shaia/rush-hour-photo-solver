function [moves, stats] = solveEidaStar(puzzle, pos0, opts)
%SOLVEEIDASTAR IDA* with a transposition table.
%   [moves, stats] = SOLVEEIDASTAR(puzzle, pos0, opts) is SOLVEIDASTAR plus
%   a transposition table, which turns each failed subtree search into
%   knowledge the next iteration can use.
%
%   Two things are worth recording about a state whose search failed:
%     limit - the budget it was searched with, so a later visit with no more
%             to spend can be turned away without looking
%     h     - every f below it overshot the bound, so the smallest of those
%             is a better lower bound on its remaining cost than the
%             heuristic gave
%   The paper's TTEntry also carries the cost of reaching the state. This
%   formulation has no use for it: what is learned is a property of the
%   state, not of the path that found it, and stays true however cheaply the
%   state is reached next time.
%
%   No eviction policy, as in the paper — at this scale the table never
%   grows large enough to need one.
%
%   The raised values are learned along one path each, while cycles are cut
%   by the path set, so a value can be pessimistic in a context it was not
%   learned in. That costs optimality, not correctness: EIDA* here, as in
%   the paper (51/136 where its own A* found 49/134), may return a valid but
%   longer solution. The acceptance set asks it only for a real solution.
    MAX_DEPTH = 256;

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

    startKey = stateKey(puzzle, pos0);
    startH = rushHourHeuristic(puzzle, pos0, occupancyGrid(puzzle, pos0), opts.blockerPenalty);
    ttIndex = dictionary(startKey, 1);
    ttCount = 1;
    ttLimit = -ones(1024, 1);              % -1: never searched, so no budget to compare against
    ttH = zeros(1024, 1);
    ttH(1) = startH;

    bound = startH;
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

        key = stateKey(puzzle, dfsPos);
        grid = occupancyGrid(puzzle, dfsPos);   % built once and used twice
        hVal = rushHourHeuristic(puzzle, dfsPos, grid, opts.blockerPenalty);
        row = 0;
        if isKey(ttIndex, key)
            row = ttIndex(key);
            if ttLimit(row) >= bound - dfsG
                % Searched before with at least this much budget, and it failed
                minExceeded = dfsG + ttH(row);
                return
            end
            hVal = max(hVal, ttH(row));     % what that earlier failed search proved
        end
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

        [posList, veh, delta, cost] = expandState(puzzle, dfsPos, grid);
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

        % An infinite overshoot means every successor was already on the path,
        % which is a fact about this path and not about the state — recording
        % it would claim the state is unsolvable everywhere
        if isfinite(minExceeded)
            rememberEntry(key, row, bound - dfsG, minExceeded - dfsG);
        end
    end

    function rememberEntry(entryKey, entryRow, entryLimit, entryH)
        if entryRow == 0
            ttCount = ttCount + 1;
            if ttCount > numel(ttH)
                grown = 2 * numel(ttH);
                ttLimit(numel(ttLimit) + 1:grown) = -1;
                ttH(numel(ttH) + 1:grown) = 0;
            end
            entryRow = ttCount;
            ttIndex(entryKey) = entryRow;
        end
        ttLimit(entryRow) = max(ttLimit(entryRow), entryLimit);
        ttH(entryRow) = max(ttH(entryRow), entryH);
    end
end
