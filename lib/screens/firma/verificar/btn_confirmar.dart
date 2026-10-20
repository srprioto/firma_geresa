import 'package:firmador_geresa/assets/theme/app_theme.dart';
import 'package:flutter/material.dart';

class VerifyButtons extends StatelessWidget {
	final VoidCallback onCancelar;
	final VoidCallback onVerificar;

	const VerifyButtons({super.key, 
		required this.onCancelar,
		required this.onVerificar,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(8),
			decoration: BoxDecoration(
				color: context.surfaceWhite,
				borderRadius: BorderRadius.circular(context.radiusPill),
				boxShadow: AppTheme.shadowMd,
				border: Border.all(color: context.borderColor),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					OutlinedButton(
						onPressed: onCancelar,
						style: OutlinedButton.styleFrom(
							backgroundColor: Colors.transparent,
							foregroundColor: context.textGrey,
							side: BorderSide.none,
							padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(context.radiusPill),
							),
						),
						child: const Text('Cancelar'),
					),
					const SizedBox(width: 8),
					ElevatedButton(
						onPressed: onVerificar,
						style: ElevatedButton.styleFrom(
							backgroundColor: context.primaryPurple,
							foregroundColor: Colors.white,
							elevation: 0,
							padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(context.radiusPill),
							),
						),
						child: const Text('Verificar firma'),
					),
				],
			),
		);
	}
}
