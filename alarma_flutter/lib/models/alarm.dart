import 'package:flutter/material.dart';

class AlarmModel {
  final String id;
  TimeOfDay time;
  bool isActive;
  final String targetObject; // El objeto que la IA pedirá para esta alarma

  AlarmModel({
    required this.id,
    required this.time,
    this.isActive = true,
    required this.targetObject,
  });
}