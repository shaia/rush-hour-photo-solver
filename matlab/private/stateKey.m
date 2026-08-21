function key = stateKey(puzzle, pos)
%STATEKEY Canonical scalar identity of a state.
%   key = STATEKEY(puzzle, pos) packs the position vector into one number
%   by base-8 positional encoding of pos-1.
%
%   Base 8 rather than base 7: pos needs the values 1..6, and 6 is also the
%   escaped position of a 2-cell target car, so six values must fit. Eight
%   costs nothing — sixteen vehicles still land inside 48 bits, which a
%   double represents exactly (and a uint64 in the ported languages holds
%   with room to spare), and it turns the encoding into a shift.
    key = (pos - 1) * puzzle.keyWeights;
end
