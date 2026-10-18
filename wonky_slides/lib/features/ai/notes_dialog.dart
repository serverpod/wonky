import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';
import '../canvas/slide_canvas_controller.dart';
import '../thumbnails/slide_thumbnail.dart';
import 'ai_widgets.dart';
import 'slides_ai_controller.dart';

/// The options of *Write speaker notes* (Slides 11 §6.7).
class NotesOptions {
  const NotesOptions({
    this.scope = 'current',
    this.length = 'standard',
    this.style = 'script',
    this.mode = 'fillEmpty',
  });

  /// current | selected | all.
  final String scope;

  /// brief | standard | detailed.
  final String length;

  /// script | bullets.
  final String style;

  /// replace | append | fillEmpty.
  final String mode;

  static const scopes = ['current', 'selected', 'all'];
  static const lengths = ['brief', 'standard', 'detailed'];
  static const styles = ['script', 'bullets'];
  static const modes = ['fillEmpty', 'append', 'replace'];
}

/// What the user accepted: the checked notes and how to write them.
class NotesDecision {
  const NotesDecision(this.notes, this.mode);
  final List<SlidesAiNote> notes;
  final String mode;
}

/// Stable widget keys of the notes dialog.
abstract final class NotesDialogKeys {
  static const dialog = ValueKey<String>('dialog.slides.aiNotes');
  static const generate = ValueKey<String>('dialog.slides.aiNotes.generate');
  static const apply = ValueKey<String>('dialog.slides.aiNotes.apply');
  static ValueKey<String> check(String slideId) =>
      ValueKey<String>('dialog.slides.aiNotes.check.$slideId');
}

/// *Write speaker notes* (Slides 11 §6.7): the options (scope, length,
/// style, what to do with existing notes), then a review list (slide
/// thumbnail, proposed notes, the current notes, a checkbox per slide).
/// *Apply* returns the checked notes; the command writes them as one undo
/// step. MCP-operable. [slideIds] of the scopes: current, selected, all.
Future<NotesDecision?> showNotesDialog(
  BuildContext context, {
  required SlidesAiController ai,
  required NotesOptions options,
  bool review = false,
}) => showShadDialog<NotesDecision>(
  context: context,
  builder: (_) => NotesDialog(ai: ai, options: options, autoStart: review),
);

class NotesDialog extends StatefulWidget {
  const NotesDialog({
    super.key,
    required this.ai,
    required this.options,
    this.autoStart = false,
  });

  final SlidesAiController ai;
  final NotesOptions options;

  /// Starts writing right away (the options came from the command).
  final bool autoStart;

  @override
  State<NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<NotesDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  late String _scope = widget.options.scope;
  late String _length = widget.options.length;
  late String _style = widget.options.style;
  late String _mode = widget.options.mode;
  bool _running = false;
  List<SlidesAiNote>? _notes;
  final Set<String> _checked = {};
  String? _error;

  SlidesAiController get ai => widget.ai;
  SlidesLocalizations get l => ai.l10n;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) unawaited(_generate());
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

  /// The slides of the scope (empty = all, for the server).
  List<String> get _slideIds {
    final ed = ai.editor;
    return switch (_scope) {
      'current' => [?ed.currentSlideId],
      'selected' =>
        ed.selectedSlideIds.isEmpty
            ? [?ed.currentSlideId]
            : [
                for (final e in ed.order.entries)
                  if (ed.selectedSlideIds.contains(e.id)) e.id,
              ],
      _ => const [],
    };
  }

  Future<void> _generate() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final notes = await ai.api.writeNotes(
        ai.itemUuid,
        _slideIds,
        length: _length,
        style: _style,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _checked
          ..clear()
          ..addAll([for (final n in notes) n.slideId]);
        _running = false;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _running = false;
        });
      }
    }
  }

  void _apply() {
    final notes = _notes;
    if (notes == null || _checked.isEmpty) return;
    Navigator.of(context).pop(
      NotesDecision([
        for (final n in notes)
          if (_checked.contains(n.slideId)) n,
      ], _mode),
    );
  }

  int _position(String slideId) =>
      ai.model.slides.indexWhere((s) => s.id == slideId) + 1;

  String _scopeText(String s) => switch (s) {
    'selected' => l.aiNotesScopeSelected,
    'all' => l.aiNotesScopeAll,
    _ => l.aiNotesScopeCurrent,
  };

  String _lengthText(String s) => switch (s) {
    'brief' => l.aiNotesLengthBrief,
    'detailed' => l.aiNotesLengthDetailed,
    _ => l.aiNotesLengthStandard,
  };

  String _styleText(String s) =>
      s == 'bullets' ? l.aiNotesStyleBullets : l.aiNotesStyleScript;

  String _modeText(String s) => switch (s) {
    'append' => l.aiNotesModeAppend,
    'replace' => l.aiNotesModeReplace,
    _ => l.aiNotesModeFillEmpty,
  };

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final notes = _notes;
    return {
      'title': notes == null ? l.aiNotesTitle : l.aiNotesReviewTitle,
      'running': _running,
      'error': ?_error,
      'fields': [
        if (notes == null) ...[
          {
            'id': 'scope',
            'label': l.aiNotesScope,
            'type': 'select',
            'value': _scope,
            'options': NotesOptions.scopes,
          },
          {
            'id': 'length',
            'label': l.aiNotesLength,
            'type': 'select',
            'value': _length,
            'options': NotesOptions.lengths,
          },
          {
            'id': 'style',
            'label': l.aiNotesStyle,
            'type': 'select',
            'value': _style,
            'options': NotesOptions.styles,
          },
          {
            'id': 'mode',
            'label': l.aiNotesMode,
            'type': 'select',
            'value': _mode,
            'options': NotesOptions.modes,
          },
        ] else
          {
            'id': 'slides',
            'label': l.aiNotesReviewTitle,
            'type': 'multiselect',
            'value': [
              for (final n in notes)
                if (_checked.contains(n.slideId)) n.slideId,
            ],
            'options': [for (final n in notes) n.slideId],
          },
      ],
      if (notes != null)
        'notes': [
          for (final n in notes)
            {
              'slide_id': n.slideId,
              'position': _position(n.slideId),
              'markdown': n.markdown,
              'existing': ?n.existing,
            },
        ],
      'buttons': [
        {'id': 'cancel', 'label': 'Cancel', 'enabled': true},
        if (notes == null)
          {'id': 'generate', 'label': l.aiNotesGenerate, 'enabled': !_running}
        else
          {
            'id': 'apply',
            'label': l.aiNotesApply,
            'enabled': _checked.isNotEmpty,
          },
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    void set(List<String> allowed, void Function(String) to) {
      if (!allowed.contains(value)) throw ArgumentError(value);
      setState(() => to(value! as String));
    }

    try {
      switch (id) {
        case 'scope':
          set(NotesOptions.scopes, (v) => _scope = v);
        case 'length':
          set(NotesOptions.lengths, (v) => _length = v);
        case 'style':
          set(NotesOptions.styles, (v) => _style = v);
        case 'mode':
          set(NotesOptions.modes, (v) => _mode = v);
        case 'slides' when value is List && _notes != null:
          setState(() {
            _checked
              ..clear()
              ..addAll([for (final v in value) '$v']);
          });
        default:
          return false;
      }
    } on ArgumentError {
      return false;
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        Navigator.of(context).pop();
        return true;
      case 'generate' when _notes == null && !_running:
        unawaited(_generate());
        return true;
      case 'apply' when _notes != null && _checked.isNotEmpty:
        _apply();
        return true;
    }
    return false;
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final la = WonkyAppLocalizations.of(context);
    final notes = _notes;
    return ShadDialog(
      closeIcon: const WonkyDialogCloseButton(),
      constraints: const BoxConstraints(maxWidth: 680),
      key: NotesDialogKeys.dialog,
      title: Text(notes == null ? l.aiNotesTitle : l.aiNotesReviewTitle),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(la.actionCancel),
        ),
        if (notes == null)
          ShadButton(
            key: NotesDialogKeys.generate,
            enabled: !_running,
            onPressed: () => unawaited(_generate()),
            child: Text(l.aiNotesGenerate),
          )
        else
          ShadButton(
            key: NotesDialogKeys.apply,
            enabled: _checked.isNotEmpty,
            onPressed: _apply,
            child: Text(l.aiNotesApply),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: SizedBox(
          width: 640,
          child: _running
              ? AiWorking(label: l.aiNotesWorking)
              : notes == null
              ? _options()
              : _review(context, notes),
        ),
      ),
    );
  }

  Widget _options() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      if (_error != null) AiError(_error!),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          AiField(
            label: l.aiNotesScope,
            child: aiSelect<String>(
              id: 'dialog.slides.aiNotes.scope',
              value: _scope,
              values: NotesOptions.scopes,
              text: _scopeText,
              onChanged: (v) => setState(() => _scope = v),
            ),
          ),
          AiField(
            label: l.aiNotesLength,
            child: aiSelect<String>(
              id: 'dialog.slides.aiNotes.length',
              value: _length,
              values: NotesOptions.lengths,
              text: _lengthText,
              onChanged: (v) => setState(() => _length = v),
            ),
          ),
          AiField(
            label: l.aiNotesStyle,
            child: aiSelect<String>(
              id: 'dialog.slides.aiNotes.style',
              value: _style,
              values: NotesOptions.styles,
              text: _styleText,
              onChanged: (v) => setState(() => _style = v),
            ),
          ),
          AiField(
            label: l.aiNotesMode,
            child: aiSelect<String>(
              id: 'dialog.slides.aiNotes.mode',
              value: _mode,
              values: NotesOptions.modes,
              minWidth: 200,
              text: _modeText,
              onChanged: (v) => setState(() => _mode = v),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _review(BuildContext context, List<SlidesAiNote> notes) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(l.aiNotesNone, style: theme.textTheme.muted),
      );
    }
    final renderer = SlideCanvasController.of(ai.editor)?.renderer;
    return ListView(
      shrinkWrap: true,
      children: [
        if (_error != null) AiError(_error!),
        for (final n in notes)
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
                  key: NotesDialogKeys.check(n.slideId),
                  value: _checked.contains(n.slideId),
                  onChanged: (v) => setState(() {
                    if (v) {
                      _checked.add(n.slideId);
                    } else {
                      _checked.remove(n.slideId);
                    }
                  }),
                ),
                if (renderer != null && ai.model.slide(n.slideId) != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.border),
                    ),
                    child: SlideThumbnail(
                      renderer: renderer,
                      slideId: n.slideId,
                      width: 112,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        l.aiPreviewSlide(_position(n.slideId)),
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(n.markdown, style: theme.textTheme.small),
                      if (n.existing != null)
                        Text(
                          '${l.aiNotesExisting}: ${n.existing}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
