import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ludo_state.dart';
import '../models/token.dart';
import '../models/settings.dart';
import '../services/ai_engine.dart';

class LudoBoardWidget extends StatelessWidget {
  const LudoBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LudoState>(context);
    final settings = Provider.of<GameSettings>(context);

    // Get color theme
    Color boardBg = Colors.white;
    Color borderCol = Colors.black;
    if (settings.theme == LudoTheme.dark) {
      boardBg = const Color(0xff121212);
      borderCol = const Color(0xff333333);
    } else if (settings.theme == LudoTheme.modern) {
      boardBg = const Color(0xfff0f4f8);
      borderCol = Colors.transparent;
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: boardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double size = constraints.maxWidth;
            double cellSize = size / 15.0;

            return Stack(
              children: [
                // Custom Paint for Ludo Board Cells
                CustomPaint(
                  size: Size(size, size),
                  painter: LudoBoardPainter(
                    theme: settings.theme,
                    borderColor: borderCol,
                  ),
                ),
                // Custom Widgets for Tokens
                ...state.allTokens.map((token) {
                  final gridPos = state.getTokenGridPosition(token);
                  double left = gridPos.y * cellSize;
                  double top = gridPos.x * cellSize;

                  // Find other tokens on the same spot to stack/spread them
                  List<LudoToken> overlapping = state.allTokens
                      .where((t) =>
                          t.isInPlay &&
                          state.getGlobalCoordinateOfToken(t, t.position) ==
                              state.getGlobalCoordinateOfToken(token, token.position) &&
                          t.color == token.color)
                      .toList();

                  int indexInOverlap = overlapping.indexOf(token);
                  double offsetVal = cellSize * 0.12;
                  
                  if (overlapping.length > 1 && indexInOverlap != -1) {
                    // Spread overlapping tokens slightly
                    double angle = (indexInOverlap * 2 * pi) / overlapping.length;
                    left += cos(angle) * offsetVal;
                    top += sin(angle) * offsetVal;
                  }

                  bool isSelectable = state.isDiceRolled &&
                      !state.isMoving &&
                      token.color == state.currentPlayer &&
                      !state.isCurrentPlayerComputer &&
                      LudoAiEngine.canMoveToken(token, state.diceValue);

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    left: left,
                    top: top,
                    width: cellSize,
                    height: cellSize,
                    child: Center(
                      child: TokenWidget(
                        token: token,
                        isSelectable: isSelectable,
                        onTap: () {
                          if (isSelectable) {
                            state.moveToken(token);
                          }
                        },
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TokenWidget extends StatelessWidget {
  final LudoToken token;
  final bool isSelectable;
  final VoidCallback onTap;

  const TokenWidget({
    super.key,
    required this.token,
    required this.isSelectable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    Color accentColor;

    switch (token.color) {
      case LudoColor.red:
        baseColor = const Color(0xffe53935);
        accentColor = const Color(0xffff8a80);
        break;
      case LudoColor.green:
        baseColor = const Color(0xff43a047);
        accentColor = const Color(0xffb9f6ca);
        break;
      case LudoColor.yellow:
        baseColor = const Color(0xfffdd835);
        accentColor = const Color(0xffffff8d);
        break;
      case LudoColor.blue:
        baseColor = const Color(0xff1e88e5);
        accentColor = const Color(0xff82b1ff);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelectable ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              if (isSelectable)
                BoxShadow(
                  color: baseColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 3,
                )
            ],
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LudoBoardPainter extends CustomPainter {
  final LudoTheme theme;
  final Color borderColor;

  LudoBoardPainter({required this.theme, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / 15.0;

    // Define colors according to the theme
    Color redColor = const Color(0xffe53935);
    Color greenColor = const Color(0xff43a047);
    Color yellowColor = const Color(0xfffdd835);
    Color blueColor = const Color(0xff1e88e5);
    Color whiteColor = Colors.white;

    if (theme == LudoTheme.dark) {
      redColor = const Color(0xffcf6679);
      greenColor = const Color(0xff03dac6);
      yellowColor = const Color(0xfffbc02d);
      blueColor = const Color(0xff3700b3);
      whiteColor = const Color(0xff1e1e1e);
    } else if (theme == LudoTheme.modern) {
      redColor = const Color(0xffff5252);
      greenColor = const Color(0xff69f0ae);
      yellowColor = const Color(0xffffd740);
      blueColor = const Color(0xff40c4ff);
      whiteColor = const Color(0xfffafafa);
    }

    Paint cellPaint = Paint()..style = PaintingStyle.fill;
    Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw the 15x15 board cells
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        Rect rect = Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize);

        // Determine base yards
        if (row < 6 && col < 6) {
          cellPaint.color = redColor;
        } else if (row < 6 && col >= 9) {
          cellPaint.color = greenColor;
        } else if (row >= 9 && col >= 9) {
          cellPaint.color = yellowColor;
        } else if (row >= 9 && col < 6) {
          cellPaint.color = blueColor;
        }
        // Home center
        else if (row >= 6 && row <= 8 && col >= 6 && col <= 8) {
          if (row == 6 && col == 7) {
            cellPaint.color = greenColor;
          } else if (row == 8 && col == 7) {
            cellPaint.color = blueColor;
          } else if (row == 7 && col == 6) {
            cellPaint.color = redColor;
          } else if (row == 7 && col == 8) {
            cellPaint.color = yellowColor;
          } else {
            cellPaint.color = whiteColor;
          }
        }
        // Paths
        else {
          cellPaint.color = whiteColor;

          // Red Starting & Home path
          if (row == 6 && col == 1) cellPaint.color = redColor;
          if (row == 7 && col >= 1 && col <= 5) cellPaint.color = redColor;

          // Green Starting & Home path
          if (row == 1 && col == 8) cellPaint.color = greenColor;
          if (col == 7 && row >= 1 && row <= 5) cellPaint.color = greenColor;

          // Yellow Starting & Home path
          if (row == 8 && col == 13) cellPaint.color = yellowColor;
          if (row == 7 && col >= 9 && col <= 13) cellPaint.color = yellowColor;

          // Blue Starting & Home path
          if (row == 13 && col == 6) cellPaint.color = blueColor;
          if (col == 7 && row >= 9 && row <= 13) cellPaint.color = blueColor;

          // Other safe zones
          if ((row == 8 && col == 2) || (row == 2 && col == 6) || (row == 6 && col == 12) || (row == 12 && col == 8)) {
            cellPaint.color = Colors.grey.shade300;
          }
        }

        canvas.drawRect(rect, cellPaint);
        if (borderColor != Colors.transparent) {
          canvas.drawRect(rect, borderPaint);
        }
      }
    }

    // Paint bases yards white inner panel
    _paintBaseYardInner(canvas, 0, 0, cellSize, whiteColor);
    _paintBaseYardInner(canvas, 9 * cellSize, 0, cellSize, whiteColor);
    _paintBaseYardInner(canvas, 9 * cellSize, 9 * cellSize, cellSize, whiteColor);
    _paintBaseYardInner(canvas, 0, 9 * cellSize, cellSize, whiteColor);
  }

  void _paintBaseYardInner(Canvas canvas, double x, double y, double cellSize, Color whiteColor) {
    Rect rect = Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 4, cellSize * 4);
    Paint fill = Paint()..color = whiteColor;
    canvas.drawRect(rect, fill);
    
    if (borderColor != Colors.transparent) {
      Paint border = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(rect, border);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
