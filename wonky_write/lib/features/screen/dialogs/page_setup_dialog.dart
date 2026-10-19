import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../../l10n/write_l10n.dart';

/// Result of the page setup dialog.
@immutable
class PageSetupResult {
  const PageSetupResult(this.setup, {this.setAsDefault = false});
  final PageSetup setup;
  final bool setAsDefault;
}

/// Page setup (`write.dialog.pageSetup`, Write 05 §12.6, 07 §6.2).
Future<PageSetupResult?> showPageSetupDialog(
  BuildContext context, {
  required PageSetup setup,
  required PageMargins themeMargins,
  bool readOnly = false,
  int initialTab = 0,
}) => showShadDialog<PageSetupResult>(
  context: context,
  builder: (_) => PageSetupDialog(
    setup: setup,
    themeMargins: themeMargins,
    readOnly: readOnly,
    initialTab: initialTab,
  ),
);

enum _Unit { inches, mm }

/// The display name of a paper size ("A4 (210 × 297 mm)").
String paperSizeLabel(WriteLocalizations l, PaperSize p) => switch (p) {
  PaperSize.letter => l.pageSetupPaperLetter,
  PaperSize.legal => l.pageSetupPaperLegal,
  PaperSize.tabloid => l.pageSetupPaperTabloid,
  PaperSize.a3 => l.pageSetupPaperA3,
  PaperSize.a4 => l.pageSetupPaperA4,
  PaperSize.a5 => l.pageSetupPaperA5,
  PaperSize.custom => l.pageSetupPaperCustom,
};

/// Paper sizes in menu order.
const _paperOrder = [
  PaperSize.letter,
  PaperSize.legal,
  PaperSize.tabloid,
  PaperSize.a3,
  PaperSize.a4,
  PaperSize.a5,
  PaperSize.custom,
];

/// The display name of a page orientation.
String orientationLabel(WriteLocalizations l, PageOrientation o) => switch (o) {
  PageOrientation.portrait => l.pageSetupPortrait,
  PageOrientation.landscape => l.pageSetupLandscape,
};

/// The display name of a page layout mode.
String layoutModeLabel(WriteLocalizations l, PageLayoutMode m) => switch (m) {
  PageLayoutMode.pages => l.pageSetupPages,
  PageLayoutMode.pageless => l.pageSetupPageless,
};

/// A margin side: [id] is stable (widget keys), the label is localized.
enum _Side { top, bottom, left, right }

class PageSetupDialog extends StatefulWidget {
  const PageSetupDialog({
    super.key,
    required this.setup,
    required this.themeMargins,
    this.readOnly = false,
    this.initialTab = 0,
  });

  final PageSetup setup;
  final PageMargins themeMargins;
  final bool readOnly;
  final int initialTab;

  @override
  State<PageSetupDialog> createState() => _PageSetupDialogState();
}

class _PageSetupDialogState extends State<PageSetupDialog> {
  late PageLayoutMode _layout = widget.setup.layout;
  late PaperSize _paper = widget.setup.paper;
  late double _customW = widget.setup.customWidthPt;
  late double _customH = widget.setup.customHeightPt;
  late PageOrientation _orientation = widget.setup.orientation;
  late bool _themeMargins = widget.setup.margins == null;
  late PageMargins _margins = widget.setup.margins ?? widget.themeMargins;
  late HeaderFooterSpec _header = widget.setup.header;
  late HeaderFooterSpec _footer = widget.setup.footer;
  late bool _differentFirst = widget.setup.differentFirstPage;
  late HeaderFooterSpec _firstHeader = widget.setup.firstPageHeader;
  late HeaderFooterSpec _firstFooter = widget.setup.firstPageFooter;
  late String _tab = widget.initialTab == 1 ? 'headerFooter' : 'page';
  _Unit _unit = _Unit.inches;

  PageSetup get _result {
    final m = _themeMargins ? widget.themeMargins : _margins;
    return PageSetup(
      layout: _layout,
      paper: _paper,
      customWidthPt: _customW,
      customHeightPt: _customH,
      orientation: _orientation,
      margins: _themeMargins ? null : _margins,
      header: _fit(_header, m.top),
      footer: _fit(_footer, m.bottom),
      differentFirstPage: _differentFirst,
      firstPageHeader: _fit(_firstHeader, m.top),
      firstPageFooter: _fit(_firstFooter, m.bottom),
      pageNumberStart: widget.setup.pageNumberStart,
      pageNumberFormat: widget.setup.pageNumberFormat,
    );
  }

  /// [spec] with its distance from the page edge moved inside [margin] when
  /// a smaller margin (e.g. the Narrow preset) would leave it outside.
  static HeaderFooterSpec _fit(HeaderFooterSpec spec, double margin) =>
      spec.distancePt < margin || margin <= 0
      ? spec
      : HeaderFooterSpec(
          enabled: spec.enabled,
          left: spec.left,
          center: spec.center,
          right: spec.right,
          distancePt: margin / 2,
        );

  double _toUnit(double pt) => _unit == _Unit.inches ? pt / 72 : pt / 72 * 25.4;
  double _fromUnit(num v) => _unit == _Unit.inches ? v * 72.0 : v / 25.4 * 72;

  String _unitSuffix(WriteLocalizations l) => _unit == _Unit.inches
      ? l.pageSetupUnitInchesShort
      : l.pageSetupUnitMillimetersShort;

  String _unitName(WriteLocalizations l, _Unit u) =>
      u == _Unit.inches ? l.pageSetupUnitInches : l.pageSetupUnitMillimeters;

  void _preset(double topBottom, double leftRight) => setState(() {
    _themeMargins = false;
    _margins = PageMargins(
      top: topBottom,
      bottom: topBottom,
      left: leftRight,
      right: leftRight,
    );
  });

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final ro = widget.readOnly;
    final errors = ro
        ? const <String>[]
        : _result.validate(themeMargins: widget.themeMargins);
    final valid = errors.isEmpty;
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.pageSetup'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.pageSetupTitle),
      description: ro ? Text(l.pageSetupReadOnly) : null,
      constraints: const BoxConstraints(maxWidth: 680),
      actions: [
        if (!ro)
          ShadButton.ghost(
            key: const ValueKey<String>('write.dialog.pageSetup.default'),
            onPressed: valid
                ? () => Navigator.of(
                    context,
                  ).pop(PageSetupResult(_result, setAsDefault: true))
                : null,
            child: Text(l.pageSetupSetAsDefault),
          ),
        ShadButton.outline(
          key: const ValueKey<String>('write.dialog.pageSetup.cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ro ? l.commonClose : l.commonCancel),
        ),
        if (!ro)
          ShadButton(
            key: const ValueKey<String>('write.dialog.pageSetup.ok'),
            onPressed: valid
                ? () => Navigator.of(context).pop(PageSetupResult(_result))
                : null,
            child: Text(l.commonOk),
          ),
      ],
      child: IgnorePointer(
        ignoring: ro,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ShadTabs<String>(
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
                tabs: [
                  ShadTab(
                    value: 'page',
                    content: _pageTab(context),
                    child: Text(l.pageSetupTabPage),
                  ),
                  ShadTab(
                    value: 'headerFooter',
                    content: _headerFooterTab(context),
                    child: Text(l.pageSetupTabHeaderFooter),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PagePreview(
                    setup: _result,
                    themeMargins: widget.themeMargins,
                  ),
                  for (final e in errors)
                    SizedBox(
                      width: 160,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          e,
                          key: const ValueKey<String>(
                            'write.dialog.pageSetup.error',
                          ),
                          style: ShadTheme.of(context).textTheme.small.copyWith(
                            color: ShadTheme.of(
                              context,
                            ).colorScheme.destructive,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: ShadTheme.of(context).textTheme.small),
  );

  Widget _pageTab(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(context, l.pageSetupLayout),
        ShadRadioGroup<PageLayoutMode>(
          initialValue: _layout,
          axis: Axis.horizontal,
          spacing: 16,
          onChanged: (v) => setState(() => _layout = v ?? _layout),
          items: [
            ShadRadio(
              key: const ValueKey<String>('write.dialog.pageSetup.pages'),
              value: PageLayoutMode.pages,
              label: Text(l.pageSetupPages),
            ),
            ShadRadio(
              key: const ValueKey<String>('write.dialog.pageSetup.pageless'),
              value: PageLayoutMode.pageless,
              label: Text(l.pageSetupPageless),
            ),
          ],
        ),
        _label(context, l.pageSetupPaperSize),
        ShadSelect<PaperSize>(
          key: const ValueKey<String>('write.dialog.pageSetup.paper'),
          initialValue: _paper,
          minWidth: 240,
          options: [
            for (final p in _paperOrder)
              ShadOption(value: p, child: Text(paperSizeLabel(l, p))),
          ],
          selectedOptionBuilder: (context, v) => Text(paperSizeLabel(l, v)),
          onChanged: (v) => setState(() => _paper = v ?? _paper),
        ),
        if (_paper == PaperSize.custom) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: WonkyNumberStepper(
                  value: _toUnit(_customW),
                  min: _unit == _Unit.inches ? 2 : 50,
                  max: _unit == _Unit.inches ? 40 : 1000,
                  step: _unit == _Unit.inches ? 0.25 : 5,
                  fractionDigits: _unit == _Unit.inches ? 2 : 0,
                  suffix: _unitSuffix(l),
                  semanticLabel: l.pageSetupWidth,
                  onChanged: (v) => setState(() => _customW = _fromUnit(v)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('×'),
              ),
              Expanded(
                child: WonkyNumberStepper(
                  value: _toUnit(_customH),
                  min: _unit == _Unit.inches ? 2 : 50,
                  max: _unit == _Unit.inches ? 40 : 1000,
                  step: _unit == _Unit.inches ? 0.25 : 5,
                  fractionDigits: _unit == _Unit.inches ? 2 : 0,
                  suffix: _unitSuffix(l),
                  semanticLabel: l.pageSetupHeight,
                  onChanged: (v) => setState(() => _customH = _fromUnit(v)),
                ),
              ),
            ],
          ),
        ],
        _label(context, l.pageSetupOrientation),
        ShadRadioGroup<PageOrientation>(
          initialValue: _orientation,
          axis: Axis.horizontal,
          spacing: 16,
          onChanged: (v) => setState(() => _orientation = v ?? _orientation),
          items: [
            for (final o in PageOrientation.values)
              ShadRadio(value: o, label: Text(orientationLabel(l, o))),
          ],
        ),
        Row(
          children: [
            _label(context, l.pageSetupMargins),
            const Spacer(),
            Semantics(
              label: l.pageSetupUnitsLabel,
              child: ShadSelect<_Unit>(
                initialValue: _unit,
                minWidth: 90,
                options: [
                  for (final u in _Unit.values)
                    ShadOption(value: u, child: Text(_unitName(l, u))),
                ],
                selectedOptionBuilder: (context, v) => Text(_unitName(l, v)),
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
            ),
          ],
        ),
        ShadCheckbox(
          key: const ValueKey<String>('write.dialog.pageSetup.themeMargins'),
          value: _themeMargins,
          onChanged: (v) => setState(() {
            _themeMargins = v;
            if (v) _margins = widget.themeMargins;
          }),
          label: Text(l.pageSetupUseThemeMargins),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: _themeMargins ? 0.5 : 1,
          child: IgnorePointer(
            ignoring: _themeMargins,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _margin(l, _Side.top, _margins.top, (v) {
                        _margins = PageMargins(
                          top: v,
                          right: _margins.right,
                          bottom: _margins.bottom,
                          left: _margins.left,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _margin(l, _Side.bottom, _margins.bottom, (v) {
                        _margins = PageMargins(
                          top: _margins.top,
                          right: _margins.right,
                          bottom: v,
                          left: _margins.left,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _margin(l, _Side.left, _margins.left, (v) {
                        _margins = PageMargins(
                          top: _margins.top,
                          right: _margins.right,
                          bottom: _margins.bottom,
                          left: v,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _margin(l, _Side.right, _margins.right, (v) {
                        _margins = PageMargins(
                          top: _margins.top,
                          right: v,
                          bottom: _margins.bottom,
                          left: _margins.left,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            Text(l.pageSetupPresets, style: theme.textTheme.muted),
            ShadButton.link(
              size: ShadButtonSize.sm,
              onPressed: () => _preset(72, 72),
              child: Text(l.pageSetupPresetNormal),
            ),
            ShadButton.link(
              size: ShadButtonSize.sm,
              onPressed: () => _preset(36, 36),
              child: Text(l.pageSetupPresetNarrow),
            ),
            ShadButton.link(
              size: ShadButtonSize.sm,
              onPressed: () => _preset(72, 144),
              child: Text(l.pageSetupPresetWide),
            ),
          ],
        ),
      ],
    );
  }

  Widget _margin(
    WriteLocalizations l,
    _Side side,
    double pt,
    void Function(double) set,
  ) {
    final (label, semantic) = switch (side) {
      _Side.top => (l.pageSetupMarginTop, l.pageSetupMarginTopSemantic),
      _Side.bottom => (
        l.pageSetupMarginBottom,
        l.pageSetupMarginBottomSemantic,
      ),
      _Side.left => (l.pageSetupMarginLeft, l.pageSetupMarginLeftSemantic),
      _Side.right => (l.pageSetupMarginRight, l.pageSetupMarginRightSemantic),
    };
    // Stable key ids (English side names, used by tests and drivers).
    final id = switch (side) {
      _Side.top => 'Top',
      _Side.bottom => 'Bottom',
      _Side.left => 'Left',
      _Side.right => 'Right',
    };
    return Row(
      children: [
        SizedBox(width: 52, child: ExcludeSemantics(child: Text(label))),
        Expanded(
          child: WonkyNumberStepper(
            key: ValueKey<String>('write.dialog.pageSetup.margin.$id'),
            value: double.parse(_toUnit(pt).toStringAsFixed(2)),
            min: 0,
            max: _unit == _Unit.inches ? 4 : 100,
            step: _unit == _Unit.inches ? 0.1 : 1,
            fractionDigits: _unit == _Unit.inches ? 2 : 0,
            suffix: _unitSuffix(l),
            semanticLabel: semantic,
            onChanged: (v) => setState(() => set(_fromUnit(v))),
          ),
        ),
      ],
    );
  }

  Widget _headerFooterTab(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          l.pageSetupTokens('{page} {pages} {title} {date} {author}'),
          style: theme.textTheme.muted.copyWith(
            fontSize: 12,
            fontFamily: WonkyTheme.monoFamily,
          ),
        ),
        _HeaderFooterEditor(
          keyPrefix: 'header',
          label: l.pageSetupHeader,
          spec: _header,
          onChanged: (s) => setState(() => _header = s),
        ),
        _HeaderFooterEditor(
          keyPrefix: 'footer',
          label: l.pageSetupFooter,
          spec: _footer,
          onChanged: (s) => setState(() => _footer = s),
        ),
        const SizedBox(height: 12),
        ShadCheckbox(
          key: const ValueKey<String>('write.dialog.pageSetup.differentFirst'),
          value: _differentFirst,
          onChanged: (v) => setState(() => _differentFirst = v),
          label: Text(l.pageSetupDifferentFirstPage),
        ),
        if (_differentFirst) ...[
          _HeaderFooterEditor(
            keyPrefix: 'firstHeader',
            label: l.pageSetupFirstPageHeader,
            spec: _firstHeader,
            onChanged: (s) => setState(() => _firstHeader = s),
          ),
          _HeaderFooterEditor(
            keyPrefix: 'firstFooter',
            label: l.pageSetupFirstPageFooter,
            spec: _firstFooter,
            onChanged: (s) => setState(() => _firstFooter = s),
          ),
        ],
        const SizedBox(height: 8),
        ShadButton.outline(
          key: const ValueKey<String>('write.dialog.pageSetup.pageNumbers'),
          size: ShadButtonSize.sm,
          leading: const Icon(LucideIcons.hash, size: 14),
          onPressed: () => setState(
            () => _footer = HeaderFooterSpec(
              enabled: true,
              left: _footer.left,
              center: '{page} / {pages}',
              right: _footer.right,
              distancePt: _footer.distancePt,
            ),
          ),
          child: Text(l.pageSetupShowPageNumbers),
        ),
      ],
    );
  }
}

class _HeaderFooterEditor extends StatefulWidget {
  const _HeaderFooterEditor({
    required this.keyPrefix,
    required this.label,
    required this.spec,
    required this.onChanged,
  });

  final String keyPrefix;
  final String label;
  final HeaderFooterSpec spec;
  final ValueChanged<HeaderFooterSpec> onChanged;

  @override
  State<_HeaderFooterEditor> createState() => _HeaderFooterEditorState();
}

class _HeaderFooterEditorState extends State<_HeaderFooterEditor> {
  late final _left = TextEditingController(text: widget.spec.left);
  late final _center = TextEditingController(text: widget.spec.center);
  late final _right = TextEditingController(text: widget.spec.right);

  @override
  void didUpdateWidget(_HeaderFooterEditor old) {
    super.didUpdateWidget(old);
    if (_center.text != widget.spec.center) _center.text = widget.spec.center;
  }

  @override
  void dispose() {
    _left.dispose();
    _center.dispose();
    _right.dispose();
    super.dispose();
  }

  void _emit({bool? enabled}) => widget.onChanged(
    HeaderFooterSpec(
      enabled: enabled ?? widget.spec.enabled,
      left: _left.text,
      center: _center.text,
      right: _right.text,
      distancePt: widget.spec.distancePt,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    Widget field(String key, TextEditingController c, String hint) => Expanded(
      child: ShadInput(
        key: ValueKey<String>(
          'write.dialog.pageSetup.${widget.keyPrefix}.$key',
        ),
        controller: c,
        enabled: widget.spec.enabled,
        placeholder: Text(hint),
        onChanged: (_) => _emit(),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadCheckbox(
            key: ValueKey<String>(
              'write.dialog.pageSetup.${widget.keyPrefix}.enabled',
            ),
            value: widget.spec.enabled,
            onChanged: (v) => _emit(enabled: v),
            label: Text(widget.label, style: theme.textTheme.small),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              field('left', _left, l.pageSetupFieldLeft),
              const SizedBox(width: 6),
              field('center', _center, l.pageSetupFieldCenter),
              const SizedBox(width: 6),
              field('right', _right, l.pageSetupFieldRight),
            ],
          ),
        ],
      ),
    );
  }
}

/// A live thumbnail of the page geometry.
class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.setup, required this.themeMargins});

  final PageSetup setup;
  final PageMargins themeMargins;

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final w = setup.pageWidthPt;
    final h = setup.pageHeightPt;
    final scale = 150 / (w > h ? w : h);
    final m = setup.marginsOr(themeMargins);
    return Container(
      width: w * scale,
      height: h * scale,
      decoration: BoxDecoration(
        color: cs.page,
        border: Border.all(color: cs.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1a000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          m.left * scale,
          m.top * scale,
          m.right * scale,
          m.bottom * scale,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: cs.ring.withValues(alpha: 0.5)),
          ),
          // Clipped: a short custom page has room for fewer lines.
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 8; i++)
                    Container(
                      margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
                      height: 2,
                      width: i == 0 ? 30 : null,
                      color: cs.mutedForeground.withValues(
                        alpha: i == 0 ? 0.6 : 0.25,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
