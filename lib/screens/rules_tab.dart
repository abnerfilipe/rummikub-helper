import 'package:flutter/material.dart';

class RulesTab extends StatelessWidget {
  const RulesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            'Objetivo do Jogo',
            'Ser o primeiro jogador a colocar todas as suas pedras na mesa. '
                'O jogo termina quando um jogador fica sem pedras. '
                'Os outros jogadores somam o valor das pedras que restaram em suas mãos, '
                'e esses pontos são negativos para eles.',
          ),
          _buildSection(
            context,
            'Componentes',
            '• 106 pedras numeradas de 1 a 13 em 4 cores (preto, vermelho, laranja, azul)\n'
                '• 2 curingas (Jokers)\n'
                '• Suportes para as pedras',
          ),
          _buildSection(
            context,
            'Configuração',
            '1. Misture todas as pedras com a face voltada para baixo.\n'
                '2. Cada jogador pega 14 pedras.\n'
                '3. Escolha quem começa (pode ser o mais velho ou por sorteio).',
          ),
          _buildSection(
            context,
            'Abertura (Entrada Inicial)',
            'Para a primeira jogada, cada jogador deve colocar pedras cuja soma '
                'seja de pelo menos 30 pontos, usando apenas pedras da sua mão. '
                'Até fazer a abertura, o jogador não pode usar pedras já na mesa.',
          ),
          _buildSection(
            context,
            'Tipos de Grupos',
            '• Sequência: 3 ou mais pedras consecutivas da mesma cor (ex: 5, 6, 7 vermelho)\n'
                '• Grupo: 3 ou 4 pedras com o mesmo número mas cores diferentes\n'
                '• O curinga (Joker) substitui qualquer pedra',
          ),
          _buildSection(
            context,
            'Pontuação',
            '• O vencedor de cada rodada recebe o negativo da soma dos pontos dos adversários\n'
                '• Os perdedores somam o valor das pedras restantes em suas mãos (negativo)\n'
                '• Curingas valem 30 pontos\n'
                '• A soma de cada rodada é sempre zero\n'
                '• Ganha quem tiver a maior pontuação (ou menor negativo) ao final',
          ),
          _buildSection(
            context,
            'Regras do Temporizador',
            '• Oficial: 1 minuto por turno — penalidade de 3 pedras ao estourar\n'
                '• Alternativa: 2 minutos por turno — penalidade de 1 pedra\n'
                '• Impatiente: 30 segundos por turno — penalidade de 1 pedra\n'
                '• Personalizado: tempo definido pelo jogador',
          ),
          _buildSection(
            context,
            'Penalidades',
            'Ao estourar o tempo, o jogador deve comprar pedras do monte '
                'como penalidade (quantidade definida pela regra de tempo escolhida). '
                'Essas pedras adicionam pontos negativos ao final da rodada.',
          ),
          _buildSection(
            context,
            'Uso do App',
            '1. Adicione os jogadores na aba "Jogadores"\n'
                '2. Na aba "Jogo", toque em "Iniciar Rodada"\n'
                '3. Use o modal de contagem de peças para registrar pontos\n'
                '4. O vencedor tem sua pontuação calculada automaticamente\n'
                '5. Toque em "Concluir Rodada" para avançar\n'
                '6. Edite rodadas passadas tocando no ícone de lápis',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
