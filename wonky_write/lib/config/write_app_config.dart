import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../commands/screen_commands.dart';
import '../features/ai/ai_commands.dart';
import '../commands/theme_commands.dart';
import '../features/document/write_collab_commands.dart';
import '../features/history/write_version_renderer.dart';
import '../features/publish/submission_commands.dart';
import '../features/import/import_route.dart';
import '../features/import/import_service.dart';
import '../features/print/print_preview_screen.dart';
import '../features/screen/write_document_screen.dart';
import '../features/settings/write_settings.dart';
import '../features/settings/write_settings_commands.dart';
import '../features/theme_editor/theme_editor_screen.dart';
import '../features/themes/document_theme.dart';
import '../l10n/write_l10n.dart';
import '../mcp/ui_write_tools.dart';
import 'write_menus.dart';

/// Brand color of Wonky Write.
const writeBrandColor = Color(0xff2563eb);

/// Wonky Write's description for the shared shell (suite 03, Write 05).
class WriteAppConfig extends WonkyAppConfig {
  const WriteAppConfig();

  @override
  WonkyAppKind get app => WonkyAppKind.write;

  @override
  String get appName => 'Wonky Write';

  @override
  DriveItemKind get primaryKind => DriveItemKind.document;

  @override
  Color get brandColor => writeBrandColor;

  @override
  Widget logo({double size = 28}) =>
      WonkyProductIcon(WonkyProduct.write, size: size);

  @override
  String itemPath(String uuid) => '/d/$uuid';

  @override
  String untitledName(BuildContext context) =>
      writeL10n(context).untitledDocument;

  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [
    WriteLocalizations.delegate,
  ];

  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) {
    final services = ShellScope.of(context);
    return WriteDocumentScreen(
      key: ValueKey<String>('write.editor.$uuid'),
      services: services,
      itemUuid: uuid,
      themes: themeCatalogFor(services),
      heading: state.uri.queryParameters['heading'],
    );
  }

  @override
  List<RouteBase> routes(ShellServices services) => [
    GoRoute(
      path: '/themes',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: ThemeEditorRoute(
          services: services,
          themes: themeCatalogFor(services),
          docItemUuid: state.uri.queryParameters['doc'],
        ),
      ),
    ),
    GoRoute(
      path: '/themes/:themeUuid',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: ThemeEditorRoute(
          key: ValueKey<String>(
            'write.themes.${state.pathParameters['themeUuid']}',
          ),
          services: services,
          themes: themeCatalogFor(services),
          themeUuid: state.pathParameters['themeUuid'],
          docItemUuid: state.uri.queryParameters['doc'],
          element: state.uri.queryParameters['element'],
        ),
      ),
    ),
    GoRoute(
      path: '/d/:uuid/print',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: PrintPreviewScreen(
          key: ValueKey<String>('write.print.${state.pathParameters['uuid']}'),
          services: services,
          itemUuid: state.pathParameters['uuid']!,
          themes: themeCatalogFor(services),
        ),
      ),
    ),
  ];

  /// `ui.write.*` MCP UI-bridge tools (Write 09 §3).
  @override
  Map<String, UiToolHandler> mcpUiTools(ShellServices services) =>
      UiWriteToolHandlers.all(services);

  @override
  List<Command<CommandArgs>> commands(ShellServices services) => [
    ...writeCommands(services, themeCatalogFor(services)),
    ...themeCommands(services, themeCatalogFor(services)),
    ...writeCollabCommands(services),
    ...writeAiCommands(services),
    ...writeSettingsCommands(services),
    ...writeSubmissionCommands(services),
  ];

  /// Installs the AI assistant (suite 10) after sign-in.
  @override
  Future<void> onSignedIn(ShellServices services) async {
    await super.onSignedIn(services);
    ShellAssistant.install(services);
  }

  @override
  Future<void> onSigningOut(ShellServices services) async {
    ShellAssistant.uninstall(services);
    await super.onSigningOut(services);
  }

  @override
  MenuRoot menus(BuildContext context, ShellMenus shell) =>
      writeMenus(shell, l10n: writeL10n(context));

  @override
  Map<String, Widget Function(BuildContext context, VoidCallback close)>
  customMenuItems(ShellServices services) => {
    WriteMenuIds.tablePicker: (context, close) => Padding(
      padding: const EdgeInsets.all(8),
      child: WonkyTableSizePicker(
        key: const ValueKey<String>('menu.insert.tablePicker'),
        onSelected: (rows, cols) {
          close();
          services.dispatcher.invoke(
            'write.insert.table',
            args: {'rows': rows, 'cols': cols},
            source: InvocationSource.menu,
            context: context,
          );
        },
      ),
    ),
  };

  @override
  VersionRenderer? get versionRenderer => _versions;

  static final _versions = WriteVersionRenderer();

  @override
  ImportHandler? get importHandler => const WriteImportHandler();

  /// (v2) The Write home lists only documents and the folders that contain
  /// them (suite 03 §3.3, Write 05 §2).
  @override
  HomeScope? get homeScope => const HomeScope.kind(DriveItemKind.document);

  /// `/import?file=<fileItemUuid>`: Drive's *Open with ▸ Wonky Write*
  /// (Drive 02 §7.2).
  @override
  ImportRouteHandler? get importRoute => importDriveFileAsDocument;

  /// Write settings: Editor, Page & export, Document themes, Spelling
  /// (`/settings/app/:section`, Write 05 §13.3).
  @override
  List<SettingsSectionSpec> appSettingsSections(ShellServices services) =>
      writeSettingsSections(services);
}
