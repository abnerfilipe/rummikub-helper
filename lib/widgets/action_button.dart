import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'dialogs/confirm_dialog.dart';
import 'dialogs/winner_dialog.dart';
import 'dialogs/game_over_dialog.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (game.game.players.isEmpty) return const SizedBox.shrink();

        final label = _getLabel(game);
        final color = _getColor(context, game);
        final icon = _getIcon(game);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _handleAction(context, game),
                style: FilledButton.styleFrom(backgroundColor: color),
                icon: Icon(icon),
                label: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLabel(GameProvider game) {
    if (!game.isGameStarted) return 'Iniciar Rodada';
    if (game.game.editingIdx != null) return 'Salvar Alterações';
    if (game.isGameFinished) return 'Jogo Finalizado';
    return 'Concluir Rodada';
  }

  Color _getColor(BuildContext context, GameProvider game) {
    if (!game.isGameStarted) return Theme.of(context).colorScheme.primary;
    if (game.game.editingIdx != null) return Colors.grey.shade800;
    if (game.isGameFinished) return Colors.green.shade700;
    return Colors.grey.shade900;
  }

  IconData _getIcon(GameProvider game) {
    if (!game.isGameStarted) return Icons.play_arrow;
    if (game.game.editingIdx != null) return Icons.save;
    if (game.isGameFinished) return Icons.emoji_events;
    return Icons.check_circle_outline;
  }

  Future<void> _handleAction(BuildContext context, GameProvider game) async {
    if (!game.isGameStarted) {
      await _startGame(context, game);
      return;
    }

    if (game.isGameFinished && game.game.editingIdx == null) {
      showGameOverDialog(context);
      return;
    }

    await _finishOrSave(context, game);
  }

  Future<void> _startGame(BuildContext context, GameProvider game) async {
    if (game.playerCount < game.minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Adicione pelo menos ${game.minPlayers} jogadores para iniciar.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      'Iniciar a 1ª Rodada?',
      'Ao iniciar, não será mais possível adicionar participantes.',
    );
    if (confirmed == true && context.mounted) {
      game.startGame();
    }
  }

  Future<void> _finishOrSave(BuildContext context, GameProvider game) async {
    final rIdx = game.activeRoundIdx;
    if (rIdx >= game.game.rounds.length) return;

    final round = game.game.rounds[rIdx];
    final emptyIndices = <int>[];
    int sum = 0;

    for (int i = 0; i < round.length; i++) {
      final val = round[i];
      if (val.isEmpty) {
        emptyIndices.add(i);
      } else {
        final n = int.tryParse(val);
        if (n == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Valores inválidos na rodada.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        sum += n;
      }
    }

    // Auto-calculate winner score when exactly one cell is empty
    if (emptyIndices.length == 1) {
      final winnerPIdx = emptyIndices.first;
      final winnerScore = -sum;
      final confirmed = await showWinnerDialog(
        context,
        rIdx: rIdx,
        pIdx: winnerPIdx,
        calculatedScore: winnerScore,
      );
      if (confirmed == true && context.mounted) {
        game.applyScore(rIdx, winnerPIdx, winnerScore.toString());
        game.setRoundWinner(rIdx, winnerPIdx);
        final wasFinished = game.isGameFinished;
        game.finishRound(rIdx);
        if (!wasFinished && game.isGameFinished && context.mounted) {
          showGameOverDialog(context);
        }
      }
      return;
    }

    if (emptyIndices.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${emptyIndices.length} células vazias. Preencha os perdedores.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // All cells filled — validate sum = 0
    if (sum != 0) {
      final diff = sum > 0 ? '+$sum' : '$sum';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'A soma deve ser zero. Diferença: $diff'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final actionLabel = game.game.editingIdx != null
        ? 'Salvar Alterações?'
        : 'Concluir Rodada?';
    final confirmed = await showConfirmDialog(
      context,
      actionLabel,
      'A soma está correta (0). Confirmar?',
    );
    if (confirmed == true && context.mounted) {
      final wasFinished = game.isGameFinished;
      game.finishRound(rIdx);
      if (!wasFinished && game.isGameFinished && context.mounted) {
        showGameOverDialog(context);
      }
    }
  }
}
