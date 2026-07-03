import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/puzzle_factory.dart';
import '../models/stored_puzzle.dart';
import '../models/sudoku_difficulty.dart';
import '../models/techniques/evil_solver.dart';
import '../models/techniques/extreme_solver.dart';

class PuzzleBufferService {
  PuzzleBufferService._();

  static final PuzzleBufferService instance = PuzzleBufferService._();

  static const int bufferSize = 5;

  final Map<SudokuDifficulty, bool> _refilling = {};
  final Map<SudokuDifficulty, List<StoredPuzzle>> _memoryPuzzles = {};
  bool _usePersistentStorage = true;

  static String _storageKey(SudokuDifficulty difficulty) {
    return 'puzzle_buffer_v3_${difficulty.name}';
  }

  /// Pre-fills the Extreme buffer once on app start.
  Future<void> warmBuffers() async {
    try {
      await _warmBuffer(SudokuDifficulty.extreme);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'PuzzleBufferService',
          context: ErrorDescription('while warming puzzle buffers'),
        ),
      );
    }
  }

  Future<void> _warmBuffer(SudokuDifficulty difficulty) async {
    var puzzles = await _loadPuzzles(difficulty);

    while (puzzles.length < bufferSize) {
      final generated = await compute(
        generateBufferedPuzzleForDifficultyIsolate,
        difficulty.index,
      );
      if (!_isPlayablePuzzle(generated, difficulty)) {
        continue;
      }

      puzzles = [...puzzles, generated.trusted()];
      await _savePuzzles(difficulty, puzzles);
    }
  }

  /// Returns the next buffered puzzle. Top-up runs when leaving the game or
  /// closing the app, not while playing.
  Future<StoredPuzzle> takePuzzle(SudokuDifficulty difficulty) async {
    if (!difficulty.usesPuzzleBuffer) {
      throw ArgumentError('${difficulty.label} does not use the puzzle buffer.');
    }

    const maxAttempts = 8;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final puzzles = await _loadPuzzles(difficulty);
      final StoredPuzzle puzzle;

      if (puzzles.isNotEmpty) {
        puzzle = puzzles.removeAt(0);
        await _savePuzzles(difficulty, puzzles);
      } else {
        puzzle = await compute(
          generateBufferedPuzzleForDifficultyIsolate,
          difficulty.index,
        );
      }

      if (_isPlayablePuzzle(puzzle, difficulty)) {
        return puzzle.trusted();
      }
    }

    final fallback = await compute(
      generateBufferedPuzzleForDifficultyIsolate,
      difficulty.index,
    );
    return fallback.trusted();
  }

  void refillBuffer(SudokuDifficulty difficulty) {
    _refillBuffer(difficulty);
  }

  Future<int> bufferCount(SudokuDifficulty difficulty) async {
    if (!difficulty.usesPuzzleBuffer) {
      return 0;
    }

    final cached = _memoryPuzzles[difficulty];
    if (cached != null) {
      return cached.length;
    }

    final puzzles = await _loadPuzzles(difficulty);
    return puzzles.length;
  }

  bool isRefilling(SudokuDifficulty difficulty) {
    return _refilling[difficulty] == true;
  }

  Future<void> _refillBuffer(SudokuDifficulty difficulty) async {
    if (_refilling[difficulty] == true) {
      return;
    }

    _refilling[difficulty] = true;
    try {
      var puzzles = await _loadPuzzles(difficulty);

      while (puzzles.length < bufferSize) {
        final generated = await compute(
          generateBufferedPuzzleForDifficultyIsolate,
          difficulty.index,
        );
        if (!_isPlayablePuzzle(generated, difficulty)) {
          continue;
        }

        puzzles = [...puzzles, generated.trusted()];
        await _savePuzzles(difficulty, puzzles);
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'PuzzleBufferService',
          context: ErrorDescription('while refilling ${difficulty.label} buffer'),
        ),
      );
    } finally {
      _refilling[difficulty] = false;
    }
  }

  bool _isPlayablePuzzle(StoredPuzzle puzzle, SudokuDifficulty difficulty) {
    if (!puzzle.puzzle.any((value) => value == null)) {
      return false;
    }

    if (!puzzle.isStoredSolutionConsistent &&
        !puzzle.hasUniquePlayableSolution) {
      return false;
    }

    switch (difficulty) {
      case SudokuDifficulty.extreme:
        return isValidExtremePuzzle(puzzle.puzzle);
      case SudokuDifficulty.evil:
        return isValidEvilPuzzle(puzzle.puzzle);
      case SudokuDifficulty.easy:
      case SudokuDifficulty.hard:
        return true;
    }
  }

  Future<List<StoredPuzzle>> _loadPuzzles(SudokuDifficulty difficulty) async {
    if (!_usePersistentStorage) {
      return List<StoredPuzzle>.from(_memoryPuzzles[difficulty] ?? const []);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(difficulty));
      if (raw == null) {
        return List<StoredPuzzle>.from(_memoryPuzzles[difficulty] ?? const []);
      }

      final decoded = jsonDecode(raw) as List;
      final puzzles = decoded
          .map((entry) => StoredPuzzle.fromJson(entry as Map<String, dynamic>))
          .where((puzzle) => _isPlayablePuzzle(puzzle, difficulty))
          .map((puzzle) => puzzle.trusted())
          .toList();
      _memoryPuzzles[difficulty] = puzzles;
      return puzzles;
    } catch (_) {
      _usePersistentStorage = false;
      return List<StoredPuzzle>.from(_memoryPuzzles[difficulty] ?? const []);
    }
  }

  Future<void> _savePuzzles(
    SudokuDifficulty difficulty,
    List<StoredPuzzle> puzzles,
  ) async {
    _memoryPuzzles[difficulty] = List<StoredPuzzle>.from(puzzles);

    if (!_usePersistentStorage) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(puzzles.map((puzzle) => puzzle.toJson()).toList());
      await prefs.setString(_storageKey(difficulty), encoded);
    } catch (_) {
      _usePersistentStorage = false;
    }
  }
}
