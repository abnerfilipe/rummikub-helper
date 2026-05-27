import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/dialogs/error_dialog.dart';

class PlayersTab extends StatefulWidget {
  const PlayersTab({super.key});

  @override
  State<PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  final _addController = TextEditingController();
  int? _editingIndex;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final players = game.game.players;
        final isLocked = game.game.locked;
        final isFinished = game.isGameFinished;

        return Column(
          children: [
            // Status banner
            if (isFinished)
              _buildBanner(context, 'Jogo finalizado', Colors.green)
            else if (isLocked)
              _buildBanner(context, 'Partida em andamento', Colors.orange),

            // Add player section
            if (!isLocked)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do jogador',
                          hintText: 'Digite o nome...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add),
                        ),
                        maxLength: 20,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _addPlayer(context, game),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: players.length >= game.maxPlayers
                          ? null
                          : () => _addPlayer(context, game),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),

            // Players list
            Expanded(
              child: players.isEmpty
                  ? _buildEmptyList(context)
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, idx) =>
                          _buildPlayerTile(context, game, idx, isLocked),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: color.withOpacity(0.15),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyList(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 60,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Nenhum jogador ainda.\nAdicione de 2 a 6 jogadores.',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(
    BuildContext context,
    GameProvider game,
    int idx,
    bool isLocked,
  ) {
    final players = game.game.players;
    final isEditing = _editingIndex == idx;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text('${idx + 1}'),
        ),
        title: isEditing
            ? TextField(
                controller: _editController,
                autofocus: true,
                maxLength: 20,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
                onSubmitted: (_) => _saveRename(context, game, idx),
              )
            : Text(
                players[idx],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
        trailing: isLocked
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing) ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Salvar',
                      onPressed: () => _saveRename(context, game, idx),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Cancelar',
                      onPressed: () => setState(() => _editingIndex = null),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      tooltip: 'Mover para cima',
                      onPressed: idx == 0
                          ? null
                          : () => game.movePlayer(idx, idx - 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      tooltip: 'Mover para baixo',
                      onPressed: idx == players.length - 1
                          ? null
                          : () => game.movePlayer(idx, idx + 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Editar nome',
                      onPressed: () {
                        _editController.text = players[idx];
                        setState(() => _editingIndex = idx);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      tooltip: 'Remover',
                      onPressed: players.length <= game.minPlayers
                          ? null
                          : () => _removePlayer(context, game, idx),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  void _addPlayer(BuildContext context, GameProvider game) {
    final name = _addController.text.trim();
    final error = game.addPlayer(name);
    if (error != null) {
      showErrorSnackBar(context, error);
    } else {
      _addController.clear();
    }
  }

  void _saveRename(BuildContext context, GameProvider game, int idx) {
    final error = game.renamePlayer(idx, _editController.text);
    if (error != null) {
      showErrorSnackBar(context, error);
    } else {
      setState(() => _editingIndex = null);
    }
  }

  void _removePlayer(BuildContext context, GameProvider game, int idx) {
    final error = game.removePlayer(idx);
    if (error != null) {
      showErrorSnackBar(context, error);
    }
  }
}
