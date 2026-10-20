import 'package:firmador_geresa/screens/firma/firmar/datos_firmante.dart';
import 'package:firmador_geresa/screens/firma/firmar/datos_firmante_service.dart';
import 'package:flutter/material.dart';
import 'package:firmador_geresa/assets/theme/app_theme.dart';
import '../../../services/api_service.dart';

class PopupPin extends StatefulWidget {
	const PopupPin({super.key});

	@override
	State<PopupPin> createState() => _PopupPinState();
}

class _PopupPinState extends State<PopupPin> {
	final _api = ApiService();
	final _pinCtrl = TextEditingController();
	bool _cargando = false;
	String? _error;

	Future<void> _validar() async {
		final pin = _pinCtrl.text;
		if (pin.isEmpty || _cargando) return;
		setState(() {
			_cargando = true;
			_error = null;
		});
		try {
			final DatosFirmante datos = await _api.obtenerDatosFirmante(pin);
			if (!mounted) return;
			Navigator.of(context).pop(AccesoFirma(pin: pin, datos: datos));
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_cargando = false;
				_error = '$e';
			});
		}
	}

	@override
	void dispose() {
		_pinCtrl.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Dialog(
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(context.radiusLg),
			),
			backgroundColor: context.surfaceWhite,
			child: Container(
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
							'Ingresa el PIN de tu DNIe para continuar.',
							textAlign: TextAlign.center,
							style: TextStyle(fontSize: 14, color: context.textGrey),
						),
						const SizedBox(height: 24),
						TextField(
							controller: _pinCtrl,
							enabled: !_cargando,
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
							onSubmitted: (_) => _validar(),
						),
						if (_error != null) ...[
							const SizedBox(height: 12),
							Text(
								_error!,
								textAlign: TextAlign.center,
								style: TextStyle(fontSize: 13, color: context.errorRed),
							),
						],
						const SizedBox(height: 32),
						Row(
							children: [
								Expanded(
									child: OutlinedButton(
										onPressed: _cargando ? null : () => Navigator.of(context).pop(),
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
										onPressed: _cargando ? null : _validar,
										style: ElevatedButton.styleFrom(
											backgroundColor: context.primaryPurple,
											foregroundColor: Colors.white,
											elevation: 0,
											padding: const EdgeInsets.symmetric(vertical: 16),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(context.radiusPill),
											),
										),
										child: _cargando
												? const SizedBox(
														width: 20,
														height: 20,
														child: CircularProgressIndicator(
															strokeWidth: 2,
															color: Colors.white,
														),
													)
												: const Text('Continuar'),
									),
								),
							],
						),
					],
				),
			),
		);
	}
}