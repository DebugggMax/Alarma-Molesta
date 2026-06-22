import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para hablar con el sistema nativo
import 'screens/home_screen.dart';

void main() async {
  // Asegura que Flutter esté listo antes de llamar a Android/iOS
  WidgetsFlutterBinding.ensureInitialized();

  // Prepara la pantalla de Android
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const AlarmaApp());
}

class AlarmaApp extends StatelessWidget {
  const AlarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despertador Pesado',
      debugShowCheckedModeBanner: false, // Corregido: devuelto a su estado original
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(), 
    );
  }
}