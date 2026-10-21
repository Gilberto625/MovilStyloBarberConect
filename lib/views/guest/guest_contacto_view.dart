import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../widgets/common_widgets.dart';
import 'catalog_list_views.dart';

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Solo se abren enlaces web del backend (mapa, WhatsApp); nunca otros
/// esquemas que pudieran lanzar intents arbitrarios.
Uri? enlaceWebSeguro(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  return uri;
}

/// `tel:` con solo dígitos y `+`.
Uri? enlaceTelefono(String telefono) {
  final limpio = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
  if (limpio.length < 7) return null;
  return Uri(scheme: 'tel', path: limpio);
}

/// Copia un dato y lo confirma. Si el portapapeles falla, lo dice.
Future<void> copiarDato(BuildContext context, String valor, String que) async {
  var ok = true;
  try {
    await Clipboard.setData(ClipboardData(text: valor));
  } catch (_) {
    ok = false;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(ok ? '$que copiado' : 'No se pudo copiar $que')),
    );
}

/// Abre un enlace en otra app (mapa, WhatsApp, marcador). Se reemplaza en
/// las pruebas para no depender del canal de la plataforma.
@visibleForTesting
Future<bool> Function(Uri uri) abrirUrlExterna = (uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Abre el enlace fuera de la app. Si no hay app que lo abra, copia el dato
/// para que la persona lo pegue donde quiera.
Future<void> abrirEnlace(
  BuildContext context,
  Uri uri, {
  required String respaldo,
  required String que,
}) async {
  var abierto = false;
  try {
    abierto = await abrirUrlExterna(uri);
  } catch (_) {
    abierto = false;
  }
  if (abierto || !context.mounted) return;
  var copiado = true;
  try {
    await Clipboard.setData(ClipboardData(text: respaldo));
  } catch (_) {
    copiado = false;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          copiado
              ? 'No se pudo abrir $que. Copiamos el dato para que lo pegues.'
              : 'No se pudo abrir $que.',
        ),
      ),
    );
}

/// Texto y color del estado de hoy.
({String texto, Color color})? estadoHoyTexto(HorarioHoy? hoy) {
  if (hoy == null) return null;
  return switch (hoy.estado) {
    EstadoHoy.abierto => (
      texto: 'Abierto ahora, cierra a las ${hoy.cierre}',
      color: AppColors.ok,
    ),
    EstadoHoy.abrePronto => (
      texto: 'Hoy abre a las ${hoy.apertura}',
      color: AppColors.warn,
    ),
    EstadoHoy.yaCerro => (texto: 'Ya cerramos por hoy', color: AppColors.muted),
    EstadoHoy.cerrado => (texto: 'Hoy no abrimos', color: AppColors.muted),
    EstadoHoy.sinDato => (
      texto: 'Horario de hoy no publicado',
      color: AppColors.muted,
    ),
  };
}

/// Punto de color más su palabra (DESIGN.md › Estado Con Palabra).
class HoyEstadoLine extends StatelessWidget {
  const HoyEstadoLine({super.key, required this.hoy, this.onPhoto = false});

  final HorarioHoy? hoy;

  /// Sobre la foto del inicio el texto va en marfil para el contraste.
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final estado = estadoHoyTexto(hoy);
    if (estado == null) return const SizedBox.shrink();
    return Row(
      key: const ValueKey('guest-hoy-estado'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: estado.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            estado.texto,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onPhoto ? AppColors.ivory : AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Invitado › Pantalla 6: Contacto (Actividad 3).
class GuestContactoTab extends StatelessWidget {
  const GuestContactoTab({super.key, required this.contacto, this.now});

  final ContactoDto contacto;

  /// Reloj inyectable para pruebas.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = contacto;
    final mapa = enlaceWebSeguro(c.googleMapsUrl);
    final whatsapp = enlaceWebSeguro(c.whatsappUrl);
    final tel = enlaceTelefono(c.telefono);
    final hoyDate = now ?? DateTime.now();
    final sinDatos =
        c.telefono.isEmpty &&
        c.correo.isEmpty &&
        c.direccion.isEmpty &&
        mapa == null &&
        whatsapp == null;

    return ListView(
      key: const PageStorageKey('guest-contacto'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      children: [
        _Columna(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CatalogHeader(title: 'Contacto', subtitle: c.nombreNegocio),
              if (tel != null || whatsapp != null || mapa != null) ...[
                Row(
                  children: [
                    if (tel != null)
                      Expanded(
                        child: _AccionContacto(
                          key: const ValueKey('contacto-llamar'),
                          icon: Icons.call_outlined,
                          label: 'Llamar',
                          onTap: () => abrirEnlace(
                            context,
                            tel,
                            respaldo: c.telefono,
                            que: 'el marcador',
                          ),
                        ),
                      ),
                    if (whatsapp != null) ...[
                      if (tel != null) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _AccionContacto(
                          key: const ValueKey('contacto-whatsapp'),
                          icon: Icons.chat_outlined,
                          label: 'WhatsApp',
                          onTap: () => abrirEnlace(
                            context,
                            whatsapp,
                            respaldo: c.whatsappUrl,
                            que: 'WhatsApp',
                          ),
                        ),
                      ),
                    ],
                    if (mapa != null) ...[
                      if (tel != null || whatsapp != null)
                        const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _AccionContacto(
                          key: const ValueKey('contacto-mapa'),
                          icon: Icons.directions_outlined,
                          label: 'Cómo llegar',
                          onTap: () => abrirEnlace(
                            context,
                            mapa,
                            respaldo: c.googleMapsUrl,
                            que: 'el mapa',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SurfaceCard(
                child: sinDatos
                    ? Text(
                        'Información de contacto no publicada.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.direccion.isNotEmpty)
                            _DatoCopiable(
                              icon: Icons.location_on_outlined,
                              label: 'Dirección',
                              value: c.direccion,
                            ),
                          if (c.telefono.isNotEmpty)
                            _DatoCopiable(
                              icon: Icons.phone_outlined,
                              label: 'Teléfono',
                              value: c.telefono,
                            ),
                          if (c.correo.isNotEmpty)
                            _DatoCopiable(
                              icon: Icons.mail_outline,
                              label: 'Correo',
                              value: c.correo,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SurfaceCard(
                child: _Horarios(contacto: c, now: hoyDate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContent),
        child: child,
      ),
    );
  }
}

class _AccionContacto extends StatelessWidget {
  const _AccionContacto({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.surfaceHigh,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.ivory),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoCopiable extends StatelessWidget {
  const _DatoCopiable({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, right: AppSpacing.md),
            child: Icon(icon, color: AppColors.museum, size: 20),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.bodySmall),
                  const SizedBox(height: 2),
                  SelectableText(
                    value,
                    style: theme.bodyLarge?.copyWith(
                      color: AppColors.ivory,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copiar ${label.toLowerCase()}',
            onPressed: () => copiarDato(context, value, label),
            icon: const Icon(
              Icons.copy_outlined,
              color: AppColors.muted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Horarios extends StatelessWidget {
  const _Horarios({required this.contacto, required this.now});

  final ContactoDto contacto;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final hoy = contacto.horarioHoy(now);
    final diaHoy = now.weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horarios de atención', style: theme.titleMedium),
        if (hoy != null) ...[
          const SizedBox(height: AppSpacing.sm),
          HoyEstadoLine(hoy: hoy),
        ],
        const SizedBox(height: AppSpacing.md),
        if (contacto.horariosPorDia.isNotEmpty)
          ...contacto.horariosPorDia.map((day) {
            final esHoy = day.diaSemana == diaHoy;
            final horas = day.cerrado
                ? 'Cerrado'
                : day.apertura == null && day.cierre == null
                ? 'Horario no publicado'
                : '${HorarioHoy.hhmm(day.apertura) ?? day.apertura ?? '—'}'
                      ' – '
                      '${HorarioHoy.hhmm(day.cierre) ?? day.cierre ?? '—'}';
            final estiloDia = theme.bodyLarge?.copyWith(
              color: esHoy ? AppColors.ivory : AppColors.muted,
              fontWeight: esHoy ? FontWeight.w700 : FontWeight.w500,
            );
            return Container(
              key: ValueKey('guest-schedule-row-${day.diaSemana}'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: esHoy
                  ? BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: AppRadii.controlBorder,
                    )
                  : null,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dias[day.diaSemana], style: estiloDia),
                      if (esHoy) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Hoy',
                          style: theme.labelMedium?.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    horas,
                    style: AppText.cifra(
                      size: 15,
                      weight: esHoy ? FontWeight.w700 : FontWeight.w500,
                      color: day.cerrado ? AppColors.muted : AppColors.ivory,
                    ),
                  ),
                ],
              ),
            );
          })
        else if (contacto.horario.isNotEmpty)
          Text(
            contacto.horario,
            style: theme.bodyLarge?.copyWith(
              color: AppColors.ivory,
              height: 1.6,
            ),
          )
        else
          Text(
            'Horario no publicado',
            style: theme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
      ],
    );
  }
}
