import 'package:flutter/material.dart';

/// Har theme ka rang aur background art (code se bana hua, koi image file nahi).
class AppThemeData {
  final String id;
  final String name;
  final Brightness brightness;
  final Color primary;
  final List<Color> gradient;
  final ArtKind art;

  const AppThemeData({
    required this.id,
    required this.name,
    required this.brightness,
    required this.primary,
    required this.gradient,
    required this.art,
  });

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: (brightness == Brightness.dark ? Colors.black : Colors.white)
            .withOpacity(0.28),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withOpacity(0.35),
      ),
    );
  }
}

enum ArtKind { sunset, night, sakura, ocean, forest, minimalDark }

const List<AppThemeData> kThemes = [
  AppThemeData(
    id: 'sunset',
    name: 'Sunset',
    brightness: Brightness.dark,
    primary: Color(0xFFFF7E5F),
    gradient: [Color(0xFF2B1055), Color(0xFFD4507A), Color(0xFFFFA45B)],
    art: ArtKind.sunset,
  ),
  AppThemeData(
    id: 'night',
    name: 'Starry Night',
    brightness: Brightness.dark,
    primary: Color(0xFF8E9BFF),
    gradient: [Color(0xFF05071A), Color(0xFF111A4A), Color(0xFF2B2F78)],
    art: ArtKind.night,
  ),
  AppThemeData(
    id: 'sakura',
    name: 'Sakura',
    brightness: Brightness.light,
    primary: Color(0xFFE75A8F),
    gradient: [Color(0xFFFFE4EE), Color(0xFFFFC2D8), Color(0xFFFFF1F6)],
    art: ArtKind.sakura,
  ),
  AppThemeData(
    id: 'ocean',
    name: 'Ocean',
    brightness: Brightness.dark,
    primary: Color(0xFF3CC7D8),
    gradient: [Color(0xFF021B2B), Color(0xFF065A7A), Color(0xFF2AA9B8)],
    art: ArtKind.ocean,
  ),
  AppThemeData(
    id: 'forest',
    name: 'Forest',
    brightness: Brightness.dark,
    primary: Color(0xFF6FCF8B),
    gradient: [Color(0xFF07201A), Color(0xFF14513B), Color(0xFF3E8F63)],
    art: ArtKind.forest,
  ),
  AppThemeData(
    id: 'dark',
    name: 'Simple Dark',
    brightness: Brightness.dark,
    primary: Color(0xFF9C7BFF),
    gradient: [Color(0xFF0B0B10), Color(0xFF14141D)],
    art: ArtKind.minimalDark,
  ),
];

AppThemeData themeById(String? id) =>
    kThemes.firstWhere((t) => t.id == id, orElse: () => kThemes.first);
