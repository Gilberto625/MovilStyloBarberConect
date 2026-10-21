import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';

const authMaxWidth = 440.0;

/// Pantalla de acceso: columna centrada, una entrada corta y teclado seguro.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.leading});

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              children: [
                if (leading != null)
                  Align(alignment: Alignment.centerLeft, child: leading!),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 40).clamp(0, 1200),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: authMaxWidth),
                      child: QuietEntrance(rise: 10, child: child),
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

/// Logo real del negocio si el backend lo publicó; si no, la marca en texto.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Sin proveedor (pruebas aisladas) se usa la marca en texto.
    final contacto = Provider.of<HomeGuestViewModel?>(context)?.contacto;
    final logo = contacto?.logoUrl ?? '';
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 220,
          minHeight: compact ? 48 : 72,
        ),
        child: BrandTitle(
          part1: contacto?.logoParte1 ?? 'Stylo',
          part2: contacto?.logoParte2 ?? 'Barber',
          logoUrl: logo.isEmpty ? null : logo,
          logoHeight: compact ? 56 : 84,
        ),
      ),
    );
  }
}

/// Título y apoyo de cada pantalla de acceso.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: theme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class AuthError extends StatelessWidget {
  const AuthError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        label: message,
        child: StatusBanner(message: message, isError: true),
      ),
    );
  }
}

/// Botón principal con estado ocupado; mantiene su alto mientras carga.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
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
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.quick),
            child: busy
                ? const SizedBox(
                    key: ValueKey('busy'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onGold,
                    ),
                  )
                : Text(label, key: const ValueKey('label')),
          ),
        ),
      ),
    );
  }
}

/// Campo para el código de 6 dígitos (2FA y confirmación de correo).
class CodigoField extends StatelessWidget {
  const CodigoField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      maxLength: 6,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppText.cifra(size: 26).copyWith(letterSpacing: 10),
      decoration: const InputDecoration(
        labelText: 'Código de 6 dígitos',
        counterText: '',
      ),
      onSubmitted: onSubmitted,
    );
  }
}

/// Oculta un correo o teléfono dejando lo justo para reconocerlo.
String maskDestino(String raw) {
  final value = raw.trim();
  if (value.contains('*')) return value; // El servidor ya lo enmascaró.
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
