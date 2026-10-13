import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/vault_service.dart';
import 'video_player_screen.dart';

class PrivateTab extends StatefulWidget {
  const PrivateTab({super.key});
  @override
  State<PrivateTab> createState() => _PrivateTabState();
}

class _PrivateTabState extends State<PrivateTab> {
  bool _unlocked = false;
  bool? _hasPassword;
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String? _error;
  List<VaultItem> _items = [];

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final has = await context.read<VaultService>().hasPassword();
    if (mounted) setState(() => _hasPassword = has);
  }

  Future<void> _submit() async {
    final vault = context.read<VaultService>();
    if (_hasPassword == false) {
      if (_pass.text.length < 4) {
        setState(() => _error = 'Kam az kam 4 harf/number rakhein');
        return;
      }
      if (_pass.text != _pass2.text) {
        setState(() => _error = 'Dono passwords match nahi karte');
        return;
      }
      await vault.setPassword(_pass.text);
    } else if (!await vault.verify(_pass.text)) {
      setState(() => _error = 'Ghalat password');
      return;
    }
    _items = await vault.list();
    if (mounted) {
      setState(() {
        _unlocked = true;
        _hasPassword = true;
        _error = null;
        _pass.clear();
        _pass2.clear();
      });
    }
  }

  Future<void> _lock() async {
    await AudioController.instance.stop();
    setState(() => _unlocked = false);
  }

  Future<void> _open(VaultItem item) async {
    if (item.isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(file: item.file, title: item.originalName),
        ),
      );
    } else {
      await AudioController.instance
          .playVideoAudio(item.file, item.originalName, Duration.zero);
    }
  }

  Future<void> _restore(VaultItem item) async {
    final base = Directory('/storage/emulated/0/${item.isVideo ? 'Movies' : 'Music'}');
    final target = await base.exists() ? base : await getApplicationDocumentsDirectory();
    final vault = context.read<VaultService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vault.restore(item, target);
      final list = await vault.list();
      if (mounted) {
        setState(() => _items = list);
        messenger.showSnackBar(
            SnackBar(content: Text('Wapas bhej di: ${p.basename(target.path)}')));
      }
    } on FileSystemException {
      messenger.showSnackBar(const SnackBar(
          content: Text('Wapas bhejne ke liye jagah nahi mili. File vault mein mehfooz hai.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPassword == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _unlocked ? _vaultView() : _lockView();
  }

  Widget _lockView() {
    final first = _hasPassword == false;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 64),
            const SizedBox(height: 14),
            Text(first ? 'Private folder ka password banayein' : 'Private folder',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            TextField(
              controller: _pass,
              obscureText: true,
              onSubmitted: (_) => first ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (first) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pass2,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password dobara likhein',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submit,
              child: Text(first ? 'Password save karein' : 'Unlock'),
            ),
            if (first) ...[
              const SizedBox(height: 14),
              const Text(
                'Yaad rakhein: password bhool gaye to chhupi hui files wapas nahi aa sakengi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vaultView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Expanded(child: Text('Chhupi hui files')),
            TextButton.icon(
              onPressed: _lock,
              icon: const Icon(Icons.lock),
              label: const Text('Lock'),
            ),
          ]),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Abhi khali hai. Videos ya Music tab mein kisi file ke menu se "Private mein chhupao" chunein.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(it.isVideo ? Icons.movie : Icons.music_note),
                        title: Text(it.originalName,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'restore') _restore(it);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'restore', child: Text('Wapas bhejein')),
                          ],
                        ),
                        onTap: () => _open(it),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
