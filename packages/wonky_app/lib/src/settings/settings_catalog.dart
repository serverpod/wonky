import '../bootstrap/app_urls.dart';
import '../shell/shell_services.dart';

/// The two groups of the settings screen (suite 04 §4): the current app's
/// own settings (`/settings/app[/:section]`) and the suite-level Wonky Work
/// settings (`/settings/:section`).
enum SettingsArea {
  /// *App settings* (e.g. *Write settings*): `WonkyAppConfig.appSettingsSections`.
  app,

  /// *Wonky Work settings*: account, device and suite sections.
  work,
}

/// The ids of the Wonky Work settings sections, in nav order (suite 04
/// §4.1). `ai-providers` keeps its v1 id (`shell.settings.open {section:
/// ai-providers}`).
const workSettingsSectionIds = <String>[
  'account',
  'security',
  'appearance',
  'language',
  'keyboard',
  'notifications',
  'storage',
  'offline',
  'ai',
  'ai-providers',
  'developer',
  'publications',
  'about',
];

/// Where a v1 section id of an app's settings lives now (suite 04 §4.1
/// "Compatibility"): Write's `write` → `/settings/app/editor`, `themes` →
/// `/settings/app/themes` (both in Write); Sheets' `sheets` →
/// `/settings/app/defaults` (in Sheets). Null for every other id.
({WonkyAppKind app, String section})? legacySettingsTarget(String id) =>
    switch (id) {
      'write' => (app: WonkyAppKind.write, section: 'editor'),
      'themes' => (app: WonkyAppKind.write, section: 'themes'),
      'sheets' => (app: WonkyAppKind.sheets, section: 'defaults'),
      _ => null,
    };

/// The route of [id] in [area]: `/settings/app/<id>` or `/settings/<id>`.
String settingsPath(SettingsArea area, String id) =>
    area == SettingsArea.app ? '/settings/app/$id' : '/settings/$id';

/// Whether [location] is a settings route.
bool isSettingsLocation(String location) =>
    location == '/settings' || location.startsWith('/settings/');

/// Back from settings (suite 04 §4.2): the last visited route that is not a
/// settings page (the editor or home the user came from), else home.
String settingsBackTarget(ShellServices s) {
  final h = s.navHistory;
  for (var i = s.navIndex; i >= 0 && i < h.length; i--) {
    if (!isSettingsLocation(h[i])) return h[i];
  }
  return '/';
}
