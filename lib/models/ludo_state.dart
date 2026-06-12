import 'dart:math';
import 'package:flutter/foundation.dart';
import 'token.dart';
import 'settings.dart';
import '../services/ai_engine.dart';

enum GameMode { vsAi, twoPlayer, threePlayer, fourPlayer }

class LudoState extends ChangeNotifier {
  // Configurable rules
  bool captureGrantsExtraTurn = true;
  bool homeEntryGrantsExtraTurn = true;
  bool blocksEnabled = true;

  // Game configuration
  GameMode mode = GameMode.vsAi;
  int aiOpponentsCount = 3; // 1, 2, or 3 for vs AI
  AiDifficulty difficulty = AiDifficulty.medium;

  // Board layout
  static const List<Point<int>> globalPath = [
    Point(6, 1), Point(6, 2), Point(6, 3), Point(6, 4), Point(6, 5), // Red path segment
    Point(5, 6), Point(4, 6), Point(3, 6), Point(2, 6), Point(1, 6), Point(0, 6),
    Point(0, 7), // Green start region
    Point(0, 8), Point(1, 8), Point(2, 8), Point(3, 8), Point(4, 8), Point(5, 8),
    Point(6, 9), Point(6, 10), Point(6, 11), Point(6, 12), Point(6, 13), Point(6, 14),
    Point(7, 14), // Yellow start region
    Point(8, 14), Point(8, 13), Point(8, 12), Point(8, 11), Point(8, 10), Point(8, 9),
    Point(9, 8), Point(10, 8), Point(11, 8), Point(12, 8), Point(13, 8), Point(14, 8),
    Point(14, 7), // Blue start region
    Point(14, 6), Point(13, 6), Point(12, 6), Point(11, 6), Point(10, 6), Point(9, 6),
    Point(8, 5), Point(8, 4), Point(8, 3), Point(8, 2), Point(8, 1), Point(8, 0),
    Point(7, 0), // Red home entry corner
    Point(6, 0),
  ];

  static const List<int> safeCellIndices = [0, 8, 13, 21, 26, 34, 39, 47]; // Safe zones on path

  // Map starting index of each color on globalPath
  static final Map<LudoColor, int> _startOffset = {
    LudoColor.red: 0,
    LudoColor.green: 13,
    LudoColor.yellow: 26,
    LudoColor.blue: 39,
  };

  // State values
  final Map<LudoColor, List<LudoToken>> playerTokens = {
    LudoColor.red: List.generate(4, (i) => LudoToken(color: LudoColor.red, id: i)),
    LudoColor.green: List.generate(4, (i) => LudoToken(color: LudoColor.green, id: i)),
    LudoColor.yellow: List.generate(4, (i) => LudoToken(color: LudoColor.yellow, id: i)),
    LudoColor.blue: List.generate(4, (i) => LudoToken(color: LudoColor.blue, id: i)),
  };

  final List<LudoColor> activePlayers = [];
  int currentPlayerIndex = 0;
  
  int diceValue = 1;
  bool isDiceRolled = false;
  bool isMoving = false;
  int consecutiveSixes = 0;
  bool hasWinner = false;
  LudoColor? winner;

  // Controls when players are AI
  final Set<LudoColor> computerPlayers = {};

  // Track event logs to play sounds in the UI
  String lastGameEvent = '';

  void setupGame(GameMode selectedMode, {int computerOpponents = 3}) {
    mode = selectedMode;
    aiOpponentsCount = computerOpponents;
    activePlayers.clear();
    computerPlayers.clear();
    hasWinner = false;
    winner = null;
    diceValue = 1;
    isDiceRolled = false;
    isMoving = false;
    consecutiveSixes = 0;

    // Standard Setup
    activePlayers.addAll([LudoColor.red, LudoColor.green, LudoColor.yellow, LudoColor.blue]);

    if (mode == GameMode.vsAi) {
      // Human plays Red, rest are computer
      if (computerOpponents >= 1) computerPlayers.add(LudoColor.yellow);
      if (computerOpponents >= 2) computerPlayers.add(LudoColor.green);
      if (computerOpponents >= 3) computerPlayers.add(LudoColor.blue);
    } else if (mode == GameMode.twoPlayer) {
      // 2 Human players (Red and Yellow)
      activePlayers.remove(LudoColor.green);
      activePlayers.remove(LudoColor.blue);
    } else if (mode == GameMode.threePlayer) {
      // 3 Human players (Red, Green, Yellow)
      activePlayers.remove(LudoColor.blue);
    }

    // Reset tokens
    for (var tokens in playerTokens.values) {
      for (var token in tokens) {
        token.reset();
      }
    }

    currentPlayerIndex = 0;
    notifyListeners();
  }

  LudoColor get currentPlayer => activePlayers[currentPlayerIndex];
  bool get isCurrentPlayerComputer => computerPlayers.contains(currentPlayer);

  // Return all tokens on the board
  List<LudoToken> get allTokens {
    List<LudoToken> list = [];
    for (var tokens in playerTokens.values) {
      list.addAll(tokens);
    }
    return list;
  }

  // Get coordinates for custom painter
  Point<int> getTokenGridPosition(LudoToken token) {
    if (token.isInBase) {
      return _getBaseCoordinate(token.color, token.id);
    }
    if (token.isAtHome) {
      return _getHomeCenterCoordinate(token.color);
    }

    // Home path coordinates (52 to 56)
    if (token.position >= 52) {
      int homeIndex = token.position - 52;
      return _getHomePathCoordinate(token.color, homeIndex);
    }

    // Main path coordinates (1 to 51)
    int globalIndex = (token.position - 1 + _startOffset[token.color]!) % 52;
    return globalPath[globalIndex];
  }

  int getGlobalCoordinateOfToken(LudoToken token, int relativePosition) {
    if (relativePosition <= 0 || relativePosition >= 52) return -1;
    return (relativePosition - 1 + _startOffset[token.color]!) % 52;
  }

  Point<int> _getBaseCoordinate(LudoColor color, int id) {
    int dx = (id % 2 == 0) ? 1.5.round() : 3.5.round();
    int dy = (id < 2) ? 1.5.round() : 3.5.round();
    switch (color) {
      case LudoColor.red:
        return Point(dy + 1, dx + 1);
      case LudoColor.green:
        return Point(dy + 1, dx + 10);
      case LudoColor.yellow:
        return Point(dy + 10, dx + 10);
      case LudoColor.blue:
        return Point(dy + 10, dx + 1);
    }
  }

  Point<int> _getHomePathCoordinate(LudoColor color, int index) {
    switch (color) {
      case LudoColor.red:
        return Point(7, index + 1);
      case LudoColor.green:
        return Point(index + 1, 7);
      case LudoColor.yellow:
        return Point(7, 13 - index);
      case LudoColor.blue:
        return Point(13 - index, 7);
    }
  }

  Point<int> _getHomeCenterCoordinate(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return const Point(7, 6);
      case LudoColor.green:
        return const Point(6, 7);
      case LudoColor.yellow:
        return const Point(7, 8);
      case LudoColor.blue:
        return const Point(8, 7);
    }
  }

  void rollDice() {
    if (isDiceRolled || isMoving || hasWinner) return;

    final random = Random();
    diceValue = random.nextInt(6) + 1;
    isDiceRolled = true;
    lastGameEvent = 'roll';
    notifyListeners();

    if (diceValue == 6) {
      consecutiveSixes++;
      if (consecutiveSixes == 3) {
        consecutiveSixes = 0;
        isDiceRolled = false;
        lastGameEvent = 'three_sixes';
        _nextTurn();
        return;
      }
    } else {
      consecutiveSixes = 0;
    }

    // Check if the current player has any valid moves
    List<LudoToken> tokens = playerTokens[currentPlayer]!;
    bool hasValidMove = false;
    for (var token in tokens) {
      if (LudoAiEngine.canMoveToken(token, diceValue)) {
        hasValidMove = true;
        break;
      }
    }

    if (!hasValidMove) {
      // Automatically skip to next player if no moves
      Future.delayed(const Duration(milliseconds: 1000), () {
        isDiceRolled = false;
        _nextTurn();
      });
    } else if (isCurrentPlayerComputer) {
      // AI Move execution automatically after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _triggerAiMove();
      });
    }
  }

  void _triggerAiMove() {
    List<LudoToken> tokens = playerTokens[currentPlayer]!;
    int selectedIndex = LudoAiEngine.selectBestMove(
      color: currentPlayer,
      tokens: tokens,
      diceValue: diceValue,
      difficulty: difficulty,
      allTokens: allTokens,
      safeCellIndices: safeCellIndices,
      getGlobalCoordinate: (token, pos) => getGlobalCoordinateOfToken(token, pos),
    );

    if (selectedIndex != -1) {
      moveToken(tokens[selectedIndex]);
    } else {
      isDiceRolled = false;
      _nextTurn();
    }
  }

  Future<void> moveToken(LudoToken token) async {
    if (!isDiceRolled || isMoving || hasWinner) return;
    if (token.color != currentPlayer) return;
    if (!LudoAiEngine.canMoveToken(token, diceValue)) return;

    isMoving = true;
    notifyListeners();

    int startPosition = token.position;
    int targetPosition = startPosition + diceValue;

    if (startPosition == 0 && diceValue == 6) {
      token.position = 1;
      lastGameEvent = 'move';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
    } else {
      // Step-by-step movement animation
      for (int i = startPosition + 1; i <= targetPosition; i++) {
        token.position = i;
        lastGameEvent = 'move';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    // Check for captures
    bool captured = false;
    if (token.position < 52) {
      int globalIndex = getGlobalCoordinateOfToken(token, token.position);
      if (!safeCellIndices.contains(globalIndex)) {
        for (var otherColor in activePlayers) {
          if (otherColor != currentPlayer) {
            for (var otherToken in playerTokens[otherColor]!) {
              if (otherToken.isInPlay) {
                int otherGlobal = getGlobalCoordinateOfToken(otherToken, otherToken.position);
                if (otherGlobal == globalIndex) {
                  otherToken.reset();
                  captured = true;
                  lastGameEvent = 'capture';
                }
              }
            }
          }
        }
      }
    }

    // Check for winning condition
    bool allAtHome = playerTokens[currentPlayer]!.every((t) => t.isAtHome);
    if (allAtHome) {
      hasWinner = true;
      winner = currentPlayer;
      lastGameEvent = 'win';
      isMoving = false;
      isDiceRolled = false;
      notifyListeners();
      return;
    }

    isMoving = false;
    isDiceRolled = false;

    // Rules for extra turns
    bool extraTurn = (diceValue == 6) ||
        (captured && captureGrantsExtraTurn) ||
        (token.position == 57 && homeEntryGrantsExtraTurn);

    if (extraTurn) {
      notifyListeners();
      if (isCurrentPlayerComputer) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          rollDice();
        });
      }
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % activePlayers.length;
    consecutiveSixes = 0;
    notifyListeners();

    if (isCurrentPlayerComputer) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        rollDice();
      });
    }
  }
}
