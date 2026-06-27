import 'package:flutter/material.dart';

enum NumberPickerMode {
  value,
  note,
}

class NumberPickerGrid extends StatelessWidget {
  const NumberPickerGrid({
    super.key,
    required this.onNumberSelected,
    required this.remainingCounts,
    this.mode = NumberPickerMode.value,
  });

  final void Function(int number) onNumberSelected;
  final Map<int, int> remainingCounts;
  final NumberPickerMode mode;

  static const double size = 168;
  static const int _gridSize = 3;
  static const Color _valueNumberColor = Color(0xFF7EB6FF);
  static const Color _noteNumberColor = Color(0xFF9E9E9E);

  Color get _numberColor {
    switch (mode) {
      case NumberPickerMode.value:
        return _valueNumberColor;
      case NumberPickerMode.note:
        return _noteNumberColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final number = index + 1;

            return InkWell(
              onTap: () => onNumberSelected(number),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: _numberColor,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      bottom: 3,
                      child: Text(
                        '${remainingCounts[number] ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
