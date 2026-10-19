import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/history/change_labels.dart';
import 'package:wonky_sheets/l10n/sheets_l10n.dart';

/// CQ-57: change labels are stored as English codes and localized when
/// shown (cell history "via …").
void main() {
  final l = sheetsL10nEnglish;

  group('Given a stored change label', () {
    test('when it is one Sheets writes then its localized text is shown', () {
      expect(
        changeLabelText(l, SheetsChangeLabels.insertImage),
        l.changeLabelInsertImage,
      );
      expect(
        changeLabelText(l, SheetsChangeLabels.addTrigger),
        l.changeLabelAddTrigger,
      );
    });

    test('when it comes from elsewhere then it is shown as stored', () {
      expect(changeLabelText(l, 'Sort range'), 'Sort range');
    });
  });
}
