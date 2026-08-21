function [moves, stats] = bestFirstSearch(puzzle, pos0, weights, opts)
%BESTFIRSTSEARCH The one search behind Uniform-Cost, Pure-Heuristic and A*.
%   [moves, stats] = BESTFIRSTSEARCH(puzzle, pos0, weights, opts) orders the
%   open list by weights(1)*g + weights(2)*h, which is the only thing that
%   separates the three algorithms — [1 0] is Uniform-Cost, [0 1] is
%   Pure-Heuristic, [1 1] is A*. The paper's own implementation shares one
%   class the same way, overriding only the cost function.
%
%   The open list is an array-backed binary min-heap with lazy deletion: a
%   state whose g improves is pushed again rather than located and sifted
%   into place, and the stale copy is dropped when it surfaces. bestG
%   doubles as the closed set, so a state is expanded only on the cheapest
%   path known to it.
%
%   States live in parallel arrays that double when full, each recording its
%   parent and the move that reached it, so the solution is a walk back up
%   the parents and nothing has to be carried along the search.
    n = puzzle.n;
    useH = weights(2) ~= 0;

    capacity = 1024;
    posStore = zeros(capacity, n);
    gScore = zeros(capacity, 1);
    parent = zeros(capacity, 1);
    moveVeh = zeros(capacity, 1);
    moveDelta = zeros(capacity, 1);

    heapF = zeros(capacity, 1);
    heapNode = zeros(capacity, 1);
    heapSize = 0;

    expanded = 0;
    limitHit = "";
    goalNode = 0;
    ticker = tic;

    startH = 0;
    if useH
        startH = rushHourHeuristic(puzzle, pos0, occupancyGrid(puzzle, pos0), opts.blockerPenalty);
    end
    if isinf(startH)
        [moves, stats] = noSolution(expanded, limitHit);
        return
    end

    numStates = 1;
    posStore(1, :) = pos0;
    bestG = dictionary(stateKey(puzzle, pos0), 0);
    heapPush(weights(2) * startH, 1);

    while heapSize > 0
        node = heapPop();
        pos = posStore(node, :);
        g = gScore(node);
        if g > bestG(stateKey(puzzle, pos))
            continue                        % stale heap entry: a cheaper path won
        end
        if pos(1) >= puzzle.exitPos
            goalNode = node;
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

        [posList, veh, delta, cost] = expandState(puzzle, pos, occupancyGrid(puzzle, pos));
        for k = 1:numel(veh)
            childPos = posList(k, :);
            childKey = stateKey(puzzle, childPos);
            childG = g + cost(k);
            if isKey(bestG, childKey) && bestG(childKey) <= childG
                continue
            end
            childH = 0;
            if useH
                childH = rushHourHeuristic(puzzle, childPos, ...
                    occupancyGrid(puzzle, childPos), opts.blockerPenalty);
                if isinf(childH)
                    continue                % provably unsolvable: never worth a slot
                end
            end

            bestG(childKey) = childG;
            numStates = numStates + 1;
            if numStates > size(posStore, 1)
                growStates();
            end
            posStore(numStates, :) = childPos;
            gScore(numStates) = childG;
            parent(numStates) = node;
            moveVeh(numStates) = veh(k);
            moveDelta(numStates) = delta(k);
            heapPush(weights(1) * childG + weights(2) * childH, numStates);
        end
    end

    if goalNode == 0
        [moves, stats] = noSolution(expanded, limitHit);
        return
    end

    depth = 0;
    walk = goalNode;
    while parent(walk) ~= 0
        depth = depth + 1;
        walk = parent(walk);
    end
    pathVeh = zeros(1, depth);
    pathDelta = zeros(1, depth);
    walk = goalNode;
    for m = depth:-1:1
        pathVeh(m) = moveVeh(walk);
        pathDelta(m) = moveDelta(walk);
        walk = parent(walk);
    end
    moves = reconstructPath(puzzle, pathVeh, pathDelta);
    stats = struct('solved', true, 'length', depth, 'cost', gScore(goalNode), ...
        'expanded', expanded, 'timeMs', 0, 'limitHit', limitHit);


    function growStates()
        grown = 2 * size(posStore, 1);
        posStore(grown, :) = 0;
        gScore(grown) = 0;
        parent(grown) = 0;
        moveVeh(grown) = 0;
        moveDelta(grown) = 0;
    end

    function heapPush(pushF, pushNode)
        heapSize = heapSize + 1;
        if heapSize > numel(heapF)
            heapF(2 * numel(heapF)) = 0;
            heapNode(2 * numel(heapNode)) = 0;
        end
        heapF(heapSize) = pushF;
        heapNode(heapSize) = pushNode;
        rising = heapSize;
        while rising > 1
            above = floor(rising / 2);
            if heapF(above) <= heapF(rising)
                break
            end
            [heapF(above), heapF(rising)] = deal(heapF(rising), heapF(above));
            [heapNode(above), heapNode(rising)] = deal(heapNode(rising), heapNode(above));
            rising = above;
        end
    end

    function popped = heapPop()
        popped = heapNode(1);
        heapF(1) = heapF(heapSize);
        heapNode(1) = heapNode(heapSize);
        heapSize = heapSize - 1;
        sinking = 1;
        while true
            left = 2 * sinking;
            small = sinking;
            if left <= heapSize && heapF(left) < heapF(small)
                small = left;
            end
            if left + 1 <= heapSize && heapF(left + 1) < heapF(small)
                small = left + 1;
            end
            if small == sinking
                break
            end
            [heapF(sinking), heapF(small)] = deal(heapF(small), heapF(sinking));
            [heapNode(sinking), heapNode(small)] = deal(heapNode(small), heapNode(sinking));
            sinking = small;
        end
    end
end
