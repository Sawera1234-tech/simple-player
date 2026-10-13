import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoItem {
  final AssetEntity asset;
  VideoItem(this.asset);
  String get title => asset.title ?? 'Video';
  Duration get duration => Duration(seconds: asset.duration);
  Future<File?> get file => asset.file;
}

class MediaLibrary {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Storage permission maango (Android 13+ mein media permissions).
  Future<bool> requestPermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    final audio = await Permission.audio.request();
    final storage = await Permission.storage.request();
    return ps.hasAccess || audio.isGranted || storage.isGranted;
  }

  Future<List<VideoItem>> loadVideos() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];
    final count = await albums.first.assetCountAsync;
    final assets = await albums.first.getAssetListRange(start: 0, end: count);
    return assets.map(VideoItem.new).toList();
  }

  Future<List<SongModel>> loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    // chhoti awazein (ringtones/notifications) hata do
    return songs.where((s) => (s.duration ?? 0) > 30000 && s.isMusic == true).toList();
  }
}
