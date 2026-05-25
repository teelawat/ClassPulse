import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight key-value store backed by a JSON file inside the app's
/// support directory.  Works on Android, iOS, Windows, macOS and Linux.
///
/// Replaces SharedPreferences to avoid the "Access is denied" error that
/// occurs with shared_preferences_windows when AppData\Roaming permissions
/// are unusual.
class AppStorage {
  static File? _file;
  static final Map<String, dynamic> _cache = {};
  static bool _initialised = false;

  /// Call once before using [getString] / [setString].
  static Future<void> init() async {
    if (_initialised) return;
    try {
      if (kIsWeb) {
        _initialised = true;
        return;
      }
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}${Platform.pathSeparator}class_pulse_store.json');
      debugPrint('AppStorage: using ${_file!.path}');
      if (await _file!.exists()) {
        final raw = await _file!.readAsString();
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          _cache.addAll(decoded);
        }
      }
      _initialised = true;
    } catch (e) {
      debugPrint('AppStorage init error: $e');
      _initialised = true; // still mark as done so app doesn't hang
    }
  }

  static Future<String?> getString(String key) async {
    return _cache[key] as String?;
  }

  static Future<bool> setString(String key, String value) async {
    _cache[key] = value;
    return _flush();
  }

  static Future<bool> remove(String key) async {
    _cache.remove(key);
    return _flush();
  }

  static Future<bool> _flush() async {
    try {
      if (_file == null || kIsWeb) return true;
      await _file!.writeAsString(json.encode(_cache));
      return true;
    } catch (e) {
      debugPrint('AppStorage flush error: $e');
      return false;
    }
  }
}
