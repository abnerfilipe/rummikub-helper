import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

Future<bool?> showWinnerDialog(
  BuildContext context, {
  required int rIdx,
  required int pIdx,
  required int calculatedScore,
}) {
  final game = context.read<GameProvider>();
  final playerName = game.game.players[pIdx];

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
      title: const Text(
        'Vencedor da Rodada',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerName,
            style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pontuação calculada: $calculatedScore',
            style: Theme.of(ctx).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '(negativo da soma dos outros jogadores)',
            style: Theme.of(ctx).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Confirmar e Concluir'),
        ),
      ],
    ),
  );
}
