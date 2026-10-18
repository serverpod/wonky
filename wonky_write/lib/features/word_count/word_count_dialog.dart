import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';
import '../screen/command_invoke.dart';
import '../screen/write_document_controller.dart';

/// "1,234" in the locale of [l] (English when omitted).
String formatCount(int n, [WriteLocalizations? l]) =>
    intl.NumberFormat.decimalPattern(
      (l ?? writeL10nEnglish).localeName,
    ).format(n);

/// "3 min" / "< 1 min" in [l] (English when omitted).
String readingTime(DocumentStats s, [WriteLocalizations? l]) {
  final strings = l ?? writeL10nEnglish;
  final m = s.readingTimeMinutes;
  return m <= 0
      ? strings.wordCountReadingTimeUnderOne
      : strings.wordCountReadingTimeMinutes(m);
}

/// Status bar label: "1,234 words" or "56 of 1,234 words" in [l] (English
/// when omitted).
String wordCountLabel(
  DocumentStats doc,
  DocumentStats? selection, [
  WriteLocalizations? l,
]) {
  final strings = l ?? writeL10nEnglish;
  if (selection == null) return strings.wordCountWords(doc.words);
  return strings.wordCountSelectionOfWords(selection.words, doc.words);
}

/// Word count dialog (`write.dialog.wordCount`, Write 05 §12.5).
Future<void> showWordCountDialog(
  BuildContext context,
  WriteDocumentController doc, {
  int? pageCount,
}) {
  doc.insights.refresh();
  return showShadDialog<void>(
    context: context,
    builder: (context) => WordCountDialog(doc: doc, pageCount: pageCount),
  );
}

class WordCountDialog extends StatelessWidget {
  const WordCountDialog({super.key, required this.doc, this.pageCount});

  final WriteDocumentController doc;
  final int? pageCount;

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    String count(int n) => formatCount(n, l);
    String time(DocumentStats s) => readingTime(s, l);
    return ListenableBuilder(
      listenable: doc,
      builder: (context, _) {
        final s = doc.insights.stats;
        final sel = doc.insights.selectionStats;
        final rows = <(String, String, String?)>[
          if (pageCount != null) (l.wordCountPages, count(pageCount!), null),
          (
            l.wordCountRowWords,
            count(s.words),
            sel == null ? null : count(sel.words),
          ),
          (
            l.wordCountCharacters,
            count(s.characters),
            sel == null ? null : count(sel.characters),
          ),
          (
            l.wordCountCharactersNoSpaces,
            count(s.charactersNoSpaces),
            sel == null ? null : count(sel.charactersNoSpaces),
          ),
          (
            l.wordCountParagraphs,
            count(s.paragraphs),
            sel == null ? null : count(sel.paragraphs),
          ),
          (l.wordCountReadingTime, time(s), sel == null ? null : time(sel)),
        ];
        TextStyle head = theme.textTheme.small.copyWith(
          color: theme.colorScheme.mutedForeground,
        );
        return ShadDialog(
          key: const ValueKey<String>('write.dialog.wordCount'),
          closeIcon: const WonkyDialogCloseButton(),
          title: Text(l.wordCountTitle),
          constraints: const BoxConstraints(maxWidth: 420),
          actions: [
            ShadButton(
              key: const ValueKey<String>('write.dialog.wordCount.ok'),
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.commonOk),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      const SizedBox(),
                      _cell(
                        Text(l.wordCountColumnDocument, style: head),
                        right: true,
                      ),
                      sel == null
                          ? const SizedBox()
                          : _cell(
                              Text(l.wordCountColumnSelection, style: head),
                              right: true,
                            ),
                    ],
                  ),
                  for (final (label, value, selValue) in rows)
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.colorScheme.border),
                        ),
                      ),
                      children: [
                        _cell(Text(label, style: theme.textTheme.small)),
                        _cell(
                          Text(
                            value,
                            style: theme.textTheme.small.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          right: true,
                        ),
                        _cell(
                          Text(
                            selValue ?? '',
                            style: theme.textTheme.small.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          right: true,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ShadCheckbox(
                    key: const ValueKey<String>(
                      'write.dialog.wordCount.showWhileTyping',
                    ),
                    value: doc.viewPrefs.showWordCount,
                    onChanged: (_) =>
                        invokeCommand(context, 'write.view.toggleWordCount'),
                    label: Text(l.wordCountShowWhileTyping),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(Widget child, {bool right = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    ),
  );
}
