import 'package:firmador_geresa/assets/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
	const HomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: context.backgroundLight,
			body: Column(
				children: [
					// ==========================================
					// FAKE TITLE BAR (Opcional, simula el diseño de la ventana)
					// ==========================================
					// Container(
					// 	height: 48,
					// 	padding: const EdgeInsets.symmetric(horizontal: 16),
					// 	decoration: BoxDecoration(
					// 		color: context.surfaceWhite,
					// 		border: Border(bottom: BorderSide(color: context.borderColor)),
					// 	),
					// 	child: Row(
					// 		children: [
					// 			const Icon(Icons.grid_view_rounded, color: Colors.blue, size: 20),
					// 			const SizedBox(width: 8),
					// 			Text(
					// 				'Gestor de Documentos',
					// 				style: TextStyle(
					// 					color: context.textDark,
					// 					fontSize: 13,
					// 					fontWeight: FontWeight.w500,
					// 				),
					// 			),
					// 			const Spacer(),
					// 			Icon(Icons.remove, color: context.textGrey, size: 18),
					// 			const SizedBox(width: 16),
					// 			Icon(Icons.crop_square, color: context.textGrey, size: 18),
					// 			const SizedBox(width: 16),
					// 			Icon(Icons.close, color: context.textGrey, size: 18),
					// 		],
					// 	),
					// ),

					// ==========================================
					// CONTENIDO PRINCIPAL
					// ==========================================
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

											// ==========================================
											// GRID DE TARJETAS (HARDCODEADO)
											// ==========================================
											Wrap(
												spacing: 24,
												runSpacing: 24,
												alignment: WrapAlignment.center,
												children: [
													// --- TARJETA 1: Unir PDF's ---
													Container(
														width: 320,
														padding: const EdgeInsets.all(32),
														decoration: BoxDecoration(
															color: context.surfaceWhite,
															borderRadius: BorderRadius.circular(context.radiusLg),
															border: Border.all(color: context.borderColor),
														),
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Container(
																	width: 80,
																	height: 80,
																	decoration: BoxDecoration(
																		color: const Color(0xFFF3E8FF), // Púrpura claro
																		borderRadius: BorderRadius.circular(20),
																	),
																	child: const Icon(Icons.copy_all_rounded, size: 40, color: Color(0xFF8B5CF6)),
																),
																const SizedBox(height: 24),
																Text(
																	"Unir PDF's",
																	style: TextStyle(
																		color: context.textDark,
																		fontSize: 18,
																		fontWeight: FontWeight.w600,
																	),
																),
																const SizedBox(height: 8),
																Text(
																	'Combina varios archivos PDF en uno solo.',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textGrey,
																		fontSize: 14,
																		height: 1.4,
																	),
																),
															],
														),
													),

													// --- TARJETA 2: Convertir Word a PDF ---
													Container(
														width: 320,
														padding: const EdgeInsets.all(32),
														decoration: BoxDecoration(
															color: context.surfaceWhite,
															borderRadius: BorderRadius.circular(context.radiusLg),
															border: Border.all(color: context.borderColor),
														),
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Container(
																	width: 80,
																	height: 80,
																	decoration: BoxDecoration(
																		color: const Color(0xFFDBEAFE), // Azul claro
																		borderRadius: BorderRadius.circular(20),
																	),
																	child: const Row(
																		mainAxisAlignment: MainAxisAlignment.center,
																		children: [
																			Icon(Icons.description, size: 24, color: Color(0xFF3B82F6)),
																			SizedBox(width: 4),
																			Icon(Icons.arrow_forward, size: 16, color: Color(0xFF6B7280)),
																			SizedBox(width: 4),
																			Icon(Icons.picture_as_pdf, size: 24, color: Color(0xFFEF4444)),
																		],
																	),
																),
																const SizedBox(height: 24),
																Text(
																	'Convertir Word a PDF',
																	style: TextStyle(
																		color: context.textDark,
																		fontSize: 18,
																		fontWeight: FontWeight.w600,
																	),
																),
																const SizedBox(height: 8),
																Text(
																	'Convierte tus documentos de Word a formato PDF.',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textGrey,
																		fontSize: 14,
																		height: 1.4,
																	),
																),
															],
														),
													),

													// --- TARJETA 3: Verificar Firma Digital ---
													Container(
														width: 320,
														padding: const EdgeInsets.all(32),
														decoration: BoxDecoration(
															color: context.surfaceWhite,
															borderRadius: BorderRadius.circular(context.radiusLg),
															border: Border.all(color: context.borderColor),
														),
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Container(
																	width: 80,
																	height: 80,
																	decoration: BoxDecoration(
																		color: const Color(0xFFDCFCE7), // Verde claro
																		borderRadius: BorderRadius.circular(20),
																	),
																	child: const Icon(Icons.verified_user_rounded, size: 40, color: Color(0xFF10B981)),
																),
																const SizedBox(height: 24),
																Text(
																	'Verificar Firma Digital',
																	style: TextStyle(
																		color: context.textDark,
																		fontSize: 18,
																		fontWeight: FontWeight.w600,
																	),
																),
																const SizedBox(height: 8),
																Text(
																	'Revisa la validez de las firmas digitales en tus documentos.',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textGrey,
																		fontSize: 14,
																		height: 1.4,
																	),
																),
															],
														),
													),

													// --- TARJETA 4: Abrir ventana de Refirma ---
													Container(
														width: 320,
														padding: const EdgeInsets.all(32),
														decoration: BoxDecoration(
															color: context.surfaceWhite,
															borderRadius: BorderRadius.circular(context.radiusLg),
															border: Border.all(color: context.borderColor),
														),
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Container(
																	width: 80,
																	height: 80,
																	decoration: BoxDecoration(
																		color: const Color(0xFFFFEDD5), // Naranja claro
																		borderRadius: BorderRadius.circular(20),
																	),
																	child: const Icon(Icons.open_in_new_rounded, size: 40, color: Color(0xFFF97316)),
																),
																const SizedBox(height: 24),
																Text(
																	'Abrir ventana de Refirma',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textDark,
																		fontSize: 18,
																		fontWeight: FontWeight.w600,
																	),
																),
																const SizedBox(height: 8),
																Text(
																	'Accede a la aplicación Refirma desde aquí.',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textGrey,
																		fontSize: 14,
																		height: 1.4,
																	),
																),
															],
														),
													),

													// --- TARJETA 5: Escanear Documentos ---
													Container(
														width: 320,
														padding: const EdgeInsets.all(32),
														decoration: BoxDecoration(
															color: context.surfaceWhite,
															borderRadius: BorderRadius.circular(context.radiusLg),
															border: Border.all(color: context.borderColor),
														),
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Container(
																	width: 80,
																	height: 80,
																	decoration: BoxDecoration(
																		color: const Color(0xFFCCFBF1), // Teal claro
																		borderRadius: BorderRadius.circular(20),
																	),
																	child: const Icon(Icons.document_scanner_rounded, size: 40, color: Color(0xFF14B8A6)),
																),
																const SizedBox(height: 24),
																Text(
																	'Escanear Documentos',
																	style: TextStyle(
																		color: context.textDark,
																		fontSize: 18,
																		fontWeight: FontWeight.w600,
																	),
																),
																const SizedBox(height: 8),
																Text(
																	'Digitaliza tus documentos desde el escáner.',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textGrey,
																		fontSize: 14,
																		height: 1.4,
																	),
																),
															],
														),
													),

													// --- TARJETA 6: Guardar Documentos ---
													Container(
														width: 320,
														padding: const EdgeInsets.all(32),
														decoration: BoxDecoration(
															color: context.surfaceWhite,
															borderRadius: BorderRadius.circular(context.radiusLg),
															border: Border.all(color: context.borderColor),
														),
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Container(
																	width: 80,
																	height: 80,
																	decoration: BoxDecoration(
																		color: const Color(0xFFEDE9FE), // Violeta claro
																		borderRadius: BorderRadius.circular(20),
																	),
																	child: const Icon(Icons.folder_rounded, size: 40, color: Color(0xFF8B5CF6)),
																),
																const SizedBox(height: 24),
																Text(
																	'Guardar Documentos',
																	style: TextStyle(
																		color: context.textDark,
																		fontSize: 18,
																		fontWeight: FontWeight.w600,
																	),
																),
																const SizedBox(height: 8),
																Text(
																	'Organiza y guarda tus archivos de forma rápida y segura.',
																	textAlign: TextAlign.center,
																	style: TextStyle(
																		color: context.textGrey,
																		fontSize: 14,
																		height: 1.4,
																	),
																),
															],
														),
													),
												],
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