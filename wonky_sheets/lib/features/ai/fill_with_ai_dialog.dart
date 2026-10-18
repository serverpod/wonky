import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import 'sheets_ai_controller.dart';

/// Fill with AI (Sheets 12 §6.6): proposals for the empty cells of a
/// column, with row label, inputs, value and confidence; Apply writes the
/// checked ones as one server change. Returns the apply result (null:
/// cancelled).
Future<SheetsAiApplyResult?> showFillWithAiDialog(
  BuildContext context, {
  required SheetsAiController ai,
  required String range,
  String? instructions,
}) => showShadDialog<SheetsAiApplyResult>(
  context: context,
  builder: (_) =>
      FillWithAiDialog(ai: ai, range: range, instructions: instructions),
);

class FillWithAiDialog extends StatefulWidget {
  const FillWithAiDialog({
    super.key,
    required this.ai,
    required this.range,
    this.instructions,
  });

  final SheetsAiController ai;
  final String range;
  final String? instructions;

  @override
  State<FillWithAiDialog> createState() => _FillWithAiDialogState();
}

class _FillWithAiDialogState extends State<FillWithAiDialog>
    implements McpDescribableDialog {
  late final _instructions = TextEditingController(
    text: widget.instructions ?? '',
  );
  ShellServices? _registeredIn;
  SheetsFillProposal? _proposal;
  final Set<String> _accepted = {};
  bool _loading = false;
  bool _applying = false;
  String? _error;

  SheetsAiController get ai => widget.ai;

  @override
  void initState() {
    super.initState();
    unawaited(_generate());
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
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = _instructions.text.trim();
      final p = await ai.api.fillRange(
        ai.itemUuid,
        widget.range,
        text.isEmpty ? null : text,
      );
      if (!mounted) return;
      setState(() {
        _proposal = p;
        _accepted
          ..clear()
          ..addAll([
            for (final r in p.rows)
              if (r.value != null && r.confidence != 'low') r.cell,
          ]);
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SheetsFillRow> get _acceptedRows => [
    for (final r in _proposal?.rows ?? const <SheetsFillRow>[])
      if (_accepted.contains(r.cell) && r.value != null) r,
  ];

  bool get _canApply =>
      !_loading && !_applying && _acceptedRows.isNotEmpty && ai.editor.canEdit;

  Future<void> _apply() async {
    if (!_canApply) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      final r = await ai.api.applyFill(
        ai.itemUuid,
        _proposal!.range,
        _acceptedRows,
      );
      if (mounted) Navigator.of(context).pop(r);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _applying = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final p = _proposal;
    return {
      'title': sheetsL10nOf(ai.services).aiFillTitle,
      'range': widget.range,
      'loading': _loading,
      'error': ?_error,
      'fields': [
        {
          'id': 'instructions',
          'label': 'Instructions',
          'type': 'text',
          'value': _instructions.text,
        },
        {
          'id': 'accepted',
          'label': 'Accepted cells',
          'type': 'multiselect',
          'value': _accepted.toList(),
          'options': [for (final r in p?.rows ?? const []) r.cell],
        },
      ],
      if (p != null)
        'proposals': [
          for (final r in p.rows)
            {
              'cell': r.cell,
              'inputs': r.inputs,
              'value': r.value,
              'confidence': r.confidence,
            },
        ],
      'buttons': [
        {'id': 'cancel', 'label': 'Cancel'},
        {'id': 'generate', 'label': 'Regenerate', 'enabled': !_loading},
        {'id': 'apply', 'label': 'Apply', 'enabled': _canApply},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'instructions':
        setState(() => _instructions.text = '${value ?? ''}');
        return true;
      case 'accepted':
        if (value is! List) return false;
        setState(() {
          _accepted
            ..clear()
            ..addAll(value.map((e) => '$e'));
        });
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        Navigator.of(context).pop();
        return true;
      case 'generate':
        unawaited(_generate());
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
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final p = _proposal;
    final n = _acceptedRows.length;
    return ShadDialog(
      key: const ValueKey<String>('dialog.fillWithAi'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.aiFillTitle),
      description: Text(l.aiFillDescription(widget.range)),
      actions: [
        ShadButton.outline(
          key: const ValueKey<String>('dialog.fillWithAi.cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(la.actionCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('dialog.fillWithAi.apply'),
          enabled: _canApply,
          leading: _applying
              ? const SizedBox(width: 14, height: 14, child: ShadSpinner())
              : null,
          onPressed: () => unawaited(_apply()),
          child: Text(l.aiFillApply(n)),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 520),
        child: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: ShadInput(
                      key: const ValueKey<String>(
                        'dialog.fillWithAi.instructions',
                      ),
                      controller: _instructions,
                      enabled: !_loading,
                      placeholder: Text(l.aiFillInstructionsPlaceholder),
                      onSubmitted: (_) => unawaited(_generate()),
                    ),
                  ),
                  ShadButton.outline(
                    key: const ValueKey<String>('dialog.fillWithAi.generate'),
                    enabled: !_loading,
                    leading: const Icon(LucideIcons.refreshCw, size: 14),
                    onPressed: () => unawaited(_generate()),
                    child: Text(l.aiFillRegenerate),
                  ),
                ],
              ),
              if (_error != null)
                Text(
                  _error!,
                  key: const ValueKey<String>('dialog.fillWithAi.error'),
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: ShadSpinner(),
                      ),
                      const SizedBox(width: 8),
                      Text(l.aiFillGenerating, style: theme.textTheme.muted),
                    ],
                  ),
                )
              else if (p != null) ...[
                Text(
                  l.aiFillSummary(p.rows.length, p.examples),
                  style: theme.textTheme.muted,
                ),
                if (p.truncated)
                  Text(l.aiFillTruncated, style: theme.textTheme.muted),
                if (p.rows.isEmpty)
                  Text(l.aiFillNothing, style: theme.textTheme.small)
                else
                  Flexible(child: _table(context, p)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _table(BuildContext context, SheetsFillProposal p) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    final allOn = p.rows.every(
      (r) => r.value == null || _accepted.contains(r.cell),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 520;
        Widget header(String t, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(
            t,
            style: theme.textTheme.small.copyWith(
              color: cs.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  spacing: 8,
                  children: [
                    ShadCheckbox(
                      value: allOn,
                      onChanged: (v) => setState(() {
                        if (v) {
                          _accepted.addAll([
                            for (final r in p.rows)
                              if (r.value != null) r.cell,
                          ]);
                        } else {
                          _accepted.clear();
                        }
                      }),
                    ),
                    SizedBox(width: 56, child: Text(l.aiFillColumnCell)),
                    if (!narrow) header(l.aiFillColumnInputs, flex: 3),
                    header(l.aiFillColumnValue, flex: 2),
                    SizedBox(
                      width: 72,
                      child: Text(
                        l.aiFillColumnConfidence,
                        style: theme.textTheme.small.copyWith(
                          color: cs.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: cs.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: p.rows.length,
                  itemBuilder: (context, i) {
                    final r = p.rows[i];
                    final low = r.confidence == 'low';
                    final on = _accepted.contains(r.cell);
                    return Container(
                      key: ValueKey<String>('dialog.fillWithAi.row.${r.cell}'),
                      color: low
                          ? cs.destructive.withValues(alpha: 0.08)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          ShadCheckbox(
                            value: on,
                            enabled: r.value != null,
                            onChanged: (v) => setState(() {
                              if (v) {
                                _accepted.add(r.cell);
                              } else {
                                _accepted.remove(r.cell);
                              }
                            }),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text(
                              _cellLabel(r.cell),
                              style: theme.textTheme.small,
                            ),
                          ),
                          if (!narrow)
                            Expanded(
                              flex: 3,
                              child: Text(
                                r.inputs,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.value ?? '—',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.small,
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              _confidence(l, r.confidence),
                              style: theme.textTheme.small.copyWith(
                                color: low
                                    ? cs.destructive
                                    : cs.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _cellLabel(String cell) {
    final i = cell.lastIndexOf('!');
    return i < 0 ? cell : cell.substring(i + 1);
  }

  static String _confidence(SheetsLocalizations l, String c) => switch (c) {
    'high' => l.aiConfidenceHigh,
    'medium' => l.aiConfidenceMedium,
    _ => l.aiConfidenceLow,
  };
}
