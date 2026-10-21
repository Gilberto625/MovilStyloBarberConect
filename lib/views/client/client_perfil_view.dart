import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import 'client_tienda_view.dart';
import 'client_widgets.dart';

/// Cliente › Pantalla 10: Perfil.
class ClientPerfilTab extends StatefulWidget {
  const ClientPerfilTab({super.key});

  @override
  State<ClientPerfilTab> createState() => _ClientPerfilTabState();
}

class _ClientPerfilTabState extends State<ClientPerfilTab> {
  PerfilDto? _perfil;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthViewModel>();
    final p = await auth.loadPerfil();
    if (!mounted) return;
    setState(() {
      _perfil = p;
      _loading = false;
      if (p == null) _error = auth.errorMessage;
    });
  }

  Future<void> _salir() async {
    final auth = context.read<AuthViewModel>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.guestHome,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final perfil = _perfil;
    final theme = Theme.of(context).textTheme;
    final nombre = perfil?.displayName ?? auth.user?.username ?? '';
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          const ClientHeader(title: 'Perfil'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading && perfil == null)
                  const LoadingView(label: 'Cargando perfil…')
                else if (_error != null && perfil == null) ...[
                  StatusBanner(message: _error!, isError: true),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ] else if (perfil != null)
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Iniciales(nombre: nombre, size: 56),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Text(nombre, style: theme.headlineSmall),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dato(label: 'Correo', value: perfil.email),
                        _Dato(label: 'Usuario', value: perfil.username),
                        _Dato(label: 'Teléfono', value: perfil.telefono),
                        _Dato(
                          label: 'Nacimiento',
                          value: perfil.fechaNacimiento,
                        ),
                        _Dato(label: 'Dirección', value: perfil.direccion),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                _Opcion(
                  key: const Key('perfil_pedidos'),
                  icon: Icons.receipt_long_outlined,
                  title: 'Mis pedidos',
                  onTap: () => abrirMisPedidos(context),
                ),
                _Opcion(
                  key: const Key('perfil_privacidad'),
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacidad y mis datos',
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.privacidad);
                    // Al volver, refleja lo que se haya corregido.
                    if (mounted) await _load();
                  },
                ),
                _Opcion(
                  key: const Key('perfil_aviso'),
                  icon: Icons.description_outlined,
                  title: 'Aviso de privacidad',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.avisoPrivacidad),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  key: const Key('perfil_cerrar_sesion'),
                  onPressed: _salir,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ivory,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return InfoRow(label: label, value: _cortable(value));
  }
}

/// Permite partir correos y rutas largas en pantallas angostas.
String _cortable(String value) {
  if (!value.contains('@') && !value.contains('/')) return value;
  return value.replaceAll('@', '@​').replaceAll('.', '.​');
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        onTap: onTap,
        semanticLabel: title,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(icon, color: AppColors.goldSoft),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.ivory),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
