import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/privacidad_viewmodels.dart';
import '../../widgets/common_widgets.dart';
import 'privacidad_widgets.dart';

/// Términos de uso desde `/public/legal/?tipo=terminos`, el mismo texto que
/// publica la web en `/nosotros?tipo=terminos`. Se abre sin sesión.
class TerminosView extends StatefulWidget {
  const TerminosView({super.key});

  @override
  State<TerminosView> createState() => _TerminosViewState();
}

class _TerminosViewState extends State<TerminosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<TerminosViewModel>();
      if (vm.state == LoadState.idle) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TerminosViewModel>();
    return PrivacidadScaffold(titulo: 'Términos de uso', body: _cuerpo(vm));
  }

  Widget _cuerpo(TerminosViewModel vm) {
    switch (vm.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const LoadingView(label: 'Cargando términos…');
      case LoadState.error:
        return ErrorView(
          message: vm.errorMessage ?? 'No se pudieron cargar los términos.',
          onRetry: vm.load,
        );
      case LoadState.empty:
        return EmptyView(
          message: 'Los términos de uso aún no están publicados.',
          onRetry: vm.load,
        );
      case LoadState.ready:
        final terminos = vm.terminos!;
        return ListView(
          key: const Key('terminos_contenido'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            PanelSeccion(
              titulo: terminos.titulo.isEmpty
                  ? terminos.tipoDisplay
                  : terminos.titulo,
              child: SelectableText(
                terminos.contenido,
                style: const TextStyle(color: AppColors.text, height: 1.5),
              ),
            ),
          ],
        );
    }
  }
}
