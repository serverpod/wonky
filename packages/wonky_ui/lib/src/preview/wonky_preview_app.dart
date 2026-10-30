import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shad/material.dart' show ShadMaterial;
import 'package:shad/shad.dart';

import '../l10n/wonky_ui_localizations.dart';
import '../theme/wonky_theme.dart';

/// The app wrapper used by `pumpWonky` (also handy for widget previews).
class WonkyTestApp extends StatelessWidget {
  const WonkyTestApp({
    super.key,
    required this.child,
    this.brightness = Brightness.light,
    this.config = const WonkyThemeConfig(),
    this.locale = const Locale('en'),
    this.extraDelegates = const [],
    this.wrap,
  });

  final Widget child;
  final Brightness brightness;
  final WonkyThemeConfig config;
  final Locale locale;
  final List<LocalizationsDelegate<dynamic>> extraDelegates;
  final TransitionBuilder? wrap;

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      debugShowCheckedModeBanner: false,
      theme: WonkyTheme.light(config),
      darkTheme: WonkyTheme.dark(config),
      themeMode: brightness == Brightness.dark
          ? ShadThemeMode.dark
          : ShadThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: [
        WonkyUiLocalizations.delegate,
        ...extraDelegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) => ShadMaterial(child: child!),
      home: WonkyThemeScope(
        data: WonkyThemeExtension(density: config.density),
        child: wrap == null ? child : Builder(builder: (c) => wrap!(c, child)),
      ),
    );
  }
}
