enum SudokuDifficulty {
  easy(40),
  hard(50),
  extreme(58),
  /// Max cells to try removing during generation. Evil difficulty is defined
  /// by technique requirements, not by how many numbers are removed.
  evil(50);

  const SudokuDifficulty(this.cellsToRemove);

  final int cellsToRemove;

  String get label {
    switch (this) {
      case SudokuDifficulty.easy:
        return 'Easy';
      case SudokuDifficulty.hard:
        return 'Hard';
      case SudokuDifficulty.extreme:
        return 'Extreme';
      case SudokuDifficulty.evil:
        return 'Evil';
    }
  }

  bool get usesPuzzleBuffer {
    return this == SudokuDifficulty.extreme || this == SudokuDifficulty.evil;
  }
}
