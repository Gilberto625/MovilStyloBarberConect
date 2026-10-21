import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/app_scope.dart';

import '../models/cita_models.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/privacidad_viewmodels.dart';
import '../views/auth/login_views.dart';
import '../views/client/client_home_view.dart';
import '../views/guest/catalog_list_views.dart';
import '../views/guest/guest_home_view.dart';
import '../views/privacy/aviso_privacidad_view.dart';
import '../views/privacy/editar_perfil_view.dart';
import '../views/privacy/mis_datos_view.dart';
import '../views/privacy/privacidad_view.dart';
import '../views/secretary/secretary_gestion_views.dart';
import '../views/secretary/secretary_home_view.dart';
import '../views/secretary/secretary_shell.dart';
import '../views/splash/splash_view.dart';

class AppRoutes {
  static const splash = '/splash';
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
  static const privacidad = '/privacidad';
  static const misDatos = '/privacidad/mis-datos';
  static const editarPerfil = '/privacidad/editar-perfil';
  static const avisoPrivacidad = '/aviso-privacidad';

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
      case splash:
        return const SplashGate();
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
      case privacidad:
        return const PrivacidadView();
      // Las pantallas de privacidad crean su ViewModel por ruta: no comparten
      // estado entre usuarios (PM09) y se liberan al salir.
      case misDatos:
        return ChangeNotifierProvider(
          create: (context) =>
              MisDatosViewModel(context.read<AppScope>().privacidadRepository),
          child: const MisDatosView(),
        );
      case editarPerfil:
        return ChangeNotifierProvider(
          create: (context) => EditarPerfilViewModel(
            context.read<AppScope>().privacidadRepository,
          ),
          child: const EditarPerfilView(),
        );
      case avisoPrivacidad:
        return ChangeNotifierProvider(
          create: (context) => AvisoPrivacidadViewModel(
            context.read<AppScope>().privacidadRepository,
            autenticado:
                context.read<AuthViewModel>().phase == AuthPhase.authenticated,
          ),
          child: const AvisoPrivacidadView(),
        );
      default:
        return const GuestHomeView();
    }
  }
}
