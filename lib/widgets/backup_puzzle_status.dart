import 'package:flutter/material.dart';

import '../models/sudoku_difficulty.dart';
import '../services/puzzle_buffer_service.dart';

class BackupPuzzleStatus extends StatefulWidget {
  const BackupPuzzleStatus({
    super.key,
    required this.difficulty,
    this.refreshToken = 0,
  });

  final SudokuDifficulty difficulty;
  final int refreshToken;

  @override
  State<BackupPuzzleStatus> createState() => _BackupPuzzleStatusState();
}

class _BackupPuzzleStatusState extends State<BackupPuzzleStatus> {
  int _backupCount = 0;
  bool _isRefilling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshStatus();
      }
    });
  }

  @override
  void didUpdateWidget(BackupPuzzleStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final count =
        await PuzzleBufferService.instance.bufferCount(widget.difficulty);
    if (!mounted) {
      return;
    }

    setState(() {
      _backupCount = count;
      _isRefilling =
          PuzzleBufferService.instance.isRefilling(widget.difficulty);
    });
  }

  String get _statusLabel {
    if (_backupCount > 0) {
      final label = _backupCount == 1 ? 'puzzle' : 'puzzles';
      return '$_backupCount backup $label ready';
    }

    if (_isRefilling) {
      return 'Preparing backup puzzles…';
    }

    return '0 ready — wait a moment';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _statusLabel,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade600,
      ),
    );
  }
}
