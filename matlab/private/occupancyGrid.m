function grid = occupancyGrid(puzzle, pos)
%OCCUPANCYGRID Which vehicle sits on each playfield cell.
%   grid = OCCUPANCYGRID(puzzle, pos) is a 6x6 uint8 of vehicle indices,
%   0 where the cell is empty.
%
%   Rebuilt from scratch on every node rather than patched incrementally:
%   it is 36 cells, and the bookkeeping needed to avoid rebuilding costs
%   more in bugs than it saves in time. It is, however, the single hottest
%   function in the whole reference — the IDA* family calls it once per
%   node, most of which are then pruned unexamined — so it is built by
%   arithmetic on the per-cell tables GRIDTOPUZZLE precomputed rather than
%   by looping over vehicles. That change alone took it from 134 to a few
%   microseconds a call.
%
%   Cells past the right edge — only ever the escaped target car's leading
%   cell, sitting on the gap — fall outside the grid and are dropped, so
%   the result always describes the playfield alone.
    grid = zeros(puzzle.size, puzzle.size, 'uint8');
    cells = puzzle.cellBase + puzzle.cellStep .* pos(puzzle.cellVeh);
    onBoard = cells <= numel(grid);
    grid(cells(onBoard)) = puzzle.cellVeh(onBoard);
end
