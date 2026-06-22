import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAlarma() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/alarma.mp3'));
      debugPrint("🔊 AudioService: Alarma iniciada.");
    } catch (e) {
      debugPrint("❌ AudioService Error: $e");
    }
  }

  Future<void> stopAlarma() async {
    try {
      await _audioPlayer.stop();
      debugPrint("🤫 AudioService: Alarma silenciada.");
    } catch (e) {
      debugPrint("❌ AudioService Stop Error: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}