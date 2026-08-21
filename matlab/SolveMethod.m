classdef SolveMethod
%SOLVEMETHOD Search algorithm selector for RushHourSolver.
%   dfid, uc, ph, astar, idastar, eidastar, rtastar — see the
%   RushHourSolver help for a description of each algorithm.
%
%   Callers may pass the member name as text (e.g. 'astar'); argument
%   validation converts it to the enumeration.
%
%   See also RUSHHOURSOLVER.
    enumeration
        dfid, uc, ph, astar, idastar, eidastar, rtastar
    end
end
