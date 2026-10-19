@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';
import 'package:wonky_server/src/sheets/spaces/sheets_create_defaults.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  group('SheetsCreateDefaults.decode', () {
    test('when the JSON has the Settings › Sheets keys then they are read', () {
      final d = SheetsCreateDefaults.decode(
        jsonEncode({
          'defaultLocale': 'de_DE',
          'defaultTimeZone': 'Europe/Berlin',
          'defaultFontFamily': 'Lato',
          'defaultFontSize': 12,
          'enterStartsEditing': true,
        }),
      );
      expect(d.locale, 'de_DE');
      expect(d.timeZone, 'Europe/Berlin');
      expect(d.fontFamily, 'Lato');
      expect(d.fontSize, 12.0);
    });

    test('when the JSON is empty, invalid or has bad values then nothing is '
        'set', () {
      for (final json in ['', '{}', 'nope', '[1]', '{"defaultFontSize": 0}']) {
        final d = SheetsCreateDefaults.decode(json);
        expect(
          [d.locale, d.timeZone, d.fontFamily, d.fontSize],
          everyElement(isNull),
          reason: json,
        );
      }
    });
  });

  withWonkyServerpod('Given a user with Settings › Sheets defaults', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      await endpoints.user.updatePreferences(
        anna.endpointSession,
        UserPreferencesPatch(
          sheetsDefaults: jsonEncode({
            'defaultLocale': 'de_DE',
            'defaultTimeZone': 'Europe/Berlin',
            'defaultFontFamily': 'Lato',
            'defaultFontSize': 12,
          }),
        ),
      );
    });

    Future<Spreadsheet> spreadsheetOf(DriveItemView view) async =>
        (await Spreadsheet.db.findById(
          anna.session,
          view.contentRef!,
        ))!;

    test('when a blank spreadsheet is created on the server then it uses '
        'the defaults', () async {
      final view = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Blank',
        null,
      );

      final s = await spreadsheetOf(view);
      expect(s.locale, 'de_DE');
      expect(s.timeZone, 'Europe/Berlin');
      expect(s.defaultFontFamily, 'Lato');
      expect(s.defaultFontSize, 12.0);
      expect((jsonDecode(s.themeJson) as Map)['fonts'], {'text': 'Lato'});
    });

    test('when a built-in template is created then it uses the defaults, '
        'and explicit arguments win', () async {
      final tpl = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Budget',
        BuiltinTemplates.byKey('sheets.monthly-budget').uuid,
      );
      final explicit = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'US',
        null,
        locale: 'en_US',
      );

      expect((await spreadsheetOf(tpl)).locale, 'de_DE');
      expect((await spreadsheetOf(tpl)).defaultFontSize, 12.0);
      expect((await spreadsheetOf(explicit)).locale, 'en_US');
      expect((await spreadsheetOf(explicit)).timeZone, 'Europe/Berlin');
    });
  });
}
