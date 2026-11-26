import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent local JSON data source backed by SharedPreferences.
class LocalStorageDataSource {
  LocalStorageDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String keyCurrentUser = 'fx_current_user_v1';
  static const String keyPreviousLastActive = 'fx_prev_last_active_v1';
  static const String keyOpenJourney = 'fx_open_journey_v1';
  static const String keySessions = 'fx_sessions_v1';
  static const String keyReflections = 'fx_session_reflections_v1';
  static const String keyUpdates = 'fx_journey_updates_v1';
  static const String keyWeeklyReflections = 'fx_weekly_reflections_v1';
  static const String keyArchives = 'fx_journey_archives_v1';
  static const String keyQueue = 'fx_journey_queue_v1';
  static const String keyGroup = 'fx_assigned_group_v1';
  static const String keyFeed = 'fx_group_feed_v1';
  static const String keyNotifications = 'fx_notifications_v1';
  static const String keyPendingSyncOps = 'fx_pending_sync_ops_v1';
  static const String keyOfflineMode = 'fx_offline_mode_v1';
  static const String keyLastLocalSave = 'fx_last_local_save_v1';
  static const String keyLastRemoteSync = 'fx_last_remote_sync_v1';

  Map<String, dynamic>? readObject(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeObject(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, jsonEncode(value));
    await _prefs.setString(keyLastLocalSave, DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
    await _prefs.setString(keyLastLocalSave, DateTime.now().toIso8601String());
  }

  bool readBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  DateTime? readDateTime(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeDateTime(String key, DateTime? dt) async {
    if (dt == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, dt.toIso8601String());
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
