import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'secretary_gestion_views.dart';
import 'secretary_home_view.dart';

class SecretaryShell extends StatefulWidget {
  const SecretaryShell({super.key});

  @override
  State<SecretaryShell> createState() => _SecretaryShellState();
}

class _SecretaryShellState extends State<SecretaryShell> {
  int _index = 0;

  static const _items = [
    (Icons.today_outlined, 'Hoy'),
    (Icons.add_circle_outline, 'Nueva'),
    (Icons.person_search_outlined, 'Clientes'),
    (Icons.grid_view_outlined, 'Más'),
  ];

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.role.isStaffPanel) {
      return const SecretaryHomeView();
    }

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = const [
      SecretaryHomeView(),
      SecretaryNuevaCitaView(),
      SecretaryClienteCitasView(),
      _SecretaryMasView(),
    ];

    return SecretaryNav(
      go: _go,
      child: Scaffold(
        backgroundColor: AppColors.panelBg,
        body: Row(
          children: [
            if (wide) _Rail(index: _index, onSelect: _go),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _go,
                  destinations: [
                    for (var i = 0; i < _items.length; i++)
                      NavigationDestination(
                        key: ValueKey('secretaria-nav-$i'),
                        icon: Icon(_items[i].$1),
                        label: _items[i].$2,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.guestCard,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stylo',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: AppColors.gold),
              ),
              const Text(
                'Secretaría',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _SecretaryShellState._items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RailButton(
                    icon: _SecretaryShellState._items[i].$1,
                    label: _label(i),
                    selected: index == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(int i) {
    return switch (i) {
      0 => 'Hoy',
      1 => 'Nueva cita',
      2 => 'Clientes',
      _ => 'Más',
    };
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.ivory;
    return Material(
      color: selected
          ? AppColors.gold.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecretaryMasView extends StatelessWidget {
  const _SecretaryMasView();

  @override
  Widget build(BuildContext context) {
    const pendientes = [
      (
        'Ventas',
        'El punto de venta vive en la web. Esta app todavía no lo conecta.',
      ),
      (
        'Inventario',
        'El stock oficial se consulta en la web. Aquí no hay un listado propio.',
      ),
      ('Pedidos', 'Los pedidos de mostrador siguen en la web.'),
      ('Corte de caja', 'El corte del día todavía no tiene pantalla móvil.'),
      (
        'Transferencias',
        'Validar anticipos por transferencia sigue en la web.',
      ),
      ('Sillas', 'La ocupación de sillas sigue en la web.'),
    ];

    return Scaffold(
      backgroundColor: AppColors.panelBg,
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Lo que ya puedes hacer aquí',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _LinkTile(
            title: 'Agenda del día',
            subtitle: 'Citas, asistencia y cobro.',
            onTap: () => SecretaryNav.open(context, 0, AppRoutes.secretaryHome),
          ),
          _LinkTile(
            title: 'Nueva cita',
            subtitle: 'Cliente, servicio, barbero y horario real.',
            onTap: () =>
                SecretaryNav.open(context, 1, AppRoutes.secretaryNuevaCita),
          ),
          _LinkTile(
            title: 'Citas de un cliente',
            subtitle: 'Próximas citas desde hoy.',
            onTap: () =>
                SecretaryNav.open(context, 2, AppRoutes.secretaryClienteCitas),
          ),
          const SizedBox(height: 20),
          Text(
            'Siguen en la web',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final item in pendientes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.panelCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.ivory,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.$2, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadii.controlBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ivory,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
