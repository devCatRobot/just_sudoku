import 'sudoku_solver.dart';

class StoredPuzzle {
  const StoredPuzzle({
    required this.solution,
    required this.puzzle,
  });

  final List<int> solution;
  final List<int?> puzzle;

  /// Whether the stored [solution] is consistent with puzzle clues (no solver).
  bool get isStoredSolutionConsistent {
    if (puzzle.length != solution.length) {
      return false;
    }

    var hasEmptyCell = false;
    for (var i = 0; i < puzzle.length; i++) {
      final clue = puzzle[i];
      if (clue == null) {
        hasEmptyCell = true;
        continue;
      }
      if (clue != solution[i]) {
        return false;
      }
    }

    return hasEmptyCell;
  }

  /// Whether [puzzle] has exactly one solution that matches its clues.
  bool get hasUniquePlayableSolution {
    if (!hasUniqueSolution(puzzle)) {
      return false;
    }

    final actual = findSolution(puzzle);
    if (actual == null) {
      return false;
    }

    for (var i = 0; i < puzzle.length; i++) {
      final clue = puzzle[i];
      if (clue != null && clue != actual[i]) {
        return false;
      }
    }

    return true;
  }

  /// Returns a trusted copy without running the solver when possible.
  StoredPuzzle trusted() {
    if (isStoredSolutionConsistent) {
      return this;
    }

    return normalized();
  }

  /// Returns a copy whose [solution] matches the puzzle's unique solution.
  StoredPuzzle normalized() {
    final actual = findSolution(puzzle);
    if (actual == null) {
      throw StateError('Puzzle has no solution.');
    }

    return StoredPuzzle(solution: actual, puzzle: puzzle);
  }

  Map<String, dynamic> toJson() {
    return {
      'solution': solution,
      'puzzle': puzzle,
    };
  }

  factory StoredPuzzle.fromJson(Map<String, dynamic> json) {
    return StoredPuzzle(
      solution: List<int>.from(json['solution'] as List),
      puzzle: (json['puzzle'] as List)
          .map((value) => value == null ? null : value as int)
          .toList(),
    );
  }
}
