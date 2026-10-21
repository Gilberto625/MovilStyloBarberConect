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
import '../../widgets/press_scale.dart';

class SecretaryHomeView extends StatefulWidget {
  const SecretaryHomeView({super.key});

  @override
  State<SecretaryHomeView> createState() => _SecretaryHomeViewState();
}

class _SecretaryHomeViewState extends State<SecretaryHomeView> {
  final _buscar = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecretariaHoyViewModel>().load();
    });
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha(SecretariaHoyViewModel vm) async {
    final actual = _fechaInicial(vm);
    final picked = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null || !mounted) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    await vm.load(fecha: iso);
  }

  DateTime _fechaInicial(SecretariaHoyViewModel vm) {
    final raw = vm.dia?.fecha ?? vm.fechaSeleccionada;
    if (raw != null && raw.length >= 10) {
      final parsed = DateTime.tryParse(raw.substring(0, 10));
      if (parsed != null) return parsed;
    }
    return DateTime.now();
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

    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(
          title: const Text('Operación'),
          actions: [
            IconButton(
              tooltip: 'Actualizar día',
              onPressed: () => context.read<SecretariaHoyViewModel>().load(),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
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
              final sinCitas = dia?.citas.isEmpty ?? true;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final inset = constraints.maxWidth > 980
                      ? (constraints.maxWidth - 960) / 2
                      : 0.0;
                  return ListView(
                    padding: EdgeInsets.only(
                      bottom: 24,
                      left: inset,
                      right: inset,
                    ),
                    children: [
                      if (vm.reloading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.gold,
                          backgroundColor: Colors.transparent,
                        ),
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dia?.esHoy == true ? 'Hoy' : 'Día seleccionado',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              '${dia?.fecha ?? '—'} · ${dia?.total ?? 0} citas',
                              style: const TextStyle(color: Color(0xFFA6BAB0)),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: vm.reloading
                                      ? null
                                      : () => _elegirFecha(vm),
                                  icon: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                  label: Text(dia?.fecha ?? 'Elegir fecha'),
                                ),
                                if (vm.fechaSeleccionada != null)
                                  TextButton(
                                    onPressed: vm.reloading
                                        ? null
                                        : vm.mostrarHoy,
                                    child: const Text('Hoy'),
                                  ),
                                OutlinedButton(
                                  onPressed: () => SecretaryNav.open(
                                    context,
                                    1,
                                    AppRoutes.secretaryNuevaCita,
                                  ),
                                  child: const Text('Nueva cita'),
                                ),
                                OutlinedButton(
                                  onPressed: () => SecretaryNav.open(
                                    context,
                                    2,
                                    AppRoutes.secretaryClienteCitas,
                                  ),
                                  child: const Text('Citas de un cliente'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _buscar,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                labelText: 'Buscar cliente, servicio o barbero',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: vm.setConsulta,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _Metric(
                                  label: 'Acción',
                                  value: '${dia?.pendientesAccion ?? 0}',
                                ),
                                _Metric(
                                  label: 'En curso',
                                  value: '${dia?.enCurso ?? 0}',
                                ),
                                _Metric(
                                  label: 'Listas',
                                  value: '${dia?.completadas ?? 0}',
                                ),
                                _Metric(
                                  label: 'Faltas',
                                  value: '${dia?.noAsistio ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Row(
                          children: [
                            for (final f in const [
                              ('todas', 'Todas'),
                              ('pendiente', 'Pendientes'),
                              ('confirmada', 'Confirmadas'),
                              ('en_curso', 'En curso'),
                              ('completada', 'Completadas'),
                              ('no_asistio', 'No asistió'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(f.$2),
                                  selected: vm.filtroEstado == f.$1,
                                  onSelected: (_) => vm.setFiltro(f.$1),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (vm.citasFiltradas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                          child: Column(
                            children: [
                              Text(
                                sinCitas ? 'No hay citas para esta fecha.' : 'Ninguna cita coincide con la búsqueda o el filtro.',
                                textAlign: TextAlign.center,
                              ),
                              if (sinCitas) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => SecretaryNav.open(
                                    context,
                                    1,
                                    AppRoutes.secretaryNuevaCita,
                                  ),
                                  child: const Text('Nueva cita'),
                                ),
                              ],
                              if (sinCitas) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: vm.load,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ],
                          ),
                        )
                      else ...[
                        for (final c in vm.citasFiltradas)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _CitaTile(cita: c),
                          ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14211B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFFA6BAB0)),
            ),
          ],
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
    return PressScale(
      child: Material(
        color: AppColors.panelCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.secretaryCitaDetail,
            arguments: cita,
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        cita.hora.isEmpty ? 'Sin hora' : cita.hora,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.gold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    EstadoChip(estado: cita.estado),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  cita.clienteNombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ivory,
                  ),
                ),
                Text(cita.servicioNombre),
                Text(
                  cita.barberoNombre,
                  style: const TextStyle(color: AppColors.museum),
                ),
                Text(
                  '${cita.duracionMinutos} min · Restante ${moneyFormat.format(cita.restante)}',
                  style: const TextStyle(color: AppColors.gold),
                ),
                if (cita.clientePenalizado)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Cliente con penalización de anticipo',
                      style: TextStyle(color: AppColors.warn, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecretaryCitaDetailView extends StatelessWidget {
  const SecretaryCitaDetailView({super.key, required this.cita});

  final SecretariaCitaDto cita;

  SecretariaCitaDto _visible(SecretariaHoyViewModel vm) {
    for (final item in vm.dia?.citas ?? const <SecretariaCitaDto>[]) {
      if (item.id == cita.id) return item;
    }
    return cita;
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _llego(BuildContext context, SecretariaCitaDto actual) async {
    final ok = await _confirmar(
      context,
      title: 'Registrar llegada',
      message:
          'La cita pasará a en curso solo si el servidor acepta la acción.',
      confirmLabel: 'Confirmar',
    );
    if (!ok || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.marcarLlego(actual.id);
    if (!context.mounted) return;
    _avisar(context, vm, success);
    if (success) Navigator.pop(context);
  }

  Future<void> _noAsistio(
    BuildContext context,
    SecretariaCitaDto actual,
  ) async {
    final ok = await _confirmar(
      context,
      title: 'Marcar no asistió',
      message:
          'Esta acción puede activar o reforzar la penalización de anticipo del cliente '
          'según la política del backend. ¿Confirmas?',
      confirmLabel: 'Confirmar',
    );
    if (!ok || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.marcarNoAsistio(actual.id);
    if (!context.mounted) return;
    _avisar(context, vm, success);
    if (success) Navigator.pop(context);
  }

  Future<void> _cobrar(BuildContext context, SecretariaCitaDto actual) async {
    // El diálogo es dueño de sus controladores: los libera en su dispose,
    // después de la animación de salida. Liberarlos aquí, apenas regresa
    // showDialog, rompía el TextField mientras el diálogo se cerraba.
    final datos = await showDialog<_DatosCobro>(
      context: context,
      builder: (_) => _CobroDialog(restante: actual.restante),
    );
    if (datos == null || !context.mounted) return;
    final metodo = datos.metodo;
    final proof = datos.comprobante.trim();
    final cashRaw = datos.efectivo.trim().replaceAll(',', '.');
    if (metodo == 'transferencia' && proof.isEmpty) {
      _snack(context, 'La transferencia requiere comprobante o referencia.');
      return;
    }
    double? cash;
    if (metodo == 'efectivo' && actual.restante > 0) {
      cash = double.tryParse(cashRaw);
      if (cash == null || cash + 0.001 < actual.restante) {
        _snack(
          context,
          'El efectivo debe cubrir ${moneyFormat.format(actual.restante)}.',
        );
        return;
      }
    }
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.cobrar(
      citaId: actual.id,
      metodoPago: metodo,
      comprobante: proof.isEmpty ? null : proof,
      efectivoRecibido: metodo == 'efectivo' ? cash : null,
    );
    if (!context.mounted) return;
    _avisar(context, vm, success);
    if (success) Navigator.pop(context);
  }

  void _avisar(BuildContext context, SecretariaHoyViewModel vm, bool success) {
    _snack(
      context,
      success ? (vm.actionMessage ?? 'OK') : (vm.errorMessage ?? 'Error'),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SecretariaHoyViewModel>();
    final actual = _visible(vm);
    final penalizacion = actual.clientePenalizado
        ? (actual.penalizacionPorcentaje > 0
              ? 'Penalización activa: anticipo del ${actual.penalizacionPorcentaje.toStringAsFixed(0)}%. '
                    'Faltan ${actual.penalizacionCitasRestantes} citas asistidas para liberarla.'
              : 'Cliente con penalización de anticipo')
        : null;
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(title: Text('Cita #${actual.id}')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                actual.clienteNombre,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (actual.clienteTelefono.isNotEmpty)
                Text(actual.clienteTelefono),
              const SizedBox(height: 16),
              _Dato(label: 'Identificador', value: '${actual.id}'),
              _Dato(label: 'Servicio', value: actual.servicioNombre),
              _Dato(label: 'Barbero', value: actual.barberoNombre),
              _Dato(label: 'Fecha', value: actual.fecha),
              _Dato(label: 'Hora', value: actual.hora),
              _Dato(label: 'Duración', value: '${actual.duracionMinutos} min'),
              _Dato(
                label: 'Precio',
                value: moneyFormat.format(actual.precioTotal),
              ),
              _Dato(
                label: 'Anticipo pagado',
                value: moneyFormat.format(actual.anticipoPagado),
              ),
              if (actual.anticipoPendiente > 0)
                _Dato(
                  label: 'Anticipo pendiente',
                  value: moneyFormat.format(actual.anticipoPendiente),
                ),
              _Dato(
                label: 'Restante',
                value: moneyFormat.format(actual.restante),
                emphasize: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: EstadoChip(estado: actual.estado),
              ),
              if (penalizacion != null) ...[
                const SizedBox(height: 12),
                Text(
                  penalizacion,
                  style: const TextStyle(color: AppColors.warn),
                ),
              ],
              const SizedBox(height: 24),
              if (actual.puedeMarcarAsistencia) ...[
                _AccionButton(
                  label: 'Cliente llegó',
                  busy: vm.actionBusy,
                  onPressed: () => _llego(context, actual),
                ),
                const SizedBox(height: 10),
                _AccionButton(
                  label: 'No asistió',
                  busy: vm.actionBusy,
                  outlined: true,
                  onPressed: () => _noAsistio(context, actual),
                ),
              ],
              if (actual.puedeCobrar) ...[
                const SizedBox(height: 10),
                _AccionButton(
                  label: 'Cobrar restante',
                  busy: vm.actionBusy,
                  onPressed: () => _cobrar(context, actual),
                ),
              ],
              if (!actual.puedeMarcarAsistencia && !actual.puedeCobrar) ...[
                const Text(
                  'Esta cita no tiene acciones autorizadas por el servidor.',
                  style: TextStyle(color: Color(0xFFA6BAB0)),
                ),
                const SizedBox(height: 12),
              ],
              if (_fechaEditable(actual.fecha)) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: vm.actionBusy
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            AppRoutes.secretaryReprogramar,
                            arguments: actual.id,
                          ),
                    child: const Text('Reprogramar'),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Text(
                  'Las citas de fechas pasadas no se pueden modificar.',
                  style: TextStyle(color: Color(0xFFA6BAB0)),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver a la agenda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final shown = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFA6BAB0)),
            ),
          ),
          Expanded(
            child: Text(
              shown,
              style: TextStyle(
                color: emphasize ? AppColors.gold : AppColors.ivory,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionButton extends StatelessWidget {
  const _AccionButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: busy ? null : onPressed, child: child)
          : ElevatedButton(onPressed: busy ? null : onPressed, child: child),
    );
  }
}

bool _fechaEditable(String fecha) {
  if (fecha.length < 10) return false;
  final parsed = DateTime.tryParse(fecha.substring(0, 10));
  if (parsed == null) return false;
  final hoy = DateTime.now();
  final inicio = DateTime(hoy.year, hoy.month, hoy.day);
  return !parsed.isBefore(inicio);
}

class SecretaryNav extends InheritedWidget {
  const SecretaryNav({super.key, required this.go, required super.child});

  final ValueChanged<int> go;

  static SecretaryNav? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<SecretaryNav>();
  }

  static void open(BuildContext context, int section, String route) {
    final nav = maybeOf(context);
    if (nav != null) {
      nav.go(section);
      return;
    }
    Navigator.pushNamed(context, route);
  }

  @override
  bool updateShouldNotify(SecretaryNav oldWidget) => go != oldWidget.go;
}

/// Lo que la secretaria capturó en el diálogo de cobro.
class _DatosCobro {
  const _DatosCobro({
    required this.metodo,
    required this.comprobante,
    required this.efectivo,
  });

  final String metodo;
  final String comprobante;
  final String efectivo;
}

class _CobroDialog extends StatefulWidget {
  const _CobroDialog({required this.restante});

  final double restante;

  @override
  State<_CobroDialog> createState() => _CobroDialogState();
}

class _CobroDialogState extends State<_CobroDialog> {
  String _metodo = 'efectivo';
  final _comprobante = TextEditingController();
  late final _recibido = TextEditingController(
    text: widget.restante > 0 ? widget.restante.toStringAsFixed(2) : '',
  );

  @override
  void dispose() {
    _comprobante.dispose();
    _recibido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar cobro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Restante ${moneyFormat.format(widget.restante)}',
              style: const TextStyle(color: AppColors.gold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opcion in const [
                  ('efectivo', 'Efectivo'),
                  ('tarjeta', 'Tarjeta'),
                  ('transferencia', 'Transferencia'),
                ])
                  ChoiceChip(
                    label: Text(opcion.$2),
                    selected: _metodo == opcion.$1,
                    onSelected: (_) => setState(() => _metodo = opcion.$1),
                  ),
              ],
            ),
            if (_metodo == 'efectivo' && widget.restante > 0) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _recibido,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Efectivo recibido',
                ),
              ),
            ],
            if (_metodo == 'transferencia') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _comprobante,
                decoration: const InputDecoration(
                  labelText: 'Comprobante / referencia',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            _DatosCobro(
              metodo: _metodo,
              comprobante: _comprobante.text,
              efectivo: _recibido.text,
            ),
          ),
          child: const Text('Cobrar'),
        ),
      ],
    );
  }
}
