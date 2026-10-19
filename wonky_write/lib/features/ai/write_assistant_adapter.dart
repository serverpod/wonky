import 'package:flutter/foundation.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../editor/controller/editor_types.dart';
import 'write_ai_controller.dart';

/// Specializes the shared assistant panel for a Write document (Write 09
/// §5.2, §5.6): selection chip and hints, the document stream session for
/// undo grouping, Show (select + reveal) and Undo of runs, Write quick
/// prompts and inserting results.
class WriteAssistantAdapter extends ChangeNotifier
    implements AssistantDocumentAdapter {
  WriteAssistantAdapter(this.ai) {
    ai.doc.editor.addListener(_onEditor);
  }

  final WriteAiController ai;

  /// Selections are sent as quotes of at most this many characters.
  static const maxSelection = 500;

  String? _chipLabel;

  @override
  UuidValue get itemUuid => ai.session.itemUuid;

  @override
  Role get role => ai.session.currentRole;

  DeltaSelection? get _selection {
    final s = ai.doc.editor.selection;
    return s == null || s.isCollapsed ? null : s;
  }

  void _onEditor() {
    final label = _label();
    if (label == _chipLabel) return;
    _chipLabel = label;
    notifyListeners();
  }

  String? _label() {
    final s = _selection;
    if (s == null) return null;
    final d = WonkyDocument(ai.doc.editor.delta);
    final lines = d.linesInRange(s.start, s.length).length;
    if (lines > 1) return ai.l10n.aiChipSelectionParagraphs(lines);
    final text = d.text
        .substring(s.start, s.end.clamp(s.start, d.text.length))
        .trim();
    final short = text.length > 32 ? '${text.substring(0, 30)}…' : text;
    return ai.l10n.aiChipSelectionQuote(short);
  }

  @override
  List<AssistantContextChip> get chips {
    final label = _chipLabel ?? _label();
    if (label == null) return const [];
    return [
      AssistantContextChip(
        id: 'selection',
        label: label,
        icon: LucideIcons.textSelect,
      ),
    ];
  }

  @override
  AssistantContextHints hints({
    required AiApplyMode applyMode,
    required Set<String> chips,
    bool includeComments = false,
  }) {
    final s = ai.doc.editor.selection;
    final useSelection = chips.contains('selection') && s != null;
    String? text;
    if (useSelection && !s.isCollapsed) {
      final plain = WonkyDocument(ai.doc.editor.delta).text;
      final end = s.end.clamp(s.start, plain.length);
      text = plain.substring(s.start, end);
      if (text.length > maxSelection) text = text.substring(0, maxSelection);
    }
    final now = DateTime.now();
    return AssistantContextHints(
      documentSessionId: ai.session.sync?.sessionId,
      applyMode: ai.doc.editor.mode == EditorMode.suggesting
          ? AiApplyMode.suggest
          : applyMode,
      revision: ai.session.revision,
      selectionStart: s?.start,
      selectionLength: useSelection ? s.length : null,
      selectionText: text,
      includeComments: includeComments,
      localTime:
          '${now.toIso8601String().substring(0, 16).replaceAll('T', ' ')} '
          '${now.timeZoneName}',
    );
  }

  @override
  List<AssistantQuickPrompt> get quickPrompts {
    final l = ai.l10n;
    // The prompts are instructions for the model and stay in English.
    return [
      AssistantQuickPrompt(
        label: l.aiSummarize,
        prompt: 'Summarize this document in a few bullet points.',
        icon: LucideIcons.listCollapse,
      ),
      if (role >= Role.commenter) ...[
        AssistantQuickPrompt(
          label: l.aiQuickImprove,
          prompt:
              'Improve the clarity and flow of the selected text (or of the '
              'document if nothing is selected) with small, targeted edits.',
          icon: LucideIcons.wandSparkles,
        ),
        AssistantQuickPrompt(
          label: l.aiQuickFixTypos,
          prompt: 'Fix spelling and grammar mistakes in the document.',
          icon: LucideIcons.spellCheck,
        ),
        AssistantQuickPrompt(
          label: l.aiQuickAddressComments,
          prompt:
              'Go through the open comments and make the changes they ask '
              'for. Reply to each comment you addressed.',
          icon: LucideIcons.messagesSquare,
          includeComments: true,
        ),
      ],
    ];
  }

  @override
  void show(AssistantActivity activity) {
    final start = activity.rangeStart;
    if (start == null) return;
    final len = WonkyDocument(ai.doc.editor.delta).length;
    final s = start.clamp(0, len - 1);
    final e = (start + (activity.rangeLength ?? 0)).clamp(s, len - 1);
    ai.doc.editor.select(DeltaSelection(s, e));
    ai.doc.reveal(s);
    ai.doc.focusEditor();
  }

  @override
  Future<bool> undoRun(String runId) => ai.session.aiUndo.undoRun(runId);

  @override
  void runFinished(String runId, String summary) =>
      ai.session.aiUndo.relabel(runId, summary);

  @override
  Future<bool> insertMarkdown(String markdown, {bool atTop = false}) async =>
      ai.insertMarkdown(markdown, atTop: atTop);

  @override
  void dispose() {
    ai.doc.editor.removeListener(_onEditor);
    super.dispose();
  }
}
