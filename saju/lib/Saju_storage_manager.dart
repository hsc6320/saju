import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SajuStorageManager {
  static Future<void> saveSajuData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        await prefs.setString(key, value);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    }
  }

  static Future<Map<String, dynamic>> loadSajuData(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> result = {};

    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null) {
        // JSON decode 시도
        try {
          result[key] = jsonDecode(value);
        } catch (_) {
          result[key] = value;
        }
      }
    }

    return result;
  }

  static Future<void> clearSajuData(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
