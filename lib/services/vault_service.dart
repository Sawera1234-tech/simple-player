import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Private folder: files app ke andar (app-private storage) move hoti hain,
/// jahan gallery ya file manager unhein nahi dekh sakta. Password hash
/// (salt + SHA-256, 10,000 rounds) ke saath save hota hai, asal password nahi.
class VaultService {
  static const _kHash = 'vault_hash';
  static const _kSalt = 'vault_salt';
  static const _kIndex = 'vault_index'; // json: { storedName: originalName }

  Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kHash) != null;
  }

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _randomSalt();
    await prefs.setString(_kSalt, salt);
    await prefs.setString(_kHash, _hash(password, salt));
  }

  Future<bool> verify(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_kSalt);
    final hash = prefs.getString(_kHash);
    if (salt == null || hash == null) return false;
    return _hash(password, salt) == hash;
  }

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, '.vault'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Map<String, String>> _readIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kIndex);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeIndex(Map<String, String> m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIndex, jsonEncode(m));
  }

  /// File ko vault mein move karo (original device se hata di jati hai).
  Future<void> hide(File source) async {
    final dir = await _dir();
    final stored = '${DateTime.now().microsecondsSinceEpoch}.bin';
    final dest = File(p.join(dir.path, stored));
    try {
      await source.rename(dest.path);
    } on FileSystemException {
      // alag storage volume: copy phir delete
      await source.copy(dest.path);
      await source.delete();
    }
    final idx = await _readIndex();
    idx[stored] = p.basename(source.path);
    await _writeIndex(idx);
  }

  /// Vault ki files: [(storedPath, originalName)]
  Future<List<VaultItem>> list() async {
    final dir = await _dir();
    final idx = await _readIndex();
    final items = <VaultItem>[];
    for (final e in idx.entries) {
      final f = File(p.join(dir.path, e.key));
      if (await f.exists()) items.add(VaultItem(f, e.value));
    }
    return items;
  }

  /// Vault se wapas device ke Download/Movies jese folder mein bhejo.
  Future<File> restore(VaultItem item, Directory target) async {
    var dest = File(p.join(target.path, item.originalName));
    if (await dest.exists()) {
      dest = File(p.join(target.path,
          '${p.basenameWithoutExtension(item.originalName)}_${DateTime.now().millisecondsSinceEpoch}${p.extension(item.originalName)}'));
    }
    try {
      await item.file.rename(dest.path);
    } on FileSystemException {
      await item.file.copy(dest.path);
      await item.file.delete();
    }
    final idx = await _readIndex();
    idx.remove(p.basename(item.file.path));
    await _writeIndex(idx);
    return dest;
  }

  String _randomSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  String _hash(String password, String salt) {
    Uint8List bytes = Uint8List.fromList(utf8.encode('$salt$password'));
    for (int i = 0; i < 10000; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64Url.encode(bytes);
  }
}

class VaultItem {
  final File file;
  final String originalName;
  VaultItem(this.file, this.originalName);

  bool get isVideo {
    final e = p.extension(originalName).toLowerCase();
    return const ['.mp4', '.mkv', '.avi', '.mov', '.webm', '.3gp', '.flv', '.wmv']
        .contains(e);
  }
}
