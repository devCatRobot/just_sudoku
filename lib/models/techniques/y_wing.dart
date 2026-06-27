import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Pivot {X,Y} with wings {X,Z} and {Y,Z}; eliminate Z from cells seeing both wings.
List<CandidateElimination> findYWingEliminations(SudokuBoard board) {
  final bivalueCells = _bivalueCells(board);
  if (bivalueCells.length < 3) {
    return const [];
  }

  final eliminations = <CandidateElimination>[];
  final seen = <String>{};
  final pivots = bivalueCells.keys.toList();

  for (final pivot in pivots) {
    final pivotNotes = bivalueCells[pivot]!.toList();
    final pivotX = pivotNotes[0];
    final pivotY = pivotNotes[1];

    for (final wingA in _wingsSeeingPivot(board, pivot, bivalueCells)) {
      final wingANotes = bivalueCells[wingA]!;
      if (wingANotes.length != 2) {
        continue;
      }

      int zValue;
      int otherPivot;

      if (wingANotes.contains(pivotX) && !wingANotes.contains(pivotY)) {
        otherPivot = pivotY;
        zValue = wingANotes.difference({pivotX}).first;
      } else if (wingANotes.contains(pivotY) && !wingANotes.contains(pivotX)) {
        otherPivot = pivotX;
        zValue = wingANotes.difference({pivotY}).first;
      } else {
        continue;
      }

      for (final wingB in _wingsSeeingPivot(board, pivot, bivalueCells)) {
        if (wingA == wingB || cellsSeeEachOther(wingA, wingB)) {
          continue;
        }

        final wingBNotes = bivalueCells[wingB]!;
        if (!wingBNotes.contains(otherPivot) || !wingBNotes.contains(zValue)) {
          continue;
        }
        if (wingBNotes.length != 2) {
          continue;
        }

        _addEliminationsSeeingBothWings(
          board: board,
          wingA: wingA,
          wingB: wingB,
          value: zValue,
          eliminations: eliminations,
          seen: seen,
        );
      }
    }
  }

  return eliminations;
}

Map<CellPosition, Set<int>> _bivalueCells(SudokuBoard board) {
  final cells = <CellPosition, Set<int>>{};
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      final notes = candidateNotesAt(board, position);
      if (notes.length == 2) {
        cells[position] = notes;
      }
    }
  }
  return cells;
}

List<CellPosition> _wingsSeeingPivot(
  SudokuBoard board,
  CellPosition pivot,
  Map<CellPosition, Set<int>> bivalueCells,
) {
  return bivalueCells.keys
      .where(
        (position) =>
            position != pivot && cellsSeeEachOther(position, pivot),
      )
      .toList();
}

void _addEliminationsSeeingBothWings({
  required SudokuBoard board,
  required CellPosition wingA,
  required CellPosition wingB,
  required int value,
  required List<CandidateElimination> eliminations,
  required Set<String> seen,
}) {
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      if (position == wingA || position == wingB) {
        continue;
      }
      if (!canPlaceValueAt(board, position, value)) {
        continue;
      }
      if (!cellsSeeEachOther(position, wingA) ||
          !cellsSeeEachOther(position, wingB)) {
        continue;
      }

      final key = '${position.row}:${position.col}:$value';
      if (!seen.add(key)) {
        continue;
      }

      eliminations.add(
        CandidateElimination(position: position, value: value),
      );
    }
  }
}
