import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/privacidad_viewmodels.dart';
import '../../widgets/common_widgets.dart';
import 'privacidad_widgets.dart';

/// Perfil › Privacidad › Eliminar mi cuenta (ARCO GH#44).
///
/// La cuenta se bloquea al momento y los datos personales se suprimen a los
/// 30 días; lo decide y lo hace Django. Al terminar se cierra la sesión local.
class EliminarCuentaView extends StatefulWidget {
  const EliminarCuentaView({super.key});

  @override
  State<EliminarCuentaView> createState() => _EliminarCuentaViewState();
}

class _EliminarCuentaViewState extends State<EliminarCuentaView> {
  var _oculta = true;

  Future<void> _enviar() async {
    final vm = context.read<EliminarCuentaViewModel>();
    final ok = await vm.enviar();
    if (!ok || !mounted) return;
    // Los tokens ya no sirven en el servidor; se borran también aquí.
    await context.read<AuthViewModel>().logout();
  }

  void _salir() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.guestHome,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EliminarCuentaViewModel>();
    final resultado = vm.resultado;
    return PopScope(
      // Con la cuenta ya cancelada no se vuelve a las pantallas con sesión:
      // Atrás lleva al inicio de invitado, igual que "Entendido".
      canPop: resultado == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && resultado != null) _salir();
      },
      child: PrivacidadScaffold(
        titulo: 'Eliminar mi cuenta',
        conRegreso: resultado == null,
        body: resultado != null
            ? _Hecho(
                folio: resultado.folio,
                fecha: resultado.fechaSupresion,
                onSalir: _salir,
              )
            : _Formulario(
                vm: vm,
                oculta: _oculta,
                onToggle: () => setState(() => _oculta = !_oculta),
                onEnviar: _enviar,
              ),
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.vm,
    required this.oculta,
    required this.onToggle,
    required this.onEnviar,
  });

  final EliminarCuentaViewModel vm;
  final bool oculta;
  final VoidCallback onToggle;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      children: [
        Text('Qué pasa al eliminarla', style: theme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        const _Paso(
          icono: Icons.lock_outline,
          texto:
              'Tu cuenta se bloquea de inmediato: ya no podrás entrar ni '
              'reservar con ella.',
        ),
        const _Paso(
          icono: Icons.event_busy_outlined,
          texto:
              'En 30 días se borran tu nombre, correo, teléfono, fecha de '
              'nacimiento y direcciones.',
        ),
        const _Paso(
          icono: Icons.receipt_long_outlined,
          texto:
              'Las citas, cobros y ventas se conservan sin tus datos, porque '
              'la barbería debe guardarlos.',
        ),
        const SizedBox(height: AppSpacing.md),
        const StatusBanner(
          isError: true,
          message:
              'No se puede deshacer desde la app. Si tienes citas próximas, '
              'avisa a la barbería.',
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('eliminar_contrasena'),
          obscureText: oculta,
          autofillHints: const [AutofillHints.password],
          onChanged: vm.setContrasena,
          decoration: InputDecoration(
            labelText: 'Tu contraseña',
            suffixIcon: IconButton(
              tooltip: oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
              onPressed: onToggle,
              icon: Icon(
                oculta
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('eliminar_confirmacion'),
          textCapitalization: TextCapitalization.characters,
          onChanged: vm.setConfirmacion,
          decoration: const InputDecoration(
            labelText: 'Escribe ELIMINAR para confirmar',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('eliminar_motivo'),
          maxLength: 500,
          minLines: 1,
          maxLines: 3,
          onChanged: vm.setMotivo,
          decoration: const InputDecoration(
            labelText: '¿Por qué te vas? (opcional)',
          ),
        ),
        if (vm.error != null)
          Semantics(
            liveRegion: true,
            child: StatusBanner(message: vm.error!, isError: true),
          ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const Key('eliminar_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.crit,
            foregroundColor: AppColors.onGold,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: vm.puedeEnviar ? onEnviar : null,
          child: vm.enviando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onGold,
                  ),
                )
              : const Text('Eliminar mi cuenta'),
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: AppColors.museum),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hecho extends StatelessWidget {
  const _Hecho({
    required this.folio,
    required this.fecha,
    required this.onSalir,
  });

  final String folio;
  final String fecha;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.ok, size: 48),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Tu cuenta quedó bloqueada',
          key: const Key('eliminar_hecho'),
          textAlign: TextAlign.center,
          style: theme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tus datos personales se eliminarán a más tardar el $fecha.',
          textAlign: TextAlign.center,
          style: theme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        SurfaceCard(
          child: Column(
            children: [
              Text('Folio de tu solicitud', style: theme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                folio,
                textAlign: TextAlign.center,
                style: AppText.cifra(size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          key: const Key('eliminar_salir'),
          onPressed: onSalir,
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
