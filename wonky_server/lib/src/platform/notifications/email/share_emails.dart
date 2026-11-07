import 'dart:convert';

import '../../common/models.dart';
import 'email_sender.dart';
import 'notification_emails.dart';

/// Renders the emails sent when someone shares an item and turns on
/// *Send an email* in the share dialog (specs/06 §4, specs/07 §4): one to an
/// existing user ("Anna shared “Plan” with you") and an invitation to an
/// address without an account, which links to sign-up and back to the item.
///
/// Every value from people (the sender's name, the item's name, the
/// message) is escaped in the HTML and flattened to one line where a line
/// is expected. Only the recipient's own address appears in an email: never
/// the sender's or another recipient's.
class ShareEmails {
  const ShareEmails({required this.webOrigin});

  /// The public web server origin, e.g. `https://wonky.example.com`.
  final Uri webOrigin;

  /// Longest message shown in an email (the share endpoint refuses longer
  /// ones; this guards rows written before).
  static const maxMessage = 1000;

  /// The item's page.
  Uri itemLink(DriveItemKind kind, String uuid) =>
      webOrigin.replace(path: NotificationEmails.itemPath(kind, uuid));

  /// Sign-up in the item's app, coming back to the item afterwards
  /// (`/write/signup?next=/d/<uuid>`; the sign-in page it links to keeps
  /// `next`, suite 04 §1).
  Uri signUpLink(DriveItemKind kind, String uuid) {
    final (app, route) = NotificationEmails.appRoute(kind, uuid);
    return webOrigin.replace(
      path: '/$app/signup',
      queryParameters: {'next': route},
    );
  }

  /// The settings page where share emails are turned off.
  Uri get settingsLink =>
      webOrigin.replace(path: '/write/settings/notifications');

  /// The email to an existing user [displayName] at [to].
  OutgoingEmail shared({
    required String to,
    required String displayName,
    required String senderName,
    required String itemName,
    required DriveItemKind itemKind,
    required String itemUuid,
    required AccessRole role,
    String? message,
  }) {
    final sender = _name(senderName);
    final title = _name(itemName, fallback: 'Untitled');
    final link = itemLink(itemKind, itemUuid);
    final note = _message(message);
    final subject = '$sender shared “$title” with you';
    final roleLine = 'You can ${_roleVerb(role)} it.';
    final text = StringBuffer()
      ..writeln('Hi ${_name(displayName, fallback: 'there')},')
      ..writeln()
      ..writeln(
        '$sender shared the ${_kindName(itemKind)} “$title” with '
        'you. $roleLine',
      );
    _quoteText(text, sender, note);
    text
      ..writeln()
      ..writeln('Open: $link')
      ..writeln()
      ..writeln(
        'You got this email because $sender shared an item with you in '
        'Wonky Work. Turn off share emails: $settingsLink',
      );
    return OutgoingEmail(
      to: to,
      subject: subject,
      text: text.toString(),
      html: _html(
        greeting: 'Hi ${_e(_name(displayName, fallback: 'there'))},',
        line:
            '${_e(sender)} shared the ${_kindName(itemKind)} '
            '<strong>“${_e(title)}”</strong> with you. ${_e(roleLine)}',
        sender: sender,
        message: note,
        button: 'Open ${_kindName(itemKind)}',
        link: link,
        footer:
            'You got this email because ${_e(sender)} shared an item with '
            'you in Wonky Work. <a href="${_e(settingsLink.toString())}" '
            'style="color:#6b7280">Turn off share emails</a>.',
      ),
      category: 'share',
    );
  }

  /// The invitation to [to], an address without an account.
  OutgoingEmail invite({
    required String to,
    required String senderName,
    required String itemName,
    required DriveItemKind itemKind,
    required String itemUuid,
    required AccessRole role,
    String? message,
  }) {
    final sender = _name(senderName);
    final title = _name(itemName, fallback: 'Untitled');
    final link = signUpLink(itemKind, itemUuid);
    final note = _message(message);
    final subject = '$sender invited you to “$title” on Wonky Work';
    final roleLine = 'You can ${_roleVerb(role)} it.';
    final account = 'Create a free account with this address ($to) to open it.';
    final text = StringBuffer()
      ..writeln('Hi,')
      ..writeln()
      ..writeln(
        '$sender invited you to the ${_kindName(itemKind)} “$title” '
        'on Wonky Work. $roleLine',
      )
      ..writeln(account);
    _quoteText(text, sender, note);
    text
      ..writeln()
      ..writeln('Sign up and open it: $link')
      ..writeln()
      ..writeln(
        'You got this email because $sender entered your address when '
        'sharing in Wonky Work. If you did not expect it, you can ignore it.',
      );
    return OutgoingEmail(
      to: to,
      subject: subject,
      text: text.toString(),
      html: _html(
        greeting: 'Hi,',
        line:
            '${_e(sender)} invited you to the ${_kindName(itemKind)} '
            '<strong>“${_e(title)}”</strong> on Wonky Work. ${_e(roleLine)} '
            '${_e(account)}',
        sender: sender,
        message: note,
        button: 'Sign up and open',
        link: link,
        footer:
            'You got this email because ${_e(sender)} entered your address '
            'when sharing in Wonky Work. If you did not expect it, you can '
            'ignore it.',
      ),
      category: 'invite',
    );
  }

  static void _quoteText(StringBuffer text, String sender, String? note) {
    if (note == null) return;
    text
      ..writeln()
      ..writeln('$sender wrote:')
      ..writeln(note.split('\n').map((l) => '> $l').join('\n'));
  }

  static String _kindName(DriveItemKind kind) => switch (kind) {
    DriveItemKind.spreadsheet => 'spreadsheet',
    DriveItemKind.presentation => 'presentation',
    DriveItemKind.folder => 'folder',
    DriveItemKind.file => 'file',
    _ => 'document',
  };

  static String _roleVerb(AccessRole role) => switch (role) {
    AccessRole.viewer => 'view',
    AccessRole.commenter => 'view and comment on',
    _ => 'edit',
  };

  /// A name on one line without control characters (subjects are headers),
  /// at most 120 characters.
  static String _name(String? s, {String fallback = 'Someone'}) {
    final flat = (s ?? '')
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (flat.isEmpty) return fallback;
    return flat.length > 120 ? '${flat.substring(0, 120)}…' : flat;
  }

  /// The sender's message: trimmed, control characters other than line
  /// breaks removed, at most [maxMessage] characters; null when empty.
  static String? _message(String? s) {
    final clean = (s ?? '')
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[\x00-\x09\x0b-\x1f\x7f]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (clean.isEmpty) return null;
    return clean.length > maxMessage
        ? '${clean.substring(0, maxMessage)}…'
        : clean;
  }

  String _html({
    required String greeting,
    required String line,
    required String sender,
    required String? message,
    required String button,
    required Uri link,
    required String footer,
  }) =>
      '<!doctype html><html><body style="margin:0;padding:24px;'
      'background:#f9fafb;font-family:-apple-system,Segoe UI,Roboto,'
      'Helvetica,Arial,sans-serif">'
      '<table role="presentation" width="100%" style="max-width:560px;'
      'margin:0 auto;background:#ffffff;border-radius:8px;padding:24px">'
      '<tr><td style="font-size:15px;color:#111827;padding-bottom:8px">'
      '$greeting</td></tr>'
      '<tr><td style="padding:4px 0 12px;font-size:14px;line-height:20px;'
      'color:#111827">$line</td></tr>'
      '${message == null ? '' : '<tr><td style="padding:0 0 12px">'
                '<div style="font-size:12px;color:#6b7280;margin-bottom:4px">'
                '${_e(sender)} wrote:</div>'
                '<div style="padding-left:10px;border-left:3px solid #d1d5db;'
                'color:#4b5563;font-size:13px;line-height:19px">'
                '${_e(message).replaceAll('\n', '<br>')}</div></td></tr>'}'
      '<tr><td style="padding:8px 0 16px;border-bottom:1px solid #e5e7eb">'
      '<a href="${_e(link.toString())}" style="display:inline-block;'
      'background:#2563eb;color:#ffffff;font-size:14px;font-weight:600;'
      'text-decoration:none;padding:9px 16px;border-radius:6px">'
      '${_e(button)}</a></td></tr>'
      '<tr><td style="padding-top:16px;font-size:12px;color:#6b7280">'
      '$footer</td></tr></table></body></html>';

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
