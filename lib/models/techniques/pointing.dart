import '../cell_position.dart';
import '../sudoku_board.dart';
import 'sudoku_unit.dart';

/// Candidates for [value] in a box are confined to one row or column, so the
/// value can be removed from the rest of that line outside the box.
class Pointing {
  const Pointing({
    required this.box,
    required this.value,
    required this.lineType,
    required this.lineIndex,
    required this.cells,
  });

  final SudokuUnit box;
  final int value;
  final SudokuUnitType lineType;
  final int lineIndex;
  final List<CellPosition> cells;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Pointing &&
            box == other.box &&
            value == other.value &&
            lineType == other.lineType &&
            lineIndex == other.lineIndex &&
            _sameCells(cells, other.cells);
  }

  @override
  int get hashCode =>
      Object.hash(box, value, lineType, lineIndex, Object.hashAll(cells));

  static bool _sameCells(List<CellPosition> a, List<CellPosition> b) {
    return a.length == b.length && Set<CellPosition>.from(a) == Set.from(b);
  }
}

/// Finds every pointing pair or triple on [board].
List<Pointing> findPointings(SudokuBoard board) {
  final results = <Pointing>[];

  for (var boxIndex = 0; boxIndex < SudokuBoard.size; boxIndex++) {
    final box = SudokuUnit(type: SudokuUnitType.box, index: boxIndex);
    results.addAll(_findPointingsInBox(board, box));
  }

  return results;
}

List<Pointing> _findPointingsInBox(SudokuBoard board, SudokuUnit box) {
  final results = <Pointing>[];

  for (var value = 1; value <= SudokuBoard.size; value++) {
    final positions = candidatePositionsForValue(board, box, value);
    if (positions.length < 2 || positions.length > 3) {
      continue;
    }

    final rows = positions.map((position) => position.row).toSet();
    final cols = positions.map((position) => position.col).toSet();

    if (rows.length == 1 &&
        _hasCandidateInRowOutsideBox(board, box, value, rows.first)) {
      results.add(
        Pointing(
          box: box,
          value: value,
          lineType: SudokuUnitType.row,
          lineIndex: rows.first,
          cells: List<CellPosition>.from(positions),
        ),
      );
    }

    if (cols.length == 1 &&
        _hasCandidateInColumnOutsideBox(board, box, value, cols.first)) {
      results.add(
        Pointing(
          box: box,
          value: value,
          lineType: SudokuUnitType.column,
          lineIndex: cols.first,
          cells: List<CellPosition>.from(positions),
        ),
      );
    }
  }

  return results;
}

bool _hasCandidateInRowOutsideBox(
  SudokuBoard board,
  SudokuUnit box,
  int value,
  int row,
) {
  final boxCells = box.cellPositions().toSet();

  for (var col = 0; col < SudokuBoard.size; col++) {
    final position = CellPosition(row: row, col: col);
    if (boxCells.contains(position)) {
      continue;
    }
    if (canPlaceValueAt(board, position, value)) {
      return true;
    }
  }

  return false;
}

bool _hasCandidateInColumnOutsideBox(
  SudokuBoard board,
  SudokuUnit box,
  int value,
  int col,
) {
  final boxCells = box.cellPositions().toSet();

  for (var row = 0; row < SudokuBoard.size; row++) {
    final position = CellPosition(row: row, col: col);
    if (boxCells.contains(position)) {
      continue;
    }
    if (canPlaceValueAt(board, position, value)) {
      return true;
    }
  }

  return false;
}
