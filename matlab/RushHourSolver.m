function [moves, stats] = RushHourSolver(board, opts)
%RUSHHOURSOLVER Solve a Rush Hour puzzle with one of seven search algorithms.
%   [moves, stats] = RUSHHOURSOLVER(board) frees the target car A through
%   the exit and returns the move sequence. board is a puzzle file path, the
%   paper's 8x8 ASCII board as text, or a bare 6x6 char playfield.
%
%   moves is a struct array with one element per move:
%     letter   - the vehicle that moved
%     dir      - 'U', 'D', 'L' or 'R'
%     squares  - how far it slid
%
%   stats reports the run:
%     solved   - true when the target car escaped
%     length   - number of moves
%     cost     - total move cost; a move costs the squares it covers plus 1
%     expanded - states expanded
%     timeMs   - wall-clock milliseconds
%     limitHit - "" when the search ran to its own conclusion, otherwise
%                "expanded", "time" or "depth" — solved=false with a limit
%                hit is a run that gave up, not a puzzle with no solution
%
%   [moves, stats] = RUSHHOURSOLVER(board, method=M) selects the algorithm;
%   M is a SolveMethod member or its name as text:
%   'astar'    - (default) best-first on g + h: the practical default,
%                optimal whenever the heuristic is admissible
%   'uc'       - uniform-cost, best-first on g alone: the reference
%                optimum, since it needs no heuristic to be trusted
%   'ph'       - pure heuristic, best-first on h alone: fastest and
%                fewest states expanded, but the solution is usually far
%                from optimal
%   'dfid'     - depth-first iterative deepening on move count: minimal
%                *length*, which under this cost model is a different
%                thing from minimal cost; uses memory linear in the depth
%                and time exponential in it
%   'idastar'  - IDA*, the same search bounded by cost instead of depth;
%                as memory-thin as DFID and far better guided, but still
%                re-searches from the root on every iteration
%   'eidastar' - IDA* plus a transposition table, so a failed subtree
%                teaches the next iteration what it learned; the only
%                low-memory method that copes with hard boards
%   'rtastar'  - real-time A*: no lookahead at all, one committed move at
%                a time; always returns a walk that reaches the exit, never
%                a short one
%
%   Options:
%   maxExpanded     - stop after this many expansions (default 5e6)
%   maxTime         - stop after this many seconds (default 120)
%   blockerPenalty  - include the heuristic's "+2 per car in a blocker's
%                     way" term (default true). The term is the paper's,
%                     but it is mildly inadmissible; turn it off to search
%                     with the provably admissible remainder
%
%   See also SOLVEMETHOD.

arguments
    board
    opts.method (1,1) SolveMethod = SolveMethod.astar
    opts.maxExpanded (1,1) double {mustBePositive} = 5e6
    opts.maxTime (1,1) double {mustBePositive} = 120
    opts.blockerPenalty (1,1) logical = true
end

[puzzle, pos0] = parseBoard(board);

ticker = tic;
switch opts.method
    case SolveMethod.dfid
        [moves, stats] = solveDfid(puzzle, pos0, opts);
    case SolveMethod.uc
        [moves, stats] = bestFirstSearch(puzzle, pos0, [1 0], opts);
    case SolveMethod.ph
        [moves, stats] = bestFirstSearch(puzzle, pos0, [0 1], opts);
    case SolveMethod.astar
        [moves, stats] = bestFirstSearch(puzzle, pos0, [1 1], opts);
    case SolveMethod.idastar
        [moves, stats] = solveIdaStar(puzzle, pos0, opts);
    case SolveMethod.eidastar
        [moves, stats] = solveEidaStar(puzzle, pos0, opts);
    case SolveMethod.rtastar
        [moves, stats] = solveRtaStar(puzzle, pos0, opts);
end
stats.timeMs = toc(ticker) * 1000;
end
