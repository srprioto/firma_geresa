import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Cliente del backend local (Java) que corre en http://127.0.0.1:8000
/// en la misma máquina.
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Firma el PDF con el PIN del DNIe. Devuelve los bytes del PDF firmado.
  Future<Uint8List> firmar({
    required Uint8List pdfBytes,
    required String nombreArchivo,
    required String pin,
  }) async {
    final uri = Uri.parse('$baseUrl/firmar');
    final request = http.MultipartRequest('POST', uri)
      ..fields['pin'] = pin
      ..files.add(
        http.MultipartFile.fromBytes('pdf', pdfBytes, filename: nombreArchivo),
      );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception(_detalle(res));
    }
    return res.bodyBytes;
  }

  /// Verifica las firmas de un PDF. Devuelve la respuesta JSON cruda tal
  /// como la entrega el backend (la misma que se ve al probar con curl).
  Future<Map<String, dynamic>> verificar({
    required Uint8List pdfBytes,
    required String nombreArchivo,
  }) async {
    final uri = Uri.parse('$baseUrl/verificar');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('pdf', pdfBytes, filename: nombreArchivo),
      );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception(_detalle(res));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _detalle(http.Response res) {
    try {
      final cuerpo = jsonDecode(res.body);
      return cuerpo['detail']?.toString() ?? 'Error desconocido (${res.statusCode})';
    } catch (_) {
      return 'Error desconocido (${res.statusCode})';
    }
  }
}
