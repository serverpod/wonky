import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../commands/command_icons.dart';
import '../../l10n/write_l10n.dart';
import '../screen/command_invoke.dart';
import 'find_controller.dart';

/// The Find and replace side panel (Write 05 §10.5).
class FindPanel extends StatefulWidget {
  const FindPanel({
    super.key,
    required this.controller,
    required this.editable,
    this.onClose,
  });

  final FindController controller;

  /// Whether the replace row is usable (Editing/Suggesting with edit rights).
  final bool editable;

  /// Esc in the panel.
  final VoidCallback? onClose;

  @override
  State<FindPanel> createState() => _FindPanelState();
}

class _FindPanelState extends State<FindPanel> {
  late final TextEditingController _find = TextEditingController(
    text: widget.controller.query,
  );
  late final TextEditingController _replace = TextEditingController(
    text: widget.controller.replacement,
  );
  final _findFocus = FocusNode(debugLabel: 'find.query');
  final _replaceFocus = FocusNode(debugLabel: 'find.replace');
  final _scroll = ScrollController();

  FindController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _findFocus.requestFocus();
      _find.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _find.text.length,
      );
    });
  }

  void _sync() {
    if (_find.text != c.query) _find.text = c.query;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_sync);
    _find.dispose();
    _replace.dispose();
    _findFocus.dispose();
    _replaceFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final kb = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose?.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final mod = kb.isMetaPressed || kb.isControlPressed;
      if (mod && kb.isAltPressed) {
        _replaceAll();
      } else if (_replaceFocus.hasFocus && !kb.isShiftPressed) {
        _replaceOne();
      } else {
        invokeCommand(
          context,
          kb.isShiftPressed ? 'write.find.previous' : 'write.find.next',
        );
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _replaceOne() => invokeCommand(
    context,
    'write.find.replace',
    args: {'replacement': _replace.text},
  );

  void _replaceAll() => invokeCommand(
    context,
    'write.find.replaceAll',
    args: {'replacement': _replace.text},
  );

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final error = c.error;
    final canReplace = widget.editable && c.matches.isNotEmpty;
    return Focus(
      onKeyEvent: _keys,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: l.findPlaceholder,
                    child: ShadInput(
                      key: const ValueKey<String>('find.query'),
                      controller: _find,
                      focusNode: _findFocus,
                      placeholder: Text(l.findPlaceholder),
                      leading: Icon(
                        LucideIcons.search,
                        size: 16,
                        color: cs.mutedForeground,
                      ),
                      trailing: c.countLabel.isEmpty
                          ? null
                          : Semantics(
                              liveRegion: true,
                              child: Text(
                                c.countLabel,
                                key: const ValueKey<String>('find.count'),
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                      onChanged: (v) => c.query = v,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _IconAction(
                  keyName: 'find.previous',
                  icon: commandIcons['write.find.previous']!,
                  label: l.findPreviousMatch,
                  shortcut: shortcutOf(context, 'write.find.previous'),
                  onPressed: c.matches.isEmpty
                      ? null
                      : () => invokeCommand(context, 'write.find.previous'),
                ),
                _IconAction(
                  keyName: 'find.next',
                  icon: commandIcons['write.find.next']!,
                  label: l.findNextMatch,
                  shortcut: shortcutOf(context, 'write.find.next'),
                  onPressed: c.matches.isEmpty
                      ? null
                      : () => invokeCommand(context, 'write.find.next'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _OptionToggle(
                  keyName: 'find.matchCase',
                  label: l.findMatchCase,
                  value: c.matchCase,
                  onChanged: (v) => c.matchCase = v,
                  child: const Text('Aa'),
                ),
                const SizedBox(width: 4),
                _OptionToggle(
                  keyName: 'find.wholeWord',
                  label: l.findWholeWord,
                  value: c.wholeWord,
                  onChanged: (v) => c.wholeWord = v,
                  child: const Text(
                    'ab',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(width: 4),
                _OptionToggle(
                  keyName: 'find.regex',
                  label: l.findRegex,
                  value: c.regex,
                  onChanged: (v) => c.regex = v,
                  child: const Text('.*'),
                ),
                const Spacer(),
                ShadButton.ghost(
                  key: const ValueKey<String>('find.toggleReplace'),
                  size: ShadButtonSize.sm,
                  leading: Icon(
                    c.showReplace
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 14,
                  ),
                  onPressed: c.toggleReplace,
                  child: Text(l.findToggleReplace),
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                error,
                key: const ValueKey<String>('find.error'),
                style: theme.textTheme.small.copyWith(color: cs.destructive),
              ),
            ),
          if (c.showReplace) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ShadTooltip(
                builder: (_) => Text(
                  widget.editable ? l.findReplaceWith : l.findSearchOnly,
                ),
                child: Semantics(
                  label: l.findReplaceWith,
                  child: ShadInput(
                    key: const ValueKey<String>('find.replacement'),
                    controller: _replace,
                    focusNode: _replaceFocus,
                    enabled: widget.editable,
                    placeholder: Text(l.findReplaceWith),
                    leading: Icon(
                      LucideIcons.replace,
                      size: 16,
                      color: cs.mutedForeground,
                    ),
                    onChanged: (v) => c.replacement = v,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  ShadButton.outline(
                    key: const ValueKey<String>('find.replaceOne'),
                    size: ShadButtonSize.sm,
                    enabled: canReplace,
                    onPressed: _replaceOne,
                    child: Text(l.findReplaceOne),
                  ),
                  const SizedBox(width: 8),
                  ShadButton.secondary(
                    key: const ValueKey<String>('find.replaceAll'),
                    size: ShadButtonSize.sm,
                    enabled: canReplace,
                    onPressed: _replaceAll,
                    child: Text(l.findReplaceAll),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const ShadSeparator.horizontal(margin: EdgeInsets.zero),
          Expanded(child: _results(context)),
        ],
      ),
    );
  }

  Widget _results(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    if (!c.hasQuery) {
      return _hint(context, l.findTypeToSearch);
    }
    if (c.error != null) return const SizedBox.shrink();
    if (c.matches.isEmpty) {
      return _hint(
        context,
        l.findNoResultsFor(c.query),
        key: const ValueKey<String>('find.noResults'),
      );
    }
    return WonkyScrollArea(
      controller: _scroll,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: c.matches.length,
        itemBuilder: (context, i) {
          final m = c.matches[i];
          final active = i == c.current;
          return _ResultRow(
            key: ValueKey<String>('find.result.$i'),
            semanticLabel: l.findResultSemantic(
              i + 1,
              c.matches.length,
              m.text,
            ),
            match: m,
            active: active,
            onTap: () => c.goTo(i),
            theme: theme,
          );
        },
      ),
    );
  }

  Widget _hint(BuildContext context, String text, {Key? key}) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(key: key, text, style: theme.textTheme.muted),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.semanticLabel,
    required this.match,
    required this.active,
    required this.onTap,
    required this.theme,
  });

  final String semanticLabel;
  final SearchMatch match;
  final bool active;
  final VoidCallback onTap;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    String clean(String s) => s.replaceAll(RegExp(r'[\n￼]'), ' ');
    // Context stays within the match's block.
    final before = match.contextBefore.split('\n').last;
    final after = match.contextAfter.split('\n').first;
    final heading = match.headingPath.isEmpty ? null : match.headingPath.last;
    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: active ? cs.accent : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w400,
                      color: cs.foreground,
                    ),
                    children: [
                      TextSpan(
                        text: before.length < match.contextBefore.length
                            ? clean(before)
                            : '…${clean(before)}',
                      ),
                      TextSpan(
                        text: clean(match.text),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          backgroundColor: cs.findMatch,
                        ),
                      ),
                      TextSpan(
                        text: after.length < match.contextAfter.length
                            ? clean(after)
                            : '${clean(after)}…',
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (heading != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionToggle extends StatelessWidget {
  const _OptionToggle({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.child,
  });

  final String keyName;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => ShadTooltip(
    builder: (_) => Text(label),
    child: ShadToggle(
      key: ValueKey<String>(keyName),
      value: value,
      onChanged: onChanged,
      width: 32,
      height: 28,
      padding: EdgeInsets.zero,
      semanticLabel: label,
      textStyle: ShadTheme.of(
        context,
      ).textTheme.small.copyWith(fontFamily: WonkyTheme.monoFamily),
      child: child,
    ),
  );
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.shortcut,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final List<String>? shortcut;

  @override
  Widget build(BuildContext context) => ShadTooltip(
    builder: (_) => ToolbarTooltipContent(label: label, shortcut: shortcut),
    child: ShadIconButton.ghost(
      key: ValueKey<String>(keyName),
      width: 30,
      height: 30,
      iconSize: 16,
      semanticLabel: label,
      enabled: onPressed != null,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}
