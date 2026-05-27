import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'game_provider.dart';

class TimerProvider extends ChangeNotifier {
  GameProvider _game;
  Timer? _timer;
  int _remaining;
  bool _running = false;

  TimerProvider(this._game) : _remaining = _game.timerConfig.durationSeconds;

  int get remaining => _remaining;
  bool get running => _running;
  int get durationSeconds => _game.timerConfig.durationSeconds;
  double get percentRemaining =>
      durationSeconds > 0 ? _remaining / durationSeconds : 0.0;
  bool get isCritical => _remaining <= 15;

  void syncGame(GameProvider g) {
    _game = g;
    notifyListeners();
  }

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    notifyListeners();
  }

  void toggle() {
    if (_running) {
      stop();
    } else {
      start();
    }
  }

  void reset() {
    stop();
    _remaining = durationSeconds;
    notifyListeners();
  }

  void skipToNext() {
    _game.rotateToNextPlayer();
    reset();
  }

  void _tick() {
    if (_remaining <= 0) {
      _handleExpiry();
      return;
    }
    _remaining--;

    // Haptic feedback as sound replacement
    if (_game.timerConfig.soundEnabled) {
      if (_remaining <= 10 && _remaining % 2 == 0) {
        HapticFeedback.mediumImpact();
      }
    }

    if (_remaining <= 0) {
      _handleExpiry();
    }

    notifyListeners();
  }

  void _handleExpiry() {
    stop();

    // Determine penalty draw count based on timeRule
    int penaltyDraws;
    switch (_game.game.timeRule) {
      case 'official':
        penaltyDraws = 3;
        break;
      case 'alternative':
      case 'impatient':
      case 'custom':
      default:
        penaltyDraws = 1;
        break;
    }

    final currentPlayer = _game.game.turnIdx;
    final rIdx = _game.activeRoundIdx;
    final playerName = _game.game.players.isNotEmpty
        ? _game.game.players[currentPlayer]
        : 'Jogador';

    // Apply penalty
    if (_game.isGameStarted) {
      _game.addPenalty(rIdx, currentPlayer, penaltyDraws);
      _game.addEvent(
        '$playerName estourou o tempo — $penaltyDraws peça(s) de penalidade',
      );
    }

    // Haptic alarm
    if (_game.timerConfig.soundEnabled) {
      HapticFeedback.heavyImpact();
    }

    if (_game.game.turnAutoRotate) {
      _game.rotateToNextPlayer();
      _remaining = durationSeconds;
      start();
    } else {
      _remaining = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
