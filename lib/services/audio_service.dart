import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Ek hi player poori app mein: music aur "video ki awaaz background mein".
/// just_audio_background se notification controls aur band screen par play milta hai.
class AudioController {
  AudioController._();
  static final AudioController instance = AudioController._();

  final AudioPlayer player = AudioPlayer();

  Future<void> playSongs(List<SongModel> songs, int startIndex) async {
    final sources = songs
        .map((s) => AudioSource.uri(
              Uri.file(s.data),
              tag: MediaItem(
                id: s.id.toString(),
                title: s.title,
                artist: s.artist == '<unknown>' ? 'Unknown artist' : s.artist,
                duration: Duration(milliseconds: s.duration ?? 0),
              ),
            ))
        .toList();
    await player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
    );
    await player.play();
  }

  /// Video ko background mein chalane ke liye: sirf us ki awaaz, usi position se.
  Future<void> playVideoAudio(File file, String title, Duration position) async {
    await player.setAudioSource(
      AudioSource.uri(
        Uri.file(file.path),
        tag: MediaItem(id: file.path, title: title, artist: 'Video'),
      ),
      initialPosition: position,
    );
    await player.play();
  }

  Future<void> stop() async => player.stop();
}
