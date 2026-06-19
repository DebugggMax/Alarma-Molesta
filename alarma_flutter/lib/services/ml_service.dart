import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MlService {
  late final ImageLabeler _imageLabeler;

  MlService() {
    // Inicializamos el reconocedor de imágenes con un umbral de confianza.
    // confidenceThreshold: 0.70 significa que solo nos devolverá etiquetas 
    // de las que esté al menos un 70% seguro para evitar falsos positivos.
    final options = ImageLabelerOptions(confidenceThreshold: 0.70);
    _imageLabeler = ImageLabeler(options: options);
  }

  /// Recibe una imagen de la cámara y devuelve el nombre del objeto principal
  Future<String?> analyzeImage(InputImage inputImage) async {
    try {
      // Le pasamos la imagen al modelo de ML Kit
      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
      
      // Si no reconoció nada con suficiente confianza, devolvemos null
      if (labels.isEmpty) return null;

      // ML Kit devuelve la lista ordenada de mayor a menor confianza.
      // Por lo tanto, el primer elemento (first) es nuestra mejor predicción.
      final highestConfidenceLabel = labels.first;
      
      debugPrint('Objeto detectado: ${highestConfidenceLabel.label} con ${highestConfidenceLabel.confidence * 100}% de seguridad');
      
      return highestConfidenceLabel.label;
      
    } catch (e) {
      debugPrint("Error procesando la imagen con ML Kit: $e");
      return null;
    }
  }

  /// Vital para liberar memoria cuando cerremos la pantalla de la cámara
  void dispose() {
    _imageLabeler.close();
  }
}