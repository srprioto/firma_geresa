import 'package:flutter/material.dart';
import 'screens/sign_screen.dart';
import 'screens/verify_screen.dart';

void main() {
  runApp(const FirmadorApp());
}

class FirmadorApp extends StatelessWidget {
  const FirmadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firmador GERESA Cusco',
      home: const HomeScreen(),
    );
  }
}

/// Pantalla de inicio: solo 2 botones-enrutadores, sin diseño todavía.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmador GERESA Cusco')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    // Ruta de respaldo fija de ejemplo; cámbiala o pásala
                    // en null si todavía no quieres que guarde copia
                    // automática en ningún lado.
                    builder: (_) => const SignScreen(rutaBackup: null),
                  ),
                );
              },
              child: const Text('Firmar'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VerifyScreen()),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
