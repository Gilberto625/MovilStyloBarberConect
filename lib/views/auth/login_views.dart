import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'auth_widgets.dart';

/// Invitado › Pantalla 7: Inicia sesión (Actividad 3).
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

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
    if (ok) goHomeByRole(context, auth.role);
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.guestHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final theme = Theme.of(context).textTheme;
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrand(),
              const SizedBox(height: AppSpacing.xxxl),
              const AuthHeading(
                title: 'Inicia sesión',
                subtitle: 'Entra para reservar y ver tus citas.',
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (auth.errorMessage != null)
                AuthError(message: auth.errorMessage!),
              TextFormField(
                key: const Key('login_cuenta'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Correo o usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validarCuenta,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('login_password'),
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => auth.busy ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AuthPrimaryButton(
                key: const Key('login_entrar'),
                label: 'Entrar',
                busy: auth.busy,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('¿No tienes cuenta?', style: theme.bodyMedium),
                  TextButton(
                    key: const Key('login_registro'),
                    onPressed: auth.busy
                        ? null
                        : () {
                            auth.limpiarError();
                            Navigator.pushNamed(context, AppRoutes.registro);
                          },
                    child: const Text('Regístrate'),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xxxl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  TextButton(
                    key: const Key('login_volver'),
                    onPressed: auth.busy ? null : _volver,
                    child: const Text('Volver al inicio'),
                  ),
                  TextButton(
                    key: const Key('login_aviso_privacidad'),
                    onPressed: auth.busy
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            AppRoutes.avisoPrivacidad,
                          ),
                    child: const Text('Aviso de privacidad'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lleva a cada rol a su panel y borra el historial de acceso.
void goHomeByRole(BuildContext context, UserRole role) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.homeFor(role),
    (_) => false,
  );
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
    if (ok) goHomeByRole(context, auth.role);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final destino = auth.pendingDestino;
    return AuthScaffold(
      leading: IconButton(
        tooltip: 'Volver al acceso',
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ivory),
        onPressed: auth.busy
            ? null
            : () {
                auth.cancel2fa();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrand(compact: true),
          const SizedBox(height: AppSpacing.xxl),
          AuthHeading(
            title: 'Verificación',
            subtitle:
                auth.pendingMensaje ?? 'Ingresa el código enviado a tu correo.',
          ),
          if (destino != null && destino.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enviado a ${maskDestino(destino)}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.museum),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (auth.errorMessage != null) AuthError(message: auth.errorMessage!),
          CodigoField(
            controller: _codigo,
            onSubmitted: (_) => auth.busy ? null : _submit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthPrimaryButton(
            key: const Key('2fa_verificar'),
            label: 'Verificar',
            busy: auth.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: auth.busy ? null : () => auth.resend2fa(),
            child: const Text('Reenviar código'),
          ),
        ],
      ),
    );
  }
}
