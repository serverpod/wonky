// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sheets_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SheetsLocalizationsEn extends SheetsLocalizations {
  SheetsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cmdCellSetRichText => 'Set rich text';

  @override
  String get fontThemeSection => 'Theme font';

  @override
  String get fontRecentSection => 'Recent';

  @override
  String get fontAllSection => 'All fonts';

  @override
  String get cmdSettingsUpdate => 'Update spreadsheet settings';

  @override
  String get currencyDialogTitle => 'Custom currencies';

  @override
  String get currencySearch => 'Search currencies';

  @override
  String get currencyNoMatch => 'No matching currency';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'CNY': 'Chinese Yuan',
      'INR': 'Indian Rupee',
      'KRW': 'South Korean Won',
      'CHF': 'Swiss Franc',
      'CAD': 'Canadian Dollar',
      'AUD': 'Australian Dollar',
      'NZD': 'New Zealand Dollar',
      'SEK': 'Swedish Krona',
      'NOK': 'Norwegian Krone',
      'DKK': 'Danish Krone',
      'ISK': 'Icelandic Króna',
      'PLN': 'Polish Złoty',
      'CZK': 'Czech Koruna',
      'HUF': 'Hungarian Forint',
      'RON': 'Romanian Leu',
      'BGN': 'Bulgarian Lev',
      'TRY': 'Turkish Lira',
      'RUB': 'Russian Ruble',
      'UAH': 'Ukrainian Hryvnia',
      'ILS': 'Israeli New Shekel',
      'AED': 'UAE Dirham',
      'SAR': 'Saudi Riyal',
      'EGP': 'Egyptian Pound',
      'ZAR': 'South African Rand',
      'NGN': 'Nigerian Naira',
      'KES': 'Kenyan Shilling',
      'BRL': 'Brazilian Real',
      'MXN': 'Mexican Peso',
      'ARS': 'Argentine Peso',
      'CLP': 'Chilean Peso',
      'COP': 'Colombian Peso',
      'PEN': 'Peruvian Sol',
      'HKD': 'Hong Kong Dollar',
      'SGD': 'Singapore Dollar',
      'TWD': 'New Taiwan Dollar',
      'THB': 'Thai Baht',
      'VND': 'Vietnamese Dong',
      'PHP': 'Philippine Peso',
      'IDR': 'Indonesian Rupiah',
      'MYR': 'Malaysian Ringgit',
      'PKR': 'Pakistani Rupee',
      'BTC': 'Bitcoin',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get dtDialogTitle => 'Custom date and time formats';

  @override
  String get dtAdd => 'Add a date or time part';

  @override
  String get dtRemove => 'Remove';

  @override
  String get dtLiteral => 'Text';

  @override
  String get dtPresets => 'Suggestions';

  @override
  String get dtDay => 'Day';

  @override
  String get dtWeekday => 'Day of the week';

  @override
  String get dtMonth => 'Month';

  @override
  String get dtYear => 'Year';

  @override
  String get dtHour => 'Hour';

  @override
  String get dtMinute => 'Minute';

  @override
  String get dtSecond => 'Second';

  @override
  String get dtMillisecond => 'Millisecond';

  @override
  String get dtAmPm => 'AM/PM';

  @override
  String get dtElapsedHours => 'Elapsed hours';

  @override
  String get dtElapsedMinutes => 'Elapsed minutes';

  @override
  String get dtElapsedSeconds => 'Elapsed seconds';

  @override
  String get numFmtPreview => 'Preview';

  @override
  String get numFmtActiveCell => 'Selected cell';

  @override
  String get numFmtSamplePositive => 'Positive';

  @override
  String get numFmtSampleNegative => 'Negative';

  @override
  String get numFmtSampleZero => 'Zero';

  @override
  String get numFmtSampleText => 'Text';

  @override
  String get numFmtRecent => 'Recently used';

  @override
  String get numFmtExamples => 'Examples';

  @override
  String get numFmtCodesHelp => 'Format codes';

  @override
  String numFmtParseError(int position, String message) {
    return 'Position $position: $message';
  }

  @override
  String get numFmtCodeZero => 'Digit, padded with zeros';

  @override
  String get numFmtCodeHash => 'Digit, no padding';

  @override
  String get numFmtCodeQuestion =>
      'Digit, padded with a space (aligns decimals)';

  @override
  String get numFmtCodeSeparators =>
      'Decimal point and thousands separator (locale symbols)';

  @override
  String get numFmtCodePercent => 'Multiplies by 100 and shows %';

  @override
  String get numFmtCodeExponent => 'Scientific notation';

  @override
  String get numFmtCodeLiteral => 'Literal text';

  @override
  String get numFmtCodeText => 'The cell\'s text';

  @override
  String get numFmtCodeSpacing =>
      'Space as wide as c / repeat c to fill the cell';

  @override
  String get numFmtCodeColor => 'Text color';

  @override
  String get numFmtCodeCondition => 'Condition for the section';

  @override
  String get numFmtCodeSections => 'Positive; negative; zero; text';

  @override
  String get numFmtCodeDates => 'Day, month (or minute), year, hour, second';

  @override
  String get numFmtCodeElapsed => 'Elapsed hours, minutes, seconds';

  @override
  String get numFmtCodeCurrency => 'Currency symbol (and locale)';

  @override
  String get settingsDialogTitle => 'Settings for this spreadsheet';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsCalculation => 'Calculation';

  @override
  String get settingsLocale => 'Locale';

  @override
  String get settingsLocaleNote =>
      'Formats like \'Currency\' and dates will display using the new locale. Existing values are not changed.';

  @override
  String get settingsTimeZone => 'Time zone';

  @override
  String get settingsDisplayLanguage => 'Function language';

  @override
  String get settingsDisplayLanguageEnglish => 'English';

  @override
  String get settingsDisplayLanguageNote =>
      'Function names and TRUE/FALSE are shown in this language. English names always work, and formulas are saved in English.';

  @override
  String get settingsSearch => 'Search';

  @override
  String get sheetsSettingsDefaults => 'Defaults';

  @override
  String get sheetsSettingsNewSpreadsheets => 'New spreadsheets';

  @override
  String get cmdSheetsPrefsSet => 'Change a Sheets setting';

  @override
  String get sheetsSettingsNewHint =>
      'Defaults for new spreadsheets you create. Each spreadsheet keeps its own settings (File › Settings).';

  @override
  String get sheetsSettingsFont => 'Default font';

  @override
  String get sheetsSettingsEditing => 'Editing';

  @override
  String get sheetsSettingsEnterStartsEditing => 'Enter key starts editing';

  @override
  String get sheetsSettingsShowEditorMode => 'Show editor mode in status bar';

  @override
  String get sheetsSettingsReduceAnimations => 'Reduce grid animations';

  @override
  String get sheetsSettingsFillLists => 'Custom fill lists';

  @override
  String get sheetsSettingsFillListsHint =>
      'Dragging the fill handle continues these lists. One list per line, items separated by commas.';

  @override
  String get sheetsSettingsFillListsPlaceholder => 'Low, Medium, High';

  @override
  String sheetsSettingsFillListsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count custom lists',
      one: '1 custom list',
      zero: 'No custom lists',
    );
    return '$_temp0';
  }

  @override
  String get settingsRecalc => 'Recalculation';

  @override
  String get settingsRecalcOnChange => 'On change';

  @override
  String get settingsRecalcMinute => 'On change and every minute';

  @override
  String get settingsRecalcHour => 'On change and every hour';

  @override
  String get settingsIterative => 'Iterative calculation';

  @override
  String get settingsIterativeHint =>
      'Allows circular references, recalculated up to the maximum number of iterations.';

  @override
  String get settingsMaxIterations => 'Max number of iterations';

  @override
  String get settingsThreshold => 'Threshold';

  @override
  String get settingsThresholdInvalid => 'Enter a number of 0 or more';

  @override
  String get settingsSave => 'Save settings';

  @override
  String get presenceInScriptEditor => 'In script editor';

  @override
  String presenceTypingIn(String cell) {
    return 'Typing in $cell';
  }

  @override
  String presenceViewingSheet(String sheet) {
    return 'Viewing $sheet';
  }

  @override
  String presenceEditingCell(String cell) {
    return 'Editing $cell';
  }

  @override
  String get presenceFollowingYou => 'Following you';

  @override
  String get presenceTyping => 'typing…';

  @override
  String presenceFollowingName(String name) {
    return 'Following $name';
  }

  @override
  String get presenceStopFollowing => 'Stop';

  @override
  String tabPresence(String names) {
    return 'On this sheet: $names';
  }

  @override
  String commentAnchorDeleted(String quoted) {
    return 'The cell this comment was on was deleted · $quoted';
  }

  @override
  String get cmdConflictsReview => 'Review overwritten edits';

  @override
  String get cmdConflictsApplyMine => 'Apply my values again';

  @override
  String get undoApplyMine => 'Apply my values again';

  @override
  String get cmdHistoryDownload => 'Download version';

  @override
  String get cmdHistoryToggleShowChanges => 'Show changes';

  @override
  String get commentsScopeSheet => 'This sheet';

  @override
  String get commentsScopeAll => 'All sheets';

  @override
  String get commentsOrphanedGroup => 'Orphaned';

  @override
  String get conflictsTitle => 'Overwritten offline edits';

  @override
  String get conflictsDescription =>
      'Others changed these cells after you edited them offline. Select the values to put back.';

  @override
  String get conflictsReview => 'Review';

  @override
  String get conflictsApplyMine => 'Apply mine again';

  @override
  String get conflictsDismissAll => 'Dismiss all';

  @override
  String get conflictsEmptyValue => '(empty)';

  @override
  String get conflictsSeveralPeople => 'several people';

  @override
  String conflictsRow(String cell, String mine, String theirs, String name) {
    return '$cell — yours: $mine · now: $theirs ($name)';
  }

  @override
  String conflictsYours(String value) {
    return 'yours: $value';
  }

  @override
  String conflictsRowDeletedBy(String name) {
    return 'Row deleted by $name';
  }

  @override
  String conflictsColumnDeletedBy(String name) {
    return 'Column deleted by $name';
  }

  @override
  String conflictsSheetDeletedBy(String name) {
    return 'Sheet deleted by $name';
  }

  @override
  String toastConflicts(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count of your offline edits were replaced by newer edits from $name',
      one: '1 of your offline edits was replaced by a newer edit from $name',
    );
    return '$_temp0';
  }

  @override
  String toastSortReplaced(String name) {
    return 'Your sort was replaced by a newer sort from $name';
  }

  @override
  String get toastVersionCopyExtrasFailed =>
      'The copy was made, but its comments and sharing couldn\'t be copied';

  @override
  String get versionCopyTitle => 'Make a copy';

  @override
  String get versionCopyNameLabel => 'Name';

  @override
  String get versionCopyNameRequired => 'Enter a name';

  @override
  String get versionCopyComments => 'Copy comments';

  @override
  String get versionCopySharing => 'Share with the same people';

  @override
  String commentReplies(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String get noteHeading => 'Note';

  @override
  String get actionClose => 'Close';

  @override
  String toastVersionRestoredBy(String name) {
    return '$name restored a previous version';
  }

  @override
  String toastEditedRowDeletedBy(String name) {
    return 'The row you were editing was deleted by $name.';
  }

  @override
  String get someone => 'Someone';

  @override
  String versionCopyName(String title) {
    return 'Copy of $title';
  }

  @override
  String toastVersionCopied(String title) {
    return 'Created \"$title\"';
  }

  @override
  String get versionOpenCopy => 'Open';

  @override
  String get toastVersionCopyFailed => 'Couldn\'t make a copy of this version';

  @override
  String versionChangedCells(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cells changed',
      one: '1 cell changed',
    );
    return '$_temp0';
  }

  @override
  String versionRowsInserted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows inserted',
      one: '1 row inserted',
    );
    return '$_temp0';
  }

  @override
  String versionRowsDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows deleted',
      one: '1 row deleted',
    );
    return '$_temp0';
  }

  @override
  String versionColumnsInserted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString columns inserted',
      one: '1 column inserted',
    );
    return '$_temp0';
  }

  @override
  String versionColumnsDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString columns deleted',
      one: '1 column deleted',
    );
    return '$_temp0';
  }

  @override
  String versionSheetRenamed(String before, String after) {
    return 'Sheet \"$before\" renamed to \"$after\"';
  }

  @override
  String versionSheetsAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sheets added',
      one: '1 sheet added',
    );
    return '$_temp0';
  }

  @override
  String versionSheetsDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sheets deleted',
      one: '1 sheet deleted',
    );
    return '$_temp0';
  }

  @override
  String get versionNoChanges => 'No changes since the previous version';

  @override
  String get versionLoadFailed => 'Couldn\'t load this version';

  @override
  String get versionLoading => 'Loading version…';

  @override
  String get versionComputingChanges => 'Finding changes…';

  @override
  String get versionChangesHidden => 'Changes are hidden';

  @override
  String get versionSheetDeletedTooltip => 'Deleted in this version';

  @override
  String get cellHistoryTitle => 'Edit history';

  @override
  String get cellHistoryNewer => 'Newer edit';

  @override
  String get cellHistoryOlder => 'Older edit';

  @override
  String cellHistoryPosition(int index, int count) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$indexString of $countString';
  }

  @override
  String get cellHistoryEmpty => 'No edits recorded for this cell';

  @override
  String get cellHistoryEmptyOffline =>
      'No edits on this device. Older history needs a connection.';

  @override
  String cellHistoryBulk(String label) {
    return 'Changed as part of \"$label\"';
  }

  @override
  String get cellHistoryChanged => 'Changed';

  @override
  String get cellHistoryBlank => '(empty)';

  @override
  String cellHistoryVia(String label) {
    return 'via $label';
  }

  @override
  String get changeLabelTyping => 'Typing';

  @override
  String get changeLabelInsertAiResult => 'Insert AI result';

  @override
  String get changeLabelInsertImage => 'Insert image';

  @override
  String get changeLabelRestoreVersion => 'Restore version';

  @override
  String get changeLabelMakeCopy => 'Make a copy';

  @override
  String get changeLabelMaintenance => 'Maintenance';

  @override
  String get changeLabelCreateScriptProject => 'Create script project';

  @override
  String get changeLabelDeleteScriptProject => 'Delete script project';

  @override
  String get changeLabelCreateScriptFile => 'Create script file';

  @override
  String get changeLabelRenameScriptFile => 'Rename script file';

  @override
  String get changeLabelDeleteScriptFile => 'Delete script file';

  @override
  String get changeLabelMoveScriptFile => 'Move script file';

  @override
  String get changeLabelSaveScriptFile => 'Save script file';

  @override
  String get changeLabelScriptSettings => 'Script settings';

  @override
  String get changeLabelCreateMacro => 'Create macro';

  @override
  String get changeLabelEditMacro => 'Edit macro';

  @override
  String get changeLabelDeleteMacro => 'Delete macro';

  @override
  String get changeLabelRecordMacro => 'Record macro';

  @override
  String get changeLabelAddTrigger => 'Add trigger';

  @override
  String get changeLabelEditTrigger => 'Edit trigger';

  @override
  String get cellHistoryRestore => 'Restore this value';

  @override
  String actorViaMcp(String name) {
    return 'Claude via MCP ($name)';
  }

  @override
  String actorViaAi(String name) {
    return 'Assistant ($name)';
  }

  @override
  String actorViaScript(String name) {
    return 'Script ($name)';
  }

  @override
  String get cmdPresenceJumpTo => 'Go to collaborator';

  @override
  String get cmdPresenceFollow => 'Follow collaborator';

  @override
  String get cmdPresenceUnfollow => 'Stop following';

  @override
  String get categoryCollaboration => 'Collaboration';

  @override
  String get cmdCommentsNext => 'Next comment';

  @override
  String get cmdCommentsPrevious => 'Previous comment';

  @override
  String get cmdHistoryRestoreVersion => 'Restore this version';

  @override
  String get cmdHistoryMakeCopy => 'Make a copy';

  @override
  String get cmdHistoryNextChange => 'Next change';

  @override
  String get cmdHistoryPreviousChange => 'Previous change';

  @override
  String get cmdHistoryRestoreCellValue => 'Restore value';

  @override
  String get undoRestoreValue => 'Restore value';

  @override
  String get cmdBandingAdd => 'Add alternating colors';

  @override
  String get cmdBandingUpdate => 'Edit alternating colors';

  @override
  String get cmdBandingRemove => 'Remove alternating colors';

  @override
  String get bandingPanelTitle => 'Alternating colors';

  @override
  String get bandingApplyToRange => 'Apply to range';

  @override
  String get bandingHeader => 'Header';

  @override
  String get bandingFooter => 'Footer';

  @override
  String get bandingColumns => 'Alternate columns';

  @override
  String get bandingColumnsHint =>
      'Header is the first column, footer the last.';

  @override
  String get bandingDefaultStyles => 'Default styles';

  @override
  String bandingPresetLabel(int n) {
    return 'Default style $n';
  }

  @override
  String get bandingCustomStyles => 'Custom styles';

  @override
  String bandingCustomLabel(int n) {
    return 'Custom style $n';
  }

  @override
  String get bandingHeaderColor => 'Header';

  @override
  String get bandingColor1 => 'Color 1';

  @override
  String get bandingColor2 => 'Color 2';

  @override
  String get bandingFooterColor => 'Footer';

  @override
  String get bandingRemove => 'Remove alternating colors';

  @override
  String get cmdThemeSet => 'Set spreadsheet theme';

  @override
  String get themePanelTitle => 'Themes';

  @override
  String get themeCustomize => 'Customize';

  @override
  String get themeFont => 'Font';

  @override
  String get themeResetToPreset => 'Reset to preset';

  @override
  String get themeImport => 'Import theme';

  @override
  String get themeImportTitle => 'Import a theme from';

  @override
  String get pickSpreadsheetOffline => 'Importing needs a connection.';

  @override
  String get themePresets => 'Themes';

  @override
  String get themeCurrent => 'Current';

  @override
  String get themeStandard => 'Standard';

  @override
  String get themeSimple => 'Simple';

  @override
  String get themeStreamline => 'Streamline';

  @override
  String get themePaperback => 'Paperback';

  @override
  String get themeMarina => 'Marina';

  @override
  String get themeCoral => 'Coral';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeMono => 'Mono';

  @override
  String get themeRetro => 'Retro';

  @override
  String get themeOcean => 'Ocean';

  @override
  String fontDisplayedAs(String font, String shown) {
    return '$font (displayed as $shown)';
  }

  @override
  String get panelDone => 'Done';

  @override
  String get themeColorText => 'Text';

  @override
  String get themeColorBackground => 'Background';

  @override
  String get themeColorLink => 'Link';

  @override
  String themeColorAccent(int n) {
    return 'Accent $n';
  }

  @override
  String get cmdCfAddRule => 'Add conditional format rule';

  @override
  String get cmdCfUpdateRule => 'Edit conditional format rule';

  @override
  String get cmdCfDeleteRule => 'Delete conditional format rule';

  @override
  String get cmdCfReorder => 'Reorder conditional format rules';

  @override
  String get cmdCfSetEnabled => 'Enable or disable conditional format rule';

  @override
  String get cfUndoEnable => 'Enable rule';

  @override
  String get cfUndoDisable => 'Disable rule';

  @override
  String get cfPanelTitle => 'Conditional format rules';

  @override
  String get cfShowRulesFor => 'Show rules for';

  @override
  String get cfScopeSelection => 'Selected range';

  @override
  String get cfScopeSheet => 'This sheet';

  @override
  String get cfNoRules => 'No conditional format rules on this sheet yet.';

  @override
  String get cfNoRulesInSelection => 'No rules apply to the selected range.';

  @override
  String get cfAddRule => 'Add another rule';

  @override
  String get cfLimitReached => 'A sheet can have at most 500 rules.';

  @override
  String get cfAddRuleTitle => 'Add rule';

  @override
  String get cfEditRuleTitle => 'Edit rule';

  @override
  String get cfTabSingle => 'Single color';

  @override
  String get cfTabColorScale => 'Color scale';

  @override
  String get cfTabDataBar => 'Data bar';

  @override
  String get cfTabIconSet => 'Icon set';

  @override
  String get cfApplyToRange => 'Apply to range';

  @override
  String get cfFormatCellsIf => 'Format cells if…';

  @override
  String get cfFormattingStyle => 'Formatting style';

  @override
  String get cfStyleCustom => 'Custom';

  @override
  String get cfStyleDefault => 'Default';

  @override
  String get cfStyleGreenFill => 'Green fill';

  @override
  String get cfStyleYellowFill => 'Yellow fill';

  @override
  String get cfStyleRedFill => 'Red fill';

  @override
  String get cfStyleGreenBold => 'Green bold text';

  @override
  String get cfStyleRedBold => 'Red bold text';

  @override
  String get cfStyleBold => 'Bold';

  @override
  String get cfStyleItalicGrey => 'Grey italic';

  @override
  String get cfStyleStrikeGrey => 'Grey strikethrough';

  @override
  String get cfBold => 'Bold';

  @override
  String get cfItalic => 'Italic';

  @override
  String get cfUnderline => 'Underline';

  @override
  String get cfStrikethrough => 'Strikethrough';

  @override
  String get cfTextColor => 'Text color';

  @override
  String get cfFillColor => 'Fill color';

  @override
  String get cfAdvanced => 'Advanced';

  @override
  String get cfStopIfTrue => 'Stop if true';

  @override
  String get cfStopIfTrueHint =>
      'Later rules don\'t apply to cells that match this rule.';

  @override
  String get cfGroupEmpty => 'Empty';

  @override
  String get cfGroupText => 'Text';

  @override
  String get cfGroupDate => 'Date';

  @override
  String get cfGroupNumber => 'Number';

  @override
  String get cfGroupCustom => 'Custom';

  @override
  String get cfCondBlank => 'Is empty';

  @override
  String get cfCondNotBlank => 'Is not empty';

  @override
  String get cfCondTextContains => 'Text contains';

  @override
  String get cfCondTextNotContains => 'Text does not contain';

  @override
  String get cfCondTextStartsWith => 'Text starts with';

  @override
  String get cfCondTextEndsWith => 'Text ends with';

  @override
  String get cfCondTextEq => 'Text is exactly';

  @override
  String get cfCondDateEq => 'Date is';

  @override
  String get cfCondDateBefore => 'Date is before';

  @override
  String get cfCondDateAfter => 'Date is after';

  @override
  String get cfCondNumberGreater => 'Greater than';

  @override
  String get cfCondNumberGreaterEq => 'Greater than or equal to';

  @override
  String get cfCondNumberLess => 'Less than';

  @override
  String get cfCondNumberLessEq => 'Less than or equal to';

  @override
  String get cfCondNumberEq => 'Is equal to';

  @override
  String get cfCondNumberNotEq => 'Is not equal to';

  @override
  String get cfCondNumberBetween => 'Is between';

  @override
  String get cfCondNumberNotBetween => 'Is not between';

  @override
  String get cfCondCustomFormula => 'Custom formula is';

  @override
  String get cfDateToday => 'Today';

  @override
  String get cfDateTomorrow => 'Tomorrow';

  @override
  String get cfDateYesterday => 'Yesterday';

  @override
  String get cfDatePastWeek => 'In the past week';

  @override
  String get cfDatePastMonth => 'In the past month';

  @override
  String get cfDatePastYear => 'In the past year';

  @override
  String get cfDateExact => 'Exact date';

  @override
  String get cfDatePlaceholder => 'Date or formula, e.g. 2026-10-14';

  @override
  String get cfValuePlaceholder => 'Value or formula';

  @override
  String get cfPickDate => 'Pick a date';

  @override
  String get formulaFieldPointHint =>
      'Select cells on the grid to insert a reference.';

  @override
  String cfSummaryTwoValues(String label, String a, String b) {
    return '$label $a and $b';
  }

  @override
  String get cfKindColorScale => 'Color scale';

  @override
  String get cfKindDataBar => 'Data bar';

  @override
  String get cfKindIconSet => 'Icon set';

  @override
  String get cfKindUnsupported => 'Unsupported rule';

  @override
  String get cfKindMin => 'Min value';

  @override
  String get cfKindMax => 'Max value';

  @override
  String get cfKindNumber => 'Number';

  @override
  String get cfKindPercent => 'Percent';

  @override
  String get cfKindPercentile => 'Percentile';

  @override
  String get cfKindFormula => 'Formula';

  @override
  String get cfKindNone => 'None';

  @override
  String get cfPreview => 'Preview';

  @override
  String get cfScalePreset => 'Preset';

  @override
  String get cfScaleWhiteGreen => 'White to green';

  @override
  String get cfScaleGreenWhite => 'Green to white';

  @override
  String get cfScaleWhiteRed => 'White to red';

  @override
  String get cfScaleRedWhite => 'Red to white';

  @override
  String get cfScaleRedWhiteGreen => 'Red to white to green';

  @override
  String get cfScaleGreenWhiteRed => 'Green to white to red';

  @override
  String get cfScaleRedYellowGreen => 'Red to yellow to green';

  @override
  String get cfScaleGreenYellowRed => 'Green to yellow to red';

  @override
  String get cfScaleWhiteBlue => 'White to blue';

  @override
  String get cfScaleBlueWhite => 'Blue to white';

  @override
  String get cfScaleYellowGreen => 'Yellow to green';

  @override
  String get cfScaleAccent => 'Theme accent 1 light to dark';

  @override
  String get cfMinpoint => 'Minpoint';

  @override
  String get cfMidpoint => 'Midpoint';

  @override
  String get cfMaxpoint => 'Maxpoint';

  @override
  String cfPointColor(String point) {
    return '$point color';
  }

  @override
  String get cfBarColors => 'Bar colors';

  @override
  String get cfBarPositive => 'Positive';

  @override
  String get cfBarNegative => 'Negative';

  @override
  String get cfBarGradient => 'Gradient fill';

  @override
  String get cfBarAxis => 'Axis';

  @override
  String get cfAxisAuto => 'Automatic';

  @override
  String get cfAxisMiddle => 'Cell midpoint';

  @override
  String get cfAxisNone => 'None';

  @override
  String get cfBarDirection => 'Bar direction';

  @override
  String get cfDirectionContext => 'Sheet direction';

  @override
  String get cfDirectionLtr => 'Left to right';

  @override
  String get cfDirectionRtl => 'Right to left';

  @override
  String get cfShowValue => 'Show cell value';

  @override
  String get cfIconStyle => 'Icon style';

  @override
  String get cfIconOtherwise => 'Otherwise';

  @override
  String get cfIconReverse => 'Reverse icon order';

  @override
  String cfIconArrows(int n) {
    return '$n arrows';
  }

  @override
  String cfIconArrowsGray(int n) {
    return '$n arrows (gray)';
  }

  @override
  String cfIconTriangles(int n) {
    return '$n triangles';
  }

  @override
  String cfIconTrafficLights(int n) {
    return '$n traffic lights';
  }

  @override
  String cfIconSigns(int n) {
    return '$n signs';
  }

  @override
  String cfIconSymbols(int n) {
    return '$n symbols';
  }

  @override
  String cfIconFlags(int n) {
    return '$n flags';
  }

  @override
  String cfIconStars(int n) {
    return '$n stars';
  }

  @override
  String cfIconRatings(int n) {
    return '$n ratings';
  }

  @override
  String cfIconQuarters(int n) {
    return '$n quarters';
  }

  @override
  String get cfErrorValue => 'Enter a value.';

  @override
  String cfErrorFormula(String message) {
    return 'Invalid formula: $message';
  }

  @override
  String get cfErrorNoFormat => 'Choose at least one format.';

  @override
  String get cfEnableRule => 'Enable rule';

  @override
  String get cfDisableRule => 'Disable rule';

  @override
  String get cfDeleteRule => 'Delete rule';

  @override
  String get cfRuleHint =>
      'Enter to edit, Alt+arrows to move, Delete to remove';

  @override
  String get rangeInputEmpty => 'Enter a range';

  @override
  String get rangeInputInvalid => 'Invalid range';

  @override
  String get rangeInputPick => 'Select a data range on the grid';

  @override
  String get rangeInputPicking =>
      'Select cells on the grid; the range follows your selection.';

  @override
  String get addRowsButton => 'Add';

  @override
  String get addRowsSuffix => 'more rows at bottom';

  @override
  String get alignBottom => 'Bottom';

  @override
  String get alignCenter => 'Center';

  @override
  String get alignLeft => 'Left';

  @override
  String get alignMiddle => 'Middle';

  @override
  String get alignRight => 'Right';

  @override
  String get alignTop => 'Top';

  @override
  String get badgeCommentOnly => 'Comment only';

  @override
  String get badgeViewOnly => 'View only';

  @override
  String get borderAll => 'All borders';

  @override
  String get borderBottom => 'Bottom border';

  @override
  String get borderClear => 'Clear borders';

  @override
  String get borderColor => 'Border color';

  @override
  String get borderHorizontal => 'Horizontal borders';

  @override
  String get borderInner => 'Inner borders';

  @override
  String get borderLeft => 'Left border';

  @override
  String get borderOuter => 'Outer borders';

  @override
  String get borderRight => 'Right border';

  @override
  String get borderStyleDashed => 'Dashed';

  @override
  String get borderStyleDotted => 'Dotted';

  @override
  String get borderStyleDouble => 'Double';

  @override
  String get borderStyleMedium => 'Medium';

  @override
  String get borderStyleThick => 'Thick';

  @override
  String get borderStyleThin => 'Thin';

  @override
  String get borderTop => 'Top border';

  @override
  String get borderVertical => 'Vertical borders';

  @override
  String get categoryData => 'Data';

  @override
  String get categoryEditing => 'Editing';

  @override
  String get categoryFile => 'File';

  @override
  String get categoryFormatting => 'Formatting';

  @override
  String get categoryFormulas => 'Formulas';

  @override
  String get categoryInsert => 'Insert';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categoryRowsColumns => 'Rows & columns';

  @override
  String get categorySheets => 'Sheets';

  @override
  String get categoryView => 'View';

  @override
  String get cmdAiAnalyze => 'Analyze data';

  @override
  String get cmdAiExplainFormula => 'Explain formula';

  @override
  String get cmdAiFillRange => 'Fill with AI';

  @override
  String get cmdAiSuggestFormula => 'Suggest a formula';

  @override
  String get cmdBandingOpenPanel => 'Alternating colors';

  @override
  String get cmdCellCancel => 'Cancel editing';

  @override
  String get cmdCellCommit => 'Commit cell';

  @override
  String get cmdCellCopyLink => 'Get link to this range';

  @override
  String get cmdCellEdit => 'Edit cell';

  @override
  String get cmdCellInsertDate => 'Insert date';

  @override
  String get cmdCellInsertDateTime => 'Insert date and time';

  @override
  String get cmdCellInsertNewline => 'Insert line break';

  @override
  String get cmdCellInsertTime => 'Insert time';

  @override
  String get cmdCellSetInput => 'Set cell input';

  @override
  String get cmdCellSetInputForSelection => 'Enter in all selected cells';

  @override
  String get cmdCellToggleEditMode => 'Toggle Enter/Edit mode';

  @override
  String get cmdCellsCopyRange => 'Copy range';

  @override
  String get cmdCellsDeleteShiftLeft => 'Delete cells and shift left';

  @override
  String get cmdCellsDeleteShiftUp => 'Delete cells and shift up';

  @override
  String get cmdCellsInsertShiftDown => 'Insert cells and shift down';

  @override
  String get cmdCellsInsertShiftRight => 'Insert cells and shift right';

  @override
  String get cmdCellsMoveRange => 'Move range';

  @override
  String get cmdCfOpenPanel => 'Conditional formatting';

  @override
  String get cmdChartInsert => 'Chart';

  @override
  String get cmdCleanupOpenRemoveDuplicates => 'Remove duplicates';

  @override
  String get cmdCleanupOpenSuggestions => 'Cleanup suggestions';

  @override
  String get cmdCleanupTrimWhitespace => 'Trim whitespace';

  @override
  String cmdClearColumns(String cols) {
    return 'Clear $cols';
  }

  @override
  String cmdClearRows(String rows) {
    return 'Clear $rows';
  }

  @override
  String get cmdColsDelete => 'Delete columns';

  @override
  String get cmdColsHide => 'Hide columns';

  @override
  String get cmdColsInsertDialog => 'Insert columns…';

  @override
  String get cmdColsInsertLeft => 'Insert column left';

  @override
  String cmdColsInsertLeftN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Insert $n columns left',
      one: 'Insert 1 column left',
    );
    return '$_temp0';
  }

  @override
  String get cmdColsInsertRight => 'Insert column right';

  @override
  String cmdColsInsertRightN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Insert $n columns right',
      one: 'Insert 1 column right',
    );
    return '$_temp0';
  }

  @override
  String get cmdColsMove => 'Move columns';

  @override
  String get cmdColsMoveLeft => 'Move column left';

  @override
  String get cmdColsMoveRight => 'Move column right';

  @override
  String get cmdColsResize => 'Resize columns';

  @override
  String get cmdColsResizeDialog => 'Resize columns…';

  @override
  String get cmdColsUnhide => 'Unhide columns';

  @override
  String get cmdCommentsOpenPanel => 'Show all comments';

  @override
  String get cmdContextMenuOpen => 'Open context menu';

  @override
  String get cmdDataColumnStats => 'Column stats';

  @override
  String get cmdDataExtraction => 'Data extraction';

  @override
  String get cmdDataOpenSortDialog => 'Advanced range sorting options';

  @override
  String get cmdDataRandomizeRange => 'Randomize range';

  @override
  String get cmdDataSortRange => 'Sort range';

  @override
  String get cmdDataSortSheet => 'Sort sheet';

  @override
  String cmdDataSortSheetBy(String col) {
    return 'Sort sheet by column $col';
  }

  @override
  String get cmdDataSplitTextToColumns => 'Split text to columns';

  @override
  String cmdDeleteColumnsLabel(String cols) {
    return 'Delete $cols';
  }

  @override
  String cmdDeleteRowsLabel(String rows) {
    return 'Delete $rows';
  }

  @override
  String get cmdDrawingInsert => 'Drawing';

  @override
  String get cmdDvOpenDropdown => 'Open dropdown';

  @override
  String get cmdDvOpenPanel => 'Data validation';

  @override
  String get cmdDvToggleCheckbox => 'Toggle checkboxes';

  @override
  String get cmdEditClearAll => 'Clear';

  @override
  String get cmdEditClearValues => 'Delete values';

  @override
  String get cmdEditCopy => 'Copy';

  @override
  String get cmdEditCut => 'Cut';

  @override
  String get cmdEditPaste => 'Paste';

  @override
  String get cmdEditPasteSpecial => 'Paste special';

  @override
  String get cmdEditPasteSpecialDialog => 'Paste special…';

  @override
  String get cmdEditRedo => 'Redo';

  @override
  String get cmdEditRepeatLast => 'Repeat last action';

  @override
  String get cmdEditUndo => 'Undo';

  @override
  String get cmdEditUndoHistory => 'Undo history…';

  @override
  String get cmdExploreToggle => 'Explore';

  @override
  String get cmdFileDownload => 'Download';

  @override
  String get cmdFileImport => 'Import…';

  @override
  String get cmdFileSaveNoop => 'Save';

  @override
  String get cmdFileSettings => 'Settings';

  @override
  String get cmdFillAutoFillDown => 'Fill down to the data';

  @override
  String get cmdFillDown => 'Fill down';

  @override
  String get cmdFillRight => 'Fill right';

  @override
  String get cmdFillSelection => 'Fill selection';

  @override
  String get cmdFillSeries => 'Fill series';

  @override
  String get cmdFilterByCellValue => 'Filter by cell value';

  @override
  String get cmdFilterToggle => 'Create a filter';

  @override
  String get cmdFilterViewActivate => 'Change view';

  @override
  String get cmdFilterViewCreate => 'Create filter view';

  @override
  String get cmdFindOpen => 'Find';

  @override
  String get cmdFindOpenReplace => 'Find and replace';

  @override
  String get cmdFitToData => 'Fit to data';

  @override
  String get cmdFormatApplyPaintFormat => 'Paint format';

  @override
  String get cmdFormatBold => 'Bold';

  @override
  String get cmdFormatBorders => 'Borders';

  @override
  String get cmdFormatClear => 'Clear formatting';

  @override
  String get cmdFormatConvertToTable => 'Convert to table';

  @override
  String get cmdFormatDecreaseDecimals => 'Decrease decimal places';

  @override
  String get cmdFormatDecreaseFontSize => 'Decrease font size';

  @override
  String get cmdFormatFillColor => 'Fill color';

  @override
  String get cmdFormatFontFamily => 'Font';

  @override
  String get cmdFormatFontSize => 'Font size';

  @override
  String get cmdFormatHAlign => 'Horizontal align';

  @override
  String get cmdFormatIncreaseDecimals => 'Increase decimal places';

  @override
  String get cmdFormatIncreaseFontSize => 'Increase font size';

  @override
  String get cmdFormatItalic => 'Italic';

  @override
  String get cmdFormatMerge => 'Merge cells';

  @override
  String get cmdFormatNumberFormat => 'Number format';

  @override
  String get cmdFormatOpenCustomCurrency => 'Custom currency';

  @override
  String get cmdFormatOpenCustomDateTime => 'Custom date and time';

  @override
  String get cmdFormatOpenCustomNumberFormat => 'Custom number format';

  @override
  String get cmdFormatPaintFormat => 'Paint format';

  @override
  String get cmdFormatRotation => 'Text rotation';

  @override
  String get cmdFormatStrikethrough => 'Strikethrough';

  @override
  String get cmdFormatTextColor => 'Text color';

  @override
  String get cmdFormatUnderline => 'Underline';

  @override
  String get cmdFormatUnmerge => 'Unmerge';

  @override
  String get cmdFormatVAlign => 'Vertical align';

  @override
  String get cmdFormatWrap => 'Text wrapping';

  @override
  String get cmdFormulaAcceptCompletion => 'Insert suggestion';

  @override
  String get cmdFormulaBarToggleExpanded => 'Expand formula bar';

  @override
  String get cmdFormulaCycleReferenceType => 'Toggle absolute reference';

  @override
  String get cmdFormulaDismissCompletion => 'Dismiss suggestions';

  @override
  String get cmdFormulaMovePoint => 'Move pointed reference';

  @override
  String get cmdFormulaNextCompletion => 'Next suggestion';

  @override
  String get cmdFormulaToggleArrayFormula => 'Toggle ARRAYFORMULA';

  @override
  String get cmdFormulaToggleHelpCard => 'Expand formula help';

  @override
  String get cmdFormulaToggleHelpCardVisible => 'Show formula help';

  @override
  String get cmdGroupCollapseAll => 'Collapse all groups';

  @override
  String get cmdGroupColumns => 'Group columns';

  @override
  String get cmdGroupExpandAll => 'Expand all groups';

  @override
  String get cmdGroupRows => 'Group rows';

  @override
  String get cmdHelpFunctionList => 'Function list';

  @override
  String cmdHideColumnsLabel(String cols) {
    return 'Hide $cols';
  }

  @override
  String cmdHideRowsLabel(String rows) {
    return 'Hide $rows';
  }

  @override
  String get cmdHistoryNameCurrentVersion => 'Name current version';

  @override
  String get cmdHistoryOpen => 'See version history';

  @override
  String get cmdHistoryShowCellHistory => 'Show edit history';

  @override
  String get cmdImageInsertInCell => 'Insert image in cell';

  @override
  String get cmdImageInsertOverCells => 'Insert image over cells';

  @override
  String get cmdInsertCheckbox => 'Checkbox';

  @override
  String get cmdInsertDropdown => 'Dropdown';

  @override
  String get cmdInsertEmoji => 'Emoji';

  @override
  String get cmdInsertFunction => 'Insert function';

  @override
  String get cmdInsertLink => 'Insert link';

  @override
  String get cmdInsertPivotTable => 'Pivot table';

  @override
  String get cmdPivotExpandGrid => 'Insert rows for the pivot table';

  @override
  String get pivotExpandGrid => 'Insert rows';

  @override
  String get pivotCondBlank => 'Is empty';

  @override
  String get pivotCondNotBlank => 'Is not empty';

  @override
  String get pivotCondTextContains => 'Text contains';

  @override
  String get pivotCondTextNotContains => 'Text does not contain';

  @override
  String get pivotCondTextStartsWith => 'Text starts with';

  @override
  String get pivotCondTextEndsWith => 'Text ends with';

  @override
  String get pivotCondTextEq => 'Text is exactly';

  @override
  String get pivotCondDateEq => 'Date is';

  @override
  String get pivotCondDateBefore => 'Date is before';

  @override
  String get pivotCondDateAfter => 'Date is after';

  @override
  String get pivotCondNumberGreater => 'Greater than';

  @override
  String get pivotCondNumberGreaterEq => 'Greater than or equal to';

  @override
  String get pivotCondNumberLess => 'Less than';

  @override
  String get pivotCondNumberLessEq => 'Less than or equal to';

  @override
  String get pivotCondNumberEq => 'Is equal to';

  @override
  String get pivotCondNumberNotEq => 'Is not equal to';

  @override
  String get pivotCondNumberBetween => 'Is between';

  @override
  String get pivotCondNumberNotBetween => 'Is not between';

  @override
  String get pivotCondCustomFormula => 'Custom formula is';

  @override
  String get pivotCondAnd => 'and';

  @override
  String get pivotApply => 'OK';

  @override
  String get pivotCancel => 'Cancel';

  @override
  String get pivotAddCalculatedField => 'Add calculated field';

  @override
  String get cmdPivotOpenEditor => 'Edit pivot table';

  @override
  String get cmdPivotUpdate => 'Edit pivot table';

  @override
  String get cmdPivotDelete => 'Delete pivot table';

  @override
  String get cmdPivotRefresh => 'Refresh pivot table';

  @override
  String get cmdPivotDrillDown => 'Show details';

  @override
  String get cmdPivotCreateGroup => 'Create pivot group';

  @override
  String get pivotReadOnlyToast =>
      'You can\'t edit a pivot table\'s output. Use the pivot table editor.';

  @override
  String get reasonNoPivot => 'Select a cell in a pivot table';

  @override
  String get pivotNoData => 'Select a data range for the pivot table';

  @override
  String get pivotNotAValueCell => 'Select a value cell of the pivot table';

  @override
  String get pivotInvalidGroup => 'The grouping is not valid';

  @override
  String get pivotFieldNotInRows => 'Add the field to Rows or Columns first';

  @override
  String get pivotSheetPrefix => 'Pivot table';

  @override
  String get pivotDetailsSheetPrefix => 'Details';

  @override
  String pivotDrillDownConfirmTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Show $countString rows?';
  }

  @override
  String get pivotDrillDownConfirmBody =>
      'A new sheet with every source row of this value will be created. Large sheets can be slow.';

  @override
  String get pivotEditButton => 'Edit';

  @override
  String get pivotPanelTitle => 'Pivot table editor';

  @override
  String get pivotPanelEmpty =>
      'Select a cell in a pivot table to edit it, or insert a new pivot table.';

  @override
  String get pivotPanelOptions => 'Pivot table options';

  @override
  String get pivotRange => 'Range';

  @override
  String get pivotRangeInvalid => 'Enter a valid range, e.g. Sheet1!A1:F100';

  @override
  String get pivotSuggested => 'Suggested';

  @override
  String pivotSuggestionBy(String value, String field) {
    return '$value by $field';
  }

  @override
  String pivotSuggestionCount(String field) {
    return 'Count of $field';
  }

  @override
  String get pivotRows => 'Rows';

  @override
  String get pivotColumns => 'Columns';

  @override
  String get pivotValues => 'Values';

  @override
  String get pivotFilters => 'Filters';

  @override
  String get pivotAdd => 'Add';

  @override
  String pivotAddTo(String area) {
    return 'Add field to $area';
  }

  @override
  String get pivotSearchFields => 'Search fields';

  @override
  String get pivotNoFields => 'No matching fields';

  @override
  String get pivotCalculatedField => 'Calculated field';

  @override
  String get pivotAreaEmpty => 'Drop a field here or use Add';

  @override
  String get pivotOrder => 'Order';

  @override
  String get pivotAscending => 'Ascending';

  @override
  String get pivotDescending => 'Descending';

  @override
  String get pivotSortBy => 'Sort by';

  @override
  String get pivotShowTotals => 'Show totals';

  @override
  String get pivotRepeatLabels => 'Repeat row labels';

  @override
  String get pivotSummarizeBy => 'Summarize by';

  @override
  String get pivotSummarizeCustom => 'Custom';

  @override
  String get pivotShowAs => 'Show as';

  @override
  String get pivotShowAsDefault => 'Default';

  @override
  String get pivotShowAsRow => '% of row';

  @override
  String get pivotShowAsColumn => '% of column';

  @override
  String get pivotShowAsGrandTotal => '% of grand total';

  @override
  String get pivotDisplayValuesAs => 'Display';

  @override
  String get pivotValuesAsColumns => 'Columns';

  @override
  String get pivotValuesAsRows => 'Rows';

  @override
  String get pivotFilterStatus => 'Status';

  @override
  String get pivotFilterAll => 'Showing all items';

  @override
  String pivotFilterSome(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Showing $shownString of $totalString items';
  }

  @override
  String get pivotFilterCondition => 'Filtered by condition';

  @override
  String get pivotFilterByValues => 'Filter by values';

  @override
  String get pivotFilterByCondition => 'Filter by condition';

  @override
  String get pivotSelectAll => 'Select all';

  @override
  String get pivotClearAll => 'Clear';

  @override
  String get pivotBlanks => '(Blanks)';

  @override
  String get pivotConditionNone => 'None';

  @override
  String get pivotConditionValue => 'Value';

  @override
  String pivotFilterTooMany(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Showing $shownString of $totalString values — refine your search';
  }

  @override
  String pivotMoveTo(String area) {
    return 'Move to $area';
  }

  @override
  String get pivotMoveUp => 'Move up';

  @override
  String get pivotMoveDown => 'Move down';

  @override
  String get pivotRemoveField => 'Remove field';

  @override
  String get pivotRenameField => 'Rename…';

  @override
  String get pivotRenameTitle => 'Rename value';

  @override
  String get pivotRenameLabel => 'Name';

  @override
  String pivotFieldOptions(String field) {
    return 'Options of $field';
  }

  @override
  String pivotDragHandle(String field) {
    return 'Drag $field to another area';
  }

  @override
  String get pivotFieldMissing =>
      'This field no longer exists in the source range';

  @override
  String get pivotDateGroup => 'Create pivot date group';

  @override
  String get pivotHistogramGroup => 'Create pivot group rule…';

  @override
  String get pivotRemoveGroup => 'Remove grouping';

  @override
  String pivotGroupedBy(String group) {
    return 'Grouped: $group';
  }

  @override
  String pivotHistogramLabel(String size) {
    return 'Intervals of $size';
  }

  @override
  String pivotManualGroupLabel(int count) {
    return '$count groups';
  }

  @override
  String get pivotHistogramTitle => 'Create pivot group rule';

  @override
  String get pivotHistogramMin => 'Minimum value';

  @override
  String get pivotHistogramMax => 'Maximum value';

  @override
  String get pivotHistogramSize => 'Interval size';

  @override
  String get pivotHistogramInvalidSize => 'Enter a number greater than 0';

  @override
  String get pivotHistogramInvalidNumber => 'Enter a number or leave it empty';

  @override
  String get pivotFormula => 'Formula';

  @override
  String get pivotFormulaHint =>
      'Use source headers as names, e.g. =\'Unit price\' * Quantity';

  @override
  String get pivotValueName => 'Name';

  @override
  String get pivotDateSecond => 'Second';

  @override
  String get pivotDateMinute => 'Minute';

  @override
  String get pivotDateHour => 'Hour';

  @override
  String get pivotDateHourMinute => 'Hour-Minute';

  @override
  String get pivotDateHourMinuteAmPm => 'Hour-Minute (AM/PM)';

  @override
  String get pivotDateDayOfWeek => 'Day of the week';

  @override
  String get pivotDateDayOfYear => 'Day of the year';

  @override
  String get pivotDateDayOfMonth => 'Day of the month';

  @override
  String get pivotDateDayMonth => 'Day-Month';

  @override
  String get pivotDateMonth => 'Month';

  @override
  String get pivotDateQuarter => 'Quarter';

  @override
  String get pivotDateYear => 'Year';

  @override
  String get pivotDateYearMonth => 'Year-Month';

  @override
  String get pivotDateYearQuarter => 'Year-Quarter';

  @override
  String get pivotDateYearMonthDay => 'Year-Month-Day';

  @override
  String get pivotSelectBlocking => 'Select blocking cells';

  @override
  String get pivotStale => 'Updating…';

  @override
  String get dialogCreatePivotTitle => 'Create pivot table';

  @override
  String get dialogCreatePivotRange => 'Data range';

  @override
  String get dialogCreatePivotInsertTo => 'Insert to';

  @override
  String get dialogCreatePivotNewSheet => 'New sheet';

  @override
  String get dialogCreatePivotExistingSheet => 'Existing sheet';

  @override
  String get dialogCreatePivotLocation => 'Location (existing sheet)';

  @override
  String get dialogCreatePivotCreate => 'Create';

  @override
  String get dialogCreatePivotInvalidRange =>
      'Enter a valid range, e.g. Sheet1!A1:F100';

  @override
  String get dialogCreatePivotInvalidLocation =>
      'Enter a single cell, e.g. Sheet2!H1';

  @override
  String get cmdInsertSmartChip => 'Smart chips';

  @override
  String get cmdLinkOpen => 'Open link';

  @override
  String get cmdLinkRemove => 'Remove link';

  @override
  String get cmdMacroImport => 'Import macro';

  @override
  String get cmdMacroManage => 'Manage macros';

  @override
  String get cmdMacroRecord => 'Record macro';

  @override
  String get cmdModeEditing => 'Editing';

  @override
  String get cmdModeViewing => 'Viewing';

  @override
  String get cmdNamedFunctionsOpenPanel => 'Named functions';

  @override
  String get cmdNamedRangesCreateFromSelection => 'Create named range';

  @override
  String get cmdNamedRangesOpenPanel => 'Named ranges';

  @override
  String get cmdNavEnter => 'Move down (Enter)';

  @override
  String get cmdNavGoTo => 'Go to range';

  @override
  String get cmdNavMove => 'Move active cell';

  @override
  String get cmdNavPage => 'Page up/down';

  @override
  String get cmdNavPageHorizontal => 'Page left/right';

  @override
  String get cmdNavRowEnd => 'Go to end of row';

  @override
  String get cmdNavRowStart => 'Go to start of row';

  @override
  String get cmdNavScrollToActive => 'Scroll to active cell';

  @override
  String get cmdNavSheetEnd => 'Go to last used cell';

  @override
  String get cmdNavSheetStart => 'Go to A1';

  @override
  String get cmdNavTab => 'Move right (Tab)';

  @override
  String get cmdNotesClear => 'Clear notes';

  @override
  String get cmdNotesInsert => 'Note';

  @override
  String get cmdNotificationsOpenRules => 'Notification rules';

  @override
  String get cmdNotificationsOpenSettings => 'Comment notifications';

  @override
  String get cmdPrintOpen => 'Print';

  @override
  String get cmdProtectOpenPanel => 'Protect sheets and ranges';

  @override
  String cmdResizeColumnsLabel(String cols) {
    return 'Resize $cols';
  }

  @override
  String cmdResizeRowsLabel(String rows) {
    return 'Resize $rows';
  }

  @override
  String get cmdRowsAddMore => 'Add more rows';

  @override
  String get cmdRowsDelete => 'Delete rows';

  @override
  String get cmdRowsHide => 'Hide rows';

  @override
  String get cmdRowsInsertAbove => 'Insert row above';

  @override
  String cmdRowsInsertAboveN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Insert $n rows above',
      one: 'Insert 1 row above',
    );
    return '$_temp0';
  }

  @override
  String get cmdRowsInsertBelow => 'Insert row below';

  @override
  String cmdRowsInsertBelowN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Insert $n rows below',
      one: 'Insert 1 row below',
    );
    return '$_temp0';
  }

  @override
  String get cmdRowsInsertDialog => 'Insert rows…';

  @override
  String get cmdRowsMove => 'Move rows';

  @override
  String get cmdRowsMoveDown => 'Move row down';

  @override
  String get cmdRowsMoveUp => 'Move row up';

  @override
  String get cmdRowsResize => 'Resize rows';

  @override
  String get cmdRowsResizeDialog => 'Resize rows…';

  @override
  String get cmdRowsUnhide => 'Unhide rows';

  @override
  String get cmdScriptOpenEditor => 'Open script editor';

  @override
  String get cmdScriptOpenExecutions => 'Executions';

  @override
  String get cmdScriptOpenTriggers => 'Triggers';

  @override
  String get cmdSelectAll => 'Select all';

  @override
  String get cmdSelectColumns => 'Select columns';

  @override
  String get cmdSelectDataRegion => 'Select data region';

  @override
  String get cmdSelectRange => 'Select range';

  @override
  String get cmdSelectRows => 'Select rows';

  @override
  String get cmdSheetActivate => 'Go to sheet';

  @override
  String get cmdSheetActivateNext => 'Next sheet';

  @override
  String get cmdSheetActivatePrevious => 'Previous sheet';

  @override
  String get cmdSheetAdd => 'Add sheet';

  @override
  String get cmdSheetCopyToExisting => 'Existing spreadsheet…';

  @override
  String get cmdSheetCopyToNew => 'New spreadsheet';

  @override
  String get cmdSheetDelete => 'Delete';

  @override
  String get cmdSheetDuplicate => 'Duplicate';

  @override
  String get cmdSheetHide => 'Hide sheet';

  @override
  String get cmdSheetMove => 'Move sheet';

  @override
  String get cmdSheetMoveLeft => 'Move left';

  @override
  String get cmdSheetMoveRight => 'Move right';

  @override
  String get cmdSheetRename => 'Rename';

  @override
  String get cmdSheetSetColor => 'Change color';

  @override
  String get cmdSheetSetRightToLeft => 'Right-to-left';

  @override
  String get cmdSheetUnhide => 'Unhide sheet';

  @override
  String get cmdSlicerAdd => 'Add a slicer';

  @override
  String get slicerUntitled => 'Slicer';

  @override
  String get slicerAll => 'Showing all';

  @override
  String get slicerByCondition => 'Filtered by condition';

  @override
  String slicerHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count values hidden',
      one: '1 value hidden',
    );
    return '$_temp0';
  }

  @override
  String slicerLocal(String summary) {
    return '$summary (only you)';
  }

  @override
  String get slicerOpen => 'Filter values';

  @override
  String get slicerSearch => 'Search values';

  @override
  String get slicerSelectAll => 'Select all';

  @override
  String get slicerClear => 'Clear';

  @override
  String get slicerBlanks => '(Blanks)';

  @override
  String get slicerCancel => 'Cancel';

  @override
  String get slicerOk => 'OK';

  @override
  String get slicerNone => 'Select a slicer to edit it.';

  @override
  String get slicerPanelTitle => 'Slicer';

  @override
  String get slicerDataRange => 'Data range';

  @override
  String get slicerColumn => 'Column';

  @override
  String get slicerApplyToPivots => 'Apply to pivot tables';

  @override
  String get slicerTitle => 'Title';

  @override
  String get slicerTitlePlaceholder => 'Column header';

  @override
  String get slicerStyle => 'Style';

  @override
  String get slicerBackground => 'Background color';

  @override
  String get slicerTextColor => 'Text color';

  @override
  String get slicerSetDefault => 'Set current filters as default';

  @override
  String get slicerReset => 'Reset filter';

  @override
  String get slicerNeedsData =>
      'Select a range with a header row to add a slicer.';

  @override
  String get cmdSlicerEdit => 'Edit slicer';

  @override
  String get cmdSlicerUpdate => 'Update slicer';

  @override
  String get cmdSlicerSetCriteria => 'Set slicer filter';

  @override
  String get cmdSlicerSetDefault => 'Set slicer filters as default';

  @override
  String get cmdSlicerReset => 'Reset slicer';

  @override
  String get cmdStatsSetShown => 'Show statistic';

  @override
  String get cmdStructureDeleteBySelection => 'Delete rows, columns or cells';

  @override
  String get cmdStructureInsertBySelection => 'Insert rows, columns or cells';

  @override
  String get cmdStructureOpenDeleteDialog => 'Delete cells…';

  @override
  String get cmdThemeOpenPanel => 'Theme';

  @override
  String get cmdToolsPersonalDictionary => 'Personal dictionary';

  @override
  String get cmdToolsSpellCheck => 'Spell check';

  @override
  String get cmdToolsToggleAutocomplete => 'Autocomplete';

  @override
  String get cmdToolsToggleFormulaSuggestions => 'Formula suggestions';

  @override
  String get cmdUngroupColumns => 'Ungroup columns';

  @override
  String get cmdUngroupRows => 'Ungroup rows';

  @override
  String get cmdViewFreezeColumns => 'Freeze columns';

  @override
  String get cmdViewFreezeRows => 'Freeze rows';

  @override
  String get cmdViewToggleCommentIndicators => 'Hide comment indicators';

  @override
  String get cmdViewToggleFormulaBar => 'Formula bar';

  @override
  String get cmdViewToggleFormulas => 'Formulas';

  @override
  String get cmdViewToggleGridlines => 'Gridlines';

  @override
  String get cmdViewToggleProtectedRanges => 'Protected ranges';

  @override
  String get cmdViewZoom => 'Zoom';

  @override
  String get cmdViewZoomIn => 'Zoom in';

  @override
  String get cmdViewZoomOut => 'Zoom out';

  @override
  String get colorAutomatic => 'Automatic';

  @override
  String get colorNone => 'None';

  @override
  String get contextDeleteCells => 'Delete cells';

  @override
  String get contextEditLink => 'Edit link';

  @override
  String get contextFitAllColumns => 'Fit all columns to data';

  @override
  String get contextInsertCells => 'Insert cells';

  @override
  String get contextMoreCellActions => 'View more cell actions';

  @override
  String get contextMoreColumnActions => 'View more column actions';

  @override
  String get contextMoreRowActions => 'View more row actions';

  @override
  String get contextUnhideAllColumns => 'Unhide all columns';

  @override
  String get contextUnhideAllRows => 'Unhide all rows';

  @override
  String get dialogApply => 'Apply';

  @override
  String get dialogCustomNumberFormatTitle => 'Custom number format';

  @override
  String get dialogDelete => 'Delete';

  @override
  String get dialogDeleteCellsTitle => 'Delete cells';

  @override
  String get dialogDeleteSheetBody => 'You can undo this.';

  @override
  String dialogDeleteSheetTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get dialogEntireColumn => 'Entire column';

  @override
  String get dialogEntireRow => 'Entire row';

  @override
  String get dialogInsert => 'Insert';

  @override
  String get dialogInsertAbove => 'Above';

  @override
  String get dialogInsertBelow => 'Below';

  @override
  String get dialogInsertCellsTitle => 'Insert cells';

  @override
  String get dialogInsertCount => 'Number';

  @override
  String get dialogInsertInvalid => 'Enter a number from 1 to 10,000';

  @override
  String get dialogInsertLeft => 'Left';

  @override
  String get dialogInsertPosition => 'Position';

  @override
  String get dialogInsertRight => 'Right';

  @override
  String get dialogLinkText => 'Text';

  @override
  String get dialogLinkTitle => 'Insert link';

  @override
  String get dialogLinkUrl => 'Link';

  @override
  String get dialogMergeAll =>
      'Merging cells will only preserve the top-leftmost value. Merge anyway?';

  @override
  String get dialogMergeHorizontal =>
      'Merging cells will only preserve the leftmost value of each row. Merge anyway?';

  @override
  String get dialogMergeTitle => 'Merge cells';

  @override
  String get dialogMergeVertical =>
      'Merging cells will only preserve the top value of each column. Merge anyway?';

  @override
  String get dialogNoteLabel => 'Note';

  @override
  String get dialogNoteTitle => 'Note';

  @override
  String get dialogOk => 'OK';

  @override
  String get dialogPaste => 'Paste';

  @override
  String get dialogPasteSpecialMode => 'Paste';

  @override
  String get dialogPasteSpecialTitle => 'Paste special';

  @override
  String get dialogReplaceDataBody => 'Do you want to replace it?';

  @override
  String get dialogReplaceDataTitle => 'There\'s already data here';

  @override
  String get dialogResizeInvalid => 'Enter a size from 2 to 5,000 px';

  @override
  String get dialogResizeMode => 'Size';

  @override
  String get dialogResizeSize => 'Size (px)';

  @override
  String get dialogResizeSpecifyColumn => 'Specify column width';

  @override
  String get dialogResizeSpecifyRow => 'Specify row height';

  @override
  String get dialogRotationLabel => 'Angle (degrees)';

  @override
  String get dialogRotationTitle => 'Custom angle';

  @override
  String get dialogSave => 'Save';

  @override
  String get dialogShiftMode => 'Shift';

  @override
  String get downloadCsv => 'Comma-separated values (.csv, current sheet)';

  @override
  String get downloadHtml => 'Web page (.html, zipped)';

  @override
  String get downloadOds => 'OpenDocument (.ods)';

  @override
  String get downloadPdf => 'PDF (.pdf)';

  @override
  String get downloadTsv => 'Tab-separated values (.tsv, current sheet)';

  @override
  String get downloadJson => 'JSON (.json, values and formulas)';

  @override
  String get downloadXlsx => 'Microsoft Excel (.xlsx)';

  @override
  String get errorSheetNameEmpty => 'A sheet name can’t be empty';

  @override
  String formulaParseError(String message) {
    return '$message';
  }

  @override
  String freezeColumns(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n columns',
      one: '1 column',
    );
    return '$_temp0';
  }

  @override
  String get freezeNoColumns => 'No columns';

  @override
  String get freezeNoRows => 'No rows';

  @override
  String freezeRows(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String freezeUpToColumn(String col) {
    return 'Up to column $col';
  }

  @override
  String freezeUpToRow(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Up to row $rowString';
  }

  @override
  String gridSemanticsLabel(String sheet) {
    return '$sheet grid';
  }

  @override
  String labelColumn(String col) {
    return 'column $col';
  }

  @override
  String labelColumns(String from, String to) {
    return 'columns $from – $to';
  }

  @override
  String labelRow(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'row $rowString';
  }

  @override
  String labelRows(int from, int to) {
    final intl.NumberFormat fromNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String toString = toNumberFormat.format(to);

    return 'rows $fromString – $toString';
  }

  @override
  String get loadingSpreadsheet => 'Opening spreadsheet…';

  @override
  String get menuAi => 'AI';

  @override
  String get menuAlignment => 'Alignment';

  @override
  String get menuCells => 'Cells';

  @override
  String get menuColumns => 'Columns';

  @override
  String get menuComments => 'Comments';

  @override
  String get menuData => 'Data';

  @override
  String get menuDataCleanup => 'Data cleanup';

  @override
  String get menuDelete => 'Delete';

  @override
  String get menuDownload => 'Download';

  @override
  String get menuExtensions => 'Extensions';

  @override
  String get menuFontSize => 'Font size';

  @override
  String get menuFormat => 'Format';

  @override
  String get menuFreeze => 'Freeze';

  @override
  String get menuFunction => 'Function';

  @override
  String get menuGroup => 'Group';

  @override
  String get menuHiddenSheets => 'Hidden sheets';

  @override
  String get menuImage => 'Image';

  @override
  String get menuInsert => 'Insert';

  @override
  String get menuMacros => 'Macros';

  @override
  String get menuMergeCells => 'Merge cells';

  @override
  String get menuMove => 'Move';

  @override
  String get menuNoHiddenSheets => 'No hidden sheets';

  @override
  String get menuNotificationSettings => 'Notification settings';

  @override
  String get menuNumber => 'Number';

  @override
  String get menuPasteSpecial => 'Paste special';

  @override
  String get menuRotation => 'Rotation';

  @override
  String get menuRows => 'Rows';

  @override
  String get menuScripts => 'Scripts';

  @override
  String get menuShow => 'Show';

  @override
  String get menuSortRange => 'Sort range';

  @override
  String get menuSortSheet => 'Sort sheet';

  @override
  String get menuSpelling => 'Spelling';

  @override
  String get menuText => 'Text';

  @override
  String get menuWrapping => 'Wrapping';

  @override
  String get menuZoom => 'Zoom';

  @override
  String get mergeAll => 'Merge all';

  @override
  String get mergeHorizontally => 'Merge horizontally';

  @override
  String get mergeVertically => 'Merge vertically';

  @override
  String get numberFormatAccounting => 'Accounting';

  @override
  String get numberFormatAutomatic => 'Automatic';

  @override
  String get numberFormatCurrency => 'Currency';

  @override
  String get numberFormatCurrencyRounded => 'Currency rounded';

  @override
  String get numberFormatDate => 'Date';

  @override
  String get numberFormatDateTime => 'Date time';

  @override
  String get numberFormatDuration => 'Duration';

  @override
  String get numberFormatFinancial => 'Financial';

  @override
  String get numberFormatNumber => 'Number';

  @override
  String get numberFormatPercent => 'Percent';

  @override
  String get numberFormatPlainText => 'Plain text';

  @override
  String get numberFormatScientific => 'Scientific';

  @override
  String get numberFormatTime => 'Time';

  @override
  String get pasteAllExceptBorders => 'All except borders';

  @override
  String get pasteColumnWidthsOnly => 'Column widths only';

  @override
  String get pasteConditionalFormattingOnly => 'Conditional formatting only';

  @override
  String get pasteDataValidationOnly => 'Data validation only';

  @override
  String get pasteFormatOnly => 'Format only';

  @override
  String get pasteFormulasOnly => 'Formula only';

  @override
  String get pasteTransposed => 'Transposed';

  @override
  String get pasteValuesOnly => 'Values only';

  @override
  String get reasonNotAvailableYet => 'Not available yet';

  @override
  String get reasonSpreadsheetLoading => 'The spreadsheet is still opening';

  @override
  String get reasonViewAccess => 'You have view access';

  @override
  String get reasonViewingMode => 'Switch to Editing mode to make changes';

  @override
  String get reasonTextSelected =>
      'Not available while text in the cell is selected';

  @override
  String get rotationCustom => 'Custom angle…';

  @override
  String get rotationDown => 'Rotate down';

  @override
  String get rotationNone => 'None';

  @override
  String get rotationStack => 'Stack vertically';

  @override
  String get rotationTiltDown => 'Tilt down';

  @override
  String get rotationTiltUp => 'Tilt up';

  @override
  String get rotationUp => 'Rotate up';

  @override
  String get screenGoHome => 'Go to home';

  @override
  String get screenOfflineUnavailable =>
      'This spreadsheet isn’t available offline';

  @override
  String get screenOfflineHint =>
      'It isn’t on this device yet. Open it once while online to keep it available offline.';

  @override
  String get screenOpenFailed => 'The spreadsheet couldn’t be opened';

  @override
  String get screenTryAgain => 'Try again';

  @override
  String get screenUnavailable => 'This spreadsheet isn’t available';

  @override
  String sheetHiddenLabel(String name) {
    return '$name (hidden)';
  }

  @override
  String get sortAtoZ => 'A to Z';

  @override
  String get sortSheetAtoZ => 'Sort sheet A to Z';

  @override
  String get sortSheetZtoA => 'Sort sheet Z to A';

  @override
  String get sortZtoA => 'Z to A';

  @override
  String get statAverage => 'Average';

  @override
  String get statCount => 'Count';

  @override
  String get statCountNumbers => 'Count numbers';

  @override
  String get statMax => 'Max';

  @override
  String get statMin => 'Min';

  @override
  String get statSum => 'Sum';

  @override
  String statusCellCount(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString cells';
  }

  @override
  String get statusCellLimitTooltip =>
      'Cells in this spreadsheet (rows × columns of every sheet) and the limit';

  @override
  String get statusModeEdit => 'Edit';

  @override
  String get statusModeEnter => 'Enter';

  @override
  String get statusModePoint => 'Point';

  @override
  String get statusModeReady => 'Ready';

  @override
  String statusSheetSize(String name, int rows, int cols) {
    final intl.NumberFormat rowsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowsString = rowsNumberFormat.format(rows);
    final intl.NumberFormat colsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String colsString = colsNumberFormat.format(cols);

    return '$name · $rowsString × $colsString';
  }

  @override
  String get tabAllSheets => 'All sheets';

  @override
  String get tabBarLabel => 'Sheet tabs';

  @override
  String get tabCopyTo => 'Copy to';

  @override
  String get tabDuplicateName => 'Another sheet has the same name';

  @override
  String tabMenu(String name) {
    return 'Options for $name';
  }

  @override
  String get tabScrollLeft => 'Scroll tabs left';

  @override
  String get tabScrollRight => 'Scroll tabs right';

  @override
  String get toastCantDeleteAllColumns =>
      'A sheet must have at least one column';

  @override
  String get toastCantDeleteAllRows => 'A sheet must have at least one row';

  @override
  String get toastCantHideAll =>
      'You can’t hide all rows or columns of a sheet';

  @override
  String get toastClipboardEmpty => 'The clipboard is empty';

  @override
  String get screenStorageUnavailable =>
      'The spreadsheet storage on this device didn\'t start. Try again, or reload the page.';

  @override
  String get toastClipboardBlocked =>
      'The browser blocked access to the clipboard. Allow clipboard access for this site to paste here.';

  @override
  String get toastCommandFailed => 'That didn’t work';

  @override
  String get toastEditedRowDeleted => 'The cell you were editing was deleted';

  @override
  String get toastFreezeTooLarge =>
      'The frozen area would be larger than the window. Zoom out or freeze fewer rows.';

  @override
  String toastInvalidRange(String range) {
    return '“$range” isn’t a valid range';
  }

  @override
  String get toastLinkCopied => 'Link copied';

  @override
  String get toastMultipleSelections =>
      'This action won’t work on multiple selections';

  @override
  String toastNamedRangeCreated(String name) {
    return 'Named range “$name” created';
  }

  @override
  String get toastSavesAutomatically => 'Wonky Sheets saves automatically';

  @override
  String toastTrimmed(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Trimmed $n cells',
      one: 'Trimmed 1 cell',
      zero: 'No cells needed trimming',
    );
    return '$_temp0';
  }

  @override
  String get toastUndoPartial =>
      'Some changes couldn’t be undone because they were edited by someone else.';

  @override
  String toastChangeNotSaved(String label, String reason) {
    return '“$label” couldn’t be saved: $reason';
  }

  @override
  String toastChangeProtected(String label) {
    return '“$label” wasn’t saved because it edits a protected cell or object.';
  }

  @override
  String get toastChangeNoAccess => 'You can no longer edit this spreadsheet';

  @override
  String get toolbarBorders => 'Borders';

  @override
  String get toolbarCurrency => 'Format as currency';

  @override
  String get toolbarFillColor => 'Fill color';

  @override
  String get toolbarFont => 'Font';

  @override
  String get toolbarFontSize => 'Font size';

  @override
  String get toolbarFunctions => 'Functions';

  @override
  String get toolbarHAlign => 'Horizontal align';

  @override
  String get toolbarLabel => 'Formatting toolbar';

  @override
  String get toolbarMerge => 'Merge cells';

  @override
  String get toolbarMoreFormats => 'More formats';

  @override
  String get toolbarPercent => 'Format as percent';

  @override
  String get toolbarRedo => 'Redo';

  @override
  String toolbarRedoLabel(String label) {
    return 'Redo $label';
  }

  @override
  String get toolbarRotation => 'Text rotation';

  @override
  String get toolbarTextColor => 'Text color';

  @override
  String get toolbarUndo => 'Undo';

  @override
  String toolbarUndoLabel(String label) {
    return 'Undo $label';
  }

  @override
  String get toolbarVAlign => 'Vertical align';

  @override
  String get toolbarWrap => 'Text wrapping';

  @override
  String get toolbarZoom => 'Zoom';

  @override
  String get undoTyping => 'Typing';

  @override
  String get untitledSpreadsheet => 'Untitled spreadsheet';

  @override
  String get wrapClip => 'Clip';

  @override
  String get wrapOverflow => 'Overflow';

  @override
  String get wrapWrap => 'Wrap';

  @override
  String zoomPercent(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString%';
  }

  @override
  String get protectBlockedTitle => 'Protected cell or object';

  @override
  String get protectBlockedBody =>
      'You are trying to edit a protected cell or object. Please contact the spreadsheet owner to remove protection if you need to edit.';

  @override
  String get protectWarningTitle => 'Heads up!';

  @override
  String get protectWarningBody =>
      'Someone has protected part of this sheet to prevent accidental changes. Edit anyway?';

  @override
  String get protectWarningSnooze => 'Don\'t show this again for 5 minutes';

  @override
  String get protectPanelEmpty => 'No protected sheets or ranges';

  @override
  String get protectPanelEmptyHint =>
      'Protect a range or a whole sheet so that it isn\'t changed by accident.';

  @override
  String get protectAdd => 'Add a sheet or range';

  @override
  String get protectTabRange => 'Range';

  @override
  String get protectTabSheet => 'Sheet';

  @override
  String get protectDescription => 'Description';

  @override
  String get protectDescriptionPlaceholder => 'Enter a description';

  @override
  String get protectRange => 'Range';

  @override
  String get protectSheet => 'Sheet';

  @override
  String get protectExceptCells => 'Except certain cells';

  @override
  String get protectSetPermissions => 'Set permissions';

  @override
  String get protectOnlyYou => 'Only you';

  @override
  String get protectRestricted => 'Restricted';

  @override
  String protectEditorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count editors',
      one: '1 editor',
    );
    return '$_temp0';
  }

  @override
  String get protectWarningOnly => 'Warning only';

  @override
  String protectSheetName(String name) {
    return 'Sheet “$name”';
  }

  @override
  String protectExceptSummary(String ranges) {
    return 'except $ranges';
  }

  @override
  String get protectCantEdit => 'You can\'t edit this protection';

  @override
  String get protectAdvisory =>
      'Only the people you choose can edit protected ranges, also from other devices, scripts and agents. Warning-only ranges ask for a confirmation instead.';

  @override
  String get protectEdit => 'Edit protection';

  @override
  String get protectRemove => 'Remove protection';

  @override
  String get protectYouCanEdit => 'You can edit';

  @override
  String get protectPermissionsTitleRange => 'Range editing permissions';

  @override
  String get protectPermissionsTitleSheet => 'Sheet editing permissions';

  @override
  String get protectPermMode => 'When someone edits';

  @override
  String get protectPermWarning => 'Show a warning when editing this range';

  @override
  String get protectPermRestrict => 'Restrict who can edit this range';

  @override
  String get protectPermWho => 'Who can edit';

  @override
  String get protectPermOnlyYou => 'Only you';

  @override
  String get protectPermCustom => 'Custom (checked editors)';

  @override
  String protectPermCopy(String name) {
    return 'Copy permissions from “$name”';
  }

  @override
  String get protectPermAddEditors => 'Add editors';

  @override
  String get protectPermAddEditorsHint => 'Emails, separated by commas';

  @override
  String protectPermNoAccess(String names) {
    return '$names doesn\'t have edit access to the spreadsheet';
  }

  @override
  String get protectPermEditorsLoading => 'Loading editors…';

  @override
  String get protectEditorsOffline =>
      'You\'re offline: these are the editors known on this device.';

  @override
  String get protectInviteTitle => 'Share with new editors?';

  @override
  String protectInviteBody(String names) {
    return '$names can\'t edit the spreadsheet yet. Share it with them as editors so they can edit this range too?';
  }

  @override
  String get protectInviteShare => 'Share and add';

  @override
  String get protectInviteSkip => 'Don\'t share';

  @override
  String protectInvitePending(String names) {
    return '$names got an invitation. Add them here once they\'ve accepted it.';
  }

  @override
  String get protectSheetProtected => 'This sheet is protected';

  @override
  String get cmdProtectAdd => 'Protect range';

  @override
  String get cmdProtectUpdate => 'Edit protection';

  @override
  String get cmdProtectDelete => 'Remove protection';

  @override
  String get reasonCantManageProtection => 'You can\'t edit this protection';

  @override
  String get dvPanelEmpty => 'No data validation rules';

  @override
  String get dvPanelEmptyHint =>
      'Add a rule to control what can be entered in cells.';

  @override
  String get dvAddRule => 'Add rule';

  @override
  String get dvRemoveAllInSelection => 'Remove all in selection';

  @override
  String get dvApplyToRange => 'Apply to range';

  @override
  String get dvCriteria => 'Criteria';

  @override
  String get dvAdvanced => 'Advanced options';

  @override
  String get dvIfInvalid => 'If the data is invalid';

  @override
  String get dvShowWarning => 'Show a warning';

  @override
  String get dvRejectInput => 'Reject the input';

  @override
  String get dvShowHelpText => 'Show help text for a selected cell';

  @override
  String get dvHelpTextPlaceholder => 'Enter help text';

  @override
  String get dvDisplayStyle => 'Display style';

  @override
  String get dvStyleChip => 'Chip';

  @override
  String get dvStyleArrow => 'Arrow';

  @override
  String get dvStylePlain => 'Plain text';

  @override
  String get dvAllowMultiple => 'Allow multiple selections';

  @override
  String get dvRemoveRule => 'Remove rule';

  @override
  String get dvAddItem => 'Add another item';

  @override
  String dvItemPlaceholder(int n) {
    return 'Option $n';
  }

  @override
  String dvItemColor(String item) {
    return 'Color of “$item”';
  }

  @override
  String dvItemRemove(String item) {
    return 'Remove “$item”';
  }

  @override
  String get dvItemMoveUp => 'Move up';

  @override
  String get dvItemMoveDown => 'Move down';

  @override
  String get pivotUpdating => 'Updating…';

  @override
  String get cmdPivotGroupSelection => 'Create pivot group';

  @override
  String get pivotSelectLabels =>
      'Select row or column labels of one pivot table field';

  @override
  String get pivotGroupName => 'Group name';

  @override
  String get pivotGroupCreate => 'Create group';

  @override
  String get pivotGroupPrefix => 'Group';

  @override
  String get pivotGroupNameEmpty => 'Enter a name';

  @override
  String get pivotShowEmptyGroups => 'Show items with no data';

  @override
  String get pivotFilterByColor => 'Filter by color';

  @override
  String get pivotFillColor => 'Fill color';

  @override
  String get pivotTextColor => 'Text color';

  @override
  String get pivotNoColorFilter => 'Any';

  @override
  String get pivotFormulaValue => '=formula, e.g. =C2>100';

  @override
  String get smartChipSearch => 'Search people, or type…';

  @override
  String get smartChipPeople => 'People';

  @override
  String get smartChipDate => 'Date';

  @override
  String get smartChipDropdown => 'Dropdown';

  @override
  String smartChipAsText(String text) {
    return 'Insert “$text” as text';
  }

  @override
  String get smartChipOpenFile => 'Open';

  @override
  String get smartChipFiles => 'Files';

  @override
  String get smartChipFilesEmpty => 'No files found';

  @override
  String get cmdChipOpenFile => 'Open linked file';

  @override
  String get smartChipCopyEmail => 'Copy email';

  @override
  String get smartChipEmailCopied => 'Email copied';

  @override
  String get dvItemDragHint => 'Drag to reorder (Alt+↑/↓ in the field)';

  @override
  String get dvNoColor => 'No color';

  @override
  String get dvChipColors => 'Chip colors';

  @override
  String get dvUseCustomValues => 'Use custom cell values';

  @override
  String get dvChecked => 'Checked';

  @override
  String get dvUnchecked => 'Unchecked';

  @override
  String get dvValue => 'Value';

  @override
  String get dvValueMin => 'Minimum';

  @override
  String get dvValueMax => 'Maximum';

  @override
  String get dvValueFormula => 'Value or =formula';

  @override
  String get dvSourceRange => 'Range of items';

  @override
  String get dvShadowed =>
      'Another rule takes precedence over part of this range';

  @override
  String get dvErrorNoItems => 'Add at least one item';

  @override
  String get dvErrorValue => 'Enter a value';

  @override
  String get dvErrorNumber => 'Enter a number or a formula';

  @override
  String get dvErrorDate => 'Enter a date or a formula';

  @override
  String get dvErrorFormula => 'Enter a formula starting with =';

  @override
  String get dvErrorRange => 'Enter a valid range';

  @override
  String get dvCapped =>
      'Some rules were simplified to stay under 1,000 ranges';

  @override
  String get dvTooManyValues =>
      'Too many distinct values to convert to a dropdown';

  @override
  String dvRuleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules',
      one: '1 rule',
    );
    return '$_temp0';
  }

  @override
  String get dvCritDropdown => 'Dropdown';

  @override
  String get dvCritDropdownRange => 'Dropdown (from a range)';

  @override
  String get dvCritTextContains => 'Text contains';

  @override
  String get dvCritTextNotContains => 'Text does not contain';

  @override
  String get dvCritTextEq => 'Text is exactly';

  @override
  String get dvCritTextIsEmail => 'Text is valid email';

  @override
  String get dvCritTextIsUrl => 'Text is valid URL';

  @override
  String get dvCritDateIsValid => 'Is valid date';

  @override
  String get dvCritDateEq => 'Date is';

  @override
  String get dvCritDateBefore => 'Date is before';

  @override
  String get dvCritDateAfter => 'Date is after';

  @override
  String get dvCritDateOnOrBefore => 'Date is on or before';

  @override
  String get dvCritDateOnOrAfter => 'Date is on or after';

  @override
  String get dvCritDateBetween => 'Date is between';

  @override
  String get dvCritDateNotBetween => 'Date is not between';

  @override
  String get dvCritNumberGreater => 'Greater than';

  @override
  String get dvCritNumberGreaterEq => 'Greater than or equal to';

  @override
  String get dvCritNumberLess => 'Less than';

  @override
  String get dvCritNumberLessEq => 'Less than or equal to';

  @override
  String get dvCritNumberEq => 'Is equal to';

  @override
  String get dvCritNumberNotEq => 'Is not equal to';

  @override
  String get dvCritNumberBetween => 'Is between';

  @override
  String get dvCritNumberNotBetween => 'Is not between';

  @override
  String get dvCritCheckbox => 'Checkbox';

  @override
  String get dvCritCustomFormula => 'Custom formula is';

  @override
  String get dvDateToday => 'Today';

  @override
  String get dvDateTomorrow => 'Tomorrow';

  @override
  String get dvDateYesterday => 'Yesterday';

  @override
  String get dvDatePastWeek => 'In the past week';

  @override
  String get dvDatePastMonth => 'In the past month';

  @override
  String get dvDatePastYear => 'In the past year';

  @override
  String get dvDateExact => 'Exact date';

  @override
  String get dvInvalidTitle => 'Invalid entry';

  @override
  String dvInvalidBody(String cell) {
    return 'The data you entered in cell $cell violates the data validation rules set on this cell.';
  }

  @override
  String get dvInvalidTooltipTitle => 'Invalid';

  @override
  String get cmdDvSaveRule => 'Save data validation rule';

  @override
  String get cmdDvDeleteRule => 'Remove data validation rule';

  @override
  String get cmdDvClearRange => 'Remove data validation';

  @override
  String get contextEditDropdown => 'Edit dropdown';

  @override
  String get pickerSearch => 'Search';

  @override
  String get pickerNoMatches => 'No matching items';

  @override
  String get pickerNoItems => 'This dropdown has no items';

  @override
  String get pickerEdit => 'Edit dropdown';

  @override
  String get pickerClear => 'Clear';

  @override
  String pickerLabel(String cell) {
    return 'Dropdown of $cell';
  }

  @override
  String datePickerLabel(String cell) {
    return 'Date of $cell';
  }

  @override
  String get linkCardCopy => 'Copy link';

  @override
  String get linkCardEdit => 'Edit link';

  @override
  String get linkCardRemove => 'Remove link';

  @override
  String get linkCardInternal => 'Range in this spreadsheet';

  @override
  String get linkOpenExternalTitle => 'Open external link?';

  @override
  String get linkOpenExternalConfirm => 'Open';

  @override
  String get linkSearchPlaceholder =>
      'Paste a link, or search sheets and named ranges';

  @override
  String get linkSearchHeading => 'Sheets and named ranges';

  @override
  String get linkInternalHint => 'Links to a place in this spreadsheet';

  @override
  String get linkInvalid =>
      'Enter a link (https://…, an email address or #sheet=…&range=…)';

  @override
  String get cmdLinkCopy => 'Copy link';

  @override
  String get notePlaceholder => 'Add a note';

  @override
  String noteEditorLabel(String cell) {
    return 'Note of $cell';
  }

  @override
  String get noteEditorHint => 'Esc or click outside to save';

  @override
  String get errorTooltipTitle => 'Error';

  @override
  String get errorHintRef =>
      'A reference points to cells that don\'t exist (deleted rows, columns or sheets).';

  @override
  String get errorHintName =>
      'Check the spelling of function, sheet and named range names.';

  @override
  String get spillTooltipTitle => 'Array result';

  @override
  String get cellInfoNote => 'Note';

  @override
  String get cellInfoHelp => 'Help';

  @override
  String get ioReportCopied => 'Report copied';

  @override
  String get ioSeverityInfo => 'Info';

  @override
  String get ioSeverityWarning => 'Warning';

  @override
  String get ioSeverityError => 'Error';

  @override
  String get ioCopyReport => 'Copy report';

  @override
  String get ioClose => 'Close';

  @override
  String get ioReportSheets => 'Sheets';

  @override
  String ioReportSheetSize(int rows, int columns, int cells) {
    final intl.NumberFormat rowsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowsString = rowsNumberFormat.format(rows);
    final intl.NumberFormat columnsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String columnsString = columnsNumberFormat.format(columns);
    final intl.NumberFormat cellsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cellsString = cellsNumberFormat.format(cells);

    return '$rowsString × $columnsString · $cellsString cells';
  }

  @override
  String get ioReportNoWarnings => 'No warnings.';

  @override
  String get ioReportSeverity => 'Severity';

  @override
  String get ioReportWhere => 'Sheet / cell';

  @override
  String get ioReportMessage => 'Message';

  @override
  String get importDialogTitle => 'Import file';

  @override
  String get importDialogImport => 'Import data';

  @override
  String get importLocationCreateNew => 'Create new spreadsheet';

  @override
  String get importLocationInsertSheets => 'Insert new sheet(s)';

  @override
  String get importLocationReplaceSpreadsheet => 'Replace spreadsheet';

  @override
  String get importLocationReplaceSheet => 'Replace current sheet';

  @override
  String get importLocationAppend => 'Append to current sheet';

  @override
  String importLocationReplaceAtCell(String cell) {
    return 'Replace data at selected cell ($cell)';
  }

  @override
  String get importSeparatorAuto => 'Detect automatically';

  @override
  String importSeparatorAutoDetected(String separator) {
    return 'Detect automatically ($separator)';
  }

  @override
  String get importSeparatorCustom => 'Custom';

  @override
  String get importSeparatorTab => 'Tab';

  @override
  String get importSeparatorComma => 'Comma';

  @override
  String get importSeparatorSemicolon => 'Semicolon';

  @override
  String get importSeparatorPipe => 'Pipe';

  @override
  String importFileLabel(String name, String size) {
    return '$name ($size)';
  }

  @override
  String get importChangeFile => 'Change file';

  @override
  String get importDropHere => 'Drag a file here';

  @override
  String get importSupportedTypes => '.xlsx, .ods, .csv, .tsv or .txt';

  @override
  String get importBrowse => 'Browse';

  @override
  String get importUnsupportedType =>
      'This file type can\'t be imported. Choose an .xlsx, .ods, .csv, .tsv or .txt file.';

  @override
  String get importLegacyXls =>
      'Legacy .xls files can\'t be imported. Save the file as .xlsx and import it again.';

  @override
  String importEstimate(int cells) {
    final intl.NumberFormat cellsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cellsString = cellsNumberFormat.format(cells);

    return 'About $cellsString cells';
  }

  @override
  String get importLocation => 'Import location';

  @override
  String get importReplaceSpreadsheetWarning =>
      'All sheets of this spreadsheet will be deleted. Title, sharing and comments stay. You can undo this.';

  @override
  String get importLimitTitle => 'Too many cells';

  @override
  String importLimitBody(int cells, int limit) {
    final intl.NumberFormat cellsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cellsString = cellsNumberFormat.format(cells);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'This import would make the spreadsheet $cellsString cells; the limit is $limitString. Import fewer sheets or a smaller file.';
  }

  @override
  String get importLargeNote => 'Large import on this device may take a while.';

  @override
  String get importServerNote =>
      'This large file will be imported on the server.';

  @override
  String get importTabUpload => 'Upload';

  @override
  String get importTabRecent => 'Recent uploads';

  @override
  String get importTabRecentShort => 'Recent';

  @override
  String get importTabDrive => 'Drive';

  @override
  String get importRecentEmpty =>
      'Files you import on this device appear here.';

  @override
  String importRecentItem(String name, String size, String date) {
    return '$name · $size · $date';
  }

  @override
  String get importRecentGone =>
      'This file is no longer stored on this device.';

  @override
  String get importDriveHint =>
      'Import the sheets of another spreadsheet in your Drive.';

  @override
  String get importDriveOffline => 'Importing from Drive needs a connection.';

  @override
  String get importDrivePick => 'Choose a spreadsheet';

  @override
  String get importDrivePickTitle => 'Import from Drive';

  @override
  String get importPreview => 'Preview (first 20 rows)';

  @override
  String get importSeparator => 'Separator type';

  @override
  String get importEncoding => 'Encoding';

  @override
  String get importEncodingAuto => 'Detect automatically';

  @override
  String importEncodingAutoDetected(String encoding) {
    return 'Detect automatically ($encoding)';
  }

  @override
  String get importLocale => 'Locale for numbers & dates';

  @override
  String importLocaleSpreadsheet(String locale) {
    return 'Spreadsheet ($locale)';
  }

  @override
  String get importConvert => 'Convert text to numbers, dates, and formulas';

  @override
  String get importSheets => 'Sheets to import';

  @override
  String importSheetHidden(String name) {
    return '$name (hidden)';
  }

  @override
  String get importUnsupportedFormulas => 'Unsupported formulas';

  @override
  String get importUnsupportedValue => 'Keep last calculated value';

  @override
  String get importUnsupportedText => 'Keep formula as text';

  @override
  String importParseFailed(String error) {
    return 'The file could not be read: $error';
  }

  @override
  String get importPreviewEmpty => 'The file has no data.';

  @override
  String importProgressTitle(String name) {
    return 'Importing $name…';
  }

  @override
  String get importPhaseReading => 'Reading the file';

  @override
  String get importPhaseWriting => 'Writing cells';

  @override
  String get importPhaseUploading => 'Uploading';

  @override
  String get importPhaseQueued => 'Waiting for your other import to finish';

  @override
  String importPhaseWritingCells(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Writing cells ($doneString of $totalString)';
  }

  @override
  String get importPhaseFinalizing => 'Finishing up';

  @override
  String get cmdFileCancelImport => 'Cancel import';

  @override
  String get importCancel => 'Cancel';

  @override
  String importToastDone(String summary) {
    return '$summary';
  }

  @override
  String importSummary(int sheets, int cells) {
    final intl.NumberFormat cellsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cellsString = cellsNumberFormat.format(cells);

    String _temp0 = intl.Intl.pluralLogic(
      sheets,
      locale: localeName,
      other: '$sheets sheets',
      one: '1 sheet',
    );
    return 'Imported $_temp0, $cellsString cells';
  }

  @override
  String importSummaryWarnings(String summary, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
    );
    return '$summary — $_temp0';
  }

  @override
  String get importView => 'View';

  @override
  String get importOpen => 'Open';

  @override
  String importCreated(String name) {
    return 'Imported “$name”';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String get importRouteOffline =>
      'You\'re offline. Connect to the internet to open this file in Wonky Sheets.';

  @override
  String get importRouteNotAFile => 'This item isn\'t an uploaded file.';

  @override
  String importRouteUnsupported(String fileName) {
    return 'Wonky Sheets can\'t open “$fileName”.';
  }

  @override
  String importRouteUploading(String fileName) {
    return '“$fileName” is still uploading. Try again when the upload has finished.';
  }

  @override
  String get importRouteDownloadFailed =>
      'The file could not be loaded from Wonky Drive.';

  @override
  String get importSummaryTitle => 'Import summary';

  @override
  String get importNoReport => 'No import report yet.';

  @override
  String importUndoLabel(String name) {
    return 'Import $name';
  }

  @override
  String importManyFiles(int count) {
    return 'Imported $count spreadsheets';
  }

  @override
  String get cmdFileImportData => 'Import data into this spreadsheet';

  @override
  String get cmdFileShowImportReport => 'Show import summary';

  @override
  String get cmdFilterRemove => 'Remove filter';

  @override
  String get cmdFilterSetRange => 'Change filter range';

  @override
  String get cmdFilterOpenColumnMenu => 'Open filter menu';

  @override
  String get cmdFilterSetColumnCriteria => 'Filter column';

  @override
  String get cmdFilterClearColumn => 'Clear filter';

  @override
  String get cmdFilterClearAll => 'Clear all filters';

  @override
  String get cmdFilterSortColumn => 'Sort filtered column';

  @override
  String get filterByValueNoData =>
      'Select a cell inside a table of data first.';

  @override
  String get filterByValueHeader => 'Select a data cell below the header row.';

  @override
  String get cmdFilterSaveAsView => 'Save as filter view';

  @override
  String get filterViewNone => 'No filter view is open.';

  @override
  String get filterStickyRowBadge => 'Hidden by filter';

  @override
  String get filterViewDeletedToast => 'This filter view no longer exists';

  @override
  String get cmdFilterViewRename => 'Rename filter view';

  @override
  String get cmdFilterViewSetRange => 'Update filter view range';

  @override
  String get cmdFilterViewDuplicate => 'Duplicate filter view';

  @override
  String filterViewCopyOf(String name) {
    return 'Copy of $name';
  }

  @override
  String get cmdFilterViewSave => 'Save view';

  @override
  String get cmdFilterViewDelete => 'Delete filter view';

  @override
  String get cmdFilterViewCopyLink => 'Copy link to filter view';

  @override
  String get cmdFilterViewOpenPanel => 'Manage filter views';

  @override
  String cmdGroupColumnsSpan(String span) {
    return 'Group columns $span';
  }

  @override
  String cmdGroupRowsSpan(String span) {
    return 'Group rows $span';
  }

  @override
  String cmdUngroupColumnsSpan(String span) {
    return 'Ungroup columns $span';
  }

  @override
  String cmdUngroupRowsSpan(String span) {
    return 'Ungroup rows $span';
  }

  @override
  String get cmdGroupToggle => 'Expand or collapse group';

  @override
  String get cmdGroupCollapseToLevel => 'Show group level';

  @override
  String get cmdGroupRemoveAll => 'Remove all groups';

  @override
  String get menuExpandAllRowGroups => 'Expand all row groups';

  @override
  String get menuCollapseAllRowGroups => 'Collapse all row groups';

  @override
  String get menuExpandAllColumnGroups => 'Expand all column groups';

  @override
  String get menuCollapseAllColumnGroups => 'Collapse all column groups';

  @override
  String sortColumnLabel(String col) {
    return 'Column $col';
  }

  @override
  String sortDialogTitle(String range) {
    return 'Sort range from $range';
  }

  @override
  String get sortDialogHasHeader => 'Data has header row';

  @override
  String get sortDialogSortBy => 'Sort by';

  @override
  String get sortDialogThenBy => 'then by';

  @override
  String get sortDialogOrder => 'Order';

  @override
  String get sortDialogAddColumn => 'Add another sort column';

  @override
  String get sortDialogRemoveColumn => 'Remove sort column';

  @override
  String get sortDialogSort => 'Sort';

  @override
  String get sortNeedsRows => 'Select at least two rows of data to sort.';

  @override
  String get cmdFindClose => 'Close find';

  @override
  String get cmdFindNext => 'Find next';

  @override
  String get cmdFindPrevious => 'Find previous';

  @override
  String get cmdFindReplace => 'Replace';

  @override
  String get cmdFindReplaceAll => 'Replace all';

  @override
  String get findNoMatches => 'No matches';

  @override
  String get dedupeTitle => 'Remove duplicates';

  @override
  String dedupeRange(String range) {
    return 'Range $range';
  }

  @override
  String get dedupeSelectAll => 'Select all';

  @override
  String get dedupeColumns => 'Columns to analyze';

  @override
  String get dedupeRemove => 'Remove duplicates';

  @override
  String get dedupeNoData => 'Select a range of data first.';

  @override
  String get splitSingleColumn =>
      'Please select a single column of data to split.';

  @override
  String get splitReplaceTitle => 'Do you want to replace existing data?';

  @override
  String get splitReplaceBody =>
      'The cells to the right of the column contain data that will be replaced.';

  @override
  String get splitReplace => 'Replace';

  @override
  String get splitNoSeparator => 'Couldn\'t detect a separator';

  @override
  String get cmdColumnStatsSelectColumn => 'Show column stats for column';

  @override
  String get cmdNamedRangesAdd => 'Add named range';

  @override
  String get cmdNamedRangesUpdate => 'Edit named range';

  @override
  String get cmdNamedRangesDelete => 'Remove named range';

  @override
  String get cmdNamedRangesGoTo => 'Go to named range';

  @override
  String get cmdNamedFunctionsCreate => 'Add named function';

  @override
  String get cmdNamedFunctionsUpdate => 'Edit named function';

  @override
  String get cmdNamedFunctionsDelete => 'Remove named function';

  @override
  String get namedFunctionNeedsDefinition => 'Enter a formula definition.';

  @override
  String get exportPhaseImages => 'Fetching images';

  @override
  String get exportPhasePreparing => 'Reading the spreadsheet';

  @override
  String get exportPhaseWriting => 'Writing the file';

  @override
  String exportProgressTitle(String format) {
    return 'Downloading $format…';
  }

  @override
  String get exportFailed => 'Download failed';

  @override
  String exportSaveDialogTitle(String fileName) {
    return 'Save $fileName';
  }

  @override
  String exportDoneWithNotes(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count features',
      one: '1 feature',
    );
    return '$fileName — $_temp0 not exported exactly';
  }

  @override
  String get exportReportTitle => 'Export report';

  @override
  String exportReportSummary(String fileName) {
    return 'Features of this spreadsheet that $fileName can\'t hold exactly.';
  }

  @override
  String importWarningsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
    );
    return '$_temp0';
  }

  @override
  String printPhaseRendering(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'Rendering $_temp0';
  }

  @override
  String get printBack => 'Back';

  @override
  String printTitle(String name) {
    return 'Print settings · $name';
  }

  @override
  String get printExportPdf => 'Export PDF';

  @override
  String get printPrint => 'Print';

  @override
  String get printScope => 'Print';

  @override
  String get printScopeSheet => 'Current sheet';

  @override
  String get printScopeWorkbook => 'Workbook';

  @override
  String printScopeSelection(String range) {
    return 'Selected cells ($range)';
  }

  @override
  String get printApplyToAll => 'Apply to all sheets';

  @override
  String get printPaperSize => 'Paper size';

  @override
  String get printPaperCustom => 'Custom';

  @override
  String get printWidth => 'Width';

  @override
  String get printHeight => 'Height';

  @override
  String get printUnitIn => 'in';

  @override
  String get printUnitCm => 'cm';

  @override
  String get printOrientation => 'Page orientation';

  @override
  String get printPortrait => 'Portrait';

  @override
  String get printLandscape => 'Landscape';

  @override
  String get printScale => 'Scale';

  @override
  String get printScaleNormal => 'Normal (100%)';

  @override
  String get printScaleFitWidth => 'Fit to width';

  @override
  String get printScaleFitHeight => 'Fit to height';

  @override
  String get printScaleFitPage => 'Fit to page';

  @override
  String get printScaleCustom => 'Custom number';

  @override
  String get printScalePercent => 'Percent (10–400)';

  @override
  String get printMargins => 'Margins';

  @override
  String get printMarginsNormal => 'Normal';

  @override
  String get printMarginsNarrow => 'Narrow';

  @override
  String get printMarginsWide => 'Wide';

  @override
  String get printMarginsCustom => 'Custom';

  @override
  String get printMarginTop => 'Top';

  @override
  String get printMarginBottom => 'Bottom';

  @override
  String get printMarginLeft => 'Left';

  @override
  String get printMarginRight => 'Right';

  @override
  String get printFormatting => 'Formatting';

  @override
  String get printGridlines => 'Show gridlines';

  @override
  String get printNotes => 'Show notes';

  @override
  String get printHeadings => 'Show row & column headers';

  @override
  String get printRepeatFrozen => 'Repeat frozen rows and columns';

  @override
  String get printPageOrder => 'Page order';

  @override
  String get printDownThenOver => 'Down, then over';

  @override
  String get printOverThenDown => 'Over, then down';

  @override
  String get printAlignment => 'Alignment';

  @override
  String get printAlignHorizontal => 'Horizontal';

  @override
  String get printAlignVertical => 'Vertical';

  @override
  String get printAlignLeft => 'Left';

  @override
  String get printAlignCenter => 'Center';

  @override
  String get printAlignRight => 'Right';

  @override
  String get printAlignTop => 'Top';

  @override
  String get printAlignMiddle => 'Middle';

  @override
  String get printAlignBottom => 'Bottom';

  @override
  String get printHeadersFooters => 'Headers & footers';

  @override
  String get printPageNumbers => 'Page numbers';

  @override
  String get printWorkbookTitle => 'Workbook title';

  @override
  String get printSheetName => 'Sheet name';

  @override
  String get printCurrentDate => 'Current date';

  @override
  String get printCurrentTime => 'Current time';

  @override
  String get printCustomFields => 'Custom fields';

  @override
  String get printHeader => 'Header';

  @override
  String get printFooter => 'Footer';

  @override
  String get printFieldLeft => 'Left';

  @override
  String get printFieldCenter => 'Center';

  @override
  String get printFieldRight => 'Right';

  @override
  String get printFieldsHint => 'Tokens you can use:';

  @override
  String get printSetBreaks => 'Set custom page breaks';

  @override
  String get printBreaksTitle => 'Custom page breaks';

  @override
  String get printBreaksHint =>
      'Pages break before these rows and columns. Drag the lines on the grid to move them, drag one off the grid to remove it, or click a row number or column letter to add one.';

  @override
  String get printBreakCanvasLabel =>
      'Page breaks of the current sheet. Dashed lines are automatic breaks, solid lines are custom breaks.';

  @override
  String get printDarkTheme => 'Use dark theme for Export PDF';

  @override
  String get printBreakRows => 'Breaks before rows';

  @override
  String get printBreakCols => 'Breaks before columns';

  @override
  String get printAddBreak => 'Add';

  @override
  String get printBreakRowPlaceholder => 'Row, e.g. 21';

  @override
  String get printBreakColPlaceholder => 'Column, e.g. F';

  @override
  String get printConfirmBreaks => 'Confirm breaks';

  @override
  String get printResetBreaks => 'Reset breaks';

  @override
  String get printCancelBreaks => 'Cancel';

  @override
  String get printNoBreaks => 'None';

  @override
  String get printRemoveBreak => 'Remove break';

  @override
  String get printResetSettings => 'Reset to defaults';

  @override
  String printPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String printPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
      zero: 'No pages',
    );
    return '$_temp0';
  }

  @override
  String get printZoomFit => 'Fit width';

  @override
  String get printZoomIn => 'Zoom in';

  @override
  String get printZoomOut => 'Zoom out';

  @override
  String get printPrevPage => 'Previous page';

  @override
  String get printNextPage => 'Next page';

  @override
  String get printNothing => 'Nothing to print';

  @override
  String get printNothingBody =>
      'The sheet is empty or the selection has no visible cells.';

  @override
  String get printUnavailableTitle => 'Printing isn\'t available here';

  @override
  String get printUnavailableBody =>
      'Export the PDF and print it from your PDF viewer.';

  @override
  String get printViewerLocal =>
      'You have view access: these settings apply to this print only.';

  @override
  String get printDownloadsDisabledTitle => 'Printing is turned off';

  @override
  String get printDownloadsDisabledBody =>
      'The owner doesn\'t allow viewers to print or download this spreadsheet.';

  @override
  String get printLoading => 'Opening the spreadsheet…';

  @override
  String get printFailed => 'The PDF could not be created';

  @override
  String printPageLabel(int page) {
    return 'Page $page';
  }

  @override
  String printInvalidRow(int max) {
    return 'Enter a row number between 2 and $max.';
  }

  @override
  String get printInvalidColumn => 'Enter a column letter after A.';

  @override
  String get cmdPrintUpdateSettings => 'Change print settings';

  @override
  String get cmdPrintResetSettings => 'Reset print settings';

  @override
  String get cmdPrintEnterBreakMode => 'Set custom page breaks';

  @override
  String get cmdPrintExitBreakMode => 'Exit page break mode';

  @override
  String get cmdPrintSetPageBreaks => 'Set page breaks';

  @override
  String get cmdPrintPrint => 'Print PDF';

  @override
  String get cmdPrintExportPdf => 'Export PDF';

  @override
  String get categoryAi => 'AI';

  @override
  String get aiPanelTitle => 'Assistant';

  @override
  String get aiTurnedOff => 'AI is turned off';

  @override
  String get aiTurnOnHint => 'Turn it on in Settings › AI.';

  @override
  String get aiUnavailable => 'AI isn\'t available right now.';

  @override
  String get aiAgentLabel => 'AI';

  @override
  String get aiUndoDefault => 'AI edit';

  @override
  String aiUndoLabel(String summary) {
    return 'AI: $summary';
  }

  @override
  String aiChipSheet(String name) {
    return 'Sheet: $name';
  }

  @override
  String aiChipRanges(String first, int more) {
    return '$first (+$more)';
  }

  @override
  String get aiQuickAnalyze => 'Analyze';

  @override
  String get aiQuickChart => 'Build a chart';

  @override
  String get aiQuickClean => 'Clean data';

  @override
  String get aiQuickFormula => 'Write a formula';

  @override
  String get aiSuggestTitle => 'Suggest a formula';

  @override
  String get aiSuggestPlaceholder => 'Describe the formula you need';

  @override
  String get aiSuggestAsk => 'Suggest';

  @override
  String get aiSuggestInsert => 'Insert';

  @override
  String get aiSuggestTryAgain => 'Try again';

  @override
  String aiSuggestResult(String value) {
    return 'Result: $value';
  }

  @override
  String get aiSuggestExternal =>
      'This formula fetches data from the internet.';

  @override
  String get aiWorking => 'Thinking…';

  @override
  String get aiExplainTitle => 'Explain formula';

  @override
  String get aiExplainToPanel => 'Open in Assistant';

  @override
  String aiExplainResultTitle(String cell) {
    return 'Explanation of $cell';
  }

  @override
  String get aiNoFormula => 'The cell has no formula.';

  @override
  String get aiFillTitle => 'Fill with AI';

  @override
  String aiFillDescription(String range) {
    return 'Proposals for the empty cells of $range, learned from the filled ones. Nothing is written until you apply.';
  }

  @override
  String get aiFillInstructionsPlaceholder =>
      'Instructions (optional), e.g. \"Use the ISO country code\"';

  @override
  String get aiFillRegenerate => 'Regenerate';

  @override
  String get aiFillGenerating => 'Generating proposals…';

  @override
  String aiFillApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Apply $count values',
      one: 'Apply 1 value',
      zero: 'Apply',
    );
    return '$_temp0';
  }

  @override
  String aiFillSummary(int count, int examples) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proposals',
      one: '1 proposal',
    );
    String _temp1 = intl.Intl.pluralLogic(
      examples,
      locale: localeName,
      other: '$examples examples',
      one: '1 example',
    );
    return '$_temp0 from $_temp1. Low-confidence values are unchecked.';
  }

  @override
  String get aiFillTruncated =>
      'Only the first 2,000 empty cells were filled. Run Fill with AI again for the rest.';

  @override
  String get aiFillNothing =>
      'Nothing to fill: there are no empty cells next to data in this column.';

  @override
  String get aiFillColumnCell => 'Cell';

  @override
  String get aiFillColumnInputs => 'Inputs';

  @override
  String get aiFillColumnValue => 'Proposed value';

  @override
  String get aiFillColumnConfidence => 'Confidence';

  @override
  String get aiConfidenceHigh => 'High';

  @override
  String get aiConfidenceMedium => 'Medium';

  @override
  String get aiConfidenceLow => 'Low';

  @override
  String get aiPreviewTitle => 'AI changes preview';

  @override
  String get aiPreviewDescription =>
      'The assistant suggested these changes. Check the ones to apply; they are applied as one undo step.';

  @override
  String get aiPreviewApply => 'Apply selected';

  @override
  String get aiPreviewDiscard => 'Discard';

  @override
  String get aiPreviewEmpty => 'The assistant suggested no changes.';

  @override
  String aiPreviewCells(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cells',
      one: '1 cell',
    );
    return '$_temp0';
  }

  @override
  String aiPreviewMoreCells(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more cells',
      one: 'and 1 more cell',
    );
    return '$_temp0';
  }

  @override
  String get aiPreviewNoCells => 'No cell values change.';

  @override
  String get aiPreviewCell => 'Cell';

  @override
  String get aiPreviewBefore => 'Before';

  @override
  String get aiPreviewAfter => 'After';

  @override
  String get aiPreviewReview => 'Review suggested changes';

  @override
  String get aiPreviewAppliedNote => 'Suggested changes applied.';

  @override
  String get aiPreviewDiscardedNote => 'Suggested changes discarded.';

  @override
  String aiPreviewSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cells were changed by someone else and kept.',
      one: '1 cell was changed by someone else and kept.',
    );
    return '$_temp0';
  }

  @override
  String get aiDescribeChartResult => 'Alt text proposal';

  @override
  String get aiInsertUndo => 'Insert AI result';

  @override
  String get cmdAiCleanupSuggestions => 'Clean up data with AI';

  @override
  String get cmdAiRefreshAiCells => 'Refresh AI cells';

  @override
  String aiCleanupPrompt(String scope, String findings) {
    return 'Clean up the data $scope. The automatic checks found:\n$findings\nGroup the problems, explain them briefly and propose fixes as suggested changes I can review.';
  }

  @override
  String aiCleanupScopeRange(String range) {
    return 'in $range';
  }

  @override
  String aiCleanupScopeSheet(String name) {
    return 'on the sheet \"$name\"';
  }

  @override
  String get aiCleanupNothing => '- nothing obvious (check the data anyway)';

  @override
  String get aiAgentMcp => 'MCP agent';

  @override
  String aiAgentOf(String name) {
    return '$name\'s agent';
  }

  @override
  String aiAgentAiOf(String name) {
    return 'AI · $name';
  }

  @override
  String get aiAssistantEmptyTitle =>
      'Ask about this spreadsheet or tell the assistant what to change.';

  @override
  String get aiAssistantPrivacyNotice =>
      'The assistant sends this spreadsheet and your messages to the AI provider to generate answers.';

  @override
  String aiAssistantPrivacyNoticeProvider(String provider) {
    return 'The assistant sends this spreadsheet and your messages to $provider to generate answers.';
  }

  @override
  String get aiAssistantModeEditHint =>
      'Edit directly: changes go straight into the spreadsheet';

  @override
  String get aiAssistantModeEditUnavailable =>
      'You can only suggest changes in this spreadsheet';

  @override
  String get aiAssistantModeSuggestHint =>
      'Suggest: changes arrive as a preview to apply or discard';

  @override
  String get cmdAiSuggestFormulaDescription =>
      'Describe a formula in words and get it written for the active cell';

  @override
  String get cmdAiFillRangeDescription =>
      'Fill the empty cells of a column from the examples in it';

  @override
  String get cmdAiDescribeChart => 'Describe chart with AI';

  @override
  String get cmdAiApplyPreview => 'Apply AI changes';

  @override
  String get cmdAiDiscardPreview => 'Discard AI changes';

  @override
  String get cmdAiInsertResult => 'Insert AI result';

  @override
  String get explorePanelTitle => 'Explore';

  @override
  String get exploreEmptyTitle => 'Nothing to explore yet';

  @override
  String get exploreEmptyBody =>
      'Select cells with data, or click into a table.';

  @override
  String get exploreSelectionStats => 'Selection';

  @override
  String get exploreSuggestedCharts => 'Suggested charts';

  @override
  String get exploreNoCharts => 'No chart fits this data.';

  @override
  String get exploreCreatePivot => 'Create a pivot table';

  @override
  String get exploreInsights => 'Insights';

  @override
  String get exploreAskTitle => 'Ask about this data';

  @override
  String get exploreAskPlaceholder => 'Ask a question about this data';

  @override
  String get exploreAsk => 'Ask';

  @override
  String get condNone => 'None';

  @override
  String get condBlank => 'Is empty';

  @override
  String get condNotBlank => 'Is not empty';

  @override
  String get condTextContains => 'Text contains';

  @override
  String get condTextNotContains => 'Text does not contain';

  @override
  String get condTextStartsWith => 'Text starts with';

  @override
  String get condTextEndsWith => 'Text ends with';

  @override
  String get condTextEq => 'Text is exactly';

  @override
  String get condDateEq => 'Date is';

  @override
  String get condDateBefore => 'Date is before';

  @override
  String get condDateAfter => 'Date is after';

  @override
  String get condNumberGreater => 'Greater than';

  @override
  String get condNumberGreaterEq => 'Greater than or equal to';

  @override
  String get condNumberLess => 'Less than';

  @override
  String get condNumberLessEq => 'Less than or equal to';

  @override
  String get condNumberEq => 'Is equal to';

  @override
  String get condNumberNotEq => 'Is not equal to';

  @override
  String get condNumberBetween => 'Is between';

  @override
  String get condNumberNotBetween => 'Is not between';

  @override
  String get condCustomFormula => 'Custom formula is';

  @override
  String get condExactDate => 'Exact date';

  @override
  String get condToday => 'Today';

  @override
  String get condTomorrow => 'Tomorrow';

  @override
  String get condYesterday => 'Yesterday';

  @override
  String get condPastWeek => 'In the past week';

  @override
  String get condPastMonth => 'In the past month';

  @override
  String get condPastYear => 'In the past year';

  @override
  String get condValuePlaceholder => 'Value or formula';

  @override
  String get condFormulaPlaceholder => '=B2>100';

  @override
  String get filterByColor => 'Filter by color';

  @override
  String get filterSortByColor => 'Sort by color';

  @override
  String get sortHeaderToastTitle => 'Sorted including row 1';

  @override
  String get sortHeaderToastBody => 'Row 1 looks like a header row.';

  @override
  String get sortHeaderToastAction => 'Freeze row 1 and re-sort';

  @override
  String get dataJobWaiting => 'Waiting for the current operation to finish…';

  @override
  String get dataJobCancel => 'Cancel';

  @override
  String get dataJobCancelled => 'Cancelled. Nothing was changed.';

  @override
  String dataJobSorting(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Sorting $countString rows…';
  }

  @override
  String dataJobDeduping(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Removing duplicates in $countString rows…';
  }

  @override
  String dataJobSplitting(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Splitting $countString rows…';
  }

  @override
  String dataJobTrimming(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Trimming whitespace in $countString rows…';
  }

  @override
  String dataJobRandomizing(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Randomizing $countString rows…';
  }

  @override
  String dataJobCleaning(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Cleaning up $countString rows…';
  }

  @override
  String get filterByCondition => 'Filter by condition';

  @override
  String get filterByValues => 'Filter by values';

  @override
  String get filterFillColor => 'Fill color';

  @override
  String get filterTextColor => 'Text color';

  @override
  String get filterNoColors => 'No colors in this column';

  @override
  String get filterHiddenByOthers => 'Hidden by other filters';

  @override
  String filterSelectAll(int count) {
    return 'Select all $count';
  }

  @override
  String get filterClear => 'Clear';

  @override
  String get filterSearch => 'Search';

  @override
  String get filterNoValues => 'No matching values';

  @override
  String filterShowingOf(int count, int total) {
    return 'Showing $count of $total values — refine your search';
  }

  @override
  String get filterBlanks => '(Blanks)';

  @override
  String get filterViewerHint =>
      'You have view access — use a temporary filter view';

  @override
  String get filterViewSortUnavailable =>
      'Sort by color isn\'t available in filter views';

  @override
  String get cmdFilterViewSortColumn => 'Sort filter view';

  @override
  String get viewSortCutUnavailable =>
      'Rows in a sorted filter view can\'t be cut together. Copy them instead.';

  @override
  String get viewSortCutPasteUnavailable =>
      'A cut can\'t be pasted into the rows of a sorted filter view. Copy it instead.';

  @override
  String get filterViewClearSort => 'Clear view sort';

  @override
  String filterViewSortedBy(String column) {
    return 'Sorted by $column';
  }

  @override
  String get findNoResults => 'No results';

  @override
  String findMatchesCount(String matches) {
    return '$matches matches';
  }

  @override
  String findOfCount(int current, String matches) {
    return '$current of $matches';
  }

  @override
  String get findPlaceholder => 'Find in sheet';

  @override
  String get findClose => 'Close';

  @override
  String get findReplaceTitle => 'Find and replace';

  @override
  String get findLabel => 'Find';

  @override
  String get replaceLabel => 'Replace with';

  @override
  String get findSearchIn => 'Search';

  @override
  String get findRange => 'Range';

  @override
  String get findButton => 'Find';

  @override
  String get findMatchCase => 'Match case';

  @override
  String get findMatchEntireCell => 'Match entire cell contents';

  @override
  String get findUseRegex => 'Search using regular expressions';

  @override
  String get findSearchFormulas => 'Also search within formulas';

  @override
  String get findSearchLinks => 'Also search within links';

  @override
  String get findAllSheets => 'All sheets';

  @override
  String get findThisSheet => 'This sheet';

  @override
  String get findSpecificRange => 'Specific range';

  @override
  String get splitSeparator => 'Separator:';

  @override
  String get splitDetect => 'Detect automatically';

  @override
  String get splitComma => 'Comma';

  @override
  String get splitSemicolon => 'Semicolon';

  @override
  String get splitPeriod => 'Period';

  @override
  String get splitSpace => 'Space';

  @override
  String get splitCustom => 'Custom';

  @override
  String get filterViewName => 'Name:';

  @override
  String get filterViewRange => 'Range:';

  @override
  String get filterViewTemporary => 'Temporary filter view — only you see it';

  @override
  String get filterViewClose => 'Close';

  @override
  String get filterViewOpen => 'Open';

  @override
  String get filterViewsTitle => 'Filter views';

  @override
  String get filterViewsEmpty => 'No filter views on this sheet yet.';

  @override
  String get filterViewTemporaryShort => 'Temporary — only you see it';

  @override
  String get namedRangesEmpty =>
      'No named ranges yet. Name a range to use it in formulas, e.g. =SUM(Sales).';

  @override
  String get namedRangesAdd => 'Add a range';

  @override
  String get namedRangesRefError => '#REF!';

  @override
  String get namedRangesName => 'Name';

  @override
  String get namedRangesRange => 'Range';

  @override
  String get namedRangesUseSelection => 'Use the current selection';

  @override
  String get namedRangesRemove => 'Remove';

  @override
  String get namedRangesManage => 'Manage named ranges';

  @override
  String get namedRangesNone => 'No named ranges';

  @override
  String get namedFunctionsEmpty =>
      'Create custom functions from formulas and use them like built-in functions, for example:';

  @override
  String get namedFunctionsAdd => 'Add new function';

  @override
  String get namedFunctionsImport => 'Import function';

  @override
  String get cmdNamedFunctionsImport => 'Import named functions';

  @override
  String get importFunctionsTitle => 'Import named functions';

  @override
  String get importFunctionsPickSpreadsheet =>
      'Choose the spreadsheet to import from.';

  @override
  String importFunctionsPickFunctions(String name) {
    return 'Functions in $name';
  }

  @override
  String get importFunctionsBack => 'Back';

  @override
  String get importFunctionsImport => 'Import';

  @override
  String get importFunctionsSearch => 'Search spreadsheets';

  @override
  String get importFunctionsNoSpreadsheets => 'No spreadsheets found';

  @override
  String get importFunctionsNone => 'This spreadsheet has no named functions.';

  @override
  String get importFunctionsDependency =>
      'Imported because a selected function uses it';

  @override
  String get importFunctionsReplace => 'Replace functions with the same name';

  @override
  String get importFunctionsOffline =>
      'Importing functions needs a connection.';

  @override
  String importFunctionsDone(int imported, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      imported,
      locale: localeName,
      other: '$imported functions imported',
      one: '1 function imported',
      zero: 'No functions imported',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ' · $skipped skipped (names exist)',
      one: ' · 1 skipped (name exists)',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get cmdCleanupApplySuggestion => 'Apply cleanup suggestion';

  @override
  String cleanupNumbersAsText(int count, String column) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Convert $count cells in column $column to numbers',
      one: 'Convert 1 cell in column $column to a number',
    );
    return '$_temp0';
  }

  @override
  String cleanupWhitespace(int count, String column) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trim extra spaces in $count cells of column $column',
      one: 'Trim extra spaces in 1 cell of column $column',
    );
    return '$_temp0';
  }

  @override
  String cleanupDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count duplicate rows',
      one: 'Remove 1 duplicate row',
    );
    return '$_temp0';
  }

  @override
  String cleanupCapitalization(int count, String column) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Make the capitalization of $count values in column $column consistent',
      one: 'Make the capitalization of 1 value in column $column consistent',
    );
    return '$_temp0';
  }

  @override
  String cleanupEmptyRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count empty rows inside the data',
      one: 'Delete 1 empty row inside the data',
    );
    return '$_temp0';
  }

  @override
  String cleanupMixedTypes(String column, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Column $column has numbers and $count text values',
      one: 'Column $column has numbers and 1 text value',
    );
    return '$_temp0';
  }

  @override
  String cleanupRow(String row) {
    return 'Row $row';
  }

  @override
  String get cleanupApply => 'Apply';

  @override
  String get cleanupDismiss => 'Dismiss';

  @override
  String get cleanupColumnStats => 'Column stats';

  @override
  String get cleanupNoneTitle => 'Looks clean';

  @override
  String get cleanupNoneBody => 'No cleanup suggestions for this sheet.';

  @override
  String get cleanupGone => 'This suggestion no longer applies.';

  @override
  String get namedFunctionsEdit => 'Edit';

  @override
  String namedFunctionsArgDescription(String param) {
    return 'Description of $param';
  }

  @override
  String namedFunctionsArgExample(String param) {
    return 'Example value for $param';
  }

  @override
  String get namedFunctionsPreview => 'Function preview';

  @override
  String get namedFunctionsUpdate => 'Update';

  @override
  String get namedFunctionsName => 'Function name';

  @override
  String get namedFunctionsDescription => 'Function description';

  @override
  String get namedFunctionsParams => 'Argument placeholders';

  @override
  String get namedFunctionsParamHint => 'Type an argument name and press Enter';

  @override
  String get namedFunctionsDefinition => 'Formula definition';

  @override
  String get namedFunctionsNext => 'Next';

  @override
  String get columnStatsIgnoreHeader => 'Ignore header row';

  @override
  String get columnStatsEmpty => 'This column has no data.';

  @override
  String get columnStatsCount => 'Count';

  @override
  String columnStatsValues(int count) {
    return 'Values $count';
  }

  @override
  String columnStatsEmptyCount(int count) {
    return 'Empty $count';
  }

  @override
  String columnStatsUnique(int count) {
    return 'Unique $count';
  }

  @override
  String get columnStatsDistribution => 'Distribution';

  @override
  String get columnStatsTable => 'Table';

  @override
  String get columnStatsFrequency => 'Frequency';

  @override
  String get columnStatsShowMore => 'Show more';

  @override
  String get columnStatsSummary => 'Summary';

  @override
  String get columnStatsSum => 'Sum';

  @override
  String get columnStatsAverage => 'Average';

  @override
  String get columnStatsMedian => 'Median';

  @override
  String get columnStatsMin => 'Min';

  @override
  String get columnStatsMax => 'Max';

  @override
  String get columnStatsShortest => 'Shortest text length';

  @override
  String get columnStatsLongest => 'Longest text length';

  @override
  String get goToTitle => 'Go to range';

  @override
  String get goToLabel => 'Cell, range or named range';

  @override
  String get goToInvalid => 'Enter a valid cell, range or named range';

  @override
  String get goToButton => 'Go';

  @override
  String get panelChartEditor => 'Chart editor';

  @override
  String get categoryCharts => 'Charts';

  @override
  String get categoryImages => 'Images';

  @override
  String get categoryObjects => 'Objects';

  @override
  String get chartAggregateAverage => 'Average';

  @override
  String get chartAggregateCount => 'Count';

  @override
  String get chartAggregateMax => 'Max';

  @override
  String get chartAggregateMedian => 'Median';

  @override
  String get chartAggregateMin => 'Min';

  @override
  String get chartAggregateSum => 'Sum';

  @override
  String get chartAlignAuto => 'Auto';

  @override
  String get chartAlignCenter => 'Center';

  @override
  String get chartAlignLeft => 'Left';

  @override
  String get chartAlignRight => 'Right';

  @override
  String get chartAxisLeft => 'Left axis';

  @override
  String get chartAxisRight => 'Right axis';

  @override
  String get chartCompareCategory => 'Category';

  @override
  String get chartCompareDatum => 'Datum';

  @override
  String get chartCompareOff => 'Off';

  @override
  String get chartDashDash => 'Dashed';

  @override
  String get chartDashDashDot => 'Dash-dot';

  @override
  String get chartDashDot => 'Dotted';

  @override
  String get chartDashLong => 'Long dash';

  @override
  String get chartDashSolid => 'Solid';

  @override
  String get chartDownloadPdf => 'PDF document (.pdf)';

  @override
  String get chartDownloadPng => 'PNG image (.png)';

  @override
  String get chartDownloadSvg => 'Scalable vector graphics (.svg)';

  @override
  String get chartEditorAddSeries => 'Add series';

  @override
  String get chartEditorAddXAxis => 'Add X-axis';

  @override
  String get chartEditorAggregate => 'Aggregate';

  @override
  String get chartEditorAlign => 'Alignment';

  @override
  String get chartEditorAllSeries => 'Apply to all series';

  @override
  String get chartEditorAlternatingColors => 'Alternating row colors';

  @override
  String get chartEditorAxis => 'Axis';

  @override
  String get chartEditorBackground => 'Background color';

  @override
  String get chartEditorBold => 'Bold';

  @override
  String get chartEditorBorderColor => 'Border color';

  @override
  String get chartEditorBucketSize => 'Bucket size';

  @override
  String get chartEditorChartType => 'Chart type';

  @override
  String get chartEditorCompareMode => 'Compare mode';

  @override
  String get chartEditorConnectorLines => 'Connector lines';

  @override
  String get chartEditorCustomize => 'Customize';

  @override
  String get chartEditorCustomizeSeries => 'Format series';

  @override
  String get chartEditorDataLabels => 'Data labels';

  @override
  String get chartEditorDataRange => 'Data range';

  @override
  String get chartEditorDomainUnnamed => '(Unnamed)';

  @override
  String get chartEditorDoughnutHole => 'Doughnut hole';

  @override
  String get chartEditorEmpty => 'Select a chart to edit it';

  @override
  String get chartEditorEmptyCells => 'Empty cells';

  @override
  String get chartEditorFallingColor => 'Falling color';

  @override
  String get chartEditorFallingFilled => 'Fill falling candles';

  @override
  String get chartEditorFillColor => 'Fill color';

  @override
  String get chartEditorFillOpacity => 'Fill opacity';

  @override
  String get chartEditorFirstValueSubtotal => 'Use first value as subtotal';

  @override
  String get chartEditorFont => 'Font';

  @override
  String get chartEditorFontSize => 'Font size';

  @override
  String get chartEditorFormatFromSource => 'Format from source data';

  @override
  String get chartEditorGridColor => 'Gridline color';

  @override
  String get chartEditorGridCount => 'Major gridline count';

  @override
  String get chartEditorIncludeHidden => 'Include hidden and filtered data';

  @override
  String get chartEditorItalic => 'Italic';

  @override
  String get chartEditorItemDividers => 'Show item dividers';

  @override
  String get chartEditorLineDash => 'Line dash';

  @override
  String get chartEditorLineThickness => 'Line thickness';

  @override
  String get chartEditorLogScale => 'Log scale';

  @override
  String get chartEditorMajorGridlines => 'Major gridlines';

  @override
  String get chartEditorMajorTicks => 'Major ticks';

  @override
  String get chartEditorMax => 'Max';

  @override
  String get chartEditorMaximize => 'Maximize';

  @override
  String get chartEditorMin => 'Min';

  @override
  String get chartEditorMinorGridlines => 'Minor gridlines';

  @override
  String get chartEditorMinorTicks => 'Minor ticks';

  @override
  String get chartEditorMissingSeries => 'Missing series (column deleted)';

  @override
  String get chartEditorMoveDown => 'Move down';

  @override
  String get chartEditorMoveUp => 'Move up';

  @override
  String get chartEditorNegativeColor => 'Negative color';

  @override
  String get chartEditorNumberFormat => 'Number format';

  @override
  String get chartEditorNumberFormatFromSource => 'From source data';

  @override
  String get chartEditorOutlierPercentile => 'Outlier percentile';

  @override
  String get chartEditorPageSize => 'Page size (0 = no paging)';

  @override
  String get chartEditorPlotNullValues => 'Plot null values';

  @override
  String get chartEditorPointShape => 'Point shape';

  @override
  String get chartEditorPointSize => 'Point size';

  @override
  String get chartEditorPosition => 'Position';

  @override
  String get chartEditorPositiveColor => 'Positive color';

  @override
  String get chartEditorRemove => 'Remove';

  @override
  String get chartEditorReset => 'Reset';

  @override
  String get chartEditorReverseAxis => 'Reverse axis order';

  @override
  String get chartEditorRisingColor => 'Rising color';

  @override
  String get chartEditorRisingFilled => 'Fill rising candles';

  @override
  String get chartEditorRowNumbers => 'Show row numbers';

  @override
  String get chartEditorSeries => 'Series';

  @override
  String get chartEditorSeriesTarget => 'Series';

  @override
  String get chartEditorSeriesType => 'Series type';

  @override
  String get chartEditorSetup => 'Setup';

  @override
  String get chartEditorShowAxisLine => 'Show axis line';

  @override
  String get chartEditorShowLabels => 'Show labels';

  @override
  String get chartEditorShowR2 => 'Show R²';

  @override
  String get chartEditorSlant => 'Slant labels';

  @override
  String get chartEditorSliceLabel => 'Slice label';

  @override
  String get chartEditorSmooth => 'Smooth';

  @override
  String get chartEditorStacking => 'Stacking';

  @override
  String get chartEditorSubtotalColor => 'Subtotal color';

  @override
  String get chartEditorSwitchRowsColumns => 'Switch rows / columns';

  @override
  String get chartEditorTextColor => 'Text color';

  @override
  String get chartEditorTitlePlaceholder => 'Add a title';

  @override
  String get chartEditorTitleTarget => 'Title';

  @override
  String get chartEditorTitleText => 'Title text';

  @override
  String get chartEditorTreatLabelsAsText => 'Treat labels as text';

  @override
  String get chartEditorTrendline => 'Trendline';

  @override
  String get chartEditorTrendlineColor => 'Trendline color';

  @override
  String get chartEditorTrendlineDegree => 'Polynomial degree';

  @override
  String get chartEditorTrendlineLabel => 'Label';

  @override
  String get chartEditorTrendlinePeriod => 'Average of';

  @override
  String get chartEditorTrendlineType => 'Type';

  @override
  String chartEditorUseColumnAsLabels(String column) {
    return 'Use column $column as labels';
  }

  @override
  String chartEditorUseRowAsHeaders(int row) {
    return 'Use row $row as headers';
  }

  @override
  String chartEditorUseRowAsLabels(int row) {
    return 'Use row $row as labels';
  }

  @override
  String get chartEditorXAxis => 'X-axis';

  @override
  String get chartEmptyCellsConnect => 'Connect line';

  @override
  String get chartEmptyCellsGap => 'Show as gaps';

  @override
  String get chartEmptyCellsZero => 'Show as zero';

  @override
  String get chartGroupArea => 'Area';

  @override
  String get chartGroupBar => 'Bar';

  @override
  String get chartGroupColumn => 'Column';

  @override
  String get chartGroupLine => 'Line';

  @override
  String get chartGroupOther => 'Other';

  @override
  String get chartGroupPie => 'Pie';

  @override
  String get chartGroupScatter => 'Scatter';

  @override
  String get chartGroupSuggested => 'Suggested';

  @override
  String get chartLabelAbove => 'Above';

  @override
  String get chartLabelBelow => 'Below';

  @override
  String get chartLabelInsideBase => 'Inside base';

  @override
  String get chartLabelInsideEnd => 'Inside end';

  @override
  String get chartLabelOutsideEnd => 'Outside end';

  @override
  String get chartLegendAuto => 'Auto';

  @override
  String get chartLegendBottom => 'Bottom';

  @override
  String get chartLegendInside => 'Inside';

  @override
  String get chartLegendLeft => 'Left';

  @override
  String get chartLegendNone => 'None';

  @override
  String get chartLegendRight => 'Right';

  @override
  String get chartLegendTop => 'Top';

  @override
  String get chartNewerVersion =>
      'This chart was created with a newer version of Wonky Sheets. Reload to edit it.';

  @override
  String get chartNoData => 'No data';

  @override
  String get chartNotFound => 'Chart not found';

  @override
  String get chartScoreAbsolute => 'Absolute change';

  @override
  String get chartScorePercent => 'Percentage change';

  @override
  String get chartSectionCandlestick => 'Candlestick';

  @override
  String get chartSectionGridlines => 'Gridlines and ticks';

  @override
  String get chartSectionHAxis => 'Horizontal axis';

  @override
  String get chartSectionHistogram => 'Histogram';

  @override
  String get chartSectionLegend => 'Legend';

  @override
  String get chartSectionPie => 'Pie chart';

  @override
  String get chartSectionScorecard => 'Scorecard';

  @override
  String get chartSectionSeries => 'Series';

  @override
  String get chartSectionStyle => 'Chart style';

  @override
  String get chartSectionTable => 'Table';

  @override
  String get chartSectionTitles => 'Chart & axis titles';

  @override
  String get chartSectionVAxis => 'Vertical axis';

  @override
  String get chartSectionWaterfall => 'Waterfall';

  @override
  String get chartShapeCircle => 'Circle';

  @override
  String get chartShapeDiamond => 'Diamond';

  @override
  String get chartShapePolygon => 'Polygon';

  @override
  String get chartShapeSquare => 'Square';

  @override
  String get chartShapeStar => 'Star';

  @override
  String get chartShapeTriangle => 'Triangle';

  @override
  String get chartSheetEmpty => 'This chart sheet is empty';

  @override
  String get chartSlantCustom => 'Custom';

  @override
  String get chartSlantNone => 'None';

  @override
  String get chartSliceLabelBoth => 'Value and percentage';

  @override
  String get chartSliceLabelLabel => 'Label';

  @override
  String get chartSliceLabelNone => 'None';

  @override
  String get chartSliceLabelPercentage => 'Percentage';

  @override
  String get chartSliceLabelValue => 'Value';

  @override
  String get chartStackingNone => 'None';

  @override
  String get chartStackingNormal => 'Standard';

  @override
  String get chartStackingPercent => '100%';

  @override
  String get chartTickInside => 'Inside';

  @override
  String get chartTickNone => 'None';

  @override
  String get chartTickOutside => 'Outside';

  @override
  String get chartTitleChart => 'Chart title';

  @override
  String get chartTitleHAxis => 'Horizontal axis title';

  @override
  String get chartTitleSubtitle => 'Chart subtitle';

  @override
  String get chartTitleV2Axis => 'Right vertical axis title';

  @override
  String get chartTitleVAxis => 'Vertical axis title';

  @override
  String get chartTrendExponential => 'Exponential';

  @override
  String get chartTrendLabelCustom => 'Custom';

  @override
  String get chartTrendLabelEquation => 'Use equation';

  @override
  String get chartTrendLabelNone => 'None';

  @override
  String get chartTrendLinear => 'Linear';

  @override
  String get chartTrendLogarithmic => 'Logarithmic';

  @override
  String get chartTrendMovingAverage => 'Moving average';

  @override
  String get chartTrendPolynomial => 'Polynomial';

  @override
  String get chartTrendPower => 'Power series';

  @override
  String get chartTypeArea => 'Area chart';

  @override
  String get chartTypeBar => 'Bar chart';

  @override
  String get chartTypeBubble => 'Bubble chart';

  @override
  String get chartTypeCandlestick => 'Candlestick chart';

  @override
  String get chartTypeColumn => 'Column chart';

  @override
  String get chartTypeCombo => 'Combo chart';

  @override
  String get chartTypeDoughnut => 'Doughnut chart';

  @override
  String get chartTypeHistogram => 'Histogram chart';

  @override
  String get chartTypeLine => 'Line chart';

  @override
  String get chartTypeNoMatch => 'No chart type matches';

  @override
  String get chartTypePercentArea => '100% stacked area chart';

  @override
  String get chartTypePercentBar => '100% stacked bar chart';

  @override
  String get chartTypePercentColumn => '100% stacked column chart';

  @override
  String get chartTypePie => 'Pie chart';

  @override
  String get chartTypeRadar => 'Radar chart';

  @override
  String get chartTypeScatter => 'Scatter chart';

  @override
  String get chartTypeScorecard => 'Scorecard chart';

  @override
  String get chartTypeSearch => 'Search chart types';

  @override
  String get chartTypeSmoothLine => 'Smooth line chart';

  @override
  String get chartTypeStackedArea => 'Stacked area chart';

  @override
  String get chartTypeStackedBar => 'Stacked bar chart';

  @override
  String get chartTypeStackedColumn => 'Stacked column chart';

  @override
  String get chartTypeTable => 'Table chart';

  @override
  String get chartTypeWaterfall => 'Waterfall chart';

  @override
  String chartWarnLogSkipped(int count) {
    return 'Log scale ignores $count non-positive values';
  }

  @override
  String get chartWarnNoData => 'No data';

  @override
  String get chartWarnRangeNotFound => 'Data range not found';

  @override
  String get chartWarnRangeSizeMismatch => 'Ranges have different sizes';

  @override
  String get chartWarnTooManyCategories =>
      'Too many categories to show individually';

  @override
  String chartWarnTrendlineIgnored(int count) {
    return 'Trendline ignores $count non-positive values';
  }

  @override
  String get cmdChartCopyAsImage => 'Copy chart as image';

  @override
  String get cmdChartDownload => 'Download chart';

  @override
  String get cmdChartEdit => 'Edit chart';

  @override
  String get cmdChartInsertDescription =>
      'Insert a chart recommended for the selected data';

  @override
  String get cmdChartMoveToOwnSheet => 'Move to own sheet';

  @override
  String get cmdChartMoveToSheet => 'Move chart to sheet';

  @override
  String get cmdChartSetDataRanges => 'Set chart data range';

  @override
  String get cmdChartSetType => 'Change chart type';

  @override
  String get cmdChartUpdate => 'Edit chart';

  @override
  String get cmdChartViewDataTable => 'View data as table';

  @override
  String get cmdImagePlaceInCell => 'Place image in selected cell';

  @override
  String get cmdImagePlaceOverCells => 'Place image over cells';

  @override
  String get cmdImageReplace => 'Replace image';

  @override
  String get cmdImageResetSize => 'Reset size';

  @override
  String get cmdObjectCopy => 'Copy';

  @override
  String get cmdObjectCut => 'Cut';

  @override
  String get cmdObjectDelete => 'Delete';

  @override
  String get cmdObjectDeselect => 'Deselect object';

  @override
  String get cmdObjectDuplicate => 'Duplicate';

  @override
  String get cmdObjectEditAltText => 'Alt text';

  @override
  String get cmdObjectList => 'List objects';

  @override
  String get cmdObjectMove => 'Move object';

  @override
  String get cmdObjectNudge => 'Nudge object';

  @override
  String get cmdObjectOrder => 'Order';

  @override
  String get cmdObjectPaste => 'Paste object';

  @override
  String get cmdObjectResize => 'Resize object';

  @override
  String get cmdObjectSelect => 'Select object';

  @override
  String get cmdObjectSelectNext => 'Select next object';

  @override
  String get cmdObjectSelectPrevious => 'Select previous object';

  @override
  String get dialogAltTextBody => 'Description';

  @override
  String get dialogAltTextDescription =>
      'Alt text describes the object for people who use screen readers.';

  @override
  String get dialogAltTextName => 'Title';

  @override
  String get dialogAltTextTitle => 'Alt text';

  @override
  String dialogChartDataTitle(String title) {
    return 'Data of $title';
  }

  @override
  String get dialogClose => 'Close';

  @override
  String get dialogDeleteChartSheetBody =>
      'The chart and its chart sheet will be deleted.';

  @override
  String get dialogDeleteChartSheetTitle => 'Delete chart sheet?';

  @override
  String get dialogImageDescription =>
      'Upload an image from your computer or insert one by URL.';

  @override
  String get dialogImageInCellTitle => 'Insert image in cell';

  @override
  String get dialogImageInsert => 'Insert';

  @override
  String get dialogImageOverCellsTitle => 'Insert image over cells';

  @override
  String get dialogImageUpload => 'Upload from computer…';

  @override
  String get dialogImageUrl => 'Image URL';

  @override
  String get dialogImageUrlInvalid => 'Enter an https:// image URL';

  @override
  String get dialogImageUrlRequired => 'Enter an image URL or upload a file';

  @override
  String downloadSaveTitle(String name) {
    return 'Save $name';
  }

  @override
  String get imageFetchFailed => 'The image could not be loaded from that URL';

  @override
  String get imageLoading => 'Loading image…';

  @override
  String get imagePickTitle => 'Choose an image';

  @override
  String get imageRejectedFormat =>
      'Only PNG, JPEG, GIF, WebP and BMP images can be inserted';

  @override
  String get imageRejectedTooLarge =>
      'The image is too large (max. 50 MB and 25 megapixels)';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get imageUploading => 'Image uploading…';

  @override
  String get imageNotUploadedOutOfStorage => 'Not uploaded — out of storage';

  @override
  String get imageRetryUpload => 'Retry';

  @override
  String get imageRemove => 'Remove';

  @override
  String get objectMenuCopyChart => 'Copy chart';

  @override
  String get objectMenuDownload => 'Download';

  @override
  String get objectMenuMoveToSheet => 'Move to sheet';

  @override
  String get objectMenuOrder => 'Order';

  @override
  String get objectMoreOptions => 'More options';

  @override
  String get objectNotFound => 'Object not found';

  @override
  String get objectOrderBack => 'Send to back';

  @override
  String get objectOrderBackward => 'Send backward';

  @override
  String get objectOrderForward => 'Bring forward';

  @override
  String get objectOrderFront => 'Bring to front';

  @override
  String get undoEditAltText => 'Edit alt text';

  @override
  String get undoEditChart => 'Edit chart';

  @override
  String get undoInsertImage => 'Insert image';

  @override
  String get dvGroupText => 'Text';

  @override
  String get dvGroupDate => 'Date';

  @override
  String get dvGroupNumber => 'Number';

  @override
  String get dvGroupOther => 'Other';

  @override
  String get filterViewNoneItem => 'None';

  @override
  String get recoveryTitle =>
      'Your offline spreadsheet data couldn\'t be opened';

  @override
  String recoveryDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count spreadsheets had changes that weren\'t synced yet. Download them before they\'re lost.',
      one:
          '1 spreadsheet had changes that weren\'t synced yet. Download them before they\'re lost.',
    );
    return '$_temp0';
  }

  @override
  String get recoveryDownload => 'Download unsynced changes';

  @override
  String get recoveryFailed => 'The unsynced changes could not be exported';

  @override
  String get storageLimitedTitle =>
      'Offline storage is limited in this browser';

  @override
  String storageLimitedDescription(String cells) {
    return 'This browser keeps offline spreadsheets in memory. Only about $cells cells stay available offline; the spreadsheets you opened least recently are removed from this device first.';
  }

  @override
  String loadingRowsStatus(int percent) {
    return 'Loading… $percent%';
  }

  @override
  String get categoryScripts => 'Scripts';

  @override
  String get menuScriptMenus => 'Script menus';

  @override
  String get cmdMacroCancelRecording => 'Cancel macro recording';

  @override
  String get cmdMacroDelete => 'Remove macro';

  @override
  String get cmdMacroRun => 'Run macro';

  @override
  String get cmdMacroSaveRecording => 'Save macro';

  @override
  String get cmdMacroUpdate => 'Edit macro';

  @override
  String get cmdScriptAddTrigger => 'Add trigger';

  @override
  String get cmdScriptAuthorize => 'Authorize script';

  @override
  String get cmdScriptCloseEditor => 'Close script editor';

  @override
  String get cmdScriptCompile => 'Build script';

  @override
  String get cmdScriptDeleteFile => 'Delete script file';

  @override
  String get cmdScriptDeleteTrigger => 'Delete trigger';

  @override
  String get cmdScriptExplainWithAi => 'Explain script with AI';

  @override
  String get cmdScriptFixErrorWithAi => 'Fix script error with AI';

  @override
  String get cmdScriptGenerateWithAi => 'Generate script with AI';

  @override
  String get cmdScriptNewFile => 'New script file';

  @override
  String get cmdScriptOpenSettings => 'Script settings';

  @override
  String get cmdScriptRenameFile => 'Rename script file';

  @override
  String get cmdScriptReorderFile => 'Move script file';

  @override
  String get cmdScriptRevertExecution => 'Revert script changes';

  @override
  String get cmdScriptRevokeAuthorization => 'Revoke my authorization';

  @override
  String get cmdScriptRun => 'Run';

  @override
  String get cmdScriptRunMenuItem => 'Run script menu item';

  @override
  String get cmdScriptSaveAll => 'Save all script files';

  @override
  String get cmdScriptSaveFile => 'Save script file';

  @override
  String get cmdScriptStop => 'Stop';

  @override
  String get cmdScriptUpdateSettings => 'Change script settings';

  @override
  String get cmdScriptUpdateTrigger => 'Edit trigger';

  @override
  String get execEmpty => 'No executions yet.';

  @override
  String get execKindCustomFunction => 'Custom function';

  @override
  String get execKindEditor => 'Editor';

  @override
  String get execKindInstallable => 'Trigger';

  @override
  String get execKindMacro => 'Macro';

  @override
  String get execKindMenu => 'Menu';

  @override
  String get execKindTimeDriven => 'Time-driven';

  @override
  String get execLoading => 'Loading executions…';

  @override
  String get execNoLogs => 'No log output.';

  @override
  String get execOpenInEditor => 'Open in editor';

  @override
  String get execRefresh => 'Refresh';

  @override
  String get execRevert => 'Revert changes';

  @override
  String get execStatusAll => 'All statuses';

  @override
  String get execStatusCancelled => 'Cancelled';

  @override
  String get execStatusCompleted => 'Completed';

  @override
  String get execStatusFailed => 'Failed';

  @override
  String get execStatusQuota => 'Quota exceeded';

  @override
  String get execStatusSkipped => 'Skipped';

  @override
  String get execStatusTimedOut => 'Timed out';

  @override
  String execDuration(int ms) {
    final intl.NumberFormat msNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String msString = msNumberFormat.format(ms);

    return '$msString ms';
  }

  @override
  String execStats(int read, int written, int fetches) {
    final intl.NumberFormat readNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String readString = readNumberFormat.format(read);
    final intl.NumberFormat writtenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String writtenString = writtenNumberFormat.format(written);
    final intl.NumberFormat fetchesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String fetchesString = fetchesNumberFormat.format(fetches);

    return '$readString cells read · $writtenString written · $fetchesString fetches';
  }

  @override
  String get macroAbsolute => 'Absolute';

  @override
  String get macroRelative => 'Relative';

  @override
  String get macroCancel => 'Cancel';

  @override
  String get macroEditScript => 'Edit script';

  @override
  String get macroImportAction => 'Import';

  @override
  String get macroImportNone =>
      'There are no functions to import. Write a function without parameters in the script editor first.';

  @override
  String get macroName => 'Name';

  @override
  String get macroNameEmpty => 'Enter a name.';

  @override
  String get macroNameFromFunction => 'Same as the function';

  @override
  String get macroNotFound => 'That macro no longer exists.';

  @override
  String get macroRecording => 'Recording new macro…';

  @override
  String macroRecordingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Recording new macro… $countString steps';
  }

  @override
  String get macroRemove => 'Remove macro';

  @override
  String get macroSaveTitle => 'Save new macro';

  @override
  String get macroShortcut => 'Shortcut';

  @override
  String get macroShortcutNone => 'None';

  @override
  String macroShortcutTaken(String shortcut, String name) {
    return '$shortcut (used by $name)';
  }

  @override
  String macroDefaultName(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Macro $nString';
  }

  @override
  String get macrosEmpty =>
      'No macros yet. Record one with Extensions › Macros › Record macro.';

  @override
  String get scriptAuthorizeAllow => 'Allow';

  @override
  String get scriptAuthorizeFailed => 'Couldn\'t authorize the script';

  @override
  String get scriptAuthorizeTitle => 'Authorization required';

  @override
  String scriptAuthorizeBody(String project) {
    return '$project wants to:';
  }

  @override
  String get scriptBackToSpreadsheet => 'Back to the spreadsheet';

  @override
  String get scriptButtonCancel => 'Cancel';

  @override
  String get scriptButtonNo => 'No';

  @override
  String get scriptButtonYes => 'Yes';

  @override
  String get scriptClearLog => 'Clear log';

  @override
  String get scriptCloseTab => 'Close';

  @override
  String get scriptCollapse => 'Collapse';

  @override
  String get scriptExpand => 'Expand';

  @override
  String get scriptConflictDiscard => 'Discard mine';

  @override
  String get scriptConflictOverwrite => 'Overwrite with mine';

  @override
  String get scriptConflictTitle => 'Newer version saved';

  @override
  String scriptConflictBody(String file) {
    return 'Someone else saved a newer version of $file since you opened it.';
  }

  @override
  String get scriptCreate => 'Create';

  @override
  String get scriptDefaultProjectName => 'This script';

  @override
  String get scriptDeleteProjectTitle => 'Delete the script project?';

  @override
  String get scriptDeleteProjectBody =>
      'Deletes all script files, triggers and macros of this spreadsheet. You can undo this.';

  @override
  String get scriptDialogTitle => 'Script';

  @override
  String scriptEditorTitle(String title) {
    return '$title · Script';
  }

  @override
  String scriptErrorToast(String function) {
    return 'Script error in $function';
  }

  @override
  String get scriptFileLimit => 'A script can have at most 50 files.';

  @override
  String get scriptFileName => 'File name';

  @override
  String get scriptFileNameDuplicate => 'A file with this name already exists.';

  @override
  String get scriptFileNameInvalid =>
      'Use lower-case letters, digits and _, ending in .dart (utils.dart).';

  @override
  String get scriptFileNotFound => 'That script file no longer exists.';

  @override
  String scriptFileUpdated(String file) {
    return '$file was updated by someone else';
  }

  @override
  String get scriptFiles => 'Files';

  @override
  String get scriptFind => 'Find';

  @override
  String get scriptFindMatchCase => 'Match case';

  @override
  String get scriptFindNext => 'Next match';

  @override
  String get scriptFindNoResults => 'No results';

  @override
  String get scriptFindPlaceholder => 'Find';

  @override
  String get scriptFindPrevious => 'Previous match';

  @override
  String get scriptFindRegex => 'Regular expression';

  @override
  String get scriptFindToggleReplace => 'Replace';

  @override
  String get scriptFixWithAi => 'Fix with AI';

  @override
  String get scriptFunctions => 'Functions';

  @override
  String get scriptGenerate => 'Generate';

  @override
  String get scriptLog => 'Log';

  @override
  String get scriptLogEmpty => 'Run a function to see its log here.';

  @override
  String get scriptNeedsNewerApp =>
      'This script needs a newer version of the app.';

  @override
  String get scriptNewerVersion =>
      'A newer version of this file was saved elsewhere.';

  @override
  String get scriptNoBuild => 'The script hasn\'t built successfully yet.';

  @override
  String get scriptNoFileOpen => 'No file open';

  @override
  String get scriptNoFunctions => 'Functions appear after a successful build.';

  @override
  String get scriptNoProblems => 'No problems';

  @override
  String get scriptNoRunnableFunctions => 'No runnable functions';

  @override
  String get scriptOffline =>
      'You\'re offline. Try again when you\'re connected.';

  @override
  String get scriptPickFunction => 'Choose a function to run.';

  @override
  String scriptProblems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Problems $countString';
  }

  @override
  String get scriptPromptLabel => 'Your answer';

  @override
  String get scriptReadOnly => 'Read-only';

  @override
  String get scriptReload => 'Reload';

  @override
  String get scriptReplace => 'Replace';

  @override
  String get scriptReplaceAll => 'Replace all';

  @override
  String get scriptReplacePlaceholder => 'Replace with';

  @override
  String scriptRevertLabel(String function) {
    return 'Revert script: $function';
  }

  @override
  String get scriptRunOnServer => 'Run on server';

  @override
  String get scriptSave => 'Save';

  @override
  String get scriptScopeExternalRequest => 'Connect to external services';

  @override
  String get scriptScopeTriggers => 'Run when you\'re not present (triggers)';

  @override
  String get scriptScopeUserEmail => 'See your email address';

  @override
  String get scriptSettings => 'Settings';

  @override
  String get scriptSettingsAllowlist =>
      'URL allowlist (hosts, comma separated)';

  @override
  String scriptSettingsApiVersion(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'API version $versionString';
  }

  @override
  String scriptSettingsBuildHash(String hash) {
    return 'Build $hash';
  }

  @override
  String scriptSettingsBuiltAt(String time) {
    return 'Built $time';
  }

  @override
  String get scriptSettingsDeleteProject => 'Delete project';

  @override
  String get scriptSettingsName => 'Project name';

  @override
  String get scriptSettingsNameEmpty => 'Enter a name.';

  @override
  String get scriptSettingsShowMenus => 'Show script menus in the menubar';

  @override
  String get scriptSettingsTimeZone => 'Time zone';

  @override
  String get scriptStatusBuilding => 'Building…';

  @override
  String scriptStatusBuilt(String time) {
    return 'Built $time';
  }

  @override
  String scriptStatusFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Build failed ($countString errors)';
  }

  @override
  String get scriptStatusNotBuilt => 'Not built yet';

  @override
  String get scriptStatusOffline =>
      'Saved on this device · Will compile when online';

  @override
  String get scriptStatusSaved => 'Saved';

  @override
  String get scriptStatusUnsaved => 'Unsaved changes';

  @override
  String scriptUnknownFunction(String name) {
    return 'There is no function $name in the script.';
  }

  @override
  String get scriptViewDetails => 'View details';

  @override
  String get triggerAdd => 'Add trigger';

  @override
  String get triggerAddTitle => 'Add trigger';

  @override
  String get triggerAt => 'Date and time (once)';

  @override
  String get triggerAtHour => 'Hour of day (0–23)';

  @override
  String get triggerDelete => 'Delete trigger';

  @override
  String get triggerDisabled => 'Disabled';

  @override
  String get triggerEnabled => 'Enabled';

  @override
  String get triggerEvent => 'Event';

  @override
  String get triggerEventChange => 'On change';

  @override
  String get triggerEventEdit => 'On edit';

  @override
  String get triggerEventOpen => 'On open';

  @override
  String get triggerEventTime => 'Time-driven';

  @override
  String triggerEveryDays(int n, int hour) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat hourNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String hourString = hourNumberFormat.format(hour);

    return 'Every $nString day(s) at $hourString:00';
  }

  @override
  String triggerEveryHours(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Every $nString hour(s)';
  }

  @override
  String triggerEveryMinutes(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Every $nString minute(s)';
  }

  @override
  String triggerEveryWeeks(int n, String weekday, int hour) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat hourNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String hourString = hourNumberFormat.format(hour);

    return 'Every $nString week(s) on $weekday at $hourString:00';
  }

  @override
  String triggerMonthly(int day, int hour) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);
    final intl.NumberFormat hourNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String hourString = hourNumberFormat.format(hour);

    return 'Monthly on day $dayString at $hourString:00';
  }

  @override
  String triggerOnce(String at) {
    return 'Once at $at';
  }

  @override
  String get triggerFireForMcp => 'Also run for agent (MCP) edits';

  @override
  String get triggerFunction => 'Function';

  @override
  String get triggerInterval => 'Every (interval)';

  @override
  String get triggerInvalidDate => 'Enter a date like 2026-12-24T09:00.';

  @override
  String get triggerInvalidNumber => 'Enter a number in range.';

  @override
  String get triggerMonthDay => 'Day of month';

  @override
  String get triggerNotFound => 'That trigger no longer exists.';

  @override
  String get triggerNotYours =>
      'Only the owner can change other people\'s triggers.';

  @override
  String get triggerNotify => 'Failure notifications';

  @override
  String get triggerNotifyDaily => 'Daily digest';

  @override
  String get triggerNotifyImmediately => 'Immediately';

  @override
  String get triggerNotifyNever => 'Never';

  @override
  String get triggerOwnerOther => 'Another user';

  @override
  String get triggerScheduleType => 'Schedule';

  @override
  String get triggerTypeDays => 'Daily';

  @override
  String get triggerTypeHours => 'Hourly';

  @override
  String get triggerTypeMinutes => 'Every few minutes';

  @override
  String get triggerTypeMonthly => 'Monthly';

  @override
  String get triggerTypeOnce => 'Once';

  @override
  String get triggerTypeWeeks => 'Weekly';

  @override
  String get triggerWeekday => 'Weekday';

  @override
  String get triggersDescription =>
      'Installable triggers run on the server, also when nobody has the spreadsheet open.';

  @override
  String get triggersEmpty => 'No triggers yet.';

  @override
  String get undoCreateScriptFile => 'Create script file';

  @override
  String get undoDeleteScriptFile => 'Delete script file';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get macroAbsoluteHint =>
      'Use absolute references (the same cells every time)';

  @override
  String get macroRelativeHint =>
      'Use relative references (cells relative to the selection)';

  @override
  String get sheetsSettingsColumnAutocomplete =>
      'Autocomplete values from the column';

  @override
  String a11yGridLabel(String sheet) {
    return '$sheet grid';
  }

  @override
  String a11yCellEmpty(String cell) {
    return '$cell, empty';
  }

  @override
  String a11yCellValue(String cell, String value) {
    return '$cell, $value';
  }

  @override
  String a11yCellFormula(String formula) {
    return 'formula $formula';
  }

  @override
  String a11yCellError(String cell, String message) {
    return '$cell, error, $message';
  }

  @override
  String get a11yCheckboxChecked => 'checkbox checked';

  @override
  String get a11yCheckboxUnchecked => 'checkbox unchecked';

  @override
  String a11yLink(String url) {
    return 'link, $url';
  }

  @override
  String get a11yHasNote => 'has note';

  @override
  String a11yRangeSelected(String from, String to, int count) {
    return '$from to $to selected, $count cells';
  }

  @override
  String a11yMerged(String from, String to) {
    return '$from to $to merged';
  }

  @override
  String a11yEditing(String cell) {
    return 'Editing $cell';
  }

  @override
  String a11yColumnHeader(String column) {
    return 'Column $column';
  }

  @override
  String a11yRowHeader(String row) {
    return 'Row $row';
  }

  @override
  String get a11yLoadingRow => 'Loading';

  @override
  String get contextMenuDragCopy => 'Copy';

  @override
  String get chartGroup3D => '3D';

  @override
  String get chartType3DColumn => '3D column chart';

  @override
  String get chartType3DStackedColumn => '3D stacked column chart';

  @override
  String get chartType3DPercentColumn => '3D 100% stacked column chart';

  @override
  String get chartType3DBar => '3D bar chart';

  @override
  String get chartType3DStackedBar => '3D stacked bar chart';

  @override
  String get chartType3DLine => '3D line chart';

  @override
  String get chartType3DArea => '3D area chart';

  @override
  String get chartType3DStackedArea => '3D stacked area chart';

  @override
  String get chartType3DPie => '3D pie chart';

  @override
  String get chartType3DDoughnut => '3D doughnut chart';

  @override
  String get chartSection3D => '3D';

  @override
  String get chartEditor3DEnabled => 'Show in 3D';

  @override
  String get chartEditor3DRotation => 'Rotation';

  @override
  String get chartEditor3DTilt => 'Tilt';

  @override
  String get chartEditor3DPerspective => 'Perspective';

  @override
  String get chartEditor3DDepth => 'Depth';

  @override
  String get chartEditor3DHeight => 'Height';

  @override
  String get chartEditor3DGapDepth => 'Gap depth';

  @override
  String get chartEditor3DExplode => 'Pull slices apart';

  @override
  String get chartEditor3DLighting => 'Lighting';

  @override
  String get chartLightingSoft => 'Soft';

  @override
  String get chartLightingBright => 'Bright';

  @override
  String get chartLightingFlat => 'Flat';

  @override
  String get chartEditor3DShape => 'Shape';

  @override
  String get chartShapeBox => 'Box';

  @override
  String get chartShapeCylinder => 'Cylinder';

  @override
  String get chartShapeCone => 'Cone';

  @override
  String get chartShapePyramid => 'Pyramid';

  @override
  String get chartEditor3DWalls => 'Floor and walls';

  @override
  String get chartEditor3DFloorColor => 'Floor color';

  @override
  String get chartEditor3DResetView => 'Reset view';

  @override
  String get chartEditor3DOrbitHint =>
      'Drag the selected chart, or press Alt+Shift+arrow keys, to rotate it.';

  @override
  String get cmdChartToggle3D => 'Show chart in 3D';

  @override
  String get cmdChartToggle3DDescription =>
      'Draws the selected column, bar, line, area or pie chart in 3D, or flat again.';

  @override
  String get cmdChartReset3DView => 'Reset 3D chart view';

  @override
  String get cmdChartRotate3D => 'Rotate 3D chart';

  @override
  String get cmdObjectAlign => 'Align objects';

  @override
  String get undoAlignObjects => 'Align objects';

  @override
  String get objectMenuAlign => 'Align';

  @override
  String get objectAlignLeft => 'Left';

  @override
  String get objectAlignCenter => 'Center';

  @override
  String get objectAlignRight => 'Right';

  @override
  String get objectAlignTop => 'Top';

  @override
  String get objectAlignMiddle => 'Middle';

  @override
  String get objectAlignBottom => 'Bottom';

  @override
  String get objectDistributeHorizontally => 'Distribute horizontally';

  @override
  String get objectDistributeVertically => 'Distribute vertically';

  @override
  String get reasonChartSheet => 'Not available on chart sheets';

  @override
  String get imageClipboardEmpty => 'There is no image on the clipboard';

  @override
  String get dialogImagePaste => 'Paste from clipboard';

  @override
  String get chartCopyImageFailed => 'Couldn\'t put the image on the clipboard';

  @override
  String get chartCopiedAsImage => 'Chart copied as an image';

  @override
  String get chartEditorTrendlineCustomLabel => 'Custom label';

  @override
  String get chartEditorTrendlineCustomLabelHint => 'Label text';

  @override
  String get chartEditorErrorBars => 'Error bars';

  @override
  String get chartEditorErrorBarsType => 'Type';

  @override
  String get chartErrorBarsConstant => 'Constant';

  @override
  String get chartErrorBarsPercent => 'Percent';

  @override
  String get chartErrorBarsStdev => 'Standard deviation';

  @override
  String get chartEditorErrorBarsValue => 'Value';

  @override
  String get chartEditorFormatDataPoint => 'Format data point';

  @override
  String get chartEditorPickPoint => 'Choose a point';

  @override
  String get chartEditorAdd => 'Add';

  @override
  String get chartSectionPieSlice => 'Pie slice';

  @override
  String get chartEditorSlice => 'Slice';

  @override
  String get chartEditorSliceColor => 'Slice color';

  @override
  String get chartEditorSliceDistance => 'Distance from center';

  @override
  String get chartEditorSubtotals => 'Subtotals';

  @override
  String get chartEditorNoSubtotals => 'No subtotals';

  @override
  String chartEditorSubtotalAfter(String point) {
    return 'After $point';
  }

  @override
  String get chartEditorSubtotalLabel => 'Label';

  @override
  String get chartEditorAddSubtotal => 'Add subtotal';

  @override
  String get chartEditorInvalidCell => 'Enter a cell such as B2 or Sheet1!B2';

  @override
  String get chartEditorKeyValueCell => 'Key value cell';

  @override
  String get chartEditorBaselineCell => 'Baseline cell';

  @override
  String get chartEditorFromDataRange => 'From the data range';

  @override
  String get scriptsDisabled =>
      'Scripts are turned off on this device (Settings › Sheets).';

  @override
  String get scriptsDisabledBanner =>
      'Scripts are turned off for you. Functions, triggers and custom functions don\'t run.';

  @override
  String get scriptsEnable => 'Turn on scripts';

  @override
  String scriptConflictBodyBy(String user, String file, String when) {
    return '$user saved a newer version of $file ($when).';
  }

  @override
  String get scriptCompare => 'Compare';

  @override
  String get scriptHideComparison => 'Hide comparison';

  @override
  String get scriptMerge => 'Merge';

  @override
  String get scriptVersionTheirs => 'Saved version';

  @override
  String get scriptVersionMine => 'Your version';

  @override
  String scriptMergeConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The merge has $count conflicts. Resolve the marked lines, then save.',
      one: 'The merge has 1 conflict. Resolve the marked lines, then save.',
    );
    return '$_temp0';
  }

  @override
  String get scriptMergeConflictProblem =>
      'Merge conflict: keep your lines, theirs or both, then remove the markers.';

  @override
  String scriptHistoryTitle(String file) {
    return 'Local history of $file';
  }

  @override
  String get scriptHistoryDescription =>
      'Versions saved on this device (the last 20). Restoring puts the version in the editor without saving.';

  @override
  String get scriptHistoryVersion => 'Version';

  @override
  String get scriptHistoryRestore => 'Restore';

  @override
  String get scriptHistoryEmpty => 'No versions saved on this device yet.';

  @override
  String get scriptHistorySelected => 'Selected version';

  @override
  String get scriptHistoryCurrent => 'Editor';

  @override
  String get scriptHistorySaved => 'Saved';

  @override
  String get scriptHistoryDiscarded => 'Discarded in a conflict';

  @override
  String get scriptHistoryOverwritten => 'Replaced by your save';

  @override
  String get scriptHistoryBeforeMerge => 'Before a merge';

  @override
  String get scriptLocalHistory => 'Local history';

  @override
  String scriptRestoredDraft(String file) {
    return 'Restored $file from the local history. Save to keep it.';
  }

  @override
  String get scriptApiReferenceTitle => 'Script API reference';

  @override
  String get scriptApiSearch => 'Search classes and members';

  @override
  String get scriptApiClass => 'Class';

  @override
  String get scriptApiNoMatches => 'No classes or members match.';

  @override
  String get cmdHelpScriptApiReference => 'Script API reference';

  @override
  String get scriptInScriptEditor => 'In the script editor';

  @override
  String scriptFileOpenBy(String names) {
    return 'Open by $names';
  }

  @override
  String get scriptDragToReorder => 'Drag to reorder';

  @override
  String get scriptLoadingCell => 'Loading…';

  @override
  String get sheetsSettingsChartPatterns =>
      'Distinguish chart series by pattern';

  @override
  String get chartViewDataTableAction => 'View data as table';

  @override
  String get chartType3DSurface => '3D surface';

  @override
  String get chartTypeSurface => 'Surface';

  @override
  String get scriptSidebarTitle => 'Script sidebar';

  @override
  String get scriptSidebarEmpty => 'No script sidebar is open.';
}
