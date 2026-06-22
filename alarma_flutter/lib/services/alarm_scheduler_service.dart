import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';

class AlarmSchedulerService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializar una sola vez (se llama desde main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // ✅ Permisos ya declarados en AndroidManifest.xml, no se requiere llamada en código
    _initialized = true;
  }

  /// Programa una alarma exacta nativa
  static Future<void> scheduleAlarm({
    required int alarmId,
    required TimeOfDay time,
    required String targetObject,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year, now.month, now.day,
      time.hour, time.minute, 0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas',
      channelDescription: 'Canal de alarmas de la app',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      sound: RawResourceAndroidNotificationSound('audio_predef'),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
  alarmId,
  '⏰ ¡Hora de despertar!',
  'Misión: Encuentra "$targetObject" para apagar la alarma',
  tzScheduled,
  notifDetails,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  payload: targetObject,
);
  }

  /// Cancela una alarma por su ID
  static Future<void> cancelAlarm(int alarmId) async {
    await _notificationsPlugin.cancel(alarmId);
  }

  /// Cancela todas las alarmas
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}