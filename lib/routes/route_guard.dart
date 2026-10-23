import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Guarda central de rutas (GH#70). Antes de mostrar un panel revisa que haya
/// sesión y que el rol le corresponda; si no, manda al acceso o al inicio de
/// su rol y no dibuja la pantalla. Es la capa de la app: quien autoriza de
/// verdad es Django, que responde 403 a cada endpoint ajeno.
class RouteGuard extends StatefulWidget {
  const RouteGuard({
    super.key,
    required this.permite,
    required this.child,
    required this.loginRoute,
    required this.homeFor,
  });

  final bool Function(UserRole role) permite;
  final Widget child;
  final String loginRoute;
  final String Function(UserRole role) homeFor;

  @override
  State<RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  bool _redirigiendo = false;

  @override
  Widget build(BuildContext context) {
    // read y no watch: al cerrar sesión, la pantalla que cierra decide a dónde
    // ir; la guarda solo actúa al construir la ruta.
    final auth = Provider.of<AuthViewModel?>(context, listen: false);
    final autenticado = auth?.phase == AuthPhase.authenticated;
    if (autenticado && widget.permite(auth!.role)) return widget.child;

    final destino = autenticado
        ? widget.homeFor(auth!.role)
        : widget.loginRoute;
    if (!_redirigiendo) {
      _redirigiendo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(destino, (_) => false);
      });
    }
    return const Scaffold(body: SizedBox.shrink());
  }
}
