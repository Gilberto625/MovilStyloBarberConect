import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Idioma de la app: español de México. Sin esto, los componentes de
/// Material (calendario, Cancelar/Aceptar, lectores de pantalla) salen en
/// inglés.
class AppLocale {
  AppLocale._();

  static const locale = Locale('es', 'MX');
  static const supported = [Locale('es', 'MX'), Locale('es')];
  static const delegates = GlobalMaterialLocalizations.delegates;
}
