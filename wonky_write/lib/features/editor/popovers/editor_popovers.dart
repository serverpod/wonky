import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/write_l10n.dart';
import '../plugins/slash_items.dart';
import '../styles/editor_theme.dart';

/// A person that can be mentioned (Write 04 §19.1).
@immutable
class MentionCandidate {
  const MentionCandidate({
    required this.userUuid,
    required this.displayName,
    required this.email,
    this.roleLabel,
  });

  final String userUuid;
  final String displayName;
  final String email;

  /// "Editor", "Viewer", … (badge), or `null` without access.
  final String? roleLabel;
}

/// Keyboard-navigable list state shared by the slash menu and the mention
/// picker: ↑↓ move, Enter/Tab choose, Esc closes.
class PickerController<T> extends ChangeNotifier {
  List<T> _items = const [];
  int _highlighted = 0;

  List<T> get items => _items;
  int get highlighted => _highlighted;
  T? get current =>
      _items.isEmpty ? null : _items[_highlighted.clamp(0, _items.length - 1)];

  set items(List<T> value) {
    _items = value;
    _highlighted = 0;
    notifyListeners();
  }

  void move(int delta) {
    if (_items.isEmpty) return;
    _highlighted = (_highlighted + delta) % _items.length;
    if (_highlighted < 0) _highlighted += _items.length;
    notifyListeners();
  }

  void highlight(int index) {
    _highlighted = index;
    notifyListeners();
  }

  /// Handles ↑ ↓ Enter Tab Esc. Returns whether the key was handled.
  bool handleKey(
    KeyEvent event, {
    required void Function(T item) onChoose,
    required VoidCallback onClose,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      move(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      move(-1);
      return true;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      final item = current;
      if (item == null) return false;
      onChoose(item);
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      onClose();
      return true;
    }
    return false;
  }
}

/// The slash command menu (Write 05 §8.1).
class SlashMenu extends StatelessWidget {
  const SlashMenu({
    super.key,
    required this.picker,
    required this.theme,
    required this.onChoose,
  });

  final PickerController<SlashItem> picker;
  final EditorTheme theme;
  final void Function(SlashItem item) onChoose;

  static const menuKey = ValueKey<String>('write.editor.slashMenu');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: picker,
      builder: (context, _) {
        final items = picker.items;
        return _PopoverCard(
          key: menuKey,
          theme: theme,
          width: 280,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    writeL10n(context).editorNoResults,
                    style: TextStyle(color: theme.mutedColor, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = index == picker.highlighted;
                    return _PopoverRow(
                      key: ValueKey('write.editor.slashMenu.${item.id}'),
                      theme: theme,
                      selected: selected,
                      onTap: () => onChoose(item),
                      onHover: () => picker.highlight(index),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.body.color,
                              ),
                            ),
                          ),
                          if (item.shortcut != null)
                            Text(
                              item.shortcut!,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.mutedColor,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// The @mention picker (Write 05 §9.3).
class MentionPicker extends StatelessWidget {
  const MentionPicker({
    super.key,
    required this.picker,
    required this.theme,
    required this.onChoose,
  });

  final PickerController<MentionCandidate> picker;
  final EditorTheme theme;
  final void Function(MentionCandidate candidate) onChoose;

  static const pickerKey = ValueKey<String>('write.editor.mentionPicker');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: picker,
      builder: (context, _) {
        final items = picker.items;
        return _PopoverCard(
          key: pickerKey,
          theme: theme,
          width: 300,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    writeL10n(context).editorNoPeopleFound,
                    style: TextStyle(color: theme.mutedColor, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length.clamp(0, 8),
                  itemBuilder: (context, index) {
                    final person = items[index];
                    return _PopoverRow(
                      key: ValueKey(
                        'write.editor.mentionPicker.${person.userUuid}',
                      ),
                      theme: theme,
                      selected: index == picker.highlighted,
                      onTap: () => onChoose(person),
                      onHover: () => picker.highlight(index),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.presenceColorFor(
                              person.userUuid,
                            ),
                            child: Text(
                              person.displayName.isEmpty
                                  ? '?'
                                  : person.displayName.characters.first
                                        .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.body.color,
                                  ),
                                ),
                                Text(
                                  person.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (person.roleLabel != null)
                            Text(
                              person.roleLabel!,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.mutedColor,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Actions of the link hover card (Write 04 §11.5).
@immutable
class LinkCardActions {
  const LinkCardActions({this.onOpen, this.onCopy, this.onEdit, this.onRemove});

  final VoidCallback? onOpen;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
}

/// The link hover card: domain and URL (no remote fetch) with Open, Copy,
/// Edit and Remove.
class LinkHoverCard extends StatelessWidget {
  const LinkHoverCard({
    super.key,
    required this.url,
    required this.theme,
    required this.actions,
    this.title,
  });

  final String url;
  final String? title;
  final EditorTheme theme;
  final LinkCardActions actions;

  static const cardKey = ValueKey<String>('write.editor.linkCard');

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final uri = Uri.tryParse(url);
    final isInternal = url.startsWith('wonky://');
    final heading = isInternal
        ? (title ?? l.editorWonkyDocument)
        : (uri?.host.isNotEmpty == true ? uri!.host : url);
    return _PopoverCard(
      key: cardKey,
      theme: theme,
      width: 340,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Icon(
              isInternal ? Icons.description_outlined : Icons.public,
              size: 18,
              color: theme.mutedColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.body.color,
                    ),
                  ),
                  Text(
                    _middleEllipsis(url, 44),
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, color: theme.mutedColor),
                  ),
                ],
              ),
            ),
            if (actions.onOpen != null)
              _icon(
                Icons.open_in_new,
                l.editorLinkOpen,
                actions.onOpen!,
                'open',
              ),
            if (actions.onCopy != null)
              _icon(
                Icons.copy_outlined,
                l.editorLinkCopy,
                actions.onCopy!,
                'copy',
              ),
            if (actions.onEdit != null)
              _icon(
                Icons.edit_outlined,
                l.editorLinkEdit,
                actions.onEdit!,
                'edit',
              ),
            if (actions.onRemove != null)
              _icon(
                Icons.link_off,
                l.editorLinkRemove,
                actions.onRemove!,
                'remove',
              ),
          ],
        ),
      ),
    );
  }

  Widget _icon(IconData icon, String tooltip, VoidCallback onTap, String id) =>
      IconButton(
        key: ValueKey('write.editor.linkCard.$id'),
        tooltip: tooltip,
        iconSize: 16,
        visualDensity: VisualDensity.compact,
        color: theme.body.color,
        onPressed: onTap,
        icon: Icon(icon),
      );

  static String _middleEllipsis(String text, int max) {
    if (text.length <= max) return text;
    final half = (max - 1) ~/ 2;
    return '${text.substring(0, half)}…${text.substring(text.length - half)}';
  }
}

class _PopoverCard extends StatelessWidget {
  const _PopoverCard({
    super.key,
    required this.theme,
    required this.width,
    required this.child,
  });

  final EditorTheme theme;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xff1f2227) : Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          minWidth: width,
          maxHeight: 360,
        ),
        child: child,
      ),
    );
  }
}

class _PopoverRow extends StatelessWidget {
  const _PopoverRow({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
    required this.onHover,
    required this.child,
  });

  final EditorTheme theme;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: selected ? theme.selectionColor : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

/// One emoji offered by the `:` trigger (Write 04 §20.1).
@immutable
class EmojiSuggestion {
  const EmojiSuggestion({
    required this.emoji,
    required this.name,
    this.shortcode,
  });

  /// The emoji (inserted as plain text).
  final String emoji;

  /// Its CLDR name ("grinning face").
  final String name;

  /// The matching shortcode, without colons ("grinning").
  final String? shortcode;
}

/// Emoji matching a `:query` (at most a few, best first).
typedef EmojiSuggester = List<EmojiSuggestion> Function(String query);

/// The `:` emoji suggestions popover.
class EmojiMenu extends StatelessWidget {
  const EmojiMenu({
    super.key,
    required this.picker,
    required this.theme,
    required this.onChoose,
  });

  final PickerController<EmojiSuggestion> picker;
  final EditorTheme theme;
  final void Function(EmojiSuggestion item) onChoose;

  static const menuKey = ValueKey<String>('write.editor.emojiMenu');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: picker,
      builder: (context, _) {
        final items = picker.items;
        return _PopoverCard(
          key: menuKey,
          theme: theme,
          width: 260,
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _PopoverRow(
                key: ValueKey('write.editor.emojiMenu.$index'),
                theme: theme,
                selected: index == picker.highlighted,
                onTap: () => onChoose(item),
                onHover: () => picker.highlight(index),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.shortcode == null
                            ? item.name
                            : ':${item.shortcode}:  ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: theme.body.color),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
