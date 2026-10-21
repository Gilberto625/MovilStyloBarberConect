import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/widgets/common_widgets.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.panel(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: app!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Tema "Barbería de noche"', () {
    testWidgets('el texto sobre latón es tinta oscura, nunca blanco', (
      tester,
    ) async {
      final theme = AppTheme.guest();
      expect(theme.colorScheme.primary, AppColors.gold);
      expect(theme.colorScheme.onPrimary, AppColors.onGold);
      final boton = theme.elevatedButtonTheme.style!;
      expect(boton.foregroundColor!.resolve({}), AppColors.onGold);
      expect(boton.backgroundColor!.resolve({}), AppColors.gold);
    });

    testWidgets('sin sombras: tarjetas, barra y diálogos van planos', (
      tester,
    ) async {
      final theme = AppTheme.panel();
      expect(theme.cardTheme.elevation, 0);
      expect(theme.navigationBarTheme.elevation, 0);
      expect(theme.dialogTheme.elevation, 0);
      expect(theme.colorScheme.shadow, Colors.transparent);
    });

    testWidgets('botones táctiles de 52 dp y objetivos de al menos 48 dp', (
      tester,
    ) async {
      final theme = AppTheme.guest();
      expect(
        theme.elevatedButtonTheme.style!.minimumSize!.resolve({})!.height,
        52,
      );
      expect(
        theme.textButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
      expect(
        theme.iconButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('cada tema conserva su suelo de marca', (tester) async {
      expect(AppTheme.guest().scaffoldBackgroundColor, AppColors.guestBg);
      expect(AppTheme.panel().scaffoldBackgroundColor, AppColors.panelBg);
    });

    testWidgets('las cifras usan números tabulares', (tester) async {
      final style = AppText.cifra();
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });
  });

  group('AppMotion', () {
    testWidgets('respeta reducir movimiento', (tester) async {
      late Duration normal;
      late Duration reducida;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            normal = AppMotion.of(context, AppMotion.entrance);
            return const SizedBox();
          },
        ),
      );
      await _pump(
        tester,
        Builder(
          builder: (context) {
            reducida = AppMotion.of(context, AppMotion.entrance);
            return const SizedBox();
          },
        ),
        disableAnimations: true,
      );
      expect(normal, const Duration(milliseconds: 220));
      expect(reducida, Duration.zero);
      expect(AppMotion.entrance.inMilliseconds, lessThan(300));
    });
  });

  group('EstadoChip', () {
    test('traduce los estados del backend a palabras', () {
      expect(EstadoChip.etiqueta('no_asistio'), 'No asistió');
      expect(EstadoChip.etiqueta('en_curso'), 'En sala');
      expect(EstadoChip.etiqueta('confirmada'), 'Confirmada');
      expect(EstadoChip.etiqueta('estado_nuevo'), 'Estado nuevo');
      expect(EstadoChip.etiqueta(''), 'Sin estado');
    });

    test('el color sigue el significado', () {
      expect(EstadoChip.color('completada'), AppColors.ok);
      expect(EstadoChip.color('pendiente'), AppColors.warn);
      expect(EstadoChip.color('no_asistio'), AppColors.crit);
    });

    testWidgets('muestra la palabra, no el código', (tester) async {
      await _pump(tester, const EstadoChip(estado: 'no_asistio'));
      expect(find.text('No asistió'), findsOneWidget);
      expect(find.text('no_asistio'), findsNothing);
    });

    testWidgets('un estado largo en poco espacio no desborda', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 90,
          child: EstadoChip(estado: 'un_estado_muy_largo_del_servidor'),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Estados de pantalla', () {
    testWidgets('EmptyView con título, mensaje y acción', (tester) async {
      var reintentos = 0;
      await _pump(
        tester,
        EmptyView(
          title: 'Aún no tienes citas',
          message: 'Agenda la primera desde Agendar.',
          actionLabel: 'Agendar',
          onRetry: () => reintentos++,
        ),
      );
      expect(find.text('Aún no tienes citas'), findsOneWidget);
      await tester.tap(find.text('Agendar'));
      expect(reintentos, 1);
    });

    testWidgets('ErrorView ofrece reintentar', (tester) async {
      var reintentos = 0;
      await _pump(
        tester,
        ErrorView(
          message: 'No se pudo cargar la agenda.',
          onRetry: () => reintentos++,
        ),
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('StatusBanner usa el icono de su tono', (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            StatusBanner(message: 'Error', isError: true),
            StatusBanner(message: 'Listo', tone: BannerTone.ok),
            StatusBanner(message: 'Pendiente'),
          ],
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  });

  group('Piezas de diseño', () {
    testWidgets('InfoRow, SectionHeader y SurfaceCard a 360×800 y texto 1.3', (
      tester,
    ) async {
      var tocada = 0;
      var accion = 0;
      await _pump(
        tester,
        Column(
          children: [
            SectionHeader(
              title: 'Próxima cita con un título bastante largo',
              action: 'Ver todas',
              onAction: () => accion++,
            ),
            SurfaceCard(
              onTap: () => tocada++,
              child: const Column(
                children: [
                  InfoRow(label: 'Hora', value: '10:30', emphasis: true),
                  InfoRow(
                    label: 'Barbero',
                    value: 'Alejandro Hernández Hernández de la Cruz',
                    icon: Icons.person_outline,
                  ),
                ],
              ),
            ),
          ],
        ),
        size: const Size(360, 800),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Ver todas'));
      await tester.tap(find.text('10:30'));
      expect(accion, 1);
      expect(tocada, 1);
    });
  });
}
