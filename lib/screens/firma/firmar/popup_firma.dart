import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firmador_geresa/assets/theme/app_theme.dart';
import '../../../services/api_service.dart';

enum _EstadoDialogoFirma { pin, cargando, exito, error }

class PopupFirma extends StatefulWidget {
	final Uint8List pdfBytes;
	final String nombreArchivo;
	final String? rutaBackup;

	/// Si viene con valor, firma automáticamente sin volver a pedir el PIN.
	final String? pinPrecargado;

	const PopupFirma({
		super.key,
		required this.pdfBytes,
		required this.nombreArchivo,
		required this.rutaBackup,
		this.pinPrecargado,
	});

	@override
	State<PopupFirma> createState() => _PopupFirmaState();
}

class _PopupFirmaState extends State<PopupFirma> {
	final _api = ApiService();
	final _pinCtrl = TextEditingController();
	final _pinFocusNode = FocusNode();
	final _popupFocusNode = FocusNode();

	_EstadoDialogoFirma _estado = _EstadoDialogoFirma.pin;
	String? _mensajeError;
	Uint8List? _pdfFirmado;

	@override
	void initState() {
		super.initState();
		if (widget.pinPrecargado != null) {
			_pinCtrl.text = widget.pinPrecargado!;
			WidgetsBinding.instance.addPostFrameCallback((_) {
				if (mounted) _firmar();
			});
		} else {
			WidgetsBinding.instance.addPostFrameCallback((_) {
				if (mounted) _pinFocusNode.requestFocus();
			});
		}
	}

	Future<void> _firmar() async {
		if (_pinCtrl.text.isEmpty) return;
		setState(() => _estado = _EstadoDialogoFirma.cargando);

		try {
			final pdfFirmado = await _api.firmar(
				pdfBytes: widget.pdfBytes,
				nombreArchivo: widget.nombreArchivo,
				pin: _pinCtrl.text,
			);

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
					debugPrint('[Firmar] No se pudo guardar el backup: $e');
				}
			}

			if (!mounted) return;
			setState(() {
				_pdfFirmado = pdfFirmado;
				_estado = _EstadoDialogoFirma.exito;
			});
		} catch (e) {
			debugPrint('[Firmar] Error: $e');
			if (!mounted) return;
			setState(() {
				_mensajeError = '$e';
				_estado = _EstadoDialogoFirma.error;
			});
		} finally {
			// El PIN no se conserva después de usarlo
			_pinCtrl.clear();
		}
	}

	Future<void> _guardarComo() async {
		if (_pdfFirmado == null) return;

		final rutaDestino = await FilePicker.platform.saveFile(
			dialogTitle: 'Guardar documento firmado',
			fileName: 'firmado_${widget.nombreArchivo}',
			type: FileType.custom,
			allowedExtensions: ['pdf'],
		);

		if (rutaDestino == null) return;

		try {
			await File(rutaDestino).writeAsBytes(_pdfFirmado!);
			debugPrint('[Firmar] Documento guardado en: $rutaDestino');
			if (mounted) {
				Navigator.of(context).pop();
			}
		} catch (e) {
			debugPrint('[Firmar] Error guardando el documento: $e');
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('No se pudo guardar: $e')),
				);
			}
		}
	}

	@override
	void dispose() {
		_pinCtrl.dispose();
		_pinFocusNode.dispose();
		_popupFocusNode.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final content = switch (_estado) {
			_EstadoDialogoFirma.pin => _buildPin(context),
			_EstadoDialogoFirma.cargando => _buildCargando(context),
			_EstadoDialogoFirma.exito => _buildExito(context),
			_EstadoDialogoFirma.error => _buildError(context),
		};

		return Focus(
			focusNode: _popupFocusNode,
			onFocusChange: (hasFocus) {
				if (!hasFocus) {
					_pinFocusNode.unfocus();
				}
			},
			child: Dialog(
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(context.radiusLg),
				),
				backgroundColor: context.surfaceWhite,
				child: content,
			),
		);
	}

	Widget _buildPin(BuildContext context) {
		return Container(
			width: 400,
			padding: const EdgeInsets.all(32),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							color: context.primaryPurple.withValues(alpha: 0.1),
							shape: BoxShape.circle,
						),
						child: Icon(
							Icons.lock_outline_rounded,
							size: 32,
							color: context.primaryPurple,
						),
					),
					const SizedBox(height: 24),
					Text(
						'Ingresa tu PIN',
						style: TextStyle(
							fontSize: 20,
							fontWeight: FontWeight.w700,
							color: context.textDark,
						),
					),
					const SizedBox(height: 8),
					Text(
						'Ingresa el PIN de tu DNIe para firmar el documento.',
						textAlign: TextAlign.center,
						style: TextStyle(
							fontSize: 14,
							color: context.textGrey,
						),
					),
					const SizedBox(height: 24),
					TextField(
						controller: _pinCtrl,
						focusNode: _pinFocusNode,
						obscureText: true,
						autofocus: true,
						textAlign: TextAlign.center,
						style: const TextStyle(
							fontSize: 24,
							letterSpacing: 8,
							fontWeight: FontWeight.w600,
						),
						decoration: InputDecoration(
							hintText: '••••••••',
							hintStyle: TextStyle(
								fontSize: 24,
								letterSpacing: 8,
								color: context.textLight,
							),
							filled: true,
							fillColor: context.surfaceGrey,
							border: OutlineInputBorder(
								borderRadius: BorderRadius.circular(context.radiusMd),
								borderSide: BorderSide.none,
							),
							enabledBorder: OutlineInputBorder(
								borderRadius: BorderRadius.circular(context.radiusMd),
								borderSide: BorderSide.none,
							),
							focusedBorder: OutlineInputBorder(
								borderRadius: BorderRadius.circular(context.radiusMd),
								borderSide: BorderSide(color: context.primaryPurple, width: 2),
							),
							contentPadding: const EdgeInsets.symmetric(vertical: 20),
						),
						onSubmitted: (_) => _firmar(),
					),
					const SizedBox(height: 32),
					Row(
						children: [
							Expanded(
								child: OutlinedButton(
									onPressed: () => Navigator.of(context).pop(),
									style: OutlinedButton.styleFrom(
										backgroundColor: context.surfaceGrey,
										foregroundColor: context.textDark,
										side: BorderSide.none,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusPill),
										),
									),
									child: const Text('Cancelar'),
								),
							),
							const SizedBox(width: 16),
							Expanded(
								child: ElevatedButton(
									onPressed: _firmar,
									style: ElevatedButton.styleFrom(
										backgroundColor: context.primaryPurple,
										foregroundColor: Colors.white,
										elevation: 0,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusPill),
										),
									),
									child: const Text('Firmar'),
								),
							),
						],
					),
				],
			),
		);
	}

	Widget _buildCargando(BuildContext context) {
		return Container(
			width: 300,
			padding: const EdgeInsets.all(32),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					CircularProgressIndicator(color: context.primaryPurple),
					const SizedBox(height: 24),
					Text(
						'Firmando documento...',
						style: TextStyle(
							fontSize: 16,
							fontWeight: FontWeight.w600,
							color: context.textDark,
						),
					),
				],
			),
		);
	}

	Widget _buildExito(BuildContext context) {
		return Container(
			width: 400,
			padding: const EdgeInsets.all(32),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							color: Colors.green.withValues(alpha: 0.1),
							shape: BoxShape.circle,
						),
						child: const Icon(
							Icons.check_circle_outline_rounded,
							size: 32,
							color: Colors.green,
						),
					),
					const SizedBox(height: 24),
					Text(
						'Documento firmado',
						style: TextStyle(
							fontSize: 20,
							fontWeight: FontWeight.w700,
							color: context.textDark,
						),
					),
					const SizedBox(height: 8),
					Text(
						'El documento se firmó correctamente. Ya puedes guardarlo.',
						textAlign: TextAlign.center,
						style: TextStyle(
							fontSize: 14,
							color: context.textGrey,
						),
					),
					const SizedBox(height: 32),
					SizedBox(
						width: double.infinity,
						child: ElevatedButton(
							onPressed: _guardarComo,
							style: ElevatedButton.styleFrom(
								backgroundColor: context.primaryPurple,
								foregroundColor: Colors.white,
								elevation: 0,
								padding: const EdgeInsets.symmetric(vertical: 16),
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(context.radiusPill),
								),
							),
							child: const Text('Guardar documento'),
						),
					),
					const SizedBox(height: 12),
					SizedBox(
						width: double.infinity,
						child: TextButton(
							onPressed: () => Navigator.of(context).pop(),
							style: TextButton.styleFrom(
								foregroundColor: context.textGrey,
								padding: const EdgeInsets.symmetric(vertical: 16),
							),
							child: const Text('Cerrar'),
						),
					),
				],
			),
		);
	}

	Widget _buildError(BuildContext context) {
		return Container(
			width: 400,
			padding: const EdgeInsets.all(32),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							color: context.errorRed.withValues(alpha: 0.1),
							shape: BoxShape.circle,
						),
						child: Icon(
							Icons.error_outline_rounded,
							size: 32,
							color: context.errorRed,
						),
					),
					const SizedBox(height: 24),
					Text(
						'No se pudo firmar',
						style: TextStyle(
							fontSize: 20,
							fontWeight: FontWeight.w700,
							color: context.textDark,
						),
					),
					const SizedBox(height: 8),
					Text(
						_mensajeError ?? 'Error desconocido.',
						textAlign: TextAlign.center,
						style: TextStyle(
							fontSize: 14,
							color: context.textGrey,
						),
					),
					const SizedBox(height: 32),
					Row(
						children: [
							Expanded(
								child: OutlinedButton(
									onPressed: () => Navigator.of(context).pop(),
									style: OutlinedButton.styleFrom(
										backgroundColor: context.surfaceGrey,
										foregroundColor: context.textDark,
										side: BorderSide.none,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusPill),
										),
									),
									child: const Text('Cerrar'),
								),
							),
							const SizedBox(width: 16),
							Expanded(
								child: ElevatedButton(
									onPressed: () => setState(() => _estado = _EstadoDialogoFirma.pin),
									style: ElevatedButton.styleFrom(
										backgroundColor: context.primaryPurple,
										foregroundColor: Colors.white,
										elevation: 0,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusPill),
										),
									),
									child: const Text('Reintentar'),
								),
							),
						],
					),
				],
			),
		);
	}
}