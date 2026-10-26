import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import 'auth_widgets.dart';
import 'login_views.dart';

/// Alta de cliente con `POST /register/` (mismos campos que la web).
class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _paterno = TextEditingController();
  final _materno = TextEditingController();
  final _telefono = TextEditingController();
  final _usuario = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  final _respuesta = TextEditingController();
  String? _pregunta;
  bool _acepta = false;
  bool _oculta = true;

  @override
  void initState() {
    super.initState();
    _contrasena.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _paterno,
      _materno,
      _telefono,
      _usuario,
      _correo,
      _contrasena,
      _confirmacion,
      _respuesta,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.registrar(
      RegistroRequest(
        nombre: _nombre.text,
        apellidoPaterno: _paterno.text,
        apellidoMaterno: _materno.text,
        username: _usuario.text,
        correo: _correo.text,
        telefono: _telefono.text,
        contrasena: _contrasena.text,
        preguntaSecreta: _pregunta!,
        respuestaSecreta: _respuesta.text,
        aceptaTerminos: _acepta,
      ),
    );
    if (!mounted || !ok) return;
    Navigator.pushNamed(context, AppRoutes.registroVerificar);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final theme = Theme.of(context).textTheme;
    return AuthScaffold(
      leading: IconButton(
        tooltip: 'Volver',
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ivory),
        onPressed: auth.busy ? null : () => Navigator.maybePop(context),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: 'Crea tu cuenta',
                subtitle: 'Para reservar citas y seguir tus pedidos.',
              ),
              if (auth.hayRegistroPendiente) ...[
                const SizedBox(height: AppSpacing.lg),
                StatusBanner(
                  tone: BannerTone.info,
                  message:
                      'Ya enviamos un código a ${auth.registroDestino ?? 'tu correo'}.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('registro_ir_codigo'),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.registroVerificar,
                    ),
                    child: const Text('Escribir el código'),
                  ),
                ),
              ],
              const _Seccion('Tus datos'),
              TextFormField(
                key: const Key('registro_nombre'),
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(labelText: 'Nombre(s)'),
                validator: validarNombre,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_paterno'),
                controller: _paterno,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                decoration: const InputDecoration(
                  labelText: 'Apellido paterno',
                ),
                validator: validarNombre,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_materno'),
                controller: _materno,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Apellido materno',
                ),
                validator: validarNombre,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_telefono'),
                controller: _telefono,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  helperText: '10 dígitos, sin espacios',
                ),
                validator: validarTelefonoObligatorio,
              ),
              const _Seccion('Acceso'),
              TextFormField(
                key: const Key('registro_usuario'),
                controller: _usuario,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: validarUsuario,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_correo'),
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  helperText: 'Te enviaremos un código para confirmarlo',
                ),
                validator: validarCorreo,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_contrasena'),
                controller: _contrasena,
                obscureText: _oculta,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _oculta
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () => setState(() => _oculta = !_oculta),
                    icon: Icon(
                      _oculta
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: validarContrasenaNueva,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Requisitos(valor: _contrasena.text),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_confirmacion'),
                controller: _confirmacion,
                obscureText: _oculta,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Confirma la contraseña',
                ),
                validator: (v) => validarConfirmacion(v, _contrasena.text),
              ),
              const _Seccion('Recuperación de cuenta'),
              DropdownButtonFormField<String>(
                key: const Key('registro_pregunta'),
                initialValue: _pregunta,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pregunta secreta',
                ),
                items: [
                  for (final p in RegistroRequest.preguntas)
                    DropdownMenuItem(
                      value: p,
                      child: Text(p, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _pregunta = v),
                validator: (v) => v == null ? 'Elige una pregunta' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('registro_respuesta'),
                controller: _respuesta,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Respuesta'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              FormField<bool>(
                initialValue: _acepta,
                validator: (_) =>
                    _acepta ? null : 'Necesitas aceptar para crear la cuenta',
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      key: const Key('registro_acepta'),
                      value: _acepta,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) {
                        setState(() => _acepta = v ?? false);
                        field.didChange(_acepta);
                      },
                      title: Text(
                        'Acepto el aviso de privacidad y los términos de uso.',
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xxl),
                      child: TextButton(
                        key: const Key('registro_leer_aviso'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.avisoPrivacidad,
                        ),
                        child: const Text('Leer el aviso de privacidad'),
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Text(
                          field.errorText!,
                          style: theme.bodySmall?.copyWith(
                            color: AppColors.crit,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (auth.errorMessage != null)
                AuthError(message: auth.errorMessage!),
              AuthPrimaryButton(
                key: const Key('registro_crear'),
                label: 'Crear cuenta',
                busy: auth.busy,
                onPressed: _crear,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('¿Ya tienes cuenta?', style: theme.bodyMedium),
                  TextButton(
                    onPressed: auth.busy
                        ? null
                        : () {
                            auth.limpiarError();
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                    child: const Text('Inicia sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxxl,
        bottom: AppSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// Requisitos de la contraseña; cada uno se marca al cumplirse.
class _Requisitos extends StatelessWidget {
  const _Requisitos({required this.valor});

  final String valor;

  @override
  Widget build(BuildContext context) {
    final duracion = AppMotion.of(context, AppMotion.quick);
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        for (final r in requisitosContrasena(valor))
          Semantics(
            label: '${r.regla}: ${r.cumple ? 'cumplido' : 'pendiente'}',
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: duracion,
                    switchInCurve: AppMotion.ease,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.6, end: 1.0).animate(a),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      r.cumple
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      key: ValueKey(r.cumple),
                      size: 16,
                      color: r.cumple ? AppColors.ok : AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: duracion,
                      style: (style ?? const TextStyle()).copyWith(
                        color: r.cumple ? AppColors.text : AppColors.muted,
                      ),
                      child: Text(r.regla),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Confirma el correo del alta con el código y abre la sesión.
class VerificarRegistroView extends StatefulWidget {
  const VerificarRegistroView({super.key});

  @override
  State<VerificarRegistroView> createState() => _VerificarRegistroViewState();
}

class _VerificarRegistroViewState extends State<VerificarRegistroView> {
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final auth = context.read<AuthViewModel>();
    final ok = await auth.verificarRegistro(_codigo.text);
    if (!mounted || !ok) return;
    goHomeByRole(context, auth.role);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final destino = auth.registroDestino;
    return AuthScaffold(
      leading: IconButton(
        tooltip: 'Volver al registro',
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ivory),
        onPressed: auth.busy ? null : () => Navigator.maybePop(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrand(compact: true),
          const SizedBox(height: AppSpacing.xxl),
          AuthHeading(
            title: 'Confirma tu correo',
            subtitle:
                auth.registroMensaje ??
                'Escribe el código que te enviamos por correo.',
          ),
          if (destino != null && destino.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enviado a ${maskDestino(destino)}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.museum),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (!auth.hayRegistroPendiente)
            const StatusBanner(
              tone: BannerTone.aviso,
              message: 'No hay un registro pendiente. Crea tu cuenta primero.',
            ),
          if (auth.errorMessage != null) AuthError(message: auth.errorMessage!),
          CodigoField(
            controller: _codigo,
            onSubmitted: (_) => auth.busy ? null : _confirmar(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthPrimaryButton(
            key: const Key('registro_verificar'),
            label: 'Confirmar y entrar',
            busy: auth.busy,
            onPressed: _confirmar,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: const Key('registro_reenviar'),
            onPressed: auth.busy || !auth.hayRegistroPendiente
                ? null
                : () => auth.reenviarCodigoRegistro(),
            child: const Text('Reenviar código'),
          ),
        ],
      ),
    );
  }
}
