import 'package:flutter/material.dart';

import '../models/cell_position.dart';
import '../models/sudoku_board.dart';
import 'sudoku_cell_view.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    super.key,
    required this.board,
    required this.cellSize,
    this.selectedCell,
    this.highlightedNumber,
    this.showImpossibleCells = false,
    this.onCellTap,
    this.onCellBlinkFinished,
  });

  final SudokuBoard board;
  final double cellSize;
  final CellPosition? selectedCell;
  final int? highlightedNumber;
  final bool showImpossibleCells;
  final void Function(int row, int col)? onCellTap;
  final void Function(int row, int col)? onCellBlinkFinished;

  static const Color _selectedColor = Color(0xFF90CAF9);
  static const Color _sameNumberColor = Color(0xFFBBDEFB);
  static const Color _impossibleColor = Color(0xFFFFEBEE);
  static const Color _checkerLight = Color(0xFFF5F5F5);
  static const Color _checkerDark = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SudokuBoard.size,
        ),
        itemCount: SudokuBoard.size * SudokuBoard.size,
        itemBuilder: (context, index) {
          final row = index ~/ SudokuBoard.size;
          final col = index % SudokuBoard.size;
          final cell = board.cellAt(row, col);
          final isSelected =
              selectedCell?.row == row && selectedCell?.col == col;
          final isSameNumberHighlight =
              !isSelected &&
              highlightedNumber != null &&
              cell.value == highlightedNumber;
          final isImpossibleHighlight = showImpossibleCells &&
              !isSelected &&
              !isSameNumberHighlight &&
              highlightedNumber != null &&
              board.isNumberImpossibleAt(row, col, highlightedNumber!);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCellTap == null ? null : () => onCellTap!(row, col),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected
                    ? _selectedColor
                    : isSameNumberHighlight
                    ? _sameNumberColor
                    : isImpossibleHighlight
                    ? _impossibleColor
                    : ((row ~/ SudokuBoard.boxSize) +
                                  (col ~/ SudokuBoard.boxSize)) %
                              2 ==
                          0
                    ? _checkerLight
                    : _checkerDark,
                border: Border(
                  top: row == 0
                      ? const BorderSide(width: 2, color: Colors.black)
                      : BorderSide.none,
                  left: col == 0
                      ? const BorderSide(width: 2, color: Colors.black)
                      : BorderSide.none,
                  right: BorderSide(
                    width:
                        (col + 1) % SudokuBoard.boxSize == 0 ||
                            col == SudokuBoard.size - 1
                        ? 2
                        : 1,
                    color: Colors.black,
                  ),
                  bottom: BorderSide(
                    width:
                        (row + 1) % SudokuBoard.boxSize == 0 ||
                            row == SudokuBoard.size - 1
                        ? 2
                        : 1,
                    color: Colors.black,
                  ),
                ),
              ),
              child: SudokuCellView(
                key: ValueKey('cell-$row-$col'),
                cell: cell,
                cellSize: cellSize,
                highlightedNumber: highlightedNumber,
                onCellBlinkFinished: onCellBlinkFinished == null
                    ? null
                    : () => onCellBlinkFinished!(row, col),
              ),
            ),
          );
        },
      ),
    );
  }
}
