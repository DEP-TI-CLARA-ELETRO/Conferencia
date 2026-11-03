import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Idioma padrão do app: português do Brasil.
const appLocale = Locale('pt', 'BR');

/// Lista de idiomas que o app "entende" (hoje só pt-BR).
const appSupportedLocales = [appLocale];

/// Delegates = pedaços oficiais do Flutter que traduzem widgets do sistema
/// (DatePicker, botões de diálogo, etc.) para o idioma escolhido.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
