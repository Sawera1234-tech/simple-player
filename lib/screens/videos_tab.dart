import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../services/media_library.dart';
import '../services/vault_service.dart';
import 'video_player_screen.dart';

String fmtDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  return h > 0
      ? '$h:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
      : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
}

class VideosTab extends StatefulWidget {
  const VideosTab({super.key});
  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  late Future<List<VideoItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<MediaLibrary>().loadVideos();
  }

  Future<void> _refresh() async {
    setState(() => _future = context.read<MediaLibrary>().loadVideos());
    await _future;
  }

  Future<void> _hide(VideoItem v) async {
    final vault = context.read<VaultService>();
    if (!await vault.hasPassword()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pehle Private tab mein jaa kar password set karein.')));
      return;
    }
    final f = await v.file;
    if (f == null) return;
    await vault.hide(f);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Private folder mein chhup gayi')));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VideoItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Koi video nahi mili'));
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final v = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: _Thumb(asset: v),
                  title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(fmtDuration(v.duration)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (s) {
                      if (s == 'hide') _hide(v);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'hide', child: Text('Private mein chhupao')),
                    ],
                  ),
                  onTap: () async {
                    final f = await v.file;
                    if (f == null || !context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(file: f, title: v.title),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  final VideoItem asset;
  const _Thumb({required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 80,
        height: 56,
        child: FutureBuilder<Uint8List?>(
          future: asset.asset.thumbnailDataWithSize(const ThumbnailSize(240, 170)),
          builder: (_, s) => s.data == null
              ? const ColoredBox(color: Colors.black26, child: Icon(Icons.play_arrow))
              : Image.memory(s.data!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
