import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Asegúrate de cambiar 'tu_proyecto' por el nombre real de tu paquete en el pubspec.yaml
import 'package:alarma_flutter/models/alarma_mision.dart';
import 'package:alarma_flutter/models/alarma_remedio.dart';

void main() {
  group('Pruebas Unitarias de Modelos de Alarma (Beta v1.0.0)', () {
    
    // TEST 1: Verificar que el modelo AlarmaMision se crea y serializa correctamente a JSON
    test('1. AlarmaMision debería inicializarse y convertirse a JSON correctamente', () {
      final alarmaMision = AlarmaMision(
        id: '101',
        time: const TimeOfDay(hour: 7, minute: 30),
        title: 'Despertador',
        targetObject: 'Taza',
      );

      final json = alarmaMision.toJson();

      expect(alarmaMision.id, '101');
      expect(alarmaMision.targetObject, 'Taza');
      expect(json['type'], 'mision');
      expect(json['targetObject'], 'Taza');
    });

    // TEST 2: Verificar que el modelo AlarmaRemedio maneja bien sus intervalos de tiempo
    test('2. AlarmaRemedio debería guardar su intervalo de horas correctamente', () {
      final alarmaRemedio = AlarmaRemedio(
        id: '102',
        time: const TimeOfDay(hour: 22, minute: 0),
        title: 'Ibuprofeno',
        intervaloHoras: 8,
      );

      final json = alarmaRemedio.toJson();

      expect(alarmaRemedio.title, 'Ibuprofeno');
      expect(alarmaRemedio.intervaloHoras, 8);
      expect(json['type'], 'remedio');
      expect(json['intervaloHoras'], 8);
    });

    // TEST 3: Simular y validar el parseo desde un JSON (Lo que hace SharedPreferences)
    test('3. Debe reconstruir una AlarmaRemedio desde un mapa JSON sin perder datos', () {
      final Map<String, dynamic> jsonFalso = {
        'id': '103',
        'hour': 14,
        'minute': 15,
        'title': 'Paracetamol',
        'isActive': true,
        'intervaloHoras': 6,
        'type': 'remedio'
      };

      final deJson = AlarmaRemedio.fromJson(jsonFalso);

      expect(deJson.id, '103');
      expect(deJson.title, 'Paracetamol');
      expect(deJson.time.hour, 14);
      expect(deJson.time.minute, 15);
      expect(deJson.intervaloHoras, 6);
      expect(deJson.isActive, true);
    });
  });
}