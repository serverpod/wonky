import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;

/// The icons of the Write assistant's actions, shared by the panel's quick
/// action buttons, its ⋮ menu and the *Tools › Assistant* commands, so the
/// menu and the panel show the same icon for an action (Write 05 §7).
abstract final class WriteAiIcons {
  static const IconData summarize = LucideIcons.listCollapse;
  static const IconData proofread = LucideIcons.spellCheck;
  static const IconData addressComments = LucideIcons.messagesSquare;
  static const IconData applyStyle = LucideIcons.pencilRuler;
  static const IconData styleGuides = LucideIcons.bookType;
}
