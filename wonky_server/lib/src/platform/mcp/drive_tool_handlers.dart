import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart'
    show DriveTools, McpToolDefinition, Role;
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../config/wonky_config.dart';
import '../../sheets/exports/sheets_export_service.dart';
import '../../sheets/imports/sheets_import_service.dart';
import '../../slides/mcp/slides_media_handlers.dart';
import '../../write/export/write_export_service.dart';
import '../../write/export/write_import_service.dart';
import '../../write/mcp/headless_editor.dart';
import '../common/models.dart';
import '../drive/drive_service.dart';
import '../drive/drive_trash.dart';
import '../drive/drive_user_state.dart';
import '../drive/drive_copies.dart';
import '../sharing/sharing_service.dart';
import '../storage/storage_service.dart';
import 'drive_file_tool_handlers.dart';
import 'tool_executor.dart';
import 'tool_support.dart';

/// Headless `drive.*` tools (suite 09 §4). Every call goes through the same
/// services (and `AccessService` checks) as the `drive`/`sharing` endpoints.
abstract final class DriveToolHandlers {
  static List<RegisteredMcpTool> get all => [
    _t(DriveTools.search, search),
    _t(DriveTools.listFolder, listFolder),
    _t(DriveTools.getItem, getItem),
    _t(DriveTools.createFolder, createFolder),
    _t(DriveTools.createDocument, createDocument),
    _t(DriveTools.rename, rename),
    _t(DriveTools.move, move),
    _t(DriveTools.copy, copy),
    _t(DriveTools.trash, trash),
    _t(DriveTools.restore, restore),
    _t(DriveTools.star, star),
    _t(DriveTools.share, share),
    _t(DriveTools.unshare, unshare),
    _t(DriveTools.setLinkSharing, setLinkSharing),
    _t(DriveTools.export, export),
    _t(DriveTools.import, import),
    ...DriveFileToolHandlers.all,
  ];

  static RegisteredMcpTool _t(McpToolDefinition d, ToolHandler h) =>
      RegisteredMcpTool(d, h);

  // ---------------------------------------------------------------- views

  /// The public base URL of the web apps (`https://wonky.work`,
  /// `http://localhost:8082` in development).
  static Uri get webBase {
    try {
      return WonkyConfig.current.webOrigin(Serverpod.instance.config);
    } on Object {
      return Uri.parse('http://localhost:8082');
    }
  }

  /// The browser URL of an item.
  static String urlOf(DriveItemView v) {
    final base = webBase;
    final path = switch (v.kind) {
      DriveItemKind.document => '/write/d/${v.uuid.uuid}',
      DriveItemKind.spreadsheet => '/sheets/s/${v.uuid.uuid}',
      DriveItemKind.folder => '/drive/f/${v.uuid.uuid}',
      DriveItemKind.presentation => '/slides/p/${v.uuid.uuid}',
      DriveItemKind.file => '/drive/file/${v.uuid.uuid}',
    };
    return base.replace(path: path).toString();
  }

  /// The JSON shape of a drive item in tool results.
  static Map<String, Object?> itemJson(DriveItemView v) => {
    'uuid': v.uuid.uuid,
    'kind': v.kind.name,
    'name': v.name,
    'description': ?v.description,
    'role': v.role.name,
    'owner': v.owner.displayName,
    'owner_email': v.owner.email,
    'parent_uuid': v.parentUuid?.uuid,
    if (v.kind == DriveItemKind.document) 'document_uuid': v.contentRef?.uuid,
    'starred': v.starred,
    'shared': v.shared,
    'link_role': v.linkRole?.name,
    'size_bytes': v.sizeBytes,
    'created_at': v.createdAt.toIso8601String(),
    'modified_at': v.modifiedAt.toIso8601String(),
    'modified_by': v.modifiedBy?.displayName,
    'trashed': v.trashedAt != null,
    'url': urlOf(v),
    // (v2) Size incl. images/attachments (what counts for the quota).
    'counted_bytes': v.countedBytes,
    if (v.kind == DriveItemKind.file) ...{
      'mime_type': v.mimeType,
      'file_category': v.fileCategory?.name,
      'upload_state': (v.uploadState ?? FileUploadState.ready).name,
      'file_meta': ?_meta(v.fileMetaJson),
    },
  };

  static Map<String, Object?>? _meta(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// (v2) `storage` of byte-adding tools (suite 09 §4): the caller's usage.
  static Map<String, Object?> storageOf(StorageUsage u) => {
    'used_bytes': u.bytesUsed,
    'quota_bytes': u.quotaBytes,
    'available_bytes': u.availableBytes,
    'over_quota': u.overQuota,
  };

  /// [storageOf] the caller of [ctx].
  static Future<Map<String, Object?>> storageJson(ToolContext ctx) async =>
      storageOf(
        await StorageService.instance.usage(ctx.session, ctx.actor.userId),
      );

  static ToolResult _items(List<DriveItemView> items, String? next) =>
      ToolResult(
        {
          'items': [for (final v in items) itemJson(v)],
          'next_cursor': next,
        },
        text: items.isEmpty
            ? 'No items'
            : [
                for (final v in items)
                  '- ${v.name} (${v.kind.name}, ${v.uuid.uuid})',
              ].join('\n'),
      );

  static ToolResult _changed(DriveItemView v, String verb) => ToolResult({
    'item': itemJson(v),
  }, text: '$verb "${v.name}" (${v.uuid.uuid})');

  /// [_changed] plus the caller's `storage` (tools that add bytes).
  static Future<ToolResult> _added(
    ToolContext ctx,
    DriveItemView v,
    String verb,
  ) async => ToolResult({
    'item': itemJson(v),
    'storage': await storageJson(ctx),
  }, text: '$verb "${v.name}" (${v.uuid.uuid})');

  /// `kind` and (v2) `kinds`, merged; null = every kind.
  static List<DriveItemKind>? _kinds(ToolArgs a) {
    final names = <String>{
      ?a.string('kind'),
      for (final k in a.list('kinds') ?? const []) '$k',
    };
    if (names.isEmpty) return null;
    return [for (final n in names) DriveItemKind.values.byName(n)];
  }

  /// (v2) `file_category`; null = every category.
  static List<FileCategory>? _categories(ToolArgs a) {
    final c = a.string('file_category');
    return c == null ? null : [FileCategory.values.byName(c)];
  }

  // ----------------------------------------------------------------- read

  static Future<ToolResult> search(ToolContext ctx, ToolArgs a) async {
    final query = a.string('query')?.trim() ?? '';
    final kinds = _kinds(a);
    final categories = _categories(a);
    final owner = a.boolean('owned_by_me') == true
        ? DriveOwnerFilter.me
        : DriveOwnerFilter.anyone;
    final limit = a.integer('limit') ?? 50;
    final modifiedAfter = a.string('modified_after') == null
        ? null
        : DateTime.parse(a.string('modified_after')!).toUtc();
    final folder = a.uuid('folder_uuid');
    DriveListPage page;
    if (query.isNotEmpty) {
      page = await DriveService.search(
        ctx.session,
        ctx.actor,
        query,
        filters: DriveSearchFilters(
          kinds: kinds,
          owner: owner,
          modifiedAfter: modifiedAfter,
          sharedOnly: a.boolean('shared_with_me') ?? false,
          fileCategories: categories,
        ),
        cursor: a.string('cursor'),
        limit: limit,
      );
    } else {
      final view = folder != null
          ? DriveView.folder
          : a.boolean('starred') == true
          ? DriveView.starred
          : a.boolean('shared_with_me') == true
          ? DriveView.sharedWithMe
          : DriveView.recent;
      page = await DriveService.list(
        ctx.session,
        ctx.actor,
        folderUuid: folder,
        filter: DriveListFilter(
          view: view,
          kinds: kinds,
          owner: owner,
          fileCategories: categories,
        ),
        sort: DriveSort(field: DriveSortField.modifiedAt),
        cursor: a.string('cursor'),
        limit: limit,
      );
    }
    var items = page.items;
    if (a.boolean('starred') == true) {
      items = [
        for (final i in items)
          if (i.starred) i,
      ];
    }
    if (query.isNotEmpty && folder != null) {
      items = [
        for (final i in items)
          if (i.parentUuid == folder) i,
      ];
    }
    if (modifiedAfter != null) {
      items = [
        for (final i in items)
          if (i.modifiedAt.isAfter(modifiedAfter)) i,
      ];
    }
    return _items(items, page.nextCursor);
  }

  static Future<ToolResult> listFolder(ToolContext ctx, ToolArgs a) async {
    final page = await DriveService.list(
      ctx.session,
      ctx.actor,
      folderUuid: a.uuid('folder_uuid'),
      filter: DriveListFilter(
        view: DriveView.folder,
        kinds: _kinds(a),
        fileCategories: _categories(a),
      ),
      sort: DriveSort(field: DriveSortField.name, descending: false),
      cursor: a.string('cursor'),
      limit: a.integer('limit') ?? 50,
    );
    return _items(page.items, page.nextCursor);
  }

  static Future<ToolResult> getItem(ToolContext ctx, ToolArgs a) async {
    final uuid = a.requireUuid('uuid');
    final view = await DriveService.get(ctx.session, ctx.actor, uuid);
    final path = await DriveService.path(ctx.session, ctx.actor, uuid);
    final sharing = await SharingService.getSharing(
      ctx.session,
      ctx.actor,
      uuid,
    );
    return ToolResult({
      'item': itemJson(view),
      'role': view.role.name,
      'path': [
        for (final p in path) {'uuid': p.uuid.uuid, 'name': p.name},
      ],
      'sharing': {
        'can_share': sharing.canShare,
        'link_role': sharing.link?.role?.name,
        'people': [
          for (final p in sharing.permissions)
            {
              'name': p.user?.displayName,
              'email': p.user?.email ?? p.invitedEmail,
              'role': p.role.name,
              'inherited_from': p.inheritedFromName,
              'pending': p.user == null,
            },
        ],
      },
    }, text: '${view.name} (${view.kind.name}) — your role: ${view.role.name}');
  }

  // ---------------------------------------------------------------- write

  static Future<ToolResult> createFolder(ToolContext ctx, ToolArgs a) async =>
      _changed(
        await DriveService.createFolder(
          ctx.session,
          ctx.actor,
          parentUuid: a.uuid('parent_uuid'),
          name: a.requireString('name'),
        ),
        'Created folder',
      );

  static Future<ToolResult> createDocument(
    ToolContext ctx,
    ToolArgs a,
  ) async => _added(
    ctx,
    await DriveService.createDocument(
      ctx.session,
      ctx.actor,
      parentUuid: a.uuid('parent_uuid'),
      name: a.requireString('name'),
      templateUuid: a.uuid('template_uuid'),
      initialMarkdown: a.string('markdown'),
    ),
    'Created document',
  );

  static Future<ToolResult> rename(ToolContext ctx, ToolArgs a) async =>
      _changed(
        await DriveService.rename(
          ctx.session,
          ctx.actor,
          a.requireUuid('uuid'),
          a.requireString('name'),
        ),
        'Renamed to',
      );

  static Future<ToolResult> move(ToolContext ctx, ToolArgs a) async {
    final moved = await DriveService.move(
      ctx.session,
      ctx.actor,
      a.uuids('uuids'),
      a.uuid('folder_uuid'),
    );
    return ToolResult({
      'items': [for (final v in moved) itemJson(v)],
    }, text: 'Moved ${moved.length} item(s)');
  }

  static Future<ToolResult> copy(ToolContext ctx, ToolArgs a) async {
    final uuid = a.requireUuid('uuid');
    var name = a.string('name');
    if (name == null) {
      final source = await DriveService.get(ctx.session, ctx.actor, uuid);
      name = 'Copy of ${source.name}';
    }
    return _added(
      ctx,
      await DriveCopies.copy(
        ctx.session,
        ctx.actor,
        uuid,
        newName: name,
        parentUuid: a.uuid('parent_uuid'),
        copyComments: a.boolean('copy_comments') ?? false,
        copySharing: a.boolean('copy_sharing') ?? false,
      ),
      'Created copy',
    );
  }

  static Future<ToolResult> trash(ToolContext ctx, ToolArgs a) async {
    final uuids = a.uuids('uuids');
    await DriveTrash.trash(ctx.session, ctx.actor, uuids);
    return ToolResult({
      'trashed': [for (final u in uuids) u.uuid],
    }, text: 'Moved ${uuids.length} item(s) to the trash');
  }

  static Future<ToolResult> restore(ToolContext ctx, ToolArgs a) async {
    final uuids = a.uuids('uuids');
    await DriveTrash.restore(ctx.session, ctx.actor, uuids);
    return ToolResult({
      'restored': [for (final u in uuids) u.uuid],
    }, text: 'Restored ${uuids.length} item(s)');
  }

  static Future<ToolResult> star(ToolContext ctx, ToolArgs a) async {
    final starred = a.boolean('starred') ?? true;
    return _changed(
      await DriveUserStates.setStarred(
        ctx.session,
        ctx.actor,
        a.requireUuid('uuid'),
        starred,
      ),
      starred ? 'Starred' : 'Unstarred',
    );
  }

  static Map<String, Object?> _sharingJson(SharingInfo s) => {
    'item_uuid': s.itemUuid.uuid,
    'link_role': s.link?.role?.name,
    'people': [
      for (final p in s.permissions)
        {
          'email': p.user?.email ?? p.invitedEmail,
          'name': p.user?.displayName,
          'role': p.role.name,
          'pending': p.user == null,
          'inherited_from': p.inheritedFromName,
        },
    ],
  };

  static Future<ToolResult> share(ToolContext ctx, ToolArgs a) async {
    final email = a.requireString('email').trim().toLowerCase();
    final role = AccessRole.values.byName(a.requireString('role'));
    final info = await SharingService.share(
      ctx.session,
      ctx.actor,
      a.requireUuid('uuid'),
      emails: [email],
      role: role,
      notify: a.boolean('notify') ?? true,
      message: a.string('message'),
    );
    final p = info.permissions.where(
      (p) => (p.user?.email ?? p.invitedEmail) == email,
    );
    return ToolResult({
      'permission': p.isEmpty
          ? {'email': email, 'role': role.name}
          : {
              'email': email,
              'role': p.first.role.name,
              'pending': p.first.user == null,
            },
      'sharing': _sharingJson(info),
    }, text: 'Shared with $email as ${role.name}');
  }

  static Future<ToolResult> unshare(ToolContext ctx, ToolArgs a) async {
    final email = a.requireString('email').trim().toLowerCase();
    final profile = await UserProfile.db.findFirstRow(
      ctx.session,
      where: (t) => t.email.equals(email),
    );
    final info = await SharingService.remove(
      ctx.session,
      ctx.actor,
      a.requireUuid('uuid'),
      userId: profile?.id,
      invitedEmail: profile == null ? email : null,
    );
    return ToolResult({
      'ok': true,
      'sharing': _sharingJson(info),
    }, text: 'Removed $email');
  }

  static Future<ToolResult> setLinkSharing(ToolContext ctx, ToolArgs a) async {
    final mode = a.requireString('mode');
    final info = await SharingService.setLink(
      ctx.session,
      ctx.actor,
      a.requireUuid('uuid'),
      mode == 'off' ? null : AccessRole.values.byName(mode),
    );
    final link = info.link;
    return ToolResult(
      {
        'link': {
          'role': link?.role?.name,
          'url': link == null
              ? null
              : webBase.replace(path: '/invite/${link.token}').toString(),
        },
      },
      text: mode == 'off'
          ? 'Link sharing is off'
          : 'Anyone with the link: $mode',
    );
  }

  // ----------------------------------------------------- export / import

  static Future<ToolResult> export(ToolContext ctx, ToolArgs a) async {
    final uuid = a.requireUuid('uuid');
    final format = a.requireString('format');
    final kindItem = await DriveService.get(ctx.session, ctx.actor, uuid);
    switch (kindItem.kind) {
      case DriveItemKind.file:
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'Uploaded files are not exported: use drive.download_file (or '
          'drive.convert_file to make an editable copy).',
        );
      case DriveItemKind.folder:
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'Folders cannot be exported.',
        );
      case DriveItemKind.presentation:
        // (SL-40) pdf as slides.export_pdf, md = the outline Markdown.
        return SlidesMediaHandlers.driveExport(ctx, uuid, format);
      case DriveItemKind.document:
      case DriveItemKind.spreadsheet:
        break;
    }
    if (kindItem.kind == DriveItemKind.spreadsheet) {
      final r = await SheetsExportService.export(
        ctx.session,
        ctx.actor,
        uuid,
        format,
        sheetName: a.string('sheet'),
        range: a.string('range'),
        darkTheme: a.boolean('dark_theme') ?? false,
      );
      final inline = r.inlineText;
      return ToolResult(
        {
          'format': format,
          'file_name': r.fileName,
          'mime_type': r.mimeType,
          'size_bytes': r.sizeBytes,
          'page_count': ?r.pageCount,
          'content': ?inline,
          'download_url': r.downloadUrl,
          'expires_at': r.expiresAt.toIso8601String(),
          'warnings': [for (final w in r.warnings) w.toJson()],
        },
        text:
            inline ?? 'Download: ${r.downloadUrl} (valid until ${r.expiresAt})',
      );
    }
    final target = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      uuid,
    );
    if (target.role < Role.editor && !target.item.nonEditorsCanExport) {
      throw McpToolException(
        McpErrorCode.forbidden,
        'The owner has disabled downloads for viewers.',
      );
    }
    if (format == 'html') {
      final state = await HeadlessDocumentEditor.head(
        ctx.session,
        target.document,
      );
      final artifact = await WriteExportService.exportBytes(
        ctx.session,
        ctx.actor,
        target.document,
        target.item,
        state.content,
        core.ExportFormat.html,
        const {'embed_images': false},
        revision: state.revision,
      );
      final fileName = artifact.fileName;
      final bytes = artifact.bytes;
      final html = utf8.decode(bytes, allowMalformed: true);
      return ToolResult({
        'format': 'html',
        'file_name': fileName,
        'mime_type': 'text/html',
        'size_bytes': bytes.length,
        'content': html,
      }, text: html);
    }
    final r = await WriteExportService.export(
      ctx.session,
      ctx.actor,
      target.document.uuid,
      format,
      '{}',
    );
    final inline = r.inlineText;
    return ToolResult(
      {
        'format': format,
        'file_name': r.fileName,
        'mime_type': r.mimeType,
        'size_bytes': r.sizeBytes,
        'page_count': ?r.pageCount,
        'content': ?inline,
        'download_url': r.downloadUrl,
        'expires_at': r.expiresAt.toIso8601String(),
      },
      text: inline ?? 'Download: ${r.downloadUrl} (valid until ${r.expiresAt})',
    );
  }

  /// `drive.import` with kind spreadsheet (Sheets 11 §9): the server
  /// import pipeline ([SheetsImportService]).
  static Future<ToolResult> _importSpreadsheet(
    ToolContext ctx,
    ToolArgs a,
    String format,
  ) async {
    if (!SheetsImportService.formats.contains(format)) {
      throw McpToolException(
        McpErrorCode.unsupported,
        'Spreadsheets can be imported from '
        '${SheetsImportService.formats.join(', ')}.',
      );
    }
    final Uint8List bytes;
    if (a.has('content_base64')) {
      try {
        bytes = base64Decode(a.string('content_base64')!);
      } on FormatException {
        throw McpToolException(McpErrorCode.invalidArgs, 'Invalid base64.');
      }
    } else if (a.has('text')) {
      bytes = Uint8List.fromList(utf8.encode(a.string('text')!));
    } else {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Pass text or content_base64.',
      );
    }
    final raw = a.values['options'];
    final name = a.requireString('name');
    final report = await SheetsImportService.importNew(
      ctx.session,
      ctx.actor,
      bytes,
      fileName: '$name.$format',
      format: format,
      options: SheetsImportService.optionsOf(
        raw is Map ? jsonEncode(raw) : null,
      ),
      name: name,
      parentUuid: a.uuid('parent_uuid'),
    );
    final view = report.item;
    return ToolResult({
      'item': itemJson(view),
      'warnings': [for (final w in report.warnings) w.toJson()],
      'storage': await storageJson(ctx),
    }, text: 'Imported "${view.name}" (${view.uuid.uuid})');
  }

  static Future<ToolResult> import(ToolContext ctx, ToolArgs a) async {
    final kind = a.requireString('kind');
    final format = a.requireString('format').toLowerCase().replaceAll('.', '');
    if (kind == 'spreadsheet') return _importSpreadsheet(ctx, a, format);
    if (kind != 'document') {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'kind must be document or spreadsheet.',
      );
    }
    if (!WriteImportService.formats.contains(format)) {
      throw McpToolException(
        McpErrorCode.unsupported,
        'Documents can be imported from '
        '${WriteImportService.formats.join(', ')}.',
      );
    }
    final Uint8List bytes;
    if (a.has('text')) {
      bytes = Uint8List.fromList(utf8.encode(a.string('text')!));
    } else if (a.has('content_base64')) {
      try {
        bytes = base64Decode(a.string('content_base64')!);
      } on FormatException {
        throw McpToolException(McpErrorCode.invalidArgs, 'Invalid base64.');
      }
    } else {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Pass text or content_base64.',
      );
    }
    final name = a.requireString('name');
    final report = await WriteImportService.importBytes(
      ctx.session,
      ctx.actor,
      bytes,
      fileName: '$name.$format',
      format: format,
      name: name,
      parentUuid: a.uuid('parent_uuid'),
      activityExtra: const {'via': 'mcp'},
    );
    final view = report.item;
    final warnings = [for (final w in report.warnings) w.toJson()];
    return ToolResult({
      'item': itemJson(view),
      'warnings': warnings,
      'storage': await storageJson(ctx),
    }, text: 'Imported "${view.name}" (${view.uuid.uuid})');
  }
}
