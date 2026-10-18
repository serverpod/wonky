import 'dart:async';

import 'package:intl/date_symbol_data_local.dart' as intl_data;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Values substituted into header/footer templates (11 §7.4).
final class HeaderFooterContext {
  /// Creates a context.
  const HeaderFooterContext({
    required this.page,
    required this.pages,
    this.title = '',
    this.sheet = '',
    this.date = '',
    this.time = '',
  });

  /// Page number in the whole job (1-based).
  final int page;

  /// Pages in the whole job.
  final int pages;
  final String title;
  final String sheet;
  final String date;
  final String time;
}

/// Header/footer token rendering: `{page}`, `{pages}`, `{title}`, `{sheet}`,
/// `{date}`, `{time}`; unknown tokens are kept verbatim.
abstract final class HeaderFooterTokens {
  static final RegExp _token = RegExp(
    r'\{(page|pages|title|sheet|date|time)\}',
  );

  /// Renders [template].
  static String render(String template, HeaderFooterContext ctx) {
    if (!template.contains('{')) return template;
    return template.replaceAllMapped(_token, (m) {
      return switch (m.group(1)) {
        'page' => '${ctx.page}',
        'pages' => '${ctx.pages}',
        'title' => ctx.title,
        'sheet' => ctx.sheet,
        'date' => ctx.date,
        'time' => ctx.time,
        _ => m.group(0)!,
      };
    });
  }
}

/// Date/time strings for `{date}`/`{time}` in the spreadsheet locale and
/// time zone.
abstract final class PrintDateTime {
  static bool _intlReady = false;
  static bool _tzReady = false;

  /// UTC offset of [timeZone] (IANA) at [utc]; unknown zones → zero.
  static Duration offset(String? timeZone, DateTime utc) {
    if (timeZone == null ||
        timeZone.isEmpty ||
        timeZone == 'UTC' ||
        timeZone == 'Etc/UTC') {
      return Duration.zero;
    }
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    try {
      final loc = tz.getLocation(timeZone);
      return loc.timeZone(utc.millisecondsSinceEpoch).offset;
    } on Object {
      return Duration.zero;
    }
  }

  /// `(date, time)` of the instant [now] in [timeZone], formatted for
  /// [locale] (`M/d/yyyy` and `h:mm a` in en_US).
  static (String, String) format(
    DateTime now, {
    String locale = 'en_US',
    String? timeZone,
    Duration Function(String? timeZone, DateTime utc)? utcOffset,
  }) {
    final utc = now.toUtc();
    final off = (utcOffset ?? offset)(timeZone, utc);
    final wall = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    ).add(off);
    if (!_intlReady) {
      // The local symbol data loads synchronously; the future is already
      // complete.
      unawaited(intl_data.initializeDateFormatting());
      _intlReady = true;
    }
    final loc = Intl.verifiedLocale(
      locale.replaceAll('-', '_'),
      DateFormat.localeExists,
      onFailure: (_) => 'en_US',
    )!;
    // CLDR uses (narrow) no-break spaces before AM/PM; PDF base fonts and
    // plain-text consumers expect ordinary spaces.
    String plain(String s) => s.replaceAll(RegExp('[\u00A0\u202F]'), ' ');
    return (
      plain(DateFormat.yMd(loc).format(wall)),
      plain(DateFormat.jm(loc).format(wall)),
    );
  }
}
