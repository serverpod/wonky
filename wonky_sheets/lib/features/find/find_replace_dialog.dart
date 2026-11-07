import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../l10n/sheets_l10n.dart';
import '../data_tools/mcp_dialog.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'find_bar.dart' show findStatusText;
import 'find_controller.dart';

/// Find and replace (04 §11.7, 07 §11.2): non-modal and draggable; the grid
/// stays interactive. Fields `find`, `replace`, `searchIn` (+ `range`),
/// `matchCase`, `matchEntireCell`, `useRegex`, `searchFormulas`,
/// `searchLinks`; buttons Find, Replace, Replace all, Done.
class FindReplaceDialog extends StatefulWidget {
  const FindReplaceDialog({
    super.key,
    required this.editor,
    required this.find,
    required this.bounds,
  });

  final SheetEditorController editor;
  final FindController find;

  /// The area the dialog may be dragged in.
  final Size bounds;

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog>
    with McpDialogState<FindReplaceDialog> {
  late final TextEditingController _find = TextEditingController(
    text: widget.find.query,
  );
  final _replace = TextEditingController();
  late final TextEditingController _range = TextEditingController(
    text: widget.find.options.range ?? widget.editor.selection.describe(),
  );
  late FindOptions _o = widget.find.options;
  Offset? _pos;
  final _focus = FocusNode(debugLabel: 'sheets.findReplace.find');

  FindController get f => widget.find;
  SheetEditorController get ed => widget.editor;

  @override
  void initState() {
    super.initState();
    f.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _find.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _find.text.length,
      );
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    f.removeListener(_changed);
    _find.dispose();
    _replace.dispose();
    _range.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search() => f.setQuery(
    _find.text,
    options: _o.copyWith(
      range: _o.scope == FindScope.range ? _range.text.trim() : null,
    ),
    select: false,
  );

  void _setOptions(FindOptions o) {
    setState(() => _o = o);
    _search();
  }

  Map<String, Object?> get _args => {
    'find': _find.text,
    'replace': _replace.text,
    ..._o.copyWith(range: _range.text.trim()).toArgs(),
  };

  void _next() {
    if (_find.text != f.query) _search();
    unawaited(ed.invokeCommand('sheets.find.next'));
  }

  void _replaceOne() {
    if (_find.text.isEmpty) return;
    if (_find.text != f.query) _search();
    if (f.currentMatch == null) {
      _next();
      return;
    }
    unawaited(ed.invokeCommand('sheets.find.replace', _args));
  }

  void _replaceAll() {
    if (_find.text.isEmpty) return;
    unawaited(ed.invokeCommand('sheets.find.replaceAll', _args));
  }

  void _done() => unawaited(ed.invokeCommand('sheets.find.close'));

  // ---- MCP ----

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.findReplaceTitle,
      'fields': [
        {
          'id': 'find',
          'label': l.findLabel,
          'type': 'text',
          'value': _find.text,
        },
        {
          'id': 'replace',
          'label': l.replaceLabel,
          'type': 'text',
          'value': _replace.text,
        },
        {
          'id': 'searchIn',
          'label': l.findSearchIn,
          'type': 'select',
          'value': _o.toArgs()['scope'],
          'options': ['allSheets', 'sheet', 'range'],
        },
        {
          'id': 'range',
          'label': l.findRange,
          'type': 'text',
          'value': _range.text,
        },
        for (final (id, label, v) in _checks(l))
          {'id': id, 'label': label, 'type': 'checkbox', 'value': v},
      ],
      'status': findStatusText(l, f),
      'buttons': [
        {'id': 'find', 'label': l.findButton},
        {'id': 'replace', 'label': l.cmdFindReplace},
        {'id': 'replaceAll', 'label': l.cmdFindReplaceAll},
        {'id': 'done', 'label': WonkyAppLocalizations.of(context).actionDone},
      ],
    };
  }

  List<(String, String, bool)> _checks(SheetsLocalizations l) => [
    ('matchCase', l.findMatchCase, _o.matchCase),
    ('matchEntireCell', l.findMatchEntireCell, _o.entireCell),
    ('useRegex', l.findUseRegex, _o.regex),
    ('searchFormulas', l.findSearchFormulas, _o.searchFormulas),
    ('searchLinks', l.findSearchLinks, _o.searchLinks),
  ];

  FindOptions _withCheck(String id, bool v) => switch (id) {
    'matchCase' => _o.copyWith(matchCase: v),
    'matchEntireCell' => _o.copyWith(entireCell: v),
    'useRegex' => _o.copyWith(regex: v),
    'searchFormulas' => _o.copyWith(searchFormulas: v),
    'searchLinks' => _o.copyWith(searchLinks: v),
    _ => _o,
  };

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'find':
        _find.text = '${value ?? ''}';
        _search();
      case 'replace':
        _replace.text = '${value ?? ''}';
      case 'range':
        _range.text = '${value ?? ''}';
        _search();
      case 'searchIn':
        final scope = switch (value) {
          'allSheets' => FindScope.allSheets,
          'sheet' => FindScope.sheet,
          'range' => FindScope.range,
          _ => null,
        };
        if (scope == null) return false;
        _setOptions(_o.copyWith(scope: scope));
      default:
        if (value is! bool) return false;
        final o = _withCheck(id, value);
        if (identical(o, _o)) return false;
        _setOptions(o);
    }
    setState(() {});
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'find':
        _next();
      case 'replace':
        _replaceOne();
      case 'replaceAll':
        _replaceAll();
      case 'done':
        _done();
      default:
        return false;
    }
    return true;
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    const width = 420.0;
    final maxW = widget.bounds.width - 16;
    final w = width > maxW ? maxW : width;
    final pos =
        _pos ??
        Offset(((widget.bounds.width - w) / 2).clamp(8, double.infinity), 24);
    final status = findStatusText(l, f);
    final canEdit = ed.canEdit;
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: w,
      child: Focus(
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _done();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          key: const ValueKey<String>('dialog.findReplace'),
          decoration: BoxDecoration(
            color: cs.popover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.move,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) {
                    final p = (_pos ?? pos) + d.delta;
                    setState(
                      () => _pos = Offset(
                        p.dx.clamp(0, widget.bounds.width - 80),
                        p.dy.clamp(0, widget.bounds.height - 40),
                      ),
                    );
                  },
                  // No X: *Done* closes it (suite 02 §4.20).
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      l.findReplaceTitle,
                      style: theme.textTheme.large.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _labeled(
                      l.findLabel,
                      ShadInput(
                        key: const ValueKey<String>('dialog.findReplace.find'),
                        controller: _find,
                        focusNode: _focus,
                        trailing: status.isEmpty
                            ? null
                            : Text(
                                status,
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                        onChanged: (_) => _search(),
                        onSubmitted: (_) => _next(),
                      ),
                    ),
                    if (f.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          f.error!,
                          style: theme.textTheme.small.copyWith(
                            color: cs.destructive,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _labeled(
                      l.replaceLabel,
                      ShadInput(
                        key: const ValueKey<String>(
                          'dialog.findReplace.replace',
                        ),
                        controller: _replace,
                        enabled: canEdit,
                        onSubmitted: (_) => _replaceOne(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _labeled(
                      l.findSearchIn,
                      ShadSelect<FindScope>(
                        key: ValueKey<String>(
                          'dialog.findReplace.searchIn.${_o.scope.name}',
                        ),
                        initialValue: _o.scope,
                        options: [
                          ShadOption(
                            value: FindScope.allSheets,
                            child: Text(l.findAllSheets),
                          ),
                          ShadOption(
                            value: FindScope.sheet,
                            child: Text(l.findThisSheet),
                          ),
                          ShadOption(
                            value: FindScope.range,
                            child: Text(l.findSpecificRange),
                          ),
                        ],
                        selectedOptionBuilder: (context, v) => Text(switch (v) {
                          FindScope.allSheets => l.findAllSheets,
                          FindScope.sheet => l.findThisSheet,
                          FindScope.range => l.findSpecificRange,
                        }),
                        onChanged: (v) {
                          if (v != null) _setOptions(_o.copyWith(scope: v));
                        },
                      ),
                    ),
                    if (_o.scope == FindScope.range) ...[
                      const SizedBox(height: 6),
                      ShadInput(
                        key: const ValueKey<String>('dialog.findReplace.range'),
                        controller: _range,
                        placeholder: const Text('A1:D20'),
                        onChanged: (_) => _search(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    for (final (id, label, v) in _checks(l))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: ShadCheckbox(
                          key: ValueKey<String>('dialog.findReplace.$id'),
                          value: v,
                          onChanged: (nv) => _setOptions(_withCheck(id, nv)),
                          label: Text(label),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ShadButton.outline(
                      key: const ValueKey<String>(
                        'dialog.findReplace.find.btn',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: _find.text.isEmpty ? null : _next,
                      child: Text(l.findButton),
                    ),
                    ShadButton.outline(
                      key: const ValueKey<String>(
                        'dialog.findReplace.replace.btn',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: !canEdit || _find.text.isEmpty
                          ? null
                          : _replaceOne,
                      child: Text(l.cmdFindReplace),
                    ),
                    ShadButton.outline(
                      key: const ValueKey<String>(
                        'dialog.findReplace.replaceAll',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: !canEdit || _find.text.isEmpty
                          ? null
                          : _replaceAll,
                      child: Text(l.cmdFindReplaceAll),
                    ),
                    ShadButton(
                      key: const ValueKey<String>('dialog.findReplace.done'),
                      size: ShadButtonSize.sm,
                      onPressed: _done,
                      child: Text(la.actionDone),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.small),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
