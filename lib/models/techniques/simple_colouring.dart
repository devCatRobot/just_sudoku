import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Simple colouring on one digit: colour conjugate-linked cells and eliminate
/// contradictions or cells that see both colours.
List<CandidateElimination> findSimpleColouringEliminations(SudokuBoard board) {
  final eliminations = <CandidateElimination>[];
  final seen = <String>{};

  for (var value = 1; value <= SudokuBoard.size; value++) {
    eliminations.addAll(
      _findEliminationsForValue(board, value, seen),
    );
  }

  return eliminations;
}

List<CandidateElimination> _findEliminationsForValue(
  SudokuBoard board,
  int value,
  Set<String> seen,
) {
  final candidates = <CellPosition>[];
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      if (canPlaceValueAt(board, position, value)) {
        candidates.add(position);
      }
    }
  }

  if (candidates.length < 2) {
    return const [];
  }

  final strongNeighbors = <CellPosition, Set<CellPosition>>{};
  for (final pair in findConjugatePairs(board, value)) {
    strongNeighbors
        .putIfAbsent(pair.cellA, () => <CellPosition>{})
        .add(pair.cellB);
    strongNeighbors
        .putIfAbsent(pair.cellB, () => <CellPosition>{})
        .add(pair.cellA);
  }

  final eliminations = <CandidateElimination>[];
  final visited = <CellPosition>{};

  for (final start in candidates) {
    if (visited.contains(start)) {
      continue;
    }
    if (!strongNeighbors.containsKey(start)) {
      continue;
    }

    final component = <CellPosition>{};
    final colors = <CellPosition, int>{};
    final queue = <CellPosition>[start];
    colors[start] = 0;
    component.add(start);
    visited.add(start);

    var hasConflict = false;
    var conflictColor = -1;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentColor = colors[current]!;

      for (final neighbor in strongNeighbors[current] ?? const {}) {
        if (!canPlaceValueAt(board, neighbor, value)) {
          continue;
        }

        final neighborColor = colors[neighbor];
        if (neighborColor == null) {
          colors[neighbor] = 1 - currentColor;
          component.add(neighbor);
          visited.add(neighbor);
          queue.add(neighbor);
          continue;
        }

        if (neighborColor == currentColor) {
          hasConflict = true;
          conflictColor = currentColor;
        }
      }
    }

    if (hasConflict) {
      for (final position in component) {
        if (colors[position] == conflictColor) {
          _addElimination(eliminations, seen, position, value);
        }
      }
      continue;
    }

    for (final unit in SudokuUnit.all) {
      final coloredInUnit = component
          .where(
            (position) =>
                unit.cellPositions().contains(position) &&
                colors.containsKey(position),
          )
          .toList();
      if (coloredInUnit.length < 2) {
        continue;
      }

      final byColor = <int, List<CellPosition>>{};
      for (final position in coloredInUnit) {
        byColor.putIfAbsent(colors[position]!, () => []).add(position);
      }

      for (final sameColorCells in byColor.values) {
        if (sameColorCells.length < 2) {
          continue;
        }

        final color = colors[sameColorCells.first]!;
        for (final position in component) {
          if (colors[position] == color) {
            _addElimination(eliminations, seen, position, value);
          }
        }
      }
    }

    for (var row = 0; row < SudokuBoard.size; row++) {
      for (var col = 0; col < SudokuBoard.size; col++) {
        final position = CellPosition(row: row, col: col);
        if (!canPlaceValueAt(board, position, value)) {
          continue;
        }
        if (component.contains(position)) {
          continue;
        }

        var seesColor0 = false;
        var seesColor1 = false;
        for (final colored in component) {
          if (!cellsSeeEachOther(position, colored)) {
            continue;
          }
          if (colors[colored] == 0) {
            seesColor0 = true;
          } else {
            seesColor1 = true;
          }
        }

        if (seesColor0 && seesColor1) {
          _addElimination(eliminations, seen, position, value);
        }
      }
    }
  }

  return eliminations;
}

void _addElimination(
  List<CandidateElimination> eliminations,
  Set<String> seen,
  CellPosition position,
  int value,
) {
  final key = '${position.row}:${position.col}:$value';
  if (!seen.add(key)) {
    return;
  }

  eliminations.add(
    CandidateElimination(position: position, value: value),
  );
}
