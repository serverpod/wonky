import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import '../common/range_input.dart';
import '../formatting/formatting_features.dart';
import '../formatting/panel_widgets.dart';
import '../formatting/sheets_colors.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'banding_controller.dart';

/// The *Alternating colors* side panel (06 §14.2): range, header/footer
/// toggles, 12 default styles from the theme accents, custom colors and the
/// spreadsheet's saved custom styles; the draft is previewed on the grid and
/// *Done* commits `sheets.banding.add` / `update` (one undo step).
class BandingPanel extends StatefulWidget {
  const BandingPanel({super.key, required this.services, required this.editor});

  final ShellServices services;
  final SheetEditorController editor;

  @override
  State<BandingPanel> createState() => _BandingPanelState();
}

class _BandingPanelState extends State<BandingPanel> {
  late BandingDraft _draft;
  late String _rangeText;
  String? _sheetId;

  SheetEditorController get ed => widget.editor;
  BandingController get c => FormattingFeatures.of(ed).banding;

  @override
  void initState() {
    super.initState();
    _start();
    ed.addListener(_onEditor);
  }

  @override
  void dispose() {
    ed.removeListener(_onEditor);
    final f = FormattingFeatures.maybeOf(ed);
    f?.banding.setDraft(null);
    f?.highlight.value = null;
    super.dispose();
  }

  void _onEditor() {
    if (!mounted) return;
    // A new sheet: start over on it.
    if (_sheetId != ed.activeSheetId) {
      setState(_start);
    }
  }

  /// Loads the banding at the selection, or a new draft over the data
  /// region of the selection.
  void _start() {
    final sid = ed.activeSheetId;
    _sheetId = sid;
    final sel = ed.selection.resolved;
    final active = sel.activeRange.rect;
    final existing = c.bandingAt(sid, active);
    if (existing != null) {
      final range = c.rangeOf(sid, existing.id);
      _rangeText = range?.a1 ?? '';
      _draft = BandingDraft(
        sheetId: sid,
        bandingId: existing.id,
        range: range,
        style: BandingStyle.parse(existing.styleJson),
      );
    } else {
      final region = sel.isSingleCell
          ? (ed.edgeFinder().region(sel.activeRow, sel.activeCol) ?? active)
          : active;
      final sheet = ed.activeSheet!;
      final grid = GridRect(
        0,
        0,
        sheet.rows.length - 1,
        sheet.columns.length - 1,
      );
      final rect = region.intersection(grid) ?? region;
      _rangeText = rect.a1;
      _draft = BandingDraft(
        sheetId: sid,
        range: rect,
        style: BandingStyle.presets(ed.model.theme).first,
      );
    }
    // Preview after the frame: the panel may be built during a layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.setDraft(_draft);
    });
  }

  void _set(BandingDraft d) {
    setState(() => _draft = d);
    c.setDraft(d);
  }

  Future<void> _done() async {
    final d = _draft;
    final range = d.range;
    if (range == null) return;
    final s = widget.services;
    final style = d.style.toJson();
    final r = d.bandingId == null
        ? await s.invokeWithToasts(
            'sheets.banding.add',
            args: {'range': range.a1, 'style': style},
            context: context,
          )
        : await s.invokeWithToasts(
            'sheets.banding.update',
            args: {'bandingId': d.bandingId, 'range': range.a1, 'style': style},
            context: context,
          );
    if (r.isOk) _close();
  }

  Future<void> _remove() async {
    final id = _draft.bandingId;
    if (id == null) return;
    final r = await widget.services.invokeWithToasts(
      'sheets.banding.remove',
      args: {'bandingId': id},
      context: context,
    );
    if (r.isOk) _close();
  }

  void _close() {
    c.setDraft(null);
    widget.services.panels.close(FormattingPanels.alternatingColors);
    ed.gridFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ed.model.theme;
    final d = _draft;
    final style = d.style;
    final presets = BandingStyle.presets(theme);
    final custom = c.customStyles();
    bool same(BandingStyle a, BandingStyle b) =>
        a.header == b.header &&
        a.firstBand == b.firstBand &&
        a.secondBand == b.secondBand &&
        a.footer == b.footer;
    BandingStyle keepFlags(BandingStyle p) => BandingStyle(
      header: p.header,
      firstBand: p.firstBand,
      secondBand: p.secondBand,
      footer: p.footer,
      showHeader: style.showHeader,
      showFooter: style.showFooter,
      dimension: style.dimension,
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _done,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _done,
      },
      child: FormatPanelFrame(
        key: const ValueKey<String>('banding.panel'),
        title: l.bandingPanelTitle,
        footer: PanelDoneFooter(
          keyPrefix: 'banding',
          cancelLabel: la.actionCancel,
          doneLabel: l.panelDone,
          onCancel: _close,
          onDone: d.range != null && ed.canEdit ? _done : null,
        ),
        children: [
          PanelSection(
            label: l.bandingApplyToRange,
            top: 4,
            child: RangeInput(
              keyName: 'banding.range',
              editor: ed,
              multiple: false,
              value: _rangeText,
              onChanged: (t, ranges) {
                _rangeText = t;
                final r = ranges?.single;
                _set(
                  BandingDraft(
                    sheetId: d.sheetId,
                    bandingId: d.bandingId,
                    range: r == null || r.sheetId != d.sheetId ? null : r.rect,
                    style: style,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Alternate rows or columns (06 §14, columns P2).
          ShadCheckbox(
            key: const ValueKey<String>('banding.columns'),
            value: style.byColumns,
            onChanged: (v) => _set(
              d.copyWith(
                style: style.copyWith(dimension: v ? 'columns' : 'rows'),
              ),
            ),
            label: Text(l.bandingColumns),
            sublabel: Text(l.bandingColumnsHint),
          ),
          const SizedBox(height: 6),
          ShadCheckbox(
            key: const ValueKey<String>('banding.header'),
            value: style.showHeader,
            onChanged: (v) => _set(d.copyWith(style: _flags(style, header: v))),
            label: Text(l.bandingHeader),
          ),
          const SizedBox(height: 6),
          ShadCheckbox(
            key: const ValueKey<String>('banding.footer'),
            value: style.showFooter,
            onChanged: (v) => _set(d.copyWith(style: _flags(style, footer: v))),
            label: Text(l.bandingFooter),
          ),
          PanelSection(
            label: l.bandingDefaultStyles,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < presets.length; i++)
                  _StyleSwatch(
                    key: ValueKey<String>('banding.preset.$i'),
                    style: presets[i],
                    theme: theme,
                    selected: same(presets[i], style),
                    label: l.bandingPresetLabel(i + 1),
                    onPressed: () =>
                        _set(d.copyWith(style: keepFlags(presets[i]))),
                  ),
              ],
            ),
          ),
          PanelSection(
            label: l.bandingCustomStyles,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (custom.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < custom.length; i++)
                          _StyleSwatch(
                            key: ValueKey<String>('banding.custom.$i'),
                            style: custom[i],
                            theme: theme,
                            selected: same(custom[i], style),
                            label: l.bandingCustomLabel(i + 1),
                            onPressed: () =>
                                _set(d.copyWith(style: keepFlags(custom[i]))),
                          ),
                      ],
                    ),
                  ),
                for (final (key, label, value) in [
                  ('header', l.bandingHeaderColor, style.header),
                  ('first', l.bandingColor1, style.firstBand),
                  ('second', l.bandingColor2, style.secondBand),
                  ('footer', l.bandingFooterColor, style.footer),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(label)),
                        SizedBox(
                          width: 150,
                          child: SheetsColorButton(
                            key: ValueKey<String>('banding.color.$key'),
                            label: label,
                            theme: theme,
                            value: value,
                            resetLabel: key == 'header' || key == 'footer'
                                ? l.colorAutomatic
                                : null,
                            onChanged: (v) =>
                                _set(d.copyWith(style: _color(style, key, v))),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (d.bandingId != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ShadButton.destructive(
                  key: const ValueKey<String>('banding.remove'),
                  size: ShadButtonSize.sm,
                  enabled: ed.canEdit,
                  leading: const Icon(LucideIcons.trash2, size: 15),
                  onPressed: () => unawaited(_remove()),
                  child: Text(l.bandingRemove),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static BandingStyle _flags(BandingStyle s, {bool? header, bool? footer}) =>
      BandingStyle(
        header: s.header,
        firstBand: s.firstBand,
        secondBand: s.secondBand,
        footer: s.footer,
        showHeader: header ?? s.showHeader,
        showFooter: footer ?? s.showFooter,
        dimension: s.dimension,
      );

  static BandingStyle _color(BandingStyle s, String key, String? c) =>
      BandingStyle(
        header: key == 'header' ? c : s.header,
        firstBand: key == 'first' ? (c ?? s.firstBand) : s.firstBand,
        secondBand: key == 'second' ? (c ?? s.secondBand) : s.secondBand,
        footer: key == 'footer' ? c : s.footer,
        showHeader: s.showHeader,
        showFooter: s.showFooter,
        dimension: s.dimension,
      );
}

/// A clickable mini table showing a banding style.
class _StyleSwatch extends StatelessWidget {
  const _StyleSwatch({
    super.key,
    required this.style,
    required this.theme,
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final BandingStyle style;
  final SpreadsheetTheme theme;
  final bool selected;
  final String label;
  final VoidCallback onPressed;

  Color _c(String? s, Color fallback) =>
      hexToColor(theme.resolveColor(s)) ?? fallback;

  @override
  Widget build(BuildContext context) {
    final shad = ShadTheme.of(context);
    const w = 52.0;
    Widget row(Color c) => Container(height: 7, color: c);
    final header = _c(
      style.header ?? style.secondBand,
      const Color(0xFF5B95F9),
    );
    final a = _c(style.firstBand, const Color(0xFFFFFFFF));
    final b = _c(style.secondBand, const Color(0xFFE8F0FE));
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed();
              return null;
            },
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: onPressed,
              child: Container(
                width: w,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    width: selected || focused ? 2 : 1,
                    color: selected
                        ? shad.colorScheme.primary
                        : focused
                        ? shad.colorScheme.ring
                        : shad.colorScheme.border,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Column(
                    children: [row(header), row(a), row(b), row(a), row(b)],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
