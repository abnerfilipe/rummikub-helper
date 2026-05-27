import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/timer_config.dart';

const _gameKey = 'rummi_v7_game';
const _timerKey = 'rummi_v7_timer';

class GameProvider extends ChangeNotifier {
  GameState _game = GameState.initial();
  TimerConfig _timerConfig = TimerConfig.initial();

  GameState get game => _game;
  TimerConfig get timerConfig => _timerConfig;

  // Convenience getters
  bool get isGameStarted => _game.started;
  bool get isGameFinished =>
      _game.started && _game.currIdx >= _game.rounds.length;
  int get activeRoundIdx => _game.editingIdx ?? _game.currIdx;
  int get playerCount => _game.players.length;
  int get minPlayers => 2;
  int get maxPlayers => 6;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final gameStr = prefs.getString(_gameKey);
    final timerStr = prefs.getString(_timerKey);
    if (gameStr != null) {
      try {
        _game = GameState.fromJsonString(gameStr);
      } catch (_) {
        _game = GameState.initial();
      }
    }
    if (timerStr != null) {
      try {
        _timerConfig = TimerConfig.fromJsonString(timerStr);
      } catch (_) {
        _timerConfig = TimerConfig.initial();
      }
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameKey, _game.toJsonString());
  }

  Future<void> saveTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timerKey, _timerConfig.toJsonString());
  }

  // Player management
  String? addPlayer(String name) {
    if (_game.locked) return 'A partida já foi iniciada.';
    if (_game.players.length >= maxPlayers) {
      return 'Máximo de $maxPlayers jogadores atingido.';
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Nome não pode estar vazio.';
    if (trimmed.length > 20) return 'Nome deve ter no máximo 20 caracteres.';
    if (_game.players.contains(trimmed)) return 'Jogador já existe.';

    _game.players.add(trimmed);
    notifyListeners();
    save();
    return null;
  }

  String? removePlayer(int idx) {
    if (_game.locked) return 'A partida já foi iniciada.';
    if (_game.players.length <= minPlayers) {
      return 'Mínimo de $minPlayers jogadores necessário.';
    }
    if (idx < 0 || idx >= _game.players.length) return 'Índice inválido.';

    _game.players.removeAt(idx);
    notifyListeners();
    save();
    return null;
  }

  void movePlayer(int from, int to) {
    if (_game.locked) return;
    if (from < 0 ||
        from >= _game.players.length ||
        to < 0 ||
        to >= _game.players.length) return;
    if (from == to) return;

    // Swap players
    final tmp = _game.players[from];
    _game.players[from] = _game.players[to];
    _game.players[to] = tmp;

    // Swap columns in rounds
    for (final row in _game.rounds) {
      if (from < row.length && to < row.length) {
        final t = row[from];
        row[from] = row[to];
        row[to] = t;
      }
    }

    // Swap tileDetails
    final newTileDetails = <String, List<int>>{};
    for (final entry in _game.tileDetails.entries) {
      final parts = entry.key.split('-');
      if (parts.length == 2) {
        final rIdx = int.tryParse(parts[0]);
        final pIdx = int.tryParse(parts[1]);
        if (pIdx != null && rIdx != null) {
          int newPIdx = pIdx;
          if (pIdx == from) {
            newPIdx = to;
          } else if (pIdx == to) {
            newPIdx = from;
          }
          newTileDetails['$rIdx-$newPIdx'] = entry.value;
        } else {
          newTileDetails[entry.key] = entry.value;
        }
      } else {
        newTileDetails[entry.key] = entry.value;
      }
    }
    _game.tileDetails
      ..clear()
      ..addAll(newTileDetails);

    // Swap roundWinners
    final newWinners = <int, int>{};
    for (final entry in _game.roundWinners.entries) {
      int newPIdx = entry.value;
      if (entry.value == from) {
        newPIdx = to;
      } else if (entry.value == to) {
        newPIdx = from;
      }
      newWinners[entry.key] = newPIdx;
    }
    _game.roundWinners
      ..clear()
      ..addAll(newWinners);

    notifyListeners();
    save();
  }

  String? renamePlayer(int idx, String name) {
    if (idx < 0 || idx >= _game.players.length) return 'Índice inválido.';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Nome não pode estar vazio.';
    if (trimmed.length > 20) return 'Nome deve ter no máximo 20 caracteres.';

    _game.players[idx] = trimmed;
    notifyListeners();
    save();
    return null;
  }

  void startGame() {
    if (_game.started) return;
    if (_game.players.length < minPlayers) return;

    _game.locked = true;
    _game.started = true;
    _game.currIdx = 0;

    // Initialize first round with empty scores
    _ensureRoundsUpToCurrent();

    notifyListeners();
    save();
  }

  void _ensureRoundsUpToCurrent() {
    while (_game.rounds.length <= _game.currIdx) {
      _game.rounds.add(List.filled(_game.players.length, ''));
    }
  }

  void applyScore(int rIdx, int pIdx, String val,
      {List<int>? tileCounts}) {
    if (rIdx < 0 || rIdx >= _game.rounds.length) return;
    if (pIdx < 0 || pIdx >= _game.players.length) return;

    _game.rounds[rIdx][pIdx] = val;

    if (tileCounts != null) {
      _game.tileDetails['$rIdx-$pIdx'] = tileCounts;
    }

    // Recalculate winner score if this round has a winner
    recalculateWinner(rIdx);

    notifyListeners();
    save();
  }

  void recalculateWinner(int rIdx) {
    final winnerPIdx = _game.roundWinners[rIdx];
    if (winnerPIdx == null) return;
    if (rIdx < 0 || rIdx >= _game.rounds.length) return;

    final row = _game.rounds[rIdx];
    int sum = 0;
    for (int i = 0; i < row.length; i++) {
      if (i == winnerPIdx) continue;
      final v = int.tryParse(row[i]);
      if (v != null) sum += v;
    }
    // Winner's score is negative sum of others (makes total = 0)
    _game.rounds[rIdx][winnerPIdx] = (-sum).toString();
  }

  void setRoundWinner(int rIdx, int pIdx) {
    if (rIdx < 0 || rIdx >= _game.rounds.length) return;
    if (pIdx < 0 || pIdx >= _game.players.length) return;

    // Clear old winner's auto-calculated score
    final oldWinner = _game.roundWinners[rIdx];
    if (oldWinner != null && oldWinner != pIdx) {
      _game.rounds[rIdx][oldWinner] = '';
    }

    _game.roundWinners[rIdx] = pIdx;
    // Mark winner's cell as empty (will be auto-calculated)
    _game.rounds[rIdx][pIdx] = '';

    // Calculate winner score from current scores of others
    recalculateWinner(rIdx);

    notifyListeners();
    save();
  }

  void clearRoundWinner(int rIdx) {
    _game.roundWinners.remove(rIdx);
    notifyListeners();
    save();
  }

  void finishRound(int rIdx) {
    if (_game.editingIdx != null) {
      _game.editingIdx = null;
    } else {
      _game.currIdx++;
      _ensureRoundsUpToCurrent();
    }
    notifyListeners();
    save();
  }

  void enableEdit(int rIdx) {
    _game.editingIdx = rIdx;
    notifyListeners();
    save();
  }

  void cancelEdit() {
    _game.editingIdx = null;
    notifyListeners();
    save();
  }

  Future<void> resetGame() async {
    _game = GameState.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameKey);
    notifyListeners();
  }

  Future<void> saveTimerSettings({
    required int seconds,
    required bool sound,
    required String rule,
    required bool autoRotate,
    required bool confirmExpiry,
  }) async {
    _timerConfig = TimerConfig(
      durationSeconds: seconds,
      soundEnabled: sound,
    );
    _game.timeRule = rule;
    _game.turnAutoRotate = autoRotate;
    _game.confirmExpiry = confirmExpiry;

    notifyListeners();
    await save();
    await saveTimer();
  }

  void addPenalty(int rIdx, int pIdx, int draws) {
    _game.roundPenalties[rIdx] ??= {};
    _game.roundPenalties[rIdx]![pIdx] =
        (_game.roundPenalties[rIdx]![pIdx] ?? 0) + draws;
    notifyListeners();
    save();
  }

  void rotateToNextPlayer() {
    if (_game.players.isEmpty) return;
    _game.turnIdx = (_game.turnIdx + 1) % _game.players.length;
    notifyListeners();
    save();
  }

  void addEvent(String msg) {
    _game.events.insert(0, GameEvent(ts: DateTime.now(), msg: msg));
    if (_game.events.length > 200) {
      _game.events = _game.events.sublist(0, 200);
    }
    notifyListeners();
    save();
  }

  // Compute per-player totals across all rounds
  List<int> computeTotals() {
    final totals = List<int>.filled(_game.players.length, 0);
    for (final row in _game.rounds) {
      for (int i = 0; i < row.length && i < totals.length; i++) {
        final v = int.tryParse(row[i]);
        if (v != null) totals[i] += v;
      }
    }
    return totals;
  }

  // Returns sorted player indices by score (lowest = best in Rummikub)
  List<int> get leaderboardOrder {
    final totals = computeTotals();
    final indices = List<int>.generate(_game.players.length, (i) => i);
    indices.sort((a, b) => totals[a].compareTo(totals[b]));
    return indices;
  }
}
