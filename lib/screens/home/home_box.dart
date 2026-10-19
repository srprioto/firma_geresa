
import 'package:firmador_geresa/assets/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HomeBox extends StatelessWidget {

	final List<Widget> children;
	
	const HomeBox({
		super.key, required this.children,
	});

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
		
		
				Expanded(
					child: SingleChildScrollView(
						padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
						child: Center(
							child: ConstrainedBox(
								constraints: const BoxConstraints(maxWidth: 1100),
								child: Column(
									children: [
										// --- HEADER (Icono, Título, Subtítulo) ---
										Container(
											width: 80,
											height: 80,
											decoration: BoxDecoration(
												color: context.surfaceWhite,
												borderRadius: BorderRadius.circular(16),
												boxShadow: AppTheme.shadowSm,
											),
											child: const Icon(Icons.copy_all_rounded, size: 40, color: Colors.blue),
										),
										const SizedBox(height: 24),
										Text(
											'Todo lo que necesitas,\nen un solo lugar',
											textAlign: TextAlign.center,
											style: TextStyle(
												color: context.textDark,
												fontSize: 36,
												fontWeight: FontWeight.w700,
												height: 1.2,
											),
										),
										const SizedBox(height: 12),
										Text(
											'Selecciona una opción para continuar',
											style: TextStyle(
												color: context.textGrey,
												fontSize: 16,
											),
										),
										const SizedBox(height: 48),

										Wrap(
											spacing: 24,
											runSpacing: 24,
											alignment: WrapAlignment.center,
											children: children // grid aqui
										),
									],
								),
							),
						),
					),
				),
			],
		);
	}
}