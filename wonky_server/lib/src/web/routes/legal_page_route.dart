import 'package:serverpod/serverpod.dart';

import '../../cache_busting.dart';

/// A legal page (specs/13 §5), the template `web/templates/<name>.html`.
/// Its `{{{@/web/…}}}` asset URLs get their content hash
/// (`og-1@<hash>.jpg`), so the link-preview image and the icon are cached
/// per version by the CDN and by the X and LinkedIn crawlers (specs/01 §2.4).
class LegalPageRoute extends WidgetRoute {
  LegalPageRoute(this.name)
    : super(
        methods: {Method.get, Method.head},
        cacheBustingConfig: cacheBustingConfig,
      );

  /// The template's name: `privacy` or `terms`.
  final String name;

  @override
  Future<WebWidget> build(Session session, Request request) async =>
      TemplateWidget(name: name);
}
