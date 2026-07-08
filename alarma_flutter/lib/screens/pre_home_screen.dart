import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class PreHomeScreen extends StatefulWidget {
  const PreHomeScreen({super.key});

  @override
  State<PreHomeScreen> createState() => _PreHomeScreenState();
}

class _PreHomeScreenState extends State<PreHomeScreen> {
  // Lista unificada de objetos que soporta la app
  final Map<String, bool> _listaObjetos = {
    'Silla': true,
    'Taza': true,
    'Control remoto': true,
    'Botella': true,
    'Teclado': true,
    'Almohada': true,
    'Mochila': true,
    'Llaves': true,
    'Zapatilla': true,
    'Plátano': true,
  };

  @override
  void initState() {
    super.initState();
    _cargarSeleccionExistente();
  }

  Future<void> _cargarSeleccionExistente() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? guardados = prefs.getStringList('objetos_disponibles');
    if (guardados != null && guardados.isNotEmpty) {
      setState(() {
        _listaObjetos.updateAll((key, value) => false);
        for (var obj in guardados) {
          if (_listaObjetos.containsKey(obj)) {
            _listaObjetos[obj] = true;
          }
        }
      });
    }
  }

  Future<void> _guardarConfiguracion() async {
    final List<String> seleccionados = _listaObjetos.keys
        .where((key) => _listaObjetos[key] == true)
        .toList();

    if (seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecciona al menos un objeto que tengas en casa.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('objetos_disponibles', seleccionados);
    await prefs.setBool('primer_inicio_completado', true);

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      // Si accedió desde la tuerca de HomeScreen, volvemos atrás refrescando
      Navigator.pop(context, true);
    } else {
      // Si es la primera vez, reemplazamos la raíz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Qué tienes en casa?', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Selecciona los objetos que están a tu alcance para usarlos en tus misiones de despertador:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _listaObjetos.keys.map((String objeto) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: CheckboxListTile(
                    activeColor: Colors.deepPurple,
                    title: Text(objeto, style: const TextStyle(fontWeight: FontWeight.w600)),
                    value: _listaObjetos[objeto],
                    onChanged: (bool? valor) {
                      setState(() {
                        _listaObjetos[objeto] = valor ?? false;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _guardarConfiguracion,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar Selección', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}