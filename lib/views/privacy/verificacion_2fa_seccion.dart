import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/privacidad_viewmodels.dart';
import '../../widgets/common_widgets.dart';
import 'privacidad_widgets.dart';

/// Privacidad y mis datos › Seguridad de tu cuenta: interruptor del código por
/// correo al iniciar sesión (`/perfil/2fa/`). Apagado por defecto.
class Verificacion2faSeccion extends StatefulWidget {
  const Verificacion2faSeccion({super.key});

  @override
  State<Verificacion2faSeccion> createState() => _Verificacion2faSeccionState();
}

class _Verificacion2faSeccionState extends State<Verificacion2faSeccion> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<Verificacion2faViewModel>();
      if (vm.state == LoadState.idle) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<Verificacion2faViewModel>();
    return PanelSeccion(
      titulo: 'Seguridad de tu cuenta',
      child: _contenido(vm),
    );
  }

  Widget _contenido(Verificacion2faViewModel vm) {
    switch (vm.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const LoadingView(label: 'Cargando tu seguridad…');
      case LoadState.error:
      case LoadState.empty:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBanner(
              key: const Key('privacidad_2fa_error'),
              message:
                  vm.errorMessage ??
                  'No se pudo leer la verificación por correo.',
              isError: true,
            ),
            TextButton(
              key: const Key('privacidad_2fa_reintentar'),
              onPressed: vm.load,
              child: const Text('Reintentar'),
            ),
          ],
        );
      case LoadState.ready:
        final pref = vm.preferencia;
        final bloqueo = pref?.motivoBloqueo.trim() ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('privacidad_2fa_switch'),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.onGold,
              activeTrackColor: AppColors.gold,
              title: const Text(
                'Pedir código por correo al iniciar sesión',
                style: TextStyle(color: AppColors.ivory),
              ),
              subtitle: const Text(
                'Además de tu contraseña, te mandaremos un código de 6 '
                'dígitos cada vez que entres.',
                style: TextStyle(color: AppColors.muted),
              ),
              value: vm.activo,
              onChanged: vm.puedeCambiar ? vm.cambiar : null,
            ),
            if (vm.guardando)
              const LinearProgressIndicator(
                key: Key('privacidad_2fa_guardando'),
                minHeight: 2,
              ),
            if (pref != null && !pref.puedeGestionar && bloqueo.isNotEmpty)
              Text(bloqueo, style: const TextStyle(color: AppColors.muted)),
            if (vm.mensaje != null) ...[
              const SizedBox(height: 8),
              StatusBanner(
                key: const Key('privacidad_2fa_mensaje'),
                message: vm.mensaje!,
                tone: BannerTone.ok,
              ),
            ],
            if (vm.errorGuardar != null) ...[
              const SizedBox(height: 8),
              StatusBanner(
                key: const Key('privacidad_2fa_error_guardar'),
                message: vm.errorGuardar!,
                isError: true,
              ),
            ],
          ],
        );
    }
  }
}
