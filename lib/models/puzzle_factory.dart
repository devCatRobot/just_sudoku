import 'dart:math';

import 'stored_puzzle.dart';
import 'sudoku_difficulty.dart';
import 'sudoku_generator.dart';
import 'sudoku_solver.dart';
import 'techniques/techniques.dart';

/// Quickly builds a unique-solution puzzle by random removal, checking
/// uniqueness once per attempt instead of after every cell removal.
StoredPuzzle generateQuickPuzzle(int cellsToRemove, {Random? random}) {
  const maxAttempts = 12;
  final rng = random ?? Random();

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final solution = generateSolvedSudoku(random: Random(rng.nextInt(1 << 31)));
    final puzzle = removeValuesFromSet(
      solution,
      cellsToRemove,
      random: Random(rng.nextInt(1 << 31)),
    );

    if (hasUniqueSolution(puzzle)) {
      return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
    }
  }

  return _generateUniquePuzzle(cellsToRemove, random: rng);
}

StoredPuzzle _generateUniquePuzzle(int cellsToRemove, {Random? random}) {
  final solution = generateSolvedSudoku(random: random);
  final puzzle = generatePuzzleFromSolution(
    solution,
    cellsToRemove,
    random: random,
  );
  return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
}

StoredPuzzle _validatedStoredPuzzle(StoredPuzzle stored) {
  if (stored.hasUniquePlayableSolution) {
    return stored.normalized();
  }

  return _generateUniquePuzzle(SudokuDifficulty.evil.cellsToRemove);
}

StoredPuzzle generateQuickPuzzleIsolate(int cellsToRemove) {
  return generateQuickPuzzle(cellsToRemove);
}

StoredPuzzle generateBufferedPuzzle(int cellsToRemove) {
  return generateQuickPuzzle(cellsToRemove);
}

StoredPuzzle generateBufferedPuzzleIsolate(int cellsToRemove) {
  return generateQuickPuzzle(cellsToRemove);
}

/// Fast Extreme puzzle: unique solution only. Used when the buffer is empty.
StoredPuzzle generateExtremePuzzleQuick() {
  return generateQuickPuzzle(SudokuDifficulty.extreme.cellsToRemove);
}

StoredPuzzle generateExtremePuzzleQuickIsolate(int cellsToRemove) {
  return generateQuickPuzzle(cellsToRemove);
}

/// Tries validated Extreme puzzles for the background buffer.
StoredPuzzle generateExtremePuzzleForBuffer() {
  const maxAttempts = 20;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final solution = generateSolvedSudoku(random: Random(attempt));
    final puzzle = generatePuzzleFromSolution(
      solution,
      SudokuDifficulty.extreme.cellsToRemove,
      random: Random(attempt + 100),
    );

    if (isValidExtremePuzzle(puzzle)) {
      return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
    }
  }

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final solution = generateSolvedSudoku(random: Random(attempt + 200));
    final puzzle = generatePuzzleFromSolution(
      solution,
      SudokuDifficulty.hard.cellsToRemove,
      random: Random(attempt + 300),
    );

    if (isValidHardPuzzle(puzzle)) {
      return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
    }
  }

  return _generateUniquePuzzle(SudokuDifficulty.extreme.cellsToRemove);
}

StoredPuzzle generateExtremePuzzle() {
  return generateExtremePuzzleForBuffer();
}

StoredPuzzle generateExtremePuzzleForBufferIsolate(int _) {
  return generateExtremePuzzleForBuffer();
}

StoredPuzzle generateEasyPuzzle() {
  final solution = generateSolvedSudoku();
  final puzzle = generatePuzzleFromSolution(
    solution,
    SudokuDifficulty.easy.cellsToRemove,
    puzzleFilter: isSolvableWithSinglesOnly,
  );
  return StoredPuzzle(solution: solution, puzzle: puzzle);
}

StoredPuzzle generateHardPuzzle() {
  const maxAttempts = 25;
  final solution = generateSolvedSudoku();

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final puzzle = generatePuzzleFromSolution(
      solution,
      SudokuDifficulty.hard.cellsToRemove,
      random: Random(attempt),
    );

    if (isValidHardPuzzle(puzzle)) {
      return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
    }
  }

  final puzzle = generatePuzzleFromSolution(
    solution,
    SudokuDifficulty.hard.cellsToRemove,
  );
  return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
}

StoredPuzzle generateEvilPuzzle() {
  const maxEvilAttempts = 8;

  for (var attempt = 0; attempt < maxEvilAttempts; attempt++) {
    final solution = generateSolvedSudoku(random: Random(attempt));
    final puzzle = generatePuzzleFromSolution(
      solution,
      SudokuDifficulty.evil.cellsToRemove,
      random: Random(attempt + 17),
    );

    if (isValidEvilPuzzle(puzzle)) {
      return StoredPuzzle(solution: solution, puzzle: puzzle).normalized();
    }
  }

  return _generateUniquePuzzle(SudokuDifficulty.evil.cellsToRemove);
}

StoredPuzzle generateEvilPuzzleForBuffer() {
  return _validatedStoredPuzzle(generateEvilPuzzle());
}

StoredPuzzle generateEvilPuzzleForBufferIsolate(int _) {
  return generateEvilPuzzleForBuffer();
}

StoredPuzzle generateBufferedPuzzleForDifficultyIsolate(int difficultyIndex) {
  final difficulty = SudokuDifficulty.values[difficultyIndex];
  switch (difficulty) {
    case SudokuDifficulty.extreme:
      return generateExtremePuzzleForBuffer();
    case SudokuDifficulty.evil:
      return generateEvilPuzzleForBuffer();
    case SudokuDifficulty.easy:
    case SudokuDifficulty.hard:
      throw ArgumentError('${difficulty.label} does not use the puzzle buffer.');
  }
}

StoredPuzzle _ensurePlayablePuzzle(StoredPuzzle stored) {
  return _validatedStoredPuzzle(stored);
}

StoredPuzzle generateEvilPuzzleIsolate(int _) {
  return _ensurePlayablePuzzle(generateEvilPuzzle());
}

StoredPuzzle generatePuzzleForDifficulty(SudokuDifficulty difficulty) {
  switch (difficulty) {
    case SudokuDifficulty.easy:
      return generateEasyPuzzle();
    case SudokuDifficulty.hard:
      return generateHardPuzzle();
    case SudokuDifficulty.extreme:
      return generateExtremePuzzleForBuffer();
    case SudokuDifficulty.evil:
      return generateEvilPuzzle();
  }
}

StoredPuzzle generatePuzzleForDifficultyIsolate(int difficultyIndex) {
  return generatePuzzleForDifficulty(SudokuDifficulty.values[difficultyIndex]);
}
