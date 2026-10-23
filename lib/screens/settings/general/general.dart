import 'package:firmador_geresa/assets/tools/json_storage.dart';
import 'package:firmador_geresa/widgets/forms/input_editable.dart';
import 'package:flutter/material.dart';


class GeneralStgs extends StatefulWidget {
	const GeneralStgs({super.key});

	@override
	State<GeneralStgs> createState() => _GeneralStgsState();
}

class _GeneralStgsState extends State<GeneralStgs> {
	// Valor actual de la ruta
	String _rutaNextCloud = '';

	// Clave que usaremos en el JSON
	final String _keyRutaNextCloud = 'ruta_nextcloud';

	@override
	void initState() {
		super.initState();
		// 1. LEER: Obtenemos el valor guardado en el JSON (si no existe, queda vacío)
		_rutaNextCloud = JsonStorage.getString(_keyRutaNextCloud) ?? '';
	}

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.all(24.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					InputEditable(
						label: 'Ruta NextCloud',
						initialValue: _rutaNextCloud,
						hintText: 'agrega ruta',
						onSave: (newValue) async {
							// 2. ACTUALIZAR UI
							setState(() {
								_rutaNextCloud = newValue;
							});

							// 3. GUARDAR: Escribimos en el JSON
							await JsonStorage.setString(_keyRutaNextCloud, newValue);
							
							// Opcional: Mostrar un mensaje de éxito
							if (mounted) {
								ScaffoldMessenger.of(context).showSnackBar(
									const SnackBar(
										content: Text('Ruta guardada correctamente'),
										duration: Duration(seconds: 2),
									),
								);
							}
						},
					),
				],
			),
		);
	}
}