import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_library.dart';
import 'music_tab.dart';
import 'private_tab.dart';
import 'settings_screen.dart';
import 'videos_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final ok = await context.read<MediaLibrary>().requestPermission();
    if (mounted) setState(() => _granted = ok);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Videos', 'Music', 'Private'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index],
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Themes',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _granted == null
          ? const Center(child: CircularProgressIndicator())
          : _granted == false
              ? _PermissionPrompt(onRetry: _ask)
              : IndexedStack(
                  index: _index,
                  children: const [VideosTab(), MusicTab(), PrivateTab()],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Videos'),
          NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music),
              label: 'Music'),
          NavigationDestination(
              icon: Icon(Icons.lock_outline),
              selectedIcon: Icon(Icons.lock),
              label: 'Private'),
        ],
      ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionPrompt({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Videos aur songs dikhane ke liye storage ki ijazat chahiye.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Allow')),
            ],
          ),
        ),
      );
}
