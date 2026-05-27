# CLAUDE.md — Rummikub Helper

## Project Overview

A Flutter app for tracking Rummikub game scores. The UI and all text are in Brazilian Portuguese (pt-BR). It runs on Android, iOS, and Web. State is persisted via `SharedPreferences` (equivalent to `localStorage` on web).

Live app: https://abnerfilipe.github.io/rummikub-helper/

---

## Tech Stack

| Tool | Role |
|------|------|
| Flutter 3.27+ | UI framework (Material Design 3) |
| Dart 3.4+ | Language |
| Provider | State management (`ChangeNotifier`) |
| SharedPreferences | Persistence (`rummi_v7_game` and `rummi_v7_timer` keys) |
| HapticFeedback | Timer tick/alarm feedback (replaces Web Audio API) |
| GitHub Actions | CI/CD — builds Flutter web and deploys to GitHub Pages on `main` push |

No custom backend. No runtime dependencies beyond the Flutter SDK and the packages in `pubspec.yaml`.

---

## Repository Layout

```
pubspec.yaml               Flutter package manifest
lib/
  main.dart                Entry point — sets up MultiProvider and runs RummikubApp
  models/
    game_state.dart        GameState + GameEvent — full JSON serialization
    timer_config.dart      TimerConfig — duration + soundEnabled
  providers/
    game_provider.dart     ChangeNotifier — all game mutations, persistence
    timer_provider.dart    ChangeNotifier — countdown timer, expiry handling
  screens/
    home_screen.dart       Scaffold + BottomNavigationBar (4 tabs, IndexedStack)
    game_tab.dart          Main game view (timer + leaderboard + score table + action button)
    players_tab.dart       Add/remove/rename/reorder players
    rules_tab.dart         Static Rummikub rules text (pt-BR)
    about_tab.dart         App info, version, GitHub link
  widgets/
    score_table.dart       Scrollable DataTable with round scores per player
    tile_calc_sheet.dart   showTileCalcSheet() — bottom sheet for entering tile counts
    timer_widget.dart      Timer display + play/pause/skip/settings controls
    leaderboard_widget.dart Collapsible ranking with trophy icons
    action_button.dart     Context-sensitive "Iniciar / Concluir / Salvar / Finalizado"
    dialogs/
      confirm_dialog.dart        showConfirmDialog()
      error_dialog.dart          showErrorSnackBar()
      winner_dialog.dart         showWinnerDialog() — auto-calculated winner score
      game_over_dialog.dart      showGameOverDialog() — final rankings + nova partida
      timer_settings_dialog.dart showTimerSettingsDialog() — rules, sound, auto-rotate
android/                   Minimal Android project (Kotlin + Gradle)
ios/                       Minimal iOS project (Swift)
web/                       Flutter web entry point (index.html + manifest.json)
.github/workflows/
  deploy.yml               Builds Flutter web → deploys build/web/ to gh-pages branch
```

---

## Architecture

### State Management

| Provider | Purpose |
|----------|---------|
| `GameProvider` | Single source of truth for game state. Wraps `GameState` + `TimerConfig`. Loads from and persists to `SharedPreferences`. |
| `TimerProvider` | Countdown timer driven by `dart:async Timer.periodic`. Reads `GameProvider` for config; calls `GameProvider` methods on expiry. |

`GameProvider` is created before `runApp` so it can `await init()`. `TimerProvider` is a `ChangeNotifierProxyProvider` — it receives `GameProvider` via `syncGame()` on every update without restarting the timer.

### State Schema (`SharedPreferences` key: `rummi_v7_game`)

```dart
GameState {
  List<String> players          // ordered player names
  List<List<String>> rounds     // rounds[rIdx][pIdx] = score string or ""
  int currIdx                   // index of the active round
  int? editingIdx               // non-null while editing a past round
  bool locked                   // true once the game has started
  bool started                  // same semantics as locked
  Map<String, List<int>> tileDetails  // "rIdx-pIdx" → 14-element tile counts
  Map<int, int> roundWinners    // rIdx → playerIdx of the winner
  int turnIdx                   // whose turn is currently active
  String timeRule               // 'official' | 'alternative' | 'impatient' | 'custom'
  bool turnAutoRotate           // auto-advance on timer expiry
  bool confirmExpiry            // show confirm dialog on expiry
  Map<int, Map<int, int>> roundPenalties  // rIdx → playerIdx → drawCount
  List<GameEvent> events        // max 200 entries [{ts, msg}]
}
```

Timer config (`SharedPreferences` key: `rummi_v7_timer`): `{ d: seconds, s: soundEnabled }`.

### Tile Details Format

`tileDetails` keys are strings `"$rIdx-$pIdx"`. Values are `List<int>` of exactly 14 elements:
- Indices 0–12 → tile values 1–13
- Index 13 → Curinga (joker), worth 30 points

### Round Scoring Rules

- All players except the winner enter their remaining tile values as **negative** numbers.
- The winner's score = **negative sum of all other players' scores** (so the round total is always 0).
- When exactly one cell is empty and the action button is pressed, `showWinnerDialog` auto-calculates and fills the winner's score.
- `showTileCalcSheet` computes the tile total and writes it as a negative value into the score cell, or marks the player as winner.

### Timer Expiry Penalties

| `timeRule` | Penalty draws |
|------------|---------------|
| `official` | 3 |
| `alternative` | 1 |
| `impatient` | 1 |
| `custom` | 1 |

### Game Flow

1. Add players (2–6) in the "Jogadores" tab.
2. Tap "Iniciar Rodada" → locks the player list, creates round 0.
3. Each round: tap a score cell to open `TileCalcSheet`, enter tile counts or mark as winner, tap "Aplicar".
4. Tap "Concluir Rodada" → validates sum = 0, advances `currIdx`.
5. When `currIdx >= rounds.length` the game-over dialog appears.
6. Past rounds can be edited via the pencil icon; `editingIdx` tracks which round is being edited.

---

## Development Workflows

### Install dependencies
```sh
flutter pub get
```

### Start dev server (web)
```sh
flutter run -d chrome
```

### Start dev server (mobile)
```sh
flutter run  # picks up connected device or emulator
```

### Production build (web)
```sh
flutter build web --base-href /rummikub-helper/
# Output goes to build/web/
```

### Run tests
```sh
flutter test
```

### Analyze code
```sh
flutter analyze
```

---

## Testing Conventions

- Widget tests live in `test/`. Use `flutter_test` and `provider` test utilities.
- Tests should use `ChangeNotifierProvider` with mocked or real `GameProvider`/`TimerProvider`.
- The `TimerProvider` timer should be stopped in `tearDown` to avoid async leaks.

---

## CI/CD

`.github/workflows/deploy.yml` triggers on every push to `main`:
1. `subosito/flutter-action@v2` — installs Flutter 3.27 stable.
2. `flutter pub get` — installs dependencies.
3. `flutter test` — runs unit/widget tests.
4. `flutter build web --base-href /rummikub-helper/` — builds to `build/web/`.
5. `peaceiris/actions-gh-pages@v4` — publishes `build/web/` to the `gh-pages` branch.

The live site picks up changes within a minute of merging to `main`.

---

## Key Conventions for AI Assistants

- **No framework migrations**: this is intentionally vanilla Flutter with Provider. Do not introduce Riverpod, Bloc, GetX, or any other state management library.
- **Portuguese UI text**: all labels, SnackBars, dialog titles, and error messages must stay in pt-BR.
- **`ChangeNotifier` pattern**: every mutation in `GameProvider` must call `notifyListeners()` and `save()`. Every mutation in `TimerProvider` must call `notifyListeners()`.
- **SharedPreferences keys are versioned**: the key `rummi_v7_game` includes a version. If the `GameState` schema changes in a breaking way, bump the version and add migration logic in `GameProvider.init()`.
- **Scores are always summed to zero per round**: preserve this invariant. The winner's score = negative sum of all others. Use `recalculateWinner(rIdx)` after any score change.
- **Build output is `build/web/`**: never change the Flutter output directory without also updating the deploy workflow `publish_dir`.
- **`escapeHtml()` is NOT needed**: Flutter's widget system is not HTML-injection-vulnerable. Use widget `Text()` instead of `innerHTML`.
- **`showModalBottomSheet` and `showDialog`**: use these for all modals — do not use `Navigator.push` for overlays.
- **Provider access in dialogs**: when a dialog needs a provider that was available in the calling context, pass it via `ChangeNotifierProvider.value(value: context.read<XProvider>(), child: ...)` in the `builder`.
- **`GameProvider.maxPlayers = 6`, `minPlayers = 2`**: enforce these bounds in the UI as well as the provider.
