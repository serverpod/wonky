// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'drive_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DriveLocalizationsEn extends DriveLocalizations {
  DriveLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get untitledFile => 'Untitled file';

  @override
  String get backToDrive => 'Back to Drive';

  @override
  String get driveSettingsSection => 'Drive';

  @override
  String get storageTitle => 'Storage';

  @override
  String get previewLoading => 'Loading preview…';

  @override
  String get previewUploadingTitle => 'This file is still uploading';

  @override
  String previewUploadingPercent(int percent) {
    return 'This file is still uploading ($percent %)';
  }

  @override
  String get previewUploadingDescription =>
      'The preview appears when the upload is complete.';

  @override
  String get previewErrorTitle => 'Couldn\'t load the preview';

  @override
  String get previewErrorDescription =>
      'Check your connection and try again, or download the file.';

  @override
  String get previewRetry => 'Retry';

  @override
  String get previewOfflineTitle => 'Previews aren\'t available offline';

  @override
  String get previewOfflineDescription => 'Reconnect to see this file.';

  @override
  String get previewTooLargeTitle => 'Preview isn\'t available for this file';

  @override
  String previewTooLargeDescription(String size) {
    return 'Files over $size (and images over 50 megapixels without a server preview) aren\'t previewed. Download the file to open it.';
  }

  @override
  String get previewImageBroken =>
      'This image can\'t be displayed. The file may be damaged.';

  @override
  String get previewNotText =>
      'This file can\'t be shown as text. It contains binary data.';

  @override
  String get previewNotFoundTitle => 'This file isn\'t available';

  @override
  String get previewNotFoundDescription =>
      'It may have been deleted, or you don\'t have access to it.';

  @override
  String get previewOpeningInApp => 'Opening in its app…';

  @override
  String get previewTrashedBanner => 'This file is in the trash';

  @override
  String get previewRestore => 'Restore';

  @override
  String get previewDownload => 'Download';

  @override
  String get previewDownloadDisabled =>
      'The owner has turned off downloads for viewers';

  @override
  String get previewDownloadUnavailable =>
      'Downloads aren\'t available in this version of Wonky Drive yet.';

  @override
  String get previewDownloadFailed => 'Couldn\'t start the download';

  @override
  String get previewOpenWith => 'Open with';

  @override
  String previewOpenWithApp(String app) {
    return 'Open with $app';
  }

  @override
  String get previewShare => 'Share';

  @override
  String get previewStar => 'Add to starred';

  @override
  String get previewUnstar => 'Remove from starred';

  @override
  String get previewDetails => 'Details';

  @override
  String get previewMore => 'More actions';

  @override
  String get previewClose => 'Close preview';

  @override
  String get previewRename => 'Rename';

  @override
  String get previewMove => 'Move to…';

  @override
  String get previewCopy => 'Make a copy';

  @override
  String get previewTrash => 'Move to trash';

  @override
  String get previewNext => 'Next file';

  @override
  String get previewPrevious => 'Previous file';

  @override
  String previewPosition(int index, int count, String folder) {
    return '$index of $count in “$folder”';
  }

  @override
  String previewPositionNoFolder(int index, int count) {
    return '$index of $count';
  }

  @override
  String get previewZoomIn => 'Zoom in';

  @override
  String get previewZoomOut => 'Zoom out';

  @override
  String get previewZoomFit => 'Fit';

  @override
  String get previewZoomActual => 'Actual size';

  @override
  String get previewRotate => 'Rotate';

  @override
  String previewZoomPercent(int percent) {
    return '$percent %';
  }

  @override
  String previewImageSize(int width, int height) {
    return '$width × $height';
  }

  @override
  String previewImageSemantics(String name, int width, int height) {
    return '$name, $width by $height pixels';
  }

  @override
  String get previewServerPreviewNote => 'Showing a smaller preview';

  @override
  String get previewWrap => 'Wrap lines';

  @override
  String get previewCopyAll => 'Copy all';

  @override
  String get previewCopied => 'Copied to the clipboard';

  @override
  String previewLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get previewPlainText => 'Plain text';

  @override
  String get previewLatin1 => 'Shown as Latin-1';

  @override
  String get previewTextTruncated =>
      'Showing the first 1 MB. Download to see the whole file.';

  @override
  String get previewCsvTable => 'Table';

  @override
  String get previewCsvText => 'Text';

  @override
  String previewCsvTruncated(int count) {
    return 'Showing the first $count rows.';
  }

  @override
  String previewCsvRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String get previewNoPreview => 'No preview available';

  @override
  String previewTypeSize(String type, String size) {
    return '$type · $size';
  }

  @override
  String get previewOwnedByMe => 'Owned by you';

  @override
  String previewOwnedBy(String name) {
    return 'Owned by $name';
  }

  @override
  String previewModified(String date) {
    return 'Modified $date';
  }

  @override
  String fileTypeLabel(String category, String ext) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'image': '$ext image',
      'pdf': 'PDF document',
      'text': '$ext text file',
      'audio': '$ext audio',
      'video': '$ext video',
      'archive': '$ext archive',
      'document': '$ext document',
      'spreadsheet': '$ext spreadsheet',
      'presentation': '$ext presentation',
      'other': '$ext file',
    });
    return '$_temp0';
  }

  @override
  String get fileTypeGeneric => 'File';

  @override
  String get categoryPreview => 'Preview';

  @override
  String get cmdPreviewFile => 'Preview';

  @override
  String get cmdOpenWith => 'Open with…';

  @override
  String get cmdDownloadFile => 'Download';

  @override
  String get cmdPreviewNext => 'Next file';

  @override
  String get cmdPreviewPrevious => 'Previous file';

  @override
  String get cmdPreviewZoomIn => 'Zoom in';

  @override
  String get cmdPreviewZoomOut => 'Zoom out';

  @override
  String get cmdPreviewZoomFit => 'Fit to window';

  @override
  String get cmdPreviewZoomActual => 'Actual size';

  @override
  String get cmdPreviewRotate => 'Rotate view';

  @override
  String get cmdPreviewToggleWrap => 'Wrap lines';

  @override
  String get cmdPreviewCopyAll => 'Copy all text';

  @override
  String get cmdPreviewClose => 'Close preview';

  @override
  String get categoryUploads => 'Uploads';

  @override
  String get cmdUploadFiles => 'Upload files';

  @override
  String get cmdUploadCancel => 'Cancel upload';

  @override
  String get cmdUploadCancelAll => 'Cancel all uploads';

  @override
  String get cmdUploadRetry => 'Retry upload';

  @override
  String get cmdUploadRetryAll => 'Retry failed uploads';

  @override
  String get cmdUploadRemove => 'Remove upload';

  @override
  String get cmdUploadClearFinished => 'Clear finished uploads';

  @override
  String get cmdUploadTogglePanel => 'Show uploads';

  @override
  String get uploadPickTitle => 'Upload files';

  @override
  String get uploadPanelLabel => 'Uploads';

  @override
  String uploadPanelUploading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uploading $count items',
      one: 'Uploading 1 item',
    );
    return '$_temp0';
  }

  @override
  String uploadPanelWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uploads waiting for connection',
      one: '1 upload waiting for connection',
    );
    return '$_temp0';
  }

  @override
  String uploadPanelComplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uploads complete',
      one: '1 upload complete',
      zero: 'Uploads',
    );
    return '$_temp0';
  }

  @override
  String uploadPanelFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uploads failed',
      one: '1 upload failed',
    );
    return '$_temp0';
  }

  @override
  String uploadSecondsLeft(int seconds) {
    return '$seconds s left';
  }

  @override
  String uploadMinutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String uploadPill(int count, int percent) {
    return 'Uploading $count · $percent %';
  }

  @override
  String uploadPillWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get uploadPanelCollapse => 'Collapse uploads';

  @override
  String get uploadPanelClose => 'Close uploads';

  @override
  String get uploadStatusQueued => 'Queued';

  @override
  String get uploadStatusWaiting => 'Waiting for connection';

  @override
  String get uploadStatusStarting => 'Starting…';

  @override
  String uploadStatusPercent(int percent) {
    return '$percent %';
  }

  @override
  String get uploadStatusVerifying => 'Verifying…';

  @override
  String get uploadStatusDone => 'Uploaded';

  @override
  String get uploadStatusCancelled => 'Cancelled';

  @override
  String get uploadFailedOutOfStorage =>
      'Not uploaded — you\'re out of storage';

  @override
  String get uploadFailedNetwork => 'Failed — network error';

  @override
  String uploadFailedTooLarge(String max) {
    return 'Too large — files can be at most $max';
  }

  @override
  String get uploadFailedFolderGone =>
      'The folder is gone or you lost access to it';

  @override
  String get uploadFailedRateLimited => 'Too many uploads — try again later';

  @override
  String get uploadFailedNotSaved =>
      'Add the file again — it wasn\'t saved on this device.';

  @override
  String get uploadFailedOther => 'Not uploaded';

  @override
  String get uploadVolatileHint => 'keep this tab open';

  @override
  String uploadActionCancel(String name) {
    return 'Cancel upload of $name';
  }

  @override
  String uploadActionRetry(String name) {
    return 'Retry upload of $name';
  }

  @override
  String uploadActionRemove(String name) {
    return 'Remove $name from the list';
  }

  @override
  String uploadActionShowInFolder(String name) {
    return 'Show $name in its folder';
  }

  @override
  String get uploadActionToMyDrive => 'Upload to My Drive';

  @override
  String get uploadActionChooseFile => 'Choose file';

  @override
  String get uploadManageStorage => 'Manage storage';

  @override
  String get uploadRetryAll => 'Retry all';

  @override
  String get uploadClearFinished => 'Clear finished';

  @override
  String uploadAnnounceDone(String name) {
    return 'Upload of $name complete';
  }

  @override
  String uploadAnnounceFailed(String name) {
    return 'Upload of $name failed';
  }

  @override
  String get uploadDialogCancel => 'Cancel';

  @override
  String get uploadConflictTitle => 'Upload options';

  @override
  String uploadConflictBodyOne(String name, String folder) {
    return '\"$name\" already exists in $folder. Keep both files, or skip this one?';
  }

  @override
  String uploadConflictBodyMany(int count, String folder) {
    return '$count files already exist in $folder. Keep both versions of each, or skip them?';
  }

  @override
  String get uploadConflictKeepBoth => 'Keep both';

  @override
  String get uploadConflictSkip => 'Skip';

  @override
  String get uploadMyDrive => 'My Drive';

  @override
  String uploadCancelAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cancel $count uploads?',
      one: 'Cancel 1 upload?',
    );
    return '$_temp0';
  }

  @override
  String get uploadCancelAllBody =>
      'Files that haven\'t finished uploading won\'t be saved.';

  @override
  String get uploadCancelAllConfirm => 'Cancel uploads';

  @override
  String get uploadKeepUploading => 'Keep uploading';

  @override
  String uploadTooManyFiles(int max) {
    return 'You can upload at most $max files at once.';
  }

  @override
  String get uploadFolderNeedsConnection =>
      'Folders can only be uploaded while you\'re online. The other files were added.';

  @override
  String get uploadFolderFailed => 'The folders couldn\'t be created';

  @override
  String storagePercent(int percent) {
    return '$percent %';
  }

  @override
  String storageOverBy(String size) {
    return 'Over by $size';
  }

  @override
  String get storageLegendFree => 'Free';

  @override
  String get storageBreakdownLabel => 'Storage by type';

  @override
  String get storageEmptyTrash => 'Empty trash';

  @override
  String get storageFreeUpTitle => 'Free up space';

  @override
  String storageCardTrashBody(String size) {
    return 'Frees $size';
  }

  @override
  String get storageCardLargeTitle => 'Large files';

  @override
  String storageCardLargeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files over 1 MB',
      one: '1 file over 1 MB',
    );
    return '$_temp0';
  }

  @override
  String get storageCardNotOpenedTitle => 'Not opened in 6 months';

  @override
  String storageCardNotOpenedBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files · $size',
      one: '1 file · $size',
    );
    return '$_temp0';
  }

  @override
  String storageCardMore(int count) {
    return 'More than $count files';
  }

  @override
  String get storageCardReview => 'Review';

  @override
  String get storageNothingToFree => 'Nothing to clean up right now.';

  @override
  String get storageItemsTitle => 'Items using storage';

  @override
  String storageFilterLabel(String type) {
    return 'Type: $type';
  }

  @override
  String get storageFilterAll => 'All';

  @override
  String get storageFilterDocuments => 'Documents';

  @override
  String get storageFilterSpreadsheets => 'Spreadsheets';

  @override
  String get storageFilterPresentations => 'Presentations';

  @override
  String get storageFilterFiles => 'Files';

  @override
  String get storageFilterTrash => 'Trash';

  @override
  String get storageFilterLarge => 'Large files';

  @override
  String get storageFilterNotOpened => 'Not opened in 6 months';

  @override
  String get storageClearFilter => 'Show all items';

  @override
  String get storageColumnName => 'Name';

  @override
  String get storageColumnKind => 'Kind';

  @override
  String get storageColumnLocation => 'Location';

  @override
  String get storageColumnLastOpened => 'Last opened';

  @override
  String get storageColumnStorage => 'Storage';

  @override
  String get storageInTrash => 'In trash';

  @override
  String get storageNeverOpened => 'Never opened';

  @override
  String storageRowLabel(String name, String kind, String size) {
    return '$name, $kind, $size';
  }

  @override
  String get storageSelectAll => 'Select all';

  @override
  String storageSelectRow(String name) {
    return 'Select $name';
  }

  @override
  String storageSelectionSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected · $size',
      one: '1 selected · $size',
    );
    return '$_temp0';
  }

  @override
  String get storageDownload => 'Download';

  @override
  String get storageClearSelection => 'Clear selection';

  @override
  String get storageEmptyTitle => 'Nothing here uses storage';

  @override
  String get storageEmptyFilterTitle => 'No items match this filter';

  @override
  String get storageEmptyTrashTitle => 'The trash is empty';

  @override
  String get storageOfflineTitle => 'You\'re offline';

  @override
  String get storageOfflineBody =>
      'The list of items needs a connection. The usage above is the last one saved on this device.';

  @override
  String get storageErrorTitle => 'Couldn\'t load your items';

  @override
  String get storageLoadingMore => 'Loading more…';

  @override
  String get storageWhatCountsTitle => 'What counts?';

  @override
  String get storageEmptyTrashTitleConfirm => 'Empty trash?';

  @override
  String storageEmptyTrashBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Permanently delete $count items in the trash? This frees $size and can\'t be undone.',
      one:
          'Permanently delete 1 item in the trash? This frees $size and can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String storageEmptyTrashBodyUnknown(String size) {
    return 'Permanently delete everything in the trash? This frees $size and can\'t be undone.';
  }

  @override
  String storageDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items forever?',
      one: 'Delete 1 item forever?',
    );
    return '$_temp0';
  }

  @override
  String storageDeleteBody(String size) {
    return 'This frees $size and can\'t be undone.';
  }

  @override
  String storageDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count items forever',
      one: 'Deleted 1 item forever',
    );
    return '$_temp0';
  }

  @override
  String get storageTrashEmptied => 'Trash emptied';

  @override
  String get categoryStorage => 'Storage';

  @override
  String get cmdStorageShow => 'Show storage';

  @override
  String get driveSettingsList => 'Files list';

  @override
  String get driveSettingsListHint =>
      'Defaults for the lists in Wonky Drive. Changing the layout or sort in a list remembers it on this device.';

  @override
  String get driveSettingsLayout => 'Default layout';

  @override
  String get driveSettingsLayoutList => 'List';

  @override
  String get driveSettingsLayoutGrid => 'Grid';

  @override
  String get driveSettingsSort => 'Default sort';

  @override
  String get driveSettingsSortOrder => 'Sort order';

  @override
  String get driveSettingsAscending => 'Ascending';

  @override
  String get driveSettingsDescending => 'Descending';

  @override
  String get driveSettingsShowExtensions => 'Show file extensions';

  @override
  String get driveSettingsShowExtensionsHint =>
      'When off, lists show \"notes\" for \"notes.pdf\". Dialogs and previews always show the full name.';

  @override
  String get driveSettingsUploads => 'Uploads';

  @override
  String get driveSettingsAskOnConflict =>
      'Ask when uploaded files have the same name';

  @override
  String get driveSettingsAskOnConflictHint =>
      'When off, both files are kept and the new one gets a number, like \"notes (1).pdf\".';

  @override
  String get driveSettingsConvertUploads => 'Convert uploads to Wonky formats';

  @override
  String get driveSettingsConvertUploadsHint =>
      'Files that Wonky Write or Wonky Sheets can open, like Word, Markdown, Excel and CSV, become documents and spreadsheets instead of being stored as files.';

  @override
  String get cmdDrivePrefsSet => 'Change a Drive setting';

  @override
  String get cmdViewSetLayout => 'Grid or list view';

  @override
  String get cmdViewSort => 'Sort by…';

  @override
  String get cmdViewToggleFoldersOnTop => 'Folders on top';

  @override
  String get categoryView => 'View';

  @override
  String uploadStatusConverted(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'document': 'Converted to a document',
      'spreadsheet': 'Converted to a spreadsheet',
      'other': 'Converted',
    });
    return '$_temp0';
  }

  @override
  String uploadConvertFailed(String name) {
    return '$name couldn\'t be converted. It was kept as a file.';
  }

  @override
  String get cmdAnalyticsShow => 'Show analytics';

  @override
  String get categoryAnalytics => 'Analytics';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsSubtitle => 'Usage of Wonky Work by UTC day.';

  @override
  String analyticsUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String analyticsTrackingSince(String date) {
    return 'Activity recorded since $date';
  }

  @override
  String get analyticsNoActivityYet => 'No activity recorded yet';

  @override
  String analyticsPeriodDays(int days) {
    return '$days days';
  }

  @override
  String get analyticsIncludeAdmins => 'Include admins';

  @override
  String get analyticsRefresh => 'Refresh';

  @override
  String get analyticsForbiddenTitle => 'Analytics are for admins';

  @override
  String get analyticsForbiddenBody =>
      'Ask a Wonky Work admin if you need these numbers.';

  @override
  String get analyticsErrorTitle => 'The analytics could not be loaded';

  @override
  String get analyticsShowTable => 'Show as table';

  @override
  String get analyticsShowChart => 'Show as chart';

  @override
  String analyticsChartLabel(String series, String from, String to) {
    return 'Chart of $series from $from to $to';
  }

  @override
  String get analyticsColDay => 'Day';

  @override
  String get analyticsColWeek => 'Week';

  @override
  String get analyticsTotal => 'Total';

  @override
  String get analyticsKpiAccounts => 'Accounts';

  @override
  String analyticsKpiNew(String count, int days) {
    return '+$count in $days days';
  }

  @override
  String get analyticsKpiToday => 'Active today';

  @override
  String analyticsKpiEditorsToday(String count) {
    return '$count created or edited';
  }

  @override
  String get analyticsKpiWeekly => 'Weekly active';

  @override
  String get analyticsKpiWeeklyNote => 'Last 7 days';

  @override
  String get analyticsKpiMonthly => 'Monthly active';

  @override
  String get analyticsKpiMonthlyNote => 'Last 30 days';

  @override
  String get analyticsKpiStickiness => 'Stickiness';

  @override
  String get analyticsKpiStickinessNote => 'Daily ÷ monthly active';

  @override
  String get analyticsKpiCreated => 'Items created';

  @override
  String analyticsKpiInPeriod(int days) {
    return 'In $days days';
  }

  @override
  String get analyticsActiveTitle => 'Active users';

  @override
  String get analyticsActiveSubtitle => 'People who used any app or MCP';

  @override
  String get analyticsViewDaily => 'Daily';

  @override
  String get analyticsViewWeekly => 'Weekly';

  @override
  String get analyticsViewMonthly => 'Monthly';

  @override
  String get analyticsSeriesActive => 'Active';

  @override
  String get analyticsSeriesEditors => 'Created or edited';

  @override
  String get analyticsSeriesWeekly => 'Weekly active';

  @override
  String get analyticsSeriesMonthly => 'Monthly active';

  @override
  String get analyticsAppsTitle => 'Active users by app';

  @override
  String get analyticsAppsSubtitle => 'A person using two apps counts in both';

  @override
  String get analyticsSeriesMcp => 'MCP clients';

  @override
  String get analyticsSignupsTitle => 'Sign-ups';

  @override
  String analyticsSignupsSubtitle(String count, String total) {
    return '$count new · $total accounts';
  }

  @override
  String get analyticsSeriesSignups => 'Sign-ups';

  @override
  String get analyticsContentNowTitle => 'Content now';

  @override
  String analyticsItemsTotal(String count, String size) {
    return '$count items · $size stored';
  }

  @override
  String get analyticsSignInTitle => 'Sign-in methods';

  @override
  String get analyticsSignInEmail => 'Email';

  @override
  String get analyticsSignInGoogle => 'Google';

  @override
  String get analyticsContentTitle => 'Content created';

  @override
  String get analyticsContentSubtitle =>
      'By people, the assistant and MCP; welcome content left out';

  @override
  String get analyticsCollabTitle => 'Collaboration';

  @override
  String get analyticsStatShared => 'Items shared now';

  @override
  String analyticsStatCoEdited(int days) {
    return 'Co-edited in $days days';
  }

  @override
  String analyticsStatCommenters(int days) {
    return 'Commenters in $days days';
  }

  @override
  String get analyticsSeriesComments => 'Comments';

  @override
  String get analyticsSeriesShares => 'Shares';

  @override
  String get analyticsAiTitle => 'AI assistant';

  @override
  String analyticsAiSubtitle(String requests, String tokens, int days) {
    return '$requests requests · $tokens tokens · kept $days days';
  }

  @override
  String get analyticsSeriesAiRequests => 'Requests';

  @override
  String get analyticsAiByFeature => 'By feature';

  @override
  String get analyticsAiByModel => 'By model';

  @override
  String analyticsAiRow(String requests, String tokens) {
    return '$requests · $tokens tokens';
  }

  @override
  String get analyticsNoAiUse => 'No AI use in this period';

  @override
  String get analyticsMcpTitle => 'MCP tool calls';

  @override
  String analyticsMcpSubtitle(String count) {
    return '$count calls by people\'s access tokens (admins included)';
  }

  @override
  String get analyticsSeriesMcpCalls => 'Tool calls';

  @override
  String get analyticsRetentionTitle => 'Retention';

  @override
  String get analyticsRetentionSubtitle =>
      'Share of each week\'s sign-ups active in the weeks after';

  @override
  String get analyticsCohortWeek => 'Signed up';

  @override
  String get analyticsCohortSize => 'Accounts';

  @override
  String analyticsCohortWeekN(int week) {
    return 'W$week';
  }

  @override
  String analyticsCohortCell(
    String cohort,
    int week,
    int active,
    String share,
  ) {
    return 'Week of $cohort: $active active in week $week ($share)';
  }
}

/// The translations for English (`en_XA`).
class DriveLocalizationsEnXa extends DriveLocalizationsEn {
  DriveLocalizationsEnXa() : super('en_XA');

  @override
  String get untitledFile => '[Ûñţîţļéð ƒîļé one t]';

  @override
  String get backToDrive => '[Ɓåçķ ţö Ðŕîṽé one]';

  @override
  String get driveSettingsSection => '[Ðŕîṽé on]';

  @override
  String get storageTitle => '[Šţöŕåĝé one]';

  @override
  String get previewLoading => '[Ļöåðîñĝ þŕéṽîéŵ… one tw]';

  @override
  String get previewUploadingTitle =>
      '[Ţĥîš ƒîļé îš šţîļļ ûþļöåðîñĝ one two t]';

  @override
  String previewUploadingPercent(int percent) {
    return '[Ţĥîš ƒîļé îš šţîļļ ûþļöåðîñĝ ($percent %) one two th]';
  }

  @override
  String get previewUploadingDescription =>
      '[Ţĥé þŕéṽîéŵ åþþéåŕš ŵĥéñ ţĥé ûþļöåð îš çöɱþļéţé. one two three f]';

  @override
  String get previewErrorTitle => '[Çöûļðñ\'ţ ļöåð ţĥé þŕéṽîéŵ one two]';

  @override
  String get previewErrorDescription =>
      '[Çĥéçķ ýöûŕ çöññéçţîöñ åñð ţŕý åĝåîñ, öŕ ðöŵñļöåð ţĥé ƒîļé. one two three four]';

  @override
  String get previewRetry => '[Ŕéţŕý on]';

  @override
  String get previewOfflineTitle =>
      '[Þŕéṽîéŵš åŕéñ\'ţ åṽåîļåƀļé öƒƒļîñé one two thr]';

  @override
  String get previewOfflineDescription =>
      '[Ŕéçöññéçţ ţö šéé ţĥîš ƒîļé. one two t]';

  @override
  String get previewTooLargeTitle =>
      '[Þŕéṽîéŵ îšñ\'ţ åṽåîļåƀļé ƒöŕ ţĥîš ƒîļé one two thre]';

  @override
  String previewTooLargeDescription(String size) {
    return '[Ƒîļéš öṽéŕ $size (åñð îɱåĝéš öṽéŕ 50 ɱéĝåþîẋéļš ŵîţĥöûţ å šéŕṽéŕ þŕéṽîéŵ) åŕéñ\'ţ þŕéṽîéŵéð. Ðöŵñļöåð ţĥé ƒîļé ţö öþéñ îţ. one two three four five six seven]';
  }

  @override
  String get previewImageBroken =>
      '[Ţĥîš îɱåĝé çåñ\'ţ ƀé ðîšþļåýéð. Ţĥé ƒîļé ɱåý ƀé ðåɱåĝéð. one two three fou]';

  @override
  String get previewNotText =>
      '[Ţĥîš ƒîļé çåñ\'ţ ƀé šĥöŵñ åš ţéẋţ. Îţ çöñţåîñš ƀîñåŕý ðåţå. one two three fou]';

  @override
  String get previewNotFoundTitle => '[Ţĥîš ƒîļé îšñ\'ţ åṽåîļåƀļé one two]';

  @override
  String get previewNotFoundDescription =>
      '[Îţ ɱåý ĥåṽé ƀééñ ðéļéţéð, öŕ ýöû ðöñ\'ţ ĥåṽé åççéšš ţö îţ. one two three fou]';

  @override
  String get previewOpeningInApp => '[Öþéñîñĝ îñ îţš åþþ… one tw]';

  @override
  String get previewTrashedBanner => '[Ţĥîš ƒîļé îš îñ ţĥé ţŕåšĥ one two]';

  @override
  String get previewRestore => '[Ŕéšţöŕé one]';

  @override
  String get previewDownload => '[Ðöŵñļöåð one]';

  @override
  String get previewDownloadDisabled =>
      '[Ţĥé öŵñéŕ ĥåš ţûŕñéð öƒƒ ðöŵñļöåðš ƒöŕ ṽîéŵéŕš one two three]';

  @override
  String get previewDownloadUnavailable =>
      '[Ðöŵñļöåðš åŕéñ\'ţ åṽåîļåƀļé îñ ţĥîš ṽéŕšîöñ öƒ Ŵöñķý Ðŕîṽé ýéţ. one two three four]';

  @override
  String get previewDownloadFailed =>
      '[Çöûļðñ\'ţ šţåŕţ ţĥé ðöŵñļöåð one two t]';

  @override
  String get previewOpenWith => '[Öþéñ ŵîţĥ one]';

  @override
  String previewOpenWithApp(String app) {
    return '[Öþéñ ŵîţĥ $app one]';
  }

  @override
  String get previewShare => '[Šĥåŕé on]';

  @override
  String get previewStar => '[Åðð ţö šţåŕŕéð one t]';

  @override
  String get previewUnstar => '[Ŕéɱöṽé ƒŕöɱ šţåŕŕéð one tw]';

  @override
  String get previewDetails => '[Ðéţåîļš one]';

  @override
  String get previewMore => '[Ṁöŕé åçţîöñš one]';

  @override
  String get previewClose => '[Çļöšé þŕéṽîéŵ one t]';

  @override
  String get previewRename => '[Ŕéñåɱé one]';

  @override
  String get previewMove => '[Ṁöṽé ţö… one]';

  @override
  String get previewCopy => '[Ṁåķé å çöþý one]';

  @override
  String get previewTrash => '[Ṁöṽé ţö ţŕåšĥ one]';

  @override
  String get previewNext => '[Ñéẋţ ƒîļé one]';

  @override
  String get previewPrevious => '[Þŕéṽîöûš ƒîļé one t]';

  @override
  String previewPosition(int index, int count, String folder) {
    return '[$index öƒ $count îñ “$folder” one]';
  }

  @override
  String previewPositionNoFolder(int index, int count) {
    return '[$index öƒ $count o]';
  }

  @override
  String get previewZoomIn => '[Žööɱ îñ one]';

  @override
  String get previewZoomOut => '[Žööɱ öûţ one]';

  @override
  String get previewZoomFit => '[Ƒîţ on]';

  @override
  String get previewZoomActual => '[Åçţûåļ šîžé one]';

  @override
  String get previewRotate => '[Ŕöţåţé one]';

  @override
  String previewZoomPercent(int percent) {
    return '[$percent % o]';
  }

  @override
  String previewImageSize(int width, int height) {
    return '[$width × $height o]';
  }

  @override
  String previewImageSemantics(String name, int width, int height) {
    return '[$name, $width ƀý $height þîẋéļš one]';
  }

  @override
  String get previewServerPreviewNote => '[Šĥöŵîñĝ å šɱåļļéŕ þŕéṽîéŵ one two]';

  @override
  String get previewWrap => '[Ŵŕåþ ļîñéš one]';

  @override
  String get previewCopyAll => '[Çöþý åļļ one]';

  @override
  String get previewCopied => '[Çöþîéð ţö ţĥé çļîþƀöåŕð one two]';

  @override
  String previewLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ļîñéš',
      one: '1 ļîñé',
    );
    return '[$_temp0 one]';
  }

  @override
  String get previewPlainText => '[Þļåîñ ţéẋţ one]';

  @override
  String get previewLatin1 => '[Šĥöŵñ åš Ļåţîñ-1 one t]';

  @override
  String get previewTextTruncated =>
      '[Šĥöŵîñĝ ţĥé ƒîŕšţ 1 ṀƁ. Ðöŵñļöåð ţö šéé ţĥé ŵĥöļé ƒîļé. one two three fo]';

  @override
  String get previewCsvTable => '[Ţåƀļé on]';

  @override
  String get previewCsvText => '[Ţéẋţ on]';

  @override
  String previewCsvTruncated(int count) {
    return '[Šĥöŵîñĝ ţĥé ƒîŕšţ $count ŕöŵš. one two]';
  }

  @override
  String previewCsvRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ŕöŵš',
      one: '1 ŕöŵ',
    );
    return '[$_temp0 one]';
  }

  @override
  String get previewNoPreview => '[Ñö þŕéṽîéŵ åṽåîļåƀļé one two]';

  @override
  String previewTypeSize(String type, String size) {
    return '[$type · $size o]';
  }

  @override
  String get previewOwnedByMe => '[Öŵñéð ƀý ýöû one]';

  @override
  String previewOwnedBy(String name) {
    return '[Öŵñéð ƀý $name one]';
  }

  @override
  String previewModified(String date) {
    return '[Ṁöðîƒîéð $date one]';
  }

  @override
  String fileTypeLabel(String category, String ext) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'image': '$ext îɱåĝé',
      'pdf': 'ÞÐƑ ðöçûɱéñţ',
      'text': '$ext ţéẋţ ƒîļé',
      'audio': '$ext åûðîö',
      'video': '$ext ṽîðéö',
      'archive': '$ext åŕçĥîṽé',
      'document': '$ext ðöçûɱéñţ',
      'spreadsheet': '$ext šþŕéåðšĥééţ',
      'presentation': '$ext þŕéšéñţåţîöñ',
      'other': '$ext ƒîļé',
    });
    return '[$_temp0 one two three four five six]';
  }

  @override
  String get fileTypeGeneric => '[Ƒîļé on]';

  @override
  String get categoryPreview => '[Þŕéṽîéŵ one]';

  @override
  String get cmdPreviewFile => '[Þŕéṽîéŵ one]';

  @override
  String get cmdOpenWith => '[Öþéñ ŵîţĥ… one]';

  @override
  String get cmdDownloadFile => '[Ðöŵñļöåð one]';

  @override
  String get cmdPreviewNext => '[Ñéẋţ ƒîļé one]';

  @override
  String get cmdPreviewPrevious => '[Þŕéṽîöûš ƒîļé one t]';

  @override
  String get cmdPreviewZoomIn => '[Žööɱ îñ one]';

  @override
  String get cmdPreviewZoomOut => '[Žööɱ öûţ one]';

  @override
  String get cmdPreviewZoomFit => '[Ƒîţ ţö ŵîñðöŵ one]';

  @override
  String get cmdPreviewZoomActual => '[Åçţûåļ šîžé one]';

  @override
  String get cmdPreviewRotate => '[Ŕöţåţé ṽîéŵ one]';

  @override
  String get cmdPreviewToggleWrap => '[Ŵŕåþ ļîñéš one]';

  @override
  String get cmdPreviewCopyAll => '[Çöþý åļļ ţéẋţ one]';

  @override
  String get cmdPreviewClose => '[Çļöšé þŕéṽîéŵ one t]';

  @override
  String get categoryUploads => '[Ûþļöåðš one]';

  @override
  String get cmdUploadFiles => '[Ûþļöåð ƒîļéš one]';

  @override
  String get cmdUploadCancel => '[Çåñçéļ ûþļöåð one t]';

  @override
  String get cmdUploadCancelAll => '[Çåñçéļ åļļ ûþļöåðš one tw]';

  @override
  String get cmdUploadRetry => '[Ŕéţŕý ûþļöåð one]';

  @override
  String get cmdUploadRetryAll => '[Ŕéţŕý ƒåîļéð ûþļöåðš one two]';

  @override
  String get cmdUploadRemove => '[Ŕéɱöṽé ûþļöåð one t]';

  @override
  String get cmdUploadClearFinished => '[Çļéåŕ ƒîñîšĥéð ûþļöåðš one two]';

  @override
  String get cmdUploadTogglePanel => '[Šĥöŵ ûþļöåðš one]';

  @override
  String get uploadPickTitle => '[Ûþļöåð ƒîļéš one]';

  @override
  String get uploadPanelLabel => '[Ûþļöåðš one]';

  @override
  String uploadPanelUploading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ûþļöåðîñĝ $count îţéɱš',
      one: 'Ûþļöåðîñĝ 1 îţéɱ',
    );
    return '[$_temp0 one two th]';
  }

  @override
  String uploadPanelWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ûþļöåðš ŵåîţîñĝ ƒöŕ çöññéçţîöñ',
      one: '1 ûþļöåð ŵåîţîñĝ ƒöŕ çöññéçţîöñ',
    );
    return '[$_temp0 one two three four]';
  }

  @override
  String uploadPanelComplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ûþļöåðš çöɱþļéţé',
      one: '1 ûþļöåð çöɱþļéţé',
      zero: 'Ûþļöåðš',
    );
    return '[$_temp0 one two three]';
  }

  @override
  String uploadPanelFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ûþļöåðš ƒåîļéð',
      one: '1 ûþļöåð ƒåîļéð',
    );
    return '[$_temp0 one two th]';
  }

  @override
  String uploadSecondsLeft(int seconds) {
    return '[$seconds š ļéƒţ on]';
  }

  @override
  String uploadMinutesLeft(int minutes) {
    return '[$minutes ɱîñ ļéƒţ one]';
  }

  @override
  String uploadPill(int count, int percent) {
    return '[Ûþļöåðîñĝ $count · $percent % one]';
  }

  @override
  String uploadPillWaiting(int count) {
    return '[$count ŵåîţîñĝ one]';
  }

  @override
  String get uploadPanelCollapse => '[Çöļļåþšé ûþļöåðš one tw]';

  @override
  String get uploadPanelClose => '[Çļöšé ûþļöåðš one t]';

  @override
  String get uploadStatusQueued => '[Ǫûéûéð one]';

  @override
  String get uploadStatusWaiting => '[Ŵåîţîñĝ ƒöŕ çöññéçţîöñ one two]';

  @override
  String get uploadStatusStarting => '[Šţåŕţîñĝ… one]';

  @override
  String uploadStatusPercent(int percent) {
    return '[$percent % o]';
  }

  @override
  String get uploadStatusVerifying => '[Ṽéŕîƒýîñĝ… one]';

  @override
  String get uploadStatusDone => '[Ûþļöåðéð one]';

  @override
  String get uploadStatusCancelled => '[Çåñçéļļéð one]';

  @override
  String get uploadFailedOutOfStorage =>
      '[Ñöţ ûþļöåðéð — ýöû\'ŕé öûţ öƒ šţöŕåĝé one two thr]';

  @override
  String get uploadFailedNetwork => '[Ƒåîļéð — ñéţŵöŕķ éŕŕöŕ one two]';

  @override
  String uploadFailedTooLarge(String max) {
    return '[Ţöö ļåŕĝé — ƒîļéš çåñ ƀé åţ ɱöšţ $max one two t]';
  }

  @override
  String get uploadFailedFolderGone =>
      '[Ţĥé ƒöļðéŕ îš ĝöñé öŕ ýöû ļöšţ åççéšš ţö îţ one two thre]';

  @override
  String get uploadFailedRateLimited =>
      '[Ţöö ɱåñý ûþļöåðš — ţŕý åĝåîñ ļåţéŕ one two th]';

  @override
  String get uploadFailedNotSaved =>
      '[Åðð ţĥé ƒîļé åĝåîñ — îţ ŵåšñ\'ţ šåṽéð öñ ţĥîš ðéṽîçé. one two three f]';

  @override
  String get uploadFailedOther => '[Ñöţ ûþļöåðéð one]';

  @override
  String get uploadVolatileHint => '[ķééþ ţĥîš ţåƀ öþéñ one tw]';

  @override
  String uploadActionCancel(String name) {
    return '[Çåñçéļ ûþļöåð öƒ $name one t]';
  }

  @override
  String uploadActionRetry(String name) {
    return '[Ŕéţŕý ûþļöåð öƒ $name one t]';
  }

  @override
  String uploadActionRemove(String name) {
    return '[Ŕéɱöṽé $name ƒŕöɱ ţĥé ļîšţ one tw]';
  }

  @override
  String uploadActionShowInFolder(String name) {
    return '[Šĥöŵ $name îñ îţš ƒöļðéŕ one tw]';
  }

  @override
  String get uploadActionToMyDrive => '[Ûþļöåð ţö Ṁý Ðŕîṽé one tw]';

  @override
  String get uploadActionChooseFile => '[Çĥööšé ƒîļé one]';

  @override
  String get uploadManageStorage => '[Ṁåñåĝé šţöŕåĝé one t]';

  @override
  String get uploadRetryAll => '[Ŕéţŕý åļļ one]';

  @override
  String get uploadClearFinished => '[Çļéåŕ ƒîñîšĥéð one t]';

  @override
  String uploadAnnounceDone(String name) {
    return '[Ûþļöåð öƒ $name çöɱþļéţé one tw]';
  }

  @override
  String uploadAnnounceFailed(String name) {
    return '[Ûþļöåð öƒ $name ƒåîļéð one t]';
  }

  @override
  String get uploadDialogCancel => '[Çåñçéļ one]';

  @override
  String get uploadConflictTitle => '[Ûþļöåð öþţîöñš one t]';

  @override
  String uploadConflictBodyOne(String name, String folder) {
    return '[\"$name\" åļŕéåðý éẋîšţš îñ $folder. Ķééþ ƀöţĥ ƒîļéš, öŕ šķîþ ţĥîš öñé? one two three fou]';
  }

  @override
  String uploadConflictBodyMany(int count, String folder) {
    return '[$count ƒîļéš åļŕéåðý éẋîšţ îñ $folder. Ķééþ ƀöţĥ ṽéŕšîöñš öƒ éåçĥ, öŕ šķîþ ţĥéɱ? one two three four]';
  }

  @override
  String get uploadConflictKeepBoth => '[Ķééþ ƀöţĥ one]';

  @override
  String get uploadConflictSkip => '[Šķîþ on]';

  @override
  String get uploadMyDrive => '[Ṁý Ðŕîṽé one]';

  @override
  String uploadCancelAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çåñçéļ $count ûþļöåðš?',
      one: 'Çåñçéļ 1 ûþļöåð?',
    );
    return '[$_temp0 one two th]';
  }

  @override
  String get uploadCancelAllBody =>
      '[Ƒîļéš ţĥåţ ĥåṽéñ\'ţ ƒîñîšĥéð ûþļöåðîñĝ ŵöñ\'ţ ƀé šåṽéð. one two three fou]';

  @override
  String get uploadCancelAllConfirm => '[Çåñçéļ ûþļöåðš one t]';

  @override
  String get uploadKeepUploading => '[Ķééþ ûþļöåðîñĝ one t]';

  @override
  String uploadTooManyFiles(int max) {
    return '[Ýöû çåñ ûþļöåð åţ ɱöšţ $max ƒîļéš åţ öñçé. one two thr]';
  }

  @override
  String get uploadFolderNeedsConnection =>
      '[Ƒöļðéŕš çåñ öñļý ƀé ûþļöåðéð ŵĥîļé ýöû\'ŕé öñļîñé. Ţĥé öţĥéŕ ƒîļéš ŵéŕé åððéð. one two three four five]';

  @override
  String get uploadFolderFailed =>
      '[Ţĥé ƒöļðéŕš çöûļðñ\'ţ ƀé çŕéåţéð one two th]';

  @override
  String storagePercent(int percent) {
    return '[$percent % o]';
  }

  @override
  String storageOverBy(String size) {
    return '[Öṽéŕ ƀý $size one]';
  }

  @override
  String get storageLegendFree => '[Ƒŕéé on]';

  @override
  String get storageBreakdownLabel => '[Šţöŕåĝé ƀý ţýþé one t]';

  @override
  String get storageEmptyTrash => '[Éɱþţý ţŕåšĥ one]';

  @override
  String get storageFreeUpTitle => '[Ƒŕéé ûþ šþåçé one]';

  @override
  String storageCardTrashBody(String size) {
    return '[Ƒŕééš $size on]';
  }

  @override
  String get storageCardLargeTitle => '[Ļåŕĝé ƒîļéš one]';

  @override
  String storageCardLargeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ƒîļéš öṽéŕ 1 ṀƁ',
      one: '1 ƒîļé öṽéŕ 1 ṀƁ',
    );
    return '[$_temp0 one two t]';
  }

  @override
  String get storageCardNotOpenedTitle => '[Ñöţ öþéñéð îñ 6 ɱöñţĥš one two]';

  @override
  String storageCardNotOpenedBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ƒîļéš · $size',
      one: '1 ƒîļé · $size',
    );
    return '[$_temp0 one t]';
  }

  @override
  String storageCardMore(int count) {
    return '[Ṁöŕé ţĥåñ $count ƒîļéš one t]';
  }

  @override
  String get storageCardReview => '[Ŕéṽîéŵ one]';

  @override
  String get storageNothingToFree =>
      '[Ñöţĥîñĝ ţö çļéåñ ûþ ŕîĝĥţ ñöŵ. one two t]';

  @override
  String get storageItemsTitle => '[Îţéɱš ûšîñĝ šţöŕåĝé one tw]';

  @override
  String storageFilterLabel(String type) {
    return '[Ţýþé: $type on]';
  }

  @override
  String get storageFilterAll => '[Åļļ on]';

  @override
  String get storageFilterDocuments => '[Ðöçûɱéñţš one]';

  @override
  String get storageFilterSpreadsheets => '[Šþŕéåðšĥééţš one t]';

  @override
  String get storageFilterPresentations => '[Þŕéšéñţåţîöñš one t]';

  @override
  String get storageFilterFiles => '[Ƒîļéš on]';

  @override
  String get storageFilterTrash => '[Ţŕåšĥ on]';

  @override
  String get storageFilterLarge => '[Ļåŕĝé ƒîļéš one]';

  @override
  String get storageFilterNotOpened => '[Ñöţ öþéñéð îñ 6 ɱöñţĥš one two]';

  @override
  String get storageClearFilter => '[Šĥöŵ åļļ îţéɱš one t]';

  @override
  String get storageColumnName => '[Ñåɱé on]';

  @override
  String get storageColumnKind => '[Ķîñð on]';

  @override
  String get storageColumnLocation => '[Ļöçåţîöñ one]';

  @override
  String get storageColumnLastOpened => '[Ļåšţ öþéñéð one]';

  @override
  String get storageColumnStorage => '[Šţöŕåĝé one]';

  @override
  String get storageInTrash => '[Îñ ţŕåšĥ one]';

  @override
  String get storageNeverOpened => '[Ñéṽéŕ öþéñéð one]';

  @override
  String storageRowLabel(String name, String kind, String size) {
    return '[$name, $kind, $size o]';
  }

  @override
  String get storageSelectAll => '[Šéļéçţ åļļ one]';

  @override
  String storageSelectRow(String name) {
    return '[Šéļéçţ $name one]';
  }

  @override
  String storageSelectionSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šéļéçţéð · $size',
      one: '1 šéļéçţéð · $size',
    );
    return '[$_temp0 one two]';
  }

  @override
  String get storageDownload => '[Ðöŵñļöåð one]';

  @override
  String get storageClearSelection => '[Çļéåŕ šéļéçţîöñ one t]';

  @override
  String get storageEmptyTitle => '[Ñöţĥîñĝ ĥéŕé ûšéš šţöŕåĝé one two]';

  @override
  String get storageEmptyFilterTitle => '[Ñö îţéɱš ɱåţçĥ ţĥîš ƒîļţéŕ one two]';

  @override
  String get storageEmptyTrashTitle => '[Ţĥé ţŕåšĥ îš éɱþţý one tw]';

  @override
  String get storageOfflineTitle => '[Ýöû\'ŕé öƒƒļîñé one t]';

  @override
  String get storageOfflineBody =>
      '[Ţĥé ļîšţ öƒ îţéɱš ñééðš å çöññéçţîöñ. Ţĥé ûšåĝé åƀöṽé îš ţĥé ļåšţ öñé šåṽéð öñ ţĥîš ðéṽîçé. one two three four five si]';

  @override
  String get storageErrorTitle => '[Çöûļðñ\'ţ ļöåð ýöûŕ îţéɱš one two]';

  @override
  String get storageLoadingMore => '[Ļöåðîñĝ ɱöŕé… one t]';

  @override
  String get storageWhatCountsTitle => '[Ŵĥåţ çöûñţš? one]';

  @override
  String get storageEmptyTrashTitleConfirm => '[Éɱþţý ţŕåšĥ? one]';

  @override
  String storageEmptyTrashBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Þéŕɱåñéñţļý ðéļéţé $count îţéɱš îñ ţĥé ţŕåšĥ? Ţĥîš ƒŕééš $size åñð çåñ\'ţ ƀé ûñðöñé.',
      one:
          'Þéŕɱåñéñţļý ðéļéţé 1 îţéɱ îñ ţĥé ţŕåšĥ? Ţĥîš ƒŕééš $size åñð çåñ\'ţ ƀé ûñðöñé.',
    );
    return '[$_temp0 one two three four five six seven eight ni]';
  }

  @override
  String storageEmptyTrashBodyUnknown(String size) {
    return '[Þéŕɱåñéñţļý ðéļéţé éṽéŕýţĥîñĝ îñ ţĥé ţŕåšĥ? Ţĥîš ƒŕééš $size åñð çåñ\'ţ ƀé ûñðöñé. one two three four five]';
  }

  @override
  String storageDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðéļéţé $count îţéɱš ƒöŕéṽéŕ?',
      one: 'Ðéļéţé 1 îţéɱ ƒöŕéṽéŕ?',
    );
    return '[$_temp0 one two three]';
  }

  @override
  String storageDeleteBody(String size) {
    return '[Ţĥîš ƒŕééš $size åñð çåñ\'ţ ƀé ûñðöñé. one two th]';
  }

  @override
  String storageDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðéļéţéð $count îţéɱš ƒöŕéṽéŕ',
      one: 'Ðéļéţéð 1 îţéɱ ƒöŕéṽéŕ',
    );
    return '[$_temp0 one two three]';
  }

  @override
  String get storageTrashEmptied => '[Ţŕåšĥ éɱþţîéð one t]';

  @override
  String get categoryStorage => '[Šţöŕåĝé one]';

  @override
  String get cmdStorageShow => '[Šĥöŵ šţöŕåĝé one]';

  @override
  String get driveSettingsList => '[Ƒîļéš ļîšţ one]';

  @override
  String get driveSettingsListHint =>
      '[Ðéƒåûļţš ƒöŕ ţĥé ļîšţš îñ Ŵöñķý Ðŕîṽé. Çĥåñĝîñĝ ţĥé ļåýöûţ öŕ šöŕţ îñ å ļîšţ ŕéɱéɱƀéŕš îţ öñ ţĥîš ðéṽîçé. one two three four five six sev]';

  @override
  String get driveSettingsLayout => '[Ðéƒåûļţ ļåýöûţ one t]';

  @override
  String get driveSettingsLayoutList => '[Ļîšţ on]';

  @override
  String get driveSettingsLayoutGrid => '[Ĝŕîð on]';

  @override
  String get driveSettingsSort => '[Ðéƒåûļţ šöŕţ one]';

  @override
  String get driveSettingsSortOrder => '[Šöŕţ öŕðéŕ one]';

  @override
  String get driveSettingsAscending => '[Åšçéñðîñĝ one]';

  @override
  String get driveSettingsDescending => '[Ðéšçéñðîñĝ one]';

  @override
  String get driveSettingsShowExtensions => '[Šĥöŵ ƒîļé éẋţéñšîöñš one two]';

  @override
  String get driveSettingsShowExtensionsHint =>
      '[Ŵĥéñ öƒƒ, ļîšţš šĥöŵ \"ñöţéš\" ƒöŕ \"ñöţéš.þðƒ\". Ðîåļöĝš åñð þŕéṽîéŵš åļŵåýš šĥöŵ ţĥé ƒûļļ ñåɱé. one two three four five six]';

  @override
  String get driveSettingsUploads => '[Ûþļöåðš one]';

  @override
  String get driveSettingsAskOnConflict =>
      '[Åšķ ŵĥéñ ûþļöåðéð ƒîļéš ĥåṽé ţĥé šåɱé ñåɱé one two three]';

  @override
  String get driveSettingsAskOnConflictHint =>
      '[Ŵĥéñ öƒƒ, ƀöţĥ ƒîļéš åŕé ķéþţ åñð ţĥé ñéŵ öñé ĝéţš å ñûɱƀéŕ, ļîķé \"ñöţéš (1).þðƒ\". one two three four five]';

  @override
  String get driveSettingsConvertUploads =>
      '[Çöñṽéŕţ ûþļöåðš ţö Ŵöñķý ƒöŕɱåţš one two th]';

  @override
  String get driveSettingsConvertUploadsHint =>
      '[Ƒîļéš ţĥåţ Ŵöñķý Ŵŕîţé öŕ Ŵöñķý Šĥééţš çåñ öþéñ, ļîķé Ŵöŕð, Ṁåŕķðöŵñ, Éẋçéļ åñð ÇŠṼ, ƀéçöɱé ðöçûɱéñţš åñð šþŕéåðšĥééţš îñšţéåð öƒ ƀéîñĝ šţöŕéð åš ƒîļéš. one two three four five six seven eight nine]';

  @override
  String get cmdDrivePrefsSet => '[Çĥåñĝé å Ðŕîṽé šéţţîñĝ one two]';

  @override
  String get cmdViewSetLayout => '[Ĝŕîð öŕ ļîšţ ṽîéŵ one t]';

  @override
  String get cmdViewSort => '[Šöŕţ ƀý… one]';

  @override
  String get cmdViewToggleFoldersOnTop => '[Ƒöļðéŕš öñ ţöþ one t]';

  @override
  String get categoryView => '[Ṽîéŵ on]';

  @override
  String uploadStatusConverted(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'document': 'Çöñṽéŕţéð ţö å ðöçûɱéñţ',
      'spreadsheet': 'Çöñṽéŕţéð ţö å šþŕéåðšĥééţ',
      'other': 'Çöñṽéŕţéð',
    });
    return '[$_temp0 one two three four]';
  }

  @override
  String uploadConvertFailed(String name) {
    return '[$name çöûļðñ\'ţ ƀé çöñṽéŕţéð. Îţ ŵåš ķéþţ åš å ƒîļé. one two three]';
  }

  @override
  String get cmdAnalyticsShow => '[Šĥöŵ åñåļýţîçš one t]';

  @override
  String get categoryAnalytics => '[Åñåļýţîçš one]';

  @override
  String get analyticsTitle => '[Åñåļýţîçš one]';

  @override
  String get analyticsSubtitle => '[Ûšåĝé öƒ Ŵöñķý Ŵöŕķ ƀý ÛŢÇ ðåý. one two t]';

  @override
  String analyticsUpdated(String time) {
    return '[Ûþðåţéð $time one]';
  }

  @override
  String analyticsTrackingSince(String date) {
    return '[Åçţîṽîţý ŕéçöŕðéð šîñçé $date one two]';
  }

  @override
  String get analyticsNoActivityYet => '[Ñö åçţîṽîţý ŕéçöŕðéð ýéţ one two]';

  @override
  String analyticsPeriodDays(int days) {
    return '[$days ðåýš on]';
  }

  @override
  String get analyticsIncludeAdmins => '[Îñçļûðé åðɱîñš one t]';

  @override
  String get analyticsRefresh => '[Ŕéƒŕéšĥ one]';

  @override
  String get analyticsForbiddenTitle => '[Åñåļýţîçš åŕé ƒöŕ åðɱîñš one two]';

  @override
  String get analyticsForbiddenBody =>
      '[Åšķ å Ŵöñķý Ŵöŕķ åðɱîñ îƒ ýöû ñééð ţĥéšé ñûɱƀéŕš. one two three]';

  @override
  String get analyticsErrorTitle =>
      '[Ţĥé åñåļýţîçš çöûļð ñöţ ƀé ļöåðéð one two th]';

  @override
  String get analyticsShowTable => '[Šĥöŵ åš ţåƀļé one]';

  @override
  String get analyticsShowChart => '[Šĥöŵ åš çĥåŕţ one]';

  @override
  String analyticsChartLabel(String series, String from, String to) {
    return '[Çĥåŕţ öƒ $series ƒŕöɱ $from ţö $to one t]';
  }

  @override
  String get analyticsColDay => '[Ðåý on]';

  @override
  String get analyticsColWeek => '[Ŵééķ on]';

  @override
  String get analyticsTotal => '[Ţöţåļ on]';

  @override
  String get analyticsKpiAccounts => '[Åççöûñţš one]';

  @override
  String analyticsKpiNew(String count, int days) {
    return '[+$count îñ $days ðåýš one]';
  }

  @override
  String get analyticsKpiToday => '[Åçţîṽé ţöðåý one]';

  @override
  String analyticsKpiEditorsToday(String count) {
    return '[$count çŕéåţéð öŕ éðîţéð one tw]';
  }

  @override
  String get analyticsKpiWeekly => '[Ŵééķļý åçţîṽé one t]';

  @override
  String get analyticsKpiWeeklyNote => '[Ļåšţ 7 ðåýš one]';

  @override
  String get analyticsKpiMonthly => '[Ṁöñţĥļý åçţîṽé one t]';

  @override
  String get analyticsKpiMonthlyNote => '[Ļåšţ 30 ðåýš one]';

  @override
  String get analyticsKpiStickiness => '[Šţîçķîñéšš one]';

  @override
  String get analyticsKpiStickinessNote => '[Ðåîļý ÷ ɱöñţĥļý åçţîṽé one two]';

  @override
  String get analyticsKpiCreated => '[Îţéɱš çŕéåţéð one t]';

  @override
  String analyticsKpiInPeriod(int days) {
    return '[Îñ $days ðåýš one]';
  }

  @override
  String get analyticsActiveTitle => '[Åçţîṽé ûšéŕš one]';

  @override
  String get analyticsActiveSubtitle =>
      '[Þéöþļé ŵĥö ûšéð åñý åþþ öŕ ṀÇÞ one two t]';

  @override
  String get analyticsViewDaily => '[Ðåîļý on]';

  @override
  String get analyticsViewWeekly => '[Ŵééķļý one]';

  @override
  String get analyticsViewMonthly => '[Ṁöñţĥļý one]';

  @override
  String get analyticsSeriesActive => '[Åçţîṽé one]';

  @override
  String get analyticsSeriesEditors => '[Çŕéåţéð öŕ éðîţéð one tw]';

  @override
  String get analyticsSeriesWeekly => '[Ŵééķļý åçţîṽé one t]';

  @override
  String get analyticsSeriesMonthly => '[Ṁöñţĥļý åçţîṽé one t]';

  @override
  String get analyticsAppsTitle => '[Åçţîṽé ûšéŕš ƀý åþþ one tw]';

  @override
  String get analyticsAppsSubtitle =>
      '[Å þéŕšöñ ûšîñĝ ţŵö åþþš çöûñţš îñ ƀöţĥ one two thr]';

  @override
  String get analyticsSeriesMcp => '[ṀÇÞ çļîéñţš one]';

  @override
  String get analyticsSignupsTitle => '[Šîĝñ-ûþš one]';

  @override
  String analyticsSignupsSubtitle(String count, String total) {
    return '[$count ñéŵ · $total åççöûñţš one t]';
  }

  @override
  String get analyticsSeriesSignups => '[Šîĝñ-ûþš one]';

  @override
  String get analyticsContentNowTitle => '[Çöñţéñţ ñöŵ one]';

  @override
  String analyticsItemsTotal(String count, String size) {
    return '[$count îţéɱš · $size šţöŕéð one t]';
  }

  @override
  String get analyticsSignInTitle => '[Šîĝñ-îñ ɱéţĥöðš one t]';

  @override
  String get analyticsSignInEmail => '[Éɱåîļ on]';

  @override
  String get analyticsSignInGoogle => '[Ĝööĝļé one]';

  @override
  String get analyticsContentTitle => '[Çöñţéñţ çŕéåţéð one t]';

  @override
  String get analyticsContentSubtitle =>
      '[Ɓý þéöþļé, ţĥé åššîšţåñţ åñð ṀÇÞ; ŵéļçöɱé çöñţéñţ ļéƒţ öûţ one two three four]';

  @override
  String get analyticsCollabTitle => '[Çöļļåƀöŕåţîöñ one t]';

  @override
  String get analyticsStatShared => '[Îţéɱš šĥåŕéð ñöŵ one t]';

  @override
  String analyticsStatCoEdited(int days) {
    return '[Çö-éðîţéð îñ $days ðåýš one tw]';
  }

  @override
  String analyticsStatCommenters(int days) {
    return '[Çöɱɱéñţéŕš îñ $days ðåýš one tw]';
  }

  @override
  String get analyticsSeriesComments => '[Çöɱɱéñţš one]';

  @override
  String get analyticsSeriesShares => '[Šĥåŕéš one]';

  @override
  String get analyticsAiTitle => '[ÅÎ åššîšţåñţ one]';

  @override
  String analyticsAiSubtitle(String requests, String tokens, int days) {
    return '[$requests ŕéǫûéšţš · $tokens ţöķéñš · ķéþţ $days ðåýš one two t]';
  }

  @override
  String get analyticsSeriesAiRequests => '[Ŕéǫûéšţš one]';

  @override
  String get analyticsAiByFeature => '[Ɓý ƒéåţûŕé one]';

  @override
  String get analyticsAiByModel => '[Ɓý ɱöðéļ one]';

  @override
  String analyticsAiRow(String requests, String tokens) {
    return '[$requests · $tokens ţöķéñš one]';
  }

  @override
  String get analyticsNoAiUse => '[Ñö ÅÎ ûšé îñ ţĥîš þéŕîöð one two]';

  @override
  String get analyticsMcpTitle => '[ṀÇÞ ţööļ çåļļš one t]';

  @override
  String analyticsMcpSubtitle(String count) {
    return '[$count çåļļš ƀý þéöþļé\'š åççéšš ţöķéñš (åðɱîñš îñçļûðéð) one two three fo]';
  }

  @override
  String get analyticsSeriesMcpCalls => '[Ţööļ çåļļš one]';

  @override
  String get analyticsRetentionTitle => '[Ŕéţéñţîöñ one]';

  @override
  String get analyticsRetentionSubtitle =>
      '[Šĥåŕé öƒ éåçĥ ŵééķ\'š šîĝñ-ûþš åçţîṽé îñ ţĥé ŵééķš åƒţéŕ one two three fou]';

  @override
  String get analyticsCohortWeek => '[Šîĝñéð ûþ one]';

  @override
  String get analyticsCohortSize => '[Åççöûñţš one]';

  @override
  String analyticsCohortWeekN(int week) {
    return '[Ŵ$week o]';
  }

  @override
  String analyticsCohortCell(
    String cohort,
    int week,
    int active,
    String share,
  ) {
    return '[Ŵééķ öƒ $cohort: $active åçţîṽé îñ ŵééķ $week ($share) one two]';
  }
}
