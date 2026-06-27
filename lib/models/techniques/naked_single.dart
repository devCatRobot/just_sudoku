import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// An empty cell where only one number can be placed.
class NakedSingle {
  const NakedSingle({
    required this.cell,
    required this.value,
  });

  final CellPosition cell;
  final int value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NakedSingle && cell == other.cell && value == other.value;
  }

  @override
  int get hashCode => Object.hash(cell, value);
}

/// Finds every empty cell that has only one valid placement.
List<NakedSingle> findNakedSingles(SudokuBoard board) {
  final results = <NakedSingle>[];

  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final cell = CellPosition(row: row, col: col);
      final values = validValuesAt(board, cell);
      if (values.length == 1) {
        results.add(
          NakedSingle(
            cell: cell,
            value: values.first,
          ),
        );
      }
    }
  }

  return results;
}
