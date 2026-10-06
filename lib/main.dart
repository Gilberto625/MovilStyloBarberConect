import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/catalog_list_viewmodel.dart';
import 'viewmodels/client_citas_viewmodel.dart';
import 'viewmodels/home_guest_viewmodel.dart';
import 'viewmodels/secretaria_hoy_viewmodel.dart';
import 'models/auth_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final scope = AppScope.create();
  await scope.authViewModel.bootstrap();
  runApp(StyloBarberApp(scope: scope));
}

class StyloBarberApp extends StatelessWidget {
  const StyloBarberApp({super.key, required this.scope});

  final AppScope scope;

  String get _initialRoute {
    final auth = scope.authViewModel;
    if (auth.phase == AuthPhase.authenticated) {
      if (auth.role.isStaffPanel) return AppRoutes.secretaryHome;
      return AppRoutes.clientHome;
    }
    return AppRoutes.guestHome;
  }

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
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.panel(),
        initialRoute: _initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
