import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Clase auxiliar para empaquetar la respuesta del escaneo
class MlResult {
  final String label;
  final bool isMatch;
  MlResult({required this.label, required this.isMatch});
}

class MlService {
  late ImageLabeler _imageLabeler;
  bool _isBusy = false;

  MlService() {
    // Inicializamos el detector con un 70% de confianza mínima
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.7));
  }

  /// ⚙️ PROCESA EL FRAME: Convierte los bytes de la cámara y evalúa victoria
  Future<MlResult> processFrame(CameraImage image, int sensorOrientation, String targetObject) async {
    if (_isBusy) return MlResult(label: "Procesando...", isMatch: false);
    _isBusy = true;

    try {
      // 1. Conversión interna de bytes aislada de la UI
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? 
          (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      // 2. Procesamiento del detector de Google
      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
      
      if (labels.isEmpty) {
        return MlResult(label: "Buscando...", isMatch: false);
      }

      final topLabel = labels.first.label;
      final bool isMatch = _checkMatch(topLabel, targetObject);

      return MlResult(label: topLabel, isMatch: isMatch);
    } catch (e) {
      debugPrint("❌ MlService Error: $e");
      return MlResult(label: "Error de lectura", isMatch: false);
    } finally {
      _isBusy = false;
    }
  }

  /// 🗣️ TRADUCTOR: Compara lo detectado en inglés con el objetivo en español
  bool _checkMatch(String detected, String target) {
    final String detectedLower = detected.toLowerCase();
    switch (target) {
      case 'Silla': return detectedLower.contains('chair') || detectedLower.contains('seat');
      case 'Taza': return detectedLower.contains('cup') || detectedLower.contains('mug');
      case 'Control remoto': return detectedLower.contains('remote') || detectedLower.contains('controller');
      case 'Botella': return detectedLower.contains('bottle');
      case 'Teclado': return detectedLower.contains('keyboard');
      case 'Almohada': return detectedLower.contains('pillow');
      case 'Mochila': return detectedLower.contains('backpack') || detectedLower.contains('bag');
      case 'Llaves': return detectedLower.contains('key');
      case 'Zapatilla': return detectedLower.contains('shoe') || detectedLower.contains('sneaker');
      case 'Plátano': return detectedLower.contains('banana');
      default: return detectedLower == target.toLowerCase();
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}