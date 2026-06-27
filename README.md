# Just Sudoku

A clean Sudoku app with **no ads** — just the puzzle. Built with Flutter.

**Latest release:** [v1.0](../../releases/tag/v1.0) — Android APK available on the Releases page.

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

## Download

### Android (v1.0)

1. Open [Releases](../../releases) and choose **v1.0**
2. Download `app-release.apk`
3. Install on your device (you may need to allow installs from unknown sources)

### Apple (iPhone / iPad)

There is no iOS build in the v1.0 release yet. See [Build for Apple devices](#build-for-apple-devices) below if you want to build and install it yourself, or wait for a future App Store / TestFlight release.

## Build from source

### Requirements (all platforms)

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.12)
- Git

### Setup

```bash
git clone https://github.com/YOUR_USERNAME/just_sudoku.git
cd just_sudoku
flutter pub get
```

### Run in debug (any platform)

```bash
flutter run
```

Use a connected device or emulator. Flutter will detect Android, iOS, or desktop automatically.

---

## Build for Android

### Requirements

- Android SDK (via [Android Studio](https://developer.android.com/studio) or command-line tools)
- JDK 17+
- A connected Android device with USB debugging enabled, or an emulator

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

---

## Build for Apple devices

iOS builds **must be done on a Mac** with Xcode installed.

### Requirements

- macOS
- [Xcode](https://developer.apple.com/xcode/) (from the Mac App Store)
- Xcode command-line tools: `xcode-select --install`
- CocoaPods: `sudo gem install cocoapods` (if not already installed)
- **Apple Developer account** ($99/year) — required to publish on the App Store or distribute via TestFlight; a free Apple ID is enough to run on your own device for development

### First-time iOS setup

```bash
cd just_sudoku
flutter pub get
cd ios
pod install
cd ..
```

Open the iOS project in Xcode to set your **Team** and **Bundle Identifier**:

```bash
open ios/Runner.xcworkspace
```

In Xcode: select the **Runner** target → **Signing & Capabilities** → choose your team.

### Run on a connected iPhone or iPad (debug)

```bash
flutter run
```

### Release build (IPA for App Store / TestFlight)

```bash
flutter build ipa --release
```

Output is under `build/ios/ipa/`. Upload with Xcode (**Organizer** → **Distribute App**) or [Apple Transporter](https://apps.apple.com/app/transporter/id1450874784).

> **Note:** You cannot build or sign an iOS app from Windows or Linux alone. For a public iOS release you need a Mac, Xcode, and a paid Apple Developer membership.

---

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
