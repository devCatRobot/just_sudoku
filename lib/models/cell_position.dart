class CellPosition {
  const CellPosition({
    required this.row,
    required this.col,
  });

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CellPosition && row == other.row && col == other.col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}
