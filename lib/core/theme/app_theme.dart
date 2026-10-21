import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores de "Barbería de noche" (DESIGN.md). Los nombres heredados se
/// conservan; las capas nuevas siguen la escala tonal del documento.
class AppColors {
  AppColors._();

  // Suelos
  static const guestBg = Color(0xFF0A100E); // verde noche
  static const panelBg = Color(0xFF0D0D0D); // negro sillón

  // Capas de cuero verde, de la más honda a la más alta.
  static const guestCard = Color(0xFF0E1612); // cuero verde hondo
  static const surface = Color(0xFF14211B); // cuero verde
  static const surfaceHigh = Color(0xFF1B2A23); // cuero verde claro
  static const guestCardProduct = Color(0xFF0C120F);
  static const panelCard = Color(0xFF141414); // carbón (heredado)

  // Latón
  static const gold = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFB8941F);
  static const goldSoft = Color(0xFFE2C76B);
  static const onGold = Color(0xFF0A120E);

  // Texto y apoyo
  static const ivory = Color(0xFFF4F0E8); // marfil
  static const text = Color(0xFFEBF0E7);
  static const textPanel = Color(0xFFF5F4EF);
  static const museum = Color(0xFF718F83); // salvia
  static const muted = Color(0xFFA6BAB0); // niebla
  static const border = Color(0xFF3D4F49); // filo

  // Estados
  static const ok = Color(0xFF34D66B);
  static const warn = Color(0xFFE2B35A);
  static const crit = Color(0xFFF45B5B);
}

/// Escala de 4 dp (DESIGN.md › Layout).
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;

  /// Margen lateral de pantalla en teléfono.
  static const page = 20.0;

  /// Ancho máximo de la columna en tablet.
  static const maxContent = 640.0;

  /// Alto mínimo de una fila de cita (accesibilidad y lectura rápida).
  static const appointmentRow = 72.0;
}

/// Radios por jerarquía (DESIGN.md › Shapes).
class AppRadii {
  AppRadii._();

  static const chip = 10.0;
  static const control = 14.0;
  static const card = 18.0;
  static const sheet = 24.0;

  static final controlBorder = BorderRadius.circular(control);
  static final cardBorder = BorderRadius.circular(card);
}

/// Motion: ease-out corto que responde al usuario (emil-design-eng).
class AppMotion {
  AppMotion._();

  static const ease = Cubic(0.23, 1, 0.32, 1);
  static const press = Duration(milliseconds: 120);
  static const quick = Duration(milliseconds: 180);
  static const entrance = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 240);
  static const stagger = Duration(milliseconds: 40);

  /// Respeta "reducir movimiento": devuelve cero si el sistema lo pide.
  static Duration of(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// Estilos de apoyo que no son roles de Material.
class AppText {
  AppText._();

  /// Horas, precios y montos con cifras tabulares, para que se alineen.
  static TextStyle cifra({
    double size = 16,
    Color color = AppColors.ivory,
    FontWeight weight = FontWeight.w700,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData guest() =>
      _build(ground: AppColors.guestBg, onSurface: AppColors.text);

  static ThemeData panel() =>
      _build(ground: AppColors.panelBg, onSurface: AppColors.textPanel);

  static ThemeData _build({required Color ground, required Color onSurface}) {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      primaryContainer: AppColors.goldDark,
      onPrimaryContainer: AppColors.onGold,
      secondary: AppColors.museum,
      onSecondary: AppColors.onGold,
      secondaryContainer: AppColors.surfaceHigh,
      onSecondaryContainer: AppColors.ivory,
      tertiary: AppColors.goldSoft,
      onTertiary: AppColors.onGold,
      error: AppColors.crit,
      onError: AppColors.onGold,
      surface: AppColors.surface,
      onSurface: onSurface,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: ground,
      surfaceContainerLow: AppColors.guestCard,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      inverseSurface: AppColors.ivory,
      onInverseSurface: AppColors.onGold,
      inversePrimary: AppColors.goldDark,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
      scrim: Colors.black,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      splashFactory: InkSparkle.splashFactory,
    );
    return _withComponents(base, ground: ground);
  }

  static TextTheme _textTheme(ThemeData base) {
    final on = base.colorScheme.onSurface;
    TextStyle fraunces(
      double size,
      FontWeight weight,
      double height, {
      double spacing = 0,
    }) => GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: AppColors.ivory,
    );
    TextStyle manrope(
      double size,
      FontWeight weight,
      double height, {
      Color? color,
      double spacing = 0,
    }) => GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color ?? on,
    );
    return TextTheme(
      displayLarge: fraunces(44, FontWeight.w600, 1.05, spacing: -0.8),
      displayMedium: fraunces(40, FontWeight.w600, 1.08, spacing: -0.6),
      displaySmall: fraunces(36, FontWeight.w600, 1.1, spacing: -0.5),
      headlineLarge: fraunces(30, FontWeight.w500, 1.15),
      headlineMedium: fraunces(28, FontWeight.w500, 1.18),
      headlineSmall: fraunces(26, FontWeight.w500, 1.2),
      titleLarge: fraunces(20, FontWeight.w500, 1.25),
      titleMedium: manrope(16, FontWeight.w700, 1.3, color: AppColors.ivory),
      titleSmall: manrope(14, FontWeight.w700, 1.3, color: AppColors.ivory),
      bodyLarge: manrope(16, FontWeight.w500, 1.45),
      bodyMedium: manrope(15, FontWeight.w500, 1.45),
      bodySmall: manrope(13, FontWeight.w500, 1.4, color: AppColors.muted),
      labelLarge: manrope(15, FontWeight.w700, 1.2, spacing: 0.1),
      labelMedium: manrope(13, FontWeight.w600, 1.3, spacing: 0.2),
      labelSmall: manrope(
        12,
        FontWeight.w600,
        1.3,
        spacing: 0.2,
        color: AppColors.muted,
      ),
    );
  }

  static ThemeData _withComponents(ThemeData base, {required Color ground}) {
    final text = _textTheme(base);
    final control = RoundedRectangleBorder(
      borderRadius: AppRadii.controlBorder,
    );
    const buttonSize = Size(64, 52);
    final label = text.labelLarge!;

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ivory,
        titleTextStyle: text.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.muted,
          textStyle: label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: control,
        ).copyWith(overlayColor: _pressOverlay(AppColors.goldDark)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.muted,
          textStyle: label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: control,
        ).copyWith(overlayColor: _pressOverlay(AppColors.goldDark)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.2),
          textStyle: label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: control,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.gold,
          textStyle: label,
          shape: control,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.ivory,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: text.bodyMedium!.copyWith(color: AppColors.muted),
        floatingLabelStyle: text.labelMedium!.copyWith(color: AppColors.gold),
        hintStyle: text.bodyMedium!.copyWith(color: AppColors.muted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall!.copyWith(color: AppColors.crit),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: _field(AppColors.border),
        enabledBorder: _field(AppColors.border),
        focusedBorder: _field(AppColors.gold, width: 1.4),
        errorBorder: _field(AppColors.crit),
        focusedErrorBorder: _field(AppColors.crit, width: 1.4),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: AppColors.gold.withValues(alpha: 0.28),
        selectionHandleColor: AppColors.gold,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.gold.withValues(alpha: 0.18),
        disabledColor: AppColors.guestCard,
        side: const BorderSide(color: AppColors.border),
        labelStyle: text.labelMedium!.copyWith(color: AppColors.text),
        secondaryLabelStyle: text.labelMedium!.copyWith(color: AppColors.ivory),
        checkmarkColor: AppColors.gold,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.guestCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.ivory
                : AppColors.muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.guestCard,
        indicatorColor: AppColors.gold.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: const IconThemeData(color: AppColors.gold),
        unselectedIconTheme: const IconThemeData(color: AppColors.muted),
        selectedLabelTextStyle: text.labelMedium!.copyWith(
          color: AppColors.ivory,
        ),
        unselectedLabelTextStyle: text.labelMedium!.copyWith(
          color: AppColors.muted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: text.bodyMedium!.copyWith(color: AppColors.ivory),
        actionTextColor: AppColors.gold,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.controlBorder,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.gold,
        textColor: AppColors.ivory,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onGold
              : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.surface,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.border,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.surfaceHigh,
        circularTrackColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: text.labelMedium!.copyWith(color: AppColors.ivory),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.surface,
        headerForegroundColor: AppColors.ivory,
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.gold),
        todayBorder: const BorderSide(color: AppColors.gold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
        ),
      ),
    );
  }

  static OutlineInputBorder _field(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppRadii.controlBorder,
        borderSide: BorderSide(color: color, width: width),
      );

  static WidgetStateProperty<Color?> _pressOverlay(Color pressed) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? pressed.withValues(alpha: 0.35)
            : null,
      );
}
