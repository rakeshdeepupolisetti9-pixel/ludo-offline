import 'package:flutter/material.dart';

enum AiDifficulty { easy, medium, hard }
enum LudoTheme { classic, dark, modern }

class GameSettings extends ChangeNotifier {
  bool _soundOn = true;
  bool _musicOn = true;
  bool _vibrationOn = true;
  AiDifficulty _difficulty = AiDifficulty.medium;
  LudoTheme _theme = LudoTheme.classic;

  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  bool get vibrationOn => _vibrationOn;
  AiDifficulty get difficulty => _difficulty;
  LudoTheme get theme => _theme;

  void setSound(bool value) {
    _soundOn = value;
    notifyListeners();
  }

  void setMusic(bool value) {
    _musicOn = value;
    notifyListeners();
  }

  void setVibration(bool value) {
    _vibrationOn = value;
    notifyListeners();
  }

  void setDifficulty(AiDifficulty value) {
    _difficulty = value;
    notifyListeners();
  }

  void setTheme(LudoTheme value) {
    _theme = value;
    notifyListeners();
  }
}
