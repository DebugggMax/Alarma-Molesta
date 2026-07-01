import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import '../models/alarma_base.dart';
import '../models/alarma_mision.dart';
import '../models/alarma_remedio.dart';
import '../services/alarm_scheduler_service.dart'; 

import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Alarma> _alarms = [];
  final Random _random = Random();
  Timer? _alarmCheckTimer;

  final List<String> _possibleObjects = [
    'Silla', 'Taza', 'Control remoto', 'Botella', 'Teclado',
    'Almohada', 'Mochila', 'Llaves', 'Zapatilla', 'Plátano'
  ];

  @override
  void initState() {
    super.initState();
    _verificarPermisos(); 
    _cargarAlarmas(); 
    _startAlarmVigilante(); 
  }

  Future<void> _verificarPermisos() async {
    bool statusNotificaciones = await Permission.notification.isGranted;
    bool statusExactAlarm = await Permission.scheduleExactAlarm.isGranted;
    bool statusBateria = await Permission.ignoreBatteryOptimizations.isGranted;

    if (!statusNotificaciones || !statusExactAlarm || !statusBateria) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _mostrarPopUpPermisosObligatorio();
      });
    }
  }

  void _mostrarPopUpPermisosObligatorio() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 10),
              Text("Permisos Requeridos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Para que la alarma suene en segundo plano y con la pantalla apagada, necesitamos estos permisos:",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 15),
                _buildRequirementItem(Icons.notifications_active, "1. Mostrar notificaciones."),
                _buildRequirementItem(Icons.alarm_on, "2. Programar alarmas exactas."),
                _buildRequirementItem(Icons.battery_alert, "3. Ignorar ahorro de batería."),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await Permission.notification.request();
                await Permission.scheduleExactAlarm.request();
                await Permission.ignoreBatteryOptimizations.request();

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Otorgar Permisos"),
            ),
          ],
        );
      }
    );
  }

  Widget _buildRequirementItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _cargarAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmasGuardadas = prefs.getStringList('mis_alarmas') ?? [];
    
    setState(() {
      _alarms.clear();
      for (String item in alarmasGuardadas) {
        final Map<String, dynamic> data = jsonDecode(item);
        if (data['type'] == 'mision') {
          _alarms.add(AlarmaMision.fromJson(data));
        } else if (data['type'] == 'remedio') {
          _alarms.add(AlarmaRemedio.fromJson(data));
        }
      }
    });
  }

  Future<void> _guardarAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmasString = _alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('mis_alarmas', alarmasString);
  }

  void _startAlarmVigilante() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = TimeOfDay.now();

      for (var alarm in _alarms) {
        if (alarm.isActive &&
            alarm.time.hour == now.hour &&
            alarm.time.minute == now.minute) {

          if (alarm is AlarmaMision) {
            setState(() => alarm.isActive = false);
            _guardarAlarmas(); 

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraScreen(targetObject: alarm.targetObject)),
            );
          } else if (alarm is AlarmaRemedio) {
            final nuevaHora = (alarm.time.hour + alarm.intervaloHoras) % 24;
            setState(() => alarm.time = TimeOfDay(hour: nuevaHora, minute: alarm.time.minute));
            _guardarAlarmas(); 

            // 🎲 CORRECCIÓN: Seleccionamos un objeto random de la lista de forma dinámica
            final randomObject = _possibleObjects[_random.nextInt(_possibleObjects.length)];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(
                  targetObject: randomObject,
                  remedioName: alarm.title, 
                ),
              ),
            );
          }
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

  void _mostrarOpcionesDeAlarma() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.psychology, color: Colors.deepPurple),
                title: const Text('Crear Alarma Misión'),
                onTap: () {
                  Navigator.pop(context);
                  _crearAlarmaMision();
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.redAccent),
                title: const Text('Crear Alarma Remedio'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarFormularioRemedio();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _crearAlarmaMision() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECCIONA LA HORA DE LA MISIÓN',
    );

    if (pickedTime != null) {
      final randomObject = _possibleObjects[_random.nextInt(_possibleObjects.length)];
      final alarmId = DateTime.now().millisecondsSinceEpoch % 100000;

      setState(() {
        _alarms.add(
          AlarmaMision(id: alarmId.toString(), time: pickedTime, title: "Despertador", targetObject: randomObject),
        );
      });
      _guardarAlarmas();
      
      AlarmSchedulerService.scheduleAlarm(alarmId: alarmId, time: pickedTime, targetObject: randomObject);
    }
  }

  Future<void> _mostrarFormularioRemedio({AlarmaRemedio? alarmaExistente}) async {
    final TextEditingController nombreController = TextEditingController(text: alarmaExistente?.title ?? '');
    final TextEditingController horasController = TextEditingController(text: alarmaExistente != null ? alarmaExistente.intervaloHoras.toString() : '');
    TimeOfDay tiempoSeleccionado = alarmaExistente?.time ?? TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(alarmaExistente == null ? 'Nuevo Remedio' : 'Editar Remedio', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre de la pastilla', prefixIcon: Icon(Icons.medication)), textCapitalization: TextCapitalization.sentences),
                    const SizedBox(height: 10),
                    TextField(controller: horasController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repetir cada X horas', prefixIcon: Icon(Icons.repeat))),
                    const SizedBox(height: 20),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                      leading: const Icon(Icons.access_time, color: Colors.redAccent),
                      title: const Text('Hora de inicio:'),
                      trailing: Text(tiempoSeleccionado.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: tiempoSeleccionado);
                        if (pickedTime != null) setStateDialog(() => tiempoSeleccionado = pickedTime);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nombreController.text.isEmpty || horasController.text.isEmpty) return;

                    int intervalo = int.tryParse(horasController.text) ?? 8;
                    final alarmId = DateTime.now().millisecondsSinceEpoch % 100000;
                    
                    if (alarmaExistente == null) {
                      setState(() => _alarms.add(AlarmaRemedio(id: alarmId.toString(), time: tiempoSeleccionado, title: nombreController.text, intervaloHoras: intervalo)));
                    } else {
                      setState(() {
                        alarmaExistente.title = nombreController.text;
                        alarmaExistente.intervaloHoras = intervalo;
                        alarmaExistente.time = tiempoSeleccionado;
                      });
                    }
                    _guardarAlarmas(); 
                    
                    AlarmSchedulerService.scheduleAlarm(alarmId: alarmId, time: tiempoSeleccionado, targetObject: "Remedio: ${nombreController.text}");
                    
                    Navigator.pop(context); 
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _editarAlarma(Alarma alarm) async {
    if (alarm is AlarmaRemedio) {
      await _mostrarFormularioRemedio(alarmaExistente: alarm);
    } else if (alarm is AlarmaMision) {
      final TimeOfDay? nuevoTime = await showTimePicker(context: context, initialTime: alarm.time, helpText: 'MODIFICAR HORA DE LA MISIÓN');
      if (nuevoTime != null) {
        setState(() => alarm.time = nuevoTime);
        _guardarAlarmas();
        
        AlarmSchedulerService.cancelAlarm(int.parse(alarm.id));
        AlarmSchedulerService.scheduleAlarm(alarmId: int.parse(alarm.id), time: nuevoTime, targetObject: alarm.targetObject);
      }
    }
  }

  Future<void> _toggleAlarm(Alarma alarm, bool value) async {
    setState(() => alarm.isActive = value);
    _guardarAlarmas(); 
    
    if (value) {
      if (alarm is AlarmaMision) {
        AlarmSchedulerService.scheduleAlarm(alarmId: int.parse(alarm.id), time: alarm.time, targetObject: alarm.targetObject);
      } else if (alarm is AlarmaRemedio) {
        AlarmSchedulerService.scheduleAlarm(alarmId: int.parse(alarm.id), time: alarm.time, targetObject: "Remedio");
      }
    } else {
      AlarmSchedulerService.cancelAlarm(int.parse(alarm.id));
    }
  }

  void _borrarAlarma(int index) {
    AlarmSchedulerService.cancelAlarm(int.parse(_alarms[index].id));
    setState(() => _alarms.removeAt(index));
    _guardarAlarmas(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Alarmas', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 2),
      body: _alarms.isEmpty
          ? const Center(child: Text('No tienes alarmas programadas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                final bool esRemedio = alarm is AlarmaRemedio;

                return Dismissible(
                  key: Key(alarm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: Colors.white, size: 30)),
                  onDismissed: (direction) => _borrarAlarma(index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _editarAlarma(alarm), 
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        title: Text(alarm.time.format(context), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: alarm.isActive ? (esRemedio ? Colors.redAccent : Colors.deepPurple) : Colors.grey)),
                        subtitle: Row(
                          children: [
                            Icon(esRemedio ? Icons.medical_services : Icons.psychology, size: 18, color: alarm.isActive ? (esRemedio ? Colors.redAccent : Colors.deepPurple) : Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(child: Text(esRemedio ? 'Remedio: ${alarm.title}' : 'Misión: Buscar "${(alarm as AlarmaMision).targetObject}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: alarm.isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.w500))),
                          ],
                        ),
                        // 🛠️ BOTÓN DE BORRAR INTEGRADO JUNTO AL SWITCH
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("¿Borrar alarma?"),
                                      content: const Text("Esta acción eliminará la alarma de forma permanente."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _borrarAlarma(index);
                                          },
                                          child: const Text("Borrar", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            Switch(value: alarm.isActive, activeColor: esRemedio ? Colors.redAccent : Colors.deepPurple, onChanged: (value) => _toggleAlarm(alarm, value)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _mostrarOpcionesDeAlarma, backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('Nueva Alarma')),
    );
  }
}