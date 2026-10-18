import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'slides_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SlidesLocalizations
/// returned by `SlidesLocalizations.of(context)`.
///
/// Applications need to include `SlidesLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/slides_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SlidesLocalizations.localizationsDelegates,
///   supportedLocales: SlidesLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the SlidesLocalizations.supportedLocales
/// property.
abstract class SlidesLocalizations {
  SlidesLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SlidesLocalizations of(BuildContext context) {
    return Localizations.of<SlidesLocalizations>(context, SlidesLocalizations)!;
  }

  static const LocalizationsDelegate<SlidesLocalizations> delegate =
      _SlidesLocalizationsDelegate();

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

  /// Default name of a new presentation.
  ///
  /// In en, this message translates to:
  /// **'Untitled presentation'**
  String get untitledPresentation;

  /// Title of the placeholder deck editor while Wonky Slides is being built (Slides 12 SL-1).
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get editorComingSoonTitle;

  /// Description of the placeholder deck editor.
  ///
  /// In en, this message translates to:
  /// **'Wonky Slides is being built. The presentation editor is on its way — your presentations stay safe in Wonky Drive meanwhile.'**
  String get editorComingSoonBody;

  /// Button on placeholder pages that returns to the Slides home.
  ///
  /// In en, this message translates to:
  /// **'Back to Slides'**
  String get backToSlides;

  /// Load state while a presentation downloads to this device (with a percentage).
  ///
  /// In en, this message translates to:
  /// **'Downloading presentation…'**
  String get deckDownloading;

  /// Load state while a presentation is read from the device.
  ///
  /// In en, this message translates to:
  /// **'Opening presentation… ({rows} rows)'**
  String deckOpening(int rows);

  /// Shown when a presentation that isn't on this device is opened offline.
  ///
  /// In en, this message translates to:
  /// **'This presentation isn’t available offline.'**
  String get deckNotAvailableOffline;

  /// Shown when the server refuses to open a presentation.
  ///
  /// In en, this message translates to:
  /// **'You don’t have access to this presentation.'**
  String get deckNoAccess;

  /// Shown when a presentation didn't arrive on this device.
  ///
  /// In en, this message translates to:
  /// **'This presentation could not be downloaded.'**
  String get deckDownloadFailed;

  /// Shown when opening a presentation failed.
  ///
  /// In en, this message translates to:
  /// **'This presentation could not be opened.'**
  String get deckOpenFailed;

  /// Shown when the presentation's data is missing on this device.
  ///
  /// In en, this message translates to:
  /// **'This presentation isn’t on this device.'**
  String get deckNotOnDevice;

  /// Shown in an open presentation after it was unshared or trashed.
  ///
  /// In en, this message translates to:
  /// **'You no longer have access to this presentation.'**
  String get deckAccessRemoved;

  /// Refusal of an edit made before the presentation finished opening.
  ///
  /// In en, this message translates to:
  /// **'The presentation is still opening.'**
  String get deckStillOpening;

  /// Shown when the local presentation database could not be started.
  ///
  /// In en, this message translates to:
  /// **'The presentation storage on this device didn\'t start. Try again, or reload the page.'**
  String get screenStorageUnavailable;

  /// Toast when a presentation is created offline before this device prepared space for offline creation.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to create a presentation'**
  String get createNeedsConnectionTitle;

  /// Toast description when a presentation can't be created offline yet.
  ///
  /// In en, this message translates to:
  /// **'This device can create presentations offline once it has been online for a moment.'**
  String get createNeedsConnectionBody;

  /// Title of the warning that offline storage is limited (no OPFS).
  ///
  /// In en, this message translates to:
  /// **'Offline storage is limited in this browser'**
  String get storageLimitedTitle;

  /// Description of the limited offline storage warning.
  ///
  /// In en, this message translates to:
  /// **'This browser keeps offline presentations in memory. Only about {elements} objects stay available offline; the presentations you opened least recently are removed from this device first.'**
  String storageLimitedDescription(String elements);

  /// Toast when the local presentation database couldn't be opened.
  ///
  /// In en, this message translates to:
  /// **'Your offline presentation data couldn\'t be opened'**
  String get recoveryTitle;

  /// Toast description with the number of presentations with unsynced changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 presentation had changes that weren\'t synced yet. Download them before they\'re lost.} other{{count} presentations had changes that weren\'t synced yet. Download them before they\'re lost.}}'**
  String recoveryDescription(int count);

  /// Toast action that downloads the unsynced presentations.
  ///
  /// In en, this message translates to:
  /// **'Download unsynced changes'**
  String get recoveryDownload;

  /// Error toast when the recovery download failed.
  ///
  /// In en, this message translates to:
  /// **'The unsynced changes could not be exported'**
  String get recoveryFailed;

  /// Title of the command `slides.file.importSlides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Import slides…'**
  String get cmdFileImportSlides;

  /// Title of the command `slides.file.download` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get cmdFileDownload;

  /// Title of the command `slides.history.nameCurrentVersion` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Name current version'**
  String get cmdHistoryNameCurrentVersion;

  /// Title of the command `slides.history.open` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'See version history'**
  String get cmdHistoryOpen;

  /// Title of the command `slides.file.setLanguage` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get cmdFileSetLanguage;

  /// Title of the command `slides.file.pageSetup` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Page setup…'**
  String get cmdFilePageSetup;

  /// Title of the command `slides.print.open` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get cmdPrintOpen;

  /// Title of the command `slides.edit.pasteSpecial` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Paste special'**
  String get cmdEditPasteSpecial;

  /// Title of the command `slides.edit.duplicate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get cmdEditDuplicate;

  /// Title of the command `slides.edit.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cmdEditDelete;

  /// Title of the command `slides.select.escape` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get cmdSelectEscape;

  /// Title of the command `slides.select.enterGroup` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Enter group'**
  String get cmdSelectEnterGroup;

  /// Title of the command `slides.element.activate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Edit text'**
  String get cmdElementActivate;

  /// Title of the command `slides.find.open` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get cmdFindOpen;

  /// Title of the command `slides.find.openReplace` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get cmdFindOpenReplace;

  /// Title of the command `slides.format.copyStyle` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Copy style'**
  String get cmdFormatCopyStyle;

  /// Title of the command `slides.format.pasteStyle` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Paste style'**
  String get cmdFormatPasteStyle;

  /// Title of the command `slides.present.fromCurrent` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Present from current slide'**
  String get cmdPresentFromCurrent;

  /// Title of the command `slides.present.fromStart` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Present from beginning'**
  String get cmdPresentFromStart;

  /// Title of the command `slides.present.presenterView` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Presenter view'**
  String get cmdPresentPresenterView;

  /// Title of the command `slides.present.rehearse` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rehearse'**
  String get cmdPresentRehearse;

  /// Title of the command `slides.present.openOnAnotherDevice` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Open on another device…'**
  String get cmdPresentOpenOnAnotherDevice;

  /// Title of the command `slides.present.remote` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Use phone as remote'**
  String get cmdPresentRemote;

  /// Title of the command `slides.present.fromSlide` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Present from this slide'**
  String get cmdPresentFromSlide;

  /// Title of the command `slides.view.setMode` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'View mode'**
  String get cmdViewSetMode;

  /// Title of the command `slides.view.toggleNavigator` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Navigator'**
  String get cmdViewToggleNavigator;

  /// Title of the command `slides.view.toggleInspector` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get cmdViewToggleInspector;

  /// Title of the command `slides.view.toggleNotes` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Speaker notes'**
  String get cmdViewToggleNotes;

  /// Title of the command `slides.view.toggleRulers` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rulers'**
  String get cmdViewToggleRulers;

  /// Title of the command `slides.view.toggleGuides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get cmdViewToggleGuides;

  /// Title of the command `slides.view.toggleCommentPins` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Comments on canvas'**
  String get cmdViewToggleCommentPins;

  /// Title of the command `slides.view.toggleRemoteCursors` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Collaborator cursors'**
  String get cmdViewToggleRemoteCursors;

  /// Title of the command `slides.presence.jumpTo` (avatar click: their slide, their selection flashes).
  ///
  /// In en, this message translates to:
  /// **'Jump to collaborator'**
  String get cmdPresenceJumpTo;

  /// Title of the command `slides.presence.follow` (follow a collaborator's slide and view).
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get cmdPresenceFollow;

  /// Title of the command `slides.presence.unfollow`.
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get cmdPresenceUnfollow;

  /// Title of the command `slides.presence.followPresenter`.
  ///
  /// In en, this message translates to:
  /// **'Follow presenter'**
  String get cmdPresenceFollowPresenter;

  /// Title of the command `slides.text.editAnyway` (edit a text someone else is editing).
  ///
  /// In en, this message translates to:
  /// **'Edit anyway'**
  String get cmdTextEditAnyway;

  /// An agent participant writing through MCP for a user.
  ///
  /// In en, this message translates to:
  /// **'Claude via MCP ({name})'**
  String actorViaMcp(String name);

  /// The AI assistant participant working for a user.
  ///
  /// In en, this message translates to:
  /// **'Assistant ({name})'**
  String actorViaAi(String name);

  /// Avatar tooltip: what a collaborator is doing.
  ///
  /// In en, this message translates to:
  /// **'Editing slide {number} · {title}'**
  String presenceEditingSlide(int number, String title);

  /// Avatar tooltip of a collaborator in Viewing mode.
  ///
  /// In en, this message translates to:
  /// **'Viewing slide {number} · {title}'**
  String presenceViewingSlide(int number, String title);

  /// Avatar tooltip of a collaborator who presents.
  ///
  /// In en, this message translates to:
  /// **'Presenting'**
  String get presencePresenting;

  /// Avatar tooltip of a collaborator in the masters view.
  ///
  /// In en, this message translates to:
  /// **'Editing layouts'**
  String get presenceEditingLayouts;

  /// Avatar tooltip suffix: this collaborator follows you.
  ///
  /// In en, this message translates to:
  /// **'Following you'**
  String get presenceFollowingYou;

  /// Screen reader label of the presence dots of a navigator row.
  ///
  /// In en, this message translates to:
  /// **'On this slide: {names}'**
  String presenceOnSlide(String names);

  /// Screen reader label of the presence dots of a collapsed group header.
  ///
  /// In en, this message translates to:
  /// **'In this group: {names}'**
  String presenceInGroup(String names);

  /// Flag above a text box a collaborator edits (soft lock).
  ///
  /// In en, this message translates to:
  /// **'✎ {name} is editing'**
  String presenceEditingFlag(String name);

  /// Flag above a text box several collaborators edit.
  ///
  /// In en, this message translates to:
  /// **'✎ {names} editing'**
  String presenceEditingFlagMany(String names);

  /// Flag text while hovering a text box a collaborator edits.
  ///
  /// In en, this message translates to:
  /// **'{name} is editing this text — double-click to edit anyway'**
  String presenceEditingHover(String name);

  /// Soft-lock popover (04 §13.11) when entering a text someone edits.
  ///
  /// In en, this message translates to:
  /// **'{name} is editing this text.'**
  String softLockMessage(String name);

  /// Soft-lock question when entering speaker notes someone edits.
  ///
  /// In en, this message translates to:
  /// **'{name} is editing these notes.'**
  String softLockNotesMessage(String name);

  /// Popover after two people started editing one text at once and the other was first.
  ///
  /// In en, this message translates to:
  /// **'{name} started editing this text first.'**
  String softLockRaceMessage(String name);

  /// Soft-lock popover: do not edit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get softLockCancel;

  /// Soft-lock popover: edit although someone else edits.
  ///
  /// In en, this message translates to:
  /// **'Edit anyway'**
  String get softLockEditAnyway;

  /// Lost claim race: stop editing the text.
  ///
  /// In en, this message translates to:
  /// **'Stop editing'**
  String get softLockStop;

  /// Lost claim race: keep editing (both edit, the later write wins).
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get softLockKeep;

  /// Banner in the speaker notes while a collaborator edits them.
  ///
  /// In en, this message translates to:
  /// **'✎ {name} is editing the notes'**
  String notesEditingBanner(String name);

  /// Canvas banner while following a collaborator.
  ///
  /// In en, this message translates to:
  /// **'Following {name}'**
  String followBanner(String name);

  /// Stops following (canvas banner).
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get followStop;

  /// Status bar pill while a collaborator presents.
  ///
  /// In en, this message translates to:
  /// **'{name} is presenting'**
  String presenterPill(String name);

  /// Follows the presenter (status bar pill).
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get presenterFollow;

  /// Toast when following a presenter who stopped presenting.
  ///
  /// In en, this message translates to:
  /// **'That presentation has ended.'**
  String get toastPresenterNotFound;

  /// Title of the command `slides.view.toggleSmartGuides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Smart guides'**
  String get cmdViewToggleSmartGuides;

  /// Title of the command `slides.view.toggleSnapObjects` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Snap to objects'**
  String get cmdViewToggleSnapObjects;

  /// Title of the command `slides.view.toggleSnapGuides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Snap to guides'**
  String get cmdViewToggleSnapGuides;

  /// Title of the command `slides.view.toggleSnapGrid` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Snap to grid'**
  String get cmdViewToggleSnapGrid;

  /// Title of the command `slides.animate.toggleOrderOverlay` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Build order'**
  String get cmdAnimateToggleOrderOverlay;

  /// Title of the command `slides.magicMove.toggleMatches` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Magic Move matches'**
  String get cmdMagicMoveToggleMatches;

  /// Title of the command `slides.guides.add` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Add guide'**
  String get cmdGuidesAdd;

  /// Title of the command `slides.guides.clear` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Clear guides'**
  String get cmdGuidesClear;

  /// Title of the command `slides.view.zoomFit` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get cmdViewZoomFit;

  /// Title of the command `slides.view.zoom` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get cmdViewZoom;

  /// Title of the command `slides.view.zoomIn` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get cmdViewZoomIn;

  /// Title of the command `slides.view.zoomOut` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get cmdViewZoomOut;

  /// Title of the command `slides.view.zoomToSelection` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Zoom to selection'**
  String get cmdViewZoomToSelection;

  /// Title of the command `slides.panel.animate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Animate'**
  String get cmdPanelAnimate;

  /// Title of the command `slides.panel.themes` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get cmdPanelThemes;

  /// Title of the command `slides.panel.layers` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get cmdPanelLayers;

  /// Title of the command `slides.panel.accessibility` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get cmdPanelAccessibility;

  /// Title of the command `slides.panel.linkedObjects` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Linked charts'**
  String get cmdPanelLinkedObjects;

  /// Title of the command `slides.mode.editing` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get cmdModeEditing;

  /// Title of the command `slides.mode.viewing` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get cmdModeViewing;

  /// Title of the command `slides.inspector.open` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Format options…'**
  String get cmdInspectorOpen;

  /// Title of the command `slides.slide.new` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'New slide'**
  String get cmdSlideNew;

  /// Title of the command `slides.slide.duplicateForMagicMove` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Magic Move slide'**
  String get cmdSlideDuplicateForMagicMove;

  /// Title of the command `slides.insert.textBox` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Text box'**
  String get cmdInsertTextBox;

  /// Title of the command `slides.insert.image` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get cmdInsertImage;

  /// Title of the command `slides.insert.shape` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get cmdInsertShape;

  /// Title of the command `slides.insert.line` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get cmdInsertLine;

  /// Title of the command `slides.insert.table` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get cmdInsertTable;

  /// Title of the command `slides.insert.code` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get cmdInsertCode;

  /// Title of the command `slides.insert.chartFromSheets` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Chart from Wonky Sheets…'**
  String get cmdInsertChartFromSheets;

  /// Title of the command `slides.insert.chart` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get cmdInsertChart;

  /// Title of the command `slides.insert.icon` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Icon…'**
  String get cmdInsertIcon;

  /// Title of the command `slides.insert.emoji` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Emoji…'**
  String get cmdInsertEmoji;

  /// Title of the command `slides.insert.specialCharacter` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Special characters…'**
  String get cmdInsertSpecialCharacter;

  /// Title of the command `slides.insert.link` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get cmdInsertLink;

  /// Title of the command `slides.deck.openNumbering` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Slide numbers…'**
  String get cmdDeckOpenNumbering;

  /// Title of the command `slides.layout.insertPlaceholder` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get cmdLayoutInsertPlaceholder;

  /// Title of the command `slides.format.bold` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get cmdFormatBold;

  /// Title of the command `slides.format.italic` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get cmdFormatItalic;

  /// Title of the command `slides.format.underline` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get cmdFormatUnderline;

  /// Title of the command `slides.format.strikethrough` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get cmdFormatStrikethrough;

  /// Title of the command `slides.format.script` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Superscript / subscript'**
  String get cmdFormatScript;

  /// Title of the command `slides.format.increaseFontSize` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get cmdFormatIncreaseFontSize;

  /// Title of the command `slides.format.decreaseFontSize` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get cmdFormatDecreaseFontSize;

  /// Title of the command `slides.format.caps` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Capitalization'**
  String get cmdFormatCaps;

  /// Title of the command `slides.format.textStyle` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get cmdFormatTextStyle;

  /// Title of the command `slides.format.font` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get cmdFormatFont;

  /// Title of the command `slides.format.fontSize` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get cmdFormatFontSize;

  /// Title of the command `slides.format.textColor` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get cmdFormatTextColor;

  /// Title of the command `slides.format.highlight` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Highlight color'**
  String get cmdFormatHighlight;

  /// Title of the command `slides.format.align` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Text alignment'**
  String get cmdFormatAlign;

  /// Title of the command `slides.format.anchor` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Vertical alignment'**
  String get cmdFormatAnchor;

  /// Title of the command `slides.format.indent` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Increase indent'**
  String get cmdFormatIndent;

  /// Title of the command `slides.format.outdent` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Decrease indent'**
  String get cmdFormatOutdent;

  /// Title of the command `slides.format.lineHeight` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get cmdFormatLineHeight;

  /// Title of the command `slides.format.paragraphSpacing` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Paragraph spacing…'**
  String get cmdFormatParagraphSpacing;

  /// Title of the command `slides.format.list` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get cmdFormatList;

  /// Title of the command `slides.format.listStyle` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'List style'**
  String get cmdFormatListStyle;

  /// Title of the command `slides.format.listStart` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Restart numbering'**
  String get cmdFormatListStart;

  /// Title of the command `slides.format.autofit` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Text fitting'**
  String get cmdFormatAutofit;

  /// Title of the command `slides.format.fill` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get cmdFormatFill;

  /// Title of the command `slides.format.stroke` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get cmdFormatStroke;

  /// Title of the command `slides.format.effects` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get cmdFormatEffects;

  /// Title of the command `slides.format.opacity` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Opacity…'**
  String get cmdFormatOpacity;

  /// Title of the command `slides.image.crop` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cmdImageCrop;

  /// Title of the command `slides.image.mask` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Mask with shape'**
  String get cmdImageMask;

  /// Title of the command `slides.image.replace` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get cmdImageReplace;

  /// Title of the command `slides.image.adjust` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Adjustments…'**
  String get cmdImageAdjust;

  /// Title of the command `slides.image.reset` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reset image'**
  String get cmdImageReset;

  /// Title of the command `slides.image.downloadOriginal` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Download original'**
  String get cmdImageDownloadOriginal;

  /// Title of the command `slides.table.insertRow` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Insert row'**
  String get cmdTableInsertRow;

  /// Title of the command `slides.table.insertColumn` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Insert column'**
  String get cmdTableInsertColumn;

  /// Title of the command `slides.table.deleteRows` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get cmdTableDeleteRows;

  /// Title of the command `slides.table.deleteColumns` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get cmdTableDeleteColumns;

  /// Title of the command `slides.table.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get cmdTableDelete;

  /// Title of the command `slides.table.mergeCells` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Merge cells'**
  String get cmdTableMergeCells;

  /// Title of the command `slides.table.unmergeCells` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Unmerge cells'**
  String get cmdTableUnmergeCells;

  /// Title of the command `slides.table.distributeRows` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Distribute rows'**
  String get cmdTableDistributeRows;

  /// Title of the command `slides.table.distributeColumns` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Distribute columns'**
  String get cmdTableDistributeColumns;

  /// Title of the command `slides.table.setOptions` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Table options…'**
  String get cmdTableSetOptions;

  /// Title of the command `slides.table.setCellFill` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Cell fill'**
  String get cmdTableSetCellFill;

  /// Title of the command `slides.table.setBorders` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Borders'**
  String get cmdTableSetBorders;

  /// Title of the command `slides.table.setCellAlign` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Vertical align'**
  String get cmdTableSetCellAlign;

  /// Title of the command `slides.shape.change` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Change shape'**
  String get cmdShapeChange;

  /// Title of the command `slides.shape.applyQuickStyle` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Quick styles'**
  String get cmdShapeApplyQuickStyle;

  /// Title of the command `slides.line.setArrow` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Arrows'**
  String get cmdLineSetArrow;

  /// Title of the command `slides.line.setRouting` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get cmdLineSetRouting;

  /// Title of the command `slides.code.edit` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Edit code'**
  String get cmdCodeEdit;

  /// Title of the command `slides.code.setLanguage` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Code language'**
  String get cmdCodeSetLanguage;

  /// Title of the command `slides.code.updateOptions` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get cmdCodeUpdateOptions;

  /// Title of the command `slides.code.setHighlightSteps` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Highlight steps…'**
  String get cmdCodeSetHighlightSteps;

  /// Title of the command `slides.code.addState` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Add state'**
  String get cmdCodeAddState;

  /// Title of the command `slides.chart.update` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Update chart'**
  String get cmdChartUpdate;

  /// Title of the command `slides.chart.setAutoUpdate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Update automatically'**
  String get cmdChartSetAutoUpdate;

  /// Title of the command `slides.chart.openSource` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Open source spreadsheet'**
  String get cmdChartOpenSource;

  /// Title of the command `slides.chart.unlink` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Unlink chart'**
  String get cmdChartUnlink;

  /// Title of the command `slides.chart.copyAsImage` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Copy chart as image'**
  String get cmdChartCopyAsImage;

  /// Title of the command `slides.element.editAltText` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Alt text…'**
  String get cmdElementEditAltText;

  /// Title of the command `slides.format.paintFormat` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Paint format'**
  String get cmdFormatPaintFormat;

  /// Title of the command `slides.format.clear` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get cmdFormatClear;

  /// Title of the command `slides.slide.duplicate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Duplicate slide'**
  String get cmdSlideDuplicate;

  /// Title of the command `slides.slide.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete slide'**
  String get cmdSlideDelete;

  /// Title of the command `slides.slide.toggleSkip` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Skip slide'**
  String get cmdSlideToggleSkip;

  /// Title of the command `slides.slide.move` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move slide'**
  String get cmdSlideMove;

  /// Title of the command `slides.slide.applyLayout` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Apply layout'**
  String get cmdSlideApplyLayout;

  /// Title of the command `slides.slide.resetToLayout` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reset slide to layout'**
  String get cmdSlideResetToLayout;

  /// Title of the command `slides.slide.setBackground` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Change background…'**
  String get cmdSlideSetBackground;

  /// Title of the command `slides.slide.applyBackgroundToAll` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Apply background to all slides'**
  String get cmdSlideApplyBackgroundToAll;

  /// Title of the command `slides.slide.setHideMasterElements` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Hide master objects'**
  String get cmdSlideSetHideMasterElements;

  /// Title of the command `slides.deck.setAppearance` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Presentation appearance'**
  String get cmdDeckSetAppearance;

  /// Title of the command `slides.group.create` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Group slides'**
  String get cmdGroupCreate;

  /// Title of the command `slides.group.ungroup` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Ungroup slides'**
  String get cmdGroupUngroup;

  /// Title of the command `slides.group.addSlides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get cmdGroupAddSlides;

  /// Title of the command `slides.group.removeSlides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get cmdGroupRemoveSlides;

  /// Title of the command `slides.group.startRename` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get cmdGroupStartRename;

  /// Title of the command `slides.group.setColor` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Group color'**
  String get cmdGroupSetColor;

  /// Title of the command `slides.group.toggleSkip` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Skip group'**
  String get cmdGroupToggleSkip;

  /// Title of the command `slides.group.collapse` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Collapse group'**
  String get cmdGroupCollapse;

  /// Title of the command `slides.group.expand` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Expand group'**
  String get cmdGroupExpand;

  /// Title of the command `slides.group.collapseAll` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Collapse all groups'**
  String get cmdGroupCollapseAll;

  /// Title of the command `slides.group.expandAll` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Expand all groups'**
  String get cmdGroupExpandAll;

  /// Title of the command `slides.group.duplicate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Duplicate group'**
  String get cmdGroupDuplicate;

  /// Title of the command `slides.group.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete group…'**
  String get cmdGroupDelete;

  /// Title of the command `slides.group.selectSlides` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Select slides in group'**
  String get cmdGroupSelectSlides;

  /// Title of the command `slides.animate.preview` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Preview animations'**
  String get cmdAnimatePreview;

  /// Title of the command `slides.animate.removeAll` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Remove all animations'**
  String get cmdAnimateRemoveAll;

  /// Title of the command `slides.animate.addBuild` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Add animation'**
  String get cmdAnimateAddBuild;

  /// Title of the command `slides.animate.copyBuilds` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Copy animation'**
  String get cmdAnimateCopyBuilds;

  /// Title of the command `slides.animate.pasteBuilds` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Paste animation'**
  String get cmdAnimatePasteBuilds;

  /// Title of the command `slides.animate.deleteBuilds` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Remove animations'**
  String get cmdAnimateDeleteBuilds;

  /// Title of the command `slides.theme.edit` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Edit theme…'**
  String get cmdThemeEdit;

  /// Title of the command `slides.nav.goToSlide` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Go to slide…'**
  String get cmdNavGoToSlide;

  /// Title of the command `slides.nav.goToGroup` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Go to group'**
  String get cmdNavGoToGroup;

  /// Title of the command `slides.nav.previousSlide` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Previous slide'**
  String get cmdNavPreviousSlide;

  /// Title of the command `slides.nav.nextSlide` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Next slide'**
  String get cmdNavNextSlide;

  /// Title of the command `slides.arrange.order` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get cmdArrangeOrder;

  /// Title of the command `slides.arrange.align` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Align objects'**
  String get cmdArrangeAlign;

  /// Title of the command `slides.arrange.distribute` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Distribute objects'**
  String get cmdArrangeDistribute;

  /// Title of the command `slides.arrange.centerOnSlide` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Center on slide'**
  String get cmdArrangeCenterOnSlide;

  /// Title of the command `slides.arrange.matchSize` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Match size'**
  String get cmdArrangeMatchSize;

  /// Title of the command `slides.arrange.rotate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get cmdArrangeRotate;

  /// Title of the command `slides.arrange.flip` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get cmdArrangeFlip;

  /// Title of the command `slides.arrange.group` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get cmdArrangeGroup;

  /// Title of the command `slides.arrange.ungroup` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Ungroup'**
  String get cmdArrangeUngroup;

  /// Title of the command `slides.element.toggleLock` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get cmdElementToggleLock;

  /// Title of the command `slides.element.unlockAll` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Unlock all on slide'**
  String get cmdElementUnlockAll;

  /// Title of the command `slides.element.hide` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get cmdElementHide;

  /// Title of the command `slides.element.show` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get cmdElementShow;

  /// Title of the command `slides.element.setLink` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Link…'**
  String get cmdElementSetLink;

  /// Title of the command `slides.element.removeLink` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get cmdElementRemoveLink;

  /// Title of the command `slides.element.resetPlaceholder` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reset to layout'**
  String get cmdElementResetPlaceholder;

  /// Title of the command `slides.spelling.check` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Check spelling'**
  String get cmdSpellingCheck;

  /// Title of the command `slides.spelling.toggleUnderline` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Underline errors'**
  String get cmdSpellingToggleUnderline;

  /// Title of the command `slides.tools.accessibilityCheck` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Accessibility check'**
  String get cmdToolsAccessibilityCheck;

  /// Title of the command `slides.notifications.openSettings` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get cmdNotificationsOpenSettings;

  /// Title of the command `slides.ai.generateDeck` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Generate presentation…'**
  String get cmdAiGenerateDeck;

  /// Title of the command `slides.ai.rewrite` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rewrite text'**
  String get cmdAiRewrite;

  /// Title of the command `slides.ai.suggestLayouts` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Suggest layouts for this slide'**
  String get cmdAiSuggestLayouts;

  /// Title of the command `slides.ai.speakerNotes` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Write speaker notes'**
  String get cmdAiSpeakerNotes;

  /// Title of the command `slides.ai.altText` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Generate alt text'**
  String get cmdAiAltText;

  /// Title of the command `slides.ai.codeWalkthrough` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Make a code walkthrough…'**
  String get cmdAiCodeWalkthrough;

  /// Title of the command `slides.tool.select` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get cmdToolSelect;

  /// Title of the command `slides.prefs.set` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Change a Slides setting'**
  String get cmdPrefsSet;

  /// Title of the command `slides.presenter.set` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Change a presenting setting'**
  String get cmdPresenterSet;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get categoryFile;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get categoryEdit;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get categoryView;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get categoryInsert;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Canvas & objects'**
  String get categoryFormat;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get categoryText;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get categoryTables;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Slides & groups'**
  String get categorySlides;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get categoryArrange;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Canvas & objects'**
  String get categoryCanvas;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get categoryPresent;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get categoryAnimations;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get categoryTools;

  /// Keyboard-shortcuts help category of Slides commands.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get categoryAi;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get alignLeft;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get alignRight;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get alignJustify;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get anchorTop;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get anchorMiddle;

  /// Alignment option (Format › Align & indent, Arrange › Align).
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get anchorBottom;

  /// Element context menu › Animate.
  ///
  /// In en, this message translates to:
  /// **'Add build in'**
  String get animateAddBuildIn;

  /// Element context menu › Animate.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get animateAddAction;

  /// Element context menu › Animate.
  ///
  /// In en, this message translates to:
  /// **'Add build out'**
  String get animateAddBuildOut;

  /// Inspector › Animate sub-tab.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get animateTabTransition;

  /// Inspector › Animate sub-tab.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get animateTabBuild;

  /// Inspector › Animate sub-tab.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get animateTabOrder;

  /// Deck appearance option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Deck appearance option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Format › Text fitting option.
  ///
  /// In en, this message translates to:
  /// **'Do not autofit'**
  String get autofitNone;

  /// Format › Text fitting option.
  ///
  /// In en, this message translates to:
  /// **'Shrink text on overflow'**
  String get autofitShrink;

  /// Format › Text fitting option.
  ///
  /// In en, this message translates to:
  /// **'Resize shape to fit text'**
  String get autofitResize;

  /// Arrange option.
  ///
  /// In en, this message translates to:
  /// **'Horizontally'**
  String get axisHorizontally;

  /// Arrange option.
  ///
  /// In en, this message translates to:
  /// **'Vertically'**
  String get axisVertically;

  /// Arrange option.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get axisBoth;

  /// Button that leaves a view mode.
  ///
  /// In en, this message translates to:
  /// **'Back to Normal view'**
  String get backToNormalView;

  /// Button on placeholder pages under a presentation.
  ///
  /// In en, this message translates to:
  /// **'Back to the presentation'**
  String get backToPresentation;

  /// Toolbar badge for viewers.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get badgeViewOnly;

  /// Toolbar badge for commenters.
  ///
  /// In en, this message translates to:
  /// **'Comment only'**
  String get badgeCommentOnly;

  /// Toolbar badge for editors in Viewing mode.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get badgeViewing;

  /// Empty deck action.
  ///
  /// In en, this message translates to:
  /// **'Choose a layout'**
  String get canvasChooseLayout;

  /// Empty deck title.
  ///
  /// In en, this message translates to:
  /// **'This presentation has no slides'**
  String get canvasEmptyTitle;

  /// Empty deck description.
  ///
  /// In en, this message translates to:
  /// **'Add a slide to start, or choose a layout for it.'**
  String get canvasEmptyBody;

  /// Screen reader label of the slide on the canvas.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}: {title}'**
  String canvasSlideSemantics(int number, String title);

  /// Format › Text › Capitalization option.
  ///
  /// In en, this message translates to:
  /// **'UPPERCASE'**
  String get capsUpper;

  /// Format › Text › Capitalization option.
  ///
  /// In en, this message translates to:
  /// **'Small caps'**
  String get capsSmallCaps;

  /// Format › Text › Capitalization option.
  ///
  /// In en, this message translates to:
  /// **'Title Case'**
  String get capsTitle;

  /// Format › Text › Capitalization option.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get capsNone;

  /// Chart type.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get chartColumn;

  /// Chart type.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get chartBar;

  /// Chart type.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get chartLine;

  /// Chart type.
  ///
  /// In en, this message translates to:
  /// **'Pie'**
  String get chartPie;

  /// Chart type.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get chartArea;

  /// Chart type.
  ///
  /// In en, this message translates to:
  /// **'Scatter'**
  String get chartScatter;

  /// Insert › Chart item.
  ///
  /// In en, this message translates to:
  /// **'From Wonky Sheets…'**
  String get chartFromSheets;

  /// Insert › Code block item.
  ///
  /// In en, this message translates to:
  /// **'All languages…'**
  String get codeAllLanguages;

  /// Format › Code item.
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get codeLineNumbers;

  /// Code language without highlighting.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get codePlainText;

  /// Format › Code item.
  ///
  /// In en, this message translates to:
  /// **'States…'**
  String get codeStates;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// Color name (group colors, laser pointer).
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get colorNone;

  /// Loading state without progress.
  ///
  /// In en, this message translates to:
  /// **'Opening presentation…'**
  String get deckLoading;

  /// Loading state with a percentage, e.g. "Downloading presentation… 42 %".
  ///
  /// In en, this message translates to:
  /// **'{message} {percent} %'**
  String deckLoadingProgress(String message, int percent);

  /// Title when a presentation can’t be shown.
  ///
  /// In en, this message translates to:
  /// **'This presentation isn’t available'**
  String get deckUnavailable;

  /// Description of the offline unavailable state.
  ///
  /// In en, this message translates to:
  /// **'It opens by itself when you’re back online.'**
  String get deckOfflineHint;

  /// File › Download format.
  ///
  /// In en, this message translates to:
  /// **'PDF document (.pdf)'**
  String get downloadPdf;

  /// File › Download format.
  ///
  /// In en, this message translates to:
  /// **'PNG image (current slide)…'**
  String get downloadPng;

  /// File › Download format.
  ///
  /// In en, this message translates to:
  /// **'PNG images (all slides, .zip)…'**
  String get downloadPngZip;

  /// File › Download format.
  ///
  /// In en, this message translates to:
  /// **'Outline as Markdown (.md)'**
  String get downloadMarkdown;

  /// A duration in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// A duration in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSeconds(String seconds);

  /// Arrange › Rotate item.
  ///
  /// In en, this message translates to:
  /// **'Flip horizontally'**
  String get flipHorizontally;

  /// Arrange › Rotate item.
  ///
  /// In en, this message translates to:
  /// **'Flip vertically'**
  String get flipVertically;

  /// Go to slide dialog title.
  ///
  /// In en, this message translates to:
  /// **'Go to slide'**
  String get goToSlideTitle;

  /// Go to slide dialog field.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get goToSlideLabel;

  /// Go to slide dialog button.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goToSlideButton;

  /// Name of a slide group without a title.
  ///
  /// In en, this message translates to:
  /// **'Untitled group'**
  String get groupUntitled;

  /// View › Guides item.
  ///
  /// In en, this message translates to:
  /// **'Add vertical guide'**
  String get guidesAddVertical;

  /// View › Guides item.
  ///
  /// In en, this message translates to:
  /// **'Add horizontal guide'**
  String get guidesAddHorizontal;

  /// Insert › Image source.
  ///
  /// In en, this message translates to:
  /// **'Upload from computer'**
  String get imageUpload;

  /// Insert › Image source.
  ///
  /// In en, this message translates to:
  /// **'From Wonky Drive'**
  String get imageFromDrive;

  /// Insert › Image source.
  ///
  /// In en, this message translates to:
  /// **'By URL'**
  String get imageByUrl;

  /// Insert › Image source.
  ///
  /// In en, this message translates to:
  /// **'From clipboard'**
  String get imageFromClipboard;

  /// Screen reader label of the inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspectorLabel;

  /// Inspector tab.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get inspectorFormat;

  /// Inspector tab.
  ///
  /// In en, this message translates to:
  /// **'Animate'**
  String get inspectorAnimate;

  /// Inspector tab.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get inspectorSlide;

  /// Inspector close button.
  ///
  /// In en, this message translates to:
  /// **'Close inspector'**
  String get inspectorClose;

  /// Inspector › Format with nothing selected.
  ///
  /// In en, this message translates to:
  /// **'Select an object to format it'**
  String get inspectorFormatEmpty;

  /// Body of an inspector section that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'These options are on their way.'**
  String get inspectorSectionSoon;

  /// Inspector › Slide row label.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get inspectorCurrentLayout;

  /// Inspector › Slide row label.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get inspectorAppearance;

  /// Inspector › Slide › Group.
  ///
  /// In en, this message translates to:
  /// **'Not in a group'**
  String get inspectorNotInGroup;

  /// Inspector › Slide row label.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get inspectorGroupName;

  /// Inspector › Slide › Info row label.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get inspectorSlideNumber;

  /// Inspector › Slide › Info row label.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get inspectorSkipped;

  /// Generic yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get lineLine;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get lineArrow;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'Double arrow'**
  String get lineDoubleArrow;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'Elbow connector'**
  String get lineElbowConnector;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'Curved connector'**
  String get lineCurvedConnector;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'Start arrow'**
  String get lineStartArrow;

  /// Line item.
  ///
  /// In en, this message translates to:
  /// **'End arrow'**
  String get lineEndArrow;

  /// Format › Bullets & numbering item.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get listBulleted;

  /// Format › Bullets & numbering item.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get listNumbered;

  /// Format › Bullets & numbering item.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get listChecklist;

  /// Format › Bullets & numbering item.
  ///
  /// In en, this message translates to:
  /// **'List options…'**
  String get listOptions;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get menuAddToGroup;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get menuAi;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Align'**
  String get menuAlign;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Align & indent'**
  String get menuAlignIndent;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Animate'**
  String get menuAnimate;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Animate…'**
  String get menuAnimateEllipsis;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Animation…'**
  String get menuAnimation;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Apply layout'**
  String get menuApplyLayout;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get menuArrange;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Border…'**
  String get menuBorderEllipsis;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Capitalization'**
  String get menuCapitalization;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Center on slide'**
  String get menuCenterOnSlide;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Change background…'**
  String get menuChangeBackground;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Change theme…'**
  String get menuChangeTheme;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get menuChart;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Choose a group…'**
  String get menuChooseGroup;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get menuCode;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get menuCodeBlock;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Comment on slide'**
  String get menuCommentOnSlide;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Distribute'**
  String get menuDistribute;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get menuDownload;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Edit layout'**
  String get menuEditLayout;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Edit masters and layouts'**
  String get menuEditMasters;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Effects…'**
  String get menuEffectsEllipsis;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get menuExtensions;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Fill…'**
  String get menuFillEllipsis;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get menuFormat;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Format options…'**
  String get menuFormatOptions;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get menuGroup;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get menuGroupColor;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get menuGuides;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get menuImage;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get menuInsert;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get menuLine;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Bullets & numbering'**
  String get menuLists;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Magic Move ID…'**
  String get menuMagicMoveId;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Match size'**
  String get menuMatchSize;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get menuMcp;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Move slide'**
  String get menuMoveSlide;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get menuNewGroup;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'New slide in group'**
  String get menuNewSlideInGroup;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'New slide with layout'**
  String get menuNewSlideWithLayout;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get menuOrder;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Panels'**
  String get menuPanels;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Paste special'**
  String get menuPasteSpecial;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Personal dictionary'**
  String get menuPersonalDictionary;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get menuPlaceholder;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get menuPresent;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Present from this group'**
  String get menuPresentFromGroup;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Presenting settings…'**
  String get menuPresentingSettings;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Rehearse presentation'**
  String get menuRehearsePresentation;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Rewrite text'**
  String get menuRewriteText;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get menuRotate;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get menuShape;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'All shapes…'**
  String get menuShapeGallery;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get menuShow;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get menuSize;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Size and position…'**
  String get menuSizePosition;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get menuSlide;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get menuSnap;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Line & paragraph spacing'**
  String get menuSpacing;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get menuSpelling;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get menuTable;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get menuText;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Text fitting'**
  String get menuTextFitting;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get menuTextStyle;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Transition…'**
  String get menuTransition;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get menuVersionHistory;

  /// Menu or submenu label (Slides 04 §4).
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get menuZoom;

  /// Slide › Move slide item.
  ///
  /// In en, this message translates to:
  /// **'To beginning'**
  String get moveToBeginning;

  /// Slide › Move slide item.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get moveUp;

  /// Slide › Move slide item.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get moveDown;

  /// Slide › Move slide item.
  ///
  /// In en, this message translates to:
  /// **'To end'**
  String get moveToEnd;

  /// Screen reader label of the slide navigator.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get navigatorLabel;

  /// Navigator with no slides.
  ///
  /// In en, this message translates to:
  /// **'No slides'**
  String get navigatorEmpty;

  /// Button that opens the navigator drawer on narrow screens.
  ///
  /// In en, this message translates to:
  /// **'Show slides'**
  String get navigatorOpen;

  /// Screen reader label of a group header.
  ///
  /// In en, this message translates to:
  /// **'Group {title}, {count, plural, =1{1 slide} other{{count} slides}}'**
  String navigatorGroupSemantics(String title, int count);

  /// Screen reader label of a navigator slide row.
  ///
  /// In en, this message translates to:
  /// **'Slide {number} of {total}: {title}'**
  String navigatorSlideSemantics(int number, int total, String title);

  /// Speaker notes pane handle.
  ///
  /// In en, this message translates to:
  /// **'Speaker notes'**
  String get notesLabel;

  /// Empty speaker notes.
  ///
  /// In en, this message translates to:
  /// **'Click to add speaker notes'**
  String get notesPlaceholder;

  /// Arrange › Order item.
  ///
  /// In en, this message translates to:
  /// **'Bring to front'**
  String get orderBringToFront;

  /// Arrange › Order item.
  ///
  /// In en, this message translates to:
  /// **'Bring forward'**
  String get orderBringForward;

  /// Arrange › Order item.
  ///
  /// In en, this message translates to:
  /// **'Send backward'**
  String get orderSendBackward;

  /// Arrange › Order item.
  ///
  /// In en, this message translates to:
  /// **'Send to back'**
  String get orderSendToBack;

  /// Outline view: slide without a title.
  ///
  /// In en, this message translates to:
  /// **'(no title)'**
  String get outlineNoTitle;

  /// Paste special option.
  ///
  /// In en, this message translates to:
  /// **'Keep source formatting'**
  String get pasteKeepSource;

  /// Paste special option.
  ///
  /// In en, this message translates to:
  /// **'Use destination theme'**
  String get pasteUseDestination;

  /// Paste special option.
  ///
  /// In en, this message translates to:
  /// **'Paste chart unlinked'**
  String get pasteChartUnlinked;

  /// Placeholder type.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get placeholderPicture;

  /// Placeholder type.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get placeholderObject;

  /// Placeholder type.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get placeholderFooter;

  /// Placeholder type.
  ///
  /// In en, this message translates to:
  /// **'Slide number'**
  String get placeholderSlideNumber;

  /// Placeholder type.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get placeholderDate;

  /// The Present button in the title row.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentButton;

  /// Chevron of the Present split button.
  ///
  /// In en, this message translates to:
  /// **'Presenting options'**
  String get presentOptions;

  /// Presenter view layout preset.
  ///
  /// In en, this message translates to:
  /// **'Current, next and notes'**
  String get presenterLayoutStandard;

  /// Presenter view layout preset.
  ///
  /// In en, this message translates to:
  /// **'Large notes'**
  String get presenterLayoutNotes;

  /// Presenter view layout preset.
  ///
  /// In en, this message translates to:
  /// **'Large next slide'**
  String get presenterLayoutNext;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get reasonNotAvailableYet;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'The presentation is still opening'**
  String get reasonDeckLoading;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'You have view access'**
  String get reasonViewAccess;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'You’re in Viewing mode'**
  String get reasonViewingMode;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'This is the first slide'**
  String get reasonFirstSlide;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'This is the last slide'**
  String get reasonLastSlide;

  /// Reason shown on a disabled command.
  ///
  /// In en, this message translates to:
  /// **'The presentation has no slides'**
  String get reasonNoSlides;

  /// AI › Rewrite text option.
  ///
  /// In en, this message translates to:
  /// **'Shorter'**
  String get rewriteShorter;

  /// AI › Rewrite text option.
  ///
  /// In en, this message translates to:
  /// **'Longer'**
  String get rewriteLonger;

  /// AI › Rewrite text option.
  ///
  /// In en, this message translates to:
  /// **'Clearer'**
  String get rewriteClearer;

  /// AI › Rewrite text option.
  ///
  /// In en, this message translates to:
  /// **'More formal'**
  String get rewriteFormal;

  /// AI › Rewrite text option.
  ///
  /// In en, this message translates to:
  /// **'Fix grammar'**
  String get rewriteGrammar;

  /// AI › Rewrite text option.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get rewriteCustom;

  /// Arrange › Rotate item.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90° clockwise'**
  String get rotateClockwise;

  /// Arrange › Rotate item.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90° counter-clockwise'**
  String get rotateCounterClockwise;

  /// Title of the present route placeholder.
  ///
  /// In en, this message translates to:
  /// **'Presenting'**
  String get routePresentTitle;

  /// Title of the print route placeholder.
  ///
  /// In en, this message translates to:
  /// **'Print and PDF'**
  String get routePrintTitle;

  /// Title of the history route placeholder.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get routeHistoryTitle;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get sectionText;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get sectionLine;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get sectionImage;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get sectionTable;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Cell'**
  String get sectionCell;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get sectionIcon;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get sectionCode;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get sectionChart;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get sectionFill;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get sectionBorder;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get sectionEffects;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get sectionArrange;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get sectionLink;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get sectionAccessibility;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get sectionLayout;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get sectionBackground;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get sectionTheme;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get sectionVisibility;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get sectionGroup;

  /// Inspector section title (Slides 04 §7).
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get sectionInfo;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'New presentations'**
  String get settingsSectionPresentations;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get settingsSectionEditing;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Animations & code'**
  String get settingsSectionAnimations;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Presenting'**
  String get settingsSectionPresenting;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'New presentations'**
  String get settingsNewPresentations;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Used when you create a presentation. Existing presentations keep their own settings.'**
  String get settingsNewPresentationsHint;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsDefaultTheme;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsDefaultAppearance;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Slide size'**
  String get settingsDefaultSize;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsDefaultLanguage;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get settingsCharts;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Update linked charts automatically'**
  String get settingsChartsAutoUpdate;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'New charts from Wonky Sheets follow their spreadsheet.'**
  String get settingsChartsAutoUpdateHint;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get settingsEditing;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Scroll to change slides'**
  String get settingsScrollChangesSlides;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Smart quotes'**
  String get settingsSmartQuotes;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Automatically format lists'**
  String get settingsAutoformatLists;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Show collaborator cursors'**
  String get settingsShowRemoteCursors;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get settingsSpelling;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Underline spelling errors'**
  String get settingsUnderlineSpelling;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get settingsAnimations;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Default transition'**
  String get settingsDefaultTransition;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Transition duration'**
  String get settingsTransitionDuration;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Default build'**
  String get settingsDefaultBuild;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Preview animations on hover'**
  String get settingsPreviewOnHover;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Reduce motion in the editor'**
  String get settingsReduceEditorMotion;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Previews show the end state instead of playing.'**
  String get settingsReduceEditorMotionHint;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get settingsCode;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Largest code font size'**
  String get settingsCodeFontSize;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Default code language'**
  String get settingsCodeLanguage;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Type-in speed'**
  String get settingsTypingSpeed;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Type-in click sound'**
  String get settingsTypeInSound;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Presenting'**
  String get settingsPresenting;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'How you present. The audience view follows the presentation.'**
  String get settingsPresentingHint;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Presenter view layout'**
  String get settingsPresenterLayout;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Notes text size'**
  String get settingsNotesSize;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get settingsTimerMode;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Countdown length'**
  String get settingsTimerTarget;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Laser pointer color'**
  String get settingsLaserColor;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Start presenting in full screen'**
  String get settingsStartFullscreen;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Start with presenter view'**
  String get settingsStartWithPresenterView;

  /// Slides settings (Slides 04 §13.16).
  ///
  /// In en, this message translates to:
  /// **'Show skipped slides in presenter view'**
  String get settingsShowSkippedInPresenter;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Widescreen 16:9'**
  String get sizeWidescreen16x9;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Standard 4:3'**
  String get sizeStandard4x3;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Widescreen 16:10'**
  String get sizeWide16x10;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Square 1:1'**
  String get sizeSquare;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Portrait 9:16'**
  String get sizePortrait9x16;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'A4 landscape'**
  String get sizeA4;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Letter landscape'**
  String get sizeLetter;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get sizeWidth;

  /// Slide size preset or dimension.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get sizeHeight;

  /// A slide without a title.
  ///
  /// In en, this message translates to:
  /// **'Untitled slide'**
  String get slideUntitled;

  /// Format › Line & paragraph spacing item.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get spacingSingle;

  /// Format › Line & paragraph spacing item.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get spacingDouble;

  /// Format › Line & paragraph spacing item.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get spacingCustom;

  /// Format › Line & paragraph spacing item.
  ///
  /// In en, this message translates to:
  /// **'Add space before paragraph'**
  String get spacingAddBefore;

  /// Format › Line & paragraph spacing item.
  ///
  /// In en, this message translates to:
  /// **'Add space after paragraph'**
  String get spacingAddAfter;

  /// Type-in speed.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get speedSlow;

  /// Type-in speed.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speedNormal;

  /// Type-in speed.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get speedFast;

  /// Status bar with an empty deck.
  ///
  /// In en, this message translates to:
  /// **'No slides'**
  String get statusNoSlides;

  /// Status bar position.
  ///
  /// In en, this message translates to:
  /// **'Slide {number} of {total}'**
  String statusSlideOf(int number, int total);

  /// Status bar: number of skipped slides.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String statusSkipped(int count);

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get styleTitle;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get styleSubtitle;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get styleHeading;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get styleBody;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Body 2'**
  String get styleBody2;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get styleCaption;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get styleQuote;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get styleAttribution;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Big number'**
  String get styleBigNumber;

  /// Theme text style (05 §2.5).
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get styleLabel;

  /// Table item.
  ///
  /// In en, this message translates to:
  /// **'Insert row above'**
  String get tableInsertRowAbove;

  /// Table item.
  ///
  /// In en, this message translates to:
  /// **'Insert row below'**
  String get tableInsertRowBelow;

  /// Table item.
  ///
  /// In en, this message translates to:
  /// **'Insert column left'**
  String get tableInsertColumnLeft;

  /// Table item.
  ///
  /// In en, this message translates to:
  /// **'Insert column right'**
  String get tableInsertColumnRight;

  /// Format › Text item.
  ///
  /// In en, this message translates to:
  /// **'Superscript'**
  String get textSuperscript;

  /// Format › Text item.
  ///
  /// In en, this message translates to:
  /// **'Subscript'**
  String get textSubscript;

  /// Presenter timer mode.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time'**
  String get timerElapsed;

  /// Presenter timer mode.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get timerCountdown;

  /// Screen reader label of the toolbar.
  ///
  /// In en, this message translates to:
  /// **'Slides toolbar'**
  String get toolbarLabel;

  /// Toolbar undo without a label.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get toolbarUndo;

  /// Toolbar redo without a label.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get toolbarRedo;

  /// Toolbar undo tooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo {label}'**
  String toolbarUndoLabel(String label);

  /// Toolbar redo tooltip.
  ///
  /// In en, this message translates to:
  /// **'Redo {label}'**
  String toolbarRedoLabel(String label);

  /// Toolbar zoom tooltip.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get toolbarZoom;

  /// Toolbar comment button.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get toolbarAddComment;

  /// Toolbar align dropdown.
  ///
  /// In en, this message translates to:
  /// **'Align'**
  String get toolbarAlign;

  /// Toolbar Animate button.
  ///
  /// In en, this message translates to:
  /// **'Animate'**
  String get toolbarAnimate;

  /// Toolbar background button (nothing selected).
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get toolbarBackground;

  /// Toolbar layout dropdown (nothing selected).
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get toolbarLayout;

  /// Toolbar theme button (nothing selected).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get toolbarTheme;

  /// Toolbar transition button (nothing selected).
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get toolbarTransition;

  /// Units option.
  ///
  /// In en, this message translates to:
  /// **'Slide units'**
  String get unitsSu;

  /// Units option.
  ///
  /// In en, this message translates to:
  /// **'Pixels'**
  String get unitsPx;

  /// Units option.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get unitsIn;

  /// Units option.
  ///
  /// In en, this message translates to:
  /// **'Centimeters'**
  String get unitsCm;

  /// View mode.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get viewNormal;

  /// View mode.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewGrid;

  /// View mode.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get viewOutline;

  /// Zoom to fit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get zoomFit;

  /// A zoom level.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String zoomPercent(int percent);

  /// Toast when an undo skipped a collaborator’s newer changes.
  ///
  /// In en, this message translates to:
  /// **'Some changes weren’t undone because a collaborator changed them since'**
  String get toastUndoPartial;

  /// A change the server rejected (RevLog 06 §4.6); it is undone on this device.
  ///
  /// In en, this message translates to:
  /// **'“{label}” couldn’t be saved: {reason}'**
  String toastChangeNotSaved(String label, String reason);

  /// A change was rejected because the user lost edit access.
  ///
  /// In en, this message translates to:
  /// **'You can no longer edit this presentation'**
  String get toastChangeNoAccess;

  /// Title of the command `slides.select.elements` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Select objects'**
  String get cmdSelectElements;

  /// Title of the command `slides.select.next` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Select next object'**
  String get cmdSelectNext;

  /// Title of the command `slides.select.previous` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Select previous object'**
  String get cmdSelectPrevious;

  /// Title of the command `slides.element.move` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get cmdElementMove;

  /// Title of the command `slides.element.resize` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get cmdElementResize;

  /// Title of the command `slides.element.nudge` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Nudge'**
  String get cmdElementNudge;

  /// Title of the command `slides.element.adjust` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Adjust shape'**
  String get cmdElementAdjust;

  /// Title of the command `slides.element.setLineEnds` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move line end'**
  String get cmdElementSetLineEnds;

  /// Title of the command `slides.element.lock` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get cmdElementLock;

  /// Title of the command `slides.element.unlock` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get cmdElementUnlock;

  /// Title of the command `slides.guides.move` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move guide'**
  String get cmdGuidesMove;

  /// Title of the command `slides.guides.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete guide'**
  String get cmdGuidesDelete;

  /// Undo label of a rotation (drag or Rotate 90°).
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get undoRotate;

  /// Undo label of Flip horizontally/vertically.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get undoFlip;

  /// Reason shown on a disabled command that needs a selected object.
  ///
  /// In en, this message translates to:
  /// **'Select an object'**
  String get reasonSelectObject;

  /// Reason shown on a disabled command (match size).
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 objects'**
  String get reasonSelectTwoObjects;

  /// Reason shown on a disabled command (distribute).
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 objects'**
  String get reasonSelectThreeObjects;

  /// Reason shown on a disabled command when a selected object is locked.
  ///
  /// In en, this message translates to:
  /// **'Unlock the object first'**
  String get reasonObjectLocked;

  /// Reason shown on a disabled command when the selection is inside an element group.
  ///
  /// In en, this message translates to:
  /// **'Not available for objects inside a group'**
  String get reasonInsideGroup;

  /// Reason shown on a disabled command that needs a selected element group.
  ///
  /// In en, this message translates to:
  /// **'Select a group'**
  String get reasonSelectGroup;

  /// Reason shown on a disabled Unlock all.
  ///
  /// In en, this message translates to:
  /// **'No locked objects on this slide'**
  String get reasonNoLockedObjects;

  /// Reason shown on disabled guide commands.
  ///
  /// In en, this message translates to:
  /// **'There are no guides'**
  String get reasonNoGuides;

  /// Reason shown when the selected object has no such action yet.
  ///
  /// In en, this message translates to:
  /// **'Not available for this object'**
  String get reasonNotOnCanvas;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Text box'**
  String get elementKindText;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get elementKindShape;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get elementKindLine;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get elementKindImage;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get elementKindTable;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get elementKindCode;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get elementKindChart;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get elementKindIcon;

  /// Name of an element kind (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get elementKindGroup;

  /// Name of an empty placeholder (screen reader announcements).
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get elementKindPlaceholder;

  /// Screen reader announcement when one object is selected on the canvas.
  ///
  /// In en, this message translates to:
  /// **'{name} selected, {index} of {count} objects'**
  String canvasAnnounceSelected(String name, int index, int count);

  /// Screen reader announcement when several objects are selected.
  ///
  /// In en, this message translates to:
  /// **'{count} objects selected'**
  String canvasAnnounceSelectedMany(int count);

  /// Screen reader announcement after a move.
  ///
  /// In en, this message translates to:
  /// **'Moved to x {x}, y {y}'**
  String canvasAnnounceMoved(int x, int y);

  /// Semantics label of a canvas element: its name and state.
  ///
  /// In en, this message translates to:
  /// **'{name}, {state}'**
  String canvasElementSemantics(String name, String state);

  /// Semantics state of a selected canvas element.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get canvasStateSelected;

  /// Semantics state of a locked canvas element.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get canvasStateLocked;

  /// Dimensions badge while resizing (slide units).
  ///
  /// In en, this message translates to:
  /// **'{width} × {height}'**
  String canvasDimensions(int width, int height);

  /// Position badge while moving (slide units).
  ///
  /// In en, this message translates to:
  /// **'{x}, {y}'**
  String canvasPosition(int x, int y);

  /// Angle badge while rotating.
  ///
  /// In en, this message translates to:
  /// **'{degrees}°'**
  String canvasAngle(int degrees);

  /// Command: print the PDF from the print preview (Slides 10 §14)
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get cmdPrintPrint;

  /// Print preview route title (10 §12)
  ///
  /// In en, this message translates to:
  /// **'Print preview'**
  String get printPreviewTitle;

  /// Print preview title with the deck name
  ///
  /// In en, this message translates to:
  /// **'Print preview — {name}'**
  String printPreviewTitleWithName(String name);

  /// Print preview: back button
  ///
  /// In en, this message translates to:
  /// **'Back to the presentation'**
  String get printBack;

  /// Print preview: download button
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get printDownloadPdf;

  /// Print preview: print button
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printPrint;

  /// Print preview: settings column heading
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get printSettings;

  /// Print preview (narrow): back to the preview
  ///
  /// In en, this message translates to:
  /// **'Show preview'**
  String get printShowPreview;

  /// Print preview: page count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String printPageCount(int count);

  /// Print preview: rendering
  ///
  /// In en, this message translates to:
  /// **'Updating preview…'**
  String get printUpdatingPreview;

  /// Print preview: waiting for the deck
  ///
  /// In en, this message translates to:
  /// **'Loading presentation…'**
  String get printLoadingDeck;

  /// Print preview: error title
  ///
  /// In en, this message translates to:
  /// **'The preview could not be created'**
  String get printPreviewFailed;

  /// Print preview: retry
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get printTryAgain;

  /// Print preview: viewers may not export
  ///
  /// In en, this message translates to:
  /// **'Downloads are turned off'**
  String get printDownloadsDisabledTitle;

  /// Print preview: viewers may not export
  ///
  /// In en, this message translates to:
  /// **'The owner has turned off downloading and printing for viewers and commenters.'**
  String get printDownloadsDisabledBody;

  /// Toast when printing is not supported
  ///
  /// In en, this message translates to:
  /// **'Printing isn\'t available here'**
  String get printUnavailableTitle;

  /// Toast when printing is not supported
  ///
  /// In en, this message translates to:
  /// **'Download the PDF and print it from your PDF viewer.'**
  String get printUnavailableBody;

  /// Semantics label of the PDF viewer
  ///
  /// In en, this message translates to:
  /// **'PDF preview'**
  String get printPdfPreviewLabel;

  /// Print preview on desktop
  ///
  /// In en, this message translates to:
  /// **'The PDF is ready'**
  String get printPdfReady;

  /// Print preview on desktop
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The PDF is ready: 1 page} other{The PDF is ready: {count} pages}}'**
  String printPdfReadyPages(int count);

  /// Print preview on desktop
  ///
  /// In en, this message translates to:
  /// **'Download the PDF to view or print it.'**
  String get printPdfDesktopHint;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get printLayout;

  /// Print layout: one slide per page
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get printLayoutSlides;

  /// Print layout: slide with speaker notes
  ///
  /// In en, this message translates to:
  /// **'Notes pages'**
  String get printLayoutNotes;

  /// Print layout: several slides per page
  ///
  /// In en, this message translates to:
  /// **'Handouts'**
  String get printLayoutHandouts;

  /// Print setting (handouts)
  ///
  /// In en, this message translates to:
  /// **'Slides per page'**
  String get printPerPage;

  /// Print setting (handouts)
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get printOrder;

  /// Handout order
  ///
  /// In en, this message translates to:
  /// **'Across, then down'**
  String get printOrderHorizontal;

  /// Handout order
  ///
  /// In en, this message translates to:
  /// **'Down, then across'**
  String get printOrderVertical;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Slides to print'**
  String get printRange;

  /// Print range
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get printRangeAll;

  /// Print range
  ///
  /// In en, this message translates to:
  /// **'Current slide'**
  String get printRangeCurrent;

  /// Print range
  ///
  /// In en, this message translates to:
  /// **'Selected slides'**
  String get printRangeSelection;

  /// Print range
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get printRangeCustom;

  /// Placeholder of the custom range
  ///
  /// In en, this message translates to:
  /// **'e.g. 1-3, 7'**
  String get printRangeHint;

  /// Invalid custom range
  ///
  /// In en, this message translates to:
  /// **'Enter slide numbers like 1-3, 7'**
  String get printRangeInvalid;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get printPaper;

  /// Paper size: the slide's own size
  ///
  /// In en, this message translates to:
  /// **'Slide size'**
  String get printPaperSlide;

  /// Paper size
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get printPaperLetter;

  /// Paper size
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get printPaperLegal;

  /// Paper size
  ///
  /// In en, this message translates to:
  /// **'Tabloid'**
  String get printPaperTabloid;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get printOrientation;

  /// Orientation
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get printOrientationAuto;

  /// Orientation
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get printOrientationPortrait;

  /// Orientation
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get printOrientationLandscape;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get printMargins;

  /// Margins
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get printMarginsNone;

  /// Margins
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get printMarginsNarrow;

  /// Margins
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get printMarginsNormal;

  /// Print setting (builds as pages, M10)
  ///
  /// In en, this message translates to:
  /// **'Print each build stage'**
  String get printBuilds;

  /// Print setting (P1): print each slide as it looks after its last build instead of the authored layout
  ///
  /// In en, this message translates to:
  /// **'Show final animation state'**
  String get printFinalState;

  /// Title of the PNG export dialog (File › Download ▸ PNG)
  ///
  /// In en, this message translates to:
  /// **'Download PNG'**
  String get pngDialogTitle;

  /// Description of the PNG export dialog
  ///
  /// In en, this message translates to:
  /// **'Several images download as one .zip file.'**
  String get pngDialogHint;

  /// PNG export: which slides
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get pngSlides;

  /// PNG export range
  ///
  /// In en, this message translates to:
  /// **'Current slide'**
  String get pngSlidesCurrent;

  /// PNG export range
  ///
  /// In en, this message translates to:
  /// **'Selected slides'**
  String get pngSlidesSelection;

  /// PNG export range
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get pngSlidesAll;

  /// PNG export: image size
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get pngSize;

  /// PNG export size choice
  ///
  /// In en, this message translates to:
  /// **'{scale}× · {width} × {height} px'**
  String pngSizeOption(int scale, int width, int height);

  /// PNG export: which build state the images show
  ///
  /// In en, this message translates to:
  /// **'Builds'**
  String get pngFrames;

  /// PNG export: the print frame
  ///
  /// In en, this message translates to:
  /// **'All content (as printed)'**
  String get pngFramesPrint;

  /// PNG export: the final frame
  ///
  /// In en, this message translates to:
  /// **'After the last build'**
  String get pngFramesFinal;

  /// PNG export: one image per build step
  ///
  /// In en, this message translates to:
  /// **'Each build stage (one image per step)'**
  String get pngFramesBuilds;

  /// PNG export option
  ///
  /// In en, this message translates to:
  /// **'Transparent background'**
  String get pngTransparent;

  /// PNG export dialog button
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get pngDownload;

  /// File name of one slide's image in a PNG ZIP (number is zero-padded)
  ///
  /// In en, this message translates to:
  /// **'Slide {number}'**
  String pngEntrySlide(String number);

  /// File name of one build step's image in a PNG ZIP
  ///
  /// In en, this message translates to:
  /// **'Slide {number}, step {step}'**
  String pngEntryStep(String number, int step);

  /// PNG export with an empty range
  ///
  /// In en, this message translates to:
  /// **'There are no slides to export'**
  String get pngNothingToExport;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Include skipped slides'**
  String get printSkipped;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Frame slides'**
  String get printFrame;

  /// Print setting (notes, handouts)
  ///
  /// In en, this message translates to:
  /// **'Header and footer'**
  String get printHeaderFooter;

  /// Print setting (handouts)
  ///
  /// In en, this message translates to:
  /// **'Slide numbers'**
  String get printSlideNumbers;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Bookmarks for sections and slides'**
  String get printBookmarks;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Clickable links'**
  String get printLinks;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Ink saver (no slide backgrounds)'**
  String get printInkSaver;

  /// Print setting
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get printQuality;

  /// Image quality
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get printQualityHigh;

  /// Image quality
  ///
  /// In en, this message translates to:
  /// **'Compact (smaller file)'**
  String get printQualityCompact;

  /// Heading of export warnings
  ///
  /// In en, this message translates to:
  /// **'About this PDF'**
  String get printWarnings;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'A font could not be embedded; a standard font was used.'**
  String get printWarningFonts;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'Some characters have no glyph in the embedded fonts.'**
  String get printWarningGlyphs;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'Some icons could not be drawn.'**
  String get printWarningIcons;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'Some images could not be loaded.'**
  String get printWarningImages;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'Links to slides that are not printed were removed.'**
  String get printWarningLinks;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'Only the first 500 pages were exported.'**
  String get printWarningPages;

  /// Export warning
  ///
  /// In en, this message translates to:
  /// **'No slides match these settings.'**
  String get printWarningEmpty;

  /// Toast after a download
  ///
  /// In en, this message translates to:
  /// **'Exported “{name}”'**
  String exportedToast(String name);

  /// Toast when an export fails
  ///
  /// In en, this message translates to:
  /// **'The export failed'**
  String get exportFailed;

  /// Download of PNG/Markdown (P1/P2)
  ///
  /// In en, this message translates to:
  /// **'This format is not available yet'**
  String get exportFormatUnavailable;

  /// PDF bookmark of an untitled slide
  ///
  /// In en, this message translates to:
  /// **'Slide {number}'**
  String pdfSlide(int number);

  /// PDF notes continuation heading
  ///
  /// In en, this message translates to:
  /// **'Notes (continued) — Slide {number}'**
  String pdfNotesContinued(int number);

  /// PDF footer
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String pdfPageOf(int page, int count);

  /// PDF bookmark of an untitled group
  ///
  /// In en, this message translates to:
  /// **'Untitled section'**
  String get pdfUntitledSection;

  /// Title of a deck without one
  ///
  /// In en, this message translates to:
  /// **'Untitled presentation'**
  String get pdfUntitledPresentation;

  /// Title of the command `slides.group.rename` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get cmdGroupRename;

  /// Title of the command `slides.group.move` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move group'**
  String get cmdGroupMove;

  /// Title of the command `slides.group.toggleCollapsed`.
  ///
  /// In en, this message translates to:
  /// **'Collapse or expand group'**
  String get cmdGroupToggleCollapsed;

  /// Title of the command `slides.nav.selectAllSlides` (⌘A in the navigator).
  ///
  /// In en, this message translates to:
  /// **'Select all slides'**
  String get cmdNavSelectAllSlides;

  /// Title of the command `slides.navigator.copy`.
  ///
  /// In en, this message translates to:
  /// **'Copy slides'**
  String get cmdNavigatorCopy;

  /// Title of the command `slides.navigator.cut` (undo label).
  ///
  /// In en, this message translates to:
  /// **'Cut slides'**
  String get cmdNavigatorCut;

  /// Title of the command `slides.navigator.paste` (undo label).
  ///
  /// In en, this message translates to:
  /// **'Paste slides'**
  String get cmdNavigatorPaste;

  /// Title of the command `slides.notes.zoom`.
  ///
  /// In en, this message translates to:
  /// **'Speaker notes zoom'**
  String get cmdNotesZoom;

  /// Dynamic label of Delete slide with the selection count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete slide} other{Delete {count} slides}}'**
  String cmdSlideDeleteCount(int count);

  /// Dynamic label of Duplicate slide with the selection count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Duplicate slide} other{Duplicate {count} slides}}'**
  String cmdSlideDuplicateCount(int count);

  /// Undo label of typing in the speaker notes.
  ///
  /// In en, this message translates to:
  /// **'Edit speaker notes'**
  String get cmdEditNotes;

  /// Disabled reason: no slide is selected.
  ///
  /// In en, this message translates to:
  /// **'Select slides in the navigator'**
  String get reasonSelectSlides;

  /// Disabled reason of Group slides when the selection is exactly one group.
  ///
  /// In en, this message translates to:
  /// **'These slides are already a group'**
  String get reasonAlreadyGroup;

  /// Disabled reason of Skip slide for a slide inside a skipped group.
  ///
  /// In en, this message translates to:
  /// **'Skipped with group'**
  String get reasonSkippedWithGroup;

  /// Disabled reason of Remove from group / Ungroup.
  ///
  /// In en, this message translates to:
  /// **'The slide isn’t in a group'**
  String get reasonNotInGroup;

  /// Disabled reason of the collapse/expand all commands.
  ///
  /// In en, this message translates to:
  /// **'The presentation has no groups'**
  String get reasonNoGroups;

  /// Drop indicator tooltip and disabled reason when groups would go inside a group.
  ///
  /// In en, this message translates to:
  /// **'Groups can’t be nested'**
  String get reasonGroupsCantNest;

  /// Disabled reason of moving slides at the start/end.
  ///
  /// In en, this message translates to:
  /// **'The slides can’t move further'**
  String get reasonCantMoveFurther;

  /// Disabled reason of Paste in the navigator.
  ///
  /// In en, this message translates to:
  /// **'Copy slides or groups first'**
  String get reasonClipboardNoSlides;

  /// Disabled reason of Collapse group.
  ///
  /// In en, this message translates to:
  /// **'The group is already collapsed'**
  String get reasonAllCollapsed;

  /// Disabled reason of Expand group.
  ///
  /// In en, this message translates to:
  /// **'The group is already expanded'**
  String get reasonAllExpanded;

  /// Drop zone of an empty, expanded group in the navigator.
  ///
  /// In en, this message translates to:
  /// **'Drop slides here'**
  String get navigatorDropHere;

  /// Tooltip of the layout chevron next to + New slide.
  ///
  /// In en, this message translates to:
  /// **'New slide with layout'**
  String get navigatorNewSlideLayout;

  /// Badge of the drag ghost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide} other{{count} slides}}'**
  String navigatorDragSlides(int count);

  /// Badge of the drag ghost of a group.
  ///
  /// In en, this message translates to:
  /// **'{title} · {count, plural, =1{1 slide} other{{count} slides}}'**
  String navigatorDragGroup(String title, int count);

  /// Screen reader state of an expanded group header.
  ///
  /// In en, this message translates to:
  /// **'expanded'**
  String get navigatorGroupExpanded;

  /// Screen reader state of a collapsed group header.
  ///
  /// In en, this message translates to:
  /// **'collapsed'**
  String get navigatorGroupCollapsed;

  /// Screen reader state of a skipped slide or group.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get navigatorSkipped;

  /// Screen reader label of a slide row inside a group.
  ///
  /// In en, this message translates to:
  /// **'Slide {number} of {total}, in group {group}: {title}'**
  String navigatorSlideInGroupSemantics(
    int number,
    int total,
    String group,
    String title,
  );

  /// Tooltip of the ⋮ button of a group header.
  ///
  /// In en, this message translates to:
  /// **'Group actions'**
  String get navigatorGroupMenu;

  /// Tooltip of the ⋮ button of a slide row.
  ///
  /// In en, this message translates to:
  /// **'Slide actions'**
  String get navigatorSlideMenu;

  /// Tooltip of the chevron of an expanded group header.
  ///
  /// In en, this message translates to:
  /// **'Collapse group (Alt+click: all groups)'**
  String get navigatorCollapseGroup;

  /// Tooltip of the chevron of a collapsed group header.
  ///
  /// In en, this message translates to:
  /// **'Expand group (Alt+click: all groups)'**
  String get navigatorExpandGroup;

  /// Tooltip of the color dot of a group header.
  ///
  /// In en, this message translates to:
  /// **'Group color'**
  String get navigatorGroupColor;

  /// Label of the inline rename field of a group.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get navigatorRenameField;

  /// Tooltip of the skip badge of a slide inside a skipped group.
  ///
  /// In en, this message translates to:
  /// **'Skipped with group'**
  String get navigatorSkippedWithGroup;

  /// Title of the Delete group dialog (04 §13.4).
  ///
  /// In en, this message translates to:
  /// **'Delete group ‘{title}’?'**
  String deleteGroupTitle(String title);

  /// Body of the Delete group dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The group contains 1 slide.} other{The group contains {count} slides.}}'**
  String deleteGroupBody(int count);

  /// Title of the Delete group dialog for several groups.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} groups?'**
  String deleteGroupsTitle(int count);

  /// Delete group dialog: keep the slides.
  ///
  /// In en, this message translates to:
  /// **'Ungroup only'**
  String get deleteGroupUngroupOnly;

  /// Delete group dialog: destructive button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete group and 1 slide} other{Delete group and {count} slides}}'**
  String deleteGroupWithSlides(int count);

  /// Toast after deleting a group (Undo action next to it).
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get toastGroupDeleted;

  /// Title of the dialog choosing the group for Add to group.
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get chooseGroupTitle;

  /// Field label of the Add to group dialog.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get chooseGroupLabel;

  /// Primary button of the Add to group dialog.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get chooseGroupButton;

  /// Label of the grid view thumbnail size slider.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail size'**
  String get gridThumbSize;

  /// Hint in the grid view toolbar.
  ///
  /// In en, this message translates to:
  /// **'Double-click a slide to open it'**
  String get gridOpenHint;

  /// Speaker notes mini toolbar.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get notesBold;

  /// Speaker notes mini toolbar.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get notesItalic;

  /// Speaker notes mini toolbar.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get notesUnderline;

  /// Speaker notes mini toolbar.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get notesBulletList;

  /// Speaker notes mini toolbar.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get notesNumberedList;

  /// Speaker notes mini toolbar.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get notesLink;

  /// Title of the speaker notes link dialog.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get notesLinkTitle;

  /// Field of the speaker notes link dialog.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get notesLinkUrl;

  /// Primary button of the speaker notes link dialog.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get notesLinkApply;

  /// Button of the speaker notes link dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get notesLinkRemove;

  /// Validation of the speaker notes link dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter an http or https address'**
  String get notesLinkInvalid;

  /// Speaker notes of a viewer (read-only).
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get notesReadOnly;

  /// Speaker notes when the deck has no slides.
  ///
  /// In en, this message translates to:
  /// **'No slide selected'**
  String get notesNoSlide;

  /// Undo step of a typing burst in a text box (SL-13).
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get undoTyping;

  /// Primary button of the Slides value dialogs (font size, link, …).
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dialogApply;

  /// Title of the link dialog (04 §13.5).
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkDialogTitle;

  /// Label of the link target select.
  ///
  /// In en, this message translates to:
  /// **'Link to'**
  String get linkTargetLabel;

  /// Link target option: a URL typed below.
  ///
  /// In en, this message translates to:
  /// **'Web address'**
  String get linkTargetUrl;

  /// Label of the URL field of the link dialog.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get linkUrlLabel;

  /// Button of the link dialog that removes the link.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get linkRemove;

  /// Element link action.
  ///
  /// In en, this message translates to:
  /// **'Next slide'**
  String get linkActionNext;

  /// Element link action.
  ///
  /// In en, this message translates to:
  /// **'Previous slide'**
  String get linkActionPrevious;

  /// Element link action.
  ///
  /// In en, this message translates to:
  /// **'First slide'**
  String get linkActionFirst;

  /// Element link action.
  ///
  /// In en, this message translates to:
  /// **'Last slide'**
  String get linkActionLast;

  /// Element link action.
  ///
  /// In en, this message translates to:
  /// **'End show'**
  String get linkActionEnd;

  /// Label of the font select.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontLabel;

  /// Label of the font size field.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fontSizeLabel;

  /// Label of the color field of the text color dialog.
  ///
  /// In en, this message translates to:
  /// **'Color (#RRGGBB or theme:accent1; empty = automatic)'**
  String get colorLabel;

  /// Label of the custom line spacing field.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lineHeightLabel;

  /// Label of the list style select.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get listStyleLabel;

  /// Label of the list start field.
  ///
  /// In en, this message translates to:
  /// **'Start numbering at'**
  String get listStartLabel;

  /// Font option: the theme's heading font.
  ///
  /// In en, this message translates to:
  /// **'Theme heading font'**
  String get fontThemeHeading;

  /// Font option: the theme's body font.
  ///
  /// In en, this message translates to:
  /// **'Theme body font'**
  String get fontThemeBody;

  /// Font option: the theme's monospace font.
  ///
  /// In en, this message translates to:
  /// **'Theme monospace font'**
  String get fontThemeMono;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Disc'**
  String get listStyleDisc;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get listStyleCircle;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get listStyleSquare;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Dash'**
  String get listStyleDash;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get listStyleArrow;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Check mark'**
  String get listStyleCheck;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get listStyleStar;

  /// Bullet style.
  ///
  /// In en, this message translates to:
  /// **'No bullet'**
  String get listStyleNone;

  /// Command: letter spacing of the selected text.
  ///
  /// In en, this message translates to:
  /// **'Letter spacing'**
  String get cmdFormatLetterSpacing;

  /// Command: text insets of a text box.
  ///
  /// In en, this message translates to:
  /// **'Text insets'**
  String get cmdFormatInsets;

  /// Command: stops editing text and selects the box.
  ///
  /// In en, this message translates to:
  /// **'Exit text editing'**
  String get cmdTextExitEditing;

  /// Command: removes the link of the selected text.
  ///
  /// In en, this message translates to:
  /// **'Remove link from text'**
  String get cmdTextRemoveLink;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'No text is being edited'**
  String get reasonNotEditingText;

  /// Disabled reason of text format commands.
  ///
  /// In en, this message translates to:
  /// **'Select text or a text box'**
  String get reasonSelectText;

  /// Disabled reason of Insert link.
  ///
  /// In en, this message translates to:
  /// **'Select text or an object'**
  String get reasonSelectTextOrObject;

  /// Disabled reason of Remove link.
  ///
  /// In en, this message translates to:
  /// **'The selection has no link'**
  String get reasonNoLink;

  /// Disabled reason of Reset to layout.
  ///
  /// In en, this message translates to:
  /// **'Select a placeholder'**
  String get reasonSelectPlaceholder;

  /// Toast when formatting skipped soft-locked text boxes (03 §6.1).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Skipped 1 text box {name} is editing} other{Skipped {count} text boxes others are editing}}'**
  String toastSkippedLocked(int count, String name);

  /// Validation message of number fields.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from {min} to {max}'**
  String validationNumberRange(String min, String max);

  /// Text of a link to a slide inserted at the caret.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}'**
  String slideNumberLabel(int number);

  /// Theme color name (color picker swatch).
  ///
  /// In en, this message translates to:
  /// **'Background 1'**
  String get themeColorBg1;

  /// Theme color name (color picker swatch).
  ///
  /// In en, this message translates to:
  /// **'Background 2'**
  String get themeColorBg2;

  /// Theme color name (color picker swatch).
  ///
  /// In en, this message translates to:
  /// **'Text 1'**
  String get themeColorText1;

  /// Theme color name (color picker swatch).
  ///
  /// In en, this message translates to:
  /// **'Text 2'**
  String get themeColorText2;

  /// Theme accent color name.
  ///
  /// In en, this message translates to:
  /// **'Accent {n}'**
  String themeColorAccent(int n);

  /// Theme color name (color picker swatch).
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get themeColorLink;

  /// Name of a shape geometry (shape gallery, Change shape, MCP).
  ///
  /// In en, this message translates to:
  /// **'{geometry, select, rect{Rectangle} roundRect{Rounded rectangle} ellipse{Ellipse} triangle{Triangle} rightTriangle{Right triangle} diamond{Diamond} pentagon{Pentagon} hexagon{Hexagon} octagon{Octagon} parallelogram{Parallelogram} trapezoid{Trapezoid} donut{Donut} arc{Arc} blockArc{Block arc} pie{Pie} chord{Chord} frame{Frame} halfFrame{Half frame} plus{Plus} cross{Cross} cylinder{Cylinder} cube{Cube} can{Can} heart{Heart} cloud{Cloud} moon{Moon} sun{Sun} lightning{Lightning bolt} arrowRight{Right arrow} arrowLeft{Left arrow} arrowUp{Up arrow} arrowDown{Down arrow} arrowLeftRight{Left-right arrow} arrowUpDown{Up-down arrow} chevron{Chevron} homePlate{Pentagon arrow} notchedArrow{Notched arrow} curvedArrow{Curved arrow} circularArrow{Circular arrow} uTurn{U-turn arrow} star4{4-point star} star5{5-point star} star6{6-point star} star8{8-point star} star12{12-point star} burst{Burst} ribbon{Ribbon} wave{Wave} seal{Seal} speech{Speech bubble} speechRound{Round speech bubble} thought{Thought bubble} calloutRect{Rectangular callout} calloutLine{Line callout} banner{Banner} process{Process} decision{Decision} terminator{Terminator} document{Document} data{Data} manualInput{Manual input} predefinedProcess{Predefined process} connector{Connector} offPage{Off-page connector} delay{Delay} storage{Stored data} brace{Brace} bracket{Bracket} doubleBrace{Double brace} custom{Custom shape} other{Shape}}'**
  String shapeName(String geometry);

  /// Category heading of the shape gallery.
  ///
  /// In en, this message translates to:
  /// **'{category, select, basic{Basic shapes} arrows{Arrows} stars{Stars and badges} callouts{Callouts} flowchart{Flowchart} brackets{Brackets} custom{Custom} other{Shapes}}'**
  String shapeCategory(String category);

  /// Category of the icon picker sidebar.
  ///
  /// In en, this message translates to:
  /// **'{category, select, all{All icons} recent{Recently used} arrows{Arrows} business{Business} charts{Charts} communication{Communication} devices{Devices} development{Development} files{Files} food{Food and drink} media{Media} nature{Nature} people{People} security{Security} shapes{Shapes} text{Text} clock{Time} tools{Tools} travel{Travel} weather{Weather} other{Icons}}'**
  String iconCategory(String category);

  /// Arrowhead style of a line end.
  ///
  /// In en, this message translates to:
  /// **'{style, select, none{None} triangle{Arrow} open{Open arrow} stealth{Stealth arrow} circle{Circle} diamond{Diamond} bar{Bar} other{Arrow}}'**
  String arrowStyleName(String style);

  /// Arrowhead size.
  ///
  /// In en, this message translates to:
  /// **'{size, select, s{Small} m{Medium} l{Large} other{Medium}}'**
  String arrowSizeName(String size);

  /// Border/line dash style.
  ///
  /// In en, this message translates to:
  /// **'{dash, select, solid{Solid} dash{Dashed} dot{Dotted} dashDot{Dash-dot} longDash{Long dash} other{Solid}}'**
  String dashName(String dash);

  /// Line cap style.
  ///
  /// In en, this message translates to:
  /// **'{cap, select, butt{Flat} round{Round} square{Square} other{Flat}}'**
  String capName(String cap);

  /// Line routing.
  ///
  /// In en, this message translates to:
  /// **'{routing, select, straight{Straight} elbow{Elbow} curved{Curved} other{Straight}}'**
  String routingName(String routing);

  /// Name of a shape quick style (toolbar and Format › Shape menu).
  ///
  /// In en, this message translates to:
  /// **'{index, select, 0{Accent 1} 1{Accent 2} 2{Accent 3} 3{Accent 4} 4{Accent 5} 5{Accent 6} 6{Outline} 7{Soft tint} other{Style}}'**
  String quickStyleName(String index);

  /// Border/line weight in the weight menu.
  ///
  /// In en, this message translates to:
  /// **'{width} pt'**
  String strokeWidthLabel(String width);

  /// Command: choose another icon for the selected icon.
  ///
  /// In en, this message translates to:
  /// **'Replace icon…'**
  String get cmdIconReplace;

  /// Command: set the stroke width of Lucide icons.
  ///
  /// In en, this message translates to:
  /// **'Icon stroke width'**
  String get cmdIconSetStrokeWidth;

  /// Command: set an element's name (Layers panel, Arrange section).
  ///
  /// In en, this message translates to:
  /// **'Rename object'**
  String get cmdElementRename;

  /// Submenu: change the geometry of the selected shapes.
  ///
  /// In en, this message translates to:
  /// **'Change shape'**
  String get menuChangeShape;

  /// Submenu: theme-based shape styles.
  ///
  /// In en, this message translates to:
  /// **'Quick styles'**
  String get menuQuickStyles;

  /// Submenu: line routing.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get menuRouting;

  /// Border/line weight menu.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get menuWeight;

  /// Border/line dash menu.
  ///
  /// In en, this message translates to:
  /// **'Dash'**
  String get menuDash;

  /// Toolbar: border color picker.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get menuBorderColor;

  /// Toolbar: line color picker.
  ///
  /// In en, this message translates to:
  /// **'Line color'**
  String get menuLineColor;

  /// Toolbar: fill color picker.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get menuFillColor;

  /// Toolbar: icon color picker.
  ///
  /// In en, this message translates to:
  /// **'Icon color'**
  String get menuIconColor;

  /// Color picker reset: use the theme's default object style.
  ///
  /// In en, this message translates to:
  /// **'Theme default'**
  String get colorThemeDefault;

  /// Inspector label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get styleLabelColor;

  /// Inspector label (border/line width).
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get styleLabelWeight;

  /// Inspector label.
  ///
  /// In en, this message translates to:
  /// **'Dash'**
  String get styleLabelDash;

  /// Inspector label: line cap.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get styleLabelCap;

  /// Inspector label.
  ///
  /// In en, this message translates to:
  /// **'Arrow size'**
  String get styleLabelArrowSize;

  /// Inspector label.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get styleLabelRouting;

  /// Inspector label: drop shadow switch.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get styleLabelShadow;

  /// Inspector label: glow switch.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get styleLabelGlow;

  /// Inspector label.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get styleLabelOpacity;

  /// Fill picker: transparent.
  ///
  /// In en, this message translates to:
  /// **'No fill'**
  String get styleLabelNoFill;

  /// Border: none.
  ///
  /// In en, this message translates to:
  /// **'No border'**
  String get styleLabelNoBorder;

  /// Inspector label: the shape geometry.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get styleLabelGeometry;

  /// Icon stroke width label.
  ///
  /// In en, this message translates to:
  /// **'Stroke width'**
  String get styleLabelStrokeWidth;

  /// Inspector label: the icon's name.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get styleLabelIcon;

  /// A value differs between the selected objects.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get styleMixed;

  /// Arrange section: x position (slide units).
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get arrangeLabelX;

  /// Arrange section: y position (slide units).
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get arrangeLabelY;

  /// Arrange section: width (slide units).
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get arrangeLabelW;

  /// Arrange section: height (slide units).
  ///
  /// In en, this message translates to:
  /// **'H'**
  String get arrangeLabelH;

  /// Arrange section: rotation in degrees.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get arrangeLabelRotation;

  /// Arrange section: object name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get arrangeLabelName;

  /// Arrange section button for element groups.
  ///
  /// In en, this message translates to:
  /// **'Edit inside group'**
  String get arrangeEditInsideGroup;

  /// Arrange section: lock switch.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get arrangeLocked;

  /// Accessibility section: description of the object.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get accessibilityAltText;

  /// Placeholder of the alt text field.
  ///
  /// In en, this message translates to:
  /// **'Describe the object for people using screen readers'**
  String get accessibilityAltTextHint;

  /// Accessibility section: skipped by screen readers and alt text checks.
  ///
  /// In en, this message translates to:
  /// **'Decorative'**
  String get accessibilityDecorative;

  /// Accessibility section: the object's position in reading order.
  ///
  /// In en, this message translates to:
  /// **'Reading order: {position} of {count}'**
  String accessibilityReadingOrder(int position, int count);

  /// Title of the alt text dialog.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get altTextDialogTitle;

  /// Checkbox of the alt text dialog.
  ///
  /// In en, this message translates to:
  /// **'Mark as decorative (screen readers skip it)'**
  String get altTextDialogDecorative;

  /// Primary button of Slides dialogs that save a value.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// Title of the icon picker.
  ///
  /// In en, this message translates to:
  /// **'Insert icon'**
  String get iconPickerTitle;

  /// Title of the icon picker when replacing an icon.
  ///
  /// In en, this message translates to:
  /// **'Replace icon'**
  String get iconPickerReplaceTitle;

  /// Search field of the icon picker.
  ///
  /// In en, this message translates to:
  /// **'Search icons'**
  String get iconPickerSearch;

  /// Icon picker without results.
  ///
  /// In en, this message translates to:
  /// **'No icons match “{query}”'**
  String iconPickerEmpty(String query);

  /// Number of icons shown in the picker.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 icon} other{{count} icons}}'**
  String iconPickerCount(int count);

  /// Empty Recently used category of the icon picker.
  ///
  /// In en, this message translates to:
  /// **'Icons you insert show up here'**
  String get iconPickerRecentEmpty;

  /// Icon picker: stroke width.
  ///
  /// In en, this message translates to:
  /// **'Stroke'**
  String get iconPickerStroke;

  /// Icon picker: icon color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get iconPickerColor;

  /// Icon picker: category select (narrow widths).
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get iconPickerCategory;

  /// Icon picker primary button.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get iconPickerInsert;

  /// Icon picker primary button when replacing.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get iconPickerReplace;

  /// Title of the All shapes dialog.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get shapeGalleryTitle;

  /// Primary button of the All shapes dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get shapeGalleryChoose;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'Select a shape'**
  String get reasonSelectShape;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'Select a line'**
  String get reasonSelectLine;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'Select an icon'**
  String get reasonSelectIcon;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'Select one object'**
  String get reasonSelectOneObject;

  /// Disabled reason of fill commands.
  ///
  /// In en, this message translates to:
  /// **'Select a shape, text box or icon'**
  String get reasonNoFill;

  /// Disabled reason of border commands.
  ///
  /// In en, this message translates to:
  /// **'Select a shape, line, text box, image or icon'**
  String get reasonNoBorder;

  /// Disabled reason of Group.
  ///
  /// In en, this message translates to:
  /// **'Placeholders can\'t be grouped'**
  String get reasonPlaceholdersCantGroup;

  /// Disabled reason of Group.
  ///
  /// In en, this message translates to:
  /// **'Select objects in the same group'**
  String get reasonSameLevel;

  /// Disabled reason of Paste style.
  ///
  /// In en, this message translates to:
  /// **'Copy a style first'**
  String get reasonNoStyleCopied;

  /// Announcement when Paint format is armed.
  ///
  /// In en, this message translates to:
  /// **'Click an object to apply the format'**
  String get painterArmed;

  /// Announcement when a shape tool is armed.
  ///
  /// In en, this message translates to:
  /// **'Click or drag on the slide to insert the shape'**
  String get toolArmedShape;

  /// Announcement when a line tool is armed.
  ///
  /// In en, this message translates to:
  /// **'Drag on the slide to draw the line'**
  String get toolArmedLine;

  /// Reset option of the text color picker (the style's color).
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get colorAutomatic;

  /// Inspector value when the selection has different values.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get inspectorMixed;

  /// Inspector › Text: space before paragraphs (su).
  ///
  /// In en, this message translates to:
  /// **'Space before'**
  String get spacingBeforeLabel;

  /// Inspector › Text: space after paragraphs (su).
  ///
  /// In en, this message translates to:
  /// **'Space after'**
  String get spacingAfterLabel;

  /// Disabled reason of image commands.
  ///
  /// In en, this message translates to:
  /// **'Select an image'**
  String get reasonSelectImage;

  /// Disabled reason of Download original.
  ///
  /// In en, this message translates to:
  /// **'Downloading isn\'t allowed for this presentation'**
  String get reasonNoDownload;

  /// Disabled reason of table commands.
  ///
  /// In en, this message translates to:
  /// **'Select a table'**
  String get reasonSelectTable;

  /// Disabled reason of commands that need a cell range.
  ///
  /// In en, this message translates to:
  /// **'Select table cells'**
  String get reasonSelectCells;

  /// Disabled reason of Unmerge cells.
  ///
  /// In en, this message translates to:
  /// **'No merged cells in the selection'**
  String get reasonNoMergedCells;

  /// Undo label of a crop.
  ///
  /// In en, this message translates to:
  /// **'Crop image'**
  String get undoCropImage;

  /// Enter in crop mode.
  ///
  /// In en, this message translates to:
  /// **'Apply crop'**
  String get cmdImageCropApply;

  /// Esc in crop mode.
  ///
  /// In en, this message translates to:
  /// **'Cancel crop'**
  String get cmdImageCropCancel;

  /// Retries an image upload refused for storage.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get cmdImageRetryUpload;

  /// Removes an image that couldn't be uploaded.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get cmdImageRemoveNotUploaded;

  /// Command: write row heights / column widths (border drag).
  ///
  /// In en, this message translates to:
  /// **'Resize rows or columns'**
  String get cmdTableResizeAxes;

  /// Command: cell padding.
  ///
  /// In en, this message translates to:
  /// **'Cell padding'**
  String get cmdTableSetCellPadding;

  /// Command: clear the text of the selected cells.
  ///
  /// In en, this message translates to:
  /// **'Clear cells'**
  String get cmdTableClearCells;

  /// Command: select a cell range.
  ///
  /// In en, this message translates to:
  /// **'Select cells'**
  String get cmdTableSelectCells;

  /// Command: arrow keys in a table.
  ///
  /// In en, this message translates to:
  /// **'Move cell selection'**
  String get cmdTableMoveSelection;

  /// Command: Tab in a table.
  ///
  /// In en, this message translates to:
  /// **'Next cell'**
  String get cmdTableNextCell;

  /// Command: Shift+Tab in a table.
  ///
  /// In en, this message translates to:
  /// **'Previous cell'**
  String get cmdTablePreviousCell;

  /// Command: edit the active cell's text.
  ///
  /// In en, this message translates to:
  /// **'Edit cell'**
  String get cmdTableEditCell;

  /// Command: Esc in a cell selection.
  ///
  /// In en, this message translates to:
  /// **'Select the whole table'**
  String get cmdTableClearCellSelection;

  /// Toast when an image's bytes can't be loaded.
  ///
  /// In en, this message translates to:
  /// **'This image isn\'t available right now.'**
  String get imageNotAvailable;

  /// File picker title for images.
  ///
  /// In en, this message translates to:
  /// **'Choose images'**
  String get imagePickTitle;

  /// Insert from clipboard without an image.
  ///
  /// In en, this message translates to:
  /// **'There\'s no image on the clipboard.'**
  String get imageClipboardEmpty;

  /// URL validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter an https:// image address.'**
  String get imageUrlInvalid;

  /// Insert by URL / Drive failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this image.'**
  String get imageFetchFailed;

  /// Insert refused for quota (agents).
  ///
  /// In en, this message translates to:
  /// **'You\'re out of storage.'**
  String get imageOutOfStorage;

  /// Image too large.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t insert \'{name}\' — images can be at most 50 MB.'**
  String imageRejectedTooLarge(String name);

  /// Unsupported image type (03 §6.5.1).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t insert \'{name}\' — this image type isn\'t supported.'**
  String imageRejectedFormat(String name);

  /// Title of the image source dialog.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get imageInsertDialogTitle;

  /// Title of the image source dialog when replacing.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get imageReplaceDialogTitle;

  /// Field label of the image source select.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get imageSourceLabel;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get dialogContinue;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get dialogInsert;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Title of the URL dialog (04 §13.2).
  ///
  /// In en, this message translates to:
  /// **'Insert image by URL'**
  String get imageUrlDialogTitle;

  /// Description of the URL dialog.
  ///
  /// In en, this message translates to:
  /// **'The image is fetched through Wonky Work and stored with the presentation.'**
  String get imageUrlDialogBody;

  /// URL field label.
  ///
  /// In en, this message translates to:
  /// **'Image address'**
  String get imageUrlLabel;

  /// Title of the mask dialog.
  ///
  /// In en, this message translates to:
  /// **'Mask with shape'**
  String get imageMaskDialogTitle;

  /// Mask shape field.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get imageMaskShape;

  /// Removes the mask.
  ///
  /// In en, this message translates to:
  /// **'No mask'**
  String get imageMaskNone;

  /// Title of the Drive image picker.
  ///
  /// In en, this message translates to:
  /// **'Insert image from Wonky Drive'**
  String get imageDriveDialogTitle;

  /// Search field of the Drive image picker.
  ///
  /// In en, this message translates to:
  /// **'Search images'**
  String get imageDriveSearch;

  /// Select field of the Drive image picker (MCP).
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageDriveImage;

  /// Drive picker error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your images. Check your connection.'**
  String get imageDriveFailed;

  /// Drive picker without results.
  ///
  /// In en, this message translates to:
  /// **'No images found.'**
  String get imageDriveEmpty;

  /// Crop aspect preset.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get cropAspectFree;

  /// Crop aspect preset.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get cropAspectOriginal;

  /// Crop bar: image covers the box.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get cropFill;

  /// Crop bar: whole image in the box.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get cropFit;

  /// Crop bar: commit.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cropDone;

  /// Badge on an image refused for storage (Drive 03 §6.3).
  ///
  /// In en, this message translates to:
  /// **'Not uploaded — out of storage'**
  String get imageNotUploadedOutOfStorage;

  /// Retry button of the badge.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get imageRetry;

  /// Remove button of the badge.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get imageRemove;

  /// Insert table dialog validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to {max}.'**
  String tableSizeInvalid(int max);

  /// Insert table dialog title.
  ///
  /// In en, this message translates to:
  /// **'Insert table'**
  String get tableInsertDialogTitle;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get tableRows;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get tableColumns;

  /// Title of `slides.theme.apply` (Themes panel; undo label).
  ///
  /// In en, this message translates to:
  /// **'Apply theme'**
  String get cmdThemeApply;

  /// Title of `slides.theme.import`.
  ///
  /// In en, this message translates to:
  /// **'Import theme from a presentation…'**
  String get cmdThemeImport;

  /// Title of `slides.theme.rename`.
  ///
  /// In en, this message translates to:
  /// **'Rename theme…'**
  String get cmdThemeRename;

  /// Title of `slides.theme.duplicate`.
  ///
  /// In en, this message translates to:
  /// **'Duplicate theme'**
  String get cmdThemeDuplicate;

  /// Title of `slides.theme.setDefault`.
  ///
  /// In en, this message translates to:
  /// **'Set as default theme'**
  String get cmdThemeSetDefault;

  /// Title of `slides.theme.delete`.
  ///
  /// In en, this message translates to:
  /// **'Remove theme'**
  String get cmdThemeDelete;

  /// Title of `slides.theme.removeUnused`.
  ///
  /// In en, this message translates to:
  /// **'Remove unused themes'**
  String get cmdThemeRemoveUnused;

  /// Title of `slides.deck.setSize`.
  ///
  /// In en, this message translates to:
  /// **'Change slide size'**
  String get cmdDeckSetSize;

  /// Title of `slides.deck.setNumbering`.
  ///
  /// In en, this message translates to:
  /// **'Set slide numbers and footer'**
  String get cmdDeckSetNumbering;

  /// Undo label of Page setup.
  ///
  /// In en, this message translates to:
  /// **'Change slide size'**
  String get undoChangeSlideSize;

  /// Undo label of the slide numbers dialog.
  ///
  /// In en, this message translates to:
  /// **'Slide numbers and footer'**
  String get undoNumbering;

  /// Disabled reason of Remove theme.
  ///
  /// In en, this message translates to:
  /// **'Used by slides — apply another theme to them first'**
  String get reasonThemeInUse;

  /// Disabled reason of Set as default theme.
  ///
  /// In en, this message translates to:
  /// **'Already the default theme'**
  String get reasonThemeIsDefault;

  /// Disabled reason of Remove unused themes.
  ///
  /// In en, this message translates to:
  /// **'Every theme is in use'**
  String get reasonNoUnusedThemes;

  /// Title of the Themes side panel.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themesPanelTitle;

  /// Themes panel: heading of the scope choice.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get themesApplyTo;

  /// Themes panel scope: every slide.
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get themesApplyAll;

  /// Themes panel scope: the selected slides.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Selected slide} other{Selected slides ({count})}}'**
  String themesApplySelected(int count);

  /// Themes panel: heading of the deck's themes.
  ///
  /// In en, this message translates to:
  /// **'In this presentation'**
  String get themesInPresentation;

  /// Themes panel: heading of the built-in themes.
  ///
  /// In en, this message translates to:
  /// **'Built-in themes'**
  String get themesBuiltIn;

  /// Themes panel button.
  ///
  /// In en, this message translates to:
  /// **'Import theme from a presentation…'**
  String get themesImport;

  /// Badge of the deck's default theme.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themesDefault;

  /// Usage of a theme.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not used} =1{Used by 1 slide} other{Used by {count} slides}}'**
  String themesUsedBy(int count);

  /// Semantics label of a theme's ⋮ button.
  ///
  /// In en, this message translates to:
  /// **'More actions for {name}'**
  String themesMore(String name);

  /// Name shown for a theme without a name.
  ///
  /// In en, this message translates to:
  /// **'Untitled theme'**
  String get themeUntitled;

  /// Subtitle drawn on theme previews.
  ///
  /// In en, this message translates to:
  /// **'Title and subtitle'**
  String get themePreviewSubtitle;

  /// Name of a duplicated theme.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String themeCopyName(String name);

  /// Rename theme dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename theme'**
  String get themeRenameTitle;

  /// Rename theme dialog field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get themeNameLabel;

  /// Rename theme validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get themeNameEmpty;

  /// Rename theme dialog button.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get themeRenameButton;

  /// Presentation picker title.
  ///
  /// In en, this message translates to:
  /// **'Import theme from a presentation'**
  String get themeImportPickTitle;

  /// Presentation picker search field.
  ///
  /// In en, this message translates to:
  /// **'Search presentations'**
  String get themeImportSearch;

  /// Presentation picker field (MCP).
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get themeImportPresentation;

  /// Presentation picker empty state.
  ///
  /// In en, this message translates to:
  /// **'No other presentations'**
  String get themeImportNoPresentations;

  /// Theme import needs the server.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to import a theme'**
  String get themeImportOffline;

  /// Theme chooser title (decks with several themes).
  ///
  /// In en, this message translates to:
  /// **'Choose a theme'**
  String get themeImportChooseTitle;

  /// A theme of the source deck in the chooser.
  ///
  /// In en, this message translates to:
  /// **'{name} — {count, plural, =0{not used} =1{1 slide} other{{count} slides}}'**
  String themeImportOption(String name, int count);

  /// Theme chooser button.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get themeImportButton;

  /// Toast after importing a theme.
  ///
  /// In en, this message translates to:
  /// **'Theme “{name}” added'**
  String themeImported(String name);

  /// Toast action after importing a theme.
  ///
  /// In en, this message translates to:
  /// **'Apply to all slides'**
  String get themeApplyToAll;

  /// Inspector › Slide › Background.
  ///
  /// In en, this message translates to:
  /// **'Reset to layout background'**
  String get backgroundResetToLayout;

  /// Page setup dialog title.
  ///
  /// In en, this message translates to:
  /// **'Page setup'**
  String get pageSetupTitle;

  /// Page setup: size preset.
  ///
  /// In en, this message translates to:
  /// **'Slide size'**
  String get pageSetupPreset;

  /// Page setup: unit of width and height.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get pageSetupUnit;

  /// Page setup: scaling choice heading.
  ///
  /// In en, this message translates to:
  /// **'Existing content'**
  String get pageSetupContent;

  /// Page setup: scale content.
  ///
  /// In en, this message translates to:
  /// **'Scale content to fit'**
  String get pageSetupScale;

  /// Page setup: keep frames.
  ///
  /// In en, this message translates to:
  /// **'Don\'t scale'**
  String get pageSetupDontScale;

  /// Page setup: preview label.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get pageSetupPreview;

  /// Apply button of page setup and slide numbers.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get pageSetupApply;

  /// Page setup validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a width and a height.'**
  String get pageSetupEnterSize;

  /// Page setup validation.
  ///
  /// In en, this message translates to:
  /// **'Each side must be between 320 and 7,680 su.'**
  String get pageSetupSideRange;

  /// Page setup validation.
  ///
  /// In en, this message translates to:
  /// **'The aspect ratio must be between 1:4 and 4:1.'**
  String get pageSetupAspectRange;

  /// Custom slide size.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get sizeCustom;

  /// Slide numbers dialog title.
  ///
  /// In en, this message translates to:
  /// **'Slide numbers and footer'**
  String get numberingTitle;

  /// Slide numbers dialog field.
  ///
  /// In en, this message translates to:
  /// **'Show slide numbers'**
  String get numberingShow;

  /// Slide numbers dialog field.
  ///
  /// In en, this message translates to:
  /// **'First slide number'**
  String get numberingFirst;

  /// Slide numbers validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to 9999'**
  String get numberingFirstInvalid;

  /// Slide numbers dialog field.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show on title slides'**
  String get numberingHideOnTitle;

  /// Slide numbers dialog field.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get numberingFooter;

  /// Slide numbers dialog placeholder.
  ///
  /// In en, this message translates to:
  /// **'Empty = no footer'**
  String get numberingFooterHint;

  /// Image section: the image is still uploading from this device.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get imageUploading;

  /// Image section heading.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get imageAdjustments;

  /// Image adjustment.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get imageBrightness;

  /// Image adjustment.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get imageContrast;

  /// Image adjustment.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get imageSaturation;

  /// Image adjustment.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get imageTemperature;

  /// Image adjustment.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get imageBlur;

  /// Image adjustment toggle.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get imageGrayscale;

  /// Image adjustment toggle.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get imageSepia;

  /// Image adjustment toggle.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get imageInvert;

  /// Table section: table style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get tableStyle;

  /// Table style: the theme's.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get tableStyleTheme;

  /// Table style: plain.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get tableStyleNone;

  /// Table option.
  ///
  /// In en, this message translates to:
  /// **'Header row'**
  String get tableHeaderRow;

  /// Table option.
  ///
  /// In en, this message translates to:
  /// **'First column'**
  String get tableFirstColumn;

  /// Table option.
  ///
  /// In en, this message translates to:
  /// **'Banded rows'**
  String get tableBandedRows;

  /// Table option.
  ///
  /// In en, this message translates to:
  /// **'Banded columns'**
  String get tableBandedColumns;

  /// Table option.
  ///
  /// In en, this message translates to:
  /// **'Total row'**
  String get tableTotalRow;

  /// Cell section: size of the cell selection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cell selected} other{{count} cells selected}}'**
  String tableCellsSelected(int count);

  /// Cell section: cell fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get tableCellFill;

  /// Reset of the cell fill (back to the table style).
  ///
  /// In en, this message translates to:
  /// **'Table style'**
  String get tableStyleFill;

  /// Cell section: vertical alignment.
  ///
  /// In en, this message translates to:
  /// **'Align'**
  String get tableVerticalAlign;

  /// Cell section: cell padding (su).
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get tableCellPadding;

  /// Placeholder of the padding select.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get tableStyleDefault;

  /// Cell section: borders.
  ///
  /// In en, this message translates to:
  /// **'Borders'**
  String get tableBorders;

  /// Edge buttons of the border picker.
  ///
  /// In en, this message translates to:
  /// **'{edge, select, all{All borders} outer{Outer borders} inner{Inner borders} horizontal{Inner horizontal borders} vertical{Inner vertical borders} top{Top border} bottom{Bottom border} left{Left border} right{Right border} none{Clear borders} other{Borders}}'**
  String tableBorderEdge(String edge);

  /// Border styles.
  ///
  /// In en, this message translates to:
  /// **'{style, select, solid{Solid} dashed{Dashed} dotted{Dotted} other{Solid}}'**
  String tableBorderStyle(String style);

  /// Title of the command `slides.present.end`.
  ///
  /// In en, this message translates to:
  /// **'End presentation'**
  String get cmdPresentEnd;

  /// Title of the command `slides.present.next` (next step or slide).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get cmdPresentNext;

  /// Title of the command `slides.present.previous`.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get cmdPresentPrevious;

  /// Title of the command `slides.present.nextSlide` (skips remaining builds).
  ///
  /// In en, this message translates to:
  /// **'Next slide'**
  String get cmdPresentNextSlide;

  /// Title of the command `slides.present.previousSlide`.
  ///
  /// In en, this message translates to:
  /// **'Previous slide'**
  String get cmdPresentPreviousSlide;

  /// Title of the command `slides.present.goTo`.
  ///
  /// In en, this message translates to:
  /// **'Go to slide'**
  String get cmdPresentGoTo;

  /// Title of the command `slides.present.first`.
  ///
  /// In en, this message translates to:
  /// **'First slide'**
  String get cmdPresentFirst;

  /// Title of the command `slides.present.last`.
  ///
  /// In en, this message translates to:
  /// **'Last slide'**
  String get cmdPresentLast;

  /// Title of the command `slides.present.blank`.
  ///
  /// In en, this message translates to:
  /// **'Black or white screen'**
  String get cmdPresentBlank;

  /// Title of the command `slides.present.picker`.
  ///
  /// In en, this message translates to:
  /// **'Slide picker'**
  String get cmdPresentPicker;

  /// Title of the command `slides.present.tool` (laser, pen, highlighter, eraser).
  ///
  /// In en, this message translates to:
  /// **'Pointer tool'**
  String get cmdPresentTool;

  /// Title of the command `slides.present.clearInk`.
  ///
  /// In en, this message translates to:
  /// **'Clear ink on this slide'**
  String get cmdPresentClearInk;

  /// Title of the command `slides.present.undoInk`.
  ///
  /// In en, this message translates to:
  /// **'Undo last ink stroke'**
  String get cmdPresentUndoInk;

  /// Title of the command `slides.present.timer` (start, pause, reset).
  ///
  /// In en, this message translates to:
  /// **'Presenter timer'**
  String get cmdPresentTimer;

  /// Title of the command `slides.present.joinAsAudience`.
  ///
  /// In en, this message translates to:
  /// **'Show audience view here'**
  String get cmdPresentJoinAsAudience;

  /// Title of the command `slides.present.toggleFullscreen`.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get cmdPresentToggleFullscreen;

  /// Title of the command `slides.present.toggleSkipped` (presenter view).
  ///
  /// In en, this message translates to:
  /// **'Show skipped slides'**
  String get cmdPresentToggleSkipped;

  /// Title of the command `slides.present.notesSize`.
  ///
  /// In en, this message translates to:
  /// **'Speaker notes size'**
  String get cmdPresentNotesSize;

  /// Title of the command `slides.present.help` (the help overlay while presenting).
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get cmdPresentHelp;

  /// Title (and undo label) of the command `slides.deck.setPresentSettings`.
  ///
  /// In en, this message translates to:
  /// **'Presentation settings'**
  String get cmdDeckSetPresentSettings;

  /// Disabled reason of in-presentation commands.
  ///
  /// In en, this message translates to:
  /// **'Not presenting'**
  String get reasonNotPresenting;

  /// Disabled reason of presenter-view commands.
  ///
  /// In en, this message translates to:
  /// **'Only in the presenter view'**
  String get reasonPresenterViewOnly;

  /// Error of a go-to command with an unknown slide.
  ///
  /// In en, this message translates to:
  /// **'That slide isn’t in this presentation'**
  String get presentUnknownSlide;

  /// Screen reader label of the presented slide.
  ///
  /// In en, this message translates to:
  /// **'Slide {number} of {total}'**
  String presentSlideLabel(int number, int total);

  /// End screen after the last slide.
  ///
  /// In en, this message translates to:
  /// **'End of presentation — click to exit'**
  String get presentEndScreen;

  /// Kiosk mode: shown with a progress ring while Esc is held to end the presentation (Slides 10 §9).
  ///
  /// In en, this message translates to:
  /// **'Keep holding Esc to exit'**
  String get presentKioskExitHold;

  /// Presenter view indicator: the running animation was too slow for this device and plays as a crossfade (Slides 06 §14).
  ///
  /// In en, this message translates to:
  /// **'Reduced effects'**
  String get presenterReducedEffects;

  /// Audience view while the presenter's slide is still syncing.
  ///
  /// In en, this message translates to:
  /// **'Catching up…'**
  String get presentCatchingUp;

  /// Screen reader label of the present toolbar.
  ///
  /// In en, this message translates to:
  /// **'Presentation controls'**
  String get presentToolbarLabel;

  /// Screen reader label of the toolbar's slide counter.
  ///
  /// In en, this message translates to:
  /// **'Slide {number} of {total}. Open the slide picker'**
  String presentCounterLabel(int number, int total);

  /// Present tool.
  ///
  /// In en, this message translates to:
  /// **'Laser pointer'**
  String get presentToolLaser;

  /// Present tool.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get presentToolPen;

  /// Present tool.
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get presentToolHighlighter;

  /// Present tool.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get presentToolEraser;

  /// Present action covering the slide in black.
  ///
  /// In en, this message translates to:
  /// **'Black screen'**
  String get presentBlackScreen;

  /// Present action covering the slide in white.
  ///
  /// In en, this message translates to:
  /// **'White screen'**
  String get presentWhiteScreen;

  /// Button that ends the presentation.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get presentEnd;

  /// Overlay while digits are typed to go to a slide.
  ///
  /// In en, this message translates to:
  /// **'Go to {number}'**
  String presentGoToNumber(String number);

  /// Title of the shortcut help overlay while presenting.
  ///
  /// In en, this message translates to:
  /// **'Presenting shortcuts'**
  String get presentHelpTitle;

  /// Help overlay row.
  ///
  /// In en, this message translates to:
  /// **'Go to slide number'**
  String get presentHelpGoToNumber;

  /// Help overlay keys for going to a slide by number.
  ///
  /// In en, this message translates to:
  /// **'1 2 3 … Enter'**
  String get presentHelpDigits;

  /// Help overlay row for holding Cmd/Ctrl.
  ///
  /// In en, this message translates to:
  /// **'Laser while held (move the mouse)'**
  String get presentHelpTemporaryLaser;

  /// Present timer action.
  ///
  /// In en, this message translates to:
  /// **'Pause or resume the timer'**
  String get presentTimerPause;

  /// Present timer action.
  ///
  /// In en, this message translates to:
  /// **'Resume the timer'**
  String get presentTimerResume;

  /// Present timer action.
  ///
  /// In en, this message translates to:
  /// **'Reset the timer'**
  String get presentTimerReset;

  /// Presenter view notes size.
  ///
  /// In en, this message translates to:
  /// **'Larger notes'**
  String get presentNotesLarger;

  /// Presenter view notes size.
  ///
  /// In en, this message translates to:
  /// **'Smaller notes'**
  String get presentNotesSmaller;

  /// Help overlay row: F5 resumes while presenting.
  ///
  /// In en, this message translates to:
  /// **'Resume (clicker F5)'**
  String get presentResume;

  /// Hint when the browser refused full screen.
  ///
  /// In en, this message translates to:
  /// **'Press F11 (⌃⌘F on Mac) for full screen'**
  String get presentFullscreenHint;

  /// Button that enters full screen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get presentFullscreenButton;

  /// Title of the audience view's start card.
  ///
  /// In en, this message translates to:
  /// **'Audience view'**
  String get presentAudienceTitle;

  /// Audience view start card.
  ///
  /// In en, this message translates to:
  /// **'This screen shows the slides of your presentation.'**
  String get presentAudienceBody;

  /// Audience view start card with the presenter's device.
  ///
  /// In en, this message translates to:
  /// **'This screen shows the slides you present on {device}.'**
  String presentAudienceBodyFrom(String device);

  /// Audience view start card hint.
  ///
  /// In en, this message translates to:
  /// **'A clicker or the arrow keys here also move the presentation.'**
  String get presentAudienceKeys;

  /// Audience view start card: keep the window.
  ///
  /// In en, this message translates to:
  /// **'Stay in window'**
  String get presentAudienceStay;

  /// Present context menu item that opens the slide picker.
  ///
  /// In en, this message translates to:
  /// **'Go to slide…'**
  String get presentGoToSlideMenu;

  /// Title of the slide picker while presenting.
  ///
  /// In en, this message translates to:
  /// **'Go to slide'**
  String get presentPickerTitle;

  /// Placeholder of the slide picker filter.
  ///
  /// In en, this message translates to:
  /// **'Filter by title or number'**
  String get presentPickerFilter;

  /// Closes the slide picker.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get presentPickerClose;

  /// Slide picker with a filter that matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No slides match'**
  String get presentPickerNoMatch;

  /// Screen reader label of a group header in the slide picker.
  ///
  /// In en, this message translates to:
  /// **'{title}, {count, plural, =1{1 slide} other{{count} slides}}'**
  String presentPickerGroup(String title, int count);

  /// Screen reader label of a slide in the picker and the strip.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}: {title}'**
  String presentPickerSlide(int number, String title);

  /// Screen reader hint of a skipped slide.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get presentPickerSkipped;

  /// Title of the audience link dialog.
  ///
  /// In en, this message translates to:
  /// **'Open on another device'**
  String get presentOpenOnDeviceTitle;

  /// Body of the audience link dialog.
  ///
  /// In en, this message translates to:
  /// **'Open this link on the computer or browser that shows the slides — for example the one connected to the projector. Sign in with your account there.'**
  String get presentOpenOnDeviceBody;

  /// Hint in the audience link dialog.
  ///
  /// In en, this message translates to:
  /// **'Or open this presentation there and choose “Show audience view here”.'**
  String get presentOpenOnDeviceHint;

  /// Label of the audience link field.
  ///
  /// In en, this message translates to:
  /// **'Audience link'**
  String get presentAudienceLink;

  /// Copies the audience link.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get presentCopyLink;

  /// Button label after the link was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get presentLinkCopied;

  /// Closes the audience link dialog.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get presentDone;

  /// Screen reader label of the QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code of the audience link'**
  String get presentQrLabel;

  /// Presenting without a connection.
  ///
  /// In en, this message translates to:
  /// **'Offline — other devices can’t join'**
  String get presentOfflineNoDevices;

  /// Presenting without a connection, details.
  ///
  /// In en, this message translates to:
  /// **'You can keep presenting here. Other devices join once you’re back online.'**
  String get presentOfflineNoDevicesBody;

  /// Presentation session status.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get presentConnecting;

  /// Presenter view: the session ended.
  ///
  /// In en, this message translates to:
  /// **'Not connected to other devices'**
  String get presentSessionEnded;

  /// Presenter view: devices showing the audience view.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No other devices yet} =1{1 other device} other{{count} other devices}}'**
  String presentAudienceDevices(int count);

  /// Audience view while the presenter reconnects.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the presenter…'**
  String get presentPresenterAway;

  /// Audience view before the first state arrives.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the presenter'**
  String get presentWaitingForPresenter;

  /// Toast on the audience device when the presenter ends.
  ///
  /// In en, this message translates to:
  /// **'The presentation ended'**
  String get presentAudienceEndedToast;

  /// Audience link of a session that ended or never existed.
  ///
  /// In en, this message translates to:
  /// **'This presentation isn’t running'**
  String get presentAudienceNotFound;

  /// Audience link that can't be joined, details.
  ///
  /// In en, this message translates to:
  /// **'Ask the presenter for a new link, or open the presentation and choose “Show audience view here”.'**
  String get presentAudienceNotFoundBody;

  /// Audience link opened by another account.
  ///
  /// In en, this message translates to:
  /// **'Only the presenter can show this audience view'**
  String get presentAudienceNoAccess;

  /// Dialog when the presenter view is already open elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Take over the presentation?'**
  String get presentTakeOverTitle;

  /// Body of the take-over dialog.
  ///
  /// In en, this message translates to:
  /// **'You’re presenting this in another window. Take over the presentation from your other window?'**
  String get presentTakeOverBody;

  /// Confirms taking over the presentation.
  ///
  /// In en, this message translates to:
  /// **'Take over'**
  String get presentTakeOver;

  /// Keeps the other window's session; presents alone here.
  ///
  /// In en, this message translates to:
  /// **'Present here only'**
  String get presentTakeOverCancel;

  /// Toast when another window took over the presentation.
  ///
  /// In en, this message translates to:
  /// **'Your presentation continues in another window'**
  String get presentTakenOverToast;

  /// One-time hint with an extended display.
  ///
  /// In en, this message translates to:
  /// **'Showing the slides on a projector?'**
  String get presentExtendedHintTitle;

  /// One-time hint with an extended display, details.
  ///
  /// In en, this message translates to:
  /// **'Open this presentation in a window there and choose “Show audience view here” — or use “Open on another device…”.'**
  String get presentExtendedHintBody;

  /// Title of the presenter view (narrow).
  ///
  /// In en, this message translates to:
  /// **'Presenter view'**
  String get presenterViewTitle;

  /// Title of the presenter view.
  ///
  /// In en, this message translates to:
  /// **'Presenter view — {name}'**
  String presenterViewTitleWithName(String name);

  /// Presenter view header button: open on another device.
  ///
  /// In en, this message translates to:
  /// **'Other device…'**
  String get presenterOtherDevice;

  /// Presenter view: label of the current slide.
  ///
  /// In en, this message translates to:
  /// **'Current slide'**
  String get presenterCurrent;

  /// Presenter view: current slide with builds.
  ///
  /// In en, this message translates to:
  /// **'Current slide · step {step} of {count}'**
  String presenterCurrentStep(int step, int count);

  /// Presenter view while the screen is black.
  ///
  /// In en, this message translates to:
  /// **'Audience: black screen'**
  String get presenterAudienceBlack;

  /// Presenter view while the screen is white.
  ///
  /// In en, this message translates to:
  /// **'Audience: white screen'**
  String get presenterAudienceWhite;

  /// Presenter view: returns from black/white.
  ///
  /// In en, this message translates to:
  /// **'Show slide'**
  String get presenterShowSlide;

  /// Presenter view: the next step of this slide.
  ///
  /// In en, this message translates to:
  /// **'Next: build {step} of {count}'**
  String presenterNextBuild(int step, int count);

  /// Presenter view: the next slide.
  ///
  /// In en, this message translates to:
  /// **'Next slide: {title}'**
  String presenterNextSlide(String title);

  /// Presenter view: the next slide without a title.
  ///
  /// In en, this message translates to:
  /// **'Next slide'**
  String get presenterNextSlideUntitled;

  /// Presenter view: nothing follows.
  ///
  /// In en, this message translates to:
  /// **'End of presentation'**
  String get presenterNextEnd;

  /// Presenter view on the end screen.
  ///
  /// In en, this message translates to:
  /// **'Next: exit'**
  String get presenterNextExit;

  /// Presenter view notes label.
  ///
  /// In en, this message translates to:
  /// **'Speaker notes'**
  String get presenterNotes;

  /// Presenter view: empty notes.
  ///
  /// In en, this message translates to:
  /// **'No speaker notes for this slide'**
  String get presenterNoNotes;

  /// Screen reader label of the timer.
  ///
  /// In en, this message translates to:
  /// **'Elapsed {time}'**
  String presenterElapsed(String time);

  /// Screen reader label of the countdown.
  ///
  /// In en, this message translates to:
  /// **'Remaining {time}'**
  String presenterRemaining(String time);

  /// Presenter view: slide counter.
  ///
  /// In en, this message translates to:
  /// **'Slide {number} / {total}'**
  String presenterSlideOf(int number, int total);

  /// Pacing against rehearsed timings.
  ///
  /// In en, this message translates to:
  /// **'{time} ahead'**
  String presenterAhead(String time);

  /// Pacing against rehearsed timings.
  ///
  /// In en, this message translates to:
  /// **'{time} behind'**
  String presenterBehind(String time);

  /// Screen reader label of the presenter view's strip.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get presenterStrip;

  /// Editor banner while a presentation session of the user is live.
  ///
  /// In en, this message translates to:
  /// **'You’re presenting on {device}'**
  String presentBannerTitle(String device);

  /// Editor banner while a session is live (no device label).
  ///
  /// In en, this message translates to:
  /// **'You’re presenting this presentation'**
  String get presentBannerTitleNoDevice;

  /// Hides the presenting banner.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get presentBannerDismiss;

  /// Copies the selection: objects, text or table cells (SL-18).
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cmdEditCopy;

  /// Cuts the selection: objects, text or table cells (SL-18).
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cmdEditCut;

  /// Pastes the clipboard into the selection or the slide (SL-18).
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get cmdEditPaste;

  /// Disabled reason of Copy for viewers when copying is off.
  ///
  /// In en, this message translates to:
  /// **'The owner turned off copying for viewers'**
  String get reasonCopyNotAllowed;

  /// Paste in the navigator when the clipboard holds objects.
  ///
  /// In en, this message translates to:
  /// **'Paste objects on a slide'**
  String get reasonPasteObjectsOnSlide;

  /// Paste into table cells when the clipboard holds slides.
  ///
  /// In en, this message translates to:
  /// **'Paste slides in the slide navigator'**
  String get reasonPasteSlidesNotInCells;

  /// Paste with an empty (or unreadable) clipboard.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to paste'**
  String get toastClipboardEmpty;

  /// Pasting a chart copied in Wonky Sheets while charts in Slides are not available (M9).
  ///
  /// In en, this message translates to:
  /// **'Charts from Wonky Sheets can\'t be pasted into presentations'**
  String get toastPasteChartsUnavailable;

  /// Paste into table cells larger than the table.
  ///
  /// In en, this message translates to:
  /// **'Only the cells that fit in the table were pasted'**
  String get toastPasteClipped;

  /// A pasted grid larger than the table limits.
  ///
  /// In en, this message translates to:
  /// **'Only the first 50 rows and 20 columns were pasted'**
  String get toastPasteTruncated;

  /// Paste options chip: the chart stays linked to Wonky Sheets.
  ///
  /// In en, this message translates to:
  /// **'Linked to the spreadsheet'**
  String get pasteChartLinked;

  /// Screen reader label of the paste options chip.
  ///
  /// In en, this message translates to:
  /// **'Paste options'**
  String get pasteOptionsLabel;

  /// Command: next find match.
  ///
  /// In en, this message translates to:
  /// **'Find next'**
  String get cmdFindNext;

  /// Command: previous find match.
  ///
  /// In en, this message translates to:
  /// **'Find previous'**
  String get cmdFindPrevious;

  /// Command/button: replace the current match.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get cmdFindReplace;

  /// Command/button: replace every match.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get cmdFindReplaceAll;

  /// Undo step label of Replace all.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get undoReplaceAll;

  /// Closes the find bar or the find and replace panel.
  ///
  /// In en, this message translates to:
  /// **'Close find'**
  String get findClose;

  /// Placeholder of the find bar.
  ///
  /// In en, this message translates to:
  /// **'Find in presentation'**
  String get findPlaceholder;

  /// Find status without matches.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get findNoResults;

  /// Find status: current match of all.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String findOfCount(int current, int total);

  /// Find status before stepping to a match.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String findMatchesCount(int count);

  /// Title of the find and replace panel.
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get findReplaceTitle;

  /// Find field label.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findLabel;

  /// Replace field label.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get replaceLabel;

  /// Find option.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get findMatchCase;

  /// Find option.
  ///
  /// In en, this message translates to:
  /// **'Whole words'**
  String get findWholeWords;

  /// Find option.
  ///
  /// In en, this message translates to:
  /// **'Use regular expressions'**
  String get findUseRegex;

  /// Find option.
  ///
  /// In en, this message translates to:
  /// **'Include speaker notes'**
  String get findIncludeNotes;

  /// Find option.
  ///
  /// In en, this message translates to:
  /// **'Include skipped slides'**
  String get findIncludeSkipped;

  /// Find scope label.
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get findScope;

  /// Find scope option.
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get findScopeAll;

  /// Find scope option.
  ///
  /// In en, this message translates to:
  /// **'Current slide'**
  String get findScopeCurrent;

  /// Find scope option.
  ///
  /// In en, this message translates to:
  /// **'Selected slides'**
  String get findScopeSelected;

  /// Find panel button.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get findButtonPrevious;

  /// Find panel button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get findButtonNext;

  /// Find error for an invalid regular expression.
  ///
  /// In en, this message translates to:
  /// **'This regular expression is not valid'**
  String get findInvalidRegex;

  /// Toast after Replace all (03 §13).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing was replaced} =1{Replaced 1 instance of “{find}” with “{replace}”} other{Replaced {count} instances of “{find}” with “{replace}”}}'**
  String toastReplacedAll(int count, String find, String replace);

  /// Replace all skipped bodies soft-locked by another person.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match in text {name} is editing was skipped} other{{count} matches in text {name} is editing were skipped}}'**
  String toastReplaceSkipped(int count, String name);

  /// Replace refused on a body soft-locked by another person.
  ///
  /// In en, this message translates to:
  /// **'{name} is editing this text'**
  String toastFindBodyLocked(String name);

  /// Title of the command `slides.layout.add` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'New layout'**
  String get cmdLayoutAdd;

  /// Title of the command `slides.layout.duplicate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Duplicate layout'**
  String get cmdLayoutDuplicate;

  /// Title of the command `slides.layout.rename` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rename layout…'**
  String get cmdLayoutRename;

  /// Title of the command `slides.layout.move` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move layout'**
  String get cmdLayoutMove;

  /// Title of the command `slides.layout.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete layout'**
  String get cmdLayoutDelete;

  /// Title of the command `slides.layout.setBackground` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Layout background'**
  String get cmdLayoutSetBackground;

  /// Title of the command `slides.layout.setHideMasterElements` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Hide master objects'**
  String get cmdLayoutSetHideMasterElements;

  /// Title of the command `slides.layout.toggleHidden` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Hide in layout picker'**
  String get cmdLayoutToggleHidden;

  /// Title of the command `slides.master.add` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'New master'**
  String get cmdMasterAdd;

  /// Title of the command `slides.master.duplicate` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Duplicate master'**
  String get cmdMasterDuplicate;

  /// Title of the command `slides.master.rename` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Rename master…'**
  String get cmdMasterRename;

  /// Title of the command `slides.master.delete` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Delete master'**
  String get cmdMasterDelete;

  /// Title of the command `slides.master.setBackground` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Master background'**
  String get cmdMasterSetBackground;

  /// Title of the command `slides.masters.exit` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Close masters view'**
  String get cmdMastersExit;

  /// Title of the command `slides.theme.update` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Edit theme'**
  String get cmdThemeUpdate;

  /// Title of the command `slides.theme.deriveDarkColors` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Derive dark colors'**
  String get cmdThemeDeriveDarkColors;

  /// Title of the command `slides.theme.resetToBuiltIn` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reset to built-in theme'**
  String get cmdThemeResetToBuiltIn;

  /// Disabled reason: no layout to act on.
  ///
  /// In en, this message translates to:
  /// **'Select a layout'**
  String get reasonNoLayout;

  /// Disabled reason: no master to act on.
  ///
  /// In en, this message translates to:
  /// **'Select a master'**
  String get reasonNoMaster;

  /// Disabled reason of Delete layout for the last layout of a master.
  ///
  /// In en, this message translates to:
  /// **'A master needs at least one layout'**
  String get reasonLastLayout;

  /// Disabled reason of Delete master for the last master of a theme.
  ///
  /// In en, this message translates to:
  /// **'A theme needs at least one master'**
  String get reasonLastMaster;

  /// A layout used by slides can't be deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Used by 1 slide — apply another layout first} other{Used by {count} slides — apply another layout first}}'**
  String reasonLayoutUsed(int count);

  /// A master whose layouts slides use can't be deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Used by 1 slide — apply another layout first} other{Used by {count} slides — apply another layout first}}'**
  String reasonMasterUsed(int count);

  /// Disabled reason of Insert › Placeholder outside masters mode.
  ///
  /// In en, this message translates to:
  /// **'Open Edit masters and layouts first'**
  String get reasonMastersOnly;

  /// Disabled reason of Reset to built-in theme.
  ///
  /// In en, this message translates to:
  /// **'This theme isn’t based on a built-in theme'**
  String get reasonNotBuiltInTheme;

  /// Name of a new layout.
  ///
  /// In en, this message translates to:
  /// **'Layout {n}'**
  String layoutDefaultName(int n);

  /// Name of a new master.
  ///
  /// In en, this message translates to:
  /// **'Master {n}'**
  String masterDefaultName(int n);

  /// Title of the rename layout dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename layout'**
  String get layoutRenameTitle;

  /// Title of the rename master dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename master'**
  String get masterRenameTitle;

  /// Title of the delete layout dialog for a used layout.
  ///
  /// In en, this message translates to:
  /// **'Delete layout?'**
  String get layoutDeleteTitle;

  /// Body of the delete layout dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide uses “{name}”. Apply “{replacement}” to it and delete the layout?} other{{count} slides use “{name}”. Apply “{replacement}” to them and delete the layout?}}'**
  String layoutDeleteUsedBody(int count, String name, String replacement);

  /// Confirm button of the delete layout dialog.
  ///
  /// In en, this message translates to:
  /// **'Apply and delete'**
  String get layoutDeleteApplyAndDelete;

  /// Prompt text of a new placeholder of a type (shown on empty slide instances).
  ///
  /// In en, this message translates to:
  /// **'{type, select, title{Click to add title} subtitle{Click to add subtitle} body{Click to add text} picture{Click to add a picture} chart{Click to add a chart} table{Click to add a table} code{Click to add code} caption{Click to add a caption} bigNumber{100%} quote{Click to add a quote} attribution{Name, role} object{Click to add an object} other{Click to add text}}'**
  String placeholderPrompt(String type);

  /// Inspector tab in masters mode while a layout is edited.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get inspectorLayout;

  /// Inspector tab in masters mode while a master is edited.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get inspectorMaster;

  /// Inspector tab of the theme editor (masters mode).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get inspectorTheme;

  /// Title and accessibility label of the masters navigator.
  ///
  /// In en, this message translates to:
  /// **'Masters and layouts'**
  String get mastersNavigatorLabel;

  /// A master row in the masters navigator.
  ///
  /// In en, this message translates to:
  /// **'Master · {name}'**
  String mastersMasterName(String name);

  /// A layout hidden from the layout gallery.
  ///
  /// In en, this message translates to:
  /// **'Hidden in layout picker'**
  String get mastersHiddenInPicker;

  /// Context menu: move the layout up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get mastersMoveUp;

  /// Context menu: move the layout down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get mastersMoveDown;

  /// Banner of masters mode while a layout is edited.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Editing layout “{name}” of theme {theme} — no slides use it yet} =1{Editing layout “{name}” of theme {theme} — changes apply to 1 slide} other{Editing layout “{name}” of theme {theme} — changes apply to {count} slides}}'**
  String mastersBannerLayout(String name, String theme, int count);

  /// Banner of masters mode while a master is edited.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Editing master “{name}” of theme {theme} — no slides use it yet} =1{Editing master “{name}” of theme {theme} — changes apply to 1 slide} other{Editing master “{name}” of theme {theme} — changes apply to {count} slides}}'**
  String mastersBannerMaster(String name, String theme, int count);

  /// Banner of masters mode without a layout or master.
  ///
  /// In en, this message translates to:
  /// **'This presentation has no layouts to edit'**
  String get mastersBannerNone;

  /// Button leaving masters mode.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get mastersDone;

  /// Accessibility label of the canvas editing a layout.
  ///
  /// In en, this message translates to:
  /// **'Layout {name}'**
  String mastersLayoutSemantics(String name);

  /// Accessibility label of the canvas editing a master.
  ///
  /// In en, this message translates to:
  /// **'Master {name}'**
  String mastersMasterSemantics(String name);

  /// Inspector section of the edited layout or master.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get mastersSectionProperties;

  /// Inspector section listing the placeholders of the edited layout or master.
  ///
  /// In en, this message translates to:
  /// **'Placeholders'**
  String get mastersSectionPlaceholders;

  /// Placeholders section without placeholders.
  ///
  /// In en, this message translates to:
  /// **'No placeholders yet'**
  String get mastersNoPlaceholders;

  /// Placeholder of the insert placeholder select.
  ///
  /// In en, this message translates to:
  /// **'Add…'**
  String get mastersChoosePlaceholder;

  /// The theme of the edited layout or master.
  ///
  /// In en, this message translates to:
  /// **'Theme {name}'**
  String mastersOfTheme(String name);

  /// Resets a layout background.
  ///
  /// In en, this message translates to:
  /// **'Use master background'**
  String get mastersBackgroundUseMaster;

  /// Resets a master background.
  ///
  /// In en, this message translates to:
  /// **'Use theme background'**
  String get mastersBackgroundUseTheme;

  /// Theme editor section.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get themeSectionColors;

  /// Theme editor section.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get themeSectionFonts;

  /// Theme editor section.
  ///
  /// In en, this message translates to:
  /// **'Text styles'**
  String get themeSectionTextStyles;

  /// Theme editor section (default object styles).
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get themeSectionObjects;

  /// Theme editor section.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get themeSectionTables;

  /// Theme editor section.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get themeSectionCharts;

  /// Theme editor without a theme.
  ///
  /// In en, this message translates to:
  /// **'This presentation has no theme'**
  String get themeEditorNoTheme;

  /// The built-in a theme was copied from.
  ///
  /// In en, this message translates to:
  /// **'Based on {name}'**
  String themeEditorBasedOn(String name);

  /// A contrast pair of theme colors.
  ///
  /// In en, this message translates to:
  /// **'{foreground} on {background}'**
  String themeContrastPair(String foreground, String background);

  /// Tooltip of a passing contrast badge.
  ///
  /// In en, this message translates to:
  /// **'{pair}: contrast {ratio} (needs {required}:1)'**
  String themeContrastPasses(String pair, String ratio, String required);

  /// Tooltip of a failing contrast badge.
  ///
  /// In en, this message translates to:
  /// **'{pair}: contrast {ratio} is too low (needs {required}:1)'**
  String themeContrastFails(String pair, String ratio, String required);

  /// Theme editor: custom colors list.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get themeEditorCustomColors;

  /// Accessibility label of a custom color name field.
  ///
  /// In en, this message translates to:
  /// **'Custom color name'**
  String get themeEditorCustomColorName;

  /// Name of a new custom color.
  ///
  /// In en, this message translates to:
  /// **'Custom {n}'**
  String themeEditorCustomColorDefault(int n);

  /// Theme editor button.
  ///
  /// In en, this message translates to:
  /// **'Add custom color'**
  String get themeEditorAddCustomColor;

  /// Accessibility label of the remove button of a custom color.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String themeEditorRemoveCustomColor(String name);

  /// A font weight.
  ///
  /// In en, this message translates to:
  /// **'{weight, select, 300{Light} 400{Regular} 500{Medium} 600{Semibold} 700{Bold} 800{Extra bold} other{{weight}}}'**
  String themeEditorWeight(String weight);

  /// Theme font that is not bundled.
  ///
  /// In en, this message translates to:
  /// **'{family} isn’t available; {fallback} is used'**
  String themeEditorFontFallback(String family, String fallback);

  /// Theme editor: italic switch.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get themeEditorItalic;

  /// Theme editor: letter spacing (em).
  ///
  /// In en, this message translates to:
  /// **'Letter spacing'**
  String get themeEditorLetterSpacing;

  /// Theme editor: caps transform.
  ///
  /// In en, this message translates to:
  /// **'Capitals'**
  String get themeEditorCaps;

  /// Theme editor: list markers.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get themeEditorLists;

  /// Theme editor: list level row.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String themeEditorListLevel(int n);

  /// Theme editor: list bullet color.
  ///
  /// In en, this message translates to:
  /// **'Bullet color'**
  String get themeEditorBulletColor;

  /// Theme editor: list indentation.
  ///
  /// In en, this message translates to:
  /// **'Indent per level'**
  String get themeEditorIndent;

  /// Theme editor: non-solid background note.
  ///
  /// In en, this message translates to:
  /// **'The background is a gradient or an image; picking a color replaces it.'**
  String get themeEditorBackgroundNotSolid;

  /// Theme editor: dark background override switch.
  ///
  /// In en, this message translates to:
  /// **'Different in dark appearance'**
  String get themeEditorDarkBackground;

  /// Theme editor: default text box style.
  ///
  /// In en, this message translates to:
  /// **'Text boxes'**
  String get themeEditorTextBoxes;

  /// Theme editor: default shape style.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get themeEditorShapes;

  /// Theme editor: default line style.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get themeEditorLines;

  /// Theme editor: default icon style.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get themeEditorIcons;

  /// Theme editor: text color.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get themeEditorTextColor;

  /// Theme editor: default shadow blur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get themeEditorShadowBlur;

  /// Theme editor: default shadow vertical offset.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get themeEditorShadowOffset;

  /// Theme editor: the 8 shape quick styles.
  ///
  /// In en, this message translates to:
  /// **'Quick styles'**
  String get themeEditorQuickStyles;

  /// Theme editor: one quick style.
  ///
  /// In en, this message translates to:
  /// **'Style {n}'**
  String themeEditorQuickStyle(int n);

  /// Theme editor: table header fill.
  ///
  /// In en, this message translates to:
  /// **'Header fill'**
  String get themeEditorHeaderFill;

  /// Theme editor: table header text color.
  ///
  /// In en, this message translates to:
  /// **'Header text'**
  String get themeEditorHeaderText;

  /// Theme editor: table body fill.
  ///
  /// In en, this message translates to:
  /// **'Body fill'**
  String get themeEditorBodyFill;

  /// Theme editor: table band fill.
  ///
  /// In en, this message translates to:
  /// **'Banded rows'**
  String get themeEditorBandFill;

  /// Theme editor: corner radius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get themeEditorCornerRadius;

  /// Theme editor: code palette on light backgrounds.
  ///
  /// In en, this message translates to:
  /// **'Light palette'**
  String get themeEditorLightPalette;

  /// Theme editor: code palette on dark backgrounds.
  ///
  /// In en, this message translates to:
  /// **'Dark palette'**
  String get themeEditorDarkPalette;

  /// Theme editor: default code block chrome.
  ///
  /// In en, this message translates to:
  /// **'Chrome'**
  String get themeEditorWindowChrome;

  /// Code chrome: a title tab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get themeEditorChromeTab;

  /// Code chrome: a window bar.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get themeEditorChromeWindow;

  /// Code chrome: a caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get themeEditorChromeCaption;

  /// Shadow strength.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get themeEditorShadowSoft;

  /// Shadow strength.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get themeEditorShadowStrong;

  /// Theme editor: chart series color.
  ///
  /// In en, this message translates to:
  /// **'Series {n}'**
  String themeEditorSeries(int n);

  /// Theme editor: chart gridline color.
  ///
  /// In en, this message translates to:
  /// **'Gridlines'**
  String get themeEditorGridlines;

  /// Theme editor: chart axis color.
  ///
  /// In en, this message translates to:
  /// **'Axis'**
  String get themeEditorAxis;

  /// Theme editor: chart 3D lighting.
  ///
  /// In en, this message translates to:
  /// **'3D lighting'**
  String get themeEditorLighting;

  /// 3D lighting preset.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get themeEditorLightingSoft;

  /// 3D lighting preset.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get themeEditorLightingStudio;

  /// 3D lighting preset.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get themeEditorLightingFlat;

  /// Description of `slides.insert.code` (palette).
  ///
  /// In en, this message translates to:
  /// **'Insert a code block with syntax highlighting, line steps and type-in states'**
  String get cmdInsertCodeDescription;

  /// Title of the command `slides.code.setPalette`.
  ///
  /// In en, this message translates to:
  /// **'Code color theme'**
  String get cmdCodeSetPalette;

  /// Title of the command `slides.code.setText` (MCP, undo).
  ///
  /// In en, this message translates to:
  /// **'Set code'**
  String get cmdCodeSetText;

  /// Description of `slides.code.addState`.
  ///
  /// In en, this message translates to:
  /// **'Adds a copy of the selected state after it: change the code there to animate the change'**
  String get cmdCodeAddStateDescription;

  /// Title of the command `slides.code.duplicateState`.
  ///
  /// In en, this message translates to:
  /// **'Duplicate state'**
  String get cmdCodeDuplicateState;

  /// Title of the command `slides.code.deleteState`.
  ///
  /// In en, this message translates to:
  /// **'Delete state'**
  String get cmdCodeDeleteState;

  /// Title of the command `slides.code.moveState`.
  ///
  /// In en, this message translates to:
  /// **'Move state'**
  String get cmdCodeMoveState;

  /// Title of the command `slides.code.selectState` (Alt+Shift+←/→).
  ///
  /// In en, this message translates to:
  /// **'Show code state'**
  String get cmdCodeSelectState;

  /// Title of the command `slides.code.setStateLabel`.
  ///
  /// In en, this message translates to:
  /// **'Rename state'**
  String get cmdCodeSetStateLabel;

  /// Title of the command `slides.code.setStateTransition` (how the code arrives at a state).
  ///
  /// In en, this message translates to:
  /// **'State arrival'**
  String get cmdCodeSetStateTransition;

  /// Title of the command `slides.code.setCallout`.
  ///
  /// In en, this message translates to:
  /// **'Step callout'**
  String get cmdCodeSetCallout;

  /// Title of the command `slides.code.addStepFromLines`.
  ///
  /// In en, this message translates to:
  /// **'Add line step'**
  String get cmdCodeAddStepFromLines;

  /// Title of the command `slides.code.previewStep`.
  ///
  /// In en, this message translates to:
  /// **'Preview line step'**
  String get cmdCodePreviewStep;

  /// Title of the command `slides.code.preview` (plays the type-in or change into the selected state on the canvas).
  ///
  /// In en, this message translates to:
  /// **'Preview code animation'**
  String get cmdCodePreview;

  /// Title of the command `slides.code.toggleDiffGutter`.
  ///
  /// In en, this message translates to:
  /// **'Show code changes'**
  String get cmdCodeToggleDiffGutter;

  /// Title of the command `slides.code.copy`.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get cmdCodeCopy;

  /// Title of the command `slides.code.convertFromText`.
  ///
  /// In en, this message translates to:
  /// **'Convert to code block'**
  String get cmdCodeConvertFromText;

  /// Why a code command is disabled.
  ///
  /// In en, this message translates to:
  /// **'Select a code block'**
  String get reasonSelectCode;

  /// Why *Delete state* is disabled.
  ///
  /// In en, this message translates to:
  /// **'A code block keeps at least one state'**
  String get reasonLastCodeState;

  /// Why *Convert to code block* is disabled.
  ///
  /// In en, this message translates to:
  /// **'Select a text box with text'**
  String get reasonSelectTextBox;

  /// Toast after *Copy code*.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get toastCodeCopied;

  /// Undo label of code block options.
  ///
  /// In en, this message translates to:
  /// **'Edit code block'**
  String get undoEditCodeBlock;

  /// Undo label of a state's label or arrival.
  ///
  /// In en, this message translates to:
  /// **'Edit code state'**
  String get undoEditCodeState;

  /// Undo label of highlight steps.
  ///
  /// In en, this message translates to:
  /// **'Edit line steps'**
  String get undoEditLineSteps;

  /// Undo label of a step callout.
  ///
  /// In en, this message translates to:
  /// **'Edit callout'**
  String get undoEditCallout;

  /// Code section / dialog label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get codeLanguageLabel;

  /// Title of the language dialog.
  ///
  /// In en, this message translates to:
  /// **'Code language'**
  String get codeLanguageDialogTitle;

  /// Title of the language dialog when inserting.
  ///
  /// In en, this message translates to:
  /// **'Insert code block'**
  String get codeInsertDialogTitle;

  /// Code section label of the syntax palette.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get codePaletteLabel;

  /// Palette option: light or dark by the background.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get codePaletteAuto;

  /// Palette option with the palette in use.
  ///
  /// In en, this message translates to:
  /// **'Auto ({name})'**
  String codePaletteAutoNamed(String name);

  /// Palette option: the deck theme's light code palette.
  ///
  /// In en, this message translates to:
  /// **'Theme light'**
  String get codePaletteLight;

  /// Palette option: the deck theme's dark code palette.
  ///
  /// In en, this message translates to:
  /// **'Theme dark'**
  String get codePaletteDark;

  /// Code section label.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get codeFontSize;

  /// Font size option: fit the box.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get codeFontSizeAuto;

  /// Code section label of the auto-size bounds.
  ///
  /// In en, this message translates to:
  /// **'Min – max'**
  String get codeFontSizeRange;

  /// Code section label of the first line number.
  ///
  /// In en, this message translates to:
  /// **'Start at'**
  String get codeStartLine;

  /// Code section toggle.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get codeWrap;

  /// Code section toggle.
  ///
  /// In en, this message translates to:
  /// **'Ligatures'**
  String get codeLigatures;

  /// Code section label of the chrome (tab, window bar, caption).
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get codeChrome;

  /// Chrome option.
  ///
  /// In en, this message translates to:
  /// **'Theme default'**
  String get codeChromeTheme;

  /// Chrome option.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get codeChromeNone;

  /// Chrome option.
  ///
  /// In en, this message translates to:
  /// **'File tab'**
  String get codeChromeTab;

  /// Chrome option (title bar with three dots).
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get codeChromeWindow;

  /// Chrome option (label above the box).
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get codeChromeCaption;

  /// Code section label (file name).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get codeTitle;

  /// Code section toggle.
  ///
  /// In en, this message translates to:
  /// **'Language badge'**
  String get codeShowLanguage;

  /// Code section label.
  ///
  /// In en, this message translates to:
  /// **'Copy button'**
  String get codeCopyButton;

  /// Copy button option.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get codeCopyNever;

  /// Copy button option.
  ///
  /// In en, this message translates to:
  /// **'In presentations'**
  String get codeCopyPresent;

  /// Copy button option.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get codeCopyAlways;

  /// Code section header of the state strip.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get codeStatesHeader;

  /// Semantics/tooltip of a state chip.
  ///
  /// In en, this message translates to:
  /// **'State {index}'**
  String codeStateChip(int index);

  /// Semantics/tooltip of a named state chip.
  ///
  /// In en, this message translates to:
  /// **'State {index}: {label}'**
  String codeStateChipNamed(int index, String label);

  /// Info line of the first state.
  ///
  /// In en, this message translates to:
  /// **'State {index} · {lines, plural, =1{1 line} other{{lines} lines}}'**
  String codeStateInfoFirst(int index, int lines);

  /// Info line of a state (lines added, changed, removed).
  ///
  /// In en, this message translates to:
  /// **'State {index} · {lines, plural, =1{1 line} other{{lines} lines}} · +{added} ~{changed} −{removed} vs. state {previous}'**
  String codeStateInfo(
    int index,
    int lines,
    int added,
    int changed,
    int removed,
    int previous,
  );

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Move state earlier'**
  String get codeMoveStateLeft;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Move state later'**
  String get codeMoveStateRight;

  /// Tooltip of ▶ on the first state.
  ///
  /// In en, this message translates to:
  /// **'Preview the type-in'**
  String get codePreviewTypeIn;

  /// Tooltip of ▶.
  ///
  /// In en, this message translates to:
  /// **'Preview the change into this state'**
  String get codePreviewChange;

  /// Code section label of a state's name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get codeStateLabel;

  /// Placeholder of a state's name.
  ///
  /// In en, this message translates to:
  /// **'e.g. Add caching'**
  String get codeStateLabelHint;

  /// Code section toggle of the diff gutter.
  ///
  /// In en, this message translates to:
  /// **'Show changes'**
  String get codeShowChanges;

  /// Header of the first state's typing settings.
  ///
  /// In en, this message translates to:
  /// **'Type-in'**
  String get codeTypeInHeader;

  /// Header of how the code arrives at the selected state.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get codeArrivalHeader;

  /// Code section label.
  ///
  /// In en, this message translates to:
  /// **'Arrives by'**
  String get codeArrivesBy;

  /// Arrival mode.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get codeModeType;

  /// Arrival mode.
  ///
  /// In en, this message translates to:
  /// **'Morph'**
  String get codeModeMorph;

  /// Arrival mode.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get codeModeInstant;

  /// Estimated duration of a typed change.
  ///
  /// In en, this message translates to:
  /// **'≈ {seconds} s (typed)'**
  String codeDurationTyped(String seconds);

  /// Duration of a morph.
  ///
  /// In en, this message translates to:
  /// **'≈ {seconds} s (morph)'**
  String codeDurationMorph(String seconds);

  /// Duration of an instant change.
  ///
  /// In en, this message translates to:
  /// **'≈ {seconds} s (crossfade)'**
  String codeDurationInstant(String seconds);

  /// Opens all typing settings.
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get codeMore;

  /// Header of the line steps.
  ///
  /// In en, this message translates to:
  /// **'Line steps (state {index})'**
  String codeLineStepsHeader(int index);

  /// Hint when a state has no line steps.
  ///
  /// In en, this message translates to:
  /// **'No steps: every line shows normally.'**
  String get codeStepsEmpty;

  /// A step that highlights nothing ("*").
  ///
  /// In en, this message translates to:
  /// **'All lines'**
  String get codeStepAll;

  /// Semantics of a step row.
  ///
  /// In en, this message translates to:
  /// **'Step {index}: {lines}'**
  String codeStepRow(int index, String lines);

  /// Tooltip of the callout button of a step.
  ///
  /// In en, this message translates to:
  /// **'Callout'**
  String get codeEditCallout;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get codeRemoveStep;

  /// Code section label of the highlight style.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get codeHighlightStyle;

  /// Highlight style.
  ///
  /// In en, this message translates to:
  /// **'Dim others'**
  String get codeStyleDim;

  /// Highlight style.
  ///
  /// In en, this message translates to:
  /// **'Blur others'**
  String get codeStyleBlur;

  /// Highlight style.
  ///
  /// In en, this message translates to:
  /// **'Dim and blur'**
  String get codeStyleDimBlur;

  /// Highlight style.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get codeStyleBar;

  /// Highlight style.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get codeStyleBox;

  /// Highlight style.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get codeStyleNone;

  /// Code section label (keep highlighted lines in view).
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get codeFocus;

  /// Focus option.
  ///
  /// In en, this message translates to:
  /// **'Scroll'**
  String get codeFocusScroll;

  /// Focus option.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get codeFocusZoom;

  /// Focus option.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get codeFocusNone;

  /// Code section toggle (auto size fits the largest state).
  ///
  /// In en, this message translates to:
  /// **'Same size in all states'**
  String get codeFitAcrossStates;

  /// Title of the line steps dialog.
  ///
  /// In en, this message translates to:
  /// **'Line steps'**
  String get codeStepsDialogTitle;

  /// Help of the line steps dialog.
  ///
  /// In en, this message translates to:
  /// **'One step per click, separated by |: lines (5), ranges (1-3, 7-), lists (2,4); * shows all lines.'**
  String get codeStepsHint;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get codeStepsLabel;

  /// A syntax issue of a step.
  ///
  /// In en, this message translates to:
  /// **'Step {index}: use a line, a range like 3-5 or 7-, or 4:2-9'**
  String codeStepIssueSyntax(int index);

  /// A step with lines that don't exist.
  ///
  /// In en, this message translates to:
  /// **'Step {index} points past the end of the code'**
  String codeStepIssuePastEnd(int index);

  /// Issue.
  ///
  /// In en, this message translates to:
  /// **'Step {index}: a range was reversed'**
  String codeStepIssueReversed(int index);

  /// Issue.
  ///
  /// In en, this message translates to:
  /// **'Step {index}: columns start at 1'**
  String codeStepIssueColumns(int index);

  /// Title of the callout dialog.
  ///
  /// In en, this message translates to:
  /// **'Callout of step {index}'**
  String codeCalloutDialogTitle(int index);

  /// Help of the callout dialog.
  ///
  /// In en, this message translates to:
  /// **'Shown next to the step\'s lines. **Bold**, *italic* and `code` work.'**
  String get codeCalloutHint;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get codeCalloutText;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get codeCalloutSide;

  /// Callout side.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get codeSideAuto;

  /// Callout side.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get codeSideRight;

  /// Callout side.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get codeSideLeft;

  /// Callout side.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get codeSideAbove;

  /// Callout side.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get codeSideBelow;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get codeCalloutStyle;

  /// Callout style option.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get codeCalloutStyleDefault;

  /// Callout style.
  ///
  /// In en, this message translates to:
  /// **'Bubble'**
  String get codeCalloutBubble;

  /// Callout style.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get codeCalloutLabel;

  /// Callout style.
  ///
  /// In en, this message translates to:
  /// **'Pill'**
  String get codeCalloutPill;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Remove callout'**
  String get codeCalloutRemove;

  /// Title of the typing settings dialog.
  ///
  /// In en, this message translates to:
  /// **'Typing settings'**
  String get codeTypingDialogTitle;

  /// Typing speed.
  ///
  /// In en, this message translates to:
  /// **'Speed (chars/s)'**
  String get codeTypingCps;

  /// Typing jitter (0 = even, 1 = very uneven).
  ///
  /// In en, this message translates to:
  /// **'Rhythm'**
  String get codeTypingRhythm;

  /// How deletions are animated.
  ///
  /// In en, this message translates to:
  /// **'Deletions'**
  String get codeTypingDeletions;

  /// Deletion mode.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get codeDeleteAuto;

  /// Deletion mode.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get codeDeleteBackspace;

  /// Deletion mode.
  ///
  /// In en, this message translates to:
  /// **'Select and delete'**
  String get codeDeleteSelect;

  /// Automatic deletions up to this length are backspaced.
  ///
  /// In en, this message translates to:
  /// **'Backspace up to (chars)'**
  String get codeTypingBackspaceMax;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Backspace speed (chars/s)'**
  String get codeTypingDeleteCps;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Caret glide (ms)'**
  String get codeTypingCaretGlide;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get codeTypingOrder;

  /// Typing order.
  ///
  /// In en, this message translates to:
  /// **'Top to bottom'**
  String get codeOrderDocument;

  /// Typing order.
  ///
  /// In en, this message translates to:
  /// **'Bottom to top'**
  String get codeOrderReverse;

  /// Insertions with this many lines appear as a paste.
  ///
  /// In en, this message translates to:
  /// **'Paste from (lines)'**
  String get codeTypingPasteLines;

  /// Longer typing speeds up to fit.
  ///
  /// In en, this message translates to:
  /// **'Longest (ms)'**
  String get codeTypingMaxDuration;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Caret'**
  String get codeTypingCaret;

  /// Caret style.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get codeCaretBar;

  /// Caret style.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get codeCaretBlock;

  /// Caret style.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get codeCaretUnderline;

  /// Checkbox.
  ///
  /// In en, this message translates to:
  /// **'Auto-indent new lines'**
  String get codeTypingAutoIndent;

  /// Checkbox.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the caret'**
  String get codeTypingScrollFollow;

  /// Checkbox.
  ///
  /// In en, this message translates to:
  /// **'Show step 1 when typed'**
  String get codeTypingHighlightOnArrive;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Morph duration (ms)'**
  String get codeMorphDuration;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Morph stagger per line (ms)'**
  String get codeMorphStagger;

  /// Validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from {min} to {max}'**
  String codeNumberRange(String min, String max);

  /// Semantics label of the in-place code editor.
  ///
  /// In en, this message translates to:
  /// **'Code editor, {language}'**
  String codeEditorSemantics(String language);

  /// Overflow badge of a code block.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line hidden} other{{count} lines hidden}}'**
  String codeLinesHidden(int count);

  /// Tooltip of the overflow badge.
  ///
  /// In en, this message translates to:
  /// **'Enlarge the box, lower the minimum size or turn on wrap'**
  String get codeOverflowHint;

  /// Title of `slides.chart.update` with several charts selected.
  ///
  /// In en, this message translates to:
  /// **'Update charts'**
  String get cmdChartUpdateMany;

  /// Title of the command `slides.chart.relink`.
  ///
  /// In en, this message translates to:
  /// **'Change linked chart…'**
  String get cmdChartRelink;

  /// Title of the command `slides.chart.setUseDeckTheme`.
  ///
  /// In en, this message translates to:
  /// **'Match presentation theme'**
  String get cmdChartSetUseDeckTheme;

  /// Title of the command `slides.chart.updateStyle`.
  ///
  /// In en, this message translates to:
  /// **'Edit chart style'**
  String get cmdChartUpdateStyle;

  /// Title of the command `slides.chart.resetOverrides`.
  ///
  /// In en, this message translates to:
  /// **'Reset style overrides'**
  String get cmdChartResetOverrides;

  /// Title of the command `slides.chart.setCamera`.
  ///
  /// In en, this message translates to:
  /// **'Rotate 3D chart'**
  String get cmdChartSetCamera;

  /// Title of `slides.chart.addCameraStep`: a build that rotates the 3D chart to its current view.
  ///
  /// In en, this message translates to:
  /// **'Add camera step'**
  String get cmdChartAddCameraStep;

  /// Title of the command `slides.chart.viewDataTable`.
  ///
  /// In en, this message translates to:
  /// **'View data as table'**
  String get cmdChartViewDataTable;

  /// Title of the command `slides.chart.checkUpdates`.
  ///
  /// In en, this message translates to:
  /// **'Check linked charts for updates'**
  String get cmdChartCheckUpdates;

  /// Palette description of `slides.insert.chartFromSheets`.
  ///
  /// In en, this message translates to:
  /// **'Insert a chart from a Wonky Sheets spreadsheet, linked so it can be updated.'**
  String get cmdInsertChartFromSheetsDescription;

  /// Disabled reason of chart commands.
  ///
  /// In en, this message translates to:
  /// **'Select a chart'**
  String get reasonSelectChart;

  /// Disabled reason of link commands.
  ///
  /// In en, this message translates to:
  /// **'Select a chart linked to a spreadsheet'**
  String get reasonSelectLinkedChart;

  /// Disabled reason of camera commands.
  ///
  /// In en, this message translates to:
  /// **'Select a 3D chart'**
  String get reasonSelect3DChart;

  /// Disabled reason of Reset style overrides.
  ///
  /// In en, this message translates to:
  /// **'The chart has no style overrides'**
  String get reasonChartNoOverrides;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Insert chart'**
  String get undoInsertChart;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Update chart'**
  String get undoUpdateChart;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Unlink chart'**
  String get undoUnlinkChart;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Change linked chart'**
  String get undoRelinkChart;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Edit chart style'**
  String get undoEditChartStyle;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Rotate chart'**
  String get undoRotateChart;

  /// Chart error offline (08 §4.3).
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to insert or update charts from Sheets.'**
  String get chartErrOffline;

  /// Chart error no_access.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this spreadsheet anymore.'**
  String get chartErrNoAccess;

  /// Chart error spreadsheet_trashed.
  ///
  /// In en, this message translates to:
  /// **'This spreadsheet is in the trash.'**
  String get chartErrTrashed;

  /// Chart error export_disabled; also the tooltip of disabled spreadsheets.
  ///
  /// In en, this message translates to:
  /// **'The owner doesn\'t allow viewers to copy charts from this spreadsheet.'**
  String get chartErrExportDisabled;

  /// Chart error chart_not_found.
  ///
  /// In en, this message translates to:
  /// **'This chart was deleted. Pick another one.'**
  String get chartErrNotFound;

  /// Chart error chart_too_large.
  ///
  /// In en, this message translates to:
  /// **'This chart has too much data to place in a presentation. Reduce its range in Sheets.'**
  String get chartErrTooLarge;

  /// Chart error unsupported_spec.
  ///
  /// In en, this message translates to:
  /// **'This chart was made with a newer version of Wonky Sheets. Reload to insert it.'**
  String get chartErrUnsupported;

  /// Chart error quota_exceeded.
  ///
  /// In en, this message translates to:
  /// **'There isn\'t enough storage for this chart.'**
  String get chartErrQuota;

  /// Chart error limitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many chart requests. Try again in a minute.'**
  String get chartErrRateLimited;

  /// Chart error, other failures.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the chart. Try again.'**
  String get chartErrFailed;

  /// Title of the insert dialog, step 1.
  ///
  /// In en, this message translates to:
  /// **'Insert chart from Wonky Sheets'**
  String get chartInsertDialogTitle;

  /// Title of the insert dialog, step 2.
  ///
  /// In en, this message translates to:
  /// **'Insert chart from \"{title}\"'**
  String chartInsertFromTitle(String title);

  /// Title of the insert dialog when relinking.
  ///
  /// In en, this message translates to:
  /// **'Change linked chart'**
  String get chartRelinkTitle;

  /// Search field of the insert dialog.
  ///
  /// In en, this message translates to:
  /// **'Search spreadsheets'**
  String get chartSearchSpreadsheets;

  /// MCP field label of the spreadsheet list.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get chartSpreadsheetsLabel;

  /// Tab of the spreadsheet list.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get chartTabRecent;

  /// Tab of the spreadsheet list.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get chartTabMine;

  /// Tab of the spreadsheet list.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get chartTabShared;

  /// Tab of the spreadsheet list.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get chartTabStarred;

  /// Empty spreadsheet list.
  ///
  /// In en, this message translates to:
  /// **'No spreadsheets found'**
  String get chartNoSpreadsheets;

  /// Loading the list failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list. Try again.'**
  String get chartListFailed;

  /// Back to step 1.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chartBack;

  /// Search field of step 2.
  ///
  /// In en, this message translates to:
  /// **'Search charts'**
  String get chartSearchCharts;

  /// MCP field label of the chart tiles.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chartPickChart;

  /// Empty chart list.
  ///
  /// In en, this message translates to:
  /// **'This spreadsheet has no charts. Create one in Wonky Sheets.'**
  String get chartNoCharts;

  /// Button of the empty chart list.
  ///
  /// In en, this message translates to:
  /// **'Open in Sheets'**
  String get chartOpenInSheets;

  /// Checkbox of the insert dialog.
  ///
  /// In en, this message translates to:
  /// **'Link to spreadsheet'**
  String get chartLinkToSpreadsheet;

  /// Checkbox of the insert dialog.
  ///
  /// In en, this message translates to:
  /// **'Match presentation theme'**
  String get chartMatchTheme;

  /// Notice in the insert dialog (08 §6).
  ///
  /// In en, this message translates to:
  /// **'Anyone with access to this presentation will see this chart\'s data.'**
  String get chartDataNotice;

  /// Badge of a chart made with a newer Sheets.
  ///
  /// In en, this message translates to:
  /// **'Needs a newer version'**
  String get chartNewerVersion;

  /// Badge of a chart on its own chart sheet.
  ///
  /// In en, this message translates to:
  /// **'Chart sheet'**
  String get chartSheetBadge;

  /// Badge of a 3D chart.
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get chart3DBadge;

  /// Chart without a title.
  ///
  /// In en, this message translates to:
  /// **'Untitled chart'**
  String get chartUntitled;

  /// Update button of linked charts.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get chartUpdateAction;

  /// Tooltip of the Update badge; summary is " (Data changed)" etc. or empty.
  ///
  /// In en, this message translates to:
  /// **'{source} changed{summary}. Update to show the latest version.'**
  String chartUpdateTooltip(String source, String summary);

  /// Badge of a linked chart.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get chartStatusLinked;

  /// Status of a changed link.
  ///
  /// In en, this message translates to:
  /// **'Linked · Source changed'**
  String get chartStatusChanged;

  /// Status when the user cannot open the spreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Linked · No access'**
  String get chartStatusNoAccess;

  /// Status when the chart was deleted in Sheets.
  ///
  /// In en, this message translates to:
  /// **'Source chart deleted'**
  String get chartStatusChartDeleted;

  /// Status when the spreadsheet is in the trash.
  ///
  /// In en, this message translates to:
  /// **'Source in trash'**
  String get chartStatusTrashed;

  /// Status when the spreadsheet was deleted forever.
  ///
  /// In en, this message translates to:
  /// **'Source deleted'**
  String get chartStatusDeleted;

  /// Status of a newer chart spec.
  ///
  /// In en, this message translates to:
  /// **'Linked · Needs a newer version'**
  String get chartStatusUnsupported;

  /// Status shown offline (last known).
  ///
  /// In en, this message translates to:
  /// **'{status} (offline)'**
  String chartStatusOffline(String status);

  /// Status after a check.
  ///
  /// In en, this message translates to:
  /// **'Linked · Up to date ({when})'**
  String chartStatusUpToDate(String when);

  /// Toast after presenting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chart has newer data} other{{count} charts have newer data}}'**
  String chartNewerDataToast(int count);

  /// Toast after automatic updates.
  ///
  /// In en, this message translates to:
  /// **'Charts updated from {sources}'**
  String chartAutoUpdatedToast(String sources);

  /// Toast after an unlinked chart paste without data.
  ///
  /// In en, this message translates to:
  /// **'The chart\'s data couldn\'t be copied. Paste it again when you\'re online.'**
  String get chartPasteNoData;

  /// Toast after Copy chart as image.
  ///
  /// In en, this message translates to:
  /// **'Chart copied'**
  String get chartCopied;

  /// Copy chart as image failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy the chart.'**
  String get chartCopyFailed;

  /// Title of the data table dialog.
  ///
  /// In en, this message translates to:
  /// **'Data of {title}'**
  String chartDataTableTitle(String title);

  /// Data table without data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get chartNoData;

  /// Chart section of an empty chart.
  ///
  /// In en, this message translates to:
  /// **'This chart has no data yet.'**
  String get chartNoDataYet;

  /// Chart section of a static chart.
  ///
  /// In en, this message translates to:
  /// **'Not linked: shows a copy of the data.'**
  String get chartNotLinked;

  /// Checkbox Update automatically in the chart section.
  ///
  /// In en, this message translates to:
  /// **'Auto-update'**
  String get chartAutoShort;

  /// Unlink button in the chart section.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get chartUnlinkShort;

  /// Header of the style mode.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get chartStyleMode;

  /// Style mode option.
  ///
  /// In en, this message translates to:
  /// **'Match theme'**
  String get chartMatchThemeShort;

  /// Style mode option.
  ///
  /// In en, this message translates to:
  /// **'Keep source style'**
  String get chartKeepSource;

  /// Chart background row.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get chartBackground;

  /// Background option.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get chartBackgroundDefault;

  /// Background option.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get chartBackgroundTransparent;

  /// Background option.
  ///
  /// In en, this message translates to:
  /// **'Slide background color'**
  String get chartBackgroundTheme;

  /// Background option.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get chartBackgroundWhite;

  /// Header of the camera controls.
  ///
  /// In en, this message translates to:
  /// **'3D view'**
  String get chartCamera;

  /// Camera preset row.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get chartCameraPreset;

  /// Placeholder when no preset matches.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get chartCameraCustom;

  /// Camera azimuth slider.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get chartCameraRotation;

  /// Camera elevation slider.
  ///
  /// In en, this message translates to:
  /// **'Tilt'**
  String get chartCameraTilt;

  /// Camera field-of-view slider.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get chartCameraPerspective;

  /// Reset the camera to the source view.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get chartCameraReset;

  /// Hint below the camera controls.
  ///
  /// In en, this message translates to:
  /// **'Drag the selected chart to orbit it. Alt+Shift+arrows rotate 5°.'**
  String get chartCameraHint;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get chartPresetDefault;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get chartPresetFront;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Isometric'**
  String get chartPresetIsometric;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Top-down'**
  String get chartPresetTopDown;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Low angle'**
  String get chartPresetLowAngle;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get chartPresetSide;

  /// Camera preset.
  ///
  /// In en, this message translates to:
  /// **'Dramatic'**
  String get chartPresetDramatic;

  /// Pie camera preset.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get chartPresetFlat;

  /// Pie camera preset.
  ///
  /// In en, this message translates to:
  /// **'Tilted'**
  String get chartPresetTilted;

  /// Pie camera preset.
  ///
  /// In en, this message translates to:
  /// **'Steep'**
  String get chartPresetSteep;

  /// Header of the presenting options.
  ///
  /// In en, this message translates to:
  /// **'Presenting'**
  String get chartPresenting;

  /// Show values on hover when presenting.
  ///
  /// In en, this message translates to:
  /// **'Hover values'**
  String get chartHoverTooltips;

  /// Let the presenter orbit a 3D chart.
  ///
  /// In en, this message translates to:
  /// **'Drag to orbit'**
  String get chartOrbitInPresent;

  /// Header of the style editor.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get chartCustomize;

  /// Unused overrides notice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Overrides of 1 series that no longer exists} other{Overrides of {count} series that no longer exist}}'**
  String chartUnusedOverrides(int count);

  /// Remove unused overrides.
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get chartCleanUp;

  /// Warning of invalid overrides.
  ///
  /// In en, this message translates to:
  /// **'Some style overrides are invalid and were ignored.'**
  String get chartInvalidOverrides;

  /// Update all button of the Linked charts panel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Update all} other{Update all ({count})}}'**
  String chartUpdateAll(int count);

  /// While checking links.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get chartChecking;

  /// Empty Linked charts panel.
  ///
  /// In en, this message translates to:
  /// **'This presentation has no linked charts.'**
  String get chartNoLinkedCharts;

  /// Slide number of a linked chart.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}'**
  String chartOnSlide(int number);

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Chart & axis titles'**
  String get chartStyleTitles;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get chartStyleLegend;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get chartStyleSeries;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Axes'**
  String get chartStyleAxes;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Gridlines'**
  String get chartStyleGridlines;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Pie chart'**
  String get chartStylePie;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get chartStyle3D;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get chartStyleLayout;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Chart title'**
  String get chartStyleChartTitle;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get chartStyleSubtitle;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Horizontal axis title'**
  String get chartStyleHAxisTitle;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Vertical axis title'**
  String get chartStyleVAxisTitle;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get chartStyleLegendPosition;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get chartStyleColor;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Line width'**
  String get chartStyleLineWidth;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Point size'**
  String get chartStylePointSize;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Data labels'**
  String get chartStyleDataLabels;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Horizontal axis line'**
  String get chartStyleHAxisLine;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Vertical axis line'**
  String get chartStyleVAxisLine;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get chartStyleNumberFormat;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Horizontal axis gridlines'**
  String get chartStyleHGridlines;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Vertical axis gridlines'**
  String get chartStyleVGridlines;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get chartStyleMaximize;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Donut hole'**
  String get chartStyleDonutHole;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Slice labels'**
  String get chartStyleSliceLabels;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Start angle'**
  String get chartStyleStartAngle;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get chartStyleLighting;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Walls and floor'**
  String get chartStyleWalls;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get chartStyleDepth;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Gap depth'**
  String get chartStyleGapDepth;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get chartStyleShape;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Explode'**
  String get chartStyleExplode;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get chartStyleAutomatic;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartStyleNone;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Reset to the spreadsheet\'s value'**
  String get chartStyleResetField;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Changed in this presentation'**
  String get chartStyleChangedHere;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get chartStyleLegendTop;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get chartStyleLegendBottom;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get chartStyleLegendLeft;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get chartStyleLegendRight;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get chartStyleLegendInside;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get chartStyleSliceLabel;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get chartStyleSliceValue;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get chartStyleSlicePercent;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Value and percentage'**
  String get chartStyleSliceValuePercent;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get chartStyleLightingSoft;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get chartStyleLightingBright;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get chartStyleLightingFlat;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get chartStyleShapeBox;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Cylinder'**
  String get chartStyleShapeCylinder;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Cone'**
  String get chartStyleShapeCone;

  /// Chart style editor (shared ChartStyleEditor).
  ///
  /// In en, this message translates to:
  /// **'Pyramid'**
  String get chartStyleShapePyramid;

  /// Name of a build effect (06 §3), by effect id.
  ///
  /// In en, this message translates to:
  /// **'{id, select, appear{Appear} fade{Fade} rise{Rise} moveIn{Move in} scale{Scale} pop{Pop} zoom{Zoom} blur{Blur} wipe{Wipe} iris{Iris} dissolve{Dissolve} drop{Drop} flip{Flip} rotate{Rotate} typewriter{Typewriter} lineDraw{Draw line} chartGrow{Grow} codeType{Type code} shimmer{Shimmer} disappear{Disappear} fadeOut{Fade out} sink{Sink} moveOut{Move out} scaleOut{Scale out} popOut{Pop out} zoomOut{Zoom out} blurOut{Blur out} wipeOut{Wipe out} irisOut{Iris out} dissolveOut{Dissolve out} fall{Fall} flipOut{Flip out} rotateOut{Rotate out} eraseText{Erase text} lineErase{Erase line} chartShrink{Shrink} pulse{Pulse} bounce{Bounce} shake{Shake} blink{Blink} spin{Spin} grow{Grow / shrink} opacityTo{Transparency} colorChange{Color change} highlight{Highlight} chartHighlight{Highlight series} chartHighlightClear{Clear highlight} chartOrbit{Orbit} chartCamera{Rotate to angle} codeHighlight{Highlight lines} codeState{Next code state} path{Motion path} moveTo{Transform} other{}}'**
  String animateEffectName(String id);

  /// One-line description of a build effect (tile tooltip, accessible description).
  ///
  /// In en, this message translates to:
  /// **'{id, select, appear{The object appears at once.} fade{The object fades in.} rise{The object moves up a short distance while fading in.} moveIn{The object moves in from a side or from off the slide.} scale{The object grows to its size while fading in.} pop{The object pops in with a little bounce.} zoom{The object comes toward its place from in front of the viewer.} blur{The object comes into focus.} wipe{A soft edge sweeps across and reveals the object.} iris{A growing circle, square or diamond reveals the object.} dissolve{The object appears through a grain of random cells.} drop{The object falls into place and bounces.} flip{The object flips into view like a card.} rotate{The object turns into place.} typewriter{The text is typed character by character.} lineDraw{The outline draws itself, then the fill fades in.} chartGrow{Bars grow, lines draw on and wedges sweep in.} codeType{The code is typed into the block.} shimmer{Particles condense into the text.} disappear{The object disappears at once.} fadeOut{The object fades out.} sink{The object moves down a short distance while fading out.} moveOut{The object moves out to a side or off the slide.} scaleOut{The object shrinks while fading out.} popOut{The object grows a little, then collapses.} zoomOut{The object moves toward the viewer and fades away.} blurOut{The object goes out of focus.} wipeOut{A soft edge sweeps across and hides the object.} irisOut{A shrinking circle, square or diamond hides the object.} dissolveOut{The object disappears into a grain of random cells.} fall{The object falls off the slide.} flipOut{The object flips away like a card.} rotateOut{The object turns away.} eraseText{The text is erased from the end, like backspacing.} lineErase{The outline erases itself.} chartShrink{Bars shrink, lines erase and wedges sweep out.} pulse{The object briefly grows and returns.} bounce{The object jumps up and lands.} shake{The object shakes from side to side.} blink{The object blinks.} spin{The object spins and keeps its new angle.} grow{The object changes its size and keeps it.} opacityTo{The object becomes more or less transparent.} colorChange{The fill, border or text changes color.} highlight{A marker sweeps behind the text.} chartHighlight{One series stands out; the rest dims.} chartHighlightClear{Every series is shown normally again.} chartOrbit{The 3D chart turns around.} chartCamera{The 3D chart turns to a new view.} codeHighlight{The next highlight step of the code is shown.} codeState{The code changes to its next state.} path{The object moves along a path.} moveTo{The object moves, resizes, turns or fades to an end state.} other{An animation from a newer version.}}'**
  String animateEffectDescription(String id);

  /// Name of a slide transition (06 §7.2), by id.
  ///
  /// In en, this message translates to:
  /// **'{id, select, none{None} fade{Fade} dissolve{Dissolve} push{Push} slide{Slide in} cover{Cover} uncover{Uncover} wipe{Wipe} iris{Iris} zoom{Zoom} flip{Flip} cube{Cube} doorway{Doorway} swap{Swap} revolve{Revolve} magicMove{Magic Move} other{Transition}}'**
  String animateTransitionName(String id);

  /// One-line description of a slide transition.
  ///
  /// In en, this message translates to:
  /// **'{id, select, none{The new slide replaces the old one at once.} fade{The new slide fades in over the old one, or both fade through a color.} dissolve{The new slide appears through a grain of random cells.} push{The new slide pushes the old one off the screen.} slide{The new slide slides in over the old one.} cover{The new slide slides over the old one, which dims.} uncover{The old slide slides away and reveals the new one.} wipe{A soft edge sweeps across and reveals the new slide.} iris{A growing circle, square or diamond reveals the new slide.} zoom{The new slide grows in, or the old one shrinks away.} flip{The slide flips over like a card; the new slide is on its back.} cube{Both slides are faces of a cube that turns a quarter turn.} doorway{The old slide opens like double doors; the new one comes forward.} swap{The slides swap places, front and back, on an arc.} revolve{The old slide swings away on its edge like a door.} magicMove{Objects on both slides morph into each other; the rest fades.} other{}}'**
  String animateTransitionDescription(String id);

  /// Label of an effect or transition parameter.
  ///
  /// In en, this message translates to:
  /// **'{key, select, distance{Distance} fade{Fade} direction{Direction} from{From} to{To} origin{Origin} bounce{Bounce} softness{Softness} shape{Shape} cell{Grain} height{Height} bounces{Bounces} axis{Axis} perspective{Perspective} angle{Angle} scale{Scale} cps{Characters/s} caret{Caret} jitter{Jitter} fillDelay{Fill delay} count{Times} amplitude{Amplitude} opacity{Opacity} property{Property} color{Color} style{Style} target{Series} dimOthers{Dim others} azimuth{Azimuth} elevation{Elevation} step{Step} state{State} mode{Mode} path{Path} preset{Preset} orientToPath{Orient to path} relativeEnd{Relative end} anticipation{Anticipation} rotation{Rotation} through{Through color} persist{Keep end state} other{Option}}'**
  String animateParamName(String key);

  /// Label of a parameter value (directions, anchors, shapes, modes).
  ///
  /// In en, this message translates to:
  /// **'{value, select, left{Left} right{Right} top{Top} bottom{Bottom} up{Up} down{Down} topLeft{Top left} topRight{Top right} bottomLeft{Bottom left} bottomRight{Bottom right} center{Center} circle{Circle} rect{Square} diamond{Diamond} x{Horizontal} y{Vertical} forward{Forward} backward{Backward} in{In} out{Out} baseline{Baseline} fill{Fill} stroke{Border} text{Text} marker{Marker} underline{Underline} box{Box} type{Type} morph{Morph} instant{Instant} line{Line} arc{Arc} curve{Curve} zigzag{Zigzag} custom{Custom} object{Object} word{Word} character{Character} shortest{Shortest} literal{As set} other{—}}'**
  String animateChoiceName(String value);

  /// Why an effect tile is disabled for the selected object.
  ///
  /// In en, this message translates to:
  /// **'{target, select, text{{effect} works on text only} stroke{{effect} works on shapes, lines and icons} colorable{{effect} works on shapes, text, lines and icons} chart{{effect} works on charts only} chart3d{{effect} works on 3D charts only} code{{effect} works on code blocks only} other{{effect} doesn\'t work on this object}}'**
  String animateTargetReason(String effect, String target);

  /// Build trigger (06 §4.1).
  ///
  /// In en, this message translates to:
  /// **'{trigger, select, onClick{On click} withPrevious{With previous} afterPrevious{After previous} other{On click of an object}}'**
  String animateTriggerName(String trigger);

  /// Delivery of a build (06 §2.3).
  ///
  /// In en, this message translates to:
  /// **'{by, select, all{All at once} paragraph{By paragraph} paragraphGroup{By paragraph group} line{By line} word{By word} character{By character} series{By series} category{By category} point{By point} chartElement{By chart element} other{All at once}}'**
  String animateDeliveryName(String by);

  /// Order of a build's parts.
  ///
  /// In en, this message translates to:
  /// **'{order, select, forward{Forward} backward{Backward} center{From the center} edges{From the edges} random{Random} other{Forward}}'**
  String animateOrderName(String order);

  /// What happens to earlier parts after the next part builds.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, none{Keep} dim{Dim} hide{Hide} other{Keep}}'**
  String animateAfterBuildName(String mode);

  /// Easing preset (06 §4.3).
  ///
  /// In en, this message translates to:
  /// **'{preset, select, smooth{Smooth} snappy{Snappy} bouncy{Bouncy} gentle{Gentle} linear{Linear} easeIn{Ease in} easeOut{Ease out} custom{Custom} other{Custom}}'**
  String animateEasingName(String preset);

  /// Heading of a group of effect or transition tiles.
  ///
  /// In en, this message translates to:
  /// **'{group, select, basic{Basic} exciting{Exciting} emphasis{Emphasis} text{Text} shape{Shape} motion{Motion} chart{Chart} code{Code} threeD{3D} magic{Magic Move} other{More}}'**
  String animateGroupName(String group);

  /// Build tab sub-tab (In / Action / Out).
  ///
  /// In en, this message translates to:
  /// **'{tab, select, buildIn{In} action{Action} buildOut{Out} other{In}}'**
  String animateKindTab(String tab);

  /// Magic Move: when unmatched objects fade.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, together{Fade with the move} before{Fade out first} after{Fade in after} other{Fade with the move}}'**
  String animateUnmatchedName(String mode);

  /// Order tab ⚙ menu item.
  ///
  /// In en, this message translates to:
  /// **'{option, select, autoPreview{Auto-preview changes} includeTransition{Include transition in preview} fullMotion{Preview full motion} other{Option}}'**
  String animatePreviewOption(String option);

  /// Warning of a build in the Order list and Build tab (06 §2.4).
  ///
  /// In en, this message translates to:
  /// **'{code, select, elementMissing{The object no longer exists.} alreadyVisible{The object is already visible: this build is skipped.} alreadyHidden{The object is already hidden: this build is skipped.} hiddenTarget{The object is hidden at this point: this build is skipped.} unsupportedEffect{Effect not supported by this version: plays as a fade.} wrongElementKind{This effect doesn\'t work on this object: it is skipped.} unsupportedTrigger{This trigger isn\'t supported yet: the build is skipped.} invalidOptions{Some options are invalid and use their defaults.} invalidEasing{The easing is invalid and plays as ease out.} deliveryFallback{This object can\'t be built in these parts: it builds as a whole.} codeStepMissing{The code has no such highlight step.} codeStateMissing{The code has no such state.} flashLimit{Blinking is slowed to at most 3 flashes per second.} other{This build plays differently than set.}}'**
  String animateWarning(String code);

  /// Build tab: adds a second build of the same kind.
  ///
  /// In en, this message translates to:
  /// **'Add another build'**
  String get animateAddAnother;

  /// Transition tab: how the slide advances.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get animateAdvance;

  /// Transition tab: delay before advancing automatically.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get animateAdvanceAfter;

  /// Transition tab: advance automatically.
  ///
  /// In en, this message translates to:
  /// **'Automatically'**
  String get animateAdvanceAuto;

  /// Transition tab: advance on click.
  ///
  /// In en, this message translates to:
  /// **'On click'**
  String get animateAdvanceClick;

  /// Build tab: what happens to earlier parts.
  ///
  /// In en, this message translates to:
  /// **'After build'**
  String get animateAfterBuild;

  /// Build tab with nothing selected: list heading.
  ///
  /// In en, this message translates to:
  /// **'Animated objects'**
  String get animateAnimatedObjects;

  /// Transition tab: auto-advance also plays click builds.
  ///
  /// In en, this message translates to:
  /// **'Play builds automatically'**
  String get animateAutoBuilds;

  /// Build tab: repeat option.
  ///
  /// In en, this message translates to:
  /// **'Play back and forth'**
  String get animateAutoReverse;

  /// Transition tab: delay before each automatic build.
  ///
  /// In en, this message translates to:
  /// **'Between builds'**
  String get animateBuildDelay;

  /// Build tab: timing field.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get animateDelay;

  /// Build tab: delivery heading.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get animateDelivery;

  /// Build tab: delivery select label.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get animateDeliveryLabel;

  /// Build tab: dim opacity.
  ///
  /// In en, this message translates to:
  /// **'Dim to'**
  String get animateDimTo;

  /// Timing field.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get animateDuration;

  /// Duration of effects that compute their own length.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get animateDurationAutomatic;

  /// Timing field.
  ///
  /// In en, this message translates to:
  /// **'Easing'**
  String get animateEasing;

  /// An effect id from a newer version.
  ///
  /// In en, this message translates to:
  /// **'Effect not supported by this version'**
  String get animateEffectUnsupported;

  /// Transform effect: the end frame.
  ///
  /// In en, this message translates to:
  /// **'End state'**
  String get animateEndState;

  /// Transform effect: end height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get animateHeight;

  /// Magic Move: hides the match outlines on the canvas.
  ///
  /// In en, this message translates to:
  /// **'Hide matches'**
  String get animateHideMatches;

  /// Magic Move on the first slide.
  ///
  /// In en, this message translates to:
  /// **'The first slide has nothing to morph from.'**
  String get animateMagicMoveFirstSlide;

  /// Magic Move without matches.
  ///
  /// In en, this message translates to:
  /// **'No objects match the previous slide: plays as a crossfade.'**
  String get animateMagicMoveNoMatches;

  /// Magic Move option.
  ///
  /// In en, this message translates to:
  /// **'Match identical content'**
  String get animateMatchByContent;

  /// Magic Move option.
  ///
  /// In en, this message translates to:
  /// **'Match text by'**
  String get animateMatchTextBy;

  /// Order list: a build whose object is gone.
  ///
  /// In en, this message translates to:
  /// **'Deleted object'**
  String get animateMissingObject;

  /// Order list context menu.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get animateMoveDown;

  /// Order list context menu.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get animateMoveUp;

  /// Order list: drop indicator on a step header.
  ///
  /// In en, this message translates to:
  /// **'New click'**
  String get animateNewClick;

  /// Animate tab without a slide (or in masters mode).
  ///
  /// In en, this message translates to:
  /// **'Animations apply to slides.'**
  String get animateNoSlide;

  /// Distance parameter: off slide.
  ///
  /// In en, this message translates to:
  /// **'From off the slide'**
  String get animateOffSlide;

  /// Accessible label of the Order list.
  ///
  /// In en, this message translates to:
  /// **'Build order'**
  String get animateOrderListLabel;

  /// Order tab empty state.
  ///
  /// In en, this message translates to:
  /// **'No animations on this slide yet. Select an object and pick an effect on the Build tab.'**
  String get animateOrderNone;

  /// Build tab: part order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get animatePartOrder;

  /// Build tab: how parts after the first start.
  ///
  /// In en, this message translates to:
  /// **'Each part'**
  String get animatePartStart;

  /// Build tab: first part to build.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get animatePartsFrom;

  /// Build tab: last part to build.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get animatePartsTo;

  /// Motion path preset.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get animatePathPreset;

  /// Order tab footer.
  ///
  /// In en, this message translates to:
  /// **'Play from selected'**
  String get animatePlayFromSelected;

  /// Plays the animation on the canvas.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get animatePreview;

  /// Order list context menu.
  ///
  /// In en, this message translates to:
  /// **'Preview from here'**
  String get animatePreviewFromHere;

  /// Reduce motion banner: preview without reduced motion.
  ///
  /// In en, this message translates to:
  /// **'Preview full motion'**
  String get animatePreviewFullMotion;

  /// Accessible label of the Order tab ⚙ menu.
  ///
  /// In en, this message translates to:
  /// **'Preview options'**
  String get animatePreviewOptions;

  /// Floating bar while a preview plays.
  ///
  /// In en, this message translates to:
  /// **'Previewing animations'**
  String get animatePreviewPlaying;

  /// Reduce motion banner: back to reduced previews.
  ///
  /// In en, this message translates to:
  /// **'Preview reduced motion'**
  String get animatePreviewReduced;

  /// Stops the preview (Esc).
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get animatePreviewStop;

  /// Animate tab banner (06 §13).
  ///
  /// In en, this message translates to:
  /// **'Reduce motion is on — animations play as fades.'**
  String get animateReducedMotionOn;

  /// Opens the reduce motion setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get animateReducedMotionSettings;

  /// Transition tab: removes the transition (cut).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get animateRemoveTransition;

  /// Build tab heading.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get animateRepeat;

  /// Build tab: repeat count.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get animateRepeatCount;

  /// Build tab: a persistent emphasis returns at its end.
  ///
  /// In en, this message translates to:
  /// **'Return to the start'**
  String get animateReturnToStart;

  /// Transition tab option.
  ///
  /// In en, this message translates to:
  /// **'Play backwards when going back'**
  String get animateReverseOnBack;

  /// Magic Move option.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get animateRotation;

  /// Build tab search field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search effects'**
  String get animateSearchEffects;

  /// Build tab empty state.
  ///
  /// In en, this message translates to:
  /// **'Select an object to animate it.'**
  String get animateSelectObject;

  /// Order list context menu.
  ///
  /// In en, this message translates to:
  /// **'Select object'**
  String get animateSelectObjectItem;

  /// Order list context menu: submenu of triggers.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get animateSetTrigger;

  /// Magic Move: shows the match outlines on the canvas.
  ///
  /// In en, this message translates to:
  /// **'Show matches'**
  String get animateShowMatches;

  /// Order list: expands a build's parts.
  ///
  /// In en, this message translates to:
  /// **'Show parts'**
  String get animateShowParts;

  /// Magic Move option: delay between pairs.
  ///
  /// In en, this message translates to:
  /// **'Stagger'**
  String get animateStagger;

  /// Build tab: gap between part starts.
  ///
  /// In en, this message translates to:
  /// **'Stagger'**
  String get animateStaggerParts;

  /// Build tab: trigger.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get animateStart;

  /// Order list: step 0 header.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get animateStepAutomatic;

  /// Build tab heading.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get animateTiming;

  /// Transition tab: the slide has no own transition.
  ///
  /// In en, this message translates to:
  /// **'Uses the presentation\'s default transition.'**
  String get animateTransitionInherited;

  /// Magic Move option: unmatched objects.
  ///
  /// In en, this message translates to:
  /// **'Unmatched'**
  String get animateUnmatched;

  /// Build tab: repeat option.
  ///
  /// In en, this message translates to:
  /// **'Until the next click'**
  String get animateUntilNextClick;

  /// Transform effect: end width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get animateWidth;

  /// Title of the command `slides.animate.buildAllSteps`.
  ///
  /// In en, this message translates to:
  /// **'Build all steps'**
  String get cmdAnimateBuildAllSteps;

  /// Title of the command `slides.animate.moveBuilds`.
  ///
  /// In en, this message translates to:
  /// **'Reorder animations'**
  String get cmdAnimateMoveBuilds;

  /// Title of the command `slides.animate.selectBuilds`.
  ///
  /// In en, this message translates to:
  /// **'Select animations'**
  String get cmdAnimateSelectBuilds;

  /// Title of the command `slides.animate.setMotionPath`.
  ///
  /// In en, this message translates to:
  /// **'Edit motion path'**
  String get cmdAnimateSetMotionPath;

  /// Title of the command `slides.animate.setTransformTarget`.
  ///
  /// In en, this message translates to:
  /// **'Set end state'**
  String get cmdAnimateSetTransformTarget;

  /// Title of the command `slides.animate.setTrigger`.
  ///
  /// In en, this message translates to:
  /// **'Set animation start'**
  String get cmdAnimateSetTrigger;

  /// Title of the command `slides.animate.stopPreview`.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get cmdAnimateStopPreview;

  /// Title of the command `slides.animate.togglePreviewOption`.
  ///
  /// In en, this message translates to:
  /// **'Preview option'**
  String get cmdAnimateTogglePreviewOption;

  /// Title of the command `slides.animate.updateBuild`.
  ///
  /// In en, this message translates to:
  /// **'Edit animation'**
  String get cmdAnimateUpdateBuild;

  /// Title of the command `slides.element.setMatchKey`.
  ///
  /// In en, this message translates to:
  /// **'Set Magic Move ID'**
  String get cmdElementSetMatchKey;

  /// Title of the command `slides.transition.applyToAll`.
  ///
  /// In en, this message translates to:
  /// **'Apply transition to all slides'**
  String get cmdTransitionApplyToAll;

  /// Title of the command `slides.transition.preview`.
  ///
  /// In en, this message translates to:
  /// **'Preview transition'**
  String get cmdTransitionPreview;

  /// Title of the command `slides.transition.remove`.
  ///
  /// In en, this message translates to:
  /// **'Remove transition'**
  String get cmdTransitionRemove;

  /// Title of the command `slides.transition.set`.
  ///
  /// In en, this message translates to:
  /// **'Set transition'**
  String get cmdTransitionSet;

  /// Title of the command `slides.transition.setAdvance`.
  ///
  /// In en, this message translates to:
  /// **'Set slide advance'**
  String get cmdTransitionSetAdvance;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'This slide has no animations'**
  String get reasonNoBuilds;

  /// Disabled reason of Paste animation.
  ///
  /// In en, this message translates to:
  /// **'Copy an animation first'**
  String get reasonNoBuildsCopied;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'No preview is playing'**
  String get reasonNotPreviewing;

  /// Disabled reason of Copy animation.
  ///
  /// In en, this message translates to:
  /// **'Select one animated object'**
  String get reasonObjectNoBuilds;

  /// Disabled reason.
  ///
  /// In en, this message translates to:
  /// **'Select an animation'**
  String get reasonSelectBuild;

  /// Disabled reason of Build all steps.
  ///
  /// In en, this message translates to:
  /// **'Select a code block with steps or a chart'**
  String get reasonSelectCodeOrChart;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Add Magic Move slide'**
  String get undoAddMagicMoveSlide;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Remove animation'**
  String get undoRemoveAnimation;

  /// Build order badge tooltip.
  ///
  /// In en, this message translates to:
  /// **'{name}: step {steps}'**
  String animateBadgeTooltip(String name, String steps);

  /// Several selected builds.
  ///
  /// In en, this message translates to:
  /// **'{count} animations'**
  String animateBuildsSelected(int count);

  /// Several selected objects.
  ///
  /// In en, this message translates to:
  /// **'{count} objects'**
  String animateObjectsSelected(int count);

  /// Magic Move match count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 object matches the previous slide} other{{count} objects match the previous slide}}'**
  String animateMagicMoveMatches(int count);

  /// Magic Move match badge tooltip.
  ///
  /// In en, this message translates to:
  /// **'Matches “{name}” on slide {number}'**
  String animateMatchTooltip(String name, int number);

  /// Order tab summary.
  ///
  /// In en, this message translates to:
  /// **'{clicks, plural, =0{No clicks} =1{1 click} other{{clicks} clicks}} · {seconds} s'**
  String animateOrderSummary(int clicks, String seconds);

  /// Order list: a part of a build.
  ///
  /// In en, this message translates to:
  /// **'Part {index}: {text}'**
  String animatePartLabel(int index, String text);

  /// Order list: number of parts.
  ///
  /// In en, this message translates to:
  /// **'{count} parts'**
  String animatePartsCount(int count);

  /// Settle time of a spring easing.
  ///
  /// In en, this message translates to:
  /// **'≈ {seconds} s'**
  String animateSettles(String seconds);

  /// Order list: step header.
  ///
  /// In en, this message translates to:
  /// **'Click {index}'**
  String animateStepClick(int index);

  /// Transition tab header.
  ///
  /// In en, this message translates to:
  /// **'Transition into slide {number}'**
  String animateTransitionForSlide(int number);

  /// Transition tab header with several slides selected.
  ///
  /// In en, this message translates to:
  /// **'Transition into {count} slides'**
  String animateTransitionForSlides(int count);

  /// Inspector › Arrange: the Magic Move ID field (06 §8.2).
  ///
  /// In en, this message translates to:
  /// **'Magic Move ID'**
  String get arrangeLabelMatchKey;

  /// Title of the command `slides.outline.setTitle` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Edit slide title'**
  String get cmdOutlineSetTitle;

  /// Title of the command `slides.outline.setBody` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Edit slide text'**
  String get cmdOutlineSetBody;

  /// Title of the command `slides.outline.newSlideAfter` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'New slide after this one'**
  String get cmdOutlineNewSlideAfter;

  /// Title of the command `slides.outline.newLine` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'New bullet'**
  String get cmdOutlineNewLine;

  /// Title of the command `slides.outline.focusBody` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Go to the slide’s bullets'**
  String get cmdOutlineFocusBody;

  /// Title of the command `slides.outline.indent` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Indent (demote)'**
  String get cmdOutlineIndent;

  /// Title of the command `slides.outline.outdent` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Outdent (promote)'**
  String get cmdOutlineOutdent;

  /// Title of the command `slides.outline.moveUp` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get cmdOutlineMoveUp;

  /// Title of the command `slides.outline.moveDown` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get cmdOutlineMoveDown;

  /// Title of the command `slides.outline.joinLine` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Join with the line above'**
  String get cmdOutlineJoinLine;

  /// Title of the command `slides.outline.copyMarkdown` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Copy outline as Markdown'**
  String get cmdOutlineCopyMarkdown;

  /// Title of the command `slides.arrange.setZ` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get cmdArrangeSetZ;

  /// Title of the command `slides.a11y.setReadingOrder` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reading order'**
  String get cmdA11ySetReadingOrder;

  /// Title of the command `slides.a11y.resetReadingOrder` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Reset to automatic'**
  String get cmdA11yResetReadingOrder;

  /// Title of the command `slides.a11y.goTo` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Go to issue'**
  String get cmdA11yGoTo;

  /// Title of the command `slides.a11y.fix` (menus, palette, tooltips, undo).
  ///
  /// In en, this message translates to:
  /// **'Fix accessibility issue'**
  String get cmdA11yFix;

  /// Disabled reason of outline commands.
  ///
  /// In en, this message translates to:
  /// **'Place the cursor in an outline line'**
  String get reasonOutlineLine;

  /// Disabled reason: the slide can't get a title.
  ///
  /// In en, this message translates to:
  /// **'This slide’s layout has no title'**
  String get reasonOutlineNoTitle;

  /// Disabled reason: the slide has no body placeholder.
  ///
  /// In en, this message translates to:
  /// **'This slide has no text placeholder'**
  String get reasonOutlineNoBody;

  /// Disabled reason of Reset to automatic.
  ///
  /// In en, this message translates to:
  /// **'The reading order is already automatic'**
  String get reasonReadingOrderAutomatic;

  /// Disabled reason of the accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'This issue has no automatic fix'**
  String get reasonA11yNoFix;

  /// Outline view: keyboard hint in the top bar.
  ///
  /// In en, this message translates to:
  /// **'Enter: new slide or bullet · Tab: indent · Shift+Tab: outdent'**
  String get outlineHint;

  /// Outline view: hint for viewers.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get outlineReadOnlyHint;

  /// Outline view: semantics label of a slide number.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}'**
  String outlineSlideNumber(int number);

  /// Outline view: semantics label of a title line.
  ///
  /// In en, this message translates to:
  /// **'Title of slide {number}'**
  String outlineTitleLabel(int number);

  /// Outline view: semantics label of a bullet line.
  ///
  /// In en, this message translates to:
  /// **'Slide {slide}, bullet {bullet}, level {level}'**
  String outlineBulletLabel(int slide, int bullet, int level);

  /// Outline view: summary of a slide's other objects ("+ image, 2 × shape").
  ///
  /// In en, this message translates to:
  /// **'+ {objects}'**
  String outlineOthers(String objects);

  /// Outline view: tooltip of a collaborator's caret bar.
  ///
  /// In en, this message translates to:
  /// **'{name} is editing'**
  String outlineEditing(String name);

  /// Toast after Copy outline as Markdown.
  ///
  /// In en, this message translates to:
  /// **'Outline copied as Markdown'**
  String get outlineCopied;

  /// Undo label of typing in the outline view.
  ///
  /// In en, this message translates to:
  /// **'Edit outline'**
  String get outlineTypingUndo;

  /// Title of the Layers side panel.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get layersPanelTitle;

  /// Layers panel tab.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get layersTabLayers;

  /// Layers panel tab.
  ///
  /// In en, this message translates to:
  /// **'Reading order'**
  String get layersTabReadingOrder;

  /// Layers panel: empty slide.
  ///
  /// In en, this message translates to:
  /// **'No objects on this slide'**
  String get layersEmpty;

  /// Layers panel: semantics state of a hidden object.
  ///
  /// In en, this message translates to:
  /// **'hidden'**
  String get layersHidden;

  /// Layers panel: semantics state of a locked object.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get layersLocked;

  /// Layers panel: placeholder of the rename field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get layersRenameHint;

  /// Layers panel: drag feedback of several objects.
  ///
  /// In en, this message translates to:
  /// **'{count} objects'**
  String layersDragMany(int count);

  /// Layers panel: the section of layout and master objects.
  ///
  /// In en, this message translates to:
  /// **'From layout ({count})'**
  String layersFromLayout(int count);

  /// Layers panel: link to masters mode.
  ///
  /// In en, this message translates to:
  /// **'Edit layout'**
  String get layersEditLayout;

  /// Layers panel › Reading order: explanation.
  ///
  /// In en, this message translates to:
  /// **'Automatic: title first, then top to bottom, left to right.'**
  String get layersOrderAutomatic;

  /// Layers panel › Reading order: explanation.
  ///
  /// In en, this message translates to:
  /// **'Custom order. Screen readers and Tab follow this list.'**
  String get layersOrderCustom;

  /// Layers panel › Reading order: move up button.
  ///
  /// In en, this message translates to:
  /// **'Read earlier'**
  String get layersOrderEarlier;

  /// Layers panel › Reading order: move down button.
  ///
  /// In en, this message translates to:
  /// **'Read later'**
  String get layersOrderLater;

  /// Title of the Accessibility side panel.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get a11yPanelTitle;

  /// Description of the accessibility check command.
  ///
  /// In en, this message translates to:
  /// **'Checks alt text, contrast, titles, text size, reading order and tables'**
  String get a11yCheckDescription;

  /// Accessibility panel: refresh button.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get a11yCheckAgain;

  /// Accessibility panel: summary.
  ///
  /// In en, this message translates to:
  /// **'{errors, plural, =1{1 error} other{{errors} errors}} · {warnings, plural, =1{1 warning} other{{warnings} warnings}} · {info, plural, =1{1 tip} other{{info} tips}}'**
  String a11ySummary(int errors, int warnings, int info);

  /// Accessibility panel: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No accessibility issues found'**
  String get a11yNoIssues;

  /// Accessibility panel: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Alt text, contrast, titles, text size, reading order and tables look good.'**
  String get a11yNoIssuesBody;

  /// Accessibility panel: heading of a slide's issues ("Slide 4 · Our mission").
  ///
  /// In en, this message translates to:
  /// **'Slide {label}'**
  String a11ySlideHeading(String label);

  /// Accessibility issue severity.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get a11ySeverityError;

  /// Accessibility issue severity.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get a11ySeverityWarning;

  /// Accessibility issue severity.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get a11ySeverityInfo;

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Missing alt text'**
  String get a11yMissingAltText;

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Low text contrast ({ratio}:1, needs {required}:1)'**
  String a11yLowContrast(String ratio, String required);

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Text over an image: check that it is readable'**
  String get a11yContrastOverImage;

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Slide has no title'**
  String get a11yMissingTitle;

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Another slide has the same title “{title}”'**
  String a11yDuplicateTitle(String title);

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Text smaller than {min} ({size})'**
  String a11ySmallText(int size, int min);

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'The custom reading order differs from the layout'**
  String get a11yReadingOrder;

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Table has no header row'**
  String get a11yTableHeader;

  /// Accessibility issue.
  ///
  /// In en, this message translates to:
  /// **'Empty placeholder'**
  String get a11yEmptyPlaceholder;

  /// Accessibility panel: button showing the issue.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get a11yGoTo;

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Add alt text…'**
  String get a11yFixAltText;

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Mark decorative'**
  String get a11yFixDecorative;

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Use a contrasting color'**
  String get a11yFixContrast;

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Enlarge to {size}'**
  String a11yFixTextSize(int size);

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Reset to automatic'**
  String get a11yFixReadingOrder;

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Turn on header row'**
  String get a11yFixTableHeader;

  /// Accessibility quick fix.
  ///
  /// In en, this message translates to:
  /// **'Remove placeholder'**
  String get a11yFixRemovePlaceholder;

  /// Accessibility panel: opens Layers › Reading order.
  ///
  /// In en, this message translates to:
  /// **'Edit reading order'**
  String get a11yEditReadingOrder;

  /// Toast when a collaborator changes the previewed slide (06 §11).
  ///
  /// In en, this message translates to:
  /// **'The animations changed — Preview again'**
  String get animatePreviewChanged;

  /// Button of the Linked charts panel: check the links now.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get chartCheckNow;

  /// Title of the command `slides.comments.next` (09 §3.4).
  ///
  /// In en, this message translates to:
  /// **'Next comment'**
  String get cmdCommentsNext;

  /// Title of the command `slides.comments.previous` (09 §3.4).
  ///
  /// In en, this message translates to:
  /// **'Previous comment'**
  String get cmdCommentsPrevious;

  /// Title of the command `slides.comments.openPanel` (09 §3.5).
  ///
  /// In en, this message translates to:
  /// **'Open comments'**
  String get cmdCommentsOpenPanel;

  /// Comments panel scope: threads of the current slide.
  ///
  /// In en, this message translates to:
  /// **'This slide'**
  String get commentsScopeSlide;

  /// Comments panel scope: every thread.
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get commentsScopeAll;

  /// Comments panel header of threads whose slide or object was deleted.
  ///
  /// In en, this message translates to:
  /// **'Orphaned'**
  String get commentsOrphanedGroup;

  /// Comments panel header of a slide's threads.
  ///
  /// In en, this message translates to:
  /// **'{number} · {title}'**
  String commentsSlideHeader(int number, String title);

  /// Quoted text of a comment on a slide (stored with the thread).
  ///
  /// In en, this message translates to:
  /// **'Slide {number}: {title}'**
  String commentSlideQuote(int number, String title);

  /// Label of a comment whose slide or object was deleted.
  ///
  /// In en, this message translates to:
  /// **'The object this comment was on was deleted'**
  String get commentAnchorDeleted;

  /// Label of a comment whose slide or object was deleted, with its quoted text.
  ///
  /// In en, this message translates to:
  /// **'{quote} — the object this comment was on was deleted'**
  String commentAnchorDeletedQuote(String quote);

  /// Semantics label of a comment pin on the canvas.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Comment by {name}} other{{count} comments, first by {name}}}'**
  String commentPinLabel(int count, String name);

  /// Reply count in a comment hover card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply} other{{count} replies}}'**
  String commentReplies(int count);

  /// Semantics and tooltip of the open-comment badge of a slide.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String commentsBadge(int count);

  /// Disabled reason of next/previous comment.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get reasonNoComments;

  /// Close button of the comment card docked at a pin.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commentsDockedClose;

  /// No description provided for @cmdSpellingCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'Walk through the misspelled words of the whole presentation'**
  String get cmdSpellingCheckDescription;

  /// No description provided for @cmdSpellingReplace.
  ///
  /// In en, this message translates to:
  /// **'Correct spelling'**
  String get cmdSpellingReplace;

  /// No description provided for @cmdSpellingReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Correct spelling everywhere'**
  String get cmdSpellingReplaceAll;

  /// No description provided for @cmdSpellingIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get cmdSpellingIgnore;

  /// No description provided for @cmdSpellingAddToDictionary.
  ///
  /// In en, this message translates to:
  /// **'Add to dictionary'**
  String get cmdSpellingAddToDictionary;

  /// No description provided for @cmdSpellingPersonalDictionary.
  ///
  /// In en, this message translates to:
  /// **'Personal dictionary…'**
  String get cmdSpellingPersonalDictionary;

  /// No description provided for @undoCorrectSpelling.
  ///
  /// In en, this message translates to:
  /// **'Correct spelling'**
  String get undoCorrectSpelling;

  /// No description provided for @undoSetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Set language'**
  String get undoSetLanguage;

  /// Disabled row of the context menu on a misspelled word without suggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get spellingNoSuggestions;

  /// No description provided for @spellingAddWordToDictionary.
  ///
  /// In en, this message translates to:
  /// **'Add “{word}” to dictionary'**
  String spellingAddWordToDictionary(String word);

  /// No description provided for @toastPersonalDictionaryFull.
  ///
  /// In en, this message translates to:
  /// **'Your personal dictionary is full ({max} words).'**
  String toastPersonalDictionaryFull(int max);

  /// No description provided for @reasonSpellingTextGone.
  ///
  /// In en, this message translates to:
  /// **'This text is no longer there'**
  String get reasonSpellingTextGone;

  /// Title of `slides.history.restoreVersion`.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get cmdHistoryRestoreVersion;

  /// Title of `slides.history.makeCopy` (a copy of the shown version).
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get cmdHistoryMakeCopy;

  /// Title of `slides.history.download` (the shown version as PDF).
  ///
  /// In en, this message translates to:
  /// **'Download as PDF'**
  String get cmdHistoryDownload;

  /// Title of the toggle `slides.history.toggleShowChanges`.
  ///
  /// In en, this message translates to:
  /// **'Show changes'**
  String get cmdHistoryToggleShowChanges;

  /// Title of the toggle `slides.history.toggleShowRemoved` (dashed outlines of deleted objects).
  ///
  /// In en, this message translates to:
  /// **'Show removed objects'**
  String get cmdHistoryToggleShowRemoved;

  /// Title of `slides.history.nextChange`.
  ///
  /// In en, this message translates to:
  /// **'Next change'**
  String get cmdHistoryNextChange;

  /// Title of `slides.history.previousChange`.
  ///
  /// In en, this message translates to:
  /// **'Previous change'**
  String get cmdHistoryPreviousChange;

  /// Title of `slides.conflicts.review`.
  ///
  /// In en, this message translates to:
  /// **'Review overwritten text'**
  String get cmdConflictsReview;

  /// Title of `slides.conflicts.restoreMine` (also the undo label).
  ///
  /// In en, this message translates to:
  /// **'Restore my text'**
  String get cmdConflictsRestoreMine;

  /// Disabled reason of version commands outside the history route.
  ///
  /// In en, this message translates to:
  /// **'Open a version first'**
  String get reasonNoVersionShown;

  /// Disabled reason of next/previous change.
  ///
  /// In en, this message translates to:
  /// **'This version has no changes'**
  String get reasonNoChanges;

  /// Disabled reason of the overwritten-text review.
  ///
  /// In en, this message translates to:
  /// **'None of your text was overwritten'**
  String get reasonNoConflicts;

  /// Spinner text of the version view.
  ///
  /// In en, this message translates to:
  /// **'Loading this version…'**
  String get versionLoading;

  /// Error title of the version view.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this version'**
  String get versionLoadFailed;

  /// Summary while the diff is computed.
  ///
  /// In en, this message translates to:
  /// **'Finding changes…'**
  String get versionComputingChanges;

  /// Summary when Show changes is off.
  ///
  /// In en, this message translates to:
  /// **'Changes are hidden'**
  String get versionChangesHidden;

  /// Summary of a version without changes.
  ///
  /// In en, this message translates to:
  /// **'No changes since the previous version'**
  String get versionNoChanges;

  /// Part of the version summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide added} other{{count} slides added}}'**
  String versionSlidesAdded(int count);

  /// Part of the version summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide changed} other{{count} slides changed}}'**
  String versionSlidesChanged(int count);

  /// Part of the version summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide moved} other{{count} slides moved}}'**
  String versionSlidesMoved(int count);

  /// Part of the version summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide deleted} other{{count} slides deleted}}'**
  String versionSlidesDeleted(int count);

  /// Version summary and the change list row of theme, master or layout changes.
  ///
  /// In en, this message translates to:
  /// **'Theme changed'**
  String get versionThemeChanged;

  /// Change list row when the deck row (title, size, numbering) changed.
  ///
  /// In en, this message translates to:
  /// **'Presentation settings changed'**
  String get versionDeckChanged;

  /// Navigator tag of a slide or group added in this version.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get versionTagNew;

  /// Navigator tag of a slide reordered or regrouped in this version.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get versionTagMoved;

  /// Navigator tag of a renamed group.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get versionTagRenamed;

  /// Navigator tag of a slide deleted in this version (ghost row).
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get versionTagDeleted;

  /// Semantics label and tooltip of a ghost row.
  ///
  /// In en, this message translates to:
  /// **'Deleted slide: {title}'**
  String versionDeletedSlide(String title);

  /// Header of the change list.
  ///
  /// In en, this message translates to:
  /// **'Changes on this slide'**
  String get versionChangesOnSlide;

  /// Empty change list.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed on this slide'**
  String get versionNoChangesOnSlide;

  /// A change list row: what changed and who did it.
  ///
  /// In en, this message translates to:
  /// **'{what} — {who}'**
  String versionChangeBy(String what, String who);

  /// Author of changes an agent made through MCP for a user.
  ///
  /// In en, this message translates to:
  /// **'Claude via MCP ({name})'**
  String versionAgentMcp(String name);

  /// Author of changes the assistant made for a user.
  ///
  /// In en, this message translates to:
  /// **'Claude ({name})'**
  String versionAgentAi(String name);

  /// A changed object: its label and the kinds of change.
  ///
  /// In en, this message translates to:
  /// **'{element}: {what}'**
  String versionElementChange(String element, String what);

  /// A changed object that is new.
  ///
  /// In en, this message translates to:
  /// **'{element} added'**
  String versionElementAdded(String element);

  /// An object deleted in this version.
  ///
  /// In en, this message translates to:
  /// **'{element} deleted'**
  String versionElementRemoved(String element);

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'text edited'**
  String get versionKindText;

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'moved or resized'**
  String get versionKindFrame;

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'restyled'**
  String get versionKindStyle;

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'content changed'**
  String get versionKindData;

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'order changed'**
  String get versionKindOrder;

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'shown, hidden or locked'**
  String get versionKindVisibility;

  /// Kind of change of an object.
  ///
  /// In en, this message translates to:
  /// **'animation changed'**
  String get versionKindAnimation;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Slide added'**
  String get versionSlideAdded;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Slide moved'**
  String get versionSlideMoved;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Slide skipped or unskipped'**
  String get versionSlideSkipToggled;

  /// Change list row of a ghost slide.
  ///
  /// In en, this message translates to:
  /// **'Slide deleted'**
  String get versionSlideDeleted;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Background changed'**
  String get versionSlideBackground;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Layout changed'**
  String get versionSlideLayout;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Transition changed'**
  String get versionSlideTransition;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Speaker notes edited'**
  String get versionSlideNotes;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Timings changed'**
  String get versionSlideTimings;

  /// Change list row.
  ///
  /// In en, this message translates to:
  /// **'Master objects shown or hidden'**
  String get versionSlideMasters;

  /// Change list row of build changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 animation changed} other{{count} animations changed}}'**
  String versionAnimations(int count);

  /// Change list row (top) of a new group.
  ///
  /// In en, this message translates to:
  /// **'Section “{title}” added'**
  String versionGroupAdded(String title);

  /// Change list row (top) of a deleted group.
  ///
  /// In en, this message translates to:
  /// **'Section “{title}” deleted'**
  String versionGroupRemoved(String title);

  /// Change list row (top) of a renamed, recolored or moved group.
  ///
  /// In en, this message translates to:
  /// **'Section “{title}” changed'**
  String versionGroupChanged(String title);

  /// Position in the changes (next/previous).
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String versionChangeCounter(int index, int count);

  /// Title of the Make a copy dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy this version'**
  String get versionCopyTitle;

  /// Name field of the Make a copy dialog.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get versionCopyNameLabel;

  /// Default name of a copy.
  ///
  /// In en, this message translates to:
  /// **'Copy of {title}'**
  String versionCopyName(String title);

  /// Validation of the copy name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get versionCopyNameRequired;

  /// Checkbox of the Make a copy dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy comments'**
  String get versionCopyComments;

  /// Checkbox of the Make a copy dialog.
  ///
  /// In en, this message translates to:
  /// **'Share with the same people'**
  String get versionCopySharing;

  /// Toast action that opens the copy.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get versionOpenCopy;

  /// Toast after a version copy.
  ///
  /// In en, this message translates to:
  /// **'Created “{name}”'**
  String toastVersionCopied(String name);

  /// Error toast.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t copy this version'**
  String get toastVersionCopyFailed;

  /// Error toast.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t download this version'**
  String get toastVersionDownloadFailed;

  /// Title of the overwritten-text review.
  ///
  /// In en, this message translates to:
  /// **'Your text was replaced'**
  String get conflictsTitle;

  /// Description of the overwritten-text review.
  ///
  /// In en, this message translates to:
  /// **'Newer edits from collaborators replaced text you edited while offline. Choose the texts to put back.'**
  String get conflictsDescription;

  /// A checkbox of the review.
  ///
  /// In en, this message translates to:
  /// **'{where} — yours: {mine} · now: {theirs} ({who})'**
  String conflictsRow(String where, String mine, String theirs, String who);

  /// A line of the review for deleted targets.
  ///
  /// In en, this message translates to:
  /// **'{where} was deleted by {who} · yours: {mine}'**
  String conflictsDeletedBy(String where, String who, String mine);

  /// Where an overwritten text is.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}, {element}'**
  String conflictsSlideTarget(int number, String element);

  /// Where overwritten notes are.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}, speaker notes'**
  String conflictsNotesTarget(int number);

  /// Where an overwritten table cell is.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}, table cell'**
  String conflictsCellTarget(int number);

  /// Where an overwritten text was (target gone).
  ///
  /// In en, this message translates to:
  /// **'A deleted slide'**
  String get conflictsGoneTarget;

  /// An empty text in the review.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get conflictsEmptyValue;

  /// Primary button of the overwritten-text review: puts the checked texts of yours back.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get conflictsRestoreMine;

  /// Button of the overwritten-text review: copies your texts to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get conflictsCopyMine;

  /// Button of the review.
  ///
  /// In en, this message translates to:
  /// **'Dismiss all'**
  String get conflictsDismissAll;

  /// Toast action that opens the review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get conflictsReview;

  /// Who replaced the texts when several did.
  ///
  /// In en, this message translates to:
  /// **'several people'**
  String get conflictsSeveralPeople;

  /// Toast after a sync replaced offline text edits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of your text edits was} other{{count} of your text edits were}} replaced by newer edits from {who}'**
  String toastConflicts(int count, String who);

  /// Toast after Copy mine.
  ///
  /// In en, this message translates to:
  /// **'Copied your text'**
  String get toastConflictsCopied;

  /// Toast when a collaborator restored a version.
  ///
  /// In en, this message translates to:
  /// **'{name} restored a previous version'**
  String toastVersionRestoredBy(String name);

  /// Undo label of dragging an elbow segment or the bend of a curved connector.
  ///
  /// In en, this message translates to:
  /// **'Edit connector route'**
  String get cmdLineSetWaypoints;

  /// Title of the assistant side panel (suite 10 §3).
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiPanelTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Ask about this presentation, or ask for changes'**
  String get aiAssistantEmptyTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Your messages and this presentation\'s content are sent to an AI provider.'**
  String get aiAssistantPrivacyNotice;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Your messages and this presentation\'s content are sent to {provider}.'**
  String aiAssistantPrivacyNoticeProvider(String provider);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Changes go straight into the presentation'**
  String get aiAssistantModeEditHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'You can only suggest changes in this presentation'**
  String get aiAssistantModeEditUnavailable;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Changes are previewed before anything is applied'**
  String get aiAssistantModeSuggestHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t available'**
  String get aiUnavailable;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'AI is turned off'**
  String get aiTurnedOff;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Settings › AI.'**
  String get aiTurnOnHint;

  /// Context chip of the assistant: the current slide.
  ///
  /// In en, this message translates to:
  /// **'Slide {position}'**
  String aiChipSlide(int position);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected object} other{{count} selected objects}}'**
  String aiChipObjects(int count);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Improve slide'**
  String get aiQuickImproveSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Speaker notes'**
  String get aiQuickNotes;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Summarize deck'**
  String get aiQuickSummarize;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Add agenda'**
  String get aiQuickAgenda;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Check wording'**
  String get aiQuickConsistency;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate a presentation…'**
  String get aiQuickNewDeck;

  /// Undo label of AI changes ("AI: Shorten text").
  ///
  /// In en, this message translates to:
  /// **'AI: {summary}'**
  String aiUndoLabel(String summary);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Assistant changes'**
  String get aiUndoDefault;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'The AI request failed'**
  String get aiFailed;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get aiPreviewReview;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Suggested changes applied'**
  String get aiPreviewAppliedNote;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Suggested changes discarded'**
  String get aiPreviewDiscardedNote;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Suggested changes'**
  String get aiPreviewTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Choose the changes to apply. Nothing changes until you apply them.'**
  String get aiPreviewDescription;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply selected'**
  String get aiPreviewApply;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aiPreviewDiscard;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get aiPreviewBefore;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get aiPreviewAfter;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'New slide'**
  String get aiPreviewNewSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get aiPreviewDeletedSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Slide {position}'**
  String aiPreviewSlide(int position);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'These changes don\'t change a slide\'s look.'**
  String get aiPreviewNoSlides;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 value someone changed meanwhile was kept} other{{count} values someone changed meanwhile were kept}}'**
  String aiPreviewSkipped(int count);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply suggested changes'**
  String get aiPreviewApplyAll;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate presentation'**
  String get aiGenerateTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get aiGenerateSource;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get aiGenerateSourcePrompt;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get aiGenerateSourceOutline;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'What is the presentation about?'**
  String get aiGeneratePromptLabel;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Quarterly review of the Serverpod Cloud launch for the board…'**
  String get aiGeneratePromptHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Your outline'**
  String get aiGenerateOutlineLabel;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Paste bullets or Markdown with one heading per slide'**
  String get aiGenerateOutlineHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get aiGenerateSlides;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get aiGenerateSlidesAuto;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get aiGenerateAudience;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get aiGenerateTone;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get aiGenerateLanguage;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Same as the text'**
  String get aiGenerateLanguageAuto;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Speaker notes'**
  String get aiGenerateNotes;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Group into sections'**
  String get aiGenerateGroups;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Keep my wording'**
  String get aiGenerateKeepWording;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get aiGenerateInsert;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'New presentation'**
  String get aiGenerateInsertNew;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'After slide {position}'**
  String aiGenerateInsertAfter(int position);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'At the end'**
  String get aiGenerateInsertEnd;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Create outline'**
  String get aiGenerateCreateOutline;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Planning the outline…'**
  String get aiGeneratePlanning;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Review the outline'**
  String get aiGenerateOutlineTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Edit titles and roles, reorder or delete slides, then create them.'**
  String get aiGenerateOutlineDescription;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Create slides'**
  String get aiGenerateBuild;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get aiGenerateBack;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiGenerateRegenerate;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Regenerate this slide'**
  String get aiGenerateRegenerateSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'What should change? (optional)'**
  String get aiGenerateRegenerateHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Add slide'**
  String get aiGenerateAddSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Delete slide'**
  String get aiGenerateDeleteSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get aiGenerateMoveUp;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get aiGenerateMoveDown;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Slide title'**
  String get aiGenerateSlideTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Bullets (one per line)'**
  String get aiGenerateBullets;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slide} other{{count} slides}}'**
  String aiGenerateSlideCount(int count);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get aiGenerateRole;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Creating slides…'**
  String get aiGenerateBuilding;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate slides'**
  String get aiGenerateUndo;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'New slide'**
  String get aiGenerateNewSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Describe the presentation first.'**
  String get aiGenerateEmpty;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 slide} other{Added {count} slides}}'**
  String aiGenerateDone(int count);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Presentation created'**
  String get aiGenerateCreated;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get aiRoleTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get aiRoleSection;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get aiRoleAgenda;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Bullets'**
  String get aiRoleBullets;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Two columns'**
  String get aiRoleTwoColumn;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get aiRoleQuote;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Big number'**
  String get aiRoleBigNumber;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Image and text'**
  String get aiRoleImageText;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get aiRoleCode;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get aiRoleChartPlaceholder;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get aiRoleClosing;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get aiAudienceGeneral;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get aiAudienceBoard;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get aiAudienceTeam;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get aiAudienceCustomers;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get aiAudienceStudents;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get aiAudienceDevelopers;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get aiToneProfessional;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get aiToneFriendly;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Inspiring'**
  String get aiToneInspiring;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get aiToneTechnical;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Concise'**
  String get aiToneConcise;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Rewrite text'**
  String get aiRewriteTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get aiRewriteWorking;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get aiRewriteReplace;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get aiRewriteTryAgain;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aiRewriteDiscard;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Refine, e.g. even shorter'**
  String get aiRewriteRefineHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Refine'**
  String get aiRewriteRefine;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get aiRewriteOriginal;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get aiRewriteResult;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'The text changed meanwhile. Copy the suggestion or try again.'**
  String get aiRewriteChanged;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiRewriteCopy;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiRewriteCopied;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'How should the text change?'**
  String get aiRewriteCustomLabel;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Make it sound more confident'**
  String get aiRewriteCustomHint;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Rewrite text'**
  String get aiRewriteUndo;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Select a text box with text'**
  String get aiRewriteNoText;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Punchier'**
  String get rewritePunchier;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Make bullets'**
  String get rewriteBullets;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Make a paragraph'**
  String get rewriteParagraph;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Write speaker notes'**
  String get aiNotesTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get aiNotesScope;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Current slide'**
  String get aiNotesScopeCurrent;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Selected slides'**
  String get aiNotesScopeSelected;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get aiNotesScopeAll;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get aiNotesLength;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get aiNotesLengthBrief;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get aiNotesLengthStandard;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get aiNotesLengthDetailed;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get aiNotesStyle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get aiNotesStyleScript;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Bullet points'**
  String get aiNotesStyleBullets;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Existing notes'**
  String get aiNotesMode;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Only write empty notes'**
  String get aiNotesModeFillEmpty;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Add to them'**
  String get aiNotesModeAppend;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Replace them'**
  String get aiNotesModeReplace;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Write notes'**
  String get aiNotesGenerate;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Writing notes…'**
  String get aiNotesWorking;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Review speaker notes'**
  String get aiNotesReviewTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get aiNotesApply;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'No slide needs notes.'**
  String get aiNotesNone;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Current notes'**
  String get aiNotesExisting;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Write speaker notes'**
  String get aiNotesUndo;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate alt text'**
  String get aiAltTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Describing objects…'**
  String get aiAltWorking;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get aiAltApply;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Nothing needs alt text.'**
  String get aiAltNone;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'This kind of object can\'t be described.'**
  String get aiAltSkippedUnsupported;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'No description was proposed.'**
  String get aiAltSkippedEmpty;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate alt text'**
  String get aiAltUndo;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'{kind} on slide {position}'**
  String aiAltObject(String kind, int position);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get a11yGenerateAlt;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Generate missing alt text'**
  String get a11yGenerateMissingAlt;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Design ideas'**
  String get aiDesignTitle;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'No ideas for this slide — add some content'**
  String get aiDesignEmpty;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Select a slide to see design ideas'**
  String get aiDesignNoSlide;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get aiDesignRefresh;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'More ideas'**
  String get aiDesignMore;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Ranking with AI…'**
  String get aiDesignRanking;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Layout ideas for this slide'**
  String get aiDesignLayoutIdeas;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Ranked by AI for this slide'**
  String get aiDesignAiRanked;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply design idea'**
  String get aiDesignUndo;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply {name}'**
  String aiDesignApply(String name);

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply design idea'**
  String get cmdAiApplyDesignIdea;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Design ideas'**
  String get cmdPanelDesignIdeas;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Apply suggested changes'**
  String get cmdAiApplyPreview;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Discard suggested changes'**
  String get cmdAiDiscardPreview;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Assistant: edit or suggest'**
  String get cmdAiSetApplyMode;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t available'**
  String get reasonAiUnavailable;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'Select a text box with text'**
  String get reasonNoTextToRewrite;

  /// Wonky Slides AI (Slides 11 §6; SL-43).
  ///
  /// In en, this message translates to:
  /// **'No suggested changes to review'**
  String get reasonNoPreview;

  /// Avatar tooltip of a collaborator editing a layout in the masters view (Slides 09 §1.2; SL-37).
  ///
  /// In en, this message translates to:
  /// **'Editing layout · {name}'**
  String presenceEditingLayout(String name);

  /// Follow banner button while the followed collaborator presents: follows their presentation (09 §1.6; SL-37).
  ///
  /// In en, this message translates to:
  /// **'Watch presentation'**
  String get followWatchPresentation;

  /// Screen reader label of the live dot on the Present button while a collaborator presents (09 §1.6; SL-37).
  ///
  /// In en, this message translates to:
  /// **'{name} is presenting'**
  String presenterLive(String name);

  /// Present menu item while a collaborator presents (04 §3, 09 §1.6; SL-37).
  ///
  /// In en, this message translates to:
  /// **'Follow {name}\'s presentation'**
  String presentMenuFollow(String name);

  /// Bar of the follower view of a presentation (09 §1.6; SL-37).
  ///
  /// In en, this message translates to:
  /// **'Following {name} — press Esc to stop'**
  String followerFollowing(String name);

  /// Bar of the follower view when the presenter's name is unknown (SL-37).
  ///
  /// In en, this message translates to:
  /// **'Following the presenter — press Esc to stop'**
  String get followerFollowingUnknown;

  /// Follower bar after the follower navigated away from the presenter (10 §6.3; SL-37).
  ///
  /// In en, this message translates to:
  /// **'You left {name}\'s slide'**
  String followerBrowsing(String name);

  /// Follower bar after browsing away, presenter name unknown (SL-37).
  ///
  /// In en, this message translates to:
  /// **'You left the presenter\'s slide'**
  String get followerBrowsingUnknown;

  /// Follower bar button: back to the presenter's slide (10 §6.3; SL-37).
  ///
  /// In en, this message translates to:
  /// **'Return to presenter'**
  String get followerReturn;

  /// Follower bar button: full screen (SL-37).
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get followerFullscreen;

  /// Follower bar button: leaves the follower view (SL-37).
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get followerStop;

  /// Title of the command `slides.presence.returnToPresenter` (menus, palette, tooltips).
  ///
  /// In en, this message translates to:
  /// **'Return to presenter'**
  String get cmdPresenceReturnToPresenter;

  /// Screen reader label of a collaborator's live pointer on the canvas (09 §1.4; SL-37).
  ///
  /// In en, this message translates to:
  /// **'{name}\'s pointer'**
  String pointerOnSlide(String name);

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'This object is locked.'**
  String get errorObjectLocked;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'There are too many guides'**
  String get errorTooManyGuides;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Select a text box'**
  String get errorSelectTextBox;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'The copy couldn’t be made'**
  String get errorCopyFailed;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore'**
  String get errorNothingToRestore;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'The crop removes the whole image'**
  String get errorCropRemovesImage;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Select at least one slide'**
  String get errorSelectSlide;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'The clipboard holds no slides'**
  String get errorClipboardNoSlides;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Nothing to move there'**
  String get errorNothingToMove;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'One emoji is expected'**
  String get errorOneEmoji;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'The text has changed'**
  String get errorTextChanged;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'One word is expected'**
  String get errorOneWord;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'No slides selected'**
  String get errorNoSlidesSelected;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix'**
  String get errorNothingToFix;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste'**
  String get errorNothingToPaste;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'The line is not on the current slide'**
  String get errorLineNotOnSlide;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Route handles are not available inside groups'**
  String get errorRouteHandlesInGroups;

  /// Message of a command that can't run (shown as a toast; CQ-57).
  ///
  /// In en, this message translates to:
  /// **'Straight lines have no waypoints'**
  String get errorStraightLineWaypoints;
}

class _SlidesLocalizationsDelegate
    extends LocalizationsDelegate<SlidesLocalizations> {
  const _SlidesLocalizationsDelegate();

  @override
  Future<SlidesLocalizations> load(Locale locale) {
    return SynchronousFuture<SlidesLocalizations>(
      lookupSlidesLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SlidesLocalizationsDelegate old) => false;
}

SlidesLocalizations lookupSlidesLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return SlidesLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SlidesLocalizationsEn();
  }

  throw FlutterError(
    'SlidesLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
