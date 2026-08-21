function [moves, stats] = solveRtaStar(puzzle, pos0, opts)
%SOLVERTASTAR Real-time A*: commit to a move, then think again.
%   [moves, stats] = SOLVERTASTAR(puzzle, pos0, opts) never searches ahead.
%   It looks one move out, steps to the successor with the smallest
%   c + h, and — this is the whole of Korf's idea — records the
%   *second*-best value as the state it just left. A state is worth what
%   you would get by coming back to it and taking your next-best option, so
%   dead ends inflate behind the agent and it stops re-entering them.
%
%   The returned solution is the walk the agent actually took, cycles and
%   all, so it is a real solution but rarely a short one. No optimality is
%   claimed and none is asserted: the paper's own RTA* rows are
%   self-contradictory ("it's also obvious from the results that RTA* is not
%   showing correct cost, but the error behind that wasn't found"), so they
%   are not a target.
%
%   With only one successor the second best is infinite, which marks the
%   state as somewhere never worth returning to.
    expanded = 0;
    limitHit = "";
    found = false;
    ticker = tic;

    capacity = 1024;
    walkVeh = zeros(capacity, 1);
    walkDelta = zeros(capacity, 1);
    steps = 0;

    pos = pos0;
    cost = 0;
    hTable = dictionary(stateKey(puzzle, pos0), ...
        rushHourHeuristic(puzzle, pos0, occupancyGrid(puzzle, pos0), opts.blockerPenalty));

    while true
        if pos(1) >= puzzle.exitPos
            found = true;
            break
        end

        expanded = expanded + 1;
        if expanded >= opts.maxExpanded
            limitHit = "expanded";
            break
        end
        if mod(expanded, 512) == 0 && toc(ticker) > opts.maxTime
            limitHit = "time";
            break
        end

        [posList, veh, delta, cost1] = expandState(puzzle, pos, occupancyGrid(puzzle, pos));
        if isempty(veh)
            break                           % nothing can move: a stuck board
        end

        f = zeros(numel(veh), 1);
        for k = 1:numel(veh)
            childKey = stateKey(puzzle, posList(k, :));
            if isKey(hTable, childKey)
                childH = hTable(childKey);
            else
                childH = rushHourHeuristic(puzzle, posList(k, :), ...
                    occupancyGrid(puzzle, posList(k, :)), opts.blockerPenalty);
                hTable(childKey) = childH;
            end
            f(k) = cost1(k) + childH;
        end

        [~, choice] = min(f);
        runnerUp = f;
        runnerUp(choice) = Inf;
        hTable(stateKey(puzzle, pos)) = min(runnerUp);

        steps = steps + 1;
        if steps > numel(walkVeh)
            walkVeh(2 * numel(walkVeh)) = 0;
            walkDelta(2 * numel(walkDelta)) = 0;
        end
        walkVeh(steps) = veh(choice);
        walkDelta(steps) = delta(choice);
        cost = cost + cost1(choice);
        pos = posList(choice, :);
    end

    if ~found
        [moves, stats] = noSolution(expanded, limitHit);
        return
    end

    moves = reconstructPath(puzzle, walkVeh(1:steps), walkDelta(1:steps));
    stats = struct('solved', true, 'length', steps, 'cost', cost, ...
        'expanded', expanded, 'timeMs', 0, 'limitHit', limitHit);
end
