import 'package:flutter/material.dart';

import '../models/cita_models.dart';
import '../views/auth/login_views.dart';
import '../views/client/client_home_view.dart';
import '../views/guest/catalog_list_views.dart';
import '../views/guest/guest_home_view.dart';
import '../views/secretary/secretary_home_view.dart';

class AppRoutes {
  static const guestHome = '/';
  static const servicios = '/servicios';
  static const productos = '/productos';
  static const login = '/login';
  static const verify2fa = '/verify-2fa';
  static const clientHome = '/cliente';
  static const secretaryHome = '/secretaria';
  static const secretaryCitaDetail = '/secretaria/cita';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case guestHome:
        return MaterialPageRoute(
          builder: (_) => const GuestHomeView(),
          settings: settings,
        );
      case servicios:
        return MaterialPageRoute(
          builder: (_) => const ServiciosListView(),
          settings: settings,
        );
      case productos:
        return MaterialPageRoute(
          builder: (_) => const ProductosListView(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginView(),
          settings: settings,
        );
      case verify2fa:
        return MaterialPageRoute(
          builder: (_) => const Verify2FAView(),
          settings: settings,
        );
      case clientHome:
        return MaterialPageRoute(
          builder: (_) => const ClientHomeShell(),
          settings: settings,
        );
      case secretaryHome:
        return MaterialPageRoute(
          builder: (_) => const SecretaryHomeView(),
          settings: settings,
        );
      case secretaryCitaDetail:
        final cita = settings.arguments;
        if (cita is! SecretariaCitaDto) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Cita no válida'))),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SecretaryCitaDetailView(cita: cita),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const GuestHomeView(),
          settings: settings,
        );
    }
  }
}
