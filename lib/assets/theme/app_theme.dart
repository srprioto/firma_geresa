import 'package:flutter/material.dart';

// ==========================================
// EXTENSIONES PARA ACCEDER FÁCILMENTE A COLORES Y DIMENSIONES
// ==========================================
extension AppColorsX on BuildContext {
	Color get primaryDark => AppTheme.primaryDark;
	Color get primaryBlue => AppTheme.primaryBlue;
	Color get backgroundLight => AppTheme.backgroundLight;
	Color get surfaceWhite => AppTheme.surfaceWhite;
	Color get textDark => AppTheme.textDark;
	Color get textGrey => AppTheme.textGrey;
	Color get textLight => AppTheme.textLight;
	Color get successGreen => AppTheme.successGreen;
	Color get warningOrange => AppTheme.warningOrange;
	Color get errorRed => AppTheme.errorRed;
	Color get chartPurple => AppTheme.chartPurple;
	Color get borderColor => AppTheme.borderColor;
	Color get dividerColor => AppTheme.dividerColor;
	Color get hoverOverlay => AppTheme.hoverOverlay;
}

extension AppDimensionsX on BuildContext {
	double get radiusSm => AppTheme.radiusSm;
	double get radiusMd => AppTheme.radiusMd;
	double get radiusLg => AppTheme.radiusLg;
	double get spaceXs => AppTheme.spaceXs;
	double get spaceSm => AppTheme.spaceSm;
	double get spaceMd => AppTheme.spaceMd;
	double get spaceLg => AppTheme.spaceLg;
	double get spaceXl => AppTheme.spaceXl;
}

class AppTheme {
	// ==========================================
	// 1. PALETA DE COLORES
	// ==========================================
	static const Color primaryDark = Color(0xFF1E2A38);
	static const Color primaryBlue = Color(0xFF0066FF);
	static const Color backgroundLight = Color(0xFFF5F7F9);
	static const Color surfaceWhite = Color(0xFFFFFFFF);

	// Colores de texto
	static const Color textDark = Color(0xFF1E2A38);
	static const Color textGrey = Color(0xFF6B7280);
	static const Color textLight = Color(0xFF9CA3AF);

	// Colores semánticos
	static const Color successGreen = Color(0xFF00A67E);
	static const Color warningOrange = Color(0xFFF59E0B);
	static const Color errorRed = Color(0xFFEF4444);
	static const Color infoBlue = Color(0xFF3B82F6);
	static const Color chartPurple = Color(0xFF8B5CF6);
	static const Color chartYellow = Color(0xFFFBBF24);

	// Bordes, divisores y overlays
	static const Color borderColor = Color(0xFFE5E7EB);
	static const Color dividerColor = Color(0xFFF3F4F6);
	static const Color hoverOverlay = Color(0xFFF9FAFB);
	static const Color focusOverlay = Color(0x140066FF);

	// ==========================================
	// 2. DIMENSIONES Y ESPACIADOS
	// ==========================================
	static const double radiusSm = 6.0;
	static const double radiusMd = 8.0;
	static const double radiusLg = 12.0;
	static const double radiusXl = 16.0;

	static const double spaceXs = 4.0;
	static const double spaceSm = 8.0;
	static const double spaceMd = 16.0;
	static const double spaceLg = 24.0;
	static const double spaceXl = 32.0;

	// ==========================================
	// 3. SOMBRAS REUTILIZABLES
	// ==========================================
	static const List<BoxShadow> shadowSm = [
		BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
	];
	static const List<BoxShadow> shadowMd = [
		BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
	];
	static const List<BoxShadow> shadowLg = [
		BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
	];

	// ==========================================
	// 4. THEME DATA
	// ==========================================
	static ThemeData get lightTheme {
		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.light,

			primaryColor: primaryDark,
			scaffoldBackgroundColor: backgroundLight,
			canvasColor: backgroundLight,
			dividerColor: dividerColor,
			cardColor: surfaceWhite,
			splashFactory: InkSparkle.splashFactory,

			// ColorScheme
			colorScheme: const ColorScheme.light(
				primary: primaryBlue,
				onPrimary: Colors.white,
				primaryContainer: primaryDark,
				onPrimaryContainer: Colors.white,
				secondary: primaryDark,
				onSecondary: Colors.white,
				secondaryContainer: Color(0xFFE0E7FF),
				onSecondaryContainer: primaryDark,
				tertiary: chartPurple,
				onTertiary: Colors.white,
				surface: surfaceWhite,
				onSurface: textDark,
				surfaceContainerHighest: hoverOverlay,
				onSurfaceVariant: textGrey,
				error: errorRed,
				onError: Colors.white,
				errorContainer: Color(0xFFFEE2E2),
				onErrorContainer: Color(0xFF991B1B),
				outline: borderColor,
				outlineVariant: dividerColor,
				shadow: Color(0xFF000000),
				scrim: Color(0x80000000),
			),

			// ==========================================
			// TIPOGRAFÍA COMPLETA
			// ==========================================
			textTheme: const TextTheme(
				displayLarge: TextStyle(color: textDark, fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.25),
				displayMedium: TextStyle(color: textDark, fontSize: 45, fontWeight: FontWeight.w700),
				displaySmall: TextStyle(color: textDark, fontSize: 36, fontWeight: FontWeight.w600),
				headlineLarge: TextStyle(color: textDark, fontSize: 32, fontWeight: FontWeight.w700),
				headlineMedium: TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w600),
				headlineSmall: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.w600),
				titleLarge: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.w700),
				titleMedium: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600),
				titleSmall: TextStyle(color: textGrey, fontSize: 14, fontWeight: FontWeight.w500),
				bodyLarge: TextStyle(color: textDark, fontSize: 16, height: 1.5),
				bodyMedium: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
				bodySmall: TextStyle(color: textLight, fontSize: 12, height: 1.4),
				labelLarge: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
				labelMedium: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w500),
				labelSmall: TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.w500),
			),

			// ==========================================
			// APPBAR
			// ==========================================
			appBarTheme: const AppBarTheme(
				backgroundColor: surfaceWhite,
				foregroundColor: textDark,
				elevation: 0,
				scrolledUnderElevation: 0,
				centerTitle: false,
				surfaceTintColor: Colors.transparent,
				titleTextStyle: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w600),
				iconTheme: IconThemeData(color: textGrey, size: 20),
				actionsIconTheme: IconThemeData(color: textGrey, size: 20),
			),

			// ==========================================
			// CARDS
			// ==========================================
			cardTheme: CardThemeData(
				color: surfaceWhite,
				surfaceTintColor: Colors.transparent,
				elevation: 0,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(radiusLg),
					side: const BorderSide(color: borderColor, width: 1),
				),
				margin: EdgeInsets.zero,
			),

			// ==========================================
			// BOTONES
			// ==========================================
			elevatedButtonTheme: ElevatedButtonThemeData(
				style: ElevatedButton.styleFrom(
					backgroundColor: primaryBlue,
					foregroundColor: Colors.white,
					disabledBackgroundColor: dividerColor,
					disabledForegroundColor: textLight,
					elevation: 0,
					padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
					minimumSize: const Size(0, 44),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
					textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
				),
			),

			outlinedButtonTheme: OutlinedButtonThemeData(
				style: OutlinedButton.styleFrom(
					foregroundColor: textDark,
					side: const BorderSide(color: borderColor),
					padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
					minimumSize: const Size(0, 44),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
					textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
				),
			),

			textButtonTheme: TextButtonThemeData(
				style: TextButton.styleFrom(
					foregroundColor: primaryBlue,
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
					textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
				),
			),

			iconButtonTheme: IconButtonThemeData(
				style: IconButton.styleFrom(
					foregroundColor: textGrey,
					highlightColor: hoverOverlay,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
				),
			),

			// ==========================================
			// INPUTS
			// ==========================================
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: surfaceWhite,
				contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
				hintStyle: const TextStyle(color: textLight, fontSize: 14),
				labelStyle: const TextStyle(color: textGrey, fontSize: 14),
				floatingLabelStyle: const TextStyle(color: primaryBlue, fontSize: 12),
				errorStyle: const TextStyle(color: errorRed, fontSize: 12),
				prefixIconColor: textGrey,
				suffixIconColor: textGrey,
				iconColor: textGrey,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					borderSide: const BorderSide(color: borderColor),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					borderSide: const BorderSide(color: borderColor),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					borderSide: const BorderSide(color: primaryBlue, width: 1.5),
				),
				errorBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					borderSide: const BorderSide(color: errorRed),
				),
				focusedErrorBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					borderSide: const BorderSide(color: errorRed, width: 1.5),
				),
				disabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					borderSide: const BorderSide(color: dividerColor),
				),
			),

			// ==========================================
			// DIVISORES
			// ==========================================
			dividerTheme: const DividerThemeData(
				color: dividerColor,
				thickness: 1,
				space: 1,
			),

			// ==========================================
			// SWITCHES / CHECKBOXES / RADIOS
			// ==========================================
			switchTheme: SwitchThemeData(
				thumbColor: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return Colors.white;
					return textLight;
				}),
				trackColor: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return primaryBlue;
					return dividerColor;
				}),
				trackOutlineColor: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return primaryBlue;
					return borderColor;
				}),
			),

			checkboxTheme: CheckboxThemeData(
				fillColor: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return primaryBlue;
					return Colors.transparent;
				}),
				checkColor: const WidgetStatePropertyAll(Colors.white),
				side: const BorderSide(color: borderColor, width: 1.5),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
			),

			radioTheme: RadioThemeData(
				fillColor: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return primaryBlue;
					return textGrey;
				}),
			),

			// ==========================================
			// CHIPS
			// ==========================================
			chipTheme: ChipThemeData(
				backgroundColor: hoverOverlay,
				selectedColor: primaryBlue.withOpacity(0.1),
				disabledColor: dividerColor,
				labelStyle: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500),
				secondaryLabelStyle: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w600),
				side: const BorderSide(color: borderColor),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
			),

			// ==========================================
			// TOOLTIPS
			// ==========================================
			tooltipTheme: TooltipThemeData(
				decoration: BoxDecoration(
					color: primaryDark,
					borderRadius: BorderRadius.circular(radiusSm),
				),
				textStyle: const TextStyle(color: Colors.white, fontSize: 12),
				padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
				waitDuration: const Duration(milliseconds: 300),
			),

			// ==========================================
			// DIÁLOGOS
			// ==========================================
			dialogTheme: DialogThemeData(
				backgroundColor: surfaceWhite,
				surfaceTintColor: Colors.transparent,
				elevation: 0,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
				titleTextStyle: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w600),
				contentTextStyle: const TextStyle(color: textGrey, fontSize: 14, height: 1.5),
			),

			// ==========================================
			// MENÚS / POPOVERS
			// ==========================================
			popupMenuTheme: PopupMenuThemeData(
				color: surfaceWhite,
				surfaceTintColor: Colors.transparent,
				elevation: 8,
				shadowColor: const Color(0x1F000000),
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(radiusMd),
					side: const BorderSide(color: borderColor),
				),
				textStyle: const TextStyle(color: textDark, fontSize: 14),
				labelTextStyle: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return const TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.w600);
					return const TextStyle(color: textDark, fontSize: 14);
				}),
			),

			// ==========================================
			// TABLAS
			// ==========================================
			dataTableTheme: DataTableThemeData(
				decoration: BoxDecoration(
					color: surfaceWhite,
					borderRadius: BorderRadius.circular(radiusLg),
					border: Border.all(color: borderColor),
				),
				headingRowColor: WidgetStatePropertyAll(hoverOverlay),
				headingTextStyle: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
				dataTextStyle: const TextStyle(color: textGrey, fontSize: 13),
				dividerThickness: 1,
				horizontalMargin: 16,
				columnSpacing: 24,
				headingRowHeight: 48,
				dataRowMinHeight: 52,
				dataRowMaxHeight: 52,
			),

			// ==========================================
			// LISTAS
			// ==========================================
			listTileTheme: ListTileThemeData(
				contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
				iconColor: textGrey,
				textColor: textDark,
				titleTextStyle: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w500),
				subtitleTextStyle: const TextStyle(color: textGrey, fontSize: 12),
				selectedTileColor: primaryBlue.withOpacity(0.08),
				selectedColor: primaryBlue,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
			),

			// ==========================================
			// NAVEGACIÓN
			// ==========================================
			navigationRailTheme: NavigationRailThemeData(
				backgroundColor: primaryDark,
				selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
				unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6), size: 22),
				selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
				unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
				indicatorColor: Colors.white.withOpacity(0.1),
				useIndicator: true,
			),

			navigationBarTheme: NavigationBarThemeData(
				backgroundColor: surfaceWhite,
				indicatorColor: primaryBlue.withOpacity(0.1),
				labelTextStyle: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w600);
					return const TextStyle(color: textGrey, fontSize: 12);
				}),
				iconTheme: WidgetStateProperty.resolveWith((states) {
					if (states.contains(WidgetState.selected)) return const IconThemeData(color: primaryBlue, size: 22);
					return const IconThemeData(color: textGrey, size: 22);
				}),
			),

			drawerTheme: DrawerThemeData(
				backgroundColor: primaryDark,
				surfaceTintColor: Colors.transparent,
				shape: const RoundedRectangleBorder(),
				width: 260,
			),

			// ==========================================
			// PROGRESO / SLIDER
			// ==========================================
			progressIndicatorTheme: const ProgressIndicatorThemeData(
				color: primaryBlue,
				linearTrackColor: dividerColor,
				circularTrackColor: dividerColor,
			),

			sliderTheme: SliderThemeData(
				activeTrackColor: primaryBlue,
				inactiveTrackColor: dividerColor,
				thumbColor: primaryBlue,
				overlayColor: primaryBlue.withOpacity(0.1),
				trackHeight: 4,
				thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
			),

			// ==========================================
			// SNACKBARS
			// ==========================================
			snackBarTheme: SnackBarThemeData(
				backgroundColor: primaryDark,
				contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
				actionTextColor: primaryBlue,
				behavior: SnackBarBehavior.floating,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
				elevation: 4,
			),

			// ==========================================
			// SCROLLBAR
			// ==========================================
			scrollbarTheme: ScrollbarThemeData(
				thumbColor: WidgetStatePropertyAll(textLight.withOpacity(0.5)),
				trackColor: const WidgetStatePropertyAll(Colors.transparent),
				thickness: const WidgetStatePropertyAll(6),
				radius: const Radius.circular(3),
				crossAxisMargin: 2,
				mainAxisMargin: 2,
			),

			// ==========================================
			// BOTTOM SHEET
			// ==========================================
			bottomSheetTheme: BottomSheetThemeData(
				backgroundColor: surfaceWhite,
				surfaceTintColor: Colors.transparent,
				elevation: 0,
				shape: const RoundedRectangleBorder(
					borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
				),
			),

			// ==========================================
			// TABS
			// ==========================================
			tabBarTheme: TabBarThemeData(
				labelColor: primaryBlue,
				unselectedLabelColor: textGrey,
				labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
				unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
				indicatorSize: TabBarIndicatorSize.label,
				indicator: UnderlineTabIndicator(
					borderSide: const BorderSide(color: primaryBlue, width: 2),
					borderRadius: BorderRadius.circular(2),
				),
				dividerColor: borderColor,
			),
		);
	}
}