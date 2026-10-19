import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import 'sheets_ai_controller.dart';

/// What the user did in the AI changes preview.
sealed class AiPreviewOutcome {
  const AiPreviewOutcome();
}

/// *Apply selected*: the server applied the checked calls.
class AiPreviewApplied extends AiPreviewOutcome {
  const AiPreviewApplied(this.result);
  final SheetsAiApplyResult result;
}

/// *Discard*.
class AiPreviewDiscarded extends AiPreviewOutcome {
  const AiPreviewDiscarded();
}

/// The AI changes preview of a Suggest-mode run (Sheets 12 §6.3): the
/// recorded tool calls with checkboxes (left) and the before → after cells
/// of the focused call (right). Null when closed without a choice.
Future<AiPreviewOutcome?> showAiPreviewDialog(
  BuildContext context, {
  required SheetsAiController ai,
  required String previewId,
}) => showShadDialog<AiPreviewOutcome>(
  context: context,
  builder: (_) => AiPreviewDialog(ai: ai, previewId: previewId),
);

class AiPreviewDialog extends StatefulWidget {
  const AiPreviewDialog({super.key, required this.ai, required this.previewId});

  final SheetsAiController ai;
  final String previewId;

  @override
  State<AiPreviewDialog> createState() => _AiPreviewDialogState();
}

class _AiPreviewDialogState extends State<AiPreviewDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  SheetsAiPreview? _preview;
  final Set<String> _checked = {};
  String? _focused;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  SheetsAiController get ai => widget.ai;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await ai.api.getPreview(widget.previewId);
      if (!mounted) return;
      setState(() {
        _preview = p;
        _checked.addAll([for (final c in p.calls) c.callId]);
        _focused = p.calls.isEmpty ? null : p.calls.first.callId;
        _loading = false;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  bool get _canApply =>
      !_busy && _preview != null && _checked.isNotEmpty && ai.editor.canEdit;

  Future<void> _apply() async {
    final p = _preview;
    if (!_canApply || p == null) return;
    setState(() => _busy = true);
    try {
      final all = _checked.length == p.calls.length;
      final r = await ai.api.applyPreview(
        widget.previewId,
        all ? null : _checked.toList(),
      );
      if (mounted) Navigator.of(context).pop(AiPreviewApplied(r));
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    try {
      await ai.api.discardPreview(widget.previewId);
    } on Object {
      // Expired previews are gone anyway.
    }
    if (mounted) Navigator.of(context).pop(const AiPreviewDiscarded());
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final p = _preview;
    return {
      'title': sheetsL10nOf(ai.services).aiPreviewTitle,
      'preview_id': widget.previewId,
      'loading': _loading,
      'error': ?_error,
      'fields': [
        {
          'id': 'calls',
          'label': 'Changes to apply',
          'type': 'multiselect',
          'value': _checked.toList(),
          'options': [for (final c in p?.calls ?? const []) c.callId],
        },
      ],
      if (p != null)
        'calls': [
          for (final c in p.calls)
            {
              'call_id': c.callId,
              'tool': c.toolName,
              'label': c.label,
              'ranges': c.ranges,
              'cells_affected': c.cellsAffected,
              'structural': ?c.structural,
              'cells': [
                for (final x in c.cells.take(20))
                  {'cell': x.cell, 'before': x.before, 'after': x.after},
              ],
            },
        ],
      'buttons': [
        {'id': 'discard', 'label': 'Discard', 'enabled': !_busy},
        {'id': 'apply', 'label': 'Apply selected', 'enabled': _canApply},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id != 'calls' || value is! List) return false;
    setState(() {
      _checked
        ..clear()
        ..addAll(value.map((e) => '$e'));
    });
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'discard':
      case 'cancel':
        unawaited(_discard());
        return true;
      case 'apply':
        if (!_canApply) return false;
        unawaited(_apply());
        return true;
    }
    return false;
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final p = _preview;
    return ShadDialog(
      key: const ValueKey<String>('dialog.aiPreview'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.aiPreviewTitle),
      description: Text(l.aiPreviewDescription),
      actions: [
        ShadButton.outline(
          key: const ValueKey<String>('dialog.aiPreview.discard'),
          enabled: !_busy,
          onPressed: () => unawaited(_discard()),
          child: Text(l.aiPreviewDiscard),
        ),
        ShadButton(
          key: const ValueKey<String>('dialog.aiPreview.apply'),
          enabled: _canApply,
          leading: _busy
              ? const SizedBox(width: 14, height: 14, child: ShadSpinner())
              : null,
          onPressed: () => unawaited(_apply()),
          child: Text(l.aiPreviewApply),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 540),
        child: SizedBox(
          width: 820,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: ShadSpinner()),
                )
              : _error != null && p == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_error!, style: theme.textTheme.muted),
                )
              : LayoutBuilder(
                  builder: (context, box) {
                    final narrow = box.maxWidth < 560;
                    final list = _calls(context, p!);
                    final detail = _detail(context, p);
                    final err = _error == null
                        ? null
                        : Text(
                            _error!,
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.destructive,
                            ),
                          );
                    if (narrow) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          ?err,
                          Flexible(child: list),
                          Flexible(child: detail),
                        ],
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        ?err,
                        Flexible(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              SizedBox(width: 300, child: list),
                              Expanded(child: detail),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _calls(BuildContext context, SheetsAiPreview p) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    if (p.calls.isEmpty) {
      return Text(l.aiPreviewEmpty, style: theme.textTheme.muted);
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final c in p.calls)
          GestureDetector(
            key: ValueKey<String>('dialog.aiPreview.call.${c.callId}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _focused = c.callId),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _focused == c.callId ? cs.accent : null,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  ShadCheckbox(
                    value: _checked.contains(c.callId),
                    onChanged: (v) => setState(() {
                      if (v) {
                        _checked.add(c.callId);
                      } else {
                        _checked.remove(c.callId);
                      }
                    }),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(c.label, style: theme.textTheme.small),
                        Text(
                          [
                            ...c.ranges,
                            if (c.cellsAffected > 0)
                              l.aiPreviewCells(c.cellsAffected),
                          ].join(' · '),
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _detail(BuildContext context, SheetsAiPreview p) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    final c = p.calls.where((x) => x.callId == _focused).firstOrNull;
    if (c == null) return const SizedBox.shrink();
    Widget cell(String? text, {bool strong = false, Color? bg}) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text == null || text.isEmpty ? '—' : text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.small.copyWith(
          fontWeight: strong ? FontWeight.w600 : null,
          color: text == null || text.isEmpty ? cs.mutedForeground : null,
        ),
      ),
    );
    final added = const Color(0xff16a34a).withValues(alpha: 0.14);
    final removed = cs.destructive.withValues(alpha: 0.10);
    return Column(
      key: const ValueKey<String>('dialog.aiPreview.detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (c.structural != null)
          Text(c.structural!, style: theme.textTheme.small),
        if (c.cells.isEmpty && c.structural == null)
          Text(l.aiPreviewNoCells, style: theme.textTheme.muted),
        if (c.cells.isNotEmpty)
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: cs.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: cs.border),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: cs.muted),
                      children: [
                        cell(l.aiPreviewCell, strong: true),
                        cell(l.aiPreviewBefore, strong: true),
                        cell(l.aiPreviewAfter, strong: true),
                      ],
                    ),
                    for (final x in c.cells)
                      TableRow(
                        children: [
                          cell(_short(x.cell)),
                          cell(
                            x.before,
                            bg: (x.before ?? '').isEmpty ? null : removed,
                          ),
                          cell(x.after, bg: added),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (c.cellsAffected > c.cells.length)
          Text(
            l.aiPreviewMoreCells(c.cellsAffected - c.cells.length),
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
      ],
    );
  }

  static String _short(String cell) {
    final i = cell.lastIndexOf('!');
    return i < 0 ? cell : cell.substring(i + 1);
  }
}
