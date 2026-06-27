import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cell_number_effect.dart';
import '../models/sudoku_cell.dart';

class SudokuCellView extends StatefulWidget {
  const SudokuCellView({
    super.key,
    required this.cell,
    required this.cellSize,
    this.highlightedNumber,
    this.onCellBlinkFinished,
  });

  final SudokuCell cell;
  final double cellSize;
  final int? highlightedNumber;
  final VoidCallback? onCellBlinkFinished;

  @override
  State<SudokuCellView> createState() => _SudokuCellViewState();
}

class _SudokuCellViewState extends State<SudokuCellView> {
  static const Duration _blinkInterval = Duration(milliseconds: 150);
  static const Duration _blinkThenNormalDuration = Duration(milliseconds: 900);
  static const Duration _blinkThenClearDuration = Duration(milliseconds: 600);

  static const int _noteGridSize = 3;
  static const Color _noteColor = Color(0xFF9E9E9E);
  static const Color _noteHighlightBackground = Color(0xFFBBDEFB);
  static const Color _noteHighlightText = Color(0xFF1976D2);
  static const Color _userValueColor = Color(0xFF1976D2);

  Timer? _blinkIntervalTimer;
  Timer? _blinkFinishTimer;
  bool _isBlinking = false;
  bool _blinkVisible = true;

  @override
  void initState() {
    super.initState();
    _syncEffect(allowSetState: false);
  }

  @override
  void didUpdateWidget(SudokuCellView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cell.numberEffect != widget.cell.numberEffect ||
        oldWidget.cell.value != widget.cell.value) {
      _syncEffect();
    }
  }

  @override
  void dispose() {
    _stopBlinkTimers();
    super.dispose();
  }

  void _stopBlinkTimers() {
    _blinkIntervalTimer?.cancel();
    _blinkIntervalTimer = null;
    _blinkFinishTimer?.cancel();
    _blinkFinishTimer = null;
  }

  void _syncEffect({bool allowSetState = true}) {
    _stopBlinkTimers();
    _isBlinking = false;
    _blinkVisible = true;

    final effect = widget.cell.numberEffect;
    if (widget.cell.value == null || effect == CellNumberEffect.none) {
      return;
    }

    if (effect == CellNumberEffect.blinkStayRed ||
        effect == CellNumberEffect.blinkThenNormal ||
        effect == CellNumberEffect.blinkThenClear) {
      final blinkDuration = effect == CellNumberEffect.blinkThenClear
          ? _blinkThenClearDuration
          : _blinkThenNormalDuration;

      void startBlink() {
        _isBlinking = true;
        _blinkVisible = true;
        _blinkIntervalTimer = Timer.periodic(_blinkInterval, (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _blinkVisible = !_blinkVisible;
          });
        });
        _blinkFinishTimer = Timer(blinkDuration, _onBlinkFinished);
      }

      if (allowSetState) {
        setState(startBlink);
      } else {
        startBlink();
      }
    }
  }

  void _onBlinkFinished() {
    _stopBlinkTimers();
    if (!mounted) {
      return;
    }

    setState(() {
      _isBlinking = false;
      _blinkVisible = true;
    });

    if (widget.cell.numberEffect == CellNumberEffect.blinkThenNormal ||
        widget.cell.numberEffect == CellNumberEffect.blinkThenClear) {
      widget.onCellBlinkFinished?.call();
    }
  }

  bool get _showRedNumber {
    final effect = widget.cell.numberEffect;
    if (widget.cell.value == null || effect == CellNumberEffect.none) {
      return false;
    }
    if (effect == CellNumberEffect.blinkStayRed) {
      return true;
    }
    return (effect == CellNumberEffect.blinkThenNormal ||
            effect == CellNumberEffect.blinkThenClear) &&
        _isBlinking;
  }

  Widget _buildValueText(double fontSize) {
    final cell = widget.cell;
    final text = Text(
      '${cell.value}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: cell.isGiven ? FontWeight.bold : FontWeight.w500,
        color: _showRedNumber
            ? Colors.red
            : (cell.isGiven ? Colors.black : _userValueColor),
      ),
    );

    if (!_isBlinking) {
      return text;
    }

    return Opacity(
      opacity: _blinkVisible ? 1.0 : 0.25,
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = widget.cellSize;
    final valueFontSize = (cellSize * 0.48).clamp(16.0, 32.0);
    final noteFontSize = (cellSize / _noteGridSize * 0.78).clamp(9.0, 15.0);

    if (widget.cell.value != null) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildValueText(valueFontSize),
        ),
      );
    }

    if (widget.cell.notes.isEmpty) {
      return const SizedBox.expand();
    }

    return Padding(
      padding: EdgeInsets.all(cellSize * 0.01),
      child: Column(
        children: List.generate(_noteGridSize, (row) {
          return Expanded(
            child: Row(
              children: List.generate(_noteGridSize, (col) {
                final number = row * _noteGridSize + col + 1;

                final isHighlightedNote =
                    widget.highlightedNumber == number &&
                    widget.cell.hasNote(number);

                return Expanded(
                  child: Center(
                    child: widget.cell.hasNote(number)
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: isHighlightedNote
                                  ? _noteHighlightBackground
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$number',
                                style: TextStyle(
                                  fontSize: noteFontSize,
                                  height: 1,
                                  fontWeight: FontWeight.w500,
                                  color: isHighlightedNote
                                      ? _noteHighlightText
                                      : _noteColor,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
