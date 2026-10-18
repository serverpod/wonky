import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import '../navigator/deck_renderer.dart';
import '../settings/slides_settings.dart' show slideSizeLabel;
import '../stage/slide_renderer.dart';
import '../thumbnails/slide_thumbnail.dart';

/// What the page setup dialog applies (`slides.deck.setSize`).
class PageSetupChoice {
  const PageSetupChoice(this.size, {required this.scaleContent});

  final SlideSize size;
  final bool scaleContent;
}

/// The localized label of a unit.
String slideUnitLabel(SlidesLocalizations l, SlideUnit u) => switch (u) {
  SlideUnit.su => l.unitsSu,
  SlideUnit.px => l.unitsPx,
  SlideUnit.inch => l.unitsIn,
  SlideUnit.cm => l.unitsCm,
};

/// The problem of a custom size in su ([SlideSize.validate], localized), or
/// null when it is valid.
String? pageSizeProblem(SlidesLocalizations l, double w, double h) {
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
    return l.pageSetupEnterSize;
  }
  if (SlideSize.validate(w, h) == null) return null;
  if (w < SlideSize.minSide ||
      h < SlideSize.minSide ||
      w > SlideSize.maxSide ||
      h > SlideSize.maxSide) {
    return l.pageSetupSideRange;
  }
  return l.pageSetupAspectRange;
}

/// Page setup (Slides 04 §13.1, 05 §7): `preset` (the slide size presets
/// and *Custom*), `width`/`height` with a `unit` (su / px / in / cm, for
/// *Custom*), `scaleContent` (*Scale content to fit* / *Don't scale*) and a
/// preview of the current slide in the new size. Custom dialog, MCP-operable
/// through `ui.get_dialog` / `ui.fill_dialog`. Returns the choice or null.
Future<PageSetupChoice?> showPageSetupDialog(
  BuildContext context,
  DeckEditorController ed,
) => showShadDialog<PageSetupChoice>(
  context: context,
  builder: (_) => PageSetupDialog(editor: ed),
);

class PageSetupDialog extends StatefulWidget {
  const PageSetupDialog({super.key, required this.editor});

  final DeckEditorController editor;

  @override
  State<PageSetupDialog> createState() => _PageSetupDialogState();
}

class _PageSetupDialogState extends State<PageSetupDialog>
    implements McpDescribableDialog {
  late SlideSizeKind _preset;
  SlideUnit _unit = SlideUnit.inch;
  bool _scale = true;
  final _width = TextEditingController();
  final _height = TextEditingController();
  late final SlideRenderer _renderer = DeckThumbnails.acquire(widget.editor);
  ShellServices? _registeredIn;

  DeckEditorController get ed => widget.editor;

  @override
  void initState() {
    super.initState();
    final d = ed.model.deck;
    _preset = d?.sizePreset ?? SlideSizeKind.widescreen16x9;
    _setFields(d?.width ?? 1920, d?.height ?? 1080);
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
    DeckThumbnails.release(ed, _renderer);
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  static String _fmt(double v) {
    final r = (v * 100).roundToDouble() / 100;
    return r == r.roundToDouble() ? '${r.round()}' : '$r';
  }

  void _setFields(double wSu, double hSu) {
    _width.text = _fmt(SlideUnits.fromSu(wSu, _unit));
    _height.text = _fmt(SlideUnits.fromSu(hSu, _unit));
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? double.nan;

  /// The size in su (presets exact, custom from the fields).
  (double, double) get _su {
    if (_preset != SlideSizeKind.custom) return (_preset.width, _preset.height);
    return (
      SlideUnits.toSu(_parse(_width), _unit).roundToDouble(),
      SlideUnits.toSu(_parse(_height), _unit).roundToDouble(),
    );
  }

  String? _problem(SlidesLocalizations l) {
    final (w, h) = _su;
    return pageSizeProblem(l, w, h);
  }

  void _choosePreset(SlideSizeKind k) {
    setState(() {
      if (k != SlideSizeKind.custom) {
        _setFields(k.width, k.height);
      }
      _preset = k;
    });
  }

  void _chooseUnit(SlideUnit u) {
    final (w, h) = _su;
    setState(() {
      _unit = u;
      if (w.isFinite && h.isFinite) _setFields(w, h);
    });
  }

  void _apply() {
    final l = slidesL10n(context);
    if (_problem(l) != null) return;
    final (w, h) = _su;
    Navigator.of(context).pop(
      PageSetupChoice(
        _preset == SlideSizeKind.custom
            ? SlideSize.custom(w, h)
            : SlideSize.preset(_preset),
        scaleContent: _scale,
      ),
    );
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    return {
      'title': l.pageSetupTitle,
      'fields': [
        {
          'id': 'preset',
          'label': l.pageSetupPreset,
          'type': 'select',
          'value': _preset.name,
          'options': [for (final k in SlideSizeKind.values) k.name],
          'optionLabels': {
            for (final k in SlideSizeKind.values) k.name: _presetLabel(l, k),
          },
        },
        {
          'id': 'width',
          'label': l.sizeWidth,
          'type': 'text',
          'value': _width.text,
        },
        {
          'id': 'height',
          'label': l.sizeHeight,
          'type': 'text',
          'value': _height.text,
        },
        {
          'id': 'unit',
          'label': l.pageSetupUnit,
          'type': 'select',
          'value': _unit.name,
          'options': [for (final u in SlideUnit.values) u.name],
          'optionLabels': {
            for (final u in SlideUnit.values) u.name: slideUnitLabel(l, u),
          },
        },
        {
          'id': 'scaleContent',
          'label': l.pageSetupContent,
          'type': 'select',
          'value': _scale ? 'scale' : 'keep',
          'options': ['scale', 'keep'],
          'optionLabels': {
            'scale': l.pageSetupScale,
            'keep': l.pageSetupDontScale,
          },
        },
      ],
      'buttons': [
        {'id': 'cancel', 'label': la.actionCancel},
        {'id': 'apply', 'label': l.pageSetupApply},
      ],
      'error': _problem(l),
    };
  }

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'preset':
        final k = SlideSizeKind.fromName(value);
        if (k == null) return false;
        _choosePreset(k);
      case 'unit':
        final u = SlideUnit.values.where((u) => u.name == value).firstOrNull;
        if (u == null) return false;
        _chooseUnit(u);
      case 'width' || 'height':
        if (value is! String && value is! num) return false;
        setState(() {
          _preset = SlideSizeKind.custom;
          (id == 'width' ? _width : _height).text = '$value';
        });
      case 'scaleContent':
        if (value != 'scale' && value != 'keep' && value is! bool) {
          return false;
        }
        setState(() => _scale = value == 'scale' || value == true);
      default:
        return false;
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        Navigator.of(context).pop();
      case 'apply':
        if (_problem(slidesL10n(context)) != null) return false;
        _apply();
      default:
        return false;
    }
    return true;
  }

  // ----------------------------------------------------------------- build

  static String _presetLabel(SlidesLocalizations l, SlideSizeKind k) =>
      k == SlideSizeKind.custom ? l.sizeCustom : slideSizeLabel(l, k.name);

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final problem = _problem(l);
    final custom = _preset == SlideSizeKind.custom;
    final narrow = MediaQuery.sizeOf(context).width < 520;

    Widget labelled(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.small),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        labelled(
          l.pageSetupPreset,
          ShadSelect<SlideSizeKind>(
            key: ValueKey<String>('slides.pageSetup.preset.${_preset.name}'),
            initialValue: _preset,
            minWidth: 200,
            options: [
              for (final k in SlideSizeKind.values)
                ShadOption<SlideSizeKind>(
                  key: ValueKey<String>('slides.pageSetup.option.${k.name}'),
                  value: k,
                  child: Text(_presetLabel(l, k)),
                ),
            ],
            selectedOptionBuilder: (_, k) => Text(_presetLabel(l, k)),
            onChanged: (k) {
              if (k != null && k != _preset) _choosePreset(k);
            },
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: labelled(
                l.sizeWidth,
                ShadInput(
                  key: const ValueKey<String>('slides.pageSetup.width'),
                  controller: _width,
                  enabled: custom,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _apply(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: labelled(
                l.sizeHeight,
                ShadInput(
                  key: const ValueKey<String>('slides.pageSetup.height'),
                  controller: _height,
                  enabled: custom,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _apply(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: labelled(
                l.pageSetupUnit,
                ShadSelect<SlideUnit>(
                  key: ValueKey<String>('slides.pageSetup.unit.${_unit.name}'),
                  initialValue: _unit,
                  minWidth: 96,
                  options: [
                    for (final u in SlideUnit.values)
                      ShadOption<SlideUnit>(
                        value: u,
                        child: Text(slideUnitLabel(l, u)),
                      ),
                  ],
                  selectedOptionBuilder: (_, u) => Text(slideUnitLabel(l, u)),
                  onChanged: (u) {
                    if (u != null && u != _unit) _chooseUnit(u);
                  },
                ),
              ),
            ),
          ],
        ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              problem,
              key: const ValueKey<String>('slides.pageSetup.error'),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
        Text(l.pageSetupContent, style: theme.textTheme.small),
        const SizedBox(height: 6),
        ShadRadioGroup<bool>(
          key: ValueKey<String>('slides.pageSetup.scale.$_scale'),
          initialValue: _scale,
          onChanged: (v) {
            if (v != null) setState(() => _scale = v);
          },
          items: [
            ShadRadio<bool>(
              key: const ValueKey<String>('slides.pageSetup.scale'),
              value: true,
              label: Text(l.pageSetupScale),
            ),
            ShadRadio<bool>(
              key: const ValueKey<String>('slides.pageSetup.dontScale'),
              value: false,
              label: Text(l.pageSetupDontScale),
            ),
          ],
        ),
      ],
    );

    final preview = _Preview(
      editor: ed,
      renderer: _renderer,
      size: problem == null ? _su : null,
      scale: _scale,
      label: l.pageSetupPreview,
    );

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): _apply},
      child: ShadDialog(
        key: const ValueKey<String>('slides.dialog.pageSetup'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.pageSetupTitle),
        constraints: BoxConstraints(maxWidth: narrow ? 360 : 620),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('slides.pageSetup.cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('slides.pageSetup.apply'),
            enabled: problem == null,
            onPressed: _apply,
            child: Text(l.pageSetupApply),
          ),
        ],
        child: SizedBox(
          width: narrow ? 320 : 560,
          child: narrow
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [fields, const SizedBox(height: 12), preview],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fields),
                    const SizedBox(width: 16),
                    SizedBox(width: 200, child: preview),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The current slide drawn in the new size: letterboxed (*Scale content*)
/// or at its su position, clipped (*Don't scale*).
class _Preview extends StatelessWidget {
  const _Preview({
    required this.editor,
    required this.renderer,
    required this.size,
    required this.scale,
    required this.label,
  });

  final DeckEditorController editor;
  final SlideRenderer renderer;
  final (double, double)? size;
  final bool scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final slide = editor.currentSlideId;
    final from = renderer.slideSize;
    final (w, h) = size ?? (from.width, from.height);
    return LayoutBuilder(
      builder: (context, c) {
        final boxW = math.min(c.maxWidth, 200.0);
        final boxH = math.min(boxW * h / w, 160.0);
        final px = math.min(boxW / w, boxH / h);
        final pw = w * px;
        final ph = h * px;
        // The old slide inside the new page (su → preview px).
        final s = scale ? math.min(w / from.width, h / from.height) : 1.0;
        final sw = from.width * s * px;
        final dx = scale ? (pw - sw) / 2 : 0.0;
        final dy = scale ? (ph - from.height * s * px) / 2 : 0.0;
        return Semantics(
          label: label,
          image: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.small),
              const SizedBox(height: 6),
              Container(
                key: const ValueKey<String>('slides.pageSetup.preview'),
                width: pw,
                height: ph,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  border: Border.all(color: theme.colorScheme.border),
                ),
                child: slide == null
                    ? null
                    : Stack(
                        children: [
                          Positioned(
                            left: dx,
                            top: dy,
                            child: SlideThumbnail(
                              renderer: renderer,
                              slideId: slide,
                              width: sw,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt(w)} × ${_fmt(h)} su',
                style: theme.textTheme.muted.copyWith(fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(double v) => v.round().toString();
}
