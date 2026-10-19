import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaUtils;

import '../commands/write_editor_commands.dart';
import '../controller/write_editor_controller.dart';
import '../model/document_queries.dart';
import 'clipboard_codec.dart';
import 'system_clipboard.dart';

/// Copy, cut and paste for the editor (`write.edit.copy`, `cut`, `paste`,
/// `pasteWithoutFormatting`, `copyAsMarkdown`, `copyAsPlainText`,
/// `copyAsHtml`; Write 04 §23).
class EditorClipboard {
  EditorClipboard({
    required this.controller,
    required this.commands,
    SystemClipboard? clipboard,
    ClipboardCodec? codec,
  }) : clipboard = clipboard ?? SystemClipboard.platform(),
       codec = codec ?? ClipboardCodec(newEmbedId: controller.newEmbedId);

  final WriteEditorController controller;
  final WriteEditorCommands commands;
  final SystemClipboard clipboard;
  final ClipboardCodec codec;

  /// Whether viewers/commenters may copy (owner setting, suite 06).
  bool copyAllowed = true;

  /// Pastes over 1,000,000 characters are refused.
  static const maxPasteLength = 1000000;

  /// The selected fragment as a document Delta, or `null`.
  Delta? selectedFragment() {
    final selection = controller.selection;
    if (selection == null || selection.isCollapsed) return null;
    return controller.mirror.slice(selection.start, selection.end);
  }

  bool get canCopy => copyAllowed && selectedFragment() != null;

  bool get canPaste => commands.canEdit;

  /// `write.edit.copy`.
  Future<bool> copy() async {
    final fragment = selectedFragment();
    if (!copyAllowed || fragment == null) return false;
    await clipboard.write(
      codec.encode(
        fragment,
        plainAsMarkdown: controller.preferences.copyPlainTextAsMarkdown,
      ),
    );
    return true;
  }

  /// `write.edit.cut`: copy, then delete the selection (one step "Cut").
  Future<bool> cut() async {
    if (!await copy()) return false;
    final selection = controller.selection!;
    commands.replaceRangeWithTextLabelled(
      selection.start,
      selection.length,
      '',
      label: controller.strings().undoCut,
    );
    return true;
  }

  /// `write.edit.copyAsMarkdown` / `copyAsPlainText` / `copyAsHtml`.
  Future<bool> copyAs(CopyFormat format) async {
    final fragment = selectedFragment();
    if (!copyAllowed || fragment == null) return false;
    final encoded = codec.encode(
      fragment,
      plainAsMarkdown: format == CopyFormat.markdown,
    );
    final text = switch (format) {
      CopyFormat.markdown => encoded.plainText,
      CopyFormat.plainText => ClipboardCodec.readablePlainText(encoded.delta!),
      CopyFormat.html => encoded.html!,
    };
    await clipboard.write(ClipboardContent(plainText: text));
    return true;
  }

  /// `write.edit.paste` (and `pasteWithoutFormatting` with [plainOnly],
  /// `pasteAsMarkdown` with [forceMarkdown]).
  Future<bool> paste({
    bool plainOnly = false,
    bool forceMarkdown = false,
  }) async {
    final content = await clipboard.read();
    if (content == null) return false;
    return pasteContent(
      content,
      plainOnly: plainOnly,
      forceMarkdown: forceMarkdown,
    );
  }

  /// Pastes already-read [content] (browser paste events, drops, tests).
  bool pasteContent(
    ClipboardContent content, {
    bool plainOnly = false,
    bool forceMarkdown = false,
  }) {
    if (!commands.canEdit) return false;
    if (content.plainText.length > maxPasteLength ||
        (content.html?.length ?? 0) > maxPasteLength * 4) {
      controller.notify(
        EditorNotice(
          EditorNoticeKind.message,
          controller.strings().editorPasteTooLarge,
        ),
      );
      return false;
    }
    final selection = controller.selection;
    if (selection == null) return false;
    final block = controller.mirror.blockAtOffset(selection.start);
    final inCode = block.isCode;
    final decoded = codec.decode(
      content,
      plainOnly: plainOnly || inCode,
      forceMarkdown: forceMarkdown,
    );
    if (decoded == null) return false;

    // A single URL over a selection within one block links the selection.
    if (decoded.isSingleUrl && !selection.isCollapsed && !inCode) {
      final blocks = controller.mirror.blocksInSelection(selection);
      if (blocks.length == 1) {
        try {
          return commands.setLink(content.plainText.trim());
        } on EditorCommandError {
          // Fall through to a plain paste.
        }
      }
    }
    if (controller.length + DeltaUtils.documentLength(decoded.delta) >
        controller.maxDocumentChars) {
      controller.notify(const EditorNotice(EditorNoticeKind.documentFull));
      return false;
    }
    final change = commands.insertFragment(
      decoded.delta,
      label: controller.strings().undoPaste,
    );
    if (decoded.droppedFormatting) {
      controller.notify(
        EditorNotice(
          EditorNoticeKind.formattingDropped,
          controller.strings().editorFormattingDropped,
        ),
      );
    }
    return change != null;
  }
}

/// Formats of the copy-as commands.
enum CopyFormat { markdown, plainText, html }
