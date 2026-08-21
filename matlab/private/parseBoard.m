function [puzzle, pos] = parseBoard(board)
%PARSEBOARD Read a Rush Hour board in any of the accepted spellings.
%   [puzzle, pos] = PARSEBOARD(board) accepts
%     - the path to a puzzle .txt file,
%     - the paper's 8x8 ASCII board as text (char array, string, or
%       cellstr; newlines in a single string are fine),
%     - a bare 6x6 char playfield, the shape the vision half produces.
%
%   The walled form carries the exit gap '=' in its right wall and is
%   checked against it; the bare form takes the target car's row as the
%   exit row, since a playfield has no wall to write the gap on.
%
%   See ../../docs/SPEC.md section 1 for the format and its validity rules.
    BOARD_SIZE = 6;

    if ischar(board) && isequal(size(board), [BOARD_SIZE BOARD_SIZE])
        [puzzle, pos] = gridToPuzzle(board);
        return
    end

    lines = boardLines(board);
    if isequal(size(lines), [BOARD_SIZE BOARD_SIZE])
        [puzzle, pos] = gridToPuzzle(lines);
        return
    end
    if ~isequal(size(lines), [BOARD_SIZE + 2, BOARD_SIZE + 2])
        error('rushHourSolver:badBoard', ...
            'A board is %d lines of %d characters or a bare %dx%d playfield; got %dx%d.', ...
            BOARD_SIZE + 2, BOARD_SIZE + 2, BOARD_SIZE, BOARD_SIZE, size(lines, 1), size(lines, 2));
    end

    % The frame must be solid apart from the single exit gap, which is what
    % distinguishes a truncated or misaligned transcription from a real board
    rightWall = lines(:, end);
    gapRows = find(rightWall == '=');
    if numel(gapRows) ~= 1
        error('rushHourSolver:badBoard', ...
            'A board carries exactly one exit gap ''='' in its right wall; found %d.', ...
            numel(gapRows));
    end
    rightWall(gapRows) = '#';
    if ~all(lines(1, :) == '#') || ~all(lines(end, :) == '#') ...
            || ~all(lines(:, 1) == '#') || ~all(rightWall == '#')
        error('rushHourSolver:badBoard', 'The board frame must be made of ''#'' walls.');
    end
    if gapRows == 1 || gapRows == BOARD_SIZE + 2
        error('rushHourSolver:badBoard', 'The exit gap must be beside a playfield row.');
    end

    [puzzle, pos] = gridToPuzzle(lines(2:end-1, 2:end-1), gapRows - 1);
end


function lines = boardLines(board)
%BOARDLINES Normalize any accepted spelling to a char matrix, padding short
%   lines so that trailing spaces lost in a text file do not shift columns.
    if (ischar(board) && isrow(board)) || (isstring(board) && isscalar(board))
        txt = string(board);
        if ~contains(txt, newline) && isfile(txt)
            txt = string(fileread(txt));
        end
        parts = splitlines(txt);
        parts(strlength(parts) == 0) = [];
        lines = char(parts);
    elseif isstring(board) || iscellstr(board)
        lines = char(board(:));
    elseif ischar(board)
        lines = board;
    else
        error('rushHourSolver:badBoard', ...
            'A board must be text, a char array, or a file path; got %s.', class(board));
    end
end
