import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:super_editor/super_editor.dart'
    show ClearComposingRegionRequest;
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, DriveItemView, UuidValue;
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../document/write_document_session.dart';
import '../editor/commands/editor_command_catalog.dart';
import '../editor/commands/write_editor_commands.dart';
import '../editor/controller/editor_types.dart';
import '../editor/controller/write_editor_controller.dart';
import '../editor/model/document_queries.dart';
import '../editor/model/embeds.dart';
import '../editor/model/link_url_policy.dart';
import '../editor/paste/editor_clipboard.dart';
import '../editor/view/editor_view_state.dart';
import '../export/export_service.dart';
import '../find_replace/find_controller.dart';
import '../images/image_services.dart';
import '../outline/outline_panel.dart';
import '../publish/submission_controller.dart';
import '../spellcheck/write_spellcheck.dart';
import '../themes/document_theme.dart';
import '../themes/write_fonts.dart';
import '../../l10n/write_l10n.dart';
import 'document_insights.dart';

/// Ids of the Write side panels (Write 05 §10).
abstract final class WritePanels {
  static const outline = 'outline';
  static const find = 'find';
}

/// Per-user view preferences of the editor screen (Write 05 §13.2): local,
/// not undoable, not synced. It is also the shell's [CommentsHost]: comments
/// and suggestions are shown in the margin, not in a side panel.
class WriteViewPrefs extends ChangeNotifier implements CommentsHost {
  WriteViewPrefs(this._store);

  final LocalStore? _store;

  bool _wordCount = false;
  bool _commentMargin = true;
  bool _selectionToolbar = true;

  /// The word count status bar ("Display word count while typing").
  bool get showWordCount => _wordCount;
  bool get showCommentMargin => _commentMargin;
  bool get showSelectionToolbar => _selectionToolbar;

  @override
  bool get isShown => _commentMargin;

  @override
  set isShown(bool value) {
    if (value != _commentMargin) showCommentMargin = value;
  }

  Future<void> load() async {
    final s = _store;
    if (s == null) return;
    Future<bool> b(String k, {bool fallback = true}) async {
      try {
        return (await s.read('write.view.$k')) as bool? ?? fallback;
      } catch (_) {
        return fallback;
      }
    }

    _wordCount = await b('wordCount', fallback: false);
    _commentMargin = await b('commentMargin');
    _selectionToolbar = await b('selectionToolbar');
    notifyListeners();
  }

  void _set(String key, bool value) {
    unawaited(_store?.write('write.view.$key', value));
    notifyListeners();
  }

  set showWordCount(bool v) => _set('wordCount', _wordCount = v);
  set showCommentMargin(bool v) => _set('commentMargin', _commentMargin = v);
  set showSelectionToolbar(bool v) =>
      _set('selectionToolbar', _selectionToolbar = v);
}

/// The open Write document as the shell sees it (suite 03, Write 04 §2.1):
/// the shell's `DocumentController`, built on the sync workstream's
/// [WriteDocumentSession] (content, sync, undo handlers, presence,
/// comments, metadata), plus the screen-level state: commands/clipboard,
/// find, outline, insights (word count), the document theme, view
/// preferences, images and exports.
///
/// `CommandContext.document` returns it; Write commands use
/// [WriteDocumentController.of].
class WriteDocumentController extends DocumentController {
  WriteDocumentController({
    required this.services,
    required this.session,
    required this.themes,
  }) : viewPrefs = WriteViewPrefs(services.userStore) {
    commands = WriteEditorCommands(
      editor,
      linkPolicy: LinkUrlPolicy(
        documentUuid: session.itemUuid.uuid,
        appHosts: {if (Uri.base.host.isNotEmpty) Uri.base.host},
      ),
    );
    clipboard = EditorClipboard(controller: editor, commands: commands);
    target = EditorCommandTarget(
      controller: editor,
      commands: commands,
      clipboard: clipboard,
    );
    insights = DocumentInsights(editor);
    find = FindController(
      editor,
      commands: commands,
      reveal: reveal,
      strings: () => writeL10nOf(services),
    );
    documentTheme = DocumentThemeController(themes);
    session.onThemeVersion = _onThemeVersion;
    session.addListener(_onSession);
    session.phase.addListener(_onSession);
    session.role.addListener(_onSession);
    session.meta.addListener(_onSession);
    editor.addListener(_onEditor);
    editor.view.addListener(notifyListeners);
    viewPrefs.addListener(notifyListeners);
    documentTheme.addListener(_onTheme);
    services.prefs.addListener(_onPrefs);
    unawaited(viewPrefs.load());
    _applyEditorPrefs();
    _onSession();
  }

  /// The active Write document of [ctx], if any.
  static WriteDocumentController? of(CommandContext ctx) {
    final d = ctx.document;
    return d is WriteDocumentController ? d : null;
  }

  final ShellServices services;
  final WriteDocumentSession session;
  final WriteThemeCatalog themes;
  final WriteViewPrefs viewPrefs;

  late final WriteEditorCommands commands;
  late final EditorClipboard clipboard;
  late final EditorCommandTarget target;
  late final DocumentInsights insights;
  late final FindController find;
  late final DocumentThemeController documentTheme;
  final OutlineViewState outlineView = OutlineViewState();

  /// Spellcheck of this document (Write 04 §28.2).
  late final WriteSpellcheck spellcheck = WriteSpellcheck(controller: editor);

  /// The document's submission to a publication (specs/18 §4); started by
  /// the screen once the document is open.
  late final SubmissionController submission = SubmissionController(
    services: services,
    itemUuid: session.itemUuid,
    revision: () => session.revision,
  );

  /// Scrolls a Delta offset into view (set by the screen's editor widget).
  void Function(int offset)? revealOffset;

  /// Moves keyboard focus to the formatting toolbar (set by the screen).
  VoidCallback? focusToolbar;

  /// Number of laid-out pages in Pages mode (set by the canvas).
  final ValueNotifier<int?> pageCount = ValueNotifier(null);

  @override
  UuidValue get itemUuid => session.itemUuid;
  WriteEditorController get editor => session.editor;
  EditorViewState get view => editor.view;

  @override
  Role get role => session.currentRole;

  @override
  bool get isLoaded =>
      session.isLoaded && session.phase.value == WriteSessionPhase.ready;

  DriveItemView? get item => session.item;

  @override
  String get title => session.title;

  @override
  DriveItemKind get kind => DriveItemKind.document;

  /// Viewers/commenters may copy/download/print only when the owner allows.
  bool get copyAllowed => role >= Role.editor || (item?.canDownload ?? true);

  /// Whether content edits are possible now (mode + role).
  bool get editable =>
      isLoaded &&
      editor.mode != EditorMode.viewing &&
      (role >= Role.editor ||
          (role >= Role.commenter && editor.mode == EditorMode.suggesting));

  /// Whether document settings (theme, page setup, language) may change.
  bool get canChangeSettings => isLoaded && role >= Role.editor;

  // ---- Meta ----

  WriteDocumentMeta get meta => session.meta.value;
  String? get themeUuid => meta.themeUuid;
  PageSetup get pageSetup => meta.pageSetup;
  String? get language => meta.language;
  String? get frontMatter => meta.frontMatter;

  /// The document's Markdown flavor (Write 11 §3.1).
  MarkdownFlavor get markdownFlavor => meta.markdownFlavor;

  /// Whether the document is in Wonky Markdown (its Wonky commands show).
  bool get isWonky => markdownFlavor == MarkdownFlavor.wonky;

  /// Changes a document property (undoable `write.meta` change).
  Future<void> setMeta(String field, Object? value, {required String label}) =>
      session.setMeta(
        field,
        value is PageSetup ? jsonEncode(value.toJson()) : jsonEncode(value),
        label: label,
      );

  /// The page margins of the theme (page setup `margins: theme`).
  PageMargins get themeMargins {
    final m = documentTheme.resolved(ThemeVariant.light).page.defaultMargins;
    return PageMargins(
      top: m.top,
      right: m.right,
      bottom: m.bottom,
      left: m.left,
    );
  }

  Object? _lastMeta;
  String? _lastUserTheme;
  String? _lastTitle;
  bool _metaApplied = false;

  void _onSession() {
    final meta = session.meta.value;
    final userTheme = defaultThemeUuidOf(services.prefs.writeDefaults);
    if (!_metaApplied ||
        !identical(meta, _lastMeta) ||
        userTheme != _lastUserTheme ||
        title != _lastTitle) {
      _metaApplied = true;
      _lastTitle = title;
      _lastMeta = meta;
      _lastUserTheme = userTheme;
      _applyMeta();
    }
    clipboard.copyAllowed = copyAllowed;
    _configureSpellcheck();
    notifyListeners();
  }

  /// Personal dictionary words (`writeDefaults.personalDictionary`).
  List<String> get personalDictionary {
    final raw = services.prefs.writeDefaults['personalDictionary'];
    return raw is List
        ? [
            for (final w in raw)
              if (w is String) w,
          ]
        : const [];
  }

  void _configureSpellcheck() {
    final d = services.prefs.writeDefaults;
    spellcheck.configure(
      enabled: (d['spellcheck'] as bool? ?? true) && isLoaded,
      language: language,
      skipAllCaps: d['spellcheckIgnoreUppercase'] as bool? ?? true,
      personalWords: personalDictionary,
    );
  }

  void _onTheme() {
    _applyPageGeometry();
    notifyListeners();
  }

  /// A save of the document's theme (here or by someone else): refetch it.
  void _onThemeVersion(String valueJson) {
    try {
      final v = jsonDecode(valueJson);
      if (v is! Map || v['themeId'] is! String) return;
      unawaited(
        themes.refresh(
          v['themeId'] as String,
          version: (v['version'] as num?)?.toInt(),
          viaDocumentUuid: session.documentUuid?.uuid,
        ),
      );
    } on FormatException {
      // Ignore malformed notifications.
    }
  }

  void _applyMeta() {
    documentTheme.documentUuid = session.documentUuid?.uuid;
    documentTheme.themeUuid =
        themeUuid ?? _lastUserTheme ?? BuiltinThemes.wonkyDefault.uuid;
    _applyPageGeometry();
  }

  void _applyPageGeometry() {
    final setup = pageSetup;
    view.layout = setup.layout == PageLayoutMode.pages && !_mobileView
        ? LayoutMode.pages
        : LayoutMode.pageless;
    final i = item;
    view.pageSetup = editorPageSetupOf(
      setup,
      themeMarginsPt: themeMargins,
      tokens: {
        'title': title.isEmpty ? writeL10nOf(services).untitledDocument : title,
        if (i != null) 'author': i.owner.displayName,
        'date': HeaderFooterTokens.mediumDate(DateTime.now(), language ?? 'en'),
      },
    );
  }

  void _onPrefs() {
    _applyEditorPrefs();
    _onSession();
  }

  /// Editor behaviour preferences from `UserPreferences.writeDefaults`.
  void _applyEditorPrefs() {
    final d = services.prefs.writeDefaults;
    bool b(String k, bool fallback) => d[k] as bool? ?? fallback;
    editor.preferences = editor.preferences.copyWith(
      markdownShortcuts: b('markdownShortcuts', true),
      smartTypography: b('smartQuotes', true),
      autoPair: b('autoPairBrackets', true),
      autolink: b('autolink', true),
      copyPlainTextAsMarkdown: b('copyAsMarkdown', true),
    );
    final sel = d['selectionToolbar'];
    if (sel is bool && sel != viewPrefs.showSelectionToolbar) {
      viewPrefs.showSelectionToolbar = sel;
    }
  }

  DeltaSelection? _lastSelection;
  EditorMode? _lastMode;

  void _onEditor() {
    final s = editor.selection;
    if (s != _lastSelection || editor.mode != _lastMode) {
      _lastSelection = s;
      _lastMode = editor.mode;
      services.registry.notifyStateChanged();
    }
    notifyListeners();
  }

  // ---- Downloads and print (File menu, `shell.file.*`) ----

  @override
  List<DownloadFormat> get downloadFormats => [
    for (final f in WriteDownloadFormat.values)
      DownloadFormat(f.id, f.labelOf(writeL10nOf(services))),
  ];

  @override
  bool get canPrint => isLoaded && copyAllowed;

  /// `shell.file.download {format}`.
  @override
  Future<void> download(String format) async {
    final f = WriteDownloadFormat.tryParse(format);
    if (f == null) {
      services.toasts.error(writeL10nOf(services).screenUnknownFormat(format));
      return;
    }
    await downloadAs(f);
  }

  /// Opens the print preview (`/d/:uuid/print`).
  @override
  Future<void> print() async => services.router.go('/d/${itemUuid.uuid}/print');

  /// Exports and saves the document as [format] (web: browser download in
  /// the same tab; desktop: save dialog).
  Future<bool> downloadAs(
    WriteDownloadFormat format, {
    WriteExportOptions options = const WriteExportOptions(),
  }) async {
    final l = writeL10nOf(services);
    // Progress with *Cancel* (Write 07 §4.3): the export runs on this
    // isolate and gives the event loop turns, so both work (W-07).
    final cancel = CancellationToken();
    final progress = ValueNotifier<double?>(null);
    final toast = services.toasts.showProgress(
      l.screenPreparingExport(format.labelOf(l)),
      progress: progress,
      cancelLabel: l.commonCancel,
      onCancel: cancel.cancel,
    );
    try {
      final artifact = await exportAs(
        format,
        options: options,
        cancel: cancel,
        progress: (phase, value) {
          if (phase == ExportPhase.layout) progress.value = value;
        },
      );
      services.toasts.hide(toast);
      final saved = await saveArtifact(artifact, l: l);
      if (saved) {
        services.toasts.show(
          l.screenExported(artifact.fileName),
          description: artifact.warnings.isEmpty
              ? null
              : artifact.warnings.map((w) => w.message).take(5).join('\n'),
        );
      }
      return saved;
    } on ExportCancelledException {
      services.toasts.hide(toast);
      return false;
    } catch (e) {
      services.toasts.hide(toast);
      services.toasts.error(l.screenExportFailed, description: '$e');
      return false;
    }
  }

  /// The snapshot exporters work on.
  ExportSource exportSource() {
    final i = item;
    return ExportSource(
      documentUuid: itemUuid.uuid,
      delta: editor.delta,
      title: title.isEmpty ? writeL10nOf(services).untitledDocument : title,
      theme: documentTheme.option.data,
      pageSetup: pageSetup,
      revision: session.revision,
      authorName: i?.owner.displayName,
      language: language,
      frontMatter: frontMatter,
      description: i?.description,
      createdAt: i?.createdAt,
      modifiedAt: i?.modifiedAt,
      markdownFlavor: markdownFlavor,
    );
  }

  /// Exports the current document (client side, Write 07 §4.3).
  Future<ExportArtifact> exportAs(
    WriteDownloadFormat format, {
    WriteExportOptions options = const WriteExportOptions(),
    CancellationToken? cancel,
    ExportProgressSink? progress,
  }) {
    final resolver = imageResolverFor(services, itemUuid.uuid);
    final exporter = WriteExporter(
      images: resolver,
      fonts: fonts,
      origin: Uri.base.hasAuthority ? Uri.base.origin : '',
    );
    return exporter
        .export(
          exportSource(),
          format,
          options: options,
          cancel: cancel,
          progress: progress,
        )
        .whenComplete(resolver.dispose);
  }

  /// Shared PDF font provider (bundled TTFs).
  static final fonts = AssetFontProvider();

  // ---- Helpers for commands and widgets ----

  /// Image services (uploads, signed URLs) of this document.
  late final WriteImageServices images = WriteImageServices(
    files: services.repositories.files,
    documentUuid: itemUuid,
    // Drive 03 §6.3: the *Out of storage* dialog (own or owner variant).
    onQuotaExceeded: (e) =>
        services.quotaErrors.present(e, reason: QuotaReasons.image),
  );

  // ---- DocumentController contract ----

  /// Write undo entries are only valid against the live document.
  @override
  bool get persistUndo => false;

  @override
  List<UndoHandler<UndoEntry>> get undoHandlers => session.undoHandlers;

  @override
  SelectionSnapshot? captureSelection() {
    final s = editor.selection;
    if (s == null) return null;
    return SelectionSnapshot('write.editor', {
      'base': s.anchor,
      'extent': s.head,
    });
  }

  @override
  void restoreSelection(SelectionSnapshot selection) {
    if (!session.shouldRestoreSelection()) return;
    if (selection.domain != 'write.editor') return;
    final base = selection.data['base'];
    final extent = selection.data['extent'];
    if (base is! int || extent is! int) return;
    editor.select(DeltaSelection(base, extent));
    reveal(extent);
  }

  @override
  String? get selectionSummary {
    final s = insights.selectionStats;
    if (s == null) return null;
    return writeL10nOf(services).screenWordsSelected(s.words);
  }

  @override
  bool get canCut => clipboard.canCopy && editable;

  @override
  bool get canCopy => clipboard.canCopy;

  @override
  bool get canPaste => editable;

  @override
  bool get canSelectAll => isLoaded;

  @override
  Future<void> cut() => clipboard.cut();

  @override
  Future<void> copy() => clipboard.copy();

  @override
  Future<void> paste({bool plainText = false}) =>
      clipboard.paste(plainOnly: plainText);

  @override
  void selectAll() => commands.selectAll();

  @override
  Future<void> beforeUndo() async {
    if (editor.composer.composingRegion.value != null) {
      editor.editor.execute([const ClearComposingRegionRequest()]);
    }
  }

  @override
  String get mode => editor.mode.name;

  @override
  double get zoom => view.zoom;

  @override
  void setZoom(double zoom) => view.zoom = zoom;

  @override
  ValueListenable<SyncStatus> get syncStatus => session.syncStatus;

  @override
  Future<void> retrySync() => session.retry();

  @override
  CommentAnchorProvider? get commentAnchors => session.commentAnchors;

  @override
  void revealParticipant(String sessionId, {int? userId}) {
    if (userId != null && session.presence.revealUser(userId)) return;
    session.revealParticipant(sessionId);
  }

  @override
  void onRoleChanged(Role role) => session.onRoleChanged(role);

  @override
  Map<String, Object?> describeState() {
    final s = editor.selection;
    return {
      'mode': editor.mode.name,
      'layout': view.layout.name,
      'zoom': (view.zoom * 100).round(),
      'role': role.name,
      'word_count': insights.stats.words,
      'page_count': pageCount.value,
      if (s != null) 'selection': {'anchor': s.anchor, 'head': s.head},
      if (insights.currentHeading != null)
        'current_heading': insights.outline[insights.currentHeading!].text,
      if (find.isActive)
        'find': {
          'query': find.query,
          'count': find.matches.length,
          'active': find.current,
        },
      'revision': session.revision,
      'pending_uploads': images.pendingUploads.value,
    };
  }

  /// Focuses the document surface.
  @override
  void focusEditor() => editor.focusNode.requestFocus();

  /// The mobile layout shows the document in Viewing, always Pageless and
  /// without text selection (suite 02 §6.1, T-1). It is layout, not a change
  /// of the document: the page setup is unchanged and widening the window
  /// restores it.
  @override
  void setReadOnlyView(bool readOnly) {
    session.setReadOnlyView(readOnly);
    editor.selectable = !readOnly;
    if (readOnly == _mobileView) return;
    _mobileView = readOnly;
    _applyPageGeometry();
  }

  bool _mobileView = false;

  /// Scrolls [offset] into view.
  void reveal(int offset) => revealOffset?.call(offset);

  /// The text of the current selection (single line), for find prefill.
  String? get selectedText {
    final s = editor.selection;
    if (s == null || s.isCollapsed) return null;
    final text = PlainTextRenderer.render(
      editor.mirror.slice(s.start, s.end),
    ).trim();
    return text.isEmpty || text.contains('\n') ? null : text;
  }

  /// Navigates to the outline entry [index] and focuses the editor.
  bool goToHeading(int index) {
    final outline = insights.outline;
    if (index < 0 || index >= outline.length) return false;
    final e = outline[index];
    editor.select(DeltaSelection.collapsed(e.deltaOffset));
    focusEditor();
    reveal(e.deltaOffset);
    return true;
  }

  /// The block [nodeId], or the block at the selection start.
  BlockRef? block([String? nodeId]) {
    if (nodeId != null) return editor.mirror.blockOf(nodeId);
    final s = editor.selection;
    if (s == null) return null;
    return editor.mirror.blockAtOffset(s.start);
  }

  /// The embed data of the [type] embed at [nodeId] / the selection.
  Map<String, dynamic>? embedData(String type, [String? nodeId]) {
    final b = block(nodeId);
    if (b == null || EmbedNodes.embedTypeOf(b.node) != type) return null;
    return EmbedNodes.embedDataOf(b.node);
  }

  /// The caret block is an image / table / code block.
  bool get onImage => embedData('image') != null;
  bool get inTable => embedData('table') != null;
  bool get inCode => block()?.isCode ?? false;

  /// Global rect of the text at Delta [offset] (popover anchors).
  Rect? globalRectForOffset(int offset) {
    final layout = editor.documentLayout;
    final position = editor.mirror.positionAt(offset);
    if (layout == null || position == null) return null;
    final rect = layout.getRectForPosition(position);
    if (rect == null) return null;
    final topLeft = layout.getGlobalOffsetFromDocumentOffset(rect.topLeft);
    return topLeft & rect.size;
  }

  /// Global rect around the selection.
  Rect? selectionRect() {
    final s = editor.selection;
    if (s == null) return null;
    final a = globalRectForOffset(s.start);
    if (a == null) return null;
    final b = s.isCollapsed ? null : globalRectForOffset(s.end);
    return b == null ? a : a.expandToInclude(b);
  }

  @override
  void dispose() {
    session.removeListener(_onSession);
    session.phase.removeListener(_onSession);
    session.role.removeListener(_onSession);
    session.meta.removeListener(_onSession);
    editor.removeListener(_onEditor);
    editor.view.removeListener(notifyListeners);
    services.prefs.removeListener(_onPrefs);
    spellcheck.dispose();
    submission.dispose();
    documentTheme.removeListener(_onTheme);
    images.dispose();
    viewPrefs.dispose();
    documentTheme.dispose();
    find.dispose();
    insights.dispose();
    outlineView.dispose();
    pageCount.dispose();
    super.dispose();
  }
}

/// The editor's page geometry (96 dpi logical px) for a page setup.
EditorPageSetup editorPageSetupOf(
  PageSetup setup, {
  PageMargins themeMarginsPt = const PageMargins.all(72),
  Map<String, String> tokens = const {},
}) {
  const px = 96 / 72;
  final m = setup.marginsOr(themeMarginsPt);
  String hf(HeaderFooterSpec s) {
    if (!s.enabled) return '';
    var text = [
      s.left,
      s.center,
      s.right,
    ].where((t) => t.isNotEmpty).join('   ');
    // {page} / {pages} are expanded per page by the editor's page chrome.
    tokens.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }

  return EditorPageSetup(
    size: Size(setup.pageWidthPt * px, setup.pageHeightPt * px),
    margins: EdgeInsets.fromLTRB(
      m.left * px,
      m.top * px,
      m.right * px,
      m.bottom * px,
    ),
    headerText: hf(setup.header),
    footerText: hf(setup.footer),
  );
}
