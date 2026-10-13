import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/media_library.dart';
import 'services/theme_controller.dart';
import 'services/vault_service.dart';
import 'theme/art_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.simple_player.audio',
    androidNotificationChannelName: 'Playback',
    androidNotificationOngoing: true,
  );
  final themeController = ThemeController();
  await themeController.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        Provider(create: (_) => MediaLibrary()),
        Provider(create: (_) => VaultService()),
      ],
      child: const SimplePlayerApp(),
    ),
  );
}

class SimplePlayerApp extends StatelessWidget {
  const SimplePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().current;
    return MaterialApp(
      title: 'Simple Player',
      debugShowCheckedModeBanner: false,
      theme: t.toThemeData(),
      builder: (context, child) =>
          ArtBackground(theme: t, child: child ?? const SizedBox()),
      home: const HomeScreen(),
    );
  }
}
