import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/media_library.dart';
import '../services/vault_service.dart';
import 'now_playing_screen.dart';

class MusicTab extends StatefulWidget {
  const MusicTab({super.key});
  @override
  State<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends State<MusicTab> {
  late Future<List<SongModel>> _future;
  final _audio = AudioController.instance;

  @override
  void initState() {
    super.initState();
    _future = context.read<MediaLibrary>().loadSongs();
  }

  Future<void> _hide(SongModel s) async {
    final vault = context.read<VaultService>();
    if (!await vault.hasPassword()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pehle Private tab mein jaa kar password set karein.')));
      return;
    }
    await vault.hide(File(s.data));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Private folder mein chhup gaya')));
      setState(() => _future = context.read<MediaLibrary>().loadSongs());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<SongModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final songs = snap.data ?? [];
              if (songs.isEmpty) {
                return const Center(child: Text('Koi song nahi mila'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: songs.length,
                itemBuilder: (_, i) {
                  final s = songs[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: QueryArtworkWidget(
                        id: s.id,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(10),
                        nullArtworkWidget: const CircleAvatar(
                            child: Icon(Icons.music_note)),
                      ),
                      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        s.artist == '<unknown>' ? 'Unknown artist' : (s.artist ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'hide') _hide(s);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'hide', child: Text('Private mein chhupao')),
                        ],
                      ),
                      onTap: () async {
                        await _audio.playSongs(songs, i);
                        if (context.mounted) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        const _MiniPlayer(),
      ],
    );
  }
}

/// Neeche chhota player jab koi gana chal raha ho.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final player = AudioController.instance.player;
    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snap) {
        final tag = snap.data?.currentSource?.tag;
        if (tag is! MediaItem) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: ListTile(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NowPlayingScreen())),
            leading: const Icon(Icons.music_note),
            title: Text(tag.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(tag.artist ?? '', maxLines: 1),
            trailing: StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (_, s) {
                final playing = s.data?.playing ?? false;
                return IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: playing ? player.pause : player.play,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
