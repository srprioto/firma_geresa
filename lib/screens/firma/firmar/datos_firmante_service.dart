import 'dart:convert';
import 'dart:typed_data';
import 'package:firmador_geresa/screens/firma/firmar/datos_firmante.dart';
import 'package:firmador_geresa/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;


/// Obtiene nombre y DNI sin tocar la API ni el documento real:
/// firma un PDF en blanco de verificación y lee el certificado
/// incrustado en esa firma. El PDF de prueba se descarta.
extension DatosFirmanteApi on ApiService {
	Future<DatosFirmante> obtenerDatosFirmante(String pin) async {
		// 1. PDF en blanco (nunca el documento real)
		final doc = sf.PdfDocument();
		doc.pages.add();
		final blanco = Uint8List.fromList(await doc.save());
		doc.dispose();

		// 2. Firma de prueba con el PIN
		final firmado = await firmar(
			pdfBytes: blanco,
			nombreArchivo: 'verificacion.pdf',
			pin: pin,
		);

		// 3. Leer nombre y DNI del certificado
		return _extraerDatos(Uint8List.fromList(firmado));
	}
}

// Formato esperado del CN: "NOMBRES APELLIDOS FIR 12345678 hard"
final _patronCn = RegExp(
	r'([A-Za-zÁÉÍÓÚÜÑáéíóúüñ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ ]+?)\s+FIR\s*\(?\s*(?:DNI\s*)?(\d{8})',
	caseSensitive: false,
);

String _utf16be(Uint8List b) {
	final units = <int>[];
	for (var i = 0; i + 1 < b.length; i += 2) {
		units.add((b[i] << 8) | b[i + 1]);
	}
	return String.fromCharCodes(units);
}

DatosFirmante? _buscar(String s) {
	final r = _patronCn.firstMatch(s);
	if (r == null) return null;
	return DatosFirmante(nombre: r.group(1)!.trim().toUpperCase(), dni: r.group(2)!);
}

DatosFirmante _extraerDatos(Uint8List pdf) {
	final texto = latin1.decode(pdf, allowInvalid: true);
	debugPrint('[DatosFirmante] PDF firmado: ${pdf.length} bytes');
	debugPrint('[DatosFirmante] Tiene /ByteRange: ${texto.contains('/ByteRange')}');

	final bloques = RegExp(r'/Contents\s*<([0-9A-Fa-f\s]+)>').allMatches(texto).toList();
	debugPrint('[DatosFirmante] Bloques /Contents encontrados: ${bloques.length}');

	for (final m in bloques) {
		final hex = m.group(1)!.replaceAll(RegExp(r'\s'), '');
		final bytes = Uint8List(hex.length ~/ 2);
		for (var i = 0; i < bytes.length; i++) {
			bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
		}

		// Utf-8, Latin-1 y UTF-16 (BMPString)
		for (final s in [
			utf8.decode(bytes, allowMalformed: true),
			latin1.decode(bytes, allowInvalid: true),
			_utf16be(bytes),
			_utf16be(Uint8List.fromList(bytes.skip(1).toList())),
		]) {
			final d = _buscar(s);
			if (d != null) return d;
		}

		// Diagnóstico: textos legibles dentro de la firma
		final legibles = RegExp(r'[\x20-\x7E]{5,}')
				.allMatches(latin1.decode(bytes, allowInvalid: true))
				.map((x) => x.group(0)!)
				.take(40)
				.toList();
		debugPrint('[DatosFirmante] Bloque de ${bytes.length} bytes. Textos legibles:');
		for (final t in legibles) {
			debugPrint('   · $t');
		}
	}

	// Último intento: buscar en todo el PDF
	final d = _buscar(texto);
	if (d != null) return d;

	throw Exception('No se pudieron leer los datos del certificado.');
}