// CORE-001 (GH#68): prueba de arranque por ambiente con los --dart-define
// reales del build. Sin defines corre como dev (CI de PR). Para los otros:
//
//   flutter test test/ambientes/arranque_ambiente_test.dart \
//     --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
//   flutter test test/ambientes/arranque_ambiente_test.dart \
//     --dart-define=APP_ENV=prod
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/config/app_config.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';

import '../mocks/mocks.mocks.dart';
import '../support/memory_token_storage.dart';

void main() {
  final a = AppConfig.ambiente;

  test('CORE-001 el build resuelve su ambiente (${a.env.name})', () {
    expect(
      a.env.name,
      AppConfig.appEnvDefine.trim().toLowerCase().isEmpty
          ? 'dev'
          : AppConfig.appEnvDefine.trim().toLowerCase(),
    );
    expect(AppConfig.apiBaseUrl, a.apiBaseUrl);
    if (a.esProd) {
      expect(Uri.parse(a.apiBaseUrl).scheme, 'https');
    }
    // El cliente HTTP usa la misma URL base que el ambiente.
    final api = ApiClient(tokenStorage: MemoryTokenStorage());
    expect(api.baseUrl, a.apiBaseUrl);
  });

  testWidgets('CORE-001 arranque en ${a.env.name}: etiqueta en el acceso', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: AuthViewModel(MockAuthRepository()),
        child: MaterialApp(theme: AppTheme.guest(), home: const LoginView()),
      ),
    );
    await tester.pumpAndSettle();
    final etiqueta = find.byKey(const Key('etiqueta_ambiente'));
    await tester.scrollUntilVisible(
      a.esProd ? find.byKey(const Key('login_aviso_privacidad')) : etiqueta,
      200,
      // El primero es la lista de la pantalla; los campos traen el suyo.
      scrollable: find.byType(Scrollable).first,
    );
    if (a.esProd) {
      expect(etiqueta, findsNothing);
      expect(find.textContaining('DEV'), findsNothing);
      expect(find.textContaining('STAGING'), findsNothing);
    } else {
      expect(etiqueta, findsOneWidget);
      expect(find.textContaining(a.etiqueta!), findsOneWidget);
    }
  });
}
