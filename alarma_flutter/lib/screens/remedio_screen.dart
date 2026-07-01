import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart'; 
import '../services/audio_service.dart'; // ✅ Volvemos a traer tu audio

class RemedioScreen extends StatefulWidget {
  final String nombreRemedio;

  const RemedioScreen({super.key, required this.nombreRemedio});

  @override
  State<RemedioScreen> createState() => _RemedioScreenState();
}

class _RemedioScreenState extends State<RemedioScreen> {
  // ✅ Instanciamos de nuevo tu servicio
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _iniciarSonidoLocal();
  }

  // 🔥 EL RELEVO DE SONIDO
  Future<void> _iniciarSonidoLocal() async {
    // 1. Matamos la alarma nativa por si seguía sonando de fondo (evita el sonido doble)
    await Alarm.stopAll();
    // 2. Encendemos tu sonido para asegurar que esta pantalla haga ruido
    await _audioService.playAlarma();
  }

  @override
  void dispose() {
    _audioService.dispose(); // Limpiamos memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              const Text(
                "¡HORA DE TU REMEDIO!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.nombreRemedio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text(
                  "Ya me lo tomé",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // ✅ Apagamos tu sonido local
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