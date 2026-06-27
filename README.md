# Just Sudoku

A clean Sudoku app for **Android** with **no ads** — just the puzzle. Built with Flutter.

**Latest release:** [v1.0](../../releases/tag/v1.0) — download the APK from the Releases page.

## Why this app exists

Most Sudoku apps are cluttered with ads and extra screens. **Just Sudoku** was built to be the opposite: a simple, focused experience — pick a difficulty, play, and nothing else gets in the way.

- No ads  
- No account or sign-in  
- Works offline  
- Four difficulty levels with fair, unique puzzles  

## Features

### Difficulty levels

| Level | Description |
|-------|-------------|
| **Easy** | Solvable with naked and hidden singles only |
| **Hard** | Adds pairs and triples; singles are capped |
| **Extreme** | Advanced techniques: pointing, wings, X-Wing, Swordfish |
| **Evil** | Full solver set, including chains and colouring |

Every generated puzzle has a **unique solution**.

### Gameplay

- Tap a cell, then pick a number to place a value or note
- **Pencil** — toggle note mode
- **Star** — fill candidate notes in empty cells
- **Light bulb** — highlight cells where the selected number cannot go
- **Remaining counts** — digits still needed shown on the number pad
- Wrong entries and conflicts get visual feedback
- Fireworks when you complete a puzzle

### Other

- Auto-save per difficulty level
- **New puzzle** with confirmation
- Backup puzzles for Extreme and Evil (refilled when you leave the game or close the app)

## Download (Android v1.0)

1. Open [Releases](../../releases) and choose **v1.0**
2. Download `app-release.apk`
3. Install on your Android device (you may need to allow installs from unknown sources)

## Build from source

### Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.12)
- Android SDK (via [Android Studio](https://developer.android.com/studio) or command-line tools)
- JDK 17+
- Git

### Setup

```bash
git clone https://github.com/YOUR_USERNAME/just_sudoku.git
cd just_sudoku
flutter pub get
```

### Run on a device or emulator (debug)

```bash
flutter run
```

Connect an Android phone with USB debugging enabled, or start an Android emulator.

### Release APK

```bash
flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

Install that file on a phone, or upload it to a GitHub Release (as in v1.0).

### Optional: install directly on a connected phone

```bash
flutter install --release
```

## Project structure

```
lib/
  models/       # Board, puzzles, solvers, difficulty
  screens/      # Menu and game screen
  services/     # Save game, puzzle buffer
  widgets/      # Grid, cells, number picker
```

## Tech stack

- **Flutter** / **Dart**
- **shared_preferences** — saved games and puzzle buffer

## License

See [LICENSE](LICENSE) if present, or contact the repository owner for usage terms.
