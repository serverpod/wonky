import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:whiskers/whiskers.dart';

import '../../cache_busting.dart';

/// A Flutter web app (specs/01-architecture.md §2.4): Serverpod's
/// [FlutterRoute] (the build's files, the SPA fallback, the WASM headers),
/// except that the shell, `index.html`, is a template served by
/// [AppShellRoute], so its `{{{@/web/…}}}` URLs are cache-busted like the
/// other pages'.
class FlutterAppRoute extends FlutterRoute {
  FlutterAppRoute(super.directory);

  @override
  void injectIn(RelicRouter router) {
    final shell = AppShellRoute(indexFile);
    final subRouter = Router<Handler>();
    if (enableWasmHeaders) {
      subRouter.use('/', const WasmHeadersMiddleware().call);
    }
    // App URLs (`/write/d/…`) aren't files: they get the shell.
    subRouter.use(
      '/',
      FallbackMiddleware(
        fallback: shell,
        on: (response) => response.statusCode == 404,
      ).call,
    );
    // Literal paths win over the static files' `/**`.
    for (final path in const ['/', '/index.html']) {
      subRouter.anyOf(shell.methods, path, shell.asHandler);
    }
    // No cache busting for the build's own files: it would strip `@…` from
    // asset names such as `icon@2x.png`.
    StaticRoute.directory(
      directory,
      cacheControlFactory: cacheControlFactory,
    ).injectIn(subRouter);
    router.attach('/', subRouter);
  }
}

/// An app's shell, the template [indexFile] (the build's `index.html`),
/// rendered with the suite's [cacheBustingConfig]: the link-preview image
/// `https://wonky.work{{{@/web/images/og-1.jpg}}}` becomes
/// `https://wonky.work/web/images/og-1@<hash>.jpg`, the URL `/web/` serves as
/// immutable, so the CDN and the link-preview caches of X and LinkedIn see a
/// new URL when the image changes.
///
/// The template is parsed once and again when the file changes (a new build
/// while the server runs); `WidgetRoute` answers `private, no-cache`.
class AppShellRoute extends WidgetRoute {
  AppShellRoute(this.indexFile)
    : super(
        methods: {Method.get, Method.head},
        cacheBustingConfig: cacheBustingConfig,
      );

  /// The build's `index.html`.
  final File indexFile;

  Template? _template;
  DateTime? _modified;

  @override
  Future<WebWidget> build(Session session, Request request) async {
    final modified = (await indexFile.stat()).modified;
    if (_template == null || modified != _modified) {
      _template = Template(
        await indexFile.readAsString(),
        name: indexFile.path,
        lenient: true,
      );
      _modified = modified;
    }
    return _ShellWidget(_template!);
  }
}

/// Renders the shell's template; it has no values, only `{{{@/web/…}}}`.
class _ShellWidget extends WebWidget {
  _ShellWidget(this.template);

  final Template template;

  @override
  String render({String? Function(String)? onMissingVariable}) =>
      template.renderString(
        const {},
        onMissingVariable: (name, context) => onMissingVariable?.call(name),
      );
}
