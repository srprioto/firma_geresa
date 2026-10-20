import 'dart:io';
import 'package:firmador_geresa/screens/firma/firmar/popup_firma.dart';
import 'package:firmador_geresa/widgets/file_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:firmador_geresa/assets/theme/app_theme.dart';



class SignScreen extends StatelessWidget {
	final String? rutaBackup;

	const SignScreen({super.key, this.rutaBackup});

	Future<void> _mostrarPopupFirma(BuildContext context, String path, String nombre) async {
		final archivo = File(path);
		final bytes = await archivo.readAsBytes();

		if (!context.mounted) return;

		await showDialog(
			context: context,
			barrierDismissible: false,
			builder: (_) => PopupFirma(
				pdfBytes: bytes,
				nombreArchivo: nombre,
				rutaBackup: rutaBackup,
			),
		);
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
					onFileDropped: (path, nombre) => _mostrarPopupFirma(context, path, nombre),
				),
			),
		);
	}
}