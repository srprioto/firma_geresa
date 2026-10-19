// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firmador_geresa/assets/theme/app_theme.dart';

import 'package:firmador_geresa/screens/firma/firmar/sign_screen.dart';
import 'package:firmador_geresa/screens/firma/verificar/verify_screen.dart';

class FirmaScreen extends StatefulWidget {
	const FirmaScreen({super.key});

	@override
	State<FirmaScreen> createState() => _FirmaScreenState();
}

class _FirmaScreenState extends State<FirmaScreen> {
	int _selectedIndex = 0;

	void _onToggle(int index) {
		if (_selectedIndex != index) {
			setState(() {
				_selectedIndex = index;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: context.backgroundLight,
			// Usamos un Stack para que el toggle flote por encima del contenido
			body: Stack(
				children: [

					// 1. CONTENIDO PRINCIPAL
					Positioned.fill(
						child: SafeArea(
							bottom: false, // Evitamos que el SafeArea empuje el contenido por el toggle
							child: IndexedStack(
								index: _selectedIndex,
								children: const [
									SignScreen(rutaBackup: null),
									VerifyScreen(),
								],
							),
						),
					),

					// 2. TOGGLE FLOTANTE (50% DE ANCHO, CENTRADO)
					Positioned(
						bottom: 32, // Distancia desde el borde inferior
						left: 0,
						right: 0,
						child: Center(
							child: FractionallySizedBox(
								widthFactor: 0.5, // Ocupa el 50% del ancho
								child: Container(
									height: 56,
									decoration: BoxDecoration(
										color: context.surfaceWhite,
										borderRadius: BorderRadius.circular(context.radiusLg),
										// Sombra para el efecto flotante
										boxShadow: [
											BoxShadow(
												color: Colors.black.withValues(alpha: 0.08),
												blurRadius: 24,
												offset: const Offset(0, 8),
											),
										],
										border: Border.all(
											color: context.borderColor,
											width: 1,
										),
									),
									child: Row(
										children: [
											Expanded(
												child: _ToggleButton(
													title: 'Firmar Documento',
													icon: Icons.edit_document,
													isSelected: _selectedIndex == 0,
													onTap: () => _onToggle(0),
												),
											),
											Expanded(
												child: _ToggleButton(
													title: 'Verificar Firma',
													icon: Icons.verified_user_rounded,
													isSelected: _selectedIndex == 1,
													onTap: () => _onToggle(1),
												),
											),
											Expanded(
												child: _ToggleButton(
													title: 'Verificar Firma',
													icon: Icons.verified_user_rounded,
													isSelected: _selectedIndex == 1,
													onTap: () => _onToggle(1),
												),
											),
										],
									),
								),
							),
						),
					),
				],
			),
		);
	}
}


// WIDGET REUTILIZABLE PARA LOS BOTONES DEL TOGGLE
class _ToggleButton extends StatelessWidget {
	final String title;
	final IconData icon;
	final bool isSelected;
	final VoidCallback onTap;

	const _ToggleButton({
		required this.title,
		required this.icon,
		required this.isSelected,
		required this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.all(4),
			child: Material(
				color: isSelected ? context.primaryBlue : Colors.transparent,
				borderRadius: BorderRadius.circular(context.radiusMd),
				child: InkWell(
					onTap: onTap,
					borderRadius: BorderRadius.circular(context.radiusMd),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								icon,
								color: isSelected ? Colors.white : context.textGrey,
								size: 20,
							),
							const SizedBox(width: 8),
							Text(
								title,
								style: TextStyle(
									color: isSelected ? Colors.white : context.textGrey,
									fontSize: 14,
									fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
								),
							),
						],
					),
				),
			),
		);
	}
}