import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'write_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of WriteLocalizations
/// returned by `WriteLocalizations.of(context)`.
///
/// Applications need to include `WriteLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/write_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: WriteLocalizations.localizationsDelegates,
///   supportedLocales: WriteLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the WriteLocalizations.supportedLocales
/// property.
abstract class WriteLocalizations {
  WriteLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static WriteLocalizations of(BuildContext context) {
    return Localizations.of<WriteLocalizations>(context, WriteLocalizations)!;
  }

  static const LocalizationsDelegate<WriteLocalizations> delegate =
      _WriteLocalizationsDelegate();

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

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get categoryAI;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get categoryBlocks;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Code blocks'**
  String get categoryCodeBlocks;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get categoryCollaboration;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get categoryComments;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get categoryDeveloper;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get categoryEdit;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get categoryFile;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get categoryFormat;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get categoryHelp;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get categoryImages;

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
  /// **'Preferences'**
  String get categoryPreferences;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get categorySuggestions;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get categoryTables;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get categoryThemes;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get categoryTools;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get categoryVersionHistory;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get categoryView;

  /// Command category (palette, keyboard shortcuts help).
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get categoryWrite;

  /// No description provided for @reasonDocumentLoading.
  ///
  /// In en, this message translates to:
  /// **'The document is still loading'**
  String get reasonDocumentLoading;

  /// No description provided for @reasonViewAccess.
  ///
  /// In en, this message translates to:
  /// **'You have view access'**
  String get reasonViewAccess;

  /// No description provided for @reasonSwitchToEditOrSuggest.
  ///
  /// In en, this message translates to:
  /// **'Switch to Editing or Suggesting to make changes'**
  String get reasonSwitchToEditOrSuggest;

  /// No description provided for @reasonSuggestOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only suggest changes'**
  String get reasonSuggestOnly;

  /// No description provided for @reasonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available here'**
  String get reasonNotAvailable;

  /// No description provided for @reasonSwitchToSuggesting.
  ///
  /// In en, this message translates to:
  /// **'Switch to Suggesting to propose changes'**
  String get reasonSwitchToSuggesting;

  /// No description provided for @reasonNeedEditAccess.
  ///
  /// In en, this message translates to:
  /// **'You need edit access'**
  String get reasonNeedEditAccess;

  /// No description provided for @reasonCannotSuggest.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be suggested — switch to Editing'**
  String get reasonCannotSuggest;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get commonInsert;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @cmdEditCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cmdEditCopy;

  /// No description provided for @cmdEditCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cmdEditCut;

  /// No description provided for @cmdEditPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get cmdEditPaste;

  /// No description provided for @cmdEditPasteWithoutFormatting.
  ///
  /// In en, this message translates to:
  /// **'Paste without formatting'**
  String get cmdEditPasteWithoutFormatting;

  /// No description provided for @cmdEditPasteAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Paste as Markdown'**
  String get cmdEditPasteAsMarkdown;

  /// No description provided for @cmdEditCopyAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy as Markdown'**
  String get cmdEditCopyAsMarkdown;

  /// No description provided for @cmdEditCopyAsPlainText.
  ///
  /// In en, this message translates to:
  /// **'Copy as plain text'**
  String get cmdEditCopyAsPlainText;

  /// No description provided for @cmdEditCopyAsHtml.
  ///
  /// In en, this message translates to:
  /// **'Copy as HTML'**
  String get cmdEditCopyAsHtml;

  /// No description provided for @cmdEditSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cmdEditSelectAll;

  /// No description provided for @cmdEditDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cmdEditDelete;

  /// No description provided for @cmdEditInsertText.
  ///
  /// In en, this message translates to:
  /// **'Insert text'**
  String get cmdEditInsertText;

  /// No description provided for @cmdEditReplaceRange.
  ///
  /// In en, this message translates to:
  /// **'Replace text'**
  String get cmdEditReplaceRange;

  /// No description provided for @cmdEditSelectRange.
  ///
  /// In en, this message translates to:
  /// **'Select range'**
  String get cmdEditSelectRange;

  /// No description provided for @cmdFormatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get cmdFormatBold;

  /// No description provided for @cmdFormatItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get cmdFormatItalic;

  /// No description provided for @cmdFormatStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get cmdFormatStrikethrough;

  /// No description provided for @cmdFormatInlineCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get cmdFormatInlineCode;

  /// No description provided for @cmdFormatClearFormatting.
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get cmdFormatClearFormatting;

  /// No description provided for @cmdFormatBlockType.
  ///
  /// In en, this message translates to:
  /// **'Paragraph style'**
  String get cmdFormatBlockType;

  /// No description provided for @cmdFormatBlockTypeParagraph.
  ///
  /// In en, this message translates to:
  /// **'Normal text'**
  String get cmdFormatBlockTypeParagraph;

  /// No description provided for @cmdFormatBlockTypeHeading1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get cmdFormatBlockTypeHeading1;

  /// No description provided for @cmdFormatBlockTypeHeading2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get cmdFormatBlockTypeHeading2;

  /// No description provided for @cmdFormatBlockTypeHeading3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get cmdFormatBlockTypeHeading3;

  /// No description provided for @cmdFormatBlockTypeHeading4.
  ///
  /// In en, this message translates to:
  /// **'Heading 4'**
  String get cmdFormatBlockTypeHeading4;

  /// No description provided for @cmdFormatBlockTypeHeading5.
  ///
  /// In en, this message translates to:
  /// **'Heading 5'**
  String get cmdFormatBlockTypeHeading5;

  /// No description provided for @cmdFormatBlockTypeHeading6.
  ///
  /// In en, this message translates to:
  /// **'Heading 6'**
  String get cmdFormatBlockTypeHeading6;

  /// No description provided for @cmdFormatBlockTypeQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get cmdFormatBlockTypeQuote;

  /// No description provided for @cmdFormatBlockTypeCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get cmdFormatBlockTypeCodeBlock;

  /// No description provided for @cmdFormatMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'Markdown formatting hint'**
  String get cmdFormatMarkdownHint;

  /// No description provided for @cmdListToggleBulleted.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get cmdListToggleBulleted;

  /// No description provided for @cmdListToggleNumbered.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get cmdListToggleNumbered;

  /// No description provided for @cmdListToggleChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get cmdListToggleChecklist;

  /// No description provided for @cmdListIndent.
  ///
  /// In en, this message translates to:
  /// **'Increase indent'**
  String get cmdListIndent;

  /// No description provided for @cmdListOutdent.
  ///
  /// In en, this message translates to:
  /// **'Decrease indent'**
  String get cmdListOutdent;

  /// No description provided for @cmdListToggleChecked.
  ///
  /// In en, this message translates to:
  /// **'Check item'**
  String get cmdListToggleChecked;

  /// No description provided for @cmdLinkSet.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get cmdLinkSet;

  /// No description provided for @cmdLinkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get cmdLinkRemove;

  /// No description provided for @cmdInsertDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get cmdInsertDivider;

  /// No description provided for @cmdInsertImageFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Image from URL'**
  String get cmdInsertImageFromUrl;

  /// No description provided for @cmdInsertTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get cmdInsertTable;

  /// No description provided for @cmdInsertMention.
  ///
  /// In en, this message translates to:
  /// **'Mention'**
  String get cmdInsertMention;

  /// No description provided for @cmdInsertSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'Special characters…'**
  String get cmdInsertSpecialCharacter;

  /// No description provided for @cmdBlockTurnInto.
  ///
  /// In en, this message translates to:
  /// **'Turn into'**
  String get cmdBlockTurnInto;

  /// No description provided for @cmdBlockDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get cmdBlockDuplicate;

  /// No description provided for @cmdBlockDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete block'**
  String get cmdBlockDelete;

  /// No description provided for @cmdBlockMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move block up'**
  String get cmdBlockMoveUp;

  /// No description provided for @cmdBlockMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move block down'**
  String get cmdBlockMoveDown;

  /// No description provided for @cmdBlockMove.
  ///
  /// In en, this message translates to:
  /// **'Move blocks'**
  String get cmdBlockMove;

  /// No description provided for @cmdBlockSelect.
  ///
  /// In en, this message translates to:
  /// **'Select block'**
  String get cmdBlockSelect;

  /// No description provided for @cmdCodeSetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Set code language'**
  String get cmdCodeSetLanguage;

  /// No description provided for @cmdCodeExit.
  ///
  /// In en, this message translates to:
  /// **'Exit code block'**
  String get cmdCodeExit;

  /// No description provided for @cmdCodeIndentLines.
  ///
  /// In en, this message translates to:
  /// **'Indent code'**
  String get cmdCodeIndentLines;

  /// No description provided for @cmdCodeOutdentLines.
  ///
  /// In en, this message translates to:
  /// **'Outdent code'**
  String get cmdCodeOutdentLines;

  /// No description provided for @cmdImageSetAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get cmdImageSetAlt;

  /// No description provided for @cmdImageReplaceFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get cmdImageReplaceFromUrl;

  /// No description provided for @cmdTableInsertRow.
  ///
  /// In en, this message translates to:
  /// **'Insert row'**
  String get cmdTableInsertRow;

  /// No description provided for @cmdTableInsertColumn.
  ///
  /// In en, this message translates to:
  /// **'Insert column'**
  String get cmdTableInsertColumn;

  /// No description provided for @cmdTableDeleteRow.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get cmdTableDeleteRow;

  /// No description provided for @cmdTableDeleteColumn.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get cmdTableDeleteColumn;

  /// No description provided for @cmdTableMoveRow.
  ///
  /// In en, this message translates to:
  /// **'Move row'**
  String get cmdTableMoveRow;

  /// No description provided for @cmdTableMoveColumn.
  ///
  /// In en, this message translates to:
  /// **'Move column'**
  String get cmdTableMoveColumn;

  /// No description provided for @cmdTableSetColumnAlignment.
  ///
  /// In en, this message translates to:
  /// **'Column alignment'**
  String get cmdTableSetColumnAlignment;

  /// No description provided for @cmdTableSetCell.
  ///
  /// In en, this message translates to:
  /// **'Edit cell'**
  String get cmdTableSetCell;

  /// No description provided for @cmdTableDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get cmdTableDelete;

  /// No description provided for @cmdViewZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get cmdViewZoomIn;

  /// No description provided for @cmdViewZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get cmdViewZoomOut;

  /// No description provided for @cmdViewZoomReset.
  ///
  /// In en, this message translates to:
  /// **'Zoom to 100 %'**
  String get cmdViewZoomReset;

  /// No description provided for @cmdViewZoomSet.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get cmdViewZoomSet;

  /// No description provided for @cmdViewSuggestionPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview suggestions'**
  String get cmdViewSuggestionPreview;

  /// No description provided for @cmdModeSet.
  ///
  /// In en, this message translates to:
  /// **'Editing mode'**
  String get cmdModeSet;

  /// No description provided for @cmdNavDocumentStart.
  ///
  /// In en, this message translates to:
  /// **'Go to document start'**
  String get cmdNavDocumentStart;

  /// No description provided for @cmdNavDocumentEnd.
  ///
  /// In en, this message translates to:
  /// **'Go to document end'**
  String get cmdNavDocumentEnd;

  /// No description provided for @cmdFileDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get cmdFileDownload;

  /// No description provided for @cmdFilePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get cmdFilePrint;

  /// No description provided for @cmdInsertFromFile.
  ///
  /// In en, this message translates to:
  /// **'Insert from file…'**
  String get cmdInsertFromFile;

  /// No description provided for @cmdFindOpen.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get cmdFindOpen;

  /// No description provided for @cmdFindOpenReplace.
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get cmdFindOpenReplace;

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

  /// No description provided for @cmdNavGoToHeading.
  ///
  /// In en, this message translates to:
  /// **'Go to heading…'**
  String get cmdNavGoToHeading;

  /// No description provided for @cmdViewToggleOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get cmdViewToggleOutline;

  /// No description provided for @cmdViewToggleWordCount.
  ///
  /// In en, this message translates to:
  /// **'Word count'**
  String get cmdViewToggleWordCount;

  /// No description provided for @cmdViewFocusToolbar.
  ///
  /// In en, this message translates to:
  /// **'Focus the toolbar'**
  String get cmdViewFocusToolbar;

  /// No description provided for @cmdViewZoomFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get cmdViewZoomFit;

  /// No description provided for @cmdOutlineSetMaxLevel.
  ///
  /// In en, this message translates to:
  /// **'Outline levels'**
  String get cmdOutlineSetMaxLevel;

  /// No description provided for @cmdInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get cmdInsertImage;

  /// No description provided for @cmdInsertTableDialog.
  ///
  /// In en, this message translates to:
  /// **'Table…'**
  String get cmdInsertTableDialog;

  /// No description provided for @cmdInsertMentionTrigger.
  ///
  /// In en, this message translates to:
  /// **'Mention a person'**
  String get cmdInsertMentionTrigger;

  /// No description provided for @cmdLinkInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get cmdLinkInsert;

  /// No description provided for @cmdLinkEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get cmdLinkEdit;

  /// No description provided for @cmdLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get cmdLinkOpen;

  /// No description provided for @cmdLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get cmdLinkCopy;

  /// No description provided for @cmdImageEditAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt text…'**
  String get cmdImageEditAlt;

  /// No description provided for @cmdImageReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace image…'**
  String get cmdImageReplace;

  /// No description provided for @cmdImageDownload.
  ///
  /// In en, this message translates to:
  /// **'Download image'**
  String get cmdImageDownload;

  /// No description provided for @cmdTableEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit table…'**
  String get cmdTableEdit;

  /// No description provided for @cmdTableCopyAsTsv.
  ///
  /// In en, this message translates to:
  /// **'Copy as TSV'**
  String get cmdTableCopyAsTsv;

  /// No description provided for @cmdCodeCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get cmdCodeCopy;

  /// No description provided for @cmdDocPageSetup.
  ///
  /// In en, this message translates to:
  /// **'Page setup…'**
  String get cmdDocPageSetup;

  /// No description provided for @cmdDocSetPageSetup.
  ///
  /// In en, this message translates to:
  /// **'Change page setup'**
  String get cmdDocSetPageSetup;

  /// No description provided for @cmdDocSetLayout.
  ///
  /// In en, this message translates to:
  /// **'Page layout'**
  String get cmdDocSetLayout;

  /// No description provided for @cmdDocLanguageDialog.
  ///
  /// In en, this message translates to:
  /// **'Language…'**
  String get cmdDocLanguageDialog;

  /// No description provided for @cmdDocSetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get cmdDocSetLanguage;

  /// No description provided for @cmdDocSetFrontMatter.
  ///
  /// In en, this message translates to:
  /// **'Change front matter'**
  String get cmdDocSetFrontMatter;

  /// No description provided for @cmdDocProperties.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get cmdDocProperties;

  /// No description provided for @cmdThemeOpenPicker.
  ///
  /// In en, this message translates to:
  /// **'Choose theme…'**
  String get cmdThemeOpenPicker;

  /// No description provided for @cmdThemeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply theme'**
  String get cmdThemeApply;

  /// No description provided for @cmdThemeSetUserDefault.
  ///
  /// In en, this message translates to:
  /// **'Save as my default theme'**
  String get cmdThemeSetUserDefault;

  /// No description provided for @cmdToolsWordCount.
  ///
  /// In en, this message translates to:
  /// **'Word count'**
  String get cmdToolsWordCount;

  /// No description provided for @cmdHelpMarkdownGuide.
  ///
  /// In en, this message translates to:
  /// **'Markdown & formatting guide'**
  String get cmdHelpMarkdownGuide;

  /// No description provided for @cmdPrefsSetDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default mode'**
  String get cmdPrefsSetDefaultMode;

  /// No description provided for @cmdInsertEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji…'**
  String get cmdInsertEmoji;

  /// No description provided for @cmdImagePreview.
  ///
  /// In en, this message translates to:
  /// **'View full size'**
  String get cmdImagePreview;

  /// No description provided for @cmdTableEditCell.
  ///
  /// In en, this message translates to:
  /// **'Edit table cell'**
  String get cmdTableEditCell;

  /// No description provided for @cmdSpellToggle.
  ///
  /// In en, this message translates to:
  /// **'Underline spelling errors'**
  String get cmdSpellToggle;

  /// No description provided for @cmdSpellToggleIgnoreUppercase.
  ///
  /// In en, this message translates to:
  /// **'Ignore words in UPPERCASE'**
  String get cmdSpellToggleIgnoreUppercase;

  /// No description provided for @cmdSpellReplace.
  ///
  /// In en, this message translates to:
  /// **'Correct spelling'**
  String get cmdSpellReplace;

  /// No description provided for @cmdSpellIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get cmdSpellIgnore;

  /// No description provided for @cmdSpellAddToDictionary.
  ///
  /// In en, this message translates to:
  /// **'Add to dictionary'**
  String get cmdSpellAddToDictionary;

  /// No description provided for @cmdSpellNextError.
  ///
  /// In en, this message translates to:
  /// **'Next spelling error'**
  String get cmdSpellNextError;

  /// No description provided for @cmdSpellCheck.
  ///
  /// In en, this message translates to:
  /// **'Check spelling…'**
  String get cmdSpellCheck;

  /// No description provided for @cmdSpellPersonalDictionary.
  ///
  /// In en, this message translates to:
  /// **'Personal dictionary…'**
  String get cmdSpellPersonalDictionary;

  /// No description provided for @cmdThemeOpenEditor.
  ///
  /// In en, this message translates to:
  /// **'Customize theme…'**
  String get cmdThemeOpenEditor;

  /// No description provided for @cmdThemeOpenManager.
  ///
  /// In en, this message translates to:
  /// **'Manage themes…'**
  String get cmdThemeOpenManager;

  /// No description provided for @cmdThemeUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use my default theme'**
  String get cmdThemeUseDefault;

  /// No description provided for @cmdThemeCreate.
  ///
  /// In en, this message translates to:
  /// **'New theme'**
  String get cmdThemeCreate;

  /// No description provided for @cmdThemeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate theme'**
  String get cmdThemeDuplicate;

  /// No description provided for @cmdThemeRename.
  ///
  /// In en, this message translates to:
  /// **'Rename theme…'**
  String get cmdThemeRename;

  /// No description provided for @cmdThemeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete theme'**
  String get cmdThemeDelete;

  /// No description provided for @cmdThemeRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore theme'**
  String get cmdThemeRestore;

  /// No description provided for @cmdThemeSetAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as my default theme'**
  String get cmdThemeSetAsDefault;

  /// No description provided for @cmdThemeApplyToDocument.
  ///
  /// In en, this message translates to:
  /// **'Apply to document'**
  String get cmdThemeApplyToDocument;

  /// No description provided for @cmdThemeSelectElement.
  ///
  /// In en, this message translates to:
  /// **'Select theme element'**
  String get cmdThemeSelectElement;

  /// No description provided for @cmdThemeSetProperty.
  ///
  /// In en, this message translates to:
  /// **'Change theme property'**
  String get cmdThemeSetProperty;

  /// No description provided for @cmdThemeResetElement.
  ///
  /// In en, this message translates to:
  /// **'Reset element'**
  String get cmdThemeResetElement;

  /// No description provided for @cmdThemeFixContrast.
  ///
  /// In en, this message translates to:
  /// **'Fix contrast'**
  String get cmdThemeFixContrast;

  /// No description provided for @cmdThemeRevert.
  ///
  /// In en, this message translates to:
  /// **'Revert theme changes'**
  String get cmdThemeRevert;

  /// No description provided for @cmdThemeSave.
  ///
  /// In en, this message translates to:
  /// **'Save theme'**
  String get cmdThemeSave;

  /// No description provided for @cmdThemeShowRevisions.
  ///
  /// In en, this message translates to:
  /// **'Theme version history…'**
  String get cmdThemeShowRevisions;

  /// No description provided for @cmdThemeImportJson.
  ///
  /// In en, this message translates to:
  /// **'Import theme…'**
  String get cmdThemeImportJson;

  /// No description provided for @cmdAiRewriteSelection.
  ///
  /// In en, this message translates to:
  /// **'Rewrite with AI'**
  String get cmdAiRewriteSelection;

  /// No description provided for @cmdAiInline.
  ///
  /// In en, this message translates to:
  /// **'Ask AI…'**
  String get cmdAiInline;

  /// No description provided for @cmdAiContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue writing'**
  String get cmdAiContinue;

  /// No description provided for @cmdAiSummarizeDocument.
  ///
  /// In en, this message translates to:
  /// **'Summarize document'**
  String get cmdAiSummarizeDocument;

  /// No description provided for @cmdAiGenerateOutline.
  ///
  /// In en, this message translates to:
  /// **'Generate outline'**
  String get cmdAiGenerateOutline;

  /// No description provided for @cmdAiProofreadDocument.
  ///
  /// In en, this message translates to:
  /// **'Proofread document'**
  String get cmdAiProofreadDocument;

  /// No description provided for @cmdAiPreviewReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace with AI result'**
  String get cmdAiPreviewReplace;

  /// No description provided for @cmdAiPreviewInsertBelow.
  ///
  /// In en, this message translates to:
  /// **'Insert AI result below'**
  String get cmdAiPreviewInsertBelow;

  /// No description provided for @cmdAiPreviewRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get cmdAiPreviewRetry;

  /// No description provided for @cmdAiPreviewRefine.
  ///
  /// In en, this message translates to:
  /// **'Refine AI result'**
  String get cmdAiPreviewRefine;

  /// No description provided for @cmdAiPreviewDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard AI result'**
  String get cmdAiPreviewDiscard;

  /// No description provided for @cmdAiSetApplyMode.
  ///
  /// In en, this message translates to:
  /// **'AI apply mode'**
  String get cmdAiSetApplyMode;

  /// No description provided for @cmdAiAcceptIssue.
  ///
  /// In en, this message translates to:
  /// **'Accept proofreading issue'**
  String get cmdAiAcceptIssue;

  /// No description provided for @cmdAiDismissIssue.
  ///
  /// In en, this message translates to:
  /// **'Dismiss proofreading issue'**
  String get cmdAiDismissIssue;

  /// No description provided for @cmdAiAcceptAllIssues.
  ///
  /// In en, this message translates to:
  /// **'Accept all proofreading issues'**
  String get cmdAiAcceptAllIssues;

  /// No description provided for @cmdOfflineSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate offline'**
  String get cmdOfflineSimulate;

  /// No description provided for @cmdCommentsAddDocumentComment.
  ///
  /// In en, this message translates to:
  /// **'Comment on the whole document'**
  String get cmdCommentsAddDocumentComment;

  /// No description provided for @cmdCommentsActivate.
  ///
  /// In en, this message translates to:
  /// **'Open comment'**
  String get cmdCommentsActivate;

  /// No description provided for @cmdCommentsReattach.
  ///
  /// In en, this message translates to:
  /// **'Re-attach comment to selection'**
  String get cmdCommentsReattach;

  /// No description provided for @cmdCommentsDeleteThread.
  ///
  /// In en, this message translates to:
  /// **'Delete comment thread'**
  String get cmdCommentsDeleteThread;

  /// No description provided for @cmdSuggestionsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept suggestion'**
  String get cmdSuggestionsAccept;

  /// No description provided for @cmdSuggestionsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject suggestion'**
  String get cmdSuggestionsReject;

  /// No description provided for @cmdModeSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggesting'**
  String get cmdModeSuggest;

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

  /// No description provided for @cmdHistoryOpen.
  ///
  /// In en, this message translates to:
  /// **'See version history'**
  String get cmdHistoryOpen;

  /// No description provided for @cmdHistoryNameCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Name current version'**
  String get cmdHistoryNameCurrentVersion;

  /// No description provided for @cmdHistoryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get cmdHistoryRestore;

  /// No description provided for @cmdHistoryCopyVersion.
  ///
  /// In en, this message translates to:
  /// **'Make a copy of this version'**
  String get cmdHistoryCopyVersion;

  /// No description provided for @cmdSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Reconnect now'**
  String get cmdSyncRetry;

  /// No description provided for @cmdInsertEmojiDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick an emoji to insert at the cursor'**
  String get cmdInsertEmojiDescription;

  /// No description provided for @cmdImagePreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the image in a full-screen viewer'**
  String get cmdImagePreviewDescription;

  /// No description provided for @cmdTableEditCellDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit a table cell in place'**
  String get cmdTableEditCellDescription;

  /// No description provided for @cmdInsertFromFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Insert a Markdown, text, HTML, Word, OpenDocument or RTF file at the cursor'**
  String get cmdInsertFromFileDescription;

  /// No description provided for @cmdInsertImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload images from your computer'**
  String get cmdInsertImageDescription;

  /// No description provided for @cmdInsertTableDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Insert a table of a custom size'**
  String get cmdInsertTableDialogDescription;

  /// No description provided for @cmdThemeOpenEditorDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the theme editor for the document theme'**
  String get cmdThemeOpenEditorDescription;

  /// No description provided for @cmdThemeDuplicateDescription.
  ///
  /// In en, this message translates to:
  /// **'Copy a theme into my themes'**
  String get cmdThemeDuplicateDescription;

  /// No description provided for @cmdAiInlineDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens the inline AI prompt at the caret (empty paragraph) or for the selection.'**
  String get cmdAiInlineDescription;

  /// No description provided for @cmdAiContinueDescription.
  ///
  /// In en, this message translates to:
  /// **'Continues the text at the caret (ghost text; Tab accepts).'**
  String get cmdAiContinueDescription;

  /// No description provided for @undoInsertEmoji.
  ///
  /// In en, this message translates to:
  /// **'Insert emoji'**
  String get undoInsertEmoji;

  /// No description provided for @undoCorrectSpelling.
  ///
  /// In en, this message translates to:
  /// **'Correct spelling'**
  String get undoCorrectSpelling;

  /// No description provided for @reasonDownloadsDisabled.
  ///
  /// In en, this message translates to:
  /// **'The owner turned off downloads'**
  String get reasonDownloadsDisabled;

  /// No description provided for @cmdModeEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing mode'**
  String get cmdModeEditing;

  /// No description provided for @cmdModeSuggesting.
  ///
  /// In en, this message translates to:
  /// **'Suggesting mode'**
  String get cmdModeSuggesting;

  /// No description provided for @cmdModeViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing mode'**
  String get cmdModeViewing;

  /// No description provided for @reasonNeedCommentAccess.
  ///
  /// In en, this message translates to:
  /// **'You need comment access'**
  String get reasonNeedCommentAccess;

  /// No description provided for @reasonTablesNotInSuggesting.
  ///
  /// In en, this message translates to:
  /// **'Tables can\'t be edited in Suggesting mode'**
  String get reasonTablesNotInSuggesting;

  /// No description provided for @undoSwitchToPages.
  ///
  /// In en, this message translates to:
  /// **'Switch to Pages'**
  String get undoSwitchToPages;

  /// No description provided for @undoSwitchToPageless.
  ///
  /// In en, this message translates to:
  /// **'Switch to Pageless'**
  String get undoSwitchToPageless;

  /// No description provided for @cmdPrefsSetMarkdownShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Markdown shortcuts'**
  String get cmdPrefsSetMarkdownShortcuts;

  /// No description provided for @cmdPrefsSetSmartTypography.
  ///
  /// In en, this message translates to:
  /// **'Smart quotes and dashes'**
  String get cmdPrefsSetSmartTypography;

  /// No description provided for @cmdPrefsSetAutoPair.
  ///
  /// In en, this message translates to:
  /// **'Auto-pair brackets'**
  String get cmdPrefsSetAutoPair;

  /// No description provided for @cmdPrefsSetAutolink.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect links'**
  String get cmdPrefsSetAutolink;

  /// No description provided for @cmdPrefsSetCopyAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy plain text as Markdown'**
  String get cmdPrefsSetCopyAsMarkdown;

  /// No description provided for @cmdPrefsSetSelectionToolbar.
  ///
  /// In en, this message translates to:
  /// **'Show toolbar on selection'**
  String get cmdPrefsSetSelectionToolbar;

  /// No description provided for @cmdThemeSetPreviewSource.
  ///
  /// In en, this message translates to:
  /// **'Preview source'**
  String get cmdThemeSetPreviewSource;

  /// No description provided for @cmdThemeSetPreviewVariant.
  ///
  /// In en, this message translates to:
  /// **'Preview variant'**
  String get cmdThemeSetPreviewVariant;

  /// No description provided for @cmdThemeSetPreviewLayout.
  ///
  /// In en, this message translates to:
  /// **'Preview layout'**
  String get cmdThemeSetPreviewLayout;

  /// No description provided for @cmdThemeExportCss.
  ///
  /// In en, this message translates to:
  /// **'Export theme as CSS…'**
  String get cmdThemeExportCss;

  /// No description provided for @cmdThemeExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export theme as JSON…'**
  String get cmdThemeExportJson;

  /// Default name of a new document.
  ///
  /// In en, this message translates to:
  /// **'Untitled document'**
  String get untitledDocument;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Document themes'**
  String get settingsDocumentThemes;

  /// Write settings section (Write 05 §13.3).
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsWriteEditor;

  /// Write settings section (Write 05 §13.3).
  ///
  /// In en, this message translates to:
  /// **'Page & export'**
  String get settingsWritePage;

  /// Write settings section (Write 05 §13.3).
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get settingsWriteSpelling;

  /// No description provided for @settingsWriteTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get settingsWriteTyping;

  /// No description provided for @settingsWriteDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsWriteDisplay;

  /// No description provided for @settingsWriteDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default mode for shared documents'**
  String get settingsWriteDefaultMode;

  /// No description provided for @settingsWriteDefaultModeHint.
  ///
  /// In en, this message translates to:
  /// **'How documents you can edit open when someone shares them with you.'**
  String get settingsWriteDefaultModeHint;

  /// No description provided for @settingsWritePageGroup.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get settingsWritePageGroup;

  /// No description provided for @settingsWriteDefaultLayout.
  ///
  /// In en, this message translates to:
  /// **'Default layout'**
  String get settingsWriteDefaultLayout;

  /// No description provided for @settingsWriteDefaultPageSetup.
  ///
  /// In en, this message translates to:
  /// **'Default page setup'**
  String get settingsWriteDefaultPageSetup;

  /// No description provided for @settingsWritePageSetupSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved with File › Page setup › Set as default.'**
  String get settingsWritePageSetupSaved;

  /// No description provided for @settingsWritePageSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Save one with File › Page setup › Set as default in a document.'**
  String get settingsWritePageSetupHint;

  /// No description provided for @settingsWriteResetPageSetup.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsWriteResetPageSetup;

  /// No description provided for @settingsWriteExportGroup.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsWriteExportGroup;

  /// No description provided for @settingsWriteSpellingGroup.
  ///
  /// In en, this message translates to:
  /// **'Spell check'**
  String get settingsWriteSpellingGroup;

  /// No description provided for @settingsWriteDictionary.
  ///
  /// In en, this message translates to:
  /// **'Personal dictionary'**
  String get settingsWriteDictionary;

  /// No description provided for @settingsWriteDictionaryHint.
  ///
  /// In en, this message translates to:
  /// **'Words you add from the spelling menu are never marked as misspelled.'**
  String get settingsWriteDictionaryHint;

  /// No description provided for @settingsWriteDictionaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No words yet.'**
  String get settingsWriteDictionaryEmpty;

  /// Screen reader label of the remove button of a personal dictionary word.
  ///
  /// In en, this message translates to:
  /// **'Remove {word}'**
  String settingsWriteDictionaryRemove(String word);

  /// No description provided for @cmdPrefsSetDefaultLayout.
  ///
  /// In en, this message translates to:
  /// **'Default layout of new documents'**
  String get cmdPrefsSetDefaultLayout;

  /// No description provided for @cmdPrefsSetExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Default export format'**
  String get cmdPrefsSetExportFormat;

  /// No description provided for @cmdPrefsResetPageSetup.
  ///
  /// In en, this message translates to:
  /// **'Reset default page setup'**
  String get cmdPrefsResetPageSetup;

  /// No description provided for @cmdPrefsRemoveDictionaryWord.
  ///
  /// In en, this message translates to:
  /// **'Remove word from personal dictionary'**
  String get cmdPrefsRemoveDictionaryWord;

  /// No description provided for @cmdCommentsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous comment'**
  String get cmdCommentsPrevious;

  /// No description provided for @cmdCommentsNext.
  ///
  /// In en, this message translates to:
  /// **'Next comment'**
  String get cmdCommentsNext;

  /// No description provided for @cmdSuggestionsAcceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept all suggestions'**
  String get cmdSuggestionsAcceptAll;

  /// No description provided for @cmdSuggestionsRejectAll.
  ///
  /// In en, this message translates to:
  /// **'Reject all suggestions'**
  String get cmdSuggestionsRejectAll;

  /// No description provided for @cmdSuggestionsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous suggestion'**
  String get cmdSuggestionsPrevious;

  /// No description provided for @cmdSuggestionsNext.
  ///
  /// In en, this message translates to:
  /// **'Next suggestion'**
  String get cmdSuggestionsNext;

  /// No description provided for @commandToastNothingToDo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do'**
  String get commandToastNothingToDo;

  /// No description provided for @commandToastNoCollaboratorCursor.
  ///
  /// In en, this message translates to:
  /// **'No cursor for this collaborator'**
  String get commandToastNoCollaboratorCursor;

  /// No description provided for @commandToastNeedEditAccessToEdit.
  ///
  /// In en, this message translates to:
  /// **'You need edit access to edit directly'**
  String get commandToastNeedEditAccessToEdit;

  /// No description provided for @commandToastNeedCommentAccessToSuggest.
  ///
  /// In en, this message translates to:
  /// **'You need comment access to suggest'**
  String get commandToastNeedCommentAccessToSuggest;

  /// No description provided for @commandToastNoTableSelected.
  ///
  /// In en, this message translates to:
  /// **'No table selected'**
  String get commandToastNoTableSelected;

  /// Toast after inserting a file into the document; name is the file name.
  ///
  /// In en, this message translates to:
  /// **'Inserted “{name}”'**
  String commandToastInsertedFile(String name);

  /// No description provided for @commandToastNoMatchToReplace.
  ///
  /// In en, this message translates to:
  /// **'No match to replace'**
  String get commandToastNoMatchToReplace;

  /// No description provided for @commandToastNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get commandToastNoMatches;

  /// No description provided for @commandToastReplacedOccurrences.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Replaced 1 occurrence} other{Replaced {count} occurrences}}'**
  String commandToastReplacedOccurrences(int count);

  /// No description provided for @commandToastNoSuchHeading.
  ///
  /// In en, this message translates to:
  /// **'No such heading'**
  String get commandToastNoSuchHeading;

  /// No description provided for @commandToastNoLinkHere.
  ///
  /// In en, this message translates to:
  /// **'No link here'**
  String get commandToastNoLinkHere;

  /// No description provided for @commandToastLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get commandToastLinkCopied;

  /// No description provided for @commandToastNoImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get commandToastNoImageSelected;

  /// No description provided for @commandToastImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The image isn’t available'**
  String get commandToastImageUnavailable;

  /// No description provided for @commandToastTableCopiedAsTsv.
  ///
  /// In en, this message translates to:
  /// **'Table copied as tab-separated values'**
  String get commandToastTableCopiedAsTsv;

  /// No description provided for @commandToastNoCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'No code block'**
  String get commandToastNoCodeBlock;

  /// No description provided for @commandToastCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get commandToastCodeCopied;

  /// No description provided for @commandToastImagesCannotBeInserted.
  ///
  /// In en, this message translates to:
  /// **'Images can’t be inserted here'**
  String get commandToastImagesCannotBeInserted;

  /// No description provided for @commandToastPlaceCursorFirst.
  ///
  /// In en, this message translates to:
  /// **'Place the cursor first'**
  String get commandToastPlaceCursorFirst;

  /// No description provided for @commandToastDefaultTheme.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is now your default theme'**
  String commandToastDefaultTheme(String name);

  /// No description provided for @commandDialogOpenExternalLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Open external link?'**
  String get commandDialogOpenExternalLinkTitle;

  /// Confirm button: open the external link in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commandDialogOpenExternalLinkConfirm;

  /// Root folder name of the drive, shown as the document location.
  ///
  /// In en, this message translates to:
  /// **'My Drive'**
  String get commandDialogMyDrive;

  /// No description provided for @undoInsertFile.
  ///
  /// In en, this message translates to:
  /// **'Insert file'**
  String get undoInsertFile;

  /// Undo label for inserting the @ mention trigger.
  ///
  /// In en, this message translates to:
  /// **'Mention'**
  String get undoMention;

  /// No description provided for @undoInsertImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Insert image} other{Insert images}}'**
  String undoInsertImages(int count);

  /// No description provided for @undoChangePageSetup.
  ///
  /// In en, this message translates to:
  /// **'Change page setup'**
  String get undoChangePageSetup;

  /// No description provided for @undoChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get undoChangeLanguage;

  /// No description provided for @undoChangeFrontMatter.
  ///
  /// In en, this message translates to:
  /// **'Change front matter'**
  String get undoChangeFrontMatter;

  /// No description provided for @undoUseDefaultTheme.
  ///
  /// In en, this message translates to:
  /// **'Use my default theme'**
  String get undoUseDefaultTheme;

  /// No description provided for @undoChangeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get undoChangeTheme;

  /// No description provided for @commandReasonOpenThemeEditorFirst.
  ///
  /// In en, this message translates to:
  /// **'Open the theme editor first'**
  String get commandReasonOpenThemeEditorFirst;

  /// No description provided for @commandReasonBuiltinThemeReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Built-in themes can’t be changed'**
  String get commandReasonBuiltinThemeReadOnly;

  /// No description provided for @commandReasonThemeReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This theme is read-only'**
  String get commandReasonThemeReadOnly;

  /// No description provided for @commandToastFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commandToastFailed;

  /// No description provided for @commandToastOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get commandToastOffline;

  /// No description provided for @commandToastNoTheme.
  ///
  /// In en, this message translates to:
  /// **'No theme selected'**
  String get commandToastNoTheme;

  /// No description provided for @commandToastThemeChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'The theme was changed elsewhere'**
  String get commandToastThemeChangedElsewhere;

  /// No description provided for @commandToastBuiltinThemeCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Built-in themes can’t be deleted'**
  String get commandToastBuiltinThemeCannotBeDeleted;

  /// Toast after duplicating a theme; name is the new theme's name.
  ///
  /// In en, this message translates to:
  /// **'Copied to “{name}”'**
  String commandToastThemeCopied(String name);

  /// No description provided for @commandToastThemeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Theme deleted'**
  String get commandToastThemeDeleted;

  /// No description provided for @commandToastDefaultThemeUnnamed.
  ///
  /// In en, this message translates to:
  /// **'The theme is now your default theme'**
  String get commandToastDefaultThemeUnnamed;

  /// No description provided for @commandToastThemeApplied.
  ///
  /// In en, this message translates to:
  /// **'Theme applied to the document'**
  String get commandToastThemeApplied;

  /// title is the document's title.
  ///
  /// In en, this message translates to:
  /// **'Theme applied to “{title}”'**
  String commandToastThemeAppliedTo(String title);

  /// Default name of a newly created theme.
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get commandDialogNewThemeName;

  /// Name of a theme created from another theme.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String commandDialogThemeCopyName(String name);

  /// No description provided for @commandDialogDeleteThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete theme?'**
  String get commandDialogDeleteThemeTitle;

  /// No description provided for @commandDialogDeleteThemeBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One of your documents uses this theme. It keeps looking the same until you choose another theme.} other{{count} of your documents use this theme. They keep looking the same until you choose another theme.}}'**
  String commandDialogDeleteThemeBody(int count);

  /// No description provided for @commandDialogRevertThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revert changes?'**
  String get commandDialogRevertThemeTitle;

  /// No description provided for @commandDialogRevertThemeBody.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes to this theme will be lost.'**
  String get commandDialogRevertThemeBody;

  /// No description provided for @commandDialogRevertThemeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get commandDialogRevertThemeConfirm;

  /// No description provided for @commandDialogImportThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a theme'**
  String get commandDialogImportThemeTitle;

  /// Title of the system save dialog.
  ///
  /// In en, this message translates to:
  /// **'Save {fileName}'**
  String commandDialogSaveFileTitle(String fileName);

  /// No description provided for @cmdAiRewriteSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Rewrites the selection (improve, fixGrammar, shorter, longer, tone, translate, custom) into a preview; explain and summarize answer in the panel. Pass a range (start, length) to target Delta offsets.'**
  String get cmdAiRewriteSelectionDescription;

  /// No description provided for @commandToastAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI is not available'**
  String get commandToastAiUnavailable;

  /// No description provided for @commandToastReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You can’t change this document'**
  String get commandToastReadOnly;

  /// No description provided for @commandToastNothingToReplace.
  ///
  /// In en, this message translates to:
  /// **'Nothing to replace'**
  String get commandToastNothingToReplace;

  /// No description provided for @commandToastNothingToInsert.
  ///
  /// In en, this message translates to:
  /// **'Nothing to insert'**
  String get commandToastNothingToInsert;

  /// No description provided for @commandToastTextChanged.
  ///
  /// In en, this message translates to:
  /// **'The text has changed'**
  String get commandToastTextChanged;

  /// No description provided for @commandToastNothingToAccept.
  ///
  /// In en, this message translates to:
  /// **'Nothing to accept'**
  String get commandToastNothingToAccept;

  /// No description provided for @commandToastNoSpellingErrors.
  ///
  /// In en, this message translates to:
  /// **'No spelling errors'**
  String get commandToastNoSpellingErrors;

  /// No description provided for @commandToastPersonalDictionaryFull.
  ///
  /// In en, this message translates to:
  /// **'Your personal dictionary is full ({count} words)'**
  String commandToastPersonalDictionaryFull(int count);

  /// No description provided for @commandMenuNoSpellingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No spelling suggestions'**
  String get commandMenuNoSpellingSuggestions;

  /// Context menu item; word is the misspelled word.
  ///
  /// In en, this message translates to:
  /// **'Add “{word}” to dictionary'**
  String commandMenuAddWordToDictionary(String word);

  /// No description provided for @commandToastUnsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Can’t insert this file type'**
  String get commandToastUnsupportedFileType;

  /// name is the dropped file's name.
  ///
  /// In en, this message translates to:
  /// **'Insert contents of “{name}” here?'**
  String commandDialogInsertFileContentsTitle(String name);

  /// No description provided for @commandToastCouldNotInsertFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t insert “{name}”'**
  String commandToastCouldNotInsertFile(String name);

  /// No description provided for @undoInsertSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'Insert special character'**
  String get undoInsertSpecialCharacter;

  /// No description provided for @undoInsertMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Insert Markdown'**
  String get undoInsertMarkdown;

  /// Submenu with clipboard formats (Markdown, plain text, HTML).
  ///
  /// In en, this message translates to:
  /// **'Copy as'**
  String get menuCopyAs;

  /// Item of the Copy as submenu.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get menuCopyAsMarkdown;

  /// Item of the Copy as submenu.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get menuCopyAsPlainText;

  /// Item of the Copy as submenu.
  ///
  /// In en, this message translates to:
  /// **'HTML'**
  String get menuCopyAsHtml;

  /// No description provided for @menuPageLayout.
  ///
  /// In en, this message translates to:
  /// **'Page layout'**
  String get menuPageLayout;

  /// Page layout option: paginated pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get menuLayoutPages;

  /// Page layout option: one continuous page.
  ///
  /// In en, this message translates to:
  /// **'Pageless'**
  String get menuLayoutPageless;

  /// View submenu for how suggested edits are shown.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get menuSuggestions;

  /// No description provided for @menuShowSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show suggestions'**
  String get menuShowSuggestions;

  /// View menu toggle that shows or hides the comment and suggestion cards next to the page.
  ///
  /// In en, this message translates to:
  /// **'Comments and suggestions'**
  String get menuShowComments;

  /// Preview the document as if all suggestions were accepted.
  ///
  /// In en, this message translates to:
  /// **'Preview accepted'**
  String get menuPreviewAccepted;

  /// Preview the document without any suggestions.
  ///
  /// In en, this message translates to:
  /// **'Preview original'**
  String get menuPreviewOriginal;

  /// No description provided for @menuZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get menuZoom;

  /// No description provided for @menuFitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit width'**
  String get menuFitWidth;

  /// No description provided for @menuFitPage.
  ///
  /// In en, this message translates to:
  /// **'Fit page'**
  String get menuFitPage;

  /// No description provided for @menuZoomReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to 100%'**
  String get menuZoomReset;

  /// No description provided for @menuSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get menuSpelling;

  /// Spelling submenu: jump to the next spelling error.
  ///
  /// In en, this message translates to:
  /// **'Next error'**
  String get menuNextError;

  /// Spelling submenu: underline misspelled words.
  ///
  /// In en, this message translates to:
  /// **'Underline errors'**
  String get menuUnderlineErrors;

  /// No description provided for @menuPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get menuPreferences;

  /// No description provided for @menuAllPreferences.
  ///
  /// In en, this message translates to:
  /// **'All preferences…'**
  String get menuAllPreferences;

  /// Insert menu / submenu title.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get menuInsert;

  /// Image submenu title.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get menuImage;

  /// No description provided for @menuImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload from computer…'**
  String get menuImageUpload;

  /// Insert an image from a web address.
  ///
  /// In en, this message translates to:
  /// **'By URL…'**
  String get menuImageByUrl;

  /// Table submenu title.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get menuTable;

  /// Accessible name of the rows × columns grid picker.
  ///
  /// In en, this message translates to:
  /// **'Table size'**
  String get menuTableSize;

  /// No description provided for @menuTableCustomSize.
  ///
  /// In en, this message translates to:
  /// **'Custom size…'**
  String get menuTableCustomSize;

  /// No description provided for @menuDividerLine.
  ///
  /// In en, this message translates to:
  /// **'Divider (horizontal line)'**
  String get menuDividerLine;

  /// No description provided for @menuLink.
  ///
  /// In en, this message translates to:
  /// **'Link…'**
  String get menuLink;

  /// Add a comment to the selection (verb).
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get menuComment;

  /// No description provided for @menuFromFile.
  ///
  /// In en, this message translates to:
  /// **'From file…'**
  String get menuFromFile;

  /// Format menu title.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get menuFormat;

  /// Format submenu with inline text styles.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get menuText;

  /// No description provided for @menuParagraphStyles.
  ///
  /// In en, this message translates to:
  /// **'Paragraph styles'**
  String get menuParagraphStyles;

  /// No description provided for @menuBulletsNumbering.
  ///
  /// In en, this message translates to:
  /// **'Bullets & numbering'**
  String get menuBulletsNumbering;

  /// No description provided for @menuToggleChecked.
  ///
  /// In en, this message translates to:
  /// **'Mark as done / not done'**
  String get menuToggleChecked;

  /// Format submenu title for links.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get menuLinkSubmenu;

  /// No description provided for @menuInsertOrEditLink.
  ///
  /// In en, this message translates to:
  /// **'Insert or edit link…'**
  String get menuInsertOrEditLink;

  /// No description provided for @menuEditCells.
  ///
  /// In en, this message translates to:
  /// **'Edit cells'**
  String get menuEditCells;

  /// Replace the selected image.
  ///
  /// In en, this message translates to:
  /// **'Replace…'**
  String get menuImageReplace;

  /// Download the selected image.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get menuImageDownload;

  /// Format submenu title for code blocks.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get menuCodeBlock;

  /// Document theme submenu / toolbar button.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get menuTheme;

  /// No description provided for @menuMoreThemes.
  ///
  /// In en, this message translates to:
  /// **'More themes…'**
  String get menuMoreThemes;

  /// Zoom level, e.g. 100%.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String screenZoomPercent(int percent);

  /// Editor mode name.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get screenModeEditing;

  /// Editor mode name.
  ///
  /// In en, this message translates to:
  /// **'Suggesting'**
  String get screenModeSuggesting;

  /// Editor mode name.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get screenModeViewing;

  /// No description provided for @screenModeEditingDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit document directly'**
  String get screenModeEditingDescription;

  /// No description provided for @screenModeSuggestingDescription.
  ///
  /// In en, this message translates to:
  /// **'Edits become suggestions'**
  String get screenModeSuggestingDescription;

  /// No description provided for @screenModeViewingDescription.
  ///
  /// In en, this message translates to:
  /// **'Read or print final document'**
  String get screenModeViewingDescription;

  /// Undo button tooltip with the name of the change to undo.
  ///
  /// In en, this message translates to:
  /// **'Undo {action}'**
  String toolbarUndo(String action);

  /// No description provided for @toolbarRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get toolbarRedo;

  /// Redo button tooltip with the name of the change to redo.
  ///
  /// In en, this message translates to:
  /// **'Redo {action}'**
  String toolbarRedoAction(String action);

  /// No description provided for @toolbarZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get toolbarZoom;

  /// No description provided for @toolbarLabel.
  ///
  /// In en, this message translates to:
  /// **'Formatting toolbar'**
  String get toolbarLabel;

  /// Paragraph style dropdown tooltip.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get toolbarStyles;

  /// No description provided for @toolbarInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get toolbarInsertImage;

  /// No description provided for @toolbarImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload from computer'**
  String get toolbarImageUpload;

  /// No description provided for @toolbarInsertTable.
  ///
  /// In en, this message translates to:
  /// **'Insert table'**
  String get toolbarInsertTable;

  /// No description provided for @toolbarEditLink.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get toolbarEditLink;

  /// Tooltip of the editing / suggesting / viewing switcher.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get toolbarMode;

  /// No description provided for @selectionToolbarLabel.
  ///
  /// In en, this message translates to:
  /// **'Selection toolbar'**
  String get selectionToolbarLabel;

  /// Short heading button text, e.g. H1.
  ///
  /// In en, this message translates to:
  /// **'H{level}'**
  String selectionToolbarHeadingShort(int level);

  /// No description provided for @selectionToolbarHide.
  ///
  /// In en, this message translates to:
  /// **'Hide this toolbar'**
  String get selectionToolbarHide;

  /// No description provided for @docMenuSearchDocument.
  ///
  /// In en, this message translates to:
  /// **'Search document'**
  String get docMenuSearchDocument;

  /// No description provided for @docMenuSearchDocumentFor.
  ///
  /// In en, this message translates to:
  /// **'Search document for “{query}”'**
  String docMenuSearchDocumentFor(String query);

  /// No description provided for @docMenuDeleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get docMenuDeleteImage;

  /// No description provided for @docMenuMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get docMenuMoveUp;

  /// No description provided for @docMenuMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get docMenuMoveDown;

  /// No description provided for @docMenuCopyMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy (Markdown)'**
  String get docMenuCopyMarkdown;

  /// Programming language of a code block.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get docMenuLanguage;

  /// Submenu to change the block type.
  ///
  /// In en, this message translates to:
  /// **'Turn into'**
  String get docMenuTurnInto;

  /// No description provided for @docMenuImageByUrl.
  ///
  /// In en, this message translates to:
  /// **'Image by URL…'**
  String get docMenuImageByUrl;

  /// Code block language: no syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get docMenuPlainText;

  /// No description provided for @screenPanelOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get screenPanelOutline;

  /// No description provided for @screenPanelFind.
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get screenPanelFind;

  /// No description provided for @screenOfflineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This document isn\'t available offline'**
  String get screenOfflineUnavailable;

  /// No description provided for @screenOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong opening this document'**
  String get screenOpenFailed;

  /// No description provided for @screenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get screenTryAgain;

  /// No description provided for @screenGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get screenGoBack;

  /// No description provided for @screenEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Type / for commands, @ to mention, or just start writing'**
  String get screenEditorHint;

  /// No description provided for @screenStatusWords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String screenStatusWords(int count);

  /// Words in the selection of the document total.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {count, plural, =1{1 word} other{{count} words}}'**
  String screenStatusSelectedOfWords(int selected, int count);

  /// Status bar: word count label followed by the page count.
  ///
  /// In en, this message translates to:
  /// **'{words} · {count, plural, =1{1 page} other{{count} pages}}'**
  String screenStatusWordsAndPages(String words, int count);

  /// Word count tooltip: characters and reading time.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}} · {minutes, plural, =0{< 1 min read} other{{minutes} min read}}'**
  String screenStatusCharactersReading(int count, int minutes);

  /// Accessibility hint of the status bar word count.
  ///
  /// In en, this message translates to:
  /// **'Open word count'**
  String get screenWordCountHint;

  /// No description provided for @screenUnknownFormat.
  ///
  /// In en, this message translates to:
  /// **'Unknown format “{format}”'**
  String screenUnknownFormat(String format);

  /// Toast while exporting, e.g. Preparing DOCX…
  ///
  /// In en, this message translates to:
  /// **'Preparing {format}…'**
  String screenPreparingExport(String format);

  /// No description provided for @screenExported.
  ///
  /// In en, this message translates to:
  /// **'Exported “{fileName}”'**
  String screenExported(String fileName);

  /// No description provided for @screenExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get screenExportFailed;

  /// No description provided for @screenWordsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word selected} other{{count} words selected}}'**
  String screenWordsSelected(int count);

  /// Accessible name of the area outside a popover that closes it.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get popoverDismiss;

  /// Document language when none is set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get docDialogLanguageNotSet;

  /// No description provided for @docDialogLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Document language'**
  String get docDialogLanguageTitle;

  /// No description provided for @docDialogLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for spelling, hyphenation in exports and screen readers.'**
  String get docDialogLanguageDescription;

  /// No description provided for @docDialogLanguageSearch.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get docDialogLanguageSearch;

  /// No description provided for @docDialogDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get docDialogDetailsTitle;

  /// No description provided for @docDialogFrontMatterFences.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: remove the --- fences'**
  String docDialogFrontMatterFences(int line);

  /// No description provided for @docDialogFrontMatterExpected.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: expected \"key: value\"'**
  String docDialogFrontMatterExpected(int line);

  /// File size in bytes.
  ///
  /// In en, this message translates to:
  /// **'{count} B'**
  String docDialogSizeBytes(int count);

  /// File size in kilobytes; size is preformatted.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String docDialogSizeKilobytes(String size);

  /// File size in megabytes; size is preformatted.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String docDialogSizeMegabytes(String size);

  /// No description provided for @docDialogRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get docDialogRowTitle;

  /// No description provided for @docDialogRowLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get docDialogRowLocation;

  /// No description provided for @docDialogRowOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get docDialogRowOwner;

  /// No description provided for @docDialogRowCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get docDialogRowCreated;

  /// No description provided for @docDialogRowModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get docDialogRowModified;

  /// No description provided for @docDialogRowSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get docDialogRowSize;

  /// No description provided for @docDialogRowWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get docDialogRowWords;

  /// No description provided for @docDialogRowLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get docDialogRowLanguage;

  /// No description provided for @docDialogRowTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get docDialogRowTheme;

  /// No description provided for @docDialogRowRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get docDialogRowRevision;

  /// Modified date and the person who modified the document.
  ///
  /// In en, this message translates to:
  /// **'{date} by {name}'**
  String docDialogModifiedBy(String date, String name);

  /// No description provided for @docDialogFrontMatterLabel.
  ///
  /// In en, this message translates to:
  /// **'Front matter (YAML)'**
  String get docDialogFrontMatterLabel;

  /// Example YAML front matter; keep the keys "title" and "tags".
  ///
  /// In en, this message translates to:
  /// **'title: My document\ntags: [notes]'**
  String get docDialogFrontMatterPlaceholder;

  /// No description provided for @docDialogGoToHeadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to heading'**
  String get docDialogGoToHeadingTitle;

  /// No description provided for @docDialogSearchHeadings.
  ///
  /// In en, this message translates to:
  /// **'Search headings'**
  String get docDialogSearchHeadings;

  /// No description provided for @docDialogNoHeadings.
  ///
  /// In en, this message translates to:
  /// **'No headings'**
  String get docDialogNoHeadings;

  /// No description provided for @docDialogUntitledHeading.
  ///
  /// In en, this message translates to:
  /// **'Untitled heading'**
  String get docDialogUntitledHeading;

  /// No description provided for @docDialogGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Markdown & formatting'**
  String get docDialogGuideTitle;

  /// No description provided for @docDialogGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'Wonky Write documents are Markdown. Type these shortcuts and they turn into formatting as you write.'**
  String get docDialogGuideDescription;

  /// No description provided for @docDialogGuideGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get docDialogGuideGotIt;

  /// Markdown syntax sample: keep the # characters.
  ///
  /// In en, this message translates to:
  /// **'# Heading 1 … ###### Heading 6'**
  String get docDialogGuideSyntaxHeadings;

  /// No description provided for @docDialogGuideHeadings.
  ///
  /// In en, this message translates to:
  /// **'Headings (type at the start of a line)'**
  String get docDialogGuideHeadings;

  /// Markdown syntax sample: keep the ** and __ markers.
  ///
  /// In en, this message translates to:
  /// **'**bold** or __bold__'**
  String get docDialogGuideSyntaxBold;

  /// No description provided for @docDialogGuideBold.
  ///
  /// In en, this message translates to:
  /// **'Bold (⌘B / Ctrl+B)'**
  String get docDialogGuideBold;

  /// Markdown syntax sample: keep the * and _ markers.
  ///
  /// In en, this message translates to:
  /// **'*italic* or _italic_'**
  String get docDialogGuideSyntaxItalic;

  /// No description provided for @docDialogGuideItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic (⌘I / Ctrl+I)'**
  String get docDialogGuideItalic;

  /// Markdown syntax sample: keep the ~~ markers.
  ///
  /// In en, this message translates to:
  /// **'~~strikethrough~~'**
  String get docDialogGuideSyntaxStrikethrough;

  /// No description provided for @docDialogGuideStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough (⌘⇧X / Ctrl+Shift+X)'**
  String get docDialogGuideStrikethrough;

  /// Markdown syntax sample: keep the backticks.
  ///
  /// In en, this message translates to:
  /// **'`code`'**
  String get docDialogGuideSyntaxCode;

  /// No description provided for @docDialogGuideCode.
  ///
  /// In en, this message translates to:
  /// **'Inline code (⌘E / Ctrl+E)'**
  String get docDialogGuideCode;

  /// Markdown syntax sample: keep the brackets and parentheses.
  ///
  /// In en, this message translates to:
  /// **'[text](https://…)'**
  String get docDialogGuideSyntaxLink;

  /// No description provided for @docDialogGuideLink.
  ///
  /// In en, this message translates to:
  /// **'Link (⌘K / Ctrl+K)'**
  String get docDialogGuideLink;

  /// Markdown syntax sample: keep the - and * markers.
  ///
  /// In en, this message translates to:
  /// **'- item  or  * item'**
  String get docDialogGuideSyntaxBullets;

  /// No description provided for @docDialogGuideBullets.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get docDialogGuideBullets;

  /// Markdown syntax sample: keep "1.".
  ///
  /// In en, this message translates to:
  /// **'1. item'**
  String get docDialogGuideSyntaxNumbered;

  /// No description provided for @docDialogGuideNumbered.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get docDialogGuideNumbered;

  /// Markdown syntax sample: keep [ ] and [x].
  ///
  /// In en, this message translates to:
  /// **'[ ] task  or  [x] done'**
  String get docDialogGuideSyntaxChecklist;

  /// No description provided for @docDialogGuideChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get docDialogGuideChecklist;

  /// Markdown syntax sample: keep the > marker.
  ///
  /// In en, this message translates to:
  /// **'> quote'**
  String get docDialogGuideSyntaxQuote;

  /// No description provided for @docDialogGuideQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get docDialogGuideQuote;

  /// Markdown syntax sample: keep the three backticks.
  ///
  /// In en, this message translates to:
  /// **'``` + space'**
  String get docDialogGuideSyntaxCodeBlock;

  /// No description provided for @docDialogGuideCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get docDialogGuideCodeBlock;

  /// No description provided for @docDialogGuideDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get docDialogGuideDivider;

  /// No description provided for @docDialogGuideCommandMenu.
  ///
  /// In en, this message translates to:
  /// **'Command menu: insert tables, images and more'**
  String get docDialogGuideCommandMenu;

  /// No description provided for @docDialogGuideMention.
  ///
  /// In en, this message translates to:
  /// **'Mention a person'**
  String get docDialogGuideMention;

  /// No description provided for @docDialogGuideFootnote.
  ///
  /// In en, this message translates to:
  /// **'Underline and text colors are not part of Markdown — use bold or italic, or change how emphasis looks with a theme.'**
  String get docDialogGuideFootnote;

  /// No description provided for @pageSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Page setup'**
  String get pageSetupTitle;

  /// No description provided for @pageSetupReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You need edit access to change the page setup.'**
  String get pageSetupReadOnly;

  /// No description provided for @pageSetupSetAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get pageSetupSetAsDefault;

  /// No description provided for @pageSetupTabPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageSetupTabPage;

  /// No description provided for @pageSetupTabHeaderFooter.
  ///
  /// In en, this message translates to:
  /// **'Header & footer'**
  String get pageSetupTabHeaderFooter;

  /// No description provided for @pageSetupLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get pageSetupLayout;

  /// Page layout mode: paginated.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pageSetupPages;

  /// Page layout mode: one continuous column.
  ///
  /// In en, this message translates to:
  /// **'Pageless'**
  String get pageSetupPageless;

  /// No description provided for @pageSetupPaperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get pageSetupPaperSize;

  /// No description provided for @pageSetupPaperLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter (8.5\" × 11\")'**
  String get pageSetupPaperLetter;

  /// No description provided for @pageSetupPaperLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal (8.5\" × 14\")'**
  String get pageSetupPaperLegal;

  /// No description provided for @pageSetupPaperTabloid.
  ///
  /// In en, this message translates to:
  /// **'Tabloid (11\" × 17\")'**
  String get pageSetupPaperTabloid;

  /// No description provided for @pageSetupPaperA3.
  ///
  /// In en, this message translates to:
  /// **'A3 (297 × 420 mm)'**
  String get pageSetupPaperA3;

  /// No description provided for @pageSetupPaperA4.
  ///
  /// In en, this message translates to:
  /// **'A4 (210 × 297 mm)'**
  String get pageSetupPaperA4;

  /// No description provided for @pageSetupPaperA5.
  ///
  /// In en, this message translates to:
  /// **'A5 (148 × 210 mm)'**
  String get pageSetupPaperA5;

  /// No description provided for @pageSetupPaperCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get pageSetupPaperCustom;

  /// No description provided for @pageSetupWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get pageSetupWidth;

  /// No description provided for @pageSetupHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get pageSetupHeight;

  /// No description provided for @pageSetupOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get pageSetupOrientation;

  /// No description provided for @pageSetupPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get pageSetupPortrait;

  /// No description provided for @pageSetupLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get pageSetupLandscape;

  /// No description provided for @pageSetupMargins.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get pageSetupMargins;

  /// No description provided for @pageSetupUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin units'**
  String get pageSetupUnitsLabel;

  /// Unit choice (display name).
  ///
  /// In en, this message translates to:
  /// **'inches'**
  String get pageSetupUnitInches;

  /// Unit choice (display name): millimeters.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get pageSetupUnitMillimeters;

  /// Unit suffix after a number: inches.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get pageSetupUnitInchesShort;

  /// Unit suffix after a number: millimeters.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get pageSetupUnitMillimetersShort;

  /// No description provided for @pageSetupUseThemeMargins.
  ///
  /// In en, this message translates to:
  /// **'Use the theme’s margins'**
  String get pageSetupUseThemeMargins;

  /// Top margin (field label).
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get pageSetupMarginTop;

  /// Bottom margin (field label).
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get pageSetupMarginBottom;

  /// Left margin (field label).
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get pageSetupMarginLeft;

  /// Right margin (field label).
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get pageSetupMarginRight;

  /// No description provided for @pageSetupMarginTopSemantic.
  ///
  /// In en, this message translates to:
  /// **'Top margin'**
  String get pageSetupMarginTopSemantic;

  /// No description provided for @pageSetupMarginBottomSemantic.
  ///
  /// In en, this message translates to:
  /// **'Bottom margin'**
  String get pageSetupMarginBottomSemantic;

  /// No description provided for @pageSetupMarginLeftSemantic.
  ///
  /// In en, this message translates to:
  /// **'Left margin'**
  String get pageSetupMarginLeftSemantic;

  /// No description provided for @pageSetupMarginRightSemantic.
  ///
  /// In en, this message translates to:
  /// **'Right margin'**
  String get pageSetupMarginRightSemantic;

  /// No description provided for @pageSetupPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets:'**
  String get pageSetupPresets;

  /// Margin preset.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get pageSetupPresetNormal;

  /// Margin preset.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get pageSetupPresetNarrow;

  /// Margin preset.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get pageSetupPresetWide;

  /// tokens is the literal list of header/footer tokens, not translated.
  ///
  /// In en, this message translates to:
  /// **'Tokens: {tokens}'**
  String pageSetupTokens(String tokens);

  /// No description provided for @pageSetupHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get pageSetupHeader;

  /// No description provided for @pageSetupFooter.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get pageSetupFooter;

  /// No description provided for @pageSetupDifferentFirstPage.
  ///
  /// In en, this message translates to:
  /// **'Different first page'**
  String get pageSetupDifferentFirstPage;

  /// No description provided for @pageSetupFirstPageHeader.
  ///
  /// In en, this message translates to:
  /// **'First page header'**
  String get pageSetupFirstPageHeader;

  /// No description provided for @pageSetupFirstPageFooter.
  ///
  /// In en, this message translates to:
  /// **'First page footer'**
  String get pageSetupFirstPageFooter;

  /// No description provided for @pageSetupShowPageNumbers.
  ///
  /// In en, this message translates to:
  /// **'Show page numbers'**
  String get pageSetupShowPageNumbers;

  /// Placeholder: left-aligned header/footer text.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get pageSetupFieldLeft;

  /// Placeholder: centered header/footer text.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get pageSetupFieldCenter;

  /// Placeholder: right-aligned header/footer text.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get pageSetupFieldRight;

  /// No description provided for @wordCountReadingTimeUnderOne.
  ///
  /// In en, this message translates to:
  /// **'< 1 min'**
  String get wordCountReadingTimeUnderOne;

  /// No description provided for @wordCountReadingTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String wordCountReadingTimeMinutes(int minutes);

  /// No description provided for @wordCountWords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCountWords(int count);

  /// Status bar: selected words of the total.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {count, plural, =1{1 word} other{{count} words}}'**
  String wordCountSelectionOfWords(int selected, int count);

  /// No description provided for @wordCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Word count'**
  String get wordCountTitle;

  /// No description provided for @wordCountPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get wordCountPages;

  /// No description provided for @wordCountRowWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get wordCountRowWords;

  /// No description provided for @wordCountCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get wordCountCharacters;

  /// No description provided for @wordCountCharactersNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Characters excluding spaces'**
  String get wordCountCharactersNoSpaces;

  /// No description provided for @wordCountParagraphs.
  ///
  /// In en, this message translates to:
  /// **'Paragraphs'**
  String get wordCountParagraphs;

  /// No description provided for @wordCountReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get wordCountReadingTime;

  /// No description provided for @wordCountColumnDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get wordCountColumnDocument;

  /// No description provided for @wordCountColumnSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get wordCountColumnSelection;

  /// No description provided for @wordCountShowWhileTyping.
  ///
  /// In en, this message translates to:
  /// **'Display word count while typing'**
  String get wordCountShowWhileTyping;

  /// No description provided for @tableEditorInsertTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert table'**
  String get tableEditorInsertTitle;

  /// No description provided for @tableEditorRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get tableEditorRows;

  /// No description provided for @tableEditorColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get tableEditorColumns;

  /// No description provided for @tableEditorIncludingHeader.
  ///
  /// In en, this message translates to:
  /// **'Including the header row'**
  String get tableEditorIncludingHeader;

  /// No description provided for @tableEditorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes to this table?'**
  String get tableEditorDiscardTitle;

  /// No description provided for @tableEditorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get tableEditorKeepEditing;

  /// No description provided for @tableEditorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get tableEditorDiscard;

  /// No description provided for @tableEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get tableEditorTitle;

  /// Table size: rows × columns.
  ///
  /// In en, this message translates to:
  /// **'{rows} × {columns}'**
  String tableEditorSize(int rows, int columns);

  /// No description provided for @tableEditorSizeSemantic.
  ///
  /// In en, this message translates to:
  /// **'{rows, plural, =1{1 row} other{{rows} rows}}, {columns, plural, =1{1 column} other{{columns} columns}}'**
  String tableEditorSizeSemantic(int rows, int columns);

  /// No description provided for @tableEditorInsertRowAbove.
  ///
  /// In en, this message translates to:
  /// **'Insert row above'**
  String get tableEditorInsertRowAbove;

  /// No description provided for @tableEditorInsertRowBelow.
  ///
  /// In en, this message translates to:
  /// **'Insert row below'**
  String get tableEditorInsertRowBelow;

  /// No description provided for @tableEditorInsertColumnLeft.
  ///
  /// In en, this message translates to:
  /// **'Insert column left'**
  String get tableEditorInsertColumnLeft;

  /// No description provided for @tableEditorInsertColumnRight.
  ///
  /// In en, this message translates to:
  /// **'Insert column right'**
  String get tableEditorInsertColumnRight;

  /// No description provided for @tableEditorDeleteRow.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get tableEditorDeleteRow;

  /// No description provided for @tableEditorDeleteColumn.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get tableEditorDeleteColumn;

  /// No description provided for @tableEditorMoveRowUp.
  ///
  /// In en, this message translates to:
  /// **'Move row up'**
  String get tableEditorMoveRowUp;

  /// No description provided for @tableEditorMoveRowDown.
  ///
  /// In en, this message translates to:
  /// **'Move row down'**
  String get tableEditorMoveRowDown;

  /// No description provided for @tableEditorMoveColumnLeft.
  ///
  /// In en, this message translates to:
  /// **'Move column left'**
  String get tableEditorMoveColumnLeft;

  /// No description provided for @tableEditorMoveColumnRight.
  ///
  /// In en, this message translates to:
  /// **'Move column right'**
  String get tableEditorMoveColumnRight;

  /// No description provided for @tableEditorAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align left'**
  String get tableEditorAlignLeft;

  /// No description provided for @tableEditorAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Align center'**
  String get tableEditorAlignCenter;

  /// No description provided for @tableEditorAlignRight.
  ///
  /// In en, this message translates to:
  /// **'Align right'**
  String get tableEditorAlignRight;

  /// No description provided for @tableEditorRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get tableEditorRedo;

  /// column is a column letter (A, B, …).
  ///
  /// In en, this message translates to:
  /// **'Select column {column}'**
  String tableEditorSelectColumn(String column);

  /// No description provided for @tableEditorSelectRow.
  ///
  /// In en, this message translates to:
  /// **'Select row {row}'**
  String tableEditorSelectRow(int row);

  /// Screen reader label of a cell; column is a letter.
  ///
  /// In en, this message translates to:
  /// **'Row {row}, column {column}'**
  String tableEditorCell(int row, String column);

  /// Screen reader label of a header cell; column is a letter.
  ///
  /// In en, this message translates to:
  /// **'Header, column {column}'**
  String tableEditorHeaderCell(String column);

  /// No description provided for @linkSuggestionHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading {level}'**
  String linkSuggestionHeading(int level);

  /// No description provided for @linkSuggestionDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get linkSuggestionDocument;

  /// No description provided for @linkText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get linkText;

  /// No description provided for @linkTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Text to display'**
  String get linkTextPlaceholder;

  /// No description provided for @linkUrl.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkUrl;

  /// No description provided for @linkUrlPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste a link or search'**
  String get linkUrlPlaceholder;

  /// No description provided for @linkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get linkRemove;

  /// No description provided for @imagePickMultipleTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert images'**
  String get imagePickMultipleTitle;

  /// No description provided for @imagePickSingleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get imagePickSingleTitle;

  /// No description provided for @imageRejectedSvg.
  ///
  /// In en, this message translates to:
  /// **'SVG images aren\'t supported'**
  String get imageRejectedSvg;

  /// No description provided for @imageRejectedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format'**
  String get imageRejectedFormat;

  /// No description provided for @imageRejectedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is larger than {megabytes} MB'**
  String imageRejectedTooLarge(int megabytes);

  /// No description provided for @imageUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert image by URL'**
  String get imageUrlTitle;

  /// No description provided for @imageUrlEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter an image URL'**
  String get imageUrlEmpty;

  /// No description provided for @imageUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get imageUrlInvalid;

  /// No description provided for @imageUrlNeedsHttps.
  ///
  /// In en, this message translates to:
  /// **'Images must use https:// URLs'**
  String get imageUrlNeedsHttps;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrlLabel;

  /// No description provided for @imageInsertAnyway.
  ///
  /// In en, this message translates to:
  /// **'Insert anyway'**
  String get imageInsertAnyway;

  /// No description provided for @imageAltText.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get imageAltText;

  /// No description provided for @imageAltPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the image'**
  String get imageAltPlaceholder;

  /// No description provided for @imageAltHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the image for people who can\'t see it'**
  String get imageAltHint;

  /// No description provided for @imageAltDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe the image for people who can\'t see it.'**
  String get imageAltDescription;

  /// No description provided for @imagePreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'A preview appears here'**
  String get imagePreviewEmpty;

  /// No description provided for @imagePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load image'**
  String get imagePreviewFailed;

  /// No description provided for @imagePreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Image preview'**
  String get imagePreviewSemantic;

  /// No description provided for @imageTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get imageTitleOptional;

  /// No description provided for @imageTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Shown as a tooltip'**
  String get imageTitlePlaceholder;

  /// Characters used of the maximum.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String imageAltCount(int count, int max);

  /// No description provided for @findNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get findNoResults;

  /// Active match of the total; total may end with "+".
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String findCountOf(int current, String total);

  /// More matches than shown.
  ///
  /// In en, this message translates to:
  /// **'{count}+'**
  String findCountMore(int count);

  /// No description provided for @findInvalidRegex.
  ///
  /// In en, this message translates to:
  /// **'Invalid regular expression'**
  String get findInvalidRegex;

  /// Undo label (Edit › Undo Replace).
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get findUndoReplace;

  /// Undo label (Edit › Undo Replace all).
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get findUndoReplaceAll;

  /// No description provided for @findPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Find in document'**
  String get findPlaceholder;

  /// No description provided for @findPreviousMatch.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get findPreviousMatch;

  /// No description provided for @findNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get findNextMatch;

  /// No description provided for @findMatchCase.
  ///
  /// In en, this message translates to:
  /// **'Match case'**
  String get findMatchCase;

  /// No description provided for @findWholeWord.
  ///
  /// In en, this message translates to:
  /// **'Whole word'**
  String get findWholeWord;

  /// No description provided for @findRegex.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get findRegex;

  /// Shows or hides the replace row.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get findToggleReplace;

  /// No description provided for @findReplaceWith.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get findReplaceWith;

  /// No description provided for @findSearchOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only search in this mode'**
  String get findSearchOnly;

  /// Button: replace the active match.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get findReplaceOne;

  /// No description provided for @findReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get findReplaceAll;

  /// No description provided for @findTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search the document.'**
  String get findTypeToSearch;

  /// No description provided for @findNoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \'{query}\''**
  String findNoResultsFor(String query);

  /// No description provided for @findResultSemantic.
  ///
  /// In en, this message translates to:
  /// **'Match {index} of {total}: {text}'**
  String findResultSemantic(int index, int total, String text);

  /// Theme editor element tree: the theme name and dark variant settings.
  ///
  /// In en, this message translates to:
  /// **'Name & variants'**
  String get themeEditorNodeGeneral;

  /// No description provided for @themeEditorNodePalette.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get themeEditorNodePalette;

  /// No description provided for @themeEditorNodeFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get themeEditorNodeFonts;

  /// No description provided for @themeEditorNodePage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get themeEditorNodePage;

  /// No description provided for @themeEditorNodeSyntax.
  ///
  /// In en, this message translates to:
  /// **'Syntax colors'**
  String get themeEditorNodeSyntax;

  /// No description provided for @themeEditorNodeHeaderFooter.
  ///
  /// In en, this message translates to:
  /// **'Page header & footer'**
  String get themeEditorNodeHeaderFooter;

  /// No description provided for @themeEditorNodeAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get themeEditorNodeAdvanced;

  /// No description provided for @themeElementBody.
  ///
  /// In en, this message translates to:
  /// **'Body text'**
  String get themeElementBody;

  /// No description provided for @themeElementHeadings.
  ///
  /// In en, this message translates to:
  /// **'All headings'**
  String get themeElementHeadings;

  /// No description provided for @themeElementHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading {level}'**
  String themeElementHeading(int level);

  /// No description provided for @themeElementParagraphAfterHeading.
  ///
  /// In en, this message translates to:
  /// **'Paragraph after heading'**
  String get themeElementParagraphAfterHeading;

  /// No description provided for @themeElementBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get themeElementBold;

  /// No description provided for @themeElementItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get themeElementItalic;

  /// No description provided for @themeElementStrike.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get themeElementStrike;

  /// No description provided for @themeElementInlineCode.
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get themeElementInlineCode;

  /// No description provided for @themeElementLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get themeElementLink;

  /// No description provided for @themeElementMention.
  ///
  /// In en, this message translates to:
  /// **'Mention'**
  String get themeElementMention;

  /// No description provided for @themeElementBlockquote.
  ///
  /// In en, this message translates to:
  /// **'Blockquote'**
  String get themeElementBlockquote;

  /// No description provided for @themeElementCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get themeElementCodeBlock;

  /// No description provided for @themeElementList.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get themeElementList;

  /// No description provided for @themeElementTask.
  ///
  /// In en, this message translates to:
  /// **'Task lists'**
  String get themeElementTask;

  /// No description provided for @themeElementRule.
  ///
  /// In en, this message translates to:
  /// **'Horizontal rule'**
  String get themeElementRule;

  /// No description provided for @themeElementImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get themeElementImage;

  /// No description provided for @themeElementTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get themeElementTable;

  /// No description provided for @themeElementHeader.
  ///
  /// In en, this message translates to:
  /// **'Page header'**
  String get themeElementHeader;

  /// No description provided for @themeElementFooter.
  ///
  /// In en, this message translates to:
  /// **'Page footer'**
  String get themeElementFooter;

  /// Theme editor element tree group.
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get themeEditorTreeHeadings;

  /// Theme editor element tree group: inline text styles.
  ///
  /// In en, this message translates to:
  /// **'Inline'**
  String get themeEditorTreeInline;

  /// Theme editor element tree group: block elements.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get themeEditorTreeBlocks;

  /// No description provided for @themeEditorSectionHeaderAndFooter.
  ///
  /// In en, this message translates to:
  /// **'Header and footer'**
  String get themeEditorSectionHeaderAndFooter;

  /// No description provided for @themeEditorSectionHeaderOnly.
  ///
  /// In en, this message translates to:
  /// **'Header only'**
  String get themeEditorSectionHeaderOnly;

  /// No description provided for @themeEditorSectionFooterOnly.
  ///
  /// In en, this message translates to:
  /// **'Footer only'**
  String get themeEditorSectionFooterOnly;

  /// Theme colors drawn over the document by the app (selection, comments, find matches).
  ///
  /// In en, this message translates to:
  /// **'App overlays'**
  String get themeEditorSectionAppOverlays;

  /// Theme inspector property group.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get themeEditorGroupText;

  /// Theme inspector property group.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get themeEditorGroupSpacing;

  /// Theme inspector property group: background, border, alignment.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get themeEditorGroupBox;

  /// Theme inspector property group: list bullets and numbers.
  ///
  /// In en, this message translates to:
  /// **'Markers'**
  String get themeEditorGroupMarkers;

  /// No description provided for @themeEditorGroupCheckboxes.
  ///
  /// In en, this message translates to:
  /// **'Checkboxes'**
  String get themeEditorGroupCheckboxes;

  /// No description provided for @themeEditorGroupTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get themeEditorGroupTable;

  /// No description provided for @themeEditorGroupImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get themeEditorGroupImage;

  /// Theme inspector property group of the horizontal rule.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get themeEditorGroupLine;

  /// No description provided for @themeEditorGroupLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get themeEditorGroupLink;

  /// No description provided for @themeEditorGroupCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get themeEditorGroupCode;

  /// Theme inspector property group: heading numbering.
  ///
  /// In en, this message translates to:
  /// **'Numbering'**
  String get themeEditorGroupNumbering;

  /// Theme inspector property group: other properties.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get themeEditorGroupMore;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get themeEditorEnumNone;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Small caps'**
  String get themeEditorEnumSmallCaps;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Header only'**
  String get themeEditorEnumHeaderOnly;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'@ prefix'**
  String get themeEditorEnumAtPrefix;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'No prefix'**
  String get themeEditorEnumNoPrefix;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get themeEditorEnumNormal;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get themeEditorEnumItalic;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Oblique'**
  String get themeEditorEnumOblique;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get themeEditorEnumUppercase;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
  String get themeEditorEnumLowercase;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Capitalize'**
  String get themeEditorEnumCapitalize;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get themeEditorEnumLeft;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get themeEditorEnumCenter;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get themeEditorEnumRight;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get themeEditorEnumJustify;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get themeEditorEnumTop;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get themeEditorEnumBottom;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get themeEditorEnumAlways;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Hover'**
  String get themeEditorEnumHover;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get themeEditorEnumSolid;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get themeEditorEnumDotted;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get themeEditorEnumDashed;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get themeEditorEnumDouble;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Ornament'**
  String get themeEditorEnumOrnament;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get themeEditorEnumSquare;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get themeEditorEnumRounded;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get themeEditorEnumCircle;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get themeEditorEnumSoft;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get themeEditorEnumStrong;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeEditorEnumAuto;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get themeEditorEnumFull;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get themeEditorEnumAll;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get themeEditorEnumHorizontal;

  /// Theme property option.
  ///
  /// In en, this message translates to:
  /// **'Outer'**
  String get themeEditorEnumOuter;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get themeEditorPaletteText;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get themeEditorPaletteHeading;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Muted text'**
  String get themeEditorPaletteMuted;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get themeEditorPaletteAccent;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get themeEditorPaletteLink;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Link hover'**
  String get themeEditorPaletteLinkHover;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get themeEditorPalettePage;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get themeEditorPaletteCanvas;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Borders'**
  String get themeEditorPaletteBorder;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Code text'**
  String get themeEditorPaletteCodeText;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Code background'**
  String get themeEditorPaletteCodeBg;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Quote text'**
  String get themeEditorPaletteQuoteText;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Quote bar'**
  String get themeEditorPaletteQuoteBar;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Quote background'**
  String get themeEditorPaletteQuoteBg;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Table header'**
  String get themeEditorPaletteTableHeaderBg;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Table stripe'**
  String get themeEditorPaletteTableStripe;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Mention background'**
  String get themeEditorPaletteMentionBg;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Mention text'**
  String get themeEditorPaletteMentionText;

  /// A theme color (palette entry).
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get themeEditorPaletteHighlight;

  /// A user-defined theme color.
  ///
  /// In en, this message translates to:
  /// **'Custom {number}'**
  String themeEditorPaletteCustom(String number);

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get themeEditorSyntaxKeyword;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'String'**
  String get themeEditorSyntaxString;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get themeEditorSyntaxNumber;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get themeEditorSyntaxComment;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get themeEditorSyntaxFunction;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get themeEditorSyntaxType;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get themeEditorSyntaxVariable;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get themeEditorSyntaxOperator;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Punctuation'**
  String get themeEditorSyntaxPunctuation;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get themeEditorSyntaxBuiltin;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Literal'**
  String get themeEditorSyntaxLiteral;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get themeEditorSyntaxMeta;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get themeEditorSyntaxTag;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Attribute'**
  String get themeEditorSyntaxAttribute;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get themeEditorSyntaxRegexp;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Addition'**
  String get themeEditorSyntaxAddition;

  /// Kind of code token colored by syntax highlighting.
  ///
  /// In en, this message translates to:
  /// **'Deletion'**
  String get themeEditorSyntaxDeletion;

  /// A contrast pair: code tokens of a kind on the code background.
  ///
  /// In en, this message translates to:
  /// **'{token} tokens on code'**
  String themeEditorPairSyntax(String token);

  /// No description provided for @themeEditorPairBody.
  ///
  /// In en, this message translates to:
  /// **'Body text on the page'**
  String get themeEditorPairBody;

  /// No description provided for @themeEditorPairCaption.
  ///
  /// In en, this message translates to:
  /// **'Captions on the page'**
  String get themeEditorPairCaption;

  /// No description provided for @themeEditorPairHeader.
  ///
  /// In en, this message translates to:
  /// **'Page header text'**
  String get themeEditorPairHeader;

  /// No description provided for @themeEditorPairFooter.
  ///
  /// In en, this message translates to:
  /// **'Page footer text'**
  String get themeEditorPairFooter;

  /// No description provided for @themeEditorPairLink.
  ///
  /// In en, this message translates to:
  /// **'Links on the page'**
  String get themeEditorPairLink;

  /// No description provided for @themeEditorPairMention.
  ///
  /// In en, this message translates to:
  /// **'Mentions on their chip'**
  String get themeEditorPairMention;

  /// No description provided for @themeEditorPairInlineCode.
  ///
  /// In en, this message translates to:
  /// **'Inline code on its background'**
  String get themeEditorPairInlineCode;

  /// No description provided for @themeEditorPairCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code on the code background'**
  String get themeEditorPairCodeBlock;

  /// No description provided for @themeEditorPairBlockquote.
  ///
  /// In en, this message translates to:
  /// **'Quote text'**
  String get themeEditorPairBlockquote;

  /// No description provided for @themeEditorPairTableHeader.
  ///
  /// In en, this message translates to:
  /// **'Table header text'**
  String get themeEditorPairTableHeader;

  /// No description provided for @themeEditorPairTableCell.
  ///
  /// In en, this message translates to:
  /// **'Table cell text'**
  String get themeEditorPairTableCell;

  /// No description provided for @themeEditorPairTableZebra.
  ///
  /// In en, this message translates to:
  /// **'Text on zebra rows'**
  String get themeEditorPairTableZebra;

  /// No description provided for @themeEditorPairTaskChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked task text'**
  String get themeEditorPairTaskChecked;

  /// A contrast pair: an element's text on the page.
  ///
  /// In en, this message translates to:
  /// **'{element} on the page'**
  String themeEditorPairElement(String element);

  /// Where an inherited value comes from: the light variant of the theme.
  ///
  /// In en, this message translates to:
  /// **'Light variant'**
  String get themeEditorSourceLightVariant;

  /// No description provided for @themeEditorSourceThemeFonts.
  ///
  /// In en, this message translates to:
  /// **'Theme fonts'**
  String get themeEditorSourceThemeFonts;

  /// No description provided for @themePropFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get themePropFontFamily;

  /// No description provided for @themePropFontSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get themePropFontSize;

  /// No description provided for @themePropFontWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get themePropFontWeight;

  /// No description provided for @themePropFontStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get themePropFontStyle;

  /// No description provided for @themePropLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line height'**
  String get themePropLineHeight;

  /// No description provided for @themePropLetterSpacing.
  ///
  /// In en, this message translates to:
  /// **'Letter spacing'**
  String get themePropLetterSpacing;

  /// No description provided for @themePropColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get themePropColor;

  /// No description provided for @themePropCaseTransform.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get themePropCaseTransform;

  /// No description provided for @themePropFontFeatures.
  ///
  /// In en, this message translates to:
  /// **'OpenType features'**
  String get themePropFontFeatures;

  /// No description provided for @themePropSpaceBefore.
  ///
  /// In en, this message translates to:
  /// **'Space before'**
  String get themePropSpaceBefore;

  /// No description provided for @themePropSpaceAfter.
  ///
  /// In en, this message translates to:
  /// **'Space after'**
  String get themePropSpaceAfter;

  /// No description provided for @themePropPadding.
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get themePropPadding;

  /// No description provided for @themePropBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themePropBackground;

  /// No description provided for @themePropBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get themePropBorder;

  /// No description provided for @themePropBorderRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get themePropBorderRadius;

  /// No description provided for @themePropKeepWithNext.
  ///
  /// In en, this message translates to:
  /// **'Keep with next'**
  String get themePropKeepWithNext;

  /// No description provided for @themePropPageBreakBefore.
  ///
  /// In en, this message translates to:
  /// **'Page break before'**
  String get themePropPageBreakBefore;

  /// No description provided for @themePropAlign.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get themePropAlign;

  /// No description provided for @themePropFirstLineIndent.
  ///
  /// In en, this message translates to:
  /// **'First-line indent'**
  String get themePropFirstLineIndent;

  /// No description provided for @themePropNumbering.
  ///
  /// In en, this message translates to:
  /// **'Heading numbering'**
  String get themePropNumbering;

  /// No description provided for @themePropEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get themePropEnabled;

  /// No description provided for @themePropFromLevel.
  ///
  /// In en, this message translates to:
  /// **'From level'**
  String get themePropFromLevel;

  /// No description provided for @themePropToLevel.
  ///
  /// In en, this message translates to:
  /// **'To level'**
  String get themePropToLevel;

  /// No description provided for @themePropStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get themePropStyle;

  /// No description provided for @themePropSuffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get themePropSuffix;

  /// No description provided for @themePropBorderBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom border'**
  String get themePropBorderBottom;

  /// No description provided for @themePropBorderTop.
  ///
  /// In en, this message translates to:
  /// **'Top border'**
  String get themePropBorderTop;

  /// No description provided for @themePropBorderBottomGap.
  ///
  /// In en, this message translates to:
  /// **'Gap above border'**
  String get themePropBorderBottomGap;

  /// No description provided for @themePropLineColor.
  ///
  /// In en, this message translates to:
  /// **'Line color'**
  String get themePropLineColor;

  /// No description provided for @themePropLineThickness.
  ///
  /// In en, this message translates to:
  /// **'Line thickness'**
  String get themePropLineThickness;

  /// No description provided for @themePropSizeRatio.
  ///
  /// In en, this message translates to:
  /// **'Size ratio'**
  String get themePropSizeRatio;

  /// No description provided for @themePropPaddingX.
  ///
  /// In en, this message translates to:
  /// **'Horizontal padding'**
  String get themePropPaddingX;

  /// No description provided for @themePropHoverColor.
  ///
  /// In en, this message translates to:
  /// **'Hover color'**
  String get themePropHoverColor;

  /// No description provided for @themePropUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get themePropUnderline;

  /// No description provided for @themePropUnderlineStyle.
  ///
  /// In en, this message translates to:
  /// **'Underline style'**
  String get themePropUnderlineStyle;

  /// No description provided for @themePropUnderlineThickness.
  ///
  /// In en, this message translates to:
  /// **'Underline thickness'**
  String get themePropUnderlineThickness;

  /// No description provided for @themePropPrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get themePropPrefix;

  /// No description provided for @themePropBar.
  ///
  /// In en, this message translates to:
  /// **'Left bar'**
  String get themePropBar;

  /// No description provided for @themePropItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get themePropItalic;

  /// No description provided for @themePropWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get themePropWrap;

  /// No description provided for @themePropShowLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language label'**
  String get themePropShowLanguageLabel;

  /// No description provided for @themePropTabSize.
  ///
  /// In en, this message translates to:
  /// **'Tab size'**
  String get themePropTabSize;

  /// No description provided for @themePropLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get themePropLineNumbers;

  /// No description provided for @themePropBullets.
  ///
  /// In en, this message translates to:
  /// **'Bullets per level'**
  String get themePropBullets;

  /// No description provided for @themePropBulletColor.
  ///
  /// In en, this message translates to:
  /// **'Bullet color'**
  String get themePropBulletColor;

  /// No description provided for @themePropBulletScale.
  ///
  /// In en, this message translates to:
  /// **'Bullet size'**
  String get themePropBulletScale;

  /// No description provided for @themePropNumberSuffix.
  ///
  /// In en, this message translates to:
  /// **'Number suffix'**
  String get themePropNumberSuffix;

  /// No description provided for @themePropNumberColor.
  ///
  /// In en, this message translates to:
  /// **'Number color'**
  String get themePropNumberColor;

  /// No description provided for @themePropIndentPerLevel.
  ///
  /// In en, this message translates to:
  /// **'Indent per level'**
  String get themePropIndentPerLevel;

  /// No description provided for @themePropMarkerGap.
  ///
  /// In en, this message translates to:
  /// **'Marker gap'**
  String get themePropMarkerGap;

  /// No description provided for @themePropItemSpacing.
  ///
  /// In en, this message translates to:
  /// **'Item spacing'**
  String get themePropItemSpacing;

  /// No description provided for @themePropCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Checkbox'**
  String get themePropCheckbox;

  /// No description provided for @themePropShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get themePropShape;

  /// No description provided for @themePropSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get themePropSize;

  /// No description provided for @themePropBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get themePropBorderColor;

  /// No description provided for @themePropCheckedFill.
  ///
  /// In en, this message translates to:
  /// **'Checked fill'**
  String get themePropCheckedFill;

  /// No description provided for @themePropCheckColor.
  ///
  /// In en, this message translates to:
  /// **'Check mark'**
  String get themePropCheckColor;

  /// No description provided for @themePropCheckedText.
  ///
  /// In en, this message translates to:
  /// **'Checked items'**
  String get themePropCheckedText;

  /// No description provided for @themePropStrike.
  ///
  /// In en, this message translates to:
  /// **'Strike through'**
  String get themePropStrike;

  /// No description provided for @themePropOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get themePropOpacity;

  /// No description provided for @themePropThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get themePropThickness;

  /// No description provided for @themePropWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get themePropWidth;

  /// No description provided for @themePropOrnament.
  ///
  /// In en, this message translates to:
  /// **'Ornament'**
  String get themePropOrnament;

  /// No description provided for @themePropMaxWidth.
  ///
  /// In en, this message translates to:
  /// **'Max width'**
  String get themePropMaxWidth;

  /// No description provided for @themePropShadow.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get themePropShadow;

  /// No description provided for @themePropCaption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get themePropCaption;

  /// No description provided for @themePropShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get themePropShow;

  /// No description provided for @themePropGap.
  ///
  /// In en, this message translates to:
  /// **'Gap'**
  String get themePropGap;

  /// No description provided for @themePropHeaderBackground.
  ///
  /// In en, this message translates to:
  /// **'Header background'**
  String get themePropHeaderBackground;

  /// No description provided for @themePropHeaderColor.
  ///
  /// In en, this message translates to:
  /// **'Header text'**
  String get themePropHeaderColor;

  /// No description provided for @themePropHeaderFontWeight.
  ///
  /// In en, this message translates to:
  /// **'Header weight'**
  String get themePropHeaderFontWeight;

  /// No description provided for @themePropBorders.
  ///
  /// In en, this message translates to:
  /// **'Borders'**
  String get themePropBorders;

  /// No description provided for @themePropBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border width'**
  String get themePropBorderWidth;

  /// No description provided for @themePropZebra.
  ///
  /// In en, this message translates to:
  /// **'Zebra rows'**
  String get themePropZebra;

  /// No description provided for @themePropZebraColor.
  ///
  /// In en, this message translates to:
  /// **'Zebra color'**
  String get themePropZebraColor;

  /// No description provided for @themePropCellPadding.
  ///
  /// In en, this message translates to:
  /// **'Cell padding'**
  String get themePropCellPadding;

  /// No description provided for @themePropFontSizeRatio.
  ///
  /// In en, this message translates to:
  /// **'Text size ratio'**
  String get themePropFontSizeRatio;

  /// No description provided for @themePropPaperColor.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get themePropPaperColor;

  /// No description provided for @themePropCanvasColor.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get themePropCanvasColor;

  /// No description provided for @themePropPageShadow.
  ///
  /// In en, this message translates to:
  /// **'Page shadow'**
  String get themePropPageShadow;

  /// No description provided for @themePropPagelessMaxWidth.
  ///
  /// In en, this message translates to:
  /// **'Pageless width'**
  String get themePropPagelessMaxWidth;

  /// No description provided for @themePropPagelessPadding.
  ///
  /// In en, this message translates to:
  /// **'Pageless padding'**
  String get themePropPagelessPadding;

  /// No description provided for @themePropDefaultMargins.
  ///
  /// In en, this message translates to:
  /// **'Default margins'**
  String get themePropDefaultMargins;

  /// No description provided for @themePropSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get themePropSelection;

  /// No description provided for @themePropCaret.
  ///
  /// In en, this message translates to:
  /// **'Caret'**
  String get themePropCaret;

  /// No description provided for @themePropCommentHighlight.
  ///
  /// In en, this message translates to:
  /// **'Comment highlight'**
  String get themePropCommentHighlight;

  /// No description provided for @themePropCommentHighlightActive.
  ///
  /// In en, this message translates to:
  /// **'Active comment'**
  String get themePropCommentHighlightActive;

  /// No description provided for @themePropSuggestionInsert.
  ///
  /// In en, this message translates to:
  /// **'Suggested insertion'**
  String get themePropSuggestionInsert;

  /// No description provided for @themePropSuggestionDelete.
  ///
  /// In en, this message translates to:
  /// **'Suggested deletion'**
  String get themePropSuggestionDelete;

  /// No description provided for @themePropFindMatch.
  ///
  /// In en, this message translates to:
  /// **'Find match'**
  String get themePropFindMatch;

  /// No description provided for @themePropFindMatchActive.
  ///
  /// In en, this message translates to:
  /// **'Current find match'**
  String get themePropFindMatchActive;

  /// No description provided for @themeControlsInheritedFrom.
  ///
  /// In en, this message translates to:
  /// **'Inherited from {source}: {value}'**
  String themeControlsInheritedFrom(String source, String value);

  /// No description provided for @themeControlsResetInherit.
  ///
  /// In en, this message translates to:
  /// **'Reset — inherit from {source}: {value}'**
  String themeControlsResetInherit(String source, String value);

  /// Accessibility label of the reset button of a theme property.
  ///
  /// In en, this message translates to:
  /// **'Reset {property}'**
  String themeControlsResetProperty(String property);

  /// A boolean theme value.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get themeControlsOn;

  /// A boolean theme value.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get themeControlsOff;

  /// No description provided for @themeControlsBodyFont.
  ///
  /// In en, this message translates to:
  /// **'Body font'**
  String get themeControlsBodyFont;

  /// No description provided for @themeControlsHeadingFont.
  ///
  /// In en, this message translates to:
  /// **'Heading font'**
  String get themeControlsHeadingFont;

  /// No description provided for @themeControlsCodeFont.
  ///
  /// In en, this message translates to:
  /// **'Code font'**
  String get themeControlsCodeFont;

  /// Color field: no color set, the inherited color is used.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get themeControlsColorAutomatic;

  /// Color field: transparent.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get themeControlsColorNone;

  /// No description provided for @themeControlsColorAutomaticInherit.
  ///
  /// In en, this message translates to:
  /// **'Automatic (inherit)'**
  String get themeControlsColorAutomaticInherit;

  /// No description provided for @themeControlsNoColor.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get themeControlsNoColor;

  /// Accessibility label of a color button: property name and its color.
  ///
  /// In en, this message translates to:
  /// **'{name}: {value}'**
  String themeControlsColorValue(String name, String value);

  /// No description provided for @fontCategorySans.
  ///
  /// In en, this message translates to:
  /// **'Sans serif'**
  String get fontCategorySans;

  /// No description provided for @fontCategorySerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontCategorySerif;

  /// No description provided for @fontCategoryMono.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get fontCategoryMono;

  /// Font category: display (decorative) fonts.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get fontCategoryDisplay;

  /// No description provided for @fontChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a font'**
  String get fontChoose;

  /// Length unit: points.
  ///
  /// In en, this message translates to:
  /// **'pt'**
  String get themeControlsUnitPt;

  /// Length unit: pixels.
  ///
  /// In en, this message translates to:
  /// **'px'**
  String get themeControlsUnitPx;

  /// Length unit: em.
  ///
  /// In en, this message translates to:
  /// **'em'**
  String get themeControlsUnitEm;

  /// Length unit: millimeters.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get themeControlsUnitMm;

  /// Length unit: inches.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get themeControlsUnitIn;

  /// Length unit: percent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get themeControlsUnitPercent;

  /// Accessibility label of the length unit select.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get themeControlsUnit;

  /// No description provided for @themeInspectorOverlaysNote.
  ///
  /// In en, this message translates to:
  /// **'Overlays replace the app colors for selection, comments, suggestions and find matches. Usually best left to the app.'**
  String get themeInspectorOverlaysNote;

  /// No description provided for @themeInspectorNumberingPerLevel.
  ///
  /// In en, this message translates to:
  /// **'Numbering per level'**
  String get themeInspectorNumberingPerLevel;

  /// Placeholder: OpenType feature tags, keep the tags.
  ///
  /// In en, this message translates to:
  /// **'e.g. onum, liga'**
  String get themeInspectorFeaturesHint;

  /// No description provided for @fontWeightThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get fontWeightThin;

  /// No description provided for @fontWeightExtraLight.
  ///
  /// In en, this message translates to:
  /// **'Extra light'**
  String get fontWeightExtraLight;

  /// Font weight 300.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get fontWeightLight;

  /// No description provided for @fontWeightRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get fontWeightRegular;

  /// No description provided for @fontWeightMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontWeightMedium;

  /// No description provided for @fontWeightSemibold.
  ///
  /// In en, this message translates to:
  /// **'Semibold'**
  String get fontWeightSemibold;

  /// No description provided for @fontWeightBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get fontWeightBold;

  /// No description provided for @fontWeightExtraBold.
  ///
  /// In en, this message translates to:
  /// **'Extra bold'**
  String get fontWeightExtraBold;

  /// Font weight 900.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get fontWeightBlack;

  /// No description provided for @themeInspectorDarkVariant.
  ///
  /// In en, this message translates to:
  /// **'Dark variant'**
  String get themeInspectorDarkVariant;

  /// No description provided for @themeInspectorDarkOverridesNote.
  ///
  /// In en, this message translates to:
  /// **'Unset colors follow the light variant (through the dark theme colors).'**
  String get themeInspectorDarkOverridesNote;

  /// A property of the dark variant.
  ///
  /// In en, this message translates to:
  /// **'{name} (dark)'**
  String themeInspectorDarkLabel(String name);

  /// A property of the light variant.
  ///
  /// In en, this message translates to:
  /// **'{name} (light)'**
  String themeInspectorLightLabel(String name);

  /// No description provided for @themeInspectorName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get themeInspectorName;

  /// No description provided for @themeInspectorDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get themeInspectorDescription;

  /// No description provided for @themeInspectorDarkColors.
  ///
  /// In en, this message translates to:
  /// **'Dark colors'**
  String get themeInspectorDarkColors;

  /// Dark colors computed from the light palette.
  ///
  /// In en, this message translates to:
  /// **'Derived'**
  String get themeInspectorDarkDerived;

  /// Dark colors set by hand.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeInspectorDarkCustom;

  /// No description provided for @themeInspectorDarkExplicitNote.
  ///
  /// In en, this message translates to:
  /// **'The dark palette is set completely in Theme colors.'**
  String get themeInspectorDarkExplicitNote;

  /// No description provided for @themeInspectorDarkDerivedNote.
  ///
  /// In en, this message translates to:
  /// **'Dark colors are computed from the light palette with good contrast. Override single colors in Theme colors.'**
  String get themeInspectorDarkDerivedNote;

  /// No description provided for @themeInspectorAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get themeInspectorAbout;

  /// No description provided for @themeInspectorVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get themeInspectorVersion;

  /// Theme version number and the date it was saved.
  ///
  /// In en, this message translates to:
  /// **'{version} · saved {date}'**
  String themeInspectorVersionSaved(int version, DateTime date);

  /// No description provided for @themeInspectorPaletteExplicitNote.
  ///
  /// In en, this message translates to:
  /// **'Light and custom dark colors. Elements reference these colors, so changing one updates everything that uses it.'**
  String get themeInspectorPaletteExplicitNote;

  /// No description provided for @themeInspectorPaletteDerivedNote.
  ///
  /// In en, this message translates to:
  /// **'Light colors on the left; dark colors on the right are derived unless you override them.'**
  String get themeInspectorPaletteDerivedNote;

  /// The light variant of a theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeInspectorLight;

  /// The dark variant of a theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeInspectorDark;

  /// No description provided for @themeInspectorCustomColors.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get themeInspectorCustomColors;

  /// No description provided for @themeInspectorFontsNote.
  ///
  /// In en, this message translates to:
  /// **'Elements use these three fonts unless they pick a font of their own.'**
  String get themeInspectorFontsNote;

  /// Theme font role for body text.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get themeInspectorFontBody;

  /// Theme font role for headings.
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get themeInspectorFontHeadings;

  /// Theme font role for code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get themeInspectorFontCode;

  /// No description provided for @themeInspectorSyntaxNote.
  ///
  /// In en, this message translates to:
  /// **'Token colors of code blocks. Unlisted tokens use the code text color; dark colors are derived unless overridden.'**
  String get themeInspectorSyntaxNote;

  /// No description provided for @themeInspectorUsesCodeTextColor.
  ///
  /// In en, this message translates to:
  /// **'Uses the code text color.'**
  String get themeInspectorUsesCodeTextColor;

  /// No description provided for @themeInspectorBuiltinReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Built-in themes can’t be changed.'**
  String get themeInspectorBuiltinReadOnly;

  /// No description provided for @themeInspectorDeleted.
  ///
  /// In en, this message translates to:
  /// **'This theme is deleted.'**
  String get themeInspectorDeleted;

  /// No description provided for @themeInspectorBelongsTo.
  ///
  /// In en, this message translates to:
  /// **'This theme belongs to {owner}.'**
  String themeInspectorBelongsTo(String owner);

  /// No description provided for @themeInspectorBelongsToSomeoneElse.
  ///
  /// In en, this message translates to:
  /// **'This theme belongs to someone else.'**
  String get themeInspectorBelongsToSomeoneElse;

  /// Contrast warning; ratio and required are numbers like 3.2.
  ///
  /// In en, this message translates to:
  /// **'Contrast {ratio}:1 — {pair} needs {required}:1'**
  String themeInspectorContrastWarning(
    String ratio,
    String pair,
    String required,
  );

  /// Contrast warning of the dark variant.
  ///
  /// In en, this message translates to:
  /// **'Contrast {ratio}:1 (dark) — {pair} needs {required}:1'**
  String themeInspectorContrastWarningDark(
    String ratio,
    String pair,
    String required,
  );

  /// Button: fix a contrast warning.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get themeInspectorFix;

  /// No description provided for @themeInspectorSetSidesSeparately.
  ///
  /// In en, this message translates to:
  /// **'Set sides separately'**
  String get themeInspectorSetSidesSeparately;

  /// No description provided for @themeInspectorSameOnAllSides.
  ///
  /// In en, this message translates to:
  /// **'Same on all sides'**
  String get themeInspectorSameOnAllSides;

  /// No description provided for @themeInspectorUnlinkSides.
  ///
  /// In en, this message translates to:
  /// **'Unlink sides'**
  String get themeInspectorUnlinkSides;

  /// No description provided for @themeInspectorLinkSides.
  ///
  /// In en, this message translates to:
  /// **'Link sides'**
  String get themeInspectorLinkSides;

  /// Accessibility label of a list level field.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String themeInspectorLevel(int level);

  /// No description provided for @themeEditorSavingFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving failed'**
  String get themeEditorSavingFailed;

  /// No description provided for @themeEditorSavingFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Saving failed: {error}'**
  String themeEditorSavingFailedWith(String error);

  /// No description provided for @themeEditorOpenErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'This theme can’t be opened'**
  String get themeEditorOpenErrorTitle;

  /// No description provided for @themeEditorOpenErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or you no longer have access.'**
  String get themeEditorOpenErrorDescription;

  /// No description provided for @themeEditorGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get themeEditorGoBack;

  /// Button opening a theme by name.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String themeEditorOpenTheme(String name);

  /// No description provided for @themeEditorThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themeEditorThemes;

  /// No description provided for @themeEditorElements.
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get themeEditorElements;

  /// No description provided for @themeEditorProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get themeEditorProperties;

  /// No description provided for @themeEditorStatusSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get themeEditorStatusSaving;

  /// No description provided for @themeEditorStatusBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in · read-only'**
  String get themeEditorStatusBuiltin;

  /// No description provided for @themeEditorStatusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get themeEditorStatusDeleted;

  /// No description provided for @themeEditorStatusReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get themeEditorStatusReadOnly;

  /// No description provided for @themeEditorStatusUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get themeEditorStatusUnsaved;

  /// No description provided for @themeEditorStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'All changes saved'**
  String get themeEditorStatusSaved;

  /// No description provided for @themeEditorUsedBy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Used by 1 of your documents} other{Used by {count} of your documents}}'**
  String themeEditorUsedBy(int count);

  /// Tooltip of the undo button; action is the undo step label.
  ///
  /// In en, this message translates to:
  /// **'Undo {action}'**
  String themeEditorUndoLabel(String action);

  /// No description provided for @themeEditorRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get themeEditorRedo;

  /// Tooltip of the redo button; action is the redo step label.
  ///
  /// In en, this message translates to:
  /// **'Redo {action}'**
  String themeEditorRedoLabel(String action);

  /// No description provided for @themeEditorBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get themeEditorBack;

  /// No description provided for @themeEditorBackTo.
  ///
  /// In en, this message translates to:
  /// **'Back to “{title}”'**
  String themeEditorBackTo(String title);

  /// No description provided for @themeEditorDuplicateToCustomize.
  ///
  /// In en, this message translates to:
  /// **'Duplicate to customize'**
  String get themeEditorDuplicateToCustomize;

  /// No description provided for @themeEditorCopyToMyThemes.
  ///
  /// In en, this message translates to:
  /// **'Copy to my themes'**
  String get themeEditorCopyToMyThemes;

  /// Button: discard unsaved theme changes.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get themeEditorRevert;

  /// No description provided for @themeEditorMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More theme actions'**
  String get themeEditorMoreActions;

  /// No description provided for @themeEditorMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename…'**
  String get themeEditorMenuRename;

  /// No description provided for @themeEditorMenuDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get themeEditorMenuDuplicate;

  /// No description provided for @themeEditorMenuVersionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history…'**
  String get themeEditorMenuVersionHistory;

  /// No description provided for @themeEditorMenuMyDefault.
  ///
  /// In en, this message translates to:
  /// **'My default theme'**
  String get themeEditorMenuMyDefault;

  /// No description provided for @themeEditorMenuExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON…'**
  String get themeEditorMenuExportJson;

  /// No description provided for @themeEditorMenuExportCss.
  ///
  /// In en, this message translates to:
  /// **'Export as CSS…'**
  String get themeEditorMenuExportCss;

  /// Theme list section: the user's default theme.
  ///
  /// In en, this message translates to:
  /// **'My default'**
  String get themeEditorMyDefault;

  /// No description provided for @themeEditorUsedByThisDocument.
  ///
  /// In en, this message translates to:
  /// **'Used by this document'**
  String get themeEditorUsedByThisDocument;

  /// No description provided for @themeEditorMyThemes.
  ///
  /// In en, this message translates to:
  /// **'My themes'**
  String get themeEditorMyThemes;

  /// No description provided for @themeEditorNoThemesHint.
  ///
  /// In en, this message translates to:
  /// **'Duplicate a built-in theme to make it your own.'**
  String get themeEditorNoThemesHint;

  /// Theme list section: themes that come with the app.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get themeEditorBuiltin;

  /// Button: import a theme file.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get themeEditorImport;

  /// No description provided for @themeEditorLowContrast.
  ///
  /// In en, this message translates to:
  /// **'Low contrast'**
  String get themeEditorLowContrast;

  /// Marks a theme element that has own settings.
  ///
  /// In en, this message translates to:
  /// **'Customized'**
  String get themeEditorCustomized;

  /// No description provided for @themeEditorPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get themeEditorPreview;

  /// Preview source: the sample document.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get themeEditorSourceSample;

  /// Preview source (short): the document the editor was opened from.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get themeEditorSourceDocument;

  /// Preview source: the document the editor was opened from.
  ///
  /// In en, this message translates to:
  /// **'This document'**
  String get themeEditorSourceThisDocument;

  /// No description provided for @themeEditorLayoutPageless.
  ///
  /// In en, this message translates to:
  /// **'Pageless'**
  String get themeEditorLayoutPageless;

  /// No description provided for @themeEditorLayoutPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get themeEditorLayoutPages;

  /// No description provided for @themeEditorZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get themeEditorZoom;

  /// No description provided for @themeEditorZoomPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String themeEditorZoomPercent(int percent);

  /// No description provided for @themeEditorContrastWarnings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contrast warning} other{{count} contrast warnings}}'**
  String themeEditorContrastWarnings(int count);

  /// Title of the theme preview's sample document (page header and footer).
  ///
  /// In en, this message translates to:
  /// **'Sample document'**
  String get themeEditorSampleTitle;

  /// Accessibility name of the theme preview.
  ///
  /// In en, this message translates to:
  /// **'Theme preview'**
  String get themeEditorPreviewTitle;

  /// No description provided for @themeEditorReadOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'This theme is read-only. Duplicate it to customize.'**
  String get themeEditorReadOnlyMessage;

  /// Undo label: a theme property changed.
  ///
  /// In en, this message translates to:
  /// **'Change {property}'**
  String themeEditorUndoChange(String property);

  /// Undo label: a theme element was reset.
  ///
  /// In en, this message translates to:
  /// **'Reset {element}'**
  String themeEditorUndoReset(String element);

  /// No description provided for @themeEditorNothingToFix.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix for this pair'**
  String get themeEditorNothingToFix;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Restore version {version}'**
  String themeEditorUndoRestoreVersion(int version);

  /// Undo label: a theme was saved.
  ///
  /// In en, this message translates to:
  /// **'Edit theme “{name}”'**
  String themeEditorUndoEdit(String name);

  /// No description provided for @themeEditorChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'The theme was changed elsewhere'**
  String get themeEditorChangedElsewhere;

  /// No description provided for @themeEditorNameLength.
  ///
  /// In en, this message translates to:
  /// **'Theme names have 1–80 characters'**
  String get themeEditorNameLength;

  /// No description provided for @themeEditorOnlyOwnerRestore.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can restore it'**
  String get themeEditorOnlyOwnerRestore;

  /// No description provided for @themeEditorNoDocument.
  ///
  /// In en, this message translates to:
  /// **'No document to apply it to'**
  String get themeEditorNoDocument;

  /// No description provided for @themeEditorNeedEditAccess.
  ///
  /// In en, this message translates to:
  /// **'You need edit access to change the document theme'**
  String get themeEditorNeedEditAccess;

  /// Undo label: the document theme changed.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get themeEditorUndoChangeTheme;

  /// Name of a theme created without a name.
  ///
  /// In en, this message translates to:
  /// **'Untitled theme'**
  String get themeLibraryUntitled;

  /// Default name of a new theme.
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get themeLibraryNewName;

  /// Fallback name of a theme that is not found.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLibraryTheme;

  /// Name of a copied theme.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String themeLibraryCopyName(String name);

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Create theme “{name}”'**
  String themeLibraryUndoCreate(String name);

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Copy theme “{name}”'**
  String themeLibraryUndoCopy(String name);

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Rename theme'**
  String get themeLibraryUndoRename;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Delete theme “{name}”'**
  String themeLibraryUndoDelete(String name);

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Restore theme “{name}”'**
  String themeLibraryUndoRestore(String name);

  /// No description provided for @themeDialogRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename theme'**
  String get themeDialogRenameTitle;

  /// No description provided for @themeDialogEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get themeDialogEnterName;

  /// No description provided for @themeDialogMaxLength.
  ///
  /// In en, this message translates to:
  /// **'At most {max} characters'**
  String themeDialogMaxLength(int max);

  /// No description provided for @themeDialogConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'This theme was changed elsewhere'**
  String get themeDialogConflictTitle;

  /// No description provided for @themeDialogConflictDescription.
  ///
  /// In en, this message translates to:
  /// **'“{name}” was saved in another window (version {version}) while you were editing it.'**
  String themeDialogConflictDescription(String name, int version);

  /// No description provided for @themeDialogSaveAsCopy.
  ///
  /// In en, this message translates to:
  /// **'Save as copy'**
  String get themeDialogSaveAsCopy;

  /// No description provided for @themeDialogReloadTheirs.
  ///
  /// In en, this message translates to:
  /// **'Reload theirs'**
  String get themeDialogReloadTheirs;

  /// No description provided for @themeDialogOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get themeDialogOverwrite;

  /// No description provided for @themeDialogUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes to “{name}”?'**
  String themeDialogUnsavedTitle(String name);

  /// No description provided for @themeDialogUnsavedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your changes to this theme are not saved yet.'**
  String get themeDialogUnsavedDescription;

  /// No description provided for @themeDialogDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get themeDialogDiscard;

  /// Last line of a list of import problems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{• … and {count} more}}'**
  String themeDialogImportMore(int count);

  /// No description provided for @themeDialogImportBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This theme can’t be imported'**
  String get themeDialogImportBlockedTitle;

  /// No description provided for @themeDialogImportWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import with changes?'**
  String get themeDialogImportWarningsTitle;

  /// No description provided for @themeDialogImportAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Some values were adjusted:\n{issues}'**
  String themeDialogImportAdjusted(String issues);

  /// No description provided for @themeDialogImportAnyway.
  ///
  /// In en, this message translates to:
  /// **'Import anyway'**
  String get themeDialogImportAnyway;

  /// No description provided for @themeDialogRevisionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme versions'**
  String get themeDialogRevisionsTitle;

  /// No description provided for @themeDialogRevisionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Load an earlier version into the editor. It becomes your draft; save to keep it.'**
  String get themeDialogRevisionsDescription;

  /// No description provided for @themeDialogNoRevisions.
  ///
  /// In en, this message translates to:
  /// **'No saved versions yet.'**
  String get themeDialogNoRevisions;

  /// No description provided for @themeDialogRevisionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (current)'**
  String themeDialogRevisionCurrent(int version);

  /// No description provided for @themeDialogRevision.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String themeDialogRevision(int version);

  /// A theme version saved by an AI assistant.
  ///
  /// In en, this message translates to:
  /// **'via an assistant'**
  String get themeDialogViaAssistant;

  /// Button: load a theme version into the editor.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get themeDialogLoad;

  /// No description provided for @themePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Document theme'**
  String get themePickerTitle;

  /// No description provided for @themePickerDescription.
  ///
  /// In en, this message translates to:
  /// **'Themes control fonts, colors and spacing — the Markdown stays the same.'**
  String get themePickerDescription;

  /// No description provided for @themePickerDescriptionReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Themes control fonts, colors and spacing. You need edit access to change the theme.'**
  String get themePickerDescriptionReadOnly;

  /// No description provided for @themePickerCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize…'**
  String get themePickerCustomize;

  /// Accessibility label of a theme card.
  ///
  /// In en, this message translates to:
  /// **'{name} theme'**
  String themePickerCardLabel(String name);

  /// Sample text in a theme card preview.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog.'**
  String get themePickerSampleText;

  /// No description provided for @themeSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Themes set fonts, colors and spacing. Documents that use “my default theme” show your default.'**
  String get themeSettingsDescription;

  /// No description provided for @themeSettingsDefaultTheme.
  ///
  /// In en, this message translates to:
  /// **'Default theme'**
  String get themeSettingsDefaultTheme;

  /// No description provided for @themeSettingsThemeEditor.
  ///
  /// In en, this message translates to:
  /// **'Theme editor'**
  String get themeSettingsThemeEditor;

  /// No description provided for @themeSettingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit…'**
  String get themeSettingsEdit;

  /// Title of the AI assistant side panel.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiPanelTitle;

  /// No description provided for @aiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t configured on this server'**
  String get aiNotConfigured;

  /// No description provided for @aiTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'The assistant is turned off'**
  String get aiTurnedOff;

  /// No description provided for @aiTurnOnHint.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Settings › AI.'**
  String get aiTurnOnHint;

  /// Label and tooltip of the AI button in the selection toolbar.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiButtonLabel;

  /// No description provided for @aiImproveWriting.
  ///
  /// In en, this message translates to:
  /// **'Improve writing'**
  String get aiImproveWriting;

  /// No description provided for @aiFixGrammar.
  ///
  /// In en, this message translates to:
  /// **'Fix spelling & grammar'**
  String get aiFixGrammar;

  /// No description provided for @aiMakeShorter.
  ///
  /// In en, this message translates to:
  /// **'Make shorter'**
  String get aiMakeShorter;

  /// No description provided for @aiMakeLonger.
  ///
  /// In en, this message translates to:
  /// **'Make longer'**
  String get aiMakeLonger;

  /// No description provided for @aiChangeTone.
  ///
  /// In en, this message translates to:
  /// **'Change tone'**
  String get aiChangeTone;

  /// No description provided for @aiToneProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get aiToneProfessional;

  /// No description provided for @aiToneCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get aiToneCasual;

  /// No description provided for @aiToneFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get aiToneFriendly;

  /// No description provided for @aiToneConfident.
  ///
  /// In en, this message translates to:
  /// **'Confident'**
  String get aiToneConfident;

  /// No description provided for @aiTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get aiTranslate;

  /// No description provided for @aiLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get aiLanguageEnglish;

  /// No description provided for @aiLanguageSwedish.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get aiLanguageSwedish;

  /// No description provided for @aiLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get aiLanguageGerman;

  /// No description provided for @aiLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get aiLanguageFrench;

  /// No description provided for @aiLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get aiLanguageSpanish;

  /// No description provided for @aiLanguageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get aiLanguageItalian;

  /// No description provided for @aiLanguagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get aiLanguagePortuguese;

  /// No description provided for @aiLanguageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get aiLanguageDutch;

  /// No description provided for @aiLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get aiLanguageJapanese;

  /// No description provided for @aiLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get aiLanguageChinese;

  /// No description provided for @aiSummarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get aiSummarize;

  /// No description provided for @aiExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get aiExplain;

  /// AI menu entry that opens a free-form prompt.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get aiCustom;

  /// No description provided for @aiTitleChangeTone.
  ///
  /// In en, this message translates to:
  /// **'Change tone: {tone}'**
  String aiTitleChangeTone(String tone);

  /// No description provided for @aiTitleTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate to {language}'**
  String aiTitleTranslate(String language);

  /// No description provided for @aiTitleEditWithAi.
  ///
  /// In en, this message translates to:
  /// **'Edit with AI'**
  String get aiTitleEditWithAi;

  /// No description provided for @aiAskToWrite.
  ///
  /// In en, this message translates to:
  /// **'Ask AI to write'**
  String get aiAskToWrite;

  /// No description provided for @aiAskToEdit.
  ///
  /// In en, this message translates to:
  /// **'Ask AI to edit'**
  String get aiAskToEdit;

  /// Status while the AI is generating text.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get aiWriting;

  /// No description provided for @aiGhostHintAccept.
  ///
  /// In en, this message translates to:
  /// **'Tab or Enter to accept · Esc to discard'**
  String get aiGhostHintAccept;

  /// No description provided for @aiGhostHintDiscard.
  ///
  /// In en, this message translates to:
  /// **'Esc to discard'**
  String get aiGhostHintDiscard;

  /// No description provided for @aiAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get aiAccept;

  /// No description provided for @aiDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aiDiscard;

  /// No description provided for @aiPromptWritePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tell AI what to write…'**
  String get aiPromptWritePlaceholder;

  /// No description provided for @aiPromptEditPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tell AI how to change the selection…'**
  String get aiPromptEditPlaceholder;

  /// No description provided for @aiGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get aiGenerate;

  /// No description provided for @aiShowChanges.
  ///
  /// In en, this message translates to:
  /// **'Show changes'**
  String get aiShowChanges;

  /// No description provided for @aiHideChanges.
  ///
  /// In en, this message translates to:
  /// **'Hide changes'**
  String get aiHideChanges;

  /// No description provided for @aiOriginalChanged.
  ///
  /// In en, this message translates to:
  /// **'The original text changed.'**
  String get aiOriginalChanged;

  /// Button that applies the AI result as a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get aiSuggest;

  /// No description provided for @aiReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get aiReplace;

  /// No description provided for @aiInsertBelow.
  ///
  /// In en, this message translates to:
  /// **'Insert below'**
  String get aiInsertBelow;

  /// No description provided for @aiRefinePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Refine: “Make it more formal”'**
  String get aiRefinePlaceholder;

  /// No description provided for @aiHintReplace.
  ///
  /// In en, this message translates to:
  /// **'Enter to replace · Esc to discard'**
  String get aiHintReplace;

  /// No description provided for @aiHintInsert.
  ///
  /// In en, this message translates to:
  /// **'Enter to insert · Esc to discard'**
  String get aiHintInsert;

  /// Undo label (Edit › Undo Typing).
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get aiTypingUndo;

  /// No description provided for @aiErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get aiErrorGeneric;

  /// No description provided for @aiRefusal.
  ///
  /// In en, this message translates to:
  /// **'The assistant can\'t help with that request.'**
  String get aiRefusal;

  /// Toast after copying the AI result.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiCopied;

  /// Undo label of an AI change (Edit › Undo AI: Improve writing).
  ///
  /// In en, this message translates to:
  /// **'AI: {action}'**
  String aiUndoLabel(String action);

  /// Undo label of an AI assistant run until it has a summary.
  ///
  /// In en, this message translates to:
  /// **'AI edit'**
  String get aiUndoDefault;

  /// No description provided for @aiInsertAtCursor.
  ///
  /// In en, this message translates to:
  /// **'Insert at cursor'**
  String get aiInsertAtCursor;

  /// No description provided for @aiInsertAtTop.
  ///
  /// In en, this message translates to:
  /// **'Insert at top'**
  String get aiInsertAtTop;

  /// No description provided for @aiInsertAsList.
  ///
  /// In en, this message translates to:
  /// **'Insert as bullet list'**
  String get aiInsertAsList;

  /// No description provided for @aiResultSelectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary of the selection'**
  String get aiResultSelectionSummary;

  /// No description provided for @aiResultExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get aiResultExplanation;

  /// No description provided for @aiResultDocumentSummary.
  ///
  /// In en, this message translates to:
  /// **'Document summary'**
  String get aiResultDocumentSummary;

  /// No description provided for @aiResultOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get aiResultOutline;

  /// No description provided for @aiResultProofreading.
  ///
  /// In en, this message translates to:
  /// **'Proofreading'**
  String get aiResultProofreading;

  /// No description provided for @aiChipSelectionParagraphs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Selection: 1 paragraph} other{Selection: {count} paragraphs}}'**
  String aiChipSelectionParagraphs(int count);

  /// No description provided for @aiChipSelectionQuote.
  ///
  /// In en, this message translates to:
  /// **'Selection: “{text}”'**
  String aiChipSelectionQuote(String text);

  /// No description provided for @aiQuickImprove.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get aiQuickImprove;

  /// No description provided for @aiQuickFixTypos.
  ///
  /// In en, this message translates to:
  /// **'Fix typos'**
  String get aiQuickFixTypos;

  /// No description provided for @aiQuickAddressComments.
  ///
  /// In en, this message translates to:
  /// **'Address comments'**
  String get aiQuickAddressComments;

  /// No description provided for @proofreadCategorySpelling.
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get proofreadCategorySpelling;

  /// No description provided for @proofreadCategoryGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get proofreadCategoryGrammar;

  /// No description provided for @proofreadCategoryPunctuation.
  ///
  /// In en, this message translates to:
  /// **'Punctuation'**
  String get proofreadCategoryPunctuation;

  /// No description provided for @proofreadCategoryStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get proofreadCategoryStyle;

  /// No description provided for @proofreadCategoryClarity.
  ///
  /// In en, this message translates to:
  /// **'Clarity'**
  String get proofreadCategoryClarity;

  /// No description provided for @proofreadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Proofreading…'**
  String get proofreadInProgress;

  /// No description provided for @proofreadProgress.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Proofreading… {done} of 1 section} other{Proofreading… {done} of {total} sections}}'**
  String proofreadProgress(int done, int total);

  /// No description provided for @proofreadNoIssues.
  ///
  /// In en, this message translates to:
  /// **'No issues found.'**
  String get proofreadNoIssues;

  /// No description provided for @proofreadAcceptAllCount.
  ///
  /// In en, this message translates to:
  /// **'Accept all ({count})'**
  String proofreadAcceptAllCount(int count);

  /// No description provided for @proofreadAcceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept all'**
  String get proofreadAcceptAll;

  /// No description provided for @proofreadCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{category} ({count})'**
  String proofreadCategoryCount(String category, int count);

  /// Undo label; category is an id (spelling, grammar, punctuation, style, clarity).
  ///
  /// In en, this message translates to:
  /// **'{category, select, spelling{AI: Accept spelling fixes} grammar{AI: Accept grammar fixes} punctuation{AI: Accept punctuation fixes} style{AI: Accept style fixes} other{AI: Accept clarity fixes}}'**
  String proofreadUndoAcceptCategory(String category);

  /// No description provided for @proofreadUndoFix.
  ///
  /// In en, this message translates to:
  /// **'AI: Fix “{quote}”'**
  String proofreadUndoFix(String quote);

  /// No description provided for @proofreadUndoAcceptMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{AI: Accept 1 correction} other{AI: Accept {count} corrections}}'**
  String proofreadUndoAcceptMany(int count);

  /// No description provided for @proofreadAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get proofreadAccept;

  /// No description provided for @proofreadDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get proofreadDismiss;

  /// No description provided for @proofreadAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get proofreadAccepted;

  /// No description provided for @proofreadDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get proofreadDismissed;

  /// No description provided for @proofreadTextChanged.
  ///
  /// In en, this message translates to:
  /// **'Text changed'**
  String get proofreadTextChanged;

  /// Semantics hint of a proofreading issue (tap selects its text).
  ///
  /// In en, this message translates to:
  /// **'Show “{quote}” in the document'**
  String proofreadShowIssue(String quote);

  /// No description provided for @suggestionActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action'**
  String get suggestionActionFailed;

  /// No description provided for @suggestionYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get suggestionYou;

  /// No description provided for @suggestionSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get suggestionSomeone;

  /// No description provided for @suggestionJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get suggestionJustNow;

  /// No description provided for @suggestionMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String suggestionMinutesAgo(int minutes);

  /// No description provided for @suggestionHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String suggestionHoursAgo(int hours);

  /// No description provided for @suggestionViaMcp.
  ///
  /// In en, this message translates to:
  /// **'Suggested via MCP'**
  String get suggestionViaMcp;

  /// No description provided for @suggestionViaAi.
  ///
  /// In en, this message translates to:
  /// **'Suggested by AI'**
  String get suggestionViaAi;

  /// No description provided for @suggestionWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw suggestion'**
  String get suggestionWithdraw;

  /// No description provided for @suggestionUndoAccept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Accept suggestion} other{Accept {count} suggestions}}'**
  String suggestionUndoAccept(int count);

  /// No description provided for @suggestionUndoReject.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Reject suggestion} other{Reject {count} suggestions}}'**
  String suggestionUndoReject(int count);

  /// No description provided for @suggestionUndoWithdraw.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Withdraw suggestion} other{Withdraw {count} suggestions}}'**
  String suggestionUndoWithdraw(int count);

  /// Anchor label of a comment on the whole document.
  ///
  /// In en, this message translates to:
  /// **'Whole document'**
  String get commentWholeDocument;

  /// No description provided for @commentSelectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'The text you selected was deleted'**
  String get commentSelectionDeleted;

  /// No description provided for @commentSavedWithoutPosition.
  ///
  /// In en, this message translates to:
  /// **'The comment was saved without a position.'**
  String get commentSavedWithoutPosition;

  /// Undo label (Edit › Undo Comment).
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentUndoAdd;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get commentUndoDelete;

  /// Undo label.
  ///
  /// In en, this message translates to:
  /// **'Re-attach comment'**
  String get commentUndoReattach;

  /// No description provided for @historyCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'This version could not be loaded'**
  String get historyCouldNotLoad;

  /// No description provided for @historyNotADocument.
  ///
  /// In en, this message translates to:
  /// **'This item is not a document.'**
  String get historyNotADocument;

  /// No description provided for @historyNoRevision.
  ///
  /// In en, this message translates to:
  /// **'This version has no revision.'**
  String get historyNoRevision;

  /// Fallback title of an unnamed version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get historyVersion;

  /// No description provided for @historyNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get historyNoChanges;

  /// No description provided for @historyChangeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}'**
  String historyChangeCount(int count);

  /// No description provided for @historyChangeOf.
  ///
  /// In en, this message translates to:
  /// **'Change {index} of {count}'**
  String historyChangeOf(int index, int count);

  /// No description provided for @historyPreviousChange.
  ///
  /// In en, this message translates to:
  /// **'Previous change'**
  String get historyPreviousChange;

  /// No description provided for @historyNextChange.
  ///
  /// In en, this message translates to:
  /// **'Next change'**
  String get historyNextChange;

  /// No description provided for @historyMakeCopy.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get historyMakeCopy;

  /// Name of a copy of a document version.
  ///
  /// In en, this message translates to:
  /// **'Copy of {name}'**
  String historyCopyOf(String name);

  /// No description provided for @historyCopyCreated.
  ///
  /// In en, this message translates to:
  /// **'Copy created'**
  String get historyCopyCreated;

  /// No description provided for @historyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get historyOpen;

  /// No description provided for @historyCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make a copy'**
  String get historyCopyFailed;

  /// No description provided for @historyShowChangesBy.
  ///
  /// In en, this message translates to:
  /// **'Show changes by {name}'**
  String historyShowChangesBy(String name);

  /// No description provided for @historyHideChangesBy.
  ///
  /// In en, this message translates to:
  /// **'Hide changes by {name}'**
  String historyHideChangesBy(String name);

  /// No description provided for @outlineHeadingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 heading} other{{count} headings}}'**
  String outlineHeadingCount(int count);

  /// No description provided for @outlineCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get outlineCollapseAll;

  /// No description provided for @outlineExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get outlineExpandAll;

  /// No description provided for @outlineShowLevels.
  ///
  /// In en, this message translates to:
  /// **'Show levels'**
  String get outlineShowLevels;

  /// No description provided for @outlineHeading1Only.
  ///
  /// In en, this message translates to:
  /// **'Heading 1 only'**
  String get outlineHeading1Only;

  /// No description provided for @outlineUpToLevel.
  ///
  /// In en, this message translates to:
  /// **'Up to heading {level}'**
  String outlineUpToLevel(int level);

  /// No description provided for @outlineOptions.
  ///
  /// In en, this message translates to:
  /// **'Outline options'**
  String get outlineOptions;

  /// No description provided for @outlineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Headings you add to the document will appear here.'**
  String get outlineEmpty;

  /// No description provided for @outlineMakeHeading.
  ///
  /// In en, this message translates to:
  /// **'Turn this line into a heading'**
  String get outlineMakeHeading;

  /// No description provided for @outlineUntitledHeading.
  ///
  /// In en, this message translates to:
  /// **'Untitled heading'**
  String get outlineUntitledHeading;

  /// No description provided for @outlineExpandSection.
  ///
  /// In en, this message translates to:
  /// **'Expand “{heading}”'**
  String outlineExpandSection(String heading);

  /// No description provided for @outlineCollapseSection.
  ///
  /// In en, this message translates to:
  /// **'Collapse “{heading}”'**
  String outlineCollapseSection(String heading);

  /// Name shown at your own caret from another tab or window.
  ///
  /// In en, this message translates to:
  /// **'You (other tab)'**
  String get presenceYouOtherTab;

  /// Name of a collaborator whose name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get presenceSomeone;

  /// No description provided for @sessionNotADocument.
  ///
  /// In en, this message translates to:
  /// **'This is not a document.'**
  String get sessionNotADocument;

  /// Undo label (Edit › Undo <label>) for a document metadata change.
  ///
  /// In en, this message translates to:
  /// **'Change document settings'**
  String get sessionUndoChangeSettings;

  /// Undo label for assigning a document theme.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get sessionUndoChangeTheme;

  /// Undo label for changing the page setup.
  ///
  /// In en, this message translates to:
  /// **'Change page setup'**
  String get sessionUndoChangePageSetup;

  /// Undo label for changing the document language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get sessionUndoChangeLanguage;

  /// No description provided for @sessionDocumentFull.
  ///
  /// In en, this message translates to:
  /// **'This document reached its maximum size'**
  String get sessionDocumentFull;

  /// Toast when the user's role on the open document changes; role is one of the sessionRole* names.
  ///
  /// In en, this message translates to:
  /// **'Your access changed to {role}'**
  String sessionAccessChanged(String role);

  /// No description provided for @sessionRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get sessionRoleViewer;

  /// No description provided for @sessionRoleCommenter.
  ///
  /// In en, this message translates to:
  /// **'Commenter'**
  String get sessionRoleCommenter;

  /// No description provided for @sessionRoleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get sessionRoleEditor;

  /// No description provided for @sessionRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get sessionRoleOwner;

  /// No description provided for @sessionRejectTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The document would exceed its maximum size.'**
  String get sessionRejectTooLarge;

  /// No description provided for @sessionRejectForbidden.
  ///
  /// In en, this message translates to:
  /// **'You no longer have permission to edit.'**
  String get sessionRejectForbidden;

  /// No description provided for @sessionRejectTooOld.
  ///
  /// In en, this message translates to:
  /// **'Your offline changes are too old to be merged.'**
  String get sessionRejectTooOld;

  /// No description provided for @sessionOfflineChangesNotMerged.
  ///
  /// In en, this message translates to:
  /// **'Your offline changes couldn\'t be merged'**
  String get sessionOfflineChangesNotMerged;

  /// No description provided for @sessionChangesNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Some of your changes could not be saved'**
  String get sessionChangesNotSaved;

  /// No description provided for @sessionSaveOfflineChangesAsCopy.
  ///
  /// In en, this message translates to:
  /// **'Save my offline changes as a copy'**
  String get sessionSaveOfflineChangesAsCopy;

  /// No description provided for @sessionSaveChangesAsCopy.
  ///
  /// In en, this message translates to:
  /// **'Save them as a copy'**
  String get sessionSaveChangesAsCopy;

  /// Name of a new document holding offline changes that could not be merged.
  ///
  /// In en, this message translates to:
  /// **'{title} (offline changes)'**
  String sessionCopyNameOfflineChanges(String title);

  /// Name of a new document holding the user's changes that could not be saved.
  ///
  /// In en, this message translates to:
  /// **'{title} (my changes)'**
  String sessionCopyNameMyChanges(String title);

  /// No description provided for @sessionCopySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved a copy'**
  String get sessionCopySaved;

  /// No description provided for @sessionCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save a copy'**
  String get sessionCopyFailed;

  /// Toast action that opens a document.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get sessionOpen;

  /// No description provided for @offlineChangesSavedAsCopy.
  ///
  /// In en, this message translates to:
  /// **'Your offline changes to “{name}” were saved as a copy'**
  String offlineChangesSavedAsCopy(String name);

  /// No description provided for @exportFormatMd.
  ///
  /// In en, this message translates to:
  /// **'Markdown (.md)'**
  String get exportFormatMd;

  /// No description provided for @exportFormatMdZip.
  ///
  /// In en, this message translates to:
  /// **'Markdown with images (.zip)'**
  String get exportFormatMdZip;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF document (.pdf)'**
  String get exportFormatPdf;

  /// No description provided for @exportFormatHtml.
  ///
  /// In en, this message translates to:
  /// **'Web page (.html)'**
  String get exportFormatHtml;

  /// No description provided for @exportFormatHtmlZip.
  ///
  /// In en, this message translates to:
  /// **'Web page, zipped (.zip)'**
  String get exportFormatHtmlZip;

  /// No description provided for @exportFormatDocx.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Word (.docx)'**
  String get exportFormatDocx;

  /// No description provided for @exportFormatOdt.
  ///
  /// In en, this message translates to:
  /// **'OpenDocument text (.odt)'**
  String get exportFormatOdt;

  /// No description provided for @exportFormatRtf.
  ///
  /// In en, this message translates to:
  /// **'Rich Text Format (.rtf)'**
  String get exportFormatRtf;

  /// No description provided for @exportFormatEpub.
  ///
  /// In en, this message translates to:
  /// **'EPUB publication (.epub)'**
  String get exportFormatEpub;

  /// No description provided for @exportFormatTxt.
  ///
  /// In en, this message translates to:
  /// **'Plain text (.txt)'**
  String get exportFormatTxt;

  /// Title of the desktop save dialog.
  ///
  /// In en, this message translates to:
  /// **'Save {fileName}'**
  String exportSaveDialogTitle(String fileName);

  /// No description provided for @importDialogTitleMany.
  ///
  /// In en, this message translates to:
  /// **'Import documents'**
  String get importDialogTitleMany;

  /// No description provided for @importDialogTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get importDialogTitleOne;

  /// Name of an imported document when the file gives none.
  ///
  /// In en, this message translates to:
  /// **'Imported document'**
  String get importDefaultName;

  /// No description provided for @importProblemUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{fileName}: unsupported file type'**
  String importProblemUnsupported(String fileName);

  /// No description provided for @importProblemInexact.
  ///
  /// In en, this message translates to:
  /// **'{fileName}: {count, plural, =1{1 element couldn\'t be imported exactly} other{{count} elements couldn\'t be imported exactly}}'**
  String importProblemInexact(String fileName, int count);

  /// No description provided for @importProblemFailed.
  ///
  /// In en, this message translates to:
  /// **'{fileName}: {error}'**
  String importProblemFailed(String fileName, String error);

  /// No description provided for @importToastImportedOne.
  ///
  /// In en, this message translates to:
  /// **'Imported “{name}”'**
  String importToastImportedOne(String name);

  /// No description provided for @importToastImportedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 document} other{Imported {count} documents}}'**
  String importToastImportedMany(int count);

  /// No description provided for @importToastFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importToastFailed;

  /// No description provided for @importBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 element couldn\'t be imported exactly} other{{count} elements couldn\'t be imported exactly}}'**
  String importBannerTitle(int count);

  /// No description provided for @importBannerDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get importBannerDetails;

  /// No description provided for @importBannerHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get importBannerHideDetails;

  /// No description provided for @importBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get importBannerDismiss;

  /// Error of /import?file= (Drive's Open with ▸ Wonky Write) without a connection.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet to open this file in Wonky Write.'**
  String get importRouteOffline;

  /// No description provided for @importRouteNotAFile.
  ///
  /// In en, this message translates to:
  /// **'This item isn\'t an uploaded file.'**
  String get importRouteNotAFile;

  /// No description provided for @importRouteUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Wonky Write can\'t open “{fileName}”.'**
  String importRouteUnsupported(String fileName);

  /// No description provided for @importRouteUploading.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” is still uploading. Try again when the upload has finished.'**
  String importRouteUploading(String fileName);

  /// Overlay of an image whose background upload was refused because the storage quota is full (Drive 03 §6.3).
  ///
  /// In en, this message translates to:
  /// **'Not uploaded — out of storage'**
  String get imageNotUploadedOutOfStorage;

  /// No description provided for @imageRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get imageRetry;

  /// No description provided for @imageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get imageRemove;

  /// No description provided for @printNoServer.
  ///
  /// In en, this message translates to:
  /// **'No server connection'**
  String get printNoServer;

  /// No description provided for @printUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Printing isn’t available here'**
  String get printUnavailableTitle;

  /// No description provided for @printUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Download the PDF and print it from your PDF viewer.'**
  String get printUnavailableBody;

  /// No description provided for @printDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get printDownloadPdf;

  /// No description provided for @printBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get printBack;

  /// No description provided for @printPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Print preview'**
  String get printPreviewTitle;

  /// No description provided for @printPreviewTitleWithName.
  ///
  /// In en, this message translates to:
  /// **'Print preview — {title}'**
  String printPreviewTitleWithName(String title);

  /// No description provided for @printPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'The preview could not be created'**
  String get printPreviewFailed;

  /// No description provided for @printTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get printTryAgain;

  /// No description provided for @printDownloadsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'The owner turned off printing and downloads'**
  String get printDownloadsDisabledTitle;

  /// No description provided for @printDownloadsDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Ask an editor for a copy.'**
  String get printDownloadsDisabledBody;

  /// No description provided for @printSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get printSettings;

  /// No description provided for @printPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String printPageCount(int count);

  /// No description provided for @printColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get printColors;

  /// No description provided for @printColorsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get printColorsLight;

  /// No description provided for @printColorsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get printColorsDark;

  /// No description provided for @printSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get printSuggestions;

  /// No description provided for @printSuggestionsAccepted.
  ///
  /// In en, this message translates to:
  /// **'As if accepted'**
  String get printSuggestionsAccepted;

  /// No description provided for @printSuggestionsOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get printSuggestionsOriginal;

  /// No description provided for @printHeaderFooter.
  ///
  /// In en, this message translates to:
  /// **'Header & footer'**
  String get printHeaderFooter;

  /// No description provided for @printToc.
  ///
  /// In en, this message translates to:
  /// **'Table of contents'**
  String get printToc;

  /// No description provided for @printPageSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Paper size, margins and the header text come from the document’s page setup (File › Page setup…).'**
  String get printPageSetupHint;

  /// Fallback title of the browser print job.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get printDocumentTitle;

  /// No description provided for @printPdfReady.
  ///
  /// In en, this message translates to:
  /// **'PDF ready'**
  String get printPdfReady;

  /// No description provided for @printPdfReadyPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{PDF ready · 1 page} other{PDF ready · {count} pages}}'**
  String printPdfReadyPages(int count);

  /// No description provided for @printPdfDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Use Download PDF to save it.'**
  String get printPdfDesktopHint;

  /// Accessibility label of the embedded PDF viewer.
  ///
  /// In en, this message translates to:
  /// **'PDF preview'**
  String get printPdfPreviewLabel;

  /// Accessibility label of the spinner shown while the PDF is regenerated.
  ///
  /// In en, this message translates to:
  /// **'Updating the preview'**
  String get printUpdatingPreview;

  /// Undo step label of typed text (Undo history).
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get undoTyping;

  /// No description provided for @undoDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get undoDelete;

  /// No description provided for @undoEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get undoEdit;

  /// No description provided for @undoSlashCommand.
  ///
  /// In en, this message translates to:
  /// **'Slash command'**
  String get undoSlashCommand;

  /// No description provided for @undoClearFormatting.
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get undoClearFormatting;

  /// No description provided for @undoIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get undoIndent;

  /// No description provided for @undoOutdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get undoOutdent;

  /// No description provided for @undoCheckItem.
  ///
  /// In en, this message translates to:
  /// **'Check item'**
  String get undoCheckItem;

  /// No description provided for @undoUncheckItem.
  ///
  /// In en, this message translates to:
  /// **'Uncheck item'**
  String get undoUncheckItem;

  /// No description provided for @undoInsertLink.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get undoInsertLink;

  /// No description provided for @undoEditLink.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get undoEditLink;

  /// No description provided for @undoRemoveLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get undoRemoveLink;

  /// No description provided for @undoInsertDivider.
  ///
  /// In en, this message translates to:
  /// **'Insert divider'**
  String get undoInsertDivider;

  /// No description provided for @undoInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get undoInsertImage;

  /// No description provided for @undoInsertTable.
  ///
  /// In en, this message translates to:
  /// **'Insert table'**
  String get undoInsertTable;

  /// No description provided for @undoInsertText.
  ///
  /// In en, this message translates to:
  /// **'Insert text'**
  String get undoInsertText;

  /// No description provided for @undoSetCodeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Set code language'**
  String get undoSetCodeLanguage;

  /// No description provided for @undoExitCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Exit code block'**
  String get undoExitCodeBlock;

  /// No description provided for @undoMoveBlock.
  ///
  /// In en, this message translates to:
  /// **'Move block'**
  String get undoMoveBlock;

  /// No description provided for @undoDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get undoDuplicate;

  /// No description provided for @undoAltText.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get undoAltText;

  /// No description provided for @undoReplaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get undoReplaceImage;

  /// No description provided for @undoEditTable.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get undoEditTable;

  /// No description provided for @undoInsertRow.
  ///
  /// In en, this message translates to:
  /// **'Insert row'**
  String get undoInsertRow;

  /// No description provided for @undoInsertColumn.
  ///
  /// In en, this message translates to:
  /// **'Insert column'**
  String get undoInsertColumn;

  /// No description provided for @undoDeleteRow.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get undoDeleteRow;

  /// No description provided for @undoDeleteColumn.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get undoDeleteColumn;

  /// No description provided for @undoMoveRow.
  ///
  /// In en, this message translates to:
  /// **'Move row'**
  String get undoMoveRow;

  /// No description provided for @undoMoveColumn.
  ///
  /// In en, this message translates to:
  /// **'Move column'**
  String get undoMoveColumn;

  /// No description provided for @undoColumnAlignment.
  ///
  /// In en, this message translates to:
  /// **'Column alignment'**
  String get undoColumnAlignment;

  /// No description provided for @undoPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get undoPaste;

  /// No description provided for @undoReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get undoReplace;

  /// Screen-reader announcement after turning an inline format on (format: Bold, Italic…).
  ///
  /// In en, this message translates to:
  /// **'{format} on'**
  String announceFormatOn(String format);

  /// Screen-reader announcement after turning an inline format off.
  ///
  /// In en, this message translates to:
  /// **'{format} off'**
  String announceFormatOff(String format);

  /// Screen-reader announcement of a list item's nesting level after indenting.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String announceListLevel(int level);

  /// Accessibility label of the editor when the document has no title.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get editorDocumentTitle;

  /// Placeholder of an empty document (editor default).
  ///
  /// In en, this message translates to:
  /// **'Type / for commands, or just start writing'**
  String get editorHint;

  /// Accessibility label of an image without alt text.
  ///
  /// In en, this message translates to:
  /// **'image, no description'**
  String get editorImageNoDescription;

  /// No description provided for @editorImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get editorImageUnavailable;

  /// No description provided for @editorImageWaitingForUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting for upload'**
  String get editorImageWaitingForUpload;

  /// Placeholder of an image another collaborator is still uploading.
  ///
  /// In en, this message translates to:
  /// **'Waiting for upload from {name}'**
  String editorImageWaitingForUploadFrom(String name);

  /// No description provided for @editorCancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get editorCancelUpload;

  /// No description provided for @editorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get editorUploadFailed;

  /// Accessibility label of a table.
  ///
  /// In en, this message translates to:
  /// **'table, {columns} columns, {rows} rows'**
  String editorTableLabel(int columns, int rows);

  /// Tooltip of the table's edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get editorEditTable;

  /// Accessibility label of a quote block.
  ///
  /// In en, this message translates to:
  /// **'quote'**
  String get editorQuoteLabel;

  /// Accessibility label of a code block.
  ///
  /// In en, this message translates to:
  /// **'code block, {language}'**
  String editorCodeBlockLabel(String language);

  /// No description provided for @editorCodeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Code language'**
  String get editorCodeLanguage;

  /// No description provided for @editorCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get editorCopyCode;

  /// Accessibility label of a checklist item's checkbox.
  ///
  /// In en, this message translates to:
  /// **'checkbox'**
  String get editorCheckboxLabel;

  /// Placeholder of an embed of an unknown type.
  ///
  /// In en, this message translates to:
  /// **'Unsupported content ({type})'**
  String editorUnsupportedContent(String type);

  /// Accessibility label of a horizontal line.
  ///
  /// In en, this message translates to:
  /// **'separator'**
  String get editorSeparatorLabel;

  /// No description provided for @undoCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get undoCut;

  /// No description provided for @undoEditCell.
  ///
  /// In en, this message translates to:
  /// **'Edit cell'**
  String get undoEditCell;

  /// No description provided for @undoCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get undoCopyText;

  /// No description provided for @undoMoveText.
  ///
  /// In en, this message translates to:
  /// **'Move text'**
  String get undoMoveText;

  /// No description provided for @editorPasteTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This paste is too large'**
  String get editorPasteTooLarge;

  /// No description provided for @editorFormattingDropped.
  ///
  /// In en, this message translates to:
  /// **'Some formatting wasn\'t kept — Markdown supports bold, italic, strikethrough, code and links'**
  String get editorFormattingDropped;

  /// No description provided for @editorUnderlineHint.
  ///
  /// In en, this message translates to:
  /// **'Underline isn\'t available in Markdown — use italic or bold.'**
  String get editorUnderlineHint;

  /// No description provided for @editorUnderlineHintTheme.
  ///
  /// In en, this message translates to:
  /// **'Underline isn\'t available in Markdown — use italic or bold, or change how emphasis looks in Format › Theme.'**
  String get editorUnderlineHintTheme;

  /// No description provided for @editorTableDeleted.
  ///
  /// In en, this message translates to:
  /// **'This table was deleted'**
  String get editorTableDeleted;

  /// No description provided for @editorCellRemoved.
  ///
  /// In en, this message translates to:
  /// **'This cell was removed while you were editing'**
  String get editorCellRemoved;

  /// No description provided for @editorNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get editorNoResults;

  /// No description provided for @editorNoPeopleFound.
  ///
  /// In en, this message translates to:
  /// **'No people found'**
  String get editorNoPeopleFound;

  /// Title of a link card for a Wonky document whose name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Wonky document'**
  String get editorWonkyDocument;

  /// No description provided for @editorLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get editorLinkOpen;

  /// No description provided for @editorLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get editorLinkCopy;

  /// No description provided for @editorLinkEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorLinkEdit;

  /// No description provided for @editorLinkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get editorLinkRemove;

  /// No description provided for @slashText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get slashText;

  /// Slash menu item.
  ///
  /// In en, this message translates to:
  /// **'Heading {level}'**
  String slashHeading(int level);

  /// No description provided for @slashBulletedList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get slashBulletedList;

  /// No description provided for @slashNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get slashNumberedList;

  /// No description provided for @slashChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get slashChecklist;

  /// No description provided for @slashQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get slashQuote;

  /// No description provided for @slashCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get slashCodeBlock;

  /// No description provided for @slashDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get slashDivider;

  /// No description provided for @slashImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get slashImage;

  /// No description provided for @slashImageFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Image from URL'**
  String get slashImageFromUrl;

  /// No description provided for @slashTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get slashTable;

  /// No description provided for @slashLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get slashLink;

  /// No description provided for @slashMentionPerson.
  ///
  /// In en, this message translates to:
  /// **'Mention person'**
  String get slashMentionPerson;

  /// No description provided for @slashComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get slashComment;

  /// No description provided for @slashEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji…'**
  String get slashEmoji;

  /// No description provided for @slashSpecialCharacters.
  ///
  /// In en, this message translates to:
  /// **'Special characters…'**
  String get slashSpecialCharacters;

  /// No description provided for @slashAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI…'**
  String get slashAskAi;

  /// No description provided for @slashContinueWriting.
  ///
  /// In en, this message translates to:
  /// **'Continue writing'**
  String get slashContinueWriting;

  /// File menu / command: submit the story to the blog it was started for (specs/18 §4.4).
  ///
  /// In en, this message translates to:
  /// **'Submit to publication…'**
  String get cmdSubmissionSubmit;

  /// No description provided for @cmdSubmissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Submission status'**
  String get cmdSubmissionStatus;

  /// No description provided for @cmdSubmissionWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw submission'**
  String get cmdSubmissionWithdraw;

  /// No description provided for @cmdSubmissionDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from publication'**
  String get cmdSubmissionDisconnect;

  /// Title row button: sends the story to the publication's review queue.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @resubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get resubmitButton;

  /// No description provided for @submitUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Submit update'**
  String get submitUpdateButton;

  /// No description provided for @submitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Submit to {publication}'**
  String submitTooltip(String publication);

  /// No description provided for @submittingChip.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submittingChip;

  /// No description provided for @submitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit to {publication}'**
  String submitTitle(String publication);

  /// No description provided for @submitHostVerified.
  ///
  /// In en, this message translates to:
  /// **'{host} ✓'**
  String submitHostVerified(String host);

  /// No description provided for @submitHostUnverified.
  ///
  /// In en, this message translates to:
  /// **'Sent to {host} (Wonky hasn\'t verified this publication).'**
  String submitHostUnverified(String host);

  /// No description provided for @submitNotVerified.
  ///
  /// In en, this message translates to:
  /// **'{host} (not verified)'**
  String submitNotVerified(String host);

  /// No description provided for @submitOpenSuggestions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open suggestion isn\'t included: the original text is sent.} other{{count} open suggestions aren\'t included: the original text is sent.}}'**
  String submitOpenSuggestions(int count);

  /// No description provided for @submitCommentsStay.
  ///
  /// In en, this message translates to:
  /// **'Comments stay in Wonky. The moderators can read them.'**
  String get submitCommentsStay;

  /// No description provided for @submitFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get submitFieldTitle;

  /// No description provided for @submitFieldSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get submitFieldSummary;

  /// No description provided for @submitFieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get submitFieldTags;

  /// No description provided for @submitFieldCover.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get submitFieldCover;

  /// No description provided for @submitFieldBio.
  ///
  /// In en, this message translates to:
  /// **'Author bio'**
  String get submitFieldBio;

  /// No description provided for @submitFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note to the moderators'**
  String get submitFieldNote;

  /// No description provided for @submitOptional.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String submitOptional(String label);

  /// No description provided for @submitRequired.
  ///
  /// In en, this message translates to:
  /// **'Required.'**
  String get submitRequired;

  /// No description provided for @submitTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get submitTagsHint;

  /// No description provided for @submitTagsFrom.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, from: {tags}'**
  String submitTagsFrom(String tags);

  /// Submit dialog: shown in the empty cover image thumbnail.
  ///
  /// In en, this message translates to:
  /// **'No cover'**
  String get submitNoCover;

  /// Submit dialog: picks an image file and uploads it as the story's cover (specs/18 §4.2).
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get submitCoverUpload;

  /// Submit dialog: uploads another image in place of the cover.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get submitCoverReplace;

  /// Submit dialog: submits without a cover image.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get submitCoverRemove;

  /// No description provided for @submitCoverUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get submitCoverUploading;

  /// No description provided for @submitCoverFailed.
  ///
  /// In en, this message translates to:
  /// **'The image couldn\'t be uploaded. Try again.'**
  String get submitCoverFailed;

  /// No description provided for @submitCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Shown with your post. It isn\'t added to the document.'**
  String get submitCoverHint;

  /// No description provided for @submitTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to {publication}\'s contributor terms ({url})'**
  String submitTerms(String publication, String url);

  /// No description provided for @submitTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Agree to {publication}\'s contributor terms to submit.'**
  String submitTermsRequired(String publication);

  /// No description provided for @submitCoverRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a cover image.'**
  String get submitCoverRequired;

  /// No description provided for @submitDone.
  ///
  /// In en, this message translates to:
  /// **'Submitted to {publication}'**
  String submitDone(String publication);

  /// No description provided for @submitPending.
  ///
  /// In en, this message translates to:
  /// **'{publication} didn\'t answer yet. We\'ll keep trying.'**
  String submitPending(String publication);

  /// No description provided for @submitDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'{publication} couldn\'t receive your submission. Try again later.'**
  String submitDeliveryFailed(String publication);

  /// No description provided for @submittedBy.
  ///
  /// In en, this message translates to:
  /// **'Submitted by {name} · {date} · #{count}'**
  String submittedBy(String name, String date, int count);

  /// No description provided for @submitOpenThread.
  ///
  /// In en, this message translates to:
  /// **'Open messages'**
  String get submitOpenThread;

  /// No description provided for @submitViewPost.
  ///
  /// In en, this message translates to:
  /// **'View post'**
  String get submitViewPost;

  /// No description provided for @submitDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from {publication}'**
  String submitDisconnect(String publication);

  /// No description provided for @submitReasonNone.
  ///
  /// In en, this message translates to:
  /// **'This document isn\'t a story for a publication.'**
  String get submitReasonNone;

  /// No description provided for @submitReasonOffline.
  ///
  /// In en, this message translates to:
  /// **'Submitting needs a connection.'**
  String get submitReasonOffline;

  /// No description provided for @submitReasonClosed.
  ///
  /// In en, this message translates to:
  /// **'{publication} isn\'t accepting stories right now.'**
  String submitReasonClosed(String publication);

  /// No description provided for @submitReasonDeclined.
  ///
  /// In en, this message translates to:
  /// **'{publication} declined this story.'**
  String submitReasonDeclined(String publication);

  /// No description provided for @submitReasonNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes since you submitted.'**
  String get submitReasonNoChanges;

  /// No description provided for @submitReasonNotInReview.
  ///
  /// In en, this message translates to:
  /// **'The story isn\'t in review.'**
  String get submitReasonNotInReview;

  /// No description provided for @submitReasonWithdrawFirst.
  ///
  /// In en, this message translates to:
  /// **'Withdraw the story before you disconnect it.'**
  String get submitReasonWithdrawFirst;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw from {publication}?'**
  String withdrawTitle(String publication);

  /// No description provided for @withdrawBody.
  ///
  /// In en, this message translates to:
  /// **'{publication} is told, and its moderators lose access to the document. You can submit it again later.'**
  String withdrawBody(String publication);

  /// No description provided for @withdrawButton.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawButton;
}

class _WriteLocalizationsDelegate
    extends LocalizationsDelegate<WriteLocalizations> {
  const _WriteLocalizationsDelegate();

  @override
  Future<WriteLocalizations> load(Locale locale) {
    return SynchronousFuture<WriteLocalizations>(
      lookupWriteLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_WriteLocalizationsDelegate old) => false;
}

WriteLocalizations lookupWriteLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return WriteLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return WriteLocalizationsEn();
  }

  throw FlutterError(
    'WriteLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
