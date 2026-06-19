import 'package:flutter/material.dart';
import 'camera_screen.dart'; // Importaremos la pantalla de la cámara

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay? _selectedTime;
  
  // PD: Recordatorio de que más adelante este valor será Random
  final String _targetObject = "Silla"; 

  // Función para abrir el selector de hora nativo
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despertador IA'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECCIÓN DEL RELOJ ---
            Text(
              _selectedTime != null 
                  ? "Alarma programada:\n${_selectedTime!.format(context)}" 
                  : "Sin alarma programada",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _selectTime(context),
              icon: const Icon(Icons.access_time),
              label: const Text('Seleccionar Hora'),
            ),
            
            const Spacer(),

            // --- SECCIÓN DE LA MISIÓN (OBJETO) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade100, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "Objeto a buscar para apagar:",
                    style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _targetObject,
                    style: const TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w900,
                      color: Colors.deepPurple
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // --- BOTÓN GIGANTE ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              onPressed: () {
                // Navegación a la pantalla de la cámara
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              child: const Text(
                'INICIAR ALARMA',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}