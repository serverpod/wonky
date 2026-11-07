import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart' show AssistantQuickAction;

/// One tool chip of an assistant reply ("Edited 3 paragraphs").
class AssistantActivity {
  AssistantActivity({
    required this.toolUseId,
    required this.toolName,
    required this.summary,
    this.running = false,
    this.error = false,
    this.changeId,
    this.rangeStart,
    this.rangeLength,
    this.revision,
    this.range,
    this.objectId,
  });

  factory AssistantActivity.fromJson(Map<String, Object?> json) =>
      AssistantActivity(
        toolUseId: '${json['toolUseId']}',
        toolName: '${json['toolName']}',
        summary: '${json['summary'] ?? ''}',
        error: json['error'] == true,
        changeId: json['changeId'] as String?,
        rangeStart: (json['rangeStart'] as num?)?.toInt(),
        rangeLength: (json['rangeLength'] as num?)?.toInt(),
        revision: (json['revision'] as num?)?.toInt(),
        range: json['range'] as String?,
        objectId: json['objectId'] as String?,
      );

  final String toolUseId;
  final String toolName;
  String summary;
  bool running;
  bool error;
  String? changeId;
  int? rangeStart;
  int? rangeLength;
  int? revision;

  /// Sheets: the A1 range the call wrote or read (Show).
  String? range;

  /// Sheets: the chart, pivot table or rule the call created (Show).
  String? objectId;

  /// Whether the call changed the document (Show / Undo apply).
  bool get changed => changeId != null;

  /// Whether it has a range (or object) to reveal.
  bool get hasRange => rangeStart != null || range != null || objectId != null;
}

/// The state of an assistant reply.
enum AssistantReplyStatus { streaming, done, stopped, refused, cutOff, failed }

/// A pending destructive-change confirmation.
class AssistantConfirmation {
  const AssistantConfirmation({
    required this.runId,
    required this.confirmationId,
    required this.summary,
  });

  final String runId;
  final String confirmationId;
  final String summary;
}

/// An entry of the message list.
sealed class AssistantEntry {
  AssistantEntry(this.key);

  /// Stable widget key.
  final String key;
}

/// A message of the user.
class AssistantUserEntry extends AssistantEntry {
  AssistantUserEntry(super.key, this.text);
  final String text;
}

/// One assistant run: streamed Markdown plus tool chips.
class AssistantReplyEntry extends AssistantEntry {
  AssistantReplyEntry(
    super.key, {
    this.runId,
    String markdown = '',
    this.status = AssistantReplyStatus.streaming,
  }) : _markdown = StringBuffer(markdown);

  String? runId;
  final StringBuffer _markdown;
  AssistantReplyStatus status;
  final List<AssistantActivity> activities = [];

  /// The latest progress note while tools run.
  String? progress;
  String? error;

  /// The error's code (`no_style`, `budget`, …) for the app's follow-up.
  String? errorCode;
  AssistantConfirmation? confirmation;

  /// A quick action's working indicator ("Proofreading…"); quick actions
  /// show no prompt in the conversation.
  String? workingLabel;

  /// The quick action this reply answers (null = a chat message).
  AssistantQuickAction? quickAction;

  /// All tool chips are shown (a long list collapses to "+N more").
  bool showAllActivities = false;

  /// Whether the run's changes were undone from the panel.
  bool undone = false;

  /// Sheets: the server change of an Edit-mode run (`done.changeId`, one
  /// undo step for the whole run).
  String? changeId;

  /// Sheets: the AI changes preview of a Suggest-mode run.
  String? previewId;

  String get markdown => _markdown.toString();

  void append(String text) => _markdown.write(text);

  /// Separates the text of two model rounds.
  void paragraphBreak() {
    final s = _markdown.toString();
    if (s.isNotEmpty && !s.endsWith('\n\n')) {
      _markdown.write(s.endsWith('\n') ? '\n' : '\n\n');
    }
  }

  bool get streaming => status == AssistantReplyStatus.streaming;

  bool get hasChanges => activities.any((a) => a.changed);
}

/// An action button of a result card ("Insert at cursor").
class AssistantResultAction {
  const AssistantResultAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.id,
  });

  final String label;
  final IconData? icon;
  final String? id;
  final void Function(String markdown) onPressed;
}

/// A result shown in the panel without a chat turn (summaries, outlines,
/// explanations, proofreading).
class AssistantResultEntry extends AssistantEntry {
  AssistantResultEntry(
    super.key, {
    required this.title,
    this.actions = const [],
    this.builder,
  });

  final String title;
  final StringBuffer _markdown = StringBuffer();
  AssistantReplyStatus status = AssistantReplyStatus.streaming;
  String? error;
  final List<AssistantResultAction> actions;

  /// A custom body (the proofreading issue list) instead of Markdown.
  final WidgetBuilder? builder;

  String get markdown => _markdown.toString();
  set markdown(String v) {
    _markdown
      ..clear()
      ..write(v);
  }

  void append(String t) => _markdown.write(t);
}

/// A context chip of the composer ("Selection: 2 paragraphs").
class AssistantContextChip {
  const AssistantContextChip({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
}

/// A quick prompt under the composer.
class AssistantQuickPrompt {
  const AssistantQuickPrompt({
    required this.label,
    required this.prompt,
    this.icon,
    this.includeComments = false,
  });

  final String label;
  final String prompt;
  final IconData? icon;

  /// Adds the open comments to the context ("Address comments").
  final bool includeComments;
}

/// Decodes `toolCallsJson`.
List<AssistantActivity> decodeActivities(String? json) {
  if (json == null || json.isEmpty) return [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return [];
    return [
      for (final e in list)
        if (e is Map) AssistantActivity.fromJson(e.cast<String, Object?>()),
    ];
  } on FormatException {
    return [];
  }
}
