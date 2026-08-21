function [ok, msg] = verifySolution(puzzle, pos0, moves, stats)
%VERIFYSOLUTION Replay a solution and check that it is one.
%   [ok, msg] = VERIFYSOLUTION(puzzle, pos0, moves, stats) walks the moves
%   from the initial position and confirms that every one is legal, that
%   the run ends with the target car escaped, and that the move costs sum
%   to stats.cost and count to stats.length.
%
%   This is the only check that applies to all seven algorithms: three of
%   them have no optimality to assert, so replaying what they returned is
%   the only way to tell a real solution from a plausible-looking one. Each
%   port inherits it (../../docs/SPEC.md section 7).
%
%   Legality is tested by asking EXPANDSTATE whether it would have offered
%   the move, so there is exactly one definition of a legal move in the
%   whole reference and no second one to drift out of step.
    ok = false;
    pos = pos0;
    total = 0;

    for m = 1:numel(moves)
        i = find(puzzle.letters == moves(m).letter, 1);
        if isempty(i)
            msg = sprintf('move %d names vehicle %c, which is not on the board', ...
                m, moves(m).letter);
            return
        end
        squares = moves(m).squares;
        if ~isscalar(squares) || squares < 1 || mod(squares, 1) ~= 0
            msg = sprintf('move %d slides %g squares', m, squares);
            return
        end
        switch moves(m).dir
            case 'L', delta = -squares; alongRow = true;
            case 'R', delta =  squares; alongRow = true;
            case 'U', delta = -squares; alongRow = false;
            case 'D', delta =  squares; alongRow = false;
            otherwise
                msg = sprintf('move %d has direction ''%s''; expected U, D, L or R', ...
                    m, moves(m).dir);
                return
        end
        if alongRow ~= puzzle.horiz(i)
            msg = sprintf('move %d slides %c across its own axis', m, moves(m).letter);
            return
        end

        [~, veh, deltas] = expandState(puzzle, pos, occupancyGrid(puzzle, pos));
        if ~any(veh == i & deltas == delta)
            msg = sprintf('move %d (%c %s %d) is not legal from that position', ...
                m, moves(m).letter, moves(m).dir, squares);
            return
        end
        pos = applyMove(pos, i, delta);
        total = total + squares + 1;
    end

    if pos(1) < puzzle.exitPos
        msg = 'the last move does not leave the target car in the exit';
        return
    end
    if total ~= stats.cost
        msg = sprintf('moves cost %d but %d was reported', total, stats.cost);
        return
    end
    if numel(moves) ~= stats.length
        msg = sprintf('%d moves returned but length %d was reported', ...
            numel(moves), stats.length);
        return
    end

    ok = true;
    msg = '';
end
