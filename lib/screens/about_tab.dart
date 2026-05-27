import 'package:flutter/material.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.casino,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Rummikub Helper',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versão 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(
            context,
            icon: Icons.info_outline,
            title: 'Sobre o App',
            content:
                'Rummikub Helper é um aplicativo para acompanhar as pontuações '
                'durante partidas de Rummikub. Controle até 6 jogadores, '
                'acompanhe o tempo de cada turno e registre as pontuações '
                'de forma fácil e rápida.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.code,
            title: 'Tecnologia',
            content:
                'Desenvolvido com Flutter, utilizando Material Design 3.\n'
                'Persistência de dados via SharedPreferences.\n'
                'Gerenciamento de estado com Provider.',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.link,
            title: 'Código Fonte',
            content: 'github.com/abnerfilipe/rummikub-helper',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.gavel,
            title: 'Licença',
            content: 'MIT License\n© 2025 Abner Filipe',
          ),
          const SizedBox(height: 32),
          Text(
            'Feito com ❤ para os fãs de Rummikub',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
