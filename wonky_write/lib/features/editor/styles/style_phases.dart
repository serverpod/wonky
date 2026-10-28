import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_code/wonky_code.dart';

import '../attributions/wonky_attributions.dart';
import '../components/cell_layout.dart' show CellSlots;
import '../mapping/wonky_schema.dart';
import 'write_stylesheet.dart';

/// Overlays presentation-only [CodeTokenAttribution]s on code block view
/// models (Write 04 §15.4). The document is never changed.
///
/// Tokens come from the shared [DefaultCodeTokenizer] (`wonky_code`, Write
/// 04 §15.5): TextMate grammars first (embedded, so blocks are highlighted
/// on their first frame), highlight.js for the other languages — the same
/// tokenizer as Write's exports and Wonky Slides (M10, v2 review Q25).
///
/// Results are cached per (node, text, language). Large blocks are tokenized
/// after a debounce so that typing stays responsive; until then the block
/// renders without highlighting.
class CodeHighlightStylePhase extends SingleColumnLayoutStylePhase {
  CodeHighlightStylePhase({
    this.debounce = const Duration(milliseconds: 120),
    this.syncLimit = 20000,
  });

  final Duration debounce;

  /// Blocks up to this many characters are tokenized synchronously.
  final int syncLimit;

  final _cache = <String, _Highlighted>{};
  final _pending = <String, Timer>{};
  bool _closed = false;

  // No `dispose` override: super_editor disposes style phases whenever it
  // recreates its layout presenter (stylesheet, zoom or theme change) and
  // then keeps using the same phase objects, so pending tokenizations must
  // survive it. The editor calls [close] instead.

  /// Cancels pending work for good (when the editor is disposed).
  void close() {
    _closed = true;
    for (final timer in _pending.values) {
      timer.cancel();
    }
    _pending.clear();
  }

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    final result = SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final model in viewModel.componentViewModels)
          _highlight(document, model),
      ],
    );
    // Forget deleted blocks (W-21).
    if (_cache.length > _seen.length || _outputs.length > _seen.length) {
      _cache.removeWhere((id, _) => !_seen.contains(id));
      _outputs.removeWhere((id, _) => !_seen.contains(id));
    }
    _seen.clear();
    return result;
  }

  /// Code block ids met in the current [style] pass.
  final _seen = <String>{};

  /// The last highlighted view model per code block and the input it was
  /// made from: an equal input (a keystroke elsewhere) gets the same output
  /// instead of a new copy with every token re-attributed (Write 04 §36).
  final _outputs =
      <
        String,
        ({
          SingleColumnLayoutComponentViewModel input,
          List<(int, int, String)> spans,
          SingleColumnLayoutComponentViewModel output,
        })
      >{};

  SingleColumnLayoutComponentViewModel _highlight(
    Document document,
    SingleColumnLayoutComponentViewModel model,
  ) {
    if (model is! TextComponentViewModel) return model;
    final node = document.getNodeById(model.nodeId);
    if (node == null || !isCodeBlockNode(node)) return model;
    _seen.add(node.id);
    final language = CodeLanguages.normalize(codeLanguageOf(node));
    if (!_tokenizer.supports(language)) return model;
    final text = model.text;
    final plain = text.toPlainText(includePlaceholders: false);

    final cached = _cache[node.id];
    if (cached == null || cached.text != plain || cached.language != language) {
      if (plain.length <= syncLimit) {
        _cache[node.id] = _Highlighted(
          plain,
          language,
          tokenize(plain, language),
        );
      } else {
        _schedule(node.id, plain, language);
        return model;
      }
    }
    final spans = _cache[node.id]!.spans;
    if (spans.isEmpty) return model;

    final memo = _outputs[node.id];
    if (memo != null &&
        identical(memo.spans, spans) &&
        _sameInput(memo.input, model)) {
      return memo.output;
    }
    final copy = model.copy();
    final highlighted = text.copy();
    for (final (start, end, token) in spans) {
      if (end > start && end <= highlighted.length) {
        highlighted.addAttribution(
          CodeTokenAttribution(token),
          SpanRange(start, end - 1),
          autoMerge: false,
        );
      }
    }
    (copy as TextComponentViewModel).text = highlighted;
    _outputs[node.id] = (input: model, spans: spans, output: copy);
    return copy;
  }

  void _schedule(String nodeId, String text, String language) {
    if (_closed) return;
    _pending[nodeId]?.cancel();
    _pending[nodeId] = Timer(debounce, () {
      _pending.remove(nodeId);
      _cache[nodeId] = _Highlighted(text, language, tokenize(text, language));
      markDirty();
    });
  }

  static const CodeTokenizer _tokenizer = DefaultCodeTokenizer.instance;

  /// Token spans `(start, end, class)` of [code] in [language] (a
  /// normalised language id); empty for plain text and unknown languages. The
  /// class is the key of the token's color in `EditorTheme.syntax`.
  static List<(int, int, String)> tokenize(String code, String language) => [
    for (final token in _tokenizer.tokenize(code, language))
      (token.start, token.end, syntaxClassOf(token.token)),
  ];

  /// The `EditorTheme.syntax` key of [token] (`builtin` is `built_in`).
  static String syntaxClassOf(SyntaxToken token) =>
      token == SyntaxToken.builtin ? 'built_in' : token.name;
}

class _Highlighted {
  _Highlighted(this.text, this.language, this.spans);

  final String text;
  final String language;
  final List<(int, int, String)> spans;
}

/// Adds presentation-only [PillGapAttribution]s around chips and buttons
/// and after arrow links (Write 11 §7.2), so the pills and arrows the pill
/// layer paints have room. The document is never changed.
class PillSpacingStylePhase extends SingleColumnLayoutStylePhase {
  /// The last output per node and the input it was made from (an equal
  /// input gets the same output, so components aren't rebuilt).
  final _outputs =
      <
        String,
        ({
          SingleColumnLayoutComponentViewModel input,
          SingleColumnLayoutComponentViewModel output,
        })
      >{};

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    final seen = <String>{};
    final result = SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final model in viewModel.componentViewModels) _space(model, seen),
      ],
    );
    _outputs.removeWhere((id, _) => !seen.contains(id));
    return result;
  }

  static bool _isPill(Attribution a) =>
      a is ChipAttribution || (a is LinkStyleAttribution && a.isButton);

  SingleColumnLayoutComponentViewModel _space(
    SingleColumnLayoutComponentViewModel model,
    Set<String> seen,
  ) {
    if (model is! TextComponentViewModel) return model;
    final text = model.text;
    final spans = text.getAttributionSpansInRange(
      attributionFilter: (a) => _isPill(a) || a is LinkStyleAttribution,
      range: SpanRange(0, text.length),
    );
    if (spans.isEmpty) return model;
    seen.add(model.nodeId);
    final memo = _outputs[model.nodeId];
    if (memo != null && _sameInput(memo.input, model)) return memo.output;
    final plain = text.toPlainText(includePlaceholders: false);
    bool isSpace(int i) => i >= 0 && i < plain.length && plain[i] == ' ';
    // The gap of each character (the largest one asked for).
    final gaps = <int, PillGapAttribution>{};
    void gap(int i, PillGapAttribution g) {
      final existing = gaps[i];
      if (existing == null || existing.em < g.em) gaps[i] = g;
    }

    for (final span in spans) {
      if (_isPill(span.attribution)) {
        // The space before and after the pill, and its last character
        // (room for its right padding).
        for (final i in [span.start - 1, span.end + 1]) {
          if (isSpace(i)) gap(i, PillGapAttribution.space);
        }
        gap(span.end, PillGapAttribution.pill);
      } else {
        gap(span.end, PillGapAttribution.arrow);
      }
    }
    final spaced = text.copy();
    for (final e in gaps.entries) {
      spaced.addAttribution(e.value, SpanRange(e.key, e.key), autoMerge: false);
    }
    final copy = model.copy();
    (copy as TextComponentViewModel).text = spaced;
    _outputs[model.nodeId] = (input: model, output: copy);
    return copy;
  }
}

/// Lays out right-to-left paragraphs right-to-left (Write 04 §38): direction
/// from the first strong character; nothing is stored in the Delta. A block
/// without one takes [fallback], a table cell or grid item its table's or
/// grid's direction (Write 12 §3.10). Alignment is left to the other phases:
/// `start` (the stylesheet's) follows the direction.
class TextDirectionStylePhase extends SingleColumnLayoutStylePhase {
  TextDirectionStylePhase({this.fallback = TextDirection.ltr});

  /// Direction of the document language (for blocks without strong chars).
  TextDirection fallback;

  /// The cell slots of the document being styled, for the direction of
  /// cells without strong characters. They are rebuilt on every document
  /// change before the layout restyles (they listen first).
  CellSlots? cells;

  var _directions = const <String, TextDirection>{};

  /// The direction of [nodeId]'s block in the last styling pass, e.g. for
  /// the arrow keys.
  TextDirection directionOf(String nodeId) => _directions[nodeId] ?? fallback;

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    final directions = <String, TextDirection>{};
    final result = SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final model in viewModel.componentViewModels)
          if (model is TextComponentViewModel)
            _withDirection(model, directions)
          else
            model,
      ],
    );
    _directions = directions;
    return result;
  }

  SingleColumnLayoutComponentViewModel _withDirection(
    SingleColumnLayoutComponentViewModel model,
    Map<String, TextDirection> directions,
  ) {
    final textModel = model as TextComponentViewModel;
    final direction = detectTextDirection(
      textModel.text.toPlainText(),
      fallback: cells?[model.nodeId]?.direction ?? fallback,
    );
    directions[model.nodeId] = direction;
    if (direction == textModel.textDirection) return model;
    final copy = model.copy();
    (copy as TextComponentViewModel).textDirection = direction;
    return copy;
  }
}

/// Whether a memoized style phase output still fits [model]: view model
/// equality ignores the text style builder, which changes with the theme
/// (light/dark), so it is compared too.
bool _sameInput(
  SingleColumnLayoutComponentViewModel memo,
  TextComponentViewModel model,
) =>
    memo == model &&
    (memo as TextComponentViewModel).textStyleBuilder == model.textStyleBuilder;
