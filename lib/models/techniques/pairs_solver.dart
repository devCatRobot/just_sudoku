import '../sudoku_board.dart';
import 'hidden_pair.dart';
import 'naked_pair.dart';
import 'naked_single.dart';
import 'naked_triple.dart';
import 'unique_candidate.dart';

/// Maximum share of placed values that may come from naked or hidden singles.
const double hardMaxSinglePlacementRatio = 0.20;

class HardSolveResult {
  const HardSolveResult({
    required this.solved,
    required this.singlePlacements,
    required this.totalPlacements,
    required this.hardTechniqueApplications,
  });

  final bool solved;
  final int singlePlacements;
  final int totalPlacements;
  final int hardTechniqueApplications;
}

/// Returns whether [puzzle] can be fully solved using naked singles, hidden
/// singles, naked pairs, hidden pairs, and naked triples.
bool isSolvableWithHardTechniques(List<int?> puzzle) {
  return solveWithHardTechniques(puzzle).solved;
}

/// Hard puzzles must be solvable with hard techniques, and at most
/// [hardMaxSinglePlacementRatio] of placed values may come from singles.
bool isValidHardPuzzle(List<int?> puzzle) {
  final totalPlacements = puzzle.where((value) => value == null).length;
  if (totalPlacements == 0) {
    return false;
  }

  final maxSingles =
      (totalPlacements * hardMaxSinglePlacementRatio).floor();

  return solveWithHardTechniques(
    puzzle,
    maxSinglePlacements: maxSingles,
  ).solved;
}

HardSolveResult solveWithHardTechniques(
  List<int?> puzzle, {
  int? maxSinglePlacements,
}) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;
  if (puzzle.length != cellCount) {
    throw ArgumentError('Puzzle must contain $cellCount values.');
  }

  final totalPlacements = puzzle.where((value) => value == null).length;
  var singlePlacements = 0;
  var hardTechniqueApplications = 0;

  var board = SudokuBoard.fromValues(
    _puzzleToRows(puzzle),
    treatFilledAsGiven: true,
  ).withCandidateNotesFilled();

  while (!_isComplete(board)) {
    final afterSingle = _tryPlaceSingle(board);
    if (afterSingle != null) {
      board = afterSingle;
      singlePlacements++;
      if (maxSinglePlacements != null &&
          singlePlacements > maxSinglePlacements) {
        return HardSolveResult(
          solved: false,
          singlePlacements: singlePlacements,
          totalPlacements: totalPlacements,
          hardTechniqueApplications: hardTechniqueApplications,
        );
      }
      continue;
    }

    final afterHiddenPair = _tryApplyHiddenPair(board);
    if (afterHiddenPair != null) {
      board = afterHiddenPair;
      hardTechniqueApplications++;
      continue;
    }

    final afterNakedPair = _tryApplyNakedPair(board);
    if (afterNakedPair != null) {
      board = afterNakedPair;
      hardTechniqueApplications++;
      continue;
    }

    final afterNakedTriple = _tryApplyNakedTriple(board);
    if (afterNakedTriple != null) {
      board = afterNakedTriple;
      hardTechniqueApplications++;
      continue;
    }

    return HardSolveResult(
      solved: false,
      singlePlacements: singlePlacements,
      totalPlacements: totalPlacements,
      hardTechniqueApplications: hardTechniqueApplications,
    );
  }

  return HardSolveResult(
    solved: true,
    singlePlacements: singlePlacements,
    totalPlacements: totalPlacements,
    hardTechniqueApplications: hardTechniqueApplications,
  );
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
