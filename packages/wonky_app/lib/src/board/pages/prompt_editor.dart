import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/board.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../core/stream_supervisor.dart';
import '../../data/api.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../markdown/markdown_composer.dart';
import '../../markdown/wonky_markdown.dart';
import '../../shell/shell_services.dart';
import '../board_hub.dart';
import 'board_widgets.dart';

/// The result of [showPromptEditor].
class PromptEditorResult {
  const PromptEditorResult(this.body, {this.publish = false});

  final String body;

  /// The task is a draft: saving also publishes it (T-11, specs/16 §10.2).
  final bool publish;
}

/// The prompt editor of specs/16 §10.2 (`dialog.board.prompt`): a
/// `MarkdownComposer` on the prompt body with a large preview, the lint,
/// *Regenerate* (with the changes against the text before) and *Save*,
/// which also publishes a draft (a prompt the lint held or the AI could not
/// write, T-11). The composer keeps its own text undo.
Future<PromptEditorResult?> showPromptEditor(
  BuildContext context,
  ShellServices s, {
  required BoardTaskView task,
}) => showShadDialog<PromptEditorResult>(
  context: context,
  builder: (_) => PromptEditorDialog(services: s, task: task),
);

class PromptEditorDialog extends StatefulWidget {
  const PromptEditorDialog({
    super.key,
    required this.services,
    required this.task,
  });

  final ShellServices services;
  final BoardTaskView task;

  @override
  State<PromptEditorDialog> createState() => _PromptEditorDialogState();
}

class _PromptEditorDialogState extends State<PromptEditorDialog> {
  ShellServices get s => widget.services;
  int get n => widget.task.number;

  late final _body = TextEditingController(text: widget.task.promptBody);
  late BoardTaskView _task = widget.task;
  bool _regenerating = false;
  SupervisedStream? _watch;
  StreamSubscription<BoardChange>? _changes;

  /// The text before the last *Regenerate* (shown as a diff).
  String? _beforeRegenerate;

  /// The AI is writing the prompt (specs/16 §10.1): the body is replaced
  /// when it is done, so editing, saving and publishing wait.
  bool get _pending => _task.promptPending;

  @override
  void initState() {
    super.initState();
    _body.addListener(_changed);
    // The AI's prompt arrives live (`watchTasks`); commands, undo and
    // redo go through the hub.
    _watch = s.supervisor.supervise<BoardPostEvent>(
      'board.promptEditor.$n',
      () => s.repositories.board.watchTasks(),
      (e) {
        if (e.number == n) unawaited(_reload());
      },
    );
    _changes = BoardHub.of(s).changes.listen((c) {
      if (c.task == n) unawaited(_reload());
    });
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _changes?.cancel();
    unawaited(_watch?.cancel());
    _body
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  /// Reads the task again; a prompt the AI finished (or a synchronous
  /// *Regenerate*) replaces the text, with the text before as the diff.
  Future<void> _reload() async {
    final BoardTaskView t;
    try {
      t = await s.repositories.board.getTask(n);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final before = _task;
    setState(() {
      _task = t;
      final written =
          !t.promptPending &&
          t.promptBody != before.promptBody &&
          (before.promptPending || _regenerating);
      if (written) {
        _beforeRegenerate = _body.text;
        _body.text = t.promptBody;
      }
    });
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final r = await s.dispatcher.invoke(
        'shell.board.admin.regeneratePrompt',
        args: {'taskNumber': n},
      );
      if (r.isOk) await _reload();
    } catch (e) {
      final l = s.l10n;
      if (l != null) {
        s.toasts.error(l.errorGeneric, description: errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  void _close({bool publish = false}) {
    if (_pending) return;
    final body = _body.text.trim();
    if (body.isEmpty) return;
    Navigator.of(context).pop(PromptEditorResult(body, publish: publish));
  }

  String _lintText(WonkyAppLocalizations l, PromptLint x) => switch (x.kind) {
    PromptLintKind.command => l.boardLintCommand(x.line, x.match),
    PromptLintKind.url => l.boardLintUrl(x.line, x.match),
    PromptLintKind.wording => l.boardLintWording(x.line, x.match),
  };

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;
    final lint = lintTaskPrompt(_body.text);
    final draft = widget.task.status == BoardTaskStatus.draft;
    final mono = boardCodeStyle(theme);
    final pending = _pending;
    final editor = MarkdownComposer(
      fieldKey: 'dialog.board.prompt.body',
      controller: _body,
      enabled: !pending,
      profile: MarkdownProfile.post,
      minLines: 14,
      maxLines: 24,
      maxLength: 50000,
    );
    final preview = Container(
      key: const ValueKey<String>('dialog.board.prompt.preview'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: WonkyMarkdown(_body.text, profile: MarkdownProfile.post),
      ),
    );
    final before = _beforeRegenerate;
    final diff = before == null ? null : _lineDiff(before, _body.text);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.board.prompt'),
        constraints: BoxConstraints(
          maxWidth: (size.width - 48).clamp(320.0, 1100.0) + 48,
        ),
        title: Text(l.boardPromptEditorTitle(widget.task.number)),
        description: Text(
          draft
              ? '${l.boardPromptEditorHint} ${l.boardPromptSavePublishes}'
              : l.boardPromptEditorHint,
        ),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.board.prompt.regenerate'),
            enabled: !_regenerating && !pending,
            onPressed: _regenerate,
            leading: const Icon(LucideIcons.refreshCw, size: 16),
            child: Text(l.cmdBoardRegeneratePrompt),
          ),
          ShadButton.outline(
            key: const ValueKey<String>('dialog.board.prompt.cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.board.prompt.save'),
            enabled: !pending,
            onPressed: () => _close(publish: draft),
            child: Text(l.actionSave),
          ),
        ],
        child: SizedBox(
          width: (size.width - 48).clamp(320.0, 1100.0),
          height: (size.height - 260).clamp(320.0, 720.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              if (pending)
                const BoardPromptPendingNotice(
                  key: ValueKey<String>('dialog.board.prompt.pending'),
                ),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 12,
                        children: [
                          Expanded(child: SingleChildScrollView(child: editor)),
                          Expanded(child: preview),
                        ],
                      )
                    : SingleChildScrollView(child: editor),
              ),
              if (lint.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: Container(
                    key: const ValueKey<String>('dialog.board.prompt.lint'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.warning.withValues(alpha: 0.1),
                      border: Border.all(color: theme.colorScheme.warning),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Row(
                            spacing: 6,
                            children: [
                              Icon(
                                LucideIcons.triangleAlert,
                                size: 16,
                                color: theme.colorScheme.warning,
                              ),
                              Expanded(
                                child: Text(
                                  l.boardLintTitle(lint.length),
                                  style: theme.textTheme.small,
                                ),
                              ),
                            ],
                          ),
                          for (final x in lint)
                            Text(_lintText(l, x), style: mono),
                        ],
                      ),
                    ),
                  ),
                ),
              if (diff != null && diff.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    key: const ValueKey<String>('dialog.board.prompt.diff'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.boardPromptDiffTitle,
                          style: theme.textTheme.small,
                        ),
                        for (final (added, line) in diff)
                          Text(
                            '${added ? '+' : '−'} $line',
                            style: mono.copyWith(
                              color: added
                                  ? theme.colorScheme.success
                                  : theme.colorScheme.destructive,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lines only in [b] (added) and only in [a] (removed), in order.
List<(bool, String)> _lineDiff(String a, String b) {
  final al = a.split('\n');
  final bl = b.split('\n');
  final inA = {...al};
  final inB = {...bl};
  return [
    for (final x in al)
      if (!inB.contains(x) && x.trim().isNotEmpty) (false, x),
    for (final x in bl)
      if (!inA.contains(x) && x.trim().isNotEmpty) (true, x),
  ];
}
