import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';
import '../stage/slide_renderer.dart';
import '../thumbnails/slide_thumbnail.dart';
import '../uploads/slides_image_service.dart';
import 'slides_ai_controller.dart';

/// What the user did in the AI changes preview.
sealed class AiPreviewOutcome {
  const AiPreviewOutcome();
}

/// *Apply selected*: the server applied the checked calls.
class AiPreviewApplied extends AiPreviewOutcome {
  const AiPreviewApplied(this.result);
  final SlidesAiApplyResult result;
}

/// *Discard*.
class AiPreviewDiscarded extends AiPreviewOutcome {
  const AiPreviewDiscarded();
}

/// A detached copy of [m] (previews never touch the live deck).
DeckModel copyDeck(DeckModel m) => DeckModel.fromRows(m.deckId, [
  for (final t in SlidesTables.dependencyOrder)
    for (final r in m.records(t)) (t, r.toColumns()),
]);

/// Stable widget keys of the preview dialog.
abstract final class AiPreviewKeys {
  static const dialog = ValueKey<String>('dialog.slides.aiPreview');
  static const apply = ValueKey<String>('dialog.slides.aiPreview.apply');
  static const discard = ValueKey<String>('dialog.slides.aiPreview.discard');
  static ValueKey<String> call(String id) =>
      ValueKey<String>('dialog.slides.aiPreview.call.$id');
  static ValueKey<String> check(String id) =>
      ValueKey<String>('dialog.slides.aiPreview.check.$id');
  static ValueKey<String> slide(String id) =>
      ValueKey<String>('dialog.slides.aiPreview.slide.$id');
}

/// The AI changes preview of a Suggest-mode run (Slides 11 §6.3): the
/// recorded tool calls with checkboxes (left) and, for the slides the
/// focused call touches, **before / after** thumbnails side by side
/// (rendered here from the preview's row changes applied to a copy of the
/// deck). *Apply selected* writes the checked calls as one undo step.
/// MCP-operable ([McpDescribableDialog]). Null when closed without a
/// choice.
Future<AiPreviewOutcome?> showAiPreviewDialog(
  BuildContext context, {
  required SlidesAiController ai,
  required String previewId,
}) => showShadDialog<AiPreviewOutcome>(
  context: context,
  builder: (_) => AiPreviewDialog(ai: ai, previewId: previewId),
);

class AiPreviewDialog extends StatefulWidget {
  const AiPreviewDialog({super.key, required this.ai, required this.previewId});

  final SlidesAiController ai;
  final String previewId;

  @override
  State<AiPreviewDialog> createState() => _AiPreviewDialogState();
}

class _AiPreviewDialogState extends State<AiPreviewDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  SlidesAiPreview? _preview;
  final Map<String, List<RowChange>> _changes = {};
  final Set<String> _checked = {};
  String? _focused;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  late final SlideRenderer _before;
  SlideRenderer? _after;

  SlidesAiController get ai => widget.ai;

  @override
  void initState() {
    super.initState();
    _before = SlideRenderer(
      model: copyDeck(ai.model),
      images: SlidesImageService.of(ai.editor),
    );
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
    _before.dispose();
    _after?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await ai.api.getPreview(widget.previewId);
      for (final c in p.calls) {
        try {
          _changes[c.callId] = [
            for (final x in jsonDecode(c.changesJson) as List)
              RowChange.fromJson((x as Map).cast<String, Object?>()),
          ];
        } on Object {
          _changes[c.callId] = const [];
        }
      }
      if (!mounted) return;
      setState(() {
        _preview = p;
        _checked.addAll([for (final c in p.calls) c.callId]);
        _focused = p.calls.isEmpty ? null : p.calls.first.callId;
        _loading = false;
      });
      _rebuildAfter();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  /// The deck with the checked calls applied (in order).
  void _rebuildAfter() {
    final p = _preview;
    if (p == null) return;
    final m = copyDeck(_before.model);
    for (final c in p.calls) {
      if (!_checked.contains(c.callId)) continue;
      try {
        m.applyChanges(_changes[c.callId] ?? const []);
      } on Object {
        // A change that doesn't fit the local deck is shown as is.
      }
    }
    final old = _after;
    setState(() {
      _after = SlideRenderer(
        model: m,
        images: SlidesImageService.of(ai.editor),
      );
    });
    old?.dispose();
  }

  void _toggle(String id, bool on) {
    setState(() {
      if (on) {
        _checked.add(id);
      } else {
        _checked.remove(id);
      }
    });
    _rebuildAfter();
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
        all
            ? null
            : [
                for (final c in p.calls)
                  if (_checked.contains(c.callId)) c.callId,
              ],
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

  int? _position(DeckModel m, String slideId) {
    final i = m.slides.indexWhere((s) => s.id == slideId);
    return i < 0 ? null : i + 1;
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final p = _preview;
    final l = slidesL10nOf(ai.services);
    return {
      'title': l.aiPreviewTitle,
      'preview_id': widget.previewId,
      'loading': _loading,
      'error': ?_error,
      'fields': [
        {
          'id': 'calls',
          'label': l.aiPreviewTitle,
          'type': 'multiselect',
          'value': [
            for (final c in p?.calls ?? const <SlidesAiPreviewCall>[])
              if (_checked.contains(c.callId)) c.callId,
          ],
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
              'slides': [
                for (final id in c.slideIds)
                  {
                    'slide_id': id,
                    'before_position': ?_position(_before.model, id),
                    if (_after != null)
                      'after_position': ?_position(_after!.model, id),
                  },
              ],
            },
        ],
      'buttons': [
        {'id': 'discard', 'label': l.aiPreviewDiscard, 'enabled': !_busy},
        {'id': 'apply', 'label': l.aiPreviewApply, 'enabled': _canApply},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    final p = _preview;
    if (id != 'calls' || value is! List || p == null) return false;
    final ids = {for (final v in value) '$v'};
    if (!ids.every((x) => p.calls.any((c) => c.callId == x))) return false;
    setState(() {
      _checked
        ..clear()
        ..addAll(ids);
    });
    _rebuildAfter();
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
    final l = slidesL10n(context);
    final theme = ShadTheme.of(context);
    final p = _preview;
    return ShadDialog(
      closeIcon: const WonkyDialogCloseButton(),
      constraints: const BoxConstraints(maxWidth: 900),
      key: AiPreviewKeys.dialog,
      title: Text(l.aiPreviewTitle),
      description: Text(l.aiPreviewDescription),
      actions: [
        ShadButton.outline(
          key: AiPreviewKeys.discard,
          enabled: !_busy,
          onPressed: () => unawaited(_discard()),
          child: Text(l.aiPreviewDiscard),
        ),
        ShadButton(
          key: AiPreviewKeys.apply,
          enabled: _canApply,
          leading: _busy
              ? const SizedBox(width: 14, height: 14, child: ShadSpinner())
              : null,
          onPressed: () => unawaited(_apply()),
          child: Text(l.aiPreviewApply),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 560),
        child: SizedBox(
          width: 860,
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
                    final detail = _detail(context, p, narrow: narrow);
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
                          Flexible(flex: 2, child: detail),
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
                              SizedBox(width: 280, child: list),
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

  Widget _calls(BuildContext context, SlidesAiPreview p) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = slidesL10n(context);
    return ListView(
      shrinkWrap: true,
      children: [
        for (final c in p.calls)
          FocusableActionDetector(
            child: GestureDetector(
              key: AiPreviewKeys.call(c.callId),
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
                      key: AiPreviewKeys.check(c.callId),
                      value: _checked.contains(c.callId),
                      onChanged: (v) => _toggle(c.callId, v),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(c.label, style: theme.textTheme.small),
                          if (c.slideIds.isNotEmpty)
                            Text(
                              <String>{
                                for (final id in c.slideIds.take(6))
                                  switch (_position(_before.model, id)) {
                                    final int n => l.aiPreviewSlide(n),
                                    null => l.aiPreviewNewSlide,
                                  },
                              }.join(' · '),
                              style: theme.textTheme.muted.copyWith(
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detail(
    BuildContext context,
    SlidesAiPreview p, {
    required bool narrow,
  }) {
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    final c = p.calls.where((x) => x.callId == _focused).firstOrNull;
    final after = _after;
    if (c == null || after == null) return const SizedBox.shrink();
    final slides = [
      for (final id in c.slideIds)
        if (_before.model.slide(id) != null || after.model.slide(id) != null)
          id,
    ];
    if (slides.isEmpty) {
      return Text(l.aiPreviewNoSlides, style: theme.textTheme.muted);
    }
    return LayoutBuilder(
      builder: (context, box) {
        final w = ((box.maxWidth - 24) / 2).clamp(80.0, 240.0);
        Widget thumb(SlideRenderer r, String id, String fallback) =>
            r.model.slide(id) == null
            ? SizedBox(
                width: w,
                height: w * 9 / 16,
                child: Center(
                  child: Text(fallback, style: theme.textTheme.muted),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.border),
                ),
                child: SlideThumbnail(renderer: r, slideId: id, width: w),
              );
        return ListView(
          shrinkWrap: true,
          children: [
            Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: w,
                  child: Text(l.aiPreviewBefore, style: theme.textTheme.small),
                ),
                SizedBox(
                  width: w,
                  child: Text(l.aiPreviewAfter, style: theme.textTheme.small),
                ),
              ],
            ),
            for (final id in slides)
              Padding(
                key: AiPreviewKeys.slide(id),
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    thumb(_before, id, l.aiPreviewNewSlide),
                    thumb(after, id, l.aiPreviewDeletedSlide),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
