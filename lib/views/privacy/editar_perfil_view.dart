import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/auth_models.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/privacidad_viewmodels.dart';
import '../../widgets/common_widgets.dart';
import 'privacidad_widgets.dart';

/// ARCO Rectificación (GH#43). Devuelve `true` al guardar para que la pantalla
/// anterior recargue.
class EditarPerfilView extends StatefulWidget {
  const EditarPerfilView({super.key});

  @override
  State<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends State<EditarPerfilView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _nacimiento = TextEditingController();
  final _direccion = TextEditingController();
  PerfilDto? _cargado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<EditarPerfilViewModel>();
      if (vm.state == LoadState.idle) vm.load();
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _nacimiento.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _llenar(PerfilDto p) {
    if (identical(_cargado, p)) return;
    _cargado = p;
    _nombre.text = p.nombre;
    _apellido.text = p.apellido;
    _telefono.text = p.telefono;
    _nacimiento.text = p.fechaNacimiento;
    _direccion.text = p.direccion;
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final actual = DateTime.tryParse(_nacimiento.text.trim());
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime(hoy.year - 25),
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
    );
    if (elegida == null) return;
    String dos(int n) => n.toString().padLeft(2, '0');
    _nacimiento.text =
        '${elegida.year}-${dos(elegida.month)}-${dos(elegida.day)}';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<EditarPerfilViewModel>();
    final ok = await vm.guardar(
      nombre: _nombre.text,
      apellido: _apellido.text,
      telefono: _telefono.text,
      fechaNacimiento: _nacimiento.text,
      direccion: _direccion.text,
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Datos actualizados.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditarPerfilViewModel>();
    return PrivacidadScaffold(titulo: 'Corregir mis datos', body: _cuerpo(vm));
  }

  Widget _cuerpo(EditarPerfilViewModel vm) {
    switch (vm.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const LoadingView(label: 'Cargando tu perfil…');
      case LoadState.error:
      case LoadState.empty:
        return ErrorView(
          message: vm.errorMessage ?? 'No se pudo cargar tu perfil.',
          onRetry: vm.load,
        );
      case LoadState.ready:
        _llenar(vm.perfil!);
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              PanelSeccion(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DatoRow(label: 'Correo', value: vm.perfil!.email),
                    const Text(
                      'El correo y el usuario no se cambian aquí.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (vm.errorMessage != null)
                StatusBanner(message: vm.errorMessage!, isError: true),
              TextFormField(
                key: const Key('editar_nombre'),
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: validarNombre,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editar_apellido'),
                controller: _apellido,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Apellido (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editar_telefono'),
                controller: _telefono,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  helperText: 'De 10 a 15 dígitos',
                ),
                validator: validarTelefono,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editar_nacimiento'),
                controller: _nacimiento,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Fecha de nacimiento (opcional)',
                  helperText: 'AAAA-MM-DD',
                  suffixIcon: IconButton(
                    tooltip: 'Elegir fecha',
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                validator: validarFechaNacimiento,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editar_direccion'),
                controller: _direccion,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                  helperText: 'Si la dejas vacía, se quita la dirección actual',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('editar_perfil_guardar'),
                  onPressed: vm.saving ? null : _guardar,
                  child: vm.saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onGold,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        );
    }
  }
}
