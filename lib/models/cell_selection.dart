import 'cell_position.dart';

class CellSelection {
  const CellSelection({
    required this.cell,
    required this.highlightedNumber,
  });

  final CellPosition cell;
  final int? highlightedNumber;
}
