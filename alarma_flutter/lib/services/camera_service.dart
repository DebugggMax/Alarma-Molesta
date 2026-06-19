import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  
  // Getter para que la UI pueda acceder al controlador
  CameraController? get controller => _controller;

  // Lógica de inicialización aislada
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first, // Usa la primera cámara (trasera)
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint("Error en CameraService: $e");
      // Aquí más adelante podríamos manejar errores específicos
    }
  }

  // Lógica de apagado aislada
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}