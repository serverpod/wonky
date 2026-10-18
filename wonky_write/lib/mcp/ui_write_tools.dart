import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../features/editor/applier/delta_applier.dart' as editor;
import '../features/screen/write_document_controller.dart';
import '../l10n/write_l10n.dart';

/// Wonky Write's UI-bridge tools (`ui.write.*`, Write 09 §3), executed in
/// the live window on the open document. Mutations go through the
/// document session's undoable local changes or commands (source `mcp`),
/// so they land on the user's undo stack.
abstract final class UiWriteToolHandlers {
  static Map<String, UiToolHandler> all(ShellServices services) => {
    'ui.write.get_selection': getSelection,
    'ui.write.select_range': selectRange,
    'ui.write.select_text': selectText,
    'ui.write.scroll_to': scrollTo,
    'ui.write.get_layout_info': getLayoutInfo,
    'ui.write.set_view_mode': (c, a) =>
        _invoke(c, 'write.mode.set', {'mode': a['mode']}),
    'ui.write.set_layout_mode': (c, a) =>
        _invoke(c, 'write.doc.setLayout', {'layout': a['layout']}),
    'ui.write.toggle_outline': toggleOutline,
    'ui.write.insert_markdown_at_selection': insertMarkdownAtSelection,
  };

  static WriteDocumentController _doc(UiToolContext c) {
    final d = c.services.activeDocument.value;
    if (d is! WriteDocumentController || !d.session.isLoaded) {
      throw const UiToolException(
        'no_document',
        'No Wonky Write document is open in this window. Open one with '
            'ui.navigate {"open_item_uuid": …}.',
      );
    }
    return d;
  }

  static Future<UiToolResult> _invoke(
    UiToolContext c,
    String id,
    Map<String, Object?> args,
  ) async {
    _doc(c);
    try {
      final r = await c.services.dispatcher.invoke(
        id,
        args: args,
        source: InvocationSource.mcp,
        context: c.context,
      );
      return UiToolResult({
        'command_id': id,
        'status': r.status.name,
        'message': ?r.message,
      });
    } on Exception catch (e) {
      throw UiToolException('failed', '$e');
    }
  }

  /// The selection JSON of [d].
  static Map<String, Object?> selectionOf(WriteDocumentController d) {
    final ed = d.editor;
    final delta = ed.delta;
    final doc = WonkyDocument(delta);
    final sel = ed.selection;
    final max = doc.length - 1;
    final start = (sel?.start ?? 0).clamp(0, max);
    final end = (sel?.end ?? 0).clamp(0, max);
    final text = doc.text.substring(start, end);
    var markdown = '';
    if (end > start) {
      final slice = delta.slice(start, end);
      final normalized = DeltaUtils.text(slice).endsWith('\n')
          ? slice
          : DeltaUtils.concatAll([slice, Delta()..insert('\n')]);
      markdown = DocumentReader.renderMarkdown(
        normalized,
        SuggestionViewMode.accepted,
      ).trimRight();
    }
    final attrs = doc.attributesAt(start) ?? const <String, dynamic>{};
    final lines = doc.linesInRange(start, (end - start).clamp(0, max));
    return {
      'document_uuid': d.itemUuid.uuid,
      'revision': d.session.revision,
      'collapsed': start == end,
      'start': start,
      'length': end - start,
      'anchor': sel?.anchor,
      'head': sel?.head,
      'selected_text': text,
      'selected_markdown': markdown,
      'block_types': {for (final l in lines) DocumentBlocks.typeOf(l)}.toList(),
      'active_formats': {
        for (final k in [
          WonkyAttr.bold,
          WonkyAttr.italic,
          WonkyAttr.strike,
          WonkyAttr.code,
        ])
          k: attrs[k] == true,
        'link': attrs[WonkyAttr.link],
      },
      'mode': ed.mode.name,
    };
  }

  static Future<UiToolResult> getSelection(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final s = selectionOf(_doc(c));
    return UiToolResult(
      s,
      text: s['collapsed'] == true
          ? 'Caret at ${s['start']}'
          : 'Selected "${s['selected_text']}"',
    );
  }

  static Future<UiToolResult> _select(
    UiToolContext c,
    WriteDocumentController d,
    int start,
    int length,
  ) async {
    final max = d.editor.length - 1;
    if (start < 0 || start > max || start + length > max + 1) {
      throw UiToolException(
        'invalid_offset',
        'Range outside [0, ${max + 1}).',
        details: {'doc_length': max + 1},
      );
    }
    final end = (start + length).clamp(0, max);
    d.focusEditor();
    d.editor.select(editor.DeltaSelection(start, end));
    d.session.revealRange(start, end);
    await uiSettle();
    return UiToolResult(selectionOf(d), text: 'Selected $start+$length');
  }

  static Future<UiToolResult> selectRange(
    UiToolContext c,
    Map<String, Object?> a,
  ) {
    final d = _doc(c);
    return _select(
      c,
      d,
      (a['start']! as num).toInt(),
      (a['length']! as num).toInt(),
    );
  }

  static Future<UiToolResult> selectText(
    UiToolContext c,
    Map<String, Object?> a,
  ) {
    final d = _doc(c);
    try {
      final r = AddressResolver(
        d.editor.delta,
      ).resolveQuote(a['quote']! as String, (a['occurrence'] as num?)?.toInt());
      return _select(c, d, r.start, r.length);
    } on AddressException catch (e) {
      throw UiToolException(e.code, e.message, details: e.details);
    }
  }

  static Future<UiToolResult> scrollTo(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final d = _doc(c);
    final target = (a['target']! as Map).cast<String, Object?>();
    final delta = d.editor.delta;
    int start;
    int end;
    try {
      if (target['heading'] != null || target['heading_index'] != null) {
        final h = AddressResolver(
          delta,
        ).resolveHeading(HeadingRef.fromJson(target.cast<String, dynamic>()));
        start = h.deltaOffset;
        end = h.deltaOffset;
      } else if (target['offset'] != null) {
        start = (target['offset']! as num).toInt().clamp(
          0,
          d.editor.length - 1,
        );
        end = start;
      } else if (target['comment_thread_uuid'] != null) {
        final id = target['comment_thread_uuid']! as String;
        final anchor = d.session.comments.anchors[id];
        if (anchor == null) {
          throw const UiToolException(
            'not_found',
            'The thread is not anchored.',
          );
        }
        start = anchor.start;
        end = anchor.start + anchor.length;
        c.services.comments.value?.activate(id);
      } else if (target['suggestion_id'] != null) {
        final id = target['suggestion_id']! as String;
        final s = d.session.suggestions.pending
            .where((x) => x.id == id)
            .firstOrNull;
        if (s == null) {
          throw const UiToolException('not_found', 'Unknown suggestion.');
        }
        d.session.suggestions.activate(id);
        start = s.start;
        end = s.parts.last.start + s.parts.last.length;
      } else {
        throw const UiToolException('invalid_args', 'Unknown target.');
      }
    } on AddressException catch (e) {
      throw UiToolException(e.code, e.message, details: e.details);
    }
    d.session.revealRange(start, end);
    await uiSettle();
    return UiToolResult({
      'start': start,
      'end': end,
    }, text: 'Scrolled to $start');
  }

  static Future<UiToolResult> getLayoutInfo(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final d = _doc(c);
    final setup = d.session.meta.value.pageSetup;
    final outline = const OutlineExtractor().outlineOf(
      WonkyDocument(d.editor.delta),
    );
    final sel = d.editor.selection;
    String? currentHeading;
    if (sel != null) {
      for (final h in outline) {
        if (h.deltaOffset <= sel.start) currentHeading = h.text;
      }
    }
    return UiToolResult({
      'document_uuid': d.itemUuid.uuid,
      'zoom': d.zoom,
      'layout': setup.layout.name,
      'paper': setup.paper.name,
      'page_size_pt': {
        'width': setup.pageWidthPt,
        'height': setup.pageHeightPt,
      },
      'doc_length': d.editor.length,
      'headings': outline.length,
      'heading_at_selection': currentHeading,
      'mode': d.editor.mode.name,
      'outline_open': c.services.panels.isOpen(WritePanels.outline),
    });
  }

  static Future<UiToolResult> toggleOutline(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    _doc(c);
    final open = a['open'] as bool?;
    final panels = c.services.panels;
    if (open == null) {
      await _invoke(c, 'write.view.toggleOutline', const {});
    } else if (open) {
      panels.open(WritePanels.outline);
    } else {
      panels.close(WritePanels.outline);
    }
    await uiSettle();
    return UiToolResult({'open': panels.isOpen(WritePanels.outline)});
  }

  static Future<UiToolResult> insertMarkdownAtSelection(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final d = _doc(c);
    final markdown = a['markdown']! as String;
    final replace = a['replace_selection'] == true;
    final head = d.editor.delta;
    final max = d.editor.length - 1;
    final sel = d.editor.selection ?? editor.DeltaSelection.collapsed(max);
    final start = sel.start.clamp(0, max);
    final end = sel.end.clamp(0, max);
    final edits = DocumentEdits();
    EditResult r;
    try {
      r = replace && end > start
          ? edits.replaceRange(
              head,
              ResolvedRange(start, end - start),
              markdown,
            )
          : edits.insertMarkdown(head, end, markdown);
    } on AddressException catch (e) {
      throw UiToolException(e.code, e.message, details: e.details);
    }
    final applied = r.appliedRange;
    final ok = d.session.applyContentChange(
      r.change,
      label: writeL10nOf(c.services).undoInsertMarkdown,
      selectionAfter: applied == null
          ? null
          : editor.DeltaSelection.collapsed(applied.end),
    );
    if (!ok) {
      throw const UiToolException(
        'forbidden',
        'The document cannot be edited in the current mode or role.',
      );
    }
    await uiSettle();
    return UiToolResult({
      'inserted_range': applied?.toJson(),
      'undo_label': c.services.undo.undoLabel.value,
      'warnings': [for (final w in r.warnings) w.message],
    }, text: 'Inserted ${applied?.length ?? 0} characters');
  }
}
