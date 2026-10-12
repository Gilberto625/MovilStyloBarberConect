import 'package:flutter/material.dart';

import '../models/cita_models.dart';
import '../views/auth/login_views.dart';
import '../views/client/client_home_view.dart';
import '../views/guest/catalog_list_views.dart';
import '../views/guest/guest_home_view.dart';
import '../views/secretary/secretary_gestion_views.dart';
import '../views/secretary/secretary_home_view.dart';
import '../views/secretary/secretary_shell.dart';

class AppRoutes {
  static const guestHome = '/';
  static const servicios = '/servicios';
  static const productos = '/productos';
  static const login = '/login';
  static const verify2fa = '/verify-2fa';
  static const clientHome = '/cliente';
  static const secretaryHome = '/secretaria';
  static const secretaryCitaDetail = '/secretaria/cita';
  static const secretaryNuevaCita = '/secretaria/cita/nueva';
  static const secretaryClienteCitas = '/secretaria/cliente-citas';
  static const secretaryReprogramar = '/secretaria/cita/editar';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = _pageFor(settings);
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  static Widget _pageFor(RouteSettings settings) {
    switch (settings.name) {
      case guestHome:
        return const GuestHomeView();
      case servicios:
        return const ServiciosListView();
      case productos:
        return const ProductosListView();
      case login:
        return const LoginView();
      case verify2fa:
        return const Verify2FAView();
      case clientHome:
        return const ClientHomeShell();
      case secretaryHome:
        return const SecretaryShell();
      case secretaryCitaDetail:
        final cita = settings.arguments;
        if (cita is! SecretariaCitaDto) {
          return const Scaffold(body: Center(child: Text('Cita no válida')));
        }
        return SecretaryCitaDetailView(cita: cita);
      case secretaryNuevaCita:
        return const SecretaryNuevaCitaView();
      case secretaryClienteCitas:
        return const SecretaryClienteCitasView();
      case secretaryReprogramar:
        final citaId = settings.arguments;
        if (citaId is! int) {
          return const Scaffold(body: Center(child: Text('Cita no válida')));
        }
        return SecretaryReprogramarView(citaId: citaId);
      default:
        return const GuestHomeView();
    }
  }
}
