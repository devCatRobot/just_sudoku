import 'dart:math';

import 'sudoku_board.dart';
import 'sudoku_solver.dart';

/// Builds a random, fully solved 9x9 sudoku grid.
///
/// Returns 81 values in row-major order (index = row * 9 + col).
/// Each number is 1-9. No duplicates in any row, column, or 3x3 box.
List<int> generateSolvedSudoku({Random? random}) {
  final rng = random ?? Random();
  final grid = List<int>.filled(SudokuBoard.size * SudokuBoard.size, 0);

  if (!_fillCell(grid, 0, rng)) {
    throw StateError('Failed to generate a solved sudoku grid.');
  }

  return grid;
}

bool _fillCell(List<int> grid, int index, Random random) {
  if (index == grid.length) {
    return true;
  }

  final row = index ~/ SudokuBoard.size;
  final col = index % SudokuBoard.size;
  final numbers = List<int>.generate(SudokuBoard.size, (i) => i + 1)..shuffle(random);

  for (final number in numbers) {
    if (_canPlace(grid, row, col, number)) {
      grid[index] = number;
      if (_fillCell(grid, index + 1, random)) {
        return true;
      }
      grid[index] = 0;
    }
  }

  return false;
}

bool _canPlace(List<int> grid, int row, int col, int number) {
  for (var c = 0; c < SudokuBoard.size; c++) {
    if (grid[row * SudokuBoard.size + c] == number) {
      return false;
    }
  }

  for (var r = 0; r < SudokuBoard.size; r++) {
    if (grid[r * SudokuBoard.size + col] == number) {
      return false;
    }
  }

  final boxRow = (row ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize;
  final boxCol = (col ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize;
  for (var r = boxRow; r < boxRow + SudokuBoard.boxSize; r++) {
    for (var c = boxCol; c < boxCol + SudokuBoard.boxSize; c++) {
      if (grid[r * SudokuBoard.size + c] == number) {
        return false;
      }
    }
  }

  return true;
}

/// Builds a puzzle by trying to remove values one at a time.
///
/// A value is only removed when the puzzle still has exactly one solution.
/// Returns up to [targetRemoveCount] empty cells (maybe fewer).
///
/// When [puzzleFilter] is provided, a removal is kept only if the filter
/// also accepts the resulting puzzle.
List<int?> generatePuzzleFromSolution(
  List<int> solution,
  int targetRemoveCount, {
  Random? random,
  bool Function(List<int?> puzzle)? puzzleFilter,
}) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;

  if (solution.length != cellCount) {
    throw ArgumentError('Expected $cellCount values, got ${solution.length}.');
  }
  if (targetRemoveCount < 0 || targetRemoveCount > cellCount) {
    throw ArgumentError('targetRemoveCount must be between 0 and $cellCount.');
  }

  final rng = random ?? Random();
  final puzzle = List<int?>.from(solution);
  final indices = List<int>.generate(cellCount, (index) => index)..shuffle(rng);

  var removedCount = 0;
  for (final index in indices) {
    if (removedCount >= targetRemoveCount) {
      break;
    }
    if (puzzle[index] == null) {
      continue;
    }

    final savedValue = puzzle[index];
    puzzle[index] = null;

    if (hasUniqueSolution(puzzle) &&
        (puzzleFilter == null || puzzleFilter(puzzle))) {
      removedCount++;
    } else {
      puzzle[index] = savedValue;
    }
  }

  return puzzle;
}

/// Removes [removeCount] random values from a solved 81-value set.
///
/// Cleared cells become `null`. Returns a new list; [values] is not changed.
List<int?> removeValuesFromSet(
  List<int> values,
  int removeCount, {
  Random? random,
}) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;

  if (values.length != cellCount) {
    throw ArgumentError('Expected $cellCount values, got ${values.length}.');
  }
  if (removeCount < 0 || removeCount > cellCount) {
    throw ArgumentError('removeCount must be between 0 and $cellCount.');
  }

  final rng = random ?? Random();
  final result = List<int?>.from(values);
  final indices = List<int>.generate(cellCount, (index) => index)..shuffle(rng);

  for (var i = 0; i < removeCount; i++) {
    result[indices[i]] = null;
  }

  return result;
}

/// Converts a flat 81-value puzzle list into a 9x9 grid (`null` = empty cell).
List<List<int?>> puzzleGridToRows(List<int?> values) {
  if (values.length != SudokuBoard.size * SudokuBoard.size) {
    throw ArgumentError('Expected 81 values, got ${values.length}.');
  }

  return List.generate(
    SudokuBoard.size,
    (row) => List<int?>.generate(
      SudokuBoard.size,
      (col) => values[row * SudokuBoard.size + col],
    ),
  );
}

/// Converts a flat 81-value list into the 9x9 shape used by [SudokuBoard].
List<List<int>> solvedGridToRows(List<int> values) {
  if (values.length != SudokuBoard.size * SudokuBoard.size) {
    throw ArgumentError('Expected 81 values, got ${values.length}.');
  }

  return List.generate(
    SudokuBoard.size,
    (row) => List<int>.generate(
      SudokuBoard.size,
      (col) => values[row * SudokuBoard.size + col],
    ),
  );
}
