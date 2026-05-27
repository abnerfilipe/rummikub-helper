import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import 'confirm_dialog.dart';

void showGameOverDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<GameProvider>(),
      child: const _GameOverDialog(),
    ),
  );
}

class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final totals = game.computeTotals();
    final players = game.game.players;

    final ranked = List.generate(players.length, (i) => i)
      ..sort((a, b) => totals[b].compareTo(totals[a]));

    final winner = ranked.isNotEmpty ? players[ranked.first] : null;

    return AlertDialog(
      icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
      title: Text(
        winner != null ? 'Parabéns, $winner!' : 'Jogo Finalizado!',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Classificação final:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...ranked.asMap().entries.map((e) {
            final rank = e.key;
            final pIdx = e.value;
            final score = totals[pIdx];
            final scoreStr = score > 0 ? '+$score' : '$score';
            final scoreColor = score > 0
                ? Colors.green.shade700
                : score < 0
                    ? Colors.red.shade700
                    : Colors.grey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _buildRankBadge(rank),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      players[pIdx],
                      style: TextStyle(
                        fontWeight: rank == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    scoreStr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirmed = await showConfirmDialog(
              context,
              'Nova Partida?',
              'Todos os dados serão perdidos.',
            );
            if (confirmed == true && context.mounted) {
              Navigator.of(context).pop();
              game.resetGame();
            }
          },
          child: const Text('Nova Partida'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 0) {
      return const Icon(Icons.emoji_events, size: 20, color: Colors.amber);
    }
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank == 1
            ? Colors.grey.shade300
            : rank == 2
                ? Colors.orange.shade200
                : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${rank + 1}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
