import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_game_state.dart';
import '../models/sudoku_difficulty.dart';

class GameSaveService {
  GameSaveService._();

  static final GameSaveService instance = GameSaveService._();

  final Map<SudokuDifficulty, SavedGameState> _memorySaves = {};
  bool _usePersistentStorage = true;

  static String _storageKey(SudokuDifficulty difficulty) {
    return 'saved_game_${difficulty.name}';
  }

  Future<void> save(SavedGameState state) async {
    _memorySaves[state.difficulty] = state;

    if (!_usePersistentStorage) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey(state.difficulty),
        jsonEncode(state.toJson()),
      );
    } catch (_) {
      _usePersistentStorage = false;
    }
  }

  Future<SavedGameState?> load(SudokuDifficulty difficulty) async {
    if (!_usePersistentStorage) {
      return _memorySaves[difficulty];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(difficulty));
      if (raw == null) {
        return _memorySaves[difficulty];
      }

      final state = SavedGameState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _memorySaves[difficulty] = state;
      return state;
    } catch (_) {
      _usePersistentStorage = false;
      return _memorySaves[difficulty];
    }
  }

  Future<void> clear(SudokuDifficulty difficulty) async {
    _memorySaves.remove(difficulty);

    if (!_usePersistentStorage) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(difficulty));
    } catch (_) {
      _usePersistentStorage = false;
    }
  }
}
