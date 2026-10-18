import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart' show DriveItemView;
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show OutlineEntry;

import '../../../l10n/write_l10n.dart';

/// Document languages (BCP-47 with native names), Write 05 §12.7.
const documentLanguages = <String, String>{
  'en-US': 'English (United States)',
  'en-GB': 'English (United Kingdom)',
  'en-AU': 'English (Australia)',
  'en-CA': 'English (Canada)',
  'sv-SE': 'Svenska',
  'da-DK': 'Dansk',
  'nb-NO': 'Norsk bokmål',
  'fi-FI': 'Suomi',
  'de-DE': 'Deutsch',
  'de-CH': 'Deutsch (Schweiz)',
  'fr-FR': 'Français',
  'fr-CA': 'Français (Canada)',
  'es-ES': 'Español (España)',
  'es-MX': 'Español (México)',
  'it-IT': 'Italiano',
  'pt-PT': 'Português (Portugal)',
  'pt-BR': 'Português (Brasil)',
  'nl-NL': 'Nederlands',
  'pl-PL': 'Polski',
  'cs-CZ': 'Čeština',
  'sk-SK': 'Slovenčina',
  'hu-HU': 'Magyar',
  'ro-RO': 'Română',
  'el-GR': 'Ελληνικά',
  'tr-TR': 'Türkçe',
  'ru-RU': 'Русский',
  'uk-UA': 'Українська',
  'he-IL': 'עברית',
  'ar': 'العربية',
  'hi-IN': 'हिन्दी',
  'th-TH': 'ไทย',
  'vi-VN': 'Tiếng Việt',
  'id-ID': 'Bahasa Indonesia',
  'ja-JP': '日本語',
  'ko-KR': '한국어',
  'zh-CN': '中文（简体）',
  'zh-TW': '中文（繁體）',
};

/// The display name of a language tag (native names stay untranslated);
/// "Not set" in [l] (English when omitted).
String languageName(String? tag, [WriteLocalizations? l]) => tag == null
    ? (l ?? writeL10nEnglish).docDialogLanguageNotSet
    : (documentLanguages[tag] ?? tag);

/// A date and time like "Oct 13, 2026 4:05 PM" in [locale] (US English when
/// the locale has no date symbols).
String formatDocumentDate(DateTime d, String locale) {
  try {
    return intl.DateFormat.yMMMd(locale).add_jm().format(d);
  } catch (_) {
    return intl.DateFormat.yMMMd('en_US').add_jm().format(d);
  }
}

/// Document language (`write.dialog.language`). Returns the tag.
Future<String?> showLanguageDialog(BuildContext context, {String? current}) =>
    showShadDialog<String>(
      context: context,
      builder: (context) => _LanguageDialog(current: current),
    );

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({this.current});
  final String? current;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late String _value = widget.current ?? 'en-US';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final options = documentLanguages.entries.where(
      (e) =>
          _search.isEmpty ||
          e.value.toLowerCase().contains(_search.toLowerCase()) ||
          e.key.toLowerCase().contains(_search.toLowerCase()),
    );
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.language'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.docDialogLanguageTitle),
      description: Text(l.docDialogLanguageDescription),
      constraints: const BoxConstraints(maxWidth: 420),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('write.dialog.language.ok'),
          onPressed: () => Navigator.of(context).pop(_value),
          child: Text(l.commonOk),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ShadSelect<String>.withSearch(
          key: const ValueKey<String>('write.dialog.language.select'),
          initialValue: _value,
          minWidth: 360,
          maxHeight: 320,
          searchPlaceholder: Text(l.docDialogLanguageSearch),
          onSearchChanged: (v) => setState(() => _search = v),
          options: [
            for (final e in options)
              ShadOption(value: e.key, child: Text('${e.value}  ·  ${e.key}')),
          ],
          selectedOptionBuilder: (context, v) => Text(languageName(v, l)),
          onChanged: (v) => setState(() => _value = v ?? _value),
        ),
      ),
    );
  }
}

/// Document details (`write.dialog.properties`, Write 05 §12.8). Returns the
/// edited front matter (null when unchanged / cancelled).
Future<String?> showDocumentDetailsDialog(
  BuildContext context, {
  required DriveItemView? item,
  required String location,
  required int words,
  required String language,
  required String themeName,
  required int revision,
  required String? frontMatter,
  required bool canEdit,
}) => showShadDialog<String>(
  context: context,
  builder: (_) => _DetailsDialog(
    item: item,
    location: location,
    words: words,
    language: language,
    themeName: themeName,
    revision: revision,
    frontMatter: frontMatter,
    canEdit: canEdit,
  ),
);

class _DetailsDialog extends StatefulWidget {
  const _DetailsDialog({
    required this.item,
    required this.location,
    required this.words,
    required this.language,
    required this.themeName,
    required this.revision,
    required this.frontMatter,
    required this.canEdit,
  });

  final DriveItemView? item;
  final String location;
  final int words;
  final String language;
  final String themeName;
  final int revision;
  final String? frontMatter;
  final bool canEdit;

  @override
  State<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<_DetailsDialog> {
  late final _fm = TextEditingController(text: widget.frontMatter ?? '');
  String? _error;

  @override
  void dispose() {
    _fm.dispose();
    super.dispose();
  }

  /// Minimal YAML sanity check: `key: value` lines, lists, comments.
  String? _validate(String text) {
    final l = writeL10n(context);
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      if (line.trim() == '---') return l.docDialogFrontMatterFences(i + 1);
      final isList = line.trimLeft().startsWith('- ');
      final isContinuation = line.startsWith(' ') || line.startsWith('\t');
      if (!isList && !isContinuation && !line.contains(':')) {
        return l.docDialogFrontMatterExpected(i + 1);
      }
    }
    return null;
  }

  void _save() {
    final text = _fm.text.trimRight();
    final error = _validate(text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(text == (widget.frontMatter ?? '') ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    final i = widget.item;
    String date(DateTime d) => formatDocumentDate(d.toLocal(), l.localeName);
    final decimal = intl.NumberFormat.decimalPattern(l.localeName);
    final oneDecimal = intl.NumberFormat('0.0', l.localeName);
    String size(int bytes) => bytes < 1024
        ? l.docDialogSizeBytes(bytes)
        : bytes < 1024 * 1024
        ? l.docDialogSizeKilobytes(oneDecimal.format(bytes / 1024))
        : l.docDialogSizeMegabytes(oneDecimal.format(bytes / 1024 / 1024));
    final modifiedBy = i?.modifiedBy;
    final rows = <(String, String)>[
      (l.docDialogRowTitle, i?.name ?? ''),
      (l.docDialogRowLocation, widget.location),
      if (i != null) (l.docDialogRowOwner, i.owner.displayName),
      if (i != null) (l.docDialogRowCreated, date(i.createdAt)),
      if (i != null)
        (
          l.docDialogRowModified,
          modifiedBy == null
              ? date(i.modifiedAt)
              : l.docDialogModifiedBy(
                  date(i.modifiedAt),
                  modifiedBy.displayName,
                ),
        ),
      if (i != null) (l.docDialogRowSize, size(i.sizeBytes)),
      (l.docDialogRowWords, decimal.format(widget.words)),
      (l.docDialogRowLanguage, widget.language),
      (l.docDialogRowTheme, widget.themeName),
      (l.docDialogRowRevision, '${widget.revision}'),
    ];
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.properties'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.docDialogDetailsTitle),
      constraints: const BoxConstraints(maxWidth: 560),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonClose),
        ),
        if (widget.canEdit)
          ShadButton(
            key: const ValueKey<String>('write.dialog.properties.save'),
            onPressed: _save,
            child: Text(l.commonSave),
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(k, style: theme.textTheme.muted),
                  ),
                  Expanded(child: Text(v, style: theme.textTheme.small)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(l.docDialogFrontMatterLabel, style: theme.textTheme.small),
          const SizedBox(height: 6),
          ShadTextarea(
            key: const ValueKey<String>('write.dialog.properties.frontMatter'),
            controller: _fm,
            readOnly: !widget.canEdit,
            minHeight: 96,
            maxHeight: 220,
            placeholder: Text(l.docDialogFrontMatterPlaceholder),
            style: TextStyle(
              fontFamily: WonkyTheme.monoFamily,
              fontSize: 13,
              color: theme.colorScheme.foreground,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Go to heading" quick list (`write.nav.goToHeading` without args).
Future<OutlineEntry?> showGoToHeadingDialog(
  BuildContext context,
  List<OutlineEntry> outline,
) => showShadDialog<OutlineEntry>(
  context: context,
  builder: (_) => _GoToHeading(outline: outline),
);

class _GoToHeading extends StatefulWidget {
  const _GoToHeading({required this.outline});
  final List<OutlineEntry> outline;

  @override
  State<_GoToHeading> createState() => _GoToHeadingState();
}

class _GoToHeadingState extends State<_GoToHeading> {
  String _q = '';
  int _i = 0;

  List<OutlineEntry> get _matches => [
    for (final e in widget.outline)
      if (_q.isEmpty || e.text.toLowerCase().contains(_q.toLowerCase())) e,
  ];

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final m = _matches;
    final minLevel = widget.outline.isEmpty
        ? 1
        : widget.outline.map((e) => e.level).reduce((a, b) => a < b ? a : b);
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.goToHeading'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.docDialogGoToHeadingTitle),
      constraints: const BoxConstraints(maxWidth: 480),
      child: Focus(
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(
              () => _i = (_i + 1).clamp(0, m.isEmpty ? 0 : m.length - 1),
            );
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(
              () => _i = (_i - 1).clamp(0, m.isEmpty ? 0 : m.length - 1),
            );
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            ShadInput(
              autofocus: true,
              placeholder: Text(l.docDialogSearchHeadings),
              leading: const Icon(LucideIcons.search, size: 16),
              onChanged: (v) => setState(() {
                _q = v;
                _i = 0;
              }),
              onSubmitted: (_) {
                if (m.isNotEmpty) {
                  Navigator.of(context).pop(m[_i.clamp(0, m.length - 1)]);
                }
              },
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: m.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l.docDialogNoHeadings,
                        style: theme.textTheme.muted,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: m.length,
                      itemBuilder: (context, i) {
                        final e = m[i];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(e),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              10.0 + (e.level - minLevel) * 14,
                              7,
                              10,
                              7,
                            ),
                            decoration: BoxDecoration(
                              color: i == _i ? theme.colorScheme.accent : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              e.text.isEmpty
                                  ? l.docDialogUntitledHeading
                                  : e.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.small.copyWith(
                                fontWeight: e.level == minLevel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Markdown & formatting guide (`write.help.markdownGuide`).
Future<void> showMarkdownGuide(BuildContext context) => showShadDialog<void>(
  context: context,
  builder: (context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final rows = [
      (l.docDialogGuideSyntaxHeadings, l.docDialogGuideHeadings),
      (l.docDialogGuideSyntaxBold, l.docDialogGuideBold),
      (l.docDialogGuideSyntaxItalic, l.docDialogGuideItalic),
      (l.docDialogGuideSyntaxStrikethrough, l.docDialogGuideStrikethrough),
      (l.docDialogGuideSyntaxCode, l.docDialogGuideCode),
      (l.docDialogGuideSyntaxLink, l.docDialogGuideLink),
      (l.docDialogGuideSyntaxBullets, l.docDialogGuideBullets),
      (l.docDialogGuideSyntaxNumbered, l.docDialogGuideNumbered),
      (l.docDialogGuideSyntaxChecklist, l.docDialogGuideChecklist),
      (l.docDialogGuideSyntaxQuote, l.docDialogGuideQuote),
      (l.docDialogGuideSyntaxCodeBlock, l.docDialogGuideCodeBlock),
      ('---', l.docDialogGuideDivider),
      ('/', l.docDialogGuideCommandMenu),
      ('@', l.docDialogGuideMention),
    ];
    final mono = TextStyle(
      fontFamily: WonkyTheme.monoFamily,
      fontSize: 13,
      color: cs.foreground,
    );
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.markdownGuide'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.docDialogGuideTitle),
      description: Text(l.docDialogGuideDescription),
      constraints: const BoxConstraints(maxWidth: 600),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.docDialogGuideGotIt),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (syntax, meaning) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.border)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(syntax, style: mono)),
                  Expanded(child: Text(meaning, style: theme.textTheme.small)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(l.docDialogGuideFootnote, style: theme.textTheme.muted),
        ],
      ),
    );
  },
);
