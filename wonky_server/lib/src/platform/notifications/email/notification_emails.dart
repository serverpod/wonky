import 'dart:convert';

import '../../common/json.dart';
import '../../common/models.dart';
import 'email_sender.dart';

/// Renders notification emails (specs/07 §4): one email for a mention or an
/// assignment, a digest for everything else. Links point at the apps on the
/// web server (`<origin>/write/d/<uuid>`, `<origin>/sheets/s/<uuid>`,
/// `<origin>/slides/p/<uuid>`, folders `<origin>/drive/f/<uuid>`).
class NotificationEmails {
  const NotificationEmails({required this.webOrigin});

  /// The public web server origin, e.g. `https://wonky.example.com`.
  final Uri webOrigin;

  /// A link to the item of [n], or the Drive home (the landing app) when it
  /// has no item.
  Uri linkFor(NotificationView n) {
    // Bugs & improvements (specs/16 §12): posts and tasks on Drive's board.
    final board = boardPathOf(n.payload);
    if (board != null) return webOrigin.replace(path: '/drive$board');
    final uuid = n.itemUuid?.uuid;
    final path = switch ((uuid, n.itemKind)) {
      (null, _) => '/drive/',
      (_, DriveItemKind.spreadsheet) => '/sheets/s/$uuid',
      (_, DriveItemKind.presentation) => '/slides/p/$uuid',
      // (v2) Folders open in Wonky Drive (suite 03 §2), files in its preview.
      (_, DriveItemKind.folder) => '/drive/f/$uuid',
      (_, DriveItemKind.file) => '/drive/file/$uuid',
      _ => '/write/d/$uuid',
    };
    // Spreadsheet comments link to their cell (Sheets 10 §3.6), deck
    // comments to their slide and element (Slides 09 §3.4).
    if (n.itemKind == DriveItemKind.spreadsheet ||
        n.itemKind == DriveItemKind.presentation) {
      final thread = _threadUuidOf(n.payload);
      if (thread != null) {
        return webOrigin.replace(
          path: path,
          queryParameters: {'comment': thread},
        );
      }
    }
    return webOrigin.replace(path: path);
  }

  /// The board path of a board notification (`/improvements/p/412` or
  /// `/improvements/t/12`), from the payload's `postNumber`/`taskNumber`.
  static String? boardPathOf(String payload) {
    final p = decodeObject(payload);
    if (p['taskNumber'] is int) return '/improvements/t/${p['taskNumber']}';
    if (p['postNumber'] is int) return '/improvements/p/${p['postNumber']}';
    return null;
  }

  static String? _threadUuidOf(String payload) {
    try {
      final p = jsonDecode(payload);
      return p is Map && p['threadUuid'] is String
          ? p['threadUuid'] as String
          : null;
    } on FormatException {
      return null;
    }
  }

  /// The settings page where notification emails are turned off.
  Uri get settingsLink =>
      webOrigin.replace(path: '/write/settings/notifications');

  /// The one-line description of [n] (plain text).
  String describe(NotificationView n) {
    final who = n.actor?.displayName ?? 'Someone';
    final what = '“${n.itemName ?? 'an item'}”';
    final p = decodeObject(n.payload);
    return switch (n.kind) {
      NotificationKind.mention => '$who mentioned you in $what',
      NotificationKind.reply => '$who replied to a comment in $what',
      NotificationKind.assigned => '$who assigned you a comment in $what',
      NotificationKind.shared =>
        '$who shared $what with you'
            '${p['role'] is String ? ' (${_roleName('${p['role']}')})' : ''}',
      NotificationKind.accessRequest =>
        '$who requests '
            '${p['role'] is String ? '${_roleName('${p['role']}')} ' : ''}'
            'access to $what',
      NotificationKind.suggestion => '$who suggested edits in $what',
      NotificationKind.suggestionDecided =>
        '$who ${p['decision'] == 'rejected' ? 'rejected' : 'accepted'} '
            'your suggestion in $what',
      NotificationKind.ownershipTransfer =>
        '$who wants to transfer ownership of $what to you',
      NotificationKind.scriptFailure => 'A script failed in $what',
      NotificationKind.storage =>
        p['message'] is String
            ? '${p['message']}'
            : 'Your Wonky Work storage needs attention',
      NotificationKind.boardReply =>
        '$who commented on “${p['title'] ?? 'an issue'}”',
      NotificationKind.boardStatus || NotificationKind.boardClaim =>
        p['line'] is String
            ? '${p['line']}'
            : 'Update on “${p['title'] ?? 'Bugs & improvements'}”',
      NotificationKind.submission =>
        '${p['publication'] ?? 'A publication'} · $what: '
            '${p['excerpt'] ?? 'your story was updated'}',
    };
  }

  static String _roleName(String role) => switch (role) {
    'viewer' => 'viewer',
    'commenter' => 'commenter',
    'editor' => 'editor',
    'owner' => 'owner',
    _ => role,
  };

  /// Quoted context of [n]: the comment excerpt or the share message.
  String? excerpt(NotificationView n) {
    final p = decodeObject(n.payload);
    final e = p['excerpt'] ?? p['message'];
    return e is String && e.trim().isNotEmpty ? e.trim() : null;
  }

  /// The email for a single mention or assignment.
  OutgoingEmail single({
    required String to,
    required String displayName,
    required NotificationView notification,
  }) {
    final line = describe(notification);
    final quote = excerpt(notification);
    final link = linkFor(notification);
    final text = StringBuffer()
      ..writeln('Hi $displayName,')
      ..writeln()
      ..writeln('$line.');
    if (quote != null) {
      text
        ..writeln()
        ..writeln(quote.split('\n').map((l) => '> $l').join('\n'));
    }
    text
      ..writeln()
      ..writeln('Open: $link')
      ..writeln()
      ..writeln(_footerText);
    return OutgoingEmail(
      to: to,
      subject: line,
      text: text.toString(),
      html: _html(
        greeting: 'Hi ${_e(displayName)},',
        entries: [_entryHtml(notification)],
      ),
      category: notification.kind.name,
    );
  }

  /// The digest email of [notifications] (grouped by item, newest first).
  OutgoingEmail digest({
    required String to,
    required String displayName,
    required List<NotificationView> notifications,
  }) {
    final sorted = [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groups = <String, List<NotificationView>>{};
    for (final n in sorted) {
      groups.putIfAbsent(n.itemUuid?.uuid ?? '', () => []).add(n);
    }
    final count = sorted.length;
    final subject = count == 1
        ? describe(sorted.single)
        : '$count new notifications in Wonky Work';
    final text = StringBuffer()
      ..writeln('Hi $displayName,')
      ..writeln()
      ..writeln(
        count == 1
            ? 'Here is what happened while you were away:'
            : 'Here are $count updates since your last email:',
      );
    for (final group in groups.values) {
      text
        ..writeln()
        ..writeln(group.first.itemName ?? 'Wonky Work');
      for (final n in group) {
        text.writeln('  • ${describe(n)}');
        final q = excerpt(n);
        if (q != null) text.writeln('    “${_oneLine(q)}”');
      }
      text.writeln('  Open: ${linkFor(group.first)}');
    }
    text
      ..writeln()
      ..writeln(_footerText);
    return OutgoingEmail(
      to: to,
      subject: subject,
      text: text.toString(),
      html: _html(
        greeting: 'Hi ${_e(displayName)},',
        entries: [for (final n in sorted) _entryHtml(n)],
      ),
      category: 'digest',
    );
  }

  String get _footerText =>
      'You get these emails because of your notification settings. '
      'Change them: $settingsLink';

  String _entryHtml(NotificationView n) {
    final quote = excerpt(n);
    return '<tr><td style="padding:12px 0;border-bottom:1px solid #e5e7eb">'
        '<div style="font-size:14px;color:#111827">${_e(describe(n))}</div>'
        '${quote == null ? '' : '<div style="margin-top:6px;padding-left:10px;border-left:3px solid #d1d5db;color:#4b5563;font-size:13px">${_e(_oneLine(quote))}</div>'}'
        '<div style="margin-top:8px"><a href="${_e(linkFor(n).toString())}" '
        'style="color:#2563eb;font-size:13px;text-decoration:none">Open</a></div>'
        '</td></tr>';
  }

  String _html({required String greeting, required List<String> entries}) =>
      '<!doctype html><html><body style="margin:0;padding:24px;'
      'background:#f9fafb;font-family:-apple-system,Segoe UI,Roboto,'
      'Helvetica,Arial,sans-serif">'
      '<table role="presentation" width="100%" style="max-width:560px;'
      'margin:0 auto;background:#ffffff;border-radius:8px;padding:24px">'
      '<tr><td style="font-size:15px;color:#111827;padding-bottom:8px">'
      '$greeting</td></tr>'
      '${entries.join()}'
      '<tr><td style="padding-top:16px;font-size:12px;color:#6b7280">'
      'You get these emails because of your notification settings. '
      '<a href="${_e(settingsLink.toString())}" style="color:#6b7280">'
      'Change them</a>.</td></tr></table></body></html>';

  static String _oneLine(String s) {
    final flat = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > 160 ? '${flat.substring(0, 160)}…' : flat;
  }

  static const _escape = HtmlEscape(
    HtmlEscapeMode(
      escapeLtGt: true,
      escapeQuot: true,
      escapeApos: true,
      escapeSlash: false,
    ),
  );

  static String _e(String s) => _escape.convert(s);
}
