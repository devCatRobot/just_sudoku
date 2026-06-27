import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// A fish pattern where a value appears in exactly three rows (or columns)
/// spanning exactly three columns (or rows).
class Swordfish {
  const Swordfish({
    required this.value,
    required this.primaryAreRows,
    required this.primaryLines,
    required this.secondaryLines,
  });

  final int value;
  final bool primaryAreRows;
  final List<int> primaryLines;
  final List<int> secondaryLines;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Swordfish &&
            value == other.value &&
            primaryAreRows == other.primaryAreRows &&
            _sameLines(primaryLines, other.primaryLines) &&
            _sameLines(secondaryLines, other.secondaryLines);
  }

  @override
  int get hashCode => Object.hash(
        value,
        primaryAreRows,
        Object.hashAll(primaryLines),
        Object.hashAll(secondaryLines),
      );

  static bool _sameLines(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    final sortedA = List<int>.from(a)..sort();
    final sortedB = List<int>.from(b)..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Finds every Swordfish on [board].
List<Swordfish> findSwordfish(SudokuBoard board) {
  final fish = <Swordfish>[];

  for (var value = 1; value <= SudokuBoard.size; value++) {
    fish.addAll(_findRowBasedSwordfish(board, value));
    fish.addAll(_findColumnBasedSwordfish(board, value));
  }

  return fish;
}

List<Swordfish> _findRowBasedSwordfish(SudokuBoard board, int value) {
  final fish = <Swordfish>[];

  for (var rowA = 0; rowA < SudokuBoard.size; rowA++) {
    final colsA = _candidateColumnsInRow(board, rowA, value);
    if (colsA.isEmpty) {
      continue;
    }

    for (var rowB = rowA + 1; rowB < SudokuBoard.size; rowB++) {
      final colsB = _candidateColumnsInRow(board, rowB, value);
      if (colsB.isEmpty) {
        continue;
      }

      for (var rowC = rowB + 1; rowC < SudokuBoard.size; rowC++) {
        final colsC = _candidateColumnsInRow(board, rowC, value);
        if (colsC.isEmpty) {
          continue;
        }

        final secondaryLines = <int>{
          ...colsA,
          ...colsB,
          ...colsC,
        }.toList()
          ..sort();

        if (secondaryLines.length != 3) {
          continue;
        }

        if (!_columnsAreSubset(secondaryLines, colsA) ||
            !_columnsAreSubset(secondaryLines, colsB) ||
            !_columnsAreSubset(secondaryLines, colsC)) {
          continue;
        }

        final primaryLines = [rowA, rowB, rowC];
        if (!_hasCandidateInColumnsOutsideRows(
          board,
          value,
          secondaryLines,
          primaryLines,
        )) {
          continue;
        }

        fish.add(
          Swordfish(
            value: value,
            primaryAreRows: true,
            primaryLines: primaryLines,
            secondaryLines: secondaryLines,
          ),
        );
      }
    }
  }

  return fish;
}

List<Swordfish> _findColumnBasedSwordfish(SudokuBoard board, int value) {
  final fish = <Swordfish>[];

  for (var colA = 0; colA < SudokuBoard.size; colA++) {
    final rowsA = _candidateRowsInColumn(board, colA, value);
    if (rowsA.isEmpty) {
      continue;
    }

    for (var colB = colA + 1; colB < SudokuBoard.size; colB++) {
      final rowsB = _candidateRowsInColumn(board, colB, value);
      if (rowsB.isEmpty) {
        continue;
      }

      for (var colC = colB + 1; colC < SudokuBoard.size; colC++) {
        final rowsC = _candidateRowsInColumn(board, colC, value);
        if (rowsC.isEmpty) {
          continue;
        }

        final secondaryLines = <int>{
          ...rowsA,
          ...rowsB,
          ...rowsC,
        }.toList()
          ..sort();

        if (secondaryLines.length != 3) {
          continue;
        }

        if (!_columnsAreSubset(secondaryLines, rowsA) ||
            !_columnsAreSubset(secondaryLines, rowsB) ||
            !_columnsAreSubset(secondaryLines, rowsC)) {
          continue;
        }

        final primaryLines = [colA, colB, colC];
        if (!_hasCandidateInRowsOutsideColumns(
          board,
          value,
          secondaryLines,
          primaryLines,
        )) {
          continue;
        }

        fish.add(
          Swordfish(
            value: value,
            primaryAreRows: false,
            primaryLines: primaryLines,
            secondaryLines: secondaryLines,
          ),
        );
      }
    }
  }

  return fish;
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

bool _columnsAreSubset(List<int> allowed, List<int> candidates) {
  final allowedSet = Set<int>.from(allowed);
  for (final candidate in candidates) {
    if (!allowedSet.contains(candidate)) {
      return false;
    }
  }
  return true;
}

bool _hasCandidateInColumnsOutsideRows(
  SudokuBoard board,
  int value,
  List<int> cols,
  List<int> excludedRows,
) {
  final excluded = Set<int>.from(excludedRows);

  for (var row = 0; row < SudokuBoard.size; row++) {
    if (excluded.contains(row)) {
      continue;
    }

    for (final col in cols) {
      if (canPlaceValueAt(board, CellPosition(row: row, col: col), value)) {
        return true;
      }
    }
  }

  return false;
}

bool _hasCandidateInRowsOutsideColumns(
  SudokuBoard board,
  int value,
  List<int> rows,
  List<int> excludedCols,
) {
  final excluded = Set<int>.from(excludedCols);

  for (var col = 0; col < SudokuBoard.size; col++) {
    if (excluded.contains(col)) {
      continue;
    }

    for (final row in rows) {
      if (canPlaceValueAt(board, CellPosition(row: row, col: col), value)) {
        return true;
      }
    }
  }

  return false;
}
