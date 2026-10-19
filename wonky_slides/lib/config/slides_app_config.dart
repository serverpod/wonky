import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';

import '../commands/commands.dart';
import '../features/editor_screen/deck_editor_screen.dart';
import '../features/editor_screen/route_placeholders.dart';
import '../features/history/slides_version_renderer.dart';
import '../features/present/present_controller.dart' show PresentView;
import '../features/present/present_screen.dart';
import '../features/print/print_preview_screen.dart';
import 'package:wonky_slides_core/interfaces.dart' show SlidesPdfLayout;
import 'package:wonky_slides_core/templates.dart' show SlidesTemplates;
import '../features/settings/slides_settings.dart';
import '../features/templates/template_preview.dart';
import '../features/undo/server_change_undo.dart';
import '../features/revlog/slides_rev_log.dart' show SlidesRevLog;
import '../l10n/slides_l10n.dart';
import '../mcp/ui_slides_tools.dart';
import 'menus/slides_menu_spec.dart';
import 'slides_features.dart';

/// Brand color of Wonky Slides (the amber of its product icon and of the
/// presentation kind, `kindColor`).
const slidesBrandColor = Color(0xffd97706);

final _versionRenderer = SlidesVersionRenderer();

/// Wonky Slides' description for the shared shell (suite 03, Slides 01 §7,
/// Slides 12 SL-1).
///
/// The home is the shell's app home scoped to presentations
/// (`HomeScope.kind(presentation)`: Recent, My files, Shared, Starred,
/// Offline, Trash; only folders that contain a presentation; Slides 04
/// §15). The deck editor at `/p/:uuid` is the `DeckEditorScreen` (04 §2,
/// SL-11) with the child routes `present`, `print` and `history`; the
/// commands, menus and Slides settings are registered here.
/// Presentations are created offline-first in reserved deck spaces by the
/// data layer installed at sign-in ([SlidesData], SL-9).
class SlidesAppConfig extends WonkyAppConfig {
  const SlidesAppConfig();

  @override
  WonkyAppKind get app => WonkyAppKind.slides;

  @override
  String get appName => 'Wonky Slides';

  @override
  DriveItemKind get primaryKind => DriveItemKind.presentation;

  @override
  Color get brandColor => slidesBrandColor;

  @override
  Widget logo({double size = 28}) =>
      WonkyProductIcon(WonkyProduct.slides, size: size);

  @override
  String itemPath(String uuid) => '/p/$uuid';

  /// Version history (Slides 09 §4; SL-39): the shell's `/p/:uuid/history`
  /// route renders versions with [SlidesVersionRenderer] (none while the
  /// feature is off).
  @override
  VersionRenderer? get versionRenderer =>
      SlidesFeatures.isOn(SlidesFeature.versionHistory)
      ? _versionRenderer
      : null;

  @override
  HomeScope? get homeScope => const HomeScope.kind(DriveItemKind.presentation);

  /// The deck editor (Slides 04 §2); `?slide=<slideId>` opens that slide,
  /// `?comment=<threadUuid>` that comment (09 §3.4).
  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) =>
      DeckEditorScreen(
        key: ValueKey<String>('slides.deck.$uuid'),
        services: ShellScope.of(context),
        itemUuid: uuid,
        initialSlideId: state.uri.queryParameters['slide'],
        initialCommentId: state.uri.queryParameters['comment'],
      );

  /// `/p/:uuid/present` and `/p/:uuid/print` (04 §1) under the editor
  /// route, so the deck session stays open underneath (SL-19, SL-20).
  /// `/p/:uuid/history` is the shell's version history route with
  /// [versionRenderer] (SL-39).
  @override
  List<RouteBase> editorRoutes(ShellServices services) => [
    for (final route in DeckChildRoute.values)
      if (route != DeckChildRoute.history)
        GoRoute(
          path: route.name,
          pageBuilder: (c, st) => NoTransitionPage<void>(
            key: st.pageKey,
            child: route == DeckChildRoute.present
                ? _presentScreen(services, st)
                : route == DeckChildRoute.print
                ? PrintPreviewScreen(
                    key: ValueKey<String>(
                      'slides.print.${st.pathParameters['uuid']}',
                    ),
                    services: services,
                    itemUuid: st.pathParameters['uuid']!,
                    initialLayout: SlidesPdfLayout.values
                        .where(
                          (v) => v.name == st.uri.queryParameters['layout'],
                        )
                        .firstOrNull,
                  )
                : DeckRoutePlaceholder(
                    key: ValueKey<String>(
                      'slides.${route.name}.${st.pathParameters['uuid']}',
                    ),
                    services: services,
                    itemUuid: st.pathParameters['uuid']!,
                    route: route,
                  ),
          ),
        ),
  ];

  /// The present route (Slides 10 §1.1; SL-19): `?view=presenter|audience`,
  /// `slide`, `step`, `session`, `share=1`, `kiosk=1` (10 §9, SL-29).
  static Widget _presentScreen(ShellServices services, GoRouterState st) {
    final q = st.uri.queryParameters;
    final uuid = st.pathParameters['uuid']!;
    final view = PresentView.fromName(q['view']);
    return PresentScreen(
      key: ValueKey<String>(
        'slides.present.$uuid.${view.name}.${q['session'] ?? ''}',
      ),
      services: services,
      itemUuid: uuid,
      view: view,
      startSlideId: q['slide'],
      startStep: int.tryParse(q['step'] ?? '') ?? 0,
      sessionId: q['session'],
      share: q['share'] == '1',
      kiosk: q['kiosk'] == '1',
    );
  }

  /// Every `slides.*` command (`commands/commands.dart`).
  @override
  List<Command<CommandArgs>> commands(ShellServices services) =>
      slidesCommands(services);

  /// Shell commands of features Slides doesn't ship yet stay out
  /// ([SlidesFeatures], SL-23; comments ship since SL-38, version history
  /// since SL-39).
  @override
  bool hidesShellCommand(String id) => SlidesFeatures.hidesShellCommand(id);

  /// The Slides menubar (04 §4).
  @override
  MenuRoot menus(BuildContext context, ShellMenus shell) =>
      slidesMenus(shell, l: slidesL10n(context));

  /// Slides settings (04 §13.16): `/settings/app/<section>`.
  @override
  List<SettingsSectionSpec> appSettingsSections(ShellServices services) =>
      slidesSettingsSections(services);

  /// The `ui.slides.*` MCP UI-bridge tools (Slides 11 §5; SL-42), next to
  /// the shared `ui.*` tools (menu tree, commands, dialogs, state with the
  /// editor's `describeState`).
  @override
  Map<String, UiToolHandler> mcpUiTools(ShellServices services) =>
      UiSlidesToolHandlers.all(services);

  /// The Slides data layer follows the signed-in user (RevLog spec 08 §2):
  /// the cache `slides_cache_<userId>.db` and its RevLog client.
  @override
  Future<void> onSignedIn(ShellServices services) async {
    await super.onSignedIn(services);
    SlidesRevLog.install(services);
    // Server-side changes (AI runs, restores from the history route on
    // the shell stack) undo through the server (02 §12.2).
    services.undo.registerHandler(SlidesServerChangeHandler(services));
    // The AI assistant (suite 10, Slides 11 §6; SL-43).
    if (SlidesFeatures.isOn(SlidesFeature.assistant)) {
      ShellAssistant.install(services);
    }
  }

  @override
  Future<void> onSigningOut(ShellServices services) async {
    ShellAssistant.uninstall(services);
    await SlidesRevLog.uninstall(services);
    await super.onSigningOut(services);
  }

  /// *New presentation*, the home's *+ New* and `/new` (Drive's *New*
  /// menu): offline-first creation as the deck's first op plus the queued
  /// `drive.registerPresentation` (Slides 02 §9.3, RevLog spec 08 §2;
  /// published templates create on the server).
  @override
  Future<UuidValue?> createItem(
    ShellServices services, {
    UuidValue? parentUuid,
    UuidValue? templateUuid,
    String? name,
  }) => SlidesRevLog.createPresentation(
    services,
    parentUuid: parentUuid,
    templateUuid: templateUuid,
    name: name,
  );

  /// Built-in templates show their first slide (Slides 04 §15, SL-22);
  /// other templates keep the shell's miniature.
  @override
  Widget? templatePreview(
    BuildContext context,
    TemplateView template, {
    required double width,
    required double height,
  }) {
    final t = template.builtin
        ? SlidesTemplates.byUuid(template.uuid.uuid)
        : null;
    return t == null ? null : SlidesTemplatePreview(template: t, width: width);
  }

  @override
  String untitledName(BuildContext context) =>
      slidesL10n(context).untitledPresentation;

  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [
    SlidesLocalizations.delegate,
  ];
}
