import 'package:flutter/material.dart';
import 'alarma_base.dart';

class AlarmaRemedio extends Alarma {
  int intervaloHoras;

  AlarmaRemedio({
    required super.id,
    required super.time,
    required super.title,
    super.isActive,
    required this.intervaloHoras,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'remedio',
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'title': title,
      'isActive': isActive,
      'intervaloHoras': intervaloHoras,
    };
  }

  factory AlarmaRemedio.fromJson(Map<String, dynamic> json) {
    return AlarmaRemedio(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      title: json['title'],
      isActive: json['isActive'],
      intervaloHoras: json['intervaloHoras'],
    );
  }
}