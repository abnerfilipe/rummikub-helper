import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/timer_widget.dart';
import '../widgets/leaderboard_widget.dart';
import '../widgets/score_table.dart';
import '../widgets/action_button.dart';
import '../widgets/dialogs/game_over_dialog.dart';

class GameTab extends StatefulWidget {
  const GameTab({super.key});

  @override
  State<GameTab> createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> {
  bool _gameOverShown = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        // Show game over dialog when game finishes
        if (game.isGameFinished && !_gameOverShown && game.isGameStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_gameOverShown && mounted) {
              _gameOverShown = true;
              showGameOverDialog(context);
            }
          });
        }
        if (!game.isGameFinished) {
          _gameOverShown = false;
        }

        if (game.game.players.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            const TimerWidget(),
            const LeaderboardWidget(),
            const Expanded(child: ScoreTable()),
            const ActionButton(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum jogador adicionado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vá para a aba "Jogadores" e adicione de 2 a 6 jogadores para começar.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
