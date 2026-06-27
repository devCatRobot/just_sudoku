import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

const int _maxXChainDepth = 12;

/// Alternating strong/weak chains on one digit. Eliminates the digit from cells
/// that see both chain endpoints.
List<CandidateElimination> findXChainEliminations(SudokuBoard board) {
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

  final strongNeighbors = _strongNeighbors(board, value);
  final weakNeighbors = _weakNeighbors(board, value, candidates);
  final eliminations = <CandidateElimination>[];

  for (final start in candidates) {
    _searchChains(
      board: board,
      value: value,
      start: start,
      current: start,
      path: [start],
      nextMustBeStrong: true,
      strongNeighbors: strongNeighbors,
      weakNeighbors: weakNeighbors,
      eliminations: eliminations,
      seen: seen,
    );
    _searchChains(
      board: board,
      value: value,
      start: start,
      current: start,
      path: [start],
      nextMustBeStrong: false,
      strongNeighbors: strongNeighbors,
      weakNeighbors: weakNeighbors,
      eliminations: eliminations,
      seen: seen,
    );
  }

  return eliminations;
}

Map<CellPosition, Set<CellPosition>> _strongNeighbors(
  SudokuBoard board,
  int value,
) {
  final neighbors = <CellPosition, Set<CellPosition>>{};
  for (final pair in findConjugatePairs(board, value)) {
    neighbors
        .putIfAbsent(pair.cellA, () => <CellPosition>{})
        .add(pair.cellB);
    neighbors
        .putIfAbsent(pair.cellB, () => <CellPosition>{})
        .add(pair.cellA);
  }
  return neighbors;
}

Map<CellPosition, Set<CellPosition>> _weakNeighbors(
  SudokuBoard board,
  int value,
  List<CellPosition> candidates,
) {
  final neighbors = <CellPosition, Set<CellPosition>>{};
  final candidateSet = candidates.toSet();

  for (final unit in SudokuUnit.all) {
    final inUnit = unit
        .cellPositions()
        .where((position) => candidateSet.contains(position))
        .toList();
    if (inUnit.length < 2) {
      continue;
    }

    for (final cellA in inUnit) {
      for (final cellB in inUnit) {
        if (cellA == cellB) {
          continue;
        }
        neighbors.putIfAbsent(cellA, () => <CellPosition>{}).add(cellB);
      }
    }
  }

  return neighbors;
}

void _searchChains({
  required SudokuBoard board,
  required int value,
  required CellPosition start,
  required CellPosition current,
  required List<CellPosition> path,
  required bool nextMustBeStrong,
  required Map<CellPosition, Set<CellPosition>> strongNeighbors,
  required Map<CellPosition, Set<CellPosition>> weakNeighbors,
  required List<CandidateElimination> eliminations,
  required Set<String> seen,
}) {
  if (path.length >= 2 && current != start) {
    _addEndpointEliminations(
      board: board,
      value: value,
      start: start,
      end: current,
      eliminations: eliminations,
      seen: seen,
    );
  }

  if (path.length >= _maxXChainDepth) {
    return;
  }

  final neighbors = nextMustBeStrong
      ? strongNeighbors[current] ?? const {}
      : weakNeighbors[current] ?? const {};

  for (final neighbor in neighbors) {
    if (path.contains(neighbor)) {
      continue;
    }
    if (!canPlaceValueAt(board, neighbor, value)) {
      continue;
    }

    _searchChains(
      board: board,
      value: value,
      start: start,
      current: neighbor,
      path: [...path, neighbor],
      nextMustBeStrong: !nextMustBeStrong,
      strongNeighbors: strongNeighbors,
      weakNeighbors: weakNeighbors,
      eliminations: eliminations,
      seen: seen,
    );
  }
}

void _addEndpointEliminations({
  required SudokuBoard board,
  required int value,
  required CellPosition start,
  required CellPosition end,
  required List<CandidateElimination> eliminations,
  required Set<String> seen,
}) {
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      if (position == start || position == end) {
        continue;
      }
      if (!canPlaceValueAt(board, position, value)) {
        continue;
      }
      if (!cellsSeeEachOther(position, start) ||
          !cellsSeeEachOther(position, end)) {
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
