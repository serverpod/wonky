import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'sheets_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SheetsLocalizations
/// returned by `SheetsLocalizations.of(context)`.
///
/// Applications need to include `SheetsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/sheets_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SheetsLocalizations.localizationsDelegates,
///   supportedLocales: SheetsLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SheetsLocalizations.supportedLocales
/// property.
abstract class SheetsLocalizations {
  SheetsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SheetsLocalizations of(BuildContext context) {
    return Localizations.of<SheetsLocalizations>(context, SheetsLocalizations)!;
  }

  static const LocalizationsDelegate<SheetsLocalizations> delegate =
      _SheetsLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @cmdCellSetRichText.
  ///
  /// In en, this message translates to:
  /// **'Set rich text'**
  String get cmdCellSetRichText;

  /// No description provided for @fontThemeSection.
  ///
  /// In en, this message translates to:
  /// **'Theme font'**
  String get fontThemeSection;

  /// No description provided for @fontRecentSection.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get fontRecentSection;

  /// No description provided for @fontAllSection.
  ///
  /// In en, this message translates to:
  /// **'All fonts'**
  String get fontAllSection;

  /// No description provided for @cmdSettingsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update spreadsheet settings'**
  String get cmdSettingsUpdate;

  /// No description provided for @currencyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom currencies'**
  String get currencyDialogTitle;

  /// No description provided for @currencySearch.
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get currencySearch;

  /// No description provided for @currencyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching currency'**
  String get currencyNoMatch;

  /// Display name of a currency by ISO code (custom currency dialog).
  ///
  /// In en, this message translates to:
  /// **'{code, select, USD{US Dollar} EUR{Euro} GBP{British Pound} JPY{Japanese Yen} CNY{Chinese Yuan} INR{Indian Rupee} KRW{South Korean Won} CHF{Swiss Franc} CAD{Canadian Dollar} AUD{Australian Dollar} NZD{New Zealand Dollar} SEK{Swedish Krona} NOK{Norwegian Krone} DKK{Danish Krone} ISK{Icelandic Króna} PLN{Polish Złoty} CZK{Czech Koruna} HUF{Hungarian Forint} RON{Romanian Leu} BGN{Bulgarian Lev} TRY{Turkish Lira} RUB{Russian Ruble} UAH{Ukrainian Hryvnia} ILS{Israeli New Shekel} AED{UAE Dirham} SAR{Saudi Riyal} EGP{Egyptian Pound} ZAR{South African Rand} NGN{Nigerian Naira} KES{Kenyan Shilling} BRL{Brazilian Real} MXN{Mexican Peso} ARS{Argentine Peso} CLP{Chilean Peso} COP{Colombian Peso} PEN{Peruvian Sol} HKD{Hong Kong Dollar} SGD{Singapore Dollar} TWD{New Taiwan Dollar} THB{Thai Baht} VND{Vietnamese Dong} PHP{Philippine Peso} IDR{Indonesian Rupiah} MYR{Malaysian Ringgit} PKR{Pakistani Rupee} BTC{Bitcoin} other{{code}}}'**
  String currencyName(String code);

  /// No description provided for @dtDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom date and time formats'**
  String get dtDialogTitle;

  /// No description provided for @dtAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a date or time part'**
  String get dtAdd;

  /// No description provided for @dtRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dtRemove;

  /// No description provided for @dtLiteral.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get dtLiteral;

  /// No description provided for @dtPresets.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get dtPresets;

  /// No description provided for @dtDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dtDay;

  /// No description provided for @dtWeekday.
  ///
  /// In en, this message translates to:
  /// **'Day of the week'**
  String get dtWeekday;

  /// No description provided for @dtMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get dtMonth;

  /// No description provided for @dtYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get dtYear;

  /// No description provided for @dtHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get dtHour;

  /// No description provided for @dtMinute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get dtMinute;

  /// No description provided for @dtSecond.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get dtSecond;

  /// No description provided for @dtMillisecond.
  ///
  /// In en, this message translates to:
  /// **'Millisecond'**
  String get dtMillisecond;

  /// No description provided for @dtAmPm.
  ///
  /// In en, this message translates to:
  /// **'AM/PM'**
  String get dtAmPm;

  /// No description provided for @dtElapsedHours.
  ///
  /// In en, this message translates to:
  /// **'Elapsed hours'**
  String get dtElapsedHours;

  /// No description provided for @dtElapsedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Elapsed minutes'**
  String get dtElapsedMinutes;

  /// No description provided for @dtElapsedSeconds.
  ///
  /// In en, this message translates to:
  /// **'Elapsed seconds'**
  String get dtElapsedSeconds;

  /// No description provided for @numFmtPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get numFmtPreview;

  /// No description provided for @numFmtActiveCell.
  ///
  /// In en, this message translates to:
  /// **'Selected cell'**
  String get numFmtActiveCell;

  /// No description provided for @numFmtSamplePositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get numFmtSamplePositive;

  /// No description provided for @numFmtSampleNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get numFmtSampleNegative;

  /// No description provided for @numFmtSampleZero.
  ///
  /// In en, this message translates to:
  /// **'Zero'**
  String get numFmtSampleZero;

  /// No description provided for @numFmtSampleText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get numFmtSampleText;

  /// No description provided for @numFmtRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get numFmtRecent;

  /// No description provided for @numFmtExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get numFmtExamples;

  /// No description provided for @numFmtCodesHelp.
  ///
  /// In en, this message translates to:
  /// **'Format codes'**
  String get numFmtCodesHelp;

  /// No description provided for @numFmtParseError.
  ///
  /// In en, this message translates to:
  /// **'Position {position}: {message}'**
  String numFmtParseError(int position, String message);

  /// No description provided for @numFmtCodeZero.
  ///
  /// In en, this message translates to:
  /// **'Digit, padded with zeros'**
  String get numFmtCodeZero;

  /// No description provided for @numFmtCodeHash.
  ///
  /// In en, this message translates to:
  /// **'Digit, no padding'**
  String get numFmtCodeHash;

  /// No description provided for @numFmtCodeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Digit, padded with a space (aligns decimals)'**
  String get numFmtCodeQuestion;

  /// No description provided for @numFmtCodeSeparators.
  ///
  /// In en, this message translates to:
  /// **'Decimal point and thousands separator (locale symbols)'**
  String get numFmtCodeSeparators;

  /// No description provided for @numFmtCodePercent.
  ///
  /// In en, this message translates to:
  /// **'Multiplies by 100 and shows %'**
  String get numFmtCodePercent;

  /// No description provided for @numFmtCodeExponent.
  ///
  /// In en, this message translates to:
  /// **'Scientific notation'**
  String get numFmtCodeExponent;

  /// No description provided for @numFmtCodeLiteral.
  ///
  /// In en, this message translates to:
  /// **'Literal text'**
  String get numFmtCodeLiteral;

  /// No description provided for @numFmtCodeText.
  ///
  /// In en, this message translates to:
  /// **'The cell\'s text'**
  String get numFmtCodeText;

  /// No description provided for @numFmtCodeSpacing.
  ///
  /// In en, this message translates to:
  /// **'Space as wide as c / repeat c to fill the cell'**
  String get numFmtCodeSpacing;

  /// No description provided for @numFmtCodeColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get numFmtCodeColor;

  /// No description provided for @numFmtCodeCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition for the section'**
  String get numFmtCodeCondition;

  /// No description provided for @numFmtCodeSections.
  ///
  /// In en, this message translates to:
  /// **'Positive; negative; zero; text'**
  String get numFmtCodeSections;

  /// No description provided for @numFmtCodeDates.
  ///
  /// In en, this message translates to:
  /// **'Day, month (or minute), year, hour, second'**
  String get numFmtCodeDates;

  /// No description provided for @numFmtCodeElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed hours, minutes, seconds'**
  String get numFmtCodeElapsed;

  /// No description provided for @numFmtCodeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency symbol (and locale)'**
  String get numFmtCodeCurrency;

  /// No description provided for @settingsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings for this spreadsheet'**
  String get settingsDialogTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsCalculation.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get settingsCalculation;

  /// No description provided for @settingsLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get settingsLocale;

  /// No description provided for @settingsLocaleNote.
  ///
  /// In en, this message translates to:
  /// **'Formats like \'Currency\' and dates will display using the new locale. Existing values are not changed.'**
  String get settingsLocaleNote;

  /// No description provided for @settingsTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsTimeZone;

  /// No description provided for @settingsDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Function language'**
  String get settingsDisplayLanguage;

  /// No description provided for @settingsDisplayLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsDisplayLanguageEnglish;

  /// No description provided for @settingsDisplayLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Function names and TRUE/FALSE are shown in this language. English names always work, and formulas are saved in English.'**
  String get settingsDisplayLanguageNote;

  /// No description provided for @settingsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get settingsSearch;

  /// Sheets settings section (suite 04 §4, Sheets 04 §11.24).
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get sheetsSettingsDefaults;

  /// No description provided for @sheetsSettingsNewSpreadsheets.
  ///
  /// In en, this message translates to:
  /// **'New spreadsheets'**
  String get sheetsSettingsNewSpreadsheets;

  /// Command (MCP, settings screen) that changes one Sheets setting.
  ///
  /// In en, this message translates to:
  /// **'Change a Sheets setting'**
  String get cmdSheetsPrefsSet;

  /// No description provided for @sheetsSettingsNewHint.
  ///
  /// In en, this message translates to:
  /// **'Defaults for new spreadsheets you create. Each spreadsheet keeps its own settings (File › Settings).'**
  String get sheetsSettingsNewHint;

  /// No description provided for @sheetsSettingsFont.
  ///
  /// In en, this message translates to:
  /// **'Default font'**
  String get sheetsSettingsFont;

  /// No description provided for @sheetsSettingsEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get sheetsSettingsEditing;

  /// No description provided for @sheetsSettingsEnterStartsEditing.
  ///
  /// In en, this message translates to:
  /// **'Enter key starts editing'**
  String get sheetsSettingsEnterStartsEditing;

  /// No description provided for @sheetsSettingsShowEditorMode.
  ///
  /// In en, this message translates to:
  /// **'Show editor mode in status bar'**
  String get sheetsSettingsShowEditorMode;

  /// No description provided for @sheetsSettingsReduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduce grid animations'**
  String get sheetsSettingsReduceAnimations;

  /// No description provided for @sheetsSettingsFillLists.
  ///
  /// In en, this message translates to:
  /// **'Custom fill lists'**
  String get sheetsSettingsFillLists;

  /// No description provided for @sheetsSettingsFillListsHint.
  ///
  /// In en, this message translates to:
  /// **'Dragging the fill handle continues these lists. One list per line, items separated by commas.'**
  String get sheetsSettingsFillListsHint;

  /// No description provided for @sheetsSettingsFillListsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Low, Medium, High'**
  String get sheetsSettingsFillListsPlaceholder;

  /// No description provided for @sheetsSettingsFillListsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No custom lists} =1{1 custom list} other{{count} custom lists}}'**
  String sheetsSettingsFillListsCount(int count);

  /// No description provided for @settingsRecalc.
  ///
  /// In en, this message translates to:
  /// **'Recalculation'**
  String get settingsRecalc;

  /// No description provided for @settingsRecalcOnChange.
  ///
  /// In en, this message translates to:
  /// **'On change'**
  String get settingsRecalcOnChange;

  /// No description provided for @settingsRecalcMinute.
  ///
  /// In en, this message translates to:
  /// **'On change and every minute'**
  String get settingsRecalcMinute;

  /// No description provided for @settingsRecalcHour.
  ///
  /// In en, this message translates to:
  /// **'On change and every hour'**
  String get settingsRecalcHour;

  /// No description provided for @settingsIterative.
  ///
  /// In en, this message translates to:
  /// **'Iterative calculation'**
  String get settingsIterative;

  /// No description provided for @settingsIterativeHint.
  ///
  /// In en, this message translates to:
  /// **'Allows circular references, recalculated up to the maximum number of iterations.'**
  String get settingsIterativeHint;

  /// No description provided for @settingsMaxIterations.
  ///
  /// In en, this message translates to:
  /// **'Max number of iterations'**
  String get settingsMaxIterations;

  /// No description provided for @settingsThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get settingsThreshold;

  /// No description provided for @settingsThresholdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number of 0 or more'**
  String get settingsThresholdInvalid;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settingsSave;

  /// No description provided for @presenceInScriptEditor.
  ///
  /// In en, this message translates to:
  /// **'In script editor'**
  String get presenceInScriptEditor;

  /// No description provided for @presenceTypingIn.
  ///
  /// In en, this message translates to:
  /// **'Typing in {cell}'**
  String presenceTypingIn(String cell);

  /// No description provided for @presenceViewingSheet.
  ///
  /// In en, this message translates to:
  /// **'Viewing {sheet}'**
  String presenceViewingSheet(String sheet);

  /// No description provided for @presenceEditingCell.
  ///
  /// In en, this message translates to:
  /// **'Editing {cell}'**
  String presenceEditingCell(String cell);

  /// No description provided for @presenceFollowingYou.
  ///
  /// In en, this message translates to:
  /// **'Following you'**
  String get presenceFollowingYou;

  /// No description provided for @presenceTyping.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get presenceTyping;

  /// No description provided for @presenceFollowingName.
  ///
  /// In en, this message translates to:
  /// **'Following {name}'**
  String presenceFollowingName(String name);

  /// No description provided for @presenceStopFollowing.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get presenceStopFollowing;

  /// No description provided for @tabPresence.
  ///
  /// In en, this message translates to:
  /// **'On this sheet: {names}'**
  String tabPresence(String names);

  /// No description provided for @commentAnchorDeleted.
  ///
  /// In en, this message translates to:
  /// **'The cell this comment was on was deleted · {quoted}'**
  String commentAnchorDeleted(String quoted);

  /// No description provided for @cmdConflictsReview.
  ///
  /// In en, this message translates to:
  /// **'Review overwritten edits'**
  String get cmdConflictsReview;

  /// No description provided for @cmdConflictsApplyMine.
  ///
  /// In en, this message translates to:
  /// **'Apply my values again'**
  String get cmdConflictsApplyMine;

  /// No description provided for @undoApplyMine.
  ///
  /// In en, this message translates to:
  /// **'Apply my values again'**
  String get undoApplyMine;

  /// No description provided for @cmdHistoryDownload.
  ///
  /// In en, this message translates to:
  /// **'Download version'**
  String get cmdHistoryDownload;

  /// No description provided for @cmdHistoryToggleShowChanges.
  ///
  /// In en, this message translates to:
  /// **'Show changes'**
  String get cmdHistoryToggleShowChanges;

  /// No description provided for @commentsScopeSheet.
  ///
  /// In en, this message translates to:
  /// **'This sheet'**
  String get commentsScopeSheet;

  /// No description provided for @commentsScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All sheets'**
  String get commentsScopeAll;

  /// No description provided for @commentsOrphanedGroup.
  ///
  /// In en, this message translates to:
  /// **'Orphaned'**
  String get commentsOrphanedGroup;

  /// No description provided for @conflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwritten offline edits'**
  String get conflictsTitle;

  /// No description provided for @conflictsDescription.
  ///
  /// In en, this message translates to:
  /// **'Others changed these cells after you edited them offline. Select the values to put back.'**
  String get conflictsDescription;

  /// No description provided for @conflictsReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get conflictsReview;

  /// No description provided for @conflictsApplyMine.
  ///
  /// In en, this message translates to:
  /// **'Apply mine again'**
  String get conflictsApplyMine;

  /// No description provided for @conflictsDismissAll.
  ///
  /// In en, this message translates to:
  /// **'Dismiss all'**
  String get conflictsDismissAll;

  /// No description provided for @conflictsEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get conflictsEmptyValue;

  /// No description provided for @conflictsSeveralPeople.
  ///
  /// In en, this message translates to:
  /// **'several people'**
  String get conflictsSeveralPeople;

  /// No description provided for @conflictsRow.
  ///
  /// In en, this message translates to:
  /// **'{cell} — yours: {mine} · now: {theirs} ({name})'**
  String conflictsRow(String cell, String mine, String theirs, String name);

  /// No description provided for @conflictsYours.
  ///
  /// In en, this message translates to:
  /// **'yours: {value}'**
  String conflictsYours(String value);

  /// No description provided for @conflictsRowDeletedBy.
  ///
  /// In en, this message translates to:
  /// **'Row deleted by {name}'**
  String conflictsRowDeletedBy(String name);

  /// No description provided for @conflictsColumnDeletedBy.
  ///
  /// In en, this message translates to:
  /// **'Column deleted by {name}'**
  String conflictsColumnDeletedBy(String name);

  /// No description provided for @conflictsSheetDeletedBy.
  ///
  /// In en, this message translates to:
  /// **'Sheet deleted by {name}'**
  String conflictsSheetDeletedBy(String name);

  /// No description provided for @toastConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of your offline edits was replaced by a newer edit from {name}} other{{count} of your offline edits were replaced by newer edits from {name}}}'**
  String toastConflicts(int count, String name);

  /// No description provided for @toastSortReplaced.
  ///
  /// In en, this message translates to:
  /// **'Your sort was replaced by a newer sort from {name}'**
  String toastSortReplaced(String name);

  /// No description provided for @toastVersionCopyExtrasFailed.
  ///
  /// In en, this message translates to:
  /// **'The copy was made, but its comments and sharing couldn\'t be copied'**
  String get toastVersionCopyExtrasFailed;

  /// No description provided for @versionCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get versionCopyTitle;

  /// No description provided for @versionCopyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get versionCopyNameLabel;

  /// No description provided for @versionCopyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get versionCopyNameRequired;

  /// No description provided for @versionCopyComments.
  ///
  /// In en, this message translates to:
  /// **'Copy comments'**
  String get versionCopyComments;

  /// No description provided for @versionCopySharing.
  ///
  /// In en, this message translates to:
  /// **'Share with the same people'**
  String get versionCopySharing;

  /// No description provided for @commentReplies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply} other{{count} replies}}'**
  String commentReplies(int count);

  /// No description provided for @noteHeading.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteHeading;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @toastVersionRestoredBy.
  ///
  /// In en, this message translates to:
  /// **'{name} restored a previous version'**
  String toastVersionRestoredBy(String name);

  /// No description provided for @toastEditedRowDeletedBy.
  ///
  /// In en, this message translates to:
  /// **'The row you were editing was deleted by {name}.'**
  String toastEditedRowDeletedBy(String name);

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @versionCopyName.
  ///
  /// In en, this message translates to:
  /// **'Copy of {title}'**
  String versionCopyName(String title);

  /// No description provided for @toastVersionCopied.
  ///
  /// In en, this message translates to:
  /// **'Created \"{title}\"'**
  String toastVersionCopied(String title);

  /// No description provided for @versionOpenCopy.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get versionOpenCopy;

  /// No description provided for @toastVersionCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make a copy of this version'**
  String get toastVersionCopyFailed;

  /// No description provided for @versionChangedCells.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cell changed} other{{count} cells changed}}'**
  String versionChangedCells(int count);

  /// No description provided for @versionRowsInserted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row inserted} other{{count} rows inserted}}'**
  String versionRowsInserted(int count);

  /// No description provided for @versionRowsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row deleted} other{{count} rows deleted}}'**
  String versionRowsDeleted(int count);

  /// No description provided for @versionColumnsInserted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 column inserted} other{{count} columns inserted}}'**
  String versionColumnsInserted(int count);

  /// No description provided for @versionColumnsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 column deleted} other{{count} columns deleted}}'**
  String versionColumnsDeleted(int count);

  /// No description provided for @versionSheetRenamed.
  ///
  /// In en, this message translates to:
  /// **'Sheet \"{before}\" renamed to \"{after}\"'**
  String versionSheetRenamed(String before, String after);

  /// No description provided for @versionSheetsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sheet added} other{{count} sheets added}}'**
  String versionSheetsAdded(int count);

  /// No description provided for @versionSheetsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sheet deleted} other{{count} sheets deleted}}'**
  String versionSheetsDeleted(int count);

  /// No description provided for @versionNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes since the previous version'**
  String get versionNoChanges;

  /// No description provided for @versionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this version'**
  String get versionLoadFailed;

  /// No description provided for @versionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading version…'**
  String get versionLoading;

  /// No description provided for @versionComputingChanges.
  ///
  /// In en, this message translates to:
  /// **'Finding changes…'**
  String get versionComputingChanges;

  /// No description provided for @versionChangesHidden.
  ///
  /// In en, this message translates to:
  /// **'Changes are hidden'**
  String get versionChangesHidden;

  /// No description provided for @versionSheetDeletedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deleted in this version'**
  String get versionSheetDeletedTooltip;

  /// No description provided for @cellHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get cellHistoryTitle;

  /// No description provided for @cellHistoryNewer.
  ///
  /// In en, this message translates to:
  /// **'Newer edit'**
  String get cellHistoryNewer;

  /// No description provided for @cellHistoryOlder.
  ///
  /// In en, this message translates to:
  /// **'Older edit'**
  String get cellHistoryOlder;

  /// No description provided for @cellHistoryPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String cellHistoryPosition(int index, int count);

  /// No description provided for @cellHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No edits recorded for this cell'**
  String get cellHistoryEmpty;

  /// No description provided for @cellHistoryEmptyOffline.
  ///
  /// In en, this message translates to:
  /// **'No edits on this device. Older history needs a connection.'**
  String get cellHistoryEmptyOffline;

  /// No description provided for @cellHistoryBulk.
  ///
  /// In en, this message translates to:
  /// **'Changed as part of \"{label}\"'**
  String cellHistoryBulk(String label);

  /// No description provided for @cellHistoryChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get cellHistoryChanged;

  /// No description provided for @cellHistoryBlank.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get cellHistoryBlank;

  /// No description provided for @cellHistoryVia.
  ///
  /// In en, this message translates to:
  /// **'via {label}'**
  String cellHistoryVia(String label);

  /// Name of a change in the cell history ("via …"): typing into a cell. The change logs store English codes; this is how they are shown.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get changeLabelTyping;

  /// No description provided for @changeLabelInsertAiResult.
  ///
  /// In en, this message translates to:
  /// **'Insert AI result'**
  String get changeLabelInsertAiResult;

  /// No description provided for @changeLabelInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get changeLabelInsertImage;

  /// No description provided for @changeLabelRestoreVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore version'**
  String get changeLabelRestoreVersion;

  /// No description provided for @changeLabelMakeCopy.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get changeLabelMakeCopy;

  /// No description provided for @changeLabelMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get changeLabelMaintenance;

  /// No description provided for @changeLabelCreateScriptProject.
  ///
  /// In en, this message translates to:
  /// **'Create script project'**
  String get changeLabelCreateScriptProject;

  /// No description provided for @changeLabelDeleteScriptProject.
  ///
  /// In en, this message translates to:
  /// **'Delete script project'**
  String get changeLabelDeleteScriptProject;

  /// No description provided for @changeLabelCreateScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Create script file'**
  String get changeLabelCreateScriptFile;

  /// No description provided for @changeLabelRenameScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Rename script file'**
  String get changeLabelRenameScriptFile;

  /// No description provided for @changeLabelDeleteScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Delete script file'**
  String get changeLabelDeleteScriptFile;

  /// No description provided for @changeLabelMoveScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Move script file'**
  String get changeLabelMoveScriptFile;

  /// No description provided for @changeLabelSaveScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Save script file'**
  String get changeLabelSaveScriptFile;

  /// No description provided for @changeLabelScriptSettings.
  ///
  /// In en, this message translates to:
  /// **'Script settings'**
  String get changeLabelScriptSettings;

  /// No description provided for @changeLabelCreateMacro.
  ///
  /// In en, this message translates to:
  /// **'Create macro'**
  String get changeLabelCreateMacro;

  /// No description provided for @changeLabelEditMacro.
  ///
  /// In en, this message translates to:
  /// **'Edit macro'**
  String get changeLabelEditMacro;

  /// No description provided for @changeLabelDeleteMacro.
  ///
  /// In en, this message translates to:
  /// **'Delete macro'**
  String get changeLabelDeleteMacro;

  /// No description provided for @changeLabelRecordMacro.
  ///
  /// In en, this message translates to:
  /// **'Record macro'**
  String get changeLabelRecordMacro;

  /// No description provided for @changeLabelAddTrigger.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get changeLabelAddTrigger;

  /// No description provided for @changeLabelEditTrigger.
  ///
  /// In en, this message translates to:
  /// **'Edit trigger'**
  String get changeLabelEditTrigger;

  /// No description provided for @cellHistoryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore this value'**
  String get cellHistoryRestore;

  /// No description provided for @actorViaMcp.
  ///
  /// In en, this message translates to:
  /// **'Claude via MCP ({name})'**
  String actorViaMcp(String name);

  /// No description provided for @actorViaAi.
  ///
  /// In en, this message translates to:
  /// **'Assistant ({name})'**
  String actorViaAi(String name);

  /// No description provided for @actorViaScript.
  ///
  /// In en, this message translates to:
  /// **'Script ({name})'**
  String actorViaScript(String name);

  /// No description provided for @cmdPresenceJumpTo.
  ///
  /// In en, this message translates to:
  /// **'Go to collaborator'**
  String get cmdPresenceJumpTo;

  /// No description provided for @cmdPresenceFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow collaborator'**
  String get cmdPresenceFollow;

  /// No description provided for @cmdPresenceUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get cmdPresenceUnfollow;

  /// No description provided for @categoryCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get categoryCollaboration;

  /// No description provided for @cmdCommentsNext.
  ///
  /// In en, this message translates to:
  /// **'Next comment'**
  String get cmdCommentsNext;

  /// No description provided for @cmdCommentsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous comment'**
  String get cmdCommentsPrevious;

  /// No description provided for @cmdHistoryRestoreVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get cmdHistoryRestoreVersion;

  /// No description provided for @cmdHistoryMakeCopy.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get cmdHistoryMakeCopy;

  /// No description provided for @cmdHistoryNextChange.
  ///
  /// In en, this message translates to:
  /// **'Next change'**
  String get cmdHistoryNextChange;

  /// No description provided for @cmdHistoryPreviousChange.
  ///
  /// In en, this message translates to:
  /// **'Previous change'**
  String get cmdHistoryPreviousChange;

  /// No description provided for @cmdHistoryRestoreCellValue.
  ///
  /// In en, this message translates to:
  /// **'Restore value'**
  String get cmdHistoryRestoreCellValue;

  /// No description provided for @undoRestoreValue.
  ///
  /// In en, this message translates to:
  /// **'Restore value'**
  String get undoRestoreValue;

  /// No description provided for @cmdBandingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add alternating colors'**
  String get cmdBandingAdd;

  /// No description provided for @cmdBandingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit alternating colors'**
  String get cmdBandingUpdate;

  /// No description provided for @cmdBandingRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove alternating colors'**
  String get cmdBandingRemove;

  /// No description provided for @bandingPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Alternating colors'**
  String get bandingPanelTitle;

  /// No description provided for @bandingApplyToRange.
  ///
  /// In en, this message translates to:
  /// **'Apply to range'**
  String get bandingApplyToRange;

  /// No description provided for @bandingHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get bandingHeader;

  /// No description provided for @bandingFooter.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get bandingFooter;

  /// No description provided for @bandingColumns.
  ///
  /// In en, this message translates to:
  /// **'Alternate columns'**
  String get bandingColumns;

  /// No description provided for @bandingColumnsHint.
  ///
  /// In en, this message translates to:
  /// **'Header is the first column, footer the last.'**
  String get bandingColumnsHint;

  /// No description provided for @bandingDefaultStyles.
  ///
  /// In en, this message translates to:
  /// **'Default styles'**
  String get bandingDefaultStyles;

  /// No description provided for @bandingPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Default style {n}'**
  String bandingPresetLabel(int n);

  /// No description provided for @bandingCustomStyles.
  ///
  /// In en, this message translates to:
  /// **'Custom styles'**
  String get bandingCustomStyles;

  /// No description provided for @bandingCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom style {n}'**
  String bandingCustomLabel(int n);

  /// No description provided for @bandingHeaderColor.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get bandingHeaderColor;

  /// No description provided for @bandingColor1.
  ///
  /// In en, this message translates to:
  /// **'Color 1'**
  String get bandingColor1;

  /// No description provided for @bandingColor2.
  ///
  /// In en, this message translates to:
  /// **'Color 2'**
  String get bandingColor2;

  /// No description provided for @bandingFooterColor.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get bandingFooterColor;

  /// No description provided for @bandingRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove alternating colors'**
  String get bandingRemove;

  /// No description provided for @cmdThemeSet.
  ///
  /// In en, this message translates to:
  /// **'Set spreadsheet theme'**
  String get cmdThemeSet;

  /// No description provided for @themePanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themePanelTitle;

  /// No description provided for @themeCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get themeCustomize;

  /// No description provided for @themeFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get themeFont;

  /// No description provided for @themeResetToPreset.
  ///
  /// In en, this message translates to:
  /// **'Reset to preset'**
  String get themeResetToPreset;

  /// No description provided for @themeImport.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get themeImport;

  /// No description provided for @themeImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a theme from'**
  String get themeImportTitle;

  /// No description provided for @pickSpreadsheetOffline.
  ///
  /// In en, this message translates to:
  /// **'Importing needs a connection.'**
  String get pickSpreadsheetOffline;

  /// No description provided for @themePresets.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themePresets;

  /// No description provided for @themeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get themeCurrent;

  /// No description provided for @themeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get themeStandard;

  /// No description provided for @themeSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get themeSimple;

  /// No description provided for @themeStreamline.
  ///
  /// In en, this message translates to:
  /// **'Streamline'**
  String get themeStreamline;

  /// No description provided for @themePaperback.
  ///
  /// In en, this message translates to:
  /// **'Paperback'**
  String get themePaperback;

  /// No description provided for @themeMarina.
  ///
  /// In en, this message translates to:
  /// **'Marina'**
  String get themeMarina;

  /// No description provided for @themeCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get themeCoral;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

  /// No description provided for @themeMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get themeMono;

  /// No description provided for @themeRetro.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get themeRetro;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// No description provided for @fontDisplayedAs.
  ///
  /// In en, this message translates to:
  /// **'{font} (displayed as {shown})'**
  String fontDisplayedAs(String font, String shown);

  /// No description provided for @panelDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get panelDone;

  /// No description provided for @themeColorText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get themeColorText;

  /// No description provided for @themeColorBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeColorBackground;

  /// No description provided for @themeColorLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get themeColorLink;

  /// No description provided for @themeColorAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent {n}'**
  String themeColorAccent(int n);

  /// No description provided for @cmdCfAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add conditional format rule'**
  String get cmdCfAddRule;

  /// No description provided for @cmdCfUpdateRule.
  ///
  /// In en, this message translates to:
  /// **'Edit conditional format rule'**
  String get cmdCfUpdateRule;

  /// No description provided for @cmdCfDeleteRule.
  ///
  /// In en, this message translates to:
  /// **'Delete conditional format rule'**
  String get cmdCfDeleteRule;

  /// No description provided for @cmdCfReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder conditional format rules'**
  String get cmdCfReorder;

  /// No description provided for @cmdCfSetEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable conditional format rule'**
  String get cmdCfSetEnabled;

  /// No description provided for @cfUndoEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable rule'**
  String get cfUndoEnable;

  /// No description provided for @cfUndoDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable rule'**
  String get cfUndoDisable;

  /// No description provided for @cfPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Conditional format rules'**
  String get cfPanelTitle;

  /// No description provided for @cfShowRulesFor.
  ///
  /// In en, this message translates to:
  /// **'Show rules for'**
  String get cfShowRulesFor;

  /// No description provided for @cfScopeSelection.
  ///
  /// In en, this message translates to:
  /// **'Selected range'**
  String get cfScopeSelection;

  /// No description provided for @cfScopeSheet.
  ///
  /// In en, this message translates to:
  /// **'This sheet'**
  String get cfScopeSheet;

  /// No description provided for @cfNoRules.
  ///
  /// In en, this message translates to:
  /// **'No conditional format rules on this sheet yet.'**
  String get cfNoRules;

  /// No description provided for @cfNoRulesInSelection.
  ///
  /// In en, this message translates to:
  /// **'No rules apply to the selected range.'**
  String get cfNoRulesInSelection;

  /// No description provided for @cfAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add another rule'**
  String get cfAddRule;

  /// No description provided for @cfLimitReached.
  ///
  /// In en, this message translates to:
  /// **'A sheet can have at most 500 rules.'**
  String get cfLimitReached;

  /// No description provided for @cfAddRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get cfAddRuleTitle;

  /// No description provided for @cfEditRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get cfEditRuleTitle;

  /// No description provided for @cfTabSingle.
  ///
  /// In en, this message translates to:
  /// **'Single color'**
  String get cfTabSingle;

  /// No description provided for @cfTabColorScale.
  ///
  /// In en, this message translates to:
  /// **'Color scale'**
  String get cfTabColorScale;

  /// No description provided for @cfTabDataBar.
  ///
  /// In en, this message translates to:
  /// **'Data bar'**
  String get cfTabDataBar;

  /// No description provided for @cfTabIconSet.
  ///
  /// In en, this message translates to:
  /// **'Icon set'**
  String get cfTabIconSet;

  /// No description provided for @cfApplyToRange.
  ///
  /// In en, this message translates to:
  /// **'Apply to range'**
  String get cfApplyToRange;

  /// No description provided for @cfFormatCellsIf.
  ///
  /// In en, this message translates to:
  /// **'Format cells if…'**
  String get cfFormatCellsIf;

  /// No description provided for @cfFormattingStyle.
  ///
  /// In en, this message translates to:
  /// **'Formatting style'**
  String get cfFormattingStyle;

  /// No description provided for @cfStyleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get cfStyleCustom;

  /// No description provided for @cfStyleDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get cfStyleDefault;

  /// No description provided for @cfStyleGreenFill.
  ///
  /// In en, this message translates to:
  /// **'Green fill'**
  String get cfStyleGreenFill;

  /// No description provided for @cfStyleYellowFill.
  ///
  /// In en, this message translates to:
  /// **'Yellow fill'**
  String get cfStyleYellowFill;

  /// No description provided for @cfStyleRedFill.
  ///
  /// In en, this message translates to:
  /// **'Red fill'**
  String get cfStyleRedFill;

  /// No description provided for @cfStyleGreenBold.
  ///
  /// In en, this message translates to:
  /// **'Green bold text'**
  String get cfStyleGreenBold;

  /// No description provided for @cfStyleRedBold.
  ///
  /// In en, this message translates to:
  /// **'Red bold text'**
  String get cfStyleRedBold;

  /// No description provided for @cfStyleBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get cfStyleBold;

  /// No description provided for @cfStyleItalicGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey italic'**
  String get cfStyleItalicGrey;

  /// No description provided for @cfStyleStrikeGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey strikethrough'**
  String get cfStyleStrikeGrey;

  /// No description provided for @cfBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get cfBold;

  /// No description provided for @cfItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get cfItalic;

  /// No description provided for @cfUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get cfUnderline;

  /// No description provided for @cfStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get cfStrikethrough;

  /// No description provided for @cfTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get cfTextColor;

  /// No description provided for @cfFillColor.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get cfFillColor;

  /// No description provided for @cfAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cfAdvanced;

  /// No description provided for @cfStopIfTrue.
  ///
  /// In en, this message translates to:
  /// **'Stop if true'**
  String get cfStopIfTrue;

  /// No description provided for @cfStopIfTrueHint.
  ///
  /// In en, this message translates to:
  /// **'Later rules don\'t apply to cells that match this rule.'**
  String get cfStopIfTrueHint;

  /// No description provided for @cfGroupEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get cfGroupEmpty;

  /// No description provided for @cfGroupText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get cfGroupText;

  /// No description provided for @cfGroupDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get cfGroupDate;

  /// No description provided for @cfGroupNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get cfGroupNumber;

  /// No description provided for @cfGroupCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get cfGroupCustom;

  /// No description provided for @cfCondBlank.
  ///
  /// In en, this message translates to:
  /// **'Is empty'**
  String get cfCondBlank;

  /// No description provided for @cfCondNotBlank.
  ///
  /// In en, this message translates to:
  /// **'Is not empty'**
  String get cfCondNotBlank;

  /// No description provided for @cfCondTextContains.
  ///
  /// In en, this message translates to:
  /// **'Text contains'**
  String get cfCondTextContains;

  /// No description provided for @cfCondTextNotContains.
  ///
  /// In en, this message translates to:
  /// **'Text does not contain'**
  String get cfCondTextNotContains;

  /// No description provided for @cfCondTextStartsWith.
  ///
  /// In en, this message translates to:
  /// **'Text starts with'**
  String get cfCondTextStartsWith;

  /// No description provided for @cfCondTextEndsWith.
  ///
  /// In en, this message translates to:
  /// **'Text ends with'**
  String get cfCondTextEndsWith;

  /// No description provided for @cfCondTextEq.
  ///
  /// In en, this message translates to:
  /// **'Text is exactly'**
  String get cfCondTextEq;

  /// No description provided for @cfCondDateEq.
  ///
  /// In en, this message translates to:
  /// **'Date is'**
  String get cfCondDateEq;

  /// No description provided for @cfCondDateBefore.
  ///
  /// In en, this message translates to:
  /// **'Date is before'**
  String get cfCondDateBefore;

  /// No description provided for @cfCondDateAfter.
  ///
  /// In en, this message translates to:
  /// **'Date is after'**
  String get cfCondDateAfter;

  /// No description provided for @cfCondNumberGreater.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get cfCondNumberGreater;

  /// No description provided for @cfCondNumberGreaterEq.
  ///
  /// In en, this message translates to:
  /// **'Greater than or equal to'**
  String get cfCondNumberGreaterEq;

  /// No description provided for @cfCondNumberLess.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get cfCondNumberLess;

  /// No description provided for @cfCondNumberLessEq.
  ///
  /// In en, this message translates to:
  /// **'Less than or equal to'**
  String get cfCondNumberLessEq;

  /// No description provided for @cfCondNumberEq.
  ///
  /// In en, this message translates to:
  /// **'Is equal to'**
  String get cfCondNumberEq;

  /// No description provided for @cfCondNumberNotEq.
  ///
  /// In en, this message translates to:
  /// **'Is not equal to'**
  String get cfCondNumberNotEq;

  /// No description provided for @cfCondNumberBetween.
  ///
  /// In en, this message translates to:
  /// **'Is between'**
  String get cfCondNumberBetween;

  /// No description provided for @cfCondNumberNotBetween.
  ///
  /// In en, this message translates to:
  /// **'Is not between'**
  String get cfCondNumberNotBetween;

  /// No description provided for @cfCondCustomFormula.
  ///
  /// In en, this message translates to:
  /// **'Custom formula is'**
  String get cfCondCustomFormula;

  /// No description provided for @cfDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get cfDateToday;

  /// No description provided for @cfDateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get cfDateTomorrow;

  /// No description provided for @cfDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get cfDateYesterday;

  /// No description provided for @cfDatePastWeek.
  ///
  /// In en, this message translates to:
  /// **'In the past week'**
  String get cfDatePastWeek;

  /// No description provided for @cfDatePastMonth.
  ///
  /// In en, this message translates to:
  /// **'In the past month'**
  String get cfDatePastMonth;

  /// No description provided for @cfDatePastYear.
  ///
  /// In en, this message translates to:
  /// **'In the past year'**
  String get cfDatePastYear;

  /// No description provided for @cfDateExact.
  ///
  /// In en, this message translates to:
  /// **'Exact date'**
  String get cfDateExact;

  /// No description provided for @cfDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Date or formula, e.g. 2026-10-14'**
  String get cfDatePlaceholder;

  /// No description provided for @cfValuePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Value or formula'**
  String get cfValuePlaceholder;

  /// No description provided for @cfPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get cfPickDate;

  /// No description provided for @formulaFieldPointHint.
  ///
  /// In en, this message translates to:
  /// **'Select cells on the grid to insert a reference.'**
  String get formulaFieldPointHint;

  /// No description provided for @cfSummaryTwoValues.
  ///
  /// In en, this message translates to:
  /// **'{label} {a} and {b}'**
  String cfSummaryTwoValues(String label, String a, String b);

  /// No description provided for @cfKindColorScale.
  ///
  /// In en, this message translates to:
  /// **'Color scale'**
  String get cfKindColorScale;

  /// No description provided for @cfKindDataBar.
  ///
  /// In en, this message translates to:
  /// **'Data bar'**
  String get cfKindDataBar;

  /// No description provided for @cfKindIconSet.
  ///
  /// In en, this message translates to:
  /// **'Icon set'**
  String get cfKindIconSet;

  /// No description provided for @cfKindUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported rule'**
  String get cfKindUnsupported;

  /// No description provided for @cfKindMin.
  ///
  /// In en, this message translates to:
  /// **'Min value'**
  String get cfKindMin;

  /// No description provided for @cfKindMax.
  ///
  /// In en, this message translates to:
  /// **'Max value'**
  String get cfKindMax;

  /// No description provided for @cfKindNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get cfKindNumber;

  /// No description provided for @cfKindPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get cfKindPercent;

  /// No description provided for @cfKindPercentile.
  ///
  /// In en, this message translates to:
  /// **'Percentile'**
  String get cfKindPercentile;

  /// No description provided for @cfKindFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get cfKindFormula;

  /// No description provided for @cfKindNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get cfKindNone;

  /// No description provided for @cfPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get cfPreview;

  /// No description provided for @cfScalePreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get cfScalePreset;

  /// No description provided for @cfScaleWhiteGreen.
  ///
  /// In en, this message translates to:
  /// **'White to green'**
  String get cfScaleWhiteGreen;

  /// No description provided for @cfScaleGreenWhite.
  ///
  /// In en, this message translates to:
  /// **'Green to white'**
  String get cfScaleGreenWhite;

  /// No description provided for @cfScaleWhiteRed.
  ///
  /// In en, this message translates to:
  /// **'White to red'**
  String get cfScaleWhiteRed;

  /// No description provided for @cfScaleRedWhite.
  ///
  /// In en, this message translates to:
  /// **'Red to white'**
  String get cfScaleRedWhite;

  /// No description provided for @cfScaleRedWhiteGreen.
  ///
  /// In en, this message translates to:
  /// **'Red to white to green'**
  String get cfScaleRedWhiteGreen;

  /// No description provided for @cfScaleGreenWhiteRed.
  ///
  /// In en, this message translates to:
  /// **'Green to white to red'**
  String get cfScaleGreenWhiteRed;

  /// No description provided for @cfScaleRedYellowGreen.
  ///
  /// In en, this message translates to:
  /// **'Red to yellow to green'**
  String get cfScaleRedYellowGreen;

  /// No description provided for @cfScaleGreenYellowRed.
  ///
  /// In en, this message translates to:
  /// **'Green to yellow to red'**
  String get cfScaleGreenYellowRed;

  /// No description provided for @cfScaleWhiteBlue.
  ///
  /// In en, this message translates to:
  /// **'White to blue'**
  String get cfScaleWhiteBlue;

  /// No description provided for @cfScaleBlueWhite.
  ///
  /// In en, this message translates to:
  /// **'Blue to white'**
  String get cfScaleBlueWhite;

  /// No description provided for @cfScaleYellowGreen.
  ///
  /// In en, this message translates to:
  /// **'Yellow to green'**
  String get cfScaleYellowGreen;

  /// No description provided for @cfScaleAccent.
  ///
  /// In en, this message translates to:
  /// **'Theme accent 1 light to dark'**
  String get cfScaleAccent;

  /// No description provided for @cfMinpoint.
  ///
  /// In en, this message translates to:
  /// **'Minpoint'**
  String get cfMinpoint;

  /// No description provided for @cfMidpoint.
  ///
  /// In en, this message translates to:
  /// **'Midpoint'**
  String get cfMidpoint;

  /// No description provided for @cfMaxpoint.
  ///
  /// In en, this message translates to:
  /// **'Maxpoint'**
  String get cfMaxpoint;

  /// No description provided for @cfPointColor.
  ///
  /// In en, this message translates to:
  /// **'{point} color'**
  String cfPointColor(String point);

  /// No description provided for @cfBarColors.
  ///
  /// In en, this message translates to:
  /// **'Bar colors'**
  String get cfBarColors;

  /// No description provided for @cfBarPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get cfBarPositive;

  /// No description provided for @cfBarNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get cfBarNegative;

  /// No description provided for @cfBarGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient fill'**
  String get cfBarGradient;

  /// No description provided for @cfBarAxis.
  ///
  /// In en, this message translates to:
  /// **'Axis'**
  String get cfBarAxis;

  /// No description provided for @cfAxisAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get cfAxisAuto;

  /// No description provided for @cfAxisMiddle.
  ///
  /// In en, this message translates to:
  /// **'Cell midpoint'**
  String get cfAxisMiddle;

  /// No description provided for @cfAxisNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get cfAxisNone;

  /// No description provided for @cfBarDirection.
  ///
  /// In en, this message translates to:
  /// **'Bar direction'**
  String get cfBarDirection;

  /// No description provided for @cfDirectionContext.
  ///
  /// In en, this message translates to:
  /// **'Sheet direction'**
  String get cfDirectionContext;

  /// No description provided for @cfDirectionLtr.
  ///
  /// In en, this message translates to:
  /// **'Left to right'**
  String get cfDirectionLtr;

  /// No description provided for @cfDirectionRtl.
  ///
  /// In en, this message translates to:
  /// **'Right to left'**
  String get cfDirectionRtl;

  /// No description provided for @cfShowValue.
  ///
  /// In en, this message translates to:
  /// **'Show cell value'**
  String get cfShowValue;

  /// No description provided for @cfIconStyle.
  ///
  /// In en, this message translates to:
  /// **'Icon style'**
  String get cfIconStyle;

  /// No description provided for @cfIconOtherwise.
  ///
  /// In en, this message translates to:
  /// **'Otherwise'**
  String get cfIconOtherwise;

  /// No description provided for @cfIconReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse icon order'**
  String get cfIconReverse;

  /// No description provided for @cfIconArrows.
  ///
  /// In en, this message translates to:
  /// **'{n} arrows'**
  String cfIconArrows(int n);

  /// No description provided for @cfIconArrowsGray.
  ///
  /// In en, this message translates to:
  /// **'{n} arrows (gray)'**
  String cfIconArrowsGray(int n);

  /// No description provided for @cfIconTriangles.
  ///
  /// In en, this message translates to:
  /// **'{n} triangles'**
  String cfIconTriangles(int n);

  /// No description provided for @cfIconTrafficLights.
  ///
  /// In en, this message translates to:
  /// **'{n} traffic lights'**
  String cfIconTrafficLights(int n);

  /// No description provided for @cfIconSigns.
  ///
  /// In en, this message translates to:
  /// **'{n} signs'**
  String cfIconSigns(int n);

  /// No description provided for @cfIconSymbols.
  ///
  /// In en, this message translates to:
  /// **'{n} symbols'**
  String cfIconSymbols(int n);

  /// No description provided for @cfIconFlags.
  ///
  /// In en, this message translates to:
  /// **'{n} flags'**
  String cfIconFlags(int n);

  /// No description provided for @cfIconStars.
  ///
  /// In en, this message translates to:
  /// **'{n} stars'**
  String cfIconStars(int n);

  /// No description provided for @cfIconRatings.
  ///
  /// In en, this message translates to:
  /// **'{n} ratings'**
  String cfIconRatings(int n);

  /// No description provided for @cfIconQuarters.
  ///
  /// In en, this message translates to:
  /// **'{n} quarters'**
  String cfIconQuarters(int n);

  /// No description provided for @cfErrorValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value.'**
  String get cfErrorValue;

  /// No description provided for @cfErrorFormula.
  ///
  /// In en, this message translates to:
  /// **'Invalid formula: {message}'**
  String cfErrorFormula(String message);

  /// No description provided for @cfErrorNoFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one format.'**
  String get cfErrorNoFormat;

  /// No description provided for @cfEnableRule.
  ///
  /// In en, this message translates to:
  /// **'Enable rule'**
  String get cfEnableRule;

  /// No description provided for @cfDisableRule.
  ///
  /// In en, this message translates to:
  /// **'Disable rule'**
  String get cfDisableRule;

  /// No description provided for @cfDeleteRule.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get cfDeleteRule;

  /// No description provided for @cfRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter to edit, Alt+arrows to move, Delete to remove'**
  String get cfRuleHint;

  /// No description provided for @rangeInputEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a range'**
  String get rangeInputEmpty;

  /// No description provided for @rangeInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid range'**
  String get rangeInputInvalid;

  /// No description provided for @rangeInputPick.
  ///
  /// In en, this message translates to:
  /// **'Select a data range on the grid'**
  String get rangeInputPick;

  /// No description provided for @rangeInputPicking.
  ///
  /// In en, this message translates to:
  /// **'Select cells on the grid; the range follows your selection.'**
  String get rangeInputPicking;

  /// No description provided for @addRowsButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addRowsButton;

  /// No description provided for @addRowsSuffix.
  ///
  /// In en, this message translates to:
  /// **'more rows at bottom'**
  String get addRowsSuffix;

  /// No description provided for @alignBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get alignBottom;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get alignLeft;

  /// No description provided for @alignMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get alignMiddle;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get alignRight;

  /// No description provided for @alignTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get alignTop;

  /// No description provided for @badgeCommentOnly.
  ///
  /// In en, this message translates to:
  /// **'Comment only'**
  String get badgeCommentOnly;

  /// No description provided for @badgeViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get badgeViewOnly;

  /// No description provided for @borderAll.
  ///
  /// In en, this message translates to:
  /// **'All borders'**
  String get borderAll;

  /// No description provided for @borderBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom border'**
  String get borderBottom;

  /// No description provided for @borderClear.
  ///
  /// In en, this message translates to:
  /// **'Clear borders'**
  String get borderClear;

  /// No description provided for @borderColor.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get borderColor;

  /// No description provided for @borderHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal borders'**
  String get borderHorizontal;

  /// No description provided for @borderInner.
  ///
  /// In en, this message translates to:
  /// **'Inner borders'**
  String get borderInner;

  /// No description provided for @borderLeft.
  ///
  /// In en, this message translates to:
  /// **'Left border'**
  String get borderLeft;

  /// No description provided for @borderOuter.
  ///
  /// In en, this message translates to:
  /// **'Outer borders'**
  String get borderOuter;

  /// No description provided for @borderRight.
  ///
  /// In en, this message translates to:
  /// **'Right border'**
  String get borderRight;

  /// No description provided for @borderStyleDashed.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get borderStyleDashed;

  /// No description provided for @borderStyleDotted.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get borderStyleDotted;

  /// No description provided for @borderStyleDouble.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get borderStyleDouble;

  /// No description provided for @borderStyleMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get borderStyleMedium;

  /// No description provided for @borderStyleThick.
  ///
  /// In en, this message translates to:
  /// **'Thick'**
  String get borderStyleThick;

  /// No description provided for @borderStyleThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get borderStyleThin;

  /// No description provided for @borderTop.
  ///
  /// In en, this message translates to:
  /// **'Top border'**
  String get borderTop;

  /// No description provided for @borderVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical borders'**
  String get borderVertical;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get categoryData;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get categoryEditing;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get categoryFile;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get categoryFormatting;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Formulas'**
  String get categoryFormulas;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get categoryInsert;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get categoryNavigation;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Rows & columns'**
  String get categoryRowsColumns;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get categorySheets;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get categoryView;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Analyze data'**
  String get cmdAiAnalyze;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Explain formula'**
  String get cmdAiExplainFormula;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill with AI'**
  String get cmdAiFillRange;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Suggest a formula'**
  String get cmdAiSuggestFormula;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Alternating colors'**
  String get cmdBandingOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get cmdCellCancel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Commit cell'**
  String get cmdCellCommit;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Get link to this range'**
  String get cmdCellCopyLink;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Edit cell'**
  String get cmdCellEdit;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert date'**
  String get cmdCellInsertDate;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert date and time'**
  String get cmdCellInsertDateTime;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert line break'**
  String get cmdCellInsertNewline;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert time'**
  String get cmdCellInsertTime;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Set cell input'**
  String get cmdCellSetInput;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Enter in all selected cells'**
  String get cmdCellSetInputForSelection;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Toggle Enter/Edit mode'**
  String get cmdCellToggleEditMode;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Copy range'**
  String get cmdCellsCopyRange;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete cells and shift left'**
  String get cmdCellsDeleteShiftLeft;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete cells and shift up'**
  String get cmdCellsDeleteShiftUp;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert cells and shift down'**
  String get cmdCellsInsertShiftDown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert cells and shift right'**
  String get cmdCellsInsertShiftRight;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move range'**
  String get cmdCellsMoveRange;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Conditional formatting'**
  String get cmdCfOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get cmdChartInsert;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get cmdCleanupOpenRemoveDuplicates;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Cleanup suggestions'**
  String get cmdCleanupOpenSuggestions;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Trim whitespace'**
  String get cmdCleanupTrimWhitespace;

  /// No description provided for @cmdClearColumns.
  ///
  /// In en, this message translates to:
  /// **'Clear {cols}'**
  String cmdClearColumns(String cols);

  /// No description provided for @cmdClearRows.
  ///
  /// In en, this message translates to:
  /// **'Clear {rows}'**
  String cmdClearRows(String rows);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete columns'**
  String get cmdColsDelete;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Hide columns'**
  String get cmdColsHide;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert columns…'**
  String get cmdColsInsertDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert column left'**
  String get cmdColsInsertLeft;

  /// No description provided for @cmdColsInsertLeftN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Insert 1 column left} other{Insert {n} columns left}}'**
  String cmdColsInsertLeftN(int n);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert column right'**
  String get cmdColsInsertRight;

  /// No description provided for @cmdColsInsertRightN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Insert 1 column right} other{Insert {n} columns right}}'**
  String cmdColsInsertRightN(int n);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move columns'**
  String get cmdColsMove;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move column left'**
  String get cmdColsMoveLeft;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move column right'**
  String get cmdColsMoveRight;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Resize columns'**
  String get cmdColsResize;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Resize columns…'**
  String get cmdColsResizeDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Unhide columns'**
  String get cmdColsUnhide;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Show all comments'**
  String get cmdCommentsOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Open context menu'**
  String get cmdContextMenuOpen;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Column stats'**
  String get cmdDataColumnStats;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Data extraction'**
  String get cmdDataExtraction;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Advanced range sorting options'**
  String get cmdDataOpenSortDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Randomize range'**
  String get cmdDataRandomizeRange;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Sort range'**
  String get cmdDataSortRange;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Sort sheet'**
  String get cmdDataSortSheet;

  /// No description provided for @cmdDataSortSheetBy.
  ///
  /// In en, this message translates to:
  /// **'Sort sheet by column {col}'**
  String cmdDataSortSheetBy(String col);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Split text to columns'**
  String get cmdDataSplitTextToColumns;

  /// No description provided for @cmdDeleteColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete {cols}'**
  String cmdDeleteColumnsLabel(String cols);

  /// No description provided for @cmdDeleteRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete {rows}'**
  String cmdDeleteRowsLabel(String rows);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get cmdDrawingInsert;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Open dropdown'**
  String get cmdDvOpenDropdown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Data validation'**
  String get cmdDvOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Toggle checkboxes'**
  String get cmdDvToggleCheckbox;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cmdEditClearAll;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete values'**
  String get cmdEditClearValues;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cmdEditCopy;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cmdEditCut;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get cmdEditPaste;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Paste special'**
  String get cmdEditPasteSpecial;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Paste special…'**
  String get cmdEditPasteSpecialDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get cmdEditRedo;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Repeat last action'**
  String get cmdEditRepeatLast;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get cmdEditUndo;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Undo history…'**
  String get cmdEditUndoHistory;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get cmdExploreToggle;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get cmdFileDownload;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get cmdFileImport;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cmdFileSaveNoop;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get cmdFileSettings;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill down to the data'**
  String get cmdFillAutoFillDown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill down'**
  String get cmdFillDown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill right'**
  String get cmdFillRight;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill selection'**
  String get cmdFillSelection;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill series'**
  String get cmdFillSeries;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Filter by cell value'**
  String get cmdFilterByCellValue;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Create a filter'**
  String get cmdFilterToggle;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get cmdFilterViewActivate;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Create filter view'**
  String get cmdFilterViewCreate;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get cmdFindOpen;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get cmdFindOpenReplace;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fit to data'**
  String get cmdFitToData;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Paint format'**
  String get cmdFormatApplyPaintFormat;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get cmdFormatBold;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Borders'**
  String get cmdFormatBorders;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get cmdFormatClear;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Convert to table'**
  String get cmdFormatConvertToTable;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Decrease decimal places'**
  String get cmdFormatDecreaseDecimals;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get cmdFormatDecreaseFontSize;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get cmdFormatFillColor;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get cmdFormatFontFamily;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get cmdFormatFontSize;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Horizontal align'**
  String get cmdFormatHAlign;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Increase decimal places'**
  String get cmdFormatIncreaseDecimals;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get cmdFormatIncreaseFontSize;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get cmdFormatItalic;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Merge cells'**
  String get cmdFormatMerge;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get cmdFormatNumberFormat;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Custom currency'**
  String get cmdFormatOpenCustomCurrency;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Custom date and time'**
  String get cmdFormatOpenCustomDateTime;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Custom number format'**
  String get cmdFormatOpenCustomNumberFormat;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Paint format'**
  String get cmdFormatPaintFormat;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Text rotation'**
  String get cmdFormatRotation;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get cmdFormatStrikethrough;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get cmdFormatTextColor;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get cmdFormatUnderline;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Unmerge'**
  String get cmdFormatUnmerge;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Vertical align'**
  String get cmdFormatVAlign;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Text wrapping'**
  String get cmdFormatWrap;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert suggestion'**
  String get cmdFormulaAcceptCompletion;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Expand formula bar'**
  String get cmdFormulaBarToggleExpanded;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Toggle absolute reference'**
  String get cmdFormulaCycleReferenceType;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Dismiss suggestions'**
  String get cmdFormulaDismissCompletion;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move pointed reference'**
  String get cmdFormulaMovePoint;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Next suggestion'**
  String get cmdFormulaNextCompletion;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Toggle ARRAYFORMULA'**
  String get cmdFormulaToggleArrayFormula;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Expand formula help'**
  String get cmdFormulaToggleHelpCard;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Show formula help'**
  String get cmdFormulaToggleHelpCardVisible;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Collapse all groups'**
  String get cmdGroupCollapseAll;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Group columns'**
  String get cmdGroupColumns;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Expand all groups'**
  String get cmdGroupExpandAll;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Group rows'**
  String get cmdGroupRows;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Function list'**
  String get cmdHelpFunctionList;

  /// No description provided for @cmdHideColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide {cols}'**
  String cmdHideColumnsLabel(String cols);

  /// No description provided for @cmdHideRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide {rows}'**
  String cmdHideRowsLabel(String rows);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Name current version'**
  String get cmdHistoryNameCurrentVersion;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'See version history'**
  String get cmdHistoryOpen;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Show edit history'**
  String get cmdHistoryShowCellHistory;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert image in cell'**
  String get cmdImageInsertInCell;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert image over cells'**
  String get cmdImageInsertOverCells;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Checkbox'**
  String get cmdInsertCheckbox;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Dropdown'**
  String get cmdInsertDropdown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get cmdInsertEmoji;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert function'**
  String get cmdInsertFunction;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get cmdInsertLink;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Pivot table'**
  String get cmdInsertPivotTable;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert rows for the pivot table'**
  String get cmdPivotExpandGrid;

  /// No description provided for @pivotExpandGrid.
  ///
  /// In en, this message translates to:
  /// **'Insert rows'**
  String get pivotExpandGrid;

  /// No description provided for @pivotCondBlank.
  ///
  /// In en, this message translates to:
  /// **'Is empty'**
  String get pivotCondBlank;

  /// No description provided for @pivotCondNotBlank.
  ///
  /// In en, this message translates to:
  /// **'Is not empty'**
  String get pivotCondNotBlank;

  /// No description provided for @pivotCondTextContains.
  ///
  /// In en, this message translates to:
  /// **'Text contains'**
  String get pivotCondTextContains;

  /// No description provided for @pivotCondTextNotContains.
  ///
  /// In en, this message translates to:
  /// **'Text does not contain'**
  String get pivotCondTextNotContains;

  /// No description provided for @pivotCondTextStartsWith.
  ///
  /// In en, this message translates to:
  /// **'Text starts with'**
  String get pivotCondTextStartsWith;

  /// No description provided for @pivotCondTextEndsWith.
  ///
  /// In en, this message translates to:
  /// **'Text ends with'**
  String get pivotCondTextEndsWith;

  /// No description provided for @pivotCondTextEq.
  ///
  /// In en, this message translates to:
  /// **'Text is exactly'**
  String get pivotCondTextEq;

  /// No description provided for @pivotCondDateEq.
  ///
  /// In en, this message translates to:
  /// **'Date is'**
  String get pivotCondDateEq;

  /// No description provided for @pivotCondDateBefore.
  ///
  /// In en, this message translates to:
  /// **'Date is before'**
  String get pivotCondDateBefore;

  /// No description provided for @pivotCondDateAfter.
  ///
  /// In en, this message translates to:
  /// **'Date is after'**
  String get pivotCondDateAfter;

  /// No description provided for @pivotCondNumberGreater.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get pivotCondNumberGreater;

  /// No description provided for @pivotCondNumberGreaterEq.
  ///
  /// In en, this message translates to:
  /// **'Greater than or equal to'**
  String get pivotCondNumberGreaterEq;

  /// No description provided for @pivotCondNumberLess.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get pivotCondNumberLess;

  /// No description provided for @pivotCondNumberLessEq.
  ///
  /// In en, this message translates to:
  /// **'Less than or equal to'**
  String get pivotCondNumberLessEq;

  /// No description provided for @pivotCondNumberEq.
  ///
  /// In en, this message translates to:
  /// **'Is equal to'**
  String get pivotCondNumberEq;

  /// No description provided for @pivotCondNumberNotEq.
  ///
  /// In en, this message translates to:
  /// **'Is not equal to'**
  String get pivotCondNumberNotEq;

  /// No description provided for @pivotCondNumberBetween.
  ///
  /// In en, this message translates to:
  /// **'Is between'**
  String get pivotCondNumberBetween;

  /// No description provided for @pivotCondNumberNotBetween.
  ///
  /// In en, this message translates to:
  /// **'Is not between'**
  String get pivotCondNumberNotBetween;

  /// No description provided for @pivotCondCustomFormula.
  ///
  /// In en, this message translates to:
  /// **'Custom formula is'**
  String get pivotCondCustomFormula;

  /// No description provided for @pivotCondAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get pivotCondAnd;

  /// No description provided for @pivotApply.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get pivotApply;

  /// No description provided for @pivotCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pivotCancel;

  /// No description provided for @pivotAddCalculatedField.
  ///
  /// In en, this message translates to:
  /// **'Add calculated field'**
  String get pivotAddCalculatedField;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Edit pivot table'**
  String get cmdPivotOpenEditor;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Edit pivot table'**
  String get cmdPivotUpdate;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete pivot table'**
  String get cmdPivotDelete;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Refresh pivot table'**
  String get cmdPivotRefresh;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get cmdPivotDrillDown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Create pivot group'**
  String get cmdPivotCreateGroup;

  /// No description provided for @pivotReadOnlyToast.
  ///
  /// In en, this message translates to:
  /// **'You can\'t edit a pivot table\'s output. Use the pivot table editor.'**
  String get pivotReadOnlyToast;

  /// No description provided for @reasonNoPivot.
  ///
  /// In en, this message translates to:
  /// **'Select a cell in a pivot table'**
  String get reasonNoPivot;

  /// No description provided for @pivotNoData.
  ///
  /// In en, this message translates to:
  /// **'Select a data range for the pivot table'**
  String get pivotNoData;

  /// No description provided for @pivotNotAValueCell.
  ///
  /// In en, this message translates to:
  /// **'Select a value cell of the pivot table'**
  String get pivotNotAValueCell;

  /// No description provided for @pivotInvalidGroup.
  ///
  /// In en, this message translates to:
  /// **'The grouping is not valid'**
  String get pivotInvalidGroup;

  /// No description provided for @pivotFieldNotInRows.
  ///
  /// In en, this message translates to:
  /// **'Add the field to Rows or Columns first'**
  String get pivotFieldNotInRows;

  /// Name of new pivot sheets, followed by a number ("Pivot table 1").
  ///
  /// In en, this message translates to:
  /// **'Pivot table'**
  String get pivotSheetPrefix;

  /// Name of drill-down sheets, followed by a number ("Details 1").
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get pivotDetailsSheetPrefix;

  /// No description provided for @pivotDrillDownConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Show {count} rows?'**
  String pivotDrillDownConfirmTitle(int count);

  /// No description provided for @pivotDrillDownConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'A new sheet with every source row of this value will be created. Large sheets can be slow.'**
  String get pivotDrillDownConfirmBody;

  /// No description provided for @pivotEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get pivotEditButton;

  /// No description provided for @pivotPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Pivot table editor'**
  String get pivotPanelTitle;

  /// No description provided for @pivotPanelEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a cell in a pivot table to edit it, or insert a new pivot table.'**
  String get pivotPanelEmpty;

  /// No description provided for @pivotPanelOptions.
  ///
  /// In en, this message translates to:
  /// **'Pivot table options'**
  String get pivotPanelOptions;

  /// No description provided for @pivotRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get pivotRange;

  /// No description provided for @pivotRangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid range, e.g. Sheet1!A1:F100'**
  String get pivotRangeInvalid;

  /// No description provided for @pivotSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get pivotSuggested;

  /// No description provided for @pivotSuggestionBy.
  ///
  /// In en, this message translates to:
  /// **'{value} by {field}'**
  String pivotSuggestionBy(String value, String field);

  /// No description provided for @pivotSuggestionCount.
  ///
  /// In en, this message translates to:
  /// **'Count of {field}'**
  String pivotSuggestionCount(String field);

  /// No description provided for @pivotRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get pivotRows;

  /// No description provided for @pivotColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get pivotColumns;

  /// No description provided for @pivotValues.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get pivotValues;

  /// No description provided for @pivotFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get pivotFilters;

  /// No description provided for @pivotAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get pivotAdd;

  /// No description provided for @pivotAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add field to {area}'**
  String pivotAddTo(String area);

  /// No description provided for @pivotSearchFields.
  ///
  /// In en, this message translates to:
  /// **'Search fields'**
  String get pivotSearchFields;

  /// No description provided for @pivotNoFields.
  ///
  /// In en, this message translates to:
  /// **'No matching fields'**
  String get pivotNoFields;

  /// No description provided for @pivotCalculatedField.
  ///
  /// In en, this message translates to:
  /// **'Calculated field'**
  String get pivotCalculatedField;

  /// No description provided for @pivotAreaEmpty.
  ///
  /// In en, this message translates to:
  /// **'Drop a field here or use Add'**
  String get pivotAreaEmpty;

  /// No description provided for @pivotOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get pivotOrder;

  /// No description provided for @pivotAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get pivotAscending;

  /// No description provided for @pivotDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get pivotDescending;

  /// No description provided for @pivotSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get pivotSortBy;

  /// No description provided for @pivotShowTotals.
  ///
  /// In en, this message translates to:
  /// **'Show totals'**
  String get pivotShowTotals;

  /// No description provided for @pivotRepeatLabels.
  ///
  /// In en, this message translates to:
  /// **'Repeat row labels'**
  String get pivotRepeatLabels;

  /// No description provided for @pivotSummarizeBy.
  ///
  /// In en, this message translates to:
  /// **'Summarize by'**
  String get pivotSummarizeBy;

  /// No description provided for @pivotSummarizeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get pivotSummarizeCustom;

  /// No description provided for @pivotShowAs.
  ///
  /// In en, this message translates to:
  /// **'Show as'**
  String get pivotShowAs;

  /// No description provided for @pivotShowAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get pivotShowAsDefault;

  /// No description provided for @pivotShowAsRow.
  ///
  /// In en, this message translates to:
  /// **'% of row'**
  String get pivotShowAsRow;

  /// No description provided for @pivotShowAsColumn.
  ///
  /// In en, this message translates to:
  /// **'% of column'**
  String get pivotShowAsColumn;

  /// No description provided for @pivotShowAsGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'% of grand total'**
  String get pivotShowAsGrandTotal;

  /// No description provided for @pivotDisplayValuesAs.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get pivotDisplayValuesAs;

  /// No description provided for @pivotValuesAsColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get pivotValuesAsColumns;

  /// No description provided for @pivotValuesAsRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get pivotValuesAsRows;

  /// No description provided for @pivotFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pivotFilterStatus;

  /// No description provided for @pivotFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all items'**
  String get pivotFilterAll;

  /// No description provided for @pivotFilterSome.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} items'**
  String pivotFilterSome(int shown, int total);

  /// No description provided for @pivotFilterCondition.
  ///
  /// In en, this message translates to:
  /// **'Filtered by condition'**
  String get pivotFilterCondition;

  /// No description provided for @pivotFilterByValues.
  ///
  /// In en, this message translates to:
  /// **'Filter by values'**
  String get pivotFilterByValues;

  /// No description provided for @pivotFilterByCondition.
  ///
  /// In en, this message translates to:
  /// **'Filter by condition'**
  String get pivotFilterByCondition;

  /// No description provided for @pivotSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get pivotSelectAll;

  /// No description provided for @pivotClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pivotClearAll;

  /// No description provided for @pivotBlanks.
  ///
  /// In en, this message translates to:
  /// **'(Blanks)'**
  String get pivotBlanks;

  /// No description provided for @pivotConditionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pivotConditionNone;

  /// No description provided for @pivotConditionValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get pivotConditionValue;

  /// No description provided for @pivotFilterTooMany.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} values — refine your search'**
  String pivotFilterTooMany(int shown, int total);

  /// No description provided for @pivotMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {area}'**
  String pivotMoveTo(String area);

  /// No description provided for @pivotMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get pivotMoveUp;

  /// No description provided for @pivotMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get pivotMoveDown;

  /// No description provided for @pivotRemoveField.
  ///
  /// In en, this message translates to:
  /// **'Remove field'**
  String get pivotRemoveField;

  /// No description provided for @pivotRenameField.
  ///
  /// In en, this message translates to:
  /// **'Rename…'**
  String get pivotRenameField;

  /// No description provided for @pivotRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename value'**
  String get pivotRenameTitle;

  /// No description provided for @pivotRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pivotRenameLabel;

  /// No description provided for @pivotFieldOptions.
  ///
  /// In en, this message translates to:
  /// **'Options of {field}'**
  String pivotFieldOptions(String field);

  /// No description provided for @pivotDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag {field} to another area'**
  String pivotDragHandle(String field);

  /// No description provided for @pivotFieldMissing.
  ///
  /// In en, this message translates to:
  /// **'This field no longer exists in the source range'**
  String get pivotFieldMissing;

  /// No description provided for @pivotDateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create pivot date group'**
  String get pivotDateGroup;

  /// No description provided for @pivotHistogramGroup.
  ///
  /// In en, this message translates to:
  /// **'Create pivot group rule…'**
  String get pivotHistogramGroup;

  /// No description provided for @pivotRemoveGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove grouping'**
  String get pivotRemoveGroup;

  /// No description provided for @pivotGroupedBy.
  ///
  /// In en, this message translates to:
  /// **'Grouped: {group}'**
  String pivotGroupedBy(String group);

  /// No description provided for @pivotHistogramLabel.
  ///
  /// In en, this message translates to:
  /// **'Intervals of {size}'**
  String pivotHistogramLabel(String size);

  /// No description provided for @pivotManualGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String pivotManualGroupLabel(int count);

  /// No description provided for @pivotHistogramTitle.
  ///
  /// In en, this message translates to:
  /// **'Create pivot group rule'**
  String get pivotHistogramTitle;

  /// No description provided for @pivotHistogramMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum value'**
  String get pivotHistogramMin;

  /// No description provided for @pivotHistogramMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum value'**
  String get pivotHistogramMax;

  /// No description provided for @pivotHistogramSize.
  ///
  /// In en, this message translates to:
  /// **'Interval size'**
  String get pivotHistogramSize;

  /// No description provided for @pivotHistogramInvalidSize.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than 0'**
  String get pivotHistogramInvalidSize;

  /// No description provided for @pivotHistogramInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number or leave it empty'**
  String get pivotHistogramInvalidNumber;

  /// No description provided for @pivotFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get pivotFormula;

  /// No description provided for @pivotFormulaHint.
  ///
  /// In en, this message translates to:
  /// **'Use source headers as names, e.g. =\'Unit price\' * Quantity'**
  String get pivotFormulaHint;

  /// No description provided for @pivotValueName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pivotValueName;

  /// No description provided for @pivotDateSecond.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get pivotDateSecond;

  /// No description provided for @pivotDateMinute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get pivotDateMinute;

  /// No description provided for @pivotDateHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get pivotDateHour;

  /// No description provided for @pivotDateHourMinute.
  ///
  /// In en, this message translates to:
  /// **'Hour-Minute'**
  String get pivotDateHourMinute;

  /// No description provided for @pivotDateHourMinuteAmPm.
  ///
  /// In en, this message translates to:
  /// **'Hour-Minute (AM/PM)'**
  String get pivotDateHourMinuteAmPm;

  /// No description provided for @pivotDateDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of the week'**
  String get pivotDateDayOfWeek;

  /// No description provided for @pivotDateDayOfYear.
  ///
  /// In en, this message translates to:
  /// **'Day of the year'**
  String get pivotDateDayOfYear;

  /// No description provided for @pivotDateDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get pivotDateDayOfMonth;

  /// No description provided for @pivotDateDayMonth.
  ///
  /// In en, this message translates to:
  /// **'Day-Month'**
  String get pivotDateDayMonth;

  /// No description provided for @pivotDateMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get pivotDateMonth;

  /// No description provided for @pivotDateQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get pivotDateQuarter;

  /// No description provided for @pivotDateYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get pivotDateYear;

  /// No description provided for @pivotDateYearMonth.
  ///
  /// In en, this message translates to:
  /// **'Year-Month'**
  String get pivotDateYearMonth;

  /// No description provided for @pivotDateYearQuarter.
  ///
  /// In en, this message translates to:
  /// **'Year-Quarter'**
  String get pivotDateYearQuarter;

  /// No description provided for @pivotDateYearMonthDay.
  ///
  /// In en, this message translates to:
  /// **'Year-Month-Day'**
  String get pivotDateYearMonthDay;

  /// No description provided for @pivotSelectBlocking.
  ///
  /// In en, this message translates to:
  /// **'Select blocking cells'**
  String get pivotSelectBlocking;

  /// No description provided for @pivotStale.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get pivotStale;

  /// No description provided for @dialogCreatePivotTitle.
  ///
  /// In en, this message translates to:
  /// **'Create pivot table'**
  String get dialogCreatePivotTitle;

  /// No description provided for @dialogCreatePivotRange.
  ///
  /// In en, this message translates to:
  /// **'Data range'**
  String get dialogCreatePivotRange;

  /// No description provided for @dialogCreatePivotInsertTo.
  ///
  /// In en, this message translates to:
  /// **'Insert to'**
  String get dialogCreatePivotInsertTo;

  /// No description provided for @dialogCreatePivotNewSheet.
  ///
  /// In en, this message translates to:
  /// **'New sheet'**
  String get dialogCreatePivotNewSheet;

  /// No description provided for @dialogCreatePivotExistingSheet.
  ///
  /// In en, this message translates to:
  /// **'Existing sheet'**
  String get dialogCreatePivotExistingSheet;

  /// No description provided for @dialogCreatePivotLocation.
  ///
  /// In en, this message translates to:
  /// **'Location (existing sheet)'**
  String get dialogCreatePivotLocation;

  /// No description provided for @dialogCreatePivotCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get dialogCreatePivotCreate;

  /// No description provided for @dialogCreatePivotInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid range, e.g. Sheet1!A1:F100'**
  String get dialogCreatePivotInvalidRange;

  /// No description provided for @dialogCreatePivotInvalidLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter a single cell, e.g. Sheet2!H1'**
  String get dialogCreatePivotInvalidLocation;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Smart chips'**
  String get cmdInsertSmartChip;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get cmdLinkOpen;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get cmdLinkRemove;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Import macro'**
  String get cmdMacroImport;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Manage macros'**
  String get cmdMacroManage;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Record macro'**
  String get cmdMacroRecord;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get cmdModeEditing;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get cmdModeViewing;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Named functions'**
  String get cmdNamedFunctionsOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Create named range'**
  String get cmdNamedRangesCreateFromSelection;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Named ranges'**
  String get cmdNamedRangesOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move down (Enter)'**
  String get cmdNavEnter;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Go to range'**
  String get cmdNavGoTo;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move active cell'**
  String get cmdNavMove;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Page up/down'**
  String get cmdNavPage;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Page left/right'**
  String get cmdNavPageHorizontal;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Go to end of row'**
  String get cmdNavRowEnd;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Go to start of row'**
  String get cmdNavRowStart;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Scroll to active cell'**
  String get cmdNavScrollToActive;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Go to last used cell'**
  String get cmdNavSheetEnd;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Go to A1'**
  String get cmdNavSheetStart;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move right (Tab)'**
  String get cmdNavTab;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Clear notes'**
  String get cmdNotesClear;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get cmdNotesInsert;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Notification rules'**
  String get cmdNotificationsOpenRules;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Comment notifications'**
  String get cmdNotificationsOpenSettings;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get cmdPrintOpen;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Protect sheets and ranges'**
  String get cmdProtectOpenPanel;

  /// No description provided for @cmdResizeColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Resize {cols}'**
  String cmdResizeColumnsLabel(String cols);

  /// No description provided for @cmdResizeRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'Resize {rows}'**
  String cmdResizeRowsLabel(String rows);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Add more rows'**
  String get cmdRowsAddMore;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete rows'**
  String get cmdRowsDelete;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Hide rows'**
  String get cmdRowsHide;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert row above'**
  String get cmdRowsInsertAbove;

  /// No description provided for @cmdRowsInsertAboveN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Insert 1 row above} other{Insert {n} rows above}}'**
  String cmdRowsInsertAboveN(int n);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert row below'**
  String get cmdRowsInsertBelow;

  /// No description provided for @cmdRowsInsertBelowN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Insert 1 row below} other{Insert {n} rows below}}'**
  String cmdRowsInsertBelowN(int n);

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert rows…'**
  String get cmdRowsInsertDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move rows'**
  String get cmdRowsMove;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move row down'**
  String get cmdRowsMoveDown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move row up'**
  String get cmdRowsMoveUp;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Resize rows'**
  String get cmdRowsResize;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Resize rows…'**
  String get cmdRowsResizeDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Unhide rows'**
  String get cmdRowsUnhide;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Open script editor'**
  String get cmdScriptOpenEditor;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Executions'**
  String get cmdScriptOpenExecutions;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get cmdScriptOpenTriggers;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cmdSelectAll;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Select columns'**
  String get cmdSelectColumns;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Select data region'**
  String get cmdSelectDataRegion;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Select range'**
  String get cmdSelectRange;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Select rows'**
  String get cmdSelectRows;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Go to sheet'**
  String get cmdSheetActivate;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Next sheet'**
  String get cmdSheetActivateNext;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Previous sheet'**
  String get cmdSheetActivatePrevious;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Add sheet'**
  String get cmdSheetAdd;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Existing spreadsheet…'**
  String get cmdSheetCopyToExisting;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'New spreadsheet'**
  String get cmdSheetCopyToNew;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cmdSheetDelete;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get cmdSheetDuplicate;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Hide sheet'**
  String get cmdSheetHide;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move sheet'**
  String get cmdSheetMove;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get cmdSheetMoveLeft;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get cmdSheetMoveRight;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get cmdSheetRename;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get cmdSheetSetColor;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Right-to-left'**
  String get cmdSheetSetRightToLeft;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Unhide sheet'**
  String get cmdSheetUnhide;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Add a slicer'**
  String get cmdSlicerAdd;

  /// No description provided for @slicerUntitled.
  ///
  /// In en, this message translates to:
  /// **'Slicer'**
  String get slicerUntitled;

  /// No description provided for @slicerAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all'**
  String get slicerAll;

  /// No description provided for @slicerByCondition.
  ///
  /// In en, this message translates to:
  /// **'Filtered by condition'**
  String get slicerByCondition;

  /// No description provided for @slicerHiddenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 value hidden} other{{count} values hidden}}'**
  String slicerHiddenCount(int count);

  /// No description provided for @slicerLocal.
  ///
  /// In en, this message translates to:
  /// **'{summary} (only you)'**
  String slicerLocal(String summary);

  /// No description provided for @slicerOpen.
  ///
  /// In en, this message translates to:
  /// **'Filter values'**
  String get slicerOpen;

  /// No description provided for @slicerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search values'**
  String get slicerSearch;

  /// No description provided for @slicerSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get slicerSelectAll;

  /// No description provided for @slicerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get slicerClear;

  /// No description provided for @slicerBlanks.
  ///
  /// In en, this message translates to:
  /// **'(Blanks)'**
  String get slicerBlanks;

  /// No description provided for @slicerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get slicerCancel;

  /// No description provided for @slicerOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get slicerOk;

  /// No description provided for @slicerNone.
  ///
  /// In en, this message translates to:
  /// **'Select a slicer to edit it.'**
  String get slicerNone;

  /// No description provided for @slicerPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Slicer'**
  String get slicerPanelTitle;

  /// No description provided for @slicerDataRange.
  ///
  /// In en, this message translates to:
  /// **'Data range'**
  String get slicerDataRange;

  /// No description provided for @slicerColumn.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get slicerColumn;

  /// No description provided for @slicerApplyToPivots.
  ///
  /// In en, this message translates to:
  /// **'Apply to pivot tables'**
  String get slicerApplyToPivots;

  /// No description provided for @slicerTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get slicerTitle;

  /// No description provided for @slicerTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Column header'**
  String get slicerTitlePlaceholder;

  /// No description provided for @slicerStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get slicerStyle;

  /// No description provided for @slicerBackground.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get slicerBackground;

  /// No description provided for @slicerTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get slicerTextColor;

  /// No description provided for @slicerSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set current filters as default'**
  String get slicerSetDefault;

  /// No description provided for @slicerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset filter'**
  String get slicerReset;

  /// No description provided for @slicerNeedsData.
  ///
  /// In en, this message translates to:
  /// **'Select a range with a header row to add a slicer.'**
  String get slicerNeedsData;

  /// No description provided for @cmdSlicerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit slicer'**
  String get cmdSlicerEdit;

  /// No description provided for @cmdSlicerUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update slicer'**
  String get cmdSlicerUpdate;

  /// No description provided for @cmdSlicerSetCriteria.
  ///
  /// In en, this message translates to:
  /// **'Set slicer filter'**
  String get cmdSlicerSetCriteria;

  /// No description provided for @cmdSlicerSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set slicer filters as default'**
  String get cmdSlicerSetDefault;

  /// No description provided for @cmdSlicerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset slicer'**
  String get cmdSlicerReset;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Show statistic'**
  String get cmdStatsSetShown;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete rows, columns or cells'**
  String get cmdStructureDeleteBySelection;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Insert rows, columns or cells'**
  String get cmdStructureInsertBySelection;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Delete cells…'**
  String get cmdStructureOpenDeleteDialog;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get cmdThemeOpenPanel;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Personal dictionary'**
  String get cmdToolsPersonalDictionary;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Spell check'**
  String get cmdToolsSpellCheck;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Autocomplete'**
  String get cmdToolsToggleAutocomplete;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Formula suggestions'**
  String get cmdToolsToggleFormulaSuggestions;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Ungroup columns'**
  String get cmdUngroupColumns;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Ungroup rows'**
  String get cmdUngroupRows;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Freeze columns'**
  String get cmdViewFreezeColumns;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Freeze rows'**
  String get cmdViewFreezeRows;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Hide comment indicators'**
  String get cmdViewToggleCommentIndicators;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Formula bar'**
  String get cmdViewToggleFormulaBar;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Formulas'**
  String get cmdViewToggleFormulas;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Gridlines'**
  String get cmdViewToggleGridlines;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Protected ranges'**
  String get cmdViewToggleProtectedRanges;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get cmdViewZoom;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get cmdViewZoomIn;

  /// Command title (menus, palette, tooltips, undo labels).
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get cmdViewZoomOut;

  /// No description provided for @colorAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get colorAutomatic;

  /// No description provided for @colorNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get colorNone;

  /// No description provided for @contextDeleteCells.
  ///
  /// In en, this message translates to:
  /// **'Delete cells'**
  String get contextDeleteCells;

  /// No description provided for @contextEditLink.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get contextEditLink;

  /// No description provided for @contextFitAllColumns.
  ///
  /// In en, this message translates to:
  /// **'Fit all columns to data'**
  String get contextFitAllColumns;

  /// No description provided for @contextInsertCells.
  ///
  /// In en, this message translates to:
  /// **'Insert cells'**
  String get contextInsertCells;

  /// No description provided for @contextMoreCellActions.
  ///
  /// In en, this message translates to:
  /// **'View more cell actions'**
  String get contextMoreCellActions;

  /// No description provided for @contextMoreColumnActions.
  ///
  /// In en, this message translates to:
  /// **'View more column actions'**
  String get contextMoreColumnActions;

  /// No description provided for @contextMoreRowActions.
  ///
  /// In en, this message translates to:
  /// **'View more row actions'**
  String get contextMoreRowActions;

  /// No description provided for @contextUnhideAllColumns.
  ///
  /// In en, this message translates to:
  /// **'Unhide all columns'**
  String get contextUnhideAllColumns;

  /// No description provided for @contextUnhideAllRows.
  ///
  /// In en, this message translates to:
  /// **'Unhide all rows'**
  String get contextUnhideAllRows;

  /// No description provided for @dialogApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dialogApply;

  /// No description provided for @dialogCustomNumberFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom number format'**
  String get dialogCustomNumberFormatTitle;

  /// No description provided for @dialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// No description provided for @dialogDeleteCellsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete cells'**
  String get dialogDeleteCellsTitle;

  /// No description provided for @dialogDeleteSheetBody.
  ///
  /// In en, this message translates to:
  /// **'You can undo this.'**
  String get dialogDeleteSheetBody;

  /// No description provided for @dialogDeleteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String dialogDeleteSheetTitle(String name);

  /// No description provided for @dialogEntireColumn.
  ///
  /// In en, this message translates to:
  /// **'Entire column'**
  String get dialogEntireColumn;

  /// No description provided for @dialogEntireRow.
  ///
  /// In en, this message translates to:
  /// **'Entire row'**
  String get dialogEntireRow;

  /// No description provided for @dialogInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get dialogInsert;

  /// No description provided for @dialogInsertAbove.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get dialogInsertAbove;

  /// No description provided for @dialogInsertBelow.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get dialogInsertBelow;

  /// No description provided for @dialogInsertCellsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert cells'**
  String get dialogInsertCellsTitle;

  /// No description provided for @dialogInsertCount.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get dialogInsertCount;

  /// No description provided for @dialogInsertInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 10,000'**
  String get dialogInsertInvalid;

  /// No description provided for @dialogInsertLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get dialogInsertLeft;

  /// No description provided for @dialogInsertPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get dialogInsertPosition;

  /// No description provided for @dialogInsertRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get dialogInsertRight;

  /// No description provided for @dialogLinkText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get dialogLinkText;

  /// No description provided for @dialogLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get dialogLinkTitle;

  /// No description provided for @dialogLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get dialogLinkUrl;

  /// No description provided for @dialogMergeAll.
  ///
  /// In en, this message translates to:
  /// **'Merging cells will only preserve the top-leftmost value. Merge anyway?'**
  String get dialogMergeAll;

  /// No description provided for @dialogMergeHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Merging cells will only preserve the leftmost value of each row. Merge anyway?'**
  String get dialogMergeHorizontal;

  /// No description provided for @dialogMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge cells'**
  String get dialogMergeTitle;

  /// No description provided for @dialogMergeVertical.
  ///
  /// In en, this message translates to:
  /// **'Merging cells will only preserve the top value of each column. Merge anyway?'**
  String get dialogMergeVertical;

  /// No description provided for @dialogNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get dialogNoteLabel;

  /// No description provided for @dialogNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get dialogNoteTitle;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// No description provided for @dialogPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get dialogPaste;

  /// No description provided for @dialogPasteSpecialMode.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get dialogPasteSpecialMode;

  /// No description provided for @dialogPasteSpecialTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste special'**
  String get dialogPasteSpecialTitle;

  /// No description provided for @dialogReplaceDataBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to replace it?'**
  String get dialogReplaceDataBody;

  /// No description provided for @dialogReplaceDataTitle.
  ///
  /// In en, this message translates to:
  /// **'There\'s already data here'**
  String get dialogReplaceDataTitle;

  /// No description provided for @dialogResizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a size from 2 to 5,000 px'**
  String get dialogResizeInvalid;

  /// No description provided for @dialogResizeMode.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get dialogResizeMode;

  /// No description provided for @dialogResizeSize.
  ///
  /// In en, this message translates to:
  /// **'Size (px)'**
  String get dialogResizeSize;

  /// No description provided for @dialogResizeSpecifyColumn.
  ///
  /// In en, this message translates to:
  /// **'Specify column width'**
  String get dialogResizeSpecifyColumn;

  /// No description provided for @dialogResizeSpecifyRow.
  ///
  /// In en, this message translates to:
  /// **'Specify row height'**
  String get dialogResizeSpecifyRow;

  /// No description provided for @dialogRotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Angle (degrees)'**
  String get dialogRotationLabel;

  /// No description provided for @dialogRotationTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom angle'**
  String get dialogRotationTitle;

  /// No description provided for @dialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// No description provided for @dialogShiftMode.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get dialogShiftMode;

  /// No description provided for @downloadCsv.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated values (.csv, current sheet)'**
  String get downloadCsv;

  /// No description provided for @downloadHtml.
  ///
  /// In en, this message translates to:
  /// **'Web page (.html, zipped)'**
  String get downloadHtml;

  /// No description provided for @downloadOds.
  ///
  /// In en, this message translates to:
  /// **'OpenDocument (.ods)'**
  String get downloadOds;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (.pdf)'**
  String get downloadPdf;

  /// No description provided for @downloadTsv.
  ///
  /// In en, this message translates to:
  /// **'Tab-separated values (.tsv, current sheet)'**
  String get downloadTsv;

  /// No description provided for @downloadJson.
  ///
  /// In en, this message translates to:
  /// **'JSON (.json, values and formulas)'**
  String get downloadJson;

  /// No description provided for @downloadXlsx.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Excel (.xlsx)'**
  String get downloadXlsx;

  /// No description provided for @errorSheetNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'A sheet name can’t be empty'**
  String get errorSheetNameEmpty;

  /// No description provided for @formulaParseError.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String formulaParseError(String message);

  /// No description provided for @freezeColumns.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 column} other{{n} columns}}'**
  String freezeColumns(int n);

  /// No description provided for @freezeNoColumns.
  ///
  /// In en, this message translates to:
  /// **'No columns'**
  String get freezeNoColumns;

  /// No description provided for @freezeNoRows.
  ///
  /// In en, this message translates to:
  /// **'No rows'**
  String get freezeNoRows;

  /// No description provided for @freezeRows.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 row} other{{n} rows}}'**
  String freezeRows(int n);

  /// No description provided for @freezeUpToColumn.
  ///
  /// In en, this message translates to:
  /// **'Up to column {col}'**
  String freezeUpToColumn(String col);

  /// No description provided for @freezeUpToRow.
  ///
  /// In en, this message translates to:
  /// **'Up to row {row}'**
  String freezeUpToRow(int row);

  /// No description provided for @gridSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'{sheet} grid'**
  String gridSemanticsLabel(String sheet);

  /// No description provided for @labelColumn.
  ///
  /// In en, this message translates to:
  /// **'column {col}'**
  String labelColumn(String col);

  /// No description provided for @labelColumns.
  ///
  /// In en, this message translates to:
  /// **'columns {from} – {to}'**
  String labelColumns(String from, String to);

  /// No description provided for @labelRow.
  ///
  /// In en, this message translates to:
  /// **'row {row}'**
  String labelRow(int row);

  /// No description provided for @labelRows.
  ///
  /// In en, this message translates to:
  /// **'rows {from} – {to}'**
  String labelRows(int from, int to);

  /// No description provided for @loadingSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Opening spreadsheet…'**
  String get loadingSpreadsheet;

  /// No description provided for @menuAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get menuAi;

  /// No description provided for @menuAlignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get menuAlignment;

  /// No description provided for @menuCells.
  ///
  /// In en, this message translates to:
  /// **'Cells'**
  String get menuCells;

  /// No description provided for @menuColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get menuColumns;

  /// No description provided for @menuComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get menuComments;

  /// No description provided for @menuData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get menuData;

  /// No description provided for @menuDataCleanup.
  ///
  /// In en, this message translates to:
  /// **'Data cleanup'**
  String get menuDataCleanup;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @menuDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get menuDownload;

  /// No description provided for @menuExtensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get menuExtensions;

  /// No description provided for @menuFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get menuFontSize;

  /// No description provided for @menuFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get menuFormat;

  /// No description provided for @menuFreeze.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get menuFreeze;

  /// No description provided for @menuFunction.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get menuFunction;

  /// No description provided for @menuGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get menuGroup;

  /// No description provided for @menuHiddenSheets.
  ///
  /// In en, this message translates to:
  /// **'Hidden sheets'**
  String get menuHiddenSheets;

  /// No description provided for @menuImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get menuImage;

  /// No description provided for @menuInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get menuInsert;

  /// No description provided for @menuMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get menuMacros;

  /// No description provided for @menuMergeCells.
  ///
  /// In en, this message translates to:
  /// **'Merge cells'**
  String get menuMergeCells;

  /// No description provided for @menuMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get menuMove;

  /// No description provided for @menuNoHiddenSheets.
  ///
  /// In en, this message translates to:
  /// **'No hidden sheets'**
  String get menuNoHiddenSheets;

  /// No description provided for @menuNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get menuNotificationSettings;

  /// No description provided for @menuNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get menuNumber;

  /// No description provided for @menuPasteSpecial.
  ///
  /// In en, this message translates to:
  /// **'Paste special'**
  String get menuPasteSpecial;

  /// No description provided for @menuRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get menuRotation;

  /// No description provided for @menuRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get menuRows;

  /// No description provided for @menuScripts.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get menuScripts;

  /// No description provided for @menuShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get menuShow;

  /// No description provided for @menuSortRange.
  ///
  /// In en, this message translates to:
  /// **'Sort range'**
  String get menuSortRange;

  /// No description provided for @menuSortSheet.
  ///
  /// In en, this message translates to:
  /// **'Sort sheet'**
  String get menuSortSheet;

  /// No description provided for @menuSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get menuSpelling;

  /// No description provided for @menuText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get menuText;

  /// No description provided for @menuWrapping.
  ///
  /// In en, this message translates to:
  /// **'Wrapping'**
  String get menuWrapping;

  /// No description provided for @menuZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get menuZoom;

  /// No description provided for @mergeAll.
  ///
  /// In en, this message translates to:
  /// **'Merge all'**
  String get mergeAll;

  /// No description provided for @mergeHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Merge horizontally'**
  String get mergeHorizontally;

  /// No description provided for @mergeVertically.
  ///
  /// In en, this message translates to:
  /// **'Merge vertically'**
  String get mergeVertically;

  /// No description provided for @numberFormatAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get numberFormatAccounting;

  /// No description provided for @numberFormatAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get numberFormatAutomatic;

  /// No description provided for @numberFormatCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get numberFormatCurrency;

  /// No description provided for @numberFormatCurrencyRounded.
  ///
  /// In en, this message translates to:
  /// **'Currency rounded'**
  String get numberFormatCurrencyRounded;

  /// No description provided for @numberFormatDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get numberFormatDate;

  /// No description provided for @numberFormatDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date time'**
  String get numberFormatDateTime;

  /// No description provided for @numberFormatDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get numberFormatDuration;

  /// No description provided for @numberFormatFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get numberFormatFinancial;

  /// No description provided for @numberFormatNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get numberFormatNumber;

  /// No description provided for @numberFormatPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get numberFormatPercent;

  /// No description provided for @numberFormatPlainText.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get numberFormatPlainText;

  /// No description provided for @numberFormatScientific.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get numberFormatScientific;

  /// No description provided for @numberFormatTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get numberFormatTime;

  /// No description provided for @pasteAllExceptBorders.
  ///
  /// In en, this message translates to:
  /// **'All except borders'**
  String get pasteAllExceptBorders;

  /// No description provided for @pasteColumnWidthsOnly.
  ///
  /// In en, this message translates to:
  /// **'Column widths only'**
  String get pasteColumnWidthsOnly;

  /// No description provided for @pasteConditionalFormattingOnly.
  ///
  /// In en, this message translates to:
  /// **'Conditional formatting only'**
  String get pasteConditionalFormattingOnly;

  /// No description provided for @pasteDataValidationOnly.
  ///
  /// In en, this message translates to:
  /// **'Data validation only'**
  String get pasteDataValidationOnly;

  /// No description provided for @pasteFormatOnly.
  ///
  /// In en, this message translates to:
  /// **'Format only'**
  String get pasteFormatOnly;

  /// No description provided for @pasteFormulasOnly.
  ///
  /// In en, this message translates to:
  /// **'Formula only'**
  String get pasteFormulasOnly;

  /// No description provided for @pasteTransposed.
  ///
  /// In en, this message translates to:
  /// **'Transposed'**
  String get pasteTransposed;

  /// No description provided for @pasteValuesOnly.
  ///
  /// In en, this message translates to:
  /// **'Values only'**
  String get pasteValuesOnly;

  /// No description provided for @reasonNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get reasonNotAvailableYet;

  /// No description provided for @reasonSpreadsheetLoading.
  ///
  /// In en, this message translates to:
  /// **'The spreadsheet is still opening'**
  String get reasonSpreadsheetLoading;

  /// No description provided for @reasonViewAccess.
  ///
  /// In en, this message translates to:
  /// **'You have view access'**
  String get reasonViewAccess;

  /// No description provided for @reasonViewingMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Editing mode to make changes'**
  String get reasonViewingMode;

  /// No description provided for @reasonTextSelected.
  ///
  /// In en, this message translates to:
  /// **'Not available while text in the cell is selected'**
  String get reasonTextSelected;

  /// No description provided for @rotationCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom angle…'**
  String get rotationCustom;

  /// No description provided for @rotationDown.
  ///
  /// In en, this message translates to:
  /// **'Rotate down'**
  String get rotationDown;

  /// No description provided for @rotationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get rotationNone;

  /// No description provided for @rotationStack.
  ///
  /// In en, this message translates to:
  /// **'Stack vertically'**
  String get rotationStack;

  /// No description provided for @rotationTiltDown.
  ///
  /// In en, this message translates to:
  /// **'Tilt down'**
  String get rotationTiltDown;

  /// No description provided for @rotationTiltUp.
  ///
  /// In en, this message translates to:
  /// **'Tilt up'**
  String get rotationTiltUp;

  /// No description provided for @rotationUp.
  ///
  /// In en, this message translates to:
  /// **'Rotate up'**
  String get rotationUp;

  /// No description provided for @screenGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get screenGoHome;

  /// No description provided for @screenOfflineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This spreadsheet isn’t available offline'**
  String get screenOfflineUnavailable;

  /// No description provided for @screenOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'It isn’t on this device yet. Open it once while online to keep it available offline.'**
  String get screenOfflineHint;

  /// No description provided for @screenOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The spreadsheet couldn’t be opened'**
  String get screenOpenFailed;

  /// No description provided for @screenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get screenTryAgain;

  /// No description provided for @screenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This spreadsheet isn’t available'**
  String get screenUnavailable;

  /// No description provided for @sheetHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} (hidden)'**
  String sheetHiddenLabel(String name);

  /// No description provided for @sortAtoZ.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get sortAtoZ;

  /// No description provided for @sortSheetAtoZ.
  ///
  /// In en, this message translates to:
  /// **'Sort sheet A to Z'**
  String get sortSheetAtoZ;

  /// No description provided for @sortSheetZtoA.
  ///
  /// In en, this message translates to:
  /// **'Sort sheet Z to A'**
  String get sortSheetZtoA;

  /// No description provided for @sortZtoA.
  ///
  /// In en, this message translates to:
  /// **'Z to A'**
  String get sortZtoA;

  /// No description provided for @statAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statAverage;

  /// No description provided for @statCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get statCount;

  /// No description provided for @statCountNumbers.
  ///
  /// In en, this message translates to:
  /// **'Count numbers'**
  String get statCountNumbers;

  /// No description provided for @statMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statMax;

  /// No description provided for @statMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statMin;

  /// No description provided for @statSum.
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get statSum;

  /// No description provided for @statusCellCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} cells'**
  String statusCellCount(int count, int max);

  /// No description provided for @statusCellLimitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cells in this spreadsheet (rows × columns of every sheet) and the limit'**
  String get statusCellLimitTooltip;

  /// No description provided for @statusModeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get statusModeEdit;

  /// No description provided for @statusModeEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get statusModeEnter;

  /// No description provided for @statusModePoint.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get statusModePoint;

  /// No description provided for @statusModeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusModeReady;

  /// No description provided for @statusSheetSize.
  ///
  /// In en, this message translates to:
  /// **'{name} · {rows} × {cols}'**
  String statusSheetSize(String name, int rows, int cols);

  /// No description provided for @tabAllSheets.
  ///
  /// In en, this message translates to:
  /// **'All sheets'**
  String get tabAllSheets;

  /// No description provided for @tabBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Sheet tabs'**
  String get tabBarLabel;

  /// No description provided for @tabCopyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to'**
  String get tabCopyTo;

  /// No description provided for @tabDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'Another sheet has the same name'**
  String get tabDuplicateName;

  /// No description provided for @tabMenu.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String tabMenu(String name);

  /// No description provided for @tabScrollLeft.
  ///
  /// In en, this message translates to:
  /// **'Scroll tabs left'**
  String get tabScrollLeft;

  /// No description provided for @tabScrollRight.
  ///
  /// In en, this message translates to:
  /// **'Scroll tabs right'**
  String get tabScrollRight;

  /// No description provided for @toastCantDeleteAllColumns.
  ///
  /// In en, this message translates to:
  /// **'A sheet must have at least one column'**
  String get toastCantDeleteAllColumns;

  /// No description provided for @toastCantDeleteAllRows.
  ///
  /// In en, this message translates to:
  /// **'A sheet must have at least one row'**
  String get toastCantDeleteAllRows;

  /// No description provided for @toastCantHideAll.
  ///
  /// In en, this message translates to:
  /// **'You can’t hide all rows or columns of a sheet'**
  String get toastCantHideAll;

  /// No description provided for @toastClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty'**
  String get toastClipboardEmpty;

  /// No description provided for @screenStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The spreadsheet storage on this device didn\'t start. Try again, or reload the page.'**
  String get screenStorageUnavailable;

  /// No description provided for @toastClipboardBlocked.
  ///
  /// In en, this message translates to:
  /// **'The browser blocked access to the clipboard. Allow clipboard access for this site to paste here.'**
  String get toastClipboardBlocked;

  /// No description provided for @toastCommandFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn’t work'**
  String get toastCommandFailed;

  /// No description provided for @toastEditedRowDeleted.
  ///
  /// In en, this message translates to:
  /// **'The cell you were editing was deleted'**
  String get toastEditedRowDeleted;

  /// No description provided for @toastFreezeTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The frozen area would be larger than the window. Zoom out or freeze fewer rows.'**
  String get toastFreezeTooLarge;

  /// No description provided for @toastInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'“{range}” isn’t a valid range'**
  String toastInvalidRange(String range);

  /// No description provided for @toastLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get toastLinkCopied;

  /// No description provided for @toastMultipleSelections.
  ///
  /// In en, this message translates to:
  /// **'This action won’t work on multiple selections'**
  String get toastMultipleSelections;

  /// No description provided for @toastNamedRangeCreated.
  ///
  /// In en, this message translates to:
  /// **'Named range “{name}” created'**
  String toastNamedRangeCreated(String name);

  /// No description provided for @toastSavesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Wonky Sheets saves automatically'**
  String get toastSavesAutomatically;

  /// No description provided for @toastTrimmed.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No cells needed trimming} =1{Trimmed 1 cell} other{Trimmed {n} cells}}'**
  String toastTrimmed(int n);

  /// No description provided for @toastUndoPartial.
  ///
  /// In en, this message translates to:
  /// **'Some changes couldn’t be undone because they were edited by someone else.'**
  String get toastUndoPartial;

  /// A change the server rejected (RevLog 06 §4.6); it is undone on this device.
  ///
  /// In en, this message translates to:
  /// **'“{label}” couldn’t be saved: {reason}'**
  String toastChangeNotSaved(String label, String reason);

  /// No description provided for @toastChangeProtected.
  ///
  /// In en, this message translates to:
  /// **'“{label}” wasn’t saved because it edits a protected cell or object.'**
  String toastChangeProtected(String label);

  /// No description provided for @toastChangeNoAccess.
  ///
  /// In en, this message translates to:
  /// **'You can no longer edit this spreadsheet'**
  String get toastChangeNoAccess;

  /// No description provided for @toolbarBorders.
  ///
  /// In en, this message translates to:
  /// **'Borders'**
  String get toolbarBorders;

  /// No description provided for @toolbarCurrency.
  ///
  /// In en, this message translates to:
  /// **'Format as currency'**
  String get toolbarCurrency;

  /// No description provided for @toolbarFillColor.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get toolbarFillColor;

  /// No description provided for @toolbarFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get toolbarFont;

  /// No description provided for @toolbarFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get toolbarFontSize;

  /// No description provided for @toolbarFunctions.
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get toolbarFunctions;

  /// No description provided for @toolbarHAlign.
  ///
  /// In en, this message translates to:
  /// **'Horizontal align'**
  String get toolbarHAlign;

  /// No description provided for @toolbarLabel.
  ///
  /// In en, this message translates to:
  /// **'Formatting toolbar'**
  String get toolbarLabel;

  /// No description provided for @toolbarMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge cells'**
  String get toolbarMerge;

  /// No description provided for @toolbarMoreFormats.
  ///
  /// In en, this message translates to:
  /// **'More formats'**
  String get toolbarMoreFormats;

  /// No description provided for @toolbarPercent.
  ///
  /// In en, this message translates to:
  /// **'Format as percent'**
  String get toolbarPercent;

  /// No description provided for @toolbarRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get toolbarRedo;

  /// No description provided for @toolbarRedoLabel.
  ///
  /// In en, this message translates to:
  /// **'Redo {label}'**
  String toolbarRedoLabel(String label);

  /// No description provided for @toolbarRotation.
  ///
  /// In en, this message translates to:
  /// **'Text rotation'**
  String get toolbarRotation;

  /// No description provided for @toolbarTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get toolbarTextColor;

  /// No description provided for @toolbarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get toolbarUndo;

  /// No description provided for @toolbarUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo {label}'**
  String toolbarUndoLabel(String label);

  /// No description provided for @toolbarVAlign.
  ///
  /// In en, this message translates to:
  /// **'Vertical align'**
  String get toolbarVAlign;

  /// No description provided for @toolbarWrap.
  ///
  /// In en, this message translates to:
  /// **'Text wrapping'**
  String get toolbarWrap;

  /// No description provided for @toolbarZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get toolbarZoom;

  /// No description provided for @undoTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get undoTyping;

  /// No description provided for @untitledSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Untitled spreadsheet'**
  String get untitledSpreadsheet;

  /// No description provided for @wrapClip.
  ///
  /// In en, this message translates to:
  /// **'Clip'**
  String get wrapClip;

  /// No description provided for @wrapOverflow.
  ///
  /// In en, this message translates to:
  /// **'Overflow'**
  String get wrapOverflow;

  /// No description provided for @wrapWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap'**
  String get wrapWrap;

  /// No description provided for @zoomPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String zoomPercent(int percent);

  /// No description provided for @protectBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected cell or object'**
  String get protectBlockedTitle;

  /// No description provided for @protectBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'You are trying to edit a protected cell or object. Please contact the spreadsheet owner to remove protection if you need to edit.'**
  String get protectBlockedBody;

  /// No description provided for @protectWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Heads up!'**
  String get protectWarningTitle;

  /// No description provided for @protectWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Someone has protected part of this sheet to prevent accidental changes. Edit anyway?'**
  String get protectWarningBody;

  /// No description provided for @protectWarningSnooze.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show this again for 5 minutes'**
  String get protectWarningSnooze;

  /// No description provided for @protectPanelEmpty.
  ///
  /// In en, this message translates to:
  /// **'No protected sheets or ranges'**
  String get protectPanelEmpty;

  /// No description provided for @protectPanelEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Protect a range or a whole sheet so that it isn\'t changed by accident.'**
  String get protectPanelEmptyHint;

  /// No description provided for @protectAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a sheet or range'**
  String get protectAdd;

  /// No description provided for @protectTabRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get protectTabRange;

  /// No description provided for @protectTabSheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get protectTabSheet;

  /// No description provided for @protectDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get protectDescription;

  /// No description provided for @protectDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a description'**
  String get protectDescriptionPlaceholder;

  /// No description provided for @protectRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get protectRange;

  /// No description provided for @protectSheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get protectSheet;

  /// No description provided for @protectExceptCells.
  ///
  /// In en, this message translates to:
  /// **'Except certain cells'**
  String get protectExceptCells;

  /// No description provided for @protectSetPermissions.
  ///
  /// In en, this message translates to:
  /// **'Set permissions'**
  String get protectSetPermissions;

  /// No description provided for @protectOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Only you'**
  String get protectOnlyYou;

  /// No description provided for @protectRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get protectRestricted;

  /// No description provided for @protectEditorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 editor} other{{count} editors}}'**
  String protectEditorsCount(int count);

  /// No description provided for @protectWarningOnly.
  ///
  /// In en, this message translates to:
  /// **'Warning only'**
  String get protectWarningOnly;

  /// No description provided for @protectSheetName.
  ///
  /// In en, this message translates to:
  /// **'Sheet “{name}”'**
  String protectSheetName(String name);

  /// No description provided for @protectExceptSummary.
  ///
  /// In en, this message translates to:
  /// **'except {ranges}'**
  String protectExceptSummary(String ranges);

  /// No description provided for @protectCantEdit.
  ///
  /// In en, this message translates to:
  /// **'You can\'t edit this protection'**
  String get protectCantEdit;

  /// No description provided for @protectAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Only the people you choose can edit protected ranges, also from other devices, scripts and agents. Warning-only ranges ask for a confirmation instead.'**
  String get protectAdvisory;

  /// No description provided for @protectEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit protection'**
  String get protectEdit;

  /// No description provided for @protectRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove protection'**
  String get protectRemove;

  /// No description provided for @protectYouCanEdit.
  ///
  /// In en, this message translates to:
  /// **'You can edit'**
  String get protectYouCanEdit;

  /// No description provided for @protectPermissionsTitleRange.
  ///
  /// In en, this message translates to:
  /// **'Range editing permissions'**
  String get protectPermissionsTitleRange;

  /// No description provided for @protectPermissionsTitleSheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet editing permissions'**
  String get protectPermissionsTitleSheet;

  /// No description provided for @protectPermMode.
  ///
  /// In en, this message translates to:
  /// **'When someone edits'**
  String get protectPermMode;

  /// No description provided for @protectPermWarning.
  ///
  /// In en, this message translates to:
  /// **'Show a warning when editing this range'**
  String get protectPermWarning;

  /// No description provided for @protectPermRestrict.
  ///
  /// In en, this message translates to:
  /// **'Restrict who can edit this range'**
  String get protectPermRestrict;

  /// No description provided for @protectPermWho.
  ///
  /// In en, this message translates to:
  /// **'Who can edit'**
  String get protectPermWho;

  /// No description provided for @protectPermOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Only you'**
  String get protectPermOnlyYou;

  /// No description provided for @protectPermCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom (checked editors)'**
  String get protectPermCustom;

  /// No description provided for @protectPermCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy permissions from “{name}”'**
  String protectPermCopy(String name);

  /// No description provided for @protectPermAddEditors.
  ///
  /// In en, this message translates to:
  /// **'Add editors'**
  String get protectPermAddEditors;

  /// No description provided for @protectPermAddEditorsHint.
  ///
  /// In en, this message translates to:
  /// **'Emails, separated by commas'**
  String get protectPermAddEditorsHint;

  /// No description provided for @protectPermNoAccess.
  ///
  /// In en, this message translates to:
  /// **'{names} doesn\'t have edit access to the spreadsheet'**
  String protectPermNoAccess(String names);

  /// No description provided for @protectPermEditorsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading editors…'**
  String get protectPermEditorsLoading;

  /// No description provided for @protectEditorsOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline: these are the editors known on this device.'**
  String get protectEditorsOffline;

  /// No description provided for @protectInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with new editors?'**
  String get protectInviteTitle;

  /// No description provided for @protectInviteBody.
  ///
  /// In en, this message translates to:
  /// **'{names} can\'t edit the spreadsheet yet. Share it with them as editors so they can edit this range too?'**
  String protectInviteBody(String names);

  /// No description provided for @protectInviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share and add'**
  String get protectInviteShare;

  /// No description provided for @protectInviteSkip.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share'**
  String get protectInviteSkip;

  /// No description provided for @protectInvitePending.
  ///
  /// In en, this message translates to:
  /// **'{names} got an invitation. Add them here once they\'ve accepted it.'**
  String protectInvitePending(String names);

  /// No description provided for @protectSheetProtected.
  ///
  /// In en, this message translates to:
  /// **'This sheet is protected'**
  String get protectSheetProtected;

  /// No description provided for @cmdProtectAdd.
  ///
  /// In en, this message translates to:
  /// **'Protect range'**
  String get cmdProtectAdd;

  /// No description provided for @cmdProtectUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit protection'**
  String get cmdProtectUpdate;

  /// No description provided for @cmdProtectDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove protection'**
  String get cmdProtectDelete;

  /// No description provided for @reasonCantManageProtection.
  ///
  /// In en, this message translates to:
  /// **'You can\'t edit this protection'**
  String get reasonCantManageProtection;

  /// No description provided for @dvPanelEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data validation rules'**
  String get dvPanelEmpty;

  /// No description provided for @dvPanelEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a rule to control what can be entered in cells.'**
  String get dvPanelEmptyHint;

  /// No description provided for @dvAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get dvAddRule;

  /// No description provided for @dvRemoveAllInSelection.
  ///
  /// In en, this message translates to:
  /// **'Remove all in selection'**
  String get dvRemoveAllInSelection;

  /// No description provided for @dvApplyToRange.
  ///
  /// In en, this message translates to:
  /// **'Apply to range'**
  String get dvApplyToRange;

  /// No description provided for @dvCriteria.
  ///
  /// In en, this message translates to:
  /// **'Criteria'**
  String get dvCriteria;

  /// No description provided for @dvAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced options'**
  String get dvAdvanced;

  /// No description provided for @dvIfInvalid.
  ///
  /// In en, this message translates to:
  /// **'If the data is invalid'**
  String get dvIfInvalid;

  /// No description provided for @dvShowWarning.
  ///
  /// In en, this message translates to:
  /// **'Show a warning'**
  String get dvShowWarning;

  /// No description provided for @dvRejectInput.
  ///
  /// In en, this message translates to:
  /// **'Reject the input'**
  String get dvRejectInput;

  /// No description provided for @dvShowHelpText.
  ///
  /// In en, this message translates to:
  /// **'Show help text for a selected cell'**
  String get dvShowHelpText;

  /// No description provided for @dvHelpTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter help text'**
  String get dvHelpTextPlaceholder;

  /// No description provided for @dvDisplayStyle.
  ///
  /// In en, this message translates to:
  /// **'Display style'**
  String get dvDisplayStyle;

  /// No description provided for @dvStyleChip.
  ///
  /// In en, this message translates to:
  /// **'Chip'**
  String get dvStyleChip;

  /// No description provided for @dvStyleArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get dvStyleArrow;

  /// No description provided for @dvStylePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get dvStylePlain;

  /// No description provided for @dvAllowMultiple.
  ///
  /// In en, this message translates to:
  /// **'Allow multiple selections'**
  String get dvAllowMultiple;

  /// No description provided for @dvRemoveRule.
  ///
  /// In en, this message translates to:
  /// **'Remove rule'**
  String get dvRemoveRule;

  /// No description provided for @dvAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add another item'**
  String get dvAddItem;

  /// No description provided for @dvItemPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String dvItemPlaceholder(int n);

  /// No description provided for @dvItemColor.
  ///
  /// In en, this message translates to:
  /// **'Color of “{item}”'**
  String dvItemColor(String item);

  /// No description provided for @dvItemRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove “{item}”'**
  String dvItemRemove(String item);

  /// No description provided for @dvItemMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get dvItemMoveUp;

  /// No description provided for @dvItemMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get dvItemMoveDown;

  /// No description provided for @pivotUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get pivotUpdating;

  /// No description provided for @cmdPivotGroupSelection.
  ///
  /// In en, this message translates to:
  /// **'Create pivot group'**
  String get cmdPivotGroupSelection;

  /// No description provided for @pivotSelectLabels.
  ///
  /// In en, this message translates to:
  /// **'Select row or column labels of one pivot table field'**
  String get pivotSelectLabels;

  /// No description provided for @pivotGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get pivotGroupName;

  /// No description provided for @pivotGroupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get pivotGroupCreate;

  /// No description provided for @pivotGroupPrefix.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get pivotGroupPrefix;

  /// No description provided for @pivotGroupNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get pivotGroupNameEmpty;

  /// No description provided for @pivotShowEmptyGroups.
  ///
  /// In en, this message translates to:
  /// **'Show items with no data'**
  String get pivotShowEmptyGroups;

  /// No description provided for @pivotFilterByColor.
  ///
  /// In en, this message translates to:
  /// **'Filter by color'**
  String get pivotFilterByColor;

  /// No description provided for @pivotFillColor.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get pivotFillColor;

  /// No description provided for @pivotTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get pivotTextColor;

  /// No description provided for @pivotNoColorFilter.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get pivotNoColorFilter;

  /// No description provided for @pivotFormulaValue.
  ///
  /// In en, this message translates to:
  /// **'=formula, e.g. =C2>100'**
  String get pivotFormulaValue;

  /// No description provided for @smartChipSearch.
  ///
  /// In en, this message translates to:
  /// **'Search people, or type…'**
  String get smartChipSearch;

  /// No description provided for @smartChipPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get smartChipPeople;

  /// No description provided for @smartChipDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get smartChipDate;

  /// No description provided for @smartChipDropdown.
  ///
  /// In en, this message translates to:
  /// **'Dropdown'**
  String get smartChipDropdown;

  /// No description provided for @smartChipAsText.
  ///
  /// In en, this message translates to:
  /// **'Insert “{text}” as text'**
  String smartChipAsText(String text);

  /// No description provided for @smartChipOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get smartChipOpenFile;

  /// No description provided for @smartChipFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get smartChipFiles;

  /// No description provided for @smartChipFilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get smartChipFilesEmpty;

  /// No description provided for @cmdChipOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open linked file'**
  String get cmdChipOpenFile;

  /// No description provided for @smartChipCopyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get smartChipCopyEmail;

  /// No description provided for @smartChipEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied'**
  String get smartChipEmailCopied;

  /// No description provided for @dvItemDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder (Alt+↑/↓ in the field)'**
  String get dvItemDragHint;

  /// No description provided for @dvNoColor.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get dvNoColor;

  /// No description provided for @dvChipColors.
  ///
  /// In en, this message translates to:
  /// **'Chip colors'**
  String get dvChipColors;

  /// No description provided for @dvUseCustomValues.
  ///
  /// In en, this message translates to:
  /// **'Use custom cell values'**
  String get dvUseCustomValues;

  /// No description provided for @dvChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get dvChecked;

  /// No description provided for @dvUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Unchecked'**
  String get dvUnchecked;

  /// No description provided for @dvValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get dvValue;

  /// No description provided for @dvValueMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get dvValueMin;

  /// No description provided for @dvValueMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get dvValueMax;

  /// No description provided for @dvValueFormula.
  ///
  /// In en, this message translates to:
  /// **'Value or =formula'**
  String get dvValueFormula;

  /// No description provided for @dvSourceRange.
  ///
  /// In en, this message translates to:
  /// **'Range of items'**
  String get dvSourceRange;

  /// No description provided for @dvShadowed.
  ///
  /// In en, this message translates to:
  /// **'Another rule takes precedence over part of this range'**
  String get dvShadowed;

  /// No description provided for @dvErrorNoItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get dvErrorNoItems;

  /// No description provided for @dvErrorValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get dvErrorValue;

  /// No description provided for @dvErrorNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number or a formula'**
  String get dvErrorNumber;

  /// No description provided for @dvErrorDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a date or a formula'**
  String get dvErrorDate;

  /// No description provided for @dvErrorFormula.
  ///
  /// In en, this message translates to:
  /// **'Enter a formula starting with ='**
  String get dvErrorFormula;

  /// No description provided for @dvErrorRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid range'**
  String get dvErrorRange;

  /// No description provided for @dvCapped.
  ///
  /// In en, this message translates to:
  /// **'Some rules were simplified to stay under 1,000 ranges'**
  String get dvCapped;

  /// No description provided for @dvTooManyValues.
  ///
  /// In en, this message translates to:
  /// **'Too many distinct values to convert to a dropdown'**
  String get dvTooManyValues;

  /// No description provided for @dvRuleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rule} other{{count} rules}}'**
  String dvRuleCount(int count);

  /// No description provided for @dvCritDropdown.
  ///
  /// In en, this message translates to:
  /// **'Dropdown'**
  String get dvCritDropdown;

  /// No description provided for @dvCritDropdownRange.
  ///
  /// In en, this message translates to:
  /// **'Dropdown (from a range)'**
  String get dvCritDropdownRange;

  /// No description provided for @dvCritTextContains.
  ///
  /// In en, this message translates to:
  /// **'Text contains'**
  String get dvCritTextContains;

  /// No description provided for @dvCritTextNotContains.
  ///
  /// In en, this message translates to:
  /// **'Text does not contain'**
  String get dvCritTextNotContains;

  /// No description provided for @dvCritTextEq.
  ///
  /// In en, this message translates to:
  /// **'Text is exactly'**
  String get dvCritTextEq;

  /// No description provided for @dvCritTextIsEmail.
  ///
  /// In en, this message translates to:
  /// **'Text is valid email'**
  String get dvCritTextIsEmail;

  /// No description provided for @dvCritTextIsUrl.
  ///
  /// In en, this message translates to:
  /// **'Text is valid URL'**
  String get dvCritTextIsUrl;

  /// No description provided for @dvCritDateIsValid.
  ///
  /// In en, this message translates to:
  /// **'Is valid date'**
  String get dvCritDateIsValid;

  /// No description provided for @dvCritDateEq.
  ///
  /// In en, this message translates to:
  /// **'Date is'**
  String get dvCritDateEq;

  /// No description provided for @dvCritDateBefore.
  ///
  /// In en, this message translates to:
  /// **'Date is before'**
  String get dvCritDateBefore;

  /// No description provided for @dvCritDateAfter.
  ///
  /// In en, this message translates to:
  /// **'Date is after'**
  String get dvCritDateAfter;

  /// No description provided for @dvCritDateOnOrBefore.
  ///
  /// In en, this message translates to:
  /// **'Date is on or before'**
  String get dvCritDateOnOrBefore;

  /// No description provided for @dvCritDateOnOrAfter.
  ///
  /// In en, this message translates to:
  /// **'Date is on or after'**
  String get dvCritDateOnOrAfter;

  /// No description provided for @dvCritDateBetween.
  ///
  /// In en, this message translates to:
  /// **'Date is between'**
  String get dvCritDateBetween;

  /// No description provided for @dvCritDateNotBetween.
  ///
  /// In en, this message translates to:
  /// **'Date is not between'**
  String get dvCritDateNotBetween;

  /// No description provided for @dvCritNumberGreater.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get dvCritNumberGreater;

  /// No description provided for @dvCritNumberGreaterEq.
  ///
  /// In en, this message translates to:
  /// **'Greater than or equal to'**
  String get dvCritNumberGreaterEq;

  /// No description provided for @dvCritNumberLess.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get dvCritNumberLess;

  /// No description provided for @dvCritNumberLessEq.
  ///
  /// In en, this message translates to:
  /// **'Less than or equal to'**
  String get dvCritNumberLessEq;

  /// No description provided for @dvCritNumberEq.
  ///
  /// In en, this message translates to:
  /// **'Is equal to'**
  String get dvCritNumberEq;

  /// No description provided for @dvCritNumberNotEq.
  ///
  /// In en, this message translates to:
  /// **'Is not equal to'**
  String get dvCritNumberNotEq;

  /// No description provided for @dvCritNumberBetween.
  ///
  /// In en, this message translates to:
  /// **'Is between'**
  String get dvCritNumberBetween;

  /// No description provided for @dvCritNumberNotBetween.
  ///
  /// In en, this message translates to:
  /// **'Is not between'**
  String get dvCritNumberNotBetween;

  /// No description provided for @dvCritCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Checkbox'**
  String get dvCritCheckbox;

  /// No description provided for @dvCritCustomFormula.
  ///
  /// In en, this message translates to:
  /// **'Custom formula is'**
  String get dvCritCustomFormula;

  /// No description provided for @dvDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dvDateToday;

  /// No description provided for @dvDateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dvDateTomorrow;

  /// No description provided for @dvDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dvDateYesterday;

  /// No description provided for @dvDatePastWeek.
  ///
  /// In en, this message translates to:
  /// **'In the past week'**
  String get dvDatePastWeek;

  /// No description provided for @dvDatePastMonth.
  ///
  /// In en, this message translates to:
  /// **'In the past month'**
  String get dvDatePastMonth;

  /// No description provided for @dvDatePastYear.
  ///
  /// In en, this message translates to:
  /// **'In the past year'**
  String get dvDatePastYear;

  /// No description provided for @dvDateExact.
  ///
  /// In en, this message translates to:
  /// **'Exact date'**
  String get dvDateExact;

  /// No description provided for @dvInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid entry'**
  String get dvInvalidTitle;

  /// No description provided for @dvInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'The data you entered in cell {cell} violates the data validation rules set on this cell.'**
  String dvInvalidBody(String cell);

  /// No description provided for @dvInvalidTooltipTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get dvInvalidTooltipTitle;

  /// No description provided for @cmdDvSaveRule.
  ///
  /// In en, this message translates to:
  /// **'Save data validation rule'**
  String get cmdDvSaveRule;

  /// No description provided for @cmdDvDeleteRule.
  ///
  /// In en, this message translates to:
  /// **'Remove data validation rule'**
  String get cmdDvDeleteRule;

  /// No description provided for @cmdDvClearRange.
  ///
  /// In en, this message translates to:
  /// **'Remove data validation'**
  String get cmdDvClearRange;

  /// No description provided for @contextEditDropdown.
  ///
  /// In en, this message translates to:
  /// **'Edit dropdown'**
  String get contextEditDropdown;

  /// No description provided for @pickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get pickerSearch;

  /// No description provided for @pickerNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get pickerNoMatches;

  /// No description provided for @pickerNoItems.
  ///
  /// In en, this message translates to:
  /// **'This dropdown has no items'**
  String get pickerNoItems;

  /// No description provided for @pickerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit dropdown'**
  String get pickerEdit;

  /// No description provided for @pickerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pickerClear;

  /// No description provided for @pickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Dropdown of {cell}'**
  String pickerLabel(String cell);

  /// No description provided for @datePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of {cell}'**
  String datePickerLabel(String cell);

  /// No description provided for @linkCardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get linkCardCopy;

  /// No description provided for @linkCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get linkCardEdit;

  /// No description provided for @linkCardRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get linkCardRemove;

  /// No description provided for @linkCardInternal.
  ///
  /// In en, this message translates to:
  /// **'Range in this spreadsheet'**
  String get linkCardInternal;

  /// No description provided for @linkOpenExternalTitle.
  ///
  /// In en, this message translates to:
  /// **'Open external link?'**
  String get linkOpenExternalTitle;

  /// No description provided for @linkOpenExternalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get linkOpenExternalConfirm;

  /// No description provided for @linkSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, or search sheets and named ranges'**
  String get linkSearchPlaceholder;

  /// No description provided for @linkSearchHeading.
  ///
  /// In en, this message translates to:
  /// **'Sheets and named ranges'**
  String get linkSearchHeading;

  /// No description provided for @linkInternalHint.
  ///
  /// In en, this message translates to:
  /// **'Links to a place in this spreadsheet'**
  String get linkInternalHint;

  /// No description provided for @linkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a link (https://…, an email address or #sheet=…&range=…)'**
  String get linkInvalid;

  /// No description provided for @cmdLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get cmdLinkCopy;

  /// No description provided for @notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get notePlaceholder;

  /// No description provided for @noteEditorLabel.
  ///
  /// In en, this message translates to:
  /// **'Note of {cell}'**
  String noteEditorLabel(String cell);

  /// No description provided for @noteEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Esc or click outside to save'**
  String get noteEditorHint;

  /// No description provided for @errorTooltipTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTooltipTitle;

  /// No description provided for @errorHintRef.
  ///
  /// In en, this message translates to:
  /// **'A reference points to cells that don\'t exist (deleted rows, columns or sheets).'**
  String get errorHintRef;

  /// No description provided for @errorHintName.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling of function, sheet and named range names.'**
  String get errorHintName;

  /// No description provided for @spillTooltipTitle.
  ///
  /// In en, this message translates to:
  /// **'Array result'**
  String get spillTooltipTitle;

  /// No description provided for @cellInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get cellInfoNote;

  /// No description provided for @cellInfoHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get cellInfoHelp;

  /// No description provided for @ioReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get ioReportCopied;

  /// No description provided for @ioSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get ioSeverityInfo;

  /// No description provided for @ioSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get ioSeverityWarning;

  /// No description provided for @ioSeverityError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get ioSeverityError;

  /// No description provided for @ioCopyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get ioCopyReport;

  /// No description provided for @ioClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ioClose;

  /// No description provided for @ioReportSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get ioReportSheets;

  /// No description provided for @ioReportSheetSize.
  ///
  /// In en, this message translates to:
  /// **'{rows} × {columns} · {cells} cells'**
  String ioReportSheetSize(int rows, int columns, int cells);

  /// No description provided for @ioReportNoWarnings.
  ///
  /// In en, this message translates to:
  /// **'No warnings.'**
  String get ioReportNoWarnings;

  /// No description provided for @ioReportSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get ioReportSeverity;

  /// No description provided for @ioReportWhere.
  ///
  /// In en, this message translates to:
  /// **'Sheet / cell'**
  String get ioReportWhere;

  /// No description provided for @ioReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get ioReportMessage;

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import file'**
  String get importDialogTitle;

  /// No description provided for @importDialogImport.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importDialogImport;

  /// No description provided for @importLocationCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new spreadsheet'**
  String get importLocationCreateNew;

  /// No description provided for @importLocationInsertSheets.
  ///
  /// In en, this message translates to:
  /// **'Insert new sheet(s)'**
  String get importLocationInsertSheets;

  /// No description provided for @importLocationReplaceSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Replace spreadsheet'**
  String get importLocationReplaceSpreadsheet;

  /// No description provided for @importLocationReplaceSheet.
  ///
  /// In en, this message translates to:
  /// **'Replace current sheet'**
  String get importLocationReplaceSheet;

  /// No description provided for @importLocationAppend.
  ///
  /// In en, this message translates to:
  /// **'Append to current sheet'**
  String get importLocationAppend;

  /// No description provided for @importLocationReplaceAtCell.
  ///
  /// In en, this message translates to:
  /// **'Replace data at selected cell ({cell})'**
  String importLocationReplaceAtCell(String cell);

  /// No description provided for @importSeparatorAuto.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically'**
  String get importSeparatorAuto;

  /// No description provided for @importSeparatorAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically ({separator})'**
  String importSeparatorAutoDetected(String separator);

  /// No description provided for @importSeparatorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get importSeparatorCustom;

  /// No description provided for @importSeparatorTab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get importSeparatorTab;

  /// No description provided for @importSeparatorComma.
  ///
  /// In en, this message translates to:
  /// **'Comma'**
  String get importSeparatorComma;

  /// No description provided for @importSeparatorSemicolon.
  ///
  /// In en, this message translates to:
  /// **'Semicolon'**
  String get importSeparatorSemicolon;

  /// No description provided for @importSeparatorPipe.
  ///
  /// In en, this message translates to:
  /// **'Pipe'**
  String get importSeparatorPipe;

  /// No description provided for @importFileLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} ({size})'**
  String importFileLabel(String name, String size);

  /// No description provided for @importChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Change file'**
  String get importChangeFile;

  /// No description provided for @importDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drag a file here'**
  String get importDropHere;

  /// No description provided for @importSupportedTypes.
  ///
  /// In en, this message translates to:
  /// **'.xlsx, .ods, .csv, .tsv or .txt'**
  String get importSupportedTypes;

  /// No description provided for @importBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get importBrowse;

  /// No description provided for @importUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This file type can\'t be imported. Choose an .xlsx, .ods, .csv, .tsv or .txt file.'**
  String get importUnsupportedType;

  /// No description provided for @importLegacyXls.
  ///
  /// In en, this message translates to:
  /// **'Legacy .xls files can\'t be imported. Save the file as .xlsx and import it again.'**
  String get importLegacyXls;

  /// No description provided for @importEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {cells} cells'**
  String importEstimate(int cells);

  /// No description provided for @importLocation.
  ///
  /// In en, this message translates to:
  /// **'Import location'**
  String get importLocation;

  /// No description provided for @importReplaceSpreadsheetWarning.
  ///
  /// In en, this message translates to:
  /// **'All sheets of this spreadsheet will be deleted. Title, sharing and comments stay. You can undo this.'**
  String get importReplaceSpreadsheetWarning;

  /// No description provided for @importLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many cells'**
  String get importLimitTitle;

  /// No description provided for @importLimitBody.
  ///
  /// In en, this message translates to:
  /// **'This import would make the spreadsheet {cells} cells; the limit is {limit}. Import fewer sheets or a smaller file.'**
  String importLimitBody(int cells, int limit);

  /// No description provided for @importLargeNote.
  ///
  /// In en, this message translates to:
  /// **'Large import on this device may take a while.'**
  String get importLargeNote;

  /// No description provided for @importServerNote.
  ///
  /// In en, this message translates to:
  /// **'This large file will be imported on the server.'**
  String get importServerNote;

  /// No description provided for @importTabUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get importTabUpload;

  /// No description provided for @importTabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent uploads'**
  String get importTabRecent;

  /// No description provided for @importTabRecentShort.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get importTabRecentShort;

  /// No description provided for @importTabDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get importTabDrive;

  /// No description provided for @importRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Files you import on this device appear here.'**
  String get importRecentEmpty;

  /// No description provided for @importRecentItem.
  ///
  /// In en, this message translates to:
  /// **'{name} · {size} · {date}'**
  String importRecentItem(String name, String size, String date);

  /// No description provided for @importRecentGone.
  ///
  /// In en, this message translates to:
  /// **'This file is no longer stored on this device.'**
  String get importRecentGone;

  /// No description provided for @importDriveHint.
  ///
  /// In en, this message translates to:
  /// **'Import the sheets of another spreadsheet in your Drive.'**
  String get importDriveHint;

  /// No description provided for @importDriveOffline.
  ///
  /// In en, this message translates to:
  /// **'Importing from Drive needs a connection.'**
  String get importDriveOffline;

  /// No description provided for @importDrivePick.
  ///
  /// In en, this message translates to:
  /// **'Choose a spreadsheet'**
  String get importDrivePick;

  /// No description provided for @importDrivePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Drive'**
  String get importDrivePickTitle;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview (first 20 rows)'**
  String get importPreview;

  /// No description provided for @importSeparator.
  ///
  /// In en, this message translates to:
  /// **'Separator type'**
  String get importSeparator;

  /// No description provided for @importEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get importEncoding;

  /// No description provided for @importEncodingAuto.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically'**
  String get importEncodingAuto;

  /// No description provided for @importEncodingAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically ({encoding})'**
  String importEncodingAutoDetected(String encoding);

  /// No description provided for @importLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale for numbers & dates'**
  String get importLocale;

  /// No description provided for @importLocaleSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet ({locale})'**
  String importLocaleSpreadsheet(String locale);

  /// No description provided for @importConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert text to numbers, dates, and formulas'**
  String get importConvert;

  /// No description provided for @importSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets to import'**
  String get importSheets;

  /// No description provided for @importSheetHidden.
  ///
  /// In en, this message translates to:
  /// **'{name} (hidden)'**
  String importSheetHidden(String name);

  /// No description provided for @importUnsupportedFormulas.
  ///
  /// In en, this message translates to:
  /// **'Unsupported formulas'**
  String get importUnsupportedFormulas;

  /// No description provided for @importUnsupportedValue.
  ///
  /// In en, this message translates to:
  /// **'Keep last calculated value'**
  String get importUnsupportedValue;

  /// No description provided for @importUnsupportedText.
  ///
  /// In en, this message translates to:
  /// **'Keep formula as text'**
  String get importUnsupportedText;

  /// No description provided for @importParseFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read: {error}'**
  String importParseFailed(String error);

  /// No description provided for @importPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'The file has no data.'**
  String get importPreviewEmpty;

  /// No description provided for @importProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing {name}…'**
  String importProgressTitle(String name);

  /// No description provided for @importPhaseReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the file'**
  String get importPhaseReading;

  /// No description provided for @importPhaseWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing cells'**
  String get importPhaseWriting;

  /// No description provided for @importPhaseUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get importPhaseUploading;

  /// No description provided for @importPhaseQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your other import to finish'**
  String get importPhaseQueued;

  /// No description provided for @importPhaseWritingCells.
  ///
  /// In en, this message translates to:
  /// **'Writing cells ({done} of {total})'**
  String importPhaseWritingCells(int done, int total);

  /// No description provided for @importPhaseFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up'**
  String get importPhaseFinalizing;

  /// No description provided for @cmdFileCancelImport.
  ///
  /// In en, this message translates to:
  /// **'Cancel import'**
  String get cmdFileCancelImport;

  /// No description provided for @importCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get importCancel;

  /// No description provided for @importToastDone.
  ///
  /// In en, this message translates to:
  /// **'{summary}'**
  String importToastDone(String summary);

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Imported {sheets, plural, =1{1 sheet} other{{sheets} sheets}}, {cells} cells'**
  String importSummary(int sheets, int cells);

  /// No description provided for @importSummaryWarnings.
  ///
  /// In en, this message translates to:
  /// **'{summary} — {count, plural, =1{1 warning} other{{count} warnings}}'**
  String importSummaryWarnings(String summary, int count);

  /// No description provided for @importView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get importView;

  /// No description provided for @importOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get importOpen;

  /// No description provided for @importCreated.
  ///
  /// In en, this message translates to:
  /// **'Imported “{name}”'**
  String importCreated(String name);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// Error of /import?file= (Drive's Open with ▸ Wonky Sheets) without a connection.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet to open this file in Wonky Sheets.'**
  String get importRouteOffline;

  /// No description provided for @importRouteNotAFile.
  ///
  /// In en, this message translates to:
  /// **'This item isn\'t an uploaded file.'**
  String get importRouteNotAFile;

  /// No description provided for @importRouteUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Wonky Sheets can\'t open “{fileName}”.'**
  String importRouteUnsupported(String fileName);

  /// No description provided for @importRouteUploading.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” is still uploading. Try again when the upload has finished.'**
  String importRouteUploading(String fileName);

  /// No description provided for @importRouteDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be loaded from Wonky Drive.'**
  String get importRouteDownloadFailed;

  /// No description provided for @importSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import summary'**
  String get importSummaryTitle;

  /// No description provided for @importNoReport.
  ///
  /// In en, this message translates to:
  /// **'No import report yet.'**
  String get importNoReport;

  /// No description provided for @importUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'Import {name}'**
  String importUndoLabel(String name);

  /// No description provided for @importManyFiles.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} spreadsheets'**
  String importManyFiles(int count);

  /// No description provided for @cmdFileImportData.
  ///
  /// In en, this message translates to:
  /// **'Import data into this spreadsheet'**
  String get cmdFileImportData;

  /// No description provided for @cmdFileShowImportReport.
  ///
  /// In en, this message translates to:
  /// **'Show import summary'**
  String get cmdFileShowImportReport;

  /// No description provided for @cmdFilterRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove filter'**
  String get cmdFilterRemove;

  /// No description provided for @cmdFilterSetRange.
  ///
  /// In en, this message translates to:
  /// **'Change filter range'**
  String get cmdFilterSetRange;

  /// No description provided for @cmdFilterOpenColumnMenu.
  ///
  /// In en, this message translates to:
  /// **'Open filter menu'**
  String get cmdFilterOpenColumnMenu;

  /// No description provided for @cmdFilterSetColumnCriteria.
  ///
  /// In en, this message translates to:
  /// **'Filter column'**
  String get cmdFilterSetColumnCriteria;

  /// No description provided for @cmdFilterClearColumn.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get cmdFilterClearColumn;

  /// No description provided for @cmdFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get cmdFilterClearAll;

  /// No description provided for @cmdFilterSortColumn.
  ///
  /// In en, this message translates to:
  /// **'Sort filtered column'**
  String get cmdFilterSortColumn;

  /// No description provided for @filterByValueNoData.
  ///
  /// In en, this message translates to:
  /// **'Select a cell inside a table of data first.'**
  String get filterByValueNoData;

  /// No description provided for @filterByValueHeader.
  ///
  /// In en, this message translates to:
  /// **'Select a data cell below the header row.'**
  String get filterByValueHeader;

  /// No description provided for @cmdFilterSaveAsView.
  ///
  /// In en, this message translates to:
  /// **'Save as filter view'**
  String get cmdFilterSaveAsView;

  /// No description provided for @filterViewNone.
  ///
  /// In en, this message translates to:
  /// **'No filter view is open.'**
  String get filterViewNone;

  /// No description provided for @filterStickyRowBadge.
  ///
  /// In en, this message translates to:
  /// **'Hidden by filter'**
  String get filterStickyRowBadge;

  /// No description provided for @filterViewDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'This filter view no longer exists'**
  String get filterViewDeletedToast;

  /// No description provided for @cmdFilterViewRename.
  ///
  /// In en, this message translates to:
  /// **'Rename filter view'**
  String get cmdFilterViewRename;

  /// No description provided for @cmdFilterViewSetRange.
  ///
  /// In en, this message translates to:
  /// **'Update filter view range'**
  String get cmdFilterViewSetRange;

  /// No description provided for @cmdFilterViewDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate filter view'**
  String get cmdFilterViewDuplicate;

  /// No description provided for @filterViewCopyOf.
  ///
  /// In en, this message translates to:
  /// **'Copy of {name}'**
  String filterViewCopyOf(String name);

  /// No description provided for @cmdFilterViewSave.
  ///
  /// In en, this message translates to:
  /// **'Save view'**
  String get cmdFilterViewSave;

  /// No description provided for @cmdFilterViewDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete filter view'**
  String get cmdFilterViewDelete;

  /// No description provided for @cmdFilterViewCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link to filter view'**
  String get cmdFilterViewCopyLink;

  /// No description provided for @cmdFilterViewOpenPanel.
  ///
  /// In en, this message translates to:
  /// **'Manage filter views'**
  String get cmdFilterViewOpenPanel;

  /// No description provided for @cmdGroupColumnsSpan.
  ///
  /// In en, this message translates to:
  /// **'Group columns {span}'**
  String cmdGroupColumnsSpan(String span);

  /// No description provided for @cmdGroupRowsSpan.
  ///
  /// In en, this message translates to:
  /// **'Group rows {span}'**
  String cmdGroupRowsSpan(String span);

  /// No description provided for @cmdUngroupColumnsSpan.
  ///
  /// In en, this message translates to:
  /// **'Ungroup columns {span}'**
  String cmdUngroupColumnsSpan(String span);

  /// No description provided for @cmdUngroupRowsSpan.
  ///
  /// In en, this message translates to:
  /// **'Ungroup rows {span}'**
  String cmdUngroupRowsSpan(String span);

  /// No description provided for @cmdGroupToggle.
  ///
  /// In en, this message translates to:
  /// **'Expand or collapse group'**
  String get cmdGroupToggle;

  /// No description provided for @cmdGroupCollapseToLevel.
  ///
  /// In en, this message translates to:
  /// **'Show group level'**
  String get cmdGroupCollapseToLevel;

  /// No description provided for @cmdGroupRemoveAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all groups'**
  String get cmdGroupRemoveAll;

  /// No description provided for @menuExpandAllRowGroups.
  ///
  /// In en, this message translates to:
  /// **'Expand all row groups'**
  String get menuExpandAllRowGroups;

  /// No description provided for @menuCollapseAllRowGroups.
  ///
  /// In en, this message translates to:
  /// **'Collapse all row groups'**
  String get menuCollapseAllRowGroups;

  /// No description provided for @menuExpandAllColumnGroups.
  ///
  /// In en, this message translates to:
  /// **'Expand all column groups'**
  String get menuExpandAllColumnGroups;

  /// No description provided for @menuCollapseAllColumnGroups.
  ///
  /// In en, this message translates to:
  /// **'Collapse all column groups'**
  String get menuCollapseAllColumnGroups;

  /// No description provided for @sortColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Column {col}'**
  String sortColumnLabel(String col);

  /// No description provided for @sortDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort range from {range}'**
  String sortDialogTitle(String range);

  /// No description provided for @sortDialogHasHeader.
  ///
  /// In en, this message translates to:
  /// **'Data has header row'**
  String get sortDialogHasHeader;

  /// No description provided for @sortDialogSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortDialogSortBy;

  /// No description provided for @sortDialogThenBy.
  ///
  /// In en, this message translates to:
  /// **'then by'**
  String get sortDialogThenBy;

  /// No description provided for @sortDialogOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get sortDialogOrder;

  /// No description provided for @sortDialogAddColumn.
  ///
  /// In en, this message translates to:
  /// **'Add another sort column'**
  String get sortDialogAddColumn;

  /// No description provided for @sortDialogRemoveColumn.
  ///
  /// In en, this message translates to:
  /// **'Remove sort column'**
  String get sortDialogRemoveColumn;

  /// No description provided for @sortDialogSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortDialogSort;

  /// No description provided for @sortNeedsRows.
  ///
  /// In en, this message translates to:
  /// **'Select at least two rows of data to sort.'**
  String get sortNeedsRows;

  /// No description provided for @cmdFindClose.
  ///
  /// In en, this message translates to:
  /// **'Close find'**
  String get cmdFindClose;

  /// No description provided for @cmdFindNext.
  ///
  /// In en, this message translates to:
  /// **'Find next'**
  String get cmdFindNext;

  /// No description provided for @cmdFindPrevious.
  ///
  /// In en, this message translates to:
  /// **'Find previous'**
  String get cmdFindPrevious;

  /// No description provided for @cmdFindReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get cmdFindReplace;

  /// No description provided for @cmdFindReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get cmdFindReplaceAll;

  /// No description provided for @findNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get findNoMatches;

  /// No description provided for @dedupeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get dedupeTitle;

  /// No description provided for @dedupeRange.
  ///
  /// In en, this message translates to:
  /// **'Range {range}'**
  String dedupeRange(String range);

  /// No description provided for @dedupeSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get dedupeSelectAll;

  /// No description provided for @dedupeColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns to analyze'**
  String get dedupeColumns;

  /// No description provided for @dedupeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get dedupeRemove;

  /// No description provided for @dedupeNoData.
  ///
  /// In en, this message translates to:
  /// **'Select a range of data first.'**
  String get dedupeNoData;

  /// No description provided for @splitSingleColumn.
  ///
  /// In en, this message translates to:
  /// **'Please select a single column of data to split.'**
  String get splitSingleColumn;

  /// No description provided for @splitReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you want to replace existing data?'**
  String get splitReplaceTitle;

  /// No description provided for @splitReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'The cells to the right of the column contain data that will be replaced.'**
  String get splitReplaceBody;

  /// No description provided for @splitReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get splitReplace;

  /// No description provided for @splitNoSeparator.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t detect a separator'**
  String get splitNoSeparator;

  /// No description provided for @cmdColumnStatsSelectColumn.
  ///
  /// In en, this message translates to:
  /// **'Show column stats for column'**
  String get cmdColumnStatsSelectColumn;

  /// No description provided for @cmdNamedRangesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add named range'**
  String get cmdNamedRangesAdd;

  /// No description provided for @cmdNamedRangesUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit named range'**
  String get cmdNamedRangesUpdate;

  /// No description provided for @cmdNamedRangesDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove named range'**
  String get cmdNamedRangesDelete;

  /// No description provided for @cmdNamedRangesGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to named range'**
  String get cmdNamedRangesGoTo;

  /// No description provided for @cmdNamedFunctionsCreate.
  ///
  /// In en, this message translates to:
  /// **'Add named function'**
  String get cmdNamedFunctionsCreate;

  /// No description provided for @cmdNamedFunctionsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit named function'**
  String get cmdNamedFunctionsUpdate;

  /// No description provided for @cmdNamedFunctionsDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove named function'**
  String get cmdNamedFunctionsDelete;

  /// No description provided for @namedFunctionNeedsDefinition.
  ///
  /// In en, this message translates to:
  /// **'Enter a formula definition.'**
  String get namedFunctionNeedsDefinition;

  /// No description provided for @exportPhaseImages.
  ///
  /// In en, this message translates to:
  /// **'Fetching images'**
  String get exportPhaseImages;

  /// No description provided for @exportPhasePreparing.
  ///
  /// In en, this message translates to:
  /// **'Reading the spreadsheet'**
  String get exportPhasePreparing;

  /// No description provided for @exportPhaseWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing the file'**
  String get exportPhaseWriting;

  /// No description provided for @exportProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading {format}…'**
  String exportProgressTitle(String format);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get exportFailed;

  /// No description provided for @exportSaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {fileName}'**
  String exportSaveDialogTitle(String fileName);

  /// No description provided for @exportDoneWithNotes.
  ///
  /// In en, this message translates to:
  /// **'{fileName} — {count, plural, =1{1 feature} other{{count} features}} not exported exactly'**
  String exportDoneWithNotes(String fileName, int count);

  /// No description provided for @exportReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReportTitle;

  /// No description provided for @exportReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Features of this spreadsheet that {fileName} can\'t hold exactly.'**
  String exportReportSummary(String fileName);

  /// No description provided for @importWarningsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warning} other{{count} warnings}}'**
  String importWarningsCount(int count);

  /// No description provided for @printPhaseRendering.
  ///
  /// In en, this message translates to:
  /// **'Rendering {count, plural, =1{1 page} other{{count} pages}}'**
  String printPhaseRendering(int count);

  /// No description provided for @printBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get printBack;

  /// No description provided for @printTitle.
  ///
  /// In en, this message translates to:
  /// **'Print settings · {name}'**
  String printTitle(String name);

  /// No description provided for @printExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get printExportPdf;

  /// No description provided for @printPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printPrint;

  /// No description provided for @printScope.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printScope;

  /// No description provided for @printScopeSheet.
  ///
  /// In en, this message translates to:
  /// **'Current sheet'**
  String get printScopeSheet;

  /// No description provided for @printScopeWorkbook.
  ///
  /// In en, this message translates to:
  /// **'Workbook'**
  String get printScopeWorkbook;

  /// No description provided for @printScopeSelection.
  ///
  /// In en, this message translates to:
  /// **'Selected cells ({range})'**
  String printScopeSelection(String range);

  /// No description provided for @printApplyToAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all sheets'**
  String get printApplyToAll;

  /// No description provided for @printPaperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get printPaperSize;

  /// No description provided for @printPaperCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get printPaperCustom;

  /// No description provided for @printWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get printWidth;

  /// No description provided for @printHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get printHeight;

  /// No description provided for @printUnitIn.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get printUnitIn;

  /// No description provided for @printUnitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get printUnitCm;

  /// No description provided for @printOrientation.
  ///
  /// In en, this message translates to:
  /// **'Page orientation'**
  String get printOrientation;

  /// No description provided for @printPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get printPortrait;

  /// No description provided for @printLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get printLandscape;

  /// No description provided for @printScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get printScale;

  /// No description provided for @printScaleNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal (100%)'**
  String get printScaleNormal;

  /// No description provided for @printScaleFitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit to width'**
  String get printScaleFitWidth;

  /// No description provided for @printScaleFitHeight.
  ///
  /// In en, this message translates to:
  /// **'Fit to height'**
  String get printScaleFitHeight;

  /// No description provided for @printScaleFitPage.
  ///
  /// In en, this message translates to:
  /// **'Fit to page'**
  String get printScaleFitPage;

  /// No description provided for @printScaleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom number'**
  String get printScaleCustom;

  /// No description provided for @printScalePercent.
  ///
  /// In en, this message translates to:
  /// **'Percent (10–400)'**
  String get printScalePercent;

  /// No description provided for @printMargins.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get printMargins;

  /// No description provided for @printMarginsNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get printMarginsNormal;

  /// No description provided for @printMarginsNarrow.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get printMarginsNarrow;

  /// No description provided for @printMarginsWide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get printMarginsWide;

  /// No description provided for @printMarginsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get printMarginsCustom;

  /// No description provided for @printMarginTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get printMarginTop;

  /// No description provided for @printMarginBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get printMarginBottom;

  /// No description provided for @printMarginLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get printMarginLeft;

  /// No description provided for @printMarginRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get printMarginRight;

  /// No description provided for @printFormatting.
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get printFormatting;

  /// No description provided for @printGridlines.
  ///
  /// In en, this message translates to:
  /// **'Show gridlines'**
  String get printGridlines;

  /// No description provided for @printNotes.
  ///
  /// In en, this message translates to:
  /// **'Show notes'**
  String get printNotes;

  /// No description provided for @printHeadings.
  ///
  /// In en, this message translates to:
  /// **'Show row & column headers'**
  String get printHeadings;

  /// No description provided for @printRepeatFrozen.
  ///
  /// In en, this message translates to:
  /// **'Repeat frozen rows and columns'**
  String get printRepeatFrozen;

  /// No description provided for @printPageOrder.
  ///
  /// In en, this message translates to:
  /// **'Page order'**
  String get printPageOrder;

  /// No description provided for @printDownThenOver.
  ///
  /// In en, this message translates to:
  /// **'Down, then over'**
  String get printDownThenOver;

  /// No description provided for @printOverThenDown.
  ///
  /// In en, this message translates to:
  /// **'Over, then down'**
  String get printOverThenDown;

  /// No description provided for @printAlignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get printAlignment;

  /// No description provided for @printAlignHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get printAlignHorizontal;

  /// No description provided for @printAlignVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get printAlignVertical;

  /// No description provided for @printAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get printAlignLeft;

  /// No description provided for @printAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get printAlignCenter;

  /// No description provided for @printAlignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get printAlignRight;

  /// No description provided for @printAlignTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get printAlignTop;

  /// No description provided for @printAlignMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get printAlignMiddle;

  /// No description provided for @printAlignBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get printAlignBottom;

  /// No description provided for @printHeadersFooters.
  ///
  /// In en, this message translates to:
  /// **'Headers & footers'**
  String get printHeadersFooters;

  /// No description provided for @printPageNumbers.
  ///
  /// In en, this message translates to:
  /// **'Page numbers'**
  String get printPageNumbers;

  /// No description provided for @printWorkbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Workbook title'**
  String get printWorkbookTitle;

  /// No description provided for @printSheetName.
  ///
  /// In en, this message translates to:
  /// **'Sheet name'**
  String get printSheetName;

  /// No description provided for @printCurrentDate.
  ///
  /// In en, this message translates to:
  /// **'Current date'**
  String get printCurrentDate;

  /// No description provided for @printCurrentTime.
  ///
  /// In en, this message translates to:
  /// **'Current time'**
  String get printCurrentTime;

  /// No description provided for @printCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get printCustomFields;

  /// No description provided for @printHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get printHeader;

  /// No description provided for @printFooter.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get printFooter;

  /// No description provided for @printFieldLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get printFieldLeft;

  /// No description provided for @printFieldCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get printFieldCenter;

  /// No description provided for @printFieldRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get printFieldRight;

  /// No description provided for @printFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'Tokens you can use:'**
  String get printFieldsHint;

  /// No description provided for @printSetBreaks.
  ///
  /// In en, this message translates to:
  /// **'Set custom page breaks'**
  String get printSetBreaks;

  /// No description provided for @printBreaksTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom page breaks'**
  String get printBreaksTitle;

  /// No description provided for @printBreaksHint.
  ///
  /// In en, this message translates to:
  /// **'Pages break before these rows and columns. Drag the lines on the grid to move them, drag one off the grid to remove it, or click a row number or column letter to add one.'**
  String get printBreaksHint;

  /// No description provided for @printBreakCanvasLabel.
  ///
  /// In en, this message translates to:
  /// **'Page breaks of the current sheet. Dashed lines are automatic breaks, solid lines are custom breaks.'**
  String get printBreakCanvasLabel;

  /// No description provided for @printDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme for Export PDF'**
  String get printDarkTheme;

  /// No description provided for @printBreakRows.
  ///
  /// In en, this message translates to:
  /// **'Breaks before rows'**
  String get printBreakRows;

  /// No description provided for @printBreakCols.
  ///
  /// In en, this message translates to:
  /// **'Breaks before columns'**
  String get printBreakCols;

  /// No description provided for @printAddBreak.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get printAddBreak;

  /// No description provided for @printBreakRowPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Row, e.g. 21'**
  String get printBreakRowPlaceholder;

  /// No description provided for @printBreakColPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Column, e.g. F'**
  String get printBreakColPlaceholder;

  /// No description provided for @printConfirmBreaks.
  ///
  /// In en, this message translates to:
  /// **'Confirm breaks'**
  String get printConfirmBreaks;

  /// No description provided for @printResetBreaks.
  ///
  /// In en, this message translates to:
  /// **'Reset breaks'**
  String get printResetBreaks;

  /// No description provided for @printCancelBreaks.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get printCancelBreaks;

  /// No description provided for @printNoBreaks.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get printNoBreaks;

  /// No description provided for @printRemoveBreak.
  ///
  /// In en, this message translates to:
  /// **'Remove break'**
  String get printRemoveBreak;

  /// No description provided for @printResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get printResetSettings;

  /// No description provided for @printPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String printPageOf(int page, int pages);

  /// No description provided for @printPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pages} =1{1 page} other{{count} pages}}'**
  String printPageCount(int count);

  /// No description provided for @printZoomFit.
  ///
  /// In en, this message translates to:
  /// **'Fit width'**
  String get printZoomFit;

  /// No description provided for @printZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get printZoomIn;

  /// No description provided for @printZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get printZoomOut;

  /// No description provided for @printPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get printPrevPage;

  /// No description provided for @printNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get printNextPage;

  /// No description provided for @printNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to print'**
  String get printNothing;

  /// No description provided for @printNothingBody.
  ///
  /// In en, this message translates to:
  /// **'The sheet is empty or the selection has no visible cells.'**
  String get printNothingBody;

  /// No description provided for @printUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Printing isn\'t available here'**
  String get printUnavailableTitle;

  /// No description provided for @printUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Export the PDF and print it from your PDF viewer.'**
  String get printUnavailableBody;

  /// No description provided for @printViewerLocal.
  ///
  /// In en, this message translates to:
  /// **'You have view access: these settings apply to this print only.'**
  String get printViewerLocal;

  /// No description provided for @printDownloadsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Printing is turned off'**
  String get printDownloadsDisabledTitle;

  /// No description provided for @printDownloadsDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'The owner doesn\'t allow viewers to print or download this spreadsheet.'**
  String get printDownloadsDisabledBody;

  /// No description provided for @printLoading.
  ///
  /// In en, this message translates to:
  /// **'Opening the spreadsheet…'**
  String get printLoading;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be created'**
  String get printFailed;

  /// No description provided for @printPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String printPageLabel(int page);

  /// No description provided for @printInvalidRow.
  ///
  /// In en, this message translates to:
  /// **'Enter a row number between 2 and {max}.'**
  String printInvalidRow(int max);

  /// No description provided for @printInvalidColumn.
  ///
  /// In en, this message translates to:
  /// **'Enter a column letter after A.'**
  String get printInvalidColumn;

  /// No description provided for @cmdPrintUpdateSettings.
  ///
  /// In en, this message translates to:
  /// **'Change print settings'**
  String get cmdPrintUpdateSettings;

  /// No description provided for @cmdPrintResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset print settings'**
  String get cmdPrintResetSettings;

  /// No description provided for @cmdPrintEnterBreakMode.
  ///
  /// In en, this message translates to:
  /// **'Set custom page breaks'**
  String get cmdPrintEnterBreakMode;

  /// No description provided for @cmdPrintExitBreakMode.
  ///
  /// In en, this message translates to:
  /// **'Exit page break mode'**
  String get cmdPrintExitBreakMode;

  /// No description provided for @cmdPrintSetPageBreaks.
  ///
  /// In en, this message translates to:
  /// **'Set page breaks'**
  String get cmdPrintSetPageBreaks;

  /// No description provided for @cmdPrintPrint.
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get cmdPrintPrint;

  /// No description provided for @cmdPrintExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get cmdPrintExportPdf;

  /// No description provided for @categoryAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get categoryAi;

  /// No description provided for @aiPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiPanelTitle;

  /// No description provided for @aiTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'AI is turned off'**
  String get aiTurnedOff;

  /// No description provided for @aiTurnOnHint.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Settings › AI.'**
  String get aiTurnOnHint;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t available right now.'**
  String get aiUnavailable;

  /// No description provided for @aiAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiAgentLabel;

  /// No description provided for @aiUndoDefault.
  ///
  /// In en, this message translates to:
  /// **'AI edit'**
  String get aiUndoDefault;

  /// No description provided for @aiUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'AI: {summary}'**
  String aiUndoLabel(String summary);

  /// No description provided for @aiChipSheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet: {name}'**
  String aiChipSheet(String name);

  /// No description provided for @aiChipRanges.
  ///
  /// In en, this message translates to:
  /// **'{first} (+{more})'**
  String aiChipRanges(String first, int more);

  /// No description provided for @aiQuickAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get aiQuickAnalyze;

  /// No description provided for @aiQuickChart.
  ///
  /// In en, this message translates to:
  /// **'Build a chart'**
  String get aiQuickChart;

  /// No description provided for @aiQuickClean.
  ///
  /// In en, this message translates to:
  /// **'Clean data'**
  String get aiQuickClean;

  /// No description provided for @aiQuickFormula.
  ///
  /// In en, this message translates to:
  /// **'Write a formula'**
  String get aiQuickFormula;

  /// No description provided for @aiSuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest a formula'**
  String get aiSuggestTitle;

  /// No description provided for @aiSuggestPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the formula you need'**
  String get aiSuggestPlaceholder;

  /// No description provided for @aiSuggestAsk.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get aiSuggestAsk;

  /// No description provided for @aiSuggestInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get aiSuggestInsert;

  /// No description provided for @aiSuggestTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get aiSuggestTryAgain;

  /// No description provided for @aiSuggestResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {value}'**
  String aiSuggestResult(String value);

  /// No description provided for @aiSuggestExternal.
  ///
  /// In en, this message translates to:
  /// **'This formula fetches data from the internet.'**
  String get aiSuggestExternal;

  /// No description provided for @aiWorking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiWorking;

  /// No description provided for @aiExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'Explain formula'**
  String get aiExplainTitle;

  /// No description provided for @aiExplainToPanel.
  ///
  /// In en, this message translates to:
  /// **'Open in Assistant'**
  String get aiExplainToPanel;

  /// No description provided for @aiExplainResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Explanation of {cell}'**
  String aiExplainResultTitle(String cell);

  /// No description provided for @aiNoFormula.
  ///
  /// In en, this message translates to:
  /// **'The cell has no formula.'**
  String get aiNoFormula;

  /// No description provided for @aiFillTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill with AI'**
  String get aiFillTitle;

  /// No description provided for @aiFillDescription.
  ///
  /// In en, this message translates to:
  /// **'Proposals for the empty cells of {range}, learned from the filled ones. Nothing is written until you apply.'**
  String aiFillDescription(String range);

  /// No description provided for @aiFillInstructionsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional), e.g. \"Use the ISO country code\"'**
  String get aiFillInstructionsPlaceholder;

  /// No description provided for @aiFillRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiFillRegenerate;

  /// No description provided for @aiFillGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating proposals…'**
  String get aiFillGenerating;

  /// No description provided for @aiFillApply.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Apply} =1{Apply 1 value} other{Apply {count} values}}'**
  String aiFillApply(int count);

  /// No description provided for @aiFillSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 proposal} other{{count} proposals}} from {examples, plural, =1{1 example} other{{examples} examples}}. Low-confidence values are unchecked.'**
  String aiFillSummary(int count, int examples);

  /// No description provided for @aiFillTruncated.
  ///
  /// In en, this message translates to:
  /// **'Only the first 2,000 empty cells were filled. Run Fill with AI again for the rest.'**
  String get aiFillTruncated;

  /// No description provided for @aiFillNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fill: there are no empty cells next to data in this column.'**
  String get aiFillNothing;

  /// No description provided for @aiFillColumnCell.
  ///
  /// In en, this message translates to:
  /// **'Cell'**
  String get aiFillColumnCell;

  /// No description provided for @aiFillColumnInputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get aiFillColumnInputs;

  /// No description provided for @aiFillColumnValue.
  ///
  /// In en, this message translates to:
  /// **'Proposed value'**
  String get aiFillColumnValue;

  /// No description provided for @aiFillColumnConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get aiFillColumnConfidence;

  /// No description provided for @aiConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get aiConfidenceHigh;

  /// No description provided for @aiConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get aiConfidenceMedium;

  /// No description provided for @aiConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get aiConfidenceLow;

  /// No description provided for @aiPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'AI changes preview'**
  String get aiPreviewTitle;

  /// No description provided for @aiPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'The assistant suggested these changes. Check the ones to apply; they are applied as one undo step.'**
  String get aiPreviewDescription;

  /// No description provided for @aiPreviewApply.
  ///
  /// In en, this message translates to:
  /// **'Apply selected'**
  String get aiPreviewApply;

  /// No description provided for @aiPreviewDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aiPreviewDiscard;

  /// No description provided for @aiPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'The assistant suggested no changes.'**
  String get aiPreviewEmpty;

  /// No description provided for @aiPreviewCells.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cell} other{{count} cells}}'**
  String aiPreviewCells(int count);

  /// No description provided for @aiPreviewMoreCells.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more cell} other{and {count} more cells}}'**
  String aiPreviewMoreCells(int count);

  /// No description provided for @aiPreviewNoCells.
  ///
  /// In en, this message translates to:
  /// **'No cell values change.'**
  String get aiPreviewNoCells;

  /// No description provided for @aiPreviewCell.
  ///
  /// In en, this message translates to:
  /// **'Cell'**
  String get aiPreviewCell;

  /// No description provided for @aiPreviewBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get aiPreviewBefore;

  /// No description provided for @aiPreviewAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get aiPreviewAfter;

  /// No description provided for @aiPreviewReview.
  ///
  /// In en, this message translates to:
  /// **'Review suggested changes'**
  String get aiPreviewReview;

  /// No description provided for @aiPreviewAppliedNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested changes applied.'**
  String get aiPreviewAppliedNote;

  /// No description provided for @aiPreviewDiscardedNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested changes discarded.'**
  String get aiPreviewDiscardedNote;

  /// No description provided for @aiPreviewSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cell was changed by someone else and kept.} other{{count} cells were changed by someone else and kept.}}'**
  String aiPreviewSkipped(int count);

  /// No description provided for @aiDescribeChartResult.
  ///
  /// In en, this message translates to:
  /// **'Alt text proposal'**
  String get aiDescribeChartResult;

  /// No description provided for @aiInsertUndo.
  ///
  /// In en, this message translates to:
  /// **'Insert AI result'**
  String get aiInsertUndo;

  /// No description provided for @cmdAiCleanupSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Clean up data with AI'**
  String get cmdAiCleanupSuggestions;

  /// No description provided for @cmdAiRefreshAiCells.
  ///
  /// In en, this message translates to:
  /// **'Refresh AI cells'**
  String get cmdAiRefreshAiCells;

  /// No description provided for @aiCleanupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Clean up the data {scope}. The automatic checks found:\n{findings}\nGroup the problems, explain them briefly and propose fixes as suggested changes I can review.'**
  String aiCleanupPrompt(String scope, String findings);

  /// No description provided for @aiCleanupScopeRange.
  ///
  /// In en, this message translates to:
  /// **'in {range}'**
  String aiCleanupScopeRange(String range);

  /// No description provided for @aiCleanupScopeSheet.
  ///
  /// In en, this message translates to:
  /// **'on the sheet \"{name}\"'**
  String aiCleanupScopeSheet(String name);

  /// No description provided for @aiCleanupNothing.
  ///
  /// In en, this message translates to:
  /// **'- nothing obvious (check the data anyway)'**
  String get aiCleanupNothing;

  /// No description provided for @aiAgentMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP agent'**
  String get aiAgentMcp;

  /// No description provided for @aiAgentOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s agent'**
  String aiAgentOf(String name);

  /// No description provided for @aiAgentAiOf.
  ///
  /// In en, this message translates to:
  /// **'AI · {name}'**
  String aiAgentAiOf(String name);

  /// No description provided for @aiAssistantEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about this spreadsheet or tell the assistant what to change.'**
  String get aiAssistantEmptyTitle;

  /// No description provided for @aiAssistantPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'The assistant sends this spreadsheet and your messages to the AI provider to generate answers.'**
  String get aiAssistantPrivacyNotice;

  /// No description provided for @aiAssistantPrivacyNoticeProvider.
  ///
  /// In en, this message translates to:
  /// **'The assistant sends this spreadsheet and your messages to {provider} to generate answers.'**
  String aiAssistantPrivacyNoticeProvider(String provider);

  /// No description provided for @aiAssistantModeEditHint.
  ///
  /// In en, this message translates to:
  /// **'Edit directly: changes go straight into the spreadsheet'**
  String get aiAssistantModeEditHint;

  /// No description provided for @aiAssistantModeEditUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You can only suggest changes in this spreadsheet'**
  String get aiAssistantModeEditUnavailable;

  /// No description provided for @aiAssistantModeSuggestHint.
  ///
  /// In en, this message translates to:
  /// **'Suggest: changes arrive as a preview to apply or discard'**
  String get aiAssistantModeSuggestHint;

  /// No description provided for @cmdAiSuggestFormulaDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe a formula in words and get it written for the active cell'**
  String get cmdAiSuggestFormulaDescription;

  /// No description provided for @cmdAiFillRangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill the empty cells of a column from the examples in it'**
  String get cmdAiFillRangeDescription;

  /// No description provided for @cmdAiDescribeChart.
  ///
  /// In en, this message translates to:
  /// **'Describe chart with AI'**
  String get cmdAiDescribeChart;

  /// No description provided for @cmdAiApplyPreview.
  ///
  /// In en, this message translates to:
  /// **'Apply AI changes'**
  String get cmdAiApplyPreview;

  /// No description provided for @cmdAiDiscardPreview.
  ///
  /// In en, this message translates to:
  /// **'Discard AI changes'**
  String get cmdAiDiscardPreview;

  /// No description provided for @cmdAiInsertResult.
  ///
  /// In en, this message translates to:
  /// **'Insert AI result'**
  String get cmdAiInsertResult;

  /// No description provided for @explorePanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explorePanelTitle;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to explore yet'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Select cells with data, or click into a table.'**
  String get exploreEmptyBody;

  /// No description provided for @exploreSelectionStats.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get exploreSelectionStats;

  /// No description provided for @exploreSuggestedCharts.
  ///
  /// In en, this message translates to:
  /// **'Suggested charts'**
  String get exploreSuggestedCharts;

  /// No description provided for @exploreNoCharts.
  ///
  /// In en, this message translates to:
  /// **'No chart fits this data.'**
  String get exploreNoCharts;

  /// No description provided for @exploreCreatePivot.
  ///
  /// In en, this message translates to:
  /// **'Create a pivot table'**
  String get exploreCreatePivot;

  /// No description provided for @exploreInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get exploreInsights;

  /// No description provided for @exploreAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about this data'**
  String get exploreAskTitle;

  /// No description provided for @exploreAskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask a question about this data'**
  String get exploreAskPlaceholder;

  /// No description provided for @exploreAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get exploreAsk;

  /// No description provided for @condNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get condNone;

  /// No description provided for @condBlank.
  ///
  /// In en, this message translates to:
  /// **'Is empty'**
  String get condBlank;

  /// No description provided for @condNotBlank.
  ///
  /// In en, this message translates to:
  /// **'Is not empty'**
  String get condNotBlank;

  /// No description provided for @condTextContains.
  ///
  /// In en, this message translates to:
  /// **'Text contains'**
  String get condTextContains;

  /// No description provided for @condTextNotContains.
  ///
  /// In en, this message translates to:
  /// **'Text does not contain'**
  String get condTextNotContains;

  /// No description provided for @condTextStartsWith.
  ///
  /// In en, this message translates to:
  /// **'Text starts with'**
  String get condTextStartsWith;

  /// No description provided for @condTextEndsWith.
  ///
  /// In en, this message translates to:
  /// **'Text ends with'**
  String get condTextEndsWith;

  /// No description provided for @condTextEq.
  ///
  /// In en, this message translates to:
  /// **'Text is exactly'**
  String get condTextEq;

  /// No description provided for @condDateEq.
  ///
  /// In en, this message translates to:
  /// **'Date is'**
  String get condDateEq;

  /// No description provided for @condDateBefore.
  ///
  /// In en, this message translates to:
  /// **'Date is before'**
  String get condDateBefore;

  /// No description provided for @condDateAfter.
  ///
  /// In en, this message translates to:
  /// **'Date is after'**
  String get condDateAfter;

  /// No description provided for @condNumberGreater.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get condNumberGreater;

  /// No description provided for @condNumberGreaterEq.
  ///
  /// In en, this message translates to:
  /// **'Greater than or equal to'**
  String get condNumberGreaterEq;

  /// No description provided for @condNumberLess.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get condNumberLess;

  /// No description provided for @condNumberLessEq.
  ///
  /// In en, this message translates to:
  /// **'Less than or equal to'**
  String get condNumberLessEq;

  /// No description provided for @condNumberEq.
  ///
  /// In en, this message translates to:
  /// **'Is equal to'**
  String get condNumberEq;

  /// No description provided for @condNumberNotEq.
  ///
  /// In en, this message translates to:
  /// **'Is not equal to'**
  String get condNumberNotEq;

  /// No description provided for @condNumberBetween.
  ///
  /// In en, this message translates to:
  /// **'Is between'**
  String get condNumberBetween;

  /// No description provided for @condNumberNotBetween.
  ///
  /// In en, this message translates to:
  /// **'Is not between'**
  String get condNumberNotBetween;

  /// No description provided for @condCustomFormula.
  ///
  /// In en, this message translates to:
  /// **'Custom formula is'**
  String get condCustomFormula;

  /// No description provided for @condExactDate.
  ///
  /// In en, this message translates to:
  /// **'Exact date'**
  String get condExactDate;

  /// No description provided for @condToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get condToday;

  /// No description provided for @condTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get condTomorrow;

  /// No description provided for @condYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get condYesterday;

  /// No description provided for @condPastWeek.
  ///
  /// In en, this message translates to:
  /// **'In the past week'**
  String get condPastWeek;

  /// No description provided for @condPastMonth.
  ///
  /// In en, this message translates to:
  /// **'In the past month'**
  String get condPastMonth;

  /// No description provided for @condPastYear.
  ///
  /// In en, this message translates to:
  /// **'In the past year'**
  String get condPastYear;

  /// No description provided for @condValuePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Value or formula'**
  String get condValuePlaceholder;

  /// No description provided for @condFormulaPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'=B2>100'**
  String get condFormulaPlaceholder;

  /// No description provided for @filterByColor.
  ///
  /// In en, this message translates to:
  /// **'Filter by color'**
  String get filterByColor;

  /// No description provided for @filterSortByColor.
  ///
  /// In en, this message translates to:
  /// **'Sort by color'**
  String get filterSortByColor;

  /// No description provided for @sortHeaderToastTitle.
  ///
  /// In en, this message translates to:
  /// **'Sorted including row 1'**
  String get sortHeaderToastTitle;

  /// No description provided for @sortHeaderToastBody.
  ///
  /// In en, this message translates to:
  /// **'Row 1 looks like a header row.'**
  String get sortHeaderToastBody;

  /// No description provided for @sortHeaderToastAction.
  ///
  /// In en, this message translates to:
  /// **'Freeze row 1 and re-sort'**
  String get sortHeaderToastAction;

  /// No description provided for @dataJobWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the current operation to finish…'**
  String get dataJobWaiting;

  /// No description provided for @dataJobCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dataJobCancel;

  /// No description provided for @dataJobCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Nothing was changed.'**
  String get dataJobCancelled;

  /// No description provided for @dataJobSorting.
  ///
  /// In en, this message translates to:
  /// **'Sorting {count} rows…'**
  String dataJobSorting(int count);

  /// No description provided for @dataJobDeduping.
  ///
  /// In en, this message translates to:
  /// **'Removing duplicates in {count} rows…'**
  String dataJobDeduping(int count);

  /// No description provided for @dataJobSplitting.
  ///
  /// In en, this message translates to:
  /// **'Splitting {count} rows…'**
  String dataJobSplitting(int count);

  /// No description provided for @dataJobTrimming.
  ///
  /// In en, this message translates to:
  /// **'Trimming whitespace in {count} rows…'**
  String dataJobTrimming(int count);

  /// No description provided for @dataJobRandomizing.
  ///
  /// In en, this message translates to:
  /// **'Randomizing {count} rows…'**
  String dataJobRandomizing(int count);

  /// No description provided for @dataJobCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up {count} rows…'**
  String dataJobCleaning(int count);

  /// No description provided for @filterByCondition.
  ///
  /// In en, this message translates to:
  /// **'Filter by condition'**
  String get filterByCondition;

  /// No description provided for @filterByValues.
  ///
  /// In en, this message translates to:
  /// **'Filter by values'**
  String get filterByValues;

  /// No description provided for @filterFillColor.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get filterFillColor;

  /// No description provided for @filterTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get filterTextColor;

  /// No description provided for @filterNoColors.
  ///
  /// In en, this message translates to:
  /// **'No colors in this column'**
  String get filterNoColors;

  /// No description provided for @filterHiddenByOthers.
  ///
  /// In en, this message translates to:
  /// **'Hidden by other filters'**
  String get filterHiddenByOthers;

  /// No description provided for @filterSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all {count}'**
  String filterSelectAll(int count);

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get filterSearch;

  /// No description provided for @filterNoValues.
  ///
  /// In en, this message translates to:
  /// **'No matching values'**
  String get filterNoValues;

  /// No description provided for @filterShowingOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total} values — refine your search'**
  String filterShowingOf(int count, int total);

  /// No description provided for @filterBlanks.
  ///
  /// In en, this message translates to:
  /// **'(Blanks)'**
  String get filterBlanks;

  /// No description provided for @filterViewerHint.
  ///
  /// In en, this message translates to:
  /// **'You have view access — use a temporary filter view'**
  String get filterViewerHint;

  /// No description provided for @filterViewSortUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sort by color isn\'t available in filter views'**
  String get filterViewSortUnavailable;

  /// No description provided for @cmdFilterViewSortColumn.
  ///
  /// In en, this message translates to:
  /// **'Sort filter view'**
  String get cmdFilterViewSortColumn;

  /// No description provided for @viewSortCutUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rows in a sorted filter view can\'t be cut together. Copy them instead.'**
  String get viewSortCutUnavailable;

  /// No description provided for @viewSortCutPasteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A cut can\'t be pasted into the rows of a sorted filter view. Copy it instead.'**
  String get viewSortCutPasteUnavailable;

  /// No description provided for @filterViewClearSort.
  ///
  /// In en, this message translates to:
  /// **'Clear view sort'**
  String get filterViewClearSort;

  /// No description provided for @filterViewSortedBy.
  ///
  /// In en, this message translates to:
  /// **'Sorted by {column}'**
  String filterViewSortedBy(String column);

  /// No description provided for @findNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get findNoResults;

  /// No description provided for @findMatchesCount.
  ///
  /// In en, this message translates to:
  /// **'{matches} matches'**
  String findMatchesCount(String matches);

  /// No description provided for @findOfCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {matches}'**
  String findOfCount(int current, String matches);

  /// No description provided for @findPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Find in sheet'**
  String get findPlaceholder;

  /// No description provided for @findClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get findClose;

  /// No description provided for @findReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get findReplaceTitle;

  /// No description provided for @findLabel.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findLabel;

  /// No description provided for @replaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get replaceLabel;

  /// No description provided for @findSearchIn.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get findSearchIn;

  /// No description provided for @findRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get findRange;

  /// No description provided for @findButton.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findButton;

  /// No description provided for @findMatchCase.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get findMatchCase;

  /// No description provided for @findMatchEntireCell.
  ///
  /// In en, this message translates to:
  /// **'Match entire cell contents'**
  String get findMatchEntireCell;

  /// No description provided for @findUseRegex.
  ///
  /// In en, this message translates to:
  /// **'Search using regular expressions'**
  String get findUseRegex;

  /// No description provided for @findSearchFormulas.
  ///
  /// In en, this message translates to:
  /// **'Also search within formulas'**
  String get findSearchFormulas;

  /// No description provided for @findSearchLinks.
  ///
  /// In en, this message translates to:
  /// **'Also search within links'**
  String get findSearchLinks;

  /// No description provided for @findAllSheets.
  ///
  /// In en, this message translates to:
  /// **'All sheets'**
  String get findAllSheets;

  /// No description provided for @findThisSheet.
  ///
  /// In en, this message translates to:
  /// **'This sheet'**
  String get findThisSheet;

  /// No description provided for @findSpecificRange.
  ///
  /// In en, this message translates to:
  /// **'Specific range'**
  String get findSpecificRange;

  /// No description provided for @splitSeparator.
  ///
  /// In en, this message translates to:
  /// **'Separator:'**
  String get splitSeparator;

  /// No description provided for @splitDetect.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically'**
  String get splitDetect;

  /// No description provided for @splitComma.
  ///
  /// In en, this message translates to:
  /// **'Comma'**
  String get splitComma;

  /// No description provided for @splitSemicolon.
  ///
  /// In en, this message translates to:
  /// **'Semicolon'**
  String get splitSemicolon;

  /// No description provided for @splitPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get splitPeriod;

  /// No description provided for @splitSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get splitSpace;

  /// No description provided for @splitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get splitCustom;

  /// No description provided for @filterViewName.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get filterViewName;

  /// No description provided for @filterViewRange.
  ///
  /// In en, this message translates to:
  /// **'Range:'**
  String get filterViewRange;

  /// No description provided for @filterViewTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary filter view — only you see it'**
  String get filterViewTemporary;

  /// No description provided for @filterViewClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get filterViewClose;

  /// No description provided for @filterViewOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filterViewOpen;

  /// No description provided for @filterViewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter views'**
  String get filterViewsTitle;

  /// No description provided for @filterViewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No filter views on this sheet yet.'**
  String get filterViewsEmpty;

  /// No description provided for @filterViewTemporaryShort.
  ///
  /// In en, this message translates to:
  /// **'Temporary — only you see it'**
  String get filterViewTemporaryShort;

  /// No description provided for @namedRangesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No named ranges yet. Name a range to use it in formulas, e.g. =SUM(Sales).'**
  String get namedRangesEmpty;

  /// No description provided for @namedRangesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a range'**
  String get namedRangesAdd;

  /// No description provided for @namedRangesRefError.
  ///
  /// In en, this message translates to:
  /// **'#REF!'**
  String get namedRangesRefError;

  /// No description provided for @namedRangesName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get namedRangesName;

  /// No description provided for @namedRangesRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get namedRangesRange;

  /// No description provided for @namedRangesUseSelection.
  ///
  /// In en, this message translates to:
  /// **'Use the current selection'**
  String get namedRangesUseSelection;

  /// No description provided for @namedRangesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get namedRangesRemove;

  /// No description provided for @namedRangesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage named ranges'**
  String get namedRangesManage;

  /// No description provided for @namedRangesNone.
  ///
  /// In en, this message translates to:
  /// **'No named ranges'**
  String get namedRangesNone;

  /// No description provided for @namedFunctionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create custom functions from formulas and use them like built-in functions, for example:'**
  String get namedFunctionsEmpty;

  /// No description provided for @namedFunctionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add new function'**
  String get namedFunctionsAdd;

  /// No description provided for @namedFunctionsImport.
  ///
  /// In en, this message translates to:
  /// **'Import function'**
  String get namedFunctionsImport;

  /// No description provided for @cmdNamedFunctionsImport.
  ///
  /// In en, this message translates to:
  /// **'Import named functions'**
  String get cmdNamedFunctionsImport;

  /// No description provided for @importFunctionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import named functions'**
  String get importFunctionsTitle;

  /// No description provided for @importFunctionsPickSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Choose the spreadsheet to import from.'**
  String get importFunctionsPickSpreadsheet;

  /// No description provided for @importFunctionsPickFunctions.
  ///
  /// In en, this message translates to:
  /// **'Functions in {name}'**
  String importFunctionsPickFunctions(String name);

  /// No description provided for @importFunctionsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get importFunctionsBack;

  /// No description provided for @importFunctionsImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importFunctionsImport;

  /// No description provided for @importFunctionsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search spreadsheets'**
  String get importFunctionsSearch;

  /// No description provided for @importFunctionsNoSpreadsheets.
  ///
  /// In en, this message translates to:
  /// **'No spreadsheets found'**
  String get importFunctionsNoSpreadsheets;

  /// No description provided for @importFunctionsNone.
  ///
  /// In en, this message translates to:
  /// **'This spreadsheet has no named functions.'**
  String get importFunctionsNone;

  /// No description provided for @importFunctionsDependency.
  ///
  /// In en, this message translates to:
  /// **'Imported because a selected function uses it'**
  String get importFunctionsDependency;

  /// No description provided for @importFunctionsReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace functions with the same name'**
  String get importFunctionsReplace;

  /// No description provided for @importFunctionsOffline.
  ///
  /// In en, this message translates to:
  /// **'Importing functions needs a connection.'**
  String get importFunctionsOffline;

  /// No description provided for @importFunctionsDone.
  ///
  /// In en, this message translates to:
  /// **'{imported, plural, =0{No functions imported} =1{1 function imported} other{{imported} functions imported}}{skipped, plural, =0{} =1{ · 1 skipped (name exists)} other{ · {skipped} skipped (names exist)}}'**
  String importFunctionsDone(int imported, int skipped);

  /// No description provided for @cmdCleanupApplySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Apply cleanup suggestion'**
  String get cmdCleanupApplySuggestion;

  /// No description provided for @cleanupNumbersAsText.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Convert 1 cell in column {column} to a number} other{Convert {count} cells in column {column} to numbers}}'**
  String cleanupNumbersAsText(int count, String column);

  /// No description provided for @cleanupWhitespace.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Trim extra spaces in 1 cell of column {column}} other{Trim extra spaces in {count} cells of column {column}}}'**
  String cleanupWhitespace(int count, String column);

  /// No description provided for @cleanupDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Remove 1 duplicate row} other{Remove {count} duplicate rows}}'**
  String cleanupDuplicates(int count);

  /// No description provided for @cleanupCapitalization.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Make the capitalization of 1 value in column {column} consistent} other{Make the capitalization of {count} values in column {column} consistent}}'**
  String cleanupCapitalization(int count, String column);

  /// No description provided for @cleanupEmptyRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 empty row inside the data} other{Delete {count} empty rows inside the data}}'**
  String cleanupEmptyRows(int count);

  /// No description provided for @cleanupMixedTypes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Column {column} has numbers and 1 text value} other{Column {column} has numbers and {count} text values}}'**
  String cleanupMixedTypes(String column, int count);

  /// No description provided for @cleanupRow.
  ///
  /// In en, this message translates to:
  /// **'Row {row}'**
  String cleanupRow(String row);

  /// No description provided for @cleanupApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cleanupApply;

  /// No description provided for @cleanupDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get cleanupDismiss;

  /// No description provided for @cleanupColumnStats.
  ///
  /// In en, this message translates to:
  /// **'Column stats'**
  String get cleanupColumnStats;

  /// No description provided for @cleanupNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Looks clean'**
  String get cleanupNoneTitle;

  /// No description provided for @cleanupNoneBody.
  ///
  /// In en, this message translates to:
  /// **'No cleanup suggestions for this sheet.'**
  String get cleanupNoneBody;

  /// No description provided for @cleanupGone.
  ///
  /// In en, this message translates to:
  /// **'This suggestion no longer applies.'**
  String get cleanupGone;

  /// No description provided for @namedFunctionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get namedFunctionsEdit;

  /// No description provided for @namedFunctionsArgDescription.
  ///
  /// In en, this message translates to:
  /// **'Description of {param}'**
  String namedFunctionsArgDescription(String param);

  /// No description provided for @namedFunctionsArgExample.
  ///
  /// In en, this message translates to:
  /// **'Example value for {param}'**
  String namedFunctionsArgExample(String param);

  /// No description provided for @namedFunctionsPreview.
  ///
  /// In en, this message translates to:
  /// **'Function preview'**
  String get namedFunctionsPreview;

  /// No description provided for @namedFunctionsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get namedFunctionsUpdate;

  /// No description provided for @namedFunctionsName.
  ///
  /// In en, this message translates to:
  /// **'Function name'**
  String get namedFunctionsName;

  /// No description provided for @namedFunctionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Function description'**
  String get namedFunctionsDescription;

  /// No description provided for @namedFunctionsParams.
  ///
  /// In en, this message translates to:
  /// **'Argument placeholders'**
  String get namedFunctionsParams;

  /// No description provided for @namedFunctionsParamHint.
  ///
  /// In en, this message translates to:
  /// **'Type an argument name and press Enter'**
  String get namedFunctionsParamHint;

  /// No description provided for @namedFunctionsDefinition.
  ///
  /// In en, this message translates to:
  /// **'Formula definition'**
  String get namedFunctionsDefinition;

  /// No description provided for @namedFunctionsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get namedFunctionsNext;

  /// No description provided for @columnStatsIgnoreHeader.
  ///
  /// In en, this message translates to:
  /// **'Ignore header row'**
  String get columnStatsIgnoreHeader;

  /// No description provided for @columnStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This column has no data.'**
  String get columnStatsEmpty;

  /// No description provided for @columnStatsCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get columnStatsCount;

  /// No description provided for @columnStatsValues.
  ///
  /// In en, this message translates to:
  /// **'Values {count}'**
  String columnStatsValues(int count);

  /// No description provided for @columnStatsEmptyCount.
  ///
  /// In en, this message translates to:
  /// **'Empty {count}'**
  String columnStatsEmptyCount(int count);

  /// No description provided for @columnStatsUnique.
  ///
  /// In en, this message translates to:
  /// **'Unique {count}'**
  String columnStatsUnique(int count);

  /// No description provided for @columnStatsDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get columnStatsDistribution;

  /// No description provided for @columnStatsTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get columnStatsTable;

  /// No description provided for @columnStatsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get columnStatsFrequency;

  /// No description provided for @columnStatsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get columnStatsShowMore;

  /// No description provided for @columnStatsSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get columnStatsSummary;

  /// No description provided for @columnStatsSum.
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get columnStatsSum;

  /// No description provided for @columnStatsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get columnStatsAverage;

  /// No description provided for @columnStatsMedian.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get columnStatsMedian;

  /// No description provided for @columnStatsMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get columnStatsMin;

  /// No description provided for @columnStatsMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get columnStatsMax;

  /// No description provided for @columnStatsShortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest text length'**
  String get columnStatsShortest;

  /// No description provided for @columnStatsLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest text length'**
  String get columnStatsLongest;

  /// No description provided for @goToTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to range'**
  String get goToTitle;

  /// No description provided for @goToLabel.
  ///
  /// In en, this message translates to:
  /// **'Cell, range or named range'**
  String get goToLabel;

  /// No description provided for @goToInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid cell, range or named range'**
  String get goToInvalid;

  /// No description provided for @goToButton.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goToButton;

  /// No description provided for @panelChartEditor.
  ///
  /// In en, this message translates to:
  /// **'Chart editor'**
  String get panelChartEditor;

  /// No description provided for @categoryCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get categoryCharts;

  /// No description provided for @categoryImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get categoryImages;

  /// No description provided for @categoryObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get categoryObjects;

  /// No description provided for @chartAggregateAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get chartAggregateAverage;

  /// No description provided for @chartAggregateCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get chartAggregateCount;

  /// No description provided for @chartAggregateMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get chartAggregateMax;

  /// No description provided for @chartAggregateMedian.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get chartAggregateMedian;

  /// No description provided for @chartAggregateMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get chartAggregateMin;

  /// No description provided for @chartAggregateSum.
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get chartAggregateSum;

  /// No description provided for @chartAlignAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get chartAlignAuto;

  /// No description provided for @chartAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get chartAlignCenter;

  /// No description provided for @chartAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get chartAlignLeft;

  /// No description provided for @chartAlignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get chartAlignRight;

  /// No description provided for @chartAxisLeft.
  ///
  /// In en, this message translates to:
  /// **'Left axis'**
  String get chartAxisLeft;

  /// No description provided for @chartAxisRight.
  ///
  /// In en, this message translates to:
  /// **'Right axis'**
  String get chartAxisRight;

  /// No description provided for @chartCompareCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get chartCompareCategory;

  /// No description provided for @chartCompareDatum.
  ///
  /// In en, this message translates to:
  /// **'Datum'**
  String get chartCompareDatum;

  /// No description provided for @chartCompareOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get chartCompareOff;

  /// No description provided for @chartDashDash.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get chartDashDash;

  /// No description provided for @chartDashDashDot.
  ///
  /// In en, this message translates to:
  /// **'Dash-dot'**
  String get chartDashDashDot;

  /// No description provided for @chartDashDot.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get chartDashDot;

  /// No description provided for @chartDashLong.
  ///
  /// In en, this message translates to:
  /// **'Long dash'**
  String get chartDashLong;

  /// No description provided for @chartDashSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get chartDashSolid;

  /// No description provided for @chartDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF document (.pdf)'**
  String get chartDownloadPdf;

  /// No description provided for @chartDownloadPng.
  ///
  /// In en, this message translates to:
  /// **'PNG image (.png)'**
  String get chartDownloadPng;

  /// No description provided for @chartDownloadSvg.
  ///
  /// In en, this message translates to:
  /// **'Scalable vector graphics (.svg)'**
  String get chartDownloadSvg;

  /// No description provided for @chartEditorAddSeries.
  ///
  /// In en, this message translates to:
  /// **'Add series'**
  String get chartEditorAddSeries;

  /// No description provided for @chartEditorAddXAxis.
  ///
  /// In en, this message translates to:
  /// **'Add X-axis'**
  String get chartEditorAddXAxis;

  /// No description provided for @chartEditorAggregate.
  ///
  /// In en, this message translates to:
  /// **'Aggregate'**
  String get chartEditorAggregate;

  /// No description provided for @chartEditorAlign.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get chartEditorAlign;

  /// No description provided for @chartEditorAllSeries.
  ///
  /// In en, this message translates to:
  /// **'Apply to all series'**
  String get chartEditorAllSeries;

  /// No description provided for @chartEditorAlternatingColors.
  ///
  /// In en, this message translates to:
  /// **'Alternating row colors'**
  String get chartEditorAlternatingColors;

  /// No description provided for @chartEditorAxis.
  ///
  /// In en, this message translates to:
  /// **'Axis'**
  String get chartEditorAxis;

  /// No description provided for @chartEditorBackground.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get chartEditorBackground;

  /// No description provided for @chartEditorBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get chartEditorBold;

  /// No description provided for @chartEditorBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get chartEditorBorderColor;

  /// No description provided for @chartEditorBucketSize.
  ///
  /// In en, this message translates to:
  /// **'Bucket size'**
  String get chartEditorBucketSize;

  /// No description provided for @chartEditorChartType.
  ///
  /// In en, this message translates to:
  /// **'Chart type'**
  String get chartEditorChartType;

  /// No description provided for @chartEditorCompareMode.
  ///
  /// In en, this message translates to:
  /// **'Compare mode'**
  String get chartEditorCompareMode;

  /// No description provided for @chartEditorConnectorLines.
  ///
  /// In en, this message translates to:
  /// **'Connector lines'**
  String get chartEditorConnectorLines;

  /// No description provided for @chartEditorCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get chartEditorCustomize;

  /// No description provided for @chartEditorCustomizeSeries.
  ///
  /// In en, this message translates to:
  /// **'Format series'**
  String get chartEditorCustomizeSeries;

  /// No description provided for @chartEditorDataLabels.
  ///
  /// In en, this message translates to:
  /// **'Data labels'**
  String get chartEditorDataLabels;

  /// No description provided for @chartEditorDataRange.
  ///
  /// In en, this message translates to:
  /// **'Data range'**
  String get chartEditorDataRange;

  /// No description provided for @chartEditorDomainUnnamed.
  ///
  /// In en, this message translates to:
  /// **'(Unnamed)'**
  String get chartEditorDomainUnnamed;

  /// No description provided for @chartEditorDoughnutHole.
  ///
  /// In en, this message translates to:
  /// **'Doughnut hole'**
  String get chartEditorDoughnutHole;

  /// No description provided for @chartEditorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a chart to edit it'**
  String get chartEditorEmpty;

  /// No description provided for @chartEditorEmptyCells.
  ///
  /// In en, this message translates to:
  /// **'Empty cells'**
  String get chartEditorEmptyCells;

  /// No description provided for @chartEditorFallingColor.
  ///
  /// In en, this message translates to:
  /// **'Falling color'**
  String get chartEditorFallingColor;

  /// No description provided for @chartEditorFallingFilled.
  ///
  /// In en, this message translates to:
  /// **'Fill falling candles'**
  String get chartEditorFallingFilled;

  /// No description provided for @chartEditorFillColor.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get chartEditorFillColor;

  /// No description provided for @chartEditorFillOpacity.
  ///
  /// In en, this message translates to:
  /// **'Fill opacity'**
  String get chartEditorFillOpacity;

  /// No description provided for @chartEditorFirstValueSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Use first value as subtotal'**
  String get chartEditorFirstValueSubtotal;

  /// No description provided for @chartEditorFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get chartEditorFont;

  /// No description provided for @chartEditorFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get chartEditorFontSize;

  /// No description provided for @chartEditorFormatFromSource.
  ///
  /// In en, this message translates to:
  /// **'Format from source data'**
  String get chartEditorFormatFromSource;

  /// No description provided for @chartEditorGridColor.
  ///
  /// In en, this message translates to:
  /// **'Gridline color'**
  String get chartEditorGridColor;

  /// No description provided for @chartEditorGridCount.
  ///
  /// In en, this message translates to:
  /// **'Major gridline count'**
  String get chartEditorGridCount;

  /// No description provided for @chartEditorIncludeHidden.
  ///
  /// In en, this message translates to:
  /// **'Include hidden and filtered data'**
  String get chartEditorIncludeHidden;

  /// No description provided for @chartEditorItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get chartEditorItalic;

  /// No description provided for @chartEditorItemDividers.
  ///
  /// In en, this message translates to:
  /// **'Show item dividers'**
  String get chartEditorItemDividers;

  /// No description provided for @chartEditorLineDash.
  ///
  /// In en, this message translates to:
  /// **'Line dash'**
  String get chartEditorLineDash;

  /// No description provided for @chartEditorLineThickness.
  ///
  /// In en, this message translates to:
  /// **'Line thickness'**
  String get chartEditorLineThickness;

  /// No description provided for @chartEditorLogScale.
  ///
  /// In en, this message translates to:
  /// **'Log scale'**
  String get chartEditorLogScale;

  /// No description provided for @chartEditorMajorGridlines.
  ///
  /// In en, this message translates to:
  /// **'Major gridlines'**
  String get chartEditorMajorGridlines;

  /// No description provided for @chartEditorMajorTicks.
  ///
  /// In en, this message translates to:
  /// **'Major ticks'**
  String get chartEditorMajorTicks;

  /// No description provided for @chartEditorMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get chartEditorMax;

  /// No description provided for @chartEditorMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get chartEditorMaximize;

  /// No description provided for @chartEditorMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get chartEditorMin;

  /// No description provided for @chartEditorMinorGridlines.
  ///
  /// In en, this message translates to:
  /// **'Minor gridlines'**
  String get chartEditorMinorGridlines;

  /// No description provided for @chartEditorMinorTicks.
  ///
  /// In en, this message translates to:
  /// **'Minor ticks'**
  String get chartEditorMinorTicks;

  /// No description provided for @chartEditorMissingSeries.
  ///
  /// In en, this message translates to:
  /// **'Missing series (column deleted)'**
  String get chartEditorMissingSeries;

  /// No description provided for @chartEditorMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get chartEditorMoveDown;

  /// No description provided for @chartEditorMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get chartEditorMoveUp;

  /// No description provided for @chartEditorNegativeColor.
  ///
  /// In en, this message translates to:
  /// **'Negative color'**
  String get chartEditorNegativeColor;

  /// No description provided for @chartEditorNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get chartEditorNumberFormat;

  /// No description provided for @chartEditorNumberFormatFromSource.
  ///
  /// In en, this message translates to:
  /// **'From source data'**
  String get chartEditorNumberFormatFromSource;

  /// No description provided for @chartEditorOutlierPercentile.
  ///
  /// In en, this message translates to:
  /// **'Outlier percentile'**
  String get chartEditorOutlierPercentile;

  /// No description provided for @chartEditorPageSize.
  ///
  /// In en, this message translates to:
  /// **'Page size (0 = no paging)'**
  String get chartEditorPageSize;

  /// No description provided for @chartEditorPlotNullValues.
  ///
  /// In en, this message translates to:
  /// **'Plot null values'**
  String get chartEditorPlotNullValues;

  /// No description provided for @chartEditorPointShape.
  ///
  /// In en, this message translates to:
  /// **'Point shape'**
  String get chartEditorPointShape;

  /// No description provided for @chartEditorPointSize.
  ///
  /// In en, this message translates to:
  /// **'Point size'**
  String get chartEditorPointSize;

  /// No description provided for @chartEditorPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get chartEditorPosition;

  /// No description provided for @chartEditorPositiveColor.
  ///
  /// In en, this message translates to:
  /// **'Positive color'**
  String get chartEditorPositiveColor;

  /// No description provided for @chartEditorRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chartEditorRemove;

  /// No description provided for @chartEditorReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get chartEditorReset;

  /// No description provided for @chartEditorReverseAxis.
  ///
  /// In en, this message translates to:
  /// **'Reverse axis order'**
  String get chartEditorReverseAxis;

  /// No description provided for @chartEditorRisingColor.
  ///
  /// In en, this message translates to:
  /// **'Rising color'**
  String get chartEditorRisingColor;

  /// No description provided for @chartEditorRisingFilled.
  ///
  /// In en, this message translates to:
  /// **'Fill rising candles'**
  String get chartEditorRisingFilled;

  /// No description provided for @chartEditorRowNumbers.
  ///
  /// In en, this message translates to:
  /// **'Show row numbers'**
  String get chartEditorRowNumbers;

  /// No description provided for @chartEditorSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get chartEditorSeries;

  /// No description provided for @chartEditorSeriesTarget.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get chartEditorSeriesTarget;

  /// No description provided for @chartEditorSeriesType.
  ///
  /// In en, this message translates to:
  /// **'Series type'**
  String get chartEditorSeriesType;

  /// No description provided for @chartEditorSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get chartEditorSetup;

  /// No description provided for @chartEditorShowAxisLine.
  ///
  /// In en, this message translates to:
  /// **'Show axis line'**
  String get chartEditorShowAxisLine;

  /// No description provided for @chartEditorShowLabels.
  ///
  /// In en, this message translates to:
  /// **'Show labels'**
  String get chartEditorShowLabels;

  /// No description provided for @chartEditorShowR2.
  ///
  /// In en, this message translates to:
  /// **'Show R²'**
  String get chartEditorShowR2;

  /// No description provided for @chartEditorSlant.
  ///
  /// In en, this message translates to:
  /// **'Slant labels'**
  String get chartEditorSlant;

  /// No description provided for @chartEditorSliceLabel.
  ///
  /// In en, this message translates to:
  /// **'Slice label'**
  String get chartEditorSliceLabel;

  /// No description provided for @chartEditorSmooth.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get chartEditorSmooth;

  /// No description provided for @chartEditorStacking.
  ///
  /// In en, this message translates to:
  /// **'Stacking'**
  String get chartEditorStacking;

  /// No description provided for @chartEditorSubtotalColor.
  ///
  /// In en, this message translates to:
  /// **'Subtotal color'**
  String get chartEditorSubtotalColor;

  /// No description provided for @chartEditorSwitchRowsColumns.
  ///
  /// In en, this message translates to:
  /// **'Switch rows / columns'**
  String get chartEditorSwitchRowsColumns;

  /// No description provided for @chartEditorTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get chartEditorTextColor;

  /// No description provided for @chartEditorTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get chartEditorTitlePlaceholder;

  /// No description provided for @chartEditorTitleTarget.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get chartEditorTitleTarget;

  /// No description provided for @chartEditorTitleText.
  ///
  /// In en, this message translates to:
  /// **'Title text'**
  String get chartEditorTitleText;

  /// No description provided for @chartEditorTreatLabelsAsText.
  ///
  /// In en, this message translates to:
  /// **'Treat labels as text'**
  String get chartEditorTreatLabelsAsText;

  /// No description provided for @chartEditorTrendline.
  ///
  /// In en, this message translates to:
  /// **'Trendline'**
  String get chartEditorTrendline;

  /// No description provided for @chartEditorTrendlineColor.
  ///
  /// In en, this message translates to:
  /// **'Trendline color'**
  String get chartEditorTrendlineColor;

  /// No description provided for @chartEditorTrendlineDegree.
  ///
  /// In en, this message translates to:
  /// **'Polynomial degree'**
  String get chartEditorTrendlineDegree;

  /// No description provided for @chartEditorTrendlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get chartEditorTrendlineLabel;

  /// No description provided for @chartEditorTrendlinePeriod.
  ///
  /// In en, this message translates to:
  /// **'Average of'**
  String get chartEditorTrendlinePeriod;

  /// No description provided for @chartEditorTrendlineType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get chartEditorTrendlineType;

  /// No description provided for @chartEditorUseColumnAsLabels.
  ///
  /// In en, this message translates to:
  /// **'Use column {column} as labels'**
  String chartEditorUseColumnAsLabels(String column);

  /// No description provided for @chartEditorUseRowAsHeaders.
  ///
  /// In en, this message translates to:
  /// **'Use row {row} as headers'**
  String chartEditorUseRowAsHeaders(int row);

  /// No description provided for @chartEditorUseRowAsLabels.
  ///
  /// In en, this message translates to:
  /// **'Use row {row} as labels'**
  String chartEditorUseRowAsLabels(int row);

  /// No description provided for @chartEditorXAxis.
  ///
  /// In en, this message translates to:
  /// **'X-axis'**
  String get chartEditorXAxis;

  /// No description provided for @chartEmptyCellsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect line'**
  String get chartEmptyCellsConnect;

  /// No description provided for @chartEmptyCellsGap.
  ///
  /// In en, this message translates to:
  /// **'Show as gaps'**
  String get chartEmptyCellsGap;

  /// No description provided for @chartEmptyCellsZero.
  ///
  /// In en, this message translates to:
  /// **'Show as zero'**
  String get chartEmptyCellsZero;

  /// No description provided for @chartGroupArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get chartGroupArea;

  /// No description provided for @chartGroupBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get chartGroupBar;

  /// No description provided for @chartGroupColumn.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get chartGroupColumn;

  /// No description provided for @chartGroupLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get chartGroupLine;

  /// No description provided for @chartGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chartGroupOther;

  /// No description provided for @chartGroupPie.
  ///
  /// In en, this message translates to:
  /// **'Pie'**
  String get chartGroupPie;

  /// No description provided for @chartGroupScatter.
  ///
  /// In en, this message translates to:
  /// **'Scatter'**
  String get chartGroupScatter;

  /// No description provided for @chartGroupSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get chartGroupSuggested;

  /// No description provided for @chartLabelAbove.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get chartLabelAbove;

  /// No description provided for @chartLabelBelow.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get chartLabelBelow;

  /// No description provided for @chartLabelInsideBase.
  ///
  /// In en, this message translates to:
  /// **'Inside base'**
  String get chartLabelInsideBase;

  /// No description provided for @chartLabelInsideEnd.
  ///
  /// In en, this message translates to:
  /// **'Inside end'**
  String get chartLabelInsideEnd;

  /// No description provided for @chartLabelOutsideEnd.
  ///
  /// In en, this message translates to:
  /// **'Outside end'**
  String get chartLabelOutsideEnd;

  /// No description provided for @chartLegendAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get chartLegendAuto;

  /// No description provided for @chartLegendBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get chartLegendBottom;

  /// No description provided for @chartLegendInside.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get chartLegendInside;

  /// No description provided for @chartLegendLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get chartLegendLeft;

  /// No description provided for @chartLegendNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartLegendNone;

  /// No description provided for @chartLegendRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get chartLegendRight;

  /// No description provided for @chartLegendTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get chartLegendTop;

  /// No description provided for @chartNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This chart was created with a newer version of Wonky Sheets. Reload to edit it.'**
  String get chartNewerVersion;

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get chartNoData;

  /// No description provided for @chartNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chart not found'**
  String get chartNotFound;

  /// No description provided for @chartScoreAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Absolute change'**
  String get chartScoreAbsolute;

  /// No description provided for @chartScorePercent.
  ///
  /// In en, this message translates to:
  /// **'Percentage change'**
  String get chartScorePercent;

  /// No description provided for @chartSectionCandlestick.
  ///
  /// In en, this message translates to:
  /// **'Candlestick'**
  String get chartSectionCandlestick;

  /// No description provided for @chartSectionGridlines.
  ///
  /// In en, this message translates to:
  /// **'Gridlines and ticks'**
  String get chartSectionGridlines;

  /// No description provided for @chartSectionHAxis.
  ///
  /// In en, this message translates to:
  /// **'Horizontal axis'**
  String get chartSectionHAxis;

  /// No description provided for @chartSectionHistogram.
  ///
  /// In en, this message translates to:
  /// **'Histogram'**
  String get chartSectionHistogram;

  /// No description provided for @chartSectionLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get chartSectionLegend;

  /// No description provided for @chartSectionPie.
  ///
  /// In en, this message translates to:
  /// **'Pie chart'**
  String get chartSectionPie;

  /// No description provided for @chartSectionScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get chartSectionScorecard;

  /// No description provided for @chartSectionSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get chartSectionSeries;

  /// No description provided for @chartSectionStyle.
  ///
  /// In en, this message translates to:
  /// **'Chart style'**
  String get chartSectionStyle;

  /// No description provided for @chartSectionTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get chartSectionTable;

  /// No description provided for @chartSectionTitles.
  ///
  /// In en, this message translates to:
  /// **'Chart & axis titles'**
  String get chartSectionTitles;

  /// No description provided for @chartSectionVAxis.
  ///
  /// In en, this message translates to:
  /// **'Vertical axis'**
  String get chartSectionVAxis;

  /// No description provided for @chartSectionWaterfall.
  ///
  /// In en, this message translates to:
  /// **'Waterfall'**
  String get chartSectionWaterfall;

  /// No description provided for @chartShapeCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get chartShapeCircle;

  /// No description provided for @chartShapeDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get chartShapeDiamond;

  /// No description provided for @chartShapePolygon.
  ///
  /// In en, this message translates to:
  /// **'Polygon'**
  String get chartShapePolygon;

  /// No description provided for @chartShapeSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get chartShapeSquare;

  /// No description provided for @chartShapeStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get chartShapeStar;

  /// No description provided for @chartShapeTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get chartShapeTriangle;

  /// No description provided for @chartSheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'This chart sheet is empty'**
  String get chartSheetEmpty;

  /// No description provided for @chartSlantCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get chartSlantCustom;

  /// No description provided for @chartSlantNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartSlantNone;

  /// No description provided for @chartSliceLabelBoth.
  ///
  /// In en, this message translates to:
  /// **'Value and percentage'**
  String get chartSliceLabelBoth;

  /// No description provided for @chartSliceLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get chartSliceLabelLabel;

  /// No description provided for @chartSliceLabelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartSliceLabelNone;

  /// No description provided for @chartSliceLabelPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get chartSliceLabelPercentage;

  /// No description provided for @chartSliceLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get chartSliceLabelValue;

  /// No description provided for @chartStackingNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartStackingNone;

  /// No description provided for @chartStackingNormal.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get chartStackingNormal;

  /// No description provided for @chartStackingPercent.
  ///
  /// In en, this message translates to:
  /// **'100%'**
  String get chartStackingPercent;

  /// No description provided for @chartTickInside.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get chartTickInside;

  /// No description provided for @chartTickNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartTickNone;

  /// No description provided for @chartTickOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get chartTickOutside;

  /// No description provided for @chartTitleChart.
  ///
  /// In en, this message translates to:
  /// **'Chart title'**
  String get chartTitleChart;

  /// No description provided for @chartTitleHAxis.
  ///
  /// In en, this message translates to:
  /// **'Horizontal axis title'**
  String get chartTitleHAxis;

  /// No description provided for @chartTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chart subtitle'**
  String get chartTitleSubtitle;

  /// No description provided for @chartTitleV2Axis.
  ///
  /// In en, this message translates to:
  /// **'Right vertical axis title'**
  String get chartTitleV2Axis;

  /// No description provided for @chartTitleVAxis.
  ///
  /// In en, this message translates to:
  /// **'Vertical axis title'**
  String get chartTitleVAxis;

  /// No description provided for @chartTrendExponential.
  ///
  /// In en, this message translates to:
  /// **'Exponential'**
  String get chartTrendExponential;

  /// No description provided for @chartTrendLabelCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get chartTrendLabelCustom;

  /// No description provided for @chartTrendLabelEquation.
  ///
  /// In en, this message translates to:
  /// **'Use equation'**
  String get chartTrendLabelEquation;

  /// No description provided for @chartTrendLabelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartTrendLabelNone;

  /// No description provided for @chartTrendLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get chartTrendLinear;

  /// No description provided for @chartTrendLogarithmic.
  ///
  /// In en, this message translates to:
  /// **'Logarithmic'**
  String get chartTrendLogarithmic;

  /// No description provided for @chartTrendMovingAverage.
  ///
  /// In en, this message translates to:
  /// **'Moving average'**
  String get chartTrendMovingAverage;

  /// No description provided for @chartTrendPolynomial.
  ///
  /// In en, this message translates to:
  /// **'Polynomial'**
  String get chartTrendPolynomial;

  /// No description provided for @chartTrendPower.
  ///
  /// In en, this message translates to:
  /// **'Power series'**
  String get chartTrendPower;

  /// No description provided for @chartTypeArea.
  ///
  /// In en, this message translates to:
  /// **'Area chart'**
  String get chartTypeArea;

  /// No description provided for @chartTypeBar.
  ///
  /// In en, this message translates to:
  /// **'Bar chart'**
  String get chartTypeBar;

  /// No description provided for @chartTypeBubble.
  ///
  /// In en, this message translates to:
  /// **'Bubble chart'**
  String get chartTypeBubble;

  /// No description provided for @chartTypeCandlestick.
  ///
  /// In en, this message translates to:
  /// **'Candlestick chart'**
  String get chartTypeCandlestick;

  /// No description provided for @chartTypeColumn.
  ///
  /// In en, this message translates to:
  /// **'Column chart'**
  String get chartTypeColumn;

  /// No description provided for @chartTypeCombo.
  ///
  /// In en, this message translates to:
  /// **'Combo chart'**
  String get chartTypeCombo;

  /// No description provided for @chartTypeDoughnut.
  ///
  /// In en, this message translates to:
  /// **'Doughnut chart'**
  String get chartTypeDoughnut;

  /// No description provided for @chartTypeHistogram.
  ///
  /// In en, this message translates to:
  /// **'Histogram chart'**
  String get chartTypeHistogram;

  /// No description provided for @chartTypeLine.
  ///
  /// In en, this message translates to:
  /// **'Line chart'**
  String get chartTypeLine;

  /// No description provided for @chartTypeNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No chart type matches'**
  String get chartTypeNoMatch;

  /// No description provided for @chartTypePercentArea.
  ///
  /// In en, this message translates to:
  /// **'100% stacked area chart'**
  String get chartTypePercentArea;

  /// No description provided for @chartTypePercentBar.
  ///
  /// In en, this message translates to:
  /// **'100% stacked bar chart'**
  String get chartTypePercentBar;

  /// No description provided for @chartTypePercentColumn.
  ///
  /// In en, this message translates to:
  /// **'100% stacked column chart'**
  String get chartTypePercentColumn;

  /// No description provided for @chartTypePie.
  ///
  /// In en, this message translates to:
  /// **'Pie chart'**
  String get chartTypePie;

  /// No description provided for @chartTypeRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar chart'**
  String get chartTypeRadar;

  /// No description provided for @chartTypeScatter.
  ///
  /// In en, this message translates to:
  /// **'Scatter chart'**
  String get chartTypeScatter;

  /// No description provided for @chartTypeScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard chart'**
  String get chartTypeScorecard;

  /// No description provided for @chartTypeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search chart types'**
  String get chartTypeSearch;

  /// No description provided for @chartTypeSmoothLine.
  ///
  /// In en, this message translates to:
  /// **'Smooth line chart'**
  String get chartTypeSmoothLine;

  /// No description provided for @chartTypeStackedArea.
  ///
  /// In en, this message translates to:
  /// **'Stacked area chart'**
  String get chartTypeStackedArea;

  /// No description provided for @chartTypeStackedBar.
  ///
  /// In en, this message translates to:
  /// **'Stacked bar chart'**
  String get chartTypeStackedBar;

  /// No description provided for @chartTypeStackedColumn.
  ///
  /// In en, this message translates to:
  /// **'Stacked column chart'**
  String get chartTypeStackedColumn;

  /// No description provided for @chartTypeTable.
  ///
  /// In en, this message translates to:
  /// **'Table chart'**
  String get chartTypeTable;

  /// No description provided for @chartTypeWaterfall.
  ///
  /// In en, this message translates to:
  /// **'Waterfall chart'**
  String get chartTypeWaterfall;

  /// No description provided for @chartWarnLogSkipped.
  ///
  /// In en, this message translates to:
  /// **'Log scale ignores {count} non-positive values'**
  String chartWarnLogSkipped(int count);

  /// No description provided for @chartWarnNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get chartWarnNoData;

  /// No description provided for @chartWarnRangeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Data range not found'**
  String get chartWarnRangeNotFound;

  /// No description provided for @chartWarnRangeSizeMismatch.
  ///
  /// In en, this message translates to:
  /// **'Ranges have different sizes'**
  String get chartWarnRangeSizeMismatch;

  /// No description provided for @chartWarnTooManyCategories.
  ///
  /// In en, this message translates to:
  /// **'Too many categories to show individually'**
  String get chartWarnTooManyCategories;

  /// No description provided for @chartWarnTrendlineIgnored.
  ///
  /// In en, this message translates to:
  /// **'Trendline ignores {count} non-positive values'**
  String chartWarnTrendlineIgnored(int count);

  /// No description provided for @cmdChartCopyAsImage.
  ///
  /// In en, this message translates to:
  /// **'Copy chart as image'**
  String get cmdChartCopyAsImage;

  /// No description provided for @cmdChartDownload.
  ///
  /// In en, this message translates to:
  /// **'Download chart'**
  String get cmdChartDownload;

  /// No description provided for @cmdChartEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit chart'**
  String get cmdChartEdit;

  /// No description provided for @cmdChartInsertDescription.
  ///
  /// In en, this message translates to:
  /// **'Insert a chart recommended for the selected data'**
  String get cmdChartInsertDescription;

  /// No description provided for @cmdChartMoveToOwnSheet.
  ///
  /// In en, this message translates to:
  /// **'Move to own sheet'**
  String get cmdChartMoveToOwnSheet;

  /// No description provided for @cmdChartMoveToSheet.
  ///
  /// In en, this message translates to:
  /// **'Move chart to sheet'**
  String get cmdChartMoveToSheet;

  /// No description provided for @cmdChartSetDataRanges.
  ///
  /// In en, this message translates to:
  /// **'Set chart data range'**
  String get cmdChartSetDataRanges;

  /// No description provided for @cmdChartSetType.
  ///
  /// In en, this message translates to:
  /// **'Change chart type'**
  String get cmdChartSetType;

  /// No description provided for @cmdChartUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit chart'**
  String get cmdChartUpdate;

  /// No description provided for @cmdChartViewDataTable.
  ///
  /// In en, this message translates to:
  /// **'View data as table'**
  String get cmdChartViewDataTable;

  /// No description provided for @cmdImagePlaceInCell.
  ///
  /// In en, this message translates to:
  /// **'Place image in selected cell'**
  String get cmdImagePlaceInCell;

  /// No description provided for @cmdImagePlaceOverCells.
  ///
  /// In en, this message translates to:
  /// **'Place image over cells'**
  String get cmdImagePlaceOverCells;

  /// No description provided for @cmdImageReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get cmdImageReplace;

  /// No description provided for @cmdImageResetSize.
  ///
  /// In en, this message translates to:
  /// **'Reset size'**
  String get cmdImageResetSize;

  /// No description provided for @cmdObjectCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cmdObjectCopy;

  /// No description provided for @cmdObjectCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cmdObjectCut;

  /// No description provided for @cmdObjectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cmdObjectDelete;

  /// No description provided for @cmdObjectDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect object'**
  String get cmdObjectDeselect;

  /// No description provided for @cmdObjectDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get cmdObjectDuplicate;

  /// No description provided for @cmdObjectEditAltText.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get cmdObjectEditAltText;

  /// No description provided for @cmdObjectList.
  ///
  /// In en, this message translates to:
  /// **'List objects'**
  String get cmdObjectList;

  /// No description provided for @cmdObjectMove.
  ///
  /// In en, this message translates to:
  /// **'Move object'**
  String get cmdObjectMove;

  /// No description provided for @cmdObjectNudge.
  ///
  /// In en, this message translates to:
  /// **'Nudge object'**
  String get cmdObjectNudge;

  /// No description provided for @cmdObjectOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get cmdObjectOrder;

  /// No description provided for @cmdObjectPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste object'**
  String get cmdObjectPaste;

  /// No description provided for @cmdObjectResize.
  ///
  /// In en, this message translates to:
  /// **'Resize object'**
  String get cmdObjectResize;

  /// No description provided for @cmdObjectSelect.
  ///
  /// In en, this message translates to:
  /// **'Select object'**
  String get cmdObjectSelect;

  /// No description provided for @cmdObjectSelectNext.
  ///
  /// In en, this message translates to:
  /// **'Select next object'**
  String get cmdObjectSelectNext;

  /// No description provided for @cmdObjectSelectPrevious.
  ///
  /// In en, this message translates to:
  /// **'Select previous object'**
  String get cmdObjectSelectPrevious;

  /// No description provided for @dialogAltTextBody.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get dialogAltTextBody;

  /// No description provided for @dialogAltTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Alt text describes the object for people who use screen readers.'**
  String get dialogAltTextDescription;

  /// No description provided for @dialogAltTextName.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get dialogAltTextName;

  /// No description provided for @dialogAltTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get dialogAltTextTitle;

  /// No description provided for @dialogChartDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data of {title}'**
  String dialogChartDataTitle(String title);

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// No description provided for @dialogDeleteChartSheetBody.
  ///
  /// In en, this message translates to:
  /// **'The chart and its chart sheet will be deleted.'**
  String get dialogDeleteChartSheetBody;

  /// No description provided for @dialogDeleteChartSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chart sheet?'**
  String get dialogDeleteChartSheetTitle;

  /// No description provided for @dialogImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an image from your computer or insert one by URL.'**
  String get dialogImageDescription;

  /// No description provided for @dialogImageInCellTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert image in cell'**
  String get dialogImageInCellTitle;

  /// No description provided for @dialogImageInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get dialogImageInsert;

  /// No description provided for @dialogImageOverCellsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert image over cells'**
  String get dialogImageOverCellsTitle;

  /// No description provided for @dialogImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload from computer…'**
  String get dialogImageUpload;

  /// No description provided for @dialogImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get dialogImageUrl;

  /// No description provided for @dialogImageUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an https:// image URL'**
  String get dialogImageUrlInvalid;

  /// No description provided for @dialogImageUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an image URL or upload a file'**
  String get dialogImageUrlRequired;

  /// No description provided for @downloadSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {name}'**
  String downloadSaveTitle(String name);

  /// No description provided for @imageFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'The image could not be loaded from that URL'**
  String get imageFetchFailed;

  /// No description provided for @imageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading image…'**
  String get imageLoading;

  /// No description provided for @imagePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get imagePickTitle;

  /// No description provided for @imageRejectedFormat.
  ///
  /// In en, this message translates to:
  /// **'Only PNG, JPEG, GIF, WebP and BMP images can be inserted'**
  String get imageRejectedFormat;

  /// No description provided for @imageRejectedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is too large (max. 50 MB and 25 megapixels)'**
  String get imageRejectedTooLarge;

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @imageUploading.
  ///
  /// In en, this message translates to:
  /// **'Image uploading…'**
  String get imageUploading;

  /// Overlay of an image whose background upload was refused because the storage quota is full (Drive 03 §6.3).
  ///
  /// In en, this message translates to:
  /// **'Not uploaded — out of storage'**
  String get imageNotUploadedOutOfStorage;

  /// No description provided for @imageRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get imageRetryUpload;

  /// No description provided for @imageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get imageRemove;

  /// No description provided for @objectMenuCopyChart.
  ///
  /// In en, this message translates to:
  /// **'Copy chart'**
  String get objectMenuCopyChart;

  /// No description provided for @objectMenuDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get objectMenuDownload;

  /// No description provided for @objectMenuMoveToSheet.
  ///
  /// In en, this message translates to:
  /// **'Move to sheet'**
  String get objectMenuMoveToSheet;

  /// No description provided for @objectMenuOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get objectMenuOrder;

  /// No description provided for @objectMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get objectMoreOptions;

  /// No description provided for @objectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Object not found'**
  String get objectNotFound;

  /// No description provided for @objectOrderBack.
  ///
  /// In en, this message translates to:
  /// **'Send to back'**
  String get objectOrderBack;

  /// No description provided for @objectOrderBackward.
  ///
  /// In en, this message translates to:
  /// **'Send backward'**
  String get objectOrderBackward;

  /// No description provided for @objectOrderForward.
  ///
  /// In en, this message translates to:
  /// **'Bring forward'**
  String get objectOrderForward;

  /// No description provided for @objectOrderFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to front'**
  String get objectOrderFront;

  /// No description provided for @undoEditAltText.
  ///
  /// In en, this message translates to:
  /// **'Edit alt text'**
  String get undoEditAltText;

  /// No description provided for @undoEditChart.
  ///
  /// In en, this message translates to:
  /// **'Edit chart'**
  String get undoEditChart;

  /// No description provided for @undoInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get undoInsertImage;

  /// No description provided for @dvGroupText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get dvGroupText;

  /// No description provided for @dvGroupDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dvGroupDate;

  /// No description provided for @dvGroupNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get dvGroupNumber;

  /// No description provided for @dvGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get dvGroupOther;

  /// No description provided for @filterViewNoneItem.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get filterViewNoneItem;

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your offline spreadsheet data couldn\'t be opened'**
  String get recoveryTitle;

  /// No description provided for @recoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 spreadsheet had changes that weren\'t synced yet. Download them before they\'re lost.} other{{count} spreadsheets had changes that weren\'t synced yet. Download them before they\'re lost.}}'**
  String recoveryDescription(int count);

  /// No description provided for @recoveryDownload.
  ///
  /// In en, this message translates to:
  /// **'Download unsynced changes'**
  String get recoveryDownload;

  /// No description provided for @recoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'The unsynced changes could not be exported'**
  String get recoveryFailed;

  /// No description provided for @storageLimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline storage is limited in this browser'**
  String get storageLimitedTitle;

  /// No description provided for @storageLimitedDescription.
  ///
  /// In en, this message translates to:
  /// **'This browser keeps offline spreadsheets in memory. Only about {cells} cells stay available offline; the spreadsheets you opened least recently are removed from this device first.'**
  String storageLimitedDescription(String cells);

  /// No description provided for @loadingRowsStatus.
  ///
  /// In en, this message translates to:
  /// **'Loading… {percent}%'**
  String loadingRowsStatus(int percent);

  /// No description provided for @categoryScripts.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get categoryScripts;

  /// No description provided for @menuScriptMenus.
  ///
  /// In en, this message translates to:
  /// **'Script menus'**
  String get menuScriptMenus;

  /// No description provided for @cmdMacroCancelRecording.
  ///
  /// In en, this message translates to:
  /// **'Cancel macro recording'**
  String get cmdMacroCancelRecording;

  /// No description provided for @cmdMacroDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove macro'**
  String get cmdMacroDelete;

  /// No description provided for @cmdMacroRun.
  ///
  /// In en, this message translates to:
  /// **'Run macro'**
  String get cmdMacroRun;

  /// No description provided for @cmdMacroSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Save macro'**
  String get cmdMacroSaveRecording;

  /// No description provided for @cmdMacroUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit macro'**
  String get cmdMacroUpdate;

  /// No description provided for @cmdScriptAddTrigger.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get cmdScriptAddTrigger;

  /// No description provided for @cmdScriptAuthorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize script'**
  String get cmdScriptAuthorize;

  /// No description provided for @cmdScriptCloseEditor.
  ///
  /// In en, this message translates to:
  /// **'Close script editor'**
  String get cmdScriptCloseEditor;

  /// No description provided for @cmdScriptCompile.
  ///
  /// In en, this message translates to:
  /// **'Build script'**
  String get cmdScriptCompile;

  /// No description provided for @cmdScriptDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete script file'**
  String get cmdScriptDeleteFile;

  /// No description provided for @cmdScriptDeleteTrigger.
  ///
  /// In en, this message translates to:
  /// **'Delete trigger'**
  String get cmdScriptDeleteTrigger;

  /// No description provided for @cmdScriptExplainWithAi.
  ///
  /// In en, this message translates to:
  /// **'Explain script with AI'**
  String get cmdScriptExplainWithAi;

  /// No description provided for @cmdScriptFixErrorWithAi.
  ///
  /// In en, this message translates to:
  /// **'Fix script error with AI'**
  String get cmdScriptFixErrorWithAi;

  /// No description provided for @cmdScriptGenerateWithAi.
  ///
  /// In en, this message translates to:
  /// **'Generate script with AI'**
  String get cmdScriptGenerateWithAi;

  /// No description provided for @cmdScriptNewFile.
  ///
  /// In en, this message translates to:
  /// **'New script file'**
  String get cmdScriptNewFile;

  /// No description provided for @cmdScriptOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Script settings'**
  String get cmdScriptOpenSettings;

  /// No description provided for @cmdScriptRenameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename script file'**
  String get cmdScriptRenameFile;

  /// No description provided for @cmdScriptReorderFile.
  ///
  /// In en, this message translates to:
  /// **'Move script file'**
  String get cmdScriptReorderFile;

  /// No description provided for @cmdScriptRevertExecution.
  ///
  /// In en, this message translates to:
  /// **'Revert script changes'**
  String get cmdScriptRevertExecution;

  /// No description provided for @cmdScriptRevokeAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Revoke my authorization'**
  String get cmdScriptRevokeAuthorization;

  /// No description provided for @cmdScriptRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get cmdScriptRun;

  /// No description provided for @cmdScriptRunMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Run script menu item'**
  String get cmdScriptRunMenuItem;

  /// No description provided for @cmdScriptSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all script files'**
  String get cmdScriptSaveAll;

  /// No description provided for @cmdScriptSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Save script file'**
  String get cmdScriptSaveFile;

  /// No description provided for @cmdScriptStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cmdScriptStop;

  /// No description provided for @cmdScriptUpdateSettings.
  ///
  /// In en, this message translates to:
  /// **'Change script settings'**
  String get cmdScriptUpdateSettings;

  /// No description provided for @cmdScriptUpdateTrigger.
  ///
  /// In en, this message translates to:
  /// **'Edit trigger'**
  String get cmdScriptUpdateTrigger;

  /// No description provided for @execEmpty.
  ///
  /// In en, this message translates to:
  /// **'No executions yet.'**
  String get execEmpty;

  /// No description provided for @execKindCustomFunction.
  ///
  /// In en, this message translates to:
  /// **'Custom function'**
  String get execKindCustomFunction;

  /// No description provided for @execKindEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get execKindEditor;

  /// No description provided for @execKindInstallable.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get execKindInstallable;

  /// No description provided for @execKindMacro.
  ///
  /// In en, this message translates to:
  /// **'Macro'**
  String get execKindMacro;

  /// No description provided for @execKindMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get execKindMenu;

  /// No description provided for @execKindTimeDriven.
  ///
  /// In en, this message translates to:
  /// **'Time-driven'**
  String get execKindTimeDriven;

  /// No description provided for @execLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading executions…'**
  String get execLoading;

  /// No description provided for @execNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No log output.'**
  String get execNoLogs;

  /// No description provided for @execOpenInEditor.
  ///
  /// In en, this message translates to:
  /// **'Open in editor'**
  String get execOpenInEditor;

  /// No description provided for @execRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get execRefresh;

  /// No description provided for @execRevert.
  ///
  /// In en, this message translates to:
  /// **'Revert changes'**
  String get execRevert;

  /// No description provided for @execStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get execStatusAll;

  /// No description provided for @execStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get execStatusCancelled;

  /// No description provided for @execStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get execStatusCompleted;

  /// No description provided for @execStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get execStatusFailed;

  /// No description provided for @execStatusQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota exceeded'**
  String get execStatusQuota;

  /// No description provided for @execStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get execStatusSkipped;

  /// No description provided for @execStatusTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get execStatusTimedOut;

  /// No description provided for @execDuration.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String execDuration(int ms);

  /// No description provided for @execStats.
  ///
  /// In en, this message translates to:
  /// **'{read} cells read · {written} written · {fetches} fetches'**
  String execStats(int read, int written, int fetches);

  /// No description provided for @macroAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Absolute'**
  String get macroAbsolute;

  /// No description provided for @macroRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get macroRelative;

  /// No description provided for @macroCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get macroCancel;

  /// No description provided for @macroEditScript.
  ///
  /// In en, this message translates to:
  /// **'Edit script'**
  String get macroEditScript;

  /// No description provided for @macroImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get macroImportAction;

  /// No description provided for @macroImportNone.
  ///
  /// In en, this message translates to:
  /// **'There are no functions to import. Write a function without parameters in the script editor first.'**
  String get macroImportNone;

  /// No description provided for @macroName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get macroName;

  /// No description provided for @macroNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get macroNameEmpty;

  /// No description provided for @macroNameFromFunction.
  ///
  /// In en, this message translates to:
  /// **'Same as the function'**
  String get macroNameFromFunction;

  /// No description provided for @macroNotFound.
  ///
  /// In en, this message translates to:
  /// **'That macro no longer exists.'**
  String get macroNotFound;

  /// No description provided for @macroRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording new macro…'**
  String get macroRecording;

  /// No description provided for @macroRecordingCount.
  ///
  /// In en, this message translates to:
  /// **'Recording new macro… {count} steps'**
  String macroRecordingCount(int count);

  /// No description provided for @macroRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove macro'**
  String get macroRemove;

  /// No description provided for @macroSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save new macro'**
  String get macroSaveTitle;

  /// No description provided for @macroShortcut.
  ///
  /// In en, this message translates to:
  /// **'Shortcut'**
  String get macroShortcut;

  /// No description provided for @macroShortcutNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get macroShortcutNone;

  /// No description provided for @macroShortcutTaken.
  ///
  /// In en, this message translates to:
  /// **'{shortcut} (used by {name})'**
  String macroShortcutTaken(String shortcut, String name);

  /// No description provided for @macroDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Macro {n}'**
  String macroDefaultName(int n);

  /// No description provided for @macrosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No macros yet. Record one with Extensions › Macros › Record macro.'**
  String get macrosEmpty;

  /// No description provided for @scriptAuthorizeAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get scriptAuthorizeAllow;

  /// No description provided for @scriptAuthorizeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t authorize the script'**
  String get scriptAuthorizeFailed;

  /// No description provided for @scriptAuthorizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorization required'**
  String get scriptAuthorizeTitle;

  /// No description provided for @scriptAuthorizeBody.
  ///
  /// In en, this message translates to:
  /// **'{project} wants to:'**
  String scriptAuthorizeBody(String project);

  /// No description provided for @scriptBackToSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Back to the spreadsheet'**
  String get scriptBackToSpreadsheet;

  /// No description provided for @scriptButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scriptButtonCancel;

  /// No description provided for @scriptButtonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get scriptButtonNo;

  /// No description provided for @scriptButtonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get scriptButtonYes;

  /// No description provided for @scriptClearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get scriptClearLog;

  /// No description provided for @scriptCloseTab.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get scriptCloseTab;

  /// No description provided for @scriptCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get scriptCollapse;

  /// No description provided for @scriptExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get scriptExpand;

  /// No description provided for @scriptConflictDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard mine'**
  String get scriptConflictDiscard;

  /// No description provided for @scriptConflictOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite with mine'**
  String get scriptConflictOverwrite;

  /// No description provided for @scriptConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Newer version saved'**
  String get scriptConflictTitle;

  /// No description provided for @scriptConflictBody.
  ///
  /// In en, this message translates to:
  /// **'Someone else saved a newer version of {file} since you opened it.'**
  String scriptConflictBody(String file);

  /// No description provided for @scriptCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get scriptCreate;

  /// No description provided for @scriptDefaultProjectName.
  ///
  /// In en, this message translates to:
  /// **'This script'**
  String get scriptDefaultProjectName;

  /// No description provided for @scriptDeleteProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the script project?'**
  String get scriptDeleteProjectTitle;

  /// No description provided for @scriptDeleteProjectBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes all script files, triggers and macros of this spreadsheet. You can undo this.'**
  String get scriptDeleteProjectBody;

  /// No description provided for @scriptDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get scriptDialogTitle;

  /// No description provided for @scriptEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} · Script'**
  String scriptEditorTitle(String title);

  /// No description provided for @scriptErrorToast.
  ///
  /// In en, this message translates to:
  /// **'Script error in {function}'**
  String scriptErrorToast(String function);

  /// No description provided for @scriptFileLimit.
  ///
  /// In en, this message translates to:
  /// **'A script can have at most 50 files.'**
  String get scriptFileLimit;

  /// No description provided for @scriptFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get scriptFileName;

  /// No description provided for @scriptFileNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A file with this name already exists.'**
  String get scriptFileNameDuplicate;

  /// No description provided for @scriptFileNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use lower-case letters, digits and _, ending in .dart (utils.dart).'**
  String get scriptFileNameInvalid;

  /// No description provided for @scriptFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'That script file no longer exists.'**
  String get scriptFileNotFound;

  /// No description provided for @scriptFileUpdated.
  ///
  /// In en, this message translates to:
  /// **'{file} was updated by someone else'**
  String scriptFileUpdated(String file);

  /// No description provided for @scriptFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get scriptFiles;

  /// No description provided for @scriptFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get scriptFind;

  /// No description provided for @scriptFindMatchCase.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get scriptFindMatchCase;

  /// No description provided for @scriptFindNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get scriptFindNext;

  /// No description provided for @scriptFindNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get scriptFindNoResults;

  /// No description provided for @scriptFindPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get scriptFindPlaceholder;

  /// No description provided for @scriptFindPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get scriptFindPrevious;

  /// No description provided for @scriptFindRegex.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get scriptFindRegex;

  /// No description provided for @scriptFindToggleReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get scriptFindToggleReplace;

  /// No description provided for @scriptFixWithAi.
  ///
  /// In en, this message translates to:
  /// **'Fix with AI'**
  String get scriptFixWithAi;

  /// No description provided for @scriptFunctions.
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get scriptFunctions;

  /// No description provided for @scriptGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get scriptGenerate;

  /// No description provided for @scriptLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get scriptLog;

  /// No description provided for @scriptLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Run a function to see its log here.'**
  String get scriptLogEmpty;

  /// No description provided for @scriptNeedsNewerApp.
  ///
  /// In en, this message translates to:
  /// **'This script needs a newer version of the app.'**
  String get scriptNeedsNewerApp;

  /// No description provided for @scriptNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'A newer version of this file was saved elsewhere.'**
  String get scriptNewerVersion;

  /// No description provided for @scriptNoBuild.
  ///
  /// In en, this message translates to:
  /// **'The script hasn\'t built successfully yet.'**
  String get scriptNoBuild;

  /// No description provided for @scriptNoFileOpen.
  ///
  /// In en, this message translates to:
  /// **'No file open'**
  String get scriptNoFileOpen;

  /// No description provided for @scriptNoFunctions.
  ///
  /// In en, this message translates to:
  /// **'Functions appear after a successful build.'**
  String get scriptNoFunctions;

  /// No description provided for @scriptNoProblems.
  ///
  /// In en, this message translates to:
  /// **'No problems'**
  String get scriptNoProblems;

  /// No description provided for @scriptNoRunnableFunctions.
  ///
  /// In en, this message translates to:
  /// **'No runnable functions'**
  String get scriptNoRunnableFunctions;

  /// No description provided for @scriptOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Try again when you\'re connected.'**
  String get scriptOffline;

  /// No description provided for @scriptPickFunction.
  ///
  /// In en, this message translates to:
  /// **'Choose a function to run.'**
  String get scriptPickFunction;

  /// No description provided for @scriptProblems.
  ///
  /// In en, this message translates to:
  /// **'Problems {count}'**
  String scriptProblems(int count);

  /// No description provided for @scriptPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get scriptPromptLabel;

  /// No description provided for @scriptReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get scriptReadOnly;

  /// No description provided for @scriptReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get scriptReload;

  /// No description provided for @scriptReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get scriptReplace;

  /// No description provided for @scriptReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get scriptReplaceAll;

  /// No description provided for @scriptReplacePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get scriptReplacePlaceholder;

  /// No description provided for @scriptRevertLabel.
  ///
  /// In en, this message translates to:
  /// **'Revert script: {function}'**
  String scriptRevertLabel(String function);

  /// No description provided for @scriptRunOnServer.
  ///
  /// In en, this message translates to:
  /// **'Run on server'**
  String get scriptRunOnServer;

  /// No description provided for @scriptSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get scriptSave;

  /// No description provided for @scriptScopeExternalRequest.
  ///
  /// In en, this message translates to:
  /// **'Connect to external services'**
  String get scriptScopeExternalRequest;

  /// No description provided for @scriptScopeTriggers.
  ///
  /// In en, this message translates to:
  /// **'Run when you\'re not present (triggers)'**
  String get scriptScopeTriggers;

  /// No description provided for @scriptScopeUserEmail.
  ///
  /// In en, this message translates to:
  /// **'See your email address'**
  String get scriptScopeUserEmail;

  /// No description provided for @scriptSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get scriptSettings;

  /// No description provided for @scriptSettingsAllowlist.
  ///
  /// In en, this message translates to:
  /// **'URL allowlist (hosts, comma separated)'**
  String get scriptSettingsAllowlist;

  /// No description provided for @scriptSettingsApiVersion.
  ///
  /// In en, this message translates to:
  /// **'API version {version}'**
  String scriptSettingsApiVersion(int version);

  /// No description provided for @scriptSettingsBuildHash.
  ///
  /// In en, this message translates to:
  /// **'Build {hash}'**
  String scriptSettingsBuildHash(String hash);

  /// No description provided for @scriptSettingsBuiltAt.
  ///
  /// In en, this message translates to:
  /// **'Built {time}'**
  String scriptSettingsBuiltAt(String time);

  /// No description provided for @scriptSettingsDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get scriptSettingsDeleteProject;

  /// No description provided for @scriptSettingsName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get scriptSettingsName;

  /// No description provided for @scriptSettingsNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get scriptSettingsNameEmpty;

  /// No description provided for @scriptSettingsShowMenus.
  ///
  /// In en, this message translates to:
  /// **'Show script menus in the menubar'**
  String get scriptSettingsShowMenus;

  /// No description provided for @scriptSettingsTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get scriptSettingsTimeZone;

  /// No description provided for @scriptStatusBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building…'**
  String get scriptStatusBuilding;

  /// No description provided for @scriptStatusBuilt.
  ///
  /// In en, this message translates to:
  /// **'Built {time}'**
  String scriptStatusBuilt(String time);

  /// No description provided for @scriptStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Build failed ({count} errors)'**
  String scriptStatusFailed(int count);

  /// No description provided for @scriptStatusNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'Not built yet'**
  String get scriptStatusNotBuilt;

  /// No description provided for @scriptStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device · Will compile when online'**
  String get scriptStatusOffline;

  /// No description provided for @scriptStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get scriptStatusSaved;

  /// No description provided for @scriptStatusUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get scriptStatusUnsaved;

  /// No description provided for @scriptUnknownFunction.
  ///
  /// In en, this message translates to:
  /// **'There is no function {name} in the script.'**
  String scriptUnknownFunction(String name);

  /// No description provided for @scriptViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get scriptViewDetails;

  /// No description provided for @triggerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get triggerAdd;

  /// No description provided for @triggerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get triggerAddTitle;

  /// No description provided for @triggerAt.
  ///
  /// In en, this message translates to:
  /// **'Date and time (once)'**
  String get triggerAt;

  /// No description provided for @triggerAtHour.
  ///
  /// In en, this message translates to:
  /// **'Hour of day (0–23)'**
  String get triggerAtHour;

  /// No description provided for @triggerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete trigger'**
  String get triggerDelete;

  /// No description provided for @triggerDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get triggerDisabled;

  /// No description provided for @triggerEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get triggerEnabled;

  /// No description provided for @triggerEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get triggerEvent;

  /// No description provided for @triggerEventChange.
  ///
  /// In en, this message translates to:
  /// **'On change'**
  String get triggerEventChange;

  /// No description provided for @triggerEventEdit.
  ///
  /// In en, this message translates to:
  /// **'On edit'**
  String get triggerEventEdit;

  /// No description provided for @triggerEventOpen.
  ///
  /// In en, this message translates to:
  /// **'On open'**
  String get triggerEventOpen;

  /// No description provided for @triggerEventTime.
  ///
  /// In en, this message translates to:
  /// **'Time-driven'**
  String get triggerEventTime;

  /// No description provided for @triggerEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Every {n} day(s) at {hour}:00'**
  String triggerEveryDays(int n, int hour);

  /// No description provided for @triggerEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Every {n} hour(s)'**
  String triggerEveryHours(int n);

  /// No description provided for @triggerEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every {n} minute(s)'**
  String triggerEveryMinutes(int n);

  /// No description provided for @triggerEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every {n} week(s) on {weekday} at {hour}:00'**
  String triggerEveryWeeks(int n, String weekday, int hour);

  /// No description provided for @triggerMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly on day {day} at {hour}:00'**
  String triggerMonthly(int day, int hour);

  /// No description provided for @triggerOnce.
  ///
  /// In en, this message translates to:
  /// **'Once at {at}'**
  String triggerOnce(String at);

  /// No description provided for @triggerFireForMcp.
  ///
  /// In en, this message translates to:
  /// **'Also run for agent (MCP) edits'**
  String get triggerFireForMcp;

  /// No description provided for @triggerFunction.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get triggerFunction;

  /// No description provided for @triggerInterval.
  ///
  /// In en, this message translates to:
  /// **'Every (interval)'**
  String get triggerInterval;

  /// No description provided for @triggerInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a date like 2026-12-24T09:00.'**
  String get triggerInvalidDate;

  /// No description provided for @triggerInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number in range.'**
  String get triggerInvalidNumber;

  /// No description provided for @triggerMonthDay.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get triggerMonthDay;

  /// No description provided for @triggerNotFound.
  ///
  /// In en, this message translates to:
  /// **'That trigger no longer exists.'**
  String get triggerNotFound;

  /// No description provided for @triggerNotYours.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change other people\'s triggers.'**
  String get triggerNotYours;

  /// No description provided for @triggerNotify.
  ///
  /// In en, this message translates to:
  /// **'Failure notifications'**
  String get triggerNotify;

  /// No description provided for @triggerNotifyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily digest'**
  String get triggerNotifyDaily;

  /// No description provided for @triggerNotifyImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get triggerNotifyImmediately;

  /// No description provided for @triggerNotifyNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get triggerNotifyNever;

  /// No description provided for @triggerOwnerOther.
  ///
  /// In en, this message translates to:
  /// **'Another user'**
  String get triggerOwnerOther;

  /// No description provided for @triggerScheduleType.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get triggerScheduleType;

  /// No description provided for @triggerTypeDays.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get triggerTypeDays;

  /// No description provided for @triggerTypeHours.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get triggerTypeHours;

  /// No description provided for @triggerTypeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every few minutes'**
  String get triggerTypeMinutes;

  /// No description provided for @triggerTypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get triggerTypeMonthly;

  /// No description provided for @triggerTypeOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get triggerTypeOnce;

  /// No description provided for @triggerTypeWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get triggerTypeWeeks;

  /// No description provided for @triggerWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get triggerWeekday;

  /// No description provided for @triggersDescription.
  ///
  /// In en, this message translates to:
  /// **'Installable triggers run on the server, also when nobody has the spreadsheet open.'**
  String get triggersDescription;

  /// No description provided for @triggersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No triggers yet.'**
  String get triggersEmpty;

  /// No description provided for @undoCreateScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Create script file'**
  String get undoCreateScriptFile;

  /// No description provided for @undoDeleteScriptFile.
  ///
  /// In en, this message translates to:
  /// **'Delete script file'**
  String get undoDeleteScriptFile;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @macroAbsoluteHint.
  ///
  /// In en, this message translates to:
  /// **'Use absolute references (the same cells every time)'**
  String get macroAbsoluteHint;

  /// No description provided for @macroRelativeHint.
  ///
  /// In en, this message translates to:
  /// **'Use relative references (cells relative to the selection)'**
  String get macroRelativeHint;

  /// No description provided for @sheetsSettingsColumnAutocomplete.
  ///
  /// In en, this message translates to:
  /// **'Autocomplete values from the column'**
  String get sheetsSettingsColumnAutocomplete;

  /// No description provided for @a11yGridLabel.
  ///
  /// In en, this message translates to:
  /// **'{sheet} grid'**
  String a11yGridLabel(String sheet);

  /// No description provided for @a11yCellEmpty.
  ///
  /// In en, this message translates to:
  /// **'{cell}, empty'**
  String a11yCellEmpty(String cell);

  /// No description provided for @a11yCellValue.
  ///
  /// In en, this message translates to:
  /// **'{cell}, {value}'**
  String a11yCellValue(String cell, String value);

  /// No description provided for @a11yCellFormula.
  ///
  /// In en, this message translates to:
  /// **'formula {formula}'**
  String a11yCellFormula(String formula);

  /// No description provided for @a11yCellError.
  ///
  /// In en, this message translates to:
  /// **'{cell}, error, {message}'**
  String a11yCellError(String cell, String message);

  /// No description provided for @a11yCheckboxChecked.
  ///
  /// In en, this message translates to:
  /// **'checkbox checked'**
  String get a11yCheckboxChecked;

  /// No description provided for @a11yCheckboxUnchecked.
  ///
  /// In en, this message translates to:
  /// **'checkbox unchecked'**
  String get a11yCheckboxUnchecked;

  /// No description provided for @a11yLink.
  ///
  /// In en, this message translates to:
  /// **'link, {url}'**
  String a11yLink(String url);

  /// No description provided for @a11yHasNote.
  ///
  /// In en, this message translates to:
  /// **'has note'**
  String get a11yHasNote;

  /// No description provided for @a11yRangeSelected.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to} selected, {count} cells'**
  String a11yRangeSelected(String from, String to, int count);

  /// No description provided for @a11yMerged.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to} merged'**
  String a11yMerged(String from, String to);

  /// No description provided for @a11yEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing {cell}'**
  String a11yEditing(String cell);

  /// No description provided for @a11yColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Column {column}'**
  String a11yColumnHeader(String column);

  /// No description provided for @a11yRowHeader.
  ///
  /// In en, this message translates to:
  /// **'Row {row}'**
  String a11yRowHeader(String row);

  /// No description provided for @a11yLoadingRow.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get a11yLoadingRow;

  /// No description provided for @contextMenuDragCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get contextMenuDragCopy;

  /// No description provided for @chartGroup3D.
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get chartGroup3D;

  /// No description provided for @chartType3DColumn.
  ///
  /// In en, this message translates to:
  /// **'3D column chart'**
  String get chartType3DColumn;

  /// No description provided for @chartType3DStackedColumn.
  ///
  /// In en, this message translates to:
  /// **'3D stacked column chart'**
  String get chartType3DStackedColumn;

  /// No description provided for @chartType3DPercentColumn.
  ///
  /// In en, this message translates to:
  /// **'3D 100% stacked column chart'**
  String get chartType3DPercentColumn;

  /// No description provided for @chartType3DBar.
  ///
  /// In en, this message translates to:
  /// **'3D bar chart'**
  String get chartType3DBar;

  /// No description provided for @chartType3DStackedBar.
  ///
  /// In en, this message translates to:
  /// **'3D stacked bar chart'**
  String get chartType3DStackedBar;

  /// No description provided for @chartType3DLine.
  ///
  /// In en, this message translates to:
  /// **'3D line chart'**
  String get chartType3DLine;

  /// No description provided for @chartType3DArea.
  ///
  /// In en, this message translates to:
  /// **'3D area chart'**
  String get chartType3DArea;

  /// No description provided for @chartType3DStackedArea.
  ///
  /// In en, this message translates to:
  /// **'3D stacked area chart'**
  String get chartType3DStackedArea;

  /// No description provided for @chartType3DPie.
  ///
  /// In en, this message translates to:
  /// **'3D pie chart'**
  String get chartType3DPie;

  /// No description provided for @chartType3DDoughnut.
  ///
  /// In en, this message translates to:
  /// **'3D doughnut chart'**
  String get chartType3DDoughnut;

  /// No description provided for @chartSection3D.
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get chartSection3D;

  /// No description provided for @chartEditor3DEnabled.
  ///
  /// In en, this message translates to:
  /// **'Show in 3D'**
  String get chartEditor3DEnabled;

  /// No description provided for @chartEditor3DRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get chartEditor3DRotation;

  /// No description provided for @chartEditor3DTilt.
  ///
  /// In en, this message translates to:
  /// **'Tilt'**
  String get chartEditor3DTilt;

  /// No description provided for @chartEditor3DPerspective.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get chartEditor3DPerspective;

  /// No description provided for @chartEditor3DDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get chartEditor3DDepth;

  /// No description provided for @chartEditor3DHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get chartEditor3DHeight;

  /// No description provided for @chartEditor3DGapDepth.
  ///
  /// In en, this message translates to:
  /// **'Gap depth'**
  String get chartEditor3DGapDepth;

  /// No description provided for @chartEditor3DExplode.
  ///
  /// In en, this message translates to:
  /// **'Pull slices apart'**
  String get chartEditor3DExplode;

  /// No description provided for @chartEditor3DLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get chartEditor3DLighting;

  /// No description provided for @chartLightingSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get chartLightingSoft;

  /// No description provided for @chartLightingBright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get chartLightingBright;

  /// No description provided for @chartLightingFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get chartLightingFlat;

  /// No description provided for @chartEditor3DShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get chartEditor3DShape;

  /// No description provided for @chartShapeBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get chartShapeBox;

  /// No description provided for @chartShapeCylinder.
  ///
  /// In en, this message translates to:
  /// **'Cylinder'**
  String get chartShapeCylinder;

  /// No description provided for @chartShapeCone.
  ///
  /// In en, this message translates to:
  /// **'Cone'**
  String get chartShapeCone;

  /// No description provided for @chartShapePyramid.
  ///
  /// In en, this message translates to:
  /// **'Pyramid'**
  String get chartShapePyramid;

  /// No description provided for @chartEditor3DWalls.
  ///
  /// In en, this message translates to:
  /// **'Floor and walls'**
  String get chartEditor3DWalls;

  /// No description provided for @chartEditor3DFloorColor.
  ///
  /// In en, this message translates to:
  /// **'Floor color'**
  String get chartEditor3DFloorColor;

  /// No description provided for @chartEditor3DResetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get chartEditor3DResetView;

  /// No description provided for @chartEditor3DOrbitHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the selected chart, or press Alt+Shift+arrow keys, to rotate it.'**
  String get chartEditor3DOrbitHint;

  /// No description provided for @cmdChartToggle3D.
  ///
  /// In en, this message translates to:
  /// **'Show chart in 3D'**
  String get cmdChartToggle3D;

  /// No description provided for @cmdChartToggle3DDescription.
  ///
  /// In en, this message translates to:
  /// **'Draws the selected column, bar, line, area or pie chart in 3D, or flat again.'**
  String get cmdChartToggle3DDescription;

  /// No description provided for @cmdChartReset3DView.
  ///
  /// In en, this message translates to:
  /// **'Reset 3D chart view'**
  String get cmdChartReset3DView;

  /// No description provided for @cmdChartRotate3D.
  ///
  /// In en, this message translates to:
  /// **'Rotate 3D chart'**
  String get cmdChartRotate3D;

  /// No description provided for @cmdObjectAlign.
  ///
  /// In en, this message translates to:
  /// **'Align objects'**
  String get cmdObjectAlign;

  /// No description provided for @undoAlignObjects.
  ///
  /// In en, this message translates to:
  /// **'Align objects'**
  String get undoAlignObjects;

  /// No description provided for @objectMenuAlign.
  ///
  /// In en, this message translates to:
  /// **'Align'**
  String get objectMenuAlign;

  /// No description provided for @objectAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get objectAlignLeft;

  /// No description provided for @objectAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get objectAlignCenter;

  /// No description provided for @objectAlignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get objectAlignRight;

  /// No description provided for @objectAlignTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get objectAlignTop;

  /// No description provided for @objectAlignMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get objectAlignMiddle;

  /// No description provided for @objectAlignBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get objectAlignBottom;

  /// No description provided for @objectDistributeHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Distribute horizontally'**
  String get objectDistributeHorizontally;

  /// No description provided for @objectDistributeVertically.
  ///
  /// In en, this message translates to:
  /// **'Distribute vertically'**
  String get objectDistributeVertically;

  /// No description provided for @reasonChartSheet.
  ///
  /// In en, this message translates to:
  /// **'Not available on chart sheets'**
  String get reasonChartSheet;

  /// No description provided for @imageClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no image on the clipboard'**
  String get imageClipboardEmpty;

  /// No description provided for @dialogImagePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get dialogImagePaste;

  /// No description provided for @chartCopyImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t put the image on the clipboard'**
  String get chartCopyImageFailed;

  /// No description provided for @chartCopiedAsImage.
  ///
  /// In en, this message translates to:
  /// **'Chart copied as an image'**
  String get chartCopiedAsImage;

  /// No description provided for @chartEditorTrendlineCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom label'**
  String get chartEditorTrendlineCustomLabel;

  /// No description provided for @chartEditorTrendlineCustomLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label text'**
  String get chartEditorTrendlineCustomLabelHint;

  /// No description provided for @chartEditorErrorBars.
  ///
  /// In en, this message translates to:
  /// **'Error bars'**
  String get chartEditorErrorBars;

  /// No description provided for @chartEditorErrorBarsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get chartEditorErrorBarsType;

  /// No description provided for @chartErrorBarsConstant.
  ///
  /// In en, this message translates to:
  /// **'Constant'**
  String get chartErrorBarsConstant;

  /// No description provided for @chartErrorBarsPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get chartErrorBarsPercent;

  /// No description provided for @chartErrorBarsStdev.
  ///
  /// In en, this message translates to:
  /// **'Standard deviation'**
  String get chartErrorBarsStdev;

  /// No description provided for @chartEditorErrorBarsValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get chartEditorErrorBarsValue;

  /// No description provided for @chartEditorFormatDataPoint.
  ///
  /// In en, this message translates to:
  /// **'Format data point'**
  String get chartEditorFormatDataPoint;

  /// No description provided for @chartEditorPickPoint.
  ///
  /// In en, this message translates to:
  /// **'Choose a point'**
  String get chartEditorPickPoint;

  /// No description provided for @chartEditorAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get chartEditorAdd;

  /// No description provided for @chartSectionPieSlice.
  ///
  /// In en, this message translates to:
  /// **'Pie slice'**
  String get chartSectionPieSlice;

  /// No description provided for @chartEditorSlice.
  ///
  /// In en, this message translates to:
  /// **'Slice'**
  String get chartEditorSlice;

  /// No description provided for @chartEditorSliceColor.
  ///
  /// In en, this message translates to:
  /// **'Slice color'**
  String get chartEditorSliceColor;

  /// No description provided for @chartEditorSliceDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance from center'**
  String get chartEditorSliceDistance;

  /// No description provided for @chartEditorSubtotals.
  ///
  /// In en, this message translates to:
  /// **'Subtotals'**
  String get chartEditorSubtotals;

  /// No description provided for @chartEditorNoSubtotals.
  ///
  /// In en, this message translates to:
  /// **'No subtotals'**
  String get chartEditorNoSubtotals;

  /// No description provided for @chartEditorSubtotalAfter.
  ///
  /// In en, this message translates to:
  /// **'After {point}'**
  String chartEditorSubtotalAfter(String point);

  /// No description provided for @chartEditorSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get chartEditorSubtotalLabel;

  /// No description provided for @chartEditorAddSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Add subtotal'**
  String get chartEditorAddSubtotal;

  /// No description provided for @chartEditorInvalidCell.
  ///
  /// In en, this message translates to:
  /// **'Enter a cell such as B2 or Sheet1!B2'**
  String get chartEditorInvalidCell;

  /// No description provided for @chartEditorKeyValueCell.
  ///
  /// In en, this message translates to:
  /// **'Key value cell'**
  String get chartEditorKeyValueCell;

  /// No description provided for @chartEditorBaselineCell.
  ///
  /// In en, this message translates to:
  /// **'Baseline cell'**
  String get chartEditorBaselineCell;

  /// No description provided for @chartEditorFromDataRange.
  ///
  /// In en, this message translates to:
  /// **'From the data range'**
  String get chartEditorFromDataRange;

  /// No description provided for @scriptsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Scripts are turned off on this device (Settings › Sheets).'**
  String get scriptsDisabled;

  /// No description provided for @scriptsDisabledBanner.
  ///
  /// In en, this message translates to:
  /// **'Scripts are turned off for you. Functions, triggers and custom functions don\'t run.'**
  String get scriptsDisabledBanner;

  /// No description provided for @scriptsEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on scripts'**
  String get scriptsEnable;

  /// No description provided for @scriptConflictBodyBy.
  ///
  /// In en, this message translates to:
  /// **'{user} saved a newer version of {file} ({when}).'**
  String scriptConflictBodyBy(String user, String file, String when);

  /// No description provided for @scriptCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get scriptCompare;

  /// No description provided for @scriptHideComparison.
  ///
  /// In en, this message translates to:
  /// **'Hide comparison'**
  String get scriptHideComparison;

  /// No description provided for @scriptMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get scriptMerge;

  /// No description provided for @scriptVersionTheirs.
  ///
  /// In en, this message translates to:
  /// **'Saved version'**
  String get scriptVersionTheirs;

  /// No description provided for @scriptVersionMine.
  ///
  /// In en, this message translates to:
  /// **'Your version'**
  String get scriptVersionMine;

  /// No description provided for @scriptMergeConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The merge has 1 conflict. Resolve the marked lines, then save.} other{The merge has {count} conflicts. Resolve the marked lines, then save.}}'**
  String scriptMergeConflicts(int count);

  /// No description provided for @scriptMergeConflictProblem.
  ///
  /// In en, this message translates to:
  /// **'Merge conflict: keep your lines, theirs or both, then remove the markers.'**
  String get scriptMergeConflictProblem;

  /// No description provided for @scriptHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Local history of {file}'**
  String scriptHistoryTitle(String file);

  /// No description provided for @scriptHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Versions saved on this device (the last 20). Restoring puts the version in the editor without saving.'**
  String get scriptHistoryDescription;

  /// No description provided for @scriptHistoryVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get scriptHistoryVersion;

  /// No description provided for @scriptHistoryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get scriptHistoryRestore;

  /// No description provided for @scriptHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No versions saved on this device yet.'**
  String get scriptHistoryEmpty;

  /// No description provided for @scriptHistorySelected.
  ///
  /// In en, this message translates to:
  /// **'Selected version'**
  String get scriptHistorySelected;

  /// No description provided for @scriptHistoryCurrent.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get scriptHistoryCurrent;

  /// No description provided for @scriptHistorySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get scriptHistorySaved;

  /// No description provided for @scriptHistoryDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded in a conflict'**
  String get scriptHistoryDiscarded;

  /// No description provided for @scriptHistoryOverwritten.
  ///
  /// In en, this message translates to:
  /// **'Replaced by your save'**
  String get scriptHistoryOverwritten;

  /// No description provided for @scriptHistoryBeforeMerge.
  ///
  /// In en, this message translates to:
  /// **'Before a merge'**
  String get scriptHistoryBeforeMerge;

  /// No description provided for @scriptLocalHistory.
  ///
  /// In en, this message translates to:
  /// **'Local history'**
  String get scriptLocalHistory;

  /// No description provided for @scriptRestoredDraft.
  ///
  /// In en, this message translates to:
  /// **'Restored {file} from the local history. Save to keep it.'**
  String scriptRestoredDraft(String file);

  /// No description provided for @scriptApiReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Script API reference'**
  String get scriptApiReferenceTitle;

  /// No description provided for @scriptApiSearch.
  ///
  /// In en, this message translates to:
  /// **'Search classes and members'**
  String get scriptApiSearch;

  /// No description provided for @scriptApiClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get scriptApiClass;

  /// No description provided for @scriptApiNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No classes or members match.'**
  String get scriptApiNoMatches;

  /// No description provided for @cmdHelpScriptApiReference.
  ///
  /// In en, this message translates to:
  /// **'Script API reference'**
  String get cmdHelpScriptApiReference;

  /// No description provided for @scriptInScriptEditor.
  ///
  /// In en, this message translates to:
  /// **'In the script editor'**
  String get scriptInScriptEditor;

  /// No description provided for @scriptFileOpenBy.
  ///
  /// In en, this message translates to:
  /// **'Open by {names}'**
  String scriptFileOpenBy(String names);

  /// No description provided for @scriptDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get scriptDragToReorder;

  /// No description provided for @scriptLoadingCell.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get scriptLoadingCell;

  /// No description provided for @sheetsSettingsChartPatterns.
  ///
  /// In en, this message translates to:
  /// **'Distinguish chart series by pattern'**
  String get sheetsSettingsChartPatterns;

  /// No description provided for @chartViewDataTableAction.
  ///
  /// In en, this message translates to:
  /// **'View data as table'**
  String get chartViewDataTableAction;

  /// No description provided for @chartType3DSurface.
  ///
  /// In en, this message translates to:
  /// **'3D surface'**
  String get chartType3DSurface;

  /// No description provided for @chartTypeSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get chartTypeSurface;

  /// No description provided for @scriptSidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Script sidebar'**
  String get scriptSidebarTitle;

  /// No description provided for @scriptSidebarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No script sidebar is open.'**
  String get scriptSidebarEmpty;
}

class _SheetsLocalizationsDelegate
    extends LocalizationsDelegate<SheetsLocalizations> {
  const _SheetsLocalizationsDelegate();

  @override
  Future<SheetsLocalizations> load(Locale locale) {
    return SynchronousFuture<SheetsLocalizations>(
      lookupSheetsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SheetsLocalizationsDelegate old) => false;
}

SheetsLocalizations lookupSheetsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SheetsLocalizationsEn();
  }

  throw FlutterError(
    'SheetsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
