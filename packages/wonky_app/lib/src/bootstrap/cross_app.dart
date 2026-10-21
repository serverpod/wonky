import 'dart:async';

import '../shell/bug_report.dart';
import 'app_urls.dart';
import 'navigation_io.dart'
    if (dart.library.js_interop) 'navigation_web.dart'
    as nav;

/// Cross-app navigation (suite 03 §1, §6): Drive, Write, Sheets and Slides
/// in the same window.
class CrossAppNavigator {
  const CrossAppNavigator(this.urls, {this.beforeLeave});

  final AppUrls urls;

  /// Awaited before the page is replaced (another app, a reload): lets an
  /// auth refresh in flight finish, so its rotated token is not lost
  /// (`WonkyClient.authRefreshSettled`).
  final Future<void> Function()? beforeLeave;

  /// Opens [path] (e.g. `/s/<uuid>`, `/`) in [app].
  Future<void> open(WonkyAppKind app, String path) async {
    final web = urls.urlFor(app, path);
    final p = path.startsWith('/') ? path.substring(1) : path;
    await beforeLeave?.call();
    return nav.openOtherApp('${app.urlScheme}://$p', web);
  }

  /// Opens an external URL in the system browser (after the confirm popover).
  Future<void> openExternal(String url) => nav.openExternal(url);

  /// Reloads the web page.
  void reload() => unawaited(
    (beforeLeave?.call() ?? Future.value()).then((_) {
      nav.reloadPage();
    }),
  );

  /// Goes back in the browser's history (to another app's page, e.g. Drive
  /// after *Open with* was cancelled); false when there is no previous page
  /// (a new tab) or on desktop.
  bool historyBack() => nav.historyBack();

  /// Remembers [app] as the last used app (web cookie).
  void rememberLastApp(WonkyAppKind app) => nav.rememberLastApp(app.name);

  /// The browser family and major version ("Chrome 131"), null on desktop.
  String? browserLabel() {
    final ua = nav.userAgent();
    return ua == null ? null : browserFromUserAgent(ua);
  }
}
