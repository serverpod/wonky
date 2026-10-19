import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';
import 'ai_widgets.dart';
import 'slides_ai_controller.dart';

/// Stable widget keys of the alt-text dialog.
abstract final class AltTextDialogKeys {
  static const dialog = ValueKey<String>('dialog.slides.aiAltText');
  static const apply = ValueKey<String>('dialog.slides.aiAltText.apply');
  static ValueKey<String> check(String id) =>
      ValueKey<String>('dialog.slides.aiAltText.check.$id');
  static ValueKey<String> text(String id) =>
      ValueKey<String>('dialog.slides.aiAltText.text.$id');
}

/// *Generate alt text* (Slides 11 §6.8; the Accessibility panel's *Generate
/// with AI* and *Generate missing alt text*): asks the server for
/// descriptions of [elementIds] (empty = every object missing alt text),
/// then lists them as editable suggestions with a checkbox each (objects
/// that can't be described say why). *Apply* returns `{elementId: alt}`;
/// the command writes them as one undo step. MCP-operable.
Future<Map<String, String>?> showAltTextGenerateDialog(
  BuildContext context, {
  required SlidesAiController ai,
  required List<String> elementIds,
}) => showShadDialog<Map<String, String>>(
  context: context,
  builder: (_) => AltTextGenerateDialog(ai: ai, elementIds: elementIds),
);

class AltTextGenerateDialog extends StatefulWidget {
  const AltTextGenerateDialog({
    super.key,
    required this.ai,
    required this.elementIds,
  });

  final SlidesAiController ai;
  final List<String> elementIds;

  @override
  State<AltTextGenerateDialog> createState() => _AltTextGenerateDialogState();
}

class _AltTextGenerateDialogState extends State<AltTextGenerateDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  List<SlidesAiAltText>? _items;
  final Map<String, TextEditingController> _texts = {};
  final Set<String> _checked = {};
  String? _error;

  SlidesAiController get ai => widget.ai;
  SlidesLocalizations get l => ai.l10n;

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
    for (final c in _texts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await ai.api.describeElements(
        ai.itemUuid,
        widget.elementIds,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        for (final i in items) {
          final alt = i.altText;
          if (alt == null) continue;
          _texts[i.elementId] = TextEditingController(text: alt);
          _checked.add(i.elementId);
        }
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  void _apply() {
    final out = <String, String>{
      for (final id in _checked)
        if (_texts[id]?.text.trim() case final String t when t.isNotEmpty)
          id: t,
    };
    if (out.isEmpty) return;
    Navigator.of(context).pop(out);
  }

  String _kindText(String kind) => switch (kind) {
    'image' => l.elementKindImage,
    'chart' => l.elementKindChart,
    'icon' => l.elementKindIcon,
    'code' => l.elementKindCode,
    'table' => l.elementKindTable,
    _ => l.elementKindShape,
  };

  int _position(String? slideId) =>
      ai.model.slides.indexWhere((s) => s.id == slideId) + 1;

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final items = _items;
    return {
      'title': l.aiAltTitle,
      'loading': items == null && _error == null,
      'error': ?_error,
      'fields': [
        if (items != null) ...[
          {
            'id': 'elements',
            'label': l.aiAltTitle,
            'type': 'multiselect',
            'value': _checked.toList(),
            'options': [
              for (final i in items)
                if (i.altText != null) i.elementId,
            ],
          },
          for (final i in items)
            if (_texts[i.elementId] case final c?)
              {
                'id': 'alt.${i.elementId}',
                'label': _kindText(i.kind),
                'type': 'text',
                'value': c.text,
              },
        ],
      ],
      if (items != null)
        'skipped': [
          for (final i in items)
            if (i.altText == null)
              {'element_id': i.elementId, 'reason': i.skipped},
        ],
      'buttons': [
        {'id': 'cancel', 'label': 'Cancel', 'enabled': true},
        {'id': 'apply', 'label': l.aiAltApply, 'enabled': _checked.isNotEmpty},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id == 'elements' && value is List) {
      final ids = {for (final v in value) '$v'};
      if (!ids.every(_texts.containsKey)) return false;
      setState(() {
        _checked
          ..clear()
          ..addAll(ids);
      });
      return true;
    }
    if (id.startsWith('alt.')) {
      final c = _texts[id.substring(4)];
      if (c == null) return false;
      c.text = '${value ?? ''}';
      setState(() {});
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
      case 'apply' when _checked.isNotEmpty:
        _apply();
        return true;
    }
    return false;
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final items = _items;
    return ShadDialog(
      closeIcon: const WonkyDialogCloseButton(),
      constraints: const BoxConstraints(maxWidth: 600),
      key: AltTextDialogKeys.dialog,
      title: Text(l.aiAltTitle),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(la.actionCancel),
        ),
        ShadButton(
          key: AltTextDialogKeys.apply,
          enabled: _checked.isNotEmpty,
          onPressed: _apply,
          child: Text(l.aiAltApply),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: SizedBox(
          width: 560,
          child: _error != null
              ? AiError(_error!)
              : items == null
              ? AiWorking(label: l.aiAltWorking)
              : items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l.aiAltNone, style: theme.textTheme.muted),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final i in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            ShadCheckbox(
                              key: AltTextDialogKeys.check(i.elementId),
                              value: _checked.contains(i.elementId),
                              enabled: _texts.containsKey(i.elementId),
                              onChanged: (v) => setState(() {
                                if (v) {
                                  _checked.add(i.elementId);
                                } else {
                                  _checked.remove(i.elementId);
                                }
                              }),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    l.aiAltObject(
                                      _kindText(i.kind),
                                      _position(i.slideId),
                                    ),
                                    style: theme.textTheme.small.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_texts[i.elementId] case final c?)
                                    ShadInput(
                                      key: AltTextDialogKeys.text(i.elementId),
                                      controller: c,
                                      minLines: 1,
                                      maxLines: 4,
                                      maxLength: 2000,
                                    )
                                  else
                                    Text(
                                      i.skipped == 'unsupported'
                                          ? l.aiAltSkippedUnsupported
                                          : l.aiAltSkippedEmpty,
                                      style: theme.textTheme.muted,
                                    ),
                                ],
                              ),
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
}
