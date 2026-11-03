import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const appLocale = Locale('pt', 'BR');

const appSupportedLocales = [appLocale];

const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
