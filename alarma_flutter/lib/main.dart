import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Importamos tu nueva pantalla

void main() {
  runApp(const AlarmaApp());
}

class AlarmaApp extends StatelessWidget {
  const AlarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despertador IA',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Aquí está la magia: conectamos el inicio con tu pantalla
      home: const HomeScreen(), 
    );
  }
}