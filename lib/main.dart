import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/ludo_state.dart';
import 'models/settings.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameSettings()),
        ChangeNotifierProvider(create: (_) => LudoState()),
      ],
      child: const LudoApp(),
    ),
  );
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<GameSettings>(context);

    // Dynamic Theme Mode Styling
    ThemeData appTheme;
    if (settings.theme == LudoTheme.dark) {
      appTheme = ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      );
    } else if (settings.theme == LudoTheme.modern) {
      appTheme = ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.pink,
        ),
      );
    } else {
      // Classic theme design
      appTheme = ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
      );
    }

    return MaterialApp(
      title: 'Ludo Offline',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
