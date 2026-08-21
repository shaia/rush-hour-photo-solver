function moves = reconstructPath(puzzle, veh, delta)
%RECONSTRUCTPATH Turn a move list into the reported solution.
%   moves = RECONSTRUCTPATH(puzzle, veh, delta) converts parallel vectors of
%   vehicle indices and signed distances into the struct array the solvers
%   return: letter / dir / squares, one element per move, in order.
%
%   The field names and the U/D/L/R spelling are the ones the ported
%   solvers print on their 'move:' lines, so the benchmark harness parses
%   one format across all five languages (../../docs/SPEC.md section 6).
    count = numel(veh);
    moves = struct('letter', cell(1, count), 'dir', cell(1, count), 'squares', cell(1, count));
    for m = 1:count
        i = veh(m);
        moves(m).letter = puzzle.letters(i);
        if puzzle.horiz(i)
            dirs = 'LR';
        else
            dirs = 'UD';
        end
        moves(m).dir = dirs((delta(m) > 0) + 1);
        moves(m).squares = abs(delta(m));
    end
end
