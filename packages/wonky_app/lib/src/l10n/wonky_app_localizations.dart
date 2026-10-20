import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'wonky_app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of WonkyAppLocalizations
/// returned by `WonkyAppLocalizations.of(context)`.
///
/// Applications need to include `WonkyAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/wonky_app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: WonkyAppLocalizations.localizationsDelegates,
///   supportedLocales: WonkyAppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the WonkyAppLocalizations.supportedLocales
/// property.
abstract class WonkyAppLocalizations {
  WonkyAppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static WonkyAppLocalizations of(BuildContext context) {
    return Localizations.of<WonkyAppLocalizations>(
      context,
      WonkyAppLocalizations,
    )!;
  }

  static const LocalizationsDelegate<WonkyAppLocalizations> delegate =
      _WonkyAppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ];

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get aboutAppVersion;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get aboutProtocol;

  /// No description provided for @aboutRunMode.
  ///
  /// In en, this message translates to:
  /// **'Server mode'**
  String get aboutRunMode;

  /// No description provided for @aboutServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get aboutServerVersion;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountMenu;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get actionReload;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @activityCommented.
  ///
  /// In en, this message translates to:
  /// **'{who} commented'**
  String activityCommented(String who);

  /// No description provided for @activityCreated.
  ///
  /// In en, this message translates to:
  /// **'{who} created this'**
  String activityCreated(String who);

  /// No description provided for @activityEdited.
  ///
  /// In en, this message translates to:
  /// **'{who} edited'**
  String activityEdited(String who);

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get activityEmpty;

  /// No description provided for @activityExported.
  ///
  /// In en, this message translates to:
  /// **'{who} exported'**
  String activityExported(String who);

  /// No description provided for @activityMoved.
  ///
  /// In en, this message translates to:
  /// **'{who} moved this'**
  String activityMoved(String who);

  /// No description provided for @activityRenamed.
  ///
  /// In en, this message translates to:
  /// **'{who} renamed this'**
  String activityRenamed(String who);

  /// No description provided for @activityRestored.
  ///
  /// In en, this message translates to:
  /// **'{who} restored this from the trash'**
  String activityRestored(String who);

  /// No description provided for @activityRestoredVersion.
  ///
  /// In en, this message translates to:
  /// **'{who} restored a version'**
  String activityRestoredVersion(String who);

  /// No description provided for @activityShared.
  ///
  /// In en, this message translates to:
  /// **'{who} shared this'**
  String activityShared(String who);

  /// No description provided for @activitySystem.
  ///
  /// In en, this message translates to:
  /// **'Wonky Work'**
  String get activitySystem;

  /// No description provided for @activityTrashed.
  ///
  /// In en, this message translates to:
  /// **'{who} moved this to the trash'**
  String activityTrashed(String who);

  /// No description provided for @activityUnshared.
  ///
  /// In en, this message translates to:
  /// **'{who} removed access'**
  String activityUnshared(String who);

  /// No description provided for @activityUploaded.
  ///
  /// In en, this message translates to:
  /// **'{who} uploaded this'**
  String activityUploaded(String who);

  /// No description provided for @addShortcutAction.
  ///
  /// In en, this message translates to:
  /// **'Add shortcut'**
  String get addShortcutAction;

  /// No description provided for @addShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Add shortcut to My Drive'**
  String get addShortcutTitle;

  /// No description provided for @agentUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'AI: {label}'**
  String agentUndoLabel(String label);

  /// No description provided for @aiEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable the assistant'**
  String get aiEnable;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authBackToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Back to sign up'**
  String get authBackToSignUp;

  /// No description provided for @authChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get authChangeEmail;

  /// No description provided for @authCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get authCodeResent;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authDisplayName;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authErrorCodeLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get authErrorCodeLength;

  /// No description provided for @authErrorEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authErrorEmail;

  /// No description provided for @authErrorExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one.'**
  String get authErrorExpiredCode;

  /// No description provided for @authErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Check it and try again.'**
  String get authErrorInvalidCode;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get authErrorPasswordMismatch;

  /// No description provided for @authErrorPasswordPolicy.
  ///
  /// In en, this message translates to:
  /// **'This password doesn\'t meet the requirements. Choose a longer or more varied password.'**
  String get authErrorPasswordPolicy;

  /// No description provided for @authErrorPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get authErrorPasswordShort;

  /// No description provided for @authErrorPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'This password is too easy to guess.'**
  String get authErrorPasswordWeak;

  /// No description provided for @authErrorTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms to continue.'**
  String get authErrorTerms;

  /// No description provided for @authErrorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get authErrorTooManyAttempts;

  /// Google sign-in button on the sign-in and sign-up screens (Google's branding wording).
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Divider between the Google button and the email form.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// Under the Google button on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'By continuing with Google, you agree to the terms of service and the privacy policy.'**
  String get authGoogleTerms;

  /// No description provided for @authErrorGoogleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google isn\'t set up on this server.'**
  String get authErrorGoogleUnavailable;

  /// No description provided for @authErrorPopupBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your browser blocked the Google sign-in window. Allow pop-ups for this site and try again.'**
  String get authErrorPopupBlocked;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get authNewPasswordSubtitle;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Wonky Work?'**
  String get authNoAccount;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get authRememberMe;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds} s'**
  String authResendIn(int seconds);

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a code to reset your password.'**
  String get authResetSubtitle;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetTitle;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set password and sign in'**
  String get authSetPassword;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account for every Wonky Work app.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create one account for every Wonky Work app.'**
  String get authSignUpSubtitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms of service and privacy policy'**
  String get authTerms;

  /// Link under the sign-up agreement checkbox; opens the terms page.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get authTermsLink;

  /// Link under the sign-up agreement checkbox; opens the privacy policy page.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get authPrivacyLink;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authVerifyNoDraft.
  ///
  /// In en, this message translates to:
  /// **'Start the sign-up again to get a new code.'**
  String get authVerifyNoDraft;

  /// No description provided for @authVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String authVerifySubtitle(String email);

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authVerifyTitle;

  /// No description provided for @badgeCommentOnly.
  ///
  /// In en, this message translates to:
  /// **'Comment only'**
  String get badgeCommentOnly;

  /// No description provided for @badgeOffline.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get badgeOffline;

  /// No description provided for @badgeShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get badgeShared;

  /// No description provided for @badgeViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get badgeViewOnly;

  /// No description provided for @categoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get categoryAccount;

  /// No description provided for @categoryComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get categoryComments;

  /// No description provided for @categoryDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get categoryDrive;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get categoryEdit;

  /// No description provided for @categoryFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get categoryFile;

  /// No description provided for @categoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get categoryHelp;

  /// No description provided for @categoryNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get categoryNavigation;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categorySharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get categorySharing;

  /// No description provided for @categoryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get categoryTools;

  /// No description provided for @categoryVersions.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get categoryVersions;

  /// No description provided for @categoryView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get categoryView;

  /// No description provided for @cmdAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get cmdAbout;

  /// No description provided for @cmdAddShortcut.
  ///
  /// In en, this message translates to:
  /// **'Add shortcut to Drive'**
  String get cmdAddShortcut;

  /// Opens the current app's settings, e.g. 'Write settings'.
  ///
  /// In en, this message translates to:
  /// **'{app} settings'**
  String cmdAppSettings(String app);

  /// No description provided for @cmdAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get cmdAssistant;

  /// No description provided for @cmdAssistantNewThread.
  ///
  /// In en, this message translates to:
  /// **'New assistant chat'**
  String get cmdAssistantNewThread;

  /// No description provided for @cmdAssistantSend.
  ///
  /// In en, this message translates to:
  /// **'Send to assistant'**
  String get cmdAssistantSend;

  /// No description provided for @cmdAssistantStop.
  ///
  /// In en, this message translates to:
  /// **'Stop assistant'**
  String get cmdAssistantStop;

  /// No description provided for @cmdBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cmdBack;

  /// No description provided for @cmdClosePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get cmdClosePanel;

  /// No description provided for @cmdCommandPalette.
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get cmdCommandPalette;

  /// No description provided for @cmdComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get cmdComment;

  /// No description provided for @cmdCommentsPanel.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get cmdCommentsPanel;

  /// No description provided for @cmdCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cmdCopy;

  /// No description provided for @cmdCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get cmdCopyLink;

  /// No description provided for @cmdCopyMcpConfig.
  ///
  /// In en, this message translates to:
  /// **'Copy MCP connection settings'**
  String get cmdCopyMcpConfig;

  /// No description provided for @cmdCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cmdCut;

  /// No description provided for @cmdDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get cmdDeleteComment;

  /// No description provided for @cmdDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get cmdDeleteForever;

  /// No description provided for @cmdDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get cmdDetails;

  /// No description provided for @cmdDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get cmdDownload;

  /// No description provided for @cmdEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get cmdEmptyTrash;

  /// No description provided for @cmdFocusSearch.
  ///
  /// In en, this message translates to:
  /// **'Search in Drive'**
  String get cmdFocusSearch;

  /// No description provided for @cmdForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get cmdForward;

  /// No description provided for @cmdHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get cmdHome;

  /// No description provided for @cmdImport.
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get cmdImport;

  /// No description provided for @cmdKeyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get cmdKeyboardShortcuts;

  /// No description provided for @cmdMakeAvailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Make available offline'**
  String get cmdMakeAvailableOffline;

  /// No description provided for @cmdMakeCopy.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get cmdMakeCopy;

  /// Opens Wonky Drive's Storage page.
  ///
  /// In en, this message translates to:
  /// **'Manage storage'**
  String get cmdManageStorage;

  /// No description provided for @cmdMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get cmdMove;

  /// No description provided for @cmdMoveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get cmdMoveToTrash;

  /// No description provided for @cmdNameCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Name current version'**
  String get cmdNameCurrentVersion;

  /// No description provided for @cmdNewDocument.
  ///
  /// In en, this message translates to:
  /// **'New document'**
  String get cmdNewDocument;

  /// No description provided for @cmdNewFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get cmdNewFile;

  /// No description provided for @cmdNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get cmdNewFolder;

  /// No description provided for @cmdNewFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From template…'**
  String get cmdNewFromTemplate;

  /// No description provided for @cmdNewSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'New spreadsheet'**
  String get cmdNewSpreadsheet;

  /// No description provided for @cmdNextPanel.
  ///
  /// In en, this message translates to:
  /// **'Next panel'**
  String get cmdNextPanel;

  /// No description provided for @cmdNextRegion.
  ///
  /// In en, this message translates to:
  /// **'Focus next region'**
  String get cmdNextRegion;

  /// No description provided for @cmdOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get cmdOpen;

  /// No description provided for @cmdOpenComment.
  ///
  /// In en, this message translates to:
  /// **'Open comment'**
  String get cmdOpenComment;

  /// No description provided for @cmdOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open…'**
  String get cmdOpenFile;

  /// Opens the current folder or view in Wonky Drive (app homes).
  ///
  /// In en, this message translates to:
  /// **'Open in Wonky Drive'**
  String get cmdOpenInDrive;

  /// No description provided for @cmdOpenPanel.
  ///
  /// In en, this message translates to:
  /// **'Open panel'**
  String get cmdOpenPanel;

  /// No description provided for @cmdOpenSheets.
  ///
  /// In en, this message translates to:
  /// **'Open Wonky Sheets'**
  String get cmdOpenSheets;

  /// No description provided for @cmdOpenWrite.
  ///
  /// In en, this message translates to:
  /// **'Open Wonky Write'**
  String get cmdOpenWrite;

  /// No description provided for @cmdPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get cmdPaste;

  /// No description provided for @cmdPastePlain.
  ///
  /// In en, this message translates to:
  /// **'Paste without formatting'**
  String get cmdPastePlain;

  /// No description provided for @cmdPreviousPanel.
  ///
  /// In en, this message translates to:
  /// **'Previous panel'**
  String get cmdPreviousPanel;

  /// No description provided for @cmdPreviousRegion.
  ///
  /// In en, this message translates to:
  /// **'Focus previous region'**
  String get cmdPreviousRegion;

  /// No description provided for @cmdPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get cmdPrint;

  /// No description provided for @cmdQuickSwitcher.
  ///
  /// In en, this message translates to:
  /// **'Go to file…'**
  String get cmdQuickSwitcher;

  /// No description provided for @cmdRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get cmdRedo;

  /// No description provided for @cmdRedoLabel.
  ///
  /// In en, this message translates to:
  /// **'Redo {label}'**
  String cmdRedoLabel(String label);

  /// No description provided for @cmdRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get cmdRename;

  /// No description provided for @cmdReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get cmdReopen;

  /// No description provided for @cmdReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get cmdReply;

  /// Opens a prefilled GitHub issue form (after a confirm).
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get cmdReportBug;

  /// No description provided for @cmdReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get cmdReportProblem;

  /// No description provided for @cmdRequestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get cmdRequestAccess;

  /// No description provided for @cmdResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get cmdResolve;

  /// No description provided for @cmdRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get cmdRestore;

  /// No description provided for @cmdRestoreVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get cmdRestoreVersion;

  /// No description provided for @cmdSeeVersionHistory.
  ///
  /// In en, this message translates to:
  /// **'See version history'**
  String get cmdSeeVersionHistory;

  /// No description provided for @cmdSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cmdSelectAll;

  /// No description provided for @cmdSetDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit description'**
  String get cmdSetDescription;

  /// No description provided for @cmdSetTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get cmdSetTheme;

  /// No description provided for @cmdSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get cmdSettings;

  /// No description provided for @cmdShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get cmdShare;

  /// No description provided for @cmdSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get cmdSignOut;

  /// No description provided for @cmdStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get cmdStar;

  /// No description provided for @cmdStopAgent.
  ///
  /// In en, this message translates to:
  /// **'Stop agent control'**
  String get cmdStopAgent;

  /// No description provided for @cmdTogglePanel.
  ///
  /// In en, this message translates to:
  /// **'Toggle panel'**
  String get cmdTogglePanel;

  /// No description provided for @cmdToggleUiBridge.
  ///
  /// In en, this message translates to:
  /// **'Allow MCP to control this window'**
  String get cmdToggleUiBridge;

  /// No description provided for @cmdUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get cmdUndo;

  /// No description provided for @cmdUndoHistory.
  ///
  /// In en, this message translates to:
  /// **'Undo history…'**
  String get cmdUndoHistory;

  /// No description provided for @cmdUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo {label}'**
  String cmdUndoLabel(String label);

  /// No description provided for @cmdUndoTo.
  ///
  /// In en, this message translates to:
  /// **'Undo to step'**
  String get cmdUndoTo;

  /// No description provided for @cmdUnstar.
  ///
  /// In en, this message translates to:
  /// **'Remove star'**
  String get cmdUnstar;

  /// No description provided for @cmdUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload file…'**
  String get cmdUpload;

  /// No description provided for @cmdVersionsPanel.
  ///
  /// In en, this message translates to:
  /// **'Version history panel'**
  String get cmdVersionsPanel;

  /// No description provided for @cmdWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get cmdWhatsNew;

  /// Opens the suite settings (account, appearance, …).
  ///
  /// In en, this message translates to:
  /// **'Wonky Work settings'**
  String get cmdWorkSettings;

  /// No description provided for @cmdZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get cmdZoom;

  /// No description provided for @collapseFolders.
  ///
  /// In en, this message translates to:
  /// **'Collapse folders'**
  String get collapseFolders;

  /// No description provided for @columnModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get columnModified;

  /// No description provided for @columnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get columnName;

  /// No description provided for @columnOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get columnOwner;

  /// No description provided for @columnSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get columnSize;

  /// No description provided for @commandFailed.
  ///
  /// In en, this message translates to:
  /// **'“{title}” failed'**
  String commandFailed(String title);

  /// No description provided for @commentAction.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentAction;

  /// No description provided for @commentAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign to {name}'**
  String commentAssign(String name);

  /// No description provided for @commentDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commentDelete;

  /// No description provided for @commentDeleteThread.
  ///
  /// In en, this message translates to:
  /// **'Delete thread'**
  String get commentDeleteThread;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

  /// No description provided for @commentEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commentEdit;

  /// No description provided for @commentEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get commentEdited;

  /// No description provided for @commentEventAssigned.
  ///
  /// In en, this message translates to:
  /// **'assigned the comment'**
  String get commentEventAssigned;

  /// No description provided for @commentEventOrphaned.
  ///
  /// In en, this message translates to:
  /// **'deleted the commented content'**
  String get commentEventOrphaned;

  /// No description provided for @commentEventOrphanedBySystem.
  ///
  /// In en, this message translates to:
  /// **'The commented content was deleted'**
  String get commentEventOrphanedBySystem;

  /// No description provided for @commentEventRestoredBySystem.
  ///
  /// In en, this message translates to:
  /// **'The commented content was restored'**
  String get commentEventRestoredBySystem;

  /// No description provided for @commentEventReopened.
  ///
  /// In en, this message translates to:
  /// **'reopened'**
  String get commentEventReopened;

  /// No description provided for @commentEventResolved.
  ///
  /// In en, this message translates to:
  /// **'marked as resolved'**
  String get commentEventResolved;

  /// No description provided for @commentEventSuggestionAccepted.
  ///
  /// In en, this message translates to:
  /// **'accepted the suggestion'**
  String get commentEventSuggestionAccepted;

  /// No description provided for @commentEventSuggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'rejected the suggestion'**
  String get commentEventSuggestionRejected;

  /// No description provided for @commentEventSuggestionReopened.
  ///
  /// In en, this message translates to:
  /// **'reopened the suggestion'**
  String get commentEventSuggestionReopened;

  /// No description provided for @commentEventSuggestionSuperseded.
  ///
  /// In en, this message translates to:
  /// **'replaced the suggestion'**
  String get commentEventSuggestionSuperseded;

  /// No description provided for @commentEventSuggestionWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'withdrew the suggestion'**
  String get commentEventSuggestionWithdrawn;

  /// No description provided for @commentFailed.
  ///
  /// In en, this message translates to:
  /// **'The comment could not be saved'**
  String get commentFailed;

  /// No description provided for @commentPending.
  ///
  /// In en, this message translates to:
  /// **'Pending — will be posted when you\'re online'**
  String get commentPending;

  /// No description provided for @commentLink.
  ///
  /// In en, this message translates to:
  /// **'Link to comment'**
  String get commentLink;

  /// No description provided for @commentOrphaned.
  ///
  /// In en, this message translates to:
  /// **'Original content deleted'**
  String get commentOrphaned;

  /// No description provided for @commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Comment or add others with @'**
  String get commentPlaceholder;

  /// No description provided for @commentShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get commentShow;

  /// No description provided for @commentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Select content and press {shortcut} to add a comment.'**
  String commentsEmptyBody(String shortcut);

  /// No description provided for @commentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get commentsEmptyTitle;

  /// No description provided for @commentsForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get commentsForYou;

  /// No description provided for @commentsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commentsOpen;

  /// No description provided for @commentsSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get commentsSort;

  /// No description provided for @commentsSortDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by date'**
  String get commentsSortDate;

  /// No description provided for @commentsSortPosition.
  ///
  /// In en, this message translates to:
  /// **'Sort by position'**
  String get commentsSortPosition;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get copyAction;

  /// No description provided for @copyComments.
  ///
  /// In en, this message translates to:
  /// **'Copy comments'**
  String get copyComments;

  /// No description provided for @copyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get copyName;

  /// No description provided for @copyOfName.
  ///
  /// In en, this message translates to:
  /// **'Copy of {name}'**
  String copyOfName(String name);

  /// No description provided for @copySharing.
  ///
  /// In en, this message translates to:
  /// **'Share it with the same people'**
  String get copySharing;

  /// No description provided for @copyTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get copyTitle;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account {email}. This cannot be undone.'**
  String deleteAccountBody(String email);

  /// No description provided for @deleteAccountConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Type {email} to confirm'**
  String deleteAccountConfirmLabel(String email);

  /// No description provided for @deleteAccountCounts.
  ///
  /// In en, this message translates to:
  /// **'You own {documents} documents, {spreadsheets} spreadsheets and {folders} folders.'**
  String deleteAccountCounts(int documents, int spreadsheets, int folders);

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Delete your account and the files you own.'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'That\'s not your email address.'**
  String get deleteAccountMismatch;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteForeverAction.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForeverAction;

  /// No description provided for @deleteForeverBody.
  ///
  /// In en, this message translates to:
  /// **'These items will be deleted permanently. This can\'t be undone.'**
  String get deleteForeverBody;

  /// No description provided for @deleteForeverTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete forever?} other{Delete {count} items forever?}}'**
  String deleteForeverTitle(int count);

  /// No description provided for @densityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get densityComfortable;

  /// No description provided for @densityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get densityCompact;

  /// No description provided for @detailsAccess.
  ///
  /// In en, this message translates to:
  /// **'Who has access'**
  String get detailsAccess;

  /// No description provided for @detailsActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get detailsActivity;

  /// No description provided for @detailsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get detailsCreated;

  /// No description provided for @detailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailsDescription;

  /// No description provided for @detailsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get detailsDescriptionHint;

  /// No description provided for @detailsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get detailsLocation;

  /// No description provided for @detailsModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get detailsModified;

  /// No description provided for @detailsNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a file to see its details'**
  String get detailsNothingSelected;

  /// No description provided for @detailsOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened by me'**
  String get detailsOpened;

  /// No description provided for @detailsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get detailsOwner;

  /// No description provided for @detailsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private to you'**
  String get detailsPrivate;

  /// No description provided for @detailsRole.
  ///
  /// In en, this message translates to:
  /// **'Your access'**
  String get detailsRole;

  /// No description provided for @detailsShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get detailsShared;

  /// No description provided for @detailsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailsType;

  /// No description provided for @driveListLabel.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get driveListLabel;

  /// No description provided for @driveOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Files you opened recently or made available offline are listed when you\'re offline.'**
  String get driveOfflineBody;

  /// No description provided for @driveOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get driveOfflineTitle;

  /// No description provided for @dropToUpload.
  ///
  /// In en, this message translates to:
  /// **'Drop files to upload'**
  String get dropToUpload;

  /// No description provided for @editorOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t available offline'**
  String get editorOfflineTitle;

  /// No description provided for @emptyFolderBody.
  ///
  /// In en, this message translates to:
  /// **'Drop files here or use the New button.'**
  String get emptyFolderBody;

  /// No description provided for @emptyFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolderTitle;

  /// No description provided for @emptyHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Create a document or open one shared with you.'**
  String get emptyHomeBody;

  /// No description provided for @emptyHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your drive'**
  String get emptyHomeTitle;

  /// Empty state of a scoped home (v2): the app's product name, e.g. Wonky Write.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String emptyAppHomeTitle(String appName);

  /// Empty state of a scoped home (v2) by the kind it lists; all = Wonky Drive.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, spreadsheet{Create a spreadsheet or open one shared with you.} presentation{Create a presentation or open one shared with you.} all{Create a document, spreadsheet or presentation, or upload files.} other{Create a document or open one shared with you.}}'**
  String emptyAppHomeBody(String kind);

  /// No description provided for @emptyOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Use “Make available offline” on files you need without a connection.'**
  String get emptyOfflineBody;

  /// No description provided for @emptyOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No offline files'**
  String get emptyOfflineTitle;

  /// No description provided for @emptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Try other words or fewer filters.'**
  String get emptySearchBody;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get emptySearchTitle;

  /// No description provided for @emptySharedBody.
  ///
  /// In en, this message translates to:
  /// **'Files others share with you will show up here.'**
  String get emptySharedBody;

  /// No description provided for @emptySharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared with you yet'**
  String get emptySharedTitle;

  /// No description provided for @emptyStarredBody.
  ///
  /// In en, this message translates to:
  /// **'Add stars to things you want to find easily later.'**
  String get emptyStarredBody;

  /// No description provided for @emptyStarredTitle.
  ///
  /// In en, this message translates to:
  /// **'No starred files yet'**
  String get emptyStarredTitle;

  /// No description provided for @emptyTrashAction.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrashAction;

  /// No description provided for @emptyTrashBody.
  ///
  /// In en, this message translates to:
  /// **'All items in the trash will be deleted forever. This can\'t be undone.'**
  String get emptyTrashBody;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrashViewBody.
  ///
  /// In en, this message translates to:
  /// **'Items in the trash are deleted forever after 30 days.'**
  String get emptyTrashViewBody;

  /// No description provided for @emptyTrashViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get emptyTrashViewTitle;

  /// No description provided for @errorBoundaryBody.
  ///
  /// In en, this message translates to:
  /// **'This part of the app hit an unexpected error. Your work is saved.'**
  String get errorBoundaryBody;

  /// No description provided for @errorBoundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorBoundaryTitle;

  /// No description provided for @errorCopyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy error details'**
  String get errorCopyDetails;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorNameSlash.
  ///
  /// In en, this message translates to:
  /// **'Names can\'t contain “/”.'**
  String get errorNameSlash;

  /// No description provided for @errorNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use at most 255 characters.'**
  String get errorNameTooLong;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get errorRequired;

  /// No description provided for @expandFolders.
  ///
  /// In en, this message translates to:
  /// **'Expand folders'**
  String get expandFolders;

  /// Confirm button: open the external link in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get externalLinkOpen;

  /// Title of the confirm before opening a link outside Wonky Work.
  ///
  /// In en, this message translates to:
  /// **'Open external link?'**
  String get externalLinkTitle;

  /// Type filter (Drive): ZIP and other archives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get fileCategoryArchives;

  /// Type filter (Drive): audio files.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get fileCategoryAudio;

  /// Type filter (Drive): image files.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get fileCategoryImages;

  /// Type filter (Drive): files of any other type.
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get fileCategoryOther;

  /// Type filter (Drive): PDF files.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get fileCategoryPdfs;

  /// Type filter (Drive): text and source files.
  ///
  /// In en, this message translates to:
  /// **'Text & code'**
  String get fileCategoryText;

  /// Type filter (Drive): video files.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get fileCategoryVideo;

  /// No description provided for @folderTree.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folderTree;

  /// No description provided for @foldersOnTop.
  ///
  /// In en, this message translates to:
  /// **'Folders on top'**
  String get foldersOnTop;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goHome;

  /// No description provided for @groupEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get groupEarlier;

  /// No description provided for @groupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Earlier this week'**
  String get groupThisWeek;

  /// No description provided for @groupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get groupToday;

  /// No description provided for @groupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get groupYesterday;

  /// No description provided for @historyBack.
  ///
  /// In en, this message translates to:
  /// **'Back to editing'**
  String get historyBack;

  /// No description provided for @historyNoRenderer.
  ///
  /// In en, this message translates to:
  /// **'Previews of versions aren\'t available for this file type.'**
  String get historyNoRenderer;

  /// No description provided for @historyRestoreThis.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get historyRestoreThis;

  /// No description provided for @historyShowChanges.
  ///
  /// In en, this message translates to:
  /// **'Show changes'**
  String get historyShowChanges;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'The import failed'**
  String get importFailed;

  /// No description provided for @importUnsupported.
  ///
  /// In en, this message translates to:
  /// **'These files can\'t be imported here'**
  String get importUnsupported;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link is not valid'**
  String get inviteInvalid;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening shared file'**
  String get inviteTitle;

  /// No description provided for @kindDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get kindDocument;

  /// No description provided for @kindFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get kindFile;

  /// No description provided for @kindFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get kindFolder;

  /// No description provided for @kindPresentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get kindPresentation;

  /// No description provided for @kindSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get kindSpreadsheet;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get layoutGrid;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get layoutList;

  /// No description provided for @mcpAllowControl.
  ///
  /// In en, this message translates to:
  /// **'Allow MCP to control this window'**
  String get mcpAllowControl;

  /// No description provided for @mcpControlling.
  ///
  /// In en, this message translates to:
  /// **'An agent is controlling this window'**
  String get mcpControlling;

  /// No description provided for @mcpHint.
  ///
  /// In en, this message translates to:
  /// **'Use this configuration in Claude Desktop or Claude Code with one of your tokens.'**
  String get mcpHint;

  /// No description provided for @mcpTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP connection'**
  String get mcpTitle;

  /// No description provided for @menuAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility settings'**
  String get menuAccessibility;

  /// No description provided for @menuAppTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get menuAppTheme;

  /// No description provided for @menuDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get menuDownload;

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// No description provided for @menuExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get menuExplore;

  /// No description provided for @menuFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menuFile;

  /// New menu (Drive): upload files.
  ///
  /// In en, this message translates to:
  /// **'File upload'**
  String get menuFileUpload;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// New menu of app homes (v2): import a file of the app's convertible types as a new item.
  ///
  /// In en, this message translates to:
  /// **'Import file…'**
  String get menuImportFile;

  /// No description provided for @menuMakeCopy.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get menuMakeCopy;

  /// No description provided for @menuMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get menuMode;

  /// No description provided for @menuNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get menuNew;

  /// No description provided for @menuNewDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get menuNewDocument;

  /// New menu: a new Wonky Slides presentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get menuNewPresentation;

  /// No description provided for @menuNewSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get menuNewSpreadsheet;

  /// Account menu submenu listing the four apps.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get menuOpenApp;

  /// No description provided for @menuPanels.
  ///
  /// In en, this message translates to:
  /// **'Panels'**
  String get menuPanels;

  /// No description provided for @menuPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get menuPreferences;

  /// No description provided for @menuShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get menuShare;

  /// No description provided for @menuTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get menuTools;

  /// No description provided for @menuVersionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get menuVersionHistory;

  /// No description provided for @menuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// No description provided for @menuZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get menuZoom;

  /// No description provided for @menus.
  ///
  /// In en, this message translates to:
  /// **'Menus'**
  String get menus;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @moveHere.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get moveHere;

  /// No description provided for @moveNoFolders.
  ///
  /// In en, this message translates to:
  /// **'No folders here'**
  String get moveNoFolders;

  /// No description provided for @moveNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to add items to this folder.'**
  String get moveNoPermission;

  /// No description provided for @moveTitleMany.
  ///
  /// In en, this message translates to:
  /// **'Move {count} items'**
  String moveTitleMany(int count);

  /// No description provided for @moveTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Move “{name}”'**
  String moveTitleOne(String name);

  /// No description provided for @nameVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version name'**
  String get nameVersionLabel;

  /// No description provided for @nameVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this version'**
  String get nameVersionTitle;

  /// Semantics label of the left menu's app section.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get navApps;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyDrive.
  ///
  /// In en, this message translates to:
  /// **'My Drive'**
  String get navMyDrive;

  /// Left menu of app homes: the root of the user's drive.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get navMyFiles;

  /// No description provided for @navOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get navOffline;

  /// No description provided for @navRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get navRecent;

  /// No description provided for @navShared.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get navShared;

  /// No description provided for @navStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get navStarred;

  /// Left menu (Drive): the Storage page; storage meter label.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get navStorage;

  /// No description provided for @navTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get navTrash;

  /// No description provided for @newButton.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newButton;

  /// No description provided for @newFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get newFolderLabel;

  /// No description provided for @newFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolderTitle;

  /// No description provided for @noAccessBody.
  ///
  /// In en, this message translates to:
  /// **'You need access to open this file. You\'re signed in as {email}.'**
  String noAccessBody(String email);

  /// No description provided for @noAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You need access'**
  String get noAccessTitle;

  /// No description provided for @notAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notAllowed;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The page you\'re looking for doesn\'t exist.'**
  String get notFoundBody;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notifAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'{who} asked for access to {item}'**
  String notifAccessRequest(String who, String item);

  /// No description provided for @notifAssigned.
  ///
  /// In en, this message translates to:
  /// **'{who} assigned you a comment in {item}'**
  String notifAssigned(String who, String item);

  /// No description provided for @notifMention.
  ///
  /// In en, this message translates to:
  /// **'{who} mentioned you in {item}'**
  String notifMention(String who, String item);

  /// No description provided for @notifOwnership.
  ///
  /// In en, this message translates to:
  /// **'{who} wants to make you the owner of {item}'**
  String notifOwnership(String who, String item);

  /// No description provided for @notifReply.
  ///
  /// In en, this message translates to:
  /// **'{who} replied in {item}'**
  String notifReply(String who, String item);

  /// No description provided for @notifScriptFailure.
  ///
  /// In en, this message translates to:
  /// **'A script failed in {item}'**
  String notifScriptFailure(String item);

  /// No description provided for @notifShared.
  ///
  /// In en, this message translates to:
  /// **'{who} shared {item} with you'**
  String notifShared(String who, String item);

  /// No description provided for @notifStorage.
  ///
  /// In en, this message translates to:
  /// **'Your Wonky Work storage needs attention'**
  String get notifStorage;

  /// No description provided for @notifBoardReply.
  ///
  /// In en, this message translates to:
  /// **'{who} commented on “{title}”'**
  String notifBoardReply(String who, String title);

  /// No description provided for @notifBoardUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update on “{title}”'**
  String notifBoardUpdate(String title);

  /// No description provided for @notifSuggestion.
  ///
  /// In en, this message translates to:
  /// **'{who} suggested an edit in {item}'**
  String notifSuggestion(String who, String item);

  /// No description provided for @notifSuggestionDecided.
  ///
  /// In en, this message translates to:
  /// **'{who} reviewed your suggestion in {item}'**
  String notifSuggestionDecided(String who, String item);

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread notification} other{{count} unread notifications}}'**
  String notificationsUnread(int count);

  /// No description provided for @notifyEmail.
  ///
  /// In en, this message translates to:
  /// **'In-app and email'**
  String get notifyEmail;

  /// No description provided for @notifyInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app'**
  String get notifyInApp;

  /// No description provided for @notifyMentions.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get notifyMentions;

  /// No description provided for @notifyOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifyOff;

  /// No description provided for @notifyReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies to my comments'**
  String get notifyReplies;

  /// No description provided for @notifyShares.
  ///
  /// In en, this message translates to:
  /// **'Files shared with me'**
  String get notifyShares;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes are saved on this device and will sync when you\'re back online.'**
  String get offlineBanner;

  /// No description provided for @offlineClear.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get offlineClear;

  /// No description provided for @offlineClearHint.
  ///
  /// In en, this message translates to:
  /// **'Removes cached files and pending changes from this device.'**
  String get offlineClearHint;

  /// No description provided for @offlineCleared.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared'**
  String get offlineCleared;

  /// No description provided for @offlinePending.
  ///
  /// In en, this message translates to:
  /// **'Changes waiting to sync'**
  String get offlinePending;

  /// No description provided for @badgeOfflineRecent.
  ///
  /// In en, this message translates to:
  /// **'Available offline (opened recently)'**
  String get badgeOfflineRecent;

  /// No description provided for @badgeOfflinePending.
  ///
  /// In en, this message translates to:
  /// **'Downloading for offline use…'**
  String get badgeOfflinePending;

  /// No description provided for @offlineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t available offline'**
  String get offlineUnavailable;

  /// No description provided for @offlineDocuments.
  ///
  /// In en, this message translates to:
  /// **'Files on this device'**
  String get offlineDocuments;

  /// No description provided for @offlineDocumentsValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None} =1{1 file} other{{count} files}}'**
  String offlineDocumentsValue(int count);

  /// No description provided for @offlinePinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files made available offline} =1{1 made available offline} other{{count} made available offline}}'**
  String offlinePinnedCount(int count);

  /// No description provided for @offlineUploads.
  ///
  /// In en, this message translates to:
  /// **'Images waiting to upload'**
  String get offlineUploads;

  /// No description provided for @offlineStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get offlineStorageUsed;

  /// No description provided for @offlineClearUnsynced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change hasn\'t synced yet and will be lost.} other{{count} changes haven\'t synced yet and will be lost.}}'**
  String offlineClearUnsynced(int count);

  /// No description provided for @offlineSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate offline'**
  String get offlineSimulate;

  /// No description provided for @offlineSimulateHint.
  ///
  /// In en, this message translates to:
  /// **'Disconnects from the server to try offline editing (developer setting).'**
  String get offlineSimulateHint;

  /// No description provided for @ownerAnyone.
  ///
  /// In en, this message translates to:
  /// **'Owned by anyone'**
  String get ownerAnyone;

  /// No description provided for @ownerMe.
  ///
  /// In en, this message translates to:
  /// **'me'**
  String get ownerMe;

  /// No description provided for @ownerMeFilter.
  ///
  /// In en, this message translates to:
  /// **'Owned by me'**
  String get ownerMeFilter;

  /// No description provided for @ownerNotMe.
  ///
  /// In en, this message translates to:
  /// **'Not owned by me'**
  String get ownerNotMe;

  /// No description provided for @paletteAllCommands.
  ///
  /// In en, this message translates to:
  /// **'All commands'**
  String get paletteAllCommands;

  /// No description provided for @paletteCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get paletteCommands;

  /// No description provided for @paletteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get paletteEmpty;

  /// No description provided for @paletteFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get paletteFiles;

  /// No description provided for @paletteGoToFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get paletteGoToFile;

  /// No description provided for @palettePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a command or search files…'**
  String get palettePlaceholder;

  /// No description provided for @paletteRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get paletteRecent;

  /// No description provided for @panelComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get panelComments;

  /// No description provided for @panelHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get panelHistory;

  /// No description provided for @presenceJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String presenceJoined(String name);

  /// No description provided for @presenceLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String presenceLeft(String name);

  /// No description provided for @quickSwitcherEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get quickSwitcherEmpty;

  /// No description provided for @quickSwitcherPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search documents and spreadsheets…'**
  String get quickSwitcherPlaceholder;

  /// No description provided for @quickSwitcherRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get quickSwitcherRecent;

  /// No description provided for @quickSwitcherResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get quickSwitcherResults;

  /// No description provided for @renameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get renameLabel;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameTitle;

  /// No description provided for @replyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Reply or add others with @'**
  String get replyPlaceholder;

  /// Shown in the confirm before opening the GitHub issue form.
  ///
  /// In en, this message translates to:
  /// **'Issues on GitHub are public: don\'t include private content.'**
  String get reportBugNote;

  /// No description provided for @requestAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'The owner will be notified and can share the file with you.'**
  String get requestAccessDescription;

  /// No description provided for @requestAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'The request could not be sent'**
  String get requestAccessFailed;

  /// No description provided for @requestAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get requestAccessMessage;

  /// No description provided for @requestAccessRole.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get requestAccessRole;

  /// No description provided for @requestAccessSend.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get requestAccessSend;

  /// No description provided for @requestAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get requestAccessTitle;

  /// No description provided for @restoreVersionAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreVersionAction;

  /// No description provided for @restoreVersionBody.
  ///
  /// In en, this message translates to:
  /// **'The current version is kept in the history, so you can switch back at any time.'**
  String get restoreVersionBody;

  /// No description provided for @restoreVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this version?'**
  String get restoreVersionTitle;

  /// No description provided for @roleCommenter.
  ///
  /// In en, this message translates to:
  /// **'Commenter'**
  String get roleCommenter;

  /// No description provided for @roleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get roleEditor;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// Shown while the /new route creates an item.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get routeCreating;

  /// Toast: /import without a valid file id.
  ///
  /// In en, this message translates to:
  /// **'This link doesn\'t name a file to import.'**
  String get routeImportInvalid;

  /// Shown while the /import route imports a Drive file.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get routeImporting;

  /// Last row of an app home's search suggestions.
  ///
  /// In en, this message translates to:
  /// **'Search all of Wonky Drive for “{query}”'**
  String searchAllDrive(String query);

  /// No description provided for @searchFor.
  ///
  /// In en, this message translates to:
  /// **'Search for “{query}”'**
  String searchFor(String query);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or content'**
  String get searchHint;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search in Drive'**
  String get searchPlaceholder;

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for “{query}”'**
  String searchResultsFor(String query);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// No description provided for @sessionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue. Your work is kept.'**
  String get sessionExpiredBody;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your session expired'**
  String get sessionExpiredTitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccent;

  /// No description provided for @settingsAccentNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get settingsAccentNeutral;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsAi;

  /// No description provided for @settingsAiProviders.
  ///
  /// In en, this message translates to:
  /// **'AI providers'**
  String get settingsAiProviders;

  /// No description provided for @settingsAiHint.
  ///
  /// In en, this message translates to:
  /// **'The assistant helps you write and analyze. It only sees files you open with it.'**
  String get settingsAiHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get settingsDensity;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer & MCP'**
  String get settingsDeveloper;

  /// Settings › Developer group with the server's status.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServerTitle;

  /// No description provided for @settingsRedis.
  ///
  /// In en, this message translates to:
  /// **'Redis'**
  String get settingsRedis;

  /// No description provided for @settingsRedisHint.
  ///
  /// In en, this message translates to:
  /// **'Messaging between server instances; needed when more than one runs.'**
  String get settingsRedisHint;

  /// No description provided for @redisConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get redisConnected;

  /// No description provided for @redisNotReachable.
  ///
  /// In en, this message translates to:
  /// **'Not reachable'**
  String get redisNotReachable;

  /// No description provided for @redisNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get redisNotConfigured;

  /// No description provided for @settingsKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsKeyboard;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Used for dates, numbers and new spreadsheets.'**
  String get settingsLanguageHint;

  /// No description provided for @settingsLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get settingsLayout;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline & device data'**
  String get settingsOffline;

  /// No description provided for @settingsOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Files you open recently stay available on this device.'**
  String get settingsOfflineHint;

  /// No description provided for @settingsPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a code to set a new password.'**
  String get settingsPasswordHint;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Turns off non-essential animations.'**
  String get settingsReduceMotionHint;

  /// Wonky Work settings section: avatar, display name, email, delete account.
  ///
  /// In en, this message translates to:
  /// **'Account & profile'**
  String get settingsAccountProfile;

  /// Shown while an old settings link hands over to another app, e.g. 'Opening Sheets settings…'.
  ///
  /// In en, this message translates to:
  /// **'Opening {settings}…'**
  String settingsOpeningOtherApp(String settings);

  /// Settings nav entry that lists the other apps' settings (they open in that app).
  ///
  /// In en, this message translates to:
  /// **'Settings of other apps'**
  String get settingsOtherApps;

  /// Screen reader label of the section select of the settings screen on narrow screens.
  ///
  /// In en, this message translates to:
  /// **'Settings section'**
  String get settingsSectionPicker;

  /// Wonky Work settings section with the storage quota.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsStorageDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get settingsStorageDocuments;

  /// No description provided for @settingsStorageFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get settingsStorageFiles;

  /// No description provided for @settingsStorageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading storage…'**
  String get settingsStorageLoading;

  /// No description provided for @settingsStorageManage.
  ///
  /// In en, this message translates to:
  /// **'Manage storage in Wonky Drive'**
  String get settingsStorageManage;

  /// No description provided for @settingsStoragePresentations.
  ///
  /// In en, this message translates to:
  /// **'Presentations'**
  String get settingsStoragePresentations;

  /// No description provided for @settingsStorageQuota.
  ///
  /// In en, this message translates to:
  /// **'Your storage'**
  String get settingsStorageQuota;

  /// No description provided for @settingsStorageQuotaHint.
  ///
  /// In en, this message translates to:
  /// **'One quota for all Wonky Work apps.'**
  String get settingsStorageQuotaHint;

  /// No description provided for @settingsStorageSpreadsheets.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets'**
  String get settingsStorageSpreadsheets;

  /// No description provided for @settingsStorageTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get settingsStorageTrash;

  /// No description provided for @settingsStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Storage usage isn\'t available right now.'**
  String get settingsStorageUnavailable;

  /// No description provided for @settingsStorageWhatCounts.
  ///
  /// In en, this message translates to:
  /// **'What counts'**
  String get settingsStorageWhatCounts;

  /// No description provided for @settingsStorageWhatCountsBody.
  ///
  /// In en, this message translates to:
  /// **'Documents, spreadsheets, presentations, uploaded files and images in your files, including the trash. Version history, thumbnails and exports don\'t count. Files shared with you count against their owner\'s storage.'**
  String get settingsStorageWhatCountsBody;

  /// Keyboard shortcuts settings: heading of the commands shared by every Wonky Work app.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shortcutsGroupShared;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsSaved;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Sign-in & security'**
  String get settingsSecurity;

  /// No description provided for @settingsSheets.
  ///
  /// In en, this message translates to:
  /// **'Wonky Sheets'**
  String get settingsSheets;

  /// No description provided for @settingsSignOutHint.
  ///
  /// In en, this message translates to:
  /// **'Signs you out of Wonky Work on this device.'**
  String get settingsSignOutHint;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsTimeZone;

  /// No description provided for @settingsTimeZoneHint.
  ///
  /// In en, this message translates to:
  /// **'IANA name, e.g. Europe/Stockholm. Empty follows this device.'**
  String get settingsTimeZoneHint;

  /// No description provided for @settingsUiLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsUiLanguage;

  /// No description provided for @settingsWrite.
  ///
  /// In en, this message translates to:
  /// **'Wonky Write'**
  String get settingsWrite;

  /// No description provided for @shareAddPeople.
  ///
  /// In en, this message translates to:
  /// **'Add people by name or email'**
  String get shareAddPeople;

  /// No description provided for @shareAnyoneWithLink.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link'**
  String get shareAnyoneWithLink;

  /// No description provided for @shareApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get shareApprove;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @shareCannotShare.
  ///
  /// In en, this message translates to:
  /// **'Only the owner and editors can share this file.'**
  String get shareCannotShare;

  /// No description provided for @shareDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get shareDeny;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'The sharing change could not be saved'**
  String get shareFailed;

  /// No description provided for @shareGeneralAccess.
  ///
  /// In en, this message translates to:
  /// **'General access'**
  String get shareGeneralAccess;

  /// No description provided for @shareInherited.
  ///
  /// In en, this message translates to:
  /// **'From folder “{folder}”'**
  String shareInherited(String folder);

  /// No description provided for @shareLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in who has the link can open it'**
  String get shareLinkHint;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get shareMessage;

  /// No description provided for @shareNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify people'**
  String get shareNotify;

  /// No description provided for @sharePending.
  ///
  /// In en, this message translates to:
  /// **'Pending invite'**
  String get sharePending;

  /// No description provided for @sharePeopleWithAccess.
  ///
  /// In en, this message translates to:
  /// **'People with access'**
  String get sharePeopleWithAccess;

  /// No description provided for @shareRemoveAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove access'**
  String get shareRemoveAccess;

  /// No description provided for @shareRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access to this file.'**
  String shareRemoveBody(String name);

  /// No description provided for @shareRemoveRecipient.
  ///
  /// In en, this message translates to:
  /// **'Remove {email}'**
  String shareRemoveRecipient(String email);

  /// No description provided for @shareRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove access?'**
  String get shareRemoveTitle;

  /// No description provided for @shareRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} requests {role} access'**
  String shareRequestTitle(String name, String role);

  /// No description provided for @shareRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get shareRestricted;

  /// No description provided for @shareRestrictedHint.
  ///
  /// In en, this message translates to:
  /// **'Only people with access can open with the link'**
  String get shareRestrictedHint;

  /// No description provided for @shareRotateLink.
  ///
  /// In en, this message translates to:
  /// **'Reset link'**
  String get shareRotateLink;

  /// No description provided for @shareSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared with 1 person} other{Shared with {count} people}}'**
  String shareSent(int count);

  /// No description provided for @shareSettingComments.
  ///
  /// In en, this message translates to:
  /// **'Viewers can see comments'**
  String get shareSettingComments;

  /// No description provided for @shareSettingEditors.
  ///
  /// In en, this message translates to:
  /// **'Editors can change permissions and share'**
  String get shareSettingEditors;

  /// No description provided for @shareSettingExport.
  ///
  /// In en, this message translates to:
  /// **'Viewers and commenters can download, print and copy'**
  String get shareSettingExport;

  /// No description provided for @shareSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing settings'**
  String get shareSettingsTitle;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share “{name}”'**
  String shareTitle(String name);

  /// No description provided for @shareTransferBody.
  ///
  /// In en, this message translates to:
  /// **'{name} becomes the owner once they accept. You\'ll stay an editor.'**
  String shareTransferBody(String name);

  /// No description provided for @shareTransferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get shareTransferOwnership;

  /// No description provided for @shareTransferSent.
  ///
  /// In en, this message translates to:
  /// **'Ownership transfer sent to {name}'**
  String shareTransferSent(String name);

  /// No description provided for @shareTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership?'**
  String get shareTransferTitle;

  /// No description provided for @shareYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String shareYou(String name);

  /// No description provided for @sheetsAutocomplete.
  ///
  /// In en, this message translates to:
  /// **'Formula suggestions'**
  String get sheetsAutocomplete;

  /// No description provided for @sheetsFormulaHelp.
  ///
  /// In en, this message translates to:
  /// **'Show formula help'**
  String get sheetsFormulaHelp;

  /// No description provided for @sheetsScripts.
  ///
  /// In en, this message translates to:
  /// **'Allow scripts'**
  String get sheetsScripts;

  /// No description provided for @shortcutConflictBody.
  ///
  /// In en, this message translates to:
  /// **'{keys} is already used by {commands}. Replace it?'**
  String shortcutConflictBody(String keys, String commands);

  /// No description provided for @shortcutConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcut in use'**
  String get shortcutConflictTitle;

  /// No description provided for @shortcutReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get shortcutReplace;

  /// No description provided for @shortcutReserved.
  ///
  /// In en, this message translates to:
  /// **'The browser reserves this shortcut.'**
  String get shortcutReserved;

  /// No description provided for @shortcutReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get shortcutReset;

  /// No description provided for @shortcutResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get shortcutResetAll;

  /// No description provided for @shortcutsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts'**
  String get shortcutsSearch;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get shortcutsTitle;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort: {field}'**
  String sortBy(String field);

  /// No description provided for @sortCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get sortCreated;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @sortModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get sortModified;

  /// No description provided for @sortModifiedByMe.
  ///
  /// In en, this message translates to:
  /// **'Last modified by me'**
  String get sortModifiedByMe;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortOpenedByMe.
  ///
  /// In en, this message translates to:
  /// **'Last opened by me'**
  String get sortOpenedByMe;

  /// No description provided for @sortSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get sortSize;

  /// Screen reader value of the storage meter.
  ///
  /// In en, this message translates to:
  /// **'{usage}, {percent} percent'**
  String storageMeterValue(String usage, int percent);

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String storageUsed(String size);

  /// Storage meter, e.g. '12.3 MB of 50 MB used'.
  ///
  /// In en, this message translates to:
  /// **'{used} of {quota} used'**
  String storageUsedOf(String used, String quota);

  /// Storage meter at or above the quota.
  ///
  /// In en, this message translates to:
  /// **'{used} of {quota} used — over quota'**
  String storageUsedOfOver(String used, String quota);

  /// Storage meter while the server computes the usage for the first time.
  ///
  /// In en, this message translates to:
  /// **'Calculating storage…'**
  String get storageCalculating;

  /// Tooltip of the storage meter.
  ///
  /// In en, this message translates to:
  /// **'Storage is shared by Wonky Drive, Write, Sheets and Slides.'**
  String get storageMeterTooltip;

  /// Tooltip of the storage meter while it shows the last known value offline.
  ///
  /// In en, this message translates to:
  /// **'Storage is shared by Wonky Drive, Write, Sheets and Slides. (offline)'**
  String get storageMeterTooltipOffline;

  /// Storage banner at 90 % of the quota.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {used} of your {quota} storage.'**
  String storageBannerWarning(String used, String quota);

  /// Storage banner when over the quota.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of storage. You can keep editing, but you can\'t upload files, add images, import, or make copies until you free up space.'**
  String get storageBannerOver;

  /// Tooltip of the storage banner's close button.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get storageBannerDismiss;

  /// Out of storage dialog: the user's own quota.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of storage'**
  String get quotaOwnTitle;

  /// No description provided for @quotaOwnBody.
  ///
  /// In en, this message translates to:
  /// **'This needs {needed}, but you have {available} left of your {quota}. Free up space in Wonky Drive by deleting files you no longer need and emptying the trash.'**
  String quotaOwnBody(String needed, String available, String quota);

  /// Out of storage dialog when the needed size is unknown.
  ///
  /// In en, this message translates to:
  /// **'You have {available} left of your {quota}. Free up space in Wonky Drive by deleting files you no longer need and emptying the trash.'**
  String quotaOwnBodyUnknown(String available, String quota);

  /// Out of storage dialog: the owner of the item is full.
  ///
  /// In en, this message translates to:
  /// **'{owner} is out of storage'**
  String quotaOwnerTitle(String owner);

  /// kind: document, spreadsheet or presentation.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, spreadsheet{Images added to this spreadsheet count against the owner\'s storage. Ask {owner} to free up space, or add the image to a spreadsheet you own.} presentation{Images added to this presentation count against the owner\'s storage. Ask {owner} to free up space, or add the image to a presentation you own.} other{Images added to this document count against the owner\'s storage. Ask {owner} to free up space, or add the image to a document you own.}}'**
  String quotaOwnerImageBody(String kind, String owner);

  /// Out of storage dialog: the owner is full (imports, other content).
  ///
  /// In en, this message translates to:
  /// **'Content added to this file counts against the owner\'s storage. Ask {owner} to free up space first.'**
  String quotaOwnerBody(String owner);

  /// No description provided for @quotaBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage for all files'**
  String get quotaBatchTitle;

  /// No description provided for @quotaBatchBody.
  ///
  /// In en, this message translates to:
  /// **'These {count} files need {needed}, but you have {available} left. Upload the files that fit, or free up space first.'**
  String quotaBatchBody(int count, String needed, String available);

  /// No description provided for @quotaBatchFit.
  ///
  /// In en, this message translates to:
  /// **'Upload the files that fit'**
  String get quotaBatchFit;

  /// Ownership transfer refused: the new owner is full.
  ///
  /// In en, this message translates to:
  /// **'{name} doesn\'t have enough storage'**
  String quotaTransferTitle(String name);

  /// No description provided for @quotaTransferBody.
  ///
  /// In en, this message translates to:
  /// **'{name} needs {needed} free to take ownership of “{item}”. Ask them to free up space first.'**
  String quotaTransferBody(String name, String needed, String item);

  /// Accepting an ownership transfer refused.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough storage'**
  String get quotaTransferAcceptTitle;

  /// No description provided for @quotaTransferAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Taking ownership of “{item}” needs {needed}, but you have {available} left.'**
  String quotaTransferAcceptBody(String item, String needed, String available);

  /// No description provided for @quotaTooLargeTitle.
  ///
  /// In en, this message translates to:
  /// **'This file is too large'**
  String get quotaTooLargeTitle;

  /// No description provided for @quotaTooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'Files can be at most {max}.'**
  String quotaTooLargeBody(String max);

  /// No description provided for @quotaTooLargeNowBody.
  ///
  /// In en, this message translates to:
  /// **'Files can be at most {max} right now, because that\'s how much storage you have left.'**
  String quotaTooLargeNowBody(String max);

  /// Ownership transfer dialog when the item's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'this item'**
  String get quotaItemFallback;

  /// No description provided for @strengthEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get strengthEmpty;

  /// No description provided for @strengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get strengthFair;

  /// No description provided for @strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// No description provided for @strengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {label}'**
  String strengthLabel(String label);

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccount;

  /// No description provided for @templateBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get templateBlank;

  /// No description provided for @templateEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get templateEducation;

  /// No description provided for @templateFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get templateFinance;

  /// No description provided for @templateGallery.
  ///
  /// In en, this message translates to:
  /// **'Template gallery'**
  String get templateGallery;

  /// No description provided for @templatePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get templatePersonal;

  /// No description provided for @templateProjectManagement.
  ///
  /// In en, this message translates to:
  /// **'Project management'**
  String get templateProjectManagement;

  /// No description provided for @templateStripTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new {kind}'**
  String templateStripTitle(String kind);

  /// No description provided for @templateWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get templateWork;

  /// No description provided for @templatesHide.
  ///
  /// In en, this message translates to:
  /// **'Hide templates'**
  String get templatesHide;

  /// No description provided for @templatesShow.
  ///
  /// In en, this message translates to:
  /// **'Show templates'**
  String get templatesShow;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Theme: {mode}'**
  String themeToggleTooltip(String mode);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @toastAccessRequested.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get toastAccessRequested;

  /// No description provided for @toastCopyCreated.
  ///
  /// In en, this message translates to:
  /// **'Created “{name}”'**
  String toastCopyCreated(String name);

  /// No description provided for @toastLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get toastLinkCopied;

  /// No description provided for @toastMcpConfigCopied.
  ///
  /// In en, this message translates to:
  /// **'MCP settings copied'**
  String get toastMcpConfigCopied;

  /// No description provided for @toastMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved to trash} other{{count} items moved to trash}}'**
  String toastMovedToTrash(int count);

  /// No description provided for @toastOfflineOpFailed.
  ///
  /// In en, this message translates to:
  /// **'A change made offline could not be applied'**
  String get toastOfflineOpFailed;

  /// No description provided for @toastShortcutAdded.
  ///
  /// In en, this message translates to:
  /// **'Shortcut added'**
  String get toastShortcutAdded;

  /// No description provided for @toastUndoPartial.
  ///
  /// In en, this message translates to:
  /// **'Some changes couldn\'t be undone because they were edited by someone else.'**
  String get toastUndoPartial;

  /// No description provided for @toastVersionNamed.
  ///
  /// In en, this message translates to:
  /// **'Saved version “{name}”'**
  String toastVersionNamed(String name);

  /// No description provided for @toastVersionRestored.
  ///
  /// In en, this message translates to:
  /// **'Version restored'**
  String get toastVersionRestored;

  /// No description provided for @toggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get toggleSidebar;

  /// No description provided for @tokenCopyOnce.
  ///
  /// In en, this message translates to:
  /// **'Copy this token now. You won\'t see it again.'**
  String get tokenCopyOnce;

  /// No description provided for @tokenCreate.
  ///
  /// In en, this message translates to:
  /// **'Create token'**
  String get tokenCreate;

  /// No description provided for @tokenName.
  ///
  /// In en, this message translates to:
  /// **'Token name'**
  String get tokenName;

  /// No description provided for @tokenRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get tokenRevoke;

  /// No description provided for @tokenRevoked.
  ///
  /// In en, this message translates to:
  /// **'revoked'**
  String get tokenRevoked;

  /// No description provided for @tokensEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tokens yet.'**
  String get tokensEmpty;

  /// No description provided for @tokensHint.
  ///
  /// In en, this message translates to:
  /// **'Personal access tokens let MCP clients act as you.'**
  String get tokensHint;

  /// No description provided for @tokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal access tokens'**
  String get tokensTitle;

  /// No description provided for @trashedBanner.
  ///
  /// In en, this message translates to:
  /// **'This file is in the trash.'**
  String get trashedBanner;

  /// No description provided for @typeAll.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get typeAll;

  /// Type filter (Drive): every uploaded file.
  ///
  /// In en, this message translates to:
  /// **'All files'**
  String get typeAllFiles;

  /// No description provided for @typeDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get typeDocuments;

  /// Type filter (Drive): uploaded files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get typeFiles;

  /// No description provided for @typeFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get typeFolders;

  /// Type filter: presentations.
  ///
  /// In en, this message translates to:
  /// **'Presentations'**
  String get typePresentations;

  /// No description provided for @typeSpreadsheets.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets'**
  String get typeSpreadsheets;

  /// No description provided for @undoHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to undo'**
  String get undoHistoryEmpty;

  /// No description provided for @undoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo history'**
  String get undoHistoryTitle;

  /// No description provided for @untitledFolder.
  ///
  /// In en, this message translates to:
  /// **'Untitled folder'**
  String get untitledFolder;

  /// No description provided for @versionNewAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get versionNewAvailable;

  /// No description provided for @versionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No versions yet'**
  String get versionsEmpty;

  /// No description provided for @versionsName.
  ///
  /// In en, this message translates to:
  /// **'Name this version'**
  String get versionsName;

  /// No description provided for @versionsNamedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only named versions'**
  String get versionsNamedOnly;

  /// No description provided for @versionsOpenFull.
  ///
  /// In en, this message translates to:
  /// **'Open full history'**
  String get versionsOpenFull;

  /// No description provided for @versionsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename version'**
  String get versionsRename;

  /// No description provided for @versionsRestorePoint.
  ///
  /// In en, this message translates to:
  /// **'Before restore'**
  String get versionsRestorePoint;

  /// No description provided for @whatsNew1.
  ///
  /// In en, this message translates to:
  /// **'One account for Wonky Write and Wonky Sheets — sign in once, use both.'**
  String get whatsNew1;

  /// No description provided for @whatsNew2.
  ///
  /// In en, this message translates to:
  /// **'Every action is a command: press Ctrl+Shift+P (⌘⇧P) to run anything.'**
  String get whatsNew2;

  /// No description provided for @whatsNew3.
  ///
  /// In en, this message translates to:
  /// **'Undo covers drive changes too — rename, move, star and trash.'**
  String get whatsNew3;

  /// No description provided for @whatsNew4.
  ///
  /// In en, this message translates to:
  /// **'Comments, mentions and version history in every file.'**
  String get whatsNew4;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @wonkyWork.
  ///
  /// In en, this message translates to:
  /// **'Wonky Work'**
  String get wonkyWork;

  /// No description provided for @writeAutoPair.
  ///
  /// In en, this message translates to:
  /// **'Auto-pair brackets and quotes'**
  String get writeAutoPair;

  /// No description provided for @writeExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Default download format'**
  String get writeExportFormat;

  /// No description provided for @writeMarkdownShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Markdown shortcuts'**
  String get writeMarkdownShortcuts;

  /// No description provided for @writePageless.
  ///
  /// In en, this message translates to:
  /// **'Pageless by default'**
  String get writePageless;

  /// No description provided for @writeSmartQuotes.
  ///
  /// In en, this message translates to:
  /// **'Smart quotes'**
  String get writeSmartQuotes;

  /// No description provided for @writeSpellcheck.
  ///
  /// In en, this message translates to:
  /// **'Spellcheck'**
  String get writeSpellcheck;

  /// No description provided for @youHaveCommentAccess.
  ///
  /// In en, this message translates to:
  /// **'You have comment access'**
  String get youHaveCommentAccess;

  /// No description provided for @youHaveViewAccess.
  ///
  /// In en, this message translates to:
  /// **'You have view access'**
  String get youHaveViewAccess;

  /// No description provided for @assistantNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get assistantNewChat;

  /// No description provided for @assistantClearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get assistantClearChat;

  /// No description provided for @assistantDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat'**
  String get assistantDeleteChat;

  /// No description provided for @assistantDeleteChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the chat'**
  String get assistantDeleteChatFailed;

  /// No description provided for @assistantAiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get assistantAiSettings;

  /// No description provided for @assistantOpenAiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open AI settings'**
  String get assistantOpenAiSettings;

  /// No description provided for @assistantEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about this document or tell the assistant what to change.'**
  String get assistantEmptyTitle;

  /// No description provided for @assistantEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every change it makes can be undone in one step.'**
  String get assistantEmptyBody;

  /// No description provided for @assistantPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant…'**
  String get assistantPlaceholder;

  /// No description provided for @assistantPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'The assistant sends this document and your messages to the AI provider to generate answers.'**
  String get assistantPrivacyNotice;

  /// No description provided for @assistantPrivacyNoticeProvider.
  ///
  /// In en, this message translates to:
  /// **'The assistant sends this document and your messages to {provider} to generate answers.'**
  String assistantPrivacyNoticeProvider(String provider);

  /// No description provided for @assistantModeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get assistantModeEdit;

  /// No description provided for @assistantModeEditHint.
  ///
  /// In en, this message translates to:
  /// **'Edit directly: changes go straight into the document'**
  String get assistantModeEditHint;

  /// No description provided for @assistantModeEditUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You can only suggest changes in this document'**
  String get assistantModeEditUnavailable;

  /// No description provided for @assistantModeSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get assistantModeSuggest;

  /// No description provided for @assistantModeSuggestHint.
  ///
  /// In en, this message translates to:
  /// **'Suggest: changes arrive as suggestions to accept or reject'**
  String get assistantModeSuggestHint;

  /// No description provided for @assistantRemoveChip.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String assistantRemoveChip(String label);

  /// No description provided for @assistantThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get assistantThinking;

  /// No description provided for @assistantRefused.
  ///
  /// In en, this message translates to:
  /// **'The assistant can\'t help with that request.'**
  String get assistantRefused;

  /// No description provided for @assistantFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get assistantFailed;

  /// No description provided for @assistantStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get assistantStopped;

  /// No description provided for @assistantContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get assistantContinue;

  /// No description provided for @assistantUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get assistantUndone;

  /// No description provided for @assistantUndoChanges.
  ///
  /// In en, this message translates to:
  /// **'Undo changes'**
  String get assistantUndoChanges;

  /// No description provided for @assistantInsertAtCursor.
  ///
  /// In en, this message translates to:
  /// **'Insert at cursor'**
  String get assistantInsertAtCursor;

  /// No description provided for @assistantAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get assistantAllow;

  /// No description provided for @assistantDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get assistantDeny;

  /// No description provided for @assistantShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get assistantShow;

  /// No description provided for @assistantCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get assistantCopyCode;

  /// No description provided for @aiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t configured on this server.'**
  String get aiNotConfigured;

  /// No description provided for @aiNotConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'Add your own OpenAI, Anthropic or Gemini API key to use it, or ask an administrator to add one to the server.'**
  String get aiNotConfiguredHint;

  /// No description provided for @aiNotConfiguredAdminHint.
  ///
  /// In en, this message translates to:
  /// **'An administrator can enable it by adding an OpenAI, Anthropic or Gemini API key to the server configuration.'**
  String get aiNotConfiguredAdminHint;

  /// No description provided for @aiAddApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add an API key'**
  String get aiAddApiKey;

  /// No description provided for @aiDisabled.
  ///
  /// In en, this message translates to:
  /// **'AI is turned off on this server.'**
  String get aiDisabled;

  /// No description provided for @aiOptedOut.
  ///
  /// In en, this message translates to:
  /// **'The assistant is turned off in your settings (Settings › AI).'**
  String get aiOptedOut;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantHint.
  ///
  /// In en, this message translates to:
  /// **'The assistant helps you write, edit and understand documents. It only sees the document you use it in.'**
  String get aiAssistantHint;

  /// No description provided for @aiEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide AI features and stop sending content to the AI service.'**
  String get aiEnableHint;

  /// No description provided for @aiQuality.
  ///
  /// In en, this message translates to:
  /// **'AI quality'**
  String get aiQuality;

  /// No description provided for @aiQualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get aiQualityBest;

  /// No description provided for @aiQualityBestHint.
  ///
  /// In en, this message translates to:
  /// **'Most capable answers and edits'**
  String get aiQualityBestHint;

  /// No description provided for @aiQualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get aiQualityBalanced;

  /// No description provided for @aiQualityBalancedHint.
  ///
  /// In en, this message translates to:
  /// **'Good answers, a little faster'**
  String get aiQualityBalancedHint;

  /// No description provided for @aiQualityFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get aiQualityFast;

  /// No description provided for @aiQualityFastHint.
  ///
  /// In en, this message translates to:
  /// **'Quickest answers for simple tasks'**
  String get aiQualityFastHint;

  /// No description provided for @aiQualitySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the AI quality'**
  String get aiQualitySaveFailed;

  /// No description provided for @aiUsageToday.
  ///
  /// In en, this message translates to:
  /// **'Usage today'**
  String get aiUsageToday;

  /// No description provided for @aiUsageTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Resets daily at midnight UTC.'**
  String get aiUsageTodayHint;

  /// No description provided for @aiUsagePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String aiUsagePercent(int percent);

  /// No description provided for @aiProviderOpenai.
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get aiProviderOpenai;

  /// No description provided for @aiProviderAnthropic.
  ///
  /// In en, this message translates to:
  /// **'Anthropic'**
  String get aiProviderAnthropic;

  /// No description provided for @aiProviderGemini.
  ///
  /// In en, this message translates to:
  /// **'Google Gemini'**
  String get aiProviderGemini;

  /// No description provided for @aiProvidersServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Provided by this server'**
  String get aiProvidersServerTitle;

  /// No description provided for @aiProvidersServerBody.
  ///
  /// In en, this message translates to:
  /// **'AI requests go to {provider} with this server\'s API key. You don\'t need a key of your own.'**
  String aiProvidersServerBody(String provider);

  /// No description provided for @aiProvidersKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your API key'**
  String get aiProvidersKeyTitle;

  /// No description provided for @aiProvidersKeyHint.
  ///
  /// In en, this message translates to:
  /// **'This server has no AI provider set up. Add your own key to use the assistant and the other AI features. The key is stored on the server, used only for your requests and never shown again.'**
  String get aiProvidersKeyHint;

  /// No description provided for @aiProvidersProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProvidersProvider;

  /// No description provided for @aiProvidersKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiProvidersKey;

  /// No description provided for @aiProvidersKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key'**
  String get aiProvidersKeyPlaceholder;

  /// No description provided for @aiProvidersSave.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get aiProvidersSave;

  /// No description provided for @aiProvidersSaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved'**
  String get aiProvidersSaved;

  /// No description provided for @aiProvidersSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the API key'**
  String get aiProvidersSaveFailed;

  /// No description provided for @aiProvidersCurrent.
  ///
  /// In en, this message translates to:
  /// **'Your key'**
  String get aiProvidersCurrent;

  /// No description provided for @aiProvidersCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'{provider} key ending in {last4}'**
  String aiProvidersCurrentValue(String provider, String last4);

  /// No description provided for @aiProvidersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove key'**
  String get aiProvidersRemove;

  /// No description provided for @aiProvidersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove your API key?'**
  String get aiProvidersRemoveTitle;

  /// No description provided for @aiProvidersRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'AI features stop working for you until you add a key again.'**
  String get aiProvidersRemoveBody;

  /// No description provided for @aiProvidersRemoved.
  ///
  /// In en, this message translates to:
  /// **'API key removed'**
  String get aiProvidersRemoved;

  /// No description provided for @aiProvidersRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the API key'**
  String get aiProvidersRemoveFailed;

  /// No description provided for @aiProvidersNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This server doesn\'t allow personal API keys. Ask an administrator to set up AI.'**
  String get aiProvidersNotAllowed;

  /// No description provided for @aiProvidersManage.
  ///
  /// In en, this message translates to:
  /// **'Manage AI providers'**
  String get aiProvidersManage;

  /// No description provided for @aiChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get aiChatHistory;

  /// No description provided for @aiChatHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Delete all your assistant chats.'**
  String get aiChatHistoryHint;

  /// No description provided for @aiClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get aiClearHistory;

  /// No description provided for @aiClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear assistant history?'**
  String get aiClearHistoryTitle;

  /// No description provided for @aiClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'All your assistant chats in every document are deleted. This can\'t be undone. Edits the assistant made stay in the documents.'**
  String get aiClearHistoryBody;

  /// No description provided for @aiClearHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear the history'**
  String get aiClearHistoryFailed;

  /// No description provided for @aiHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 chat} other{Deleted {count} chats}}'**
  String aiHistoryCleared(int count);

  /// No description provided for @mcpScopeDriveRead.
  ///
  /// In en, this message translates to:
  /// **'Drive: read (list, search, export, download files, storage)'**
  String get mcpScopeDriveRead;

  /// No description provided for @mcpScopeDriveWrite.
  ///
  /// In en, this message translates to:
  /// **'Drive: write (create, rename, move, trash, share, upload and convert files)'**
  String get mcpScopeDriveWrite;

  /// No description provided for @mcpScopeWriteRead.
  ///
  /// In en, this message translates to:
  /// **'Documents: read'**
  String get mcpScopeWriteRead;

  /// No description provided for @mcpScopeWriteEdit.
  ///
  /// In en, this message translates to:
  /// **'Documents: edit (content, comments, suggestions)'**
  String get mcpScopeWriteEdit;

  /// No description provided for @mcpScopeSheetsRead.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets: read'**
  String get mcpScopeSheetsRead;

  /// No description provided for @mcpScopeSheetsEdit.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets: edit'**
  String get mcpScopeSheetsEdit;

  /// No description provided for @mcpScopeSlidesRead.
  ///
  /// In en, this message translates to:
  /// **'Presentations: read'**
  String get mcpScopeSlidesRead;

  /// No description provided for @mcpScopeSlidesEdit.
  ///
  /// In en, this message translates to:
  /// **'Presentations: edit'**
  String get mcpScopeSlidesEdit;

  /// No description provided for @mcpScopeScriptsRun.
  ///
  /// In en, this message translates to:
  /// **'Scripts: run'**
  String get mcpScopeScriptsRun;

  /// No description provided for @mcpScopeUiControl.
  ///
  /// In en, this message translates to:
  /// **'Control app windows (ui.* tools)'**
  String get mcpScopeUiControl;

  /// No description provided for @mcpScopeBoard.
  ///
  /// In en, this message translates to:
  /// **'Bugs & improvements: read, report issues, vote, claim tasks'**
  String get mcpScopeBoard;

  /// No description provided for @tokenCreateHint.
  ///
  /// In en, this message translates to:
  /// **'The token acts as you with the permissions you choose. You can revoke it at any time.'**
  String get tokenCreateHint;

  /// No description provided for @tokenNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the token a name.'**
  String get tokenNameRequired;

  /// No description provided for @tokenScopesRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one permission.'**
  String get tokenScopesRequired;

  /// No description provided for @tokenExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get tokenExpires;

  /// No description provided for @tokenExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{In 1 day} other{In {days} days}}'**
  String tokenExpiresInDays(int days);

  /// No description provided for @tokenExpiresInYear.
  ///
  /// In en, this message translates to:
  /// **'In 1 year'**
  String get tokenExpiresInYear;

  /// No description provided for @tokenNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get tokenNever;

  /// No description provided for @tokenNeverLower.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get tokenNeverLower;

  /// No description provided for @tokenExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get tokenExpired;

  /// No description provided for @tokenNameWithStatus.
  ///
  /// In en, this message translates to:
  /// **'{name} · {status}'**
  String tokenNameWithStatus(String name, String status);

  /// No description provided for @tokenDates.
  ///
  /// In en, this message translates to:
  /// **'Created {created} · expires {expires} · last used {lastUsed}'**
  String tokenDates(String created, String expires, String lastUsed);

  /// No description provided for @tokenRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke \"{name}\"?'**
  String tokenRevokeTitle(String name);

  /// No description provided for @tokenRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'MCP clients using this token stop working immediately. This can\'t be undone.'**
  String get tokenRevokeBody;

  /// No description provided for @toastTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Token copied'**
  String get toastTokenCopied;

  /// No description provided for @mcpEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint: {url}'**
  String mcpEndpoint(String url);

  /// No description provided for @mcpReplaceToken.
  ///
  /// In en, this message translates to:
  /// **'Replace {variable} with a token.'**
  String mcpReplaceToken(String variable);

  /// No description provided for @mcpWindowControl.
  ///
  /// In en, this message translates to:
  /// **'Window control'**
  String get mcpWindowControl;

  /// No description provided for @mcpWindowControlHint.
  ///
  /// In en, this message translates to:
  /// **'Lets MCP clients with the ui:control permission drive this window: navigate, run commands, fill dialogs, take screenshots. A pill with Stop shows while an agent works.'**
  String get mcpWindowControlHint;

  /// No description provided for @mcpBridgeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get mcpBridgeStatus;

  /// No description provided for @mcpBridgeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get mcpBridgeOff;

  /// No description provided for @mcpBridgeConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get mcpBridgeConnecting;

  /// No description provided for @mcpBridgeConnected.
  ///
  /// In en, this message translates to:
  /// **'On · window {id}'**
  String mcpBridgeConnected(String id);

  /// Screen reader label of a drive row or card, e.g. 'Document Plan'.
  ///
  /// In en, this message translates to:
  /// **'{kind} {name}'**
  String driveItemLabel(String kind, String name);

  /// No description provided for @activityShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get activityShowMore;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsFilterUnread;

  /// No description provided for @notificationsFilterUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'Unread ({count})'**
  String notificationsFilterUnreadCount(int count);

  /// No description provided for @notificationsSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationsSettings;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notifications'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationsEmptyUnread.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get notificationsEmptyUnread;

  /// No description provided for @notificationsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get notificationsLoadMore;

  /// No description provided for @notificationsUnreadMarker.
  ///
  /// In en, this message translates to:
  /// **'unread'**
  String get notificationsUnreadMarker;

  /// No description provided for @notifSuggestionAccepted.
  ///
  /// In en, this message translates to:
  /// **'{who} accepted your suggestion in {item}'**
  String notifSuggestionAccepted(String who, String item);

  /// No description provided for @notifSuggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'{who} rejected your suggestion in {item}'**
  String notifSuggestionRejected(String who, String item);

  /// No description provided for @notifyAccessRequests.
  ///
  /// In en, this message translates to:
  /// **'Access requests'**
  String get notifyAccessRequests;

  /// No description provided for @notifySuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions on my files'**
  String get notifySuggestions;

  /// No description provided for @notifyDigest.
  ///
  /// In en, this message translates to:
  /// **'Bundle emails'**
  String get notifyDigest;

  /// No description provided for @notifyDigestHint.
  ///
  /// In en, this message translates to:
  /// **'Send one email every 15 minutes instead of one per notification. Mentions and assignments are always emailed right away.'**
  String get notifyDigestHint;

  /// No description provided for @exportFormatMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown (.md)'**
  String get exportFormatMarkdown;

  /// No description provided for @exportFormatHtml.
  ///
  /// In en, this message translates to:
  /// **'HTML (.html)'**
  String get exportFormatHtml;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (.pdf)'**
  String get exportFormatPdf;

  /// No description provided for @exportFormatText.
  ///
  /// In en, this message translates to:
  /// **'Plain text (.txt)'**
  String get exportFormatText;

  /// No description provided for @badgePendingCreate.
  ///
  /// In en, this message translates to:
  /// **'Created offline. It is added to your Drive when you\'re back online.'**
  String get badgePendingCreate;

  /// Drop overlay of Wonky Drive while files are dragged over the list (Drive 04 §3.5).
  ///
  /// In en, this message translates to:
  /// **'Drop files to upload to {folder}'**
  String dropToUploadInto(String folder);

  /// Drop overlay while files dragged from the OS hover a folder row.
  ///
  /// In en, this message translates to:
  /// **'Upload to {folder}'**
  String dropUploadToFolder(String folder);

  /// Last-modified column of a file that is still uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get driveItemUploading;

  /// Title of the Check spelling dialog (Write, Slides).
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get spellingTitle;

  /// No description provided for @spellingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get spellingDone;

  /// No description provided for @spellingNoErrors.
  ///
  /// In en, this message translates to:
  /// **'No spelling errors found.'**
  String get spellingNoErrors;

  /// No description provided for @spellingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Spellcheck isn’t available for this document’s language.'**
  String get spellingUnavailable;

  /// Label above the flagged word in the Check spelling dialog.
  ///
  /// In en, this message translates to:
  /// **'Not in dictionary'**
  String get spellingNotInDictionary;

  /// No description provided for @spellingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get spellingSuggestions;

  /// No description provided for @spellingNoSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get spellingNoSuggestions;

  /// No description provided for @spellingChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get spellingChange;

  /// No description provided for @spellingChangeAll.
  ///
  /// In en, this message translates to:
  /// **'Change all'**
  String get spellingChangeAll;

  /// No description provided for @spellingIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get spellingIgnore;

  /// No description provided for @spellingIgnoreAll.
  ///
  /// In en, this message translates to:
  /// **'Ignore all'**
  String get spellingIgnoreAll;

  /// No description provided for @spellingAddToDictionary.
  ///
  /// In en, this message translates to:
  /// **'Add to dictionary'**
  String get spellingAddToDictionary;

  /// No description provided for @spellingPersonalDictionary.
  ///
  /// In en, this message translates to:
  /// **'Personal dictionary'**
  String get spellingPersonalDictionary;

  /// No description provided for @spellingPersonalDictionaryHint.
  ///
  /// In en, this message translates to:
  /// **'Words you added are never marked as misspelled, in any document.'**
  String get spellingPersonalDictionaryHint;

  /// Placeholder of the word field in the Personal dictionary dialog.
  ///
  /// In en, this message translates to:
  /// **'Add a word'**
  String get spellingAddWord;

  /// No description provided for @spellingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get spellingAdd;

  /// No description provided for @spellingNoWords.
  ///
  /// In en, this message translates to:
  /// **'No words yet.'**
  String get spellingNoWords;

  /// Screen reader label of the remove button of a personal dictionary word.
  ///
  /// In en, this message translates to:
  /// **'Remove {word}'**
  String spellingRemoveWord(String word);

  /// No description provided for @emojiPickerClose.
  ///
  /// In en, this message translates to:
  /// **'Close emoji picker'**
  String get emojiPickerClose;

  /// No description provided for @emojiDialogLabel.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojiDialogLabel;

  /// No description provided for @emojiPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Emoji picker'**
  String get emojiPickerLabel;

  /// No description provided for @emojiSearch.
  ///
  /// In en, this message translates to:
  /// **'Search emoji'**
  String get emojiSearch;

  /// No description provided for @emojiRecentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get emojiRecentlyUsed;

  /// No description provided for @emojiLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Emoji could not be loaded'**
  String get emojiLoadFailed;

  /// No description provided for @emojiNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No emoji found'**
  String get emojiNoneFound;

  /// No description provided for @emojiNone.
  ///
  /// In en, this message translates to:
  /// **'No emoji'**
  String get emojiNone;

  /// No description provided for @emojiSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get emojiSearchResults;

  /// No description provided for @emojiPickAnEmoji.
  ///
  /// In en, this message translates to:
  /// **'Pick an emoji'**
  String get emojiPickAnEmoji;

  /// No description provided for @emojiSkinToneOption.
  ///
  /// In en, this message translates to:
  /// **'{tone} skin tone'**
  String emojiSkinToneOption(String tone);

  /// No description provided for @emojiSkinToneCurrent.
  ///
  /// In en, this message translates to:
  /// **'Skin tone: {tone}'**
  String emojiSkinToneCurrent(String tone);

  /// No description provided for @emojiSkinToneDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get emojiSkinToneDefault;

  /// No description provided for @emojiSkinToneLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get emojiSkinToneLight;

  /// No description provided for @emojiSkinToneMediumLight.
  ///
  /// In en, this message translates to:
  /// **'Medium-light'**
  String get emojiSkinToneMediumLight;

  /// No description provided for @emojiSkinToneMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get emojiSkinToneMedium;

  /// No description provided for @emojiSkinToneMediumDark.
  ///
  /// In en, this message translates to:
  /// **'Medium-dark'**
  String get emojiSkinToneMediumDark;

  /// No description provided for @emojiSkinToneDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get emojiSkinToneDark;

  /// No description provided for @specialCharsTitle.
  ///
  /// In en, this message translates to:
  /// **'Special characters'**
  String get specialCharsTitle;

  /// No description provided for @specialCharsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get specialCharsClose;

  /// No description provided for @specialCharsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code (U+2192)'**
  String get specialCharsSearch;

  /// No description provided for @specialCharsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get specialCharsRecent;

  /// No description provided for @specialCharsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Characters could not be loaded'**
  String get specialCharsLoadFailed;

  /// No description provided for @specialCharsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No characters found'**
  String get specialCharsNoneFound;

  /// No description provided for @specialCharsSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get specialCharsSearchResults;

  /// Detail of a presentation edit event in the activity feed: how many slides were edited.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide} other{{count} slides}}'**
  String activityDetailSlides(int count);

  /// Detail of a presentation edit event: slides deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide deleted} other{{count} slides deleted}}'**
  String activityDetailSlidesDeleted(int count);

  /// Detail of a presentation edit event: the theme changed.
  ///
  /// In en, this message translates to:
  /// **'theme changed'**
  String get activityDetailTheme;

  /// Detail of an edit event made through MCP or the assistant.
  ///
  /// In en, this message translates to:
  /// **'with Claude'**
  String get activityDetailAgent;

  /// No description provided for @markdownBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get markdownBold;

  /// No description provided for @markdownItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get markdownItalic;

  /// No description provided for @markdownCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get markdownCode;

  /// No description provided for @markdownLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get markdownLink;

  /// No description provided for @markdownBulletedList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get markdownBulletedList;

  /// No description provided for @markdownStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get markdownStrikethrough;

  /// No description provided for @markdownNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get markdownNumberedList;

  /// No description provided for @markdownTaskList.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get markdownTaskList;

  /// No description provided for @markdownQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get markdownQuote;

  /// Screen reader label of the Markdown composer's formatting toolbar.
  ///
  /// In en, this message translates to:
  /// **'Formatting'**
  String get markdownToolbar;

  /// No description provided for @markdownLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get markdownLinkTitle;

  /// No description provided for @markdownLinkEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get markdownLinkEditTitle;

  /// No description provided for @markdownLinkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get markdownLinkRemove;

  /// No description provided for @markdownLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get markdownLinkUrl;

  /// No description provided for @markdownLinkInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get markdownLinkInsert;

  /// No description provided for @markdownLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a web (http or https) or email (mailto) link'**
  String get markdownLinkInvalid;

  /// The character counter of the Markdown composer.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String markdownLength(int count, int max);

  /// No description provided for @commentAddReaction.
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get commentAddReaction;

  /// Semantics label of a reaction chip on a comment.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {count, plural, =1{1 reaction} other{{count} reactions}}'**
  String commentReaction(String emoji, int count);

  /// Semantics label of the image lightbox when the image has no alt text.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get lightboxImage;

  /// No description provided for @lightboxClose.
  ///
  /// In en, this message translates to:
  /// **'Close (Esc)'**
  String get lightboxClose;

  /// No description provided for @lightboxCloseImage.
  ///
  /// In en, this message translates to:
  /// **'Close image'**
  String get lightboxCloseImage;

  /// No description provided for @lightboxLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The image couldn’t be loaded'**
  String get lightboxLoadFailed;

  /// No description provided for @lightboxZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get lightboxZoomIn;

  /// No description provided for @lightboxZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get lightboxZoomOut;

  /// No description provided for @lightboxFit.
  ///
  /// In en, this message translates to:
  /// **'Fit to screen'**
  String get lightboxFit;

  /// Help menu and palette: opens the report dialog (specs/16 §4.1).
  ///
  /// In en, this message translates to:
  /// **'Bugs & improvements…'**
  String get cmdBoardReport;

  /// Help menu and palette: opens the Bugs & improvements board page.
  ///
  /// In en, this message translates to:
  /// **'Browse Bugs & improvements'**
  String get cmdBoardOpen;

  /// The product name of the public bug and idea board; title of the report dialog and the entry points.
  ///
  /// In en, this message translates to:
  /// **'Bugs & improvements'**
  String get boardReportName;

  /// Home left menu (wrench icon): opens the Bugs & improvements board, where people vote on issues and pick up tasks to build.
  ///
  /// In en, this message translates to:
  /// **'Contribute & build'**
  String get boardContributeNav;

  /// No description provided for @boardReportKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get boardReportKindLabel;

  /// No description provided for @boardReportKindBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get boardReportKindBug;

  /// No description provided for @boardReportKindIdea.
  ///
  /// In en, this message translates to:
  /// **'Suggest an improvement'**
  String get boardReportKindIdea;

  /// No description provided for @boardReportFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get boardReportFieldTitle;

  /// No description provided for @boardReportTitleHintBug.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem in a few words'**
  String get boardReportTitleHintBug;

  /// No description provided for @boardReportTitleHintIdea.
  ///
  /// In en, this message translates to:
  /// **'Describe your idea in a few words'**
  String get boardReportTitleHintIdea;

  /// No description provided for @boardReportFieldHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get boardReportFieldHappened;

  /// No description provided for @boardReportFieldExpected.
  ///
  /// In en, this message translates to:
  /// **'What did you expect?'**
  String get boardReportFieldExpected;

  /// No description provided for @boardReportFieldSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps to reproduce'**
  String get boardReportFieldSteps;

  /// No description provided for @boardReportFieldIdea.
  ///
  /// In en, this message translates to:
  /// **'What would you like?'**
  String get boardReportFieldIdea;

  /// No description provided for @boardReportFieldWhy.
  ///
  /// In en, this message translates to:
  /// **'Why would it help?'**
  String get boardReportFieldWhy;

  /// No description provided for @boardReportOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get boardReportOptional;

  /// Validation of the issue title.
  ///
  /// In en, this message translates to:
  /// **'Use {min} to {max} characters.'**
  String boardReportTitleLength(int min, int max);

  /// No description provided for @boardReportBodyTooLong.
  ///
  /// In en, this message translates to:
  /// **'The description is too long: at most {max} characters.'**
  String boardReportBodyTooLong(int max);

  /// No description provided for @boardReportSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar issues'**
  String get boardReportSimilarTitle;

  /// Semantics label of a similar issue's score.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vote} other{{count} votes}}'**
  String boardReportSimilarVotes(int count);

  /// Screen-reader label of a similar issue's title in the report dialog: it opens the issue's details.
  ///
  /// In en, this message translates to:
  /// **'Show #{number} {title}'**
  String boardSimilarShow(int number, String title);

  /// No description provided for @boardSimilarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this issue. Try again later.'**
  String get boardSimilarLoadFailed;

  /// No description provided for @boardTaskCommentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Comments for the prompt'**
  String get boardTaskCommentsLabel;

  /// No description provided for @boardTaskCommentsHint.
  ///
  /// In en, this message translates to:
  /// **'The AI reads the checked comments when it writes the prompt.'**
  String get boardTaskCommentsHint;

  /// No description provided for @boardCommentsPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Checked comments go into the task prompt when you select this issue for building.'**
  String get boardCommentsPromptHint;

  /// Screen-reader label of an admin's checkbox on an issue comment.
  ///
  /// In en, this message translates to:
  /// **'Include the comment by {name} in the task prompt'**
  String boardCommentInPrompt(String name);

  /// No description provided for @boardReportVoteInstead.
  ///
  /// In en, this message translates to:
  /// **'Vote instead'**
  String get boardReportVoteInstead;

  /// No description provided for @boardReportVoted.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get boardReportVoted;

  /// Toast after "Vote instead" on an improvement.
  ///
  /// In en, this message translates to:
  /// **'Voted for #{number}'**
  String boardReportVotedFor(int number);

  /// Toast after "Vote instead" on a bug.
  ///
  /// In en, this message translates to:
  /// **'Added “I hit this too” to #{number}'**
  String boardReportHitThisToo(int number);

  /// No description provided for @boardReportVoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t vote: {message}'**
  String boardReportVoteFailed(String message);

  /// No description provided for @boardReportScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get boardReportScreenshot;

  /// No description provided for @boardReportAddScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Add screenshot'**
  String get boardReportAddScreenshot;

  /// No description provided for @boardReportEditScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get boardReportEditScreenshot;

  /// No description provided for @boardReportRemoveScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get boardReportRemoveScreenshot;

  /// No description provided for @boardReportScreenshotPreview.
  ///
  /// In en, this message translates to:
  /// **'Screenshot preview'**
  String get boardReportScreenshotPreview;

  /// No description provided for @boardReportScreenshotWarning.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are public. Cover names, emails and document content.'**
  String get boardReportScreenshotWarning;

  /// No description provided for @boardReportCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t capture the screen'**
  String get boardReportCaptureFailed;

  /// Collapsed line listing the details a bug report includes.
  ///
  /// In en, this message translates to:
  /// **'Details that will be included: {summary}'**
  String boardReportDetails(String summary);

  /// No description provided for @boardReportDetailApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get boardReportDetailApp;

  /// No description provided for @boardReportDetailPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get boardReportDetailPlatform;

  /// No description provided for @boardReportDetailTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get boardReportDetailTheme;

  /// No description provided for @boardReportDetailLocale.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get boardReportDetailLocale;

  /// No description provided for @boardReportDetailWindow.
  ///
  /// In en, this message translates to:
  /// **'Window size'**
  String get boardReportDetailWindow;

  /// No description provided for @boardReportDetailRoute.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get boardReportDetailRoute;

  /// No description provided for @boardReportDetailError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get boardReportDetailError;

  /// No description provided for @boardReportThemeLight.
  ///
  /// In en, this message translates to:
  /// **'light theme'**
  String get boardReportThemeLight;

  /// No description provided for @boardReportThemeDark.
  ///
  /// In en, this message translates to:
  /// **'dark theme'**
  String get boardReportThemeDark;

  /// Checkbox; age is e.g. "2 min ago".
  ///
  /// In en, this message translates to:
  /// **'Include the last error ({age})'**
  String boardReportIncludeError(String age);

  /// No description provided for @boardReportErrorAge.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{just now} =1{1 min ago} other{{minutes} min ago}}'**
  String boardReportErrorAge(int minutes);

  /// No description provided for @boardReportErrorAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 h ago} other{{hours} h ago}}'**
  String boardReportErrorAgeHours(int hours);

  /// No description provided for @boardReportAiNotice.
  ///
  /// In en, this message translates to:
  /// **'Issues are public and checked automatically by AI (Jev, Gemini).'**
  String get boardReportAiNotice;

  /// No description provided for @boardReportPublicNotice.
  ///
  /// In en, this message translates to:
  /// **'Issues are public.'**
  String get boardReportPublicNotice;

  /// No description provided for @boardReportSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Security issue? Don’t post it here: email {contact}'**
  String boardReportSecurityNotice(String contact);

  /// No description provided for @boardReportPostBug.
  ///
  /// In en, this message translates to:
  /// **'Post bug'**
  String get boardReportPostBug;

  /// No description provided for @boardReportPostIdea.
  ///
  /// In en, this message translates to:
  /// **'Post improvement'**
  String get boardReportPostIdea;

  /// No description provided for @boardReportPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get boardReportPosted;

  /// No description provided for @boardReportPostedChecking.
  ///
  /// In en, this message translates to:
  /// **'Posted. Checking it now…'**
  String get boardReportPostedChecking;

  /// No description provided for @boardReportPostedHeld.
  ///
  /// In en, this message translates to:
  /// **'Posted. Waiting for review: a moderator will look at it.'**
  String get boardReportPostedHeld;

  /// No description provided for @boardReportView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get boardReportView;

  /// No description provided for @boardReportRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You’ve posted a lot recently. Please try again later.'**
  String get boardReportRateLimited;

  /// No description provided for @boardReportBlocked.
  ///
  /// In en, this message translates to:
  /// **'You can’t post on Bugs & improvements.'**
  String get boardReportBlocked;

  /// No description provided for @boardReportBlockedReason.
  ///
  /// In en, this message translates to:
  /// **'You can’t post on Bugs & improvements: {reason}'**
  String boardReportBlockedReason(String reason);

  /// No description provided for @boardReportPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t post: {message}'**
  String boardReportPostFailed(String message);

  /// No description provided for @boardReportUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t upload the screenshot: {message}'**
  String boardReportUploadFailed(String message);

  /// No description provided for @boardReportDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard draft?'**
  String get boardReportDiscardTitle;

  /// No description provided for @boardReportDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your issue hasn’t been posted yet.'**
  String get boardReportDiscardBody;

  /// No description provided for @boardReportDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get boardReportDiscard;

  /// No description provided for @boardReportKeepDraft.
  ///
  /// In en, this message translates to:
  /// **'Keep draft'**
  String get boardReportKeepDraft;

  /// Error card button: opens the report dialog with the error attached.
  ///
  /// In en, this message translates to:
  /// **'Report this bug'**
  String get errorReportBug;

  /// No description provided for @screenshotEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit screenshot'**
  String get screenshotEditorTitle;

  /// No description provided for @screenshotEditorWarning.
  ///
  /// In en, this message translates to:
  /// **'This screenshot will be public. Cover anything private: names, emails, document and spreadsheet content you don’t want to share.'**
  String get screenshotEditorWarning;

  /// No description provided for @screenshotToolsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get screenshotToolsLabel;

  /// No description provided for @screenshotColorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get screenshotColorsLabel;

  /// No description provided for @screenshotToolCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get screenshotToolCover;

  /// No description provided for @screenshotToolHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get screenshotToolHighlight;

  /// No description provided for @screenshotToolArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get screenshotToolArrow;

  /// No description provided for @screenshotToolPen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get screenshotToolPen;

  /// No description provided for @screenshotColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get screenshotColorRed;

  /// No description provided for @screenshotColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get screenshotColorYellow;

  /// No description provided for @screenshotColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get screenshotColorBlue;

  /// No description provided for @screenshotUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get screenshotUndo;

  /// No description provided for @screenshotRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get screenshotRedo;

  /// No description provided for @screenshotDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get screenshotDelete;

  /// No description provided for @screenshotClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get screenshotClear;

  /// No description provided for @screenshotDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get screenshotDone;

  /// Tooltip of an editor tool with its key.
  ///
  /// In en, this message translates to:
  /// **'{label} ({shortcut})'**
  String screenshotShortcut(String label, String shortcut);

  /// No description provided for @screenshotCanvasLabel.
  ///
  /// In en, this message translates to:
  /// **'Screenshot. Drag to draw with the selected tool; click an annotation to select it.'**
  String get screenshotCanvasLabel;

  /// No description provided for @screenshotEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t prepare the screenshot: {message}'**
  String screenshotEncodeFailed(String message);

  /// Name of the board pages (specs/16 §4.3): the breadcrumb root and the page title, like the home menu entry boardContributeNav. The report dialog, Help menu and command category keep boardReportName.
  ///
  /// In en, this message translates to:
  /// **'Contribute & build'**
  String get boardTitle;

  /// No description provided for @boardBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Breadcrumb'**
  String get boardBreadcrumb;

  /// No description provided for @boardClose.
  ///
  /// In en, this message translates to:
  /// **'Close Contribute & build'**
  String get boardClose;

  /// No description provided for @boardShowPath.
  ///
  /// In en, this message translates to:
  /// **'Show the full path'**
  String get boardShowPath;

  /// No description provided for @boardTabWithCount.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count}'**
  String boardTabWithCount(String name, int count);

  /// No description provided for @boardReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get boardReportBug;

  /// No description provided for @boardSuggestImprovement.
  ///
  /// In en, this message translates to:
  /// **'Suggest an improvement'**
  String get boardSuggestImprovement;

  /// No description provided for @boardSearch.
  ///
  /// In en, this message translates to:
  /// **'Search issues'**
  String get boardSearch;

  /// No description provided for @boardSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get boardSignIn;

  /// Banner on the board for signed-out visitors.
  ///
  /// In en, this message translates to:
  /// **'Sign in to vote and report issues.'**
  String get boardSignInToVote;

  /// No description provided for @boardSignInToComment.
  ///
  /// In en, this message translates to:
  /// **'Sign in to comment'**
  String get boardSignInToComment;

  /// No description provided for @boardSignInToClaim.
  ///
  /// In en, this message translates to:
  /// **'Sign in to claim this task'**
  String get boardSignInToClaim;

  /// No description provided for @boardBlocked.
  ///
  /// In en, this message translates to:
  /// **'You can\'t post on Bugs & improvements.'**
  String get boardBlocked;

  /// No description provided for @boardContributeLink.
  ///
  /// In en, this message translates to:
  /// **'How to contribute'**
  String get boardContributeLink;

  /// No description provided for @boardTabImprovements.
  ///
  /// In en, this message translates to:
  /// **'Improvements'**
  String get boardTabImprovements;

  /// No description provided for @boardTabBugs.
  ///
  /// In en, this message translates to:
  /// **'Bugs'**
  String get boardTabBugs;

  /// Board tab with the tasks contributors can claim.
  ///
  /// In en, this message translates to:
  /// **'Up for grabs'**
  String get boardTabTasks;

  /// Board tab with the tasks someone has claimed or that are in review.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get boardTabClaimed;

  /// Tooltip of the board's search button (opens the search popover; shortcut /).
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get boardSearchButton;

  /// The active board search: the search button's label and the removable chip in the filter row.
  ///
  /// In en, this message translates to:
  /// **'Search: “{query}”'**
  String boardSearchActive(String query);

  /// No description provided for @boardSearchRemove.
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get boardSearchRemove;

  /// No description provided for @boardSearchIncludeClosed.
  ///
  /// In en, this message translates to:
  /// **'Include closed'**
  String get boardSearchIncludeClosed;

  /// No description provided for @boardSearchIncludeClosedHint.
  ///
  /// In en, this message translates to:
  /// **'Done, shipped, declined and duplicates'**
  String get boardSearchIncludeClosedHint;

  /// No description provided for @boardSearchKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get boardSearchKind;

  /// No description provided for @boardSearchKindAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get boardSearchKindAll;

  /// Breadcrumb of the board's search results page without a query.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get boardSearchResults;

  /// Header and breadcrumb of the board's search results across all issues.
  ///
  /// In en, this message translates to:
  /// **'Results for “{query}”'**
  String boardSearchResultsFor(String query);

  /// No description provided for @boardSearchStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Search the board'**
  String get boardSearchStartTitle;

  /// No description provided for @boardSearchStartHint.
  ///
  /// In en, this message translates to:
  /// **'Find issues by their words, part of a title or their number.'**
  String get boardSearchStartHint;

  /// No description provided for @boardEmptySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Try fewer words or part of a word, or include closed issues.'**
  String get boardEmptySearchHint;

  /// No description provided for @boardEmptyClaimed.
  ///
  /// In en, this message translates to:
  /// **'No claimed tasks'**
  String get boardEmptyClaimed;

  /// No description provided for @boardEmptyClaimedHint.
  ///
  /// In en, this message translates to:
  /// **'Tasks show here while someone works on them, and while their pull request is in review.'**
  String get boardEmptyClaimedHint;

  /// No description provided for @boardTabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get boardTabDone;

  /// Admins' moderation tab of the board.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get boardTabReview;

  /// No description provided for @boardKindBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get boardKindBug;

  /// No description provided for @boardKindIdea.
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get boardKindIdea;

  /// No description provided for @boardAreaDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get boardAreaDrive;

  /// No description provided for @boardAreaWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get boardAreaWrite;

  /// No description provided for @boardAreaSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get boardAreaSheets;

  /// No description provided for @boardAreaSlides.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get boardAreaSlides;

  /// Board area: sign-in, settings, menus shared by all apps.
  ///
  /// In en, this message translates to:
  /// **'Suite'**
  String get boardAreaSuite;

  /// No description provided for @boardAreaServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get boardAreaServer;

  /// No description provided for @boardSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get boardSizeSmall;

  /// No description provided for @boardSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get boardSizeMedium;

  /// No description provided for @boardSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get boardSizeLarge;

  /// No description provided for @boardStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get boardStatusOpen;

  /// No description provided for @boardStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get boardStatusPlanned;

  /// No description provided for @boardStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get boardStatusDone;

  /// No description provided for @boardStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get boardStatusShipped;

  /// No description provided for @boardStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get boardStatusDeclined;

  /// No description provided for @boardStatusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get boardStatusDuplicate;

  /// No description provided for @boardTaskDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get boardTaskDraft;

  /// No description provided for @boardTaskPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get boardTaskPublished;

  /// No description provided for @boardTaskClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get boardTaskClaimed;

  /// No description provided for @boardTaskInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get boardTaskInReview;

  /// No description provided for @boardTaskCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get boardTaskCancelled;

  /// No description provided for @boardModerationChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get boardModerationChecking;

  /// No description provided for @boardModerationVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get boardModerationVisible;

  /// No description provided for @boardModerationHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get boardModerationHeld;

  /// No description provided for @boardModerationRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get boardModerationRemoved;

  /// No description provided for @boardReasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive'**
  String get boardReasonOffensive;

  /// No description provided for @boardReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get boardReasonSpam;

  /// No description provided for @boardReasonPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get boardReasonPersonalData;

  /// No description provided for @boardReasonSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security issue'**
  String get boardReasonSecurity;

  /// No description provided for @boardReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get boardReasonOther;

  /// No description provided for @boardSortTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get boardSortTrending;

  /// No description provided for @boardSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get boardSortTop;

  /// No description provided for @boardSortNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get boardSortNew;

  /// No description provided for @boardSortDiscussed.
  ///
  /// In en, this message translates to:
  /// **'Most discussed'**
  String get boardSortDiscussed;

  /// No description provided for @boardSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get boardSort;

  /// No description provided for @boardFilterArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get boardFilterArea;

  /// No description provided for @boardFilterSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get boardFilterSize;

  /// No description provided for @boardFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get boardFilterStatus;

  /// Board filter: issues I wrote or voted on.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get boardFilterMine;

  /// No description provided for @boardFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get boardFilterAny;

  /// No description provided for @boardSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get boardSelect;

  /// No description provided for @boardSelectDone.
  ///
  /// In en, this message translates to:
  /// **'Done selecting'**
  String get boardSelectDone;

  /// No description provided for @boardSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String boardSelected(int count);

  /// No description provided for @boardCreateTaskFrom.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Create task from 1 issue…} other{Create task from {count} issues…}}'**
  String boardCreateTaskFrom(int count);

  /// No description provided for @boardCreateTaskHint.
  ///
  /// In en, this message translates to:
  /// **'The draft task gets an AI-written prompt. It is published once the prompt is written.'**
  String get boardCreateTaskHint;

  /// No description provided for @boardAddToTask.
  ///
  /// In en, this message translates to:
  /// **'Add to task'**
  String get boardAddToTask;

  /// No description provided for @boardAddToTaskEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Add to task…'**
  String get boardAddToTaskEllipsis;

  /// No description provided for @boardNoOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'There are no draft or published tasks.'**
  String get boardNoOpenTasks;

  /// No description provided for @boardLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get boardLoadMore;

  /// Under the board list: how many issues are shown.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String boardShowing(int shown, int total);

  /// No description provided for @boardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load Contribute & build'**
  String get boardLoadFailed;

  /// No description provided for @boardEmptyIdeas.
  ///
  /// In en, this message translates to:
  /// **'No improvements here yet'**
  String get boardEmptyIdeas;

  /// No description provided for @boardEmptyBugs.
  ///
  /// In en, this message translates to:
  /// **'No bugs here'**
  String get boardEmptyBugs;

  /// No description provided for @boardEmptyDone.
  ///
  /// In en, this message translates to:
  /// **'Nothing finished yet'**
  String get boardEmptyDone;

  /// No description provided for @boardEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No issues match your search'**
  String get boardEmptySearch;

  /// No description provided for @boardEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Change the filters, or be the first to report one.'**
  String get boardEmptyHint;

  /// No description provided for @boardEmptyTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks up for grabs'**
  String get boardEmptyTasks;

  /// No description provided for @boardEmptyTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Admins publish tasks from the most wanted issues. Check back soon.'**
  String get boardEmptyTasksHint;

  /// Semantics label of the up-vote button.
  ///
  /// In en, this message translates to:
  /// **'Upvote, {score} votes'**
  String boardUpvoteLabel(int score);

  /// No description provided for @boardDownvoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Downvote, {score} votes'**
  String boardDownvoteLabel(int score);

  /// No description provided for @boardRemoveUpvote.
  ///
  /// In en, this message translates to:
  /// **'Remove upvote'**
  String get boardRemoveUpvote;

  /// No description provided for @boardRemoveDownvote.
  ///
  /// In en, this message translates to:
  /// **'Remove downvote'**
  String get boardRemoveDownvote;

  /// Tooltip of the disabled down-vote arrow on bugs.
  ///
  /// In en, this message translates to:
  /// **'Bugs can only be upvoted'**
  String get boardBugsUpvoteOnly;

  /// Semantics label of the disabled down-vote arrow on bugs.
  ///
  /// In en, this message translates to:
  /// **'Downvote, unavailable: bugs can only be upvoted'**
  String get boardDownvoteUnavailable;

  /// Marker on labels set by AI and not yet confirmed by an admin.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get boardAiMarker;

  /// No description provided for @boardAiLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}, set by AI'**
  String boardAiLabel(String label);

  /// No description provided for @boardPlannedIn.
  ///
  /// In en, this message translates to:
  /// **'Planned · T-{number}'**
  String boardPlannedIn(int number);

  /// No description provided for @boardCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String boardCommentCount(int count);

  /// No description provided for @boardHasScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Has a screenshot'**
  String get boardHasScreenshot;

  /// No description provided for @boardDeletedUser.
  ///
  /// In en, this message translates to:
  /// **'Deleted user'**
  String get boardDeletedUser;

  /// No description provided for @boardAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get boardAdmin;

  /// No description provided for @boardEdited.
  ///
  /// In en, this message translates to:
  /// **'edited {time}'**
  String boardEdited(String time);

  /// No description provided for @boardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get boardCopy;

  /// No description provided for @boardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get boardCopied;

  /// No description provided for @boardPromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied'**
  String get boardPromptCopied;

  /// No description provided for @boardFlagged.
  ///
  /// In en, this message translates to:
  /// **'Thanks. A moderator will take a look.'**
  String get boardFlagged;

  /// No description provided for @boardPostNotFound.
  ///
  /// In en, this message translates to:
  /// **'Issue #{number} doesn\'t exist or isn\'t public'**
  String boardPostNotFound(int number);

  /// No description provided for @boardTaskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task T-{number} doesn\'t exist'**
  String boardTaskNotFound(int number);

  /// No description provided for @boardBackToBoard.
  ///
  /// In en, this message translates to:
  /// **'Back to Contribute & build'**
  String get boardBackToBoard;

  /// Heading of the admin entries in the issue's actions menu.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get boardAdminActions;

  /// No description provided for @boardEditAndApprove.
  ///
  /// In en, this message translates to:
  /// **'Edit and approve…'**
  String get boardEditAndApprove;

  /// No description provided for @boardActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get boardActionApprove;

  /// No description provided for @boardActionHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get boardActionHold;

  /// No description provided for @boardActionLooksFine.
  ///
  /// In en, this message translates to:
  /// **'Looks fine'**
  String get boardActionLooksFine;

  /// No description provided for @boardActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get boardActionRestore;

  /// No description provided for @boardActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get boardActionRemove;

  /// No description provided for @boardActionRemoveEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Remove…'**
  String get boardActionRemoveEllipsis;

  /// No description provided for @boardActionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get boardActionDecline;

  /// No description provided for @boardActionMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get boardActionMerge;

  /// No description provided for @boardActionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get boardActionBlock;

  /// No description provided for @boardActionCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get boardActionCreateTask;

  /// No description provided for @boardActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get boardActionAdd;

  /// No description provided for @boardActionLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get boardActionLink;

  /// No description provided for @boardSelectForBuilding.
  ///
  /// In en, this message translates to:
  /// **'Select for building'**
  String get boardSelectForBuilding;

  /// No description provided for @boardDeclineEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Decline…'**
  String get boardDeclineEllipsis;

  /// No description provided for @boardMergeEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Merge into…'**
  String get boardMergeEllipsis;

  /// No description provided for @boardLabelsEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Labels…'**
  String get boardLabelsEllipsis;

  /// No description provided for @boardBlockEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Block user from the board…'**
  String get boardBlockEllipsis;

  /// No description provided for @boardEditEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Edit…'**
  String get boardEditEllipsis;

  /// No description provided for @boardDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get boardDismiss;

  /// No description provided for @boardApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get boardApply;

  /// No description provided for @boardMergedFromNote.
  ///
  /// In en, this message translates to:
  /// **'#{number} was merged into this issue.'**
  String boardMergedFromNote(int number);

  /// No description provided for @boardPostDeleted.
  ///
  /// In en, this message translates to:
  /// **'This issue was deleted.'**
  String get boardPostDeleted;

  /// No description provided for @boardChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your issue…'**
  String get boardChecking;

  /// No description provided for @boardWaitingForReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review: a moderator will look at it.'**
  String get boardWaitingForReview;

  /// No description provided for @boardHeldAdmin.
  ///
  /// In en, this message translates to:
  /// **'Held for review. {reason}'**
  String boardHeldAdmin(String reason);

  /// No description provided for @boardRemovedByModerator.
  ///
  /// In en, this message translates to:
  /// **'Removed by a moderator. {reason}'**
  String boardRemovedByModerator(String reason);

  /// No description provided for @boardDeclinedNote.
  ///
  /// In en, this message translates to:
  /// **'Declined: {reason}'**
  String boardDeclinedNote(String reason);

  /// No description provided for @boardMergedInto.
  ///
  /// In en, this message translates to:
  /// **'Merged into #{number}.'**
  String boardMergedInto(int number);

  /// No description provided for @boardOpenPost.
  ///
  /// In en, this message translates to:
  /// **'Open #{number}'**
  String boardOpenPost(int number);

  /// No description provided for @boardMovedToIdeas.
  ///
  /// In en, this message translates to:
  /// **'Moved to Improvements'**
  String get boardMovedToIdeas;

  /// No description provided for @boardMovedToBugs.
  ///
  /// In en, this message translates to:
  /// **'Moved to Bugs'**
  String get boardMovedToBugs;

  /// No description provided for @boardEditedByModerator.
  ///
  /// In en, this message translates to:
  /// **'Edited by a moderator'**
  String get boardEditedByModerator;

  /// No description provided for @boardDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get boardDetails;

  /// No description provided for @boardAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get boardAdminPanel;

  /// No description provided for @boardTriage.
  ///
  /// In en, this message translates to:
  /// **'Triage: {state}'**
  String boardTriage(String state);

  /// No description provided for @boardNeedsCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get boardNeedsCheck;

  /// No description provided for @boardNeedsLabels.
  ///
  /// In en, this message translates to:
  /// **'Needs labels'**
  String get boardNeedsLabels;

  /// No description provided for @boardSuggestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested title: {title}'**
  String boardSuggestedTitle(String title);

  /// No description provided for @boardPossibleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate of #{number}'**
  String boardPossibleDuplicate(int number);

  /// No description provided for @boardAiScores.
  ///
  /// In en, this message translates to:
  /// **'AI scores'**
  String get boardAiScores;

  /// No description provided for @boardFlags.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flag} other{{count} flags}}: {reasons}'**
  String boardFlags(int count, String reasons);

  /// No description provided for @boardOpenScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Open screenshot'**
  String get boardOpenScreenshot;

  /// No description provided for @boardScreenshotAlt.
  ///
  /// In en, this message translates to:
  /// **'Screenshot of issue #{number}'**
  String boardScreenshotAlt(int number);

  /// No description provided for @boardRelations.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get boardRelations;

  /// No description provided for @boardPartOfTask.
  ///
  /// In en, this message translates to:
  /// **'Part of task T-{number}: {title}'**
  String boardPartOfTask(int number, String title);

  /// No description provided for @boardMergedFrom.
  ///
  /// In en, this message translates to:
  /// **'Duplicates merged into this issue:'**
  String get boardMergedFrom;

  /// No description provided for @boardSimilarPosts.
  ///
  /// In en, this message translates to:
  /// **'Similar issues'**
  String get boardSimilarPosts;

  /// No description provided for @boardScore.
  ///
  /// In en, this message translates to:
  /// **'{score, plural, =1{1 vote} other{{score} votes}}'**
  String boardScore(int score);

  /// No description provided for @boardCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String boardCommentsTitle(int count);

  /// No description provided for @boardCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get boardCommentHint;

  /// No description provided for @boardCommentHeld.
  ///
  /// In en, this message translates to:
  /// **'Hidden pending review'**
  String get boardCommentHeld;

  /// No description provided for @boardCommentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed by a moderator'**
  String get boardCommentRemoved;

  /// No description provided for @boardCommentOnPost.
  ///
  /// In en, this message translates to:
  /// **'Comment on #{number}'**
  String boardCommentOnPost(int number);

  /// No description provided for @boardCommentOnTask.
  ///
  /// In en, this message translates to:
  /// **'Comment on T-{number}'**
  String boardCommentOnTask(int number);

  /// No description provided for @boardEventClaimed.
  ///
  /// In en, this message translates to:
  /// **'claimed the task'**
  String get boardEventClaimed;

  /// No description provided for @boardEventReleased.
  ///
  /// In en, this message translates to:
  /// **'released the claim'**
  String get boardEventReleased;

  /// No description provided for @boardEventExpired.
  ///
  /// In en, this message translates to:
  /// **'The claim expired'**
  String get boardEventExpired;

  /// No description provided for @boardEventPrLinked.
  ///
  /// In en, this message translates to:
  /// **'linked a pull request: {url}'**
  String boardEventPrLinked(String url);

  /// No description provided for @boardEventPrUnlinked.
  ///
  /// In en, this message translates to:
  /// **'unlinked the pull request'**
  String get boardEventPrUnlinked;

  /// No description provided for @boardEventPublished.
  ///
  /// In en, this message translates to:
  /// **'published the task'**
  String get boardEventPublished;

  /// No description provided for @boardEventDone.
  ///
  /// In en, this message translates to:
  /// **'marked the task done'**
  String get boardEventDone;

  /// No description provided for @boardEventShipped.
  ///
  /// In en, this message translates to:
  /// **'marked the task shipped'**
  String get boardEventShipped;

  /// No description provided for @boardEventCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled the task'**
  String get boardEventCancelled;

  /// No description provided for @boardEventMerged.
  ///
  /// In en, this message translates to:
  /// **'merged a duplicate'**
  String get boardEventMerged;

  /// Task activity (admins): the task was merged into another one. {task} is like T-3.
  ///
  /// In en, this message translates to:
  /// **'merged this task into {task}'**
  String boardEventMergedInto(String task);

  /// Task activity (admins): other tasks were merged into this one. {tasks} is like 'T-5, T-7'.
  ///
  /// In en, this message translates to:
  /// **'merged {tasks} into this task'**
  String boardEventMergedTasks(String tasks);

  /// No description provided for @boardEventUnmerged.
  ///
  /// In en, this message translates to:
  /// **'undid a merge of tasks'**
  String get boardEventUnmerged;

  /// No description provided for @boardEventRewriting.
  ///
  /// In en, this message translates to:
  /// **'changed the issues; the task is a draft until the AI has rewritten the prompt'**
  String get boardEventRewriting;

  /// Up for grabs selection bar (admins) and the merge dialog's title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Merge 1 task…} other{Merge {count} tasks…}}'**
  String boardMergeTasksTitle(int count);

  /// No description provided for @boardMergeTasksHint.
  ///
  /// In en, this message translates to:
  /// **'The oldest task keeps all the issues and gets a new AI-written prompt. The other tasks are cancelled. Until the prompt is written, the task is a draft.'**
  String get boardMergeTasksHint;

  /// No description provided for @boardMergeTasksNeedsTwo.
  ///
  /// In en, this message translates to:
  /// **'Select two tasks or more to merge them'**
  String get boardMergeTasksNeedsTwo;

  /// No description provided for @boardTaskMergedNotice.
  ///
  /// In en, this message translates to:
  /// **'This task was merged into T-{number}.'**
  String boardTaskMergedNotice(int number);

  /// No description provided for @boardOpenTask.
  ///
  /// In en, this message translates to:
  /// **'Open T-{number}'**
  String boardOpenTask(int number);

  /// No description provided for @cmdBoardMergeTasks.
  ///
  /// In en, this message translates to:
  /// **'Merge tasks'**
  String get cmdBoardMergeTasks;

  /// No description provided for @boardUpForGrabs.
  ///
  /// In en, this message translates to:
  /// **'Up for grabs'**
  String get boardUpForGrabs;

  /// No description provided for @boardClaimedBy.
  ///
  /// In en, this message translates to:
  /// **'Claimed by {name} · {hours} h left'**
  String boardClaimedBy(String name, int hours);

  /// No description provided for @boardInReviewBy.
  ///
  /// In en, this message translates to:
  /// **'In review · {name}'**
  String boardInReviewBy(String name);

  /// No description provided for @boardPostCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 issue} other{{count} issues}}'**
  String boardPostCount(int count);

  /// No description provided for @boardClaimTask.
  ///
  /// In en, this message translates to:
  /// **'Claim this task'**
  String get boardClaimTask;

  /// No description provided for @boardReleaseClaim.
  ///
  /// In en, this message translates to:
  /// **'Release claim'**
  String get boardReleaseClaim;

  /// No description provided for @boardYourClaimCode.
  ///
  /// In en, this message translates to:
  /// **'Your claim code'**
  String get boardYourClaimCode;

  /// No description provided for @boardTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} h left on your claim'**
  String boardTimeLeft(int hours);

  /// No description provided for @boardClaimCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Put it in the pull request description. Only you can see it.'**
  String get boardClaimCodeHint;

  /// No description provided for @boardClaimCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'<your claim code>'**
  String get boardClaimCodePlaceholder;

  /// No description provided for @boardDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft: only admins see this task. It is published once the AI has written its prompt, or when you save the prompt.'**
  String get boardDraftNotice;

  /// No description provided for @boardPromptWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing the prompt with AI… this takes about a minute'**
  String get boardPromptWriting;

  /// No description provided for @boardPromptNote.
  ///
  /// In en, this message translates to:
  /// **'The AI did not write the prompt: {note}'**
  String boardPromptNote(String note);

  /// No description provided for @boardTaskCancelledNotice.
  ///
  /// In en, this message translates to:
  /// **'This task was cancelled. Its issues are open again.'**
  String get boardTaskCancelledNotice;

  /// No description provided for @boardLinkedPosts.
  ///
  /// In en, this message translates to:
  /// **'Linked issues'**
  String get boardLinkedPosts;

  /// No description provided for @boardNoLinkedPosts.
  ///
  /// In en, this message translates to:
  /// **'No issues are linked to this task.'**
  String get boardNoLinkedPosts;

  /// No description provided for @boardRemoveFromTask.
  ///
  /// In en, this message translates to:
  /// **'Remove from task'**
  String get boardRemoveFromTask;

  /// No description provided for @boardAddPosts.
  ///
  /// In en, this message translates to:
  /// **'Add issues…'**
  String get boardAddPosts;

  /// No description provided for @boardFieldPostNumbers.
  ///
  /// In en, this message translates to:
  /// **'Issue numbers'**
  String get boardFieldPostNumbers;

  /// No description provided for @boardHowToBuild.
  ///
  /// In en, this message translates to:
  /// **'How to build it'**
  String get boardHowToBuild;

  /// The number of the first step of How to build it, before the link boardStepSetupLink.
  ///
  /// In en, this message translates to:
  /// **'1.'**
  String get boardStepSetupNumber;

  /// Step 1 of How to build it: a link to the How to contribute page.
  ///
  /// In en, this message translates to:
  /// **'Set up your development environment'**
  String get boardStepSetupLink;

  /// No description provided for @boardInstallTools.
  ///
  /// In en, this message translates to:
  /// **'Install Flutter, Dart and the Serverpod CLI:'**
  String get boardInstallTools;

  /// No description provided for @boardInstallGuide.
  ///
  /// In en, this message translates to:
  /// **'Serverpod installation guide'**
  String get boardInstallGuide;

  /// No description provided for @boardStepPrompt.
  ///
  /// In en, this message translates to:
  /// **'2. Give your coding agent the prompt'**
  String get boardStepPrompt;

  /// No description provided for @boardStepPr.
  ///
  /// In en, this message translates to:
  /// **'3. Open a pull request'**
  String get boardStepPr;

  /// No description provided for @boardStepPromptLocked.
  ///
  /// In en, this message translates to:
  /// **'2. Give your coding agent the prompt (claim the task to get the prompt).'**
  String get boardStepPromptLocked;

  /// No description provided for @boardPrRules.
  ///
  /// In en, this message translates to:
  /// **'One task per pull request, against main. Put these two lines in its description:'**
  String get boardPrRules;

  /// No description provided for @boardPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Pull request'**
  String get boardPullRequest;

  /// No description provided for @boardPrNumber.
  ///
  /// In en, this message translates to:
  /// **'Pull request #{number}'**
  String boardPrNumber(int number);

  /// No description provided for @boardPrBy.
  ///
  /// In en, this message translates to:
  /// **'by {login}'**
  String boardPrBy(String login);

  /// No description provided for @boardLatestReview.
  ///
  /// In en, this message translates to:
  /// **'Latest review'**
  String get boardLatestReview;

  /// Heading of a task's activity rows (claimed, released, PR linked …), shown to admins.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get boardActivity;

  /// No description provided for @boardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get boardNoActivity;

  /// No description provided for @boardClaimForPrompt.
  ///
  /// In en, this message translates to:
  /// **'Claim this task to get the prompt.'**
  String get boardClaimForPrompt;

  /// No description provided for @boardContributeTitle.
  ///
  /// In en, this message translates to:
  /// **'How to contribute'**
  String get boardContributeTitle;

  /// No description provided for @boardContributeIntro.
  ///
  /// In en, this message translates to:
  /// **'Anyone can build a task that is up for grabs. Claim it, let a coding agent do the work with the task\'s prompt, and open a pull request.'**
  String get boardContributeIntro;

  /// No description provided for @boardContribStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Get the tools'**
  String get boardContribStep1Title;

  /// No description provided for @boardContribStep1.
  ///
  /// In en, this message translates to:
  /// **'Install Flutter, Dart and the Serverpod CLI, and an AI coding agent that reads AGENTS.md, such as Claude Code.'**
  String get boardContribStep1;

  /// No description provided for @boardContribStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Install or update the Serverpod CLI'**
  String get boardContribStep2Title;

  /// No description provided for @boardContribStep2.
  ///
  /// In en, this message translates to:
  /// **'It runs the server and the apps. The same command updates an installed CLI to this version. Add Dart\'s install directory to your PATH if serverpod is not found.'**
  String get boardContribStep2;

  /// No description provided for @boardContribStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Fork the repository'**
  String get boardContribStep3Title;

  /// No description provided for @boardContribStep3.
  ///
  /// In en, this message translates to:
  /// **'Create your own copy of the repository on GitHub. You push your changes to your fork and open the pull request from there.'**
  String get boardContribStep3;

  /// No description provided for @boardContribForkLink.
  ///
  /// In en, this message translates to:
  /// **'Fork on GitHub'**
  String get boardContribForkLink;

  /// No description provided for @boardContribStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Clone the repository'**
  String get boardContribStep4Title;

  /// No description provided for @boardContribStep4.
  ///
  /// In en, this message translates to:
  /// **'Clone your fork to your machine (replace <you> with your GitHub username) and get the packages.'**
  String get boardContribStep4;

  /// No description provided for @boardContribStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Configure the server'**
  String get boardContribStep5Title;

  /// No description provided for @boardContribStep5.
  ///
  /// In en, this message translates to:
  /// **'Create your passwords file in wonky_server and replace the CHANGE_ME values. AI keys are optional.'**
  String get boardContribStep5;

  /// No description provided for @boardContribStep6Title.
  ///
  /// In en, this message translates to:
  /// **'Start the server'**
  String get boardContribStep6Title;

  /// No description provided for @boardContribStep6.
  ///
  /// In en, this message translates to:
  /// **'Run it in wonky_server: it starts the development database, applies the migrations and hot reloads. Start an app from its UI or let your agent do it through the serverpod MCP server (.mcp.json is in the repository). Sign up with any email; in development the code is in the server log.'**
  String get boardContribStep6;

  /// No description provided for @boardContribStep7Title.
  ///
  /// In en, this message translates to:
  /// **'Pick a task'**
  String get boardContribStep7Title;

  /// No description provided for @boardContribStep7.
  ///
  /// In en, this message translates to:
  /// **'Claim a task under Up for grabs, paste its prompt into your agent and review the result.'**
  String get boardContribStep7;

  /// No description provided for @boardContribStep8Title.
  ///
  /// In en, this message translates to:
  /// **'Open a pull request'**
  String get boardContribStep8Title;

  /// No description provided for @boardContribStep8.
  ///
  /// In en, this message translates to:
  /// **'One task per pull request. The description contains the Wonky-Task and Wonky-Claim lines from the task page. Pull requests without a valid task are closed after 7 days.'**
  String get boardContribStep8;

  /// No description provided for @boardContribStep9Title.
  ///
  /// In en, this message translates to:
  /// **'Sign the CLA and follow up'**
  String get boardContribStep9Title;

  /// No description provided for @boardContribStep9.
  ///
  /// In en, this message translates to:
  /// **'If you haven\'t signed the Serverpod contributor license agreement (CLA) yet, sign it on GitHub: the CLA Assistant bot asks for it on your pull request, and you reply with the line below. You sign it once. Then check back once your pull request has been reviewed, and fix any issues the review points out.'**
  String get boardContribStep9;

  /// No description provided for @boardContribLicense.
  ///
  /// In en, this message translates to:
  /// **'Contributions are accepted under the repository\'s BSD-3-Clause license.'**
  String get boardContribLicense;

  /// No description provided for @boardContribSecurity.
  ///
  /// In en, this message translates to:
  /// **'Found a security issue? Email {email}. Never post it on the board or in a pull request.'**
  String boardContribSecurity(String email);

  /// No description provided for @boardContributeGuide.
  ///
  /// In en, this message translates to:
  /// **'Full guide on GitHub'**
  String get boardContributeGuide;

  /// No description provided for @boardFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get boardFieldTitle;

  /// No description provided for @boardTitleLength.
  ///
  /// In en, this message translates to:
  /// **'Use 8 to 120 characters.'**
  String get boardTitleLength;

  /// No description provided for @boardModeratorEditHint.
  ///
  /// In en, this message translates to:
  /// **'The issue shows Edited by a moderator.'**
  String get boardModeratorEditHint;

  /// No description provided for @boardFieldReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get boardFieldReason;

  /// No description provided for @boardFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get boardFieldNote;

  /// No description provided for @boardFieldNoteForAuthor.
  ///
  /// In en, this message translates to:
  /// **'Message to the author (optional)'**
  String get boardFieldNoteForAuthor;

  /// No description provided for @boardFlagHint.
  ///
  /// In en, this message translates to:
  /// **'Flagged issues are hidden for review after 3 people flag them.'**
  String get boardFlagHint;

  /// No description provided for @boardFlagAction.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get boardFlagAction;

  /// No description provided for @boardRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get boardRemoveTitle;

  /// No description provided for @boardDeclineOutOfScope.
  ///
  /// In en, this message translates to:
  /// **'Out of scope'**
  String get boardDeclineOutOfScope;

  /// No description provided for @boardDeclineAsIntended.
  ///
  /// In en, this message translates to:
  /// **'Works as intended'**
  String get boardDeclineAsIntended;

  /// No description provided for @boardDeclineWontFix.
  ///
  /// In en, this message translates to:
  /// **'Won\'t fix'**
  String get boardDeclineWontFix;

  /// No description provided for @boardBlockHint.
  ///
  /// In en, this message translates to:
  /// **'{name} can still read the board but can\'t post, vote or comment.'**
  String boardBlockHint(String name);

  /// No description provided for @boardMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Votes on #{number} move to the issue that remains.'**
  String boardMergeHint(int number);

  /// No description provided for @boardFieldTargetPost.
  ///
  /// In en, this message translates to:
  /// **'Issue that remains'**
  String get boardFieldTargetPost;

  /// No description provided for @boardInvalidPostNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter an issue number'**
  String get boardInvalidPostNumber;

  /// No description provided for @boardMergeSelf.
  ///
  /// In en, this message translates to:
  /// **'An issue can\'t be merged into itself'**
  String get boardMergeSelf;

  /// No description provided for @boardFieldKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get boardFieldKind;

  /// No description provided for @boardFieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get boardFieldArea;

  /// No description provided for @boardFieldSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get boardFieldSize;

  /// No description provided for @boardNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get boardNoLabel;

  /// No description provided for @boardFieldTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get boardFieldTask;

  /// No description provided for @boardLinkPrHint.
  ///
  /// In en, this message translates to:
  /// **'A pull request of the repository. Leave it empty to unlink.'**
  String get boardLinkPrHint;

  /// No description provided for @boardFieldPrUrl.
  ///
  /// In en, this message translates to:
  /// **'Pull request URL'**
  String get boardFieldPrUrl;

  /// No description provided for @boardInvalidPrUrl.
  ///
  /// In en, this message translates to:
  /// **'Use a github.com pull request URL'**
  String get boardInvalidPrUrl;

  /// No description provided for @boardRemoveScreenshotHint.
  ///
  /// In en, this message translates to:
  /// **'The screenshot is deleted for good.'**
  String get boardRemoveScreenshotHint;

  /// No description provided for @boardPromptEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt of T-{number}'**
  String boardPromptEditorTitle(int number);

  /// No description provided for @boardPromptEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Contributors run this prompt in coding agents. Read it all before saving.'**
  String get boardPromptEditorHint;

  /// No description provided for @boardPromptSavePublishes.
  ///
  /// In en, this message translates to:
  /// **'Saving publishes the task.'**
  String get boardPromptSavePublishes;

  /// No description provided for @boardPromptDiffTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes from Regenerate'**
  String get boardPromptDiffTitle;

  /// No description provided for @boardLintTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unusual instruction} other{{count} unusual instructions}}: check before saving'**
  String boardLintTitle(int count);

  /// No description provided for @boardLintCommand.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: command {text}'**
  String boardLintCommand(int line, String text);

  /// No description provided for @boardLintUrl.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: link outside the repository {text}'**
  String boardLintUrl(int line, String text);

  /// No description provided for @boardLintWording.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: “{text}”'**
  String boardLintWording(int line, String text);

  /// No description provided for @boardReviewHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get boardReviewHeld;

  /// No description provided for @boardReviewCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get boardReviewCheck;

  /// No description provided for @boardReviewUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Unchecked'**
  String get boardReviewUnchecked;

  /// No description provided for @boardReviewDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicates'**
  String get boardReviewDuplicates;

  /// No description provided for @boardReviewBundles.
  ///
  /// In en, this message translates to:
  /// **'Suggested bundles'**
  String get boardReviewBundles;

  /// No description provided for @boardReviewDrafts.
  ///
  /// In en, this message translates to:
  /// **'Draft tasks'**
  String get boardReviewDrafts;

  /// No description provided for @boardReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review.'**
  String get boardReviewEmpty;

  /// No description provided for @cmdBoardVote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get cmdBoardVote;

  /// No description provided for @cmdBoardCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get cmdBoardCreatePost;

  /// No description provided for @cmdBoardEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit issue'**
  String get cmdBoardEditPost;

  /// No description provided for @cmdBoardDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete issue'**
  String get cmdBoardDeletePost;

  /// No description provided for @cmdBoardRemoveScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove screenshot'**
  String get cmdBoardRemoveScreenshot;

  /// No description provided for @cmdBoardComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get cmdBoardComment;

  /// No description provided for @cmdBoardEditComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get cmdBoardEditComment;

  /// No description provided for @cmdBoardDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get cmdBoardDeleteComment;

  /// No description provided for @cmdBoardFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag…'**
  String get cmdBoardFlag;

  /// No description provided for @cmdBoardClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim task'**
  String get cmdBoardClaim;

  /// No description provided for @cmdBoardRelease.
  ///
  /// In en, this message translates to:
  /// **'Unclaim this task'**
  String get cmdBoardRelease;

  /// No description provided for @cmdBoardCopyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy prompt'**
  String get cmdBoardCopyPrompt;

  /// No description provided for @cmdBoardCopyClaimCode.
  ///
  /// In en, this message translates to:
  /// **'Copy claim code'**
  String get cmdBoardCopyClaimCode;

  /// No description provided for @cmdBoardModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get cmdBoardModerate;

  /// No description provided for @cmdBoardSetLabels.
  ///
  /// In en, this message translates to:
  /// **'Set kind, area and size…'**
  String get cmdBoardSetLabels;

  /// No description provided for @cmdBoardAdminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit as moderator…'**
  String get cmdBoardAdminEdit;

  /// No description provided for @cmdBoardApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply suggested title'**
  String get cmdBoardApplyTitle;

  /// No description provided for @cmdBoardNotDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Not a duplicate'**
  String get cmdBoardNotDuplicate;

  /// No description provided for @cmdBoardMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge into…'**
  String get cmdBoardMerge;

  /// No description provided for @cmdBoardUnmerge.
  ///
  /// In en, this message translates to:
  /// **'Unmerge'**
  String get cmdBoardUnmerge;

  /// No description provided for @cmdBoardDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get cmdBoardDecline;

  /// No description provided for @cmdBoardReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get cmdBoardReopen;

  /// No description provided for @cmdBoardBlock.
  ///
  /// In en, this message translates to:
  /// **'Block user from the board'**
  String get cmdBoardBlock;

  /// No description provided for @cmdBoardCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get cmdBoardCreateTask;

  /// No description provided for @cmdBoardEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get cmdBoardEditTask;

  /// No description provided for @cmdBoardSetTaskPosts.
  ///
  /// In en, this message translates to:
  /// **'Change the task\'s issues'**
  String get cmdBoardSetTaskPosts;

  /// No description provided for @cmdBoardRegeneratePrompt.
  ///
  /// In en, this message translates to:
  /// **'Regenerate prompt'**
  String get cmdBoardRegeneratePrompt;

  /// No description provided for @cmdBoardEditPrompt.
  ///
  /// In en, this message translates to:
  /// **'Edit prompt'**
  String get cmdBoardEditPrompt;

  /// No description provided for @cmdBoardPublishTask.
  ///
  /// In en, this message translates to:
  /// **'Publish task'**
  String get cmdBoardPublishTask;

  /// No description provided for @cmdBoardLinkPr.
  ///
  /// In en, this message translates to:
  /// **'Link pull request…'**
  String get cmdBoardLinkPr;

  /// No description provided for @cmdBoardMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get cmdBoardMarkDone;

  /// No description provided for @cmdBoardMarkShipped.
  ///
  /// In en, this message translates to:
  /// **'Mark shipped'**
  String get cmdBoardMarkShipped;

  /// No description provided for @cmdBoardCancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel task'**
  String get cmdBoardCancelTask;

  /// No description provided for @cmdBoardSuggestBundles.
  ///
  /// In en, this message translates to:
  /// **'Suggest bundles'**
  String get cmdBoardSuggestBundles;

  /// No description provided for @cmdBoardDismissSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Dismiss suggestion'**
  String get cmdBoardDismissSuggestion;

  /// Notification settings: replies, status changes and claims on the board.
  ///
  /// In en, this message translates to:
  /// **'Bugs & improvements'**
  String get notifyBoard;

  /// No description provided for @notifyBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Replies to your issues, status changes and your task claims'**
  String get notifyBoardHint;

  /// No description provided for @boardEventPrClosed.
  ///
  /// In en, this message translates to:
  /// **'Pull request closed without merge: {url}. The task is open again.'**
  String boardEventPrClosed(String url);

  /// No description provided for @boardEventPrMerged.
  ///
  /// In en, this message translates to:
  /// **'Pull request merged: {url}'**
  String boardEventPrMerged(String url);

  /// No description provided for @boardEventPrOpened.
  ///
  /// In en, this message translates to:
  /// **'Pull request opened: {url}'**
  String boardEventPrOpened(String url);

  /// No description provided for @boardEventDeployed.
  ///
  /// In en, this message translates to:
  /// **'Shipped in deploy {sha}'**
  String boardEventDeployed(String sha);

  /// No description provided for @boardVerdictMet.
  ///
  /// In en, this message translates to:
  /// **'Met'**
  String get boardVerdictMet;

  /// No description provided for @boardVerdictPartly.
  ///
  /// In en, this message translates to:
  /// **'Partly'**
  String get boardVerdictPartly;

  /// No description provided for @boardVerdictNotMet.
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get boardVerdictNotMet;

  /// No description provided for @boardVerdictCantTell.
  ///
  /// In en, this message translates to:
  /// **'Can\'t tell'**
  String get boardVerdictCantTell;

  /// No description provided for @boardVerdictAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get boardVerdictAdded;

  /// No description provided for @boardVerdictUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get boardVerdictUpdated;

  /// No description provided for @boardVerdictMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get boardVerdictMissing;

  /// No description provided for @boardVerdictNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get boardVerdictNotNeeded;

  /// No description provided for @boardReviewTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get boardReviewTests;

  /// No description provided for @boardReviewSpecs.
  ///
  /// In en, this message translates to:
  /// **'Specs'**
  String get boardReviewSpecs;

  /// No description provided for @boardReviewRisks.
  ///
  /// In en, this message translates to:
  /// **'Risks'**
  String get boardReviewRisks;

  /// No description provided for @boardReviewUnrelated.
  ///
  /// In en, this message translates to:
  /// **'Changes the task didn\'t ask for'**
  String get boardReviewUnrelated;

  /// No description provided for @boardReviewedSha.
  ///
  /// In en, this message translates to:
  /// **'Reviewed at {sha}'**
  String boardReviewedSha(String sha);
}

class _WonkyAppLocalizationsDelegate
    extends LocalizationsDelegate<WonkyAppLocalizations> {
  const _WonkyAppLocalizationsDelegate();

  @override
  Future<WonkyAppLocalizations> load(Locale locale) {
    return SynchronousFuture<WonkyAppLocalizations>(
      lookupWonkyAppLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_WonkyAppLocalizationsDelegate old) => false;
}

WonkyAppLocalizations lookupWonkyAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return WonkyAppLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return WonkyAppLocalizationsEn();
  }

  throw FlutterError(
    'WonkyAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
