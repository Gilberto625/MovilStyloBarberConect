import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/config/app_fonts.dart';
import 'core/config/app_locale.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/catalog_list_viewmodel.dart';
import 'viewmodels/client_citas_viewmodel.dart';
import 'viewmodels/home_guest_viewmodel.dart';
import 'viewmodels/secretaria_gestion_viewmodel.dart';
import 'viewmodels/secretaria_hoy_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFonts.configurar();
  try {
    AppConfig.ambiente;
  } on AmbienteInvalido catch (e) {
    // Build mal configurado: se dice qué corregir en vez de arrancar contra
    // un backend equivocado.
    runApp(AmbienteInvalidoApp(mensaje: e.mensaje));
    return;
  }
  final scope = AppScope.create();
  runApp(StyloBarberApp(scope: scope));
}

class StyloBarberApp extends StatelessWidget {
  const StyloBarberApp({super.key, required this.scope});

  final AppScope scope;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppScope>.value(value: scope),
        ChangeNotifierProvider<AuthViewModel>.value(value: scope.authViewModel),
        ChangeNotifierProvider<HomeGuestViewModel>.value(
          value: scope.homeGuestViewModel,
        ),
        ChangeNotifierProvider<CatalogListViewModel>.value(
          value: scope.catalogListViewModel,
        ),
        ChangeNotifierProvider<ClientCitasViewModel>.value(
          value: scope.clientCitasViewModel,
        ),
        ChangeNotifierProvider<SecretariaHoyViewModel>.value(
          value: scope.secretariaHoyViewModel,
        ),
        ChangeNotifierProvider<SecretariaGestionViewModel>.value(
          value: scope.secretariaGestionViewModel,
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.panel(),
        locale: AppLocale.locale,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: AppLocale.delegates,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

/// Pantalla única cuando `APP_ENV`/`API_BASE_URL` no son válidos.
class AmbienteInvalidoApp extends StatelessWidget {
  const AmbienteInvalidoApp({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.panel(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_outlined, size: 40),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => Text(
                      'Configuración de ambiente no válida',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(mensaje, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
