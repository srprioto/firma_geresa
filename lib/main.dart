import 'package:firmador_geresa/assets/theme/app_theme.dart';
import 'package:firmador_geresa/screens/nav/navi_bar.dart';

import 'package:flutter/material.dart';

void main() {
  	runApp(const FirmadorApp());
}

class FirmadorApp extends StatelessWidget {
	const FirmadorApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			theme: AppTheme.lightTheme,
			title: 'Firmador GERESA Cusco',
			// home: HomeScreenBtn(),
			home: const NaviBar(),
		);
	}
}



// /// Pantalla de inicio: solo 2 botones-enrutadores, sin diseño todavía.
// class HomeScreenBtn extends StatelessWidget {
// 	const HomeScreenBtn({super.key});

// 	@override
// 	Widget build(BuildContext context) {
// 		return Scaffold(
// 			appBar: AppBar(title: const Text('Firmador GERESA Cusco')),
// 			body: Center(
// 				child: Column(
// 					mainAxisSize: MainAxisSize.min,
// 					children: [
// 						ElevatedButton(
// 						onPressed: () {
// 							Navigator.of(context).push(
// 								MaterialPageRoute(
// 									// Ruta de respaldo fija de ejemplo; cámbiala o pásala
// 									// en null si todavía no quieres que guarde copia
// 									// automática en ningún lado.
// 									builder: (_) => const SignScreen(rutaBackup: null),
// 								),
// 							);
// 						},
// 						child: const Text('Firmar'),
// 						),
// 						const SizedBox(height: 16),
// 						ElevatedButton(
// 							onPressed: () {
// 								Navigator.of(context).push(
// 									MaterialPageRoute(builder: (_) => const VerifyScreen()),
// 								);
// 							},
// 							child: const Text('Confirmar'),
// 						),
// 					],
// 				),
// 			),
// 		);
// 	}
// }
