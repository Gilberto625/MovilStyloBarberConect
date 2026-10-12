import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/views/splash/splash_view.dart';

class _SessionRepository implements AuthRepository {
  final session = Completer<AuthUser?>();
  int restores = 0;

  @override
  Future<AuthUser?> restoreSession() {
    restores++;
    return session.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final role in <UserRole?>[
    null,
    UserRole.cliente,
    UserRole.secretaria,
    UserRole.admin,
  ]) {
    testWidgets(
      'splash waits for session and routes ${role?.name ?? 'guest'}',
      (tester) async {
        final repository = _SessionRepository();
        final auth = AuthViewModel(repository);
        addTearDown(auth.dispose);
        final destination = role == null
            ? AppRoutes.guestHome
            : role.isStaffPanel
            ? AppRoutes.secretaryHome
            : AppRoutes.clientHome;

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthViewModel>.value(
            value: auth,
            child: MaterialApp(
              initialRoute: AppRoutes.splash,
              onGenerateInitialRoutes: (_) => [
                AppRoutes.onGenerateRoute(
                  const RouteSettings(name: AppRoutes.splash),
                ),
              ],
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => Scaffold(body: Text(settings.name!)),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 800));
        expect(find.byType(SplashView), findsOneWidget);
        expect(find.text(destination), findsNothing);
        expect(repository.restores, 1);

        repository.session.complete(
          role == null
              ? null
              : AuthUser(
                  id: 1,
                  username: 'test-session',
                  email: 'session@example.test',
                  rol: role,
                ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SplashView), findsNothing);
        expect(find.text(destination), findsOneWidget);
        expect(repository.restores, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
