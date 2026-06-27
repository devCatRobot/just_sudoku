import 'sudoku_board.dart';

/// Returns whether [number] can be placed at [index] without breaking sudoku rules.
bool isValidPlacement(List<int?> grid, int index, int number) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;
  if (grid.length != cellCount) {
    throw ArgumentError('Grid must contain $cellCount values.');
  }
  if (index < 0 || index >= cellCount) {
    throw ArgumentError('Index must be between 0 and ${cellCount - 1}.');
  }

  final row = index ~/ SudokuBoard.size;
  final col = index % SudokuBoard.size;

  for (var c = 0; c < SudokuBoard.size; c++) {
    final cellIndex = row * SudokuBoard.size + c;
    if (cellIndex != index && grid[cellIndex] == number) {
      return false;
    }
  }

  for (var r = 0; r < SudokuBoard.size; r++) {
    final cellIndex = r * SudokuBoard.size + col;
    if (cellIndex != index && grid[cellIndex] == number) {
      return false;
    }
  }

  final boxRow = (row ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize;
  final boxCol = (col ~/ SudokuBoard.boxSize) * SudokuBoard.boxSize;
  for (var r = boxRow; r < boxRow + SudokuBoard.boxSize; r++) {
    for (var c = boxCol; c < boxCol + SudokuBoard.boxSize; c++) {
      final cellIndex = r * SudokuBoard.size + c;
      if (cellIndex != index && grid[cellIndex] == number) {
        return false;
      }
    }
  }

  return true;
}

/// Finds one completed solution for [puzzle].
///
/// [puzzle] uses `null` for empty cells and `1-9` for filled cells.
/// Returns `null` when the puzzle is invalid or has no solution.
List<int>? findSolution(List<int?> puzzle) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;
  if (puzzle.length != cellCount) {
    throw ArgumentError('Puzzle must contain $cellCount values.');
  }

  if (!_hasValidStartingClues(puzzle)) {
    return null;
  }

  final grid = List<int?>.from(puzzle);
  if (!_fillNextEmptyCell(grid, 0)) {
    return null;
  }

  return List<int>.generate(cellCount, (index) => grid[index]!);
}

/// Counts how many solutions [puzzle] has, stopping after [maxCount].
int countSolutions(List<int?> puzzle, {int maxCount = 2}) {
  final cellCount = SudokuBoard.size * SudokuBoard.size;
  if (puzzle.length != cellCount) {
    throw ArgumentError('Puzzle must contain $cellCount values.');
  }
  if (maxCount < 1) {
    throw ArgumentError('maxCount must be at least 1.');
  }
  if (!_hasValidStartingClues(puzzle)) {
    return 0;
  }

  final grid = List<int?>.from(puzzle);
  final solutionCount = <int>[0];
  _countSolutions(grid, 0, maxCount, solutionCount);
  return solutionCount[0];
}

/// Returns `true` when [puzzle] has exactly one solution.
bool hasUniqueSolution(List<int?> puzzle) {
  return countSolutions(puzzle, maxCount: 2) == 1;
}

bool _hasValidStartingClues(List<int?> puzzle) {
  for (var index = 0; index < puzzle.length; index++) {
    final value = puzzle[index];
    if (value == null) {
      continue;
    }
    if (value < 1 || value > SudokuBoard.size) {
      return false;
    }
    if (!isValidPlacement(puzzle, index, value)) {
      return false;
    }
  }
  return true;
}

bool _fillNextEmptyCell(List<int?> grid, int index) {
  final cellCount = grid.length;
  if (index == cellCount) {
    return true;
  }

  if (grid[index] != null) {
    return _fillNextEmptyCell(grid, index + 1);
  }

  for (var number = 1; number <= SudokuBoard.size; number++) {
    if (!isValidPlacement(grid, index, number)) {
      continue;
    }

    grid[index] = number;
    if (_fillNextEmptyCell(grid, index + 1)) {
      return true;
    }
    grid[index] = null;
  }

  return false;
}

void _countSolutions(
  List<int?> grid,
  int index,
  int maxCount,
  List<int> solutionCount,
) {
  if (solutionCount[0] >= maxCount) {
    return;
  }

  if (index == grid.length) {
    solutionCount[0]++;
    return;
  }

  if (grid[index] != null) {
    _countSolutions(grid, index + 1, maxCount, solutionCount);
    return;
  }

  for (var number = 1; number <= SudokuBoard.size; number++) {
    if (!isValidPlacement(grid, index, number)) {
      continue;
    }

    grid[index] = number;
    _countSolutions(grid, index + 1, maxCount, solutionCount);
    grid[index] = null;

    if (solutionCount[0] >= maxCount) {
      return;
    }
  }
}
