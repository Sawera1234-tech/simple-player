import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../services/audio_service.dart';
import 'videos_tab.dart' show fmtDuration;

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = AudioController.instance.player;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: cs.primary.withOpacity(0.45),
                        blurRadius: 40,
                        spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.music_note, size: 110, color: Colors.white),
              ),
              const SizedBox(height: 36),
              StreamBuilder<SequenceState?>(
                stream: player.sequenceStateStream,
                builder: (_, snap) {
                  final tag = snap.data?.currentSource?.tag;
                  final item = tag is MediaItem ? tag : null;
                  return Column(children: [
                    Text(item?.title ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(item?.artist ?? '',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ]);
                },
              ),
              const Spacer(),
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (_, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final total = player.duration ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble();
                  return Column(children: [
                    Slider(
                      value: pos.inMilliseconds.toDouble().clamp(0, max > 0 ? max : 1),
                      max: max > 0 ? max : 1,
                      onChanged: (v) =>
                          player.seek(Duration(milliseconds: v.round())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(fmtDuration(pos)), Text(fmtDuration(total))],
                    ),
                  ]);
                },
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                StreamBuilder<bool>(
                  stream: player.shuffleModeEnabledStream,
                  builder: (_, s) => IconButton(
                    color: (s.data ?? false) ? cs.primary : null,
                    icon: const Icon(Icons.shuffle),
                    onPressed: () async {
                      final on = !(s.data ?? false);
                      if (on) await player.shuffle();
                      await player.setShuffleModeEnabled(on);
                    },
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: player.seekToPrevious,
                ),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (_, s) {
                    final playing = s.data?.playing ?? false;
                    return IconButton.filled(
                      iconSize: 46,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: playing ? player.pause : player.play,
                    );
                  },
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next),
                  onPressed: player.seekToNext,
                ),
                StreamBuilder<LoopMode>(
                  stream: player.loopModeStream,
                  builder: (_, s) {
                    final m = s.data ?? LoopMode.off;
                    return IconButton(
                      color: m == LoopMode.off ? null : cs.primary,
                      icon: Icon(m == LoopMode.one ? Icons.repeat_one : Icons.repeat),
                      onPressed: () => player.setLoopMode(
                          LoopMode.values[(m.index + 1) % LoopMode.values.length]),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
