import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Two numbers in the same unit that can only be placed in the same two cells.
class HiddenPair {
  const HiddenPair({
    required this.unit,
    required this.cellA,
    required this.cellB,
    required this.values,
  });

  final SudokuUnit unit;
  final CellPosition cellA;
  final CellPosition cellB;
  final Set<int> values;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HiddenPair &&
            unit == other.unit &&
            cellA == other.cellA &&
            cellB == other.cellB &&
            _sameValues(values, other.values);
  }

  @override
  int get hashCode => Object.hash(unit, cellA, cellB, Object.hashAll(values));

  static bool _sameValues(Set<int> a, Set<int> b) {
    return a.length == b.length && a.containsAll(b);
  }
}

/// Finds every hidden pair on [board] across all rows, columns, and 3x3 boxes.
List<HiddenPair> findHiddenPairs(SudokuBoard board) {
  final pairs = <HiddenPair>[];

  for (final unit in SudokuUnit.all) {
    pairs.addAll(_findHiddenPairsInUnit(board, unit));
  }

  return pairs;
}

List<HiddenPair> _findHiddenPairsInUnit(SudokuBoard board, SudokuUnit unit) {
  final pairs = <HiddenPair>[];

  for (var valueA = 1; valueA < SudokuBoard.size; valueA++) {
    for (var valueB = valueA + 1; valueB <= SudokuBoard.size; valueB++) {
      final positionsA = candidatePositionsForValue(board, unit, valueA);
      final positionsB = candidatePositionsForValue(board, unit, valueB);

      if (positionsA.length != 2 || positionsB.length != 2) {
        continue;
      }

      if (!_sameTwoCells(positionsA, positionsB)) {
        continue;
      }

      pairs.add(
        HiddenPair(
          unit: unit,
          cellA: positionsA[0],
          cellB: positionsA[1],
          values: {valueA, valueB},
        ),
      );
    }
  }

  return pairs;
}

bool _sameTwoCells(List<CellPosition> a, List<CellPosition> b) {
  return {a[0], a[1]} == {b[0], b[1]};
}
