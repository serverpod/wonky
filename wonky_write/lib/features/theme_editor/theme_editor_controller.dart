import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart' show UndoService, UndoStackKey;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../../l10n/write_l10n.dart';
import '../themes/document_theme.dart';
import '../themes/theme_repository.dart';
import 'theme_editor_model.dart';
import 'theme_library.dart';
import 'theme_undo.dart';

/// Where the preview's content comes from (Write 06 §10.2).
enum ThemePreviewSource { sample, document }

/// Pages or Pageless preview.
enum ThemePreviewLayout { pages, pageless }

/// The document the theme editor was opened from (`?doc=`).
@immutable
class ThemeEditorDocument {
  const ThemeEditorDocument({
    required this.itemUuid,
    required this.documentUuid,
    required this.title,
    required this.delta,
    required this.themeUuid,
    required this.canEdit,
  });

  /// Drive item uuid (`/d/<itemUuid>`).
  final String itemUuid;

  /// Document (content) uuid.
  final String documentUuid;
  final String title;
  final Delta delta;

  /// The document's theme (null = the viewer's default).
  final String? themeUuid;

  /// Whether the user may change the document's theme (Editor+).
  final bool canEdit;

  ThemeEditorDocument withTheme(String? uuid) => ThemeEditorDocument(
    itemUuid: itemUuid,
    documentUuid: documentUuid,
    title: title,
    delta: delta,
    themeUuid: uuid,
    canEdit: canEdit,
  );
}

/// Result of a theme editor operation.
@immutable
class ThemeEditResult {
  const ThemeEditResult.ok([this.data]) : error = null;
  const ThemeEditResult.failed(String this.error) : data = null;

  final String? error;
  final Object? data;

  bool get isOk => error == null;
}

/// The theme editor state (Write 06 §10.4): the saved theme, the draft
/// being edited (every change is a `write.theme` draft undo step on the
/// stack `theme-draft:<uuid>`), the selection in the element tree, the
/// preview settings and the save / conflict state.
class ThemeEditorController extends ChangeNotifier implements ThemeDraftHost {
  ThemeEditorController({
    required this.themeUuid,
    required this.catalog,
    required this.undo,
    this.repository,
    this.myUserUuid,
    this.loadDocument,
    this.documentItemUuid,
    this.setDefault,
    this.defaultThemeUuid,
    WriteLocalizations Function()? strings,
    UuidV7Generator? ids,
  }) : _ids = ids ?? UuidV7Generator.instance,
       _strings = strings ?? _english;

  static WriteLocalizations _english() => writeL10nEnglish;

  /// The UI strings (undo labels, error messages) in the app's locale.
  final WriteLocalizations Function() _strings;
  WriteLocalizations get _l => _strings();

  /// Library operations (null without a server connection).
  late final ThemeLibrary? library = repository == null
      ? null
      : ThemeLibrary(
          repository: repository!,
          catalog: catalog,
          undo: undo,
          ids: _ids,
          strings: _strings,
        );

  @override
  final String themeUuid;
  final WriteThemeCatalog catalog;
  final UndoService undo;
  final ThemeRepository? repository;

  /// The signed-in user (decides whether a theme is editable).
  final String? myUserUuid;

  /// Loads the `?doc=` document (preview "This document", apply).
  final Future<ThemeEditorDocument?> Function(String itemUuid)? loadDocument;
  final String? documentItemUuid;

  /// Stores the user's default theme (`writeDefaults.defaultThemeId`).
  final Future<void> Function(String uuid)? setDefault;

  /// The user's current default theme.
  final String? Function()? defaultThemeUuid;
  final UuidV7Generator _ids;

  /// The editor that is open now (commands, MCP, undo of draft steps).
  static final ValueNotifier<ThemeEditorController?> active = ValueNotifier(
    null,
  );

  UndoStackKey get draftStack => UndoStackKey(themeDraftStackKey(themeUuid));

  // ---------------------------------------------------------------- state

  bool _loading = true;
  Object? _loadError;
  ThemeRecord? _record;
  ThemeOption? _builtin;
  ThemeJson _savedJson = const {};
  ThemeJson _draftJson = const {};
  WriteThemeData? _draft;
  ThemeEditorDocument? _document;
  ThemeNode _selected = ThemeNode.element(ThemeElement.body);
  ThemeVariant _variant = ThemeVariant.light;
  ThemePreviewLayout _layout = ThemePreviewLayout.pageless;
  ThemePreviewSource _source = ThemePreviewSource.sample;
  double _zoom = 1;
  bool _saving = false;
  ThemeConflict? _conflict;
  int? _usage;
  String? _lastError;
  bool _disposed = false;

  bool get loading => _loading;
  Object? get loadError => _loadError;

  /// The server record (user and foreign themes; null for built-ins).
  ThemeRecord? get record => _record;

  bool get isBuiltin => _builtin != null;

  /// Owned by the user: editable. Built-ins and collaborators' themes are
  /// read-only (Write 06 §10.4).
  bool get isMine =>
      _record != null &&
      !_record!.isBuiltin &&
      (myUserUuid == null ||
          _record!.ownerUuid == null ||
          _record!.ownerUuid == myUserUuid);

  bool get readOnly => !isMine || (_record?.isDeleted ?? false);

  bool get isDeleted => _record?.isDeleted ?? false;

  String get name => _record?.name ?? _builtin?.name ?? draft.name;

  int get version => _record?.version ?? _builtin?.version ?? 1;

  /// The draft theme (last valid state).
  WriteThemeData get draft => _draft ?? BuiltinThemes.wonkyDefault.theme;

  /// The draft as JSON (`ThemePropertyPath` paths).
  ThemeJson get draftJson => _draftJson;

  /// The saved theme.
  WriteThemeData get saved => WriteThemeData.fromJson(_savedJson);

  bool get dirty =>
      _draft != null &&
      canonicalJsonEncode(_draftJson) != canonicalJsonEncode(_savedJson);

  bool get saving => _saving;
  ThemeConflict? get conflict => _conflict;

  /// Documents of the user using this theme (shown next to Save).
  int? get usage => _usage;

  String? get lastError => _lastError;

  ThemeEditorDocument? get document => _document;
  ThemeNode get selected => _selected;
  ThemeVariant get variant => _variant;
  ThemePreviewLayout get layout => _layout;
  ThemePreviewSource get source => _source;
  double get zoom => _zoom;

  /// The resolved draft for the preview variant.
  ResolvedWriteTheme resolved([ThemeVariant? v]) =>
      ThemeResolver.instance.resolve(draft, v ?? _variant);

  List<ContrastResult>? _contrast;
  String? _contrastHash;

  /// Failing contrast pairs of the draft in both variants (§10.6).
  List<ContrastResult> get contrastWarnings {
    final hash = draft.contentHash;
    if (_contrastHash != hash) {
      _contrastHash = hash;
      _contrast = ContrastChecker().warnings(draft);
    }
    return _contrast!;
  }

  /// Contrast warnings that belong to [node].
  List<ContrastResult> warningsOf(ThemeNode node) => [
    for (final w in contrastWarnings)
      if (nodeOfPair(w.pairId) == node) w,
  ];

  /// Whether [node] has overrides in the draft (tree dot).
  bool hasOverrides(ThemeNode node) {
    final j = _draftJson;
    Map<Object?, Object?>? m(Object? v) => v is Map ? v : null;
    final dark = m(j['dark']);
    switch (node.kind) {
      case ThemeNodeKind.element:
        final k = node.element!.name;
        return (m(m(j['elements'])?[k])?.isNotEmpty ?? false) ||
            (m(m(dark?['elements'])?[k])?.isNotEmpty ?? false);
      case ThemeNodeKind.page:
        return m(j['page'])?.keys.any((k) => k != 'headerFooter') ?? false;
      case ThemeNodeKind.headerFooter:
        return (m(m(j['page'])?['headerFooter'])?.isNotEmpty ?? false) ||
            (m(m(j['elements'])?['header'])?.isNotEmpty ?? false) ||
            (m(m(j['elements'])?['footer'])?.isNotEmpty ?? false);
      case ThemeNodeKind.syntax:
        return (m(j['syntax'])?.isNotEmpty ?? false) || dark?['syntax'] != null;
      case ThemeNodeKind.advanced:
        return m(j['overlays'])?.isNotEmpty ?? false;
      case ThemeNodeKind.palette:
        return m(dark?['palette'])?.isNotEmpty ?? false;
      case ThemeNodeKind.fonts || ThemeNodeKind.general:
        return false;
    }
  }

  // ------------------------------------------------------------- loading

  /// Loads the theme (and the `?doc=` document).
  Future<void> load() async {
    _loading = true;
    _loadError = null;
    _notify();
    try {
      final builtin = catalog.lookup(themeUuid);
      if (builtin != null && builtin.isBuiltin) {
        _builtin = builtin;
        _setSaved(builtin.data.toJson());
      } else {
        final repo = repository;
        if (repo == null) throw StateError('No server connection');
        final doc = await _loadDocument();
        final r = await repo.get(themeUuid, viaDocumentUuid: doc?.documentUuid);
        _record = r;
        _setSaved(_decode(r.json));
        if (isMine) unawaited(_loadUsage());
      }
      if (_document == null) await _loadDocument();
      _loading = false;
    } catch (e) {
      _loadError = e;
      _loading = false;
    }
    _notify();
  }

  Future<ThemeEditorDocument?> _loadDocument() async {
    final item = documentItemUuid;
    final loader = loadDocument;
    if (item == null || loader == null || _document != null) return _document;
    try {
      _document = await loader(item);
    } catch (e) {
      debugPrint('Loading the document for the theme preview failed: $e');
    }
    return _document;
  }

  Future<void> _loadUsage() async {
    try {
      _usage = await repository?.usage(themeUuid);
      _notify();
    } catch (_) {}
  }

  static ThemeJson _decode(String json) =>
      Map<String, Object?>.from(jsonDecode(json) as Map);

  void _setSaved(ThemeJson json) {
    final data = WriteThemeData.fromJson(json);
    _savedJson = data.toJson();
    _draftJson = _savedJson;
    _draft = data;
  }

  // ------------------------------------------------------- draft editing

  /// Applies [json] as the new draft (validated). Returns the blocking
  /// errors (the draft is unchanged then).
  List<ThemeIssue> _validate(ThemeJson json) =>
      const WriteThemeValidator().validate(json).errors;

  /// Sets [path] to [value] (`write.theme.setProperty`; null resets to
  /// inherit). [variant] qualifies `palette.*`, `elements.*`, `syntax.*`
  /// paths for the dark variant. [coalesceKey] merges consecutive steps of
  /// one gesture (slider drags, stepper repeats).
  ThemeEditResult setProperty(
    String path,
    Object? value, {
    ThemeVariant? variant,
    String? coalesceKey,
    String? label,
  }) {
    if (readOnly) return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    ThemeJson next;
    try {
      next = ThemePropertyPath.set(_draftJson, path, value, variant: variant);
    } on ThemePathException catch (e) {
      return ThemeEditResult.failed(e.message);
    }
    if (path == 'dark.mode' && value == DarkMode.explicit.json) {
      // An explicit dark palette must be complete: start from the derived
      // one (overrides kept), Write 06 §4.
      next = _withCompleteDarkPalette(next);
    }
    return _commit(
      next,
      label:
          label ??
          _l.themeEditorUndoChange(propLabel(_l, path.split('.').last)),
      coalesceKey: coalesceKey,
    );
  }

  ThemeJson _withCompleteDarkPalette(ThemeJson json) {
    final out = jsonDecode(jsonEncode(json)) as Map<String, Object?>;
    final dark = (out['dark'] as Map?)?.cast<String, Object?>() ?? {};
    final palette = (dark['palette'] as Map?)?.cast<String, Object?>() ?? {};
    final derived = const DarkPaletteDeriver().derive(draft.palette);
    for (final k in PaletteKey.values) {
      if (k.isCustom) continue;
      if (palette[k.name] == null && derived[k] != null) {
        palette[k.name] = argbToHex(
          derived[k]!,
          withAlpha: derived[k]! >>> 24 != 255,
        );
      }
    }
    dark['palette'] = palette;
    out['dark'] = dark;
    return out;
  }

  ThemeEditResult _commit(
    ThemeJson next, {
    required String label,
    String? coalesceKey,
  }) {
    final errors = _validate(next);
    if (errors.isNotEmpty) {
      _lastError = errors.first.message;
      _notify();
      return ThemeEditResult.failed(errors.first.message);
    }
    final data = WriteThemeData.fromJson(next);
    final before = canonicalJsonEncode(_draftJson);
    final after = data.canonicalJson;
    if (before == after) return const ThemeEditResult.ok();
    _draftJson = data.toJson();
    _draft = data;
    _lastError = null;
    undo.push(
      UndoStep(
        id: _ids.nextString(),
        label: label,
        entries: [
          ThemeDraftUndoEntry(
            themeUuid: themeUuid,
            beforeJson: before,
            afterJson: after,
          ),
        ],
        coalesceKey: coalesceKey == null ? null : 'theme:$coalesceKey',
      ),
      stack: draftStack,
    );
    _notify();
    return const ThemeEditResult.ok();
  }

  /// Removes every override of [node] (`write.theme.resetElement`).
  ThemeEditResult resetElement(ThemeNode node) {
    if (readOnly) return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    final next = jsonDecode(jsonEncode(_draftJson)) as Map<String, Object?>;
    void drop(Object? section, String key) {
      if (section is Map) section.remove(key);
    }

    final dark = next['dark'];
    switch (node.kind) {
      case ThemeNodeKind.element:
        drop(next['elements'], node.element!.name);
        if (dark is Map) drop(dark['elements'], node.element!.name);
      case ThemeNodeKind.page:
        final page = next['page'];
        if (page is Map) page.removeWhere((k, _) => k != 'headerFooter');
      case ThemeNodeKind.headerFooter:
        drop(next['page'], 'headerFooter');
        drop(next['elements'], 'header');
        drop(next['elements'], 'footer');
      case ThemeNodeKind.syntax:
        next['syntax'] = <String, Object?>{};
        if (dark is Map) dark['syntax'] = null;
      case ThemeNodeKind.advanced:
        next['overlays'] = <String, Object?>{};
      case ThemeNodeKind.palette:
        if (dark is Map) dark['palette'] = <String, Object?>{};
      case ThemeNodeKind.fonts:
        next['fonts'] = const ThemeFonts().toJson();
      case ThemeNodeKind.general:
        return const ThemeEditResult.ok();
    }
    return _commit(next, label: _l.themeEditorUndoReset(node.label(_l)));
  }

  /// Fixes a failing contrast pair (`write.theme.fixContrast`): the
  /// foreground lightness changes minimally (one draft step).
  ThemeEditResult fixContrast(String pairId, ThemeVariant variant) {
    if (readOnly) return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    final fix = ContrastChecker().fix(draft, pairId, variant);
    if (fix == null) {
      return ThemeEditResult.failed(_l.themeEditorNothingToFix);
    }
    final next = ThemePropertyPath.set(_draftJson, fix.path, fix.value);
    return _commit(next, label: _l.cmdThemeFixContrast);
  }

  /// Replaces the draft with a revision's JSON (one draft step).
  ThemeEditResult loadRevision(ThemeRevision r) {
    if (readOnly) return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    return _commit(
      _decode(r.json),
      label: _l.themeEditorUndoRestoreVersion(r.version),
    );
  }

  /// Discards the draft (`write.theme.revert`).
  Future<void> revert() async {
    _draftJson = _savedJson;
    _draft = WriteThemeData.fromJson(_savedJson);
    _lastError = null;
    await _clearDraftStack();
    _notify();
  }

  Future<void> _clearDraftStack() async {
    final wasActive = undo.activeDocumentStack == draftStack;
    await undo.closeStack(draftStack, forget: true);
    if (wasActive) undo.setActiveDocument(draftStack);
  }

  @override
  void applyDraftJson(String json) {
    final data = WriteThemeData.fromJsonString(json);
    _draftJson = data.toJson();
    _draft = data;
    _notify();
  }

  @override
  void onLibraryChanged(ThemeRecord record) {
    final wasDirty = dirty;
    _record = record;
    if (!wasDirty) {
      _setSaved(_decode(record.json));
    } else {
      _savedJson = _decode(record.json);
    }
    _notify();
  }

  // ---------------------------------------------------------- selection

  void select(ThemeNode node) {
    if (node == _selected) return;
    _selected = node;
    _notify();
  }

  bool _variantChosen = false;

  /// Shows the preview in [v] (`write.theme.setPreviewVariant`); from then
  /// on the preview no longer follows the app theme.
  void setVariant(ThemeVariant v) {
    _variantChosen = true;
    if (v == _variant) return;
    _variant = v;
    _notify();
  }

  /// The app theme changed: the preview follows it until a variant was
  /// chosen explicitly.
  void followAppVariant(ThemeVariant v) {
    if (_variantChosen || v == _variant) return;
    _variant = v;
    _notify();
  }

  void setLayout(ThemePreviewLayout l) {
    if (l == _layout) return;
    _layout = l;
    _notify();
  }

  void setSource(ThemePreviewSource s) {
    if (s == _source) return;
    if (s == ThemePreviewSource.document && _document == null) return;
    _source = s;
    _notify();
  }

  void setZoom(double z) {
    final v = z.clamp(0.5, 2.0);
    if (v == _zoom) return;
    _zoom = v;
    _notify();
  }

  // ---------------------------------------------------------------- save

  /// Saves the draft (`write.theme.save`). On a [ThemeConflict] the
  /// conflict is kept in [conflict] and false is returned.
  Future<ThemeEditResult> save({bool overwrite = false}) async {
    final repo = repository;
    final r = _record;
    if (readOnly || r == null || repo == null) {
      return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    }
    if (!dirty && !overwrite) return const ThemeEditResult.ok();
    final expected = overwrite && _conflict != null
        ? _conflict!.serverVersion
        : r.version;
    final before = r.json;
    final after = draft.canonicalJson;
    _saving = true;
    _notify();
    try {
      final saved = await repo.update(themeUuid, after, expected);
      _conflict = null;
      _record = saved;
      _savedJson = _decode(saved.json);
      _saving = false;
      await _clearDraftStack();
      final option = ThemeOption.fromRecord(saved);
      if (option != null) catalog.put(option);
      undo.push(
        UndoStep(
          id: _ids.nextString(),
          label: _l.themeEditorUndoEdit(saved.name),
          entries: [
            ThemeLibraryUndoEntry(
              op: ThemeLibraryOp.saved,
              themeUuid: themeUuid,
              before: before,
              after: saved.json,
              version: saved.version,
            ),
          ],
        ),
        stack: UndoStackKey.shell,
      );
      _notify();
      return const ThemeEditResult.ok();
    } on ThemeConflict catch (c) {
      _conflict = c;
      _saving = false;
      _notify();
      return ThemeEditResult.failed(_l.themeEditorChangedElsewhere);
    } catch (e) {
      _saving = false;
      _lastError = '$e';
      _notify();
      return ThemeEditResult.failed(_l.themeEditorSavingFailedWith('$e'));
    }
  }

  /// Conflict resolution: take the server's version (discard the draft).
  Future<void> reloadTheirs() async {
    final c = _conflict;
    final r = _record;
    if (c == null || r == null) return;
    _record = r.copyWith(
      json: c.serverJson,
      version: c.serverVersion,
      name: c.serverName,
    );
    _conflict = null;
    _setSaved(_decode(c.serverJson));
    await _clearDraftStack();
    final option = ThemeOption.fromRecord(_record!);
    if (option != null) catalog.put(option);
    _notify();
  }

  /// Conflict resolution: save the draft over the server's version.
  Future<ThemeEditResult> overwrite() => save(overwrite: true);

  /// Conflict resolution: saves the draft as a new theme in the library.
  Future<ThemeRecord?> saveAsCopy({String? name}) async {
    final lib = library;
    if (lib == null) return null;
    final r = await lib.create(
      name ?? _l.themeLibraryCopyName(this.name),
      draft.toJson(),
      basedOnUuid: themeUuid,
    );
    _conflict = null;
    _notify();
    return r;
  }

  /// Copies this theme (or the unsaved draft) into the user's library
  /// (`write.theme.duplicate`).
  Future<ThemeRecord?> duplicate({String? name}) async => library?.duplicate(
    themeUuid,
    name: name,
    draft: dirty ? draft.toJson() : null,
    viaDocumentUuid: _document?.documentUuid,
  );

  /// Renames this theme (`write.theme.rename`).
  Future<ThemeEditResult> rename(String newName) async {
    final lib = library;
    final r = _record;
    if (readOnly || lib == null || r == null) {
      return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    }
    final clean = newName.trim();
    if (clean.isEmpty || clean.length > 80) {
      return ThemeEditResult.failed(_l.themeEditorNameLength);
    }
    if (clean == r.name) return const ThemeEditResult.ok();
    try {
      _record = await lib.rename(r, clean);
      _notify();
      return const ThemeEditResult.ok();
    } on ThemeConflict catch (c) {
      _conflict = c;
      _notify();
      return ThemeEditResult.failed(_l.themeEditorChangedElsewhere);
    }
  }

  /// Soft-deletes this theme (`write.theme.delete`).
  Future<ThemeEditResult> delete() async {
    final lib = library;
    if (readOnly || lib == null) {
      return ThemeEditResult.failed(_l.themeEditorReadOnlyMessage);
    }
    _record = await lib.delete(themeUuid);
    _notify();
    return const ThemeEditResult.ok();
  }

  /// Restores this soft-deleted theme (`write.theme.restore`).
  Future<ThemeEditResult> restore() async {
    final lib = library;
    if (!isMine || lib == null) {
      return ThemeEditResult.failed(_l.themeEditorOnlyOwnerRestore);
    }
    _record = await lib.restore(themeUuid);
    _notify();
    return const ThemeEditResult.ok();
  }

  /// Revision history of this theme (owner only).
  Future<List<ThemeRevision>> revisions() async =>
      isMine ? await repository!.listRevisions(themeUuid) : const [];

  /// Assigns this theme to the `?doc=` document (`Apply to document`).
  Future<ThemeEditResult> applyToDocument() async {
    final doc = _document;
    final repo = repository;
    if (doc == null || repo == null) {
      return ThemeEditResult.failed(_l.themeEditorNoDocument);
    }
    if (!doc.canEdit) {
      return ThemeEditResult.failed(_l.themeEditorNeedEditAccess);
    }
    if (doc.themeUuid == themeUuid) return const ThemeEditResult.ok();
    await repo.assignToDocument(doc.documentUuid, themeUuid);
    undo.push(
      UndoStep(
        id: _ids.nextString(),
        label: _l.themeEditorUndoChangeTheme,
        entries: [
          ThemeLibraryUndoEntry(
            op: ThemeLibraryOp.assigned,
            themeUuid: themeUuid,
            target: doc.documentUuid,
            // Running the entry assigns `before` (the previous theme).
            before: doc.themeUuid,
            after: themeUuid,
          ),
        ],
      ),
      stack: UndoStackKey.shell,
    );
    _document = doc.withTheme(themeUuid);
    _notify();
    return const ThemeEditResult.ok();
  }

  /// Whether this theme is the user's default.
  bool get isDefault => (defaultThemeUuid?.call()) == themeUuid;

  /// Makes this theme the user's default (`write.theme.setAsDefault`).
  Future<void> makeDefault() async {
    await setDefault?.call(themeUuid);
    _notify();
  }

  // ---------------------------------------------------------- lifecycle

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (active.value == this) active.value = null;
    super.dispose();
  }
}
