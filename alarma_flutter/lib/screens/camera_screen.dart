import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/audio_service.dart';

class CameraScreen extends StatefulWidget {
  final String targetObject;
  final String? remedioName; // ✅ Recibe opcionalmente el nombre del remedio

  const CameraScreen({
    super.key, 
    required this.targetObject, 
    this.remedioName,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final MlService _mlService = MlService();
  final AudioService _audioService = AudioService();

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

    await _audioService.playAlarma();
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
        await _audioService.stopAlarma();

        if (mounted) {
          Navigator.pop(context);
          
          final String mensajeExito = widget.remedioName != null
              ? '¡Excelente! Escaneaste tu ${widget.targetObject}. Ya puedes tomar tu "${widget.remedioName}". 💊'
              : '¡Excelente! Encontraste: ${widget.targetObject}. Alarma apagada. ☀️';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeExito, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: widget.remedioName != null ? Colors.redAccent : Colors.green.shade700,
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
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esRemedio = widget.remedioName != null;

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
                
                // 🛠️ PÍLDORA SUPERIOR REPARADA: Cambiada a Column para evitar superposición
                Positioned(
                  top: kToolbarHeight + 10,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: esRemedio 
                            ? Colors.redAccent.withOpacity(0.9) 
                            : Colors.deepPurple.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Ajuste dinámico sin desbordar
                        children: [
                          // ETIQUETA 1: Solo aparece si es una alarma de tipo remedio
                          if (esRemedio) ...[
                            Text(
                              '💊 Remedio: ${widget.remedioName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6), // Separación limpia y segura
                          ],
                          // ETIQUETA 2: La misión / objeto a escanear (Aparece siempre)
                          Text(
                            '🔍 Misión: Buscar "${widget.targetObject}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w600, 
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Lector inferior
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