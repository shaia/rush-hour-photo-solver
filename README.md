# Rush Hour photo solver

Photograph the physical ThinkFun Rush Hour game, recognize the board, solve it, and show the
move sequence — with the solver written five times over, in MATLAB, Python, C++, C and x64
assembly, each implementing the same seven search algorithms.

The seven algorithms, the board format and the benchmark come from Brynjar Reynisson and Ívar
Björn Hilmarsson, *Rush-Hour puzzles solved with multiple search algorithms* (Reykjavik
University, T-622-ARTI, 2008), bundled here as [Rush_Hour_Puzzle.pdf](Rush_Hour_Puzzle.pdf):
DFID, Uniform-Cost, Pure-Heuristic, A*, IDA*, Enhanced-IDA* and RTA*.

The two halves meet at a 6×6 grid of characters and nowhere else. Every solver can be exercised
without a single photograph, and the vision pipeline can be exercised without a single search.

## Status

| Milestone | State |
| --- | --- |
| M0 scaffold, [docs/SPEC.md](docs/SPEC.md), puzzle data | done |
| M1 MATLAB reference solvers, all seven algorithms | done |
| M2 Python port + benchmark harness | done |
| M3–M4 C++ and C ports (MATLAB joins the harness at M3) | not started |
| M5–M6 assembly hot paths, then a standalone assembly solver | not started |
| M7 MATLAB vision pipeline (photo → board) | not started |

The plan is in [plans/rush-hour-photo-solver-plan.md](plans/rush-hour-photo-solver-plan.md).

## Quick start (MATLAB)

Requires MATLAB R2023b or newer (`dictionary`, `arguments` blocks). No toolboxes — the solver
half is plain MATLAB; the Image Processing Toolbox is only needed by the vision half at M7.

```matlab
cd matlab

% Solve the paper's hard puzzle and report the run
[moves, stats] = RushHourSolver('../data/puzzles/puzzle3.txt', method='uc')

% Every algorithm on every puzzle, judged against the acceptance set
evalSolver
```

`stats` reports `solved`, `length`, `cost`, `expanded`, `timeMs` and `limitHit`; `moves` is one
`letter` / `dir` / `squares` record per move.

Headless, as a gate:

```powershell
& "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd matlab; assert(evalSolver)"
```

## Quick start (Python)

Stdlib only — the venv exists for pytest, not for the solver.

```powershell
py -m venv python\.venv
python\.venv\Scripts\python.exe -m pip install -r python\requirements-dev.txt

# The command-line contract of docs/SPEC.md section 6
cd python
py -m rushhour --method uc ..\data\puzzles\puzzle3.txt

# Tests, including the 28-run acceptance set
.venv\Scripts\python.exe -m pytest
```

And the cross-language benchmark, which judges every run against the acceptance set and writes
[benchmark/results/](benchmark/results/):

```powershell
python\.venv\Scripts\python.exe benchmark\run_benchmark.py
```

## Solving

```matlab
[moves, stats] = RushHourSolver(board, method='astar')
```

`board` is a puzzle file path, the paper's 8×8 ASCII board as text, or a bare 6×6 char
playfield — the shape the vision half will produce.

| Method | Algorithm | Optimal? |
| --- | --- | --- |
| `astar` | (default) best-first on `g + h` | yes when `h` is admissible |
| `uc` | uniform-cost, best-first on `g` alone | **yes — the reference optimum** |
| `ph` | pure heuristic, best-first on `h` alone | no |
| `dfid` | depth-first iterative deepening on move count | in *length*, not cost |
| `idastar` | IDA*: the same search bounded by cost | yes when `h` is admissible |
| `eidastar` | IDA* with a transposition table | yes when `h` is admissible |
| `rtastar` | real-time A*: one committed move at a time | no |

`uc`, `ph` and `astar` are one search under three orderings. Options: `maxExpanded`, `maxTime`,
and `blockerPenalty` (the heuristic's mildly inadmissible third term, on by default).

A move slides one vehicle any distance and **costs the squares it covers plus one**; the target
car escapes by sliding its leading cell onto the exit gap. That model is not stated in the
paper — it was recovered by reproducing its results, and it reproduces them exactly. The
derivation is [docs/design.md](docs/design.md) §1; do not change it without reading that first.

## Puzzles

[data/puzzles/](data/puzzles/) holds four boards in the paper's ASCII format. Only `puzzle3.txt`
is the paper's own, and only its 49 moves / cost 134 is published ground truth; the rest are
reconstructions with self-computed baselines. See
[data/puzzles/PUZZLE_SOURCES.md](data/puzzles/PUZZLE_SOURCES.md).

| Puzzle | Vehicles | Optimum | Role |
| --- | --- | --- | --- |
| 0 | 1 | 1 / 6 | pins down what "escaped" means |
| 1 | 4 | 3 / 10 | smoke test |
| 2 | 10 | 6 / 18 | four trucks; sized so *every* algorithm finishes |
| 3 | 13 | **49 / 134** | the paper's hard puzzle — the calibration gate |

## Repository layout

| Path | Contents |
| --- | --- |
| [docs/paper.md](docs/paper.md) | what the source article says, and where it stops saying it |
| [docs/SPEC.md](docs/SPEC.md) | the cross-language contract: format, cost model, heuristic, CLI, acceptance set |
| [docs/design.md](docs/design.md) | why the contract says what it says — the calibration record |
| [data/puzzles/](data/puzzles/) | shared ASCII boards, provenance, and [optima.json](data/puzzles/optima.json) — the machine-readable acceptance numbers |
| [matlab/](matlab/) | the reference implementation: `RushHourSolver`, `evalSolver`, `private/` |
| [python/](python/) | the Python port and the trusted move verifier |
| [cpp/](cpp/), [c/](c/), [asm/](asm/) | ports, M3–M6 |
| [benchmark/](benchmark/) | cross-language runner and results |
| [plans/](plans/) | the implementation plan |

Every port is written against [docs/SPEC.md](docs/SPEC.md), not against the MATLAB code. The
MATLAB implementation is a reference, not an authority: where the two disagree, the spec — and
the paper behind it — wins.

## License and attribution

The code and documentation in this repository are MIT licensed — see [LICENSE](LICENSE).

[Rush_Hour_Puzzle.pdf](Rush_Hour_Puzzle.pdf) is **not** covered by that license and is not mine
to license. It is Brynjar Reynisson and Ívar Björn Hilmarsson, *Rush-Hour puzzles solved with
multiple search algorithms*, Reykjavik University, T-622-ARTI, 19 February 2008, bundled here
because every number this project checks itself against comes from it and a reader should be
able to check the derivation in [docs/design.md](docs/design.md) against the source. All rights
remain with its authors; [docs/paper.md](docs/paper.md) is my reading of it, not a substitute
for it.

Rush Hour is a trademark of ThinkFun, Inc. This project is unaffiliated with them.
