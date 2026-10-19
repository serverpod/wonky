import 'dart:convert';

import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../../platform/ai/untrusted_text.dart';
import '../mcp/slides_read_handlers.dart';

/// The deck context of an AI request (Slides 11 §6.2).
class SlidesAiContext {
  SlidesAiContext({required this.summary, required this.lines});

  /// The deck summary (title, size, theme, layouts, groups, slide list).
  final String summary;

  /// One line per slide (by slide id), for "Deck changed" elements.
  final Map<String, String> lines;

  /// A stable hash of [summary]: a "Deck changed" element is appended
  /// when it changes during a thread.
  int get fingerprint => SlidesContextBuilder.stableHash(summary);

  /// The cached-prefix block of the first user turn.
  String get snapshot => SlidesContextBuilder.wrap(summary);
}

/// Builds the AI context of a deck (Slides 11 §6.2) within budgets
/// (≈ 4 characters per token): the deck summary (≤ 4k tokens; titles only
/// beyond 150 slides) in the cached prefix; the current slide (every
/// element as compact JSON + notes, ≤ 6k tokens) and the selection are
/// volatile and go at the end of the latest user turn. Deck text is
/// wrapped in `<deck_content>` (untrusted data, never instructions); a
/// closing tag inside the content is escaped so text cannot leave the
/// wrapper.
abstract final class SlidesContextBuilder {
  static const charsPerToken = 4;
  static const summaryTokens = 4000;
  static const slideTokens = 6000;
  static const titlesOnlyAbove = 150;
  static const maxLine = 120;

  /// A stable 31-bit hash (FNV-1a) of [s].
  static int stableHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  static String _cut(String s, int tokens) {
    final max = tokens * charsPerToken;
    if (s.length <= max) return s;
    return '${s.substring(0, max)}\n[… cut to fit the context budget]';
  }

  static String _short(String s, [int max = maxLine]) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= max ? t : '${t.substring(0, max - 1)}…';
  }

  /// [content] in `<deck_content>` tags (closing tags inside escaped).
  static String wrap(String content, {String tag = 'deck_content'}) =>
      UntrustedText.wrap(tag, content);

  /// [content] with its own `<tag>`s (any case and spacing) defused.
  static String escape(String content, {String tag = 'deck_content'}) =>
      UntrustedText.escape(content, tag);

  /// The plain text of every element of [slideId] except its title, on
  /// one line.
  static String slideText(DeckModel m, String slideId) {
    final parts = <String>[];
    for (final e in m.allElementsOf(slideId)) {
      if (e.placeholderType == SlidePlaceholderType.title) continue;
      final t = SlidesText.plainText(e.text).trim();
      if (t.isNotEmpty) parts.add(t);
    }
    return parts.join(' · ');
  }

  /// The context of [m] titled [title].
  static SlidesAiContext build(DeckModel m, {required String title}) {
    final d = m.deck;
    final theme = d?.themeId == null ? null : m.theme(d!.themeId!);
    final b = StringBuffer()
      ..writeln(
        'Presentation: "${_short(d?.title.isNotEmpty == true ? d!.title : title, 200)}"',
      )
      ..writeln(
        'Size: ${d?.width ?? 1920} × ${d?.height ?? 1080} slide units, '
        '${d?.appearance.name ?? 'light'} appearance',
      );
    if (theme != null) b.writeln('Theme: ${_short(theme.name, 80)}');
    final layouts = SlidesReadHandlers.layoutsJson(m, d?.themeId);
    if (layouts.isNotEmpty) {
      b.writeln(
        'Layouts: ${[for (final l in layouts) l['key'] ?? l['name']].whereType<String>().toSet().join(', ')}',
      );
    }
    final groups = m.groups;
    if (groups.isNotEmpty) {
      b.writeln('Groups:');
      for (final g in groups) {
        b.writeln(
          '- ${g.id} "${_short(g.title, 80)}"${g.skipped ? ' (skipped)' : ''}',
        );
      }
    }
    final slides = m.slides;
    final titlesOnly = slides.length > titlesOnlyAbove;
    final lines = <String, String>{};
    b.writeln('Slides (${slides.length}):');
    for (final (i, s) in slides.indexed) {
      final layout = s.layoutId == null ? null : m.layout(s.layoutId!);
      final t = SlidesReadHandlers.slideTitle(m, s.id);
      final kinds = <String, int>{};
      for (final e in m.allElementsOf(s.id)) {
        kinds[e.kind.name] = (kinds[e.kind.name] ?? 0) + 1;
      }
      final line = StringBuffer(
        '${i + 1}. [${s.id}] "${_short(t, 80)}" '
        '(${layout?.key ?? 'custom'}',
      );
      if (s.groupId != null) line.write(', group ${s.groupId}');
      if (s.skipped) line.write(', skipped');
      line.write(')');
      if (!titlesOnly) {
        if (kinds.isNotEmpty) {
          line.write(
            ' ${[for (final e in kinds.entries) '${e.value} ${e.key}'].join(', ')}',
          );
        }
        final text = slideText(m, s.id);
        if (text.isNotEmpty) line.write(' — ${_short(text)}');
        if (!SlidesText.isBlank(s.notes)) line.write(' [notes]');
      }
      lines[s.id] = line.toString();
      b.writeln(line);
    }
    return SlidesAiContext(
      summary: _cut(b.toString().trimRight(), summaryTokens),
      lines: lines,
    );
  }

  /// The "Deck changed" element of a later turn: the slides added, removed
  /// or edited since [previous] (the summary sent before), or null.
  static String? update({
    required String? previous,
    required SlidesAiContext now,
  }) {
    if (previous == null) return null;
    final before = <String, String>{};
    for (final l in previous.split('\n')) {
      final m = RegExp(r'^\d+\. \[([^\]]+)\]').firstMatch(l);
      if (m != null) {
        before[m.group(1)!] = l.replaceFirst(RegExp(r'^\d+\. '), '');
      }
    }
    final edited = <String>[];
    final added = <String>[];
    var position = 0;
    for (final e in now.lines.entries) {
      position++;
      final was = before.remove(e.key);
      final line = e.value.replaceFirst(RegExp(r'^\d+\. '), '');
      if (was == null) {
        added.add('$position');
      } else if (was != line) {
        edited.add('$position');
      }
    }
    final removed = before.length;
    if (edited.isEmpty && added.isEmpty && removed == 0) return null;
    final parts = [
      if (edited.isNotEmpty) 'slides ${edited.join(', ')} edited',
      if (added.isNotEmpty) 'slides ${added.join(', ')} added',
      if (removed > 0) '$removed slide${removed == 1 ? '' : 's'} removed',
    ];
    return 'Deck changed since the summary above: ${parts.join('; ')}. '
        'The current summary:\n${wrap(now.summary)}';
  }

  /// The current slide [slideId] as compact JSON (elements with text as
  /// Markdown, notes), wrapped.
  static String currentSlide(DeckModel m, String slideId) {
    final json = SlidesReadHandlers.slideJson(
      m,
      slideId,
      include: const {'elements', 'text', 'notes'},
    );
    return wrap(_cut(jsonEncode(_compact(json)), slideTokens));
  }

  /// Drops nulls and empty collections.
  static Object? _compact(Object? v) => switch (v) {
    Map() => {
      for (final e in v.entries)
        if (_compact(e.value) case final Object x
            when !(x is Map && x.isEmpty) && !(x is List && x.isEmpty))
          '${e.key}': x,
    },
    List() => [for (final x in v) ?_compact(x)],
    _ => v,
  };
}
