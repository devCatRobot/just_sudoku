import '../cell_position.dart';
import '../sudoku_board.dart';

enum SudokuUnitType {
  row,
  column,
  box,
}

/// A single row, column, or 3x3 box on the sudoku board.
class SudokuUnit {
  const SudokuUnit({
    required this.type,
    required this.index,
  });

  final SudokuUnitType type;
  final int index;

  static List<SudokuUnit> get all {
    return [
      for (var i = 0; i < SudokuBoard.size; i++)
        SudokuUnit(type: SudokuUnitType.row, index: i),
      for (var i = 0; i < SudokuBoard.size; i++)
        SudokuUnit(type: SudokuUnitType.column, index: i),
      for (var i = 0; i < SudokuBoard.size; i++)
        SudokuUnit(type: SudokuUnitType.box, index: i),
    ];
  }

  Iterable<CellPosition> cellPositions() sync* {
    switch (type) {
      case SudokuUnitType.row:
        for (var col = 0; col < SudokuBoard.size; col++) {
          yield CellPosition(row: index, col: col);
        }
      case SudokuUnitType.column:
        for (var row = 0; row < SudokuBoard.size; row++) {
          yield CellPosition(row: row, col: index);
        }
      case SudokuUnitType.box:
        final boxRow = (index ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize;
        final boxCol = (index % SudokuBoard.boxSize) * SudokuBoard.boxSize;
        for (var row = boxRow; row < boxRow + SudokuBoard.boxSize; row++) {
          for (var col = boxCol; col < boxCol + SudokuBoard.boxSize; col++) {
            yield CellPosition(row: row, col: col);
          }
        }
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SudokuUnit && type == other.type && index == other.index;
  }

  @override
  int get hashCode => Object.hash(type, index);
}

Set<int> candidateNotesAt(SudokuBoard board, CellPosition position) {
  final cell = board.cellAt(position.row, position.col);
  if (cell.value != null) {
    return const {};
  }
  return Set<int>.from(cell.notes);
}

bool isValuePlacedInUnit(SudokuBoard board, SudokuUnit unit, int value) {
  for (final position in unit.cellPositions()) {
    if (board.valueAt(position.row, position.col) == value) {
      return true;
    }
  }
  return false;
}

bool canPlaceValueAt(SudokuBoard board, CellPosition position, int value) {
  if (board.valueAt(position.row, position.col) != null) {
    return false;
  }
  return !board.isValueInRowOrColumn(position.row, position.col, value);
}

List<CellPosition> candidatePositionsForValue(
  SudokuBoard board,
  SudokuUnit unit,
  int value,
) {
  if (isValuePlacedInUnit(board, unit, value)) {
    return const [];
  }

  final positions = <CellPosition>[];
  for (final position in unit.cellPositions()) {
    if (canPlaceValueAt(board, position, value)) {
      positions.add(position);
    }
  }
  return positions;
}

/// Two cells in a unit where [value] appears as a candidate in exactly those cells.
class ConjugatePair {
  const ConjugatePair({
    required this.value,
    required this.cellA,
    required this.cellB,
  });

  final int value;
  final CellPosition cellA;
  final CellPosition cellB;
}

List<ConjugatePair> findConjugatePairs(SudokuBoard board, int value) {
  final pairs = <ConjugatePair>[];
  final seen = <String>{};

  for (final unit in SudokuUnit.all) {
    final positions = candidatePositionsForValue(board, unit, value);
    if (positions.length != 2) {
      continue;
    }

    final cellA = positions[0];
    final cellB = positions[1];
    final key = _conjugateKey(value, cellA, cellB);
    if (seen.add(key)) {
      pairs.add(ConjugatePair(value: value, cellA: cellA, cellB: cellB));
    }
  }

  return pairs;
}

String _conjugateKey(int value, CellPosition cellA, CellPosition cellB) {
  final a = cellA.row * SudokuBoard.size + cellA.col;
  final b = cellB.row * SudokuBoard.size + cellB.col;
  final low = a < b ? a : b;
  final high = a < b ? b : a;
  return '$value:$low:$high';
}

bool cellsSeeEachOther(CellPosition a, CellPosition b) {
  if (a == b) {
    return true;
  }
  if (a.row == b.row || a.col == b.col) {
    return true;
  }

  final boxA =
      (a.row ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize +
      (a.col ~/ SudokuBoard.boxSize);
  final boxB =
      (b.row ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize +
      (b.col ~/ SudokuBoard.boxSize);
  return boxA == boxB;
}

class CandidateElimination {
  const CandidateElimination({
    required this.position,
    required this.value,
  });

  final CellPosition position;
  final int value;
}

Set<int> validValuesAt(SudokuBoard board, CellPosition position) {
  if (board.valueAt(position.row, position.col) != null) {
    return const {};
  }

  final values = <int>{};
  for (var value = 1; value <= SudokuBoard.size; value++) {
    if (canPlaceValueAt(board, position, value)) {
      values.add(value);
    }
  }
  return values;
}
