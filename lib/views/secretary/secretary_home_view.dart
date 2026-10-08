import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/secretaria_hoy_viewmodel.dart';
import '../../widgets/common_widgets.dart';

class SecretaryHomeView extends StatefulWidget {
  const SecretaryHomeView({super.key});

  @override
  State<SecretaryHomeView> createState() => _SecretaryHomeViewState();
}

class _SecretaryHomeViewState extends State<SecretaryHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecretariaHoyViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.role.isStaffPanel) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No autorizado para secretaría.'),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.guestHome,
                  (_) => false,
                ),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoy'),
        actions: [
          IconButton(
            onPressed: () => context.read<SecretariaHoyViewModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.guestHome,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<SecretariaHoyViewModel>(
          builder: (context, vm, _) {
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return const LoadingView(label: 'Cargando citas del día…');
            }
            if (vm.state == LoadState.error) {
              return ErrorView(
                message: vm.errorMessage ?? 'Error',
                onRetry: vm.load,
              );
            }
            final dia = vm.dia;
            return Column(
              children: [
                if (vm.actionMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: StatusBanner(message: vm.actionMessage!),
                  ),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: StatusBanner(
                      message: vm.errorMessage!,
                      isError: true,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fecha: ${dia?.fecha ?? '—'}'
                          '${dia?.esHoy == true ? ' (hoy)' : ''}',
                        ),
                      ),
                      Text('${dia?.total ?? 0} citas'),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final f in const [
                        'todas',
                        'pendiente',
                        'confirmada',
                        'en_curso',
                        'completada',
                        'no_asistio',
                        'cancelada',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: vm.filtroEstado == f,
                            onSelected: (_) => vm.setFiltro(f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.citasFiltradas.isEmpty
                      ? EmptyView(
                          message: 'Sin citas para este filtro.',
                          onRetry: vm.load,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.citasFiltradas.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final c = vm.citasFiltradas[i];
                            return _CitaTile(cita: c);
                          },
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

class _CitaTile extends StatelessWidget {
  const _CitaTile({required this.cita});

  final SecretariaCitaDto cita;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.secretaryCitaDetail,
        arguments: cita,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panelCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${cita.hora} · ${cita.clienteNombre}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                EstadoChip(estado: cita.estado),
              ],
            ),
            const SizedBox(height: 4),
            Text(cita.servicioNombre),
            Text(
              cita.barberoNombre,
              style: const TextStyle(color: AppColors.museum),
            ),
            Text(
              'Total ${moneyFormat.format(cita.precioTotal)} · Restante ${moneyFormat.format(cita.restante)}',
              style: const TextStyle(color: AppColors.gold),
            ),
            if (cita.clientePenalizado)
              const Text(
                'Cliente con penalización de anticipo',
                style: TextStyle(color: AppColors.warn, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class SecretaryCitaDetailView extends StatelessWidget {
  const SecretaryCitaDetailView({super.key, required this.cita});

  final SecretariaCitaDto cita;

  Future<void> _noAsistio(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar no asistió'),
        content: const Text(
          'Esta acción puede activar o reforzar la penalización de anticipo del cliente '
          'según la política del backend. ¿Confirmas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.marcarNoAsistio(cita.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? (vm.actionMessage ?? 'OK') : (vm.errorMessage ?? 'Error'),
        ),
      ),
    );
    if (success) Navigator.pop(context);
  }

  Future<void> _cobrar(BuildContext context) async {
    String metodo = 'efectivo';
    final comprobante = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Registrar cobro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'efectivo', label: Text('Efectivo')),
                  ButtonSegment(value: 'tarjeta', label: Text('Tarjeta')),
                  ButtonSegment(
                    value: 'transferencia',
                    label: Text('Transfer.'),
                  ),
                ],
                selected: {metodo},
                onSelectionChanged: (s) => setLocal(() => metodo = s.first),
              ),
              if (metodo == 'transferencia') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: comprobante,
                  decoration: const InputDecoration(
                    labelText: 'Comprobante / referencia',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cobrar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.cobrar(
      citaId: cita.id,
      metodoPago: metodo,
      comprobante: comprobante.text.trim().isEmpty
          ? null
          : comprobante.text.trim(),
    );
    comprobante.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (vm.actionMessage ?? 'Cobro OK')
              : (vm.errorMessage ?? 'Error'),
        ),
      ),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SecretariaHoyViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text('Cita #${cita.id}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              cita.clienteNombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (cita.clienteTelefono.isNotEmpty) Text(cita.clienteTelefono),
            const SizedBox(height: 12),
            Text('${cita.fecha} · ${cita.hora}'),
            Text(cita.servicioNombre),
            Text('Barbero: ${cita.barberoNombre}'),
            const SizedBox(height: 8),
            EstadoChip(estado: cita.estado),
            const SizedBox(height: 12),
            Text('Total: ${moneyFormat.format(cita.precioTotal)}'),
            Text('Anticipo: ${moneyFormat.format(cita.anticipoPagado)}'),
            Text(
              'Restante: ${moneyFormat.format(cita.restante)}',
              style: const TextStyle(color: AppColors.gold),
            ),
            const SizedBox(height: 24),
            if (cita.puedeMarcarAsistencia) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.actionBusy
                      ? null
                      : () async {
                          final ok = await vm.marcarLlego(cita.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? (vm.actionMessage ?? 'OK')
                                    : (vm.errorMessage ?? 'Error'),
                              ),
                            ),
                          );
                          if (ok) Navigator.pop(context);
                        },
                  child: const Text('Cliente llegó'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: vm.actionBusy ? null : () => _noAsistio(context),
                  child: const Text('No asistió'),
                ),
              ),
            ],
            if (cita.puedeCobrar) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.actionBusy ? null : () => _cobrar(context),
                  child: const Text('Cobrar restante'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
