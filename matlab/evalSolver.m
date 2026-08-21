function pass = evalSolver(opts)
%EVALSOLVER Run every algorithm on every bundled puzzle and check the results.
%   EVALSOLVER prints a Table-1-shaped report over ../data/puzzles and
%   judges each run against the acceptance set in ../docs/SPEC.md section 7.
%
%   pass = EVALSOLVER returns true when nothing failed, so the harness can
%   be used as a gate:
%       matlab -batch "cd matlab; assert(evalSolver)"
%
%   Every outcome here is decided by the *expansion* cap, never by the
%   clock: at 1e5 expansions DFID and IDA* give up on puzzle 3 and
%   everything else finishes, on any machine. The time cap is a backstop set
%   far enough out that a loaded machine cannot change a verdict — which it
%   otherwise does, since EIDA* needs 57166 expansions on puzzle 3 and lands
%   either side of a 30-second line depending on what else is running.
%
%   Options:
%   full         - use the production caps (5e6 expansions, 600 s) instead
%                  of the harness caps (1e5, 300 s), which is slower and does
%                  not change any verdict (default false)
%   maxExpanded  - override the expansion cap directly
%   maxTime      - override the time cap directly
%
%   Three things are checked before the table, because a failure in any of
%   them would make every row below meaningless: that each puzzle file
%   round-trips through the parser unchanged, that the successors of a known
%   position are exactly the hand-enumerated ones, and — for every run that
%   claims a solution — that the moves really replay to the exit.
%
%   See also RUSHHOURSOLVER.

arguments
    opts.full (1,1) logical = false
    opts.maxExpanded double {mustBeScalarOrEmpty} = []
    opts.maxTime double {mustBeScalarOrEmpty} = []
end

if isempty(opts.maxExpanded)
    if opts.full
        opts.maxExpanded = 5e6;
    else
        opts.maxExpanded = 1e5;
    end
end
if isempty(opts.maxTime)
    if opts.full
        opts.maxTime = 600;
    else
        opts.maxTime = 300;
    end
end

puzzleDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'puzzles');
files = "puzzle" + string(0:3) + ".txt";
methods = ["dfid" "uc" "ph" "astar" "idastar" "eidastar" "rtastar"];

% Proven optima, [length cost] per puzzle — puzzle 3's is the paper's
% published result, the rest are this project's own baselines
optimum = [1 6; 3 10; 6 18; 49 134];

failures = 0;
failures = failures + checkRoundTrip(puzzleDir, files);
failures = failures + checkExpansion(fullfile(puzzleDir, files(4)));

fprintf('\ncaps: %g expansions, %g s\n\n', opts.maxExpanded, opts.maxTime);
fprintf('  N  %-14s %-6s %-6s %-6s %-10s %-9s %-8s %s\n', ...
    'Algorithm', 'Solved', 'Length', 'Cost', 'Expanded', 'Time(ms)', 'Replay', 'Verdict');

for p = 1:numel(files)
    file = fullfile(puzzleDir, files(p));
    [puzzle, pos0] = parseBoard(file);
    for m = 1:numel(methods)
        try
            [moves, stats] = RushHourSolver(file, method = methods(m), ...
                maxExpanded = opts.maxExpanded, maxTime = opts.maxTime);
        catch err
            fprintf('  %d  %-14s SOLVER ERROR: %s\n', p - 1, methods(m), err.message);
            failures = failures + 1;
            continue
        end

        replay = "-";
        if stats.solved
            [ok, msg] = verifySolution(puzzle, pos0, moves, stats);
            if ok
                replay = "ok";
            else
                replay = "BAD";
                fprintf('      replay of puzzle%d/%s: %s\n', p - 1, methods(m), msg);
            end
        end

        verdict = judge(p - 1, methods(m), stats, optimum(p, :));
        if replay == "BAD"
            verdict = "FAIL: replay";
        end
        if startsWith(verdict, "FAIL")
            failures = failures + 1;
        end

        fprintf('  %d  %-14s %-6d %-6d %-6d %-10d %-9.0f %-8s %s\n', ...
            p - 1, methods(m), stats.solved, stats.length, stats.cost, ...
            stats.expanded, stats.timeMs, replay, verdict);
    end
    fprintf('\n');
end

printPaperComparison();

pass = failures == 0;
if pass
    fprintf('TOTAL: all %d runs pass the acceptance set.\n', numel(files) * numel(methods));
else
    fprintf('TOTAL: %d FAILURES.\n', failures);
end
end


function verdict = judge(n, method, stats, opt)
%JUDGE Score one run against ../docs/SPEC.md section 7.
    % A solution cheaper than the proven optimum is not a triumph, it means
    % the cost model or the goal test has drifted
    if stats.solved && stats.cost < opt(2)
        verdict = sprintf("FAIL: cost %d undercuts the proven optimum %d", stats.cost, opt(2));
        return
    end

    capAllowed = n == 3 && ismember(method, ["dfid" "idastar" "eidastar" "rtastar"]);
    if ~stats.solved
        if capAllowed && stats.limitHit ~= ""
            verdict = "cap:" + stats.limitHit;
        elseif stats.limitHit ~= ""
            verdict = "FAIL: gave up (" + stats.limitHit + ")";
        else
            verdict = "FAIL: reported no solution";
        end
        return
    end

    % Uniform-Cost is the optimality anchor everywhere; A* joins it where the
    % heuristic is admissible, and puzzle 0 is so small that every algorithm
    % must land on its single move
    mustBeOptimal = n == 0 || ismember(method, ["uc" "astar"]);
    if mustBeOptimal
        if n == 3 && method == "astar"
            % the default heuristic overestimates by at most 1 (design.md #3)
            ok = stats.cost <= opt(2) + 1 && (stats.cost ~= opt(2) || stats.length == opt(1));
        else
            ok = stats.length == opt(1) && stats.cost == opt(2);
        end
        if ~ok
            verdict = sprintf("FAIL: expected %d/%d, got %d/%d", ...
                opt(1), opt(2), stats.length, stats.cost);
            return
        end
    end

    verdict = "PASS";
end


function failures = checkRoundTrip(puzzleDir, files)
%CHECKROUNDTRIP Every puzzle file must survive parse and format unchanged.
    failures = 0;
    for k = 1:numel(files)
        file = fullfile(puzzleDir, files(k));
        [puzzle, pos] = parseBoard(file);
        again = formatBoard(puzzle, pos);
        original = char(splitlines(strip(string(fileread(file)), "right", newline)));
        if isequal(again, original)
            fprintf('round-trip %s: ok (%d vehicles)\n', files(k), puzzle.n);
        else
            fprintf('round-trip %s: MISMATCH\n', files(k));
            disp(again);
            failures = failures + 1;
        end
    end
end


function failures = checkExpansion(file)
%CHECKEXPANSION The successors of puzzle 3's initial position, by hand.
%   Every other vehicle on that board is pinned by a wall or a neighbour, so
%   the opening has exactly four legal moves. If the generator disagrees,
%   nothing downstream of it is worth reading.
    expected = ["D L 1" "H R 1" "I L 1" "I R 1"];

    [puzzle, pos] = parseBoard(file);
    [~, veh, delta] = expandState(puzzle, pos, occupancyGrid(puzzle, pos));
    moves = reconstructPath(puzzle, veh, delta);
    got = sort(string(compose('%c %c %d', ...
        [moves.letter]', char([moves.dir])', [moves.squares]')))';

    if isequal(got, sort(expected))
        fprintf('expansion of puzzle3 opening: ok (%s)\n', strjoin(got, ', '));
        failures = 0;
    else
        fprintf('expansion of puzzle3 opening: MISMATCH\n  expected: %s\n  got:      %s\n', ...
            strjoin(sort(expected), ', '), strjoin(got, ', '));
        failures = 1;
    end
end


function printPaperComparison()
%PRINTPAPERCOMPARISON Table 1 of the paper for puzzle 3, for the eye.
%   Length and cost are the contract; expansion counts differ with
%   tie-breaking and are never asserted.
    fprintf('Reynisson & Hilmarsson, Table 1, puzzle 3:\n');
    fprintf('  Uniform-Cost   solved  49 / 134   2645 expanded     60 ms\n');
    fprintf('  A*             solved  49 / 134   2074 expanded     60 ms\n');
    fprintf('  Pure-Heuristic solved 116 / 303    606 expanded     26 ms\n');
    fprintf('  EIDA*          solved  51 / 136  55676 expanded    527 ms\n');
    fprintf('  DFID, IDA*     terminated without a result\n');
    fprintf('  RTA*           out of memory after 37203891 expansions\n\n');
end
