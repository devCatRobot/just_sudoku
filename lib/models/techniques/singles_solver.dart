import '../sudoku_board.dart';
import 'naked_single.dart';
import 'unique_candidate.dart';

/// Returns whether [puzzle] can be fully solved using only naked singles
/// and hidden singles.
bool isSolvableWithSinglesOnly(List<int?> puzzle) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;
  if (puzzle.length != cellCount) {
    throw ArgumentError('Puzzle must contain $cellCount values.');
  }

  var board = SudokuBoard.fromValues(
    _puzzleToRows(puzzle),
    treatFilledAsGiven: true,
  );

  while (!_isComplete(board)) {
    final nakedSingles = findNakedSingles(board);
    if (nakedSingles.isNotEmpty) {
      final single = nakedSingles.first;
      board = board.withValue(
        single.cell.row,
        single.cell.col,
        single.value,
      );
      continue;
    }

    final hiddenSingles = findUniqueCandidates(board);
    if (hiddenSingles.isNotEmpty) {
      final single = hiddenSingles.first;
      board = board.withValue(
        single.cell.row,
        single.cell.col,
        single.value,
      );
      continue;
    }

    return false;
  }

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

List<List<int?>> _puzzleToRows(List<int?> puzzle) {
  return List.generate(
    SudokuBoard.size,
    (row) => List<int?>.generate(
      SudokuBoard.size,
      (col) => puzzle[row * SudokuBoard.size + col],
    ),
  );
}
