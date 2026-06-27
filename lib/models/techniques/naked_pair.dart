import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Two empty cells in the same unit that share exactly two notes, and those
/// notes appear in no other cell in that unit.
class NakedPair {
  const NakedPair({
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
        other is NakedPair &&
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

/// Finds every naked pair on [board] across all rows, columns, and 3x3 boxes.
List<NakedPair> findNakedPairs(SudokuBoard board) {
  final pairs = <NakedPair>[];

  for (final unit in SudokuUnit.all) {
    pairs.addAll(_findNakedPairsInUnit(board, unit));
  }

  return pairs;
}

List<NakedPair> _findNakedPairsInUnit(SudokuBoard board, SudokuUnit unit) {
  final pairs = <NakedPair>[];
  final twinCells = <CellPosition, Set<int>>{};

  for (final position in unit.cellPositions()) {
    final notes = candidateNotesAt(board, position);
    if (notes.length == 2) {
      twinCells[position] = notes;
    }
  }

  final positions = twinCells.keys.toList();
  for (var i = 0; i < positions.length; i++) {
    for (var j = i + 1; j < positions.length; j++) {
      final cellA = positions[i];
      final cellB = positions[j];
      final values = twinCells[cellA]!;

      if (!_sameNotes(values, twinCells[cellB]!)) {
        continue;
      }

      if (!_isNakedPairInUnit(board, unit, cellA, cellB, values)) {
        continue;
      }

      pairs.add(
        NakedPair(
          unit: unit,
          cellA: cellA,
          cellB: cellB,
          values: Set<int>.from(values),
        ),
      );
    }
  }

  return pairs;
}

bool _isNakedPairInUnit(
  SudokuBoard board,
  SudokuUnit unit,
  CellPosition cellA,
  CellPosition cellB,
  Set<int> values,
) {
  for (final position in unit.cellPositions()) {
    if (position == cellA || position == cellB) {
      continue;
    }

    final notes = candidateNotesAt(board, position);
    for (final value in values) {
      if (notes.contains(value)) {
        return false;
      }
    }
  }

  return true;
}

bool _sameNotes(Set<int> a, Set<int> b) {
  return a.length == b.length && a.containsAll(b);
}
