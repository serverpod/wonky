import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart'
    show kDoubleTapTimeout, kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_rich_text/wonky_rich_text.dart' show softBreak;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart' show SlidesOperation;
import 'package:wonky_ui/wonky_ui.dart';

import '../../commands/slides_command.dart' show SlidesKeyScopes;
import '../../config/slides_features.dart';
import '../../l10n/slides_l10n.dart';
import '../../theme/slides_tokens.dart';
import '../collab/presence_widgets.dart' show SlidePresenceDots;
import '../collab/slides_collab.dart';
import '../collab/slides_presence_controller.dart' show RemoteDeckCursor;
import '../editor_screen/deck_editor_controller.dart';
import '../layers/element_names.dart';
import '../navigator/navigator_controller.dart';
import '../spellcheck/editor_spelling.dart' show spellingErrorColor;
import '../spellcheck/slides_spelling.dart';
import '../spellcheck/spelling_actions.dart' show spellingMenuEntriesWith;
import '../text_editing/text_editing_host.dart'
    show TextLockTarget, textEditingOf;
import 'outline_body.dart';
import 'outline_controller.dart';

/// Stable widget keys of the outline view.
abstract final class OutlineKeys {
  static const view = ValueKey<String>('slides.view.outline');
  static const copyMarkdown = ValueKey<String>('slides.outline.copyMarkdown');

  static ValueKey<String> slide(String id) =>
      ValueKey<String>('slides.outline.slide.$id');
  static ValueKey<String> number(String id) =>
      ValueKey<String>('slides.outline.number.$id');
  static ValueKey<String> title(String id) =>
      ValueKey<String>('slides.outline.title.$id');
  static ValueKey<String> bullet(String id, int i) =>
      ValueKey<String>('slides.outline.bullet.$id.$i');
  static ValueKey<String> summary(String id) =>
      ValueKey<String>('slides.outline.summary.$id');
  static ValueKey<String> caretBar(String elementId) =>
      ValueKey<String>('slides.outline.caret.$elementId');
  static ValueKey<String> group(String id) =>
      ValueKey<String>('slides.outline.group.$id');
  static ValueKey<String> groupChevron(String id) =>
      ValueKey<String>('slides.outline.group.$id.chevron');
  static ValueKey<String> groupTitle(String id) =>
      ValueKey<String>('slides.outline.group.$id.title');
}

/// The outline view (Slides 04 §10): the deck as an editable outline —
/// group headers (color, title, slide count, collapse shared with the
/// navigator), then per slide its number, title (the title placeholder)
/// and bullets (the first body placeholder's paragraphs, indented by
/// level; inline bold/italic shown and kept), other objects summarized.
///
/// Keyboard (scope `slidesOutline`): Enter in a title adds a slide after
/// it, Enter in a bullet adds a bullet, ⌘Enter goes to the bullets,
/// Tab / Shift+Tab indent / outdent (promote a top-level bullet to a slide,
/// demote a slide into the previous one), Alt+Shift+↑/↓ move, Backspace at
/// the start joins lines, ↑/↓ move between lines, ⌘G groups the selected
/// slides. Typing is written after a pause (one undo step per burst).
/// The focused slide is the current slide (navigator selection);
/// collaborators editing a title or body show a caret bar in their color.
class OutlineView extends StatefulWidget {
  const OutlineView({super.key, required this.services, required this.editor});

  final ShellServices services;
  final DeckEditorController editor;

  @override
  State<OutlineView> createState() => _OutlineViewState();
}

class _OutlineViewState extends State<OutlineView> {
  final _scroll = ScrollController();
  late final OutlineController _o = outlineOf(widget.editor);
  late final NavigatorController _nav = navigatorOf(widget.editor);
  final Map<String, GlobalKey> _blockKeys = {};
  List<OutlineLine> _lines = const [];
  String? _shownCurrent;
  String? _renamingGroup;
  String? _lastGroupTap;
  DateTime _lastGroupTapAt = DateTime.fromMillisecondsSinceEpoch(0);
  final _groupRename = TextEditingController();
  final _groupFocus = FocusNode(debugLabel: 'slides.outline.groupRename');

  DeckEditorController get ed => widget.editor;

  @override
  void initState() {
    super.initState();
    ed.addListener(_onEditor);
    _groupFocus.addListener(() {
      if (!_groupFocus.hasFocus && _renamingGroup != null) _commitGroup();
    });
    final cur = ed.currentSlideId;
    if (cur != null && _o.focused == null && ed.canEdit) {
      _o.focusLine(OutlineLine.title(cur));
    }
    _shownCurrent = cur;
  }

  @override
  void dispose() {
    ed.removeListener(_onEditor);
    _o.reset();
    _scroll.dispose();
    _groupRename.dispose();
    _groupFocus.dispose();
    super.dispose();
  }

  /// Another surface changed the current slide: show it.
  void _onEditor() {
    final cur = ed.currentSlideId;
    if (cur == _shownCurrent) return;
    _shownCurrent = cur;
    if (cur == null || _o.focused?.slideId == cur) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _blockKeys[cur]?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.3,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }

  /// ↑/↓ from [line] past its first/last visual line.
  void _moveFocus(OutlineLine line, int delta) {
    final i = _lines.indexOf(line);
    if (i < 0) return;
    final j = i + delta;
    if (j < 0 || j >= _lines.length) return;
    _o.focusLine(_lines[j], offset: delta < 0 ? null : 0);
  }

  void _run(String id, [Map<String, Object?> args = const {}]) {
    unawaited(
      widget.services.dispatcher
          .invoke(id, args: args, source: InvocationSource.ui, context: context)
          .catchError((Object _) => const CommandResult.failed('error')),
    );
  }

  void _startGroupRename(SlideGroupRec g) {
    if (!ed.canEdit) return;
    setState(() {
      _renamingGroup = g.id;
      _groupRename.text = g.title;
      _groupRename.selection = TextSelection(
        baseOffset: 0,
        extentOffset: g.title.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _groupFocus.requestFocus();
    });
  }

  void _commitGroup() {
    final id = _renamingGroup;
    if (id == null) return;
    setState(() => _renamingGroup = null);
    final t = _groupRename.text.trim();
    if (t.isNotEmpty && t != ed.model.group(id)?.title) {
      _run('slides.group.rename', {'groupId': id, 'title': t});
    }
  }

  @override
  Widget build(BuildContext context) {
    final collab = SlidesCollab.of(ed);
    return KeymapScope(
      scope: SlidesKeyScopes.outline,
      keymap: widget.services.keymap,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          ed,
          _o,
          _nav,
          widget.services.registry,
          ?collab?.presence,
        ]),
        builder: (context, _) => _build(context, collab),
      ),
    );
  }

  Widget _build(BuildContext context, SlidesCollab? collab) {
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    final order = ed.order;
    final m = ed.model;
    final rows = <Widget>[];
    final lines = <OutlineLine>[];
    final cursors = collab?.presence.cursors ?? const <RemoteDeckCursor>[];

    void addSlide(SlideOrderEntry e) {
      final parts = OutlineSlideParts.of(m, e.id);
      final key = _blockKeys[e.id] ??= GlobalKey();
      lines.add(OutlineLine.title(e.id));
      final body = parts.bodyLines;
      final focusedHere =
          _o.focused?.slideId == e.id && (_o.focused?.index ?? -1) >= 0;
      if (parts.body != null && (!body.isBlank || focusedHere)) {
        for (var i = 0; i < body.length; i++) {
          lines.add(OutlineLine(e.id, i));
        }
      }
      rows.add(
        KeyedSubtree(
          key: key,
          child: _OutlineSlideBlock(
            key: OutlineKeys.slide(e.id),
            services: widget.services,
            editor: ed,
            outline: _o,
            entry: e,
            parts: parts,
            current: ed.currentSlideId == e.id,
            selected: ed.selectedSlideIds.contains(e.id),
            cursors: cursors,
            onMove: _moveFocus,
          ),
        ),
      );
    }

    for (final item in order.topLevel) {
      if (!item.isGroup) {
        final e = order.entry(item.id);
        if (e != null) addSlide(e);
        continue;
      }
      final g = m.group(item.id);
      if (g == null) continue;
      final range = order.range(g.id);
      final collapsed = _nav.isCollapsed(g.id);
      rows.add(_groupHeader(context, l, g, range?.length ?? 0, collapsed));
      if (collapsed || range == null) continue;
      for (var i = range.start; i < range.end; i++) {
        addSlide(order.entries[i]);
      }
    }
    // Orphan slides (not top-level items until repaired).
    for (final e in order.entries) {
      if (e.orphan) addSlide(e);
    }
    _lines = lines;

    return ColoredBox(
      key: OutlineKeys.view,
      color: theme.colorScheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context, l),
          Container(height: 1, color: theme.colorScheme.border),
          Expanded(
            child: WonkyScrollArea(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rows.isEmpty
                          ? [
                              Text(
                                l.navigatorEmpty,
                                style: theme.textTheme.muted,
                              ),
                            ]
                          : rows,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, SlidesLocalizations l) {
    final theme = ShadTheme.of(context);
    final copy = widget.services.dispatcher.stateOf(
      'slides.outline.copyMarkdown',
    );
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ed.canEdit ? l.outlineHint : l.outlineReadOnlyHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted,
              ),
            ),
            ShadTooltip(
              builder: (_) => Text(l.cmdOutlineCopyMarkdown),
              child: ShadIconButton.ghost(
                key: OutlineKeys.copyMarkdown,
                width: 28,
                height: 28,
                iconSize: 16,
                semanticLabel: l.cmdOutlineCopyMarkdown,
                enabled: copy.enabled,
                icon: const Icon(LucideIcons.clipboardCopy),
                onPressed: () => _run('slides.outline.copyMarkdown'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(
    BuildContext context,
    SlidesLocalizations l,
    SlideGroupRec g,
    int count,
    bool collapsed,
  ) {
    final theme = ShadTheme.of(context);
    final tokens = SlidesTokens.of(context);
    final renaming = _renamingGroup == g.id;
    return Padding(
      key: OutlineKeys.group(g.id),
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          Semantics(
            button: true,
            expanded: !collapsed,
            label: collapsed ? l.cmdGroupExpand : l.cmdGroupCollapse,
            child: GestureDetector(
              key: OutlineKeys.groupChevron(g.id),
              behavior: HitTestBehavior.opaque,
              onTap: () => _run('slides.group.toggleCollapsed', {
                'groupIds': [g.id],
              }),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  collapsed
                      ? LucideIcons.chevronRight
                      : LucideIcons.chevronDown,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 4, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  tokens.groupColor(g.color) ??
                  theme.colorScheme.mutedForeground,
            ),
          ),
          Flexible(
            child: renaming
                ? SizedBox(
                    width: 260,
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          setState(() => _renamingGroup = null);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: ShadInput(
                        key: OutlineKeys.groupTitle(g.id),
                        controller: _groupRename,
                        focusNode: _groupFocus,
                        onSubmitted: (_) => _commitGroup(),
                      ),
                    ),
                  )
                : GestureDetector(
                    key: OutlineKeys.groupTitle(g.id),
                    onTap: () {
                      final now = clock.now();
                      final again =
                          _lastGroupTap == g.id &&
                          now.difference(_lastGroupTapAt) < kDoubleTapTimeout;
                      _lastGroupTap = g.id;
                      _lastGroupTapAt = now;
                      if (again) _startGroupRename(g);
                    },
                    child: Text(
                      (g.title.isEmpty ? l.groupUntitled : g.title)
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        decoration: g.skipped
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: theme.textTheme.muted),
          const Spacer(),
          SlidePresenceDots(editor: ed, groupId: g.id),
        ],
      ),
    );
  }
}

/// A text controller drawing outline runs (bold, italic, underline,
/// strike) while its text matches them.
class _RunsController extends TextEditingController {
  List<OutlineRun> _runs = const [];

  /// The misspelled words of a text (SL-44; `caret`: the word being typed
  /// is skipped), or null without spell checking.
  List<SpellRange> Function(String text, int? caret)? misspellings;

  /// Whether the line has the keyboard focus (the word at the caret is
  /// being typed).
  bool Function()? focused;

  /// The misspelled words of the current text.
  List<SpellRange> get misspelled {
    final f = misspellings;
    if (f == null) return const [];
    final sel = selection;
    final caret = (focused?.call() ?? false) && sel.isValid && sel.isCollapsed
        ? sel.extentOffset
        : null;
    return f(text, caret);
  }

  void setRuns(List<OutlineRun> runs) {
    _runs = runs;
    notifyListeners();
  }

  /// Sets text and runs without moving the caret more than needed.
  void sync(OutlineParagraph p) {
    final t = p.text;
    if (t == text) {
      setRuns(p.runs);
      return;
    }
    _runs = p.runs;
    final sel = selection;
    value = TextEditingValue(
      text: t,
      selection: sel.isValid
          ? TextSelection(
              baseOffset: sel.baseOffset.clamp(0, t.length),
              extentOffset: sel.extentOffset.clamp(0, t.length),
            )
          : TextSelection.collapsed(offset: t.length),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final joined = _runs.map((r) => r.text).join();
    final composing =
        withComposing &&
        value.isComposingRangeValid &&
        !value.composing.isCollapsed;
    // Spelling squiggles (SL-44), not while the IME composes.
    final errors = composing ? const <SpellRange>[] : misspelled;
    if (joined != text || _runs.isEmpty) {
      if (errors.isEmpty) {
        return super.buildTextSpan(
          context: context,
          style: style,
          withComposing: withComposing,
        );
      }
      return TextSpan(
        style: style,
        children: _squiggled([(text, null)], errors),
      );
    }
    return TextSpan(
      style: style,
      children: _squiggled([
        for (final r in _runs)
          (
            r.text,
            TextStyle(
              fontWeight: r.bold ? FontWeight.w700 : null,
              fontStyle: r.italic ? FontStyle.italic : null,
              decoration: TextDecoration.combine([
                if (r.underline) TextDecoration.underline,
                if (r.strike) TextDecoration.lineThrough,
              ]),
            ),
          ),
      ], errors),
    );
  }

  /// [pieces] as spans, split at the misspelled [errors] (wavy red
  /// underline).
  static List<InlineSpan> _squiggled(
    List<(String, TextStyle?)> pieces,
    List<SpellRange> errors,
  ) {
    const squiggle = TextStyle(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: spellingErrorColor,
    );
    final out = <InlineSpan>[];
    var at = 0;
    for (final (text, style) in pieces) {
      final end = at + text.length;
      var i = at;
      while (i < end) {
        SpellRange? inside;
        var next = end;
        for (final e in errors) {
          if (e.start <= i && e.end > i) {
            inside = e;
            next = e.end < end ? e.end : end;
            break;
          }
          if (e.start > i && e.start < next) next = e.start;
        }
        out.add(
          TextSpan(
            text: text.substring(i - at, next - at),
            style: inside == null
                ? style
                : (style ?? const TextStyle()).merge(squiggle),
          ),
        );
        i = next;
      }
      at = end;
    }
    return out;
  }
}

/// One editable line (title or bullet).
class _Line {
  _Line() {
    focus = FocusNode(debugLabel: 'slides.outline.line');
  }

  final controller = _RunsController();
  late final FocusNode focus;
  final input = GlobalKey<ShadInputState>();
  String lastText = '';

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

/// One slide of the outline: number, title, bullets, summary.
class _OutlineSlideBlock extends StatefulWidget {
  const _OutlineSlideBlock({
    super.key,
    required this.services,
    required this.editor,
    required this.outline,
    required this.entry,
    required this.parts,
    required this.current,
    required this.selected,
    required this.cursors,
    required this.onMove,
  });

  final ShellServices services;
  final DeckEditorController editor;
  final OutlineController outline;
  final SlideOrderEntry entry;
  final OutlineSlideParts parts;
  final bool current;
  final bool selected;
  final List<RemoteDeckCursor> cursors;
  final void Function(OutlineLine line, int delta) onMove;

  @override
  State<_OutlineSlideBlock> createState() => _OutlineSlideBlockState();
}

class _OutlineSlideBlockState extends State<_OutlineSlideBlock>
    implements OutlineSlideHandle {
  /// Typing is written after this pause.
  static const commitDelay = Duration(milliseconds: 500);

  final _title = _Line();
  final List<_Line> _bullets = [];
  OutlineParagraph _titlePara = const OutlineParagraph([]);
  OutlineBody _body = OutlineBody(const []);
  String? _titleJson;
  String? _bodyJson;
  bool _titleDirty = false;
  bool _bodyDirty = false;
  bool _syncing = false;
  bool _showEmptyBody = false;
  Timer? _timer;
  (int, int?)? _wantFocus;

  String get slideId => widget.entry.id;
  DeckEditorController get ed => widget.editor;

  @override
  void initState() {
    super.initState();
    _spelling?.addListener(_onSpelling);
    widget.outline.register(slideId, this);
    _wire(_title, -1);
    _sync(force: true);
    final f = widget.outline.takeFocusFor(slideId);
    if (f != null) focusLine(f.$1, f.$2);
  }

  @override
  void didUpdateWidget(_OutlineSlideBlock old) {
    super.didUpdateWidget(old);
    if (old.entry.id != slideId) {
      widget.outline.unregister(old.entry.id, this);
      widget.outline.register(slideId, this);
    }
    _sync();
  }

  @override
  void dispose() {
    SlidesSpelling.maybeOf(ed)?.removeListener(_onSpelling);
    _timer?.cancel();
    _commitNow();
    // The claim is released after the frame (the tree is locked now).
    final claim = _claim;
    final locks = textEditingOf(ed).locks;
    final activity = _activity;
    _claim = null;
    scheduleMicrotask(() {
      if (claim != null) locks.releaseTarget(claim);
      activity.dispose();
    });
    widget.outline.unregister(slideId, this);
    _title.dispose();
    for (final b in _bullets) {
      b.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------- sync

  void _sync({bool force = false}) {
    final p = widget.parts;
    _syncing = true;
    try {
      final tj = p.title?.text;
      if (force || (!_titleDirty && tj != _titleJson)) {
        _titleJson = tj;
        _titlePara = p.titleBody[0];
        _title.controller.sync(_titlePara);
        _title.lastText = _titlePara.text;
      }
      final bj = p.body?.text;
      if (force || (!_bodyDirty && bj != _bodyJson)) {
        _bodyJson = bj;
        _body = p.bodyLines;
        while (_bullets.length < _body.length) {
          final line = _Line();
          _wire(line, _bullets.length);
          _bullets.add(line);
        }
        while (_bullets.length > _body.length) {
          _bullets.removeLast().dispose();
        }
        for (var i = 0; i < _body.length; i++) {
          _bullets[i].controller.sync(_body[i]);
          _bullets[i].lastText = _body[i].text;
        }
      }
    } finally {
      _syncing = false;
    }
  }

  void _wire(_Line line, int index) {
    line.controller.addListener(() => _onChanged(line));
    line.focus.addListener(() => _onFocus(line));
    // Spelling squiggles (SL-44, 03 §14).
    line.controller
      ..misspellings = _misspellings
      ..focused = () => line.focus.hasFocus;
  }

  List<SpellRange> _misspellings(String text, int? caret) {
    final sp = _spelling;
    if (sp == null || !sp.underline) return const [];
    return sp.check(text, caret: caret);
  }

  SlidesSpelling? get _spelling => SlidesFeatures.isOn(SlidesFeature.spelling)
      ? SlidesSpelling.of(ed)
      : null;

  void _onSpelling() {
    if (mounted) setState(() {});
  }

  /// A right-click on a misspelled word of [line]: the spelling menu; a
  /// suggestion replaces the word in the line (written like typing).
  void _spellingMenu(_Line line, PointerDownEvent e) {
    final editable = line.input.currentState?.editableTextKey.currentState;
    if (editable == null || _spelling == null) return;
    final pos = editable.renderEditable.getPositionForPoint(e.position);
    final c = line.controller;
    SpellRange? hit;
    // Every misspelled word counts here, also the one at the caret.
    for (final r
        in c.misspellings?.call(c.text, null) ?? const <SpellRange>[]) {
      if (r.covers(pos.offset)) hit = r;
    }
    final r = hit;
    if (r == null) return;
    final entries = spellingMenuEntriesWith(
      ed,
      r.word,
      onReplace: (replacement) {
        final t = c.text;
        if (r.end > t.length || t.substring(r.start, r.end) != r.word) return;
        c.value = TextEditingValue(
          text: t.replaceRange(r.start, r.end, replacement),
          selection: TextSelection.collapsed(
            offset: r.start + replacement.length,
          ),
        );
        line.focus.requestFocus();
      },
    );
    if (entries.isEmpty) return;
    WonkyPopupMenuHost.maybeOf(context)?.show(e.position, () => entries);
  }

  int _indexOf(_Line line) =>
      identical(line, _title) ? -1 : _bullets.indexOf(line);

  void _onChanged(_Line line) {
    final i = _indexOf(line);
    final c = line.controller;
    if (line.focus.hasFocus) {
      widget.outline.reportFocus(
        OutlineLine(slideId, i),
        caret: c.selection.isValid ? c.selection.extentOffset : 0,
        selection: c.selection.isValid && !c.selection.isCollapsed,
      );
    }
    if (_syncing || c.text == line.lastText) return;
    line.lastText = c.text;
    if (i < 0) {
      _titlePara = _titlePara.withText(c.text);
      c.setRuns(_titlePara.runs);
      _titleDirty = true;
    } else if (i < _body.length) {
      _body = _body.withText(i, c.text);
      c.setRuns(_body[i].runs);
      _bodyDirty = true;
    }
    _timer?.cancel();
    _timer = Timer(commitDelay, _commitNow);
    _activity.value++;
    _hint(i);
  }

  // ------------------------------------- soft locks and hints (SL-37)

  /// The body this block claims while one of its lines has focus (09
  /// §2.1): the title element or the body element.
  TextLockTarget? _claim;

  /// Input in any line of this block (keeps the claim from idling).
  final _activity = ValueNotifier<int>(0);

  /// The element whose body line [i] edits (null: no element yet).
  String? _elementOf(int i) =>
      i < 0 ? widget.parts.title?.id : widget.parts.body?.id;

  /// Claims the body of line [line] (outline typing has no soft-lock
  /// question: a body someone else edits is entered as with *Edit anyway*,
  /// and outline claims never start a race prompt — they are forced).
  void _claimFor(_Line line) {
    if (!ed.canEdit) return;
    final id = _elementOf(_indexOf(line));
    final target = id == null ? null : TextLockTarget.element(id);
    if (target == _claim) return;
    _releaseClaim();
    if (target == null) return;
    final collab = SlidesCollab.of(ed);
    if (collab == null) return;
    _claim = target;
    collab.locks.editAnyway(target);
    collab.locks.claimTarget(
      target,
      activity: _activity,
      stop: () => line.focus.unfocus(),
    );
  }

  void _releaseClaim() {
    final c = _claim;
    _claim = null;
    if (c != null) textEditingOf(ed).locks.releaseTarget(c);
  }

  /// Sends the typed body of line [i] as a live text hint (09 §2.4).
  void _hint(int i) {
    final hints = SlidesCollab.of(ed)?.hints;
    final id = _elementOf(i);
    if (hints == null || id == null) return;
    final json = i < 0
        ? widget.parts.titleBody.withText(0, _titlePara.text).toJson()
        : _body.toJson();
    hints.typing(id, slideId, json);
  }

  void _onFocus(_Line line) {
    final i = _indexOf(line);
    final l = OutlineLine(slideId, i);
    if (line.focus.hasFocus) {
      final c = line.controller;
      widget.outline.reportFocus(
        l,
        caret: c.selection.isValid ? c.selection.extentOffset : c.text.length,
      );
      _claimFor(line);
      if (ed.currentSlideId != slideId) {
        ed.setCurrentSlide(slideId);
      } else if (!ed.selectedSlideIds.contains(slideId)) {
        ed.selectSlides([slideId]);
      }
    } else {
      widget.outline.clearFocus(l);
      _commitNow();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Moving between this block's lines keeps the claim.
        if (!mounted) return;
        if (!_title.focus.hasFocus && !_bullets.any((b) => b.focus.hasFocus)) {
          _releaseClaim();
        }
      });
      if (i == 0 && _body.isBlank && _showEmptyBody) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!_bullets.any((b) => b.focus.hasFocus)) {
            setState(() => _showEmptyBody = false);
          }
        });
      }
    }
  }

  // ------------------------------------------------------------- writes

  /// Writes pending typing through the outline commands (one coalesced
  /// step per burst).
  void _commitNow() {
    _timer?.cancel();
    _timer = null;
    if (!_titleDirty && !_bodyDirty) return;
    final d = widget.services.dispatcher;
    if (_titleDirty) {
      _titleDirty = false;
      unawaited(
        d
            .invoke(
              'slides.outline.setTitle',
              args: {
                'slideId': slideId,
                'text': _titlePara.text,
                'typing': true,
              },
              source: InvocationSource.ui,
            )
            .catchError((Object _) => const CommandResult.failed('error')),
      );
    }
    if (_bodyDirty) {
      _bodyDirty = false;
      unawaited(
        d
            .invoke(
              'slides.outline.setBody',
              args: {
                'slideId': slideId,
                'delta': _body.toJson(),
                'typing': true,
              },
              source: InvocationSource.ui,
            )
            .catchError((Object _) => const CommandResult.failed('error')),
      );
    }
  }

  @override
  List<SlidesOperation> takePending() {
    _timer?.cancel();
    _timer = null;
    if (!_titleDirty && !_bodyDirty) return const [];
    final parts = OutlineSlideParts.of(ed.model, slideId);
    final ops = <SlidesOperation>[
      if (_titleDirty) ...parts.setTitle(_titlePara.text),
      if (_bodyDirty) ?parts.setBody(_body),
    ];
    _titleDirty = false;
    _bodyDirty = false;
    return ops;
  }

  @override
  Future<void> commit() async => _commitNow();

  // -------------------------------------------------------------- focus

  @override
  void focusLine(int index, int? offset) {
    _wantFocus = (index, offset);
    if (index >= 0 && _body.isBlank) _showEmptyBody = true;
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFocus());
  }

  void _applyFocus() {
    final want = _wantFocus;
    if (want == null || !mounted) return;
    _wantFocus = null;
    final (index, offset) = want;
    final line = index < 0
        ? _title
        : (index < _bullets.length ? _bullets[index] : null);
    if (line == null) return;
    final c = line.controller;
    final o = (offset ?? c.text.length).clamp(0, c.text.length);
    line.focus.requestFocus();
    c.selection = TextSelection.collapsed(offset: o);
    final ctx = line.input.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      Scrollable.ensureVisible(
        ctx,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  // --------------------------------------------------------------- keys

  KeyEventResult _onKey(_Line line, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance;
    final k = event.logicalKey;
    final mac = widget.services.keymap.platform.isMac;
    final mod = mac ? keys.isMetaPressed : keys.isControlPressed;
    // Undo/redo: the deck's (typing is written first, `beforeUndo`).
    if (mod && !keys.isAltPressed) {
      final z = k == LogicalKeyboardKey.keyZ;
      final y = k == LogicalKeyboardKey.keyY && !mac;
      if (z || y) {
        _commitNow();
        final redo = y || keys.isShiftPressed;
        unawaited(
          widget.services.dispatcher
              .invoke(
                redo ? 'shell.edit.redo' : 'shell.edit.undo',
                source: InvocationSource.shortcut,
              )
              .catchError((Object _) => const CommandResult.failed('error')),
        );
        return KeyEventResult.handled;
      }
    }
    final up = k == LogicalKeyboardKey.arrowUp;
    final down = k == LogicalKeyboardKey.arrowDown;
    if ((up || down) && !keys.isAltPressed && !keys.isShiftPressed && !mod) {
      final c = line.controller;
      final state = line.input.currentState?.editableTextKey.currentState;
      if (!c.selection.isValid || state == null) return KeyEventResult.ignored;
      final r = state.renderEditable.getLineAtOffset(
        TextPosition(offset: c.selection.extentOffset),
      );
      final atEdge = up ? r.start <= 0 : r.end >= c.text.length;
      if (!atEdge) return KeyEventResult.ignored;
      widget.onMove(OutlineLine(slideId, _indexOf(line)), up ? -1 : 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = slidesL10n(context);
    final p = widget.parts;
    final e = widget.entry;
    final canEdit = ed.canEdit;
    final showBody =
        p.body != null &&
        (!_body.isBlank ||
            _showEmptyBody ||
            _bullets.any((b) => b.focus.hasFocus));
    final titleStyle = theme.textTheme.p.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: e.skipped ? cs.mutedForeground : cs.foreground,
    );
    final bulletStyle = theme.textTheme.p.copyWith(
      height: 1.4,
      color: e.skipped ? cs.mutedForeground : cs.foreground,
    );
    final number = Semantics(
      button: true,
      selected: widget.selected,
      label: l.outlineSlideNumber(e.index + 1),
      child: GestureDetector(
        key: OutlineKeys.number(e.id),
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectSlide(),
        child: Container(
          width: 32,
          height: 24,
          margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.current
                ? cs.primary
                : (widget.selected ? cs.accent : null),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (e.skipped)
                Icon(LucideIcons.eyeOff, size: 10, color: cs.mutedForeground),
              Text(
                '${e.index + 1}',
                style: theme.textTheme.small.copyWith(
                  color: widget.current
                      ? cs.primaryForeground
                      : cs.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final titleField = p.titleEditable
        ? _field(
            context,
            _title,
            key: OutlineKeys.title(e.id),
            style: titleStyle,
            readOnly: !canEdit,
            hint: l.outlineNoTitle,
            label: l.outlineTitleLabel(e.index + 1),
          )
        : Text(
            l.outlineNoTitle,
            key: OutlineKeys.title(e.id),
            style: titleStyle.copyWith(color: cs.mutedForeground),
          );

    final summary = _summary(l, p);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          number,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _caretBar(p.title?.id),
                    Expanded(child: titleField),
                    if (summary != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          summary,
                          key: OutlineKeys.summary(e.id),
                          style: theme.textTheme.muted,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: SlidePresenceDots(editor: ed, slideId: e.id),
                    ),
                  ],
                ),
                if (showBody)
                  for (var i = 0; i < _bullets.length && i < _body.length; i++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i == 0)
                          _caretBar(p.body?.id)
                        else
                          const SizedBox(width: 3),
                        SizedBox(width: 12.0 + 20.0 * _body[i].level),
                        Padding(
                          padding: const EdgeInsets.only(top: 1, right: 6),
                          child: Text(
                            _body[i].level.isEven ? '•' : '◦',
                            style: bulletStyle.copyWith(
                              color: cs.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _field(
                            context,
                            _bullets[i],
                            key: OutlineKeys.bullet(e.id, i),
                            style: bulletStyle,
                            readOnly: !canEdit,
                            label: l.outlineBulletLabel(
                              e.index + 1,
                              i + 1,
                              _body[i].level + 1,
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectSlide() {
    final keys = HardwareKeyboard.instance;
    final mac = widget.services.keymap.platform.isMac;
    final mod = mac ? keys.isMetaPressed : keys.isControlPressed;
    final order = ed.order;
    if (keys.isShiftPressed && ed.currentSlideId != null) {
      final a = order.indexOf(ed.currentSlideId!);
      final b = order.indexOf(slideId);
      final lo = a < b ? a : b, hi = a < b ? b : a;
      ed.selectSlides([for (var i = lo; i <= hi; i++) order.entries[i].id]);
      return;
    }
    if (mod) {
      final sel = {...ed.selectedSlideIds};
      if (!sel.remove(slideId)) sel.add(slideId);
      ed.selectSlides(sel);
      return;
    }
    ed.setCurrentSlide(slideId);
    if (ed.canEdit && widget.parts.titleEditable) focusLine(-1, null);
  }

  /// A 3 px bar in the color of a collaborator editing [elementId].
  Widget _caretBar(String? elementId) {
    final theme = ShadTheme.of(context);
    RemoteDeckCursor? who;
    if (elementId != null) {
      for (final c in widget.cursors) {
        if (!c.isAway && c.cursor.editing?.elementId == elementId) {
          who = c;
          break;
        }
      }
    }
    if (who == null) return const SizedBox(width: 3);
    final color = theme.colorScheme.presence(who.colorIndex);
    return ShadTooltip(
      builder: (_) =>
          Text(slidesL10n(context).outlineEditing(who!.displayName)),
      child: Semantics(
        label: slidesL10n(context).outlineEditing(who.displayName),
        child: Container(
          key: OutlineKeys.caretBar(elementId!),
          width: 3,
          height: 22,
          margin: const EdgeInsets.only(right: 4, top: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }

  /// "+ 2 images, chart" for the other objects of the slide.
  String? _summary(SlidesLocalizations l, OutlineSlideParts p) {
    if (p.others.isEmpty) return null;
    final parts = <String>[
      for (final MapEntry(:key, :value) in p.others.entries)
        value == 1
            ? ElementNames.kind(l, key).toLowerCase()
            : '$value × ${ElementNames.kind(l, key).toLowerCase()}',
    ];
    return l.outlineOthers(parts.join(', '));
  }

  Widget _field(
    BuildContext context,
    _Line line, {
    required Key key,
    required TextStyle style,
    required bool readOnly,
    required String label,
    String? hint,
  }) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return KeyedSubtree(
      key: key,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) => _onKey(line, event),
        child: Listener(
          onPointerDown: (e) {
            if (e.buttons & kSecondaryMouseButton != 0) _spellingMenu(line, e);
          },
          child: Semantics(
            label: label,
            child: ShadInput(
              key: line.input,
              controller: line.controller,
              focusNode: line.focus,
              readOnly: readOnly,
              style: style,
              placeholder: hint == null ? null : Text(hint),
              placeholderStyle: style.copyWith(color: cs.mutedForeground),
              decoration: ShadDecoration.none,
              padding: EdgeInsets.zero,
              inputPadding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 22),
              cursorColor: cs.foreground,
              selectionColor: cs.selection,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.none,
              inputFormatters: [_SoftBreaks()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Typed line breaks become soft breaks (one outline line = one paragraph).
class _SoftBreaks extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.text.contains('\n')
      ? newValue.copyWith(text: newValue.text.replaceAll('\n', softBreak))
      : newValue;
}
