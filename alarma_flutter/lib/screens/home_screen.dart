import 'dart:math'; // Dejamos solo uno de los imports
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<AlarmModel> _alarms = [];
  
  // 1. ✨ INSTANCIA ÚNICA: Creamos el generador aquí arriba para que tenga memoria de secuencia
  final Random _random = Random();
  
  // 2. ✨ MÁS VARIEDAD: Ampliamos la lista para bajar drásticamente las repeticiones
  final List<String> _possibleObjects = [
    'Silla', 
    'Taza', 
    'Control remoto', 
    'Botella',
    'Teclado',
    'Almohada',
    'Mochila',
    'Llaves',
    'Zapatilla',
    'Plátano'
  ];

  // 🕒 FUNCIÓN POP-UP: Abre el reloj gigante y añade la alarma a la lista
  Future<void> _openTimePickerPopUp(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECCIONA LA HORA DE TU ALARMA',
    );

    if (pickedTime != null) {
      // 3. ✨ SOLUCIÓN: Usamos '_random' (con minúscula) para usar la secuencia global ordenada
      final randomObject = _possibleObjects[_random.nextInt(_possibleObjects.length)];

      setState(() {
        _alarms.add(
          AlarmModel(
            id: DateTime.now().toString(), 
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
                    
                    title: Text(
                      alarm.time.format(context),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: alarm.isActive ? Colors.deepPurple : Colors.grey,
                      ),
                    ),
                    
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
                    
                    trailing: Switch(
                      value: alarm.isActive,
                      activeColor: Colors.deepPurple,
                      onChanged: (value) {
                        setState(() {
                          alarm.isActive = value;
                        });
                        
                        if (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(targetObject: alarm.targetObject),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),

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