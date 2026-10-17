import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'wonky_ui_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of WonkyUiLocalizations
/// returned by `WonkyUiLocalizations.of(context)`.
///
/// Applications need to include `WonkyUiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/wonky_ui_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: WonkyUiLocalizations.localizationsDelegates,
///   supportedLocales: WonkyUiLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the WonkyUiLocalizations.supportedLocales
/// property.
abstract class WonkyUiLocalizations {
  WonkyUiLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static WonkyUiLocalizations of(BuildContext context) {
    return Localizations.of<WonkyUiLocalizations>(
      context,
      WonkyUiLocalizations,
    )!;
  }

  static const LocalizationsDelegate<WonkyUiLocalizations> delegate =
      _WonkyUiLocalizationsDelegate();

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

  /// Overflow button of a toolbar that holds items that do not fit.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get toolbarMore;

  /// No description provided for @toolbarLabel.
  ///
  /// In en, this message translates to:
  /// **'Toolbar'**
  String get toolbarLabel;

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

  /// No description provided for @colorReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get colorReset;

  /// No description provided for @colorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get colorCustom;

  /// No description provided for @colorCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get colorCustomTitle;

  /// No description provided for @colorThemeColors.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get colorThemeColors;

  /// No description provided for @colorRecentColors.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get colorRecentColors;

  /// No description provided for @colorHex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get colorHex;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get colorBlue;

  /// No description provided for @colorAlpha.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get colorAlpha;

  /// No description provided for @colorHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get colorHue;

  /// No description provided for @colorSaturationValue.
  ///
  /// In en, this message translates to:
  /// **'Saturation and brightness'**
  String get colorSaturationValue;

  /// No description provided for @colorEyedropper.
  ///
  /// In en, this message translates to:
  /// **'Pick a color from the screen'**
  String get colorEyedropper;

  /// No description provided for @colorApply.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get colorApply;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'black'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'white'**
  String get colorWhite;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'gray'**
  String get colorGray;

  /// No description provided for @colorDarkGray.
  ///
  /// In en, this message translates to:
  /// **'dark gray {n}'**
  String colorDarkGray(int n);

  /// No description provided for @colorLightGray.
  ///
  /// In en, this message translates to:
  /// **'light gray {n}'**
  String colorLightGray(int n);

  /// No description provided for @colorLight.
  ///
  /// In en, this message translates to:
  /// **'light {hue} {n}'**
  String colorLight(String hue, int n);

  /// No description provided for @colorDark.
  ///
  /// In en, this message translates to:
  /// **'dark {hue} {n}'**
  String colorDark(String hue, int n);

  /// No description provided for @hueRedBerry.
  ///
  /// In en, this message translates to:
  /// **'red berry'**
  String get hueRedBerry;

  /// No description provided for @hueRed.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get hueRed;

  /// No description provided for @hueOrange.
  ///
  /// In en, this message translates to:
  /// **'orange'**
  String get hueOrange;

  /// No description provided for @hueYellow.
  ///
  /// In en, this message translates to:
  /// **'yellow'**
  String get hueYellow;

  /// No description provided for @hueGreen.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get hueGreen;

  /// No description provided for @hueCyan.
  ///
  /// In en, this message translates to:
  /// **'cyan'**
  String get hueCyan;

  /// No description provided for @hueCornflowerBlue.
  ///
  /// In en, this message translates to:
  /// **'cornflower blue'**
  String get hueCornflowerBlue;

  /// No description provided for @hueBlue.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get hueBlue;

  /// No description provided for @huePurple.
  ///
  /// In en, this message translates to:
  /// **'purple'**
  String get huePurple;

  /// No description provided for @hueMagenta.
  ///
  /// In en, this message translates to:
  /// **'magenta'**
  String get hueMagenta;

  /// No description provided for @panelCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse panel'**
  String get panelCollapse;

  /// No description provided for @panelClose.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get panelClose;

  /// No description provided for @panelResize.
  ///
  /// In en, this message translates to:
  /// **'Resize panel'**
  String get panelResize;

  /// No description provided for @treeExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get treeExpand;

  /// No description provided for @treeCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get treeCollapse;

  /// No description provided for @presenceEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get presenceEditing;

  /// No description provided for @presenceViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get presenceViewing;

  /// No description provided for @presenceIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get presenceIdle;

  /// No description provided for @presenceAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get presenceAway;

  /// No description provided for @presenceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get presenceOffline;

  /// No description provided for @presenceMore.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String presenceMore(int count);

  /// No description provided for @presenceMoreLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} more people'**
  String presenceMoreLabel(int count);

  /// No description provided for @presenceYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get presenceYou;

  /// No description provided for @presenceYouTabs.
  ///
  /// In en, this message translates to:
  /// **'You ({count} tabs)'**
  String presenceYouTabs(int count);

  /// No description provided for @presenceTabs.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count} tabs)'**
  String presenceTabs(String name, int count);

  /// No description provided for @presenceJumpTo.
  ///
  /// In en, this message translates to:
  /// **'Go to {name}\'s cursor'**
  String presenceJumpTo(String name);

  /// No description provided for @presenceFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get presenceFollow;

  /// No description provided for @presenceInFile.
  ///
  /// In en, this message translates to:
  /// **'In this file'**
  String get presenceInFile;

  /// No description provided for @stepperDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get stepperDecrease;

  /// No description provided for @stepperIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get stepperIncrease;

  /// No description provided for @tableSize.
  ///
  /// In en, this message translates to:
  /// **'{rows} × {columns}'**
  String tableSize(int rows, int columns);

  /// No description provided for @tableSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Insert a table with {rows} rows and {columns} columns'**
  String tableSizeLabel(int rows, int columns);

  /// No description provided for @fontRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get fontRecent;

  /// No description provided for @fontTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme fonts'**
  String get fontTheme;

  /// No description provided for @fontAll.
  ///
  /// In en, this message translates to:
  /// **'All fonts'**
  String get fontAll;

  /// No description provided for @fontSearch.
  ///
  /// In en, this message translates to:
  /// **'Search fonts'**
  String get fontSearch;

  /// No description provided for @fontNone.
  ///
  /// In en, this message translates to:
  /// **'No fonts found'**
  String get fontNone;

  /// No description provided for @syncSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get syncSaved;

  /// No description provided for @syncSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get syncSaving;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes saved on this device'**
  String get syncOffline;

  /// No description provided for @syncOfflineShort.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOfflineShort;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncError;

  /// No description provided for @syncConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get syncConnecting;

  /// No description provided for @syncReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting in {seconds} s…'**
  String syncReconnecting(int seconds);

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncPending(int count);

  /// No description provided for @syncDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncDetailsTitle;

  /// No description provided for @syncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get syncRetry;

  /// No description provided for @syncLog.
  ///
  /// In en, this message translates to:
  /// **'Recent events'**
  String get syncLog;

  /// No description provided for @syncNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No sync events yet.'**
  String get syncNoEvents;

  /// No description provided for @titleUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get titleUntitled;

  /// No description provided for @titleRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get titleRename;

  /// No description provided for @shortcutPress.
  ///
  /// In en, this message translates to:
  /// **'Press keys…'**
  String get shortcutPress;

  /// No description provided for @shortcutRecord.
  ///
  /// In en, this message translates to:
  /// **'Record shortcut'**
  String get shortcutRecord;

  /// No description provided for @shortcutClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get shortcutClear;

  /// No description provided for @shortcutNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get shortcutNone;

  /// No description provided for @shortcutCancelHint.
  ///
  /// In en, this message translates to:
  /// **'Press Esc to cancel'**
  String get shortcutCancelHint;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @scrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get scrollToTop;

  /// No description provided for @menuSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type to jump to an item'**
  String get menuSearchHint;

  /// Close button of the mobile presenter mode's top bar.
  ///
  /// In en, this message translates to:
  /// **'Exit presenter mode'**
  String get presenterExit;

  /// No description provided for @presenterPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous slide'**
  String get presenterPrevious;

  /// No description provided for @presenterNext.
  ///
  /// In en, this message translates to:
  /// **'Next slide'**
  String get presenterNext;

  /// No description provided for @presenterPosition.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String presenterPosition(int current, int total);

  /// No description provided for @presenterBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Presenter controls'**
  String get presenterBarLabel;
}

class _WonkyUiLocalizationsDelegate
    extends LocalizationsDelegate<WonkyUiLocalizations> {
  const _WonkyUiLocalizationsDelegate();

  @override
  Future<WonkyUiLocalizations> load(Locale locale) {
    return SynchronousFuture<WonkyUiLocalizations>(
      lookupWonkyUiLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_WonkyUiLocalizationsDelegate old) => false;
}

WonkyUiLocalizations lookupWonkyUiLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return WonkyUiLocalizationsEn();
  }

  throw FlutterError(
    'WonkyUiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
