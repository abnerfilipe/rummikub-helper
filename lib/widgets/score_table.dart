import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'tile_calc_sheet.dart';
import 'dialogs/confirm_dialog.dart';

class ScoreTable extends StatelessWidget {
  const ScoreTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final players = game.game.players;
        final rounds = game.game.rounds;
        if (players.isEmpty || rounds.isEmpty) {
          return const Center(child: Text('Nenhuma rodada iniciada.'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(context, game),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, GameProvider game) {
    final players = game.game.players;
    final rounds = game.game.rounds;
    final totals = game.computeTotals();

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        Theme.of(context).colorScheme.surfaceVariant,
      ),
      dataRowMinHeight: 52,
      dataRowMaxHeight: 52,
      columnSpacing: 0,
      horizontalMargin: 0,
      columns: [
        const DataColumn(
          label: SizedBox(
            width: 56,
            child: Center(
              child: Text('Rdda',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ),
        ...players.map((p) => DataColumn(
              label: SizedBox(
                width: 90,
                child: Center(
                  child: Text(
                    p,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )),
      ],
      rows: [
        ...rounds.asMap().entries.map((e) {
          final rIdx = e.key;
          final round = e.value;
          final isEditing = game.game.editingIdx == rIdx;
          final isCurrent = game.game.currIdx == rIdx &&
              game.game.editingIdx == null;
          final isPast =
              rIdx < game.game.currIdx && game.game.editingIdx == null;
          final isEditable = isEditing || isCurrent;

          Color? rowColor;
          if (isEditing) {
            rowColor = Colors.orange.shade50;
          } else if (isCurrent) {
            rowColor = Colors.blue.shade50;
          } else if (isPast) {
            rowColor = null;
          } else {
            rowColor = Colors.grey.shade50;
          }

          return DataRow(
            color: WidgetStateProperty.all(rowColor),
            cells: [
              // Round number cell
              DataCell(
                SizedBox(
                  width: 56,
                  child: Center(
                    child: isEditing
                        ? Text('Edit',
                            style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))
                        : isCurrent
                            ? Text('${rIdx + 1}',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.bold))
                            : isPast && game.game.editingIdx == null
                                ? InkWell(
                                    onTap: () =>
                                        _enableEdit(context, game, rIdx),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('${rIdx + 1}',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12)),
                                        Icon(Icons.edit,
                                            size: 12,
                                            color: Colors.grey.shade400),
                                      ],
                                    ),
                                  )
                                : Text('${rIdx + 1}',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12)),
                  ),
                ),
              ),
              // Score cells
              ...round.asMap().entries.map((pe) {
                final pIdx = pe.key;
                final val = pe.value;
                final score = int.tryParse(val);
                final isWinner =
                    game.game.roundWinners[rIdx] == pIdx;

                Color textColor;
                if (score != null) {
                  if (score > 0) {
                    textColor = Colors.green.shade700;
                  } else if (score < 0) {
                    textColor = Colors.red.shade700;
                  } else if (isWinner) {
                    textColor = Colors.green.shade700;
                  } else {
                    textColor = Colors.grey.shade400;
                  }
                } else {
                  textColor = Colors.grey.shade300;
                }

                return DataCell(
                  InkWell(
                    onTap: isEditable
                        ? () => showTileCalcSheet(context,
                            rIdx: rIdx, pIdx: pIdx)
                        : null,
                    child: SizedBox(
                      width: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isWinner)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Icon(Icons.emoji_events,
                                  size: 12, color: Colors.amber.shade600),
                            ),
                          Text(
                            val.isEmpty ? '—' : val,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: val.isEmpty
                                  ? Colors.grey.shade200
                                  : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
        // Totals row
        DataRow(
          color: WidgetStateProperty.all(
            Theme.of(context).colorScheme.inverseSurface,
          ),
          cells: [
            DataCell(
              SizedBox(
                width: 56,
                child: Center(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
            ...totals.map((s) {
              final color = s > 0
                  ? Colors.green.shade300
                  : s < 0
                      ? Colors.red.shade300
                      : Colors.grey.shade400;
              return DataCell(
                SizedBox(
                  width: 90,
                  child: Center(
                    child: Text(
                      s > 0 ? '+$s' : '$s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Future<void> _enableEdit(
      BuildContext context, GameProvider game, int rIdx) async {
    final confirmed = await showConfirmDialog(
      context,
      'Editar rodada ${rIdx + 1}?',
      'A rodada atual será temporariamente bloqueada.',
    );
    if (confirmed == true) {
      game.enableEdit(rIdx);
    }
  }
}
