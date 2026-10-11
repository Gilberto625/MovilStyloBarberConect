import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';

class GuestHomeView extends StatefulWidget {
  const GuestHomeView({super.key});

  @override
  State<GuestHomeView> createState() => _GuestHomeViewState();
}

class _GuestHomeViewState extends State<GuestHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeGuestViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final wide = screen.width >= 700;
    final short = screen.height < 520;
    final heroHeight = short
        ? 200.0
        : (screen.width * (wide ? 0.34 : 0.62)).clamp(230.0, 320.0);

    return Scaffold(
      backgroundColor: AppColors.guestBg,
      body: SafeArea(
        child: Consumer<HomeGuestViewModel>(
          builder: (context, vm, _) {
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return const LoadingView(label: 'Cargando catálogo…');
            }
            if (vm.state == LoadState.error) {
              return ErrorView(
                message: vm.errorMessage ?? 'No se pudo cargar la información.',
                onRetry: vm.load,
              );
            }
            final c = vm.contacto;
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BrandTitle(
                          part1: c.logoParte1,
                          part2: c.logoParte2,
                          logoUrl: c.logoUrl.isEmpty ? null : c.logoUrl,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.login),
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: heroHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(wide ? 28 : 20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF16211C),
                          Color(0xFF0A100E),
                          Color(0xFF1A1510),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    padding: EdgeInsets.all(wide ? 28 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nombreNegocio.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.gold.withValues(alpha: 0.9),
                            letterSpacing: wide ? 2.2 : 1.4,
                            fontSize: wide ? 14 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: short ? 6 : 10),
                        Container(
                          width: wide ? 72 : 48,
                          height: 1,
                          color: AppColors.gold.withValues(alpha: 0.8),
                        ),
                        SizedBox(height: short ? 8 : 12),
                        Text(
                          'Tu Estilo,\nNuestra Pasión',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                height: 1.12,
                                fontSize: wide ? 40 : (short ? 26 : 32),
                              ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: wide ? 240 : double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRoutes.login),
                            child: const Text('Reservar cita'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (vm.state == LoadState.empty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No hay servicios ni productos publicados todavía.',
                      ),
                    ),
                  if (vm.promociones.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Promociones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.promociones.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final p = vm.promociones[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              p.bannerUrl,
                              width: 260,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 260,
                                    color: AppColors.guestCard,
                                    alignment: Alignment.center,
                                    child: Text(p.nombre),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Servicios',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.servicios),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (vm.serviciosDestacados.isEmpty)
                    const Text('Sin servicios disponibles.')
                  else
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.serviciosDestacados.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final s = vm.serviciosDestacados[i];
                          return ServicioCard(
                            nombre: s.nombre,
                            precio: s.precio,
                            duracion: s.duracionMinutos,
                            imagenUrl: s.imagenUrl,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Productos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.productos),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (vm.productosDestacados.isEmpty)
                    const Text('Sin productos disponibles.')
                  else
                    SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.productosDestacados.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final p = vm.productosDestacados[i];
                          return ProductoCard(
                            nombre: p.nombre,
                            marca: p.marca,
                            precio: p.precio,
                            imagenUrl: p.imagenUrl,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Encuéntranos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.guestCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.direccion.isNotEmpty) Text(c.direccion),
                        if (c.horario.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            c.horario,
                            style: TextStyle(
                              color: AppColors.text.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                        if (c.telefono.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(c.telefono),
                        ],
                        if (c.correo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(c.correo),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
