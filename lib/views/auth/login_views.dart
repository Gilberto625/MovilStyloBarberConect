import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common_widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.login(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (auth.phase == AuthPhase.needs2fa) {
      Navigator.pushReplacementNamed(context, AppRoutes.verify2fa);
      return;
    }
    if (ok) {
      _goHomeByRole(auth.role);
    }
  }

  void _goHomeByRole(UserRole role) {
    if (role.isStaffPanel) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.secretaryHome,
        (_) => false,
      );
    } else if (role == UserRole.barbero) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.clientHome,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.clientHome,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Stylo Barber Connect',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia sesión con tu cuenta del sistema.',
              style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            if (auth.errorMessage != null)
              StatusBanner(message: auth.errorMessage!, isError: true),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Correo o usuario',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.busy ? null : _submit,
                      child: auth.busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onGold,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Verify2FAView extends StatefulWidget {
  const Verify2FAView({super.key});

  @override
  State<Verify2FAView> createState() => _Verify2FAViewState();
}

class _Verify2FAViewState extends State<Verify2FAView> {
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthViewModel>();
    final ok = await auth.verify2fa(_codigo.text);
    if (!mounted) return;
    if (ok) {
      if (auth.role.isStaffPanel) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.secretaryHome,
          (_) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.clientHome,
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación 2FA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            auth.cancel2fa();
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              auth.pendingMensaje ?? 'Ingresa el código enviado a tu correo.',
            ),
            if (auth.pendingDestino != null &&
                auth.pendingDestino!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Destino: ${auth.pendingDestino}',
                style: const TextStyle(color: AppColors.museum),
              ),
            ],
            const SizedBox(height: 16),
            if (auth.errorMessage != null)
              StatusBanner(message: auth.errorMessage!, isError: true),
            TextField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const CircularProgressIndicator(color: AppColors.onGold)
                    : const Text('Verificar'),
              ),
            ),
            TextButton(
              onPressed: auth.busy ? null : () => auth.resend2fa(),
              child: const Text('Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}
