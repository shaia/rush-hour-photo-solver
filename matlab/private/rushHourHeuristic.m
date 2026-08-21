function h = rushHourHeuristic(puzzle, pos, grid, blockerPenalty)
%RUSHHOURHEURISTIC The paper's RushHourHeuristic3, in the units of g.
%   h = RUSHHOURHEURISTIC(puzzle, pos, grid, blockerPenalty) sums three
%   terms, as described in Reynisson & Hilmarsson section 1: "the exact cost
%   of moving one's car (A) to the exit, the exact cost of moving everything
%   out of A's way (B) and a cost of 2 for each car that's in the way of
%   those cars specified as B".
%
%   Term 2 considers walls only — a blocker's own obstructions are
%   deliberately ignored, which is what keeps the term cheap and, on its
%   own, admissible. Inf means provably unsolvable: a horizontal vehicle
%   sitting in the exit row can never leave it, and a vehicle walled in on
%   both sides of the exit row can never clear it. That second case cannot
%   arise on a 6x6 board with 2- and 3-cell vehicles — it needs both
%   e + len > 6 and e - len < 1 — so the branch is kept against a larger
%   board rather than exercised here.
%
%   blockerPenalty switches term 3, which is the paper's own wording but is
%   *not* admissible: measured across all 6458 states of puzzle 3 it
%   overestimates on 16 of them, by at most 1 (see ../../docs/design.md
%   section 3). It is on by default to stay faithful to the paper; Uniform-
%   Cost, never A*, is what the acceptance set trusts for optimality.
    target = 1;
    if pos(target) >= puzzle.exitPos
        h = 0;
        return
    end

    % Term 1: the exact cost of the escape move itself
    h = (puzzle.exitPos - pos(target)) + 1;

    % A vehicle covers consecutive cells, so scanning a line only ever sees
    % it in one run: dropping repeats of the previous entry deduplicates the
    % scan exactly, and far more cheaply than UNIQUE on a hot path
    firstAhead = pos(target) + puzzle.lens(target);
    ahead = grid(puzzle.exitRow, firstAhead:puzzle.size);
    ahead = ahead(ahead ~= 0);
    if isempty(ahead)
        return
    end
    blockers = double(ahead([true, ahead(2:end) ~= ahead(1:end-1)]));

    for k = blockers
        if puzzle.horiz(k)
            h = Inf;                       % nothing can push it off the exit row
            return
        end

        % Term 2: the cheaper of clearing the exit row upwards or downwards,
        % judged against the walls alone
        p = pos(k);
        len = puzzle.lens(k);
        e = puzzle.exitRow;
        up = p + len - e;                  % far enough that the tail clears e
        down = e - p + 1;                  % far enough that the head clears e

        best = Inf;
        sweep = [];
        if p - up >= 1
            best = up;
            sweep = p - up : p - 1;
        end
        if down < best && p + len - 1 + down <= puzzle.size
            best = down;
            sweep = p + len : p + len - 1 + down;
        end
        if isinf(best)
            h = Inf;                       % walled in on both sides of the exit row
            return
        end
        h = h + best + 1;

        % Term 3: every distinct car standing in the escape sweep costs 2
        if blockerPenalty
            inTheWay = grid(sweep, puzzle.fixed(k));
            inTheWay = inTheWay(inTheWay ~= 0);
            if ~isempty(inTheWay)
                h = h + 2 * (1 + sum(inTheWay(2:end) ~= inTheWay(1:end-1)));
            end
        end
    end
end
