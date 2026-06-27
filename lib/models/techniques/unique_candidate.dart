import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// A number that can only be placed in one cell within a row, column, or box.
class UniqueCandidate {
  const UniqueCandidate({
    required this.unit,
    required this.value,
    required this.cell,
  });

  final SudokuUnit unit;
  final int value;
  final CellPosition cell;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UniqueCandidate &&
            unit == other.unit &&
            value == other.value &&
            cell == other.cell;
  }

  @override
  int get hashCode => Object.hash(unit, value, cell);
}

/// Finds every case where a number has only one possible cell in a row,
/// column, or 3x3 box.
List<UniqueCandidate> findUniqueCandidates(SudokuBoard board) {
  final results = <UniqueCandidate>[];

  for (final unit in SudokuUnit.all) {
    for (var value = 1; value <= SudokuBoard.size; value++) {
      final positions = candidatePositionsForValue(board, unit, value);
      if (positions.length == 1) {
        results.add(
          UniqueCandidate(
            unit: unit,
            value: value,
            cell: positions.first,
          ),
        );
      }
    }
  }

  return results;
}
