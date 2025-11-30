import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'isDarkMode';
  late Box<dynamic> _settingsBox;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(_boxName);
    _isDarkMode = _settingsBox.get(_themeKey, defaultValue: false);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsBox.put(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _settingsBox.put(_themeKey, _isDarkMode);
    notifyListeners();
  }
}
