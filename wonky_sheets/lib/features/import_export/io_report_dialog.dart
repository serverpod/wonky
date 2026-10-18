import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';

/// The import summary / export report (11 §2.3, §6.2): a summary line, the
/// sheets table (imports) and the warnings table; *Copy report* copies the
/// warnings as TSV. MCP-operable (`describe`/`press`).
Future<void> showIoReportDialog(
  BuildContext context, {
  required String title,
  required String summary,
  List<ImportSheetReport> sheets = const [],
  required List<ImportWarning> warnings,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => _IoReportDialog(
    title: title,
    summary: summary,
    sheets: sheets,
    warnings: warnings,
  ),
);

/// The warnings as TSV (severity, sheet, range, message, count).
String warningsTsv(List<ImportWarning> warnings) =>
    ImportReport(sheets: const [], warnings: warnings).toTsv();

class _IoReportDialog extends StatefulWidget {
  const _IoReportDialog({
    required this.title,
    required this.summary,
    required this.sheets,
    required this.warnings,
  });

  final String title;
  final String summary;
  final List<ImportSheetReport> sheets;
  final List<ImportWarning> warnings;

  @override
  State<_IoReportDialog> createState() => _IoReportDialogState();
}

class _IoReportDialogState extends State<_IoReportDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  final _scroll = ScrollController();

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
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: warningsTsv(widget.warnings)));
    final s = _registeredIn;
    if (s != null && mounted) {
      s.toasts.show(sheetsL10n(context).ioReportCopied);
    }
  }

  @override
  Map<String, Object?> describe() => {
    'title': widget.title,
    'summary': widget.summary,
    'sheets': [for (final s in widget.sheets) s.toJson()],
    'warnings': [for (final w in widget.warnings) w.toJson()],
    'fields': const [],
    'buttons': [
      {'id': 'copy', 'label': 'Copy report'},
      {'id': 'close', 'label': 'Close'},
    ],
  };

  @override
  bool setField(String id, Object? value) => false;

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'copy':
        _copy();
        return true;
      case 'close' || 'cancel':
        Navigator.of(context).pop();
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final small = theme.textTheme.small;
    final muted = theme.textTheme.muted;
    Widget cell(String t, {double? width, bool bold = false, int flex = 0}) {
      final text = Text(
        t,
        style: bold ? small.copyWith(fontWeight: FontWeight.w600) : small,
        softWrap: true,
      );
      final padded = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: text,
      );
      if (width != null) return SizedBox(width: width, child: padded);
      return Expanded(flex: flex == 0 ? 1 : flex, child: padded);
    }

    String severity(ImportSeverity s) => switch (s) {
      ImportSeverity.info => l.ioSeverityInfo,
      ImportSeverity.warning => l.ioSeverityWarning,
      ImportSeverity.error => l.ioSeverityError,
    };

    return ShadDialog(
      key: const ValueKey<String>('dialog.ioReport'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(widget.title),
      description: Text(widget.summary),
      actions: [
        if (widget.warnings.isNotEmpty)
          ShadButton.outline(
            key: const ValueKey<String>('dialog.ioReport.copy'),
            leading: const Icon(LucideIcons.copy, size: 16),
            onPressed: _copy,
            child: Text(l.ioCopyReport),
          ),
        ShadButton(
          key: const ValueKey<String>('dialog.ioReport.close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.ioClose),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 420),
        child: SizedBox(
          width: 640,
          child: WonkyScrollArea(
            controller: _scroll,
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.sheets.isNotEmpty) ...[
                    Text(l.ioReportSheets, style: theme.textTheme.large),
                    const SizedBox(height: 6),
                    for (final s in widget.sheets)
                      Row(
                        children: [
                          cell(s.name, flex: 3),
                          cell(
                            l.ioReportSheetSize(s.rows, s.columns, s.cells),
                            flex: 4,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.warnings.isEmpty)
                    Text(l.ioReportNoWarnings, style: muted)
                  else ...[
                    Container(
                      color: cs.muted,
                      child: Row(
                        children: [
                          cell(l.ioReportSeverity, width: 84, bold: true),
                          cell(l.ioReportWhere, width: 120, bold: true),
                          cell(l.ioReportMessage, flex: 4, bold: true),
                          cell('#', width: 48, bold: true),
                        ],
                      ),
                    ),
                    for (final w in widget.warnings)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: cs.border)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            cell(severity(w.severity), width: 84),
                            cell([?w.sheet, ?w.range].join('!'), width: 120),
                            cell(w.message, flex: 4),
                            cell('${w.count}', width: 48),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
