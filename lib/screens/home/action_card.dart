// lib/widgets/action_card.dart
import 'package:firmador_geresa/assets/theme/app_theme.dart';
import 'package:flutter/material.dart';


class ActionCard extends StatelessWidget {
	/// Título principal de la tarjeta.
	final String titulo;

	/// Texto descriptivo debajo del título.
	final String descripcion;

	/// Icono o cualquier Widget que se muestre en el recuadro superior.
	final Widget icono;

	/// Color de fondo del recuadro del icono.
	final Color iconBackgroundColor;

	/// Ancho fijo de la tarjeta. Por defecto 320 (diseño original).
	final double width;

	/// Callback al tocar la tarjeta. Opcional.
	final VoidCallback? onTap;

	const ActionCard({
		super.key,
		required this.titulo,
		required this.descripcion,
		required this.icono,
		required this.iconBackgroundColor,
		this.width = 320,
		this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		final card = Container(
			width: width,
			padding: const EdgeInsets.all(32),
			decoration: BoxDecoration(
				color: context.surfaceWhite,
				borderRadius: BorderRadius.circular(context.radiusLg),
				border: Border.all(color: context.borderColor),
			),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					// Recuadro del icono
					Container(
						width: 80,
						height: 80,
						decoration: BoxDecoration(
							color: iconBackgroundColor,
							borderRadius: BorderRadius.circular(20),
						),
						child: Center(child: icono),
					),
					const SizedBox(height: 24),
					Text(
						titulo,
						textAlign: TextAlign.center,
						style: TextStyle(
							color: context.textDark,
							fontSize: 18,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 8),
					Text(
						descripcion,
						textAlign: TextAlign.center,
						style: TextStyle(
							color: context.textGrey,
							fontSize: 14,
							height: 1.4,
						),
					),
				],
			),
		);

		if (onTap == null) return card;

		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(context.radiusLg),
			child: card,
		);
	}
}