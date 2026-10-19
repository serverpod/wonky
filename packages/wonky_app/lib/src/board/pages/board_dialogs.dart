import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/wonky_app_localizations.dart';
import '../../markdown/markdown_composer.dart';
import '../../markdown/wonky_markdown.dart';
import '../../shell/form_dialog.dart';
import '../../shell/shell_services.dart';
import 'board_labels.dart';

/// The dialogs of the board's commands (specs/16 §4.5, §9.2). All but the
/// post editor are [WonkyDialogSpec]s, so MCP can operate them.

/// *Edit post* (author) or *Edit and approve* ([moderator]): title and a
/// Markdown body. Resolves with the new title and body.
Future<(String, String)?> showBoardEditPostDialog(
  BuildContext context,
  ShellServices s, {
  required String title,
  required String body,
  bool moderator = false,
}) => showShadDialog<(String, String)>(
  context: context,
  builder: (_) =>
      _EditPostDialog(title: title, body: body, moderator: moderator),
);

class _EditPostDialog extends StatefulWidget {
  const _EditPostDialog({
    required this.title,
    required this.body,
    required this.moderator,
  });

  final String title;
  final String body;
  final bool moderator;

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final _title = TextEditingController(text: widget.title);
  late final _body = TextEditingController(text: widget.body);
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final l = WonkyAppLocalizations.of(context);
    final t = _title.text.trim();
    final b = _body.text.trim();
    if (t.length < (widget.moderator ? 1 : 8) || t.length > 120) {
      setState(() => _error = l.boardTitleLength);
      return;
    }
    if (b.isEmpty) {
      setState(() => _error = l.errorRequired);
      return;
    }
    Navigator.of(context).pop((t, b));
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.board.editPost'),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: const BoxConstraints(maxWidth: 700),
        title: Text(
          widget.moderator ? l.cmdBoardAdminEdit : l.cmdBoardEditPost,
        ),
        description: widget.moderator ? Text(l.boardModeratorEditHint) : null,
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.board.editPost.cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.board.editPost.save'),
            onPressed: _save,
            child: Text(l.actionSave),
          ),
        ],
        child: SizedBox(
          width: width < 680 ? width - 48 : 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              ShadInput(
                key: const ValueKey<String>('dialog.board.editPost.title'),
                controller: _title,
                maxLength: 120,
                placeholder: Text(l.boardFieldTitle),
              ),
              MarkdownComposer(
                fieldKey: 'dialog.board.editPost.body',
                controller: _body,
                profile: MarkdownProfile.post,
                maxLength: 10000,
                minLines: 6,
                maxLines: 14,
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// *Flag* (specs/16 §7.5): a reason and an optional note.
Future<(BoardFlagReason, String?)?> showBoardFlagDialog(
  BuildContext context,
) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdBoardFlag,
      description: l.boardFlagHint,
      dialogKey: 'dialog.board.flag',
      fields: [
        SelectFieldSpec(
          id: 'reason',
          label: l.boardFieldReason,
          options: {
            for (final x in BoardFlagReason.values)
              x.name: l.boardFlagReasonName(x),
          },
          initial: BoardFlagReason.spam.name,
        ),
        TextFieldSpec(
          id: 'note',
          label: l.boardFieldNote,
          multiline: true,
          maxLength: 1000,
          validator: (_) => null,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'flag', label: l.boardFlagAction, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'flag') return null;
  final note = r!.text('note').trim();
  return (
    BoardFlagReason.values.byName(r.text('reason')),
    note.isEmpty ? null : note,
  );
}

/// A reason preset plus optional text (*Remove*, *Decline…*): resolves
/// with "Preset: text" or the preset alone.
Future<String?> _reasonDialog(
  BuildContext context, {
  required String title,
  required String key,
  required Map<String, String> presets,
  required String confirm,
  String? initial,
  String? description,
  bool destructive = false,
}) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: title,
      description: description,
      dialogKey: key,
      fields: [
        SelectFieldSpec(
          id: 'reason',
          label: l.boardFieldReason,
          options: presets,
          initial: presets.containsKey(initial) ? initial! : presets.keys.first,
        ),
        TextFieldSpec(
          id: 'note',
          label: l.boardFieldNoteForAuthor,
          multiline: true,
          maxLength: 900,
          validator: (_) => null,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(
          id: 'ok',
          label: confirm,
          primary: true,
          destructive: destructive,
        ),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  final preset = presets[r!.text('reason')] ?? '';
  final note = r.text('note').trim();
  return note.isEmpty ? preset : '$preset: $note';
}

/// The reason post [p] was held for, as a *Remove* preset: the highest
/// moderation score of the triage ([BoardPostView.reviewScores]), else the
/// author-facing hold reason, else the most common community flag; *Other*
/// when none of them names one (`not_actionable`, `off_topic`, unknown).
BoardFlagReason boardRemoveReasonFor(BoardPostView? p) {
  if (p == null) return BoardFlagReason.other;
  BoardFlagReason? fromDecision(String id) => switch (id) {
    'security' => BoardFlagReason.security,
    'offensive' => BoardFlagReason.offensive,
    'personal_data' => BoardFlagReason.personalData,
    'spam' => BoardFlagReason.spam,
    _ => null,
  };
  final scores = p.reviewScores;
  if (scores != null && scores.isNotEmpty) {
    final top = scores.entries.reduce((a, b) => b.value > a.value ? b : a);
    return fromDecision(top.key) ?? BoardFlagReason.other;
  }
  final reason = p.moderationReason?.toLowerCase() ?? '';
  for (final (text, r) in const [
    ('security', BoardFlagReason.security),
    ('offensive', BoardFlagReason.offensive),
    ('personal data', BoardFlagReason.personalData),
    ('spam', BoardFlagReason.spam),
  ]) {
    if (reason.contains(text)) return r;
  }
  final flags = p.flags ?? const <BoardFlagView>[];
  if (flags.isNotEmpty) {
    final counts = <BoardFlagReason, int>{};
    for (final f in flags) {
      counts[f.reason] = (counts[f.reason] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
  return BoardFlagReason.other;
}

/// *Remove* (specs/16 §9.2): offensive, spam, personal data, security,
/// other, plus text shown to the author. The reason starts at [initial]
/// (the reason the post was held for, [boardRemoveReasonFor]).
Future<String?> showBoardRemoveDialog(
  BuildContext context, {
  BoardFlagReason initial = BoardFlagReason.other,
}) {
  final l = WonkyAppLocalizations.of(context);
  return _reasonDialog(
    context,
    title: l.boardRemoveTitle,
    key: 'dialog.board.remove',
    presets: {
      for (final x in BoardFlagReason.values) x.name: l.boardFlagReasonName(x),
    },
    initial: initial.name,
    confirm: l.boardActionRemove,
    destructive: true,
  );
}

/// *Decline…* (specs/16 §3.1): out of scope, works as intended, won't fix.
Future<String?> showBoardDeclineDialog(BuildContext context) {
  final l = WonkyAppLocalizations.of(context);
  return _reasonDialog(
    context,
    title: l.cmdBoardDecline,
    key: 'dialog.board.decline',
    presets: {
      'outOfScope': l.boardDeclineOutOfScope,
      'asIntended': l.boardDeclineAsIntended,
      'wontFix': l.boardDeclineWontFix,
      'other': l.boardReasonOther,
    },
    confirm: l.boardActionDecline,
  );
}

/// *Block user from the board…*: the reason (stored for admins).
Future<String?> showBoardBlockDialog(BuildContext context, String? name) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdBoardBlock,
      description: l.boardBlockHint(name ?? l.someone),
      dialogKey: 'dialog.board.block',
      fields: [
        TextFieldSpec(id: 'reason', label: l.boardFieldReason, maxLength: 1000),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(
          id: 'ok',
          label: l.boardActionBlock,
          primary: true,
          destructive: true,
        ),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return r!.text('reason').trim();
}

int? _postNumber(String v) =>
    int.tryParse(v.trim().replaceFirst(RegExp(r'^#'), ''));

/// *Merge into…*: the number of the post that remains.
Future<int?> showBoardMergeDialog(BuildContext context, int source) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdBoardMerge,
      description: l.boardMergeHint(source),
      dialogKey: 'dialog.board.merge',
      fields: [
        TextFieldSpec(
          id: 'target',
          label: l.boardFieldTargetPost,
          placeholder: '#412',
          maxLength: 12,
          validator: (v) {
            final n = _postNumber(v);
            if (n == null || n < 1) return l.boardInvalidPostNumber;
            if (n == source) return l.boardMergeSelf;
            return null;
          },
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.boardActionMerge, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return _postNumber(r!.text('target'));
}

const _none = 'none';

/// *Set kind / area / size*.
Future<(BoardPostKind, BoardArea?, BoardSize?)?> showBoardLabelsDialog(
  BuildContext context, {
  required BoardPostKind kind,
  required BoardArea? area,
  required BoardSize? size,
}) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdBoardSetLabels,
      dialogKey: 'dialog.board.labels',
      fields: [
        SelectFieldSpec(
          id: 'kind',
          label: l.boardFieldKind,
          options: {
            for (final x in BoardPostKind.values) x.name: l.boardKindName(x),
          },
          initial: kind.name,
        ),
        SelectFieldSpec(
          id: 'area',
          label: l.boardFieldArea,
          options: {
            _none: l.boardNoLabel,
            for (final x in BoardArea.values) x.name: l.boardAreaName(x),
          },
          initial: area?.name ?? _none,
        ),
        SelectFieldSpec(
          id: 'size',
          label: l.boardFieldSize,
          options: {
            _none: l.boardNoLabel,
            for (final x in BoardSize.values) x.name: l.boardSizeName(x),
          },
          initial: size?.name ?? _none,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.actionSave, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  final a = r!.text('area');
  final s = r.text('size');
  return (
    BoardPostKind.values.byName(r.text('kind')),
    a == _none ? null : BoardArea.values.byName(a),
    s == _none ? null : BoardSize.values.byName(s),
  );
}

/// *Create task from N issues…* ([count] set), *Merge N tasks…*
/// ([mergeCount] set) or *Edit task*.
Future<(String, BoardArea, BoardSize)?> showBoardTaskDialog(
  BuildContext context, {
  int? count,
  int? mergeCount,
  required String title,
  required BoardArea area,
  required BoardSize size,
}) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: switch ((count, mergeCount)) {
        (final n?, _) => l.boardCreateTaskFrom(n),
        (_, final n?) => l.boardMergeTasksTitle(n),
        _ => l.cmdBoardEditTask,
      },
      description: switch ((count, mergeCount)) {
        (_?, _) => l.boardCreateTaskHint,
        (_, _?) => l.boardMergeTasksHint,
        _ => null,
      },
      dialogKey: 'dialog.board.task',
      fields: [
        TextFieldSpec(
          id: 'title',
          label: l.boardFieldTitle,
          initial: title,
          maxLength: 120,
        ),
        SelectFieldSpec(
          id: 'area',
          label: l.boardFieldArea,
          options: {
            for (final x in BoardArea.values) x.name: l.boardAreaName(x),
          },
          initial: area.name,
        ),
        SelectFieldSpec(
          id: 'size',
          label: l.boardFieldSize,
          options: {
            for (final x in BoardSize.values) x.name: l.boardSizeName(x),
          },
          initial: size.name,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(
          id: 'ok',
          label: switch ((count, mergeCount)) {
            (_?, _) => l.boardActionCreateTask,
            (_, _?) => l.boardActionMerge,
            _ => l.actionSave,
          },
          primary: true,
        ),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return (
    r!.text('title').trim(),
    BoardArea.values.byName(r.text('area')),
    BoardSize.values.byName(r.text('size')),
  );
}

/// *Add to task…*: one of the open tasks.
Future<int?> showBoardPickTaskDialog(
  BuildContext context,
  List<BoardTaskView> tasks,
) async {
  final l = WonkyAppLocalizations.of(context);
  if (tasks.isEmpty) {
    await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.boardAddToTask,
        description: l.boardNoOpenTasks,
        dialogKey: 'dialog.board.pickTask',
        buttons: [DialogButtonSpec(id: 'cancel', label: l.actionClose)],
      ),
    );
    return null;
  }
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.boardAddToTask,
      dialogKey: 'dialog.board.pickTask',
      fields: [
        SelectFieldSpec(
          id: 'task',
          label: l.boardFieldTask,
          options: {
            for (final t in tasks)
              '${t.number}':
                  'T-${t.number} ${t.title} (${l.boardTaskStatusName(t.status)})',
          },
          initial: '${tasks.first.number}',
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.boardActionAdd, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return int.tryParse(r!.text('task'));
}

/// *Link pull request…*: a GitHub PR URL; an empty field unlinks.
Future<String?> showBoardLinkPrDialog(
  BuildContext context,
  String? current,
) async {
  final l = WonkyAppLocalizations.of(context);
  final pr = RegExp(r'^https://github\.com/[\w.-]+/[\w.-]+/pull/\d+/?$');
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdBoardLinkPr,
      description: l.boardLinkPrHint,
      dialogKey: 'dialog.board.linkPr',
      width: 480,
      fields: [
        TextFieldSpec(
          id: 'url',
          label: l.boardFieldPrUrl,
          initial: current ?? '',
          placeholder: 'https://github.com/serverpod/wonky/pull/345',
          maxLength: 300,
          validator: (v) => v.trim().isEmpty || pr.hasMatch(v.trim())
              ? null
              : l.boardInvalidPrUrl,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.boardActionLink, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return r!.text('url').trim();
}
