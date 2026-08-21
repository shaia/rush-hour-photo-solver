function [posList, veh, delta, cost] = expandState(puzzle, pos, grid)
%EXPANDSTATE Every state reachable from pos in one move.
%   [posList, veh, delta, cost] = EXPANDSTATE(puzzle, pos, grid) returns one
%   successor per vehicle per reachable distance: posList(k,:) is the new
%   position vector, veh(k) the vehicle that moved, delta(k) its signed
%   distance (negative = left/up), and cost(k) = abs(delta) + 1.
%
%   The '+ 1' is the paper's cost model, not decoration — see
%   ../../docs/SPEC.md section 3. Sliding three squares at once is cheaper
%   than three single-square slides, which is why cost-optimal and
%   move-optimal solutions can differ.
%
%   The escape is deliberately not a special case. The target car, and only
%   it, and only along the exit row, may scan one column past the playfield
%   onto the gap; every other rule then applies unchanged and there is no
%   separate goal transition to keep in step.
    n = puzzle.n;
    sz = puzzle.size;

    posList = zeros(puzzle.maxMoves, n);  % a vehicle of length L has sz-L+1 positions,
    veh = zeros(puzzle.maxMoves, 1);      % so sz-L of them are moves away from here
    delta = zeros(puzzle.maxMoves, 1);
    cost = zeros(puzzle.maxMoves, 1);
    m = 0;

    for i = 1:n
        p = pos(i);
        f = puzzle.fixed(i);
        isH = puzzle.horiz(i);

        % Backward: left for a horizontal vehicle, up for a vertical one
        d = 1;
        while p - d >= 1
            if isH
                blocked = grid(f, p - d);
            else
                blocked = grid(p - d, f);
            end
            if blocked ~= 0
                break
            end
            m = m + 1;
            posList(m, :) = pos;
            posList(m, i) = p - d;
            veh(m) = i;
            delta(m) = -d;
            cost(m) = d + 1;
            d = d + 1;
        end

        % Forward: right or down, with the target car allowed onto the gap
        limit = sz;
        if i == 1 && isH && f == puzzle.exitRow
            limit = sz + 1;
        end
        d = 1;
        while p + puzzle.lens(i) - 1 + d <= limit
            tail = p + puzzle.lens(i) - 1 + d;
            if tail <= sz
                if isH
                    blocked = grid(f, tail);
                else
                    blocked = grid(tail, f);
                end
                if blocked ~= 0
                    break
                end
            end
            m = m + 1;
            posList(m, :) = pos;
            posList(m, i) = p + d;
            veh(m) = i;
            delta(m) = d;
            cost(m) = d + 1;
            d = d + 1;
        end
    end

    posList = posList(1:m, :);
    veh = veh(1:m);
    delta = delta(1:m);
    cost = cost(1:m);
end
