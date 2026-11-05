import 'package:flutter/widgets.dart';
import 'package:shared/shared.dart';

/// Grupo cujo fundo de marca está atrás do conteúdo.
class BrandScope extends InheritedWidget {
  const BrandScope({super.key, required this.unit, required super.child});

  final BusinessUnit? unit;

  static BusinessUnit? unitOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BrandScope>()?.unit;
  }

  @override
  bool updateShouldNotify(BrandScope oldWidget) => unit != oldWidget.unit;
}
