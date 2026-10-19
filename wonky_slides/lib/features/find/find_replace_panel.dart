import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/find.dart';

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import 'find_bar.dart' show findStatusText;
import 'find_controller.dart';

/// *Find and replace* (03 §13, ⇧⌘H): a non-modal panel over the canvas
/// (the deck stays interactive). Fields `find`, `replace`, `matchCase`,
/// `wholeWords`, `useRegex`, `includeNotes`, `includeSkipped`, `scope`;
/// buttons Previous, Next ("3 of 12"), Replace, Replace all, Done. The MCP
/// UI bridge describes, fills and presses it (`dialog.slides.findReplace`).
class FindReplacePanel extends StatefulWidget {
  const FindReplacePanel({super.key, required this.editor});

  final DeckEditorController editor;

  static const panelKey = ValueKey<String>('dialog.slides.findReplace');

  @override
  State<FindReplacePanel> createState() => _FindReplacePanelState();
}

class _FindReplacePanelState extends State<FindReplacePanel>
    implements McpDescribableDialog {
  late final DeckFindController f = DeckFindController.of(widget.editor);
  late final TextEditingController _find = TextEditingController(text: f.query);
  late final TextEditingController _replace = TextEditingController(
    text: f.replacement,
  );
  final _focus = FocusNode(debugLabel: 'slides.findReplace.find');
  ShellServices? _registeredIn;

  DeckEditorController get ed => widget.editor;
  DeckFindOptions get _o => f.options;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    if (s == _registeredIn) return;
    _registeredIn?.openDialogs.remove(this);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  void _changed() {
    if (!mounted) return;
    if (_find.text != f.query && !_focus.hasFocus) _find.text = f.query;
    setState(() {});
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    f.removeListener(_changed);
    _find.dispose();
    _replace.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setOptions(DeckFindOptions o) => f.search(_find.text, options: o);

  Map<String, Object?> get _args => {
    'find': _find.text,
    'replace': _replace.text,
    ...findOptionsArgs(_o),
  };

  Future<void> _run(String id, [Map<String, Object?>? args]) => ed
      .services
      .dispatcher
      .invoke(id, args: args ?? _args, source: InvocationSource.ui);

  Future<void> _step(bool forward) async {
    f.replacement = _replace.text;
    await _run(forward ? 'slides.find.next' : 'slides.find.previous', {
      'query': _find.text,
      ...findOptionsArgs(_o),
    });
    if (mounted) _focus.requestFocus();
  }

  void _replaceOne() {
    if (_find.text.isEmpty) return;
    f.replacement = _replace.text;
    unawaited(_run('slides.find.replace'));
  }

  void _replaceAll() {
    if (_find.text.isEmpty) return;
    f.replacement = _replace.text;
    unawaited(_run('slides.find.replaceAll'));
  }

  void _done() {
    f.replacement = _replace.text;
    unawaited(_run('slides.find.close', const {}));
  }

  // ---- MCP ----

  List<(String, String, bool)> _checks(SlidesLocalizations l) => [
    ('matchCase', l.findMatchCase, _o.matchCase),
    ('wholeWords', l.findWholeWords, _o.wholeWords),
    ('useRegex', l.findUseRegex, _o.useRegex),
    ('includeNotes', l.findIncludeNotes, _o.includeNotes),
    ('includeSkipped', l.findIncludeSkipped, _o.includeSkipped),
  ];

  DeckFindOptions _withCheck(String id, bool v) => switch (id) {
    'matchCase' => _o.copyWith(matchCase: v),
    'wholeWords' => _o.copyWith(wholeWords: v),
    'useRegex' => _o.copyWith(useRegex: v),
    'includeNotes' => _o.copyWith(includeNotes: v),
    'includeSkipped' => _o.copyWith(includeSkipped: v),
    _ => _o,
  };

  static String _scopeLabel(SlidesLocalizations l, FindScope s) => switch (s) {
    FindScope.all => l.findScopeAll,
    FindScope.currentSlide => l.findScopeCurrent,
    FindScope.selectedSlides => l.findScopeSelected,
  };

  @override
  Map<String, Object?> describe() {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    return {
      'dialogKey': 'dialog.slides.findReplace',
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
          'id': 'scope',
          'label': l.findScope,
          'type': 'select',
          'value': findScopeName(_o.scope),
          'options': [for (final s in FindScope.values) findScopeName(s)],
          'optionLabels': {
            for (final s in FindScope.values)
              findScopeName(s): _scopeLabel(l, s),
          },
        },
        for (final (id, label, v) in _checks(l))
          {'id': id, 'label': label, 'type': 'checkbox', 'value': v},
      ],
      'status': findStatusText(l, f),
      'buttons': [
        {'id': 'previous', 'label': l.findButtonPrevious},
        {'id': 'next', 'label': l.findButtonNext},
        {'id': 'replace', 'label': l.cmdFindReplace},
        {'id': 'replaceAll', 'label': l.cmdFindReplaceAll},
        {'id': 'done', 'label': la.actionDone},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'find':
        _find.text = '${value ?? ''}';
        f.search(_find.text);
      case 'replace':
        _replace.text = '${value ?? ''}';
        f.replacement = _replace.text;
      case 'scope':
        final scope = findScopeOf(value);
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
      case 'previous':
        unawaited(_step(false));
      case 'next':
        unawaited(_step(true));
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
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final status = findStatusText(l, f);
    final canEdit = ed.canEdit;
    final hasQuery = _find.text.isNotEmpty;
    return Focus(
      onKeyEvent: (node, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          _done();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        key: FindReplacePanel.panelKey,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l.findReplaceTitle,
                          style: theme.textTheme.large.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                    FindIconButton(
                      keyName: 'dialog.slides.findReplace.close',
                      icon: LucideIcons.x,
                      tooltip: l.findClose,
                      onPressed: _done,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _labeled(
                      l.findLabel,
                      ShadInput(
                        key: const ValueKey<String>(
                          'dialog.slides.findReplace.find',
                        ),
                        controller: _find,
                        focusNode: _focus,
                        trailing: status.isEmpty
                            ? null
                            : Semantics(
                                liveRegion: true,
                                child: Text(
                                  status,
                                  key: const ValueKey<String>(
                                    'dialog.slides.findReplace.status',
                                  ),
                                  style: theme.textTheme.muted.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                        onChanged: (v) => f.search(v),
                        onSubmitted: (_) => unawaited(_step(true)),
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
                          'dialog.slides.findReplace.replace',
                        ),
                        controller: _replace,
                        enabled: canEdit,
                        onChanged: (v) => f.replacement = v,
                        onSubmitted: (_) => _replaceOne(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _labeled(
                      l.findScope,
                      ShadSelect<FindScope>(
                        key: ValueKey<String>(
                          'dialog.slides.findReplace.scope.${_o.scope.name}',
                        ),
                        initialValue: _o.scope,
                        options: [
                          for (final s in FindScope.values)
                            ShadOption(
                              value: s,
                              child: Text(_scopeLabel(l, s)),
                            ),
                        ],
                        selectedOptionBuilder: (context, v) =>
                            Text(_scopeLabel(l, v)),
                        onChanged: (v) {
                          if (v != null) _setOptions(_o.copyWith(scope: v));
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final (id, label, v) in _checks(l))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: ShadCheckbox(
                          key: ValueKey<String>(
                            'dialog.slides.findReplace.$id',
                          ),
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
                        'dialog.slides.findReplace.previous',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: hasQuery ? () => _step(false) : null,
                      child: Text(l.findButtonPrevious),
                    ),
                    ShadButton.outline(
                      key: const ValueKey<String>(
                        'dialog.slides.findReplace.next',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: hasQuery ? () => _step(true) : null,
                      child: Text(l.findButtonNext),
                    ),
                    ShadButton.outline(
                      key: const ValueKey<String>(
                        'dialog.slides.findReplace.replaceOne',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: canEdit && hasQuery ? _replaceOne : null,
                      child: Text(l.cmdFindReplace),
                    ),
                    ShadButton.outline(
                      key: const ValueKey<String>(
                        'dialog.slides.findReplace.replaceAll',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: canEdit && hasQuery ? _replaceAll : null,
                      child: Text(l.cmdFindReplaceAll),
                    ),
                    ShadButton(
                      key: const ValueKey<String>(
                        'dialog.slides.findReplace.done',
                      ),
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

/// The args names of [o] (commands, MCP).
Map<String, Object?> findOptionsArgs(DeckFindOptions o) => {
  'matchCase': o.matchCase,
  'wholeWords': o.wholeWords,
  'useRegex': o.useRegex,
  'includeNotes': o.includeNotes,
  'includeSkipped': o.includeSkipped,
  'scope': findScopeName(o.scope),
};

/// `all`, `current`, `selected`.
String findScopeName(FindScope s) => switch (s) {
  FindScope.all => 'all',
  FindScope.currentSlide => 'current',
  FindScope.selectedSlides => 'selected',
};

FindScope? findScopeOf(Object? v) => switch (v) {
  'all' => FindScope.all,
  'current' => FindScope.currentSlide,
  'selected' => FindScope.selectedSlides,
  _ => null,
};
