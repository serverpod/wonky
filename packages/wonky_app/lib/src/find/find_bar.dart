import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// What a [WonkyFindBar] shows and edits: the app's find controller.
abstract interface class FindBarModel implements Listenable {
  /// The current query.
  String get query;

  /// Whether there is at least one match (previous/next are enabled).
  bool get hasResults;

  /// Fires when the query field should take the focus and select its text
  /// (find opened again while open).
  Listenable get focusRequest;

  /// Searches for [query].
  void setQuery(String query);
}

/// The texts of a [WonkyFindBar] (the app's localizations).
class FindBarLabels {
  const FindBarLabels({
    required this.placeholder,
    required this.previous,
    required this.next,
    required this.replace,
    required this.close,
  });

  final String placeholder;
  final String previous;
  final String next;
  final String replace;
  final String close;
}

/// The compact find bar of Sheets (07 §11.1) and Slides (03 §13): query,
/// "3 of 12", ↑/↓, *Find and replace*, ✕. Enter = next, Shift+Enter =
/// previous, Esc closes (CQ-53: one widget, each app passes its model,
/// commands and texts). Keys: `<keyPrefix>` (the bar), `.query`, `.status`,
/// `.previous`, `.next`, [replaceKeyName], `.close`.
class WonkyFindBar extends StatefulWidget {
  const WonkyFindBar({
    super.key,
    required this.model,
    required this.keyPrefix,
    required this.labels,
    required this.statusText,
    required this.onNext,
    required this.onPrevious,
    required this.onReplace,
    required this.onClose,
    this.replaceIcon = LucideIcons.replace,
    this.replaceKeyName = 'replace',
    this.queryWidth = 220,
  });

  final FindBarModel model;
  final String keyPrefix;
  final FindBarLabels labels;

  /// "3 of 12" / "No results" ('' for none).
  final String Function() statusText;

  /// Steps to the next / previous match of the query in the field.
  final Future<void> Function(String query) onNext;
  final Future<void> Function(String query) onPrevious;

  /// Opens *Find and replace* with the query in the field.
  final Future<void> Function(String query) onReplace;
  final Future<void> Function() onClose;

  final IconData replaceIcon;
  final String replaceKeyName;
  final double queryWidth;

  @override
  State<WonkyFindBar> createState() => _WonkyFindBarState();
}

class _WonkyFindBarState extends State<WonkyFindBar> {
  FindBarModel get f => widget.model;
  late final TextEditingController _text = TextEditingController(text: f.query);
  late final _focus = FocusNode(debugLabel: '${widget.keyPrefix}.query');

  @override
  void initState() {
    super.initState();
    f.addListener(_sync);
    f.focusRequest.addListener(_focusInput);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInput());
  }

  void _focusInput() {
    if (!mounted) return;
    _focus.requestFocus();
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
  }

  void _sync() {
    if (_text.text != f.query && !_focus.hasFocus) _text.text = f.query;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    f.removeListener(_sync);
    f.focusRequest.removeListener(_focusInput);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Steps to a match; the bar keeps the keyboard (showing a match may
  /// move the focus, e.g. into a text box).
  Future<void> _step(Future<void> Function(String) step) async {
    await step(_text.text);
    if (mounted) _focus.requestFocus();
  }

  KeyEventResult _keys(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      unawaited(widget.onClose());
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      unawaited(
        _step(
          HardwareKeyboard.instance.isShiftPressed
              ? widget.onPrevious
              : widget.onNext,
        ),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    final p = widget.keyPrefix;
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final status = widget.statusText();
    final has = f.hasResults;
    return Focus(
      onKeyEvent: _keys,
      child: Container(
        key: ValueKey<String>(p),
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cs.popover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SizedBox(
                width: widget.queryWidth,
                child: Semantics(
                  label: l.placeholder,
                  textField: true,
                  child: ShadInput(
                    key: ValueKey<String>('$p.query'),
                    controller: _text,
                    focusNode: _focus,
                    placeholder: Text(l.placeholder),
                    leading: Icon(
                      LucideIcons.search,
                      size: 15,
                      color: cs.mutedForeground,
                    ),
                    trailing: status.isEmpty
                        ? null
                        : Semantics(
                            liveRegion: true,
                            child: Text(
                              status,
                              key: ValueKey<String>('$p.status'),
                              style: theme.textTheme.muted.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                    onChanged: f.setQuery,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            FindIconButton(
              keyName: '$p.previous',
              icon: LucideIcons.chevronUp,
              tooltip: l.previous,
              onPressed: has ? () => unawaited(_step(widget.onPrevious)) : null,
            ),
            FindIconButton(
              keyName: '$p.next',
              icon: LucideIcons.chevronDown,
              tooltip: l.next,
              onPressed: has ? () => unawaited(_step(widget.onNext)) : null,
            ),
            FindIconButton(
              keyName: '$p.${widget.replaceKeyName}',
              icon: widget.replaceIcon,
              tooltip: l.replace,
              onPressed: () => unawaited(widget.onReplace(_text.text)),
            ),
            FindIconButton(
              keyName: '$p.close',
              icon: LucideIcons.x,
              tooltip: l.close,
              onPressed: () => unawaited(widget.onClose()),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small ghost icon button with a tooltip, a semantics label and a
/// stable key (find bars and find-and-replace panels).
class FindIconButton extends StatelessWidget {
  const FindIconButton({
    super.key,
    required this.keyName,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final String keyName;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ShadTooltip(
    builder: (_) => Text(tooltip),
    child: Semantics(
      button: true,
      label: tooltip,
      child: ShadIconButton.ghost(
        key: ValueKey<String>(keyName),
        width: 30,
        height: 30,
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        enabled: onPressed != null,
      ),
    ),
  );
}
