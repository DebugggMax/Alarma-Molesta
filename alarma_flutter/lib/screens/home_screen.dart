import 'dart:async'; // 1. IMPORTANTE: Necesario para usar el Timer (reloj interno)
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
  final List<AlarmModel> _alarms = [];
  final Random _random = Random();
  
  // 2. Definimos el temporizador que vigilará el reloj del celular
  Timer? _alarmCheckTimer;

  final List<String> _possibleObjects = [
    'Silla', 'Taza', 'Control remoto', 'Botella', 'Teclado',
    'Almohada', 'Mochila', 'Llaves', 'Zapatilla', 'Plátano'
  ];

  @override
  void initState() {
    super.initState();
    // 3. En cuanto abre la app, activamos el vigilante de alarmas
    _startAlarmVigilante();
  }

  // 4. Esta función corre en silencio cada 5 segundos revisando si ya es la hora
  void _startAlarmVigilante() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = TimeOfDay.now();
      
      for (var alarm in _alarms) {
        // SI la alarma está encendida Y coincide exactamente la hora y el minuto...
        if (alarm.isActive && 
            alarm.time.hour == now.hour && 
            alarm.time.minute == now.minute) {
          
          // A. Desactivamos la alarma primero para que no se vuelva a disparar en bucle
          setState(() {
            alarm.isActive = false;
          });

          // B. ¡FUEGO! Disparamos la pantalla de la cámara automáticamente
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(targetObject: alarm.targetObject),
            ),
          );
          
          break; // Rompemos el ciclo para evitar abrir múltiples cámaras si coinciden
        }
      }
    });
  }

  @override
  void dispose() {
    // ⚠️ Siempre cancelamos el timer al salir de la pantalla para no gastar batería
    _alarmCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _openTimePickerPopUp(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECCIONA LA HORA DE TU ALARMA',
    );

    if (pickedTime != null) {
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
                        // 5. El Switch ahora SOLO guarda si la alarma está prendida o apagada.
                        // Ya no te manda a la cámara de inmediato. El Timer hará ese trabajo.
                        setState(() {
                          alarm.isActive = value;
                        });
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