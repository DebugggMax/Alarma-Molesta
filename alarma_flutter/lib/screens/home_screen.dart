import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_scheduler_service.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<AlarmModel> _alarms = [];
  final Random _random = Random();
  Timer? _alarmCheckTimer;

  final List<String> _possibleObjects = [
    'Silla', 'Taza', 'Control remoto', 'Botella', 'Teclado',
    'Almohada', 'Mochila', 'Llaves', 'Zapatilla', 'Plátano'
  ];

  @override
  void initState() {
    super.initState();
    _startAlarmVigilante();
  }

  // Vigila el reloj cuando la app está abierta en primer plano
  void _startAlarmVigilante() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = TimeOfDay.now();

      for (var alarm in _alarms) {
        if (alarm.isActive &&
            alarm.time.hour == now.hour &&
            alarm.time.minute == now.minute) {

          setState(() {
            alarm.isActive = false;
          });

          // Cancelamos también en el scheduler nativo para no disparar dos veces
          final alarmId = int.tryParse(alarm.id) ?? 0;
          AlarmSchedulerService.cancelAlarm(alarmId);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(targetObject: alarm.targetObject),
            ),
          );

          break;
        }
      }
    });
  }

  @override
  void dispose() {
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
      final alarmId = DateTime.now().millisecondsSinceEpoch % 100000;

      // Programamos en el scheduler nativo para background/pantalla apagada
      await AlarmSchedulerService.scheduleAlarm(
        alarmId: alarmId,
        time: pickedTime,
        targetObject: randomObject,
      );

      setState(() {
        _alarms.add(
          AlarmModel(
            id: alarmId.toString(),
            time: pickedTime,
            targetObject: randomObject,
          ),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarma programada. Misión: "$randomObject"'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    }
  }

  Future<void> _toggleAlarm(AlarmModel alarm, bool value) async {
    final alarmId = int.tryParse(alarm.id) ?? 0;

    if (value) {
      await AlarmSchedulerService.scheduleAlarm(
        alarmId: alarmId,
        time: alarm.time,
        targetObject: alarm.targetObject,
      );
    } else {
      await AlarmSchedulerService.cancelAlarm(alarmId);
    }

    setState(() {
      alarm.isActive = value;
    });
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
                'No tienes alarmas programadas.\nPresiona el botón de abajo para añadir una.',
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
                      onChanged: (value) => _toggleAlarm(alarm, value),
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