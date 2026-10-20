import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'drive_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of DriveLocalizations
/// returned by `DriveLocalizations.of(context)`.
///
/// Applications need to include `DriveLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/drive_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: DriveLocalizations.localizationsDelegates,
///   supportedLocales: DriveLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the DriveLocalizations.supportedLocales
/// property.
abstract class DriveLocalizations {
  DriveLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static DriveLocalizations of(BuildContext context) {
    return Localizations.of<DriveLocalizations>(context, DriveLocalizations)!;
  }

  static const LocalizationsDelegate<DriveLocalizations> delegate =
      _DriveLocalizationsDelegate();

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

  /// Default name of a new item in Wonky Drive (Drive creates no items of its own).
  ///
  /// In en, this message translates to:
  /// **'Untitled file'**
  String get untitledFile;

  /// Button on placeholder pages that returns to the Drive home.
  ///
  /// In en, this message translates to:
  /// **'Back to Drive'**
  String get backToDrive;

  /// Drive settings section (Drive 04 §8).
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get driveSettingsSection;

  /// Title of the Storage page (Drive 04 §6).
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// Spinner label while a file preview loads (Drive 02 §6.1).
  ///
  /// In en, this message translates to:
  /// **'Loading preview…'**
  String get previewLoading;

  /// Preview state of a file whose upload has not finished.
  ///
  /// In en, this message translates to:
  /// **'This file is still uploading'**
  String get previewUploadingTitle;

  /// Preview state with upload progress.
  ///
  /// In en, this message translates to:
  /// **'This file is still uploading ({percent} %)'**
  String previewUploadingPercent(int percent);

  /// Description under the uploading state.
  ///
  /// In en, this message translates to:
  /// **'The preview appears when the upload is complete.'**
  String get previewUploadingDescription;

  /// Title of the preview error state.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the preview'**
  String get previewErrorTitle;

  /// Description of the generic preview error state.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again, or download the file.'**
  String get previewErrorDescription;

  /// Button that reloads a failed preview.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get previewRetry;

  /// Preview state when offline and the file is not cached.
  ///
  /// In en, this message translates to:
  /// **'Previews aren\'t available offline'**
  String get previewOfflineTitle;

  /// Description of the offline preview state.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to see this file.'**
  String get previewOfflineDescription;

  /// Title of the too-large preview state.
  ///
  /// In en, this message translates to:
  /// **'Preview isn\'t available for this file'**
  String get previewTooLargeTitle;

  /// Description of the too-large preview state.
  ///
  /// In en, this message translates to:
  /// **'Files over {size} (and images over 50 megapixels without a server preview) aren\'t previewed. Download the file to open it.'**
  String previewTooLargeDescription(String size);

  /// Preview error for an image that does not decode.
  ///
  /// In en, this message translates to:
  /// **'This image can\'t be displayed. The file may be damaged.'**
  String get previewImageBroken;

  /// Preview error for a text file whose bytes are binary.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be shown as text. It contains binary data.'**
  String get previewNotText;

  /// Title when the previewed item does not exist or is not accessible.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t available'**
  String get previewNotFoundTitle;

  /// Description of the not-found preview state.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or you don\'t have access to it.'**
  String get previewNotFoundDescription;

  /// Shown while a non-file item opened at /file/ is redirected to its app.
  ///
  /// In en, this message translates to:
  /// **'Opening in its app…'**
  String get previewOpeningInApp;

  /// Banner on the preview of a trashed file.
  ///
  /// In en, this message translates to:
  /// **'This file is in the trash'**
  String get previewTrashedBanner;

  /// Button on the trashed banner that restores the file.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get previewRestore;

  /// Download button of the preview (Drive 04 §6).
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get previewDownload;

  /// Tooltip of the disabled Download button.
  ///
  /// In en, this message translates to:
  /// **'The owner has turned off downloads for viewers'**
  String get previewDownloadDisabled;

  /// Toast when downloads are not supported on the platform (desktop).
  ///
  /// In en, this message translates to:
  /// **'Downloads aren\'t available in this version of Wonky Drive yet.'**
  String get previewDownloadUnavailable;

  /// Toast when starting a download fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the download'**
  String get previewDownloadFailed;

  /// Open with dropdown of the preview top bar.
  ///
  /// In en, this message translates to:
  /// **'Open with'**
  String get previewOpenWith;

  /// Open with menu item / button.
  ///
  /// In en, this message translates to:
  /// **'Open with {app}'**
  String previewOpenWithApp(String app);

  /// Share button of the preview top bar.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get previewShare;

  /// Star button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to starred'**
  String get previewStar;

  /// Unstar button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from starred'**
  String get previewUnstar;

  /// Details panel toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get previewDetails;

  /// Tooltip of the ⋮ menu of the preview.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get previewMore;

  /// Tooltip of the close / back buttons of the preview.
  ///
  /// In en, this message translates to:
  /// **'Close preview'**
  String get previewClose;

  /// ⋮ menu item.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get previewRename;

  /// ⋮ menu item.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get previewMove;

  /// ⋮ menu item.
  ///
  /// In en, this message translates to:
  /// **'Make a copy'**
  String get previewCopy;

  /// ⋮ menu item.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get previewTrash;

  /// Tooltip of the next-file arrow.
  ///
  /// In en, this message translates to:
  /// **'Next file'**
  String get previewNext;

  /// Tooltip of the previous-file arrow.
  ///
  /// In en, this message translates to:
  /// **'Previous file'**
  String get previewPrevious;

  /// Position of the file in its folder (Drive 04 §6).
  ///
  /// In en, this message translates to:
  /// **'{index} of {count} in “{folder}”'**
  String previewPosition(int index, int count, String folder);

  /// Position of the file when the folder name is unknown.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String previewPositionNoFolder(int index, int count);

  /// Viewer bar button.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get previewZoomIn;

  /// Viewer bar button.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get previewZoomOut;

  /// Viewer bar button: fit the image to the window.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get previewZoomFit;

  /// Viewer bar button: 100 %.
  ///
  /// In en, this message translates to:
  /// **'Actual size'**
  String get previewZoomActual;

  /// Viewer bar button: rotate the image view 90°.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get previewRotate;

  /// Zoom level label.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String previewZoomPercent(int percent);

  /// Image pixel size in the viewer bar.
  ///
  /// In en, this message translates to:
  /// **'{width} × {height}'**
  String previewImageSize(int width, int height);

  /// Accessibility label of the previewed image.
  ///
  /// In en, this message translates to:
  /// **'{name}, {width} by {height} pixels'**
  String previewImageSemantics(String name, int width, int height);

  /// Viewer bar note when the server preview image is shown instead of the original.
  ///
  /// In en, this message translates to:
  /// **'Showing a smaller preview'**
  String get previewServerPreviewNote;

  /// Viewer bar toggle of the text viewer.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get previewWrap;

  /// Viewer bar button that copies the whole text.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get previewCopyAll;

  /// Toast after Copy all.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard'**
  String get previewCopied;

  /// Line count in the text viewer bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String previewLines(int count);

  /// Language label of text without highlighting.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get previewPlainText;

  /// Notice when a text file is not UTF-8 (Drive 02 §6.4).
  ///
  /// In en, this message translates to:
  /// **'Shown as Latin-1'**
  String get previewLatin1;

  /// Notice when a text file is larger than 1 MB.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 1 MB. Download to see the whole file.'**
  String get previewTextTruncated;

  /// CSV viewer toggle: table view.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get previewCsvTable;

  /// CSV viewer toggle: text view.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get previewCsvText;

  /// Notice when a CSV file has more rows than the table shows.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} rows.'**
  String previewCsvTruncated(int count);

  /// Row count of the CSV table.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row} other{{count} rows}}'**
  String previewCsvRows(int count);

  /// Title of the "everything else" card (Drive 02 §6.7).
  ///
  /// In en, this message translates to:
  /// **'No preview available'**
  String get previewNoPreview;

  /// Type and size line of the file card ("ZIP archive · 12.4 MB").
  ///
  /// In en, this message translates to:
  /// **'{type} · {size}'**
  String previewTypeSize(String type, String size);

  /// Owner line of the file card.
  ///
  /// In en, this message translates to:
  /// **'Owned by you'**
  String get previewOwnedByMe;

  /// Owner line of the file card.
  ///
  /// In en, this message translates to:
  /// **'Owned by {name}'**
  String previewOwnedBy(String name);

  /// Modified line of the file card.
  ///
  /// In en, this message translates to:
  /// **'Modified {date}'**
  String previewModified(String date);

  /// Type label of an uploaded file by category; ext is the upper-case extension (may be "File").
  ///
  /// In en, this message translates to:
  /// **'{category, select, image{{ext} image} pdf{PDF document} text{{ext} text file} audio{{ext} audio} video{{ext} video} archive{{ext} archive} document{{ext} document} spreadsheet{{ext} spreadsheet} presentation{{ext} presentation} other{{ext} file}}'**
  String fileTypeLabel(String category, String ext);

  /// Type label of a file without an extension.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileTypeGeneric;

  /// Command category of the file preview commands.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get categoryPreview;

  /// Command drive.file.preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get cmdPreviewFile;

  /// Command drive.file.openWith.
  ///
  /// In en, this message translates to:
  /// **'Open with…'**
  String get cmdOpenWith;

  /// Command drive.file.download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get cmdDownloadFile;

  /// Command drive.preview.next.
  ///
  /// In en, this message translates to:
  /// **'Next file'**
  String get cmdPreviewNext;

  /// Command drive.preview.previous.
  ///
  /// In en, this message translates to:
  /// **'Previous file'**
  String get cmdPreviewPrevious;

  /// Command drive.preview.zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get cmdPreviewZoomIn;

  /// Command drive.preview.zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get cmdPreviewZoomOut;

  /// Command drive.preview.zoomFit.
  ///
  /// In en, this message translates to:
  /// **'Fit to window'**
  String get cmdPreviewZoomFit;

  /// Command drive.preview.zoomActual.
  ///
  /// In en, this message translates to:
  /// **'Actual size'**
  String get cmdPreviewZoomActual;

  /// Command drive.preview.rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate view'**
  String get cmdPreviewRotate;

  /// Command drive.preview.toggleWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get cmdPreviewToggleWrap;

  /// Command drive.preview.copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all text'**
  String get cmdPreviewCopyAll;

  /// Command drive.preview.close.
  ///
  /// In en, this message translates to:
  /// **'Close preview'**
  String get cmdPreviewClose;

  /// Command palette category of the upload commands (Drive 04 §9).
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get categoryUploads;

  /// Command drive.upload.files (drop and picker handler).
  ///
  /// In en, this message translates to:
  /// **'Upload files'**
  String get cmdUploadFiles;

  /// Command drive.upload.cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get cmdUploadCancel;

  /// Command drive.upload.cancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel all uploads'**
  String get cmdUploadCancelAll;

  /// Command drive.upload.retry.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get cmdUploadRetry;

  /// Command drive.upload.retryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry failed uploads'**
  String get cmdUploadRetryAll;

  /// Command drive.upload.remove (removes a row of the upload panel).
  ///
  /// In en, this message translates to:
  /// **'Remove upload'**
  String get cmdUploadRemove;

  /// Command drive.upload.clearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished uploads'**
  String get cmdUploadClearFinished;

  /// Command drive.upload.togglePanel.
  ///
  /// In en, this message translates to:
  /// **'Show uploads'**
  String get cmdUploadTogglePanel;

  /// Title of the file picker of File upload… in Wonky Drive.
  ///
  /// In en, this message translates to:
  /// **'Upload files'**
  String get uploadPickTitle;

  /// Accessibility label of the upload panel.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get uploadPanelLabel;

  /// Upload panel header while uploads run.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Uploading 1 item} other{Uploading {count} items}}'**
  String uploadPanelUploading(int count);

  /// Upload panel header while offline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 upload waiting for connection} other{{count} uploads waiting for connection}}'**
  String uploadPanelWaiting(int count);

  /// Upload panel header when everything is uploaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Uploads} =1{1 upload complete} other{{count} uploads complete}}'**
  String uploadPanelComplete(int count);

  /// Upload panel header when uploads failed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 upload failed} other{{count} uploads failed}}'**
  String uploadPanelFailed(int count);

  /// Time left of the uploads, under a minute.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left'**
  String uploadSecondsLeft(int seconds);

  /// Time left of the uploads, in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String uploadMinutesLeft(int minutes);

  /// Collapsed upload panel.
  ///
  /// In en, this message translates to:
  /// **'Uploading {count} · {percent} %'**
  String uploadPill(int count, int percent);

  /// Collapsed upload panel while every upload waits for the connection (offline).
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String uploadPillWaiting(int count);

  /// Button that collapses the upload panel to a pill.
  ///
  /// In en, this message translates to:
  /// **'Collapse uploads'**
  String get uploadPanelCollapse;

  /// Button that closes the upload panel.
  ///
  /// In en, this message translates to:
  /// **'Close uploads'**
  String get uploadPanelClose;

  /// Upload row status: waiting for a free slot.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get uploadStatusQueued;

  /// Upload row status while offline.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get uploadStatusWaiting;

  /// Upload row status while the upload is created on the server.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get uploadStatusStarting;

  /// Upload row status: progress.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String uploadStatusPercent(int percent);

  /// Upload row status while the server checks the bytes.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get uploadStatusVerifying;

  /// Upload row status when done.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadStatusDone;

  /// Upload row status after cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get uploadStatusCancelled;

  /// Upload row status: the quota doesn't fit the file.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded — you\'re out of storage'**
  String get uploadFailedOutOfStorage;

  /// Upload row status after repeated network failures.
  ///
  /// In en, this message translates to:
  /// **'Failed — network error'**
  String get uploadFailedNetwork;

  /// Upload row status: the file is over the size limit.
  ///
  /// In en, this message translates to:
  /// **'Too large — files can be at most {max}'**
  String uploadFailedTooLarge(String max);

  /// Upload row status: the target folder was deleted or access was lost.
  ///
  /// In en, this message translates to:
  /// **'The folder is gone or you lost access to it'**
  String get uploadFailedFolderGone;

  /// Upload row status: upload rate limit.
  ///
  /// In en, this message translates to:
  /// **'Too many uploads — try again later'**
  String get uploadFailedRateLimited;

  /// Upload row status after a reload when the bytes were only held in memory.
  ///
  /// In en, this message translates to:
  /// **'Add the file again — it wasn\'t saved on this device.'**
  String get uploadFailedNotSaved;

  /// Upload row status for other errors.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get uploadFailedOther;

  /// Hint on rows whose bytes are held in memory only (no OPFS).
  ///
  /// In en, this message translates to:
  /// **'keep this tab open'**
  String get uploadVolatileHint;

  /// Row action (accessibility label).
  ///
  /// In en, this message translates to:
  /// **'Cancel upload of {name}'**
  String uploadActionCancel(String name);

  /// Row action (accessibility label).
  ///
  /// In en, this message translates to:
  /// **'Retry upload of {name}'**
  String uploadActionRetry(String name);

  /// Row action (accessibility label).
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the list'**
  String uploadActionRemove(String name);

  /// Row action of a finished upload (accessibility label).
  ///
  /// In en, this message translates to:
  /// **'Show {name} in its folder'**
  String uploadActionShowInFolder(String name);

  /// Row action when the target folder is gone.
  ///
  /// In en, this message translates to:
  /// **'Upload to My Drive'**
  String get uploadActionToMyDrive;

  /// Row action when the bytes weren't saved on this device.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get uploadActionChooseFile;

  /// Opens the Storage page (quota failures).
  ///
  /// In en, this message translates to:
  /// **'Manage storage'**
  String get uploadManageStorage;

  /// Upload panel footer button.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get uploadRetryAll;

  /// Upload panel footer button.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get uploadClearFinished;

  /// Screen reader announcement.
  ///
  /// In en, this message translates to:
  /// **'Upload of {name} complete'**
  String uploadAnnounceDone(String name);

  /// Screen reader announcement.
  ///
  /// In en, this message translates to:
  /// **'Upload of {name} failed'**
  String uploadAnnounceFailed(String name);

  /// Cancel button of the upload dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get uploadDialogCancel;

  /// Title of the name-conflict dialog (Drive 02 §3.2).
  ///
  /// In en, this message translates to:
  /// **'Upload options'**
  String get uploadConflictTitle;

  /// Name-conflict dialog body, one file.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists in {folder}. Keep both files, or skip this one?'**
  String uploadConflictBodyOne(String name, String folder);

  /// Name-conflict dialog body, several files.
  ///
  /// In en, this message translates to:
  /// **'{count} files already exist in {folder}. Keep both versions of each, or skip them?'**
  String uploadConflictBodyMany(int count, String folder);

  /// Name-conflict choice: upload with a numbered name.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get uploadConflictKeepBoth;

  /// Name-conflict choice: don't upload the files with existing names.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get uploadConflictSkip;

  /// Name of the user's drive root in upload texts.
  ///
  /// In en, this message translates to:
  /// **'My Drive'**
  String get uploadMyDrive;

  /// Confirm when closing the upload panel while uploads run.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Cancel 1 upload?} other{Cancel {count} uploads?}}'**
  String uploadCancelAllTitle(int count);

  /// Body of the cancel-uploads confirm.
  ///
  /// In en, this message translates to:
  /// **'Files that haven\'t finished uploading won\'t be saved.'**
  String get uploadCancelAllBody;

  /// Confirm button of the cancel-uploads dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel uploads'**
  String get uploadCancelAllConfirm;

  /// Dismiss button of the cancel-uploads dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep uploading'**
  String get uploadKeepUploading;

  /// Toast when a batch has too many files.
  ///
  /// In en, this message translates to:
  /// **'You can upload at most {max} files at once.'**
  String uploadTooManyFiles(int max);

  /// Toast when a folder is dropped offline.
  ///
  /// In en, this message translates to:
  /// **'Folders can only be uploaded while you\'re online. The other files were added.'**
  String get uploadFolderNeedsConnection;

  /// Toast when creating the folders of a folder upload failed.
  ///
  /// In en, this message translates to:
  /// **'The folders couldn\'t be created'**
  String get uploadFolderFailed;

  /// Share of the quota used, next to the Storage page headline.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String storagePercent(int percent);

  /// Storage page: how far usage is over the quota.
  ///
  /// In en, this message translates to:
  /// **'Over by {size}'**
  String storageOverBy(String size);

  /// Legend entry of the unused part of the quota.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get storageLegendFree;

  /// Screen reader label prefix of the usage bar.
  ///
  /// In en, this message translates to:
  /// **'Storage by type'**
  String get storageBreakdownLabel;

  /// Storage page button that empties the trash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get storageEmptyTrash;

  /// Storage page section with clean-up suggestions.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get storageFreeUpTitle;

  /// Empty trash suggestion card.
  ///
  /// In en, this message translates to:
  /// **'Frees {size}'**
  String storageCardTrashBody(String size);

  /// Suggestion card of items of 1 MB or more.
  ///
  /// In en, this message translates to:
  /// **'Large files'**
  String get storageCardLargeTitle;

  /// Large files suggestion card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file over 1 MB} other{{count} files over 1 MB}}'**
  String storageCardLargeBody(int count);

  /// Suggestion card of items nobody opened for 6 months.
  ///
  /// In en, this message translates to:
  /// **'Not opened in 6 months'**
  String get storageCardNotOpenedTitle;

  /// Not opened suggestion card: count and total size.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file · {size}} other{{count} files · {size}}}'**
  String storageCardNotOpenedBody(int count, String size);

  /// Suggestion card when there are more matches than were counted.
  ///
  /// In en, this message translates to:
  /// **'More than {count} files'**
  String storageCardMore(int count);

  /// Button of a suggestion card that filters the list.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageCardReview;

  /// Free up space section without suggestions.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clean up right now.'**
  String get storageNothingToFree;

  /// Title of the Storage page table.
  ///
  /// In en, this message translates to:
  /// **'Items using storage'**
  String get storageItemsTitle;

  /// Type filter button of the Storage page.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String storageFilterLabel(String type);

  /// Storage type filter: everything.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storageFilterAll;

  /// Storage type filter.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get storageFilterDocuments;

  /// Storage type filter.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets'**
  String get storageFilterSpreadsheets;

  /// Storage type filter.
  ///
  /// In en, this message translates to:
  /// **'Presentations'**
  String get storageFilterPresentations;

  /// Storage type filter: uploaded files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get storageFilterFiles;

  /// Storage type filter: trashed items.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get storageFilterTrash;

  /// Storage filter of the Large files card.
  ///
  /// In en, this message translates to:
  /// **'Large files'**
  String get storageFilterLarge;

  /// Storage filter of the Not opened card.
  ///
  /// In en, this message translates to:
  /// **'Not opened in 6 months'**
  String get storageFilterNotOpened;

  /// Removes a suggestion filter of the Storage page table.
  ///
  /// In en, this message translates to:
  /// **'Show all items'**
  String get storageClearFilter;

  /// Storage table column.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get storageColumnName;

  /// Storage table column.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get storageColumnKind;

  /// Storage table column.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get storageColumnLocation;

  /// Storage table column.
  ///
  /// In en, this message translates to:
  /// **'Last opened'**
  String get storageColumnLastOpened;

  /// Storage table column: counted size.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageColumnStorage;

  /// Badge of a trashed row in the Storage table.
  ///
  /// In en, this message translates to:
  /// **'In trash'**
  String get storageInTrash;

  /// Screen reader text of an empty Last opened cell.
  ///
  /// In en, this message translates to:
  /// **'Never opened'**
  String get storageNeverOpened;

  /// Screen reader label of a Storage table row.
  ///
  /// In en, this message translates to:
  /// **'{name}, {kind}, {size}'**
  String storageRowLabel(String name, String kind, String size);

  /// Header checkbox of the Storage table.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get storageSelectAll;

  /// Row checkbox of the Storage table.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String storageSelectRow(String name);

  /// Selection bar of the Storage table.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected · {size}} other{{count} selected · {size}}}'**
  String storageSelectionSize(int count, String size);

  /// Selection bar: download the selected files.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get storageDownload;

  /// Selection bar: clear the selection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get storageClearSelection;

  /// Empty Storage table.
  ///
  /// In en, this message translates to:
  /// **'Nothing here uses storage'**
  String get storageEmptyTitle;

  /// Empty Storage table with a filter.
  ///
  /// In en, this message translates to:
  /// **'No items match this filter'**
  String get storageEmptyFilterTitle;

  /// Empty Storage table with the Trash filter.
  ///
  /// In en, this message translates to:
  /// **'The trash is empty'**
  String get storageEmptyTrashTitle;

  /// Storage table offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get storageOfflineTitle;

  /// Storage table offline.
  ///
  /// In en, this message translates to:
  /// **'The list of items needs a connection. The usage above is the last one saved on this device.'**
  String get storageOfflineBody;

  /// Storage table load error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your items'**
  String get storageErrorTitle;

  /// Footer while the next page loads.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get storageLoadingMore;

  /// Footer title of the Storage page.
  ///
  /// In en, this message translates to:
  /// **'What counts?'**
  String get storageWhatCountsTitle;

  /// Title of the empty-trash confirm of the Storage page.
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get storageEmptyTrashTitleConfirm;

  /// Empty-trash confirm (Drive 03 §6.4).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Permanently delete 1 item in the trash? This frees {size} and can\'t be undone.} other{Permanently delete {count} items in the trash? This frees {size} and can\'t be undone.}}'**
  String storageEmptyTrashBody(int count, String size);

  /// Empty-trash confirm when the item count is unknown.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete everything in the trash? This frees {size} and can\'t be undone.'**
  String storageEmptyTrashBodyUnknown(String size);

  /// Delete-forever confirm of the Storage page.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 item forever?} other{Delete {count} items forever?}}'**
  String storageDeleteTitle(int count);

  /// Delete-forever confirm of the Storage page.
  ///
  /// In en, this message translates to:
  /// **'This frees {size} and can\'t be undone.'**
  String storageDeleteBody(String size);

  /// Toast after deleting forever.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 item forever} other{Deleted {count} items forever}}'**
  String storageDeleted(int count);

  /// Toast after emptying the trash.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get storageTrashEmptied;

  /// Command palette category of the Storage page commands.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get categoryStorage;

  /// Command drive.storage.show: opens the Storage page (with a filter).
  ///
  /// In en, this message translates to:
  /// **'Show storage'**
  String get cmdStorageShow;

  /// Drive settings group of the list defaults.
  ///
  /// In en, this message translates to:
  /// **'Files list'**
  String get driveSettingsList;

  /// Drive settings group description.
  ///
  /// In en, this message translates to:
  /// **'Defaults for the lists in Wonky Drive. Changing the layout or sort in a list remembers it on this device.'**
  String get driveSettingsListHint;

  /// Drive setting.
  ///
  /// In en, this message translates to:
  /// **'Default layout'**
  String get driveSettingsLayout;

  /// Drive setting value.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get driveSettingsLayoutList;

  /// Drive setting value.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get driveSettingsLayoutGrid;

  /// Drive setting.
  ///
  /// In en, this message translates to:
  /// **'Default sort'**
  String get driveSettingsSort;

  /// Drive setting.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get driveSettingsSortOrder;

  /// Drive setting value.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get driveSettingsAscending;

  /// Drive setting value.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get driveSettingsDescending;

  /// Drive setting.
  ///
  /// In en, this message translates to:
  /// **'Show file extensions'**
  String get driveSettingsShowExtensions;

  /// Drive setting description.
  ///
  /// In en, this message translates to:
  /// **'When off, lists show \"notes\" for \"notes.pdf\". Dialogs and previews always show the full name.'**
  String get driveSettingsShowExtensionsHint;

  /// Drive settings group.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get driveSettingsUploads;

  /// Drive setting.
  ///
  /// In en, this message translates to:
  /// **'Ask when uploaded files have the same name'**
  String get driveSettingsAskOnConflict;

  /// Drive setting description.
  ///
  /// In en, this message translates to:
  /// **'When off, both files are kept and the new one gets a number, like \"notes (1).pdf\".'**
  String get driveSettingsAskOnConflictHint;

  /// Drive setting (Drive 02 §7.3).
  ///
  /// In en, this message translates to:
  /// **'Convert uploads to Wonky formats'**
  String get driveSettingsConvertUploads;

  /// Drive setting description.
  ///
  /// In en, this message translates to:
  /// **'Files that Wonky Write or Wonky Sheets can open, like Word, Markdown, Excel and CSV, become documents and spreadsheets instead of being stored as files.'**
  String get driveSettingsConvertUploadsHint;

  /// Command drive.prefs.set.
  ///
  /// In en, this message translates to:
  /// **'Change a Drive setting'**
  String get cmdDrivePrefsSet;

  /// Command drive.view.setLayout.
  ///
  /// In en, this message translates to:
  /// **'Grid or list view'**
  String get cmdViewSetLayout;

  /// Command drive.view.sort.
  ///
  /// In en, this message translates to:
  /// **'Sort by…'**
  String get cmdViewSort;

  /// Command drive.view.toggleFoldersOnTop.
  ///
  /// In en, this message translates to:
  /// **'Folders on top'**
  String get cmdViewToggleFoldersOnTop;

  /// Command palette category of the drive.view commands.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get categoryView;

  /// Upload panel row of an upload converted with Convert uploads to Wonky formats (Drive 02 §7.3).
  ///
  /// In en, this message translates to:
  /// **'{kind, select, document{Converted to a document} spreadsheet{Converted to a spreadsheet} other{Converted}}'**
  String uploadStatusConverted(String kind);

  /// Toast when converting an upload failed.
  ///
  /// In en, this message translates to:
  /// **'{name} couldn\'t be converted. It was kept as a file.'**
  String uploadConvertFailed(String name);

  /// Command: opens the usage analytics page (admins, specs/19).
  ///
  /// In en, this message translates to:
  /// **'Show analytics'**
  String get cmdAnalyticsShow;

  /// Command palette category of the analytics commands.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get categoryAnalytics;

  /// Title of the usage analytics page (specs/19 §3).
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// Note under the analytics title while it loads.
  ///
  /// In en, this message translates to:
  /// **'Usage of Wonky Work by UTC day.'**
  String get analyticsSubtitle;

  /// When the shown numbers were computed.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String analyticsUpdated(String time);

  /// Shown when activity tracking started inside the period (earlier days have no activity data).
  ///
  /// In en, this message translates to:
  /// **'Activity recorded since {date}'**
  String analyticsTrackingSince(String date);

  /// Shown before any activity was recorded.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get analyticsNoActivityYet;

  /// A period tab of the analytics page.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String analyticsPeriodDays(int days);

  /// Switch: count admins (Wonky Work team) in every number.
  ///
  /// In en, this message translates to:
  /// **'Include admins'**
  String get analyticsIncludeAdmins;

  /// Reloads the analytics.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get analyticsRefresh;

  /// Page state when a non-admin opens /analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics are for admins'**
  String get analyticsForbiddenTitle;

  /// Body of the admins-only state.
  ///
  /// In en, this message translates to:
  /// **'Ask a Wonky Work admin if you need these numbers.'**
  String get analyticsForbiddenBody;

  /// Error state of the analytics page.
  ///
  /// In en, this message translates to:
  /// **'The analytics could not be loaded'**
  String get analyticsErrorTitle;

  /// Toggles a chart card to its table view.
  ///
  /// In en, this message translates to:
  /// **'Show as table'**
  String get analyticsShowTable;

  /// Toggles a chart card back to its chart.
  ///
  /// In en, this message translates to:
  /// **'Show as chart'**
  String get analyticsShowChart;

  /// Screen reader label of a chart.
  ///
  /// In en, this message translates to:
  /// **'Chart of {series} from {from} to {to}'**
  String analyticsChartLabel(String series, String from, String to);

  /// Table view: the day column.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get analyticsColDay;

  /// Table view: the week column (weekly bars).
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get analyticsColWeek;

  /// Tooltip row: the total of stacked bars.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get analyticsTotal;

  /// Headline number: all accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get analyticsKpiAccounts;

  /// Under the accounts number: accounts created in the period.
  ///
  /// In en, this message translates to:
  /// **'+{count} in {days} days'**
  String analyticsKpiNew(String count, int days);

  /// Headline number: distinct active users today (UTC).
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get analyticsKpiToday;

  /// Under active today: how many of them created or edited something.
  ///
  /// In en, this message translates to:
  /// **'{count} created or edited'**
  String analyticsKpiEditorsToday(String count);

  /// Headline number: distinct active users in the last 7 days.
  ///
  /// In en, this message translates to:
  /// **'Weekly active'**
  String get analyticsKpiWeekly;

  /// Note under the weekly number.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get analyticsKpiWeeklyNote;

  /// Headline number: distinct active users in the last 30 days (MAU).
  ///
  /// In en, this message translates to:
  /// **'Monthly active'**
  String get analyticsKpiMonthly;

  /// Note under the monthly number.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get analyticsKpiMonthlyNote;

  /// Headline number: average daily active users over monthly active users.
  ///
  /// In en, this message translates to:
  /// **'Stickiness'**
  String get analyticsKpiStickiness;

  /// Note under stickiness.
  ///
  /// In en, this message translates to:
  /// **'Daily ÷ monthly active'**
  String get analyticsKpiStickinessNote;

  /// Headline number: documents, spreadsheets, presentations and files created in the period.
  ///
  /// In en, this message translates to:
  /// **'Items created'**
  String get analyticsKpiCreated;

  /// Note: the number covers the period.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String analyticsKpiInPeriod(int days);

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Active users'**
  String get analyticsActiveTitle;

  /// Card subtitle of active users.
  ///
  /// In en, this message translates to:
  /// **'People who used any app or MCP'**
  String get analyticsActiveSubtitle;

  /// Tab: daily active users.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get analyticsViewDaily;

  /// Tab: users active in the 7 days ending each day.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get analyticsViewWeekly;

  /// Tab: users active in the 30 days ending each day.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get analyticsViewMonthly;

  /// Series: daily active users.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get analyticsSeriesActive;

  /// Series: users who created or edited something that day.
  ///
  /// In en, this message translates to:
  /// **'Created or edited'**
  String get analyticsSeriesEditors;

  /// Series: 7-day active users.
  ///
  /// In en, this message translates to:
  /// **'Weekly active'**
  String get analyticsSeriesWeekly;

  /// Series: 30-day active users.
  ///
  /// In en, this message translates to:
  /// **'Monthly active'**
  String get analyticsSeriesMonthly;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Active users by app'**
  String get analyticsAppsTitle;

  /// Card subtitle.
  ///
  /// In en, this message translates to:
  /// **'A person using two apps counts in both'**
  String get analyticsAppsSubtitle;

  /// Series: users active through an MCP client.
  ///
  /// In en, this message translates to:
  /// **'MCP clients'**
  String get analyticsSeriesMcp;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Sign-ups'**
  String get analyticsSignupsTitle;

  /// Card subtitle: new accounts in the period and all accounts.
  ///
  /// In en, this message translates to:
  /// **'{count} new · {total} accounts'**
  String analyticsSignupsSubtitle(String count, String total);

  /// Series: accounts created.
  ///
  /// In en, this message translates to:
  /// **'Sign-ups'**
  String get analyticsSeriesSignups;

  /// Card title: items that exist now by kind.
  ///
  /// In en, this message translates to:
  /// **'Content now'**
  String get analyticsContentNowTitle;

  /// Line in the content card: items now and the storage they use.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {size} stored'**
  String analyticsItemsTotal(String count, String size);

  /// Heading of the sign-in methods bar.
  ///
  /// In en, this message translates to:
  /// **'Sign-in methods'**
  String get analyticsSignInTitle;

  /// Sign-in method: email and password.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get analyticsSignInEmail;

  /// Sign-in method: Google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get analyticsSignInGoogle;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Content created'**
  String get analyticsContentTitle;

  /// Card subtitle.
  ///
  /// In en, this message translates to:
  /// **'By people, the assistant and MCP; welcome content left out'**
  String get analyticsContentSubtitle;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get analyticsCollabTitle;

  /// Stat: items shared with at least one other person.
  ///
  /// In en, this message translates to:
  /// **'Items shared now'**
  String get analyticsStatShared;

  /// Stat: items edited by two or more people in the period.
  ///
  /// In en, this message translates to:
  /// **'Co-edited in {days} days'**
  String analyticsStatCoEdited(int days);

  /// Stat: people who commented in the period.
  ///
  /// In en, this message translates to:
  /// **'Commenters in {days} days'**
  String analyticsStatCommenters(int days);

  /// Series: comments and replies.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get analyticsSeriesComments;

  /// Series: items shared with people.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get analyticsSeriesShares;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get analyticsAiTitle;

  /// Card subtitle: AI usage in the period and how long it is kept.
  ///
  /// In en, this message translates to:
  /// **'{requests} requests · {tokens} tokens · kept {days} days'**
  String analyticsAiSubtitle(String requests, String tokens, int days);

  /// Series: AI model requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get analyticsSeriesAiRequests;

  /// Heading of AI usage by feature.
  ///
  /// In en, this message translates to:
  /// **'By feature'**
  String get analyticsAiByFeature;

  /// Heading of AI usage by model.
  ///
  /// In en, this message translates to:
  /// **'By model'**
  String get analyticsAiByModel;

  /// Value of an AI usage row.
  ///
  /// In en, this message translates to:
  /// **'{requests} · {tokens} tokens'**
  String analyticsAiRow(String requests, String tokens);

  /// Empty AI usage list.
  ///
  /// In en, this message translates to:
  /// **'No AI use in this period'**
  String get analyticsNoAiUse;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'MCP tool calls'**
  String get analyticsMcpTitle;

  /// Card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} calls by people\'s access tokens (admins included)'**
  String analyticsMcpSubtitle(String count);

  /// Series: MCP tool calls.
  ///
  /// In en, this message translates to:
  /// **'Tool calls'**
  String get analyticsSeriesMcpCalls;

  /// Card title: weekly sign-up cohorts.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get analyticsRetentionTitle;

  /// Card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Share of each week\'s sign-ups active in the weeks after'**
  String get analyticsRetentionSubtitle;

  /// Cohort table column: the sign-up week.
  ///
  /// In en, this message translates to:
  /// **'Signed up'**
  String get analyticsCohortWeek;

  /// Cohort table column: accounts in the cohort.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get analyticsCohortSize;

  /// Cohort table column: week N after sign-up.
  ///
  /// In en, this message translates to:
  /// **'W{week}'**
  String analyticsCohortWeekN(int week);

  /// Tooltip of a cohort cell.
  ///
  /// In en, this message translates to:
  /// **'Week of {cohort}: {active} active in week {week} ({share})'**
  String analyticsCohortCell(String cohort, int week, int active, String share);
}

class _DriveLocalizationsDelegate
    extends LocalizationsDelegate<DriveLocalizations> {
  const _DriveLocalizationsDelegate();

  @override
  Future<DriveLocalizations> load(Locale locale) {
    return SynchronousFuture<DriveLocalizations>(
      lookupDriveLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_DriveLocalizationsDelegate old) => false;
}

DriveLocalizations lookupDriveLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return DriveLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return DriveLocalizationsEn();
  }

  throw FlutterError(
    'DriveLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
