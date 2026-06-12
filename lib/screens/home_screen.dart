import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import '../models/ludo_state.dart';
import '../models/settings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LudoState>(context, listen: false);
    final settings = Provider.of<GameSettings>(context);
    final isDark = settings.theme == LudoTheme.dark;

    Color startBg = isDark ? const Color(0xff1a1a2e) : const Color(0xfff3f4f6);
    Color cardColor = isDark ? const Color(0xff16213e) : Colors.white;
    Color titleColor = isDark ? Colors.tealAccent : const Color(0xff1e88e5);

    return Scaffold(
      backgroundColor: startBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double paddingVal = constraints.maxWidth > 600 ? 64.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: paddingVal, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Title Header Logo Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: titleColor.withOpacity(0.15),
                        ),
                        child: Icon(
                          Icons.grid_on_rounded,
                          size: 90,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'LUDO OFFLINE',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'Classic Dice Board Game',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey : Colors.grey.shade600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Game Selection Cards
                      _gameModeCard(
                        context,
                        title: 'Play VS Computer',
                        subtitle: 'Single Player vs 1-3 AI Opponents',
                        icon: Icons.computer_rounded,
                        color: Colors.purple.shade400,
                        cardBg: cardColor,
                        isDark: isDark,
                        onTap: () => _showAiOpponentSelection(context, state),
                      ),
                      const SizedBox(height: 16),
                      _gameModeCard(
                        context,
                        title: '2 Players Mode',
                        subtitle: 'Local game for 2 human players',
                        icon: Icons.people_outline_rounded,
                        color: Colors.green.shade400,
                        cardBg: cardColor,
                        isDark: isDark,
                        onTap: () {
                          state.setupGame(GameMode.twoPlayer);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _gameModeCard(
                        context,
                        title: '3 Players Mode',
                        subtitle: 'Local game for 3 human players',
                        icon: Icons.people_rounded,
                        color: Colors.orange.shade400,
                        cardBg: cardColor,
                        isDark: isDark,
                        onTap: () {
                          state.setupGame(GameMode.threePlayer);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _gameModeCard(
                        context,
                        title: '4 Players Mode',
                        subtitle: 'Local game for 4 human players',
                        icon: Icons.groups_rounded,
                        color: Colors.blue.shade400,
                        cardBg: cardColor,
                        isDark: isDark,
                        onTap: () {
                          state.setupGame(GameMode.fourPlayer);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // Configuration Option Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                            icon: const Icon(Icons.settings_rounded),
                            label: const Text('Settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAiOpponentSelection(BuildContext context, LudoState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select AI Opponents',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3].map((count) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () {
                      state.setupGame(GameMode.vsAi, computerOpponents: count);
                      Navigator.pop(context); // Close sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
                    },
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gameModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
