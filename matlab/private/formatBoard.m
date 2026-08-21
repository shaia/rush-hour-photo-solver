function lines = formatBoard(puzzle, pos)
%FORMATBOARD Render a state back as the paper's 8x8 ASCII board.
%   lines = FORMATBOARD(puzzle, pos) is the inverse of PARSEBOARD for any
%   board read from a puzzle file, and the two round-trip exactly.
%
%   An escaped target car has its leading cell on the gap column, so it is
%   drawn over the '=' — the picture of a solved board is the letter A
%   sitting in the doorway.
    sz = puzzle.size;
    lines = repmat('#', sz + 2, sz + 2);
    lines(2:sz+1, 2:sz+1) = ' ';
    lines(puzzle.exitRow + 1, sz + 2) = '=';

    for i = 1:puzzle.n
        for c = pos(i):pos(i) + puzzle.lens(i) - 1
            if puzzle.horiz(i)
                lines(puzzle.fixed(i) + 1, c + 1) = puzzle.letters(i);
            else
                lines(c + 1, puzzle.fixed(i) + 1) = puzzle.letters(i);
            end
        end
    end
end
