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

  //  Matriz estricta de tolerancia dinámica objeto por objeto
  final Map<String, double> _umbralesPorObjeto = {
    'Silla': 0.60,          // Muebles cúbicos confunden al modelo fácilmente
    'Taza': 0.45,           // Son pequeñas y el usuario suele cubrirlas con la mano
    'Control remoto': 0.55, // Estándar moderado
    'Botella': 0.50,        // Estándar equilibrado
    'Teclado': 0.65,        // Exigente: Evita falsas lecturas con texturas de líneas paralelas
    'Almohada': 0.60,       // Exigente: Se confunde con sábanas o ropa arrugada
    'Mochila': 0.55,        // Estándar moderado
    'Llaves': 0.60,         // Exigente: Evita que cualquier metal pequeño apruebe la misión
    'Zapatilla': 0.55,      // Estándar equilibrado
    'Plátano': 0.65,        // Alto: Debe certificar un plátano real y no cualquier comida
  };

  MlService() {
    // ✅ Bajamos el umbral nativo a 0.0 para controlarlo dinámicamente en código
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.0));
  }

  /// PROCESA EL FRAME: Convierte los bytes de la cámara y evalúa victoria
  Future<MlResult> processFrame(CameraImage image, int sensorOrientation, String targetObject) async {
    if (_isBusy) return MlResult(label: "Procesando...", isMatch: false);
    _isBusy = true;

    try {
      final InputImage? inputImage = _buildInputImage(image, sensorOrientation);
      if (inputImage == null) {
        return MlResult(label: "Preparando cámara...", isMatch: false);
      }

      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);

      if (labels.isEmpty) {
        return MlResult(label: "Buscando...", isMatch: false);
      }

      // ✅ Mostramos el objeto detectado principal junto a su porcentaje real de confianza
      final primaryLabel = labels.first;
      final topLabelWithConfidence = "${primaryLabel.label} (${(primaryLabel.confidence * 100).toStringAsFixed(0)}%)";
      
      // ✅ Evaluamos la coincidencia inyectando el valor numérico de confianza
      final bool isMatch = labels.any((label) => _checkMatch(label.label, label.confidence, targetObject));

      return MlResult(label: topLabelWithConfidence, isMatch: isMatch);
    } catch (e) {
      debugPrint("XXXX MlService Error: $e");
      return MlResult(label: "Error de lectura", isMatch: false);
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, int sensorOrientation) {
    if (Platform.isIOS) {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    final int width = image.width;
    final int height = image.height;

    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    final Uint8List yPlane = image.planes[0].bytes;
    final int yRowStride = image.planes[0].bytesPerRow;

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        nv21[row * width + col] = yPlane[row * yRowStride + col];
      }
    }

    if (image.planes.length >= 3) {
      final Uint8List uPlane = image.planes[1].bytes;
      final Uint8List vPlane = image.planes[2].bytes;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerRow ~/ (width ~/ 2);

      int uvIndex = ySize;
      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int uvOffset = row * uvRowStride + col * uvPixelStride;
          if (uvIndex + 1 < nv21.length && uvOffset < vPlane.length && uvOffset < uPlane.length) {
            nv21[uvIndex++] = vPlane[uvOffset];
            nv21[uvIndex++] = uPlane[uvOffset];
          }
        }
      }
    }

    final InputImageRotation rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg;

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  /// ✅ TRADUCTOR OPTIMIZADO: Evalúa certeza individual y limpia términos ambiguos
  bool _checkMatch(String detected, double confidence, String target) {
    final String detectedLower = detected.toLowerCase();
    
    // Filtro inmediato de confianza según el objeto seleccionado
    double umbralRequerido = _umbralesPorObjeto[target] ?? 0.50;
    if (confidence < umbralRequerido) {
      return false; 
    }

    switch (target) {
      case 'Silla':
        return detectedLower.contains('chair') ||
            detectedLower.contains('seat') ||
            detectedLower.contains('stool') ||
            detectedLower.contains('armchair');

      case 'Taza':
        return detectedLower.contains('cup') ||
            detectedLower.contains('mug') ||
            detectedLower.contains('coffee cup');

      case 'Control remoto':
        return detectedLower.contains('remote') ||
            detectedLower.contains('remote control') ||
            detectedLower.contains('clicker');

      case 'Botella':
        return detectedLower.contains('bottle') ||
            detectedLower.contains('water bottle') ||
            detectedLower.contains('plastic bottle');

      case 'Teclado':
        return detectedLower.contains('keyboard') ||
            detectedLower.contains('computer keyboard');

      case 'Almohada':
        return detectedLower.contains('pillow') ||
            detectedLower.contains('cushion') ||
            detectedLower.contains('throw pillow');

      case 'Mochila':
        return detectedLower.contains('backpack') ||
            detectedLower.contains('rucksack') ||
            detectedLower.contains('satchel');

      case 'Llaves':
        return detectedLower.contains('key') ||
            detectedLower.contains('keys') ||
            detectedLower.contains('keychain');

      case 'Zapatilla':
        return detectedLower.contains('shoe') ||
            detectedLower.contains('sneaker') ||
            detectedLower.contains('footwear') ||
            detectedLower.contains('running shoe');

      case 'Plátano':
        return detectedLower.contains('banana');

      default:
        return detectedLower == target.toLowerCase();
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}