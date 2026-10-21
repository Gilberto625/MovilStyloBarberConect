import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Marco común de las pantallas de privacidad: tema de invitado (el mismo que
/// el panel de cliente), una sola top bar con regreso y ancho máximo legible.
class PrivacidadScaffold extends StatelessWidget {
  const PrivacidadScaffold({
    super.key,
    required this.titulo,
    required this.body,
  });

  final String titulo;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        appBar: AppBar(title: Text(titulo)),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class PanelSeccion extends StatelessWidget {
  const PanelSeccion({super.key, this.titulo, required this.child});

  final String? titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Material (no Container con color) para que los ListTile de adentro
    // pinten su efecto de toque.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titulo != null) ...[
                Text(
                  titulo!,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.ivory),
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta y valor. Un valor vacío se muestra como "Sin registrar", porque en
/// "Mis datos" también importa saber qué no se tiene.
class DatoRow extends StatelessWidget {
  const DatoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vacio = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Text(
            vacio ? 'Sin registrar' : _cortable(value),
            softWrap: true,
            style: TextStyle(
              color: vacio ? AppColors.muted : AppColors.ivory,
              fontStyle: vacio ? FontStyle.italic : FontStyle.normal,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Permite cortar correos y URLs largas en pantallas de 360 dp.
String _cortable(String value) {
  if (!value.contains('@') && !value.contains('/')) return value;
  return value.replaceAll('@', '@​').replaceAll('.', '.​');
}

String fechaHoraCorta(DateTime fecha) {
  final f = fecha.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
}
