import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalityManager {
  static const _key = 'lux_personality';

  static Future<Map<String, double>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return _empty();
    return Map<String, double>.from(json.decode(raw));
  }

  static Future<void> save(Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(data));
  }

  static Map<String, double> _empty() => {
    'friendliness': 0.0,
    'formality': 0.0,
    'humor': 0.0,
    'knowledge': 0.0,
  };

  static Future<void> add(String trait, double delta) async {
    final map = await load();
    map[trait] = (map[trait] ?? 0) + delta;
    map[trait] = map[trait]!.clamp(-1.0, 1.0);
    await save(map);
  }
}
