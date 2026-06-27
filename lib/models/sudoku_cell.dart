import 'cell_number_effect.dart';

class SudokuCell {
  const SudokuCell({
    this.value,
    this.isGiven = false,
    this.notes = const {},
    this.numberEffect = CellNumberEffect.none,
  });

  final int? value;
  final bool isGiven;
  final Set<int> notes;
  final CellNumberEffect numberEffect;

  bool get isEmpty => value == null;

  bool hasNote(int number) => notes.contains(number);

  SudokuCell withNoteToggled(int number) {
    if (value != null || isGiven) {
      return this;
    }
    if (number < 1 || number > 9) {
      return this;
    }

    final nextNotes = Set<int>.from(notes);
    if (nextNotes.contains(number)) {
      nextNotes.remove(number);
    } else {
      nextNotes.add(number);
    }

    return copyWith(notes: nextNotes);
  }

  SudokuCell withNumberEffect(CellNumberEffect effect) {
    return copyWith(numberEffect: effect);
  }

  SudokuCell copyWith({
    int? value,
    bool? isGiven,
    Set<int>? notes,
    CellNumberEffect? numberEffect,
    bool clearValue = false,
  }) {
    final nextValue = clearValue ? null : (value ?? this.value);
    final nextNotes = notes ??
        (value != null && !clearValue ? const <int>{} : this.notes);
    final nextEffect = () {
      if (clearValue) {
        return CellNumberEffect.none;
      }
      if (numberEffect != null) {
        return numberEffect;
      }
      if (value != null && !clearValue) {
        return CellNumberEffect.none;
      }
      return this.numberEffect;
    }();

    return SudokuCell(
      value: nextValue,
      isGiven: isGiven ?? this.isGiven,
      notes: nextNotes,
      numberEffect: nextEffect,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SudokuCell &&
            value == other.value &&
            isGiven == other.isGiven &&
            numberEffect == other.numberEffect &&
            _sameNotes(notes, other.notes);
  }

  @override
  int get hashCode =>
      Object.hash(value, isGiven, numberEffect, Object.hashAllUnordered(notes));

  static bool _sameNotes(Set<int> a, Set<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final note in a) {
      if (!b.contains(note)) {
        return false;
      }
    }
    return true;
  }
}
