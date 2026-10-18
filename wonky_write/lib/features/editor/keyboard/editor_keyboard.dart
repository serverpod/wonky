import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../applier/delta_applier.dart';
import '../commands/write_editor_commands.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../model/document_queries.dart';

/// Handles a key event before the editor; returns `true` when handled.
typedef EditorKeyHandler = bool Function(KeyEvent event);

/// Host actions the editor's built-in shortcuts trigger but can't perform
/// itself (they live in the shell: undo stack, dialogs, popovers).
@immutable
class EditorShortcutCallbacks {
  const EditorShortcutCallbacks({
    this.onUndo,
    this.onRedo,
    this.onInsertLink,
    this.onCopy,
    this.onCut,
    this.onPaste,
    this.onPasteWithoutFormatting,
    this.onFind,
  });

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  /// `Mod+K` (`write.link.insert`): open the link popover.
  final VoidCallback? onInsertLink;
  final VoidCallback? onCopy;
  final VoidCallback? onCut;
  final VoidCallback? onPaste;
  final VoidCallback? onPasteWithoutFormatting;

  /// `Mod+F` (`write.find.open`).
  final VoidCallback? onFind;
}

/// Whether "Mod" (⌘ on macOS, Ctrl elsewhere) is pressed.
bool isModPressed() {
  final keyboard = HardwareKeyboard.instance;
  return _isApple ? keyboard.isMetaPressed : keyboard.isControlPressed;
}

bool get _isApple =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// The Write keyboard actions (Write 04 §41.1): the host keymap first, then
/// open popovers, then the built-in Write shortcuts (when the shell doesn't
/// provide a keymap), then super_editor's IME defaults minus the actions
/// Write replaces (undo/redo, bold/italic, clipboard, select all, paragraph
/// indentation, Esc).
List<SuperEditorKeyboardAction> wonkyKeyboardActions({
  required WriteEditorController controller,
  required WriteEditorCommands commands,
  EditorKeyHandler? keymap,
  EditorKeyHandler? popoverKeys,
  bool builtInShortcuts = true,
  EditorShortcutCallbacks callbacks = const EditorShortcutCallbacks(),
  bool ime = true,
}) {
  ExecutionInstruction handler({
    required SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (popoverKeys != null && popoverKeys(keyEvent)) {
      return ExecutionInstruction.haltExecution;
    }
    if (keymap != null && keymap(keyEvent)) {
      return ExecutionInstruction.haltExecution;
    }
    if (builtInShortcuts &&
        _builtInShortcut(keyEvent, controller, commands, callbacks)) {
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }

  final removed = <SuperEditorKeyboardAction>{
    undoWhenCmdZOrCtrlZIsPressed,
    redoWhenCmdShiftZOrCtrlShiftZIsPressed,
    cmdBToToggleBold,
    cmdIToToggleItalics,
    pasteWhenCmdVIsPressed,
    copyWhenCmdCIsPressed,
    cutWhenCmdXIsPressed,
    selectAllWhenCmdAIsPressed,
    tabToIndentParagraph,
    shiftTabToUnIndentParagraph,
    backspaceToUnIndentParagraph,
    enterToUnIndentParagraph,
    collapseSelectionWhenEscIsPressed,
  };
  final defaults = ime ? defaultImeKeyboardActions : defaultKeyboardActions;
  return [handler, ...defaults.where((action) => !removed.contains(action))];
}

bool _builtInShortcut(
  KeyEvent event,
  WriteEditorController controller,
  WriteEditorCommands commands,
  EditorShortcutCallbacks callbacks,
) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
  final keyboard = HardwareKeyboard.instance;
  final mod = isModPressed();
  final shift = keyboard.isShiftPressed;
  final alt = keyboard.isAltPressed;
  final key = event.logicalKey;
  final editable = controller.mode != EditorMode.viewing;

  // Ctrl+Alt producing a character is AltGr on Windows: type it (§1).
  if (!_isApple &&
      keyboard.isControlPressed &&
      alt &&
      event.character != null &&
      event.character!.isNotEmpty) {
    return false;
  }

  bool run(void Function()? action) {
    if (action == null) return false;
    action();
    return true;
  }

  if (mod && !alt) {
    switch (key) {
      case LogicalKeyboardKey.keyB when !shift:
        return run(() => commands.toggleFormat(InlineFormat.bold));
      case LogicalKeyboardKey.keyI when !shift:
        return run(() => commands.toggleFormat(InlineFormat.italic));
      case LogicalKeyboardKey.keyE when !shift:
        return run(() => commands.toggleFormat(InlineFormat.code));
      case LogicalKeyboardKey.keyX when shift:
        return run(() => commands.toggleFormat(InlineFormat.strikethrough));
      case LogicalKeyboardKey.backslash:
        return run(commands.clearFormatting);
      case LogicalKeyboardKey.keyU when !shift:
        controller.notify(
          EditorNotice(
            EditorNoticeKind.markdownHint,
            controller.strings().editorUnderlineHint,
          ),
        );
        return true;
      case LogicalKeyboardKey.keyK when !shift:
        return run(callbacks.onInsertLink);
      case LogicalKeyboardKey.keyA when !shift:
        return run(commands.selectAll);
      case LogicalKeyboardKey.keyZ when !shift:
        return run(callbacks.onUndo);
      case LogicalKeyboardKey.keyZ when shift:
        return run(callbacks.onRedo);
      case LogicalKeyboardKey.keyY when !_isApple:
        return run(callbacks.onRedo);
      case LogicalKeyboardKey.keyC when !shift:
        return run(callbacks.onCopy);
      case LogicalKeyboardKey.keyX when !shift:
        return run(callbacks.onCut);
      case LogicalKeyboardKey.keyV when shift:
        return run(callbacks.onPasteWithoutFormatting);
      case LogicalKeyboardKey.keyV:
        return run(callbacks.onPaste);
      case LogicalKeyboardKey.keyF when !shift:
        return run(callbacks.onFind);
      case LogicalKeyboardKey.digit7 when shift:
        return run(commands.toggleNumbered);
      case LogicalKeyboardKey.digit8 when shift:
        return run(commands.toggleBulleted);
      case LogicalKeyboardKey.digit9 when shift:
        return run(commands.toggleChecklist);
      case LogicalKeyboardKey.period when shift:
        return run(() => commands.setBlockType(BlockKind.quote));
      case LogicalKeyboardKey.enter:
        if (commands.canToggleChecked()) return run(commands.toggleChecked);
        if (commands.canEditCode()) return run(commands.exitCodeBlock);
        return false;
    }
  }

  if (mod && alt && !shift) {
    final headings = {
      LogicalKeyboardKey.digit0: BlockKind.paragraph,
      LogicalKeyboardKey.digit1: BlockKind.heading1,
      LogicalKeyboardKey.digit2: BlockKind.heading2,
      LogicalKeyboardKey.digit3: BlockKind.heading3,
      LogicalKeyboardKey.digit4: BlockKind.heading4,
      LogicalKeyboardKey.digit5: BlockKind.heading5,
      LogicalKeyboardKey.digit6: BlockKind.heading6,
      LogicalKeyboardKey.keyC: BlockKind.codeBlock,
    };
    final kind = headings[key];
    if (kind != null) return run(() => commands.setBlockType(kind));
  }

  // Move blocks: ⌃⇧↑/↓ on macOS, Alt+Shift+↑/↓ elsewhere (§22.4).
  final moveModifier = _isApple
      ? keyboard.isControlPressed && !keyboard.isMetaPressed
      : alt;
  if (shift &&
      moveModifier &&
      (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown)) {
    final up = key == LogicalKeyboardKey.arrowUp;
    if (commands.canMoveBlock(up: up)) commands.moveBlock(up: up);
    return true;
  }

  if (key == LogicalKeyboardKey.tab && !mod && !alt) {
    if (!editable) return false;
    if (commands.canEditCode()) {
      return run(shift ? commands.outdentCodeLines : commands.indentCodeLines);
    }
    final blocks = controller.selection == null
        ? const <BlockRef>[]
        : controller.mirror.blocksInSelection(controller.selection!);
    final inList = blocks.any(
      (b) => b.node is ListItemNode || b.node is TaskNode,
    );
    if (inList) {
      if (shift) {
        commands.outdent();
      } else {
        commands.indent();
      }
    }
    // Tab outside lists and code is consumed (§13.3).
    return true;
  }

  if (key == LogicalKeyboardKey.escape && !mod && !shift && !alt) {
    final selection = controller.selection;
    if (selection == null) return false;
    if (controller.view.blockSelection) {
      controller.view.blockSelection = false;
      return false;
    }
    if (!selection.isCollapsed) {
      controller.select(DeltaSelection.collapsed(selection.head));
      return true;
    }
    commands.selectBlock();
    controller.view.blockSelection = true;
    return true;
  }
  return false;
}
