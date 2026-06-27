import '../cell_position.dart';
import '../sudoku_board.dart';
import '../sudoku_solver.dart';
import 'hidden_pair.dart';
import 'naked_pair.dart';
import 'naked_single.dart';
import 'naked_triple.dart';
import 'pointing.dart';
import 'simple_colouring.dart';
import 'sudoku_unit.dart';
import 'swordfish.dart';
import 'unique_candidate.dart';
import 'w_wing.dart';
import 'x_chain.dart';
import 'x_wing.dart';
import 'xy_chain.dart';
import 'y_wing.dart';

/// Maximum share of placed values that may come from naked or hidden singles.
const double extremeMaxSinglePlacementRatio = 0.15;

enum SudokuTechniqueLevel {
  none(0),
  single(1),
  hard(2),
  pointing(3),
  yWing(4),
  wWing(5),
  xWing(6),
  swordfish(7),
  simpleColouring(8),
  xChain(9),
  xyChain(10);

  const SudokuTechniqueLevel(this.rank);
  final int rank;
}

class TechniqueSolveResult {
  const TechniqueSolveResult({
    required this.solved,
    required this.singlePlacements,
    required this.totalPlacements,
    required this.hardestTechnique,
  });

  final bool solved;
  final int singlePlacements;
  final int totalPlacements;
  final SudokuTechniqueLevel hardestTechnique;
}

/// Extreme: pointing through swordfish and wings. Evil adds chains/colouring.
const SudokuTechniqueLevel extremeMaxTechnique = SudokuTechniqueLevel.swordfish;
const SudokuTechniqueLevel extremeMinHardestTechnique =
    SudokuTechniqueLevel.pointing;
const SudokuTechniqueLevel evilMaxTechnique = SudokuTechniqueLevel.xyChain;
const SudokuTechniqueLevel evilMinHardestTechnique =
    SudokuTechniqueLevel.simpleColouring;

/// Returns whether [puzzle] can be solved using Extreme-level techniques.
bool isSolvableWithExtremeTechniques(List<int?> puzzle) {
  return solveWithTechniques(
    puzzle,
    maxTechnique: extremeMaxTechnique,
  ).solved;
}

/// Extreme puzzles need fish or wing techniques, not chains.
bool isValidExtremePuzzle(List<int?> puzzle) {
  if (!hasUniqueSolution(puzzle)) {
    return false;
  }

  final totalPlacements = puzzle.where((value) => value == null).length;
  if (totalPlacements == 0) {
    return false;
  }

  final maxSingles =
      (totalPlacements * extremeMaxSinglePlacementRatio).floor();

  return solveWithTechniques(
    puzzle,
    maxSinglePlacements: maxSingles,
    maxTechnique: extremeMaxTechnique,
    requireHardestAtLeast: extremeMinHardestTechnique,
  ).solved;
}

TechniqueSolveResult solveWithTechniques(
  List<int?> puzzle, {
  int? maxSinglePlacements,
  SudokuTechniqueLevel maxTechnique = SudokuTechniqueLevel.xyChain,
  SudokuTechniqueLevel? requireHardestAtLeast,
}) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;
  if (puzzle.length != cellCount) {
    throw ArgumentError('Puzzle must contain $cellCount values.');
  }

  final totalPlacements = puzzle.where((value) => value == null).length;
  var singlePlacements = 0;
  var hardestTechnique = SudokuTechniqueLevel.none;

  var board = SudokuBoard.fromValues(
    _puzzleToRows(puzzle),
    treatFilledAsGiven: true,
  ).withCandidateNotesFilled();

  while (!_isComplete(board)) {
    final afterSingle = _tryPlaceSingle(board);
    if (afterSingle != null) {
      board = afterSingle;
      singlePlacements++;
      hardestTechnique = _maxTechniqueLevel(
        hardestTechnique,
        SudokuTechniqueLevel.single,
      );
      if (maxSinglePlacements != null &&
          singlePlacements > maxSinglePlacements) {
        return TechniqueSolveResult(
          solved: false,
          singlePlacements: singlePlacements,
          totalPlacements: totalPlacements,
          hardestTechnique: hardestTechnique,
        );
      }
      continue;
    }

    final afterHiddenPair = _tryApplyHiddenPair(board);
    if (afterHiddenPair != null) {
      board = afterHiddenPair;
      hardestTechnique = _maxTechniqueLevel(
        hardestTechnique,
        SudokuTechniqueLevel.hard,
      );
      continue;
    }

    final afterNakedPair = _tryApplyNakedPair(board);
    if (afterNakedPair != null) {
      board = afterNakedPair;
      hardestTechnique = _maxTechniqueLevel(
        hardestTechnique,
        SudokuTechniqueLevel.hard,
      );
      continue;
    }

    final afterNakedTriple = _tryApplyNakedTriple(board);
    if (afterNakedTriple != null) {
      board = afterNakedTriple;
      hardestTechnique = _maxTechniqueLevel(
        hardestTechnique,
        SudokuTechniqueLevel.hard,
      );
      continue;
    }

    if (SudokuTechniqueLevel.pointing.rank <= maxTechnique.rank) {
      final afterPointing = _tryApplyPointing(board);
      if (afterPointing != null) {
        board = afterPointing;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.pointing,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.yWing.rank <= maxTechnique.rank) {
      final afterYWing = _tryApplyYWing(board);
      if (afterYWing != null) {
        board = afterYWing;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.yWing,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.wWing.rank <= maxTechnique.rank) {
      final afterWWing = _tryApplyWWing(board);
      if (afterWWing != null) {
        board = afterWWing;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.wWing,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.xWing.rank <= maxTechnique.rank) {
      final afterXWing = _tryApplyXWing(board);
      if (afterXWing != null) {
        board = afterXWing;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.xWing,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.swordfish.rank <= maxTechnique.rank) {
      final afterSwordfish = _tryApplySwordfish(board);
      if (afterSwordfish != null) {
        board = afterSwordfish;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.swordfish,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.simpleColouring.rank <= maxTechnique.rank) {
      final afterSimpleColouring = _tryApplySimpleColouring(board);
      if (afterSimpleColouring != null) {
        board = afterSimpleColouring;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.simpleColouring,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.xChain.rank <= maxTechnique.rank) {
      final afterXChain = _tryApplyXChain(board);
      if (afterXChain != null) {
        board = afterXChain;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.xChain,
        );
        continue;
      }
    }

    if (SudokuTechniqueLevel.xyChain.rank <= maxTechnique.rank) {
      final afterXYChain = _tryApplyXYChain(board);
      if (afterXYChain != null) {
        board = afterXYChain;
        hardestTechnique = _maxTechniqueLevel(
          hardestTechnique,
          SudokuTechniqueLevel.xyChain,
        );
        continue;
      }
    }

    return TechniqueSolveResult(
      solved: false,
      singlePlacements: singlePlacements,
      totalPlacements: totalPlacements,
      hardestTechnique: hardestTechnique,
    );
  }

  if (requireHardestAtLeast != null &&
      hardestTechnique.rank < requireHardestAtLeast.rank) {
    return TechniqueSolveResult(
      solved: false,
      singlePlacements: singlePlacements,
      totalPlacements: totalPlacements,
      hardestTechnique: hardestTechnique,
    );
  }

  return TechniqueSolveResult(
    solved: true,
    singlePlacements: singlePlacements,
    totalPlacements: totalPlacements,
    hardestTechnique: hardestTechnique,
  );
}

SudokuTechniqueLevel _maxTechniqueLevel(
  SudokuTechniqueLevel current,
  SudokuTechniqueLevel next,
) {
  return next.rank > current.rank ? next : current;
}

SudokuBoard? _tryPlaceSingle(SudokuBoard board) {
  final nakedSingles = findNakedSingles(board);
  if (nakedSingles.isNotEmpty) {
    final single = nakedSingles.first;
    return board
        .withValue(single.cell.row, single.cell.col, single.value)
        .withNoteRemovedFromPeers(
          single.cell.row,
          single.cell.col,
          single.value,
        );
  }

  final hiddenSingles = findUniqueCandidates(board);
  if (hiddenSingles.isNotEmpty) {
    final single = hiddenSingles.first;
    return board
        .withValue(single.cell.row, single.cell.col, single.value)
        .withNoteRemovedFromPeers(
          single.cell.row,
          single.cell.col,
          single.value,
        );
  }

  return null;
}

SudokuBoard? _tryApplyHiddenPair(SudokuBoard board) {
  for (final pair in findHiddenPairs(board)) {
    var next = board;
    var changed = false;

    for (final cell in [pair.cellA, pair.cellB]) {
      final current = next.cellAt(cell.row, cell.col);
      if (current.value != null) {
        continue;
      }
      if (_sameNotes(current.notes, pair.values)) {
        continue;
      }

      next = next.withCell(
        cell.row,
        cell.col,
        current.copyWith(notes: Set<int>.from(pair.values)),
      );
      changed = true;
    }

    if (changed) {
      return next;
    }
  }

  return null;
}

SudokuBoard? _tryApplyNakedPair(SudokuBoard board) {
  for (final pair in findNakedPairs(board)) {
    var next = board;
    var changed = false;

    for (final position in pair.unit.cellPositions()) {
      if (position == pair.cellA || position == pair.cellB) {
        continue;
      }

      final cell = next.cellAt(position.row, position.col);
      if (cell.value != null) {
        continue;
      }

      final nextNotes = Set<int>.from(cell.notes)..removeAll(pair.values);
      if (nextNotes.length == cell.notes.length) {
        continue;
      }

      next = next.withCell(
        position.row,
        position.col,
        cell.copyWith(notes: nextNotes),
      );
      changed = true;
    }

    if (changed) {
      return next;
    }
  }

  return null;
}

SudokuBoard? _tryApplyNakedTriple(SudokuBoard board) {
  for (final triple in findNakedTriples(board)) {
    var next = board;
    var changed = false;

    for (final position in triple.unit.cellPositions()) {
      if (position == triple.cellA ||
          position == triple.cellB ||
          position == triple.cellC) {
        continue;
      }

      final cell = next.cellAt(position.row, position.col);
      if (cell.value != null) {
        continue;
      }

      final nextNotes = Set<int>.from(cell.notes)..removeAll(triple.values);
      if (nextNotes.length == cell.notes.length) {
        continue;
      }

      next = next.withCell(
        position.row,
        position.col,
        cell.copyWith(notes: nextNotes),
      );
      changed = true;
    }

    if (changed) {
      return next;
    }
  }

  return null;
}

SudokuBoard? _tryApplyPointing(SudokuBoard board) {
  for (final pointing in findPointings(board)) {
    var next = board;
    var changed = false;
    final boxCells = pointing.box.cellPositions().toSet();

    if (pointing.lineType == SudokuUnitType.row) {
      for (var col = 0; col < SudokuBoard.size; col++) {
        final position = CellPosition(row: pointing.lineIndex, col: col);
        if (boxCells.contains(position)) {
          continue;
        }

        changed = _removeNote(next, position, pointing.value, (board) {
          next = board;
        }) || changed;
      }
    } else {
      for (var row = 0; row < SudokuBoard.size; row++) {
        final position = CellPosition(row: row, col: pointing.lineIndex);
        if (boxCells.contains(position)) {
          continue;
        }

        changed = _removeNote(next, position, pointing.value, (board) {
          next = board;
        }) || changed;
      }
    }

    if (changed) {
      return next;
    }
  }

  return null;
}

SudokuBoard? _tryApplyXWing(SudokuBoard board) {
  for (final wing in findXWings(board)) {
    var next = board;
    var changed = false;

    if (wing.primaryAreRows) {
      for (var row = 0; row < SudokuBoard.size; row++) {
        if (row == wing.primaryLineA || row == wing.primaryLineB) {
          continue;
        }

        for (final col in [wing.secondaryLineA, wing.secondaryLineB]) {
          changed = _removeNote(
                next,
                CellPosition(row: row, col: col),
                wing.value,
                (board) {
                  next = board;
                },
              ) ||
              changed;
        }
      }
    } else {
      for (var col = 0; col < SudokuBoard.size; col++) {
        if (col == wing.primaryLineA || col == wing.primaryLineB) {
          continue;
        }

        for (final row in [wing.secondaryLineA, wing.secondaryLineB]) {
          changed = _removeNote(
                next,
                CellPosition(row: row, col: col),
                wing.value,
                (board) {
                  next = board;
                },
              ) ||
              changed;
        }
      }
    }

    if (changed) {
      return next;
    }
  }

  return null;
}

SudokuBoard? _tryApplySwordfish(SudokuBoard board) {
  for (final fish in findSwordfish(board)) {
    var next = board;
    var changed = false;
    final primary = Set<int>.from(fish.primaryLines);
    final secondary = fish.secondaryLines;

    if (fish.primaryAreRows) {
      for (var row = 0; row < SudokuBoard.size; row++) {
        if (primary.contains(row)) {
          continue;
        }

        for (final col in secondary) {
          changed = _removeNote(
                next,
                CellPosition(row: row, col: col),
                fish.value,
                (board) {
                  next = board;
                },
              ) ||
              changed;
        }
      }
    } else {
      for (var col = 0; col < SudokuBoard.size; col++) {
        if (primary.contains(col)) {
          continue;
        }

        for (final row in secondary) {
          changed = _removeNote(
                next,
                CellPosition(row: row, col: col),
                fish.value,
                (board) {
                  next = board;
                },
              ) ||
              changed;
        }
      }
    }

    if (changed) {
      return next;
    }
  }

  return null;
}

SudokuBoard? _tryApplyCandidateEliminations(
  SudokuBoard board,
  List<CandidateElimination> eliminations,
) {
  var next = board;
  var changed = false;

  for (final elimination in eliminations) {
    changed = _removeNote(
          next,
          elimination.position,
          elimination.value,
          (updated) {
            next = updated;
          },
        ) ||
        changed;
  }

  return changed ? next : null;
}

SudokuBoard? _tryApplySimpleColouring(SudokuBoard board) {
  return _tryApplyCandidateEliminations(
    board,
    findSimpleColouringEliminations(board),
  );
}

SudokuBoard? _tryApplyYWing(SudokuBoard board) {
  return _tryApplyCandidateEliminations(
    board,
    findYWingEliminations(board),
  );
}

SudokuBoard? _tryApplyWWing(SudokuBoard board) {
  return _tryApplyCandidateEliminations(
    board,
    findWWingEliminations(board),
  );
}

SudokuBoard? _tryApplyXChain(SudokuBoard board) {
  return _tryApplyCandidateEliminations(
    board,
    findXChainEliminations(board),
  );
}

SudokuBoard? _tryApplyXYChain(SudokuBoard board) {
  return _tryApplyCandidateEliminations(
    board,
    findXYChainEliminations(board),
  );
}

bool _removeNote(
  SudokuBoard board,
  CellPosition position,
  int value,
  void Function(SudokuBoard board) updateBoard,
) {
  final cell = board.cellAt(position.row, position.col);
  if (cell.value != null || !cell.notes.contains(value)) {
    return false;
  }

  final nextNotes = Set<int>.from(cell.notes)..remove(value);
  updateBoard(
    board.withCell(
      position.row,
      position.col,
      cell.copyWith(notes: nextNotes),
    ),
  );
  return true;
}

bool _isComplete(SudokuBoard board) {
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      if (board.valueAt(row, col) == null) {
        return false;
      }
    }
  }
  return true;
}

bool _sameNotes(Set<int> a, Set<int> b) {
  return a.length == b.length && a.containsAll(b);
}

List<List<int?>> _puzzleToRows(List<int?> puzzle) {
  return List.generate(
    SudokuBoard.size,
    (row) => List<int?>.generate(
      SudokuBoard.size,
      (col) => puzzle[row * SudokuBoard.size + col],
    ),
  );
}
