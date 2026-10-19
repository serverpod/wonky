import 'dart:async';
import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show presenceColorIndex;
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaUtils, DiffAttr, WonkyAttr;

import '../../l10n/write_l10n.dart';
import '../document/write_document_api.dart';
import '../editor/controller/editor_types.dart';
import '../editor/controller/write_editor_controller.dart';
import '../document/reveal.dart';
import '../editor/styles/editor_theme.dart';
import '../editor/ui/wonky_editor.dart';

/// Renders Write versions in the shell's full-screen history route
/// (Write 08 §4.4): the selected version read-only, with per-author change
/// highlighting (insertions in the author's color, deletions struck,
/// formatting dotted) when *Show changes* is on, an author legend, change
/// navigation (↑ ↓) and *Make a copy*.
///
/// Set it as `WriteAppConfig.versionRenderer`. [themeOf] provides the
/// document theme (defaults to Wonky Default for the brightness).
class WriteVersionRenderer extends VersionRenderer {
  WriteVersionRenderer({this.api, this.themeOf});

  /// Server calls (defaults to the shell's client).
  final WriteDocumentApi? api;

  /// The document theme for [itemUuid].
  final EditorTheme? Function(BuildContext context, UuidValue itemUuid)?
  themeOf;

  @override
  Widget build(
    BuildContext context, {
    required UuidValue itemUuid,
    required ItemVersionView version,
    ItemVersionView? previous,
    required bool showChanges,
  }) {
    final services = ShellScope.of(context);
    return WriteVersionView(
      key: ValueKey<String>('write.history.view.${itemUuid.uuid}'),
      services: services,
      api: api ?? ServerWriteDocumentApi(services.client!),
      itemUuid: itemUuid,
      version: version,
      previous: previous,
      showChanges: showChanges,
      theme: themeOf?.call(context, itemUuid),
    );
  }
}

/// One author of a version diff, for the legend.
@immutable
class VersionAuthor {
  const VersionAuthor({
    required this.key,
    required this.name,
    required this.inserted,
    required this.deleted,
    required this.formatted,
  });

  /// User uuid (or `''` for "Multiple people").
  final String key;
  final String name;
  final int inserted;
  final int deleted;
  final int formatted;
}

/// The content shown for a version: the document (with `sug_*` marks for
/// the attributed changes when diffing) and the change regions.
@immutable
class VersionContent {
  const VersionContent(this.delta, this.changes, this.authors);

  final Delta delta;

  /// Contiguous changed ranges `(start, end)` in document order.
  final List<(int, int)> changes;
  final List<VersionAuthor> authors;

  /// Converts a `WriteDiffView` delta (`diff_ins` / `diff_del` /
  /// `diff_fmt` overlays) into suggestion marks, which the editor renders in
  /// the author's presence color (insertions underlined, deletions struck,
  /// formatting dotted). Authors in [hidden] are rendered plain.
  static VersionContent fromDiff(
    WriteDiffView diff, {
    Set<String> hidden = const {},
  }) {
    final source = Delta.fromJson(jsonDecode(diff.deltaJson) as List);
    final out = Delta();
    final changes = <(int, int)>[];
    var offset = 0;
    for (final op in source.operations) {
      final len = op.length!;
      final attrs = <String, dynamic>{...?op.attributes};
      String? kind;
      Map<String, dynamic>? mark;
      for (final (key, t) in [
        (DiffAttr.ins, 'ins'),
        (DiffAttr.del, 'del'),
        (DiffAttr.fmt, 'fmt'),
      ]) {
        final v = attrs.remove(key);
        if (v is Map && kind == null) {
          kind = t;
          mark = v.cast<String, dynamic>();
        }
      }
      if (kind != null) {
        final by = (mark!['by'] as String?) ?? '';
        if (!hidden.contains(by)) {
          final id = 'h${by.hashCode.toUnsigned(32).toRadixString(16)}$kind';
          attrs[WonkyAttr.suggestionKey(id)] = {
            't': kind,
            'by': by.isEmpty ? 'multiple' : by,
            'at': 0,
            if (kind == 'fmt')
              'before': mark['before'] ?? const <String, Object?>{},
          };
        }
        if (changes.isNotEmpty && changes.last.$2 == offset) {
          changes[changes.length - 1] = (changes.last.$1, offset + len);
        } else {
          changes.add((offset, offset + len));
        }
      }
      out.push(Operation.insert(op.data, attrs.isEmpty ? null : attrs));
      offset += len;
    }
    return VersionContent(DeltaUtils.canonical(out), changes, [
      for (final a in diff.authors)
        VersionAuthor(
          key: a.userUuid?.uuid ?? '',
          name: a.name,
          inserted: a.inserted,
          deleted: a.deleted,
          formatted: a.formatted,
        ),
    ]);
  }
}

/// The left side of the history route for one version.
class WriteVersionView extends StatefulWidget {
  const WriteVersionView({
    super.key,
    required this.services,
    required this.api,
    required this.itemUuid,
    required this.version,
    required this.showChanges,
    this.previous,
    this.theme,
  });

  final ShellServices services;
  final WriteDocumentApi api;
  final UuidValue itemUuid;
  final ItemVersionView version;
  final ItemVersionView? previous;
  final bool showChanges;
  final EditorTheme? theme;

  @override
  State<WriteVersionView> createState() => WriteVersionViewState();
}

class WriteVersionViewState extends State<WriteVersionView> {
  final WriteEditorController _editor = WriteEditorController(
    mode: EditorMode.viewing,
  );
  final ScrollController _scroll = ScrollController();
  UuidValue? _documentUuid;
  DriveItemView? _item;
  WriteDiffView? _diff;
  VersionContent? _content;
  Object? _error;
  bool _loading = true;
  int _change = -1;
  final Set<String> _hidden = {};
  int _request = 0;

  /// The change regions of the shown version (tests, commands).
  List<(int, int)> get changes => _content?.changes ?? const [];

  /// The index of the current change (`-1` before navigating).
  int get currentChange => _change;

  @override
  void initState() {
    super.initState();
    _editor.view.suggestionPreview = SuggestionPreviewMode.show;
    unawaited(_load());
  }

  @override
  void didUpdateWidget(WriteVersionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version.id != widget.version.id ||
        oldWidget.previous?.id != widget.previous?.id ||
        oldWidget.showChanges != widget.showChanges) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _editor.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<UuidValue> _doc() async {
    final known = _documentUuid;
    if (known != null) return known;
    final item = await widget.api.getItem(widget.itemUuid);
    _item = item;
    final ref = item.contentRef;
    if (ref == null) {
      throw _LoadError(writeL10nOf(widget.services).historyNotADocument);
    }
    return _documentUuid = ref;
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await _doc();
      final rev = widget.version.revision;
      if (rev == null) {
        throw _LoadError(writeL10nOf(widget.services).historyNoRevision);
      }
      final from = widget.previous?.revision;
      VersionContent content;
      WriteDiffView? diff;
      if (widget.showChanges && from != null && from < rev) {
        diff = await widget.api.diff(doc, from, rev);
        content = VersionContent.fromDiff(diff, hidden: _hidden);
      } else {
        final v = await widget.api.getVersionDocument(doc, rev);
        content = VersionContent(
          Delta.fromJson(jsonDecode(v.deltaJson) as List),
          const [],
          const [],
        );
      }
      if (!mounted || request != _request) return;
      _editor.resetDocument(content.delta);
      setState(() {
        _diff = diff;
        _content = content;
        _loading = false;
        _change = -1;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _toggleAuthor(String key) {
    final diff = _diff;
    if (diff == null) return;
    setState(() {
      if (!_hidden.remove(key)) _hidden.add(key);
      final content = VersionContent.fromDiff(diff, hidden: _hidden);
      _content = content;
      _editor.resetDocument(content.delta);
    });
  }

  /// Moves to the next (or previous) change (`write.history.nextChange`).
  void goToChange({bool previous = false}) {
    final list = changes;
    if (list.isEmpty) return;
    setState(() {
      _change = previous
          ? (_change <= 0 ? list.length - 1 : _change - 1)
          : (_change + 1) % list.length;
    });
    final (start, end) = list[_change];
    _reveal(start, end);
  }

  void _reveal(int start, int end) => revealDocumentRange(
    _editor.documentLayout,
    _editor.mirror,
    start,
    end,
    margin: 64,
  );

  Future<void> makeCopy() async {
    final s = widget.services;
    final l = writeL10nOf(s);
    try {
      final doc = await _doc();
      final base = _item?.name ?? l.untitledDocument;
      final name = widget.version.name ?? base;
      final copy = await widget.api.copyVersion(
        doc,
        widget.version.id,
        l.historyCopyOf(name),
        parentUuid: _item?.parentUuid,
      );
      s.toasts.show(
        l.historyCopyCreated,
        description: copy.name,
        actionLabel: l.historyOpen,
        onAction: () => s.openItem(copy),
      );
    } catch (e) {
      s.toasts.error(l.historyCopyFailed, description: errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final err = _error;
    final content = _content;
    final editorTheme = widget.theme ?? EditorTheme.fallback(theme.brightness);
    final l = writeL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(context),
        Expanded(
          child: err != null
              ? WonkyEmptyState(
                  illustration: EmptyIllustration.error,
                  title: l.historyCouldNotLoad,
                  description: errorMessage(err),
                  actions: [
                    ShadButton.outline(
                      onPressed: _load,
                      child: Text(l.commonRetry),
                    ),
                  ],
                )
              : content == null
              ? const Center(child: ShadSpinner())
              : Stack(
                  children: [
                    WonkyEditor(
                      key: const ValueKey<String>('write.history.document'),
                      controller: _editor,
                      theme: editorTheme,
                      scrollController: _scroll,
                      documentTitle: widget.version.name ?? l.historyVersion,
                      hint: '',
                    ),
                    if (_loading)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: ShadSpinner(size: 16),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    final theme = ShadTheme.of(context);
    final content = _content;
    final authors = content?.authors ?? const <VersionAuthor>[];
    final n = changes.length;
    final l = writeL10n(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final a in authors)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _AuthorChip(
                        author: a,
                        hidden: _hidden.contains(a.key),
                        onTap: () => _toggleAuthor(a.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.showChanges && content != null) ...[
            Text(
              n == 0
                  ? l.historyNoChanges
                  : (_change < 0
                        ? l.historyChangeCount(n)
                        : l.historyChangeOf(_change + 1, n)),
              key: const ValueKey<String>('write.history.changeCount'),
              style: theme.textTheme.muted,
            ),
            ShadIconButton.ghost(
              key: const ValueKey<String>('write.history.previousChange'),
              width: 30,
              height: 30,
              iconSize: 16,
              enabled: n > 0,
              semanticLabel: l.historyPreviousChange,
              icon: const Icon(LucideIcons.chevronUp),
              onPressed: () => goToChange(previous: true),
            ),
            ShadIconButton.ghost(
              key: const ValueKey<String>('write.history.nextChange'),
              width: 30,
              height: 30,
              iconSize: 16,
              enabled: n > 0,
              semanticLabel: l.historyNextChange,
              icon: const Icon(LucideIcons.chevronDown),
              onPressed: goToChange,
            ),
          ],
          const SizedBox(width: 8),
          ShadButton.outline(
            key: const ValueKey<String>('write.history.copy'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.copy, size: 14),
            onPressed: makeCopy,
            child: Text(l.historyMakeCopy),
          ),
        ],
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  const _AuthorChip({
    required this.author,
    required this.hidden,
    required this.onTap,
  });

  final VersionAuthor author;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = author.key.isEmpty
        ? theme.colorScheme.mutedForeground
        : theme.colorScheme.presence(presenceColorIndex(author.key));
    final counts = [
      if (author.inserted > 0) '+${author.inserted}',
      if (author.deleted > 0) '−${author.deleted}',
      if (author.formatted > 0) '~${author.formatted}',
    ].join(' ');
    final l = writeL10n(context);
    final tip = hidden
        ? l.historyShowChangesBy(author.name)
        : l.historyHideChangesBy(author.name);
    return ShadTooltip(
      builder: (_) => Text(tip),
      child: GestureDetector(
        key: ValueKey<String>('write.history.author.${author.key}'),
        onTap: onTap,
        child: Semantics(
          button: true,
          toggled: !hidden,
          hint: tip,
          child: Opacity(
            opacity: hidden ? 0.45 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(author.name, style: theme.textTheme.small),
                  if (counts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      counts,
                      style: theme.textTheme.muted.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A load failure shown as is in the error state.
class _LoadError implements Exception {
  const _LoadError(this.message);

  final String message;

  @override
  String toString() => message;
}
