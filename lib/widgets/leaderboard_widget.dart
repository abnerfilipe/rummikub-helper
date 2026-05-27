import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final totals = game.computeTotals();
        final players = game.game.players;
        if (players.isEmpty) return const SizedBox.shrink();

        final ranked = List.generate(players.length, (i) => i)
          ..sort((a, b) => totals[b].compareTo(totals[a]));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.leaderboard,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Placar',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Mini podium when collapsed
                      if (!_expanded) _buildMiniPodium(context, ranked, totals),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    children: ranked.asMap().entries.map((e) {
                      final rank = e.key;
                      final pIdx = e.value;
                      final score = totals[pIdx];
                      return _buildRankRow(
                          context, rank, players[pIdx], score);
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPodium(
      BuildContext context, List<int> ranked, List<int> totals) {
    final top = ranked.take(3).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: top.asMap().entries.map((e) {
        final rank = e.key;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: _RankBadge(rank: rank),
        );
      }).toList(),
    );
  }

  Widget _buildRankRow(
      BuildContext context, int rank, String name, int score) {
    final isFirst = rank == 0;
    final scoreStr = score > 0 ? '+$score' : '$score';
    final scoreColor = score > 0
        ? Colors.green.shade700
        : score < 0
            ? Colors.red.shade700
            : Theme.of(context).colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isFirst ? FontWeight.bold : FontWeight.normal,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            scoreStr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
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
