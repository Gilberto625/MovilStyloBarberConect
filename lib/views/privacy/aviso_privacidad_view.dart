import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/privacidad_viewmodels.dart';
import '../../widgets/common_widgets.dart';
import 'privacidad_widgets.dart';

/// Aviso de privacidad desde `/public/legal/` (6.6) y opt-in de finalidades
/// secundarias, apagado por defecto (6.7, GH#41). Se abre sin sesión.
class AvisoPrivacidadView extends StatefulWidget {
  const AvisoPrivacidadView({super.key});

  @override
  State<AvisoPrivacidadView> createState() => _AvisoPrivacidadViewState();
}

class _AvisoPrivacidadViewState extends State<AvisoPrivacidadView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AvisoPrivacidadViewModel>();
      if (vm.state == LoadState.idle) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AvisoPrivacidadViewModel>();
    return PrivacidadScaffold(titulo: 'Aviso de privacidad', body: _cuerpo(vm));
  }

  Widget _cuerpo(AvisoPrivacidadViewModel vm) {
    switch (vm.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const LoadingView(label: 'Cargando aviso…');
      case LoadState.error:
        return ErrorView(
          message: vm.errorMessage ?? 'No se pudo cargar el aviso.',
          onRetry: vm.load,
        );
      case LoadState.empty:
        return EmptyView(
          message: 'El aviso de privacidad aún no está publicado.',
          onRetry: vm.load,
        );
      case LoadState.ready:
        final aviso = vm.aviso!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            PanelSeccion(
              titulo: aviso.titulo.isEmpty ? aviso.tipoDisplay : aviso.titulo,
              child: SelectableText(
                aviso.contenido,
                style: const TextStyle(color: AppColors.text, height: 1.5),
              ),
            ),
            PanelSeccion(
              titulo: 'Usos opcionales de tus datos',
              child: _preferencias(vm),
            ),
          ],
        );
    }
  }

  Widget _preferencias(AvisoPrivacidadViewModel vm) {
    const intro = Text(
      'Agendar y atender tus citas no depende de esto. '
      'Todo empieza apagado y puedes cambiarlo cuando quieras.',
      style: TextStyle(color: AppColors.muted, height: 1.4),
    );
    if (!vm.autenticado) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro,
          SizedBox(height: 12),
          Text(
            'Inicia sesión para elegir tus permisos. Se guardan en tu cuenta.',
            key: Key('aviso_requiere_sesion'),
            style: TextStyle(color: AppColors.ivory, height: 1.4),
          ),
        ],
      );
    }
    if (!vm.preferenciasListas) {
      final error = vm.preferenciasError;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro,
          const SizedBox(height: 12),
          if (error == null)
            const LoadingView(label: 'Cargando tus preferencias…')
          else ...[
            StatusBanner(message: error, isError: true),
            OutlinedButton(
              onPressed: vm.cargarPreferencias,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        intro,
        if (vm.avisoCambio)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: StatusBanner(
              message:
                  'El aviso cambió desde tu última respuesta. '
                  'Revisa tus preferencias.',
            ),
          ),
        const SizedBox(height: 8),
        _Permiso(
          key: const Key('aviso_opt_promociones'),
          titulo: 'Promociones y novedades',
          detalle: 'Ofertas y avisos de la barbería.',
          valor: vm.borrador.promociones,
          onChanged: vm.saving ? null : vm.setPromociones,
        ),
        _Permiso(
          key: const Key('aviso_opt_whatsapp'),
          titulo: 'Recordatorios por WhatsApp',
          detalle: 'Mensajes antes de tus citas.',
          valor: vm.borrador.recordatoriosWhatsapp,
          onChanged: vm.saving ? null : vm.setRecordatoriosWhatsapp,
        ),
        _Permiso(
          key: const Key('aviso_opt_perfilado'),
          titulo: 'Análisis de mi historial',
          detalle: 'Estadísticas y estimación de inasistencia con mis citas.',
          valor: vm.borrador.analiticaPerfilado,
          onChanged: vm.saving ? null : vm.setAnaliticaPerfilado,
        ),
        if (vm.guardado.fecha != null)
          Text(
            'Última respuesta: ${fechaHoraCorta(vm.guardado.fecha!)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        if (vm.mensaje != null) ...[
          const SizedBox(height: 12),
          StatusBanner(message: vm.mensaje!),
        ],
        if (vm.preferenciasError != null) ...[
          const SizedBox(height: 12),
          StatusBanner(message: vm.preferenciasError!, isError: true),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            key: const Key('aviso_guardar_preferencias'),
            onPressed: vm.puedeGuardar ? vm.guardar : null,
            child: vm.saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onGold,
                    ),
                  )
                : const Text('Guardar mis preferencias'),
          ),
        ),
      ],
    );
  }
}

class _Permiso extends StatelessWidget {
  const _Permiso({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.valor,
    required this.onChanged,
  });

  final String titulo;
  final String detalle;
  final bool valor;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.onGold,
      activeTrackColor: AppColors.gold,
      title: Text(titulo, style: const TextStyle(color: AppColors.ivory)),
      subtitle: Text(detalle, style: const TextStyle(color: AppColors.muted)),
      value: valor,
      onChanged: onChanged,
    );
  }
}
