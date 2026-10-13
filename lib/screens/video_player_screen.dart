import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/audio_service.dart';
import 'videos_tab.dart' show fmtDuration;

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  final String title;
  const VideoPlayerScreen({super.key, required this.file, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _controls = true;
  bool _locked = false;
  double _speed = 1.0;
  double _volume = 1.0;
  Timer? _hideTimer;
  String? _hint; // gesture ka chhota message (volume/seek)
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WakelockPlus.enable();
    _c = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _c.play();
        _scheduleHide();
      });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hintTimer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _c.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _c.value.isPlaying) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    if (_controls) _scheduleHide();
  }

  void _showHint(String text) {
    setState(() => _hint = text);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _seekBy(int seconds) {
    final target = _c.value.position + Duration(seconds: seconds);
    final max = _c.value.duration;
    _c.seekTo(target < Duration.zero ? Duration.zero : (target > max ? max : target));
    _showHint(seconds > 0 ? '+${seconds}s' : '${seconds}s');
  }

  /// Background play: video band, sirf awaaz usi position se chalti rahe.
  Future<void> _playInBackground() async {
    final pos = _c.value.position;
    await _c.pause();
    await AudioController.instance
        .playVideoAudio(widget.file, widget.title, pos);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Background mein chal raha hai. Notification se control karein.')));
      Navigator.pop(context);
    }
  }

  void _pickSpeed() async {
    final s = await showModalBottomSheet<double>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          for (final v in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
            ListTile(
              title: Text('${v}x'),
              trailing: v == _speed ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, v),
            ),
        ]),
      ),
    );
    if (s != null) {
      _speed = s;
      _c.setPlaybackSpeed(s);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTapDown: (d) {
          if (_locked) return;
          final w = MediaQuery.of(context).size.width;
          _seekBy(d.localPosition.dx < w / 2 ? -10 : 10);
        },
        onDoubleTap: () {},
        onVerticalDragUpdate: (d) {
          if (_locked) return;
          final w = MediaQuery.of(context).size.width;
          if (d.localPosition.dx > w / 2) {
            _volume = (_volume - d.delta.dy / 300).clamp(0.0, 1.0);
            _c.setVolume(_volume);
            _showHint('Volume ${(_volume * 100).round()}%');
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _ready
                  ? AspectRatio(
                      aspectRatio: v.aspectRatio, child: VideoPlayer(_c))
                  : const CircularProgressIndicator(),
            ),
            if (_hint != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(_hint!,
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            if (_controls && !_locked) _overlay(v),
            if (_locked)
              Positioned(
                left: 16,
                bottom: 24,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.lock_open),
                  onPressed: () => setState(() => _locked = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _overlay(VideoPlayerValue v) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent, Colors.black87],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(children: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              IconButton(
                color: Colors.white,
                tooltip: 'Background play',
                icon: const Icon(Icons.headphones),
                onPressed: _playInBackground,
              ),
            ]),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                iconSize: 38,
                color: Colors.white,
                icon: const Icon(Icons.replay_10),
                onPressed: () => _seekBy(-10),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                iconSize: 44,
                icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  v.isPlaying ? _c.pause() : _c.play();
                  _scheduleHide();
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                iconSize: 38,
                color: Colors.white,
                icon: const Icon(Icons.forward_10),
                onPressed: () => _seekBy(10),
              ),
            ]),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Text(fmtDuration(v.position),
                    style: const TextStyle(color: Colors.white)),
                Expanded(
                  child: VideoProgressIndicator(
                    _c,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  ),
                ),
                Text(fmtDuration(v.duration),
                    style: const TextStyle(color: Colors.white)),
              ]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton.icon(
                onPressed: _pickSpeed,
                icon: const Icon(Icons.speed, color: Colors.white),
                label: Text('${_speed}x',
                    style: const TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _locked = true),
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                label: const Text('Lock', style: TextStyle(color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
