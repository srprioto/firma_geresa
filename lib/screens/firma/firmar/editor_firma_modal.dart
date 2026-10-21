import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:image/image.dart' as img;
import 'package:firmador_geresa/assets/theme/app_theme.dart';

enum PosicionFirma {
	arribaIzquierda,
	arribaCentro,
	arribaDerecha,
	abajoIzquierda,
	abajoCentro,
	abajoDerecha,
}

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
	final GlobalKey _stackKey = GlobalKey();

	bool _modoManual = false;
	bool _procesando = false;

	// Tamaño de la firma en puntos PDF (el preview usa las mismas medidas y se escala)
	static const double _anchoFirma = 190;
	static const double _altoFirma = 50;
	static const double _lado = 44; // lado del cuadro de la imagen
	static const double _margen = 5; // distancia al borde de la página

	// Posición de la esquina superior izquierda, en fracción de la página
	Offset? _posicionPorcentual;
	int _paginaFirma = 1; // 1-based
	int _totalPaginas = 1;
	List<Size> _tamanos = const [];
	PosicionFirma _posicionAuto = PosicionFirma.arribaIzquierda;

	// ---------- Utilidades ----------

	Offset _limitar(Offset p, int pagina) {
		if (_tamanos.isEmpty) return p;
		final s = _tamanos[pagina - 1];
		final maxX = (1 - _anchoFirma / s.width).clamp(0.0, 1.0);
		final maxY = (1 - _altoFirma / s.height).clamp(0.0, 1.0);
		return Offset(p.dx.clamp(0.0, maxX), p.dy.clamp(0.0, maxY));
	}

	void _irAPagina(int pagina) {
		if (!_pdfController.isReady) return;
		_pdfController.goToPage(pageNumber: pagina, anchor: PdfPageAnchor.all);
	}

	void _cambiarPagina(int delta) {
		final nueva = (_paginaFirma + delta).clamp(1, _totalPaginas);
		if (nueva == _paginaFirma || _posicionPorcentual == null) return;
		setState(() {
			_paginaFirma = nueva;
			_posicionPorcentual = _limitar(_posicionPorcentual!, nueva);
		});
		_irAPagina(nueva);
	}

	void _colocarAutomatico() {
		if (_tamanos.isEmpty) return;
		final n = _totalPaginas; // última página (usa 1 si prefieres la primera)
		final s = _tamanos[n - 1];

		final izq = _margen / s.width;
		final cen = (1 - _anchoFirma / s.width) / 2;
		final der = 1 - (_anchoFirma + _margen) / s.width;
		final arr = _margen / s.height;
		final aba = 1 - (_altoFirma + _margen) / s.height;

		final pos = switch (_posicionAuto) {
			PosicionFirma.arribaIzquierda => Offset(izq, arr),
			PosicionFirma.arribaCentro => Offset(cen, arr),
			PosicionFirma.arribaDerecha => Offset(der, arr),
			PosicionFirma.abajoIzquierda => Offset(izq, aba),
			PosicionFirma.abajoCentro => Offset(cen, aba),
			PosicionFirma.abajoDerecha => Offset(der, aba),
		};

		setState(() {
			_modoManual = false;
			_paginaFirma = n;
			_posicionPorcentual = _limitar(pos, n);
		});
		_irAPagina(n);
	}

	void _elegirPosicionAuto(PosicionFirma p) {
		_posicionAuto = p;
		_colocarAutomatico();
	}

	void _colocarManual() {
		setState(() {
			_modoManual = true;
			_posicionPorcentual = null;
		});
	}

	// Se llama al soltar la firma sobre el visor
	void _alSoltar(DragTargetDetails<Uint8List> details) {
		if (!_pdfController.isReady || _tamanos.isEmpty) return;

		final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
		if (box == null) return;

		// details.offset = esquina superior izquierda del feedback.
		// Le sumamos la mitad del feedback para obtener el punto central (el cursor).
		final centroGlobal = details.offset + const Offset(_anchoFirma / 2, _altoFirma / 2);
		final local = box.globalToLocal(centroGlobal);

		// Coordenadas del visor -> coordenadas del documento (considera zoom y scroll)
		final inversa = Matrix4.inverted(_pdfController.value);
		final doc = MatrixUtils.transformPoint(inversa, local);

		// Página sobre la que se soltó (o la más cercana)
		final layouts = _pdfController.layout.pageLayouts;
		int idx = 0;
		double mejor = double.infinity;
		for (int i = 0; i < layouts.length; i++) {
			final r = layouts[i];
			final dx = math.max(math.max(r.left - doc.dx, 0.0), doc.dx - r.right);
			final dy = math.max(math.max(r.top - doc.dy, 0.0), doc.dy - r.bottom);
			final d = dx * dx + dy * dy;
			if (d < mejor) {
				mejor = d;
				idx = i;
			}
		}

		final rect = layouts[idx];
		final size = _tamanos[idx];
		final cx = (doc.dx - rect.left) / rect.width;
		final cy = (doc.dy - rect.top) / rect.height;

		// El cursor queda en el centro de la firma
		final pos = Offset(
			cx - (_anchoFirma / size.width) / 2,
			cy - (_altoFirma / size.height) / 2,
		);

		setState(() {
			_paginaFirma = idx + 1;
			_posicionPorcentual = _limitar(pos, idx + 1);
		});
	}

	// Calcula si el nombre debe ir en 1 o 2 líneas
	List<String> _calcularNombreLineas(String nombre) {
		// Formatear a Tipo Título (Primera letra mayúscula, resto minúsculas)
		final textoFormateado = nombre.trim().split(' ').map((palabra) {
			if (palabra.isEmpty) return '';
			return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
		}).join(' ');

		// 20 caracteres es el límite aproximado para el ancho del sello en puntos PDF
		if (textoFormateado.length <= 20) return [textoFormateado];

		final palabras = textoFormateado.split(' ');
		if (palabras.length == 1) return [textoFormateado];

		int mejorCorte = -1;
		int largoActual = 0;

		for (int i = 0; i < palabras.length; i++) {
			largoActual += palabras[i].length + 1;
			if (largoActual > 20) {
				mejorCorte = i;
				break;
			}
		}

		if (mejorCorte <= 0) return [textoFormateado];

		final linea1 = palabras.sublist(0, mejorCorte).join(' ');
		final linea2 = palabras.sublist(mejorCorte).join(' ');
		
		return [linea1, linea2];
	}

	// ---------- Confirmar ----------

	Future<void> _confirmar() async {
		if (_posicionPorcentual == null) return;
		setState(() => _procesando = true);
		sf.PdfDocument? document;
		try {
			final ahora = DateTime.now();
			final fechaStr = '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';
			final horaStr = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

			final decoded = img.decodeImage(widget.imagenFirmaBytes);
			if (decoded == null) throw Exception('No se pudo decodificar la imagen de la firma');
			final bitmap = sf.PdfBitmap(img.encodePng(decoded));

			document = sf.PdfDocument(inputBytes: widget.pdfBytes);
			final page = document.pages[_paginaFirma - 1];

			final x = _posicionPorcentual!.dx * page.size.width;
			final y = _posicionPorcentual!.dy * page.size.height;

			final g = page.graphics;

			// Imagen con proporción original, contenida en un cuadro de _lado x _lado
			final ratio = decoded.width / decoded.height;
			double w = _lado, h = _lado;
			if (ratio > 1) {
				h = _lado / ratio;
			} else {
				w = _lado * ratio;
			}
			g.drawImage(
				bitmap,
				Rect.fromLTWH(x + (_lado - w) / 2, y + (_altoFirma - h) / 2, w, h),
			);

			// Texto (mismas posiciones que el preview)
			final fuente = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 6);
			final negrita = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 7.5, style: sf.PdfFontStyle.bold);
			final negro = sf.PdfSolidBrush(sf.PdfColor(0, 0, 0));
			final tx = x + _lado + 8;

			final lineasNombre = _calcularNombreLineas(widget.nombreFirmante);
			final esDobleLinea = lineasNombre.length > 1;

			g.drawString('Firmado digitalmente por:', fuente, brush: negro, bounds: Rect.fromLTWH(tx, y + 7.5, 0, 0));
			g.drawString(lineasNombre[0], negrita, brush: negro, bounds: Rect.fromLTWH(tx, y + (esDobleLinea ? 13.5 : 16.7), 0, 0));
			
			if (esDobleLinea) {
				g.drawString(lineasNombre[1], negrita, brush: negro, bounds: Rect.fromLTWH(tx, y + 21, 0, 0));
				g.drawString('FIR (DNI ${widget.dniFirmante}) hard', fuente, brush: negro, bounds: Rect.fromLTWH(tx, y + 28, 0, 0));
				g.drawString('Fecha: $fechaStr - $horaStr', fuente, brush: negro, bounds: Rect.fromLTWH(tx, y + 35, 0, 0));
			} else {
				g.drawString('FIR (DNI ${widget.dniFirmante}) hard', fuente, brush: negro, bounds: Rect.fromLTWH(tx, y + 25.7, 0, 0));
				g.drawString('Fecha: $fechaStr - $horaStr', fuente, brush: negro, bounds: Rect.fromLTWH(tx, y + 32.9, 0, 0));
			}

			final List<int> resultado = await document.save();

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
			document?.dispose();
			if (mounted) setState(() => _procesando = false);
		}
	}

	// ---------- UI ----------

	Widget _imagenFirma({double? size}) => Image.memory(
				widget.imagenFirmaBytes,
				width: size ?? _lado,
				height: size ?? _lado,
				fit: BoxFit.contain,
				filterQuality: FilterQuality.high,
			);

	// Preview con medidas en "puntos PDF" (190 x 50). Luego se escala con FittedBox.
	Widget _firmaVisual() {
		final ahora = DateTime.now();
		final fechaStr = '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';
		final horaStr = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
		
		const estiloNormal = TextStyle(fontSize: 6, color: Colors.black, height: 1.1);
		const estiloNegrita = TextStyle(fontSize: 7.5, color: Colors.black, fontWeight: FontWeight.bold, height: 1.1);

		final lineasNombre = _calcularNombreLineas(widget.nombreFirmante);
		final esDobleLinea = lineasNombre.length > 1;

		return SizedBox(
			width: _anchoFirma,
			height: _altoFirma,
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					SizedBox(width: _lado, height: _lado, child: _imagenFirma()),
					const SizedBox(width: 8),
					Expanded(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text('Firmado digitalmente por:', style: estiloNormal),
								Text(lineasNombre[0], style: estiloNegrita),
								if (esDobleLinea) Text(lineasNombre[1], style: estiloNegrita),
								Text('FIR (DNI ${widget.dniFirmante}) hard', style: estiloNormal),
								Text('Fecha: $fechaStr - $horaStr', style: estiloNormal),
							],
						),
					),
				],
			),
		);
	}

	Widget _opcionPosicion(PosicionFirma p, String tooltip) {
		final seleccionado = _posicionAuto == p;
		return Tooltip(
			message: tooltip,
			child: InkWell(
				customBorder: const CircleBorder(),
				onTap: () => _elegirPosicionAuto(p),
				child: Padding(
					padding: const EdgeInsets.all(6),
					child: Icon(
						seleccionado
								? Icons.radio_button_checked_rounded
								: Icons.radio_button_unchecked_rounded,
						size: 22,
						color: seleccionado ? context.primaryPurple : context.textGrey,
					),
				),
			),
		);
	}

	Widget _selectorPosicion() {
		return Container(
			margin: const EdgeInsets.only(top: 16),
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: context.surfaceGrey,
				borderRadius: BorderRadius.circular(context.radiusMd),
				border: Border.all(color: context.borderColor),
			),
			child: Column(
				children: [
					Text(
						'Posición en la página',
						style: TextStyle(
							fontSize: 12,
							fontWeight: FontWeight.w600,
							color: context.textGrey,
						),
					),
					const SizedBox(height: 8),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							_opcionPosicion(PosicionFirma.arribaIzquierda, 'Arriba izquierda'),
							_opcionPosicion(PosicionFirma.arribaCentro, 'Arriba centro'),
							_opcionPosicion(PosicionFirma.arribaDerecha, 'Arriba derecha'),
						],
					),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							_opcionPosicion(PosicionFirma.abajoIzquierda, 'Abajo izquierda'),
							_opcionPosicion(PosicionFirma.abajoCentro, 'Abajo centro'),
							_opcionPosicion(PosicionFirma.abajoDerecha, 'Abajo derecha'),
						],
					),
				],
			),
		);
	}

	Widget _botonZoom(IconData icono, String tooltip, VoidCallback onTap) {
		return Material(
			color: context.surfaceWhite,
			elevation: 2,
			borderRadius: BorderRadius.circular(context.radiusMd),
			child: IconButton(
				icon: Icon(icono, size: 20),
				tooltip: tooltip,
				color: context.textDark,
				onPressed: onTap,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
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
									key: _stackKey,
									children: [
										PdfViewer.data(
											widget.pdfBytes,
											sourceName: widget.nombreArchivo,
											controller: _pdfController,
											params: PdfViewerParams(
												backgroundColor: context.surfaceGrey,
												onViewerReady: (document, controller) {
													setState(() {
														_totalPaginas = document.pages.length;
														_tamanos = document.pages
																.map((p) => Size(p.width, p.height))
																.toList();
													});
													// Posición por defecto: arriba izquierda
													_colocarAutomatico();
												},
												pageOverlaysBuilder: (context, pageRect, page) {
													if (_posicionPorcentual == null || page.pageNumber != _paginaFirma) {
														return const [];
													}

													// Pantalla (o documento) por cada punto PDF
													final escala = pageRect.width / page.width;

													return [
														Positioned(
															left: _posicionPorcentual!.dx * pageRect.width,
															top: _posicionPorcentual!.dy * pageRect.height,
															child: GestureDetector(
																onPanUpdate: _modoManual
																		? (details) {
																				setState(() {
																					final nuevo = Offset(
																						_posicionPorcentual!.dx + details.delta.dx / pageRect.width,
																						_posicionPorcentual!.dy + details.delta.dy / pageRect.height,
																					);
																					_posicionPorcentual = _limitar(nuevo, _paginaFirma);
																				});
																			}
																		: null,
																child: MouseRegion(
																	cursor: _modoManual ? SystemMouseCursors.grab : SystemMouseCursors.basic,
																	child: SizedBox(
																		width: _anchoFirma * escala,
																		height: _altoFirma * escala,
																		child: FittedBox(
																			fit: BoxFit.fill,
																			child: _firmaVisual(),
																		),
																	),
																),
															),
														),
													];
												},
											),
										),

										// Zona donde se suelta la firma (activa en modo manual)
										if (_modoManual)
											Positioned.fill(
												child: DragTarget<Uint8List>(
													onAcceptWithDetails: _alSoltar,
													builder: (context, candidateData, rejectedData) {
														return IgnorePointer(
															child: Container(
																color: candidateData.isNotEmpty
																		? context.primaryPurple.withValues(alpha: 0.05)
																		: Colors.transparent,
															),
														);
													},
												),
											),

										// Controles de zoom
										Positioned(
											top: 12,
											right: 12,
											child: Column(
												children: [
													_botonZoom(Icons.add_rounded, 'Acercar', () {
														if (_pdfController.isReady) _pdfController.zoomUp();
													}),
													const SizedBox(height: 8),
													_botonZoom(Icons.remove_rounded, 'Alejar', () {
														if (_pdfController.isReady) _pdfController.zoomDown();
													}),
													const SizedBox(height: 8),
													_botonZoom(Icons.fit_screen_rounded, 'Ajustar página', () {
														_irAPagina(_pdfController.pageNumber ?? 1);
													}),
												],
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

								if (!_modoManual) _selectorPosicion(),

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
											// El centro del feedback queda exactamente bajo el cursor
											dragAnchorStrategy: (draggable, context, position) =>
													const Offset(_anchoFirma / 2, _altoFirma / 2),
											feedback: Material(
												color: Colors.transparent,
												child: Opacity(
													opacity: 0.85,
													child: _firmaVisual(),
												),
											),
											childWhenDragging: Opacity(
												opacity: 0.3,
												child: _imagenFirma(size: 50),
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
														_imagenFirma(size: 50),
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

								// Selector de página (aparece cuando ya hay una firma colocada)
								if (_posicionPorcentual != null && _totalPaginas > 1) ...[
									const SizedBox(height: 24),
									Row(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											IconButton(
												onPressed: _paginaFirma > 1 ? () => _cambiarPagina(-1) : null,
												icon: const Icon(Icons.chevron_left_rounded),
											),
											Text(
												'Página $_paginaFirma de $_totalPaginas',
												style: TextStyle(
													fontSize: 14,
													fontWeight: FontWeight.w600,
													color: context.textDark,
												),
											),
											IconButton(
												onPressed: _paginaFirma < _totalPaginas ? () => _cambiarPagina(1) : null,
												icon: const Icon(Icons.chevron_right_rounded),
											),
										],
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