import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Reproduce el sonido de la alarma en un bucle infinito
  Future<void> playAlarma() async {
    try {
      // 1. Le decimos al reproductor que cuando termine la pista, vuelva a empezar (bucle)
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // 2. Reproducimos el archivo. 
      await _audioPlayer.play(AssetSource('audio/audio_predef.mp3'));
      
      debugPrint("🔊 Alarma sonando en bucle...");
    } catch (e) {
      debugPrint("Error al reproducir la alarma: $e");
    }
  }

  /// Detiene el sonido por completo
  Future<void> stopAlarma() async {
    try {
      await _audioPlayer.stop();
      debugPrint("🔇 Alarma detenida.");
    } catch (e) {
      debugPrint("Error al detener la alarma: $e");
    }
  }

  /// Libera la memoria del reproductor cuando ya no se usa
  void dispose() {
    _audioPlayer.dispose();
  }
}