import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/privacidad_viewmodels.dart';
import '../../widgets/common_widgets.dart';
import 'privacidad_widgets.dart';

/// ARCO Acceso (GH#42): lo que la app puede consultar del titular.
class MisDatosView extends StatefulWidget {
  const MisDatosView({super.key});

  @override
  State<MisDatosView> createState() => _MisDatosViewState();
}

class _MisDatosViewState extends State<MisDatosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<MisDatosViewModel>();
      if (vm.state == LoadState.idle) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisDatosViewModel>();
    return PrivacidadScaffold(titulo: 'Mis datos', body: _cuerpo(vm));
  }

  Widget _cuerpo(MisDatosViewModel vm) {
    switch (vm.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const LoadingView(label: 'Cargando tus datos…');
      case LoadState.error:
      case LoadState.empty:
        return ErrorView(
          message: vm.errorMessage ?? 'No se pudieron cargar tus datos.',
          onRetry: vm.load,
        );
      case LoadState.ready:
        final p = vm.perfil!;
        return RefreshIndicator(
          color: AppColors.gold,
          onRefresh: vm.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              PanelSeccion(
                titulo: 'Cuenta',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DatoRow(label: 'Correo', value: p.email),
                    DatoRow(label: 'Usuario', value: p.username),
                  ],
                ),
              ),
              PanelSeccion(
                titulo: 'Datos personales',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DatoRow(label: 'Nombre', value: p.nombre),
                    DatoRow(label: 'Apellido', value: p.apellido),
                    DatoRow(label: 'Teléfono', value: p.telefono),
                    DatoRow(
                      label: 'Fecha de nacimiento',
                      value: p.fechaNacimiento,
                    ),
                    DatoRow(label: 'Dirección', value: p.direccion),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const Key('mis_datos_corregir'),
                      onPressed: () async {
                        final cambio = await Navigator.pushNamed(
                          context,
                          AppRoutes.editarPerfil,
                        );
                        if (cambio == true && mounted) {
                          await context.read<MisDatosViewModel>().load();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Corregir mis datos'),
                    ),
                  ],
                ),
              ),
              PanelSeccion(
                titulo: 'Historial de citas (${vm.citas.length})',
                child: _historial(vm),
              ),
              const Text(
                'Aquí ves lo que la app puede consultar. Para una copia de todo '
                'lo que guarda la barbería (pagos, pedidos y consentimientos), '
                'solicítala por el medio que indica el aviso de privacidad.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        );
    }
  }

  Widget _historial(MisDatosViewModel vm) {
    if (vm.citasError != null) {
      return StatusBanner(
        message: 'No se pudo cargar el historial: ${vm.citasError}',
        isError: true,
      );
    }
    if (vm.citas.isEmpty) {
      return const Text(
        'Aún no tienes citas registradas.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    return Column(children: [for (final c in vm.citas) _CitaFila(cita: c)]);
  }
}

class _CitaFila extends StatelessWidget {
  const _CitaFila({required this.cita});

  final CitaDto cita;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cita.servicioNombre.isEmpty
                      ? 'Servicio'
                      : cita.servicioNombre,
                  style: const TextStyle(color: AppColors.ivory),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cita.fecha} · ${cita.hora} · ${cita.barberoNombre}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EstadoChip(estado: cita.estado),
        ],
      ),
    );
  }
}
