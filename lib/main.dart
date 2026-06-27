import 'package:flutter/material.dart';

import 'models/sudoku_difficulty.dart';
import 'screens/menu_screen.dart';
import 'services/puzzle_buffer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JustSudokuApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    PuzzleBufferService.instance.warmBuffers();
  });
}

class JustSudokuApp extends StatefulWidget {
  const JustSudokuApp({super.key});

  @override
  State<JustSudokuApp> createState() => _JustSudokuAppState();
}

class _JustSudokuAppState extends State<JustSudokuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _refillBufferedDifficulties();
      case AppLifecycleState.inactive:
      case AppLifecycleState.resumed:
        break;
    }
  }

  void _refillBufferedDifficulties() {
    PuzzleBufferService.instance.refillBuffer(SudokuDifficulty.extreme);
    PuzzleBufferService.instance.refillBuffer(SudokuDifficulty.evil);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'just_sudoku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MenuScreen(),
    );
  }
}
