import '../models/sudoku_board.dart';
import '../models/sudoku_cell.dart';
import '../models/sudoku_difficulty.dart';
import '../models/sudoku_solver.dart';

class SavedGameState {
  const SavedGameState({
    required this.difficulty,
    required this.solution,
    required this.values,
    required this.isGiven,
    required this.notes,
    required this.isNoteMode,
    required this.showImpossibleCells,
  });

  final SudokuDifficulty difficulty;
  final List<int> solution;
  final List<int?> values;
  final List<bool> isGiven;
  final List<List<int>> notes;
  final bool isNoteMode;
  final bool showImpossibleCells;

  factory SavedGameState.fromBoard({
    required SudokuBoard board,
    required SudokuDifficulty difficulty,
    required bool isNoteMode,
    required bool showImpossibleCells,
  }) {
    final solution = board.solution;
    if (solution == null) {
      throw StateError('Cannot save a board without a solution.');
    }

    final values = <int?>[];
    final isGiven = <bool>[];
    final notes = <List<int>>[];

    for (var row = 0; row < SudokuBoard.size; row++) {
      for (var col = 0; col < SudokuBoard.size; col++) {
        final cell = board.cellAt(row, col);
        values.add(cell.value);
        isGiven.add(cell.isGiven);
        notes.add(cell.notes.toList()..sort());
      }
    }

    return SavedGameState(
      difficulty: difficulty,
      solution: List<int>.from(solution),
      values: values,
      isGiven: isGiven,
      notes: notes,
      isNoteMode: isNoteMode,
      showImpossibleCells: showImpossibleCells,
    );
  }

  SudokuBoard toBoard() {
    final cells = List.generate(
      SudokuBoard.size,
      (row) => List.generate(
        SudokuBoard.size,
        (col) {
          final index = row * SudokuBoard.size + col;
          return SudokuCell(
            value: values[index],
            isGiven: isGiven[index],
            notes: Set<int>.from(notes[index]),
          );
        },
      ),
    );

    return SudokuBoard.fromCells(
      cells: cells,
      solution: solution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty.name,
      'solution': solution,
      'values': values,
      'isGiven': isGiven,
      'notes': notes,
      'isNoteMode': isNoteMode,
      'showImpossibleCells': showImpossibleCells,
    };
  }

  factory SavedGameState.fromJson(Map<String, dynamic> json) {
    return SavedGameState(
      difficulty: SudokuDifficulty.values.byName(json['difficulty'] as String),
      solution: List<int>.from(json['solution'] as List),
      values: (json['values'] as List)
          .map((value) => value == null ? null : value as int)
          .toList(),
      isGiven: List<bool>.from(json['isGiven'] as List),
      notes: (json['notes'] as List)
          .map((entry) => List<int>.from(entry as List))
          .toList(),
      isNoteMode: json['isNoteMode'] as bool,
      showImpossibleCells: json['showImpossibleCells'] as bool,
    );
  }

  /// A playable puzzle has empty cells or at least one value the user entered.
  bool get isPlayable {
    if (values.any((value) => value == null)) {
      return true;
    }

    return isGiven.contains(false);
  }

  /// Detects the old bug where every cell was filled and marked as a given clue.
  bool get isCorruptFullGrid {
    return values.every((value) => value != null) && isGiven.every((given) => given);
  }

  /// Whether the original given clues have exactly one solution.
  bool get hasUniqueGivenClues {
    final clues = List<int?>.filled(SudokuBoard.size * SudokuBoard.size, null);
    for (var i = 0; i < values.length; i++) {
      if (isGiven[i]) {
        clues[i] = values[i];
      }
    }

    return hasUniqueSolution(clues);
  }
}
