import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Pantalla de arranque. El tamaño del texto y del indicador
/// sale del lado más corto de la pantalla para que sirva en
/// teléfono, tablet y horizontal.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guestBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final shortest = width < height ? width : height;
            final titleSize = (shortest * 0.11).clamp(28.0, 64.0);
            final subtitleSize = (titleSize * 0.28).clamp(12.0, 18.0);
            final gap = (height * 0.045).clamp(16.0, 40.0);
            final indicator = (shortest * 0.07).clamp(28.0, 42.0);
            final horizontal = (width * 0.08).clamp(20.0, 72.0);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: titleSize,
                              height: 1.05,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
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
                      ),
                      SizedBox(height: gap * 0.35),
                      Text(
                        'BARBERÍA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.museum,
                          fontSize: subtitleSize,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        width: indicator,
                        height: indicator,
                        child: CircularProgressIndicator(
                          strokeWidth: (indicator * 0.08).clamp(2.0, 3.5),
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
