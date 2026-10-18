import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../core/l10n_or_english.dart';
import '../core/local_store.dart';
import '../shell/form_dialog.dart';
import 'special_chars_catalog.dart';

/// The stable widget keys of the special characters dialog of one app
/// (suite 15 §7): `<app>.dialog.specialChars…`.
@immutable
final class SpecialCharsKeySet {
  const SpecialCharsKeySet(this.app);

  /// The key prefix (`write`, `slides`).
  final String app;

  String get _p => '$app.dialog.specialChars';

  ValueKey<String> get dialog => ValueKey<String>(_p);
  ValueKey<String> get category => ValueKey<String>('$_p.category');
  ValueKey<String> get search => ValueKey<String>('$_p.search');
  ValueKey<String> get grid => ValueKey<String>('$_p.grid');
  ValueKey<String> get recentRow => ValueKey<String>('$_p.recentRow');
  ValueKey<String> get preview => ValueKey<String>('$_p.preview');
  ValueKey<String> get close => ValueKey<String>('$_p.close');
  ValueKey<String> get empty => ValueKey<String>('$_p.empty');

  static String _hex(int cp) => cp.toRadixString(16).toUpperCase();

  /// Grid cell of code point [cp] ("…cell.2192").
  ValueKey<String> cell(int cp) => ValueKey<String>('$_p.cell.${_hex(cp)}');

  /// Cell of [cp] in the recent row.
  ValueKey<String> recent(int cp) => ValueKey<String>('$_p.recent.${_hex(cp)}');

  /// Option [index] of the category select.
  ValueKey<String> categoryOption(int index) =>
      ValueKey<String>('$_p.category.$index');

  @override
  bool operator ==(Object other) =>
      other is SpecialCharsKeySet && other.app == app;

  @override
  int get hashCode => app.hashCode;
}

/// Stable widget keys of the special characters dialog (suite 15 §7):
/// Write's (`write.dialog.specialChars…`, the default) and Slides'
/// ([slides]).
abstract final class SpecialCharsKeys {
  /// Write's keys (the default).
  static const write = SpecialCharsKeySet('write');

  /// Slides' keys (`slides.dialog.specialChars…`).
  static const slides = SpecialCharsKeySet('slides');

  static const dialog = ValueKey<String>('write.dialog.specialChars');
  static const category = ValueKey<String>(
    'write.dialog.specialChars.category',
  );
  static const search = ValueKey<String>('write.dialog.specialChars.search');
  static const grid = ValueKey<String>('write.dialog.specialChars.grid');
  static const recentRow = ValueKey<String>(
    'write.dialog.specialChars.recentRow',
  );
  static const preview = ValueKey<String>('write.dialog.specialChars.preview');
  static const close = ValueKey<String>('write.dialog.specialChars.close');
  static const empty = ValueKey<String>('write.dialog.specialChars.empty');

  /// Grid cell of code point [cp] ("…cell.2192").
  static ValueKey<String> cell(int cp) => write.cell(cp);

  /// Cell of [cp] in the recent row.
  static ValueKey<String> recent(int cp) => write.recent(cp);

  /// Option [index] of the category select.
  static ValueKey<String> categoryOption(int index) =>
      write.categoryOption(index);
}

/// Insert › Special characters… (Write 04 §20.2, Slides 03 §14). Each click
/// or Enter on a character calls [onInsert]; the dialog stays open until
/// Close or Esc. [keys] names the app's widget keys (Write's by default).
/// Recents are kept in [store] (the shell's per-user [LocalStore]) under
/// [SpecialCharactersDialog.recentKey].
Future<void> showSpecialCharactersDialog(
  BuildContext context, {
  required void Function(String char) onInsert,
  LocalStore? store,
  SpecialCharsCatalog? catalog,
  SpecialCharsKeySet keys = SpecialCharsKeys.write,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => SpecialCharactersDialog(
    onInsert: onInsert,
    store: store,
    catalog: catalog,
    keys: keys,
  ),
);

const _cellExtent = 40.0;
const _searchLimit = 400;

class SpecialCharactersDialog extends StatefulWidget {
  const SpecialCharactersDialog({
    super.key,
    required this.onInsert,
    this.store,
    this.catalog,
    this.bundle,
    this.keys = SpecialCharsKeys.write,
  });

  /// The recents' store key (shared by the apps, like `EmojiPrefs`).
  static const recentKey = 'write.specialChars.recent';
  static const maxRecent = 24;

  final void Function(String char) onInsert;
  final LocalStore? store;

  /// Preloaded table (tests); otherwise loaded from [bundle] or the ambient
  /// [DefaultAssetBundle].
  final SpecialCharsCatalog? catalog;
  final AssetBundle? bundle;

  /// The app's widget keys.
  final SpecialCharsKeySet keys;

  @override
  State<SpecialCharactersDialog> createState() =>
      _SpecialCharactersDialogState();
}

class _SpecialCharactersDialogState extends State<SpecialCharactersDialog>
    with McpDialogRegistration<SpecialCharactersDialog> {
  final _query = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'specialChars.search');
  final _gridFocus = FocusNode(debugLabel: 'specialChars.grid');
  final _scroll = ScrollController();

  SpecialCharsCatalog? _catalog;
  Object? _loadError;
  int _category = 0;
  List<String> _recent = const [];
  int _active = 0;
  int _columns = 1;
  SpecialChar? _hover;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog;
    _gridFocus.addListener(() => setState(() {}));
    _loadRecent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_catalog == null && _loadError == null) {
      SpecialCharsCatalog.load(
        widget.bundle ?? DefaultAssetBundle.of(context),
      ).then(
        (c) {
          if (mounted) setState(() => _catalog = c);
        },
        onError: (Object e) {
          if (mounted) setState(() => _loadError = e);
        },
      );
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    _gridFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final v = await widget.store?.read(SpecialCharactersDialog.recentKey);
    if (!mounted || v is! List) return;
    setState(() {
      _recent = [
        ..._recent,
        for (final s in v)
          if (s is String && s.isNotEmpty && !_recent.contains(s)) s,
      ].take(SpecialCharactersDialog.maxRecent).toList();
    });
  }

  bool get _searching => _query.text.trim().isNotEmpty;

  Object? _itemsKey;
  List<SpecialChar> _itemsCache = const [];

  /// The listing: search results, or the selected category (memoized).
  List<SpecialChar> get _items {
    final c = _catalog;
    if (c == null) return const [];
    final key = (c, _category, _query.text.trim());
    if (key != _itemsKey) {
      _itemsKey = key;
      _itemsCache = _searching
          ? c.search(_query.text, limit: _searchLimit)
          : c.inCategory(_category);
    }
    return _itemsCache;
  }

  void _insert(SpecialChar c) {
    final ch = c.char;
    widget.onInsert(ch);
    setState(() {
      _recent = [
        ch,
        ..._recent.where((r) => r != ch),
      ].take(SpecialCharactersDialog.maxRecent).toList();
    });
    widget.store?.write(SpecialCharactersDialog.recentKey, _recent);
  }

  void _setActive(int i, int count) {
    if (count == 0) return;
    final index = i.clamp(0, count - 1);
    setState(() => _active = index);
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final top = (index ~/ _columns) * _cellExtent;
    final bottom = top + _cellExtent;
    if (top < pos.pixels) {
      _scroll.jumpTo(top.clamp(0, pos.maxScrollExtent));
    } else if (bottom > pos.pixels + pos.viewportDimension) {
      _scroll.jumpTo(
        (bottom - pos.viewportDimension).clamp(0, pos.maxScrollExtent),
      );
    }
  }

  void _resetListing() {
    _active = 0;
    _hover = null;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Bumped when MCP sets the category (the select shows its initial value).
  int _categoryGeneration = 0;

  // MCP (`ui.get_dialog`, suite 09 §6.2): `query`, `category` and the
  // `character` of the listing (first 200), `insert` (the chosen one; the
  // dialog stays open) and `close`.

  @override
  Map<String, Object?> describe() {
    final l = wonkyAppL10nOrEnglish(context);
    final catalog = _catalog;
    final items = _items;
    final shown = items.take(200).toList();
    final active = items.isEmpty
        ? null
        : items[_active.clamp(0, items.length - 1)];
    return {
      'title': l.specialCharsTitle,
      'kind': 'specialCharacters',
      'loaded': catalog != null,
      'fields': [
        {
          'id': 'query',
          'label': l.specialCharsSearch,
          'type': 'text',
          'value': _query.text,
        },
        if (catalog != null)
          {
            'id': 'category',
            'label': l.specialCharsTitle,
            'type': 'select',
            'value': catalog.categories[_category],
            'options': catalog.categories,
          },
        {
          'id': 'character',
          'label': l.specialCharsSearchResults,
          'type': 'select',
          'value': active?.char,
          'options': [for (final c in shown) c.char],
          'optionLabels': {for (final c in shown) c.char: c.name},
          if (items.length > shown.length) 'truncated': true,
        },
      ],
      'recent': _recent,
      'buttons': [
        if (active != null) {'id': 'insert', 'label': active.name},
        {'id': 'close', 'label': l.specialCharsClose},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'query':
        setState(() {
          _query.text = '${value ?? ''}';
          _resetListing();
        });
        return true;
      case 'category':
        final c = _catalog;
        if (c == null) return false;
        final i = value is int ? value : c.categories.indexOf('$value');
        if (i < 0 || i >= c.categories.length) return false;
        setState(() {
          _category = i;
          _categoryGeneration++;
          _query.clear();
          _resetListing();
        });
        return true;
      case 'character':
        final items = _items;
        var i = items.indexWhere((c) => c.char == '$value');
        if (i < 0) {
          // A character outside the listing: search for it.
          final c = '$value'.runes.length == 1
              ? _catalog?.byCodePoint('$value'.runes.first)
              : null;
          if (c == null) return false;
          setState(() {
            _query.text = c.name;
            _resetListing();
          });
          i = _items.indexWhere((x) => x.char == c.char);
          if (i < 0) return false;
        }
        setState(() => _active = i);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'insert':
        final items = _items;
        if (items.isEmpty) return false;
        _insert(items[_active.clamp(0, items.length - 1)]);
        return true;
      case 'close' || 'cancel':
        Navigator.of(context).pop();
        return true;
    }
    return false;
  }

  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final items = _items;
    final n = items.length;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _setActive(_active - 1, n);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _setActive(_active + 1, n);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (_active + _columns < n) _setActive(_active + _columns, n);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (_active - _columns >= 0) {
        _setActive(_active - _columns, n);
      } else {
        _searchFocus.requestFocus();
      }
    } else if (key == LogicalKeyboardKey.home) {
      _setActive(0, n);
    } else if (key == LogicalKeyboardKey.end) {
      _setActive(n - 1, n);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _setActive(_active + _columns * 6, n);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _setActive(_active - _columns * 6, n);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (n > 0) _insert(items[_active.clamp(0, n - 1)]);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && _items.isNotEmpty) {
      _gridFocus.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onRootKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = wonkyAppL10nOrEnglish(context);
    final k = widget.keys;
    final catalog = _catalog;
    final items = _items;
    if (_active >= items.length) _active = math.max(0, items.length - 1);
    final width = math.min(632.0, MediaQuery.sizeOf(context).width - 48);
    final narrow = width < 480;
    final previewChar =
        _hover ??
        (items.isEmpty ? null : items[_active.clamp(0, items.length - 1)]);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onRootKey,
      child: ShadDialog(
        key: k.dialog,
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.specialCharsTitle),
        constraints: const BoxConstraints(maxWidth: 680),
        scrollable: false,
        actions: [
          ShadButton.outline(
            key: k.close,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.specialCharsClose),
          ),
        ],
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  if (catalog != null)
                    KeyedSubtree(
                      // A category set over MCP rebuilds the select.
                      key: ValueKey<int>(_categoryGeneration),
                      child: ShadSelect<int>(
                        key: k.category,
                        minWidth: 180,
                        initialValue: _category,
                        options: [
                          for (var i = 0; i < catalog.categories.length; i++)
                            ShadOption(
                              key: k.categoryOption(i),
                              value: i,
                              child: Text(catalog.categories[i]),
                            ),
                        ],
                        selectedOptionBuilder: (context, v) =>
                            Text(catalog.categories[v]),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _category = v;
                            _query.clear();
                            _resetListing();
                          });
                        },
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: _onSearchKey,
                      child: ShadInput(
                        key: k.search,
                        controller: _query,
                        focusNode: _searchFocus,
                        autofocus: true,
                        placeholder: Text(l.specialCharsSearch),
                        leading: Icon(
                          LucideIcons.search,
                          size: 16,
                          color: cs.mutedForeground,
                        ),
                        onChanged: (_) => setState(_resetListing),
                        onSubmitted: (_) {
                          final list = _items;
                          if (list.isNotEmpty) {
                            _insert(list[_active.clamp(0, list.length - 1)]);
                          }
                          _searchFocus.requestFocus();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_recent.isNotEmpty && catalog != null) ...[
                const SizedBox(height: 12),
                _recentRow(context, catalog),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _grid(context, items)),
                    if (!narrow) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 168,
                        child: _preview(context, previewChar),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentRow(BuildContext context, SpecialCharsCatalog catalog) {
    final theme = ShadTheme.of(context);
    final l = wonkyAppL10nOrEnglish(context);
    final recent = [
      for (final r in _recent)
        if (r.runes.length == 1)
          catalog.byCodePoint(r.runes.first) ??
              SpecialChar(r.runes.first, '', -1),
    ];
    return Row(
      key: widget.keys.recentRow,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            l.specialCharsRecent,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: _cellExtent,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in recent)
                  _CharCell(
                    key: widget.keys.recent(c.codePoint),
                    char: c,
                    highlighted: false,
                    focused: false,
                    hovered: _hover == c,
                    onTap: () => _insert(c),
                    onHover: (inside) => _onHover(c, inside),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onHover(SpecialChar c, bool inside) {
    if (inside) {
      setState(() => _hover = c);
    } else if (_hover == c) {
      setState(() => _hover = null);
    }
  }

  Widget _grid(BuildContext context, List<SpecialChar> items) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = wonkyAppL10nOrEnglish(context);
    Widget body;
    if (_loadError != null) {
      body = Center(
        child: Text(l.specialCharsLoadFailed, style: theme.textTheme.muted),
      );
    } else if (_catalog == null) {
      body = const Center(child: ShadSpinner(size: 20));
    } else if (items.isEmpty) {
      body = Center(
        key: widget.keys.empty,
        child: Text(l.specialCharsNoneFound, style: theme.textTheme.muted),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          _columns = math.max(
            1,
            ((constraints.maxWidth - 8) / _cellExtent).floor(),
          );
          return Focus(
            focusNode: _gridFocus,
            onKeyEvent: _onGridKey,
            child: Semantics(
              label: _searching
                  ? l.specialCharsSearchResults
                  : _catalog!.categories[_category],
              child: GridView.builder(
                key: widget.keys.grid,
                controller: _scroll,
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  mainAxisExtent: _cellExtent,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final c = items[i];
                  return _CharCell(
                    key: widget.keys.cell(c.codePoint),
                    char: c,
                    highlighted:
                        i == _active && (_gridFocus.hasFocus || _searching),
                    focused: i == _active && _gridFocus.hasFocus,
                    hovered: _hover == c,
                    onTap: () {
                      setState(() => _active = i);
                      _insert(c);
                    },
                    onHover: (inside) => _onHover(c, inside),
                  );
                },
              ),
            ),
          );
        },
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: cs.border),
        borderRadius: theme.radius,
      ),
      child: ClipRRect(borderRadius: theme.radius, child: body),
    );
  }

  Widget _preview(BuildContext context, SpecialChar? c) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Container(
      key: widget.keys.preview,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.muted, borderRadius: theme.radius),
      child: c == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: Center(
                    child: ExcludeSemantics(
                      child: c.isInvisible
                          ? Text(
                              _invisibleLabel(c),
                              style: theme.textTheme.large.copyWith(
                                color: cs.mutedForeground,
                              ),
                            )
                          : Text(
                              c.char,
                              style: TextStyle(
                                fontSize: 64,
                                height: 1.2,
                                color: cs.foreground,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.small,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  c.codeLabel,
                  style: theme.textTheme.muted.copyWith(
                    fontFamily: WonkyTheme.monoFamily,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Short label for an invisible character: the initials of its name
/// ("ZERO WIDTH SPACE" → "ZWS").
String _invisibleLabel(SpecialChar c) {
  final words = c.name.split(RegExp(r'[\s-]+')).where((w) => w.isNotEmpty);
  final initials = words.map((w) => w[0]).join();
  return initials.isEmpty ? c.codeLabel : initials;
}

class _CharCell extends StatelessWidget {
  const _CharCell({
    super.key,
    required this.char,
    required this.highlighted,
    required this.focused,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  final SpecialChar char;
  final bool highlighted;
  final bool focused;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final label = char.name.isEmpty
        ? char.codeLabel
        : '${char.displayName}, ${char.codeLabel}';
    return Semantics(
      button: true,
      selected: highlighted,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: _cellExtent,
            height: _cellExtent,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted
                  ? cs.accent
                  : hovered
                  ? cs.muted
                  : null,
              borderRadius: theme.radius,
              border: focused ? Border.all(color: cs.ring, width: 2) : null,
            ),
            child: ExcludeSemantics(
              child: char.isInvisible
                  ? Text(
                      _invisibleLabel(char),
                      style: TextStyle(
                        fontSize: 9,
                        color: highlighted
                            ? cs.accentForeground
                            : cs.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    )
                  : Text(
                      char.char,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        color: highlighted
                            ? cs.accentForeground
                            : cs.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
