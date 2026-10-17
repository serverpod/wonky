// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'wonky_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class WonkyUiLocalizationsEn extends WonkyUiLocalizations {
  WonkyUiLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get toolbarMore => 'More';

  @override
  String get toolbarLabel => 'Toolbar';

  @override
  String get colorAutomatic => 'Automatic';

  @override
  String get colorNone => 'None';

  @override
  String get colorReset => 'Reset';

  @override
  String get colorCustom => 'Custom…';

  @override
  String get colorCustomTitle => 'Custom color';

  @override
  String get colorThemeColors => 'Theme colors';

  @override
  String get colorRecentColors => 'Custom';

  @override
  String get colorHex => 'Hex';

  @override
  String get colorRed => 'R';

  @override
  String get colorGreen => 'G';

  @override
  String get colorBlue => 'B';

  @override
  String get colorAlpha => 'Opacity';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturationValue => 'Saturation and brightness';

  @override
  String get colorEyedropper => 'Pick a color from the screen';

  @override
  String get colorApply => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get colorBlack => 'black';

  @override
  String get colorWhite => 'white';

  @override
  String get colorGray => 'gray';

  @override
  String colorDarkGray(int n) {
    return 'dark gray $n';
  }

  @override
  String colorLightGray(int n) {
    return 'light gray $n';
  }

  @override
  String colorLight(String hue, int n) {
    return 'light $hue $n';
  }

  @override
  String colorDark(String hue, int n) {
    return 'dark $hue $n';
  }

  @override
  String get hueRedBerry => 'red berry';

  @override
  String get hueRed => 'red';

  @override
  String get hueOrange => 'orange';

  @override
  String get hueYellow => 'yellow';

  @override
  String get hueGreen => 'green';

  @override
  String get hueCyan => 'cyan';

  @override
  String get hueCornflowerBlue => 'cornflower blue';

  @override
  String get hueBlue => 'blue';

  @override
  String get huePurple => 'purple';

  @override
  String get hueMagenta => 'magenta';

  @override
  String get panelCollapse => 'Collapse panel';

  @override
  String get panelClose => 'Close panel';

  @override
  String get panelResize => 'Resize panel';

  @override
  String get treeExpand => 'Expand';

  @override
  String get treeCollapse => 'Collapse';

  @override
  String get presenceEditing => 'Editing';

  @override
  String get presenceViewing => 'Viewing';

  @override
  String get presenceIdle => 'Idle';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceOffline => 'Offline';

  @override
  String presenceMore(int count) {
    return '+$count';
  }

  @override
  String presenceMoreLabel(int count) {
    return '$count more people';
  }

  @override
  String get presenceYou => 'You';

  @override
  String presenceYouTabs(int count) {
    return 'You ($count tabs)';
  }

  @override
  String presenceTabs(String name, int count) {
    return '$name ($count tabs)';
  }

  @override
  String presenceJumpTo(String name) {
    return 'Go to $name\'s cursor';
  }

  @override
  String get presenceFollow => 'Follow';

  @override
  String get presenceInFile => 'In this file';

  @override
  String get stepperDecrease => 'Decrease';

  @override
  String get stepperIncrease => 'Increase';

  @override
  String tableSize(int rows, int columns) {
    return '$rows × $columns';
  }

  @override
  String tableSizeLabel(int rows, int columns) {
    return 'Insert a table with $rows rows and $columns columns';
  }

  @override
  String get fontRecent => 'Recent';

  @override
  String get fontTheme => 'Theme fonts';

  @override
  String get fontAll => 'All fonts';

  @override
  String get fontSearch => 'Search fonts';

  @override
  String get fontNone => 'No fonts found';

  @override
  String get syncSaved => 'Saved';

  @override
  String get syncSaving => 'Saving…';

  @override
  String get syncOffline => 'Offline — changes saved on this device';

  @override
  String get syncOfflineShort => 'Offline';

  @override
  String get syncError => 'Sync error';

  @override
  String get syncConnecting => 'Connecting…';

  @override
  String syncReconnecting(int seconds) {
    return 'Reconnecting in $seconds s…';
  }

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailsTitle => 'Sync status';

  @override
  String get syncRetry => 'Retry now';

  @override
  String get syncLog => 'Recent events';

  @override
  String get syncNoEvents => 'No sync events yet.';

  @override
  String get titleUntitled => 'Untitled';

  @override
  String get titleRename => 'Rename';

  @override
  String get shortcutPress => 'Press keys…';

  @override
  String get shortcutRecord => 'Record shortcut';

  @override
  String get shortcutClear => 'Clear';

  @override
  String get shortcutNone => 'None';

  @override
  String get shortcutCancelHint => 'Press Esc to cancel';

  @override
  String get loading => 'Loading…';

  @override
  String get scrollToTop => 'Scroll to top';

  @override
  String get menuSearchHint => 'Type to jump to an item';

  @override
  String get presenterExit => 'Exit presenter mode';

  @override
  String get presenterPrevious => 'Previous slide';

  @override
  String get presenterNext => 'Next slide';

  @override
  String presenterPosition(int current, int total) {
    return '$current of $total';
  }

  @override
  String get presenterBarLabel => 'Presenter controls';
}
