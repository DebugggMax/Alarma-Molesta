import 'dart:async';
import 'dart:math';
import 'dart:convert'; // IMPORTANTE: Para empaquetar en JSON
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANTE: Para el caché
import 'package:alarm/alarm.dart';
// Modelos polimórficos
import '../models/alarma_base.dart';
import '../models/alarma_mision.dart';
import '../models/alarma_remedio.dart';

// Servicio nativo
import '../services/alarm_scheduler_service.dart';
import 'camera_screen.dart';
import 'remedio_screen.dart';

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

    // 🚨 ESTA ES LA MAGIA: Escucha si una alarma suena estando la app cerrada o abierta
    Alarm.ringStream.stream.listen((alarmSettings) {
      // Buscamos qué alarma sonó para saber qué objeto era (Misión o Remedio)
      final alarmaSonando = _alarms.firstWhere(
        (a) => a.id == alarmSettings.id.toString(),
        // Si no la encuentra, devuelve un objeto vacío de seguridad
        orElse: () => AlarmaMision(id: '0', time: TimeOfDay.now(), title: '', targetObject: 'Objeto'),
      );

      // Si es una Misión, abrimos la cámara
      if (alarmaSonando is AlarmaMision) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(targetObject: alarmaSonando.targetObject),
          ),
        );
      } 
      // Si es un Remedio, abrimos la pantalla roja
      else if (alarmaSonando is AlarmaRemedio) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RemedioScreen(nombreRemedio: alarmaSonando.title),
          ),
        );
      }
    });
  }

  // 🚨 Recuperar datos del caché
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

  // Guardar datos en el caché
  Future<void> _guardarAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmasString = _alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('mis_alarmas', alarmasString);
  }

  // VERIFICACIÓN ESTRICTA DE PERMISOS XIAOMI
  Future<void> _verificarPermisos() async {
    PermissionStatus statusNotificaciones = await Permission.notification.status;
    PermissionStatus statusAlarmasExactas = await Permission.scheduleExactAlarm.status;
    // Chequeamos también el permiso de superposición (Ventanas en segundo plano)
    bool statusVentanas = await Permission.systemAlertWindow.isGranted;

    if (!statusNotificaciones.isGranted || !statusAlarmasExactas.isGranted || !statusVentanas) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _mostrarPopUpPermisosObligatorio();
      });
    }
  }

  // EL NUEVO POP-UP MAQUIAVÉLICO
  // 🚨 EL NUEVO POP-UP CORREGIDO (YA NO TE ATRAPA)
  void _mostrarPopUpPermisosObligatorio() {
    showDialog(
      context: context,
      barrierDismissible: true, // CAMBIO: Ahora puedes tocar afuera para cerrarlo si molesta
      builder: (context) {
        return AlertDialog( // CAMBIO: Quitamos el PopScope que te impedía salir
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 10),
              Text("Permisos Xiaomi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Para que la alarma encienda la pantalla al estar cerrada, idealmente activa esto en los ajustes de tu celular. Si ya lo hiciste, presiona 'Ignorar' para entrar.",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 15),
                _buildRequirementItem(Icons.looks_one, "Notificaciones y Alarmas Exactas."),
                _buildRequirementItem(Icons.looks_two, "Mostrar en pantalla de bloqueo."),
                _buildRequirementItem(Icons.looks_3, "Abrir nuevas ventanas (Segundo plano)."),
                _buildRequirementItem(Icons.battery_charging_full, "Sin restricciones de batería."),
              ],
            ),
          ),
          actions: [
            // 🚨 NUEVO BOTÓN: Te permite saltarte el cartel si Xiaomi se pone terco
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ignorar / Ya lo activé", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                // Pedimos los permisos nativos estándar de Android
                await Permission.notification.request();
                await Permission.scheduleExactAlarm.request();
                await Permission.ignoreBatteryOptimizations.request();
                
                // Pedimos el permiso de superposición
                if (!await Permission.systemAlertWindow.isGranted) {
                  await Permission.systemAlertWindow.request();
                }

                bool notificacionesOk = await Permission.notification.isGranted;
                bool alarmasOk = await Permission.scheduleExactAlarm.isGranted;
                bool ventanasOk = await Permission.systemAlertWindow.isGranted;

                // Si por milagro Xiaomi responde bien a la primera, se cierra solo
                if (notificacionesOk && alarmasOk && ventanasOk) {
                  if (context.mounted) Navigator.pop(context);
                } else {
                  // Si no, te manda a los ajustes para que verifiques
                  openAppSettings();
                }
              },
              child: const Text("Ir a Configurar"),
            ),
          ],
        );
      }
    );
  }

  // Widget auxiliar para que las instrucciones del Pop-up se vean elegantes
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

  void _startAlarmVigilante() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = TimeOfDay.now();

      for (var alarm in _alarms) {
        if (alarm.isActive &&
            alarm.time.hour == now.hour &&
            alarm.time.minute == now.minute) {

          final alarmId = int.tryParse(alarm.id) ?? 0;
          AlarmSchedulerService.cancelAlarm(alarmId);

          if (alarm is AlarmaMision) {
            setState(() {
              alarm.isActive = false;
            });
            _guardarAlarmas(); // Guarda que se apagó

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(targetObject: alarm.targetObject),
              ),
            );
          } else if (alarm is AlarmaRemedio) {
            final nuevaHora = (alarm.time.hour + alarm.intervaloHoras) % 24;
            final nuevoTime = TimeOfDay(hour: nuevaHora, minute: alarm.time.minute);

            setState(() {
              alarm.time = nuevoTime; 
            });
            _guardarAlarmas(); // Guarda la nueva hora reprogramada

            AlarmSchedulerService.scheduleAlarm(
              alarmId: alarmId,
              time: nuevoTime,
              targetObject: alarm.title,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RemedioScreen(nombreRemedio: alarm.title),
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

      await AlarmSchedulerService.scheduleAlarm(
        alarmId: alarmId,
        time: pickedTime,
        targetObject: randomObject,
      );

      setState(() {
        _alarms.add(
          AlarmaMision(
            id: alarmId.toString(),
            time: pickedTime,
            title: "Despertador",
            targetObject: randomObject,
          ),
        );
      });
      _guardarAlarmas(); // Guarda la nueva alarma
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
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la pastilla/remedio',
                        prefixIcon: Icon(Icons.medication),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: horasController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repetir cada X horas (Ej: 8)',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                      leading: const Icon(Icons.access_time, color: Colors.redAccent),
                      title: const Text('Hora de inicio:'),
                      trailing: Text(tiempoSeleccionado.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: tiempoSeleccionado,
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            tiempoSeleccionado = pickedTime;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nombreController.text.isEmpty || horasController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena todos los campos')));
                      return;
                    }

                    int intervalo = int.tryParse(horasController.text) ?? 8;
                    
                    if (alarmaExistente == null) {
                      final alarmId = DateTime.now().millisecondsSinceEpoch % 100000;
                      await AlarmSchedulerService.scheduleAlarm(
                        alarmId: alarmId,
                        time: tiempoSeleccionado,
                        targetObject: nombreController.text, 
                      );

                      setState(() {
                        _alarms.add(
                          AlarmaRemedio(
                            id: alarmId.toString(),
                            time: tiempoSeleccionado,
                            title: nombreController.text,
                            intervaloHoras: intervalo,
                          ),
                        );
                      });
                    } else {
                      setState(() {
                        alarmaExistente.title = nombreController.text;
                        alarmaExistente.intervaloHoras = intervalo;
                        alarmaExistente.time = tiempoSeleccionado;
                      });

                      if (alarmaExistente.isActive) {
                        final alarmId = int.tryParse(alarmaExistente.id) ?? 0;
                        await AlarmSchedulerService.scheduleAlarm(
                          alarmId: alarmId,
                          time: tiempoSeleccionado,
                          targetObject: alarmaExistente.title,
                        );
                      }
                    }
                    
                    _guardarAlarmas(); // Guarda los cambios en el disco
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
      final TimeOfDay? nuevoTime = await showTimePicker(
        context: context,
        initialTime: alarm.time,
        helpText: 'MODIFICAR HORA DE LA MISIÓN',
      );

      if (nuevoTime != null) {
        setState(() {
          alarm.time = nuevoTime;
        });

        if (alarm.isActive) {
          final alarmId = int.tryParse(alarm.id) ?? 0;
          await AlarmSchedulerService.scheduleAlarm(
            alarmId: alarmId,
            time: nuevoTime,
            targetObject: alarm.targetObject,
          );
        }
        _guardarAlarmas(); // 🚨 Guarda la nueva hora
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Misión modificada con éxito")));
      }
    }
  }

  Future<void> _toggleAlarm(Alarma alarm, bool value) async {
    final alarmId = int.tryParse(alarm.id) ?? 0;

    if (value) {
      String target = alarm is AlarmaMision ? alarm.targetObject : alarm.title;
      await AlarmSchedulerService.scheduleAlarm(
        alarmId: alarmId,
        time: alarm.time,
        targetObject: target,
      );
    } else {
      await AlarmSchedulerService.cancelAlarm(alarmId);
    }

    setState(() {
      alarm.isActive = value;
    });
    _guardarAlarmas(); // Guarda el estado prendido/apagado
  }

  // Función para borrar alarmas al deslizar
  void _borrarAlarma(int index) {
    final alarmId = int.tryParse(_alarms[index].id) ?? 0;
    AlarmSchedulerService.cancelAlarm(alarmId);
    
    setState(() {
      _alarms.removeAt(index);
    });
    _guardarAlarmas(); //  Actualiza el disco
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alarmas', style: TextStyle(fontWeight: FontWeight.bold)),
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
                final bool esRemedio = alarm is AlarmaRemedio;

                // Envolvemos la Card en un Dismissible para poder borrar deslizando
                return Dismissible(
                  key: Key(alarm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  onDismissed: (direction) => _borrarAlarma(index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _editarAlarma(alarm), 
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Text(
                          alarm.time.format(context),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: alarm.isActive 
                                ? (esRemedio ? Colors.redAccent : Colors.deepPurple) 
                                : Colors.grey,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                esRemedio ? Icons.medical_services : Icons.psychology, 
                                size: 18, 
                                color: alarm.isActive 
                                    ? (esRemedio ? Colors.redAccent : Colors.deepPurple) 
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  esRemedio 
                                      ? 'Remedio: ${alarm.title} (Cada ${(alarm as AlarmaRemedio).intervaloHoras} hrs)'
                                      : 'Misión: Buscar "${(alarm as AlarmaMision).targetObject}"',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: alarm.isActive ? Colors.black : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Switch(
                          value: alarm.isActive,
                          activeColor: esRemedio ? Colors.redAccent : Colors.deepPurple,
                          onChanged: (value) => _toggleAlarm(alarm, value),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarOpcionesDeAlarma,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Alarma'),
      ),
    );
  }
}