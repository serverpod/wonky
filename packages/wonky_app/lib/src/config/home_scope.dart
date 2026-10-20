import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';

import '../shell/shell_services.dart';

/// What an app's home (the shell's drive UI) lists and offers (suite 03
/// §3.3, suite 05 §3.0): Wonky Drive shows every kind ([HomeScope.all]),
/// the app homes only their own kind ([HomeScope.kind]).
///
/// `WonkyAppConfig.homeScope` returns null until an app opts in (D-16 for
/// Write and Sheets): the shell then keeps the v1 home (type filter, every
/// folder, tree).
@immutable
class HomeScope {
  /// Wonky Drive: all kinds, folder management, file uploads.
  const HomeScope.all() : kind = null;

  /// An app home (Write, Sheets, Slides): only [kind] and the folders that
  /// contain it (`DriveItem.kindMask`, suite 05 §3.2).
  const HomeScope.kind(DriveItemKind this.kind)
    : assert(
        kind != DriveItemKind.folder && kind != DriveItemKind.file,
        'App homes list documents, spreadsheets or presentations.',
      );

  /// The listed kind; null = every kind ([HomeScope.all]).
  final DriveItemKind? kind;

  /// Wonky Drive's scope.
  bool get isAll => kind == null;

  /// `DriveListFilter.kinds` / `DriveSearchFilters.kinds` of the home's
  /// lists: null (all) for Drive, `[kind, folder]` in folder views of app
  /// homes (folders are narrowed by [foldersContaining]).
  List<DriveItemKind>? get listKinds =>
      isAll ? null : [kind!, DriveItemKind.folder];

  /// Kinds of search results (folders are not searched in app homes).
  List<DriveItemKind>? get searchKinds => isAll ? null : [kind!];

  /// `DriveListFilter.foldersContaining`: app homes list only folders whose
  /// `kindMask` has their kind.
  DriveItemKind? get foldersContaining => kind;

  /// The kinds *+ New* creates: Drive offers every editor kind (and folders,
  /// uploads and templates through its own items), app homes their kind.
  List<DriveItemKind> get newKinds => isAll
      ? const [
          DriveItemKind.document,
          DriveItemKind.spreadsheet,
          DriveItemKind.presentation,
        ]
      : [kind!];

  /// Folder tree, drag-and-drop moves and *New folder* (Drive only; app
  /// homes show *Open in Wonky Drive*).
  bool get managesFolders => isAll;

  /// Arbitrary file uploads (Drive); app homes import their convertible
  /// types (*Import file…*).
  bool get uploadsFiles => isAll;

  /// The *Type* filter chip (Drive only).
  bool get showsTypeFilter => isAll;

  /// The template strip above Recent (app homes only).
  bool get showsTemplateStrip => !isAll;

  /// Whether items of [k] are listed in this home.
  bool lists(DriveItemKind k) =>
      isAll || k == kind || k == DriveItemKind.folder;

  @override
  bool operator ==(Object other) => other is HomeScope && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() =>
      isAll ? 'HomeScope.all' : 'HomeScope.kind(${kind!.name})';
}

/// The destinations of a home's left menu (suite 03 §3.3, Drive 04 §2).
/// Labels and icons come from the shell (`HomeSidebar`, D-10).
enum HomeNavDestination {
  /// Drive: Home (`/`).
  home,

  /// App homes: Recent (`/`); Drive: Recent (`/recent`).
  recent,

  /// App homes: My files (`/my-files`); Drive: My Drive (`/my-drive`, with
  /// the folder tree).
  myFiles,
  shared,
  starred,

  /// App homes only: on-device availability.
  offline,
  trash,

  /// Drive only: the Storage page (`/storage`).
  storage,
}

/// One entry of the left menu's navigation.
@immutable
class HomeNavItem {
  const HomeNavItem(this.destination, this.route);

  final HomeNavDestination destination;

  /// The route relative to the app's base href, e.g. `/my-files`.
  final String route;

  @override
  bool operator ==(Object other) =>
      other is HomeNavItem &&
      other.destination == destination &&
      other.route == route;

  @override
  int get hashCode => Object.hash(destination, route);
}

/// The navigation section of an app's left menu (`WonkyAppConfig.homeNav`,
/// suite 03 §3.3): the app section above and the bottom section (settings,
/// *Report a bug*, storage meter) are the same in every app.
@immutable
class HomeNavSpec {
  const HomeNavSpec({required this.items, this.folderTree = false});

  /// App homes: Recent (`/`), My files, Shared with me, Starred, Offline,
  /// Trash — no folder tree.
  static const appHome = HomeNavSpec(
    items: [
      HomeNavItem(HomeNavDestination.recent, '/'),
      HomeNavItem(HomeNavDestination.myFiles, '/my-files'),
      HomeNavItem(HomeNavDestination.shared, '/shared'),
      HomeNavItem(HomeNavDestination.starred, '/starred'),
      HomeNavItem(HomeNavDestination.offline, '/offline'),
      HomeNavItem(HomeNavDestination.trash, '/trash'),
    ],
  );

  /// Wonky Drive: Home, My Drive (+ folder tree), Shared with me, Recent,
  /// Starred, Trash, Storage.
  static const drive = HomeNavSpec(
    items: [
      HomeNavItem(HomeNavDestination.home, '/'),
      HomeNavItem(HomeNavDestination.myFiles, '/my-drive'),
      HomeNavItem(HomeNavDestination.shared, '/shared'),
      HomeNavItem(HomeNavDestination.recent, '/recent'),
      HomeNavItem(HomeNavDestination.starred, '/starred'),
      HomeNavItem(HomeNavDestination.trash, '/trash'),
      HomeNavItem(HomeNavDestination.storage, '/storage'),
    ],
    folderTree: true,
  );

  final List<HomeNavItem> items;

  /// The v1 home (`homeScope` null, until D-16 flips Write and Sheets):
  /// Home, My Drive (+ folder tree), Shared with me, Recent, Starred,
  /// Offline, Trash — the list of the v1 sidebar.
  static const legacy = HomeNavSpec(
    items: [
      HomeNavItem(HomeNavDestination.home, '/'),
      HomeNavItem(HomeNavDestination.myFiles, '/my-drive'),
      HomeNavItem(HomeNavDestination.shared, '/shared'),
      HomeNavItem(HomeNavDestination.recent, '/recent'),
      HomeNavItem(HomeNavDestination.starred, '/starred'),
      HomeNavItem(HomeNavDestination.offline, '/offline'),
      HomeNavItem(HomeNavDestination.trash, '/trash'),
    ],
    folderTree: true,
  );

  /// Whether *My Drive* expands to the lazy folder tree (Drive only).
  final bool folderTree;

  /// The route of the user's drive root: `/my-files` (app homes) or
  /// `/my-drive` (Drive, v1 homes). The other one redirects to it.
  String get myFilesRoute => items
      .firstWhere(
        (i) => i.destination == HomeNavDestination.myFiles,
        orElse: () =>
            const HomeNavItem(HomeNavDestination.myFiles, '/my-files'),
      )
      .route;
}

/// The query of `/new?folder=&template=` (suite 03 §2, v2).
@immutable
class NewItemRequest {
  const NewItemRequest({
    this.folderUuid,
    this.templateUuid,
    this.name,
    this.publicationId,
    this.ref,
  });

  /// Parses the route's query parameters (invalid uuids are ignored).
  factory NewItemRequest.fromQuery(Map<String, String> query) => NewItemRequest(
    folderUuid: _uuid(query['folder']),
    templateUuid: _uuid(query['template']),
    name: query['name'],
    publicationId: query['publication'],
    ref: query['ref'],
  );

  final UuidValue? folderUuid;
  final UuidValue? templateUuid;
  final String? name;

  /// (M14) A contributor link: start a story for this publication
  /// (`pub_…`, specs/18 §3), with the blog's optional [ref].
  final String? publicationId;
  final String? ref;

  /// The `/new` route of this request (relative to the app's base href):
  /// `/new?folder=<uuid>&template=<uuid>`.
  String get path {
    final q = <String, String>{
      if (folderUuid != null) 'folder': folderUuid!.uuid,
      if (templateUuid != null) 'template': templateUuid!.uuid,
      if (name != null && name!.isNotEmpty) 'name': name!,
      'publication': ?publicationId,
      'ref': ?ref,
    };
    return q.isEmpty
        ? '/new'
        : Uri(path: '/new', queryParameters: q).toString();
  }
}

/// The query of `/import?file=<fileItemUuid>` (Drive 02 §7.2).
@immutable
class ImportRouteRequest {
  const ImportRouteRequest({required this.fileItemUuid});

  /// Null when `file` is missing or not a uuid.
  static ImportRouteRequest? fromQuery(Map<String, String> query) {
    final file = _uuid(query['file']);
    return file == null ? null : ImportRouteRequest(fileItemUuid: file);
  }

  /// The uploaded `file` drive item to import.
  final UuidValue fileItemUuid;
}

/// Creates the item of a `/new` route; returns its uuid (the shell then
/// replaces the route with `itemPath(uuid)`), or null when cancelled (the
/// shell goes back).
typedef NewItemRouteHandler =
    Future<UuidValue?> Function(
      BuildContext context,
      ShellServices services,
      NewItemRequest request,
    );

/// Imports the Drive file of an `/import` route with the app's import
/// dialog into the file's folder (or My Drive); returns the new item's uuid
/// (the shell opens it), or null when cancelled (the shell goes back to the
/// previous Drive location).
typedef ImportRouteHandler =
    Future<UuidValue?> Function(
      BuildContext context,
      ShellServices services,
      ImportRouteRequest request,
    );

UuidValue? _uuid(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    return UuidValue.withValidation(s);
  } on FormatException {
    return null;
  }
}
