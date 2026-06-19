import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../services/camera_service.dart';
import '../services/ml_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final MlService _mlService = MlService(); // 1. Instanciamos el servicio de IA
  
  bool _isCameraInitialized = false;
  bool _isBusy = false; // 2. Nuestro semáforo para no saturar la memoria
  String _currentLabel = "Buscando..."; // Texto para mostrar en pantalla

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    await _cameraService.initializeCamera();
    
    if (mounted && _cameraService.controller != null) {
      setState(() {
        _isCameraInitialized = true;
      });

      // 3. Empezamos a capturar el video en vivo frame por frame
      _cameraService.controller!.startImageStream(_processCameraImage);
    }
  }

  // 4. Función que convierte el frame y lo envía a la IA
  Future<void> _processCameraImage(CameraImage image) async {
    // Si la IA ya está procesando una imagen anterior, descartamos esta
    if (_isBusy) return;
    _isBusy = true;

    try {
      // --- CONVERSIÓN DE FORMATO (De CameraImage a InputImage para ML Kit) ---
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Calculamos la rotación según la posición del teléfono
      final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(
              _cameraService.controller!.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      // Formato de imagen (NV21 para Android, BGRA8888 para iOS)
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
      // -----------------------------------------------------------------------

      // 5. Le enviamos la imagen ya convertida a nuestro servicio de IA
      final String? labelDetectado = await _mlService.analyzeImage(inputImage);

      if (labelDetectado != null && mounted) {
        setState(() {
          _currentLabel = labelDetectado;
        });
        
        // Aquí es donde en el futuro validaremos si labelDetectado == _targetObject
        // y apagaremos la alarma.
      }
    } catch (e) {
      debugPrint("Error procesando el frame: $e");
    } finally {
      // 6. ¡Luz verde! La IA terminó, puede recibir la siguiente imagen
      _isBusy = false; 
    }
  }

  @override
  void dispose() {
    // ⚠️ Importante: Detener el stream antes de apagar la cámara y cerrar la IA
    _cameraService.controller?.stopImageStream();
    _cameraService.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneando objeto...'),
        backgroundColor: Colors.black45,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: _isCameraInitialized && _cameraService.controller != null
          ? Stack(
              children: [
                // Vista de la cámara a pantalla completa
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraService.controller!),
                ),
                // Letrero que muestra lo que la IA está viendo en tiempo real
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Veo: $_currentLabel",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
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