import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';

/// Etiqueta discreta con el ambiente del build (GH#68, CORE-001).
///
/// Muestra `DEV` o `STAGING` y el host de la API para que quien prueba sepa
/// contra qué backend trabaja. En producción no pinta nada.
class EtiquetaAmbiente extends StatelessWidget {
  const EtiquetaAmbiente({super.key, this.ambiente});

  /// Ambiente a mostrar. Por defecto, el del build ([AppConfig.ambiente]).
  final AmbienteConfig? ambiente;

  @override
  Widget build(BuildContext context) {
    final a = ambiente ?? AppConfig.ambiente;
    final etiqueta = a.etiqueta;
    if (etiqueta == null) return const SizedBox.shrink();
    final uri = Uri.parse(a.apiBaseUrl);
    final host = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Center(
        child: Semantics(
          container: true,
          label: 'Ambiente $etiqueta, API $host',
          child: ExcludeSemantics(
            child: DecoratedBox(
              key: const Key('etiqueta_ambiente'),
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                border: Border.all(color: AppColors.warn),
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '$etiqueta · $host',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.warn,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
