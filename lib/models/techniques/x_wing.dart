import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// A fish pattern where a value appears in exactly two rows (or columns) and
/// the same two columns (or rows), allowing eliminations on the crossing lines.
class XWing {
  const XWing({
    required this.value,
    required this.primaryAreRows,
    required this.primaryLineA,
    required this.primaryLineB,
    required this.secondaryLineA,
    required this.secondaryLineB,
  });

  final int value;
  final bool primaryAreRows;
  final int primaryLineA;
  final int primaryLineB;
  final int secondaryLineA;
  final int secondaryLineB;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is XWing &&
            value == other.value &&
            primaryAreRows == other.primaryAreRows &&
            primaryLineA == other.primaryLineA &&
            primaryLineB == other.primaryLineB &&
            secondaryLineA == other.secondaryLineA &&
            secondaryLineB == other.secondaryLineB;
  }

  @override
  int get hashCode => Object.hash(
        value,
        primaryAreRows,
        primaryLineA,
        primaryLineB,
        secondaryLineA,
        secondaryLineB,
      );
}

/// Finds every X-Wing on [board].
List<XWing> findXWings(SudokuBoard board) {
  final wings = <XWing>[];

  for (var value = 1; value <= SudokuBoard.size; value++) {
    wings.addAll(_findRowBasedXWings(board, value));
    wings.addAll(_findColumnBasedXWings(board, value));
  }

  return wings;
}

List<XWing> _findRowBasedXWings(SudokuBoard board, int value) {
  final wings = <XWing>[];

  for (var rowA = 0; rowA < SudokuBoard.size; rowA++) {
    final colsA = _candidateColumnsInRow(board, rowA, value);
    if (colsA.length != 2) {
      continue;
    }

    for (var rowB = rowA + 1; rowB < SudokuBoard.size; rowB++) {
      final colsB = _candidateColumnsInRow(board, rowB, value);
      if (colsB.length != 2) {
        continue;
      }

      if (colsA[0] != colsB[0] || colsA[1] != colsB[1]) {
        continue;
      }

      if (!_hasCandidateInColumnsOutsideRows(
        board,
        value,
        colsA[0],
        colsA[1],
        rowA,
        rowB,
      )) {
        continue;
      }

      wings.add(
        XWing(
          value: value,
          primaryAreRows: true,
          primaryLineA: rowA,
          primaryLineB: rowB,
          secondaryLineA: colsA[0],
          secondaryLineB: colsA[1],
        ),
      );
    }
  }

  return wings;
}

List<XWing> _findColumnBasedXWings(SudokuBoard board, int value) {
  final wings = <XWing>[];

  for (var colA = 0; colA < SudokuBoard.size; colA++) {
    final rowsA = _candidateRowsInColumn(board, colA, value);
    if (rowsA.length != 2) {
      continue;
    }

    for (var colB = colA + 1; colB < SudokuBoard.size; colB++) {
      final rowsB = _candidateRowsInColumn(board, colB, value);
      if (rowsB.length != 2) {
        continue;
      }

      if (rowsA[0] != rowsB[0] || rowsA[1] != rowsB[1]) {
        continue;
      }

      if (!_hasCandidateInRowsOutsideColumns(
        board,
        value,
        rowsA[0],
        rowsA[1],
        colA,
        colB,
      )) {
        continue;
      }

      wings.add(
        XWing(
          value: value,
          primaryAreRows: false,
          primaryLineA: colA,
          primaryLineB: colB,
          secondaryLineA: rowsA[0],
          secondaryLineB: rowsA[1],
        ),
      );
    }
  }

  return wings;
}

List<int> _candidateColumnsInRow(SudokuBoard board, int row, int value) {
  final rowUnit = SudokuUnit(type: SudokuUnitType.row, index: row);
  return candidatePositionsForValue(board, rowUnit, value)
      .map((position) => position.col)
      .toList()
    ..sort();
}

List<int> _candidateRowsInColumn(SudokuBoard board, int col, int value) {
  final columnUnit = SudokuUnit(type: SudokuUnitType.column, index: col);
  return candidatePositionsForValue(board, columnUnit, value)
      .map((position) => position.row)
      .toList()
    ..sort();
}

bool _hasCandidateInColumnsOutsideRows(
  SudokuBoard board,
  int value,
  int colA,
  int colB,
  int rowA,
  int rowB,
) {
  for (var row = 0; row < SudokuBoard.size; row++) {
    if (row == rowA || row == rowB) {
      continue;
    }
    if (canPlaceValueAt(board, CellPosition(row: row, col: colA), value) ||
        canPlaceValueAt(board, CellPosition(row: row, col: colB), value)) {
      return true;
    }
  }

  return false;
}

bool _hasCandidateInRowsOutsideColumns(
  SudokuBoard board,
  int value,
  int rowA,
  int rowB,
  int colA,
  int colB,
) {
  for (var col = 0; col < SudokuBoard.size; col++) {
    if (col == colA || col == colB) {
      continue;
    }
    if (canPlaceValueAt(board, CellPosition(row: rowA, col: col), value) ||
        canPlaceValueAt(board, CellPosition(row: rowB, col: col), value)) {
      return true;
    }
  }

  return false;
}
