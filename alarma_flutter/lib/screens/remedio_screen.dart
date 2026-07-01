import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Aunque lo importamos, no usaremos el controller aquí
import '../services/audio_service.dart'; // ✅ Usamos tu servicio de audio original

class RemedioScreen extends StatefulWidget {
  final String nombreRemedio;

  const RemedioScreen({super.key, required this.nombreRemedio});

  @override
  State<RemedioScreen> createState() => _RemedioScreenState();
}

class _RemedioScreenState extends State<RemedioScreen> {
  // ✅ Usamos exclusivamente tu AudioService original
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // 🧹 Limpieza total de cámara en el initState. 
    // Solo activamos tu sonido clásico que funcionaba perfecto.
    _audioService.playAlarma();
  }

  @override
  void dispose() {
    // ✅ Limpiamos el audio al salir
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 DISEÑO RESTAURADO: Fondo rojo sólido, SIN CÁMARA
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Icono grande y limpio en el centro
              const Icon(
                Icons.medical_services,
                size: 140,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              const Text(
                "¡HORA DE TU REMEDIO!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  widget.nombreRemedio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              // ✅ Tu botón original de confirmación
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 22),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 32),
                label: const Text(
                  "Ya me lo tomé",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // ✅ Apagamos tu audio al presionar
                  await _audioService.stopAlarma();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}