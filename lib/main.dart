import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
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
