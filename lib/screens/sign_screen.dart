import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

/// Pantalla de Firmar. Sin diseño todavía: solo la lógica.
///
/// [rutaBackup] es opcional: si se pasa una ruta de carpeta, cada
/// documento firmado se guarda ahí también, en SILENCIO (sin avisar al
/// usuario), además de lo que el usuario decida guardar manualmente. La
/// idea es que el usuario siga sintiéndose responsable de cuidar su
/// propio archivo — el backup es solo una red de seguridad interna, no
/// algo que deba hacerlo confiarse.
class SignScreen extends StatelessWidget {
  final String? rutaBackup;

  const SignScreen({super.key, this.rutaBackup});

  Future<void> _elegirYFirmar(BuildContext context) async {
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

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoFirma(
        pdfBytes: pdfBytes,
        nombreArchivo: nombreArchivo,
        rutaBackup: rutaBackup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmar documento')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _elegirYFirmar(context),
          child: const Text('Seleccionar documento PDF'),
        ),
      ),
    );
  }
}

enum _EstadoDialogoFirma { pin, cargando, exito, error }

class _DialogoFirma extends StatefulWidget {
  final Uint8List pdfBytes;
  final String nombreArchivo;
  final String? rutaBackup;

  const _DialogoFirma({
    required this.pdfBytes,
    required this.nombreArchivo,
    required this.rutaBackup,
  });

  @override
  State<_DialogoFirma> createState() => _DialogoFirmaState();
}

class _DialogoFirmaState extends State<_DialogoFirma> {
  final _api = ApiService();
  final _pinCtrl = TextEditingController();

  _EstadoDialogoFirma _estado = _EstadoDialogoFirma.pin;
  String? _mensajeError;
  Uint8List? _pdfFirmado;

  Future<void> _firmar() async {
    setState(() => _estado = _EstadoDialogoFirma.cargando);

    try {
      final pdfFirmado = await _api.firmar(
        pdfBytes: widget.pdfBytes,
        nombreArchivo: widget.nombreArchivo,
        pin: _pinCtrl.text,
      );

      // Los mismos datos que se ven al probar con curl, ahora en la
      // consola de Flutter (ventana donde corre `flutter run`).
      debugPrint('[Firmar] Documento firmado correctamente.');
      debugPrint('[Firmar] Tamaño del PDF firmado: ${pdfFirmado.length} bytes');

      if (widget.rutaBackup != null) {
        try {
          final destino = File(
            '${widget.rutaBackup}${Platform.pathSeparator}firmado_${widget.nombreArchivo}',
          );
          await destino.writeAsBytes(pdfFirmado);
          debugPrint('[Firmar] Backup guardado en: ${destino.path}');
        } catch (e) {
          // El backup es una red de seguridad interna: si falla, no
          // interrumpimos el flujo del usuario, solo lo dejamos en el
          // log para que alguien de soporte lo revise.
          debugPrint('[Firmar] No se pudo guardar el backup: $e');
        }
      }

      setState(() {
        _pdfFirmado = pdfFirmado;
        _estado = _EstadoDialogoFirma.exito;
      });
    } catch (e) {
      debugPrint('[Firmar] Error: $e');
      setState(() {
        _mensajeError = '$e';
        _estado = _EstadoDialogoFirma.error;
      });
    } finally {
      _pinCtrl.clear();
    }
  }

  Future<void> _guardarComo() async {
    if (_pdfFirmado == null) return;

    // En Windows/macOS/Linux, file_picker solo devuelve la ruta elegida;
    // el parámetro `bytes` de saveFile únicamente funciona en Web. Así
    // que en escritorio hay que escribir el archivo nosotros mismos.
    final rutaDestino = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar documento firmado',
      fileName: 'firmado_${widget.nombreArchivo}',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (rutaDestino == null) return; // el usuario canceló

    try {
      await File(rutaDestino).writeAsBytes(_pdfFirmado!);
      debugPrint('[Firmar] Documento guardado en: $rutaDestino');
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[Firmar] Error guardando el documento: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_estado) {
      case _EstadoDialogoFirma.pin:
        return AlertDialog(
          title: const Text('Ingresa tu PIN'),
          content: TextField(
            controller: _pinCtrl,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN del DNIe'),
            onSubmitted: (_) => _firmar(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _firmar,
              child: const Text('OK'),
            ),
          ],
        );

      case _EstadoDialogoFirma.cargando:
        return const AlertDialog(
          content: SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
        );

      case _EstadoDialogoFirma.exito:
        return AlertDialog(
          title: const Text('Documento firmado'),
          content: const Text('El documento se firmó correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: _guardarComo,
              child: const Text('Guardar documento'),
            ),
          ],
        );

      case _EstadoDialogoFirma.error:
        return AlertDialog(
          title: const Text('No se pudo firmar'),
          content: Text(_mensajeError ?? 'Error desconocido.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _estado = _EstadoDialogoFirma.pin),
              child: const Text('Reintentar'),
            ),
          ],
        );
    }
  }
}
