import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'privacidad_widgets.dart';

/// Perfil → Privacidad: entrada a los derechos ARCO que la app ya cubre.
class PrivacidadView extends StatelessWidget {
  const PrivacidadView({super.key});

  @override
  Widget build(BuildContext context) {
    return PrivacidadScaffold(
      titulo: 'Privacidad y mis datos',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'Puedes consultar y corregir los datos que la barbería tiene de ti, '
            'y elegir para qué más se usan.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          _Opcion(
            key: const Key('privacidad_mis_datos'),
            icono: Icons.person_search_outlined,
            titulo: 'Mis datos',
            detalle: 'Tu perfil y tu historial de citas.',
            onTap: () => Navigator.pushNamed(context, AppRoutes.misDatos),
          ),
          _Opcion(
            key: const Key('privacidad_editar_perfil'),
            icono: Icons.edit_outlined,
            titulo: 'Corregir mis datos',
            detalle: 'Nombre, teléfono, fecha de nacimiento y dirección.',
            onTap: () => Navigator.pushNamed(context, AppRoutes.editarPerfil),
          ),
          _Opcion(
            key: const Key('privacidad_aviso'),
            icono: Icons.policy_outlined,
            titulo: 'Aviso de privacidad y preferencias',
            detalle: 'Qué datos se usan, para qué, y tus permisos opcionales.',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.avisoPrivacidad),
          ),
          const SizedBox(height: 8),
          const PanelSeccion(
            titulo: 'Cancelar tu cuenta u oponerte a un uso',
            child: Text(
              'La app todavía no tramita estas solicitudes. Envíalas por el '
              'medio que indica el aviso de privacidad.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minVerticalPadding: 14,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(icono, color: AppColors.gold),
          title: Text(titulo, style: const TextStyle(color: AppColors.ivory)),
          subtitle: Text(
            detalle,
            style: const TextStyle(color: AppColors.muted),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: onTap,
        ),
      ),
    );
  }
}
