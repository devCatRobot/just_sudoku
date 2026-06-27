import 'package:flutter/material.dart';

import '../models/sudoku_difficulty.dart';
import 'sudoku_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _startGame(BuildContext context, SudokuDifficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SudokuScreen(difficulty: difficulty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _startGame(context, SudokuDifficulty.easy),
              child: const Text('Easy'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _startGame(context, SudokuDifficulty.hard),
              child: const Text('Hard'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _startGame(context, SudokuDifficulty.extreme),
              child: const Text('Extreme'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _startGame(context, SudokuDifficulty.evil),
              child: const Text('Evil'),
            ),
          ],
        ),
      ),
    );
  }
}
