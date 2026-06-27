import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Three empty cells in the same unit whose notes use exactly three values,
/// and those values appear in no other cell in that unit.
class NakedTriple {
  const NakedTriple({
    required this.unit,
    required this.cellA,
    required this.cellB,
    required this.cellC,
    required this.values,
  });

  final SudokuUnit unit;
  final CellPosition cellA;
  final CellPosition cellB;
  final CellPosition cellC;
  final Set<int> values;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NakedTriple &&
            unit == other.unit &&
            cellA == other.cellA &&
            cellB == other.cellB &&
            cellC == other.cellC &&
            _sameValues(values, other.values);
  }

  @override
  int get hashCode =>
      Object.hash(unit, cellA, cellB, cellC, Object.hashAll(values));

  static bool _sameValues(Set<int> a, Set<int> b) {
    return a.length == b.length && a.containsAll(b);
  }
}

/// Finds every naked triple on [board] across all rows, columns, and 3x3 boxes.
List<NakedTriple> findNakedTriples(SudokuBoard board) {
  final triples = <NakedTriple>[];

  for (final unit in SudokuUnit.all) {
    triples.addAll(_findNakedTriplesInUnit(board, unit));
  }

  return triples;
}

List<NakedTriple> _findNakedTriplesInUnit(SudokuBoard board, SudokuUnit unit) {
  final triples = <NakedTriple>[];
  final notedCells = <CellPosition, Set<int>>{};

  for (final position in unit.cellPositions()) {
    final notes = candidateNotesAt(board, position);
    if (notes.isEmpty) {
      continue;
    }
    notedCells[position] = notes;
  }

  final positions = notedCells.keys.toList();
  for (var i = 0; i < positions.length; i++) {
    for (var j = i + 1; j < positions.length; j++) {
      for (var k = j + 1; k < positions.length; k++) {
        final cellA = positions[i];
        final cellB = positions[j];
        final cellC = positions[k];
        final values = Set<int>.from(notedCells[cellA]!)
          ..addAll(notedCells[cellB]!)
          ..addAll(notedCells[cellC]!);

        if (values.length != 3) {
          continue;
        }

        if (!_isNakedTripleInUnit(
          board,
          unit,
          cellA,
          cellB,
          cellC,
          values,
        )) {
          continue;
        }

        triples.add(
          NakedTriple(
            unit: unit,
            cellA: cellA,
            cellB: cellB,
            cellC: cellC,
            values: Set<int>.from(values),
          ),
        );
      }
    }
  }

  return triples;
}

bool _isNakedTripleInUnit(
  SudokuBoard board,
  SudokuUnit unit,
  CellPosition cellA,
  CellPosition cellB,
  CellPosition cellC,
  Set<int> values,
) {
  for (final position in unit.cellPositions()) {
    if (position == cellA || position == cellB || position == cellC) {
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
