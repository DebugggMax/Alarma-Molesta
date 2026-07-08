import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/audio_service.dart';

class CameraScreen extends StatefulWidget {
  final String targetObject;
  final String? remedioName;

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
  bool _isProcessingFrame = false; // ✅ Bloquea el botón mientras analiza
  String _currentLabel = "Apunta al objeto y captura la foto";

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
  }

  // ✅ NUEVA FUNCIÓN: Captura un único fotograma bajo demanda controlada
  Future<void> _capturarYAnalizar() async {
    if (_isProcessingFrame || _cameraService.controller == null) return;

    setState(() {
      _isProcessingFrame = true;
      _currentLabel = "Analizando captura...";
    });

    bool fotogramaTomado = false;

    try {
      // Abrimos el canal del stream de la cámara por un único instante
      await _cameraService.controller!.startImageStream((CameraImage image) async {
        if (fotogramaTomado) return;
        fotogramaTomado = true;

        // ✅ Congelamos/Detenemos el flujo inmediatamente
        await _cameraService.controller!.stopImageStream();

        // Procesamos ese único fotograma capturado
        final result = await _mlService.processFrame(
          image, 
          _cameraService.controller!.description.sensorOrientation, 
          widget.targetObject
        );

        if (!mounted) return;

        if (result.isMatch) {
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
        } else {
          setState(() {
            _isProcessingFrame = false;
            _currentLabel = "No coincide. ¡Intenta de nuevo!\n(Visto: ${result.label})";
          });
        }
      });
    } catch (e) {
      setState(() {
        _isProcessingFrame = false;
        _currentLabel = "Error al procesar el fotograma instantáneo.";
      });
    }
  }

  @override
  void dispose() {
    // Protección extra por si se cierra la pantalla a la fuerza
    try { _cameraService.controller?.stopImageStream(); } catch (_) {}
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
                
                // Píldora superior informativa
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (esRemedio) ...[
                            Text(
                              '💊 Remedio: ${widget.remedioName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            '🔍 Misión: Buscar "${widget.targetObject}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Lector inferior e instrucciones
                Positioned(
                  bottom: 140,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // ✅ BOTÓN DE CAPTURA ESTILO OBTURADOR NATIVO
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessingFrame ? null : _capturarYAnalizar,
                      child: Container(
                        height: 80,
                        width: 80,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessingFrame ? Colors.grey : (esRemedio ? Colors.redAccent : Colors.deepPurple),
                          ),
                          child: _isProcessingFrame 
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
    );
  }
}