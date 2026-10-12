import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/secretaria_gestion_viewmodel.dart';
import '../../viewmodels/secretaria_hoy_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';

class SecretaryNuevaCitaView extends StatefulWidget {
  const SecretaryNuevaCitaView({super.key});

  @override
  State<SecretaryNuevaCitaView> createState() => _SecretaryNuevaCitaViewState();
}

class _SecretaryNuevaCitaViewState extends State<SecretaryNuevaCitaView> {
  final _buscar = TextEditingController();
  final _nombres = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _anticipo = TextEditingController();
  final _comprobante = TextEditingController();
  final _notas = TextEditingController();
  bool _paso = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hoy = context.read<SecretariaHoyViewModel>();
      final gestion = context.read<SecretariaGestionViewModel>();
      gestion.prepararNueva(_fechaInicial(hoy));
      gestion.cargarServicios();
    });
  }

  @override
  void dispose() {
    _buscar.dispose();
    _nombres.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _anticipo.dispose();
    _comprobante.dispose();
    _notas.dispose();
    super.dispose();
  }

  String _fechaInicial(SecretariaHoyViewModel hoy) {
    final raw = hoy.fechaSeleccionada ?? hoy.dia?.fecha ?? '';
    final parsed = DateTime.tryParse(
      raw.length >= 10 ? raw.substring(0, 10) : raw,
    );
    final hoyDia = DateTime.now();
    final inicio = DateTime(hoyDia.year, hoyDia.month, hoyDia.day);
    if (parsed != null && !parsed.isBefore(inicio)) {
      return _iso(parsed);
    }
    return _iso(inicio);
  }

  Future<void> _elegirFecha(SecretariaGestionViewModel vm) async {
    final actual = DateTime.tryParse(vm.fecha) ?? DateTime.now();
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: actual.isBefore(inicio) ? inicio : actual,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 60)),
    );
    if (picked == null) return;
    await vm.elegirFecha(_iso(picked));
  }

  Future<void> _registrarPaso(SecretariaGestionViewModel vm) async {
    final ok = await _confirmar(
      'Registrar cliente de paso',
      'Se creará un cliente en el servidor con el nombre y el teléfono indicados.',
    );
    if (!ok || !mounted) return;
    final creado = await vm.registrarClientePaso(
      nombres: _nombres.text,
      apellido: _apellido.text,
      telefono: _telefono.text,
    );
    if (!creado || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vm.cliente?.nombreCompleto ?? 'Cliente registrado'),
      ),
    );
  }

  Future<void> _confirmarCita(SecretariaGestionViewModel vm) async {
    vm.setAnticipoTexto(_anticipo.text);
    vm.setComprobante(_comprobante.text);
    vm.setNotas(_notas.text);
    final ok = await _confirmar(
      'Crear cita',
      'La cita se guardará solo si el servidor acepta el horario.',
    );
    if (!ok || !mounted) return;
    final id = await vm.crearCita();
    if (!mounted) return;
    final mensaje = id != null
        ? (vm.mensaje ?? 'Cita creada (#$id).')
        : (vm.errorMessage ?? 'No se pudo crear la cita.');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
    if (id == null) return;
    await context.read<SecretariaHoyViewModel>().load(fecha: vm.fecha);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _confirmar(String title, String message) async {
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
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(title: const Text('Nueva cita')),
        body: SafeArea(
          child: Consumer<SecretariaGestionViewModel>(
            builder: (context, vm, _) {
              final precio = vm.servicio?.precio ?? 0;
              final minimo = vm.anticipoMinimo(precio);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        if (vm.errorMessage != null)
                          StatusBanner(
                            message: vm.errorMessage!,
                            isError: true,
                          ),
                        const _Titulo('Cliente'),
                        TextField(
                          controller: _buscar,
                          textInputAction: TextInputAction.search,
                          scrollPadding: const EdgeInsets.only(bottom: 120),
                          decoration: const InputDecoration(
                            labelText: 'Buscar cliente',
                            hintText: 'Nombre, teléfono o correo',
                          ),
                          onChanged: vm.buscarClientes,
                        ),
                        const SizedBox(height: 8),
                        if (vm.clientesState == LoadState.loading)
                          const LinearProgressIndicator(
                            minHeight: 2,
                            color: AppColors.gold,
                          )
                        else if (vm.clientesState == LoadState.empty)
                          const Text('Ningún cliente coincide.')
                        else if (vm.clientesState == LoadState.error)
                          TextButton(
                            onPressed: () => vm.buscarClientes(_buscar.text),
                            child: const Text('Reintentar'),
                          )
                        else
                          for (final c in vm.clientes)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(c.nombreCompleto),
                              subtitle: Text(
                                [
                                  if (c.telefono.isNotEmpty) c.telefono,
                                  if (c.email.isNotEmpty) c.email,
                                ].join(' · '),
                              ),
                              selected: vm.cliente?.id == c.id,
                              onTap: () => vm.elegirCliente(c),
                            ),
                        if (vm.cliente != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Seleccionado: ${vm.cliente!.nombreCompleto}',
                              style: const TextStyle(color: AppColors.gold),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setState(() => _paso = !_paso),
                            child: Text(
                              _paso
                                  ? 'Ocultar cliente de paso'
                                  : 'Registrar cliente de paso',
                            ),
                          ),
                        ),
                        if (_paso) ...[
                          TextField(
                            controller: _nombres,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                          ),
                          TextField(
                            controller: _apellido,
                            decoration: const InputDecoration(
                              labelText: 'Apellido paterno',
                            ),
                          ),
                          TextField(
                            controller: _telefono,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: vm.busy
                                ? null
                                : () => _registrarPaso(vm),
                            child: const Text('Registrar cliente'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const _Titulo('Servicio'),
                        if (vm.serviciosState == LoadState.loading)
                          const LoadingView(label: 'Cargando servicios…')
                        else if (vm.serviciosState == LoadState.error)
                          ErrorView(
                            message: vm.errorMessage ?? 'Error',
                            onRetry: vm.cargarServicios,
                          )
                        else if (vm.serviciosReservables.isEmpty)
                          const Text('No hay servicios publicados.')
                        else
                          for (final s in vm.serviciosReservables)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(s.nombre),
                              subtitle: Text(
                                '${s.duracionMinutos} min · ${moneyFormat.format(s.precio)}',
                              ),
                              selected: vm.servicio?.id == s.id,
                              onTap: () => vm.elegirServicio(s),
                            ),
                        const SizedBox(height: 8),
                        const _Titulo('Barbero'),
                        if (vm.servicio == null)
                          const Text('Elige un servicio para ver barberos.')
                        else if (vm.barberosLoading)
                          const LoadingView(label: 'Cargando barberos…')
                        else if (vm.barberos.isEmpty)
                          const Text('No hay barberos para ese servicio.')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final b in vm.barberos)
                                ChoiceChip(
                                  label: Text(b.displayName),
                                  selected: vm.barbero?.id == b.id,
                                  onSelected: (_) => vm.elegirBarbero(b),
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        const _Titulo('Fecha y horario'),
                        OutlinedButton.icon(
                          onPressed: () => _elegirFecha(vm),
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            vm.fecha.isEmpty ? 'Elegir fecha' : vm.fecha,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (vm.barbero == null)
                          const Text(
                            'Elige un barbero para consultar disponibilidad.',
                          )
                        else if (vm.slotsLoading)
                          const LoadingView(label: 'Consultando horarios…')
                        else if (vm.horariosElegibles.isEmpty)
                          const Text(
                            'No hay horarios disponibles para esa fecha.',
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final slot in vm.horariosElegibles)
                                ChoiceChip(
                                  label: Text(slot.hora),
                                  selected:
                                      vm.hora ==
                                      slot.hora.substring(
                                        0,
                                        slot.hora.length.clamp(0, 5),
                                      ),
                                  onSelected: (_) => vm.elegirHora(slot.hora),
                                ),
                            ],
                          ),
                        if (minimo > 0) ...[
                          const SizedBox(height: 16),
                          StatusBanner(
                            message:
                                'Cliente penalizado. Anticipo mínimo ${moneyFormat.format(minimo)}.',
                          ),
                          TextField(
                            controller: _anticipo,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Anticipo',
                            ),
                            onChanged: vm.setAnticipoTexto,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final metodo in const [
                                'efectivo',
                                'tarjeta',
                                'transferencia',
                              ])
                                ChoiceChip(
                                  label: Text(metodo),
                                  selected: vm.metodoAnticipo == metodo,
                                  onSelected: (_) =>
                                      vm.setMetodoAnticipo(metodo),
                                ),
                            ],
                          ),
                          if (vm.metodoAnticipo == 'transferencia')
                            TextField(
                              controller: _comprobante,
                              decoration: const InputDecoration(
                                labelText: 'Comprobante / referencia',
                              ),
                              onChanged: vm.setComprobante,
                            ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notas,
                          decoration: const InputDecoration(labelText: 'Notas'),
                          onChanged: vm.setNotas,
                        ),
                        if (vm.puedeConfirmarCreacion) ...[
                          const SizedBox(height: 16),
                          const _Titulo('Resumen'),
                          Text(vm.cliente!.nombreCompleto),
                          Text(vm.servicio!.nombre),
                          Text(vm.barbero!.displayName),
                          Text('${vm.fecha} · ${vm.hora}'),
                          Text(moneyFormat.format(vm.servicio!.precio)),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: PressScale(
                      enabled: !vm.busy,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: vm.busy ? null : () => _confirmarCita(vm),
                          child: vm.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Confirmar cita'),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SecretaryClienteCitasView extends StatefulWidget {
  const SecretaryClienteCitasView({super.key});

  @override
  State<SecretaryClienteCitasView> createState() =>
      _SecretaryClienteCitasViewState();
}

class _SecretaryClienteCitasViewState extends State<SecretaryClienteCitasView> {
  final _buscar = TextEditingController();

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _abrir(SecretariaCitaResumenDto cita) async {
    final hoy = context.read<SecretariaHoyViewModel>();
    await hoy.load(fecha: cita.fecha);
    if (!mounted) return;
    final coincidencias =
        hoy.dia?.citas.where((c) => c.id == cita.id) ?? const [];
    if (coincidencias.isNotEmpty) {
      await Navigator.pushNamed(
        context,
        AppRoutes.secretaryCitaDetail,
        arguments: coincidencias.first,
      );
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cita #${cita.id}'),
        content: Text(
          '${cita.fecha} · ${cita.hora}\n${cita.servicio}\n${cita.barbero}\n${cita.estado}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(title: const Text('Citas del cliente')),
        body: SafeArea(
          child: Consumer<SecretariaGestionViewModel>(
            builder: (context, vm, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (vm.errorMessage != null)
                    StatusBanner(message: vm.errorMessage!, isError: true),
                  TextField(
                    controller: _buscar,
                    decoration: const InputDecoration(
                      labelText: 'Buscar cliente',
                      hintText: 'Al menos 2 caracteres',
                    ),
                    onChanged: vm.buscarClientes,
                  ),
                  const SizedBox(height: 8),
                  if (vm.clientesState == LoadState.loading)
                    const LoadingView(label: 'Buscando clientes…')
                  else if (vm.clientesState == LoadState.empty)
                    const Text('Ningún cliente coincide.')
                  else if (vm.clientesState == LoadState.error)
                    ErrorView(
                      message: vm.errorMessage ?? 'Error',
                      onRetry: () => vm.buscarClientes(_buscar.text),
                    )
                  else
                    for (final c in vm.clientes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.nombreCompleto),
                        subtitle: Text(c.telefono),
                        onTap: () {
                          vm.elegirCliente(c);
                          vm.cargarCitasCliente(c.id);
                        },
                      ),
                  const SizedBox(height: 12),
                  if (vm.citasClienteState == LoadState.loading)
                    const LoadingView(label: 'Cargando citas…')
                  else if (vm.citasClienteState == LoadState.empty)
                    EmptyView(
                      message: 'Este cliente no tiene citas desde hoy.',
                      onRetry: vm.cliente == null
                          ? null
                          : () => vm.cargarCitasCliente(vm.cliente!.id),
                    )
                  else if (vm.citasClienteState == LoadState.error)
                    ErrorView(
                      message: vm.errorMessage ?? 'Error',
                      onRetry: vm.cliente == null
                          ? null
                          : () => vm.cargarCitasCliente(vm.cliente!.id),
                    )
                  else
                    for (final cita in vm.citasCliente)
                      Card(
                        color: AppColors.panelCard,
                        child: ListTile(
                          title: Text('${cita.fecha} · ${cita.hora}'),
                          subtitle: Text(
                            '${cita.servicio}\n${cita.barbero} · ${cita.estado}',
                          ),
                          isThreeLine: true,
                          onTap: () => _abrir(cita),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SecretaryReprogramarView extends StatefulWidget {
  const SecretaryReprogramarView({super.key, required this.citaId});

  final int citaId;

  @override
  State<SecretaryReprogramarView> createState() =>
      _SecretaryReprogramarViewState();
}

class _SecretaryReprogramarViewState extends State<SecretaryReprogramarView> {
  final _notas = TextEditingController();
  SecretariaGestionViewModel? _gestion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<SecretariaGestionViewModel>();
    if (!identical(_gestion, vm)) {
      _gestion?.removeListener(_copiarNotas);
      _gestion = vm;
      vm.addListener(_copiarNotas);
      vm.cargarEditable(widget.citaId);
    }
  }

  void _copiarNotas() {
    final notas = _gestion?.notas ?? '';
    if (_notas.text.isEmpty && notas.isNotEmpty) {
      _notas.text = notas;
    }
  }

  @override
  void dispose() {
    _gestion?.removeListener(_copiarNotas);
    _notas.dispose();
    super.dispose();
  }

  Future<void> _fecha(SecretariaGestionViewModel vm) async {
    final minima =
        DateTime.tryParse(vm.editable?.fechaMinima ?? '') ?? DateTime.now();
    final actual = DateTime.tryParse(vm.fecha) ?? minima;
    final picked = await showDatePicker(
      context: context,
      initialDate: actual.isBefore(minima) ? minima : actual,
      firstDate: DateTime(minima.year, minima.month, minima.day),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null) return;
    await vm.elegirFecha(_iso(picked));
  }

  Future<void> _guardar(SecretariaGestionViewModel vm) async {
    vm.setNotas(_notas.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprogramar cita'),
        content: const Text(
          'El cambio se aplica solo cuando el servidor confirma el horario.',
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
    if (ok != true || !mounted) return;
    final success = await vm.reprogramar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (vm.mensaje ?? 'Cita actualizada correctamente.')
              : (vm.errorMessage ?? 'No se pudo actualizar la cita.'),
        ),
      ),
    );
    if (!success) return;
    await context.read<SecretariaHoyViewModel>().load(fecha: vm.fecha);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _cancelar(SecretariaGestionViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text(
          'El servidor cancela la cita si su fecha es de hoy en adelante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await vm.cancelarCita();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (vm.mensaje ?? 'Cita actualizada correctamente.')
              : (vm.errorMessage ?? 'No se pudo cancelar la cita.'),
        ),
      ),
    );
    if (!success) return;
    await context.read<SecretariaHoyViewModel>().load(
      fecha: vm.editable?.fecha,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(title: Text('Reprogramar #${widget.citaId}')),
        body: SafeArea(
          child: Consumer<SecretariaGestionViewModel>(
            builder: (context, vm, _) {
              if (vm.editableState == LoadState.loading ||
                  vm.editableState == LoadState.idle) {
                return const LoadingView(label: 'Cargando cita…');
              }
              if (vm.editableState == LoadState.error) {
                return ErrorView(
                  message: vm.errorMessage ?? 'Error',
                  onRetry: () => vm.cargarEditable(widget.citaId),
                );
              }
              final actual = vm.editable;
              if (actual == null || !actual.puedeEditar) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    Text(
                      'El servidor no permite modificar esta cita. Solo se editan citas de hoy en adelante.',
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (vm.errorMessage != null)
                    StatusBanner(message: vm.errorMessage!, isError: true),
                  Text(
                    actual.clienteNombre,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const _Titulo('Servicio'),
                  for (final s in vm.serviciosReservables)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.nombre),
                      subtitle: Text(
                        '${s.duracionMinutos} min · ${moneyFormat.format(s.precio)}',
                      ),
                      selected: vm.servicio?.id == s.id,
                      onTap: vm.busy ? null : () => vm.elegirServicio(s),
                    ),
                  if (vm.servicio != null &&
                      !vm.serviciosReservables.any(
                        (s) => s.id == vm.servicio!.id,
                      ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(vm.servicio!.nombre),
                      selected: true,
                    ),
                  const _Titulo('Barbero'),
                  if (vm.barberosLoading)
                    const LoadingView(label: 'Cargando barberos…')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final b in vm.barberos)
                          ChoiceChip(
                            label: Text(b.displayName),
                            selected: vm.barbero?.id == b.id,
                            onSelected: vm.busy
                                ? null
                                : (_) => vm.elegirBarbero(b),
                          ),
                        if (vm.barbero != null &&
                            !vm.barberos.any((b) => b.id == vm.barbero!.id))
                          ChoiceChip(
                            label: Text(vm.barbero!.displayName),
                            selected: true,
                            onSelected: null,
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: vm.busy ? null : () => _fecha(vm),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(vm.fecha),
                  ),
                  const SizedBox(height: 8),
                  if (vm.slotsLoading)
                    const LoadingView(label: 'Consultando horarios…')
                  else if (vm.horariosElegibles.isEmpty)
                    const Text('No hay horarios disponibles para esa fecha.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in vm.horariosElegibles)
                          ChoiceChip(
                            label: Text(
                              slot.hora == actual.hora
                                  ? '${slot.hora} · actual'
                                  : slot.hora,
                            ),
                            selected:
                                vm.hora ==
                                slot.hora.substring(
                                  0,
                                  slot.hora.length.clamp(0, 5),
                                ),
                            onSelected: vm.busy
                                ? null
                                : (_) => vm.elegirHora(slot.hora),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notas,
                    decoration: const InputDecoration(labelText: 'Notas'),
                    onChanged: vm.setNotas,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.busy ? null : () => _guardar(vm),
                      child: vm.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar cambio'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: vm.busy ? null : () => _cancelar(vm),
                      child: const Text('Cancelar cita'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

String _iso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
