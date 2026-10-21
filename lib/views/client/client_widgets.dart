import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cita_models.dart';
import '../../widgets/common_widgets.dart';

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

DateTime? _parse(String yyyyMmDd) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(yyyyMmDd.trim());
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

/// "Martes 14 de octubre". Si no es una fecha válida devuelve el texto tal
/// cual, sin inventar.
String fechaLarga(String yyyyMmDd) {
  final d = _parse(yyyyMmDd);
  if (d == null) return yyyyMmDd;
  return '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';
}

/// "14 oct".
({String dia, String mes})? fechaCorta(String yyyyMmDd) {
  final d = _parse(yyyyMmDd);
  if (d == null) return null;
  return (dia: '${d.day}', mes: _meses[d.month - 1].substring(0, 3));
}

String diaSemanaCorto(DateTime d) => _dias[d.weekday - 1].substring(0, 3);

String isoFecha(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Hora `HH:MM` aunque el backend mande segundos.
String horaCorta(String hora) {
  final partes = hora.trim().split(':');
  if (partes.length < 2) return hora;
  return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';
}

const estadosCerrados = {'cancelada', 'completada', 'no_asistio'};

/// Encabezado de cada pestaña del cliente.
class ClientHeader extends StatelessWidget {
  const ClientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.headlineMedium),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Fila seleccionable con borde de latón cuando está elegida.
class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.quick);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.ease,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  AppColors.gold.withValues(alpha: 0.10),
                  AppColors.surface,
                )
              : AppColors.surface,
          borderRadius: AppRadii.cardBorder,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadii.cardBorder,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.appointmentRow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo con iniciales para personas sin foto.
class Iniciales extends StatelessWidget {
  const Iniciales({super.key, required this.nombre, this.size = 44});

  final String nombre;
  final double size;

  @override
  Widget build(BuildContext context) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final ini = partes
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        ini.isEmpty ? '?' : ini,
        style: AppText.cifra(size: size * 0.34, color: AppColors.goldSoft),
      ),
    );
  }
}

/// Selector de cantidad con 48 dp por botón. El número cambia con un
/// desplazamiento corto.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.cantidad,
    required this.onMenos,
    required this.onMas,
    this.nombre = '',
  });

  final int cantidad;
  final VoidCallback onMenos;
  final VoidCallback? onMas;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.quick);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadii.controlBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Quitar uno de $nombre',
            onPressed: onMenos,
            icon: Icon(
              cantidad <= 1 ? Icons.delete_outline : Icons.remove_rounded,
            ),
          ),
          AnimatedSwitcher(
            duration: dur,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: a, curve: AppMotion.ease)),
                child: child,
              ),
            ),
            child: SizedBox(
              key: ValueKey(cantidad),
              width: 28,
              child: Text(
                '$cantidad',
                textAlign: TextAlign.center,
                style: AppText.cifra(size: 16),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Agregar uno de $nombre',
            onPressed: onMas,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

/// Boleto de cita (DESIGN.md › componente "Próxima cita"): hora grande,
/// estado con palabra y pares etiqueta–valor.
class CitaTicket extends StatelessWidget {
  const CitaTicket({super.key, required this.cita, this.actions});

  final CitaDto cita;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadii.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fechaLarga(cita.fecha),
                      style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      horaCorta(cita.hora),
                      style: AppText.cifra(size: 40, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: EstadoChip(estado: cita.estado),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          InfoRow(label: 'Servicio', value: cita.servicioNombre),
          InfoRow(label: 'Barbero', value: cita.barberoNombre),
          InfoRow(label: 'Duración', value: '${cita.duracionMinutos} min'),
          if (actions != null) ...[
            const SizedBox(height: AppSpacing.md),
            actions!,
          ],
        ],
      ),
    );
  }
}
