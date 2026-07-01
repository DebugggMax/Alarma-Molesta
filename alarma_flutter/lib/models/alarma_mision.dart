import 'package:flutter/material.dart';
import 'alarma_base.dart';

class AlarmaMision extends Alarma {
  String targetObject;

  AlarmaMision({
    required super.id,
    required super.time,
    required super.title,
    super.isActive,
    required this.targetObject,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'mision', // Etiqueta clave para saber qué tipo de alarma es al cargar
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'title': title,
      'isActive': isActive,
      'targetObject': targetObject,
    };
  }

  factory AlarmaMision.fromJson(Map<String, dynamic> json) {
    return AlarmaMision(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      title: json['title'],
      isActive: json['isActive'],
      targetObject: json['targetObject'],
    );
  }
}