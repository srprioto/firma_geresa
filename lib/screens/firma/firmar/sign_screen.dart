import 'dart:io';
import 'dart:typed_data';

import 'package:firmador_geresa/screens/firma/firmar/datos_firmante.dart';
import 'package:firmador_geresa/screens/firma/firmar/editor_firma_modal.dart';
import 'package:firmador_geresa/screens/firma/firmar/popup_firma.dart';
import 'package:firmador_geresa/screens/firma/firmar/popup_pin.dart';
import 'package:firmador_geresa/widgets/file_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:firmador_geresa/assets/theme/app_theme.dart';

class SignScreen extends StatelessWidget {
	final String? rutaBackup;

	const SignScreen({super.key, this.rutaBackup});

	Future<void> _procesarArchivo(BuildContext context, String path, String nombre) async {
		final bytes = await File(path).readAsBytes();
		final imagenFirmaBytes = await _obtenerImagenFirma(context);

		if (!context.mounted) return;

		// 1. PIN -> obtiene los datos del firmante
		final acceso = await showDialog<AccesoFirma>(
			context: context,
			barrierDismissible: false,
			builder: (_) => const PopupPin(),
		);

		if (acceso == null || !context.mounted) return;

		// 2. Editor: se estampa la imagen en el PDF
		final pdfConImagen = await Navigator.of(context).push<Uint8List>(
			MaterialPageRoute(
				builder: (_) => EditorFirmaModal(
					pdfBytes: bytes,
					nombreArchivo: nombre,
					imagenFirmaBytes: imagenFirmaBytes,
					nombreFirmante: acceso.datos.nombre,
					dniFirmante: acceso.datos.dni,
				),
			),
		);

		if (pdfConImagen == null || !context.mounted) return;

		// 3. Firma criptográfica sobre el PDF ya editado
		await showDialog(
			context: context,
			barrierDismissible: false,
			builder: (_) => PopupFirma(
				pdfBytes: pdfConImagen,
				nombreArchivo: nombre,
				rutaBackup: rutaBackup,
				pinPrecargado: acceso.pin,
			),
		);
	}

	Future<Uint8List> _obtenerImagenFirma(BuildContext context) async {
		final data = await DefaultAssetBundle.of(context).load('lib/assets/images/logo_firma.png');
		return data.buffer.asUint8List();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Firmar Documento')),
			backgroundColor: context.backgroundLight,
			body: Align(
				alignment: const Alignment(0, -0.4),
				child: FileDropZone(
					width: 500,
					height: 300,
					onFileDropped: (path, nombre) => _procesarArchivo(context, path, nombre),
				),
			),
		);
	}
}