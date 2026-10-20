// lib/screens/firma/firmar/editor_firma_modal.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:image/image.dart' as img;
import 'package:firmador_geresa/assets/theme/app_theme.dart';

class EditorFirmaModal extends StatefulWidget {
	final Uint8List pdfBytes;
	final String nombreArchivo;
	final Uint8List imagenFirmaBytes;
	final String nombreFirmante;
	final String dniFirmante;

	const EditorFirmaModal({
		super.key,
		required this.pdfBytes,
		required this.nombreArchivo,
		required this.imagenFirmaBytes,
		required this.nombreFirmante,
		required this.dniFirmante,
	});

	@override
	State<EditorFirmaModal> createState() => _EditorFirmaModalState();
}

class _EditorFirmaModalState extends State<EditorFirmaModal> {
	final PdfViewerController _pdfController = PdfViewerController();
	final GlobalKey _firmaKey = GlobalKey();

	bool _modoManual = false;
	bool _procesando = false;

	static const double _anchoFirma = 50;
	static const double _altoFirma = 50;

	Offset? _posicionPorcentual;

	@override
	void initState() {
		super.initState();
		// Firma automática por defecto
		_posicionPorcentual = const Offset(0.01, 0.01);
	}

	void _colocarAutomatico() {
		setState(() {
			_modoManual = false;
			_posicionPorcentual = const Offset(0.01, 0.01); 
		});
	}

	void _colocarManual() {
		setState(() {
			_modoManual = true;
			_posicionPorcentual = null;
		});
	}

	Future<Uint8List?> _capturarFirmaCombinada() async {
		try {
			final RenderRepaintBoundary boundary = _firmaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
			final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
			final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
			return byteData?.buffer.asUint8List();
		} catch (e) {
			debugPrint('Error al capturar la firma: $e');
			return null;
		}
	}

	Future<void> _confirmar() async {
		setState(() => _procesando = true);
		try {
			final firmaCombinadaBytes = await _capturarFirmaCombinada();
			if (firmaCombinadaBytes == null) throw Exception('No se pudo generar la firma visual');

			final document = sf.PdfDocument(inputBytes: widget.pdfBytes);
			final page = document.pages[0];

			final decodedImage = img.decodeImage(firmaCombinadaBytes);
			if (decodedImage == null) throw Exception('No se pudo decodificar la imagen combinada');
			final cleanPngBytes = img.encodePng(decodedImage);
			final image = sf.PdfBitmap(cleanPngBytes);

			double x = 20;
			double y = 20;

			if (_posicionPorcentual != null) {
				x = _posicionPorcentual!.dx * page.size.width;
				y = _posicionPorcentual!.dy * page.size.height;
			}

			final double anchoPdf = 180; 
			final double altoPdf = 60;

			page.graphics.drawImage(
				image,
				Rect.fromLTWH(x, y, anchoPdf, altoPdf),
			);

			final List<int> resultado = await document.save();
			document.dispose();

			if (!mounted) return;
			Navigator.of(context).pop(Uint8List.fromList(resultado));
		} catch (e) {
			debugPrint('[EditorFirma] Error: $e');
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Error al insertar la firma: $e')),
				);
			}
		} finally {
			if (mounted) setState(() => _procesando = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final ahora = DateTime.now();
		final fechaStr = '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';
		final horaStr = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

		final Widget firmaVisual = RepaintBoundary(
			key: _firmaKey,
			child: Container(
				color: Colors.transparent,
				child: Row(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						Image.memory(
							widget.imagenFirmaBytes,
							width: _anchoFirma,
							height: _altoFirma,
							fit: BoxFit.contain,
							filterQuality: FilterQuality.high,
						),
						const SizedBox(width: 8),
						Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							mainAxisSize: MainAxisSize.min,
							children: [
								Text(
									'Firmado digitalmente por:',
									style: TextStyle(fontSize: 8, color: context.textDark, fontWeight: FontWeight.w600),
								),
								Text(
									widget.nombreFirmante,
									style: TextStyle(fontSize: 10, color: context.textDark, fontWeight: FontWeight.bold),
								),
								Text(
									'FIR (DNI ${widget.dniFirmante}) hard',
									style: TextStyle(fontSize: 8, color: context.textDark),
								),
								Text(
									'Fecha: $fechaStr - $horaStr',
									style: TextStyle(fontSize: 8, color: context.textDark),
								),
							],
						),
					],
				),
			),
		);

		return Scaffold(
			backgroundColor: context.backgroundLight,
			appBar: AppBar(
				title: const Text('Firma del documento'),
				elevation: 0,
				backgroundColor: context.surfaceWhite,
				foregroundColor: context.textDark,
			),
			body: Row(
				children: [
					Expanded(
						child: Container(
							margin: const EdgeInsets.all(24),
							decoration: BoxDecoration(
								color: context.surfaceGrey,
								borderRadius: BorderRadius.circular(context.radiusLg),
								border: Border.all(color: context.borderColor),
							),
							child: ClipRRect(
								borderRadius: BorderRadius.circular(context.radiusLg),
								child: Stack(
									children: [
										PdfViewer.data(
											widget.pdfBytes,
											sourceName: widget.nombreArchivo,
											controller: _pdfController,
											params: PdfViewerParams(
												backgroundColor: context.surfaceGrey,
												// FORZAMOS EL REFRESCO CUANDO EL PDF ESTÁ LISTO
												onViewerReady: (document, controller) {
													Future.delayed(const Duration(milliseconds: 100), () {
														if (mounted) setState(() {});
													});
												},
												pageOverlaysBuilder: (context, pageRect, page) {
													if (_posicionPorcentual == null) return const [];
													
													return [
														Positioned(
															left: pageRect.left + (_posicionPorcentual!.dx * pageRect.width),
															top: pageRect.top + (_posicionPorcentual!.dy * pageRect.height),
															child: GestureDetector(
																onPanUpdate: _modoManual ? (details) {
																	setState(() {
																		final newX = _posicionPorcentual!.dx + (details.delta.dx / pageRect.width);
																		final newY = _posicionPorcentual!.dy + (details.delta.dy / pageRect.height);
																		_posicionPorcentual = Offset(
																			newX.clamp(0.0, 1.0),
																			newY.clamp(0.0, 1.0),
																		);
																	});
																} : null,
																child: MouseRegion(
																	cursor: _modoManual ? SystemMouseCursors.grab : SystemMouseCursors.basic,
																	child: firmaVisual,
																),
															),
														),
													];
												},
											),
										),
										
										// DRAG TARGET PARA RECIBIR LA IMAGEN
										if (_modoManual && _posicionPorcentual == null)
											Positioned.fill(
												child: DragTarget<Uint8List>(
													onAcceptWithDetails: (details) {
														// Al soltar, simplemente la ponemos en el centro de la pantalla
														// y el usuario la moverá con el mouse.
														setState(() {
															_posicionPorcentual = const Offset(0.5, 0.5);
														});
													},
													builder: (context, candidateData, rejectedData) {
														return IgnorePointer(
															child: Container(color: Colors.transparent),
														);
													},
												),
											),
									],
								),
							),
						),
					),
					Container(
						width: 300,
						padding: const EdgeInsets.all(24),
						decoration: BoxDecoration(
							color: context.surfaceWhite,
							border: Border(left: BorderSide(color: context.borderColor)),
						),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								Text(
									'Firma del documento',
									style: TextStyle(
										fontSize: 20,
										fontWeight: FontWeight.w700,
										color: context.textDark,
									),
								),
								const SizedBox(height: 8),
								Text(
									'Elige cómo deseas colocar tu firma antes de firmar el documento.',
									style: TextStyle(fontSize: 14, color: context.textGrey),
								),
								const SizedBox(height: 32),
								
								OutlinedButton.icon(
									onPressed: _colocarAutomatico,
									style: OutlinedButton.styleFrom(
										backgroundColor: !_modoManual ? context.primaryPurple.withValues(alpha: 0.1) : Colors.transparent,
										foregroundColor: !_modoManual ? context.primaryPurple : context.textGrey,
										side: BorderSide(color: !_modoManual ? context.primaryPurple : context.borderColor),
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusMd),
										),
									),
									icon: const Icon(Icons.auto_awesome_rounded, size: 20),
									label: const Text('Firma automática'),
								),
								
								const SizedBox(height: 12),
								
								OutlinedButton.icon(
									onPressed: _colocarManual,
									style: OutlinedButton.styleFrom(
										backgroundColor: _modoManual ? context.primaryPurple.withValues(alpha: 0.1) : Colors.transparent,
										foregroundColor: _modoManual ? context.primaryPurple : context.textGrey,
										side: BorderSide(color: _modoManual ? context.primaryPurple : context.borderColor),
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusMd),
										),
									),
									icon: const Icon(Icons.touch_app_outlined, size: 20),
									label: const Text('Firma manual'),
								),
								
								if (_modoManual) ...[
									const SizedBox(height: 24),
									Center(
										child: Draggable<Uint8List>(
											data: widget.imagenFirmaBytes,
											feedback: Material(
												color: Colors.transparent,
												child: Opacity(
													opacity: 0.8,
													child: Image.memory(
														widget.imagenFirmaBytes,
														width: _anchoFirma,
														height: _altoFirma,
														fit: BoxFit.contain,
														filterQuality: FilterQuality.high,
													),
												),
											),
											childWhenDragging: Opacity(
												opacity: 0.3,
												child: Image.memory(
													widget.imagenFirmaBytes,
													width: _anchoFirma,
													height: _altoFirma,
													fit: BoxFit.contain,
													filterQuality: FilterQuality.high,
												),
											),
											child: Container(
												padding: const EdgeInsets.all(8),
												decoration: BoxDecoration(
													color: context.surfaceGrey,
													borderRadius: BorderRadius.circular(context.radiusMd),
													border: Border.all(color: context.borderColor),
												),
												child: Column(
													children: [
														Image.memory(
															widget.imagenFirmaBytes,
															width: _anchoFirma,
															height: _altoFirma,
															fit: BoxFit.contain,
															filterQuality: FilterQuality.high,
														),
														const SizedBox(height: 8),
														Text(
															'Arrastra la firma hacia\nel documento',
															textAlign: TextAlign.center,
															style: TextStyle(
																fontSize: 12, 
																color: context.textGrey,
																fontWeight: FontWeight.w500,
															),
														),
													],
												),
											),
										),
									),
								],
								
								const Spacer(),
								
								ElevatedButton(
									onPressed: _procesando || _posicionPorcentual == null ? null : _confirmar,
									style: ElevatedButton.styleFrom(
										backgroundColor: context.primaryPurple,
										foregroundColor: Colors.white,
										elevation: 0,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(context.radiusPill),
										),
									),
									child: _procesando
											? const SizedBox(
													width: 20,
													height: 20,
													child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
												)
											: const Text('Confirmar firma'),
								),
								const SizedBox(height: 8),
								TextButton(
									onPressed: () => Navigator.of(context).pop(null),
									style: TextButton.styleFrom(
										foregroundColor: context.textGrey,
									),
									child: const Text('Cancelar'),
								),
							],
						),
					),
				],
			),
		);
	}
}