import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';

const _ivory = AppColors.ivory;
const _authMaxWidth = 420.0;

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
    return _AuthScaffold(
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AuthBrand(),
              const SizedBox(height: 28),
              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: _ivory, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión con tu cuenta del sistema.',
                style: TextStyle(color: AppColors.text.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 24),
              if (auth.errorMessage != null)
                _AuthError(message: auth.errorMessage!),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Correo o usuario',
                ),
                validator: validarCuenta,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => auth.busy ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
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
                      color: AppColors.gold,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 24),
              _AuthPrimaryButton(
                label: 'Entrar',
                busy: auth.busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: auth.busy
                    ? null
                    : () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.guestHome,
                          );
                        }
                      },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
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
    final destino = auth.pendingDestino;
    return _AuthScaffold(
      leading: IconButton(
        tooltip: 'Volver al acceso',
        icon: const Icon(Icons.arrow_back, color: _ivory),
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
          const _AuthBrand(),
          const SizedBox(height: 28),
          Text(
            'Verificación',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: _ivory, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            auth.pendingMensaje ?? 'Ingresa el código enviado a tu correo.',
            style: TextStyle(color: AppColors.text.withValues(alpha: 0.78)),
          ),
          if (destino != null && destino.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Enviado a ${_maskDestino(destino)}',
              style: const TextStyle(color: AppColors.museum),
            ),
          ],
          const SizedBox(height: 20),
          if (auth.errorMessage != null)
            _AuthError(message: auth.errorMessage!),
          TextField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: _ivory,
              fontSize: 24,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              counterText: '',
            ),
            onSubmitted: (_) => auth.busy ? null : _submit(),
          ),
          const SizedBox(height: 16),
          _AuthPrimaryButton(
            label: 'Verificar',
            busy: auth.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: auth.busy ? null : () => auth.resend2fa(),
            child: const Text('Reenviar código'),
          ),
        ],
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child, this.leading});

  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guestBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              children: [
                if (leading != null)
                  Align(alignment: Alignment.centerLeft, child: leading!),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 40).clamp(0, 1200),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _authMaxWidth,
                      ),
                      child: QuietEntrance(child: child),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF101A16),
            border: Border.all(color: AppColors.gold, width: 1.4),
          ),
          child: const Icon(Icons.content_cut, color: AppColors.gold, size: 30),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(fontSize: 32, height: 1.05, color: _ivory),
            children: [
              TextSpan(text: 'Stylo'),
              TextSpan(
                text: ' Barber',
                style: TextStyle(color: AppColors.gold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'BARBERÍA',
          style: TextStyle(
            color: AppColors.museum,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        label: message,
        child: StatusBanner(message: message, isError: true),
      ),
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  const _AuthPrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: !busy,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onGold,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

String _maskDestino(String raw) {
  final value = raw.trim();
  final at = value.indexOf('@');
  if (at > 0) {
    final name = value.substring(0, at);
    final domain = value.substring(at);
    final visible = name.substring(0, name.length > 1 ? 1 : name.length);
    return '$visible***$domain';
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 4) {
    return '***${digits.substring(digits.length - 4)}';
  }
  if (value.length <= 2) return '***';
  return '${value.substring(0, 1)}***';
}
