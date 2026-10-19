import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';

import '../commands/sheets_commands.dart';
import '../features/history/server_change_undo.dart';
import '../features/history/sheets_version_view.dart';
import '../features/import/drive_file_import.dart';
import '../features/import/sheets_import_handler.dart';
import '../features/print/print_preview_screen.dart';
import '../features/scripts/editor/script_editor_screen.dart';
import '../features/scripts/script_menus.dart';
import '../features/settings/sheets_settings.dart';
import '../features/sheet_editor/sheet_editor_screen.dart';
import '../features/revlog/sheets_rev_log.dart' show SheetsRevLog;
import '../l10n/sheets_l10n.dart';
import '../mcp/ui_sheets_tools.dart';
import 'sheets_menus.dart';

/// Brand color of Wonky Sheets.
const sheetsBrandColor = Color(0xff16a34a);

/// Wonky Sheets' description for the shared shell (suite 03, Sheets 04).
final _versionRenderer = SheetsVersionRenderer();

class SheetsAppConfig extends WonkyAppConfig {
  const SheetsAppConfig();

  /// The full-screen version history (`/s/:uuid/history`, Sheets 10 §5).
  @override
  VersionRenderer? get versionRenderer => _versionRenderer;

  @override
  WonkyAppKind get app => WonkyAppKind.sheets;

  @override
  String get appName => 'Wonky Sheets';

  @override
  DriveItemKind get primaryKind => DriveItemKind.spreadsheet;

  @override
  Color get brandColor => sheetsBrandColor;

  @override
  Widget logo({double size = 28}) =>
      WonkyProductIcon(WonkyProduct.sheets, size: size);

  @override
  String itemPath(String uuid) => '/s/$uuid';

  /// Home/drive uploads and drops of .xlsx/.ods/.csv/.tsv (11 §2.1).
  @override
  ImportHandler? get importHandler => const SheetsImportHandler();

  /// (v2) The Sheets home lists only spreadsheets and the folders that
  /// contain them (suite 03 §3.3, 04 §12).
  @override
  HomeScope? get homeScope => const HomeScope.kind(DriveItemKind.spreadsheet);

  /// `/import?file=<fileItemUuid>`: Drive's *Open with ▸ Wonky Sheets*
  /// imports the file with the import dialog (Drive 02 §7.2, 04 §11.15).
  @override
  ImportRouteHandler? get importRoute => importDriveFileAsSpreadsheet;

  /// `/s/:uuid/print` (11 §7.1) under the editor route: the spreadsheet
  /// stays open underneath the print preview.
  @override
  List<RouteBase> editorRoutes(ShellServices services) => [
    // The script editor (09 §14.1), also a child of the editor route.
    GoRoute(
      path: 'script',
      pageBuilder: (c, st) => NoTransitionPage<void>(
        key: st.pageKey,
        child: ScriptEditorScreen(
          key: ValueKey<String>('sheets.script.${st.pathParameters['uuid']}'),
          services: services,
          itemUuid: st.pathParameters['uuid']!,
          initialFile: st.uri.queryParameters['file'],
          initialLine: int.tryParse(st.uri.queryParameters['line'] ?? ''),
        ),
      ),
    ),
    GoRoute(
      path: 'print',
      pageBuilder: (c, st) => NoTransitionPage<void>(
        key: st.pageKey,
        child: SheetsPrintPreviewScreen(
          key: ValueKey<String>('sheets.print.${st.pathParameters['uuid']}'),
          services: services,
          itemUuid: st.pathParameters['uuid']!,
          scope: st.uri.queryParameters['scope'],
          exportMode: st.uri.queryParameters['export'] == '1',
        ),
      ),
    ),
  ];

  @override
  String untitledName(BuildContext context) =>
      sheetsL10n(context).untitledSpreadsheet;

  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [
    SheetsLocalizations.delegate,
  ];

  @override
  List<Command<CommandArgs>> commands(ShellServices services) => [
    ...sheetsCommands(services),
    ...sheetsSettingsCommands(services),
  ];

  @override
  MenuRoot menus(BuildContext context, ShellMenus shell) =>
      withScriptMenus(sheetsMenus(shell, l: sheetsL10n(context)), context);

  /// Installs the Sheets data layer (sync controller and replica, suite
  /// 12 §2.5) for the signed-in user.
  @override
  Future<void> onSignedIn(ShellServices services) async {
    await super.onSignedIn(services);
    SheetsRevLog.install(services);
    // Restores (history screen, shell stack) and MCP/AI changes undo on
    // the server (Sheets 10 A-10-5).
    services.undo.registerHandler(SheetsServerChangeHandler(services));
    // The AI assistant (suite 10, Sheets 12 §6).
    ShellAssistant.install(services);
  }

  @override
  Future<void> onSigningOut(ShellServices services) async {
    ShellAssistant.uninstall(services);
    await SheetsRevLog.uninstall(services);
    await super.onSigningOut(services);
  }

  /// Sheets settings › Defaults: spreadsheet defaults and editing
  /// preferences (`/settings/app/defaults`, 04 §11.24, suite 04 §4).
  @override
  List<SettingsSectionSpec> appSettingsSections(ShellServices services) =>
      sheetsSettingsSections(services);

  /// `ui.sheets.*` MCP UI-bridge tools (Sheets 12 §5).
  @override
  Map<String, UiToolHandler> mcpUiTools(ShellServices services) =>
      UiSheetsToolHandlers.all(services);

  /// New spreadsheets are created locally in a reserved space (offline
  /// first) and registered with the drive.
  @override
  Future<UuidValue?> createItem(
    ShellServices services, {
    UuidValue? parentUuid,
    UuidValue? templateUuid,
    String? name,
  }) => SheetsRevLog.createSpreadsheet(
    services,
    parentUuid: parentUuid,
    templateUuid: templateUuid,
    name: name,
  );

  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) =>
      SheetEditorScreen(
        key: ValueKey<String>('sheets.editor.$uuid'),
        services: ShellScope.of(context),
        itemUuid: uuid,
        initialSheetId: state.uri.queryParameters['sheet'],
        initialRange: state.uri.queryParameters['range'],
        initialFilterView: state.uri.queryParameters['fv'],
      );
}
