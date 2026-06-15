import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _seedColorKey = 'theme_seed_color';
  static const String _showTopicsKey = 'show_suggested_topics';
  static const String _showAuthorsKey = 'show_top_authors';

  Color _seedColor = const Color(0xFF1D9E75);
  bool _showSuggestedTopics = true;
  bool _showTopAuthors = true;

  Color get seedColor => _seedColor;
  bool get showSuggestedTopics => _showSuggestedTopics;
  bool get showTopAuthors => _showTopAuthors;

  Color get appBarColor {
    final hsl = HSLColor.fromColor(_seedColor);
    return hsl.withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0)).toColor();
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_seedColorKey);
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    _showSuggestedTopics = prefs.getBool(_showTopicsKey) ?? true;
    _showTopAuthors = prefs.getBool(_showAuthorsKey) ?? true;
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.value);
  }

  Future<void> setShowSuggestedTopics(bool value) async {
    _showSuggestedTopics = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTopicsKey, value);
  }

  Future<void> setShowTopAuthors(bool value) async {
    _showTopAuthors = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAuthorsKey, value);
  }
}
