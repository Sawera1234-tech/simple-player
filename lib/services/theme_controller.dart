import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class ThemeController extends ChangeNotifier {
  AppThemeData _current = kThemes.first;
  AppThemeData get current => _current;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _current = themeById(prefs.getString('theme'));
    notifyListeners();
  }

  Future<void> select(AppThemeData t) async {
    _current = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', t.id);
  }
}
