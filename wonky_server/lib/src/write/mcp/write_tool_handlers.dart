import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart'
    show McpToolDefinition, Role, WriteTools;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/comments/comment_service.dart';
import '../../platform/common/models.dart';
import '../../platform/files/file_service.dart';
import '../../platform/mcp/drive_tool_handlers.dart';
import '../../platform/mcp/tool_executor.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/users/user_service.dart';
import '../collab/overlay_lifecycle.dart';
import '../export/write_export_service.dart';
import '../ot/document_service.dart';
import '../ot/document_store.dart';
import '../themes/theme_service.dart';
import 'headless_editor.dart';
import '../../platform/storage/storage_hooks.dart';
import '../../platform/storage/storage_service.dart';

/// Implementations of the headless `write.*` tools (Write 09 §2). Reads go
/// to the head without locking; every mutation is one op through
/// [HeadlessDocumentEditor.mutate].
abstract final class WriteToolHandlers {
  static List<RegisteredMcpTool> get all => [
    _t(WriteTools.getDocument, getDocument),
    _t(WriteTools.getOutline, getOutline),
    _t(WriteTools.getStats, getStats),
    _t(WriteTools.search, search),
    _t(WriteTools.getPageSetup, getPageSetup),
    _t(WriteTools.insertMarkdown, insertMarkdown),
    _t(WriteTools.replaceText, replaceText),
    _t(WriteTools.replaceRange, replaceRange),
    _t(WriteTools.deleteRange, deleteRange),
    _t(WriteTools.applyFormat, applyFormat),
    _t(WriteTools.setBlockType, setBlockType),
    _t(WriteTools.setMarkdown, setMarkdown),
    _t(WriteTools.applyDelta, applyDelta),
    _t(WriteTools.insertImage, insertImage),
    _t(WriteTools.insertTable, insertTable),
    _t(WriteTools.updateTable, updateTable),
    _t(WriteTools.updatePageSetup, updatePageSetup),
    _t(WriteTools.listSuggestions, listSuggestions),
    _t(WriteTools.acceptSuggestion, acceptSuggestion),
    _t(WriteTools.rejectSuggestion, rejectSuggestion),
    _t(WriteTools.suggestEdit, suggestEdit),
    _t(WriteTools.listThemes, listThemes),
    _t(WriteTools.applyTheme, applyTheme),
  ];

  static RegisteredMcpTool _t(McpToolDefinition d, ToolHandler h) =>
      RegisteredMcpTool(d, h);

  // ---------------------------------------------------------------- shared

  static UuidValue _doc(ToolArgs a) => a.requireUuid('document_uuid');

  static ResolvedRange? _range(Delta doc, Map<String, dynamic>? json) =>
      json == null
      ? null
      : AddressResolver(doc).resolveRange(RangeAddress.fromJson(json));

  static ToolResult _mutation(Map<String, Object?> r) {
    final rev = r['revision'];
    final id = r['change_id'];
    return ToolResult(
      r,
      text:
          '${r['summary'] ?? 'Done'} · revision $rev'
          '${id == null ? '' : ' · change_id $id'}',
    );
  }

  static Map<String, Object?> _docHeader(WriteTarget t, int revision) => {
    'document_uuid': t.item.uuid.uuid,
    'title': t.item.name,
    'revision': revision,
  };

  static String _layout(Document doc) {
    try {
      final json = jsonDecode(doc.pageSetupJson);
      if (json is Map && json['layout'] == 'pageless') return 'pageless';
    } on FormatException {
      // Default layout.
    }
    return 'pages';
  }

  static PageSetup _pageSetup(Document doc) {
    try {
      final json = jsonDecode(doc.pageSetupJson);
      if (json is Map) return PageSetup.fromJson(json.cast<String, dynamic>());
    } on FormatException {
      // Default setup.
    }
    return const PageSetup();
  }

  /// A builder result for a raw change (normalized against [head]).
  static EditResult _raw(
    Delta head,
    Delta change, {
    String summary = '',
    Map<String, dynamic> extra = const {},
  }) {
    final n = const WonkyDeltaNormalizer().normalizeChange(head, change);
    return EditResult(
      change: n.change,
      document: n.document,
      summary: summary,
      extra: extra,
    );
  }

  // --------------------------------------------------------------- reading

  static Future<ToolResult> getDocument(ToolContext ctx, ToolArgs a) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
    );
    final state = await HeadlessDocumentEditor.head(ctx.session, t.document);
    var content = state.content;
    var revision = state.revision;
    final wanted = a.integer('revision');
    if (wanted != null && wanted != revision) {
      if (t.role < Role.editor) {
        throw McpToolException(
          McpErrorCode.forbidden,
          'Reading older revisions requires edit access.',
        );
      }
      if (wanted > revision || wanted < 0) {
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'Revision $wanted does not exist (head is $revision).',
        );
      }
      content = await DocumentStore.contentAt(ctx.session, t.document, wanted);
      revision = wanted;
    }
    final format = switch (a.string('format') ?? 'markdown') {
      'delta' => ReadFormat.delta,
      'text' => ReadFormat.text,
      'outline' => ReadFormat.outline,
      _ => ReadFormat.markdown,
    };
    final view = switch (a.string('suggestions')) {
      'accepted' => SuggestionViewMode.accepted,
      'original' => SuggestionViewMode.original,
      'raw' => SuggestionViewMode.raw,
      _ => null,
    };
    final read = const DocumentReader().read(
      content,
      format: format,
      range: _range(content, a.object('range')),
      view: view,
      includeBlocks: a.boolean('include_blocks') ?? false,
      maxChars: a.integer('max_chars') ?? 50000,
      cursor: a.string('cursor'),
      frontMatter: t.document.frontMatter,
    );
    final out = <String, Object?>{
      ..._docHeader(t, revision),
      ...read.toJson(),
      'front_matter': t.document.frontMatter,
      'theme_uuid': t.document.themeId?.uuid,
      'layout': _layout(t.document),
      'role': t.role.name,
    };
    final text = read.content is String
        ? '${read.content}${read.truncated ? '\n\n[truncated — continue with cursor "${read.nextCursor}"]' : ''}'
        : jsonEncode(read.content);
    return ToolResult(out, text: text);
  }

  static Future<ToolResult> getOutline(ToolContext ctx, ToolArgs a) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
    );
    final state = await HeadlessDocumentEditor.head(ctx.session, t.document);
    final out = outlineOf(state.content, state.revision);
    return ToolResult({..._docHeader(t, state.revision), ...out});
  }

  /// `write.get_outline` output for [content].
  static Map<String, Object?> outlineOf(Delta content, int revision) => {
    'revision': revision,
    'headings': [
      for (final e in const OutlineExtractor().outlineOf(
        WonkyDocument(content),
      ))
        {
          'index': e.index,
          'level': e.level,
          'text': e.text,
          'delta_start': e.deltaOffset,
          'section_start': e.sectionStart,
          'section_length': e.sectionLength,
        },
    ],
  };

  static Future<ToolResult> getStats(ToolContext ctx, ToolArgs a) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
    );
    final state = await HeadlessDocumentEditor.head(ctx.session, t.document);
    final range = _range(state.content, a.object('range'));
    final stats = const DocumentStatsCalculator().stats(
      state.content,
      start: range?.start,
      length: range?.length,
    );
    final openComments = await CommentThread.db.count(
      ctx.session,
      where: (c) =>
          c.itemId.equals(t.item.id!) &
          c.status.equals(CommentStatus.open) &
          c.suggestionId.equals(null),
    );
    final modifiedBy = await UserService.summary(
      ctx.session,
      t.item.modifiedById,
    );
    final json = stats.toJson();
    return ToolResult({
      ..._docHeader(t, state.revision),
      ...json,
      'pages_estimate': stats.words == 0 ? 1 : (stats.words / 500).ceil(),
      'open_comments': openComments,
      'pending_suggestions': SuggestionIndex.list(state.content).length,
      'last_modified_at': t.item.modifiedAt.toIso8601String(),
      'last_modified_by': modifiedBy?.displayName,
    });
  }

  static Future<ToolResult> search(ToolContext ctx, ToolArgs a) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
    );
    final state = await HeadlessDocumentEditor.head(ctx.session, t.document);
    final spec = FindSpec(
      a.requireString('query'),
      regex: a.boolean('regex') ?? false,
      matchCase: a.boolean('match_case') ?? false,
      wholeWord: a.boolean('whole_word') ?? false,
    );
    final r = TextSearch(WonkyDocument(state.content)).search(
      spec,
      scope: _range(state.content, a.object('scope')),
      limit: a.integer('limit') ?? 100,
      contextChars: a.integer('context_chars') ?? 40,
    );
    return ToolResult({
      ..._docHeader(t, state.revision),
      'total': r.total,
      'matches': [for (final m in r.matches) m.toJson()],
      'truncated': r.truncated,
    }, text: '${r.total} match(es) at revision ${state.revision}');
  }

  static Future<ToolResult> getPageSetup(ToolContext ctx, ToolArgs a) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
    );
    final setup = _pageSetup(t.document);
    return ToolResult({
      'document_uuid': t.item.uuid.uuid,
      'page_setup': setup.toJson(),
      'paper_size_pt': {
        'width': setup.pageWidthPt,
        'height': setup.pageHeightPt,
      },
    });
  }

  // ------------------------------------------------------------- mutations

  static Future<ToolResult> insertMarkdown(ToolContext ctx, ToolArgs a) async {
    final markdown = a.requireString('markdown');
    final as = switch (a.string('as')) {
      'inline' => InsertAs.inline,
      'blocks' => InsertAs.blocks,
      _ => InsertAs.auto,
    };
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.insert_markdown',
      options: MutationOptions.of(a),
      defaultLabel: 'Insert text',
      build: (head, edits) {
        final resolver = AddressResolver(head);
        final at = PositionAddress.fromJson(a.object('at')!);
        if (at is ReplaceSectionPosition) {
          final range = resolver.resolveReplaceSection(at);
          final res = edits.replaceRange(head, range, markdown);
          return EditResult(
            change: res.change,
            document: res.document,
            appliedRange: res.appliedRange,
            warnings: res.warnings,
            summary: 'Replaced the section',
            extra: {'inserted_range': res.appliedRange?.toJson()},
          );
        }
        return edits.insertMarkdown(
          head,
          resolver.resolvePosition(at),
          markdown,
          as: as,
        );
      },
    );
    return _mutation(r);
  }

  static Future<ToolResult> replaceText(ToolContext ctx, ToolArgs a) async {
    final occ = a.values['occurrence'];
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.replace_text',
      options: MutationOptions.of(a),
      defaultLabel: 'Replace text',
      build: (head, edits) => edits.replaceText(
        head,
        FindSpec(
          a.requireString('find'),
          regex: a.boolean('regex') ?? false,
          matchCase: a.boolean('match_case') ?? false,
          wholeWord: a.boolean('whole_word') ?? false,
        ),
        a.requireString('replace'),
        occurrence: occ is num ? occ.toInt() : null,
        format: a.string('replace_format') == 'markdown_inline'
            ? ReplaceFormat.markdownInline
            : ReplaceFormat.text,
        scope: _range(head, a.object('scope')),
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> replaceRange(ToolContext ctx, ToolArgs a) async {
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.replace_range',
      options: MutationOptions.of(a),
      defaultLabel: 'Rewrite text',
      build: (head, edits) => edits.replaceRange(
        head,
        _range(head, a.object('range'))!,
        a.requireString('markdown'),
        preserveOverlays: a.boolean('preserve_overlays') ?? true,
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> deleteRange(ToolContext ctx, ToolArgs a) async {
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.delete_range',
      options: MutationOptions.of(a),
      defaultLabel: 'Delete text',
      build: (head, edits) =>
          edits.deleteRange(head, _range(head, a.object('range'))!),
    );
    return _mutation(r);
  }

  static Future<ToolResult> applyFormat(ToolContext ctx, ToolArgs a) async {
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.apply_format',
      options: MutationOptions.of(a),
      defaultLabel: 'Format text',
      build: (head, edits) => edits.applyInlineFormat(
        head,
        _range(head, a.object('range'))!,
        InlineFormatPatch.fromJson(a.object('set')!),
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> setBlockType(ToolContext ctx, ToolArgs a) async {
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.set_block_type',
      options: MutationOptions.of(a),
      defaultLabel: 'Change block type',
      build: (head, edits) => edits.setBlockType(
        head,
        _range(head, a.object('range'))!,
        BlockTypeSpec.fromJson(a.values.cast<String, dynamic>()),
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> setMarkdown(ToolContext ctx, ToolArgs a) async {
    final uuid = _doc(a);
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: uuid,
      toolName: 'write.set_markdown',
      options: MutationOptions.of(a),
      defaultLabel: 'Replace document',
      build: (head, edits) =>
          edits.setMarkdown(head, a.requireString('markdown')),
    );
    if (a.present('front_matter')) {
      final t = await HeadlessDocumentEditor.resolve(
        ctx.session,
        ctx.actor,
        uuid,
        min: Role.editor,
      );
      final before = HeadlessDocumentEditor.metaValueJson(
        t.document,
        'frontMatter',
      );
      final after = jsonEncode(a.string('front_matter'));
      await DocumentService.updateMeta(
        ctx.session,
        ctx.actor,
        t.document.uuid,
        DocumentMetaPatch(field: 'frontMatter', valueJson: after),
        const Uuid().v7obj(),
      );
      r['front_matter_change_id'] =
          await HeadlessDocumentEditor.recordMetaChange(
            ctx,
            t,
            toolName: 'write.set_markdown',
            field: 'frontMatter',
            beforeValueJson: before,
            afterValueJson: after,
            label: 'Change front matter',
          );
    }
    return _mutation(r);
  }

  static Future<ToolResult> applyDelta(ToolContext ctx, ToolArgs a) async {
    final options = MutationOptions.of(a);
    if (options.mode == 'suggest') {
      throw McpToolException(
        McpErrorCode.unsupportedInSuggestMode,
        'write.apply_delta applies the delta as given; use mode "edit" or '
        'send a suggestion-shaped delta (sug_* attributes) with the '
        'commenter role.',
      );
    }
    Delta delta;
    try {
      delta = Delta.fromJson(a.list('delta')!);
    } on Object catch (e) {
      throw McpToolException(McpErrorCode.invalidArgs, 'Invalid delta: $e');
    }
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.apply_delta',
      options: options,
      overlayOnly: true,
      baseRevisionOverride: a.integer('base_revision'),
      defaultLabel: 'Apply delta',
      build: (head, edits) => EditResult(
        change: DeltaUtils.canonical(delta),
        document: head,
        summary: 'Applied the delta',
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> insertImage(ToolContext ctx, ToolArgs a) async {
    final uuid = _doc(a);
    final target = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      uuid,
      min: Role.commenter,
    );
    final source = a.object('source')!;
    final url = source['url'] as String?;
    final b64 = source['base64'] as String?;
    if ((url == null) == (b64 == null)) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'source needs exactly one of url or base64.',
      );
    }
    final store = a.boolean('store') ?? true;
    String src;
    String? fileUuid;
    if (url != null && !store) {
      src = url;
    } else {
      Uint8List bytes;
      String mime;
      if (b64 != null) {
        try {
          bytes = base64Decode(b64);
        } on FormatException {
          throw McpToolException(McpErrorCode.invalidArgs, 'Invalid base64.');
        }
        mime = (source['mime'] as String?) ?? 'image/png';
      } else {
        final data = await WriteExportService.fetchImage(
          ctx.session,
          ctx.actor,
          target.document.uuid,
          url!,
        );
        bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        mime = FileService.sniffImage(bytes) ?? 'image/png';
      }
      if (bytes.length > FileService.maxBytes(StoredFileKind.image)) {
        throw McpToolException(
          McpErrorCode.tooLarge,
          'Images can be at most 20 MB.',
        );
      }
      final sniffed = mime == 'image/svg+xml'
          ? mime
          : FileService.sniffImage(bytes);
      if (sniffed == null) {
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'The data is not a supported image.',
        );
      }
      final ext = sniffed.split('/').last.replaceAll('svg+xml', 'svg');
      // (v2) Images count for the document's owner (Drive 03 §7.2).
      await StorageHooks.checkOwnerOf(
        ctx.session,
        ctx.actor,
        target.item,
        bytes.length,
        QuotaReason.image,
      );
      final file = await FileService.storeServerFile(
        ctx.session,
        ownerId: ctx.actor.userId,
        itemId: target.item.id,
        kind: StoredFileKind.image,
        fileName: 'image.$ext',
        mimeType: sniffed,
        bytes: bytes,
        optimize: true,
      );
      await StorageHooks.chargeImage(ctx.session, target.item, file);
      fileUuid = file.fileUuid.uuid;
      src = 'wonky-file://$fileUuid';
    }
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: uuid,
      toolName: 'write.insert_image',
      options: MutationOptions.of(a),
      defaultLabel: 'Insert image',
      build: (head, edits) => edits.insertImage(
        head,
        AddressResolver(
          head,
        ).resolvePosition(PositionAddress.fromJson(a.object('at')!)),
        src: src,
        alt: a.string('alt') ?? '',
        title: a.string('title'),
      ),
    );
    return _mutation({
      ...r,
      'file_uuid': ?fileUuid,
      // (v2) Stored images count for the document's owner (suite 09 §4).
      if (fileUuid != null) 'storage': await DriveToolHandlers.storageJson(ctx),
    });
  }

  static Future<ToolResult> insertTable(ToolContext ctx, ToolArgs a) async {
    final rows = [
      for (final row in a.list('rows')!) [for (final c in row as List) '$c'],
    ];
    final align = a.list('align') == null
        ? null
        : [
            for (final v in a.list('align')!)
              switch (v) {
                'left' => CellAlign.left,
                'center' => CellAlign.center,
                'right' => CellAlign.right,
                _ => null,
              },
          ];
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.insert_table',
      options: MutationOptions.of(a),
      defaultLabel: 'Insert table',
      build: (head, edits) => edits.insertTable(
        head,
        AddressResolver(
          head,
        ).resolvePosition(PositionAddress.fromJson(a.object('at')!)),
        rows,
        align: align,
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> updateTable(ToolContext ctx, ToolArgs a) async {
    final table = a.object('table')!;
    final rows = a.list('rows') == null
        ? null
        : [
            for (final row in a.list('rows')!)
              [for (final c in row as List) '$c'],
          ];
    final ops = [
      for (final o in a.list('operations') ?? const [])
        TableOperation.fromJson((o as Map).cast<String, dynamic>()),
    ];
    if (rows == null && ops.isEmpty) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Pass rows or operations.',
      );
    }
    if (table['table_id'] == null && table['table_index'] == null) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'table needs table_id or table_index.',
      );
    }
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: _doc(a),
      toolName: 'write.update_table',
      options: MutationOptions.of(a),
      defaultLabel: 'Edit table',
      build: (head, edits) => edits.updateTable(
        head,
        tableId: table['table_id'] as String?,
        tableIndex: (table['table_index'] as num?)?.toInt(),
        rows: rows,
        operations: ops,
      ),
    );
    return _mutation(r);
  }

  static Future<ToolResult> updatePageSetup(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
      min: Role.editor,
    );
    final expected = a.integer('expected_revision');
    if (expected != null && expected != t.document.headRevision) {
      throw McpToolException(
        McpErrorCode.revisionMismatch,
        'The document is at revision ${t.document.headRevision}.',
        details: {'current_revision': t.document.headRevision},
      );
    }
    final current = _pageSetup(t.document);
    PageSetup next;
    try {
      next = current.applyPatch(a.object('patch')!);
    } on FormatException catch (e) {
      throw McpToolException(
        McpErrorCode.validationFailed,
        'Invalid page setup: ${e.message}',
      );
    }
    final before = t.document.pageSetupJson;
    final after = jsonEncode(next.toJson());
    await DocumentService.updateMeta(
      ctx.session,
      ctx.actor,
      t.document.uuid,
      DocumentMetaPatch(field: 'pageSetup', valueJson: after),
      const Uuid().v7obj(),
    );
    final id = await HeadlessDocumentEditor.recordMetaChange(
      ctx,
      t,
      toolName: 'write.update_page_setup',
      field: 'pageSetup',
      beforeValueJson: before,
      afterValueJson: after,
      label: 'Page setup',
    );
    return ToolResult({
      'document_uuid': t.item.uuid.uuid,
      'page_setup': next.toJson(),
      'change_id': id,
    }, text: 'Updated the page setup · change_id $id');
  }

  // ----------------------------------------------------------- suggestions

  static Future<Map<String, Map<String, Object?>>> _authors(
    Session session,
    Iterable<String> authUuids,
  ) async {
    final ids = <UuidValue>{};
    for (final u in authUuids) {
      try {
        ids.add(UuidValue.withValidation(u));
      } on FormatException {
        // Not a user uuid.
      }
    }
    if (ids.isEmpty) return const {};
    final profiles = await UserProfile.db.find(
      session,
      where: (t) => t.authUserId.inSet(ids),
    );
    return {
      for (final p in profiles)
        p.authUserId.uuid: {'uuid': p.authUserId.uuid, 'name': p.displayName},
    };
  }

  static Future<ToolResult> listSuggestions(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
    );
    if (t.role == Role.viewer && !t.item.viewersSeeComments) {
      throw McpToolException(
        McpErrorCode.forbidden,
        'Suggestions are hidden for viewers of this document.',
      );
    }
    final state = await HeadlessDocumentEditor.head(ctx.session, t.document);
    final all = SuggestionIndex.list(
      state.content,
      authorUuid: a.string('author_uuid'),
    );
    final offset = int.tryParse(a.string('cursor') ?? '') ?? 0;
    final limit = a.integer('limit') ?? 50;
    final page = all.skip(offset).take(limit).toList();
    final authors = await _authors(ctx.session, {for (final s in page) s.by});
    final threads = await CommentThread.db.find(
      ctx.session,
      where: (c) =>
          c.itemId.equals(t.item.id!) &
          c.suggestionId.inSet({for (final s in page) s.id}),
    );
    final byId = {for (final th in threads) th.suggestionId!: th};
    final replies = <int, int>{};
    for (final th in threads) {
      replies[th.id!] = await Comment.db.count(
        ctx.session,
        where: (c) => c.threadId.equals(th.id!) & c.deletedAt.equals(null),
      );
    }
    final next = offset + page.length;
    return ToolResult({
      ..._docHeader(t, state.revision),
      'total': all.length,
      'suggestions': [
        for (final s in page)
          {
            ...s.toJson(),
            'author': authors[s.by] ?? {'uuid': s.by, 'name': 'Unknown'},
            'created_at': DateTime.fromMillisecondsSinceEpoch(
              s.at,
              isUtc: true,
            ).toIso8601String(),
            'thread_uuid': OverlayLifecycle.suggestionThreadUuid(
              t.document.uuid,
              s.id,
            ).uuid,
            'reply_count': byId[s.id] == null ? 0 : replies[byId[s.id]!.id!],
          },
      ],
      'next_cursor': next < all.length ? '$next' : null,
    }, text: '${all.length} pending suggestion(s)');
  }

  static Future<ToolResult> acceptSuggestion(
    ToolContext ctx,
    ToolArgs a,
  ) => _decide(ctx, a, accept: true);

  static Future<ToolResult> rejectSuggestion(
    ToolContext ctx,
    ToolArgs a,
  ) => _decide(ctx, a, accept: false);

  static Future<ToolResult> _decide(
    ToolContext ctx,
    ToolArgs a, {
    required bool accept,
  }) async {
    final uuid = _doc(a);
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      uuid,
      min: Role.commenter,
    );
    final state = await HeadlessDocumentEditor.head(ctx.session, t.document);
    final author = a.string('author_uuid');
    final pending = {
      for (final s in SuggestionIndex.list(state.content, authorUuid: author))
        s.id: s,
    };
    final raw = a.values['suggestion_ids'];
    final requested = raw is List
        ? [for (final v in raw) '$v']
        : pending.keys.toList();
    final ids = {
      for (final id in requested)
        if (pending.containsKey(id)) id,
    };
    final skipped = [
      for (final id in requested)
        if (!pending.containsKey(id)) {'id': id, 'reason': 'not_found'},
    ];
    if (t.role < Role.editor) {
      final me = ctx.actor.authUserId.uuid;
      final foreign = ids.where((id) => pending[id]!.by != me);
      if (accept || foreign.isNotEmpty) {
        throw McpToolException(
          McpErrorCode.forbidden,
          accept
              ? 'Only editors can accept suggestions.'
              : 'Commenters can only withdraw their own suggestions.',
        );
      }
    }
    if (ids.isEmpty) {
      return ToolResult({
        ..._docHeader(t, state.revision),
        'change_id': null,
        accept ? 'accepted' : 'rejected': const <String>[],
        'skipped': skipped,
        'summary': 'No pending suggestions matched',
      }, text: 'No pending suggestions matched');
    }
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: uuid,
      toolName: accept ? 'write.accept_suggestion' : 'write.reject_suggestion',
      options: MutationOptions.of(a),
      overlayOnly: true,
      defaultLabel: accept ? 'Accept suggestions' : 'Reject suggestions',
      build: (head, edits) => _raw(
        head,
        accept
            ? SuggestionOps.accept(head, ids)
            : SuggestionOps.reject(head, ids),
        summary:
            '${accept ? 'Accepted' : 'Rejected'} ${ids.length} suggestion(s)',
      ),
    );
    return _mutation({
      ...r,
      accept ? 'accepted' : 'rejected': ids.toList(),
      'skipped': skipped,
    });
  }

  static Future<ToolResult> suggestEdit(ToolContext ctx, ToolArgs a) async {
    final uuid = _doc(a);
    final markdown = a.requireString('markdown');
    final r = await HeadlessDocumentEditor.mutate(
      ctx,
      documentUuid: uuid,
      toolName: 'write.suggest_edit',
      options: MutationOptions(
        expectedRevision: a.integer('expected_revision'),
        mode: 'suggest',
        label: a.string('label'),
      ),
      forceSuggest: true,
      defaultLabel: 'Suggest edit',
      build: (head, edits) {
        final range = _range(head, a.object('range'))!;
        return markdown.isEmpty
            ? edits.deleteRange(head, range)
            : edits.replaceRange(head, range, markdown);
      },
    );
    final sid = r['suggestion_id'] as String?;
    final comment = a.string('comment');
    if (sid != null) {
      final t = await HeadlessDocumentEditor.resolve(
        ctx.session,
        ctx.actor,
        uuid,
      );
      final threadUuid = OverlayLifecycle.suggestionThreadUuid(
        t.document.uuid,
        sid,
      );
      r['thread_uuid'] = threadUuid.uuid;
      if (comment != null && comment.trim().isNotEmpty) {
        final exists = await CommentThread.db.findFirstRow(
          ctx.session,
          where: (c) => c.uuid.equals(threadUuid),
        );
        if (exists != null) {
          await CommentService.reply(
            ctx.session,
            ctx.actor,
            threadUuid,
            body: comment,
          );
        } else {
          r['warnings'] = [
            ...(r['warnings'] as List? ?? const []),
            {
              'code': 'comment_not_posted',
              'message': 'The suggestion thread is not ready yet.',
            },
          ];
        }
      }
    }
    return _mutation(r);
  }

  // ---------------------------------------------------------------- themes

  static Future<ToolResult> listThemes(ToolContext ctx, ToolArgs a) async {
    final scope = a.string('scope') ?? 'all';
    final docUuid = a.uuid('document_uuid');
    WriteTarget? target;
    if (docUuid != null) {
      target = await HeadlessDocumentEditor.resolve(
        ctx.session,
        ctx.actor,
        docUuid,
      );
    }
    final themes = <WriteThemeView>[
      if (scope != 'mine') ...await ThemeService.listBuiltins(ctx.session),
      if (scope != 'builtin')
        ...await ThemeService.listMine(ctx.session, ctx.actor),
    ];
    final docTheme = target?.document.themeId;
    if (docTheme != null && !themes.any((th) => th.uuid == docTheme)) {
      try {
        themes.add(
          await ThemeService.get(
            ctx.session,
            ctx.actor,
            docTheme,
            viaDocumentUuid: target!.document.uuid,
          ),
        );
      } on WonkyException {
        // Not readable.
      }
    }
    final defaultId = await UserService.defaultThemeId(
      ctx.session,
      ctx.actor.userId,
    );
    return ToolResult({
      'themes': [
        for (final th in themes)
          {
            'uuid': th.uuid.uuid,
            'name': th.name,
            'description': th.description,
            'is_builtin': th.isBuiltin,
            'owner': th.owner?.displayName,
            'version': th.version,
            'updated_at': th.updatedAt.toIso8601String(),
            'is_default': th.uuid == defaultId,
            'used_by_document': docTheme != null && th.uuid == docTheme,
          },
      ],
    }, text: '${themes.length} theme(s)');
  }

  static Future<ToolResult> applyTheme(ToolContext ctx, ToolArgs a) async {
    final t = await HeadlessDocumentEditor.resolve(
      ctx.session,
      ctx.actor,
      _doc(a),
      min: Role.editor,
    );
    final theme = a.uuid('theme_uuid');
    final before = HeadlessDocumentEditor.metaValueJson(t.document, 'themeId');
    final after = jsonEncode(theme?.uuid);
    await DocumentService.updateMeta(
      ctx.session,
      ctx.actor,
      t.document.uuid,
      DocumentMetaPatch(field: 'themeId', valueJson: after),
      const Uuid().v7obj(),
    );
    final id = await HeadlessDocumentEditor.recordMetaChange(
      ctx,
      t,
      toolName: 'write.apply_theme',
      field: 'themeId',
      beforeValueJson: before,
      afterValueJson: after,
      label: 'Change theme',
    );
    return ToolResult({
      'document_uuid': t.item.uuid.uuid,
      'theme_uuid': theme?.uuid,
      'revision': t.document.headRevision,
      'change_id': id,
    }, text: 'Applied the theme · change_id $id');
  }
}
