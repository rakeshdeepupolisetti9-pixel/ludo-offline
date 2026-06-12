import 'dart:math';
import '../models/token.dart';
import '../models/settings.dart';

class LudoAiEngine {
  static final Random _random = Random();

  /// Evaluates and selects the best token index to move.
  /// Returns -1 if no valid moves are possible.
  static int selectBestMove({
    required LudoColor color,
    required List<LudoToken> tokens,
    required int diceValue,
    required AiDifficulty difficulty,
    required List<LudoToken> allTokens, // All tokens of all players
    required List<int> safeCellIndices, // Indices of safe zones in global coordinates
    required int Function(LudoToken, int) getGlobalCoordinate, // Helper to convert relative to global coordinate
  }) {
    // 1. Find all valid moves for this player's tokens
    List<int> validTokenIndices = [];
    for (int i = 0; i < tokens.length; i++) {
      LudoToken token = tokens[i];
      if (canMoveToken(token, diceValue)) {
        validTokenIndices.add(i);
      }
    }

    if (validTokenIndices.isEmpty) return -1;
    if (validTokenIndices.length == 1) return validTokenIndices.first;

    // 2. Select move based on difficulty
    switch (difficulty) {
      case AiDifficulty.easy:
        return validTokenIndices[_random.nextInt(validTokenIndices.length)];

      case AiDifficulty.medium:
        return _selectMediumMove(
          color,
          tokens,
          validTokenIndices,
          diceValue,
          allTokens,
          safeCellIndices,
          getGlobalCoordinate,
        );

      case AiDifficulty.hard:
        return _selectHardMove(
          color,
          tokens,
          validTokenIndices,
          diceValue,
          allTokens,
          safeCellIndices,
          getGlobalCoordinate,
        );
    }
  }

  static bool canMoveToken(LudoToken token, int diceValue) {
    if (token.isInBase) {
      return diceValue == 6;
    }
    return token.position + diceValue <= 57;
  }

  static int _selectMediumMove(
    LudoColor color,
    List<LudoToken> tokens,
    List<int> validIndices,
    int diceValue,
    List<LudoToken> allTokens,
    List<int> safeCellIndices,
    int Function(LudoToken, int) getGlobalCoordinate,
  ) {
    // Check if any move captures an opponent
    for (int index in validIndices) {
      LudoToken token = tokens[index];
      int nextPosition = token.isInBase ? 1 : token.position + diceValue;
      int nextGlobal = getGlobalCoordinate(token, nextPosition);

      // If next spot is not safe, check if we capture an opponent
      if (!safeCellIndices.contains(nextGlobal) && nextPosition < 52) {
        for (LudoToken other in allTokens) {
          if (other.color != color && other.isInPlay) {
            int otherGlobal = getGlobalCoordinate(other, other.position);
            if (otherGlobal == nextGlobal) {
              return index; // Capture!
            }
          }
        }
      }
    }

    // Check if any move lands on a safe cell
    for (int index in validIndices) {
      LudoToken token = tokens[index];
      int nextPosition = token.isInBase ? 1 : token.position + diceValue;
      int nextGlobal = getGlobalCoordinate(token, nextPosition);
      if (safeCellIndices.contains(nextGlobal)) {
        return index;
      }
    }

    // Default to moving the token closest to home
    int bestIndex = validIndices.first;
    int maxPosition = -1;
    for (int index in validIndices) {
      if (tokens[index].position > maxPosition) {
        maxPosition = tokens[index].position;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  static int _selectHardMove(
    LudoColor color,
    List<LudoToken> tokens,
    List<int> validIndices,
    int diceValue,
    List<LudoToken> allTokens,
    List<int> safeCellIndices,
    int Function(LudoToken, int) getGlobalCoordinate,
  ) {
    int bestIndex = validIndices.first;
    double highestScore = -999999.0;

    for (int index in validIndices) {
      LudoToken token = tokens[index];
      double score = 0.0;

      int currentPos = token.position;
      int nextPos = token.isInBase ? 1 : currentPos + diceValue;
      int currentGlobal = getGlobalCoordinate(token, currentPos);
      int nextGlobal = getGlobalCoordinate(token, nextPos);

      // Rule 1: Prioritize capturing (highly valued)
      bool willCapture = false;
      if (!safeCellIndices.contains(nextGlobal) && nextPos < 52) {
        for (LudoToken other in allTokens) {
          if (other.color != color && other.isInPlay) {
            int otherGlobal = getGlobalCoordinate(other, other.position);
            if (otherGlobal == nextGlobal) {
              willCapture = true;
              score += 150.0;
            }
          }
        }
      }

      // Rule 2: Releasing token from base
      if (currentPos == 0 && diceValue == 6) {
        score += 80.0;
      }

      // Rule 3: Reaching home
      if (nextPos == 57) {
        score += 100.0;
      }

      // Rule 4: Landing in a safe zone
      if (safeCellIndices.contains(nextGlobal)) {
        score += 40.0;
      }

      // Rule 5: Avoid landing in danger (vulnerability check)
      // Check if any opponent is behind the destination and can potentially capture it
      bool inDanger = false;
      for (LudoToken other in allTokens) {
        if (other.color != color && other.isInPlay) {
          int otherGlobal = getGlobalCoordinate(other, other.position);
          // Simple heuristic: if opponent is within 1 to 6 steps behind nextGlobal
          // (Requires checking path distances in a full implementation, here we approximate)
          int distance = (nextGlobal - otherGlobal) % 52;
          if (distance > 0 && distance <= 6 && !safeCellIndices.contains(nextGlobal)) {
            inDanger = true;
          }
        }
      }
      if (inDanger) {
        score -= 30.0;
      }

      // Rule 6: Get out of danger if currently vulnerable
      bool currentlyInDanger = false;
      for (LudoToken other in allTokens) {
        if (other.color != color && other.isInPlay) {
          int otherGlobal = getGlobalCoordinate(other, other.position);
          int distance = (currentGlobal - otherGlobal) % 52;
          if (distance > 0 && distance <= 6 && !safeCellIndices.contains(currentGlobal)) {
            currentlyInDanger = true;
          }
        }
      }
      if (currentlyInDanger && !inDanger) {
        score += 50.0; // Moving away from danger is good
      }

      // Rule 7: General progress (prefer moving tokens that are closer to home, but not too close to get blocked)
      score += nextPos * 0.5;

      if (score > highestScore) {
        highestScore = score;
        bestIndex = index;
      }
    }

    return bestIndex;
  }
}
