import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/wonky_ui_localizations.dart';
import '../../theme/wonky_theme.dart';

/// Lets File › Rename put a [DocumentTitleField] into edit mode.
class DocumentTitleFieldController {
  _DocumentTitleFieldState? _state;

  /// Switches to the input and selects the title.
  void startEditing() => _state?._startEditing();

  bool get isEditing => _state?._editing ?? false;
}

/// Inline-editable title in the editor header (suite 02 §4.15): looks like
/// text, becomes a `ShadInput` on click; Enter/blur commits through
/// [onRename] (a rename command — undoable), Esc reverts; auto-width up to
/// 400 px. Read-only (viewers) renders plain text.
class DocumentTitleField extends StatefulWidget {
  const DocumentTitleField({
    super.key,
    required this.title,
    this.onRename,
    this.readOnly = false,
    this.placeholder,
    this.controller,
    this.maxLength = 255,
  });

  final String title;

  /// Called with the trimmed new title. Empty input reverts.
  final FutureOr<void> Function(String title)? onRename;
  final bool readOnly;

  /// Shown when [title] is empty ("Untitled document").
  final String? placeholder;
  final DocumentTitleFieldController? controller;
  final int maxLength;

  @override
  State<DocumentTitleField> createState() => _DocumentTitleFieldState();
}

class _DocumentTitleFieldState extends State<DocumentTitleField> {
  final _text = TextEditingController();
  final _focus = FocusNode(debugLabel: 'DocumentTitleField');
  bool _editing = false;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) unawaited(_commit());
    });
  }

  @override
  void didUpdateWidget(DocumentTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.readOnly || widget.onRename == null) return;
    setState(() {
      _editing = true;
      _text.text = widget.title;
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.title.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _cancel() {
    setState(() => _editing = false);
  }

  Future<void> _commit() async {
    final value = _text.text.trim();
    setState(() => _editing = false);
    if (value.isEmpty || value == widget.title) return;
    await widget.onRename?.call(value);
  }

  double _measure(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = WonkyUiLocalizations.of(context);
    final maxWidth = WonkyThemeScope.of(context).maxTitleWidth;
    final style = theme.textTheme.large.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 17,
    );
    final shown = widget.title.isEmpty
        ? (widget.placeholder ?? l10n.titleUntitled)
        : widget.title;

    if (_editing) {
      final w = (_measure(_text.text.isEmpty ? shown : _text.text, style) + 28)
          .clamp(80.0, maxWidth);
      return SizedBox(
        width: w,
        height: 32,
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
          child: ShadInput(
            key: const ValueKey<String>('titleField.input'),
            controller: _text,
            focusNode: _focus,
            style: style,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            maxLength: widget.maxLength,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp('[/\n]')),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _commit(),
          ),
        ),
      );
    }

    final textWidget = Text(
      shown,
      key: const ValueKey<String>('titleField.text'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(
        color: widget.title.isEmpty ? theme.colorScheme.mutedForeground : null,
      ),
    );
    if (widget.readOnly || widget.onRename == null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Semantics(header: true, child: textWidget),
      );
    }
    return Semantics(
      button: true,
      label: '${l10n.titleRename}: $shown',
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.text,
        onShowHoverHighlight: (h) => setState(() => _hover = h),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _startEditing();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: _startEditing,
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: focused
                        ? theme.colorScheme.ring
                        : _hover
                        ? theme.colorScheme.border
                        : const Color(0x00000000),
                  ),
                ),
                child: textWidget,
              );
            },
          ),
        ),
      ),
    );
  }
}
