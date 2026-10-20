import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/files.dart' show FileTypes;
import 'package:wonky_core/wonky_core.dart' show CommandArgs;

import '../commands/drive_commands.dart';
import '../commands/upload_commands.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/preview/file_preview_screen.dart';
import '../features/preview/preview_commands.dart';
import '../features/settings/drive_settings.dart';
import '../features/settings/drive_settings_keys.dart';
import '../features/storage/storage_screen.dart';
import '../features/uploads/drive_upload_handler.dart';
import '../features/uploads/upload_host.dart';
import '../features/uploads/upload_panel.dart';
import '../l10n/drive_l10n.dart';
import '../mcp/ui_drive_tools.dart';

/// Brand color of Wonky Drive (the purple of its product icon).
const driveBrandColor = Color(0xff6a5cb3);

/// Wonky Drive's description for the shared shell (suite 03, Drive 05 §1):
/// the unified drive with every kind (`HomeScope.all()`), no editor of its
/// own (`/file/:uuid` previews a file) and the Storage page.
///
/// The home is the shell's scope-aware drive (`HomeScope.all()`: every
/// kind, folder tree and drag moves, the Drive left menu `HomeNavSpec.drive`
/// with Storage, the type filter with file subtypes; D-10), the Storage
/// page and Drive settings (D-17).
class DriveAppConfig extends WonkyAppConfig {
  const DriveAppConfig();

  @override
  WonkyAppKind get app => WonkyAppKind.drive;

  @override
  String get appName => 'Wonky Drive';

  /// Drive edits nothing itself; documents, spreadsheets and presentations
  /// open in their apps.
  @override
  DriveItemKind? get primaryKind => null;

  @override
  Color get brandColor => driveBrandColor;

  @override
  Widget logo({double size = 28}) =>
      WonkyProductIcon(WonkyProduct.drive, size: size);

  @override
  String itemPath(String uuid) => '/file/$uuid';

  @override
  HomeScope? get homeScope => const HomeScope.all();

  /// The file page (Drive 02 §6).
  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) =>
      FilePreviewScreen(
        key: ValueKey<String>('drive.file.$uuid'),
        services: ShellScope.of(context),
        itemUuid: uuid,
      );

  /// The Drive commands (Drive 04 §9): previews (`drive.file.*`,
  /// `drive.preview.*`), uploads (`drive.upload.*`), the list view
  /// (`drive.view.*`), settings (`drive.prefs.set`), the Storage page
  /// (`drive.storage.show`) and the Analytics page (`drive.analytics.show`).
  @override
  List<Command<CommandArgs>> commands(ShellServices services) => [
    ...previewCommands(services),
    ...uploadCommands(services),
    ...driveCommands(services),
  ];

  /// `ui.drive.*` (Drive 04 §13).
  @override
  Map<String, UiToolHandler> mcpUiTools(ShellServices services) =>
      UiDriveToolHandlers.all(services);

  /// *Show file extensions* off hides the extension of uploaded files in
  /// lists (Drive 04 §8).
  @override
  String listItemName(ShellServices services, DriveItemView item) {
    if (item.kind != DriveItemKind.file ||
        DriveSettings.showsExtensions(services)) {
      return item.name;
    }
    final ext = FileTypes.extensionOf(item.name);
    if (ext.isEmpty || item.name.length <= ext.length + 1) return item.name;
    return item.name.substring(0, item.name.length - ext.length - 1);
  }

  /// *File upload…* and drops upload any file through the upload queue
  /// (Drive 02 §3; D-13) instead of importing it.
  @override
  ImportHandler? get importHandler => const DriveUploadHandler();

  /// Files in the item menu: *Preview*, *Open with ▸ Wonky Write/Sheets* (convertible
  /// files), *Download*; *Open* is hidden (it previews too, Drive 04 §3.7).
  @override
  ItemMenuContribution itemMenuCommands(
    BuildContext context,
    ShellServices services,
    List<DriveItemView> selection,
  ) => fileItemMenu(context, selection);

  /// The upload panel floats over every Drive screen (Drive 04 §4).
  @override
  Widget wrap(BuildContext context, ShellServices services, Widget child) =>
      UploadPanelLayer(services: services, child: child);

  /// Opens the signed-in user's upload queue (`drive_<user>.db`), which
  /// continues interrupted uploads (Drive 02 §4).
  @override
  Future<void> onSignedIn(ShellServices services) async {
    await super.onSignedIn(services);
    UploadHost.of(services).install();
  }

  @override
  Future<void> onSigningOut(ShellServices services) async {
    await UploadHost.of(services).uninstall();
    await super.onSigningOut(services);
  }

  /// `/storage[?filter=…]` (Drive 04 §7, Drive 03 §6.4) and, for admins,
  /// `/analytics[?days=…&admins=1]` (specs/19 §3).
  @override
  List<RouteBase> routes(ShellServices services) => [
    GoRoute(
      path: '/storage',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: const ValueKey<String>('drive.storagePage'),
        child: storageRoutePage(services, state.uri),
      ),
    ),
    GoRoute(
      path: '/analytics',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: const ValueKey<String>('drive.analyticsPage'),
        child: analyticsRoutePage(services, state.uri),
      ),
    ),
  ];

  /// Drive settings (`/settings/app/drive`, Drive 04 §8).
  @override
  List<SettingsSectionSpec> appSettingsSections(ShellServices services) =>
      driveSettingsSections(services);

  @override
  String untitledName(BuildContext context) => driveL10n(context).untitledFile;

  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [
    DriveLocalizations.delegate,
  ];
}
