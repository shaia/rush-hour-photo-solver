function [puzzle, pos] = gridToPuzzle(grid, exitRow)
%GRIDTOPUZZLE Turn a 6x6 char grid into a solvable puzzle description.
%   [puzzle, pos] = GRIDTOPUZZLE(grid) reads the grid (space = empty,
%   'A' = target car, other letters = other vehicles) and infers the exit
%   row from the row the target car sits in.
%
%   [puzzle, pos] = GRIDTOPUZZLE(grid, exitRow) uses the given exit row and
%   checks that the target car is in it.
%
%   This is the single seam between the vision half and the solver half: it
%   takes a grid of characters and nothing else, so every algorithm can be
%   exercised without an image and the reader can be exercised without a
%   search. See ../../docs/SPEC.md section 2.
%
%   puzzle describes what never changes during a search:
%     letters     1xN char, sorted, so letters(1) is always 'A'
%     lens        1xN vehicle lengths (2 or 3)
%     horiz       1xN logical, true for a horizontal vehicle
%     fixed       1xN cross-axis coordinate: the row of a horizontal
%                 vehicle, the column of a vertical one
%     exitRow     row carrying the gap in the right wall
%     exitPos     pos value of the target car meaning "escaped": its
%                 leading cell is on the gap, one column past the board
%     keyWeights  Nx1 base-8 place values for stateKey
%     maxMoves    successors any one state can have, for preallocation
%     cellVeh, cellBase, cellStep
%                 one entry per occupied cell, laying out OCCUPANCYGRID as
%                 arithmetic rather than a loop (see below)
%     n, size     vehicle count and board edge
%
%   pos is the 1xN mutable state: leftmost column of a horizontal vehicle,
%   topmost row of a vertical one.
    BOARD_SIZE = 6;

    if ~ischar(grid) || ~isequal(size(grid), [BOARD_SIZE BOARD_SIZE])
        error('rushHourSolver:badBoard', ...
            'The playfield must be a %dx%d char array.', BOARD_SIZE, BOARD_SIZE);
    end

    letters = unique(grid(grid ~= ' '));
    letters = letters(:)';
    if isempty(letters) || any(letters < 'A' | letters > 'Z')
        error('rushHourSolver:badBoard', ...
            'Vehicles must be marked with the letters A-Z (space = empty).');
    end
    if letters(1) ~= 'A'
        error('rushHourSolver:badBoard', ...
            'The board has no target car: exactly one vehicle must be lettered A.');
    end

    n = numel(letters);
    lens = zeros(1, n);
    horiz = false(1, n);
    fixed = zeros(1, n);
    pos = zeros(1, n);
    for i = 1:n
        [rows, cols] = find(grid == letters(i));
        rows = rows'; cols = cols';
        lens(i) = numel(rows);
        if lens(i) < 2 || lens(i) > 3
            error('rushHourSolver:badBoard', ...
                'Vehicle %c covers %d cells; vehicles are 2 or 3 cells long.', ...
                letters(i), lens(i));
        end
        horiz(i) = all(rows == rows(1));
        if horiz(i)
            fixed(i) = rows(1);
            pos(i) = min(cols);
            run = sort(cols);
        elseif all(cols == cols(1))
            fixed(i) = cols(1);
            pos(i) = min(rows);
            run = sort(rows);
        else
            error('rushHourSolver:badBoard', ...
                'Vehicle %c is neither a row nor a column: it must lie straight.', letters(i));
        end
        if any(diff(run) ~= 1)
            error('rushHourSolver:badBoard', ...
                'Vehicle %c is split into separate pieces; its cells must be contiguous.', ...
                letters(i));
        end
    end

    if ~horiz(1)
        error('rushHourSolver:badBoard', 'The target car A must be horizontal.');
    end
    if nargin < 2 || isempty(exitRow)
        exitRow = fixed(1);                % no wall to read it from: A defines it
    elseif exitRow ~= fixed(1)
        error('rushHourSolver:badBoard', ...
            'The exit is on row %d but the target car A is on row %d.', exitRow, fixed(1));
    end

    % Every occupied cell's linear index in the 6x6 grid is an affine function
    % of its vehicle's pos, so the whole occupancy grid is one vectorised
    % expression instead of a loop over vehicles. Column-major, so the cell
    % (row r, column c) is at r + (c-1)*6:
    %   horizontal, row f, cell k of the vehicle: (f - 6 + 6k) + 6*pos
    %   vertical,   column f, cell k:             (k + (f-1)*6) + 1*pos
    totalCells = sum(lens);
    cellVeh = zeros(1, totalCells);
    cellBase = zeros(1, totalCells);
    cellStep = zeros(1, totalCells);
    j = 0;
    for i = 1:n
        for k = 0:lens(i) - 1
            j = j + 1;
            cellVeh(j) = i;
            if horiz(i)
                cellBase(j) = fixed(i) - BOARD_SIZE + BOARD_SIZE * k;
                cellStep(j) = BOARD_SIZE;
            else
                cellBase(j) = k + (fixed(i) - 1) * BOARD_SIZE;
                cellStep(j) = 1;
            end
        end
    end

    puzzle = struct( ...
        'letters', letters, ...
        'lens', lens, ...
        'horiz', horiz, ...
        'fixed', fixed, ...
        'exitRow', exitRow, ...
        'exitPos', BOARD_SIZE + 2 - lens(1), ...  % leading cell on the gap column
        'keyWeights', (8 .^ (0:n-1))', ...
        'maxMoves', sum(BOARD_SIZE - lens) + 1, ... % positions each vehicle could reach, plus the exit
        'cellVeh', cellVeh, ...
        'cellBase', cellBase, ...
        'cellStep', cellStep, ...
        'n', n, ...
        'size', BOARD_SIZE);
end
