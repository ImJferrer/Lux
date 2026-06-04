import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return result ?? false;
    }

    // En Android, siempre retorna true ya que los permisos se otorgan al instalar.
    return true;
  }

  static Future<void> initialize() async {
    await _requestPermissions();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          notificationCategories: [
            DarwinNotificationCategory(
              'lux_category',
              actions: <DarwinNotificationAction>[],
            ),
          ],
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final payload = json.decode(details.payload!);
            if (payload['type'] == 'memory_followup') {
              // Manejar navegación al chat con la memoria específica
            }
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

      final androidDetails = AndroidNotificationDetails(
        'lux_channel',
        'Recordatorios LUX',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      final iosDetails = DarwinNotificationDetails(
        presentSound: true,
        sound: 'notification.aiff',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
}
