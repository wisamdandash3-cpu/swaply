import 'package:flutter/material.dart';

/// يوفر للمكوّنات تحت الشجرة إمكانية تغيير لغة التطبيق (من الإعدادات مثلاً).
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.setLocale,
    required super.child,
  });

  final Future<void> Function(Locale locale) setLocale;

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found. Wrap app with LocaleScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(LocaleScope old) => setLocale != old.setLocale;
}
