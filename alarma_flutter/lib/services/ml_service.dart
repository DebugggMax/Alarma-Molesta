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
  // Matriz calibrada para la vida real (luz de dormitorio/oficina)
  final Map<String, double> _umbralesPorObjeto = {
    'Silla': 0.45,          
    'Taza': 0.40,           
    'Control remoto': 0.45, 
    'Botella': 0.40,        //  Más permisivo para botellas transparentes/vidrio
    'Teclado': 0.45,        // ⌨ Umbral equilibrado para captar texturas
    'Almohada': 0.45,       
    'Mochila': 0.45,        
    'Llaves': 0.45,         
    'Zapatilla': 0.45,      
    'Plátano': 0.50,        
  };

  MlService() {
    // Bajamos el umbral nativo a 0.0 para controlarlo dinámicamente en código
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

      // Mostramos el objeto detectado principal junto a su porcentaje real de confianza
      final primaryLabel = labels.first;
      final topLabelWithConfidence = "${primaryLabel.label} (${(primaryLabel.confidence * 100).toStringAsFixed(0)}%)";
      
      // Evaluamos la coincidencia inyectando el valor numérico de confianza
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

  ///  TRADUCTOR OPTIMIZADO: Evalúa certeza individual y limpia términos ambiguos
  ///  TRADUCTOR ADAPTATIVO: Absorbe las limitaciones del modelo de Google
  bool _checkMatch(String detected, double confidence, String target) {
    final String detectedLower = detected.toLowerCase();
    
    // Filtro inmediato de confianza según el objeto seleccionado
    double umbralRequerido = _umbralesPorObjeto[target] ?? 0.45;
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
            detectedLower.contains('coffee cup') ||
            detectedLower.contains('tableware'); // Añadido por si se confunde con vajilla

      case 'Control remoto':
        return detectedLower.contains('remote') ||
            detectedLower.contains('remote control') ||
            detectedLower.contains('clicker');

      case 'Botella':
        //  Ahora acepta "container" o "glass", pero SOLO si estás buscando una botella 
        // y con el umbral calibrado, evitando colisiones accidentales.
        return detectedLower.contains('bottle') ||
            detectedLower.contains('water bottle') ||
            detectedLower.contains('plastic bottle') ||
            detectedLower.contains('glass bottle') ||
            detectedLower.contains('container') ||
            detectedLower.contains('liquid');

      case 'Teclado':
        //  Solución al error de Google: Si confunde el teclado con un piano o periférico, lo acepta.
        return detectedLower.contains('keyboard') ||
            detectedLower.contains('computer keyboard') ||
            detectedLower.contains('input device') ||
            detectedLower.contains('space bar') ||
            detectedLower.contains('musical instrument') || 
            detectedLower.contains('piano') ||
            detectedLower.contains('electronic instrument');

      case 'Almohada':
        return detectedLower.contains('pillow') ||
            detectedLower.contains('cushion') ||
            detectedLower.contains('throw pillow');

      case 'Mochila':
        return detectedLower.contains('backpack') ||
            detectedLower.contains('rucksack') ||
            detectedLower.contains('satchel') ||
            detectedLower.contains('bag'); // Volvemos a admitir bag pero protegido por el caso de uso

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