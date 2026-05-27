import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameProvider = GameProvider();
  await gameProvider.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameProvider),
        ChangeNotifierProxyProvider<GameProvider, TimerProvider>(
          create: (ctx) => TimerProvider(gameProvider),
          update: (ctx, game, prev) => prev!..syncGame(game),
        ),
      ],
      child: const RummikubApp(),
    ),
  );
}

class RummikubApp extends StatelessWidget {
  const RummikubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rummikub Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEA580C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
