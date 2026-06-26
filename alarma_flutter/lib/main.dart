import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'services/alarm_scheduler_service.dart';

// ✅ Navigator key global para navegar desde fuera del árbol de widgets
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Callback para cuando el usuario toca la notificación con la app cerrada
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint("🔔 Notificación tocada en background: ${notificationResponse.payload}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ✅ Inicializamos el scheduler nativo antes de lanzar la app
  await AlarmSchedulerService.initialize();

  runApp(const AlarmaApp());
}

class AlarmaApp extends StatefulWidget {
  const AlarmaApp({super.key});

  @override
  State<AlarmaApp> createState() => _AlarmaAppState();
}

class _AlarmaAppState extends State<AlarmaApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // ✅ Maneja el tap en la notificación cuando la app estaba en segundo plano o cerrada
    FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final targetObject = response.payload ?? 'Objeto';
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CameraScreen(targetObject: targetObject),
          ),
        );
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Permite navegar desde fuera del árbol
      title: 'Despertador Pesado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}