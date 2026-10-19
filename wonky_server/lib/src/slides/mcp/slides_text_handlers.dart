import 'package:wonky_slides_core/find.dart';
import 'package:wonky_slides_core/markdown.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';

import '../../platform/mcp/tool_support.dart';
import '../ai/slides_ai_guard.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_read_handlers.dart';
import 'slides_writes.dart';

import 'slides_element_handlers.dart';

/// MCP tools for the text of deck elements (Slides 11 §3): set, format and
/// find & replace.
abstract final class SlidesTextHandlers {
  // ------------------------------------------------------------ set_text

  static Future<ToolResult> setText(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final warnings = <SlidesWarning>[];
    late String id;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_text',
      force: a.boolean('force') ?? false,
      warnings: warnings,
      build: (s) {
        final m = s.model;
        id = SlidesMcp.elementId(m, a.values['element']);
        final rec = m.element(id)!;
        SlidesElementHandlers.requireText(rec);
        var delta = SlidesInput.text(
          m,
          a.values['text'],
          pointer: '/text',
          warnings: warnings,
          elementId: id,
        );
        final old = rec.text;
        if (a.boolean('keep_formatting') ?? true) {
          delta = SlidesMarkdownCodec.keepFormatting(old, delta);
        }
        final mode = a.string('mode') ?? 'replace';
        if (mode != 'replace') {
          delta = SlidesMarkdownCodec.concat(
            old,
            delta,
            prepend: mode == 'prepend',
          );
        }
        s.run(SetText(ElementText(id), delta));
      },
    );
    final m = t.model;
    final slideId = m.element(id)?.slideId;
    Map<String, Object?>? overflow;
    if (slideId != null) {
      for (final w in _overflow(m, slideId, id)) {
        o.warnings.add(w);
        overflow = {'element_id': id, 'message': w.message};
      }
    }
    return SlidesWrites.result(o, 'Set the text of $id', {
      'overflow': ?overflow,
    });
  }

  static List<SlidesWarning> _overflow(DeckModel m, String slideId, String id) {
    final out = <SlidesWarning>[];
    final rs = SlideResolver(m).resolve(slideId);
    if (rs == null) return out;
    try {
      final scene = SlidesReadHandlers.fit(m, rs);
      final f = scene[id];
      if (f != null) {
        out.add(
          SlidesWarning(
            'text_overflow',
            f.$2
                ? 'The text overflows its box.'
                : 'The text is shrunk to ${(f.$1 * 100).round()} %.',
            elementId: id,
          ),
        );
      }
    } on Object {
      // Informational.
    }
    return out;
  }

  // --------------------------------------------------------- format_text

  static Future<ToolResult> formatText(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final format = a.object('format')!;
    final attrs = <String, Object?>{
      for (final e in format.entries)
        switch (e.key) {
          'line_height' => 'lineHeight',
          _ => e.key,
        }: e.key == 'list' && e.value == 'none'
            ? null
            : e.value,
    };
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.format_text',
      force: a.boolean('force') ?? false,
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.elementId(m, a.values['element']);
        final rec = m.element(id)!;
        SlidesElementHandlers.requireText(rec);
        final range = a.values['range'];
        final target = ElementText(id);
        if (range == null || range == 'all') {
          s.run(FormatText([target], attrs));
          return;
        }
        final plain = SlidesText.plainText(rec.text);
        if (range is Map && range['quote'] is String) {
          final quote = range['quote']! as String;
          final occ = (range['occurrence'] as num?)?.toInt() ?? 1;
          var at = -1;
          for (var k = 0; k < occ; k++) {
            at = plain.indexOf(quote, at + 1);
            if (at < 0) break;
          }
          if (at < 0) {
            throw McpToolException(
              McpErrorCode.notFound,
              'Occurrence $occ of "$quote" not found in the text.',
              details: {'pointer': '/range/quote'},
            );
          }
          s.run(FormatText([target], attrs, start: at, length: quote.length));
          return;
        }
        if (range is Map && range['paragraphs'] is List) {
          final starts = <int>[0];
          for (var k = 0; k < plain.length; k++) {
            if (plain.codeUnitAt(k) == 0x0A) starts.add(k + 1);
          }
          for (final p in range['paragraphs']! as List) {
            final i = (p as num).toInt();
            if (i >= starts.length - 1 || i < 0) {
              throw SlidesMcp.invalid(
                'Paragraph $i does not exist (the text has '
                '${starts.length - 1}).',
                pointer: '/range/paragraphs',
              );
            }
            final len = starts[i + 1] - 1 - starts[i];
            s.run(
              FormatText(
                [target],
                attrs,
                start: starts[i],
                length: len < 1 ? 1 : len,
              ),
            );
          }
        }
      },
    );
    return SlidesWrites.result(o, 'Formatted the text');
  }

  // -------------------------------------------------------- replace_text

  static Future<ToolResult> replaceText(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final find = a.requireString('find');
    final replace = a.requireString('replace');
    final where = {
      for (final x in a.list('in') ?? const ['text', 'notes']) '$x',
    };
    final useRegex = a.boolean('regex') ?? false;
    var replaced = 0;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.replace_text',
      force: a.boolean('force') ?? false,
      confirmIf: () => SlidesAiGuard.replaceReason(replaced),
      build: (s) {
        final m = s.model;
        final scope = SlidesMcp.slideIds(
          m,
          (a.object('scope')?['slides'] as List?)?.cast<Object?>(),
          pointer: '/scope/slides',
        );
        final options = DeckFindOptions(
          matchCase: a.boolean('match_case') ?? false,
          wholeWords: a.boolean('whole_word') ?? false,
          useRegex: useRegex,
          includeNotes: where.contains('notes'),
          includeSkipped: true,
          scope: scope.isEmpty ? FindScope.all : FindScope.selectedSlides,
          slideIds: scope,
        );
        final RegExp? found;
        try {
          found = DeckFind.pattern(find, options);
        } on FormatException catch (e) {
          throw SlidesMcp.invalid('Invalid regular expression: ${e.message}');
        }
        if (found == null) return;
        final re = found;
        final byBody = <String, (TextTarget, List<(int, int, String)>)>{};
        for (final x in DeckFind.search(m, find, options)) {
          final notes = x.target is NotesText;
          if (!notes && !where.contains('text')) continue;
          final entry = byBody.putIfAbsent(
            DeckFind.bodyKey(x.target),
            () => (x.target, []),
          );
          entry.$2.add((
            x.start,
            x.length,
            DeckFind.expand(x.text, replace, re, useRegex: useRegex),
          ));
        }
        for (final (target, ranges) in byBody.values) {
          replaced += ranges.length;
          switch (target) {
            case ElementText(:final elementId):
              s.run(
                SetText(
                  target,
                  DeckFind.replaceRanges(m.element(elementId)!.text!, ranges),
                ),
              );
            case CellText(:final elementId, :final rowId, :final columnId):
              final cell = m
                  .cellsOf(elementId)
                  .firstWhere(
                    (c) => c.rowId == rowId && c.columnId == columnId,
                  );
              s.run(
                SetCells(elementId, [
                  CellWrite(rowId, columnId, {
                    SlidesCols.text: DeckFind.replaceRanges(cell.text!, ranges),
                  }),
                ]),
              );
            case NotesText(:final slideId):
              s.run(
                SetSlideProps(
                  [
                    slideId,
                  ],
                  notes: Patch(
                    DeckFind.replaceRanges(
                      m.slide(slideId)!.notes!,
                      ranges,
                      notes: true,
                    ),
                  ),
                ),
              );
          }
        }
        if (where.contains('code')) {
          final only = scope.toSet();
          for (final slide in m.slides) {
            if (only.isNotEmpty && !only.contains(slide.id)) continue;
            for (final e in m.allElementsOf(slide.id)) {
              if (e.kind != ElementKind.code) continue;
              for (final st in m.codeStatesOf(e.id)) {
                var n = 0;
                final next = st.code.replaceAllMapped(re, (match) {
                  n++;
                  return DeckFind.expand(
                    match.group(0)!,
                    replace,
                    re,
                    useRegex: useRegex,
                  );
                });
                if (n > 0) {
                  replaced += n;
                  s.run(SetCode(st.id, next));
                }
              }
            }
          }
        }
      },
    );
    return SlidesWrites.result(o, 'Replaced $replaced occurrence(s)', {
      'replaced': replaced,
    });
  }
}
