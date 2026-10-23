import 'package:flutter/material.dart';
import 'package:firmador_geresa/assets/theme/app_theme.dart';
import 'package:flutter_desktop_updater/flutter_desktop_updater.dart';

class UpdateButton extends StatefulWidget {
	const UpdateButton({super.key});

	@override
	State<UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<UpdateButton> {
	// URL Raw de tu archivo app.json en GitHub
	static const String _jsonUrl = 'https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/app.json';

	final UpdateManager _manager = UpdateManager();

	Future<void> _buscarActualizacion(BuildContext context) async {
		// 1. Mostrar loader
		showDialog(
			context: context,
			barrierDismissible: false,
			builder: (ctx) => const Center(
				child: Material(
					color: Colors.transparent,
					child: CircularProgressIndicator(color: Colors.white),
				),
			),
		);

		try {
			// Configurar la URL (si tu versión del paquete lo requiere)
			UpdateConfig().configure(updateJsonUrl: _jsonUrl);

			// 2. Verificar actualización
			await _manager.checkForUpdate();

			if (!context.mounted) return;
			Navigator.of(context).pop(); // Cerrar loader

			// 3. Revisar el estado para saber si hay actualización
			// El enum UpdateStatus tiene valores como 'updateAvailable', 'noUpdate', 'error', etc.
			if (_manager.status == UpdateStatus.updateAvailable) {
				// Hay actualización: mostrar popup
				final confirmar = await showDialog<bool>(
					context: context,
					builder: (ctx) => AlertDialog(
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ctx.radiusLg)),
						title: Row(
							children: [
								Icon(Icons.browser_updated, color: ctx.primaryPurple),
								const SizedBox(width: 8),
								const Text('Actualización disponible'),
							],
						),
						content: Text('Hay una nueva versión disponible.\n\n¿Deseas descargarla y actualizar la aplicación ahora?'),
						actions: [
							TextButton(
								onPressed: () => Navigator.pop(ctx, false),
								child: Text('Más tarde', style: TextStyle(color: ctx.textGrey)),
							),
							ElevatedButton(
								onPressed: () => Navigator.pop(ctx, true),
								style: ElevatedButton.styleFrom(backgroundColor: ctx.primaryPurple),
								child: const Text('Actualizar'),
							),
						],
					),
				);

				if (confirmar == true && context.mounted) {
					// 4. Iniciar descarga/instalación
					await _manager.startUpdate();
					
					// 5. Reiniciar la app (opcional, o preguntar al usuario)
					if (context.mounted) {
						await _manager.restartApp();
					}
				}
			} else {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Ya tienes la última versión instalada.')),
				);
			}
		} catch (e) {
			if (!context.mounted) return;
			Navigator.of(context).pop();
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error: $e'), backgroundColor: context.errorRed),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		return FloatingActionButton(
			onPressed: () => _buscarActualizacion(context),
			backgroundColor: context.surfaceWhite,
			foregroundColor: context.primaryPurple,
			elevation: 2,
			tooltip: 'Buscar actualizaciones',
			child: const Icon(Icons.browser_updated),
		);
	}
}