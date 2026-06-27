import 'cell_position.dart';
import 'sudoku_cell.dart';
import 'sudoku_generator.dart';

class SudokuBoard {
  const SudokuBoard._(this._cells, this.solution);

  static const int size = 9;
  static const int boxSize = 3;

  final List<List<SudokuCell>> _cells;
  final List<int>? solution;

  factory SudokuBoard.empty() {
    return SudokuBoard._(
      List.generate(
        size,
        (_) => List.generate(size, (_) => const SudokuCell()),
      ),
      null,
    );
  }

  factory SudokuBoard.fromSolution(List<int> solution) {
    if (solution.length != size * size) {
      throw ArgumentError('Solution must contain ${size * size} values.');
    }

    final rows = solvedGridToRows(solution);
    return SudokuBoard.fromValues(
      rows.map((row) => row.cast<int?>()).toList(),
      treatFilledAsGiven: false,
    )._copyWithSolution(List.unmodifiable(solution));
  }

  factory SudokuBoard.fromPuzzle({
    required List<int> solution,
    required List<int?> puzzle,
  }) {
    if (solution.length != size * size) {
      throw ArgumentError('Solution must contain ${size * size} values.');
    }
    if (puzzle.length != size * size) {
      throw ArgumentError('Puzzle must contain ${size * size} values.');
    }

    return SudokuBoard.fromValues(
      puzzleGridToRows(puzzle),
      treatFilledAsGiven: true,
    )._copyWithSolution(List.unmodifiable(solution));
  }

  factory SudokuBoard.fromValues(
    List<List<int?>> values, {
    bool treatFilledAsGiven = true,
  }) {
    if (values.length != size) {
      throw ArgumentError('Board must have $size rows.');
    }

    final cells = <List<SudokuCell>>[];
    for (var row = 0; row < size; row++) {
      if (values[row].length != size) {
        throw ArgumentError('Row $row must have $size columns.');
      }

      cells.add(
        List.generate(
          size,
          (col) {
            final value = values[row][col];
            return SudokuCell(
              value: value,
              isGiven: treatFilledAsGiven && value != null,
            );
          },
        ),
      );
    }

    return SudokuBoard._(cells, null);
  }

  factory SudokuBoard.fromCells({
    required List<List<SudokuCell>> cells,
    required List<int> solution,
  }) {
    if (solution.length != size * size) {
      throw ArgumentError('Solution must contain ${size * size} values.');
    }
    if (cells.length != size) {
      throw ArgumentError('Board must have $size rows.');
    }

    return SudokuBoard._(
      cells.map(List<SudokuCell>.from).toList(),
      List.unmodifiable(solution),
    );
  }

  SudokuBoard _copyWithSolution(List<int> solution) {
    return SudokuBoard._(_cells, solution);
  }

  int? solutionAt(int row, int col) => solution?[row * size + col];

  bool isSolvedCorrectly() {
    final solution = this.solution;
    if (solution == null) {
      return false;
    }

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final value = valueAt(row, col);
        if (value == null || value != solutionAt(row, col)) {
          return false;
        }
      }
    }

    return true;
  }

  SudokuCell cellAt(int row, int col) => _cells[row][col];

  int? valueAt(int row, int col) => _cells[row][col].value;

  /// How many more of each digit 1-9 still need to be placed on the board.
  Map<int, int> remainingDigitCounts() {
    final placed = List.filled(size + 1, 0);

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final value = valueAt(row, col);
        if (value != null) {
          placed[value]++;
        }
      }
    }

    return {
      for (var digit = 1; digit <= size; digit++) digit: size - placed[digit],
    };
  }

  bool isGivenAt(int row, int col) => _cells[row][col].isGiven;

  bool canPlaceValue(int row, int col, int number) {
    final current = cellAt(row, col);
    if (current.isGiven || number < 1 || number > 9) {
      return false;
    }
    return !isValueInRowOrColumn(row, col, number);
  }

  bool canToggleNote(int row, int col, int number) {
    final current = cellAt(row, col);
    if (current.isGiven || current.value != null || number < 1 || number > 9) {
      return false;
    }
    if (current.hasNote(number)) {
      return true;
    }
    return !isValueInRowOrColumn(row, col, number);
  }

  bool isValueInRowOrColumn(int row, int col, int number) {
    return valueConflictsAt(row, col, number).isNotEmpty;
  }

  /// Returns whether [number] cannot be placed at [row]/[col].
  bool isNumberImpossibleAt(int row, int col, int number) {
    final value = valueAt(row, col);
    if (value == number) {
      return false;
    }
    if (value != null) {
      return true;
    }
    return isValueInRowOrColumn(row, col, number);
  }

  Iterable<CellPosition> valueConflictsAt(int row, int col, int number) sync* {
    for (var c = 0; c < size; c++) {
      if (c != col && valueAt(row, c) == number) {
        yield CellPosition(row: row, col: c);
      }
    }

    for (var r = 0; r < size; r++) {
      if (r != row && valueAt(r, col) == number) {
        yield CellPosition(row: r, col: col);
      }
    }

    final boxRow = (row ~/ boxSize) * boxSize;
    final boxCol = (col ~/ boxSize) * boxSize;
    for (var r = boxRow; r < boxRow + boxSize; r++) {
      for (var c = boxCol; c < boxCol + boxSize; c++) {
        if (r == row && c == col) {
          continue;
        }
        if (valueAt(r, c) == number) {
          yield CellPosition(row: r, col: c);
        }
      }
    }
  }

  SudokuBoard withCell(int row, int col, SudokuCell cell) {
    final nextRows = _cells.map(List<SudokuCell>.from).toList();
    nextRows[row][col] = cell;
    return SudokuBoard._(nextRows, solution);
  }

  SudokuBoard withValue(int row, int col, int? value) {
    final current = cellAt(row, col);
    if (current.isGiven) {
      return this;
    }
    if (value != null && isValueInRowOrColumn(row, col, value)) {
      return this;
    }

    return withCell(
      row,
      col,
      current.copyWith(value: value, clearValue: value == null),
    );
  }

  /// Removes [number] from notes in every other cell in the same row,
  /// column, and 3x3 box as [row]/[col].
  SudokuBoard withNoteRemovedFromPeers(int row, int col, int number) {
    var board = this;
    final updated = <String>{};

    void removeNoteAt(int r, int c) {
      if (r == row && c == col) {
        return;
      }

      final key = '$r-$c';
      if (updated.contains(key)) {
        return;
      }
      updated.add(key);

      final cell = board.cellAt(r, c);
      if (!cell.hasNote(number)) {
        return;
      }

      final nextNotes = Set<int>.from(cell.notes)..remove(number);
      board = board.withCell(r, c, cell.copyWith(notes: nextNotes));
    }

    for (var c = 0; c < size; c++) {
      removeNoteAt(row, c);
    }

    for (var r = 0; r < size; r++) {
      removeNoteAt(r, col);
    }

    final boxRow = (row ~/ boxSize) * boxSize;
    final boxCol = (col ~/ boxSize) * boxSize;
    for (var r = boxRow; r < boxRow + boxSize; r++) {
      for (var c = boxCol; c < boxCol + boxSize; c++) {
        removeNoteAt(r, c);
      }
    }

    return board;
  }

  SudokuBoard withNoteToggled(int row, int col, int number) {
    final current = cellAt(row, col);
    if (current.isGiven) {
      return this;
    }
    if (!current.hasNote(number) &&
        isValueInRowOrColumn(row, col, number)) {
      return this;
    }

    return withCell(
      row,
      col,
      current.withNoteToggled(number),
    );
  }

  /// Fills every empty cell with notes for numbers allowed in its row,
  /// column, and 3x3 box.
  SudokuBoard withCandidateNotesFilled() {
    var board = this;

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final cell = board.cellAt(row, col);
        if (cell.value != null) {
          continue;
        }

        final candidates = <int>{};
        for (var number = 1; number <= size; number++) {
          if (!board.isValueInRowOrColumn(row, col, number)) {
            candidates.add(number);
          }
        }

        board = board.withCell(row, col, cell.copyWith(notes: candidates));
      }
    }

    return board;
  }

  /// Removes all notes from every cell. Values are not changed.
  SudokuBoard withAllNotesCleared() {
    var board = this;

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final cell = board.cellAt(row, col);
        if (cell.notes.isEmpty) {
          continue;
        }
        board = board.withCell(row, col, cell.copyWith(notes: const {}));
      }
    }

    return board;
  }
}
