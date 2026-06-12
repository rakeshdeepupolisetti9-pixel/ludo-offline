enum LudoColor { red, green, yellow, blue }

class LudoToken {
  final LudoColor color;
  final int id;
  
  // 0 = in base
  // 1 to 51 = main track
  // 52 to 56 = home path (safe zone)
  // 57 = home (finished)
  int position;

  LudoToken({
    required this.color,
    required this.id,
    this.position = 0,
  });

  bool get isInBase => position == 0;
  bool get isAtHome => position == 57;
  bool get isInPlay => position > 0 && position < 57;

  void reset() {
    position = 0;
  }
}
