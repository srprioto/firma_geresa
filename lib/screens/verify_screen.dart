import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

/// Pantalla de Confirmar. Sin diseño todavía: solo la lógica.
class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  Future<void> _elegirYVerificar(BuildContext context) async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (resultado == null || resultado.files.single.bytes == null) {
      return;
    }
    final pdfBytes = resultado.files.single.bytes!;
    final nombreArchivo = resultado.files.single.name;

    final api = ApiService();

    // Diálogo de carga mientras se verifica.
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final respuesta = await api.verificar(
        pdfBytes: pdfBytes,
        nombreArchivo: nombreArchivo,
      );

      // Los mismos datos que se ven al probar con curl, ahora en la
      // consola de Flutter.
      debugPrint('[Confirmar] Respuesta: $respuesta');

      final firmas = (respuesta['firmas'] as List?) ?? [];
      final estaFirmado = firmas.isNotEmpty &&
          firmas.any((f) => f is Map && f['error'] == null);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // cierra el diálogo de carga

      String mensaje;
      if (!estaFirmado) {
        mensaje = 'El documento NO está firmado (o no se pudo leer ninguna firma).';
      } else {
        final primera = firmas.first as Map;
        mensaje = 'El documento está firmado por: ${primera['firmante']}';
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resultado'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[Confirmar] Error: $e');
      if (!context.mounted) return;
      Navigator.of(context).pop(); // cierra el diálogo de carga
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error al verificar'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar firma')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _elegirYVerificar(context),
          child: const Text('Seleccionar documento PDF'),
        ),
      ),
    );
  }
}
