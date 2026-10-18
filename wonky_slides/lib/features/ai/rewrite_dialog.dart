import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';
import 'ai_widgets.dart';
import 'slides_ai_api.dart';

/// Stable widget keys of the rewrite dialog.
abstract final class RewriteKeys {
  static const dialog = ValueKey<String>('dialog.slides.aiRewrite');
  static const instruction = ValueKey<String>(
    'dialog.slides.aiRewrite.instruction',
  );
  static const result = ValueKey<String>('dialog.slides.aiRewrite.result');
  static const refine = ValueKey<String>('dialog.slides.aiRewrite.refine');
  static const replace = ValueKey<String>('dialog.slides.aiRewrite.replace');
  static const retry = ValueKey<String>('dialog.slides.aiRewrite.retry');
  static const discard = ValueKey<String>('dialog.slides.aiRewrite.discard');
  static const start = ValueKey<String>('dialog.slides.aiRewrite.start');
}

/// *Rewrite text* (Slides 11 §6.5): streams the rewritten Markdown of one
/// text box next to the original; *Replace* (Enter) returns it, *Try
/// again*, *Refine* ("even shorter") and *Discard* (Esc). Custom mode first
/// asks how the text should change. When the box's text changed meanwhile
/// ([currentMarkdown] differs from the original), *Replace* is off and the
/// dialog offers *Copy*. MCP-operable. Returns the Markdown to write, or
/// null.
Future<String?> showRewriteDialog(
  BuildContext context, {
  required SlidesAiApi api,
  required UuidValue itemUuid,
  required SlidesAiRewriteRequest request,
  required String Function() currentMarkdown,
  required String title,
}) => showShadDialog<String>(
  context: context,
  builder: (_) => RewriteDialog(
    api: api,
    itemUuid: itemUuid,
    request: request,
    currentMarkdown: currentMarkdown,
    title: title,
  ),
);

class RewriteDialog extends StatefulWidget {
  const RewriteDialog({
    super.key,
    required this.api,
    required this.itemUuid,
    required this.request,
    required this.currentMarkdown,
    required this.title,
  });

  final SlidesAiApi api;
  final UuidValue itemUuid;
  final SlidesAiRewriteRequest request;
  final String Function() currentMarkdown;
  final String title;

  @override
  State<RewriteDialog> createState() => _RewriteDialogState();
}

class _RewriteDialogState extends State<RewriteDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  final TextEditingController _instruction = TextEditingController();
  final TextEditingController _refine = TextEditingController();
  final StringBuffer _text = StringBuffer();
  String? _result;
  String? _error;
  bool _running = false;
  bool _copied = false;
  StreamSubscription<InlineAiEvent>? _sub;

  bool get _needsInstruction =>
      widget.request.mode == 'custom' &&
      (widget.request.instruction ?? '').trim().isEmpty;

  bool _asked = false;

  @override
  void initState() {
    super.initState();
    if (!_needsInstruction) _run();
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
    unawaited(_sub?.cancel());
    _instruction.dispose();
    _refine.dispose();
    super.dispose();
  }

  bool get _changed =>
      widget.currentMarkdown().trim() != widget.request.markdown.trim();

  void _run({String? refine}) {
    final r = widget.request;
    final instruction = _needsInstruction || _asked
        ? _instruction.text.trim()
        : r.instruction;
    _asked = _asked || _needsInstruction;
    final request = r.copyWith(
      instruction: refine?.trim().isNotEmpty == true
          ? refine!.trim()
          : instruction,
      previous: refine?.trim().isNotEmpty == true ? _result : null,
    );
    unawaited(_sub?.cancel());
    setState(() {
      _running = true;
      _error = null;
      _copied = false;
      _text.clear();
    });
    _sub = widget.api
        .rewrite(widget.itemUuid, request)
        .listen(
          (e) {
            if (!mounted) return;
            setState(() {
              switch (e.type) {
                case InlineAiEventType.textDelta:
                  _text.write(e.text ?? '');
                case InlineAiEventType.done:
                  _result = e.markdown ?? _text.toString().trim();
                  _running = false;
                case InlineAiEventType.refusal || InlineAiEventType.error:
                  _error = e.error;
                  _running = false;
              }
            });
          },
          onError: (Object err) {
            if (mounted) {
              setState(() {
                _error = errorMessage(err);
                _running = false;
              });
            }
          },
          onDone: () {
            if (mounted && _running) setState(() => _running = false);
          },
        );
  }

  bool get _canReplace => !_running && _result != null && !_changed;

  void _replace() {
    if (!_canReplace) return;
    Navigator.of(context).pop(_result);
  }

  Future<void> _copy() async {
    final r = _result;
    if (r == null) return;
    await Clipboard.setData(ClipboardData(text: r));
    if (mounted) setState(() => _copied = true);
  }

  void _discard() {
    unawaited(_sub?.cancel());
    Navigator.of(context).pop();
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final l = slidesL10nOf(_registeredIn ?? ShellScope.of(context));
    final asking = _needsInstruction && !_asked;
    return {
      'title': widget.title,
      'mode': widget.request.mode,
      'original': widget.request.markdown,
      'running': _running,
      'result': ?_result,
      if (_running) 'progress': _text.toString(),
      'error': ?_error,
      'text_changed': _changed,
      'fields': [
        if (asking)
          {
            'id': 'instruction',
            'label': l.aiRewriteCustomLabel,
            'type': 'text',
            'value': _instruction.text,
          }
        else
          {
            'id': 'refine',
            'label': l.aiRewriteRefineHint,
            'type': 'text',
            'value': _refine.text,
          },
      ],
      'buttons': [
        {'id': 'discard', 'label': l.aiRewriteDiscard, 'enabled': true},
        if (asking)
          {
            'id': 'start',
            'label': l.aiRewriteTitle,
            'enabled': _instruction.text.trim().isNotEmpty,
          }
        else ...[
          {'id': 'retry', 'label': l.aiRewriteTryAgain, 'enabled': !_running},
          {
            'id': 'refine',
            'label': l.aiRewriteRefine,
            'enabled': !_running && _result != null,
          },
          if (_changed)
            {'id': 'copy', 'label': l.aiRewriteCopy, 'enabled': _result != null}
          else
            {
              'id': 'replace',
              'label': l.aiRewriteReplace,
              'enabled': _canReplace,
            },
        ],
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'instruction':
        _instruction.text = '${value ?? ''}';
      case 'refine':
        _refine.text = '${value ?? ''}';
      default:
        return false;
    }
    setState(() {});
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'discard' || 'cancel':
        _discard();
        return true;
      case 'start' when _instruction.text.trim().isNotEmpty:
        _run();
        return true;
      case 'retry' when !_running:
        _run();
        return true;
      case 'refine' when !_running && _result != null:
        _run(refine: _refine.text);
        return true;
      case 'replace' when _canReplace:
        _replace();
        return true;
      case 'copy' when _result != null:
        unawaited(_copy());
        return true;
    }
    return false;
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final asking = _needsInstruction && !_asked;
    final changed = !_running && _result != null && _changed;
    Widget box(String label, String text, {Key? key, bool muted = false}) =>
        AiField(
          label: label,
          child: Container(
            key: key,
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: muted ? cs.muted : null,
              border: Border.all(color: cs.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: Text(
                text,
                style: muted ? theme.textTheme.muted : theme.textTheme.small,
              ),
            ),
          ),
        );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (asking) {
            if (_instruction.text.trim().isNotEmpty) _run();
          } else {
            _replace();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): _discard,
      },
      child: ShadDialog(
        closeIcon: const WonkyDialogCloseButton(),
        constraints: const BoxConstraints(maxWidth: 600),
        key: RewriteKeys.dialog,
        title: Text(widget.title),
        actions: [
          ShadButton.outline(
            key: RewriteKeys.discard,
            onPressed: _discard,
            child: Text(l.aiRewriteDiscard),
          ),
          if (asking)
            ShadButton(
              key: RewriteKeys.start,
              enabled: _instruction.text.trim().isNotEmpty,
              onPressed: _run,
              child: Text(l.aiRewriteTitle),
            )
          else ...[
            ShadButton.outline(
              key: RewriteKeys.retry,
              enabled: !_running,
              leading: const Icon(LucideIcons.refreshCw, size: 14),
              onPressed: _run,
              child: Text(l.aiRewriteTryAgain),
            ),
            if (changed)
              ShadButton(
                onPressed: () => unawaited(_copy()),
                child: Text(_copied ? l.aiRewriteCopied : l.aiRewriteCopy),
              )
            else
              ShadButton(
                key: RewriteKeys.replace,
                enabled: _canReplace,
                onPressed: _replace,
                child: Text(l.aiRewriteReplace),
              ),
          ],
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                if (asking)
                  AiField(
                    label: l.aiRewriteCustomLabel,
                    child: ShadInput(
                      key: RewriteKeys.instruction,
                      controller: _instruction,
                      autofocus: true,
                      placeholder: Text(l.aiRewriteCustomHint),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (_instruction.text.trim().isNotEmpty) _run();
                      },
                    ),
                  ),
                box(l.aiRewriteOriginal, widget.request.markdown, muted: true),
                if (!asking) ...[
                  if (_error != null)
                    AiError(_error!)
                  else if (_running && _text.isEmpty)
                    AiWorking(label: l.aiRewriteWorking)
                  else
                    box(
                      l.aiRewriteResult,
                      _result ?? _text.toString(),
                      key: RewriteKeys.result,
                    ),
                  if (changed) AiError(l.aiRewriteChanged),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: ShadInput(
                          key: RewriteKeys.refine,
                          controller: _refine,
                          enabled: !_running && _result != null,
                          placeholder: Text(l.aiRewriteRefineHint),
                          onSubmitted: (v) => _run(refine: v),
                        ),
                      ),
                      ShadButton.outline(
                        enabled: !_running && _result != null,
                        onPressed: () => _run(refine: _refine.text),
                        child: Text(l.aiRewriteRefine),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
