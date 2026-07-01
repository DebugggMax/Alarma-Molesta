import 'package:flutter/material.dart';

abstract class Alarma {
  String id;
  TimeOfDay time;
  String title;
  bool isActive;

  Alarma({
    required this.id,
    required this.time,
    required this.title,
    this.isActive = true,
  });

  // Obligamos a los hijos a tener una función para convertirse en texto (JSON)
  Map<String, dynamic> toJson();
}