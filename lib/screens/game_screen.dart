import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ludo_state.dart';
import '../models/settings.dart';
import '../models/token.dart';
import '../widgets/ludo_board.dart';
import '../widgets/dice_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LudoState>(context);
    final settings = Provider.of<GameSettings>(context);
    final isDark = settings.theme == LudoTheme.dark;

    Color bg = isDark ? const Color(0xff121212) : const Color(0xfff0f2f5);
    Color cardColor = isDark ? const Color(0xff1e1e1e) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Ludo Offline',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              // Reset Game Dialog
              _showResetDialog(context, state);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isTablet = constraints.maxWidth > 600;

                if (isTablet) {
                  // Tablet Horizontal Layout
                  return Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: const LudoBoardWidget(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPlayersPanel(state, cardColor, textColor),
                              const SizedBox(height: 30),
                              _buildDiceControlPanel(state, textColor),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                } else {
                  // Mobile Portrait Layout
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: _buildPlayersPanel(state, cardColor, textColor),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: const LudoBoardWidget(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                        child: _buildDiceControlPanel(state, textColor),
                      )
                    ],
                  );
                }
              },
            ),
          ),
          
          // Victory Win Celebration Overlay
          if (state.hasWinner && state.winner != null)
            _buildVictoryOverlay(context, state, bg, textColor),
        ],
      ),
    );
  }

  Widget _buildPlayersPanel(LudoState state, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Players & Turn Indicator',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: state.activePlayers.map((playerColor) {
              bool isCurrent = state.currentPlayer == playerColor;
              bool isAi = state.computerPlayers.contains(playerColor);

              Color color;
              String name;
              switch (playerColor) {
                case LudoColor.red:
                  color = const Color(0xffe53935);
                  name = 'Red';
                  break;
                case LudoColor.green:
                  color = const Color(0xff43a047);
                  name = 'Green';
                  break;
                case LudoColor.yellow:
                  color = const Color(0xfffdd835);
                  name = 'Yellow';
                  break;
                case LudoColor.blue:
                  color = const Color(0xff1e88e5);
                  name = 'Blue';
                  break;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color,
                      child: isAi
                          ? const Icon(Icons.computer_rounded, size: 14, color: Colors.white)
                          : const Icon(Icons.person_rounded, size: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceControlPanel(LudoState state, Color textColor) {
    Color color;
    String name;
    switch (state.currentPlayer) {
      case LudoColor.red:
        color = const Color(0xffe53935);
        name = 'Red';
        break;
      case LudoColor.green:
        color = const Color(0xff43a047);
        name = 'Green';
        break;
      case LudoColor.yellow:
        color = const Color(0xfffdd835);
        name = 'Yellow';
        break;
      case LudoColor.blue:
        color = const Color(0xff1e88e5);
        name = 'Blue';
        break;
    }

    bool isAi = state.isCurrentPlayerComputer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAi ? "$name AI is rolling..." : "$name's Turn: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            if (!isAi)
              const Text(
                "Tap Dice",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DiceWidget(),
            const SizedBox(width: 20),
            // Show dice numeric helper/indicator
            if (state.isDiceRolled && !state.isMoving)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Rolled a ${state.diceValue}!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVictoryOverlay(
    BuildContext context,
    LudoState state,
    Color bg,
    Color textColor,
  ) {
    String winnerName = state.winner.toString().split('.').last.toUpperCase();
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$winnerName Player Wins!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      state.setupGame(state.mode);
                    },
                    child: const Text('Play Again'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Main Menu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, LudoState state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restart Game?'),
          content: const Text('Are you sure you want to restart the current game? All progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                state.setupGame(state.mode, computerOpponents: state.aiOpponentsCount);
                Navigator.pop(context);
              },
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );
  }
}
