import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ludo_state.dart';
import '../models/token.dart';

class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayValue = 1;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollDiceEffect(int targetValue) async {
    setState(() {
      _rolling = true;
    });

    _controller.forward(from: 0.0);
    
    // Simulate dice rotation / face switches
    for (int i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _displayValue = Random().nextInt(6) + 1;
        });
      }
    }

    if (mounted) {
      setState(() {
        _displayValue = targetValue;
        _rolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LudoState>(context);

    // Trigger local roll animation if state rolled and we are not matching the target
    if (state.isDiceRolled && !_rolling && _displayValue != state.diceValue) {
      _rollDiceEffect(state.diceValue);
    }

    // Reset indicator
    if (!state.isDiceRolled && _displayValue != state.diceValue) {
      _displayValue = state.diceValue;
    }

    Color activeColor;
    switch (state.currentPlayer) {
      case LudoColor.red:
        activeColor = const Color(0xffe53935);
        break;
      case LudoColor.green:
        activeColor = const Color(0xff43a047);
        break;
      case LudoColor.yellow:
        activeColor = const Color(0xfffdd835);
        break;
      case LudoColor.blue:
        activeColor = const Color(0xff1e88e5);
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!state.isDiceRolled && !state.isMoving && !state.isCurrentPlayerComputer) {
          state.rollDice();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double rotation = _controller.value * 2 * pi;
          double scale = 1.0;
          if (_rolling) {
            scale = 0.8 + 0.2 * sin(_controller.value * pi);
          }

          return Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: CustomPaint(
                  painter: DicePainter(value: _displayValue, color: activeColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DicePainter extends CustomPainter {
  final int value;
  final Color color;

  DicePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    double radius = size.width * 0.08;

    void drawDot(double cx, double cy) {
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    double left = size.width * 0.25;
    double mid = size.width * 0.5;
    double right = size.width * 0.75;

    switch (value) {
      case 1:
        drawDot(mid, mid);
        break;
      case 2:
        drawDot(left, left);
        drawDot(right, right);
        break;
      case 3:
        drawDot(left, left);
        drawDot(mid, mid);
        drawDot(right, right);
        break;
      case 4:
        drawDot(left, left);
        drawDot(right, left);
        drawDot(left, right);
        drawDot(right, right);
        break;
      case 5:
        drawDot(left, left);
        drawDot(right, left);
        drawDot(mid, mid);
        drawDot(left, right);
        drawDot(right, right);
        break;
      case 6:
        drawDot(left, left);
        drawDot(right, left);
        drawDot(left, mid);
        drawDot(right, mid);
        drawDot(left, right);
        drawDot(right, right);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
