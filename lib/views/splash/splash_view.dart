import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Pantalla de arranque. El sello, el título y la barra
/// se calculan con el lado más corto para teléfono, tablet y horizontal.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guestBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final shortest = width < height ? width : height;
          final landscape = width > height;
          final mark = (shortest * (landscape ? 0.22 : 0.30)).clamp(
            72.0,
            148.0,
          );
          final titleSize = (shortest * (landscape ? 0.075 : 0.09)).clamp(
            26.0,
            52.0,
          );
          final subtitleSize = (titleSize * 0.28).clamp(11.0, 16.0);
          final gap = (height * 0.028).clamp(10.0, 28.0);
          final horizontal = (width * 0.08).clamp(20.0, 72.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const _SplashBackdrop(),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 20),
                  child: Column(
                    children: [
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _BrandMark(size: mark),
                            SizedBox(height: gap * 1.4),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                // Fraunces del tema, como el resto de la marca.
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      fontSize: titleSize,
                                      height: 1.05,
                                      color: AppColors.ivory,
                                    ),
                                children: const [
                                  TextSpan(text: 'Stylo'),
                                  TextSpan(
                                    text: ' Barber',
                                    style: TextStyle(color: AppColors.gold),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: gap * 0.5),
                            // Sin versalitas espaciadas (DESIGN.md).
                            Text(
                              'Barbería',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.muted,
                                    fontSize: subtitleSize * 1.25,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const _SplashStatus(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  // Suelo plano de la marca: sin halos ni brillos (DESIGN.md › Sin Sombra).
  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: AppColors.guestBg, child: SizedBox.expand());
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: (size * 0.012).clamp(1.0, 2.0),
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.78,
        height: size * 0.78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.gold,
            width: (size * 0.02).clamp(1.4, 2.6),
          ),
        ),
        child: Icon(
          Icons.content_cut,
          color: AppColors.gold,
          size: size * 0.32,
        ),
      ),
    );
  }
}

class _SplashStatus extends StatelessWidget {
  const _SplashStatus();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final barWidth = (width * 0.42).clamp(120.0, 180.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: barWidth,
          child: const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.gold,
            backgroundColor: AppColors.border,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Cargando',
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Muestra [SplashView] mientras se restaura la sesión y luego
/// entra a invitado, cliente o secretaría.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openNext());
  }

  Future<void> _openNext() async {
    final auth = context.read<AuthViewModel>();
    await Future.wait<void>([
      auth.bootstrap(),
      Future<void>.delayed(const Duration(milliseconds: 700)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(_routeFor(auth));
  }

  String _routeFor(AuthViewModel auth) {
    if (auth.phase == AuthPhase.authenticated) {
      if (auth.role.isStaffPanel) return AppRoutes.secretaryHome;
      return AppRoutes.clientHome;
    }
    return AppRoutes.guestHome;
  }

  @override
  Widget build(BuildContext context) => const SplashView();
}
