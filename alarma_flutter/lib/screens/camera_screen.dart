import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/audio_service.dart';

class CameraScreen extends StatefulWidget {
  final String targetObject;

  const CameraScreen({super.key, required this.targetObject});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final MlService _mlService = MlService();
  final AudioService _audioService = AudioService();

  bool _isCameraInitialized = false;
  bool _isBusy = false;
  String _currentLabel = "Buscando...";

  @override
  void initState() {
    super.initState();
    _setupCameraAndAudio();
  }

 Future<void> _setupCameraAndAudio() async {
    // 1. Inicializamos el hardware de la cámara primero
    await _cameraService.initializeCamera();
    
    if (mounted && _cameraService.controller != null) {
      setState(() {
        _isCameraInitialized = true;
      });
      // 2. Reproducimos el sonido de la alarma EN SEGUNDO PLANO sin esperar a que termine
      
      _audioService.playAlarma();

      // 3. Arrancamos el escaneo de la IA en el mismísimo milisegundo
      _cameraService.controller!.startImageStream(_processCameraImage);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      // --- CONVERSIÓN DE FORMATO A INPUTIMAGE ---
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(
              _cameraService.controller!.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;
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
      // ------------------------------------------

      final String? labelDetectado = await _mlService.analyzeImage(inputImage);

      if (labelDetectado != null && mounted) {
        setState(() {
          _currentLabel = labelDetectado;
        });
        
        if (_isTargetMatched(labelDetectado, widget.targetObject)) {
          await _cameraService.controller?.stopImageStream();
          await _audioService.stopAlarma();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Excelente! Encontraste: ${widget.targetObject}. Alarma apagada. ☀️'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error procesando el frame: $e");
    } finally {
      _isBusy = false; 
    }
  }

  bool _isTargetMatched(String detected, String target) {
    final String detectedLower = detected.toLowerCase();
    switch (target) {
      case 'Silla':
        return detectedLower.contains('chair') || detectedLower.contains('seat');
      case 'Taza':
        return detectedLower.contains('cup') || detectedLower.contains('mug');
      case 'Control remoto':
        return detectedLower.contains('remote') || detectedLower.contains('controller');
      case 'Botella':
        return detectedLower.contains('bottle');
      case 'Teclado':
        return detectedLower.contains('keyboard');
      case 'Almohada':
        return detectedLower.contains('pillow');
      case 'Mochila':
        return detectedLower.contains('backpack') || detectedLower.contains('bag');
      case 'Llaves':
        return detectedLower.contains('key');
      case 'Zapatilla':
        return detectedLower.contains('shoe') || detectedLower.contains('sneaker');
      case 'Plátano':
        return detectedLower.contains('banana');
      default:
        return detectedLower == target.toLowerCase();
    }
  }

  @override
  void dispose() {
    _cameraService.controller?.stopImageStream();
    _cameraService.dispose();
    _mlService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hacemos el AppBar completamente transparente para que la cámara use toda la pantalla
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: _isCameraInitialized && _cameraService.controller != null
          ? Stack(
              children: [
                // 1. Vista de la cámara de fondo
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraService.controller!),
                ),

                // 2. ✨ NUEVO: El objeto a fotografiar "arribita en pequeño" coincidiendo con el Home
                Positioned(
                  top: kToolbarHeight + 20, // Justo debajo de los botones del AppBar
                  left: 30,
                  right: 30,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.85), // Fondo morado semitransparente
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Objetivo: ${widget.targetObject}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Letrero inferior que muestra lo que ve la IA actualmente
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Veo: $_currentLabel",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
    );
  }
}