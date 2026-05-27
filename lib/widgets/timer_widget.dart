import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/timer_provider.dart';
import 'dialogs/timer_settings_dialog.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimerProvider, GameProvider>(
      builder: (context, timer, game, _) {
        final isCritical = timer.isCritical;
        final currentPlayerIdx = game.game.turnIdx;
        final players = game.game.players;
        final currentPlayerName = players.isNotEmpty && currentPlayerIdx < players.length
            ? players[currentPlayerIdx]
            : '—';

        final minutes = timer.remaining ~/ 60;
        final seconds = timer.remaining % 60;
        final timeStr =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCritical
                ? Colors.red.shade50
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCritical
                  ? Colors.red.shade400
                  : Theme.of(context).colorScheme.outlineVariant,
              width: isCritical ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isCritical
                    ? Colors.red.withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentPlayerName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Timer display
              Text(
                timeStr,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isCritical ? Colors.red.shade700 : null,
                    ),
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timer.percentRemaining.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isCritical
                      ? Colors.red.shade100
                      : Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCritical
                        ? Colors.red.shade500
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset button
                  IconButton.outlined(
                    onPressed: timer.reset,
                    icon: const Icon(Icons.replay),
                    tooltip: 'Reiniciar',
                  ),
                  const SizedBox(width: 8),
                  // Play/Pause button
                  FilledButton.icon(
                    onPressed: timer.toggle,
                    icon: Icon(timer.running ? Icons.pause : Icons.play_arrow),
                    label: Text(timer.running ? 'Pausar' : 'Iniciar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isCritical ? Colors.red.shade500 : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Skip to next player button
                  IconButton.outlined(
                    onPressed: () {
                      timer.skipToNext();
                      game.addEvent(
                        '${currentPlayerName} pulou o turno',
                      );
                    },
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'Próximo jogador',
                  ),
                  const SizedBox(width: 8),
                  // Settings button
                  IconButton.outlined(
                    onPressed: () => showTimerSettingsDialog(context),
                    icon: const Icon(Icons.settings),
                    tooltip: 'Configurações do timer',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
