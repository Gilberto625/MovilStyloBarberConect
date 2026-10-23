import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/di/app_scope.dart';

import '../core/theme/app_theme.dart';
import '../models/auth_models.dart';
import '../models/catalog_models.dart';
import '../models/cita_models.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/barbero_agenda_viewmodel.dart';
import '../viewmodels/privacidad_viewmodels.dart';
import '../views/auth/login_views.dart';
import '../views/barber/barbero_agenda_view.dart';
import '../views/auth/registro_views.dart';
import '../views/client/client_home_view.dart';
import '../views/guest/catalog_detail_views.dart';
import '../views/guest/catalog_list_views.dart';
import '../views/guest/guest_home_view.dart';
import '../views/privacy/aviso_privacidad_view.dart';
import '../views/privacy/eliminar_cuenta_view.dart';
import '../views/privacy/editar_perfil_view.dart';
import '../views/privacy/mis_datos_view.dart';
import '../views/privacy/privacidad_view.dart';
import '../views/secretary/secretary_gestion_views.dart';
import '../views/secretary/secretary_home_view.dart';
import '../views/secretary/secretary_shell.dart';
import '../views/splash/splash_view.dart';
import 'route_guard.dart';

class AppRoutes {
  static const splash = '/splash';
  static const guestHome = '/';
  static const servicios = '/servicios';
  static const productos = '/productos';
  static const servicioDetalle = '/servicio';
  static const productoDetalle = '/producto';
  static const login = '/login';
  static const verify2fa = '/verify-2fa';
  static const registro = '/registro';
  static const registroVerificar = '/registro/verificar';
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
  static const eliminarCuenta = '/privacidad/eliminar-cuenta';
  static const barberHome = '/barbero';

  /// Inicio de cada rol después de entrar o al abrir la app con sesión.
  static String homeFor(UserRole role) {
    if (role.isStaffPanel) return secretaryHome;
    if (role == UserRole.barbero) return barberHome;
    return clientHome;
  }

  static bool _esCliente(UserRole r) =>
      !r.isStaffPanel && r != UserRole.barbero;
  static bool _esSecretaria(UserRole r) => r.isStaffPanel;
  static bool _esBarbero(UserRole r) => r == UserRole.barbero;
  static bool _conSesion(UserRole r) => true;

  static Widget _guard(bool Function(UserRole) permite, Widget child) =>
      RouteGuard(
        permite: permite,
        loginRoute: login,
        homeFor: homeFor,
        child: child,
      );

  static Route<dynamic> onGenerateRoute(RouteSettings settings) =>
      page<void>(_guarded(settings), settings: settings);

  /// GH#70: cada panel pasa por la guarda de sesión y rol.
  static Widget _guarded(RouteSettings settings) {
    final page = _pageFor(settings);
    return switch (settings.name) {
      clientHome => _guard(_esCliente, page),
      barberHome => _guard(_esBarbero, page),
      secretaryHome ||
      secretaryCitaDetail ||
      secretaryNuevaCita ||
      secretaryClienteCitas ||
      secretaryReprogramar => _guard(_esSecretaria, page),
      privacidad ||
      misDatos ||
      editarPerfil ||
      eliminarCuenta => _guard(_conSesion, page),
      _ => page,
    };
  }

  /// Ruta con la transición de la marca. Sirve también para pantallas que
  /// reciben su ViewModel por constructor (carrito, detalle de cita).
  static Route<T> page<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppMotion.page,
      reverseTransitionDuration: AppMotion.quick,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.ease,
          reverseCurve: Curves.easeIn,
        );
        // Fundido con un ascenso corto (≈2 % del alto), sin escala ni rebote.
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
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
      case servicioDetalle:
        final args = settings.arguments;
        if (args is CatalogDetailArgs<ServicioDto>) {
          return ServicioDetailView(
            servicio: args.item,
            heroTag: args.heroTag,
            accion: args.accion,
          );
        }
        if (args is ServicioDto) return ServicioDetailView(servicio: args);
        return const Scaffold(body: Center(child: Text('Servicio no válido')));
      case productoDetalle:
        final args = settings.arguments;
        if (args is CatalogDetailArgs<ProductoDto>) {
          return ProductoDetailView(
            producto: args.item,
            heroTag: args.heroTag,
            accion: args.accion,
          );
        }
        if (args is ProductoDto) return ProductoDetailView(producto: args);
        return const Scaffold(body: Center(child: Text('Producto no válido')));
      case login:
        return const LoginView();
      case verify2fa:
        return const Verify2FAView();
      case registro:
        return const RegistroView();
      case registroVerificar:
        return const VerificarRegistroView();
      case clientHome:
        return const ClientHomeShell();
      case secretaryHome:
        return const SecretaryShell();
      // Se crea por ruta: la agenda no pasa de una cuenta a otra (PM09).
      case barberHome:
        return ChangeNotifierProvider(
          create: (context) => BarberoAgendaViewModel(
            context.read<AppScope>().barberoRepository,
          ),
          child: const BarberoAgendaView(),
        );
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
      case eliminarCuenta:
        return ChangeNotifierProvider(
          create: (context) => EliminarCuentaViewModel(
            context.read<AppScope>().privacidadRepository,
          ),
          child: const EliminarCuentaView(),
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
