import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

const int _maxXYChainDepth = 10;

/// Chains of bivalue cells linked by shared candidates. Eliminates the matching
/// endpoint digit from cells that see both chain ends.
List<CandidateElimination> findXYChainEliminations(SudokuBoard board) {
  final bivalueCells = <CellPosition, Set<int>>{};
  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      final notes = candidateNotesAt(board, position);
      if (notes.length == 2) {
        bivalueCells[position] = notes;
      }
    }
  }

  if (bivalueCells.length < 2) {
    return const [];
  }

  final neighbors = _buildBivalueNeighbors(bivalueCells);
  final eliminations = <CandidateElimination>[];
  final seen = <String>{};

  for (final start in bivalueCells.keys) {
    _searchChains(
      board: board,
      start: start,
      current: start,
      previous: null,
      path: [start],
      bivalueCells: bivalueCells,
      neighbors: neighbors,
      eliminations: eliminations,
      seen: seen,
    );
  }

  return eliminations;
}

Map<CellPosition, Set<CellPosition>> _buildBivalueNeighbors(
  Map<CellPosition, Set<int>> bivalueCells,
) {
  final neighbors = <CellPosition, Set<CellPosition>>{};
  final positions = bivalueCells.keys.toList();

  for (var i = 0; i < positions.length; i++) {
    for (var j = i + 1; j < positions.length; j++) {
      final cellA = positions[i];
      final cellB = positions[j];
      if (!cellsSeeEachOther(cellA, cellB)) {
        continue;
      }

      final shared = bivalueCells[cellA]!.intersection(bivalueCells[cellB]!);
      if (shared.length != 1) {
        continue;
      }

      neighbors.putIfAbsent(cellA, () => <CellPosition>{}).add(cellB);
      neighbors.putIfAbsent(cellB, () => <CellPosition>{}).add(cellA);
    }
  }

  return neighbors;
}

void _searchChains({
  required SudokuBoard board,
  required CellPosition start,
  required CellPosition current,
  required CellPosition? previous,
  required List<CellPosition> path,
  required Map<CellPosition, Set<int>> bivalueCells,
  required Map<CellPosition, Set<CellPosition>> neighbors,
  required List<CandidateElimination> eliminations,
  required Set<String> seen,
}) {
  if (path.length >= 2 && current != start) {
    _addEndpointEliminations(
      board: board,
      start: start,
      nextFromStart: path[1],
      end: current,
      previousOfEnd: previous,
      bivalueCells: bivalueCells,
      eliminations: eliminations,
      seen: seen,
    );
  }

  if (path.length >= _maxXYChainDepth) {
    return;
  }

  for (final neighbor in neighbors[current] ?? const {}) {
    if (path.contains(neighbor)) {
      continue;
    }

    _searchChains(
      board: board,
      start: start,
      current: neighbor,
      previous: current,
      path: [...path, neighbor],
      bivalueCells: bivalueCells,
      neighbors: neighbors,
      eliminations: eliminations,
      seen: seen,
    );
  }
}

void _addEndpointEliminations({
  required SudokuBoard board,
  required CellPosition start,
  required CellPosition nextFromStart,
  required CellPosition end,
  required CellPosition? previousOfEnd,
  required Map<CellPosition, Set<int>> bivalueCells,
  required List<CandidateElimination> eliminations,
  required Set<String> seen,
}) {
  if (previousOfEnd == null) {
    return;
  }

  final startNotes = bivalueCells[start]!;
  final endNotes = bivalueCells[end]!;
  final startLink = startNotes.intersection(bivalueCells[nextFromStart]!);
  final endLink = endNotes.intersection(bivalueCells[previousOfEnd]!);

  if (startLink.length != 1 || endLink.length != 1) {
    return;
  }

  final startElim = startNotes.difference({startLink.first});
  final endElim = endNotes.difference({endLink.first});
  if (startElim.length != 1 || endElim.length != 1) {
    return;
  }

  final eliminationValue = startElim.first;
  if (eliminationValue != endElim.first) {
    return;
  }

  for (var row = 0; row < SudokuBoard.size; row++) {
    for (var col = 0; col < SudokuBoard.size; col++) {
      final position = CellPosition(row: row, col: col);
      if (position == start || position == end) {
        continue;
      }
      if (!canPlaceValueAt(board, position, eliminationValue)) {
        continue;
      }
      if (!cellsSeeEachOther(position, start) ||
          !cellsSeeEachOther(position, end)) {
        continue;
      }

      final key = '${position.row}:${position.col}:$eliminationValue';
      if (!seen.add(key)) {
        continue;
      }

      eliminations.add(
        CandidateElimination(
          position: position,
          value: eliminationValue,
        ),
      );
    }
  }
}
