import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Two matching bivalue cells linked by a conjugate chain on one candidate.
/// Eliminates the other shared candidate from cells seeing both cells.
List<CandidateElimination> findWWingEliminations(SudokuBoard board) {
  final bivalueCells = _bivalueCells(board);
  if (bivalueCells.length < 2) {
    return const [];
  }

  final eliminations = <CandidateElimination>[];
  final seen = <String>{};
  final positions = bivalueCells.keys.toList();

  for (var i = 0; i < positions.length; i++) {
    for (var j = i + 1; j < positions.length; j++) {
      final cellA = positions[i];
      final cellB = positions[j];
      if (cellsSeeEachOther(cellA, cellB)) {
        continue;
      }

      final notesA = bivalueCells[cellA]!;
      final notesB = bivalueCells[cellB]!;
      if (notesA.length != 2 || notesB.length != 2 || notesA != notesB) {
        continue;
      }

      final values = notesA.toList();
      final linkValue = values[0];
      final eliminateValue = values[1];

      if (_areConjugateLinked(board, linkValue, cellA, cellB)) {
        _addEliminationsSeeingBothCells(
          board: board,
          cellA: cellA,
          cellB: cellB,
          value: eliminateValue,
          eliminations: eliminations,
          seen: seen,
        );
      }

      if (_areConjugateLinked(board, eliminateValue, cellA, cellB)) {
        _addEliminationsSeeingBothCells(
          board: board,
          cellA: cellA,
          cellB: cellB,
          value: linkValue,
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

bool _areConjugateLinked(
  SudokuBoard board,
  int value,
  CellPosition start,
  CellPosition end,
) {
  if (!canPlaceValueAt(board, start, value) ||
      !canPlaceValueAt(board, end, value)) {
    return false;
  }

  final neighbors = <CellPosition, Set<CellPosition>>{};
  for (final pair in findConjugatePairs(board, value)) {
    neighbors
        .putIfAbsent(pair.cellA, () => <CellPosition>{})
        .add(pair.cellB);
    neighbors
        .putIfAbsent(pair.cellB, () => <CellPosition>{})
        .add(pair.cellA);
  }

  final visited = <CellPosition>{start};
  final queue = <CellPosition>[start];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (current == end) {
      return true;
    }

    for (final neighbor in neighbors[current] ?? const {}) {
      if (visited.add(neighbor)) {
        queue.add(neighbor);
      }
    }
  }

  return false;
}

void _addEliminationsSeeingBothCells({
  required SudokuBoard board,
  required CellPosition cellA,
  required CellPosition cellB,
  required int value,
  required List<CandidateElimination> eliminations,
  required Set<String> seen,
}) {
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      if (position == cellA || position == cellB) {
        continue;
      }
      if (!canPlaceValueAt(board, position, value)) {
        continue;
      }
      if (!cellsSeeEachOther(position, cellA) ||
          !cellsSeeEachOther(position, cellB)) {
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
