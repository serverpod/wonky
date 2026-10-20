import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../bootstrap/app_urls.dart';
import '../commands/command.dart';
import '../mcp_bridge/ui_tool.dart';
import '../menus/shell_menus.dart';
import '../publications/start_story.dart';
import '../shell/shell_services.dart';
import '../versions/version_renderer.dart';
import 'home_scope.dart';

/// A file an app can import (drag-and-drop or "Upload file…").
class ImportFile {
  const ImportFile({
    required this.name,
    required this.bytes,
    this.mimeType,
    this.lastModified,
    this.folderPath = const [],
  });

  final String name;
  final List<int> bytes;
  final String? mimeType;

  /// The file's modification time, when the platform reports it.
  final DateTime? lastModified;

  /// The folders between the drop target and the file when a folder was
  /// dropped (`['Holiday', 'Day 1']`); empty for single files (Drive 02
  /// §3.1 folder uploads).
  final List<String> folderPath;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

/// App hook for uploads/imports from the drive (suite 05 §3.1).
abstract class ImportHandler {
  /// Lower-case extensions this app imports (`md`, `docx`, `xlsx`, …).
  Set<String> get extensions;

  /// Shows the platform file picker; returns the picked files (empty when
  /// cancelled).
  Future<List<ImportFile>> pickFiles(BuildContext context);

  /// Imports [files] into [parentUuid]; shows options dialogs as needed and
  /// returns the created items.
  Future<List<DriveItemView>> importFiles(
    BuildContext context,
    ShellServices services,
    List<ImportFile> files, {
    UuidValue? parentUuid,
  });
}

/// A command the app adds to the drive item menu (⋮ / context menu) for
/// the current selection (`WonkyAppConfig.itemMenuCommands`).
class ItemMenuCommand {
  const ItemMenuCommand(this.id, {this.args = const {}, this.label});

  final String id;
  final Map<String, Object?> args;

  /// Overrides the command title ("Open with Wonky Sheets").
  final String? label;
}

/// The app's part of the drive item menu: [commands] after *Open*, and the
/// shell entries to [hide] (Drive hides *Open* for files: *Preview* opens
/// them).
class ItemMenuContribution {
  const ItemMenuContribution({this.commands = const [], this.hide = const {}});

  static const none = ItemMenuContribution();

  final List<ItemMenuCommand> commands;
  final Set<String> hide;
}

/// A side panel the app contributes to the editor's panel host.
typedef PanelBuilder =
    SidePanelSpec Function(BuildContext context, ShellServices services);

/// Describes one app to the shared shell (suite 03): `WonkyShell(config:
/// WriteAppConfig())`.
abstract class WonkyAppConfig {
  const WonkyAppConfig();

  /// Which app this is.
  WonkyAppKind get app;

  /// "Wonky Write" / "Wonky Sheets" (product name, not localized).
  String get appName => app.productName;

  /// "Write" / "Sheets": the name next to the logo on the drive home.
  String get shortAppName => appName.replaceFirst(RegExp(r'^Wonky '), '');

  /// The kind of file this app edits; null for Wonky Drive (no editor of
  /// its own — `buildEditor` shows the file preview).
  DriveItemKind? get primaryKind;

  /// Brand color (logo tile, accents).
  Color get brandColor;

  /// The app logo (title row, top bar, auth screens).
  Widget logo({double size = 28});

  /// Path of the editor route for [uuid] (`/d/<uuid>`, `/s/<uuid>`,
  /// `/p/<uuid>`; Drive: `/file/<uuid>`).
  String itemPath(String uuid);

  /// Builds the editor screen for `itemPath` routes. The screen should use
  /// `EditorScaffold`, which makes its controller the active document.
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid);

  /// Extra app routes (`/d/:uuid/history`, `/themes`, `/s/:uuid/script` …),
  /// relative to the app's base href.
  List<RouteBase> routes(ShellServices services) => const [];

  /// Routes nested under the editor route (`print` → `/s/:uuid/print`):
  /// the editor page stays mounted underneath, so its open document (and
  /// in-memory model) remains available to the child screen.
  List<RouteBase> editorRoutes(ShellServices services) => const [];

  /// App commands (registered at start-up; shell ids are reserved).
  List<Command<CommandArgs>> commands(ShellServices services) => const [];

  /// The app's menubar: extend [shell]'s shared menus (File, Edit, View,
  /// Tools, Help) with app menus and items.
  MenuRoot menus(BuildContext context, ShellMenus shell) => shell.root;

  /// Builders for `MenuSpec.custom` items, by id.
  Map<String, Widget Function(BuildContext context, VoidCallback close)>
  customMenuItems(ShellServices services) => const {};

  /// App side panels (Outline, Named ranges, …). Shell panels (comments,
  /// history, details) are added by the shell.
  List<PanelBuilder> panels() => const [];

  /// Localization delegates of the app.
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [];

  /// Renders versions in the full-screen history route.
  VersionRenderer? get versionRenderer => null;

  /// Upload/import support on the home screen.
  ImportHandler? get importHandler => null;

  /// App entries of the drive item menu for [selection] (Drive: *Preview*,
  /// *Open with*, *Download* for files, Drive 04 §3.7).
  ItemMenuContribution itemMenuCommands(
    BuildContext context,
    ShellServices services,
    List<DriveItemView> selection,
  ) => ItemMenuContribution.none;

  /// (v2) The name of [item] as list rows and grid cards show it (Drive's
  /// *Show file extensions* setting hides the extension of uploaded files,
  /// Drive 04 §8); dialogs and titles always show the full name.
  String listItemName(ShellServices services, DriveItemView item) => item.name;

  /// Creates a new item of the primary kind (Sheets creates the spreadsheet
  /// locally in a reserved space, offline-first). Returns its uuid. The
  /// default calls `drive.createDocument` / `drive.createSpreadsheet`;
  /// apps without a primary kind (Drive) create nothing.
  Future<UuidValue?> createItem(
    ShellServices services, {
    UuidValue? parentUuid,
    UuidValue? templateUuid,
    String? name,
  }) async {
    final kind = primaryKind;
    if (kind == null) return null;
    return services.createItemOnServer(
      kind,
      parentUuid: parentUuid,
      templateUuid: templateUuid,
      name: name,
    );
  }

  /// (v2) The picture of a template card (suite 05 §3.1), or null for the
  /// shell's miniature drawn from `TemplateView.previewStyle`/`previewText`.
  /// Wonky Slides renders the first slide of its built-in templates
  /// (Slides 04 §15). [width] × [height] is the card's preview area.
  Widget? templatePreview(
    BuildContext context,
    TemplateView template, {
    required double width,
    required double height,
  }) => null;

  // ------------------------------------------------------------------ v2

  /// What the home lists and offers (suite 03 §3.3): `HomeScope.all()` for
  /// Wonky Drive, `HomeScope.kind(primaryKind)` for app homes. Null keeps
  /// the v1 home (all kinds behind the type filter, every folder, tree)
  /// until the app opts in (D-16 for Write and Sheets).
  HomeScope? get homeScope => null;

  /// The navigation of the home's left menu (`HomeSidebar`, suite 03 §3.3):
  /// Drive's list for `HomeScope.all()`, the app-home list for
  /// `HomeScope.kind`, and the v1 list (with the folder tree) while
  /// [homeScope] is null.
  HomeNavSpec get homeNav => switch (homeScope) {
    null => HomeNavSpec.legacy,
    final s when s.isAll => HomeNavSpec.drive,
    _ => HomeNavSpec.appHome,
  };

  /// The app's own settings (the *App settings* (e.g. *Write settings*) group of the settings
  /// screen, suite 04 §4.2), hosted at `/settings/app/:section`;
  /// `/settings/app` opens the first. Write: Editor, Page & export,
  /// Document themes, Spelling; Sheets: Defaults; Drive: Drive. Empty =
  /// the app has no settings of its own (`/settings/app` shows Wonky Work
  /// settings).
  List<SettingsSectionSpec> appSettingsSections(ShellServices services) =>
      const [];

  /// Handles `/new?folder=&template=` (suite 03 §2): Drive's *New* menu and
  /// *From template* navigate there. The default creates the item with
  /// [createItem]; null (Drive) = the app has no `/new` route.
  NewItemRouteHandler? get newItemRoute => primaryKind == null
      ? null
      : (context, services, request) =>
            // A contributor link starts a story (Write, specs/18 §3).
            request.publicationId != null &&
                primaryKind == DriveItemKind.document &&
                services.repositories.hasPublications
            ? startPublicationStory(
                context,
                services,
                request.publicationId!,
                ref: request.ref,
              )
            : createItem(
                services,
                parentUuid: request.folderUuid,
                templateUuid: request.templateUuid,
                name: request.name,
              );

  /// Handles `/import?file=<fileItemUuid>` (*Open with*, Drive 02 §7.2);
  /// null = the app has no import route (Drive, Slides). Write and Sheets
  /// provide it in D-16.
  ImportRouteHandler? get importRoute => null;

  /// Default name of new items ("Untitled document").
  String untitledName(BuildContext context);

  /// Wraps the app (extra providers). Called inside the shell providers.
  Widget wrap(BuildContext context, ShellServices services, Widget child) =>
      child;

  /// Called after sign-in (start sync, …) and before sign-out (stop sync).
  Future<void> onSignedIn(ShellServices services) async {}
  Future<void> onSigningOut(ShellServices services) async {}

  /// App-specific MCP UI-bridge tools (`ui.write.*`, suite 09 §6.2), by
  /// tool name; the shared `ui.*` tools are built in.
  Map<String, UiToolHandler> mcpUiTools(ShellServices services) => const {};

  /// (v2) Whether the shell command [id] is left out of this app's
  /// registry (not offered anywhere: menus, palette, shortcuts, MCP), for
  /// shell features the app doesn't support yet (Slides: comments,
  /// version history and the assistant until M11).
  bool hidesShellCommand(String id) => false;
}

/// A section of the app's settings ([WonkyAppConfig.appSettingsSections]):
/// [id] is the last route segment (`/settings/app/<id>`).
class SettingsSectionSpec {
  const SettingsSectionSpec({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String Function(BuildContext context) title;
  final IconData icon;
  final WidgetBuilder builder;
}
