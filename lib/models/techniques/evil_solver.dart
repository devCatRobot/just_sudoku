import 'extreme_solver.dart';
import '../sudoku_solver.dart';

/// Evil puzzles use every technique and must need chains or colouring.
bool isValidEvilPuzzle(List<int?> puzzle) {
  if (!hasUniqueSolution(puzzle)) {
    return false;
  }

  final totalPlacements = puzzle.where((value) => value == null).length;
  if (totalPlacements == 0) {
    return false;
  }

  final maxSingles =
      (totalPlacements * extremeMaxSinglePlacementRatio).floor();

  return solveWithTechniques(
    puzzle,
    maxSinglePlacements: maxSingles,
    maxTechnique: evilMaxTechnique,
    requireHardestAtLeast: evilMinHardestTechnique,
  ).solved;
}

bool isSolvableAsEvilPuzzle(List<int?> puzzle) {
  return solveWithTechniques(
    puzzle,
    maxTechnique: evilMaxTechnique,
  ).solved;
}
