import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../codec/inline_codec.dart';
import '../editor/markdown_editing_controller.dart';
import '../editor/rich_editor_reactions.dart';
import '../spelling/document_spelling.dart';
import '../spelling/spelling_menu.dart';
import 'rich_editor_style.dart';

/// What the link dialog decided: a URL, or none to remove the link.
class RichLinkResult {
  const RichLinkResult(this.url);

  /// The link (null removes it).
  final String? url;
}

/// Asks for a link; [current] is the link being edited (null = a new
/// one). Returns null when cancelled.
typedef RichLinkRequest =
    Future<RichLinkResult?> Function(BuildContext context, String? current);

/// The labels of the editor (tooltips and screen readers); English by
/// default, the shell passes its translations.
class RichEditorLabels {
  const RichEditorLabels({
    this.bold = 'Bold',
    this.italic = 'Italic',
    this.strikethrough = 'Strikethrough',
    this.code = 'Code',
    this.link = 'Link',
    this.bulletedList = 'Bulleted list',
    this.numberedList = 'Numbered list',
    this.taskList = 'Checklist',
    this.quote = 'Quote',
    this.toolbar = 'Formatting',
    this.length = _length,
    this.cut = 'Cut',
    this.copy = 'Copy',
    this.paste = 'Paste',
    this.spelling = const SpellingMenuLabels(),
  });

  final String bold;
  final String italic;
  final String strikethrough;
  final String code;
  final String link;
  final String bulletedList;
  final String numberedList;
  final String taskList;
  final String quote;

  /// The toolbar's group label.
  final String toolbar;

  /// The character counter (`120 / 500`).
  final String Function(int count, int max) length;

  /// The context menu (with a spell checker).
  final String cut;
  final String copy;
  final String paste;

  /// The spelling section of the context menu.
  final SpellingMenuLabels spelling;

  static String _length(int count, int max) => '$count / $max';
}

/// A lightweight WYSIWYG Markdown field (specs/16 §7.3): super_editor on
/// the Markdown of a [MarkdownEditingController], styled like the suite's
/// text inputs (shad input border, radius, focus ring, padding) and its
/// Markdown rendering, with a formatting toolbar.
///
/// - **Autoformat while typing** like Write (04 §7): `# ` headings, `- ` /
///   `* ` bullets, `1. ` numbers, `[] ` tasks, `> ` quotes, `---` rules,
///   `**bold**`, `*italic*`, `~~strike~~`, `` `code` `` and `[text](url)`.
///   There are no code blocks: a fence (```` ``` ````) stays text, and
///   fenced code set or pasted as Markdown is a literal block.
/// - **Shortcuts** (Write 04 §10, §13): `Mod+B` / `I` / `E` (code),
///   `Mod+Shift+X` (strikethrough), `Mod+K` (link), `Mod+Shift+7` / `8` /
///   `9` (numbered, bulleted, checklist), `Mod+Shift+.` (quote), `Tab` /
///   `Shift+Tab` (list levels; elsewhere they move the focus), `Mod+Z` /
///   `Mod+Shift+Z` (the field's own undo), `Mod+C` / `Mod+X` (the selection
///   as Markdown, [MarkdownEditingController.selectedMarkdown]), `Mod+V`
///   (Markdown is converted; `Mod+Shift+V` pastes plain text), `Mod+Enter`
///   ([onSubmit]).
/// - **Spelling** with a [spellChecker]: misspelled words get red squiggles
///   ([DocumentSpelling]; not in literal blocks or inline code), and a right-click opens a context
///   menu with the suggestions, *Ignore* and *Add to dictionary* on a
///   misspelled word, then *Cut*, *Copy*, *Paste* (the browser's own menu
///   is off over the field). Keys: `menu.markdown.spell.suggestion.<i>`,
///   `.ignore`, `.add`, `menu.markdown.cut`, `.copy`, `.paste`.
/// - The field grows from [minHeight] to [maxHeight] and then scrolls.
///
/// Stable keys from [fieldKey]: the field `<fieldKey>`, the toolbar
/// buttons `<fieldKey>.bold`, `.italic`, `.strike`, `.code`, `.link`,
/// `.bullets`, `.numbers`, `.tasks`, `.quote`, the counter
/// `<fieldKey>.count`.
class WonkyRichEditor extends StatefulWidget {
  const WonkyRichEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.fieldKey = 'markdown.composer',
    this.hint,
    this.minHeight = 76,
    this.maxHeight = 260,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLength,
    this.toolbar = true,
    this.onSubmit,
    this.requestLink,
    this.labels = const RichEditorLabels(),
    this.customStylePhases = const [],
    this.spellChecker,
  });

  final MarkdownEditingController controller;
  final FocusNode? focusNode;

  /// The prefix of the stable keys.
  final String fieldKey;

  /// The placeholder of the empty field.
  final String? hint;

  /// The height of the field (the toolbar and counter come on top).
  final double minHeight;
  final double maxHeight;

  final bool autofocus;

  /// Disabled: greyed out, no editing, no toolbar.
  final bool enabled;

  /// Read-only: the text can be selected and copied, not changed.
  final bool readOnly;

  /// The maximum length of the Markdown (a counter shows from 80%).
  final int? maxLength;

  /// Whether the formatting toolbar shows.
  final bool toolbar;

  /// `Mod+Enter` (null: no shortcut).
  final VoidCallback? onSubmit;

  /// Asks for a link (defaults to a small dialog).
  final RichLinkRequest? requestLink;

  final RichEditorLabels labels;

  /// Extra style phases of the document.
  final List<SingleColumnLayoutStylePhase> customStylePhases;

  /// Checks the spelling (null: no spelling squiggles or menu).
  final RichEditorSpellChecker? spellChecker;

  @override
  State<WonkyRichEditor> createState() => WonkyRichEditorState();
}

class WonkyRichEditorState extends State<WonkyRichEditor> {
  FocusNode? _ownFocus;
  final _scroll = ScrollController();
  final _layoutKey = GlobalKey();
  final _menu = GlobalKey<WonkyPopupMenuHostState>();
  DocumentSpelling? _spelling;
  bool _secondaryDown = false;
  bool _browserMenuOff = false;

  /// The spelling squiggles (with a [WonkyRichEditor.spellChecker]).
  DocumentSpelling? get spelling => _spelling;

  /// The layout of the document (positions of the text on screen).
  DocumentLayout? get documentLayout {
    final s = _layoutKey.currentState;
    return s is DocumentLayout ? s as DocumentLayout : null;
  }

  FocusNode get focusNode =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'WonkyRichEditor'));

  MarkdownEditingController get controller => widget.controller;

  bool get _editable => widget.enabled && !widget.readOnly;

  static bool get _mac =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _configure();
    _attachSpelling();
    focusNode.addListener(_onFocus);
    if (widget.autofocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !focusNode.hasFocus) focus();
      });
    }
  }

  @override
  void didUpdateWidget(WonkyRichEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      focusNode.addListener(_onFocus);
    }
    _configure();
    _attachSpelling(force: oldWidget.controller != widget.controller);
    if (!listEquals(oldWidget.customStylePhases, widget.customStylePhases)) {
      // The layout takes style phases when it is created.
      _styledTheme = null;
    }
  }

  void _attachSpelling({bool force = false}) {
    final checker = widget.spellChecker;
    if (!force && identical(checker, _spelling?.checker)) return;
    _spelling?.dispose();
    _spelling = checker == null
        ? null
        : DocumentSpelling(
            document: controller.document,
            composer: controller.composer,
            checker: checker,
            checks: (node) => !isCodeLike(node),
          );
    // The layout takes style phases when it is created.
    _styledTheme = null;
  }

  void _configure() {
    controller
      ..readOnly = !_editable
      ..maxLength = widget.maxLength;
  }

  @override
  void dispose() {
    _spelling?.dispose();
    _browserMenu(off: false);
    focusNode.removeListener(_onFocus);
    _ownFocus?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  /// Focuses the field (the caret at the end when there was none).
  void focus() {
    if (!widget.enabled) return;
    focusNode.requestFocus();
    if (controller.selection == null) controller.moveCaretToEnd();
  }

  // ------------------------------------------------------------ actions

  void _inline(InlineFormat f) {
    controller.toggleInline(f);
    focus();
  }

  void _block(BlockFormat f) {
    controller.toggleBlock(f);
    focus();
  }

  Future<void> editLink() async {
    if (!_editable || !controller.canLink) return;
    final current = controller.link;
    final selection = controller.selection;
    final result = await (widget.requestLink ?? _defaultLinkDialog)(
      context,
      current,
    );
    if (!mounted) return;
    if (result != null && selection != null) {
      controller.editor.execute([
        ChangeSelectionRequest(
          selection,
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      ]);
      controller.setLink(result.url);
    }
    focus();
  }

  /// Copies the selection as Markdown ([cut] also deletes it, unless the
  /// field is read-only).
  Future<void> _copy({bool cut = false}) async {
    final markdown = controller.selectedMarkdown;
    if (markdown == null) return;
    if (cut && _editable) controller.deleteSelection();
    await Clipboard.setData(ClipboardData(text: markdown));
  }

  Future<void> _paste({bool plain = false}) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted || text == null || text.isEmpty) return;
    controller.paste(text, plain: plain);
  }

  // ----------------------------------------------------------- keyboard

  ExecutionInstruction _keys({
    required SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      return ExecutionInstruction.continueExecution;
    }
    final keyboard = HardwareKeyboard.instance;
    final mod = _mac ? keyboard.isMetaPressed : keyboard.isControlPressed;
    final shift = keyboard.isShiftPressed;
    final alt = keyboard.isAltPressed;
    final key = keyEvent.logicalKey;
    ExecutionInstruction run(void Function() action) {
      action();
      return ExecutionInstruction.haltExecution;
    }

    if (mod && !alt) {
      switch (key) {
        case LogicalKeyboardKey.keyB when !shift:
          return run(() => _inline(InlineFormat.bold));
        case LogicalKeyboardKey.keyI when !shift:
          return run(() => _inline(InlineFormat.italic));
        case LogicalKeyboardKey.keyE when !shift:
          return run(() => _inline(InlineFormat.code));
        case LogicalKeyboardKey.keyX when shift:
          return run(() => _inline(InlineFormat.strikethrough));
        case LogicalKeyboardKey.keyK when !shift:
          return run(() => unawaited(editLink()));
        case LogicalKeyboardKey.keyZ:
          return run(shift ? controller.redo : controller.undo);
        case LogicalKeyboardKey.keyY when !_mac:
          return run(controller.redo);
        case LogicalKeyboardKey.keyC when !shift:
          return run(() => unawaited(_copy()));
        case LogicalKeyboardKey.keyX when !shift:
          return run(() => unawaited(_copy(cut: true)));
        case LogicalKeyboardKey.keyV:
          return run(() => unawaited(_paste(plain: shift)));
        case LogicalKeyboardKey.digit7 when shift:
          return run(() => _block(BlockFormat.numberedList));
        case LogicalKeyboardKey.digit8 when shift:
          return run(() => _block(BlockFormat.bulletList));
        case LogicalKeyboardKey.digit9 when shift:
          return run(() => _block(BlockFormat.taskList));
        case LogicalKeyboardKey.period when shift:
          return run(() => _block(BlockFormat.quote));
        case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
          final submit = widget.onSubmit;
          if (submit == null) return ExecutionInstruction.continueExecution;
          return run(submit);
      }
      return ExecutionInstruction.continueExecution;
    }
    if (key == LogicalKeyboardKey.tab && !mod && !alt) {
      if (_inCode()) {
        if (!shift && _editable) {
          controller.editor.execute([
            const InsertPlainTextAtCaretRequest('  '),
          ]);
        }
        return ExecutionInstruction.haltExecution;
      }
      if (_editable && controller.indentItems(outdent: shift)) {
        return ExecutionInstruction.haltExecution;
      }
      // Elsewhere Tab leaves the field, like any other input.
      if (shift) {
        focusNode.previousFocus();
      } else {
        focusNode.nextFocus();
      }
      return ExecutionInstruction.haltExecution;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        !mod &&
        !shift &&
        !alt &&
        _editable &&
        _enterConversion()) {
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }

  bool _inCode() {
    final s = controller.selection;
    if (s == null) return false;
    return isCodeLike(controller.document.getNodeById(s.extent.nodeId));
  }

  /// `---` + Enter makes a rule (Write 04 §7.1).
  bool _enterConversion() {
    final s = controller.selection;
    if (s == null || !s.isCollapsed) return false;
    final node = controller.document.getNodeById(s.extent.nodeId);
    final p = s.extent.nodePosition;
    if (!isPlainParagraph(node) || p is! TextNodePosition) return false;
    final text = (node as ParagraphNode).text.toPlainText();
    if (p.offset != text.length) return false;
    final whole = DocumentRange(
      start: DocumentPosition(
        nodeId: node.id,
        nodePosition: const TextNodePosition(offset: 0),
      ),
      end: s.extent,
    );
    final caret = DocumentSelection.collapsed(
      position: DocumentPosition(
        nodeId: node.id,
        nodePosition: const TextNodePosition(offset: 0),
      ),
    );
    if (controller.features.rules &&
        RegExp(r'^(---|\*\*\*|___)$').hasMatch(text)) {
      controller.editor.execute([
        DeleteContentRequest(documentRange: whole),
        InsertNodeAtIndexRequest(
          nodeIndex: controller.document.getNodeIndexById(node.id),
          newNode: HorizontalRuleNode(id: Editor.createNodeId()),
        ),
        ChangeSelectionRequest(
          caret,
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      ]);
      return true;
    }
    return false;
  }

  static final _removedActions = <SuperEditorKeyboardAction>{
    undoWhenCmdZOrCtrlZIsPressed,
    redoWhenCmdShiftZOrCtrlShiftZIsPressed,
    cmdBToToggleBold,
    cmdIToToggleItalics,
    pasteWhenCmdVIsPressed,
    copyWhenCmdCIsPressed,
    cutWhenCmdXIsPressed,
    tabToIndentParagraph,
    shiftTabToUnIndentParagraph,
    backspaceToUnIndentParagraph,
    enterToUnIndentParagraph,
    tabToIndentTask,
    shiftTabToUnIndentTask,
    // Esc belongs to the dialog or page around the field.
    collapseSelectionWhenEscIsPressed,
  };

  static final List<SuperEditorKeyboardAction> _imeActions = [
    for (final a in defaultImeKeyboardActions)
      if (!_removedActions.contains(a)) a,
  ];

  // ---------------------------------------------------------- shortcuts

  List<String> _shortcut(String key, {bool shift = false}) =>
      _mac ? [if (shift) '⇧', '⌘', key] : ['Ctrl', if (shift) 'Shift', key];

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final style = RichEditorStyle.of(context);
    final theme = style.theme;
    final decoration = (theme.inputTheme.decoration ?? const ShadDecoration())
        .merge(theme.textareaTheme.decoration);
    final focused = focusNode.hasFocus;
    final max = widget.maxLength;
    final field = ShadDecorator(
      decoration: decoration,
      focused: focused && widget.enabled,
      child: Semantics(
        textField: true,
        multiline: true,
        readOnly: !_editable,
        enabled: widget.enabled,
        label: widget.hint,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            _secondaryDown = e.buttons & kSecondaryMouseButton != 0;
            if (_secondaryDown) _contextMenu(e.position);
          },
          onPointerUp: (_) {
            // A tap below the text (inside the field) focuses it too — at
            // once: the IME connection opens with the focus, and keys typed
            // before it exists are lost on the web (a post-frame focus
            // waited for an unrelated frame, up to a caret blink).
            if (!_secondaryDown && mounted && !focusNode.hasFocus) focus();
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.minHeight,
              maxHeight: widget.maxHeight,
            ),
            child: KeyedSubtree(
              key: ValueKey<String>(widget.fieldKey),
              child: _editor(style),
            ),
          ),
        ),
      ),
    );
    final spelling = widget.spellChecker != null;
    // A press outside the field and its toolbar leaves it, as it does a
    // text input (menus and dialogs it opens focus it again when done).
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only the toolbar and the counter follow every keystroke.
        if (widget.toolbar) ...[
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _toolbar(context),
          ),
          const SizedBox(height: 4),
        ],
        if (spelling)
          MouseRegion(
            // The browser's context menu would cover ours (web).
            onEnter: (_) => _browserMenu(off: widget.enabled),
            onExit: (_) => _browserMenu(off: false),
            child: WonkyPopupMenuHost(key: _menu, child: field),
          )
        else
          field,
        if (max != null)
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final length = controller.length;
              if (length < max * 0.8) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  widget.labels.length(length, max),
                  key: ValueKey<String>('${widget.fieldKey}.count'),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 11,
                    color: length >= max ? theme.colorScheme.destructive : null,
                  ),
                ),
              );
            },
          ),
      ],
    );
    return ShadDisabled(
      disabled: !widget.enabled,
      child: TapRegion(
        groupId: _tapGroup,
        onTapOutside: (_) {
          if (focusNode.hasFocus) focusNode.unfocus();
        },
        child: column,
      ),
    );
  }

  /// The field and its toolbar as one region for [TapRegion.onTapOutside].
  String get _tapGroup => '${widget.fieldKey}#${identityHashCode(this)}';

  ShadThemeData? _styledTheme;
  String? _styledHint;
  late Stylesheet _stylesheet;
  late List<ComponentBuilder> _builders;

  Widget _editor(RichEditorStyle style) {
    final theme = style.theme;
    // A new stylesheet restyles the whole document: only on theme changes.
    if (!identical(theme, _styledTheme) || widget.hint != _styledHint) {
      _styledTheme = theme;
      _styledHint = widget.hint;
      _stylesheet = style.stylesheet();
      _builders = style.componentBuilders(controller.editor, hint: widget.hint);
    }
    // Its own scroll view: super_editor scrolls the nearest vertical
    // Scrollable, which must not be the dialog's or the page's.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(
        controller: _scroll,
        shrinkWrap: true,
        slivers: [
          SuperEditor(
            editor: controller.editor,
            focusNode: focusNode,
            documentLayoutKey: _layoutKey,
            inputSource: TextInputSource.ime,
            // Several fields can be on screen (a dialog over a page).
            inputRole: _tapGroup,
            tapRegionGroupId: _tapGroup,
            gestureMode: DocumentGestureMode.mouse,
            selectionPolicies: const SuperEditorSelectionPolicies(
              clearSelectionWhenEditorLosesFocus: false,
              clearSelectionWhenImeConnectionCloses: false,
            ),
            stylesheet: _stylesheet,
            customStylePhases: [
              ...widget.customStylePhases,
              ?_spelling?.stylePhase,
            ],
            componentBuilders: _builders,
            selectionStyle: SelectionStyles(
              selectionColor: theme.colorScheme.selection,
            ),
            // The selection outlives the focus (the toolbar acts on it), so
            // the caret layer is only there while the field is focused and
            // editable: no caret, and no blink timer, in an unfocused field.
            // An empty layer takes its slot: super_editor's ContentLayers
            // never unmounts layers dropped from the end of the list.
            documentOverlayBuilders: [
              if (focusNode.hasFocus && _editable)
                DefaultCaretOverlayBuilder(
                  caretStyle: CaretStyle(
                    width: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                const FunctionalSuperEditorLayerBuilder(_noCaret),
            ],
            keyboardActions: [_keys, ..._imeActions],
            // Links don't open while editing.
            contentTapDelegateFactories: const [],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- context menu

  /// Turns the browser's context menu off while the pointer is over the
  /// field (web; restored as it was).
  void _browserMenu({required bool off}) {
    if (!kIsWeb) return;
    if (off && !_browserMenuOff && BrowserContextMenu.enabled) {
      _browserMenuOff = true;
      unawaited(BrowserContextMenu.disableContextMenu());
    } else if (!off && _browserMenuOff) {
      _browserMenuOff = false;
      unawaited(BrowserContextMenu.enableContextMenu());
    }
  }

  /// A right-click at [global]: the spelling menu of the misspelled word
  /// there, then Cut, Copy and Paste.
  void _contextMenu(Offset global) {
    final checker = widget.spellChecker;
    final host = _menu.currentState;
    if (checker == null || host == null || !widget.enabled) return;
    final layout = documentLayout;
    final position = layout?.getDocumentPositionNearestToOffset(
      layout.getDocumentOffsetFromAncestorOffset(global),
    );
    final hit = position == null ? null : _spelling?.errorAt(position);
    final nodeId = position?.nodeId;
    final hasSelection = !(controller.selection?.isCollapsed ?? true);
    final l = widget.labels;
    host.show(
      global,
      () => [
        if (hit != null && nodeId != null && _editable && checker.underline)
          ...spellingMenuEntries(
            word: hit.word,
            suggestions: checker.suggestionsFor(hit.word),
            onReplace: (word) {
              controller.replaceText(nodeId, hit.start, hit.end, word);
              focus();
            },
            onIgnore: () {
              checker.ignore(hit.word);
              focus();
            },
            onAddToDictionary: () {
              unawaited(checker.addToDictionary(hit.word));
              focus();
            },
            labels: l.spelling,
            keyPrefix: 'menu.markdown.spell',
          ),
        WonkyMenuItem(
          key: const ValueKey<String>('menu.markdown.cut'),
          label: l.cut,
          icon: LucideIcons.scissors,
          enabled: _editable && hasSelection,
          shortcut: _shortcut('X'),
          onSelected: () {
            unawaited(_copy(cut: true));
            focus();
          },
        ),
        WonkyMenuItem(
          key: const ValueKey<String>('menu.markdown.copy'),
          label: l.copy,
          icon: LucideIcons.copy,
          enabled: hasSelection,
          shortcut: _shortcut('C'),
          onSelected: () {
            unawaited(_copy());
            focus();
          },
        ),
        WonkyMenuItem(
          key: const ValueKey<String>('menu.markdown.paste'),
          label: l.paste,
          icon: LucideIcons.clipboardPaste,
          enabled: _editable,
          shortcut: _shortcut('V'),
          onSelected: () {
            focus();
            unawaited(_paste());
          },
        ),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    final l = widget.labels;
    final c = controller;
    final on = _editable;
    final inline = on && c.canFormatInline;
    final block = c.blockFormat;
    Widget toggle(
      String id,
      IconData icon,
      String label,
      bool value,
      bool enabled,
      VoidCallback action, {
      List<String>? shortcut,
    }) {
      final size = WonkyThemeScope.of(context).toolbarButtonSize;
      // Like wonky_ui's ToolbarToggleButton (Write's toolbar), with a
      // tooltip that wraps instead of overflowing.
      return ShadTooltip(
        builder: (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label)),
            if (enabled && shortcut != null) ...[
              const SizedBox(width: 8),
              ShadKbd.group(shortcut, height: 18),
            ],
          ],
        ),
        child: ShadToggle(
          key: ValueKey<String>('${widget.fieldKey}.$id'),
          value: value,
          enabled: enabled,
          onChanged: (_) => action(),
          width: size,
          height: size,
          padding: EdgeInsets.zero,
          semanticLabel: label,
          child: Icon(icon, size: 16),
        ),
      );
    }

    Widget gap() => const SizedBox(width: 6);
    return Semantics(
      container: true,
      label: l.toolbar,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          toggle(
            'bold',
            LucideIcons.bold,
            l.bold,
            c.isActive(InlineFormat.bold),
            inline,
            () => _inline(InlineFormat.bold),
            shortcut: _shortcut('B'),
          ),
          toggle(
            'italic',
            LucideIcons.italic,
            l.italic,
            c.isActive(InlineFormat.italic),
            inline,
            () => _inline(InlineFormat.italic),
            shortcut: _shortcut('I'),
          ),
          toggle(
            'strike',
            LucideIcons.strikethrough,
            l.strikethrough,
            c.isActive(InlineFormat.strikethrough),
            inline,
            () => _inline(InlineFormat.strikethrough),
            shortcut: _shortcut('X', shift: true),
          ),
          toggle(
            'code',
            LucideIcons.code,
            l.code,
            c.isActive(InlineFormat.code),
            inline,
            () => _inline(InlineFormat.code),
            shortcut: _shortcut('E'),
          ),
          toggle(
            'link',
            LucideIcons.link,
            l.link,
            c.link != null,
            inline,
            () => unawaited(editLink()),
            shortcut: _shortcut('K'),
          ),
          gap(),
          toggle(
            'bullets',
            LucideIcons.list,
            l.bulletedList,
            block == BlockFormat.bulletList,
            on && c.canFormatBlock(BlockFormat.bulletList),
            () => _block(BlockFormat.bulletList),
            shortcut: _shortcut('8', shift: true),
          ),
          toggle(
            'numbers',
            LucideIcons.listOrdered,
            l.numberedList,
            block == BlockFormat.numberedList,
            on && c.canFormatBlock(BlockFormat.numberedList),
            () => _block(BlockFormat.numberedList),
            shortcut: _shortcut('7', shift: true),
          ),
          toggle(
            'tasks',
            LucideIcons.listTodo,
            l.taskList,
            block == BlockFormat.taskList,
            on && c.canFormatBlock(BlockFormat.taskList),
            () => _block(BlockFormat.taskList),
            shortcut: _shortcut('9', shift: true),
          ),
          gap(),
          if (c.features.quotes)
            toggle(
              'quote',
              LucideIcons.quote,
              l.quote,
              block == BlockFormat.quote,
              on && c.canFormatBlock(BlockFormat.quote),
              () => _block(BlockFormat.quote),
              shortcut: _shortcut('.', shift: true),
            ),
        ],
      ),
    );
  }

  /// A minimal link dialog when the host provides none.
  Future<RichLinkResult?> _defaultLinkDialog(
    BuildContext context,
    String? current,
  ) => showShadDialog<RichLinkResult>(
    context: context,
    builder: (context) => _LinkDialog(current: current, labels: widget.labels),
  );
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.current, required this.labels});

  final String? current;
  final RichEditorLabels labels;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _url = TextEditingController(text: widget.current ?? 'https://');
  bool _invalid = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _apply() {
    final target = normalizeLinkTarget(_url.text);
    if (target == null || !isSafeLink(target)) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(RichLinkResult(target));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      key: const ValueKey<String>('dialog.markdown.link'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(widget.labels.link),
      actions: [
        if (widget.current != null)
          ShadButton.outline(
            key: const ValueKey<String>('dialog.markdown.link.remove'),
            onPressed: () =>
                Navigator.of(context).pop(const RichLinkResult(null)),
            child: const Icon(LucideIcons.unlink, size: 16),
          ),
        ShadButton(
          key: const ValueKey<String>('dialog.markdown.link.ok'),
          onPressed: _apply,
          child: const Icon(LucideIcons.check, size: 16),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            key: const ValueKey<String>('dialog.markdown.link.url'),
            controller: _url,
            autofocus: true,
            onSubmitted: (_) => _apply(),
          ),
          if (_invalid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'http(s) / mailto',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The caret's layer in a field without focus (see [WonkyRichEditorState]).
ContentLayerWidget _noCaret(BuildContext context, SuperEditorContext _) =>
    const EmptyContentLayer();
