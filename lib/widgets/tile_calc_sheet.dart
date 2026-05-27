import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

Future<void> showTileCalcSheet(
  BuildContext context, {
  required int rIdx,
  required int pIdx,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<GameProvider>(),
      child: _TileCalcSheet(rIdx: rIdx, pIdx: pIdx),
    ),
  );
}

class _TileCalcSheet extends StatefulWidget {
  final int rIdx;
  final int pIdx;
  const _TileCalcSheet({required this.rIdx, required this.pIdx});

  @override
  State<_TileCalcSheet> createState() => _TileCalcSheetState();
}

class _TileCalcSheetState extends State<_TileCalcSheet> {
  late List<int> _counts;
  bool _isWinner = false;

  // Tile values: indices 0-12 → values 1-13, index 13 → joker = 30
  static const _tileValues = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 30
  ];

  @override
  void initState() {
    super.initState();
    final game = context.read<GameProvider>();
    final key = '${widget.rIdx}-${widget.pIdx}';
    final saved = game.game.tileDetails[key];
    _counts = (saved != null && saved.length == 14)
        ? List<int>.from(saved)
        : List<int>.filled(14, 0);
    _isWinner =
        game.game.roundWinners[widget.rIdx] == widget.pIdx;
  }

  int get _total {
    int s = 0;
    for (int i = 0; i < _counts.length; i++) {
      s += _counts[i] * _tileValues[i];
    }
    return -s;
  }

  void _apply() {
    final game = context.read<GameProvider>();
    if (_isWinner) {
      game.setRoundWinner(widget.rIdx, widget.pIdx);
    } else {
      // Remove winner flag if this player was the winner
      if (game.game.roundWinners[widget.rIdx] == widget.pIdx) {
        game.clearRoundWinner(widget.rIdx);
      }
      game.applyScore(
        widget.rIdx,
        widget.pIdx,
        _total.toString(),
        tileCounts: _counts,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final playerName = game.game.players[widget.pIdx];
    final totalStr = _isWinner
        ? 'Auto'
        : (_total > 0 ? '+$_total' : '$_total');
    final totalColor = _isWinner
        ? Colors.amber.shade800
        : _total < 0
            ? Colors.red.shade700
            : _total > 0
                ? Colors.green.shade700
                : Colors.grey;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rodada ${widget.rIdx + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          playerName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Winner toggle button
                  FilterChip(
                    label: const Text('Vencedor'),
                    avatar: Icon(
                      Icons.emoji_events,
                      color: _isWinner ? Colors.amber : null,
                    ),
                    selected: _isWinner,
                    onSelected: (v) => setState(() => _isWinner = v),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tile grid (hidden when winner)
            if (!_isWinner)
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: 14,
                  itemBuilder: (_, i) => _TileCard(
                    index: i,
                    count: _counts[i],
                    onInc: () => setState(() {
                      _counts[i] = (_counts[i] + 1).clamp(0, 99);
                    }),
                    onDec: () => setState(() {
                      _counts[i] = (_counts[i] - 1).clamp(0, 99);
                    }),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events,
                          size: 64, color: Colors.amber),
                      const SizedBox(height: 12),
                      Text(
                        'Vencedor!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A pontuação será calculada automaticamente\na partir dos outros jogadores.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Total display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        totalStr,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: totalColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TileCard extends StatelessWidget {
  final int index;
  final int count;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _TileCard({
    required this.index,
    required this.count,
    required this.onInc,
    required this.onDec,
  });

  static const _tileValues = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 30
  ];

  @override
  Widget build(BuildContext context) {
    final isJoker = index == 13;
    final value = _tileValues[index];
    final label = isJoker ? 'J' : '${index + 1}';
    final pts = '$value pt${value == 1 ? '' : 's'}';
    final hasCount = count > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCount
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: hasCount ? 1.5 : 1,
        ),
        color: hasCount
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          // Tile label
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasCount
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasCount
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!isJoker)
                  Text(
                    pts,
                    style: TextStyle(
                      fontSize: 7,
                      color: hasCount
                          ? Colors.white70
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Controls
          Expanded(
            child: Row(
              children: [
                _CountBtn(
                  icon: Icons.remove,
                  onTap: count > 0 ? onDec : null,
                ),
                Expanded(
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasCount
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                _CountBtn(icon: Icons.add, onTap: onInc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null
              ? Theme.of(context).colorScheme.surfaceVariant
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16,
            color: onTap != null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Colors.grey.shade300),
      ),
    );
  }
}
