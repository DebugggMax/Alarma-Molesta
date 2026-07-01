import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:alarm/alarm.dart'; 
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/audio_service.dart'; // ✅ Vuelve el audio

class CameraScreen extends StatefulWidget {
  final String targetObject;
  const CameraScreen({super.key, required this.targetObject});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final MlService _mlService = MlService();
  final AudioService _audioService = AudioService(); // ✅ Instanciamos

  bool _isCameraInitialized = false;
  String _currentLabel = "Cargando misión...";
  
  DateTime? _lastProcessedTime;

  @override
  void initState() {
    super.initState();
    _startMission();
  }

  Future<void> _startMission() async {
    await _cameraService.initializeCamera();
    if (!mounted || _cameraService.controller == null) return;

    setState(() {
      _isCameraInitialized = true;
    });

    // 🔥 DETONADOR DEL AUDIO Y RELEVO: 
    await Alarm.stopAll(); // Matamos el nativo para evitar doble sonido
    await _audioService.playAlarma(); // Prendemos tu alarma manual molesta
    await Future.delayed(const Duration(milliseconds: 500));

    _cameraService.controller!.startImageStream((CameraImage image) async {
      final now = DateTime.now();
      
      if (_lastProcessedTime != null && now.difference(_lastProcessedTime!).inMilliseconds < 350) {
        return;
      }
      _lastProcessedTime = now;

      final result = await _mlService.processFrame(
        image, 
        _cameraService.controller!.description.sensorOrientation, 
        widget.targetObject
      );

      if (!mounted) return;

      setState(() {
        _currentLabel = result.label;
      });

      if (result.isMatch) {
        await _cameraService.controller?.stopImageStream();
        
        // ✅ Apagamos el sonido manual al ganar
        await _audioService.stopAlarma();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Excelente! Encontraste: ${widget.targetObject}. Alarma apagada. ☀️'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _cameraService.controller?.stopImageStream();
    _cameraService.dispose();
    _mlService.dispose();
    _audioService.dispose(); // ✅ Limpiamos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraService.controller!),
                ),
                Positioned(
                  top: kToolbarHeight + 20,
                  left: 30,
                  right: 30,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Objetivo: ${widget.targetObject}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
    );
  }
}