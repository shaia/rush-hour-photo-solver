function pos = applyMove(pos, veh, delta)
%APPLYMOVE Slide one vehicle.
%   pos = APPLYMOVE(pos, veh, delta) is the whole of a Rush Hour move: a
%   vehicle never turns, so its entire state is one scalar and a move is a
%   signed distance added to it. Negative is left or up.
%
%   The caller is responsible for the move being legal — EXPANDSTATE only
%   ever offers legal ones.
    pos(veh) = pos(veh) + delta;
end
