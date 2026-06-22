import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioService {
  // Creamos una única instancia del reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// 🎵 FUNCIÓN PARA HACER SONAR LA ALARMA
  Future<void> playAlarma() async {
    try {
      debugPrint("🔊 Intentando reproducir la alarma...");

      // 1. Configuramos para que el sonido se repita en bucle (infinito hasta que despierte)
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // 2. Establecemos el volumen al máximo de la app
      await _audioPlayer.setVolume(1.0);

      // 3. Reproducimos desde la carpeta de assets
      // Nota: 'AssetSource' asume por defecto que estás dentro de la carpeta 'assets/'
      // Si tu archivo está en 'assets/audio/alarma.mp3', aquí pones solo 'audio/alarma.mp3'
      await _audioPlayer.play(AssetSource('audio/alarma.mp3'));
      
      debugPrint(" ¡La alarma está sonando con éxito!");
    } catch (e) {
      // Si la ruta está mal o falta el archivo, esto saldrá en tu consola en color rojo
      debugPrint(" ERROR CRÍTICO AL REPRODUCIR AUDIO: $e");
    }
  }

  /// 🛑 FUNCIÓN PARA DETENER LA ALARMA
  Future<void> stopAlarma() async {
    try {
      await _audioPlayer.stop();
      debugPrint(" Alarma detenida con éxito.");
    } catch (e) {
      debugPrint("Error al detener la alarma: $e");
    }
  }

  /// 🧹 LIMPIEZA DE MEMORIA
  void dispose() {
    _audioPlayer.dispose();
  }
}