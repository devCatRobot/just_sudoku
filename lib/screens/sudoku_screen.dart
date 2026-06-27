import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cell_number_effect.dart';
import '../models/cell_position.dart';
import '../models/cell_selection.dart';
import '../models/puzzle_factory.dart';
import '../models/stored_puzzle.dart';
import '../models/saved_game_state.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_difficulty.dart';
import '../services/game_save_service.dart';
import '../services/puzzle_buffer_service.dart';
import '../widgets/backup_puzzle_status.dart';
import '../widgets/fireworks_overlay.dart';
import '../widgets/number_picker_grid.dart';
import '../widgets/sudoku_grid.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key, required this.difficulty});

  final SudokuDifficulty difficulty;

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> with WidgetsBindingObserver {
  SudokuBoard _board = SudokuBoard.empty();
  final ValueNotifier<CellSelection?> _selection =
      ValueNotifier<CellSelection?>(null);
  bool _isNoteMode = false;
  bool _showImpossibleCells = false;
  bool _showCelebration = false;
  bool _isLoadingPuzzle = false;
  int _backupStatusRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreOrLoadPuzzle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduleBufferRefill();
    _selection.dispose();
    unawaited(_saveGame());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_saveGame());
        _scheduleBufferRefill();
      case AppLifecycleState.resumed:
        break;
    }
  }

  void _scheduleBufferRefill() {
    if (!widget.difficulty.usesPuzzleBuffer) {
      return;
    }

    PuzzleBufferService.instance.refillBuffer(widget.difficulty);
  }

  void _schedulePersist() {
    unawaited(_saveGame());
  }

  Future<void> _restoreOrLoadPuzzle() async {
    final saved = await GameSaveService.instance.load(widget.difficulty);
    if (!mounted) {
      return;
    }

    if (saved != null &&
        saved.isPlayable &&
        !saved.isCorruptFullGrid &&
        saved.hasUniqueGivenClues) {
      setState(() {
        _board = saved.toBoard();
        _isNoteMode = saved.isNoteMode;
        _showImpossibleCells = saved.showImpossibleCells;
        _isLoadingPuzzle = false;
      });
      return;
    }

    if (saved != null) {
      await GameSaveService.instance.clear(widget.difficulty);
    }

    if (widget.difficulty.usesPuzzleBuffer) {
      setState(() {
        _isLoadingPuzzle = true;
      });
      await _loadBufferedPuzzle();
      return;
    }

    setState(_loadNewPuzzle);
    _schedulePersist();
  }

  Future<void> _saveGame() async {
    if (_isLoadingPuzzle || _board.solution == null) {
      return;
    }

    final state = SavedGameState.fromBoard(
      board: _board,
      difficulty: widget.difficulty,
      isNoteMode: _isNoteMode,
      showImpossibleCells: _showImpossibleCells,
    );

    if (!state.isPlayable || state.isCorruptFullGrid) {
      return;
    }

    await GameSaveService.instance.save(state);
  }

  Future<void> _leaveScreen() async {
    _scheduleBufferRefill();
    await _saveGame();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _loadNewPuzzle() {
    final generated = generatePuzzleForDifficulty(widget.difficulty);
    _board = SudokuBoard.fromPuzzle(
      solution: generated.solution,
      puzzle: generated.puzzle,
    );
  }

  Future<void> _loadBufferedPuzzle() async {
    StoredPuzzle stored;
    final timeout = widget.difficulty == SudokuDifficulty.evil
        ? const Duration(seconds: 45)
        : const Duration(seconds: 12);

    try {
      stored = await PuzzleBufferService.instance
          .takePuzzle(widget.difficulty)
          .timeout(timeout);
    } catch (_) {
      stored = widget.difficulty == SudokuDifficulty.evil
          ? generateEvilPuzzleForBuffer()
          : generateExtremePuzzleForBuffer();
    }

    if (!mounted) {
      return;
    }

    final playable = stored.trusted();
    setState(() {
      _board = SudokuBoard.fromPuzzle(
        solution: playable.solution,
        puzzle: playable.puzzle,
      );
      _isLoadingPuzzle = false;
      _backupStatusRefreshToken++;
    });
    _schedulePersist();
  }

  Future<void> _startNewPuzzle() async {
    await GameSaveService.instance.clear(widget.difficulty);

    _selection.value = null;
    _isNoteMode = false;
    _showCelebration = false;

    if (widget.difficulty.usesPuzzleBuffer) {
      setState(() {
        _isLoadingPuzzle = true;
      });
      await _loadBufferedPuzzle();
      return;
    }

    setState(_loadNewPuzzle);
    _schedulePersist();
  }

  Future<void> _onNewPuzzleTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New puzzle?'),
        content: const Text(
          'Start a new puzzle? Your current progress for this level will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('New puzzle'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _startNewPuzzle();
  }

  SudokuBoard _boardWithCellEffect(int row, int col, CellNumberEffect effect) {
    return _board.withCell(
      row,
      col,
      _board.cellAt(row, col).withNumberEffect(effect),
    );
  }

  SudokuBoard _boardWithConflictEffect(
    int row,
    int col,
    int number,
    CellNumberEffect effect,
  ) {
    var board = _board;

    for (final conflict in _board.valueConflictsAt(row, col, number)) {
      final conflictRow = conflict.row;
      final conflictCol = conflict.col;
      board = board.withCell(
        conflictRow,
        conflictCol,
        board.cellAt(conflictRow, conflictCol).withNumberEffect(effect),
      );
    }

    return board;
  }

  SudokuBoard _boardWithBlinkStayRedOnConflicts(int row, int col, int number) {
    return _boardWithConflictEffect(
      row,
      col,
      number,
      CellNumberEffect.blinkStayRed,
    );
  }

  SudokuBoard _boardWithBlinkThenNormalOnConflicts(
    int row,
    int col,
    int number,
  ) {
    return _boardWithConflictEffect(
      row,
      col,
      number,
      CellNumberEffect.blinkThenNormal,
    );
  }

  SudokuBoard _boardClearBlinkStayRed(SudokuBoard board) {
    var result = board;

    for (var r = 0; r < SudokuBoard.size; r++) {
      for (var c = 0; c < SudokuBoard.size; c++) {
        final cell = result.cellAt(r, c);
        if (cell.numberEffect == CellNumberEffect.blinkStayRed) {
          result = result.withCell(
            r,
            c,
            cell.withNumberEffect(CellNumberEffect.none),
          );
        }
      }
    }

    return result;
  }

  void _onCellBlinkFinished(int row, int col) {
    if (!mounted) {
      return;
    }

    final cell = _board.cellAt(row, col);
    var shouldPersist = false;
    setState(() {
      if (cell.numberEffect == CellNumberEffect.blinkThenClear) {
        _board = _board.withCell(
          row,
          col,
          cell.copyWith(clearValue: true, notes: cell.notes),
        );
        shouldPersist = true;
        return;
      }

      if (cell.numberEffect == CellNumberEffect.blinkThenNormal) {
        _board = _boardWithCellEffect(row, col, CellNumberEffect.none);
      }
    });
    if (shouldPersist) {
      _schedulePersist();
    }
  }

  void _onCellTap(int row, int col) {
    _selection.value = CellSelection(
      cell: CellPosition(row: row, col: col),
      highlightedNumber: _board.valueAt(row, col),
    );
  }

  void _onNumberSelected(int number) {
    final selected = _selection.value;
    if (selected == null) {
      return;
    }

    final row = selected.cell.row;
    final col = selected.cell.col;

    if (_isNoteMode) {
      if (!_board.canToggleNote(row, col, number)) {
        final cell = _board.cellAt(row, col);
        if (!cell.hasNote(number) &&
            _board.isValueInRowOrColumn(row, col, number)) {
          setState(() {
            _board = _boardWithBlinkThenNormalOnConflicts(row, col, number);
          });
        }
        return;
      }

      setState(() {
        _board = _board.withNoteToggled(row, col, number);
      });
      _schedulePersist();
      return;
    }

    if (!_board.canPlaceValue(row, col, number)) {
      if (_board.isValueInRowOrColumn(row, col, number)) {
        setState(() {
          _board = _boardWithBlinkStayRedOnConflicts(row, col, number);
        });
      }
      return;
    }

    final correctAnswer = _board.solutionAt(row, col);
    if (correctAnswer != null && number != correctAnswer) {
      setState(() {
        var board = _boardClearBlinkStayRed(_board);
        final cell = board.cellAt(row, col);
        board = board.withCell(
          row,
          col,
          cell.copyWith(
            value: number,
            notes: cell.notes,
            numberEffect: CellNumberEffect.blinkThenClear,
          ),
        );
        _board = board;
      });
      return;
    }

    setState(() {
      var board = _boardClearBlinkStayRed(_board.withValue(row, col, number));
      board = board.withNoteRemovedFromPeers(row, col, number);
      _board = board;
      _showCelebration = board.isSolvedCorrectly();
    });
    _schedulePersist();
  }

  void _onPencilTap() {
    setState(() {
      _isNoteMode = !_isNoteMode;
    });
    _schedulePersist();
  }

  void _onImpossibleCellsTap() {
    setState(() {
      _showImpossibleCells = !_showImpossibleCells;
    });
    _schedulePersist();
  }

  void _onInfoTap() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Symbols'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                Icon(
                  Icons.lightbulb_outline,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
                'Light bulb',
                'Turn on to highlight cells where the tapped number cannot go. '
                    'Turn off to only highlight matching numbers.',
              ),
              _infoRow(
                Icon(Icons.star_border, size: 24, color: Colors.grey.shade700),
                'Star',
                'Fill every empty cell with possible notes, based on row, '
                    'column, and 3×3 box.',
              ),
              _infoRow(
                _starWithCrossIcon(color: Colors.grey.shade700),
                'Undo star',
                'Remove all notes from every cell. Use this to undo notes '
                    'added by the star button. Numbers you placed in edit mode stay.',
              ),
              _infoRow(
                Icon(Icons.edit, size: 24, color: Colors.grey.shade700),
                'Pencil',
                'Switch to note mode. Tap numbers to add or remove small notes '
                    'in a cell instead of placing a value.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(Widget icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, height: 24, child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _starWithCrossIcon({double size = 24, Color? color}) {
    final iconColor = color ?? Colors.grey.shade700;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(Icons.star_border, size: size, color: iconColor),
        Positioned(
          right: -2,
          top: -2,
          child: Icon(Icons.close, size: size * 0.5, color: iconColor),
        ),
      ],
    );
  }

  void _onStarTap() {
    setState(() {
      _board = _board.withCandidateNotesFilled();
    });
    _schedulePersist();
  }

  void _onClearAllNotesTap() {
    setState(() {
      _board = _board.withAllNotesCleared();
    });
    _schedulePersist();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _leaveScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveScreen,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isLoadingPuzzle ? null : _onNewPuzzleTap,
                child: const Text('New puzzle'),
              ),
            ),
          ],
        ),
        body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.difficulty.usesPuzzleBuffer)
                  Align(
                    alignment: Alignment.centerRight,
                    child: BackupPuzzleStatus(
                      difficulty: widget.difficulty,
                      refreshToken: _backupStatusRefreshToken,
                    ),
                  ),
                if (widget.difficulty.usesPuzzleBuffer)
                  const SizedBox(height: 4),
                Text(
                  widget.difficulty.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gridWidth = constraints.maxWidth;
                    final cellSize = gridWidth / SudokuBoard.size;

                    return SizedBox(
                      width: gridWidth,
                      child: ValueListenableBuilder<CellSelection?>(
                        valueListenable: _selection,
                        builder: (context, selection, _) {
                          return SudokuGrid(
                            board: _board,
                            cellSize: cellSize,
                            selectedCell: selection?.cell,
                            highlightedNumber: selection?.highlightedNumber,
                            showImpossibleCells: _showImpossibleCells,
                            onCellTap: _onCellTap,
                            onCellBlinkFinished: _onCellBlinkFinished,
                          );
                        },
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _onInfoTap,
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Help',
                    ),
                    IconButton(
                      onPressed: _onImpossibleCellsTap,
                      icon: Icon(
                        _showImpossibleCells
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline,
                      ),
                      tooltip: _showImpossibleCells
                          ? 'Impossible cells on'
                          : 'Impossible cells off',
                      style: IconButton.styleFrom(
                        backgroundColor: _showImpossibleCells
                            ? Colors.grey.shade300
                            : Colors.transparent,
                        foregroundColor: _showImpossibleCells
                            ? Colors.grey.shade800
                            : Colors.grey.shade500,
                      ),
                    ),
                    IconButton(
                      onPressed: _onStarTap,
                      icon: const Icon(Icons.star_border),
                      tooltip: 'Fill candidate notes',
                    ),
                    IconButton(
                      onPressed: _onClearAllNotesTap,
                      icon: Builder(
                        builder: (context) => _starWithCrossIcon(
                          color: IconTheme.of(context).color,
                        ),
                      ),
                      tooltip: 'Undo star notes',
                    ),
                    IconButton(
                      onPressed: _onPencilTap,
                      icon: const Icon(Icons.edit),
                      tooltip: _isNoteMode ? 'Note mode on' : 'Note mode off',
                      style: IconButton.styleFrom(
                        backgroundColor: _isNoteMode
                            ? Colors.grey.shade300
                            : Colors.transparent,
                        foregroundColor: _isNoteMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: NumberPickerGrid(
                    mode: _isNoteMode
                        ? NumberPickerMode.note
                        : NumberPickerMode.value,
                    remainingCounts: _board.remainingDigitCounts(),
                    onNumberSelected: _onNumberSelected,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingPuzzle)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xCCFFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_showCelebration)
            Positioned.fill(child: FireworksOverlay(onTap: _startNewPuzzle)),
        ],
      ),
      ),
    );
  }
}
