import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../models/ludo_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<GameSettings>(context);
    final state = Provider.of<LudoState>(context);

    // Apply color schemes based on Theme
    bool isDark = settings.theme == LudoTheme.dark;
    Color scaffoldBg = isDark ? const Color(0xff121212) : const Color(0xfff8f9fa);
    Color cardColor = isDark ? const Color(0xff1e1e1e) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Settings & Rules',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audio & Haptics Section
          _buildSectionHeader('Preferences', textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: const Color(0xff2196f3),
                  title: Text('Sound Effects', style: TextStyle(color: textColor)),
                  value: settings.soundOn,
                  onChanged: (val) => settings.setSound(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: const Color(0xff2196f3),
                  title: Text('Background Music', style: TextStyle(color: textColor)),
                  value: settings.musicOn,
                  onChanged: (val) => settings.setMusic(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: const Color(0xff2196f3),
                  title: Text('Vibration Feedback', style: TextStyle(color: textColor)),
                  value: settings.vibrationOn,
                  onChanged: (val) => settings.setVibration(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Match AI Difficulty Section
          _buildSectionHeader('AI Difficulty', textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _difficultyButton(context, settings, AiDifficulty.easy, 'Easy', Colors.green),
                  _difficultyButton(context, settings, AiDifficulty.medium, 'Medium', Colors.amber),
                  _difficultyButton(context, settings, AiDifficulty.hard, 'Hard', Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Themes Selection Section
          _buildSectionHeader('Theme Design', textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _themeButton(context, settings, LudoTheme.classic, 'Classic', Colors.blue),
                  _themeButton(context, settings, LudoTheme.dark, 'Dark', Colors.grey.shade900),
                  _themeButton(context, settings, LudoTheme.modern, 'Modern', Colors.teal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ludo Rules Customization
          _buildSectionHeader('Custom Ludo Rules', textColor),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: const Color(0xff2196f3),
                  title: Text('Capture token grants extra turn', style: TextStyle(color: textColor)),
                  value: state.captureGrantsExtraTurn,
                  onChanged: (val) {
                    state.captureGrantsExtraTurn = val;
                    state.notifyListeners();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: const Color(0xff2196f3),
                  title: Text('Entering Home grants extra turn', style: TextStyle(color: textColor)),
                  value: state.homeEntryGrantsExtraTurn,
                  onChanged: (val) {
                    state.homeEntryGrantsExtraTurn = val;
                    state.notifyListeners();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: const Color(0xff2196f3),
                  title: Text('Safe zone rules (Safe block entry)', style: TextStyle(color: textColor)),
                  value: state.blocksEnabled,
                  onChanged: (val) {
                    state.blocksEnabled = val;
                    state.notifyListeners();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _difficultyButton(
    BuildContext context,
    GameSettings settings,
    AiDifficulty level,
    String label,
    Color activeColor,
  ) {
    bool isSelected = settings.difficulty == level;
    return ChoiceChip(
      selectedColor: activeColor,
      backgroundColor: Colors.transparent,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) settings.setDifficulty(level);
      },
    );
  }

  Widget _themeButton(
    BuildContext context,
    GameSettings settings,
    LudoTheme theme,
    String label,
    Color activeColor,
  ) {
    bool isSelected = settings.theme == theme;
    return ChoiceChip(
      selectedColor: activeColor,
      backgroundColor: Colors.transparent,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) settings.setTheme(theme);
      },
    );
  }
}
