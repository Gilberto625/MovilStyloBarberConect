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
              return const _GuestLoading();
            }
            if (vm.state == LoadState.error) {
              return ErrorView(
                message: _guestErrorMessage(vm.errorMessage),
                onRetry: vm.load,
              );
            }
            final c = vm.contacto;
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: vm.load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 20,
                  12,
                  wide ? 28 : 20,
                  32,
                ),
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
                    const _SectionHeading(title: 'Promociones'),
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
                  _SectionHeading(
                    title: 'Servicios',
                    action: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.servicios),
                      child: const Text('Ver todos'),
                    ),
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
                  _SectionHeading(
                    title: 'Productos',
                    action: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.productos),
                      child: const Text('Ver todos'),
                    ),
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
                  const _SectionHeading(title: 'Encuéntranos'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.guestCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.direccion.isNotEmpty)
                          _ContactLine(
                            icon: Icons.place_outlined,
                            text: c.direccion,
                          ),
                        if (c.horario.isNotEmpty)
                          _ContactLine(icon: Icons.schedule, text: c.horario),
                        if (c.telefono.isNotEmpty)
                          _ContactLine(
                            icon: Icons.phone_outlined,
                            text: c.telefono,
                          ),
                        if (c.correo.isNotEmpty)
                          _ContactLine(
                            icon: Icons.mail_outline,
                            text: c.correo,
                          ),
                        if (c.direccion.isEmpty &&
                            c.horario.isEmpty &&
                            c.telefono.isEmpty &&
                            c.correo.isEmpty)
                          Text(
                            'La ubicación y el horario aparecen cuando el servidor responde.',
                            style: TextStyle(
                              color: AppColors.text.withValues(alpha: 0.7),
                            ),
                          ),
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

String _guestErrorMessage(String? raw) {
  final text = raw ?? '';
  if (text.contains('Failed to fetch') ||
      text.contains('ClientException') ||
      text.contains('SocketException') ||
      text.contains('Timeout')) {
    return 'No se pudo conectar con la barbería. Si el servidor está dormido, ábrelo y pulsa Reintentar.';
  }
  if (text.isEmpty) return 'No se pudo cargar la información.';
  return text;
}

class _GuestLoading extends StatelessWidget {
  const _GuestLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.gold,
              backgroundColor: Color(0xFF24302B),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cargando catálogo',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.7),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 2,
                color: AppColors.gold.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
