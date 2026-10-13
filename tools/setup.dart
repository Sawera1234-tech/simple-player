// Windows / Mac / Linux, teeno par chalti hai. Chalane ka tareeqa (project folder ke andar):
//   dart tools/setup.dart
// 1) Purane plugins mein "namespace" ki missing setting theek karti hai
// 2) Android ki permissions aur background-play service lagati hai
import 'dart:io';

final String _sep = Platform.pathSeparator;

void main() {
  _patchPluginNamespaces();
  _configureAndroid();
  stdout.writeln('Android configuration ho gayi.');
}

void _patchPluginNamespaces() {
  final env = Platform.environment;
  final roots = <String>[
    if (env['PUB_CACHE'] != null) env['PUB_CACHE']!,
    if (env['HOME'] != null) '${env['HOME']}/.pub-cache',
    if (env['USERPROFILE'] != null) '${env['USERPROFILE']}\\.pub-cache',
    if (env['LOCALAPPDATA'] != null) '${env['LOCALAPPDATA']}\\Pub\\Cache',
    if (env['APPDATA'] != null) '${env['APPDATA']}\\Pub\\Cache',
  ];
  for (final root in roots) {
    final hosted = Directory('$root${_sep}hosted');
    if (!hosted.existsSync()) continue;
    for (final host in hosted.listSync().whereType<Directory>()) {
      for (final pkg in host.listSync().whereType<Directory>()) {
        final android = '${pkg.path}${_sep}android';
        final gradle = File('$android${_sep}build.gradle');
        if (!gradle.existsSync()) continue;
        var text = gradle.readAsStringSync();
        if (text.contains('namespace')) continue;
        final manifest =
            File('$android${_sep}src${_sep}main${_sep}AndroidManifest.xml');
        if (!manifest.existsSync()) continue;
        final m =
            RegExp(r'package="([^"]+)"').firstMatch(manifest.readAsStringSync());
        if (m == null) continue;
        text = text.replaceFirst(
            RegExp(r'android\s*\{'), 'android {\n    namespace "${m.group(1)}"');
        gradle.writeAsStringSync(text);
        stdout.writeln('patched ${pkg.path}');
      }
    }
  }
}

void _configureAndroid() {
  // 1) AndroidManifest.xml
  final mf = File('android/app/src/main/AndroidManifest.xml');
  var s = mf.readAsStringSync();
  if (!s.contains('xmlns:tools')) {
    s = s.replaceFirst(
        '<manifest ', '<manifest xmlns:tools="http://schemas.android.com/tools" ');
  }
  const perms = '''

    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
''';
  if (!s.contains('READ_MEDIA_VIDEO')) {
    s = s.replaceFirstMapped(
        RegExp(r'(<manifest[^>]*>)'), (m) => '${m.group(1)}$perms');
  }
  const svc = '''

        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>
''';
  if (!s.contains('com.ryanheise.audioservice.AudioService')) {
    s = s.replaceFirst('</application>', '$svc    </application>');
  }
  s = s.replaceAll('android:label="simple_player"', 'android:label="Simple Player"');
  mf.writeAsStringSync(s);

  // 2) MainActivity -> AudioServiceActivity (background play ke liye zaroori)
  final src = Directory('android/app/src/main');
  for (final f in src.listSync(recursive: true).whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.startsWith('MainActivity.')) continue;
    final pkg = RegExp(r'^package\s+([\w.]+)', multiLine: true)
        .firstMatch(f.readAsStringSync())!
        .group(1);
    f.writeAsStringSync('package $pkg\n\n'
        'import com.ryanheise.audioservice.AudioServiceActivity\n\n'
        'class MainActivity : AudioServiceActivity()\n');
  }

  // 3) minSdk 24
  for (final name in ['build.gradle', 'build.gradle.kts']) {
    final g = File('android/app/$name');
    if (!g.existsSync()) continue;
    g.writeAsStringSync(g.readAsStringSync().replaceAll(
        RegExp(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion'), 'minSdk = 24'));
  }
}
