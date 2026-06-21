import 'dart:math';
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Nuestra lista dinámica de alarmas (empieza vacía)
  final List<AlarmModel> _alarms = [];
  
  // Lista de objetos aleatorios para las misiones de la IA
  final List<String> _possibleObjects = ['Silla', 'Taza', 'Control remoto', 'Botella'];

  // 🕒 FUNCIÓN POP-UP: Abre el reloj gigante y añade la alarma a la lista
  Future<void> _openTimePickerPopUp(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECCIONA LA HORA DE TU ALARMA',
    );

    if (pickedTime != null) {
      // Elegimos un objeto al azar de la lista para la misión
      final randomObject = _possibleObjects[Random().nextInt(_possibleObjects.length)];

      setState(() {
        _alarms.add(
          AlarmModel(
            id: DateTime.now().toString(), // ID único basado en el milisegundo actual
            time: pickedTime,
            targetObject: randomObject,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alarmas IA', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      
      // Si no hay alarmas, mostramos un letrero bonito. Si hay, mostramos la lista.
      body: _alarms.isEmpty
          ? const Center(
              child: Text(
                'No tienes alarmas programadas.\nPresiona el botón de abajo para añadir una. ⏰',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    
                    // Hora de la alarma en grande
                    title: Text(
                      alarm.time.format(context),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: alarm.isActive ? Colors.deepPurple : Colors.grey,
                      ),
                    ),
                    
                    // Misión asignada debajo de la hora
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, size: 18, color: Colors.deepPurple),
                          const SizedBox(width: 6),
                          Text(
                            'Misión: Buscar "${alarm.targetObject}"',
                            style: TextStyle(
                              color: alarm.isActive ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // El interruptor (Switch) para activar/desactivar
                    trailing: Switch(
                      value: alarm.isActive,
                      activeColor: Colors.deepPurple,
                      onChanged: (value) {
                        setState(() {
                          alarm.isActive = value;
                        });
                        
                        // SIMULACIÓN: Si el usuario enciende la alarma, simulamos que suena mandándolo a la cámara
                        if (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CameraScreen()),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),

      // ➕ Botón Flotante para añadir alarmas (esquinas redondeadas estilo Material 3)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTimePickerPopUp(context),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Alarma'),
      ),
    );
  }
}