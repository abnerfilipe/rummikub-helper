import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/timer_provider.dart';

void showTimerSettingsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<GameProvider>()),
        ChangeNotifierProvider.value(value: context.read<TimerProvider>()),
      ],
      child: const _TimerSettingsDialog(),
    ),
  );
}

class _TimerSettingsDialog extends StatefulWidget {
  const _TimerSettingsDialog();
  @override
  State<_TimerSettingsDialog> createState() => _TimerSettingsDialogState();
}

class _TimerSettingsDialogState extends State<_TimerSettingsDialog> {
  late String _rule;
  late bool _sound;
  late bool _autoRotate;
  late bool _confirmExpiry;
  late TextEditingController _customMinutes;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameProvider>();
    _rule = game.game.timeRule;
    _sound = game.timerConfig.soundEnabled;
    _autoRotate = game.game.turnAutoRotate;
    _confirmExpiry = game.game.confirmExpiry;
    final mins = (game.timerConfig.durationSeconds / 60).round();
    _customMinutes = TextEditingController(text: '$mins');
  }

  @override
  void dispose() {
    _customMinutes.dispose();
    super.dispose();
  }

  int _getSeconds() {
    switch (_rule) {
      case 'official':
        return 60;
      case 'alternative':
        return 120;
      case 'impatient':
        return 30;
      default:
        return (int.tryParse(_customMinutes.text) ?? 2) * 60;
    }
  }

  void _save() {
    final seconds = _getSeconds();
    if (seconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tempo inválido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<GameProvider>().saveTimerSettings(
          seconds: seconds,
          sound: _sound,
          rule: _rule,
          autoRotate: _autoRotate,
          confirmExpiry: _confirmExpiry,
        );
    context.read<TimerProvider>().reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurações do Temporizador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Regra de tempo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            ...[
              ('official', 'Oficial', '1 min — penalidade: 3 peças'),
              ('alternative', 'Alternativa', '2 min — penalidade: 1 peça'),
              ('impatient', 'Variação (impatiente)', '30 s — penalidade: 1 peça'),
              ('custom', 'Personalizado', 'Defina o tempo abaixo'),
            ].map(
              (r) => RadioListTile<String>(
                dense: true,
                title: Text(r.$2),
                subtitle: Text(r.$3,
                    style: Theme.of(context).textTheme.bodySmall),
                value: r.$1,
                groupValue: _rule,
                onChanged: (v) => setState(() => _rule = v!),
              ),
            ),
            if (_rule == 'custom') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customMinutes,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Minutos (1–59)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const Divider(height: 24),
            SwitchListTile(
              dense: true,
              title: const Text('Som / Vibração'),
              value: _sound,
              onChanged: (v) => setState(() => _sound = v),
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Rotação automática'),
              subtitle: const Text(
                  'Avança para o próximo jogador ao estourar o tempo'),
              value: _autoRotate,
              onChanged: (v) => setState(() => _autoRotate = v),
            ),
            SwitchListTile(
              dense: true,
              title: const Text('Confirmar ao expirar'),
              subtitle: const Text('Pede confirmação antes de aplicar penalidade'),
              value: _confirmExpiry,
              onChanged: (v) => setState(() => _confirmExpiry = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
