import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lux_app/services/notification_service.dart';

class MemoryManager {
  static const _memoriesKey = 'user_memories';

  static Future<void> saveMemory(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memories = await getAllMemories();

      memories[key] = {...data, 'createdAt': DateTime.now().toIso8601String()};

      await prefs.setString(_memoriesKey, json.encode(memories));
    } catch (e) {
      debugPrint('Error saving memory: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAllMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoriesJson = prefs.getString(_memoriesKey);
      if (memoriesJson == null) return {};

      final decoded = json.decode(memoriesJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      debugPrint('Error loading memories: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getMemoriesForFollowUp() async {
    final memories = await getAllMemories();
    final now = DateTime.now();

    return memories.entries
        .where((entry) {
          final memory = entry.value as Map<String, dynamic>;
          final createdAt = DateTime.parse(memory['createdAt'] as String);
          final daysPassed = now.difference(createdAt).inDays;
          final followedUp = memory['followedUp'] as bool? ?? false;

          return daysPassed >= 2 && daysPassed <= 4 && !followedUp;
        })
        .map((e) {
          return <String, dynamic>{
            ...e.value as Map<String, dynamic>,
            'key': e.key,
          };
        })
        .toList();
  }

  static Future<void> markAsFollowedUp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final memories = await getAllMemories();

    if (memories.containsKey(key)) {
      memories[key]['followedUp'] = true;
      await prefs.setString(_memoriesKey, json.encode(memories));
    }
  }

  static Future<void> scheduleMemoryNotifications() async {
    final memories = await getAllMemories();
    final now = DateTime.now();
    int notificationId = 1000;

    for (final entry in memories.entries) {
      final memory = entry.value as Map<String, dynamic>;
      final createdAt = DateTime.parse(memory['createdAt'] as String);
      final daysPassed = now.difference(createdAt).inDays;
      final followedUp = memory['followedUp'] as bool? ?? false;

      if (!followedUp && daysPassed < 2) {
        final daysUntilNotification = 2 + (entry.key.hashCode % 3);
        final notificationTime = createdAt.add(
          Duration(days: daysUntilNotification),
        );

        await NotificationService.scheduleNotification(
          id: notificationId++,
          title: 'Recordatorio de ${memory['topic']}',
          body:
              memory['followUpQuestion'] as String? ??
              '¿Cómo va ese tema que mencionaste?',
          delay: notificationTime.difference(now),
          payload: json.encode({
            'type': 'memory_followup',
            'memory_key': entry.key,
          }),
        );
      }
    }
  }
}
