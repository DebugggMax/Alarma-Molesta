import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmSchedulerService {
  static bool _initialized = false;

  /// Inicializar el motor indestructible de alarmas
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Inicializa la librería nativa
    await Alarm.init();
    
    _initialized = true;
  }

  /// Programa la alarma real
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

    // Si la hora ya pasó hoy, se programa para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 🚨 SINTAXIS EXACTA Y FINAL PARA LA VERSIÓN 4.0.8
    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledDate,
      assetAudioPath: 'assets/audio/audio_predef.mp3', 
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      
      // 1. EL VOLUMEN SUELTO (Como lo exige la v4)
      volume: 1.0,
      fadeDuration: 3.0, // En la v4 se pasa como número (segundos), no como Duration
      
      // 2. LA NOTIFICACIÓN (Ya vimos que esta sí la acepta perfecto)
      notificationSettings: const NotificationSettings(
        title: '¡Hora de despertar!',
        body: 'Toca para iniciar tu misión o tomar tu remedio',
        stopButton: 'Abrir App',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  /// Cancela una alarma
  static Future<void> cancelAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
  }

  /// Cancela todas
  static Future<void> cancelAll() async {
    await Alarm.stopAll();
  }
}