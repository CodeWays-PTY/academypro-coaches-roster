import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String sessionBoxName = 'session_box';
  static const String cacheBoxName = 'cache_box';
  static const String syncQueueBoxName = 'sync_queue_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(sessionBoxName);
    await Hive.openBox(cacheBoxName);
    await Hive.openBox(syncQueueBoxName);
  }

  // ==========================================
  // SESSION METHODS (JWT & Profile)
  // ==========================================

  static Box get _sessionBox => Hive.box(sessionBoxName);

  static Future<void> saveSession(String token, Map<String, dynamic> userProfile) async {
    await _sessionBox.put('token', token);
    await _sessionBox.put('user', jsonEncode(userProfile));
  }

  static String? getToken() {
    return _sessionBox.get('token') as String?;
  }

  static Map<String, dynamic>? getUserProfile() {
    final rawUser = _sessionBox.get('user') as String?;
    if (rawUser == null) return null;
    return jsonDecode(rawUser) as Map<String, dynamic>;
  }

  static Future<void> clearSession() async {
    await _sessionBox.clear();
  }

  // ==========================================
  // CACHE METHODS (Roster & Summary JSONs)
  // ==========================================

  static Box get _cacheBox => Hive.box(cacheBoxName);

  static Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, jsonEncode(data));
  }

  static dynamic getCachedData(String key) {
    final rawData = _cacheBox.get(key) as String?;
    if (rawData == null) return null;
    return jsonDecode(rawData);
  }

  // ==========================================
  // OFFLINE SYNC METHODS (Queue)
  // ==========================================

  static Box get _syncBox => Hive.box(syncQueueBoxName);

  static Future<void> queueMatchStats(Map<String, dynamic> payload) async {
    // Generate unique key using timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _syncBox.put(timestamp, jsonEncode(payload));
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    final list = <Map<String, dynamic>>[];
    for (var key in _syncBox.keys) {
      final val = _syncBox.get(key) as String?;
      if (val != null) {
        list.add({
          'key': key,
          'payload': jsonDecode(val),
        });
      }
    }
    return list;
  }

  static Future<void> dequeueItem(dynamic key) async {
    await _syncBox.delete(key);
  }
}
