// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'slides_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SlidesLocalizationsEn extends SlidesLocalizations {
  SlidesLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get untitledPresentation => 'Untitled presentation';

  @override
  String get editorComingSoonTitle => 'Coming soon';

  @override
  String get editorComingSoonBody =>
      'Wonky Slides is being built. The presentation editor is on its way — your presentations stay safe in Wonky Drive meanwhile.';

  @override
  String get backToSlides => 'Back to Slides';

  @override
  String get deckDownloading => 'Downloading presentation…';

  @override
  String deckOpening(int rows) {
    return 'Opening presentation… ($rows rows)';
  }

  @override
  String get deckNotAvailableOffline =>
      'This presentation isn’t available offline.';

  @override
  String get deckNoAccess => 'You don’t have access to this presentation.';

  @override
  String get deckDownloadFailed => 'This presentation could not be downloaded.';

  @override
  String get deckOpenFailed => 'This presentation could not be opened.';

  @override
  String get deckNotOnDevice => 'This presentation isn’t on this device.';

  @override
  String get deckAccessRemoved =>
      'You no longer have access to this presentation.';

  @override
  String get deckStillOpening => 'The presentation is still opening.';

  @override
  String get screenStorageUnavailable =>
      'The presentation storage on this device didn\'t start. Try again, or reload the page.';

  @override
  String get createNeedsConnectionTitle =>
      'Connect to the internet to create a presentation';

  @override
  String get createNeedsConnectionBody =>
      'This device can create presentations offline once it has been online for a moment.';

  @override
  String get storageLimitedTitle =>
      'Offline storage is limited in this browser';

  @override
  String storageLimitedDescription(String elements) {
    return 'This browser keeps offline presentations in memory. Only about $elements objects stay available offline; the presentations you opened least recently are removed from this device first.';
  }

  @override
  String get recoveryTitle =>
      'Your offline presentation data couldn\'t be opened';

  @override
  String recoveryDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count presentations had changes that weren\'t synced yet. Download them before they\'re lost.',
      one:
          '1 presentation had changes that weren\'t synced yet. Download them before they\'re lost.',
    );
    return '$_temp0';
  }

  @override
  String get recoveryDownload => 'Download unsynced changes';

  @override
  String get recoveryFailed => 'The unsynced changes could not be exported';

  @override
  String get cmdFileImportSlides => 'Import slides…';

  @override
  String get cmdFileDownload => 'Download';

  @override
  String get cmdHistoryNameCurrentVersion => 'Name current version';

  @override
  String get cmdHistoryOpen => 'See version history';

  @override
  String get cmdFileSetLanguage => 'Language';

  @override
  String get cmdFilePageSetup => 'Page setup…';

  @override
  String get cmdPrintOpen => 'Print';

  @override
  String get cmdEditPasteSpecial => 'Paste special';

  @override
  String get cmdEditDuplicate => 'Duplicate';

  @override
  String get cmdEditDelete => 'Delete';

  @override
  String get cmdSelectEscape => 'Select none';

  @override
  String get cmdSelectEnterGroup => 'Enter group';

  @override
  String get cmdElementActivate => 'Edit text';

  @override
  String get cmdFindOpen => 'Find';

  @override
  String get cmdFindOpenReplace => 'Find and replace';

  @override
  String get cmdFormatCopyStyle => 'Copy style';

  @override
  String get cmdFormatPasteStyle => 'Paste style';

  @override
  String get cmdPresentFromCurrent => 'Present from current slide';

  @override
  String get cmdPresentFromStart => 'Present from beginning';

  @override
  String get cmdPresentPresenterView => 'Presenter view';

  @override
  String get cmdPresentRehearse => 'Rehearse';

  @override
  String get cmdPresentOpenOnAnotherDevice => 'Open on another device…';

  @override
  String get cmdPresentRemote => 'Use phone as remote';

  @override
  String get cmdPresentFromSlide => 'Present from this slide';

  @override
  String get cmdViewSetMode => 'View mode';

  @override
  String get cmdViewToggleNavigator => 'Navigator';

  @override
  String get cmdViewToggleInspector => 'Inspector';

  @override
  String get cmdViewToggleNotes => 'Speaker notes';

  @override
  String get cmdViewToggleRulers => 'Rulers';

  @override
  String get cmdViewToggleGuides => 'Guides';

  @override
  String get cmdViewToggleCommentPins => 'Comments on canvas';

  @override
  String get cmdViewToggleRemoteCursors => 'Collaborator cursors';

  @override
  String get cmdPresenceJumpTo => 'Jump to collaborator';

  @override
  String get cmdPresenceFollow => 'Follow';

  @override
  String get cmdPresenceUnfollow => 'Stop following';

  @override
  String get cmdPresenceFollowPresenter => 'Follow presenter';

  @override
  String get cmdTextEditAnyway => 'Edit anyway';

  @override
  String actorViaMcp(String name) {
    return 'Claude via MCP ($name)';
  }

  @override
  String actorViaAi(String name) {
    return 'Assistant ($name)';
  }

  @override
  String presenceEditingSlide(int number, String title) {
    return 'Editing slide $number · $title';
  }

  @override
  String presenceViewingSlide(int number, String title) {
    return 'Viewing slide $number · $title';
  }

  @override
  String get presencePresenting => 'Presenting';

  @override
  String get presenceEditingLayouts => 'Editing layouts';

  @override
  String get presenceFollowingYou => 'Following you';

  @override
  String presenceOnSlide(String names) {
    return 'On this slide: $names';
  }

  @override
  String presenceInGroup(String names) {
    return 'In this group: $names';
  }

  @override
  String presenceEditingFlag(String name) {
    return '✎ $name is editing';
  }

  @override
  String presenceEditingFlagMany(String names) {
    return '✎ $names editing';
  }

  @override
  String presenceEditingHover(String name) {
    return '$name is editing this text — double-click to edit anyway';
  }

  @override
  String softLockMessage(String name) {
    return '$name is editing this text.';
  }

  @override
  String softLockNotesMessage(String name) {
    return '$name is editing these notes.';
  }

  @override
  String softLockRaceMessage(String name) {
    return '$name started editing this text first.';
  }

  @override
  String get softLockCancel => 'Cancel';

  @override
  String get softLockEditAnyway => 'Edit anyway';

  @override
  String get softLockStop => 'Stop editing';

  @override
  String get softLockKeep => 'Keep editing';

  @override
  String notesEditingBanner(String name) {
    return '✎ $name is editing the notes';
  }

  @override
  String followBanner(String name) {
    return 'Following $name';
  }

  @override
  String get followStop => 'Stop';

  @override
  String presenterPill(String name) {
    return '$name is presenting';
  }

  @override
  String get presenterFollow => 'Follow';

  @override
  String get toastPresenterNotFound => 'That presentation has ended.';

  @override
  String get cmdViewToggleSmartGuides => 'Smart guides';

  @override
  String get cmdViewToggleSnapObjects => 'Snap to objects';

  @override
  String get cmdViewToggleSnapGuides => 'Snap to guides';

  @override
  String get cmdViewToggleSnapGrid => 'Snap to grid';

  @override
  String get cmdAnimateToggleOrderOverlay => 'Build order';

  @override
  String get cmdMagicMoveToggleMatches => 'Magic Move matches';

  @override
  String get cmdGuidesAdd => 'Add guide';

  @override
  String get cmdGuidesClear => 'Clear guides';

  @override
  String get cmdViewZoomFit => 'Fit';

  @override
  String get cmdViewZoom => 'Zoom';

  @override
  String get cmdViewZoomIn => 'Zoom in';

  @override
  String get cmdViewZoomOut => 'Zoom out';

  @override
  String get cmdViewZoomToSelection => 'Zoom to selection';

  @override
  String get cmdPanelAnimate => 'Animate';

  @override
  String get cmdPanelThemes => 'Themes';

  @override
  String get cmdPanelLayers => 'Layers';

  @override
  String get cmdPanelAccessibility => 'Accessibility';

  @override
  String get cmdPanelLinkedObjects => 'Linked charts';

  @override
  String get cmdModeEditing => 'Editing';

  @override
  String get cmdModeViewing => 'Viewing';

  @override
  String get cmdInspectorOpen => 'Format options…';

  @override
  String get cmdSlideNew => 'New slide';

  @override
  String get cmdSlideDuplicateForMagicMove => 'Magic Move slide';

  @override
  String get cmdInsertTextBox => 'Text box';

  @override
  String get cmdInsertImage => 'Image';

  @override
  String get cmdInsertShape => 'Shape';

  @override
  String get cmdInsertLine => 'Line';

  @override
  String get cmdInsertTable => 'Table';

  @override
  String get cmdInsertCode => 'Code block';

  @override
  String get cmdInsertChartFromSheets => 'Chart from Wonky Sheets…';

  @override
  String get cmdInsertChart => 'Chart';

  @override
  String get cmdInsertIcon => 'Icon…';

  @override
  String get cmdInsertEmoji => 'Emoji…';

  @override
  String get cmdInsertSpecialCharacter => 'Special characters…';

  @override
  String get cmdInsertLink => 'Link';

  @override
  String get cmdDeckOpenNumbering => 'Slide numbers…';

  @override
  String get cmdLayoutInsertPlaceholder => 'Placeholder';

  @override
  String get cmdFormatBold => 'Bold';

  @override
  String get cmdFormatItalic => 'Italic';

  @override
  String get cmdFormatUnderline => 'Underline';

  @override
  String get cmdFormatStrikethrough => 'Strikethrough';

  @override
  String get cmdFormatScript => 'Superscript / subscript';

  @override
  String get cmdFormatIncreaseFontSize => 'Increase font size';

  @override
  String get cmdFormatDecreaseFontSize => 'Decrease font size';

  @override
  String get cmdFormatCaps => 'Capitalization';

  @override
  String get cmdFormatTextStyle => 'Text style';

  @override
  String get cmdFormatFont => 'Font';

  @override
  String get cmdFormatFontSize => 'Font size';

  @override
  String get cmdFormatTextColor => 'Text color';

  @override
  String get cmdFormatHighlight => 'Highlight color';

  @override
  String get cmdFormatAlign => 'Text alignment';

  @override
  String get cmdFormatAnchor => 'Vertical alignment';

  @override
  String get cmdFormatIndent => 'Increase indent';

  @override
  String get cmdFormatOutdent => 'Decrease indent';

  @override
  String get cmdFormatLineHeight => 'Line spacing';

  @override
  String get cmdFormatParagraphSpacing => 'Paragraph spacing…';

  @override
  String get cmdFormatList => 'Lists';

  @override
  String get cmdFormatListStyle => 'List style';

  @override
  String get cmdFormatListStart => 'Restart numbering';

  @override
  String get cmdFormatAutofit => 'Text fitting';

  @override
  String get cmdFormatFill => 'Fill';

  @override
  String get cmdFormatStroke => 'Border';

  @override
  String get cmdFormatEffects => 'Effects';

  @override
  String get cmdFormatOpacity => 'Opacity…';

  @override
  String get cmdImageCrop => 'Crop';

  @override
  String get cmdImageMask => 'Mask with shape';

  @override
  String get cmdImageReplace => 'Replace image';

  @override
  String get cmdImageAdjust => 'Adjustments…';

  @override
  String get cmdImageReset => 'Reset image';

  @override
  String get cmdImageDownloadOriginal => 'Download original';

  @override
  String get cmdTableInsertRow => 'Insert row';

  @override
  String get cmdTableInsertColumn => 'Insert column';

  @override
  String get cmdTableDeleteRows => 'Delete row';

  @override
  String get cmdTableDeleteColumns => 'Delete column';

  @override
  String get cmdTableDelete => 'Delete table';

  @override
  String get cmdTableMergeCells => 'Merge cells';

  @override
  String get cmdTableUnmergeCells => 'Unmerge cells';

  @override
  String get cmdTableDistributeRows => 'Distribute rows';

  @override
  String get cmdTableDistributeColumns => 'Distribute columns';

  @override
  String get cmdTableSetOptions => 'Table options…';

  @override
  String get cmdTableSetCellFill => 'Cell fill';

  @override
  String get cmdTableSetBorders => 'Borders';

  @override
  String get cmdTableSetCellAlign => 'Vertical align';

  @override
  String get cmdShapeChange => 'Change shape';

  @override
  String get cmdShapeApplyQuickStyle => 'Quick styles';

  @override
  String get cmdLineSetArrow => 'Arrows';

  @override
  String get cmdLineSetRouting => 'Routing';

  @override
  String get cmdCodeEdit => 'Edit code';

  @override
  String get cmdCodeSetLanguage => 'Code language';

  @override
  String get cmdCodeUpdateOptions => 'Line numbers';

  @override
  String get cmdCodeSetHighlightSteps => 'Highlight steps…';

  @override
  String get cmdCodeAddState => 'Add state';

  @override
  String get cmdChartUpdate => 'Update chart';

  @override
  String get cmdChartSetAutoUpdate => 'Update automatically';

  @override
  String get cmdChartOpenSource => 'Open source spreadsheet';

  @override
  String get cmdChartUnlink => 'Unlink chart';

  @override
  String get cmdChartCopyAsImage => 'Copy chart as image';

  @override
  String get cmdElementEditAltText => 'Alt text…';

  @override
  String get cmdFormatPaintFormat => 'Paint format';

  @override
  String get cmdFormatClear => 'Clear formatting';

  @override
  String get cmdSlideDuplicate => 'Duplicate slide';

  @override
  String get cmdSlideDelete => 'Delete slide';

  @override
  String get cmdSlideToggleSkip => 'Skip slide';

  @override
  String get cmdSlideMove => 'Move slide';

  @override
  String get cmdSlideApplyLayout => 'Apply layout';

  @override
  String get cmdSlideResetToLayout => 'Reset slide to layout';

  @override
  String get cmdSlideSetBackground => 'Change background…';

  @override
  String get cmdSlideApplyBackgroundToAll => 'Apply background to all slides';

  @override
  String get cmdSlideSetHideMasterElements => 'Hide master objects';

  @override
  String get cmdDeckSetAppearance => 'Presentation appearance';

  @override
  String get cmdGroupCreate => 'Group slides';

  @override
  String get cmdGroupUngroup => 'Ungroup slides';

  @override
  String get cmdGroupAddSlides => 'Add to group';

  @override
  String get cmdGroupRemoveSlides => 'Remove from group';

  @override
  String get cmdGroupStartRename => 'Rename group';

  @override
  String get cmdGroupSetColor => 'Group color';

  @override
  String get cmdGroupToggleSkip => 'Skip group';

  @override
  String get cmdGroupCollapse => 'Collapse group';

  @override
  String get cmdGroupExpand => 'Expand group';

  @override
  String get cmdGroupCollapseAll => 'Collapse all groups';

  @override
  String get cmdGroupExpandAll => 'Expand all groups';

  @override
  String get cmdGroupDuplicate => 'Duplicate group';

  @override
  String get cmdGroupDelete => 'Delete group…';

  @override
  String get cmdGroupSelectSlides => 'Select slides in group';

  @override
  String get cmdAnimatePreview => 'Preview animations';

  @override
  String get cmdAnimateRemoveAll => 'Remove all animations';

  @override
  String get cmdAnimateAddBuild => 'Add animation';

  @override
  String get cmdAnimateCopyBuilds => 'Copy animation';

  @override
  String get cmdAnimatePasteBuilds => 'Paste animation';

  @override
  String get cmdAnimateDeleteBuilds => 'Remove animations';

  @override
  String get cmdThemeEdit => 'Edit theme…';

  @override
  String get cmdNavGoToSlide => 'Go to slide…';

  @override
  String get cmdNavGoToGroup => 'Go to group';

  @override
  String get cmdNavPreviousSlide => 'Previous slide';

  @override
  String get cmdNavNextSlide => 'Next slide';

  @override
  String get cmdArrangeOrder => 'Order';

  @override
  String get cmdArrangeAlign => 'Align objects';

  @override
  String get cmdArrangeDistribute => 'Distribute objects';

  @override
  String get cmdArrangeCenterOnSlide => 'Center on slide';

  @override
  String get cmdArrangeMatchSize => 'Match size';

  @override
  String get cmdArrangeRotate => 'Rotate';

  @override
  String get cmdArrangeFlip => 'Flip';

  @override
  String get cmdArrangeGroup => 'Group';

  @override
  String get cmdArrangeUngroup => 'Ungroup';

  @override
  String get cmdElementToggleLock => 'Lock';

  @override
  String get cmdElementUnlockAll => 'Unlock all on slide';

  @override
  String get cmdElementHide => 'Hide';

  @override
  String get cmdElementShow => 'Show';

  @override
  String get cmdElementSetLink => 'Link…';

  @override
  String get cmdElementRemoveLink => 'Remove link';

  @override
  String get cmdElementResetPlaceholder => 'Reset to layout';

  @override
  String get cmdSpellingCheck => 'Check spelling';

  @override
  String get cmdSpellingToggleUnderline => 'Underline errors';

  @override
  String get cmdToolsAccessibilityCheck => 'Accessibility check';

  @override
  String get cmdNotificationsOpenSettings => 'Notification settings';

  @override
  String get cmdAiGenerateDeck => 'Generate presentation…';

  @override
  String get cmdAiRewrite => 'Rewrite text';

  @override
  String get cmdAiSuggestLayouts => 'Suggest layouts for this slide';

  @override
  String get cmdAiSpeakerNotes => 'Write speaker notes';

  @override
  String get cmdAiAltText => 'Generate alt text';

  @override
  String get cmdAiCodeWalkthrough => 'Make a code walkthrough…';

  @override
  String get cmdToolSelect => 'Select';

  @override
  String get cmdPrefsSet => 'Change a Slides setting';

  @override
  String get cmdPresenterSet => 'Change a presenting setting';

  @override
  String get categoryFile => 'File';

  @override
  String get categoryEdit => 'Common';

  @override
  String get categoryView => 'View';

  @override
  String get categoryInsert => 'Insert';

  @override
  String get categoryFormat => 'Canvas & objects';

  @override
  String get categoryText => 'Text';

  @override
  String get categoryTables => 'Tables';

  @override
  String get categorySlides => 'Slides & groups';

  @override
  String get categoryArrange => 'Arrange';

  @override
  String get categoryCanvas => 'Canvas & objects';

  @override
  String get categoryPresent => 'Present';

  @override
  String get categoryAnimations => 'Animations';

  @override
  String get categoryTools => 'Tools';

  @override
  String get categoryAi => 'AI';

  @override
  String get alignLeft => 'Left';

  @override
  String get alignCenter => 'Center';

  @override
  String get alignRight => 'Right';

  @override
  String get alignJustify => 'Justify';

  @override
  String get anchorTop => 'Top';

  @override
  String get anchorMiddle => 'Middle';

  @override
  String get anchorBottom => 'Bottom';

  @override
  String get animateAddBuildIn => 'Add build in';

  @override
  String get animateAddAction => 'Add action';

  @override
  String get animateAddBuildOut => 'Add build out';

  @override
  String get animateTabTransition => 'Transition';

  @override
  String get animateTabBuild => 'Build';

  @override
  String get animateTabOrder => 'Order';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get autofitNone => 'Do not autofit';

  @override
  String get autofitShrink => 'Shrink text on overflow';

  @override
  String get autofitResize => 'Resize shape to fit text';

  @override
  String get axisHorizontally => 'Horizontally';

  @override
  String get axisVertically => 'Vertically';

  @override
  String get axisBoth => 'Both';

  @override
  String get backToNormalView => 'Back to Normal view';

  @override
  String get backToPresentation => 'Back to the presentation';

  @override
  String get badgeViewOnly => 'View only';

  @override
  String get badgeCommentOnly => 'Comment only';

  @override
  String get badgeViewing => 'Viewing';

  @override
  String get canvasChooseLayout => 'Choose a layout';

  @override
  String get canvasEmptyTitle => 'This presentation has no slides';

  @override
  String get canvasEmptyBody =>
      'Add a slide to start, or choose a layout for it.';

  @override
  String canvasSlideSemantics(int number, String title) {
    return 'Slide $number: $title';
  }

  @override
  String get capsUpper => 'UPPERCASE';

  @override
  String get capsSmallCaps => 'Small caps';

  @override
  String get capsTitle => 'Title Case';

  @override
  String get capsNone => 'None';

  @override
  String get chartColumn => 'Column';

  @override
  String get chartBar => 'Bar';

  @override
  String get chartLine => 'Line';

  @override
  String get chartPie => 'Pie';

  @override
  String get chartArea => 'Area';

  @override
  String get chartScatter => 'Scatter';

  @override
  String get chartFromSheets => 'From Wonky Sheets…';

  @override
  String get codeAllLanguages => 'All languages…';

  @override
  String get codeLineNumbers => 'Line numbers';

  @override
  String get codePlainText => 'Plain text';

  @override
  String get codeStates => 'States…';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorNone => 'None';

  @override
  String get deckLoading => 'Opening presentation…';

  @override
  String deckLoadingProgress(String message, int percent) {
    return '$message $percent %';
  }

  @override
  String get deckUnavailable => 'This presentation isn’t available';

  @override
  String get deckOfflineHint => 'It opens by itself when you’re back online.';

  @override
  String get downloadPdf => 'PDF document (.pdf)';

  @override
  String get downloadPng => 'PNG image (current slide)…';

  @override
  String get downloadPngZip => 'PNG images (all slides, .zip)…';

  @override
  String get downloadMarkdown => 'Outline as Markdown (.md)';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get flipHorizontally => 'Flip horizontally';

  @override
  String get flipVertically => 'Flip vertically';

  @override
  String get goToSlideTitle => 'Go to slide';

  @override
  String get goToSlideLabel => 'Slide';

  @override
  String get goToSlideButton => 'Go';

  @override
  String get groupUntitled => 'Untitled group';

  @override
  String get guidesAddVertical => 'Add vertical guide';

  @override
  String get guidesAddHorizontal => 'Add horizontal guide';

  @override
  String get imageUpload => 'Upload from computer';

  @override
  String get imageFromDrive => 'From Wonky Drive';

  @override
  String get imageByUrl => 'By URL';

  @override
  String get imageFromClipboard => 'From clipboard';

  @override
  String get inspectorLabel => 'Inspector';

  @override
  String get inspectorFormat => 'Format';

  @override
  String get inspectorAnimate => 'Animate';

  @override
  String get inspectorSlide => 'Slide';

  @override
  String get inspectorClose => 'Close inspector';

  @override
  String get inspectorFormatEmpty => 'Select an object to format it';

  @override
  String get inspectorSectionSoon => 'These options are on their way.';

  @override
  String get inspectorCurrentLayout => 'Layout';

  @override
  String get inspectorAppearance => 'Appearance';

  @override
  String get inspectorNotInGroup => 'Not in a group';

  @override
  String get inspectorGroupName => 'Group';

  @override
  String get inspectorSlideNumber => 'Position';

  @override
  String get inspectorSkipped => 'Skipped';

  @override
  String get yes => 'Yes';

  @override
  String get lineLine => 'Line';

  @override
  String get lineArrow => 'Arrow';

  @override
  String get lineDoubleArrow => 'Double arrow';

  @override
  String get lineElbowConnector => 'Elbow connector';

  @override
  String get lineCurvedConnector => 'Curved connector';

  @override
  String get lineStartArrow => 'Start arrow';

  @override
  String get lineEndArrow => 'End arrow';

  @override
  String get listBulleted => 'Bulleted list';

  @override
  String get listNumbered => 'Numbered list';

  @override
  String get listChecklist => 'Checklist';

  @override
  String get listOptions => 'List options…';

  @override
  String get menuAddToGroup => 'Add to group';

  @override
  String get menuAi => 'AI';

  @override
  String get menuAlign => 'Align';

  @override
  String get menuAlignIndent => 'Align & indent';

  @override
  String get menuAnimate => 'Animate';

  @override
  String get menuAnimateEllipsis => 'Animate…';

  @override
  String get menuAnimation => 'Animation…';

  @override
  String get menuApplyLayout => 'Apply layout';

  @override
  String get menuArrange => 'Arrange';

  @override
  String get menuBorderEllipsis => 'Border…';

  @override
  String get menuCapitalization => 'Capitalization';

  @override
  String get menuCenterOnSlide => 'Center on slide';

  @override
  String get menuChangeBackground => 'Change background…';

  @override
  String get menuChangeTheme => 'Change theme…';

  @override
  String get menuChart => 'Chart';

  @override
  String get menuChooseGroup => 'Choose a group…';

  @override
  String get menuCode => 'Code';

  @override
  String get menuCodeBlock => 'Code block';

  @override
  String get menuCommentOnSlide => 'Comment on slide';

  @override
  String get menuDistribute => 'Distribute';

  @override
  String get menuDownload => 'Download';

  @override
  String get menuEditLayout => 'Edit layout';

  @override
  String get menuEditMasters => 'Edit masters and layouts';

  @override
  String get menuEffectsEllipsis => 'Effects…';

  @override
  String get menuExtensions => 'Extensions';

  @override
  String get menuFillEllipsis => 'Fill…';

  @override
  String get menuFormat => 'Format';

  @override
  String get menuFormatOptions => 'Format options…';

  @override
  String get menuGroup => 'Group';

  @override
  String get menuGroupColor => 'Color';

  @override
  String get menuGuides => 'Guides';

  @override
  String get menuImage => 'Image';

  @override
  String get menuInsert => 'Insert';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuLine => 'Line';

  @override
  String get menuLists => 'Bullets & numbering';

  @override
  String get menuMagicMoveId => 'Magic Move ID…';

  @override
  String get menuMatchSize => 'Match size';

  @override
  String get menuMcp => 'MCP';

  @override
  String get menuMoveSlide => 'Move slide';

  @override
  String get menuNewGroup => 'New group';

  @override
  String get menuNewSlideInGroup => 'New slide in group';

  @override
  String get menuNewSlideWithLayout => 'New slide with layout';

  @override
  String get menuOrder => 'Order';

  @override
  String get menuPanels => 'Panels';

  @override
  String get menuPasteSpecial => 'Paste special';

  @override
  String get menuPersonalDictionary => 'Personal dictionary';

  @override
  String get menuPlaceholder => 'Placeholder';

  @override
  String get menuPresent => 'Present';

  @override
  String get menuPresentFromGroup => 'Present from this group';

  @override
  String get menuPresentingSettings => 'Presenting settings…';

  @override
  String get menuRehearsePresentation => 'Rehearse presentation';

  @override
  String get menuRewriteText => 'Rewrite text';

  @override
  String get menuRotate => 'Rotate';

  @override
  String get menuShape => 'Shape';

  @override
  String get menuShapeGallery => 'All shapes…';

  @override
  String get menuShow => 'Show';

  @override
  String get menuSize => 'Size';

  @override
  String get menuSizePosition => 'Size and position…';

  @override
  String get menuSlide => 'Slide';

  @override
  String get menuSnap => 'Snap';

  @override
  String get menuSpacing => 'Line & paragraph spacing';

  @override
  String get menuSpelling => 'Spelling';

  @override
  String get menuTable => 'Table';

  @override
  String get menuText => 'Text';

  @override
  String get menuTextFitting => 'Text fitting';

  @override
  String get menuTextStyle => 'Text style';

  @override
  String get menuTransition => 'Transition…';

  @override
  String get menuVersionHistory => 'Version history';

  @override
  String get menuZoom => 'Zoom';

  @override
  String get moveToBeginning => 'To beginning';

  @override
  String get moveUp => 'Up';

  @override
  String get moveDown => 'Down';

  @override
  String get moveToEnd => 'To end';

  @override
  String get navigatorLabel => 'Slides';

  @override
  String get navigatorEmpty => 'No slides';

  @override
  String get navigatorOpen => 'Show slides';

  @override
  String navigatorGroupSemantics(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
    );
    return 'Group $title, $_temp0';
  }

  @override
  String navigatorSlideSemantics(int number, int total, String title) {
    return 'Slide $number of $total: $title';
  }

  @override
  String get notesLabel => 'Speaker notes';

  @override
  String get notesPlaceholder => 'Click to add speaker notes';

  @override
  String get orderBringToFront => 'Bring to front';

  @override
  String get orderBringForward => 'Bring forward';

  @override
  String get orderSendBackward => 'Send backward';

  @override
  String get orderSendToBack => 'Send to back';

  @override
  String get outlineNoTitle => '(no title)';

  @override
  String get pasteKeepSource => 'Keep source formatting';

  @override
  String get pasteUseDestination => 'Use destination theme';

  @override
  String get pasteChartUnlinked => 'Paste chart unlinked';

  @override
  String get placeholderPicture => 'Picture';

  @override
  String get placeholderObject => 'Object';

  @override
  String get placeholderFooter => 'Footer';

  @override
  String get placeholderSlideNumber => 'Slide number';

  @override
  String get placeholderDate => 'Date';

  @override
  String get presentButton => 'Present';

  @override
  String get presentOptions => 'Presenting options';

  @override
  String get presenterLayoutStandard => 'Current, next and notes';

  @override
  String get presenterLayoutNotes => 'Large notes';

  @override
  String get presenterLayoutNext => 'Large next slide';

  @override
  String get reasonNotAvailableYet => 'Not available yet';

  @override
  String get reasonDeckLoading => 'The presentation is still opening';

  @override
  String get reasonViewAccess => 'You have view access';

  @override
  String get reasonViewingMode => 'You’re in Viewing mode';

  @override
  String get reasonFirstSlide => 'This is the first slide';

  @override
  String get reasonLastSlide => 'This is the last slide';

  @override
  String get reasonNoSlides => 'The presentation has no slides';

  @override
  String get rewriteShorter => 'Shorter';

  @override
  String get rewriteLonger => 'Longer';

  @override
  String get rewriteClearer => 'Clearer';

  @override
  String get rewriteFormal => 'More formal';

  @override
  String get rewriteGrammar => 'Fix grammar';

  @override
  String get rewriteCustom => 'Custom…';

  @override
  String get rotateClockwise => 'Rotate 90° clockwise';

  @override
  String get rotateCounterClockwise => 'Rotate 90° counter-clockwise';

  @override
  String get routePresentTitle => 'Presenting';

  @override
  String get routePrintTitle => 'Print and PDF';

  @override
  String get routeHistoryTitle => 'Version history';

  @override
  String get sectionText => 'Text';

  @override
  String get sectionLine => 'Line';

  @override
  String get sectionImage => 'Image';

  @override
  String get sectionTable => 'Table';

  @override
  String get sectionCell => 'Cell';

  @override
  String get sectionIcon => 'Icon';

  @override
  String get sectionCode => 'Code';

  @override
  String get sectionChart => 'Chart';

  @override
  String get sectionFill => 'Fill';

  @override
  String get sectionBorder => 'Border';

  @override
  String get sectionEffects => 'Effects';

  @override
  String get sectionArrange => 'Arrange';

  @override
  String get sectionLink => 'Link';

  @override
  String get sectionAccessibility => 'Accessibility';

  @override
  String get sectionLayout => 'Layout';

  @override
  String get sectionBackground => 'Background';

  @override
  String get sectionTheme => 'Theme';

  @override
  String get sectionVisibility => 'Visibility';

  @override
  String get sectionGroup => 'Group';

  @override
  String get sectionInfo => 'Info';

  @override
  String get settingsSectionPresentations => 'New presentations';

  @override
  String get settingsSectionEditing => 'Editing';

  @override
  String get settingsSectionAnimations => 'Animations & code';

  @override
  String get settingsSectionPresenting => 'Presenting';

  @override
  String get settingsNewPresentations => 'New presentations';

  @override
  String get settingsNewPresentationsHint =>
      'Used when you create a presentation. Existing presentations keep their own settings.';

  @override
  String get settingsDefaultTheme => 'Theme';

  @override
  String get settingsDefaultAppearance => 'Appearance';

  @override
  String get settingsDefaultSize => 'Slide size';

  @override
  String get settingsDefaultLanguage => 'Language';

  @override
  String get settingsCharts => 'Charts';

  @override
  String get settingsChartsAutoUpdate => 'Update linked charts automatically';

  @override
  String get settingsChartsAutoUpdateHint =>
      'New charts from Wonky Sheets follow their spreadsheet.';

  @override
  String get settingsEditing => 'Editing';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsScrollChangesSlides => 'Scroll to change slides';

  @override
  String get settingsSmartQuotes => 'Smart quotes';

  @override
  String get settingsAutoformatLists => 'Automatically format lists';

  @override
  String get settingsShowRemoteCursors => 'Show collaborator cursors';

  @override
  String get settingsSpelling => 'Spelling';

  @override
  String get settingsUnderlineSpelling => 'Underline spelling errors';

  @override
  String get settingsAnimations => 'Animations';

  @override
  String get settingsDefaultTransition => 'Default transition';

  @override
  String get settingsTransitionDuration => 'Transition duration';

  @override
  String get settingsDefaultBuild => 'Default build';

  @override
  String get settingsPreviewOnHover => 'Preview animations on hover';

  @override
  String get settingsReduceEditorMotion => 'Reduce motion in the editor';

  @override
  String get settingsReduceEditorMotionHint =>
      'Previews show the end state instead of playing.';

  @override
  String get settingsCode => 'Code';

  @override
  String get settingsCodeFontSize => 'Largest code font size';

  @override
  String get settingsCodeLanguage => 'Default code language';

  @override
  String get settingsTypingSpeed => 'Type-in speed';

  @override
  String get settingsTypeInSound => 'Type-in click sound';

  @override
  String get settingsPresenting => 'Presenting';

  @override
  String get settingsPresentingHint =>
      'How you present. The audience view follows the presentation.';

  @override
  String get settingsPresenterLayout => 'Presenter view layout';

  @override
  String get settingsNotesSize => 'Notes text size';

  @override
  String get settingsTimerMode => 'Timer';

  @override
  String get settingsTimerTarget => 'Countdown length';

  @override
  String get settingsLaserColor => 'Laser pointer color';

  @override
  String get settingsStartFullscreen => 'Start presenting in full screen';

  @override
  String get settingsStartWithPresenterView => 'Start with presenter view';

  @override
  String get settingsShowSkippedInPresenter =>
      'Show skipped slides in presenter view';

  @override
  String get sizeWidescreen16x9 => 'Widescreen 16:9';

  @override
  String get sizeStandard4x3 => 'Standard 4:3';

  @override
  String get sizeWide16x10 => 'Widescreen 16:10';

  @override
  String get sizeSquare => 'Square 1:1';

  @override
  String get sizePortrait9x16 => 'Portrait 9:16';

  @override
  String get sizeA4 => 'A4 landscape';

  @override
  String get sizeLetter => 'Letter landscape';

  @override
  String get sizeWidth => 'Width';

  @override
  String get sizeHeight => 'Height';

  @override
  String get slideUntitled => 'Untitled slide';

  @override
  String get spacingSingle => 'Single';

  @override
  String get spacingDouble => 'Double';

  @override
  String get spacingCustom => 'Custom…';

  @override
  String get spacingAddBefore => 'Add space before paragraph';

  @override
  String get spacingAddAfter => 'Add space after paragraph';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String get statusNoSlides => 'No slides';

  @override
  String statusSlideOf(int number, int total) {
    return 'Slide $number of $total';
  }

  @override
  String statusSkipped(int count) {
    return '$count skipped';
  }

  @override
  String get styleTitle => 'Title';

  @override
  String get styleSubtitle => 'Subtitle';

  @override
  String get styleHeading => 'Heading';

  @override
  String get styleBody => 'Body';

  @override
  String get styleBody2 => 'Body 2';

  @override
  String get styleCaption => 'Caption';

  @override
  String get styleQuote => 'Quote';

  @override
  String get styleAttribution => 'Attribution';

  @override
  String get styleBigNumber => 'Big number';

  @override
  String get styleLabel => 'Label';

  @override
  String get tableInsertRowAbove => 'Insert row above';

  @override
  String get tableInsertRowBelow => 'Insert row below';

  @override
  String get tableInsertColumnLeft => 'Insert column left';

  @override
  String get tableInsertColumnRight => 'Insert column right';

  @override
  String get textSuperscript => 'Superscript';

  @override
  String get textSubscript => 'Subscript';

  @override
  String get timerElapsed => 'Elapsed time';

  @override
  String get timerCountdown => 'Countdown';

  @override
  String get toolbarLabel => 'Slides toolbar';

  @override
  String get toolbarUndo => 'Undo';

  @override
  String get toolbarRedo => 'Redo';

  @override
  String toolbarUndoLabel(String label) {
    return 'Undo $label';
  }

  @override
  String toolbarRedoLabel(String label) {
    return 'Redo $label';
  }

  @override
  String get toolbarZoom => 'Zoom';

  @override
  String get toolbarAddComment => 'Add comment';

  @override
  String get toolbarAlign => 'Align';

  @override
  String get toolbarAnimate => 'Animate';

  @override
  String get toolbarBackground => 'Background';

  @override
  String get toolbarLayout => 'Layout';

  @override
  String get toolbarTheme => 'Theme';

  @override
  String get toolbarTransition => 'Transition';

  @override
  String get unitsSu => 'Slide units';

  @override
  String get unitsPx => 'Pixels';

  @override
  String get unitsIn => 'Inches';

  @override
  String get unitsCm => 'Centimeters';

  @override
  String get viewNormal => 'Normal';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewOutline => 'Outline';

  @override
  String get zoomFit => 'Fit';

  @override
  String zoomPercent(int percent) {
    return '$percent %';
  }

  @override
  String get toastUndoPartial =>
      'Some changes weren’t undone because a collaborator changed them since';

  @override
  String toastChangeNotSaved(String label, String reason) {
    return '“$label” couldn’t be saved: $reason';
  }

  @override
  String get toastChangeNoAccess => 'You can no longer edit this presentation';

  @override
  String get cmdSelectElements => 'Select objects';

  @override
  String get cmdSelectNext => 'Select next object';

  @override
  String get cmdSelectPrevious => 'Select previous object';

  @override
  String get cmdElementMove => 'Move';

  @override
  String get cmdElementResize => 'Resize';

  @override
  String get cmdElementNudge => 'Nudge';

  @override
  String get cmdElementAdjust => 'Adjust shape';

  @override
  String get cmdElementSetLineEnds => 'Move line end';

  @override
  String get cmdElementLock => 'Lock';

  @override
  String get cmdElementUnlock => 'Unlock';

  @override
  String get cmdGuidesMove => 'Move guide';

  @override
  String get cmdGuidesDelete => 'Delete guide';

  @override
  String get undoRotate => 'Rotate';

  @override
  String get undoFlip => 'Flip';

  @override
  String get reasonSelectObject => 'Select an object';

  @override
  String get reasonSelectTwoObjects => 'Select at least 2 objects';

  @override
  String get reasonSelectThreeObjects => 'Select at least 3 objects';

  @override
  String get reasonObjectLocked => 'Unlock the object first';

  @override
  String get reasonInsideGroup => 'Not available for objects inside a group';

  @override
  String get reasonSelectGroup => 'Select a group';

  @override
  String get reasonNoLockedObjects => 'No locked objects on this slide';

  @override
  String get reasonNoGuides => 'There are no guides';

  @override
  String get reasonNotOnCanvas => 'Not available for this object';

  @override
  String get elementKindText => 'Text box';

  @override
  String get elementKindShape => 'Shape';

  @override
  String get elementKindLine => 'Line';

  @override
  String get elementKindImage => 'Image';

  @override
  String get elementKindTable => 'Table';

  @override
  String get elementKindCode => 'Code';

  @override
  String get elementKindChart => 'Chart';

  @override
  String get elementKindIcon => 'Icon';

  @override
  String get elementKindGroup => 'Group';

  @override
  String get elementKindPlaceholder => 'Placeholder';

  @override
  String canvasAnnounceSelected(String name, int index, int count) {
    return '$name selected, $index of $count objects';
  }

  @override
  String canvasAnnounceSelectedMany(int count) {
    return '$count objects selected';
  }

  @override
  String canvasAnnounceMoved(int x, int y) {
    return 'Moved to x $x, y $y';
  }

  @override
  String canvasElementSemantics(String name, String state) {
    return '$name, $state';
  }

  @override
  String get canvasStateSelected => 'selected';

  @override
  String get canvasStateLocked => 'locked';

  @override
  String canvasDimensions(int width, int height) {
    return '$width × $height';
  }

  @override
  String canvasPosition(int x, int y) {
    return '$x, $y';
  }

  @override
  String canvasAngle(int degrees) {
    return '$degrees°';
  }

  @override
  String get cmdPrintPrint => 'Print PDF';

  @override
  String get printPreviewTitle => 'Print preview';

  @override
  String printPreviewTitleWithName(String name) {
    return 'Print preview — $name';
  }

  @override
  String get printBack => 'Back to the presentation';

  @override
  String get printDownloadPdf => 'Download PDF';

  @override
  String get printPrint => 'Print';

  @override
  String get printSettings => 'Settings';

  @override
  String get printShowPreview => 'Show preview';

  @override
  String printPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get printUpdatingPreview => 'Updating preview…';

  @override
  String get printLoadingDeck => 'Loading presentation…';

  @override
  String get printPreviewFailed => 'The preview could not be created';

  @override
  String get printTryAgain => 'Try again';

  @override
  String get printDownloadsDisabledTitle => 'Downloads are turned off';

  @override
  String get printDownloadsDisabledBody =>
      'The owner has turned off downloading and printing for viewers and commenters.';

  @override
  String get printUnavailableTitle => 'Printing isn\'t available here';

  @override
  String get printUnavailableBody =>
      'Download the PDF and print it from your PDF viewer.';

  @override
  String get printPdfPreviewLabel => 'PDF preview';

  @override
  String get printPdfReady => 'The PDF is ready';

  @override
  String printPdfReadyPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The PDF is ready: $count pages',
      one: 'The PDF is ready: 1 page',
    );
    return '$_temp0';
  }

  @override
  String get printPdfDesktopHint => 'Download the PDF to view or print it.';

  @override
  String get printLayout => 'Layout';

  @override
  String get printLayoutSlides => 'Slides';

  @override
  String get printLayoutNotes => 'Notes pages';

  @override
  String get printLayoutHandouts => 'Handouts';

  @override
  String get printPerPage => 'Slides per page';

  @override
  String get printOrder => 'Order';

  @override
  String get printOrderHorizontal => 'Across, then down';

  @override
  String get printOrderVertical => 'Down, then across';

  @override
  String get printRange => 'Slides to print';

  @override
  String get printRangeAll => 'All slides';

  @override
  String get printRangeCurrent => 'Current slide';

  @override
  String get printRangeSelection => 'Selected slides';

  @override
  String get printRangeCustom => 'Custom range';

  @override
  String get printRangeHint => 'e.g. 1-3, 7';

  @override
  String get printRangeInvalid => 'Enter slide numbers like 1-3, 7';

  @override
  String get printPaper => 'Paper';

  @override
  String get printPaperSlide => 'Slide size';

  @override
  String get printPaperLetter => 'Letter';

  @override
  String get printPaperLegal => 'Legal';

  @override
  String get printPaperTabloid => 'Tabloid';

  @override
  String get printOrientation => 'Orientation';

  @override
  String get printOrientationAuto => 'Automatic';

  @override
  String get printOrientationPortrait => 'Portrait';

  @override
  String get printOrientationLandscape => 'Landscape';

  @override
  String get printMargins => 'Margins';

  @override
  String get printMarginsNone => 'None';

  @override
  String get printMarginsNarrow => 'Narrow';

  @override
  String get printMarginsNormal => 'Normal';

  @override
  String get printBuilds => 'Print each build stage';

  @override
  String get printFinalState => 'Show final animation state';

  @override
  String get pngDialogTitle => 'Download PNG';

  @override
  String get pngDialogHint => 'Several images download as one .zip file.';

  @override
  String get pngSlides => 'Slides';

  @override
  String get pngSlidesCurrent => 'Current slide';

  @override
  String get pngSlidesSelection => 'Selected slides';

  @override
  String get pngSlidesAll => 'All slides';

  @override
  String get pngSize => 'Size';

  @override
  String pngSizeOption(int scale, int width, int height) {
    return '$scale× · $width × $height px';
  }

  @override
  String get pngFrames => 'Builds';

  @override
  String get pngFramesPrint => 'All content (as printed)';

  @override
  String get pngFramesFinal => 'After the last build';

  @override
  String get pngFramesBuilds => 'Each build stage (one image per step)';

  @override
  String get pngTransparent => 'Transparent background';

  @override
  String get pngDownload => 'Download';

  @override
  String pngEntrySlide(String number) {
    return 'Slide $number';
  }

  @override
  String pngEntryStep(String number, int step) {
    return 'Slide $number, step $step';
  }

  @override
  String get pngNothingToExport => 'There are no slides to export';

  @override
  String get printSkipped => 'Include skipped slides';

  @override
  String get printFrame => 'Frame slides';

  @override
  String get printHeaderFooter => 'Header and footer';

  @override
  String get printSlideNumbers => 'Slide numbers';

  @override
  String get printBookmarks => 'Bookmarks for sections and slides';

  @override
  String get printLinks => 'Clickable links';

  @override
  String get printInkSaver => 'Ink saver (no slide backgrounds)';

  @override
  String get printQuality => 'Image quality';

  @override
  String get printQualityHigh => 'High';

  @override
  String get printQualityCompact => 'Compact (smaller file)';

  @override
  String get printWarnings => 'About this PDF';

  @override
  String get printWarningFonts =>
      'A font could not be embedded; a standard font was used.';

  @override
  String get printWarningGlyphs =>
      'Some characters have no glyph in the embedded fonts.';

  @override
  String get printWarningIcons => 'Some icons could not be drawn.';

  @override
  String get printWarningImages => 'Some images could not be loaded.';

  @override
  String get printWarningLinks =>
      'Links to slides that are not printed were removed.';

  @override
  String get printWarningPages => 'Only the first 500 pages were exported.';

  @override
  String get printWarningEmpty => 'No slides match these settings.';

  @override
  String exportedToast(String name) {
    return 'Exported “$name”';
  }

  @override
  String get exportFailed => 'The export failed';

  @override
  String get exportFormatUnavailable => 'This format is not available yet';

  @override
  String pdfSlide(int number) {
    return 'Slide $number';
  }

  @override
  String pdfNotesContinued(int number) {
    return 'Notes (continued) — Slide $number';
  }

  @override
  String pdfPageOf(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get pdfUntitledSection => 'Untitled section';

  @override
  String get pdfUntitledPresentation => 'Untitled presentation';

  @override
  String get cmdGroupRename => 'Rename group';

  @override
  String get cmdGroupMove => 'Move group';

  @override
  String get cmdGroupToggleCollapsed => 'Collapse or expand group';

  @override
  String get cmdNavSelectAllSlides => 'Select all slides';

  @override
  String get cmdNavigatorCopy => 'Copy slides';

  @override
  String get cmdNavigatorCut => 'Cut slides';

  @override
  String get cmdNavigatorPaste => 'Paste slides';

  @override
  String get cmdNotesZoom => 'Speaker notes zoom';

  @override
  String cmdSlideDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count slides',
      one: 'Delete slide',
    );
    return '$_temp0';
  }

  @override
  String cmdSlideDuplicateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Duplicate $count slides',
      one: 'Duplicate slide',
    );
    return '$_temp0';
  }

  @override
  String get cmdEditNotes => 'Edit speaker notes';

  @override
  String get reasonSelectSlides => 'Select slides in the navigator';

  @override
  String get reasonAlreadyGroup => 'These slides are already a group';

  @override
  String get reasonSkippedWithGroup => 'Skipped with group';

  @override
  String get reasonNotInGroup => 'The slide isn’t in a group';

  @override
  String get reasonNoGroups => 'The presentation has no groups';

  @override
  String get reasonGroupsCantNest => 'Groups can’t be nested';

  @override
  String get reasonCantMoveFurther => 'The slides can’t move further';

  @override
  String get reasonClipboardNoSlides => 'Copy slides or groups first';

  @override
  String get reasonAllCollapsed => 'The group is already collapsed';

  @override
  String get reasonAllExpanded => 'The group is already expanded';

  @override
  String get navigatorDropHere => 'Drop slides here';

  @override
  String get navigatorNewSlideLayout => 'New slide with layout';

  @override
  String navigatorDragSlides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
    );
    return '$_temp0';
  }

  @override
  String navigatorDragGroup(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
    );
    return '$title · $_temp0';
  }

  @override
  String get navigatorGroupExpanded => 'expanded';

  @override
  String get navigatorGroupCollapsed => 'collapsed';

  @override
  String get navigatorSkipped => 'skipped';

  @override
  String navigatorSlideInGroupSemantics(
    int number,
    int total,
    String group,
    String title,
  ) {
    return 'Slide $number of $total, in group $group: $title';
  }

  @override
  String get navigatorGroupMenu => 'Group actions';

  @override
  String get navigatorSlideMenu => 'Slide actions';

  @override
  String get navigatorCollapseGroup => 'Collapse group (Alt+click: all groups)';

  @override
  String get navigatorExpandGroup => 'Expand group (Alt+click: all groups)';

  @override
  String get navigatorGroupColor => 'Group color';

  @override
  String get navigatorRenameField => 'Group name';

  @override
  String get navigatorSkippedWithGroup => 'Skipped with group';

  @override
  String deleteGroupTitle(String title) {
    return 'Delete group ‘$title’?';
  }

  @override
  String deleteGroupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The group contains $count slides.',
      one: 'The group contains 1 slide.',
    );
    return '$_temp0';
  }

  @override
  String deleteGroupsTitle(int count) {
    return 'Delete $count groups?';
  }

  @override
  String get deleteGroupUngroupOnly => 'Ungroup only';

  @override
  String deleteGroupWithSlides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete group and $count slides',
      one: 'Delete group and 1 slide',
    );
    return '$_temp0';
  }

  @override
  String get toastGroupDeleted => 'Group deleted';

  @override
  String get chooseGroupTitle => 'Add to group';

  @override
  String get chooseGroupLabel => 'Group';

  @override
  String get chooseGroupButton => 'Add';

  @override
  String get gridThumbSize => 'Thumbnail size';

  @override
  String get gridOpenHint => 'Double-click a slide to open it';

  @override
  String get notesBold => 'Bold';

  @override
  String get notesItalic => 'Italic';

  @override
  String get notesUnderline => 'Underline';

  @override
  String get notesBulletList => 'Bulleted list';

  @override
  String get notesNumberedList => 'Numbered list';

  @override
  String get notesLink => 'Link';

  @override
  String get notesLinkTitle => 'Link';

  @override
  String get notesLinkUrl => 'URL';

  @override
  String get notesLinkApply => 'Apply';

  @override
  String get notesLinkRemove => 'Remove link';

  @override
  String get notesLinkInvalid => 'Enter an http or https address';

  @override
  String get notesReadOnly => 'View only';

  @override
  String get notesNoSlide => 'No slide selected';

  @override
  String get undoTyping => 'Typing';

  @override
  String get dialogApply => 'Apply';

  @override
  String get linkDialogTitle => 'Link';

  @override
  String get linkTargetLabel => 'Link to';

  @override
  String get linkTargetUrl => 'Web address';

  @override
  String get linkUrlLabel => 'Address';

  @override
  String get linkRemove => 'Remove link';

  @override
  String get linkActionNext => 'Next slide';

  @override
  String get linkActionPrevious => 'Previous slide';

  @override
  String get linkActionFirst => 'First slide';

  @override
  String get linkActionLast => 'Last slide';

  @override
  String get linkActionEnd => 'End show';

  @override
  String get fontLabel => 'Font';

  @override
  String get fontSizeLabel => 'Size';

  @override
  String get colorLabel =>
      'Color (#RRGGBB or theme:accent1; empty = automatic)';

  @override
  String get lineHeightLabel => 'Line spacing';

  @override
  String get listStyleLabel => 'Style';

  @override
  String get listStartLabel => 'Start numbering at';

  @override
  String get fontThemeHeading => 'Theme heading font';

  @override
  String get fontThemeBody => 'Theme body font';

  @override
  String get fontThemeMono => 'Theme monospace font';

  @override
  String get listStyleDisc => 'Disc';

  @override
  String get listStyleCircle => 'Circle';

  @override
  String get listStyleSquare => 'Square';

  @override
  String get listStyleDash => 'Dash';

  @override
  String get listStyleArrow => 'Arrow';

  @override
  String get listStyleCheck => 'Check mark';

  @override
  String get listStyleStar => 'Star';

  @override
  String get listStyleNone => 'No bullet';

  @override
  String get cmdFormatLetterSpacing => 'Letter spacing';

  @override
  String get cmdFormatInsets => 'Text insets';

  @override
  String get cmdTextExitEditing => 'Exit text editing';

  @override
  String get cmdTextRemoveLink => 'Remove link from text';

  @override
  String get reasonNotEditingText => 'No text is being edited';

  @override
  String get reasonSelectText => 'Select text or a text box';

  @override
  String get reasonSelectTextOrObject => 'Select text or an object';

  @override
  String get reasonNoLink => 'The selection has no link';

  @override
  String get reasonSelectPlaceholder => 'Select a placeholder';

  @override
  String toastSkippedLocked(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skipped $count text boxes others are editing',
      one: 'Skipped 1 text box $name is editing',
    );
    return '$_temp0';
  }

  @override
  String validationNumberRange(String min, String max) {
    return 'Enter a number from $min to $max';
  }

  @override
  String slideNumberLabel(int number) {
    return 'Slide $number';
  }

  @override
  String get themeColorBg1 => 'Background 1';

  @override
  String get themeColorBg2 => 'Background 2';

  @override
  String get themeColorText1 => 'Text 1';

  @override
  String get themeColorText2 => 'Text 2';

  @override
  String themeColorAccent(int n) {
    return 'Accent $n';
  }

  @override
  String get themeColorLink => 'Link';

  @override
  String shapeName(String geometry) {
    String _temp0 = intl.Intl.selectLogic(geometry, {
      'rect': 'Rectangle',
      'roundRect': 'Rounded rectangle',
      'ellipse': 'Ellipse',
      'triangle': 'Triangle',
      'rightTriangle': 'Right triangle',
      'diamond': 'Diamond',
      'pentagon': 'Pentagon',
      'hexagon': 'Hexagon',
      'octagon': 'Octagon',
      'parallelogram': 'Parallelogram',
      'trapezoid': 'Trapezoid',
      'donut': 'Donut',
      'arc': 'Arc',
      'blockArc': 'Block arc',
      'pie': 'Pie',
      'chord': 'Chord',
      'frame': 'Frame',
      'halfFrame': 'Half frame',
      'plus': 'Plus',
      'cross': 'Cross',
      'cylinder': 'Cylinder',
      'cube': 'Cube',
      'can': 'Can',
      'heart': 'Heart',
      'cloud': 'Cloud',
      'moon': 'Moon',
      'sun': 'Sun',
      'lightning': 'Lightning bolt',
      'arrowRight': 'Right arrow',
      'arrowLeft': 'Left arrow',
      'arrowUp': 'Up arrow',
      'arrowDown': 'Down arrow',
      'arrowLeftRight': 'Left-right arrow',
      'arrowUpDown': 'Up-down arrow',
      'chevron': 'Chevron',
      'homePlate': 'Pentagon arrow',
      'notchedArrow': 'Notched arrow',
      'curvedArrow': 'Curved arrow',
      'circularArrow': 'Circular arrow',
      'uTurn': 'U-turn arrow',
      'star4': '4-point star',
      'star5': '5-point star',
      'star6': '6-point star',
      'star8': '8-point star',
      'star12': '12-point star',
      'burst': 'Burst',
      'ribbon': 'Ribbon',
      'wave': 'Wave',
      'seal': 'Seal',
      'speech': 'Speech bubble',
      'speechRound': 'Round speech bubble',
      'thought': 'Thought bubble',
      'calloutRect': 'Rectangular callout',
      'calloutLine': 'Line callout',
      'banner': 'Banner',
      'process': 'Process',
      'decision': 'Decision',
      'terminator': 'Terminator',
      'document': 'Document',
      'data': 'Data',
      'manualInput': 'Manual input',
      'predefinedProcess': 'Predefined process',
      'connector': 'Connector',
      'offPage': 'Off-page connector',
      'delay': 'Delay',
      'storage': 'Stored data',
      'brace': 'Brace',
      'bracket': 'Bracket',
      'doubleBrace': 'Double brace',
      'custom': 'Custom shape',
      'other': 'Shape',
    });
    return '$_temp0';
  }

  @override
  String shapeCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'basic': 'Basic shapes',
      'arrows': 'Arrows',
      'stars': 'Stars and badges',
      'callouts': 'Callouts',
      'flowchart': 'Flowchart',
      'brackets': 'Brackets',
      'custom': 'Custom',
      'other': 'Shapes',
    });
    return '$_temp0';
  }

  @override
  String iconCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'all': 'All icons',
      'recent': 'Recently used',
      'arrows': 'Arrows',
      'business': 'Business',
      'charts': 'Charts',
      'communication': 'Communication',
      'devices': 'Devices',
      'development': 'Development',
      'files': 'Files',
      'food': 'Food and drink',
      'media': 'Media',
      'nature': 'Nature',
      'people': 'People',
      'security': 'Security',
      'shapes': 'Shapes',
      'text': 'Text',
      'clock': 'Time',
      'tools': 'Tools',
      'travel': 'Travel',
      'weather': 'Weather',
      'other': 'Icons',
    });
    return '$_temp0';
  }

  @override
  String arrowStyleName(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'none': 'None',
      'triangle': 'Arrow',
      'open': 'Open arrow',
      'stealth': 'Stealth arrow',
      'circle': 'Circle',
      'diamond': 'Diamond',
      'bar': 'Bar',
      'other': 'Arrow',
    });
    return '$_temp0';
  }

  @override
  String arrowSizeName(String size) {
    String _temp0 = intl.Intl.selectLogic(size, {
      's': 'Small',
      'm': 'Medium',
      'l': 'Large',
      'other': 'Medium',
    });
    return '$_temp0';
  }

  @override
  String dashName(String dash) {
    String _temp0 = intl.Intl.selectLogic(dash, {
      'solid': 'Solid',
      'dash': 'Dashed',
      'dot': 'Dotted',
      'dashDot': 'Dash-dot',
      'longDash': 'Long dash',
      'other': 'Solid',
    });
    return '$_temp0';
  }

  @override
  String capName(String cap) {
    String _temp0 = intl.Intl.selectLogic(cap, {
      'butt': 'Flat',
      'round': 'Round',
      'square': 'Square',
      'other': 'Flat',
    });
    return '$_temp0';
  }

  @override
  String routingName(String routing) {
    String _temp0 = intl.Intl.selectLogic(routing, {
      'straight': 'Straight',
      'elbow': 'Elbow',
      'curved': 'Curved',
      'other': 'Straight',
    });
    return '$_temp0';
  }

  @override
  String quickStyleName(String index) {
    String _temp0 = intl.Intl.selectLogic(index, {
      '0': 'Accent 1',
      '1': 'Accent 2',
      '2': 'Accent 3',
      '3': 'Accent 4',
      '4': 'Accent 5',
      '5': 'Accent 6',
      '6': 'Outline',
      '7': 'Soft tint',
      'other': 'Style',
    });
    return '$_temp0';
  }

  @override
  String strokeWidthLabel(String width) {
    return '$width pt';
  }

  @override
  String get cmdIconReplace => 'Replace icon…';

  @override
  String get cmdIconSetStrokeWidth => 'Icon stroke width';

  @override
  String get cmdElementRename => 'Rename object';

  @override
  String get menuChangeShape => 'Change shape';

  @override
  String get menuQuickStyles => 'Quick styles';

  @override
  String get menuRouting => 'Routing';

  @override
  String get menuWeight => 'Weight';

  @override
  String get menuDash => 'Dash';

  @override
  String get menuBorderColor => 'Border color';

  @override
  String get menuLineColor => 'Line color';

  @override
  String get menuFillColor => 'Fill color';

  @override
  String get menuIconColor => 'Icon color';

  @override
  String get colorThemeDefault => 'Theme default';

  @override
  String get styleLabelColor => 'Color';

  @override
  String get styleLabelWeight => 'Weight';

  @override
  String get styleLabelDash => 'Dash';

  @override
  String get styleLabelCap => 'Ends';

  @override
  String get styleLabelArrowSize => 'Arrow size';

  @override
  String get styleLabelRouting => 'Routing';

  @override
  String get styleLabelShadow => 'Shadow';

  @override
  String get styleLabelGlow => 'Glow';

  @override
  String get styleLabelOpacity => 'Opacity';

  @override
  String get styleLabelNoFill => 'No fill';

  @override
  String get styleLabelNoBorder => 'No border';

  @override
  String get styleLabelGeometry => 'Shape';

  @override
  String get styleLabelStrokeWidth => 'Stroke width';

  @override
  String get styleLabelIcon => 'Icon';

  @override
  String get styleMixed => 'Mixed';

  @override
  String get arrangeLabelX => 'X';

  @override
  String get arrangeLabelY => 'Y';

  @override
  String get arrangeLabelW => 'W';

  @override
  String get arrangeLabelH => 'H';

  @override
  String get arrangeLabelRotation => 'Rotation';

  @override
  String get arrangeLabelName => 'Name';

  @override
  String get arrangeEditInsideGroup => 'Edit inside group';

  @override
  String get arrangeLocked => 'Locked';

  @override
  String get accessibilityAltText => 'Alt text';

  @override
  String get accessibilityAltTextHint =>
      'Describe the object for people using screen readers';

  @override
  String get accessibilityDecorative => 'Decorative';

  @override
  String accessibilityReadingOrder(int position, int count) {
    return 'Reading order: $position of $count';
  }

  @override
  String get altTextDialogTitle => 'Alt text';

  @override
  String get altTextDialogDecorative =>
      'Mark as decorative (screen readers skip it)';

  @override
  String get dialogSave => 'Save';

  @override
  String get iconPickerTitle => 'Insert icon';

  @override
  String get iconPickerReplaceTitle => 'Replace icon';

  @override
  String get iconPickerSearch => 'Search icons';

  @override
  String iconPickerEmpty(String query) {
    return 'No icons match “$query”';
  }

  @override
  String iconPickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count icons',
      one: '1 icon',
    );
    return '$_temp0';
  }

  @override
  String get iconPickerRecentEmpty => 'Icons you insert show up here';

  @override
  String get iconPickerStroke => 'Stroke';

  @override
  String get iconPickerColor => 'Color';

  @override
  String get iconPickerCategory => 'Category';

  @override
  String get iconPickerInsert => 'Insert';

  @override
  String get iconPickerReplace => 'Replace';

  @override
  String get shapeGalleryTitle => 'Shapes';

  @override
  String get shapeGalleryChoose => 'Choose';

  @override
  String get reasonSelectShape => 'Select a shape';

  @override
  String get reasonSelectLine => 'Select a line';

  @override
  String get reasonSelectIcon => 'Select an icon';

  @override
  String get reasonSelectOneObject => 'Select one object';

  @override
  String get reasonNoFill => 'Select a shape, text box or icon';

  @override
  String get reasonNoBorder => 'Select a shape, line, text box, image or icon';

  @override
  String get reasonPlaceholdersCantGroup => 'Placeholders can\'t be grouped';

  @override
  String get reasonSameLevel => 'Select objects in the same group';

  @override
  String get reasonNoStyleCopied => 'Copy a style first';

  @override
  String get painterArmed => 'Click an object to apply the format';

  @override
  String get toolArmedShape => 'Click or drag on the slide to insert the shape';

  @override
  String get toolArmedLine => 'Drag on the slide to draw the line';

  @override
  String get colorAutomatic => 'Automatic';

  @override
  String get inspectorMixed => 'Mixed';

  @override
  String get spacingBeforeLabel => 'Space before';

  @override
  String get spacingAfterLabel => 'Space after';

  @override
  String get reasonSelectImage => 'Select an image';

  @override
  String get reasonNoDownload =>
      'Downloading isn\'t allowed for this presentation';

  @override
  String get reasonSelectTable => 'Select a table';

  @override
  String get reasonSelectCells => 'Select table cells';

  @override
  String get reasonNoMergedCells => 'No merged cells in the selection';

  @override
  String get undoCropImage => 'Crop image';

  @override
  String get cmdImageCropApply => 'Apply crop';

  @override
  String get cmdImageCropCancel => 'Cancel crop';

  @override
  String get cmdImageRetryUpload => 'Retry upload';

  @override
  String get cmdImageRemoveNotUploaded => 'Remove image';

  @override
  String get cmdTableResizeAxes => 'Resize rows or columns';

  @override
  String get cmdTableSetCellPadding => 'Cell padding';

  @override
  String get cmdTableClearCells => 'Clear cells';

  @override
  String get cmdTableSelectCells => 'Select cells';

  @override
  String get cmdTableMoveSelection => 'Move cell selection';

  @override
  String get cmdTableNextCell => 'Next cell';

  @override
  String get cmdTablePreviousCell => 'Previous cell';

  @override
  String get cmdTableEditCell => 'Edit cell';

  @override
  String get cmdTableClearCellSelection => 'Select the whole table';

  @override
  String get imageNotAvailable => 'This image isn\'t available right now.';

  @override
  String get imagePickTitle => 'Choose images';

  @override
  String get imageClipboardEmpty => 'There\'s no image on the clipboard.';

  @override
  String get imageUrlInvalid => 'Enter an https:// image address.';

  @override
  String get imageFetchFailed => 'Couldn\'t load this image.';

  @override
  String get imageOutOfStorage => 'You\'re out of storage.';

  @override
  String imageRejectedTooLarge(String name) {
    return 'Couldn\'t insert \'$name\' — images can be at most 50 MB.';
  }

  @override
  String imageRejectedFormat(String name) {
    return 'Couldn\'t insert \'$name\' — this image type isn\'t supported.';
  }

  @override
  String get imageInsertDialogTitle => 'Insert image';

  @override
  String get imageReplaceDialogTitle => 'Replace image';

  @override
  String get imageSourceLabel => 'Source';

  @override
  String get dialogContinue => 'Continue';

  @override
  String get dialogInsert => 'Insert';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get imageUrlDialogTitle => 'Insert image by URL';

  @override
  String get imageUrlDialogBody =>
      'The image is fetched through Wonky Work and stored with the presentation.';

  @override
  String get imageUrlLabel => 'Image address';

  @override
  String get imageMaskDialogTitle => 'Mask with shape';

  @override
  String get imageMaskShape => 'Shape';

  @override
  String get imageMaskNone => 'No mask';

  @override
  String get imageDriveDialogTitle => 'Insert image from Wonky Drive';

  @override
  String get imageDriveSearch => 'Search images';

  @override
  String get imageDriveImage => 'Image';

  @override
  String get imageDriveFailed =>
      'Couldn\'t load your images. Check your connection.';

  @override
  String get imageDriveEmpty => 'No images found.';

  @override
  String get cropAspectFree => 'Free';

  @override
  String get cropAspectOriginal => 'Original';

  @override
  String get cropFill => 'Fill';

  @override
  String get cropFit => 'Fit';

  @override
  String get cropDone => 'Done';

  @override
  String get imageNotUploadedOutOfStorage => 'Not uploaded — out of storage';

  @override
  String get imageRetry => 'Retry';

  @override
  String get imageRemove => 'Remove';

  @override
  String tableSizeInvalid(int max) {
    return 'Enter a number from 1 to $max.';
  }

  @override
  String get tableInsertDialogTitle => 'Insert table';

  @override
  String get tableRows => 'Rows';

  @override
  String get tableColumns => 'Columns';

  @override
  String get cmdThemeApply => 'Apply theme';

  @override
  String get cmdThemeImport => 'Import theme from a presentation…';

  @override
  String get cmdThemeRename => 'Rename theme…';

  @override
  String get cmdThemeDuplicate => 'Duplicate theme';

  @override
  String get cmdThemeSetDefault => 'Set as default theme';

  @override
  String get cmdThemeDelete => 'Remove theme';

  @override
  String get cmdThemeRemoveUnused => 'Remove unused themes';

  @override
  String get cmdDeckSetSize => 'Change slide size';

  @override
  String get cmdDeckSetNumbering => 'Set slide numbers and footer';

  @override
  String get undoChangeSlideSize => 'Change slide size';

  @override
  String get undoNumbering => 'Slide numbers and footer';

  @override
  String get reasonThemeInUse =>
      'Used by slides — apply another theme to them first';

  @override
  String get reasonThemeIsDefault => 'Already the default theme';

  @override
  String get reasonNoUnusedThemes => 'Every theme is in use';

  @override
  String get themesPanelTitle => 'Themes';

  @override
  String get themesApplyTo => 'Apply to';

  @override
  String get themesApplyAll => 'All slides';

  @override
  String themesApplySelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selected slides ($count)',
      one: 'Selected slide',
    );
    return '$_temp0';
  }

  @override
  String get themesInPresentation => 'In this presentation';

  @override
  String get themesBuiltIn => 'Built-in themes';

  @override
  String get themesImport => 'Import theme from a presentation…';

  @override
  String get themesDefault => 'Default';

  @override
  String themesUsedBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $count slides',
      one: 'Used by 1 slide',
      zero: 'Not used',
    );
    return '$_temp0';
  }

  @override
  String themesMore(String name) {
    return 'More actions for $name';
  }

  @override
  String get themeUntitled => 'Untitled theme';

  @override
  String get themePreviewSubtitle => 'Title and subtitle';

  @override
  String themeCopyName(String name) {
    return '$name copy';
  }

  @override
  String get themeRenameTitle => 'Rename theme';

  @override
  String get themeNameLabel => 'Name';

  @override
  String get themeNameEmpty => 'Enter a name';

  @override
  String get themeRenameButton => 'Rename';

  @override
  String get themeImportPickTitle => 'Import theme from a presentation';

  @override
  String get themeImportSearch => 'Search presentations';

  @override
  String get themeImportPresentation => 'Presentation';

  @override
  String get themeImportNoPresentations => 'No other presentations';

  @override
  String get themeImportOffline => 'Connect to the internet to import a theme';

  @override
  String get themeImportChooseTitle => 'Choose a theme';

  @override
  String themeImportOption(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
      zero: 'not used',
    );
    return '$name — $_temp0';
  }

  @override
  String get themeImportButton => 'Import';

  @override
  String themeImported(String name) {
    return 'Theme “$name” added';
  }

  @override
  String get themeApplyToAll => 'Apply to all slides';

  @override
  String get backgroundResetToLayout => 'Reset to layout background';

  @override
  String get pageSetupTitle => 'Page setup';

  @override
  String get pageSetupPreset => 'Slide size';

  @override
  String get pageSetupUnit => 'Unit';

  @override
  String get pageSetupContent => 'Existing content';

  @override
  String get pageSetupScale => 'Scale content to fit';

  @override
  String get pageSetupDontScale => 'Don\'t scale';

  @override
  String get pageSetupPreview => 'Preview';

  @override
  String get pageSetupApply => 'Apply';

  @override
  String get pageSetupEnterSize => 'Enter a width and a height.';

  @override
  String get pageSetupSideRange =>
      'Each side must be between 320 and 7,680 su.';

  @override
  String get pageSetupAspectRange =>
      'The aspect ratio must be between 1:4 and 4:1.';

  @override
  String get sizeCustom => 'Custom';

  @override
  String get numberingTitle => 'Slide numbers and footer';

  @override
  String get numberingShow => 'Show slide numbers';

  @override
  String get numberingFirst => 'First slide number';

  @override
  String get numberingFirstInvalid => 'Enter a number from 0 to 9999';

  @override
  String get numberingHideOnTitle => 'Don\'t show on title slides';

  @override
  String get numberingFooter => 'Footer';

  @override
  String get numberingFooterHint => 'Empty = no footer';

  @override
  String get imageUploading => 'Uploading…';

  @override
  String get imageAdjustments => 'Adjustments';

  @override
  String get imageBrightness => 'Brightness';

  @override
  String get imageContrast => 'Contrast';

  @override
  String get imageSaturation => 'Saturation';

  @override
  String get imageTemperature => 'Temperature';

  @override
  String get imageBlur => 'Blur';

  @override
  String get imageGrayscale => 'Grayscale';

  @override
  String get imageSepia => 'Sepia';

  @override
  String get imageInvert => 'Invert';

  @override
  String get tableStyle => 'Style';

  @override
  String get tableStyleTheme => 'Theme';

  @override
  String get tableStyleNone => 'None';

  @override
  String get tableHeaderRow => 'Header row';

  @override
  String get tableFirstColumn => 'First column';

  @override
  String get tableBandedRows => 'Banded rows';

  @override
  String get tableBandedColumns => 'Banded columns';

  @override
  String get tableTotalRow => 'Total row';

  @override
  String tableCellsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cells selected',
      one: '1 cell selected',
    );
    return '$_temp0';
  }

  @override
  String get tableCellFill => 'Fill';

  @override
  String get tableStyleFill => 'Table style';

  @override
  String get tableVerticalAlign => 'Align';

  @override
  String get tableCellPadding => 'Padding';

  @override
  String get tableStyleDefault => 'Default';

  @override
  String get tableBorders => 'Borders';

  @override
  String tableBorderEdge(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'all': 'All borders',
      'outer': 'Outer borders',
      'inner': 'Inner borders',
      'horizontal': 'Inner horizontal borders',
      'vertical': 'Inner vertical borders',
      'top': 'Top border',
      'bottom': 'Bottom border',
      'left': 'Left border',
      'right': 'Right border',
      'none': 'Clear borders',
      'other': 'Borders',
    });
    return '$_temp0';
  }

  @override
  String tableBorderStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'solid': 'Solid',
      'dashed': 'Dashed',
      'dotted': 'Dotted',
      'other': 'Solid',
    });
    return '$_temp0';
  }

  @override
  String get cmdPresentEnd => 'End presentation';

  @override
  String get cmdPresentNext => 'Next';

  @override
  String get cmdPresentPrevious => 'Previous';

  @override
  String get cmdPresentNextSlide => 'Next slide';

  @override
  String get cmdPresentPreviousSlide => 'Previous slide';

  @override
  String get cmdPresentGoTo => 'Go to slide';

  @override
  String get cmdPresentFirst => 'First slide';

  @override
  String get cmdPresentLast => 'Last slide';

  @override
  String get cmdPresentBlank => 'Black or white screen';

  @override
  String get cmdPresentPicker => 'Slide picker';

  @override
  String get cmdPresentTool => 'Pointer tool';

  @override
  String get cmdPresentClearInk => 'Clear ink on this slide';

  @override
  String get cmdPresentUndoInk => 'Undo last ink stroke';

  @override
  String get cmdPresentTimer => 'Presenter timer';

  @override
  String get cmdPresentJoinAsAudience => 'Show audience view here';

  @override
  String get cmdPresentToggleFullscreen => 'Full screen';

  @override
  String get cmdPresentToggleSkipped => 'Show skipped slides';

  @override
  String get cmdPresentNotesSize => 'Speaker notes size';

  @override
  String get cmdPresentHelp => 'Keyboard shortcuts';

  @override
  String get cmdDeckSetPresentSettings => 'Presentation settings';

  @override
  String get reasonNotPresenting => 'Not presenting';

  @override
  String get reasonPresenterViewOnly => 'Only in the presenter view';

  @override
  String get presentUnknownSlide => 'That slide isn’t in this presentation';

  @override
  String presentSlideLabel(int number, int total) {
    return 'Slide $number of $total';
  }

  @override
  String get presentEndScreen => 'End of presentation — click to exit';

  @override
  String get presentKioskExitHold => 'Keep holding Esc to exit';

  @override
  String get presenterReducedEffects => 'Reduced effects';

  @override
  String get presentCatchingUp => 'Catching up…';

  @override
  String get presentToolbarLabel => 'Presentation controls';

  @override
  String presentCounterLabel(int number, int total) {
    return 'Slide $number of $total. Open the slide picker';
  }

  @override
  String get presentToolLaser => 'Laser pointer';

  @override
  String get presentToolPen => 'Pen';

  @override
  String get presentToolHighlighter => 'Highlighter';

  @override
  String get presentToolEraser => 'Eraser';

  @override
  String get presentBlackScreen => 'Black screen';

  @override
  String get presentWhiteScreen => 'White screen';

  @override
  String get presentEnd => 'End';

  @override
  String presentGoToNumber(String number) {
    return 'Go to $number';
  }

  @override
  String get presentHelpTitle => 'Presenting shortcuts';

  @override
  String get presentHelpGoToNumber => 'Go to slide number';

  @override
  String get presentHelpDigits => '1 2 3 … Enter';

  @override
  String get presentHelpTemporaryLaser => 'Laser while held (move the mouse)';

  @override
  String get presentTimerPause => 'Pause or resume the timer';

  @override
  String get presentTimerResume => 'Resume the timer';

  @override
  String get presentTimerReset => 'Reset the timer';

  @override
  String get presentNotesLarger => 'Larger notes';

  @override
  String get presentNotesSmaller => 'Smaller notes';

  @override
  String get presentResume => 'Resume (clicker F5)';

  @override
  String get presentFullscreenHint => 'Press F11 (⌃⌘F on Mac) for full screen';

  @override
  String get presentFullscreenButton => 'Full screen';

  @override
  String get presentAudienceTitle => 'Audience view';

  @override
  String get presentAudienceBody =>
      'This screen shows the slides of your presentation.';

  @override
  String presentAudienceBodyFrom(String device) {
    return 'This screen shows the slides you present on $device.';
  }

  @override
  String get presentAudienceKeys =>
      'A clicker or the arrow keys here also move the presentation.';

  @override
  String get presentAudienceStay => 'Stay in window';

  @override
  String get presentGoToSlideMenu => 'Go to slide…';

  @override
  String get presentPickerTitle => 'Go to slide';

  @override
  String get presentPickerFilter => 'Filter by title or number';

  @override
  String get presentPickerClose => 'Close';

  @override
  String get presentPickerNoMatch => 'No slides match';

  @override
  String presentPickerGroup(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
    );
    return '$title, $_temp0';
  }

  @override
  String presentPickerSlide(int number, String title) {
    return 'Slide $number: $title';
  }

  @override
  String get presentPickerSkipped => 'Skipped';

  @override
  String get presentOpenOnDeviceTitle => 'Open on another device';

  @override
  String get presentOpenOnDeviceBody =>
      'Open this link on the computer or browser that shows the slides — for example the one connected to the projector. Sign in with your account there.';

  @override
  String get presentOpenOnDeviceHint =>
      'Or open this presentation there and choose “Show audience view here”.';

  @override
  String get presentAudienceLink => 'Audience link';

  @override
  String get presentCopyLink => 'Copy link';

  @override
  String get presentLinkCopied => 'Copied';

  @override
  String get presentDone => 'Done';

  @override
  String get presentQrLabel => 'QR code of the audience link';

  @override
  String get presentOfflineNoDevices => 'Offline — other devices can’t join';

  @override
  String get presentOfflineNoDevicesBody =>
      'You can keep presenting here. Other devices join once you’re back online.';

  @override
  String get presentConnecting => 'Connecting…';

  @override
  String get presentSessionEnded => 'Not connected to other devices';

  @override
  String presentAudienceDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other devices',
      one: '1 other device',
      zero: 'No other devices yet',
    );
    return '$_temp0';
  }

  @override
  String get presentPresenterAway => 'Waiting for the presenter…';

  @override
  String get presentWaitingForPresenter => 'Waiting for the presenter';

  @override
  String get presentAudienceEndedToast => 'The presentation ended';

  @override
  String get presentAudienceNotFound => 'This presentation isn’t running';

  @override
  String get presentAudienceNotFoundBody =>
      'Ask the presenter for a new link, or open the presentation and choose “Show audience view here”.';

  @override
  String get presentAudienceNoAccess =>
      'Only the presenter can show this audience view';

  @override
  String get presentTakeOverTitle => 'Take over the presentation?';

  @override
  String get presentTakeOverBody =>
      'You’re presenting this in another window. Take over the presentation from your other window?';

  @override
  String get presentTakeOver => 'Take over';

  @override
  String get presentTakeOverCancel => 'Present here only';

  @override
  String get presentTakenOverToast =>
      'Your presentation continues in another window';

  @override
  String get presentExtendedHintTitle => 'Showing the slides on a projector?';

  @override
  String get presentExtendedHintBody =>
      'Open this presentation in a window there and choose “Show audience view here” — or use “Open on another device…”.';

  @override
  String get presenterViewTitle => 'Presenter view';

  @override
  String presenterViewTitleWithName(String name) {
    return 'Presenter view — $name';
  }

  @override
  String get presenterOtherDevice => 'Other device…';

  @override
  String get presenterCurrent => 'Current slide';

  @override
  String presenterCurrentStep(int step, int count) {
    return 'Current slide · step $step of $count';
  }

  @override
  String get presenterAudienceBlack => 'Audience: black screen';

  @override
  String get presenterAudienceWhite => 'Audience: white screen';

  @override
  String get presenterShowSlide => 'Show slide';

  @override
  String presenterNextBuild(int step, int count) {
    return 'Next: build $step of $count';
  }

  @override
  String presenterNextSlide(String title) {
    return 'Next slide: $title';
  }

  @override
  String get presenterNextSlideUntitled => 'Next slide';

  @override
  String get presenterNextEnd => 'End of presentation';

  @override
  String get presenterNextExit => 'Next: exit';

  @override
  String get presenterNotes => 'Speaker notes';

  @override
  String get presenterNoNotes => 'No speaker notes for this slide';

  @override
  String presenterElapsed(String time) {
    return 'Elapsed $time';
  }

  @override
  String presenterRemaining(String time) {
    return 'Remaining $time';
  }

  @override
  String presenterSlideOf(int number, int total) {
    return 'Slide $number / $total';
  }

  @override
  String presenterAhead(String time) {
    return '$time ahead';
  }

  @override
  String presenterBehind(String time) {
    return '$time behind';
  }

  @override
  String get presenterStrip => 'Slides';

  @override
  String presentBannerTitle(String device) {
    return 'You’re presenting on $device';
  }

  @override
  String get presentBannerTitleNoDevice =>
      'You’re presenting this presentation';

  @override
  String get presentBannerDismiss => 'Dismiss';

  @override
  String get cmdEditCopy => 'Copy';

  @override
  String get cmdEditCut => 'Cut';

  @override
  String get cmdEditPaste => 'Paste';

  @override
  String get reasonCopyNotAllowed => 'The owner turned off copying for viewers';

  @override
  String get reasonPasteObjectsOnSlide => 'Paste objects on a slide';

  @override
  String get reasonPasteSlidesNotInCells =>
      'Paste slides in the slide navigator';

  @override
  String get toastClipboardEmpty => 'There is nothing to paste';

  @override
  String get toastPasteChartsUnavailable =>
      'Charts from Wonky Sheets can\'t be pasted into presentations';

  @override
  String get toastPasteClipped =>
      'Only the cells that fit in the table were pasted';

  @override
  String get toastPasteTruncated =>
      'Only the first 50 rows and 20 columns were pasted';

  @override
  String get pasteChartLinked => 'Linked to the spreadsheet';

  @override
  String get pasteOptionsLabel => 'Paste options';

  @override
  String get cmdFindNext => 'Find next';

  @override
  String get cmdFindPrevious => 'Find previous';

  @override
  String get cmdFindReplace => 'Replace';

  @override
  String get cmdFindReplaceAll => 'Replace all';

  @override
  String get undoReplaceAll => 'Replace all';

  @override
  String get findClose => 'Close find';

  @override
  String get findPlaceholder => 'Find in presentation';

  @override
  String get findNoResults => 'No results';

  @override
  String findOfCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String findMatchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get findReplaceTitle => 'Find and replace';

  @override
  String get findLabel => 'Find';

  @override
  String get replaceLabel => 'Replace with';

  @override
  String get findMatchCase => 'Match case';

  @override
  String get findWholeWords => 'Whole words';

  @override
  String get findUseRegex => 'Use regular expressions';

  @override
  String get findIncludeNotes => 'Include speaker notes';

  @override
  String get findIncludeSkipped => 'Include skipped slides';

  @override
  String get findScope => 'Search in';

  @override
  String get findScopeAll => 'All slides';

  @override
  String get findScopeCurrent => 'Current slide';

  @override
  String get findScopeSelected => 'Selected slides';

  @override
  String get findButtonPrevious => 'Previous';

  @override
  String get findButtonNext => 'Next';

  @override
  String get findInvalidRegex => 'This regular expression is not valid';

  @override
  String toastReplacedAll(int count, String find, String replace) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Replaced $count instances of “$find” with “$replace”',
      one: 'Replaced 1 instance of “$find” with “$replace”',
      zero: 'Nothing was replaced',
    );
    return '$_temp0';
  }

  @override
  String toastReplaceSkipped(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches in text $name is editing were skipped',
      one: '1 match in text $name is editing was skipped',
    );
    return '$_temp0';
  }

  @override
  String toastFindBodyLocked(String name) {
    return '$name is editing this text';
  }

  @override
  String get cmdLayoutAdd => 'New layout';

  @override
  String get cmdLayoutDuplicate => 'Duplicate layout';

  @override
  String get cmdLayoutRename => 'Rename layout…';

  @override
  String get cmdLayoutMove => 'Move layout';

  @override
  String get cmdLayoutDelete => 'Delete layout';

  @override
  String get cmdLayoutSetBackground => 'Layout background';

  @override
  String get cmdLayoutSetHideMasterElements => 'Hide master objects';

  @override
  String get cmdLayoutToggleHidden => 'Hide in layout picker';

  @override
  String get cmdMasterAdd => 'New master';

  @override
  String get cmdMasterDuplicate => 'Duplicate master';

  @override
  String get cmdMasterRename => 'Rename master…';

  @override
  String get cmdMasterDelete => 'Delete master';

  @override
  String get cmdMasterSetBackground => 'Master background';

  @override
  String get cmdMastersExit => 'Close masters view';

  @override
  String get cmdThemeUpdate => 'Edit theme';

  @override
  String get cmdThemeDeriveDarkColors => 'Derive dark colors';

  @override
  String get cmdThemeResetToBuiltIn => 'Reset to built-in theme';

  @override
  String get reasonNoLayout => 'Select a layout';

  @override
  String get reasonNoMaster => 'Select a master';

  @override
  String get reasonLastLayout => 'A master needs at least one layout';

  @override
  String get reasonLastMaster => 'A theme needs at least one master';

  @override
  String reasonLayoutUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $count slides — apply another layout first',
      one: 'Used by 1 slide — apply another layout first',
    );
    return '$_temp0';
  }

  @override
  String reasonMasterUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $count slides — apply another layout first',
      one: 'Used by 1 slide — apply another layout first',
    );
    return '$_temp0';
  }

  @override
  String get reasonMastersOnly => 'Open Edit masters and layouts first';

  @override
  String get reasonNotBuiltInTheme =>
      'This theme isn’t based on a built-in theme';

  @override
  String layoutDefaultName(int n) {
    return 'Layout $n';
  }

  @override
  String masterDefaultName(int n) {
    return 'Master $n';
  }

  @override
  String get layoutRenameTitle => 'Rename layout';

  @override
  String get masterRenameTitle => 'Rename master';

  @override
  String get layoutDeleteTitle => 'Delete layout?';

  @override
  String layoutDeleteUsedBody(int count, String name, String replacement) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count slides use “$name”. Apply “$replacement” to them and delete the layout?',
      one:
          '1 slide uses “$name”. Apply “$replacement” to it and delete the layout?',
    );
    return '$_temp0';
  }

  @override
  String get layoutDeleteApplyAndDelete => 'Apply and delete';

  @override
  String placeholderPrompt(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'title': 'Click to add title',
      'subtitle': 'Click to add subtitle',
      'body': 'Click to add text',
      'picture': 'Click to add a picture',
      'chart': 'Click to add a chart',
      'table': 'Click to add a table',
      'code': 'Click to add code',
      'caption': 'Click to add a caption',
      'bigNumber': '100%',
      'quote': 'Click to add a quote',
      'attribution': 'Name, role',
      'object': 'Click to add an object',
      'other': 'Click to add text',
    });
    return '$_temp0';
  }

  @override
  String get inspectorLayout => 'Layout';

  @override
  String get inspectorMaster => 'Master';

  @override
  String get inspectorTheme => 'Theme';

  @override
  String get mastersNavigatorLabel => 'Masters and layouts';

  @override
  String mastersMasterName(String name) {
    return 'Master · $name';
  }

  @override
  String get mastersHiddenInPicker => 'Hidden in layout picker';

  @override
  String get mastersMoveUp => 'Move up';

  @override
  String get mastersMoveDown => 'Move down';

  @override
  String mastersBannerLayout(String name, String theme, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Editing layout “$name” of theme $theme — changes apply to $count slides',
      one: 'Editing layout “$name” of theme $theme — changes apply to 1 slide',
      zero: 'Editing layout “$name” of theme $theme — no slides use it yet',
    );
    return '$_temp0';
  }

  @override
  String mastersBannerMaster(String name, String theme, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Editing master “$name” of theme $theme — changes apply to $count slides',
      one: 'Editing master “$name” of theme $theme — changes apply to 1 slide',
      zero: 'Editing master “$name” of theme $theme — no slides use it yet',
    );
    return '$_temp0';
  }

  @override
  String get mastersBannerNone => 'This presentation has no layouts to edit';

  @override
  String get mastersDone => 'Done';

  @override
  String mastersLayoutSemantics(String name) {
    return 'Layout $name';
  }

  @override
  String mastersMasterSemantics(String name) {
    return 'Master $name';
  }

  @override
  String get mastersSectionProperties => 'Properties';

  @override
  String get mastersSectionPlaceholders => 'Placeholders';

  @override
  String get mastersNoPlaceholders => 'No placeholders yet';

  @override
  String get mastersChoosePlaceholder => 'Add…';

  @override
  String mastersOfTheme(String name) {
    return 'Theme $name';
  }

  @override
  String get mastersBackgroundUseMaster => 'Use master background';

  @override
  String get mastersBackgroundUseTheme => 'Use theme background';

  @override
  String get themeSectionColors => 'Colors';

  @override
  String get themeSectionFonts => 'Fonts';

  @override
  String get themeSectionTextStyles => 'Text styles';

  @override
  String get themeSectionObjects => 'Objects';

  @override
  String get themeSectionTables => 'Tables';

  @override
  String get themeSectionCharts => 'Charts';

  @override
  String get themeEditorNoTheme => 'This presentation has no theme';

  @override
  String themeEditorBasedOn(String name) {
    return 'Based on $name';
  }

  @override
  String themeContrastPair(String foreground, String background) {
    return '$foreground on $background';
  }

  @override
  String themeContrastPasses(String pair, String ratio, String required) {
    return '$pair: contrast $ratio (needs $required:1)';
  }

  @override
  String themeContrastFails(String pair, String ratio, String required) {
    return '$pair: contrast $ratio is too low (needs $required:1)';
  }

  @override
  String get themeEditorCustomColors => 'Custom colors';

  @override
  String get themeEditorCustomColorName => 'Custom color name';

  @override
  String themeEditorCustomColorDefault(int n) {
    return 'Custom $n';
  }

  @override
  String get themeEditorAddCustomColor => 'Add custom color';

  @override
  String themeEditorRemoveCustomColor(String name) {
    return 'Remove $name';
  }

  @override
  String themeEditorWeight(String weight) {
    String _temp0 = intl.Intl.selectLogic(weight, {
      '300': 'Light',
      '400': 'Regular',
      '500': 'Medium',
      '600': 'Semibold',
      '700': 'Bold',
      '800': 'Extra bold',
      'other': '$weight',
    });
    return '$_temp0';
  }

  @override
  String themeEditorFontFallback(String family, String fallback) {
    return '$family isn’t available; $fallback is used';
  }

  @override
  String get themeEditorItalic => 'Italic';

  @override
  String get themeEditorLetterSpacing => 'Letter spacing';

  @override
  String get themeEditorCaps => 'Capitals';

  @override
  String get themeEditorLists => 'Lists';

  @override
  String themeEditorListLevel(int n) {
    return 'Level $n';
  }

  @override
  String get themeEditorBulletColor => 'Bullet color';

  @override
  String get themeEditorIndent => 'Indent per level';

  @override
  String get themeEditorBackgroundNotSolid =>
      'The background is a gradient or an image; picking a color replaces it.';

  @override
  String get themeEditorDarkBackground => 'Different in dark appearance';

  @override
  String get themeEditorTextBoxes => 'Text boxes';

  @override
  String get themeEditorShapes => 'Shapes';

  @override
  String get themeEditorLines => 'Lines';

  @override
  String get themeEditorIcons => 'Icons';

  @override
  String get themeEditorTextColor => 'Text color';

  @override
  String get themeEditorShadowBlur => 'Blur';

  @override
  String get themeEditorShadowOffset => 'Offset';

  @override
  String get themeEditorQuickStyles => 'Quick styles';

  @override
  String themeEditorQuickStyle(int n) {
    return 'Style $n';
  }

  @override
  String get themeEditorHeaderFill => 'Header fill';

  @override
  String get themeEditorHeaderText => 'Header text';

  @override
  String get themeEditorBodyFill => 'Body fill';

  @override
  String get themeEditorBandFill => 'Banded rows';

  @override
  String get themeEditorCornerRadius => 'Corner radius';

  @override
  String get themeEditorLightPalette => 'Light palette';

  @override
  String get themeEditorDarkPalette => 'Dark palette';

  @override
  String get themeEditorWindowChrome => 'Chrome';

  @override
  String get themeEditorChromeTab => 'Tab';

  @override
  String get themeEditorChromeWindow => 'Window';

  @override
  String get themeEditorChromeCaption => 'Caption';

  @override
  String get themeEditorShadowSoft => 'Soft';

  @override
  String get themeEditorShadowStrong => 'Strong';

  @override
  String themeEditorSeries(int n) {
    return 'Series $n';
  }

  @override
  String get themeEditorGridlines => 'Gridlines';

  @override
  String get themeEditorAxis => 'Axis';

  @override
  String get themeEditorLighting => '3D lighting';

  @override
  String get themeEditorLightingSoft => 'Soft';

  @override
  String get themeEditorLightingStudio => 'Studio';

  @override
  String get themeEditorLightingFlat => 'Flat';

  @override
  String get cmdInsertCodeDescription =>
      'Insert a code block with syntax highlighting, line steps and type-in states';

  @override
  String get cmdCodeSetPalette => 'Code color theme';

  @override
  String get cmdCodeSetText => 'Set code';

  @override
  String get cmdCodeAddStateDescription =>
      'Adds a copy of the selected state after it: change the code there to animate the change';

  @override
  String get cmdCodeDuplicateState => 'Duplicate state';

  @override
  String get cmdCodeDeleteState => 'Delete state';

  @override
  String get cmdCodeMoveState => 'Move state';

  @override
  String get cmdCodeSelectState => 'Show code state';

  @override
  String get cmdCodeSetStateLabel => 'Rename state';

  @override
  String get cmdCodeSetStateTransition => 'State arrival';

  @override
  String get cmdCodeSetCallout => 'Step callout';

  @override
  String get cmdCodeAddStepFromLines => 'Add line step';

  @override
  String get cmdCodePreviewStep => 'Preview line step';

  @override
  String get cmdCodePreview => 'Preview code animation';

  @override
  String get cmdCodeToggleDiffGutter => 'Show code changes';

  @override
  String get cmdCodeCopy => 'Copy code';

  @override
  String get cmdCodeConvertFromText => 'Convert to code block';

  @override
  String get reasonSelectCode => 'Select a code block';

  @override
  String get reasonLastCodeState => 'A code block keeps at least one state';

  @override
  String get reasonSelectTextBox => 'Select a text box with text';

  @override
  String get toastCodeCopied => 'Code copied';

  @override
  String get undoEditCodeBlock => 'Edit code block';

  @override
  String get undoEditCodeState => 'Edit code state';

  @override
  String get undoEditLineSteps => 'Edit line steps';

  @override
  String get undoEditCallout => 'Edit callout';

  @override
  String get codeLanguageLabel => 'Language';

  @override
  String get codeLanguageDialogTitle => 'Code language';

  @override
  String get codeInsertDialogTitle => 'Insert code block';

  @override
  String get codePaletteLabel => 'Colors';

  @override
  String get codePaletteAuto => 'Auto';

  @override
  String codePaletteAutoNamed(String name) {
    return 'Auto ($name)';
  }

  @override
  String get codePaletteLight => 'Theme light';

  @override
  String get codePaletteDark => 'Theme dark';

  @override
  String get codeFontSize => 'Font size';

  @override
  String get codeFontSizeAuto => 'Auto';

  @override
  String get codeFontSizeRange => 'Min – max';

  @override
  String get codeStartLine => 'Start at';

  @override
  String get codeWrap => 'Wrap lines';

  @override
  String get codeLigatures => 'Ligatures';

  @override
  String get codeChrome => 'Frame';

  @override
  String get codeChromeTheme => 'Theme default';

  @override
  String get codeChromeNone => 'None';

  @override
  String get codeChromeTab => 'File tab';

  @override
  String get codeChromeWindow => 'Window';

  @override
  String get codeChromeCaption => 'Caption';

  @override
  String get codeTitle => 'Title';

  @override
  String get codeShowLanguage => 'Language badge';

  @override
  String get codeCopyButton => 'Copy button';

  @override
  String get codeCopyNever => 'Never';

  @override
  String get codeCopyPresent => 'In presentations';

  @override
  String get codeCopyAlways => 'Always';

  @override
  String get codeStatesHeader => 'States';

  @override
  String codeStateChip(int index) {
    return 'State $index';
  }

  @override
  String codeStateChipNamed(int index, String label) {
    return 'State $index: $label';
  }

  @override
  String codeStateInfoFirst(int index, int lines) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines lines',
      one: '1 line',
    );
    return 'State $index · $_temp0';
  }

  @override
  String codeStateInfo(
    int index,
    int lines,
    int added,
    int changed,
    int removed,
    int previous,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines lines',
      one: '1 line',
    );
    return 'State $index · $_temp0 · +$added ~$changed −$removed vs. state $previous';
  }

  @override
  String get codeMoveStateLeft => 'Move state earlier';

  @override
  String get codeMoveStateRight => 'Move state later';

  @override
  String get codePreviewTypeIn => 'Preview the type-in';

  @override
  String get codePreviewChange => 'Preview the change into this state';

  @override
  String get codeStateLabel => 'Name';

  @override
  String get codeStateLabelHint => 'e.g. Add caching';

  @override
  String get codeShowChanges => 'Show changes';

  @override
  String get codeTypeInHeader => 'Type-in';

  @override
  String get codeArrivalHeader => 'Arrival';

  @override
  String get codeArrivesBy => 'Arrives by';

  @override
  String get codeModeType => 'Typing';

  @override
  String get codeModeMorph => 'Morph';

  @override
  String get codeModeInstant => 'Instant';

  @override
  String codeDurationTyped(String seconds) {
    return '≈ $seconds s (typed)';
  }

  @override
  String codeDurationMorph(String seconds) {
    return '≈ $seconds s (morph)';
  }

  @override
  String codeDurationInstant(String seconds) {
    return '≈ $seconds s (crossfade)';
  }

  @override
  String get codeMore => 'More…';

  @override
  String codeLineStepsHeader(int index) {
    return 'Line steps (state $index)';
  }

  @override
  String get codeStepsEmpty => 'No steps: every line shows normally.';

  @override
  String get codeStepAll => 'All lines';

  @override
  String codeStepRow(int index, String lines) {
    return 'Step $index: $lines';
  }

  @override
  String get codeEditCallout => 'Callout';

  @override
  String get codeRemoveStep => 'Remove step';

  @override
  String get codeHighlightStyle => 'Highlight';

  @override
  String get codeStyleDim => 'Dim others';

  @override
  String get codeStyleBlur => 'Blur others';

  @override
  String get codeStyleDimBlur => 'Dim and blur';

  @override
  String get codeStyleBar => 'Bar';

  @override
  String get codeStyleBox => 'Box';

  @override
  String get codeStyleNone => 'None';

  @override
  String get codeFocus => 'Focus';

  @override
  String get codeFocusScroll => 'Scroll';

  @override
  String get codeFocusZoom => 'Zoom';

  @override
  String get codeFocusNone => 'None';

  @override
  String get codeFitAcrossStates => 'Same size in all states';

  @override
  String get codeStepsDialogTitle => 'Line steps';

  @override
  String get codeStepsHint =>
      'One step per click, separated by |: lines (5), ranges (1-3, 7-), lists (2,4); * shows all lines.';

  @override
  String get codeStepsLabel => 'Steps';

  @override
  String codeStepIssueSyntax(int index) {
    return 'Step $index: use a line, a range like 3-5 or 7-, or 4:2-9';
  }

  @override
  String codeStepIssuePastEnd(int index) {
    return 'Step $index points past the end of the code';
  }

  @override
  String codeStepIssueReversed(int index) {
    return 'Step $index: a range was reversed';
  }

  @override
  String codeStepIssueColumns(int index) {
    return 'Step $index: columns start at 1';
  }

  @override
  String codeCalloutDialogTitle(int index) {
    return 'Callout of step $index';
  }

  @override
  String get codeCalloutHint =>
      'Shown next to the step\'s lines. **Bold**, *italic* and `code` work.';

  @override
  String get codeCalloutText => 'Text';

  @override
  String get codeCalloutSide => 'Side';

  @override
  String get codeSideAuto => 'Automatic';

  @override
  String get codeSideRight => 'Right';

  @override
  String get codeSideLeft => 'Left';

  @override
  String get codeSideAbove => 'Above';

  @override
  String get codeSideBelow => 'Below';

  @override
  String get codeCalloutStyle => 'Style';

  @override
  String get codeCalloutStyleDefault => 'Default';

  @override
  String get codeCalloutBubble => 'Bubble';

  @override
  String get codeCalloutLabel => 'Label';

  @override
  String get codeCalloutPill => 'Pill';

  @override
  String get codeCalloutRemove => 'Remove callout';

  @override
  String get codeTypingDialogTitle => 'Typing settings';

  @override
  String get codeTypingCps => 'Speed (chars/s)';

  @override
  String get codeTypingRhythm => 'Rhythm';

  @override
  String get codeTypingDeletions => 'Deletions';

  @override
  String get codeDeleteAuto => 'Automatic';

  @override
  String get codeDeleteBackspace => 'Backspace';

  @override
  String get codeDeleteSelect => 'Select and delete';

  @override
  String get codeTypingBackspaceMax => 'Backspace up to (chars)';

  @override
  String get codeTypingDeleteCps => 'Backspace speed (chars/s)';

  @override
  String get codeTypingCaretGlide => 'Caret glide (ms)';

  @override
  String get codeTypingOrder => 'Order';

  @override
  String get codeOrderDocument => 'Top to bottom';

  @override
  String get codeOrderReverse => 'Bottom to top';

  @override
  String get codeTypingPasteLines => 'Paste from (lines)';

  @override
  String get codeTypingMaxDuration => 'Longest (ms)';

  @override
  String get codeTypingCaret => 'Caret';

  @override
  String get codeCaretBar => 'Bar';

  @override
  String get codeCaretBlock => 'Block';

  @override
  String get codeCaretUnderline => 'Underline';

  @override
  String get codeTypingAutoIndent => 'Auto-indent new lines';

  @override
  String get codeTypingScrollFollow => 'Scroll to the caret';

  @override
  String get codeTypingHighlightOnArrive => 'Show step 1 when typed';

  @override
  String get codeMorphDuration => 'Morph duration (ms)';

  @override
  String get codeMorphStagger => 'Morph stagger per line (ms)';

  @override
  String codeNumberRange(String min, String max) {
    return 'Enter a number from $min to $max';
  }

  @override
  String codeEditorSemantics(String language) {
    return 'Code editor, $language';
  }

  @override
  String codeLinesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines hidden',
      one: '1 line hidden',
    );
    return '$_temp0';
  }

  @override
  String get codeOverflowHint =>
      'Enlarge the box, lower the minimum size or turn on wrap';

  @override
  String get cmdChartUpdateMany => 'Update charts';

  @override
  String get cmdChartRelink => 'Change linked chart…';

  @override
  String get cmdChartSetUseDeckTheme => 'Match presentation theme';

  @override
  String get cmdChartUpdateStyle => 'Edit chart style';

  @override
  String get cmdChartResetOverrides => 'Reset style overrides';

  @override
  String get cmdChartSetCamera => 'Rotate 3D chart';

  @override
  String get cmdChartAddCameraStep => 'Add camera step';

  @override
  String get cmdChartViewDataTable => 'View data as table';

  @override
  String get cmdChartCheckUpdates => 'Check linked charts for updates';

  @override
  String get cmdInsertChartFromSheetsDescription =>
      'Insert a chart from a Wonky Sheets spreadsheet, linked so it can be updated.';

  @override
  String get reasonSelectChart => 'Select a chart';

  @override
  String get reasonSelectLinkedChart =>
      'Select a chart linked to a spreadsheet';

  @override
  String get reasonSelect3DChart => 'Select a 3D chart';

  @override
  String get reasonChartNoOverrides => 'The chart has no style overrides';

  @override
  String get undoInsertChart => 'Insert chart';

  @override
  String get undoUpdateChart => 'Update chart';

  @override
  String get undoUnlinkChart => 'Unlink chart';

  @override
  String get undoRelinkChart => 'Change linked chart';

  @override
  String get undoEditChartStyle => 'Edit chart style';

  @override
  String get undoRotateChart => 'Rotate chart';

  @override
  String get chartErrOffline =>
      'You\'re offline. Connect to insert or update charts from Sheets.';

  @override
  String get chartErrNoAccess =>
      'You don\'t have access to this spreadsheet anymore.';

  @override
  String get chartErrTrashed => 'This spreadsheet is in the trash.';

  @override
  String get chartErrExportDisabled =>
      'The owner doesn\'t allow viewers to copy charts from this spreadsheet.';

  @override
  String get chartErrNotFound => 'This chart was deleted. Pick another one.';

  @override
  String get chartErrTooLarge =>
      'This chart has too much data to place in a presentation. Reduce its range in Sheets.';

  @override
  String get chartErrUnsupported =>
      'This chart was made with a newer version of Wonky Sheets. Reload to insert it.';

  @override
  String get chartErrQuota => 'There isn\'t enough storage for this chart.';

  @override
  String get chartErrRateLimited =>
      'Too many chart requests. Try again in a minute.';

  @override
  String get chartErrFailed => 'Couldn\'t get the chart. Try again.';

  @override
  String get chartInsertDialogTitle => 'Insert chart from Wonky Sheets';

  @override
  String chartInsertFromTitle(String title) {
    return 'Insert chart from \"$title\"';
  }

  @override
  String get chartRelinkTitle => 'Change linked chart';

  @override
  String get chartSearchSpreadsheets => 'Search spreadsheets';

  @override
  String get chartSpreadsheetsLabel => 'Spreadsheet';

  @override
  String get chartTabRecent => 'Recent';

  @override
  String get chartTabMine => 'My files';

  @override
  String get chartTabShared => 'Shared with me';

  @override
  String get chartTabStarred => 'Starred';

  @override
  String get chartNoSpreadsheets => 'No spreadsheets found';

  @override
  String get chartListFailed => 'Couldn\'t load the list. Try again.';

  @override
  String get chartBack => 'Back';

  @override
  String get chartSearchCharts => 'Search charts';

  @override
  String get chartPickChart => 'Chart';

  @override
  String get chartNoCharts =>
      'This spreadsheet has no charts. Create one in Wonky Sheets.';

  @override
  String get chartOpenInSheets => 'Open in Sheets';

  @override
  String get chartLinkToSpreadsheet => 'Link to spreadsheet';

  @override
  String get chartMatchTheme => 'Match presentation theme';

  @override
  String get chartDataNotice =>
      'Anyone with access to this presentation will see this chart\'s data.';

  @override
  String get chartNewerVersion => 'Needs a newer version';

  @override
  String get chartSheetBadge => 'Chart sheet';

  @override
  String get chart3DBadge => '3D';

  @override
  String get chartUntitled => 'Untitled chart';

  @override
  String get chartUpdateAction => 'Update';

  @override
  String chartUpdateTooltip(String source, String summary) {
    return '$source changed$summary. Update to show the latest version.';
  }

  @override
  String get chartStatusLinked => 'Linked';

  @override
  String get chartStatusChanged => 'Linked · Source changed';

  @override
  String get chartStatusNoAccess => 'Linked · No access';

  @override
  String get chartStatusChartDeleted => 'Source chart deleted';

  @override
  String get chartStatusTrashed => 'Source in trash';

  @override
  String get chartStatusDeleted => 'Source deleted';

  @override
  String get chartStatusUnsupported => 'Linked · Needs a newer version';

  @override
  String chartStatusOffline(String status) {
    return '$status (offline)';
  }

  @override
  String chartStatusUpToDate(String when) {
    return 'Linked · Up to date ($when)';
  }

  @override
  String chartNewerDataToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charts have newer data',
      one: '1 chart has newer data',
    );
    return '$_temp0';
  }

  @override
  String chartAutoUpdatedToast(String sources) {
    return 'Charts updated from $sources';
  }

  @override
  String get chartPasteNoData =>
      'The chart\'s data couldn\'t be copied. Paste it again when you\'re online.';

  @override
  String get chartCopied => 'Chart copied';

  @override
  String get chartCopyFailed => 'Couldn\'t copy the chart.';

  @override
  String chartDataTableTitle(String title) {
    return 'Data of $title';
  }

  @override
  String get chartNoData => 'No data';

  @override
  String get chartNoDataYet => 'This chart has no data yet.';

  @override
  String get chartNotLinked => 'Not linked: shows a copy of the data.';

  @override
  String get chartAutoShort => 'Auto-update';

  @override
  String get chartUnlinkShort => 'Unlink';

  @override
  String get chartStyleMode => 'Style';

  @override
  String get chartMatchThemeShort => 'Match theme';

  @override
  String get chartKeepSource => 'Keep source style';

  @override
  String get chartBackground => 'Background';

  @override
  String get chartBackgroundDefault => 'Default';

  @override
  String get chartBackgroundTransparent => 'Transparent';

  @override
  String get chartBackgroundTheme => 'Slide background color';

  @override
  String get chartBackgroundWhite => 'White';

  @override
  String get chartCamera => '3D view';

  @override
  String get chartCameraPreset => 'View';

  @override
  String get chartCameraCustom => 'Custom';

  @override
  String get chartCameraRotation => 'Rotation';

  @override
  String get chartCameraTilt => 'Tilt';

  @override
  String get chartCameraPerspective => 'Perspective';

  @override
  String get chartCameraReset => 'Reset view';

  @override
  String get chartCameraHint =>
      'Drag the selected chart to orbit it. Alt+Shift+arrows rotate 5°.';

  @override
  String get chartPresetDefault => 'Default';

  @override
  String get chartPresetFront => 'Front';

  @override
  String get chartPresetIsometric => 'Isometric';

  @override
  String get chartPresetTopDown => 'Top-down';

  @override
  String get chartPresetLowAngle => 'Low angle';

  @override
  String get chartPresetSide => 'Side';

  @override
  String get chartPresetDramatic => 'Dramatic';

  @override
  String get chartPresetFlat => 'Flat';

  @override
  String get chartPresetTilted => 'Tilted';

  @override
  String get chartPresetSteep => 'Steep';

  @override
  String get chartPresenting => 'Presenting';

  @override
  String get chartHoverTooltips => 'Hover values';

  @override
  String get chartOrbitInPresent => 'Drag to orbit';

  @override
  String get chartCustomize => 'Customize';

  @override
  String chartUnusedOverrides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Overrides of $count series that no longer exist',
      one: 'Overrides of 1 series that no longer exists',
    );
    return '$_temp0';
  }

  @override
  String get chartCleanUp => 'Clean up';

  @override
  String get chartInvalidOverrides =>
      'Some style overrides are invalid and were ignored.';

  @override
  String chartUpdateAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Update all ($count)',
      zero: 'Update all',
    );
    return '$_temp0';
  }

  @override
  String get chartChecking => 'Checking…';

  @override
  String get chartNoLinkedCharts => 'This presentation has no linked charts.';

  @override
  String chartOnSlide(int number) {
    return 'Slide $number';
  }

  @override
  String get chartStyleTitles => 'Chart & axis titles';

  @override
  String get chartStyleLegend => 'Legend';

  @override
  String get chartStyleSeries => 'Series';

  @override
  String get chartStyleAxes => 'Axes';

  @override
  String get chartStyleGridlines => 'Gridlines';

  @override
  String get chartStylePie => 'Pie chart';

  @override
  String get chartStyle3D => '3D';

  @override
  String get chartStyleLayout => 'Layout';

  @override
  String get chartStyleChartTitle => 'Chart title';

  @override
  String get chartStyleSubtitle => 'Subtitle';

  @override
  String get chartStyleHAxisTitle => 'Horizontal axis title';

  @override
  String get chartStyleVAxisTitle => 'Vertical axis title';

  @override
  String get chartStyleLegendPosition => 'Position';

  @override
  String get chartStyleColor => 'Color';

  @override
  String get chartStyleLineWidth => 'Line width';

  @override
  String get chartStylePointSize => 'Point size';

  @override
  String get chartStyleDataLabels => 'Data labels';

  @override
  String get chartStyleHAxisLine => 'Horizontal axis line';

  @override
  String get chartStyleVAxisLine => 'Vertical axis line';

  @override
  String get chartStyleNumberFormat => 'Number format';

  @override
  String get chartStyleHGridlines => 'Horizontal axis gridlines';

  @override
  String get chartStyleVGridlines => 'Vertical axis gridlines';

  @override
  String get chartStyleMaximize => 'Maximize';

  @override
  String get chartStyleDonutHole => 'Donut hole';

  @override
  String get chartStyleSliceLabels => 'Slice labels';

  @override
  String get chartStyleStartAngle => 'Start angle';

  @override
  String get chartStyleLighting => 'Lighting';

  @override
  String get chartStyleWalls => 'Walls and floor';

  @override
  String get chartStyleDepth => 'Depth';

  @override
  String get chartStyleGapDepth => 'Gap depth';

  @override
  String get chartStyleShape => 'Shape';

  @override
  String get chartStyleExplode => 'Explode';

  @override
  String get chartStyleAutomatic => 'Automatic';

  @override
  String get chartStyleNone => 'None';

  @override
  String get chartStyleResetField => 'Reset to the spreadsheet\'s value';

  @override
  String get chartStyleChangedHere => 'Changed in this presentation';

  @override
  String get chartStyleLegendTop => 'Top';

  @override
  String get chartStyleLegendBottom => 'Bottom';

  @override
  String get chartStyleLegendLeft => 'Left';

  @override
  String get chartStyleLegendRight => 'Right';

  @override
  String get chartStyleLegendInside => 'Inside';

  @override
  String get chartStyleSliceLabel => 'Label';

  @override
  String get chartStyleSliceValue => 'Value';

  @override
  String get chartStyleSlicePercent => 'Percentage';

  @override
  String get chartStyleSliceValuePercent => 'Value and percentage';

  @override
  String get chartStyleLightingSoft => 'Soft';

  @override
  String get chartStyleLightingBright => 'Bright';

  @override
  String get chartStyleLightingFlat => 'Flat';

  @override
  String get chartStyleShapeBox => 'Box';

  @override
  String get chartStyleShapeCylinder => 'Cylinder';

  @override
  String get chartStyleShapeCone => 'Cone';

  @override
  String get chartStyleShapePyramid => 'Pyramid';

  @override
  String animateEffectName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'appear': 'Appear',
      'fade': 'Fade',
      'rise': 'Rise',
      'moveIn': 'Move in',
      'scale': 'Scale',
      'pop': 'Pop',
      'zoom': 'Zoom',
      'blur': 'Blur',
      'wipe': 'Wipe',
      'iris': 'Iris',
      'dissolve': 'Dissolve',
      'drop': 'Drop',
      'flip': 'Flip',
      'rotate': 'Rotate',
      'typewriter': 'Typewriter',
      'lineDraw': 'Draw line',
      'chartGrow': 'Grow',
      'codeType': 'Type code',
      'shimmer': 'Shimmer',
      'disappear': 'Disappear',
      'fadeOut': 'Fade out',
      'sink': 'Sink',
      'moveOut': 'Move out',
      'scaleOut': 'Scale out',
      'popOut': 'Pop out',
      'zoomOut': 'Zoom out',
      'blurOut': 'Blur out',
      'wipeOut': 'Wipe out',
      'irisOut': 'Iris out',
      'dissolveOut': 'Dissolve out',
      'fall': 'Fall',
      'flipOut': 'Flip out',
      'rotateOut': 'Rotate out',
      'eraseText': 'Erase text',
      'lineErase': 'Erase line',
      'chartShrink': 'Shrink',
      'pulse': 'Pulse',
      'bounce': 'Bounce',
      'shake': 'Shake',
      'blink': 'Blink',
      'spin': 'Spin',
      'grow': 'Grow / shrink',
      'opacityTo': 'Transparency',
      'colorChange': 'Color change',
      'highlight': 'Highlight',
      'chartHighlight': 'Highlight series',
      'chartHighlightClear': 'Clear highlight',
      'chartOrbit': 'Orbit',
      'chartCamera': 'Rotate to angle',
      'codeHighlight': 'Highlight lines',
      'codeState': 'Next code state',
      'path': 'Motion path',
      'moveTo': 'Transform',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String animateEffectDescription(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'appear': 'The object appears at once.',
      'fade': 'The object fades in.',
      'rise': 'The object moves up a short distance while fading in.',
      'moveIn': 'The object moves in from a side or from off the slide.',
      'scale': 'The object grows to its size while fading in.',
      'pop': 'The object pops in with a little bounce.',
      'zoom': 'The object comes toward its place from in front of the viewer.',
      'blur': 'The object comes into focus.',
      'wipe': 'A soft edge sweeps across and reveals the object.',
      'iris': 'A growing circle, square or diamond reveals the object.',
      'dissolve': 'The object appears through a grain of random cells.',
      'drop': 'The object falls into place and bounces.',
      'flip': 'The object flips into view like a card.',
      'rotate': 'The object turns into place.',
      'typewriter': 'The text is typed character by character.',
      'lineDraw': 'The outline draws itself, then the fill fades in.',
      'chartGrow': 'Bars grow, lines draw on and wedges sweep in.',
      'codeType': 'The code is typed into the block.',
      'shimmer': 'Particles condense into the text.',
      'disappear': 'The object disappears at once.',
      'fadeOut': 'The object fades out.',
      'sink': 'The object moves down a short distance while fading out.',
      'moveOut': 'The object moves out to a side or off the slide.',
      'scaleOut': 'The object shrinks while fading out.',
      'popOut': 'The object grows a little, then collapses.',
      'zoomOut': 'The object moves toward the viewer and fades away.',
      'blurOut': 'The object goes out of focus.',
      'wipeOut': 'A soft edge sweeps across and hides the object.',
      'irisOut': 'A shrinking circle, square or diamond hides the object.',
      'dissolveOut': 'The object disappears into a grain of random cells.',
      'fall': 'The object falls off the slide.',
      'flipOut': 'The object flips away like a card.',
      'rotateOut': 'The object turns away.',
      'eraseText': 'The text is erased from the end, like backspacing.',
      'lineErase': 'The outline erases itself.',
      'chartShrink': 'Bars shrink, lines erase and wedges sweep out.',
      'pulse': 'The object briefly grows and returns.',
      'bounce': 'The object jumps up and lands.',
      'shake': 'The object shakes from side to side.',
      'blink': 'The object blinks.',
      'spin': 'The object spins and keeps its new angle.',
      'grow': 'The object changes its size and keeps it.',
      'opacityTo': 'The object becomes more or less transparent.',
      'colorChange': 'The fill, border or text changes color.',
      'highlight': 'A marker sweeps behind the text.',
      'chartHighlight': 'One series stands out; the rest dims.',
      'chartHighlightClear': 'Every series is shown normally again.',
      'chartOrbit': 'The 3D chart turns around.',
      'chartCamera': 'The 3D chart turns to a new view.',
      'codeHighlight': 'The next highlight step of the code is shown.',
      'codeState': 'The code changes to its next state.',
      'path': 'The object moves along a path.',
      'moveTo': 'The object moves, resizes, turns or fades to an end state.',
      'other': 'An animation from a newer version.',
    });
    return '$_temp0';
  }

  @override
  String animateTransitionName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'none': 'None',
      'fade': 'Fade',
      'dissolve': 'Dissolve',
      'push': 'Push',
      'slide': 'Slide in',
      'cover': 'Cover',
      'uncover': 'Uncover',
      'wipe': 'Wipe',
      'iris': 'Iris',
      'zoom': 'Zoom',
      'flip': 'Flip',
      'cube': 'Cube',
      'doorway': 'Doorway',
      'swap': 'Swap',
      'revolve': 'Revolve',
      'magicMove': 'Magic Move',
      'other': 'Transition',
    });
    return '$_temp0';
  }

  @override
  String animateTransitionDescription(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'none': 'The new slide replaces the old one at once.',
      'fade':
          'The new slide fades in over the old one, or both fade through a color.',
      'dissolve': 'The new slide appears through a grain of random cells.',
      'push': 'The new slide pushes the old one off the screen.',
      'slide': 'The new slide slides in over the old one.',
      'cover': 'The new slide slides over the old one, which dims.',
      'uncover': 'The old slide slides away and reveals the new one.',
      'wipe': 'A soft edge sweeps across and reveals the new slide.',
      'iris': 'A growing circle, square or diamond reveals the new slide.',
      'zoom': 'The new slide grows in, or the old one shrinks away.',
      'flip': 'The slide flips over like a card; the new slide is on its back.',
      'cube': 'Both slides are faces of a cube that turns a quarter turn.',
      'doorway':
          'The old slide opens like double doors; the new one comes forward.',
      'swap': 'The slides swap places, front and back, on an arc.',
      'revolve': 'The old slide swings away on its edge like a door.',
      'magicMove':
          'Objects on both slides morph into each other; the rest fades.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String animateParamName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'distance': 'Distance',
      'fade': 'Fade',
      'direction': 'Direction',
      'from': 'From',
      'to': 'To',
      'origin': 'Origin',
      'bounce': 'Bounce',
      'softness': 'Softness',
      'shape': 'Shape',
      'cell': 'Grain',
      'height': 'Height',
      'bounces': 'Bounces',
      'axis': 'Axis',
      'perspective': 'Perspective',
      'angle': 'Angle',
      'scale': 'Scale',
      'cps': 'Characters/s',
      'caret': 'Caret',
      'jitter': 'Jitter',
      'fillDelay': 'Fill delay',
      'count': 'Times',
      'amplitude': 'Amplitude',
      'opacity': 'Opacity',
      'property': 'Property',
      'color': 'Color',
      'style': 'Style',
      'target': 'Series',
      'dimOthers': 'Dim others',
      'azimuth': 'Azimuth',
      'elevation': 'Elevation',
      'step': 'Step',
      'state': 'State',
      'mode': 'Mode',
      'path': 'Path',
      'preset': 'Preset',
      'orientToPath': 'Orient to path',
      'relativeEnd': 'Relative end',
      'anticipation': 'Anticipation',
      'rotation': 'Rotation',
      'through': 'Through color',
      'persist': 'Keep end state',
      'other': 'Option',
    });
    return '$_temp0';
  }

  @override
  String animateChoiceName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'left': 'Left',
      'right': 'Right',
      'top': 'Top',
      'bottom': 'Bottom',
      'up': 'Up',
      'down': 'Down',
      'topLeft': 'Top left',
      'topRight': 'Top right',
      'bottomLeft': 'Bottom left',
      'bottomRight': 'Bottom right',
      'center': 'Center',
      'circle': 'Circle',
      'rect': 'Square',
      'diamond': 'Diamond',
      'x': 'Horizontal',
      'y': 'Vertical',
      'forward': 'Forward',
      'backward': 'Backward',
      'in': 'In',
      'out': 'Out',
      'baseline': 'Baseline',
      'fill': 'Fill',
      'stroke': 'Border',
      'text': 'Text',
      'marker': 'Marker',
      'underline': 'Underline',
      'box': 'Box',
      'type': 'Type',
      'morph': 'Morph',
      'instant': 'Instant',
      'line': 'Line',
      'arc': 'Arc',
      'curve': 'Curve',
      'zigzag': 'Zigzag',
      'custom': 'Custom',
      'object': 'Object',
      'word': 'Word',
      'character': 'Character',
      'shortest': 'Shortest',
      'literal': 'As set',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String animateTargetReason(String effect, String target) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'text': '$effect works on text only',
      'stroke': '$effect works on shapes, lines and icons',
      'colorable': '$effect works on shapes, text, lines and icons',
      'chart': '$effect works on charts only',
      'chart3d': '$effect works on 3D charts only',
      'code': '$effect works on code blocks only',
      'other': '$effect doesn\'t work on this object',
    });
    return '$_temp0';
  }

  @override
  String animateTriggerName(String trigger) {
    String _temp0 = intl.Intl.selectLogic(trigger, {
      'onClick': 'On click',
      'withPrevious': 'With previous',
      'afterPrevious': 'After previous',
      'other': 'On click of an object',
    });
    return '$_temp0';
  }

  @override
  String animateDeliveryName(String by) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'all': 'All at once',
      'paragraph': 'By paragraph',
      'paragraphGroup': 'By paragraph group',
      'line': 'By line',
      'word': 'By word',
      'character': 'By character',
      'series': 'By series',
      'category': 'By category',
      'point': 'By point',
      'chartElement': 'By chart element',
      'other': 'All at once',
    });
    return '$_temp0';
  }

  @override
  String animateOrderName(String order) {
    String _temp0 = intl.Intl.selectLogic(order, {
      'forward': 'Forward',
      'backward': 'Backward',
      'center': 'From the center',
      'edges': 'From the edges',
      'random': 'Random',
      'other': 'Forward',
    });
    return '$_temp0';
  }

  @override
  String animateAfterBuildName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'none': 'Keep',
      'dim': 'Dim',
      'hide': 'Hide',
      'other': 'Keep',
    });
    return '$_temp0';
  }

  @override
  String animateEasingName(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'smooth': 'Smooth',
      'snappy': 'Snappy',
      'bouncy': 'Bouncy',
      'gentle': 'Gentle',
      'linear': 'Linear',
      'easeIn': 'Ease in',
      'easeOut': 'Ease out',
      'custom': 'Custom',
      'other': 'Custom',
    });
    return '$_temp0';
  }

  @override
  String animateGroupName(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'basic': 'Basic',
      'exciting': 'Exciting',
      'emphasis': 'Emphasis',
      'text': 'Text',
      'shape': 'Shape',
      'motion': 'Motion',
      'chart': 'Chart',
      'code': 'Code',
      'threeD': '3D',
      'magic': 'Magic Move',
      'other': 'More',
    });
    return '$_temp0';
  }

  @override
  String animateKindTab(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'buildIn': 'In',
      'action': 'Action',
      'buildOut': 'Out',
      'other': 'In',
    });
    return '$_temp0';
  }

  @override
  String animateUnmatchedName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'together': 'Fade with the move',
      'before': 'Fade out first',
      'after': 'Fade in after',
      'other': 'Fade with the move',
    });
    return '$_temp0';
  }

  @override
  String animatePreviewOption(String option) {
    String _temp0 = intl.Intl.selectLogic(option, {
      'autoPreview': 'Auto-preview changes',
      'includeTransition': 'Include transition in preview',
      'fullMotion': 'Preview full motion',
      'other': 'Option',
    });
    return '$_temp0';
  }

  @override
  String animateWarning(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'elementMissing': 'The object no longer exists.',
      'alreadyVisible': 'The object is already visible: this build is skipped.',
      'alreadyHidden': 'The object is already hidden: this build is skipped.',
      'hiddenTarget':
          'The object is hidden at this point: this build is skipped.',
      'unsupportedEffect':
          'Effect not supported by this version: plays as a fade.',
      'wrongElementKind':
          'This effect doesn\'t work on this object: it is skipped.',
      'unsupportedTrigger':
          'This trigger isn\'t supported yet: the build is skipped.',
      'invalidOptions': 'Some options are invalid and use their defaults.',
      'invalidEasing': 'The easing is invalid and plays as ease out.',
      'deliveryFallback':
          'This object can\'t be built in these parts: it builds as a whole.',
      'codeStepMissing': 'The code has no such highlight step.',
      'codeStateMissing': 'The code has no such state.',
      'flashLimit': 'Blinking is slowed to at most 3 flashes per second.',
      'other': 'This build plays differently than set.',
    });
    return '$_temp0';
  }

  @override
  String get animateAddAnother => 'Add another build';

  @override
  String get animateAdvance => 'Advance';

  @override
  String get animateAdvanceAfter => 'After';

  @override
  String get animateAdvanceAuto => 'Automatically';

  @override
  String get animateAdvanceClick => 'On click';

  @override
  String get animateAfterBuild => 'After build';

  @override
  String get animateAnimatedObjects => 'Animated objects';

  @override
  String get animateAutoBuilds => 'Play builds automatically';

  @override
  String get animateAutoReverse => 'Play back and forth';

  @override
  String get animateBuildDelay => 'Between builds';

  @override
  String get animateDelay => 'Delay';

  @override
  String get animateDelivery => 'Parts';

  @override
  String get animateDeliveryLabel => 'Build';

  @override
  String get animateDimTo => 'Dim to';

  @override
  String get animateDuration => 'Duration';

  @override
  String get animateDurationAutomatic => 'Automatic';

  @override
  String get animateEasing => 'Easing';

  @override
  String get animateEffectUnsupported => 'Effect not supported by this version';

  @override
  String get animateEndState => 'End state';

  @override
  String get animateHeight => 'Height';

  @override
  String get animateHideMatches => 'Hide matches';

  @override
  String get animateMagicMoveFirstSlide =>
      'The first slide has nothing to morph from.';

  @override
  String get animateMagicMoveNoMatches =>
      'No objects match the previous slide: plays as a crossfade.';

  @override
  String get animateMatchByContent => 'Match identical content';

  @override
  String get animateMatchTextBy => 'Match text by';

  @override
  String get animateMissingObject => 'Deleted object';

  @override
  String get animateMoveDown => 'Move down';

  @override
  String get animateMoveUp => 'Move up';

  @override
  String get animateNewClick => 'New click';

  @override
  String get animateNoSlide => 'Animations apply to slides.';

  @override
  String get animateOffSlide => 'From off the slide';

  @override
  String get animateOrderListLabel => 'Build order';

  @override
  String get animateOrderNone =>
      'No animations on this slide yet. Select an object and pick an effect on the Build tab.';

  @override
  String get animatePartOrder => 'Order';

  @override
  String get animatePartStart => 'Each part';

  @override
  String get animatePartsFrom => 'Parts';

  @override
  String get animatePartsTo => 'to';

  @override
  String get animatePathPreset => 'Path';

  @override
  String get animatePlayFromSelected => 'Play from selected';

  @override
  String get animatePreview => 'Preview';

  @override
  String get animatePreviewFromHere => 'Preview from here';

  @override
  String get animatePreviewFullMotion => 'Preview full motion';

  @override
  String get animatePreviewOptions => 'Preview options';

  @override
  String get animatePreviewPlaying => 'Previewing animations';

  @override
  String get animatePreviewReduced => 'Preview reduced motion';

  @override
  String get animatePreviewStop => 'Stop';

  @override
  String get animateReducedMotionOn =>
      'Reduce motion is on — animations play as fades.';

  @override
  String get animateReducedMotionSettings => 'Settings';

  @override
  String get animateRemoveTransition => 'Remove';

  @override
  String get animateRepeat => 'Repeat';

  @override
  String get animateRepeatCount => 'Times';

  @override
  String get animateReturnToStart => 'Return to the start';

  @override
  String get animateReverseOnBack => 'Play backwards when going back';

  @override
  String get animateRotation => 'Rotation';

  @override
  String get animateSearchEffects => 'Search effects';

  @override
  String get animateSelectObject => 'Select an object to animate it.';

  @override
  String get animateSelectObjectItem => 'Select object';

  @override
  String get animateSetTrigger => 'Start';

  @override
  String get animateShowMatches => 'Show matches';

  @override
  String get animateShowParts => 'Show parts';

  @override
  String get animateStagger => 'Stagger';

  @override
  String get animateStaggerParts => 'Stagger';

  @override
  String get animateStart => 'Start';

  @override
  String get animateStepAutomatic => 'Automatic';

  @override
  String get animateTiming => 'Timing';

  @override
  String get animateTransitionInherited =>
      'Uses the presentation\'s default transition.';

  @override
  String get animateUnmatched => 'Unmatched';

  @override
  String get animateUntilNextClick => 'Until the next click';

  @override
  String get animateWidth => 'Width';

  @override
  String get cmdAnimateBuildAllSteps => 'Build all steps';

  @override
  String get cmdAnimateMoveBuilds => 'Reorder animations';

  @override
  String get cmdAnimateSelectBuilds => 'Select animations';

  @override
  String get cmdAnimateSetMotionPath => 'Edit motion path';

  @override
  String get cmdAnimateSetTransformTarget => 'Set end state';

  @override
  String get cmdAnimateSetTrigger => 'Set animation start';

  @override
  String get cmdAnimateStopPreview => 'Stop preview';

  @override
  String get cmdAnimateTogglePreviewOption => 'Preview option';

  @override
  String get cmdAnimateUpdateBuild => 'Edit animation';

  @override
  String get cmdElementSetMatchKey => 'Set Magic Move ID';

  @override
  String get cmdTransitionApplyToAll => 'Apply transition to all slides';

  @override
  String get cmdTransitionPreview => 'Preview transition';

  @override
  String get cmdTransitionRemove => 'Remove transition';

  @override
  String get cmdTransitionSet => 'Set transition';

  @override
  String get cmdTransitionSetAdvance => 'Set slide advance';

  @override
  String get reasonNoBuilds => 'This slide has no animations';

  @override
  String get reasonNoBuildsCopied => 'Copy an animation first';

  @override
  String get reasonNotPreviewing => 'No preview is playing';

  @override
  String get reasonObjectNoBuilds => 'Select one animated object';

  @override
  String get reasonSelectBuild => 'Select an animation';

  @override
  String get reasonSelectCodeOrChart =>
      'Select a code block with steps or a chart';

  @override
  String get undoAddMagicMoveSlide => 'Add Magic Move slide';

  @override
  String get undoRemoveAnimation => 'Remove animation';

  @override
  String animateBadgeTooltip(String name, String steps) {
    return '$name: step $steps';
  }

  @override
  String animateBuildsSelected(int count) {
    return '$count animations';
  }

  @override
  String animateObjectsSelected(int count) {
    return '$count objects';
  }

  @override
  String animateMagicMoveMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects match the previous slide',
      one: '1 object matches the previous slide',
    );
    return '$_temp0';
  }

  @override
  String animateMatchTooltip(String name, int number) {
    return 'Matches “$name” on slide $number';
  }

  @override
  String animateOrderSummary(int clicks, String seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      clicks,
      locale: localeName,
      other: '$clicks clicks',
      one: '1 click',
      zero: 'No clicks',
    );
    return '$_temp0 · $seconds s';
  }

  @override
  String animatePartLabel(int index, String text) {
    return 'Part $index: $text';
  }

  @override
  String animatePartsCount(int count) {
    return '$count parts';
  }

  @override
  String animateSettles(String seconds) {
    return '≈ $seconds s';
  }

  @override
  String animateStepClick(int index) {
    return 'Click $index';
  }

  @override
  String animateTransitionForSlide(int number) {
    return 'Transition into slide $number';
  }

  @override
  String animateTransitionForSlides(int count) {
    return 'Transition into $count slides';
  }

  @override
  String get arrangeLabelMatchKey => 'Magic Move ID';

  @override
  String get cmdOutlineSetTitle => 'Edit slide title';

  @override
  String get cmdOutlineSetBody => 'Edit slide text';

  @override
  String get cmdOutlineNewSlideAfter => 'New slide after this one';

  @override
  String get cmdOutlineNewLine => 'New bullet';

  @override
  String get cmdOutlineFocusBody => 'Go to the slide’s bullets';

  @override
  String get cmdOutlineIndent => 'Indent (demote)';

  @override
  String get cmdOutlineOutdent => 'Outdent (promote)';

  @override
  String get cmdOutlineMoveUp => 'Move up';

  @override
  String get cmdOutlineMoveDown => 'Move down';

  @override
  String get cmdOutlineJoinLine => 'Join with the line above';

  @override
  String get cmdOutlineCopyMarkdown => 'Copy outline as Markdown';

  @override
  String get cmdArrangeSetZ => 'Reorder';

  @override
  String get cmdA11ySetReadingOrder => 'Reading order';

  @override
  String get cmdA11yResetReadingOrder => 'Reset to automatic';

  @override
  String get cmdA11yGoTo => 'Go to issue';

  @override
  String get cmdA11yFix => 'Fix accessibility issue';

  @override
  String get reasonOutlineLine => 'Place the cursor in an outline line';

  @override
  String get reasonOutlineNoTitle => 'This slide’s layout has no title';

  @override
  String get reasonOutlineNoBody => 'This slide has no text placeholder';

  @override
  String get reasonReadingOrderAutomatic =>
      'The reading order is already automatic';

  @override
  String get reasonA11yNoFix => 'This issue has no automatic fix';

  @override
  String get outlineHint =>
      'Enter: new slide or bullet · Tab: indent · Shift+Tab: outdent';

  @override
  String get outlineReadOnlyHint => 'View only';

  @override
  String outlineSlideNumber(int number) {
    return 'Slide $number';
  }

  @override
  String outlineTitleLabel(int number) {
    return 'Title of slide $number';
  }

  @override
  String outlineBulletLabel(int slide, int bullet, int level) {
    return 'Slide $slide, bullet $bullet, level $level';
  }

  @override
  String outlineOthers(String objects) {
    return '+ $objects';
  }

  @override
  String outlineEditing(String name) {
    return '$name is editing';
  }

  @override
  String get outlineCopied => 'Outline copied as Markdown';

  @override
  String get outlineTypingUndo => 'Edit outline';

  @override
  String get layersPanelTitle => 'Layers';

  @override
  String get layersTabLayers => 'Layers';

  @override
  String get layersTabReadingOrder => 'Reading order';

  @override
  String get layersEmpty => 'No objects on this slide';

  @override
  String get layersHidden => 'hidden';

  @override
  String get layersLocked => 'locked';

  @override
  String get layersRenameHint => 'Name';

  @override
  String layersDragMany(int count) {
    return '$count objects';
  }

  @override
  String layersFromLayout(int count) {
    return 'From layout ($count)';
  }

  @override
  String get layersEditLayout => 'Edit layout';

  @override
  String get layersOrderAutomatic =>
      'Automatic: title first, then top to bottom, left to right.';

  @override
  String get layersOrderCustom =>
      'Custom order. Screen readers and Tab follow this list.';

  @override
  String get layersOrderEarlier => 'Read earlier';

  @override
  String get layersOrderLater => 'Read later';

  @override
  String get a11yPanelTitle => 'Accessibility';

  @override
  String get a11yCheckDescription =>
      'Checks alt text, contrast, titles, text size, reading order and tables';

  @override
  String get a11yCheckAgain => 'Check again';

  @override
  String a11ySummary(int errors, int warnings, int info) {
    String _temp0 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors errors',
      one: '1 error',
    );
    String _temp1 = intl.Intl.pluralLogic(
      warnings,
      locale: localeName,
      other: '$warnings warnings',
      one: '1 warning',
    );
    String _temp2 = intl.Intl.pluralLogic(
      info,
      locale: localeName,
      other: '$info tips',
      one: '1 tip',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get a11yNoIssues => 'No accessibility issues found';

  @override
  String get a11yNoIssuesBody =>
      'Alt text, contrast, titles, text size, reading order and tables look good.';

  @override
  String a11ySlideHeading(String label) {
    return 'Slide $label';
  }

  @override
  String get a11ySeverityError => 'Error';

  @override
  String get a11ySeverityWarning => 'Warning';

  @override
  String get a11ySeverityInfo => 'Tip';

  @override
  String get a11yMissingAltText => 'Missing alt text';

  @override
  String a11yLowContrast(String ratio, String required) {
    return 'Low text contrast ($ratio:1, needs $required:1)';
  }

  @override
  String get a11yContrastOverImage =>
      'Text over an image: check that it is readable';

  @override
  String get a11yMissingTitle => 'Slide has no title';

  @override
  String a11yDuplicateTitle(String title) {
    return 'Another slide has the same title “$title”';
  }

  @override
  String a11ySmallText(int size, int min) {
    return 'Text smaller than $min ($size)';
  }

  @override
  String get a11yReadingOrder =>
      'The custom reading order differs from the layout';

  @override
  String get a11yTableHeader => 'Table has no header row';

  @override
  String get a11yEmptyPlaceholder => 'Empty placeholder';

  @override
  String get a11yGoTo => 'Go to';

  @override
  String get a11yFixAltText => 'Add alt text…';

  @override
  String get a11yFixDecorative => 'Mark decorative';

  @override
  String get a11yFixContrast => 'Use a contrasting color';

  @override
  String a11yFixTextSize(int size) {
    return 'Enlarge to $size';
  }

  @override
  String get a11yFixReadingOrder => 'Reset to automatic';

  @override
  String get a11yFixTableHeader => 'Turn on header row';

  @override
  String get a11yFixRemovePlaceholder => 'Remove placeholder';

  @override
  String get a11yEditReadingOrder => 'Edit reading order';

  @override
  String get animatePreviewChanged => 'The animations changed — Preview again';

  @override
  String get chartCheckNow => 'Check now';

  @override
  String get cmdCommentsNext => 'Next comment';

  @override
  String get cmdCommentsPrevious => 'Previous comment';

  @override
  String get cmdCommentsOpenPanel => 'Open comments';

  @override
  String get commentsScopeSlide => 'This slide';

  @override
  String get commentsScopeAll => 'All slides';

  @override
  String get commentsOrphanedGroup => 'Orphaned';

  @override
  String commentsSlideHeader(int number, String title) {
    return '$number · $title';
  }

  @override
  String commentSlideQuote(int number, String title) {
    return 'Slide $number: $title';
  }

  @override
  String get commentAnchorDeleted =>
      'The object this comment was on was deleted';

  @override
  String commentAnchorDeletedQuote(String quote) {
    return '$quote — the object this comment was on was deleted';
  }

  @override
  String commentPinLabel(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments, first by $name',
      one: 'Comment by $name',
    );
    return '$_temp0';
  }

  @override
  String commentReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String commentsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get reasonNoComments => 'No comments';

  @override
  String get commentsDockedClose => 'Close';

  @override
  String get cmdSpellingCheckDescription =>
      'Walk through the misspelled words of the whole presentation';

  @override
  String get cmdSpellingReplace => 'Correct spelling';

  @override
  String get cmdSpellingReplaceAll => 'Correct spelling everywhere';

  @override
  String get cmdSpellingIgnore => 'Ignore';

  @override
  String get cmdSpellingAddToDictionary => 'Add to dictionary';

  @override
  String get cmdSpellingPersonalDictionary => 'Personal dictionary…';

  @override
  String get undoCorrectSpelling => 'Correct spelling';

  @override
  String get undoSetLanguage => 'Set language';

  @override
  String get spellingNoSuggestions => 'No suggestions';

  @override
  String spellingAddWordToDictionary(String word) {
    return 'Add “$word” to dictionary';
  }

  @override
  String toastPersonalDictionaryFull(int max) {
    return 'Your personal dictionary is full ($max words).';
  }

  @override
  String get reasonSpellingTextGone => 'This text is no longer there';

  @override
  String get cmdHistoryRestoreVersion => 'Restore this version';

  @override
  String get cmdHistoryMakeCopy => 'Make a copy';

  @override
  String get cmdHistoryDownload => 'Download as PDF';

  @override
  String get cmdHistoryToggleShowChanges => 'Show changes';

  @override
  String get cmdHistoryToggleShowRemoved => 'Show removed objects';

  @override
  String get cmdHistoryNextChange => 'Next change';

  @override
  String get cmdHistoryPreviousChange => 'Previous change';

  @override
  String get cmdConflictsReview => 'Review overwritten text';

  @override
  String get cmdConflictsRestoreMine => 'Restore my text';

  @override
  String get reasonNoVersionShown => 'Open a version first';

  @override
  String get reasonNoChanges => 'This version has no changes';

  @override
  String get reasonNoConflicts => 'None of your text was overwritten';

  @override
  String get versionLoading => 'Loading this version…';

  @override
  String get versionLoadFailed => 'Couldn’t load this version';

  @override
  String get versionComputingChanges => 'Finding changes…';

  @override
  String get versionChangesHidden => 'Changes are hidden';

  @override
  String get versionNoChanges => 'No changes since the previous version';

  @override
  String versionSlidesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides added',
      one: '1 slide added',
    );
    return '$_temp0';
  }

  @override
  String versionSlidesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides changed',
      one: '1 slide changed',
    );
    return '$_temp0';
  }

  @override
  String versionSlidesMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides moved',
      one: '1 slide moved',
    );
    return '$_temp0';
  }

  @override
  String versionSlidesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides deleted',
      one: '1 slide deleted',
    );
    return '$_temp0';
  }

  @override
  String get versionThemeChanged => 'Theme changed';

  @override
  String get versionDeckChanged => 'Presentation settings changed';

  @override
  String get versionTagNew => 'New';

  @override
  String get versionTagMoved => 'Moved';

  @override
  String get versionTagRenamed => 'Renamed';

  @override
  String get versionTagDeleted => 'Deleted';

  @override
  String versionDeletedSlide(String title) {
    return 'Deleted slide: $title';
  }

  @override
  String get versionChangesOnSlide => 'Changes on this slide';

  @override
  String get versionNoChangesOnSlide => 'Nothing changed on this slide';

  @override
  String versionChangeBy(String what, String who) {
    return '$what — $who';
  }

  @override
  String versionAgentMcp(String name) {
    return 'Claude via MCP ($name)';
  }

  @override
  String versionAgentAi(String name) {
    return 'Claude ($name)';
  }

  @override
  String versionElementChange(String element, String what) {
    return '$element: $what';
  }

  @override
  String versionElementAdded(String element) {
    return '$element added';
  }

  @override
  String versionElementRemoved(String element) {
    return '$element deleted';
  }

  @override
  String get versionKindText => 'text edited';

  @override
  String get versionKindFrame => 'moved or resized';

  @override
  String get versionKindStyle => 'restyled';

  @override
  String get versionKindData => 'content changed';

  @override
  String get versionKindOrder => 'order changed';

  @override
  String get versionKindVisibility => 'shown, hidden or locked';

  @override
  String get versionKindAnimation => 'animation changed';

  @override
  String get versionSlideAdded => 'Slide added';

  @override
  String get versionSlideMoved => 'Slide moved';

  @override
  String get versionSlideSkipToggled => 'Slide skipped or unskipped';

  @override
  String get versionSlideDeleted => 'Slide deleted';

  @override
  String get versionSlideBackground => 'Background changed';

  @override
  String get versionSlideLayout => 'Layout changed';

  @override
  String get versionSlideTransition => 'Transition changed';

  @override
  String get versionSlideNotes => 'Speaker notes edited';

  @override
  String get versionSlideTimings => 'Timings changed';

  @override
  String get versionSlideMasters => 'Master objects shown or hidden';

  @override
  String versionAnimations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animations changed',
      one: '1 animation changed',
    );
    return '$_temp0';
  }

  @override
  String versionGroupAdded(String title) {
    return 'Section “$title” added';
  }

  @override
  String versionGroupRemoved(String title) {
    return 'Section “$title” deleted';
  }

  @override
  String versionGroupChanged(String title) {
    return 'Section “$title” changed';
  }

  @override
  String versionChangeCounter(int index, int count) {
    return '$index of $count';
  }

  @override
  String get versionCopyTitle => 'Copy this version';

  @override
  String get versionCopyNameLabel => 'Name';

  @override
  String versionCopyName(String title) {
    return 'Copy of $title';
  }

  @override
  String get versionCopyNameRequired => 'Enter a name';

  @override
  String get versionCopyComments => 'Copy comments';

  @override
  String get versionCopySharing => 'Share with the same people';

  @override
  String get versionOpenCopy => 'Open';

  @override
  String toastVersionCopied(String name) {
    return 'Created “$name”';
  }

  @override
  String get toastVersionCopyFailed => 'Couldn’t copy this version';

  @override
  String get toastVersionDownloadFailed => 'Couldn’t download this version';

  @override
  String get conflictsTitle => 'Your text was replaced';

  @override
  String get conflictsDescription =>
      'Newer edits from collaborators replaced text you edited while offline. Choose the texts to put back.';

  @override
  String conflictsRow(String where, String mine, String theirs, String who) {
    return '$where — yours: $mine · now: $theirs ($who)';
  }

  @override
  String conflictsDeletedBy(String where, String who, String mine) {
    return '$where was deleted by $who · yours: $mine';
  }

  @override
  String conflictsSlideTarget(int number, String element) {
    return 'Slide $number, $element';
  }

  @override
  String conflictsNotesTarget(int number) {
    return 'Slide $number, speaker notes';
  }

  @override
  String conflictsCellTarget(int number) {
    return 'Slide $number, table cell';
  }

  @override
  String get conflictsGoneTarget => 'A deleted slide';

  @override
  String get conflictsEmptyValue => '(empty)';

  @override
  String get conflictsRestoreMine => 'Restore';

  @override
  String get conflictsCopyMine => 'Copy';

  @override
  String get conflictsDismissAll => 'Dismiss all';

  @override
  String get conflictsReview => 'Review';

  @override
  String get conflictsSeveralPeople => 'several people';

  @override
  String toastConflicts(int count, String who) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of your text edits were',
      one: '1 of your text edits was',
    );
    return '$_temp0 replaced by newer edits from $who';
  }

  @override
  String get toastConflictsCopied => 'Copied your text';

  @override
  String toastVersionRestoredBy(String name) {
    return '$name restored a previous version';
  }

  @override
  String get cmdLineSetWaypoints => 'Edit connector route';

  @override
  String get aiPanelTitle => 'Assistant';

  @override
  String get aiAssistantEmptyTitle =>
      'Ask about this presentation, or ask for changes';

  @override
  String get aiAssistantPrivacyNotice =>
      'Your messages and this presentation\'s content are sent to an AI provider.';

  @override
  String aiAssistantPrivacyNoticeProvider(String provider) {
    return 'Your messages and this presentation\'s content are sent to $provider.';
  }

  @override
  String get aiAssistantModeEditHint =>
      'Changes go straight into the presentation';

  @override
  String get aiAssistantModeEditUnavailable =>
      'You can only suggest changes in this presentation';

  @override
  String get aiAssistantModeSuggestHint =>
      'Changes are previewed before anything is applied';

  @override
  String get aiUnavailable => 'AI isn\'t available';

  @override
  String get aiTurnedOff => 'AI is turned off';

  @override
  String get aiTurnOnHint => 'Turn it on in Settings › AI.';

  @override
  String aiChipSlide(int position) {
    return 'Slide $position';
  }

  @override
  String aiChipObjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected objects',
      one: '1 selected object',
    );
    return '$_temp0';
  }

  @override
  String get aiQuickImproveSlide => 'Improve slide';

  @override
  String get aiQuickNotes => 'Speaker notes';

  @override
  String get aiQuickSummarize => 'Summarize deck';

  @override
  String get aiQuickAgenda => 'Add agenda';

  @override
  String get aiQuickConsistency => 'Check wording';

  @override
  String get aiQuickNewDeck => 'Generate a presentation…';

  @override
  String aiUndoLabel(String summary) {
    return 'AI: $summary';
  }

  @override
  String get aiUndoDefault => 'Assistant changes';

  @override
  String get aiFailed => 'The AI request failed';

  @override
  String get aiPreviewReview => 'Review changes';

  @override
  String get aiPreviewAppliedNote => 'Suggested changes applied';

  @override
  String get aiPreviewDiscardedNote => 'Suggested changes discarded';

  @override
  String get aiPreviewTitle => 'Suggested changes';

  @override
  String get aiPreviewDescription =>
      'Choose the changes to apply. Nothing changes until you apply them.';

  @override
  String get aiPreviewApply => 'Apply selected';

  @override
  String get aiPreviewDiscard => 'Discard';

  @override
  String get aiPreviewBefore => 'Before';

  @override
  String get aiPreviewAfter => 'After';

  @override
  String get aiPreviewNewSlide => 'New slide';

  @override
  String get aiPreviewDeletedSlide => 'Deleted';

  @override
  String aiPreviewSlide(int position) {
    return 'Slide $position';
  }

  @override
  String get aiPreviewNoSlides =>
      'These changes don\'t change a slide\'s look.';

  @override
  String aiPreviewSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count values someone changed meanwhile were kept',
      one: '1 value someone changed meanwhile was kept',
    );
    return '$_temp0';
  }

  @override
  String get aiPreviewApplyAll => 'Apply suggested changes';

  @override
  String get aiGenerateTitle => 'Generate presentation';

  @override
  String get aiGenerateSource => 'Source';

  @override
  String get aiGenerateSourcePrompt => 'Prompt';

  @override
  String get aiGenerateSourceOutline => 'Outline';

  @override
  String get aiGeneratePromptLabel => 'What is the presentation about?';

  @override
  String get aiGeneratePromptHint =>
      'Quarterly review of the Serverpod Cloud launch for the board…';

  @override
  String get aiGenerateOutlineLabel => 'Your outline';

  @override
  String get aiGenerateOutlineHint =>
      'Paste bullets or Markdown with one heading per slide';

  @override
  String get aiGenerateSlides => 'Slides';

  @override
  String get aiGenerateSlidesAuto => 'Auto';

  @override
  String get aiGenerateAudience => 'Audience';

  @override
  String get aiGenerateTone => 'Tone';

  @override
  String get aiGenerateLanguage => 'Language';

  @override
  String get aiGenerateLanguageAuto => 'Same as the text';

  @override
  String get aiGenerateNotes => 'Speaker notes';

  @override
  String get aiGenerateGroups => 'Group into sections';

  @override
  String get aiGenerateKeepWording => 'Keep my wording';

  @override
  String get aiGenerateInsert => 'Insert';

  @override
  String get aiGenerateInsertNew => 'New presentation';

  @override
  String aiGenerateInsertAfter(int position) {
    return 'After slide $position';
  }

  @override
  String get aiGenerateInsertEnd => 'At the end';

  @override
  String get aiGenerateCreateOutline => 'Create outline';

  @override
  String get aiGeneratePlanning => 'Planning the outline…';

  @override
  String get aiGenerateOutlineTitle => 'Review the outline';

  @override
  String get aiGenerateOutlineDescription =>
      'Edit titles and roles, reorder or delete slides, then create them.';

  @override
  String get aiGenerateBuild => 'Create slides';

  @override
  String get aiGenerateBack => 'Back';

  @override
  String get aiGenerateRegenerate => 'Regenerate';

  @override
  String get aiGenerateRegenerateSlide => 'Regenerate this slide';

  @override
  String get aiGenerateRegenerateHint => 'What should change? (optional)';

  @override
  String get aiGenerateAddSlide => 'Add slide';

  @override
  String get aiGenerateDeleteSlide => 'Delete slide';

  @override
  String get aiGenerateMoveUp => 'Move up';

  @override
  String get aiGenerateMoveDown => 'Move down';

  @override
  String get aiGenerateSlideTitle => 'Slide title';

  @override
  String get aiGenerateBullets => 'Bullets (one per line)';

  @override
  String aiGenerateSlideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateRole => 'Role';

  @override
  String get aiGenerateBuilding => 'Creating slides…';

  @override
  String get aiGenerateUndo => 'Generate slides';

  @override
  String get aiGenerateNewSlide => 'New slide';

  @override
  String get aiGenerateEmpty => 'Describe the presentation first.';

  @override
  String aiGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count slides',
      one: 'Added 1 slide',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateCreated => 'Presentation created';

  @override
  String get aiRoleTitle => 'Title';

  @override
  String get aiRoleSection => 'Section';

  @override
  String get aiRoleAgenda => 'Agenda';

  @override
  String get aiRoleBullets => 'Bullets';

  @override
  String get aiRoleTwoColumn => 'Two columns';

  @override
  String get aiRoleQuote => 'Quote';

  @override
  String get aiRoleBigNumber => 'Big number';

  @override
  String get aiRoleImageText => 'Image and text';

  @override
  String get aiRoleCode => 'Code';

  @override
  String get aiRoleChartPlaceholder => 'Chart';

  @override
  String get aiRoleClosing => 'Closing';

  @override
  String get aiAudienceGeneral => 'General';

  @override
  String get aiAudienceBoard => 'Board';

  @override
  String get aiAudienceTeam => 'Team';

  @override
  String get aiAudienceCustomers => 'Customers';

  @override
  String get aiAudienceStudents => 'Students';

  @override
  String get aiAudienceDevelopers => 'Developers';

  @override
  String get aiToneProfessional => 'Professional';

  @override
  String get aiToneFriendly => 'Friendly';

  @override
  String get aiToneInspiring => 'Inspiring';

  @override
  String get aiToneTechnical => 'Technical';

  @override
  String get aiToneConcise => 'Concise';

  @override
  String get aiRewriteTitle => 'Rewrite text';

  @override
  String get aiRewriteWorking => 'Writing…';

  @override
  String get aiRewriteReplace => 'Replace';

  @override
  String get aiRewriteTryAgain => 'Try again';

  @override
  String get aiRewriteDiscard => 'Discard';

  @override
  String get aiRewriteRefineHint => 'Refine, e.g. even shorter';

  @override
  String get aiRewriteRefine => 'Refine';

  @override
  String get aiRewriteOriginal => 'Original';

  @override
  String get aiRewriteResult => 'Suggestion';

  @override
  String get aiRewriteChanged =>
      'The text changed meanwhile. Copy the suggestion or try again.';

  @override
  String get aiRewriteCopy => 'Copy';

  @override
  String get aiRewriteCopied => 'Copied';

  @override
  String get aiRewriteCustomLabel => 'How should the text change?';

  @override
  String get aiRewriteCustomHint => 'Make it sound more confident';

  @override
  String get aiRewriteUndo => 'Rewrite text';

  @override
  String get aiRewriteNoText => 'Select a text box with text';

  @override
  String get rewritePunchier => 'Punchier';

  @override
  String get rewriteBullets => 'Make bullets';

  @override
  String get rewriteParagraph => 'Make a paragraph';

  @override
  String get aiNotesTitle => 'Write speaker notes';

  @override
  String get aiNotesScope => 'Slides';

  @override
  String get aiNotesScopeCurrent => 'Current slide';

  @override
  String get aiNotesScopeSelected => 'Selected slides';

  @override
  String get aiNotesScopeAll => 'All slides';

  @override
  String get aiNotesLength => 'Length';

  @override
  String get aiNotesLengthBrief => 'Brief';

  @override
  String get aiNotesLengthStandard => 'Standard';

  @override
  String get aiNotesLengthDetailed => 'Detailed';

  @override
  String get aiNotesStyle => 'Style';

  @override
  String get aiNotesStyleScript => 'Script';

  @override
  String get aiNotesStyleBullets => 'Bullet points';

  @override
  String get aiNotesMode => 'Existing notes';

  @override
  String get aiNotesModeFillEmpty => 'Only write empty notes';

  @override
  String get aiNotesModeAppend => 'Add to them';

  @override
  String get aiNotesModeReplace => 'Replace them';

  @override
  String get aiNotesGenerate => 'Write notes';

  @override
  String get aiNotesWorking => 'Writing notes…';

  @override
  String get aiNotesReviewTitle => 'Review speaker notes';

  @override
  String get aiNotesApply => 'Apply';

  @override
  String get aiNotesNone => 'No slide needs notes.';

  @override
  String get aiNotesExisting => 'Current notes';

  @override
  String get aiNotesUndo => 'Write speaker notes';

  @override
  String get aiAltTitle => 'Generate alt text';

  @override
  String get aiAltWorking => 'Describing objects…';

  @override
  String get aiAltApply => 'Apply';

  @override
  String get aiAltNone => 'Nothing needs alt text.';

  @override
  String get aiAltSkippedUnsupported =>
      'This kind of object can\'t be described.';

  @override
  String get aiAltSkippedEmpty => 'No description was proposed.';

  @override
  String get aiAltUndo => 'Generate alt text';

  @override
  String aiAltObject(String kind, int position) {
    return '$kind on slide $position';
  }

  @override
  String get a11yGenerateAlt => 'Generate with AI';

  @override
  String get a11yGenerateMissingAlt => 'Generate missing alt text';

  @override
  String get aiDesignTitle => 'Design ideas';

  @override
  String get aiDesignEmpty => 'No ideas for this slide — add some content';

  @override
  String get aiDesignNoSlide => 'Select a slide to see design ideas';

  @override
  String get aiDesignRefresh => 'Refresh';

  @override
  String get aiDesignMore => 'More ideas';

  @override
  String get aiDesignRanking => 'Ranking with AI…';

  @override
  String get aiDesignLayoutIdeas => 'Layout ideas for this slide';

  @override
  String get aiDesignAiRanked => 'Ranked by AI for this slide';

  @override
  String get aiDesignUndo => 'Apply design idea';

  @override
  String aiDesignApply(String name) {
    return 'Apply $name';
  }

  @override
  String get cmdAiApplyDesignIdea => 'Apply design idea';

  @override
  String get cmdPanelDesignIdeas => 'Design ideas';

  @override
  String get cmdAiApplyPreview => 'Apply suggested changes';

  @override
  String get cmdAiDiscardPreview => 'Discard suggested changes';

  @override
  String get cmdAiSetApplyMode => 'Assistant: edit or suggest';

  @override
  String get reasonAiUnavailable => 'AI isn\'t available';

  @override
  String get reasonNoTextToRewrite => 'Select a text box with text';

  @override
  String get reasonNoPreview => 'No suggested changes to review';

  @override
  String presenceEditingLayout(String name) {
    return 'Editing layout · $name';
  }

  @override
  String get followWatchPresentation => 'Watch presentation';

  @override
  String presenterLive(String name) {
    return '$name is presenting';
  }

  @override
  String presentMenuFollow(String name) {
    return 'Follow $name\'s presentation';
  }

  @override
  String followerFollowing(String name) {
    return 'Following $name — press Esc to stop';
  }

  @override
  String get followerFollowingUnknown =>
      'Following the presenter — press Esc to stop';

  @override
  String followerBrowsing(String name) {
    return 'You left $name\'s slide';
  }

  @override
  String get followerBrowsingUnknown => 'You left the presenter\'s slide';

  @override
  String get followerReturn => 'Return to presenter';

  @override
  String get followerFullscreen => 'Full screen';

  @override
  String get followerStop => 'Stop following';

  @override
  String get cmdPresenceReturnToPresenter => 'Return to presenter';

  @override
  String pointerOnSlide(String name) {
    return '$name\'s pointer';
  }

  @override
  String get errorObjectLocked => 'This object is locked.';

  @override
  String get errorTooManyGuides => 'There are too many guides';

  @override
  String get errorSelectTextBox => 'Select a text box';

  @override
  String get errorCopyFailed => 'The copy couldn’t be made';

  @override
  String get errorNothingToRestore => 'Nothing to restore';

  @override
  String get errorCropRemovesImage => 'The crop removes the whole image';

  @override
  String get errorSelectSlide => 'Select at least one slide';

  @override
  String get errorClipboardNoSlides => 'The clipboard holds no slides';

  @override
  String get errorNothingToMove => 'Nothing to move there';

  @override
  String get errorOneEmoji => 'One emoji is expected';

  @override
  String get errorTextChanged => 'The text has changed';

  @override
  String get errorOneWord => 'One word is expected';

  @override
  String get errorNoSlidesSelected => 'No slides selected';

  @override
  String get errorNothingToFix => 'Nothing to fix';

  @override
  String get errorNothingToPaste => 'Nothing to paste';

  @override
  String get errorLineNotOnSlide => 'The line is not on the current slide';

  @override
  String get errorRouteHandlesInGroups =>
      'Route handles are not available inside groups';

  @override
  String get errorStraightLineWaypoints => 'Straight lines have no waypoints';
}

/// The translations for English (`en_XA`).
class SlidesLocalizationsEnXa extends SlidesLocalizationsEn {
  SlidesLocalizationsEnXa() : super('en_XA');

  @override
  String get untitledPresentation => '[Ûñţîţļéð þŕéšéñţåţîöñ one two]';

  @override
  String get editorComingSoonTitle => '[Çöɱîñĝ šööñ one]';

  @override
  String get editorComingSoonBody =>
      '[Ŵöñķý Šļîðéš îš ƀéîñĝ ƀûîļţ. Ţĥé þŕéšéñţåţîöñ éðîţöŕ îš öñ îţš ŵåý — ýöûŕ þŕéšéñţåţîöñš šţåý šåƒé îñ Ŵöñķý Ðŕîṽé ɱéåñŵĥîļé. one two three four five six seven eig]';

  @override
  String get backToSlides => '[Ɓåçķ ţö Šļîðéš one t]';

  @override
  String get deckDownloading => '[Ðöŵñļöåðîñĝ þŕéšéñţåţîöñ… one two t]';

  @override
  String deckOpening(int rows) {
    return '[Öþéñîñĝ þŕéšéñţåţîöñ… ($rows ŕöŵš) one two th]';
  }

  @override
  String get deckNotAvailableOffline =>
      '[Ţĥîš þŕéšéñţåţîöñ îšñ’ţ åṽåîļåƀļé öƒƒļîñé. one two three]';

  @override
  String get deckNoAccess =>
      '[Ýöû ðöñ’ţ ĥåṽé åççéšš ţö ţĥîš þŕéšéñţåţîöñ. one two three]';

  @override
  String get deckDownloadFailed =>
      '[Ţĥîš þŕéšéñţåţîöñ çöûļð ñöţ ƀé ðöŵñļöåðéð. one two three]';

  @override
  String get deckOpenFailed =>
      '[Ţĥîš þŕéšéñţåţîöñ çöûļð ñöţ ƀé öþéñéð. one two thre]';

  @override
  String get deckNotOnDevice =>
      '[Ţĥîš þŕéšéñţåţîöñ îšñ’ţ öñ ţĥîš ðéṽîçé. one two thre]';

  @override
  String get deckAccessRemoved =>
      '[Ýöû ñö ļöñĝéŕ ĥåṽé åççéšš ţö ţĥîš þŕéšéñţåţîöñ. one two three]';

  @override
  String get deckStillOpening =>
      '[Ţĥé þŕéšéñţåţîöñ îš šţîļļ öþéñîñĝ. one two thr]';

  @override
  String get screenStorageUnavailable =>
      '[Ţĥé þŕéšéñţåţîöñ šţöŕåĝé öñ ţĥîš ðéṽîçé ðîðñ\'ţ šţåŕţ. Ţŕý åĝåîñ, öŕ ŕéļöåð ţĥé þåĝé. one two three four five s]';

  @override
  String get createNeedsConnectionTitle =>
      '[Çöññéçţ ţö ţĥé îñţéŕñéţ ţö çŕéåţé å þŕéšéñţåţîöñ one two three f]';

  @override
  String get createNeedsConnectionBody =>
      '[Ţĥîš ðéṽîçé çåñ çŕéåţé þŕéšéñţåţîöñš öƒƒļîñé öñçé îţ ĥåš ƀééñ öñļîñé ƒöŕ å ɱöɱéñţ. one two three four five s]';

  @override
  String get storageLimitedTitle =>
      '[Öƒƒļîñé šţöŕåĝé îš ļîɱîţéð îñ ţĥîš ƀŕöŵšéŕ one two three]';

  @override
  String storageLimitedDescription(String elements) {
    return '[Ţĥîš ƀŕöŵšéŕ ķééþš öƒƒļîñé þŕéšéñţåţîöñš îñ ɱéɱöŕý. Öñļý åƀöûţ $elements öƀĵéçţš šţåý åṽåîļåƀļé öƒƒļîñé; ţĥé þŕéšéñţåţîöñš ýöû öþéñéð ļéåšţ ŕéçéñţļý åŕé ŕéɱöṽéð ƒŕöɱ ţĥîš ðéṽîçé ƒîŕšţ. one two three four five six seven eight nine ten one]';
  }

  @override
  String get recoveryTitle =>
      '[Ýöûŕ öƒƒļîñé þŕéšéñţåţîöñ ðåţå çöûļðñ\'ţ ƀé öþéñéð one two three fo]';

  @override
  String recoveryDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count þŕéšéñţåţîöñš ĥåð çĥåñĝéš ţĥåţ ŵéŕéñ\'ţ šýñçéð ýéţ. Ðöŵñļöåð ţĥéɱ ƀéƒöŕé ţĥéý\'ŕé ļöšţ.',
      one:
          '1 þŕéšéñţåţîöñ ĥåð çĥåñĝéš ţĥåţ ŵéŕéñ\'ţ šýñçéð ýéţ. Ðöŵñļöåð ţĥéɱ ƀéƒöŕé ţĥéý\'ŕé ļöšţ.',
    );
    return '[$_temp0 one two three four five six seven eight nine ten one]';
  }

  @override
  String get recoveryDownload => '[Ðöŵñļöåð ûñšýñçéð çĥåñĝéš one two t]';

  @override
  String get recoveryFailed =>
      '[Ţĥé ûñšýñçéð çĥåñĝéš çöûļð ñöţ ƀé éẋþöŕţéð one two three]';

  @override
  String get cmdFileImportSlides => '[Îɱþöŕţ šļîðéš… one t]';

  @override
  String get cmdFileDownload => '[Ðöŵñļöåð one]';

  @override
  String get cmdHistoryNameCurrentVersion => '[Ñåɱé çûŕŕéñţ ṽéŕšîöñ one two]';

  @override
  String get cmdHistoryOpen => '[Šéé ṽéŕšîöñ ĥîšţöŕý one tw]';

  @override
  String get cmdFileSetLanguage => '[Ļåñĝûåĝé one]';

  @override
  String get cmdFilePageSetup => '[Þåĝé šéţûþ… one]';

  @override
  String get cmdPrintOpen => '[Þŕîñţ on]';

  @override
  String get cmdEditPasteSpecial => '[Þåšţé šþéçîåļ one t]';

  @override
  String get cmdEditDuplicate => '[Ðûþļîçåţé one]';

  @override
  String get cmdEditDelete => '[Ðéļéţé one]';

  @override
  String get cmdSelectEscape => '[Šéļéçţ ñöñé one]';

  @override
  String get cmdSelectEnterGroup => '[Éñţéŕ ĝŕöûþ one]';

  @override
  String get cmdElementActivate => '[Éðîţ ţéẋţ one]';

  @override
  String get cmdFindOpen => '[Ƒîñð on]';

  @override
  String get cmdFindOpenReplace => '[Ƒîñð åñð ŕéþļåçé one t]';

  @override
  String get cmdFormatCopyStyle => '[Çöþý šţýļé one]';

  @override
  String get cmdFormatPasteStyle => '[Þåšţé šţýļé one]';

  @override
  String get cmdPresentFromCurrent => '[Þŕéšéñţ ƒŕöɱ çûŕŕéñţ šļîðé one two t]';

  @override
  String get cmdPresentFromStart => '[Þŕéšéñţ ƒŕöɱ ƀéĝîññîñĝ one two]';

  @override
  String get cmdPresentPresenterView => '[Þŕéšéñţéŕ ṽîéŵ one t]';

  @override
  String get cmdPresentRehearse => '[Ŕéĥéåŕšé one]';

  @override
  String get cmdPresentOpenOnAnotherDevice =>
      '[Öþéñ öñ åñöţĥéŕ ðéṽîçé… one two]';

  @override
  String get cmdPresentRemote => '[Ûšé þĥöñé åš ŕéɱöţé one tw]';

  @override
  String get cmdPresentFromSlide => '[Þŕéšéñţ ƒŕöɱ ţĥîš šļîðé one two]';

  @override
  String get cmdViewSetMode => '[Ṽîéŵ ɱöðé one]';

  @override
  String get cmdViewToggleNavigator => '[Ñåṽîĝåţöŕ one]';

  @override
  String get cmdViewToggleInspector => '[Îñšþéçţöŕ one]';

  @override
  String get cmdViewToggleNotes => '[Šþéåķéŕ ñöţéš one t]';

  @override
  String get cmdViewToggleRulers => '[Ŕûļéŕš one]';

  @override
  String get cmdViewToggleGuides => '[Ĝûîðéš one]';

  @override
  String get cmdViewToggleCommentPins => '[Çöɱɱéñţš öñ çåñṽåš one tw]';

  @override
  String get cmdViewToggleRemoteCursors => '[Çöļļåƀöŕåţöŕ çûŕšöŕš one two]';

  @override
  String get cmdPresenceJumpTo => '[Ĵûɱþ ţö çöļļåƀöŕåţöŕ one two]';

  @override
  String get cmdPresenceFollow => '[Ƒöļļöŵ one]';

  @override
  String get cmdPresenceUnfollow => '[Šţöþ ƒöļļöŵîñĝ one t]';

  @override
  String get cmdPresenceFollowPresenter => '[Ƒöļļöŵ þŕéšéñţéŕ one tw]';

  @override
  String get cmdTextEditAnyway => '[Éðîţ åñýŵåý one]';

  @override
  String actorViaMcp(String name) {
    return '[Çļåûðé ṽîå ṀÇÞ ($name) one t]';
  }

  @override
  String actorViaAi(String name) {
    return '[Åššîšţåñţ ($name) one]';
  }

  @override
  String presenceEditingSlide(int number, String title) {
    return '[Éðîţîñĝ šļîðé $number · $title one t]';
  }

  @override
  String presenceViewingSlide(int number, String title) {
    return '[Ṽîéŵîñĝ šļîðé $number · $title one t]';
  }

  @override
  String get presencePresenting => '[Þŕéšéñţîñĝ one]';

  @override
  String get presenceEditingLayouts => '[Éðîţîñĝ ļåýöûţš one t]';

  @override
  String get presenceFollowingYou => '[Ƒöļļöŵîñĝ ýöû one t]';

  @override
  String presenceOnSlide(String names) {
    return '[Öñ ţĥîš šļîðé: $names one t]';
  }

  @override
  String presenceInGroup(String names) {
    return '[Îñ ţĥîš ĝŕöûþ: $names one t]';
  }

  @override
  String presenceEditingFlag(String name) {
    return '[✎ $name îš éðîţîñĝ one]';
  }

  @override
  String presenceEditingFlagMany(String names) {
    return '[✎ $names éðîţîñĝ one]';
  }

  @override
  String presenceEditingHover(String name) {
    return '[$name îš éðîţîñĝ ţĥîš ţéẋţ — ðöûƀļé-çļîçķ ţö éðîţ åñýŵåý one two three f]';
  }

  @override
  String softLockMessage(String name) {
    return '[$name îš éðîţîñĝ ţĥîš ţéẋţ. one two]';
  }

  @override
  String softLockNotesMessage(String name) {
    return '[$name îš éðîţîñĝ ţĥéšé ñöţéš. one two]';
  }

  @override
  String softLockRaceMessage(String name) {
    return '[$name šţåŕţéð éðîţîñĝ ţĥîš ţéẋţ ƒîŕšţ. one two th]';
  }

  @override
  String get softLockCancel => '[Çåñçéļ one]';

  @override
  String get softLockEditAnyway => '[Éðîţ åñýŵåý one]';

  @override
  String get softLockStop => '[Šţöþ éðîţîñĝ one]';

  @override
  String get softLockKeep => '[Ķééþ éðîţîñĝ one]';

  @override
  String notesEditingBanner(String name) {
    return '[✎ $name îš éðîţîñĝ ţĥé ñöţéš one two]';
  }

  @override
  String followBanner(String name) {
    return '[Ƒöļļöŵîñĝ $name one]';
  }

  @override
  String get followStop => '[Šţöþ on]';

  @override
  String presenterPill(String name) {
    return '[$name îš þŕéšéñţîñĝ one t]';
  }

  @override
  String get presenterFollow => '[Ƒöļļöŵ one]';

  @override
  String get toastPresenterNotFound =>
      '[Ţĥåţ þŕéšéñţåţîöñ ĥåš éñðéð. one two t]';

  @override
  String get cmdViewToggleSmartGuides => '[Šɱåŕţ ĝûîðéš one]';

  @override
  String get cmdViewToggleSnapObjects => '[Šñåþ ţö öƀĵéçţš one t]';

  @override
  String get cmdViewToggleSnapGuides => '[Šñåþ ţö ĝûîðéš one t]';

  @override
  String get cmdViewToggleSnapGrid => '[Šñåþ ţö ĝŕîð one]';

  @override
  String get cmdAnimateToggleOrderOverlay => '[Ɓûîļð öŕðéŕ one]';

  @override
  String get cmdMagicMoveToggleMatches => '[Ṁåĝîç Ṁöṽé ɱåţçĥéš one tw]';

  @override
  String get cmdGuidesAdd => '[Åðð ĝûîðé one]';

  @override
  String get cmdGuidesClear => '[Çļéåŕ ĝûîðéš one]';

  @override
  String get cmdViewZoomFit => '[Ƒîţ on]';

  @override
  String get cmdViewZoom => '[Žööɱ on]';

  @override
  String get cmdViewZoomIn => '[Žööɱ îñ one]';

  @override
  String get cmdViewZoomOut => '[Žööɱ öûţ one]';

  @override
  String get cmdViewZoomToSelection => '[Žööɱ ţö šéļéçţîöñ one tw]';

  @override
  String get cmdPanelAnimate => '[Åñîɱåţé one]';

  @override
  String get cmdPanelThemes => '[Ţĥéɱéš one]';

  @override
  String get cmdPanelLayers => '[Ļåýéŕš one]';

  @override
  String get cmdPanelAccessibility => '[Åççéššîƀîļîţý one t]';

  @override
  String get cmdPanelLinkedObjects => '[Ļîñķéð çĥåŕţš one t]';

  @override
  String get cmdModeEditing => '[Éðîţîñĝ one]';

  @override
  String get cmdModeViewing => '[Ṽîéŵîñĝ one]';

  @override
  String get cmdInspectorOpen => '[Ƒöŕɱåţ öþţîöñš… one t]';

  @override
  String get cmdSlideNew => '[Ñéŵ šļîðé one]';

  @override
  String get cmdSlideDuplicateForMagicMove => '[Ṁåĝîç Ṁöṽé šļîðé one t]';

  @override
  String get cmdInsertTextBox => '[Ţéẋţ ƀöẋ one]';

  @override
  String get cmdInsertImage => '[Îɱåĝé on]';

  @override
  String get cmdInsertShape => '[Šĥåþé on]';

  @override
  String get cmdInsertLine => '[Ļîñé on]';

  @override
  String get cmdInsertTable => '[Ţåƀļé on]';

  @override
  String get cmdInsertCode => '[Çöðé ƀļöçķ one]';

  @override
  String get cmdInsertChartFromSheets => '[Çĥåŕţ ƒŕöɱ Ŵöñķý Šĥééţš… one two]';

  @override
  String get cmdInsertChart => '[Çĥåŕţ on]';

  @override
  String get cmdInsertIcon => '[Îçöñ… on]';

  @override
  String get cmdInsertEmoji => '[Éɱöĵî… one]';

  @override
  String get cmdInsertSpecialCharacter => '[Šþéçîåļ çĥåŕåçţéŕš… one two]';

  @override
  String get cmdInsertLink => '[Ļîñķ on]';

  @override
  String get cmdDeckOpenNumbering => '[Šļîðé ñûɱƀéŕš… one t]';

  @override
  String get cmdLayoutInsertPlaceholder => '[Þļåçéĥöļðéŕ one]';

  @override
  String get cmdFormatBold => '[Ɓöļð on]';

  @override
  String get cmdFormatItalic => '[Îţåļîç one]';

  @override
  String get cmdFormatUnderline => '[Ûñðéŕļîñé one]';

  @override
  String get cmdFormatStrikethrough => '[Šţŕîķéţĥŕöûĝĥ one t]';

  @override
  String get cmdFormatScript => '[Šûþéŕšçŕîþţ / šûƀšçŕîþţ one two]';

  @override
  String get cmdFormatIncreaseFontSize => '[Îñçŕéåšé ƒöñţ šîžé one tw]';

  @override
  String get cmdFormatDecreaseFontSize => '[Ðéçŕéåšé ƒöñţ šîžé one tw]';

  @override
  String get cmdFormatCaps => '[Çåþîţåļîžåţîöñ one t]';

  @override
  String get cmdFormatTextStyle => '[Ţéẋţ šţýļé one]';

  @override
  String get cmdFormatFont => '[Ƒöñţ on]';

  @override
  String get cmdFormatFontSize => '[Ƒöñţ šîžé one]';

  @override
  String get cmdFormatTextColor => '[Ţéẋţ çöļöŕ one]';

  @override
  String get cmdFormatHighlight => '[Ĥîĝĥļîĝĥţ çöļöŕ one t]';

  @override
  String get cmdFormatAlign => '[Ţéẋţ åļîĝñɱéñţ one t]';

  @override
  String get cmdFormatAnchor => '[Ṽéŕţîçåļ åļîĝñɱéñţ one tw]';

  @override
  String get cmdFormatIndent => '[Îñçŕéåšé îñðéñţ one t]';

  @override
  String get cmdFormatOutdent => '[Ðéçŕéåšé îñðéñţ one t]';

  @override
  String get cmdFormatLineHeight => '[Ļîñé šþåçîñĝ one]';

  @override
  String get cmdFormatParagraphSpacing => '[Þåŕåĝŕåþĥ šþåçîñĝ… one tw]';

  @override
  String get cmdFormatList => '[Ļîšţš on]';

  @override
  String get cmdFormatListStyle => '[Ļîšţ šţýļé one]';

  @override
  String get cmdFormatListStart => '[Ŕéšţåŕţ ñûɱƀéŕîñĝ one tw]';

  @override
  String get cmdFormatAutofit => '[Ţéẋţ ƒîţţîñĝ one]';

  @override
  String get cmdFormatFill => '[Ƒîļļ on]';

  @override
  String get cmdFormatStroke => '[Ɓöŕðéŕ one]';

  @override
  String get cmdFormatEffects => '[Éƒƒéçţš one]';

  @override
  String get cmdFormatOpacity => '[Öþåçîţý… one]';

  @override
  String get cmdImageCrop => '[Çŕöþ on]';

  @override
  String get cmdImageMask => '[Ṁåšķ ŵîţĥ šĥåþé one t]';

  @override
  String get cmdImageReplace => '[Ŕéþļåçé îɱåĝé one t]';

  @override
  String get cmdImageAdjust => '[Åðĵûšţɱéñţš… one t]';

  @override
  String get cmdImageReset => '[Ŕéšéţ îɱåĝé one]';

  @override
  String get cmdImageDownloadOriginal => '[Ðöŵñļöåð öŕîĝîñåļ one tw]';

  @override
  String get cmdTableInsertRow => '[Îñšéŕţ ŕöŵ one]';

  @override
  String get cmdTableInsertColumn => '[Îñšéŕţ çöļûɱñ one t]';

  @override
  String get cmdTableDeleteRows => '[Ðéļéţé ŕöŵ one]';

  @override
  String get cmdTableDeleteColumns => '[Ðéļéţé çöļûɱñ one t]';

  @override
  String get cmdTableDelete => '[Ðéļéţé ţåƀļé one]';

  @override
  String get cmdTableMergeCells => '[Ṁéŕĝé çéļļš one]';

  @override
  String get cmdTableUnmergeCells => '[Ûñɱéŕĝé çéļļš one t]';

  @override
  String get cmdTableDistributeRows => '[Ðîšţŕîƀûţé ŕöŵš one t]';

  @override
  String get cmdTableDistributeColumns => '[Ðîšţŕîƀûţé çöļûɱñš one tw]';

  @override
  String get cmdTableSetOptions => '[Ţåƀļé öþţîöñš… one t]';

  @override
  String get cmdTableSetCellFill => '[Çéļļ ƒîļļ one]';

  @override
  String get cmdTableSetBorders => '[Ɓöŕðéŕš one]';

  @override
  String get cmdTableSetCellAlign => '[Ṽéŕţîçåļ åļîĝñ one t]';

  @override
  String get cmdShapeChange => '[Çĥåñĝé šĥåþé one]';

  @override
  String get cmdShapeApplyQuickStyle => '[Ǫûîçķ šţýļéš one]';

  @override
  String get cmdLineSetArrow => '[Åŕŕöŵš one]';

  @override
  String get cmdLineSetRouting => '[Ŕöûţîñĝ one]';

  @override
  String get cmdCodeEdit => '[Éðîţ çöðé one]';

  @override
  String get cmdCodeSetLanguage => '[Çöðé ļåñĝûåĝé one t]';

  @override
  String get cmdCodeUpdateOptions => '[Ļîñé ñûɱƀéŕš one]';

  @override
  String get cmdCodeSetHighlightSteps => '[Ĥîĝĥļîĝĥţ šţéþš… one tw]';

  @override
  String get cmdCodeAddState => '[Åðð šţåţé one]';

  @override
  String get cmdChartUpdate => '[Ûþðåţé çĥåŕţ one]';

  @override
  String get cmdChartSetAutoUpdate => '[Ûþðåţé åûţöɱåţîçåļļý one two]';

  @override
  String get cmdChartOpenSource => '[Öþéñ šöûŕçé šþŕéåðšĥééţ one two]';

  @override
  String get cmdChartUnlink => '[Ûñļîñķ çĥåŕţ one]';

  @override
  String get cmdChartCopyAsImage => '[Çöþý çĥåŕţ åš îɱåĝé one tw]';

  @override
  String get cmdElementEditAltText => '[Åļţ ţéẋţ… one]';

  @override
  String get cmdFormatPaintFormat => '[Þåîñţ ƒöŕɱåţ one]';

  @override
  String get cmdFormatClear => '[Çļéåŕ ƒöŕɱåţţîñĝ one tw]';

  @override
  String get cmdSlideDuplicate => '[Ðûþļîçåţé šļîðé one t]';

  @override
  String get cmdSlideDelete => '[Ðéļéţé šļîðé one]';

  @override
  String get cmdSlideToggleSkip => '[Šķîþ šļîðé one]';

  @override
  String get cmdSlideMove => '[Ṁöṽé šļîðé one]';

  @override
  String get cmdSlideApplyLayout => '[Åþþļý ļåýöûţ one]';

  @override
  String get cmdSlideResetToLayout => '[Ŕéšéţ šļîðé ţö ļåýöûţ one two]';

  @override
  String get cmdSlideSetBackground => '[Çĥåñĝé ƀåçķĝŕöûñð… one tw]';

  @override
  String get cmdSlideApplyBackgroundToAll =>
      '[Åþþļý ƀåçķĝŕöûñð ţö åļļ šļîðéš one two th]';

  @override
  String get cmdSlideSetHideMasterElements => '[Ĥîðé ɱåšţéŕ öƀĵéçţš one tw]';

  @override
  String get cmdDeckSetAppearance => '[Þŕéšéñţåţîöñ åþþéåŕåñçé one two]';

  @override
  String get cmdGroupCreate => '[Ĝŕöûþ šļîðéš one]';

  @override
  String get cmdGroupUngroup => '[Ûñĝŕöûþ šļîðéš one t]';

  @override
  String get cmdGroupAddSlides => '[Åðð ţö ĝŕöûþ one]';

  @override
  String get cmdGroupRemoveSlides => '[Ŕéɱöṽé ƒŕöɱ ĝŕöûþ one tw]';

  @override
  String get cmdGroupStartRename => '[Ŕéñåɱé ĝŕöûþ one]';

  @override
  String get cmdGroupSetColor => '[Ĝŕöûþ çöļöŕ one]';

  @override
  String get cmdGroupToggleSkip => '[Šķîþ ĝŕöûþ one]';

  @override
  String get cmdGroupCollapse => '[Çöļļåþšé ĝŕöûþ one t]';

  @override
  String get cmdGroupExpand => '[Éẋþåñð ĝŕöûþ one]';

  @override
  String get cmdGroupCollapseAll => '[Çöļļåþšé åļļ ĝŕöûþš one tw]';

  @override
  String get cmdGroupExpandAll => '[Éẋþåñð åļļ ĝŕöûþš one tw]';

  @override
  String get cmdGroupDuplicate => '[Ðûþļîçåţé ĝŕöûþ one t]';

  @override
  String get cmdGroupDelete => '[Ðéļéţé ĝŕöûþ… one t]';

  @override
  String get cmdGroupSelectSlides => '[Šéļéçţ šļîðéš îñ ĝŕöûþ one two]';

  @override
  String get cmdAnimatePreview => '[Þŕéṽîéŵ åñîɱåţîöñš one tw]';

  @override
  String get cmdAnimateRemoveAll => '[Ŕéɱöṽé åļļ åñîɱåţîöñš one two]';

  @override
  String get cmdAnimateAddBuild => '[Åðð åñîɱåţîöñ one t]';

  @override
  String get cmdAnimateCopyBuilds => '[Çöþý åñîɱåţîöñ one t]';

  @override
  String get cmdAnimatePasteBuilds => '[Þåšţé åñîɱåţîöñ one t]';

  @override
  String get cmdAnimateDeleteBuilds => '[Ŕéɱöṽé åñîɱåţîöñš one tw]';

  @override
  String get cmdThemeEdit => '[Éðîţ ţĥéɱé… one]';

  @override
  String get cmdNavGoToSlide => '[Ĝö ţö šļîðé… one]';

  @override
  String get cmdNavGoToGroup => '[Ĝö ţö ĝŕöûþ one]';

  @override
  String get cmdNavPreviousSlide => '[Þŕéṽîöûš šļîðé one t]';

  @override
  String get cmdNavNextSlide => '[Ñéẋţ šļîðé one]';

  @override
  String get cmdArrangeOrder => '[Öŕðéŕ on]';

  @override
  String get cmdArrangeAlign => '[Åļîĝñ öƀĵéçţš one t]';

  @override
  String get cmdArrangeDistribute => '[Ðîšţŕîƀûţé öƀĵéçţš one tw]';

  @override
  String get cmdArrangeCenterOnSlide => '[Çéñţéŕ öñ šļîðé one t]';

  @override
  String get cmdArrangeMatchSize => '[Ṁåţçĥ šîžé one]';

  @override
  String get cmdArrangeRotate => '[Ŕöţåţé one]';

  @override
  String get cmdArrangeFlip => '[Ƒļîþ on]';

  @override
  String get cmdArrangeGroup => '[Ĝŕöûþ on]';

  @override
  String get cmdArrangeUngroup => '[Ûñĝŕöûþ one]';

  @override
  String get cmdElementToggleLock => '[Ļöçķ on]';

  @override
  String get cmdElementUnlockAll => '[Ûñļöçķ åļļ öñ šļîðé one tw]';

  @override
  String get cmdElementHide => '[Ĥîðé on]';

  @override
  String get cmdElementShow => '[Šĥöŵ on]';

  @override
  String get cmdElementSetLink => '[Ļîñķ… on]';

  @override
  String get cmdElementRemoveLink => '[Ŕéɱöṽé ļîñķ one]';

  @override
  String get cmdElementResetPlaceholder => '[Ŕéšéţ ţö ļåýöûţ one t]';

  @override
  String get cmdSpellingCheck => '[Çĥéçķ šþéļļîñĝ one t]';

  @override
  String get cmdSpellingToggleUnderline => '[Ûñðéŕļîñé éŕŕöŕš one tw]';

  @override
  String get cmdToolsAccessibilityCheck => '[Åççéššîƀîļîţý çĥéçķ one two]';

  @override
  String get cmdNotificationsOpenSettings => '[Ñöţîƒîçåţîöñ šéţţîñĝš one two]';

  @override
  String get cmdAiGenerateDeck => '[Ĝéñéŕåţé þŕéšéñţåţîöñ… one two]';

  @override
  String get cmdAiRewrite => '[Ŕéŵŕîţé ţéẋţ one]';

  @override
  String get cmdAiSuggestLayouts =>
      '[Šûĝĝéšţ ļåýöûţš ƒöŕ ţĥîš šļîðé one two th]';

  @override
  String get cmdAiSpeakerNotes => '[Ŵŕîţé šþéåķéŕ ñöţéš one tw]';

  @override
  String get cmdAiAltText => '[Ĝéñéŕåţé åļţ ţéẋţ one tw]';

  @override
  String get cmdAiCodeWalkthrough => '[Ṁåķé å çöðé ŵåļķţĥŕöûĝĥ… one two]';

  @override
  String get cmdToolSelect => '[Šéļéçţ one]';

  @override
  String get cmdPrefsSet => '[Çĥåñĝé å Šļîðéš šéţţîñĝ one two]';

  @override
  String get cmdPresenterSet => '[Çĥåñĝé å þŕéšéñţîñĝ šéţţîñĝ one two t]';

  @override
  String get categoryFile => '[Ƒîļé on]';

  @override
  String get categoryEdit => '[Çöɱɱöñ one]';

  @override
  String get categoryView => '[Ṽîéŵ on]';

  @override
  String get categoryInsert => '[Îñšéŕţ one]';

  @override
  String get categoryFormat => '[Çåñṽåš & öƀĵéçţš one t]';

  @override
  String get categoryText => '[Ţéẋţ on]';

  @override
  String get categoryTables => '[Ţåƀļéš one]';

  @override
  String get categorySlides => '[Šļîðéš & ĝŕöûþš one t]';

  @override
  String get categoryArrange => '[Åŕŕåñĝé one]';

  @override
  String get categoryCanvas => '[Çåñṽåš & öƀĵéçţš one t]';

  @override
  String get categoryPresent => '[Þŕéšéñţ one]';

  @override
  String get categoryAnimations => '[Åñîɱåţîöñš one]';

  @override
  String get categoryTools => '[Ţööļš on]';

  @override
  String get categoryAi => '[ÅÎ o]';

  @override
  String get alignLeft => '[Ļéƒţ on]';

  @override
  String get alignCenter => '[Çéñţéŕ one]';

  @override
  String get alignRight => '[Ŕîĝĥţ on]';

  @override
  String get alignJustify => '[Ĵûšţîƒý one]';

  @override
  String get anchorTop => '[Ţöþ on]';

  @override
  String get anchorMiddle => '[Ṁîððļé one]';

  @override
  String get anchorBottom => '[Ɓöţţöɱ one]';

  @override
  String get animateAddBuildIn => '[Åðð ƀûîļð îñ one]';

  @override
  String get animateAddAction => '[Åðð åçţîöñ one]';

  @override
  String get animateAddBuildOut => '[Åðð ƀûîļð öûţ one]';

  @override
  String get animateTabTransition => '[Ţŕåñšîţîöñ one]';

  @override
  String get animateTabBuild => '[Ɓûîļð on]';

  @override
  String get animateTabOrder => '[Öŕðéŕ on]';

  @override
  String get appearanceLight => '[Ļîĝĥţ on]';

  @override
  String get appearanceDark => '[Ðåŕķ on]';

  @override
  String get autofitNone => '[Ðö ñöţ åûţöƒîţ one t]';

  @override
  String get autofitShrink => '[Šĥŕîñķ ţéẋţ öñ öṽéŕƒļöŵ one two]';

  @override
  String get autofitResize => '[Ŕéšîžé šĥåþé ţö ƒîţ ţéẋţ one two]';

  @override
  String get axisHorizontally => '[Ĥöŕîžöñţåļļý one t]';

  @override
  String get axisVertically => '[Ṽéŕţîçåļļý one]';

  @override
  String get axisBoth => '[Ɓöţĥ on]';

  @override
  String get backToNormalView => '[Ɓåçķ ţö Ñöŕɱåļ ṽîéŵ one tw]';

  @override
  String get backToPresentation => '[Ɓåçķ ţö ţĥé þŕéšéñţåţîöñ one two]';

  @override
  String get badgeViewOnly => '[Ṽîéŵ öñļý one]';

  @override
  String get badgeCommentOnly => '[Çöɱɱéñţ öñļý one]';

  @override
  String get badgeViewing => '[Ṽîéŵîñĝ one]';

  @override
  String get canvasChooseLayout => '[Çĥööšé å ļåýöûţ one t]';

  @override
  String get canvasEmptyTitle => '[Ţĥîš þŕéšéñţåţîöñ ĥåš ñö šļîðéš one two th]';

  @override
  String get canvasEmptyBody =>
      '[Åðð å šļîðé ţö šţåŕţ, öŕ çĥööšé å ļåýöûţ ƒöŕ îţ. one two three]';

  @override
  String canvasSlideSemantics(int number, String title) {
    return '[Šļîðé $number: $title one]';
  }

  @override
  String get capsUpper => '[ÛÞÞÉŔÇÅŠÉ one]';

  @override
  String get capsSmallCaps => '[Šɱåļļ çåþš one]';

  @override
  String get capsTitle => '[Ţîţļé Çåšé one]';

  @override
  String get capsNone => '[Ñöñé on]';

  @override
  String get chartColumn => '[Çöļûɱñ one]';

  @override
  String get chartBar => '[Ɓåŕ on]';

  @override
  String get chartLine => '[Ļîñé on]';

  @override
  String get chartPie => '[Þîé on]';

  @override
  String get chartArea => '[Åŕéå on]';

  @override
  String get chartScatter => '[Šçåţţéŕ one]';

  @override
  String get chartFromSheets => '[Ƒŕöɱ Ŵöñķý Šĥééţš… one tw]';

  @override
  String get codeAllLanguages => '[Åļļ ļåñĝûåĝéš… one t]';

  @override
  String get codeLineNumbers => '[Ļîñé ñûɱƀéŕš one]';

  @override
  String get codePlainText => '[Þļåîñ ţéẋţ one]';

  @override
  String get codeStates => '[Šţåţéš… one]';

  @override
  String get colorGray => '[Ĝŕåý on]';

  @override
  String get colorRed => '[Ŕéð on]';

  @override
  String get colorOrange => '[Öŕåñĝé one]';

  @override
  String get colorAmber => '[Åɱƀéŕ on]';

  @override
  String get colorGreen => '[Ĝŕééñ on]';

  @override
  String get colorTeal => '[Ţéåļ on]';

  @override
  String get colorBlue => '[Ɓļûé on]';

  @override
  String get colorViolet => '[Ṽîöļéţ one]';

  @override
  String get colorPink => '[Þîñķ on]';

  @override
  String get colorNone => '[Ñöñé on]';

  @override
  String get deckLoading => '[Öþéñîñĝ þŕéšéñţåţîöñ… one two]';

  @override
  String deckLoadingProgress(String message, int percent) {
    return '[$message $percent % o]';
  }

  @override
  String get deckUnavailable =>
      '[Ţĥîš þŕéšéñţåţîöñ îšñ’ţ åṽåîļåƀļé one two thr]';

  @override
  String get deckOfflineHint =>
      '[Îţ öþéñš ƀý îţšéļƒ ŵĥéñ ýöû’ŕé ƀåçķ öñļîñé. one two three]';

  @override
  String get downloadPdf => '[ÞÐƑ ðöçûɱéñţ (.þðƒ) one tw]';

  @override
  String get downloadPng => '[ÞÑĜ îɱåĝé (çûŕŕéñţ šļîðé)… one two t]';

  @override
  String get downloadPngZip => '[ÞÑĜ îɱåĝéš (åļļ šļîðéš, .žîþ)… one two th]';

  @override
  String get downloadMarkdown => '[Öûţļîñé åš Ṁåŕķðöŵñ (.ɱð) one two]';

  @override
  String durationMinutes(int minutes) {
    return '[$minutes ɱîñ on]';
  }

  @override
  String durationSeconds(String seconds) {
    return '[$seconds š o]';
  }

  @override
  String get flipHorizontally => '[Ƒļîþ ĥöŕîžöñţåļļý one tw]';

  @override
  String get flipVertically => '[Ƒļîþ ṽéŕţîçåļļý one t]';

  @override
  String get goToSlideTitle => '[Ĝö ţö šļîðé one]';

  @override
  String get goToSlideLabel => '[Šļîðé on]';

  @override
  String get goToSlideButton => '[Ĝö o]';

  @override
  String get groupUntitled => '[Ûñţîţļéð ĝŕöûþ one t]';

  @override
  String get guidesAddVertical => '[Åðð ṽéŕţîçåļ ĝûîðé one tw]';

  @override
  String get guidesAddHorizontal => '[Åðð ĥöŕîžöñţåļ ĝûîðé one two]';

  @override
  String get imageUpload => '[Ûþļöåð ƒŕöɱ çöɱþûţéŕ one two]';

  @override
  String get imageFromDrive => '[Ƒŕöɱ Ŵöñķý Ðŕîṽé one t]';

  @override
  String get imageByUrl => '[Ɓý ÛŔĻ on]';

  @override
  String get imageFromClipboard => '[Ƒŕöɱ çļîþƀöåŕð one t]';

  @override
  String get inspectorLabel => '[Îñšþéçţöŕ one]';

  @override
  String get inspectorFormat => '[Ƒöŕɱåţ one]';

  @override
  String get inspectorAnimate => '[Åñîɱåţé one]';

  @override
  String get inspectorSlide => '[Šļîðé on]';

  @override
  String get inspectorClose => '[Çļöšé îñšþéçţöŕ one t]';

  @override
  String get inspectorFormatEmpty =>
      '[Šéļéçţ åñ öƀĵéçţ ţö ƒöŕɱåţ îţ one two t]';

  @override
  String get inspectorSectionSoon =>
      '[Ţĥéšé öþţîöñš åŕé öñ ţĥéîŕ ŵåý. one two th]';

  @override
  String get inspectorCurrentLayout => '[Ļåýöûţ one]';

  @override
  String get inspectorAppearance => '[Åþþéåŕåñçé one]';

  @override
  String get inspectorNotInGroup => '[Ñöţ îñ å ĝŕöûþ one]';

  @override
  String get inspectorGroupName => '[Ĝŕöûþ on]';

  @override
  String get inspectorSlideNumber => '[Þöšîţîöñ one]';

  @override
  String get inspectorSkipped => '[Šķîþþéð one]';

  @override
  String get yes => '[Ýéš on]';

  @override
  String get lineLine => '[Ļîñé on]';

  @override
  String get lineArrow => '[Åŕŕöŵ on]';

  @override
  String get lineDoubleArrow => '[Ðöûƀļé åŕŕöŵ one]';

  @override
  String get lineElbowConnector => '[Éļƀöŵ çöññéçţöŕ one t]';

  @override
  String get lineCurvedConnector => '[Çûŕṽéð çöññéçţöŕ one tw]';

  @override
  String get lineStartArrow => '[Šţåŕţ åŕŕöŵ one]';

  @override
  String get lineEndArrow => '[Éñð åŕŕöŵ one]';

  @override
  String get listBulleted => '[Ɓûļļéţéð ļîšţ one t]';

  @override
  String get listNumbered => '[Ñûɱƀéŕéð ļîšţ one t]';

  @override
  String get listChecklist => '[Çĥéçķļîšţ one]';

  @override
  String get listOptions => '[Ļîšţ öþţîöñš… one t]';

  @override
  String get menuAddToGroup => '[Åðð ţö ĝŕöûþ one]';

  @override
  String get menuAi => '[ÅÎ o]';

  @override
  String get menuAlign => '[Åļîĝñ on]';

  @override
  String get menuAlignIndent => '[Åļîĝñ & îñðéñţ one t]';

  @override
  String get menuAnimate => '[Åñîɱåţé one]';

  @override
  String get menuAnimateEllipsis => '[Åñîɱåţé… one]';

  @override
  String get menuAnimation => '[Åñîɱåţîöñ… one]';

  @override
  String get menuApplyLayout => '[Åþþļý ļåýöûţ one]';

  @override
  String get menuArrange => '[Åŕŕåñĝé one]';

  @override
  String get menuBorderEllipsis => '[Ɓöŕðéŕ… one]';

  @override
  String get menuCapitalization => '[Çåþîţåļîžåţîöñ one t]';

  @override
  String get menuCenterOnSlide => '[Çéñţéŕ öñ šļîðé one t]';

  @override
  String get menuChangeBackground => '[Çĥåñĝé ƀåçķĝŕöûñð… one tw]';

  @override
  String get menuChangeTheme => '[Çĥåñĝé ţĥéɱé… one t]';

  @override
  String get menuChart => '[Çĥåŕţ on]';

  @override
  String get menuChooseGroup => '[Çĥööšé å ĝŕöûþ… one t]';

  @override
  String get menuCode => '[Çöðé on]';

  @override
  String get menuCodeBlock => '[Çöðé ƀļöçķ one]';

  @override
  String get menuCommentOnSlide => '[Çöɱɱéñţ öñ šļîðé one t]';

  @override
  String get menuDistribute => '[Ðîšţŕîƀûţé one]';

  @override
  String get menuDownload => '[Ðöŵñļöåð one]';

  @override
  String get menuEditLayout => '[Éðîţ ļåýöûţ one]';

  @override
  String get menuEditMasters => '[Éðîţ ɱåšţéŕš åñð ļåýöûţš one two]';

  @override
  String get menuEffectsEllipsis => '[Éƒƒéçţš… one]';

  @override
  String get menuExtensions => '[Éẋţéñšîöñš one]';

  @override
  String get menuFillEllipsis => '[Ƒîļļ… on]';

  @override
  String get menuFormat => '[Ƒöŕɱåţ one]';

  @override
  String get menuFormatOptions => '[Ƒöŕɱåţ öþţîöñš… one t]';

  @override
  String get menuGroup => '[Ĝŕöûþ on]';

  @override
  String get menuGroupColor => '[Çöļöŕ on]';

  @override
  String get menuGuides => '[Ĝûîðéš one]';

  @override
  String get menuImage => '[Îɱåĝé on]';

  @override
  String get menuInsert => '[Îñšéŕţ one]';

  @override
  String get menuLanguage => '[Ļåñĝûåĝé one]';

  @override
  String get menuLine => '[Ļîñé on]';

  @override
  String get menuLists => '[Ɓûļļéţš & ñûɱƀéŕîñĝ one tw]';

  @override
  String get menuMagicMoveId => '[Ṁåĝîç Ṁöṽé ÎÐ… one t]';

  @override
  String get menuMatchSize => '[Ṁåţçĥ šîžé one]';

  @override
  String get menuMcp => '[ṀÇÞ on]';

  @override
  String get menuMoveSlide => '[Ṁöṽé šļîðé one]';

  @override
  String get menuNewGroup => '[Ñéŵ ĝŕöûþ one]';

  @override
  String get menuNewSlideInGroup => '[Ñéŵ šļîðé îñ ĝŕöûþ one tw]';

  @override
  String get menuNewSlideWithLayout => '[Ñéŵ šļîðé ŵîţĥ ļåýöûţ one two]';

  @override
  String get menuOrder => '[Öŕðéŕ on]';

  @override
  String get menuPanels => '[Þåñéļš one]';

  @override
  String get menuPasteSpecial => '[Þåšţé šþéçîåļ one t]';

  @override
  String get menuPersonalDictionary => '[Þéŕšöñåļ ðîçţîöñåŕý one two]';

  @override
  String get menuPlaceholder => '[Þļåçéĥöļðéŕ one]';

  @override
  String get menuPresent => '[Þŕéšéñţ one]';

  @override
  String get menuPresentFromGroup => '[Þŕéšéñţ ƒŕöɱ ţĥîš ĝŕöûþ one two]';

  @override
  String get menuPresentingSettings => '[Þŕéšéñţîñĝ šéţţîñĝš… one two]';

  @override
  String get menuRehearsePresentation => '[Ŕéĥéåŕšé þŕéšéñţåţîöñ one two]';

  @override
  String get menuRewriteText => '[Ŕéŵŕîţé ţéẋţ one]';

  @override
  String get menuRotate => '[Ŕöţåţé one]';

  @override
  String get menuShape => '[Šĥåþé on]';

  @override
  String get menuShapeGallery => '[Åļļ šĥåþéš… one]';

  @override
  String get menuShow => '[Šĥöŵ on]';

  @override
  String get menuSize => '[Šîžé on]';

  @override
  String get menuSizePosition => '[Šîžé åñð þöšîţîöñ… one tw]';

  @override
  String get menuSlide => '[Šļîðé on]';

  @override
  String get menuSnap => '[Šñåþ on]';

  @override
  String get menuSpacing => '[Ļîñé & þåŕåĝŕåþĥ šþåçîñĝ one two]';

  @override
  String get menuSpelling => '[Šþéļļîñĝ one]';

  @override
  String get menuTable => '[Ţåƀļé on]';

  @override
  String get menuText => '[Ţéẋţ on]';

  @override
  String get menuTextFitting => '[Ţéẋţ ƒîţţîñĝ one]';

  @override
  String get menuTextStyle => '[Ţéẋţ šţýļé one]';

  @override
  String get menuTransition => '[Ţŕåñšîţîöñ… one]';

  @override
  String get menuVersionHistory => '[Ṽéŕšîöñ ĥîšţöŕý one t]';

  @override
  String get menuZoom => '[Žööɱ on]';

  @override
  String get moveToBeginning => '[Ţö ƀéĝîññîñĝ one]';

  @override
  String get moveUp => '[Ûþ o]';

  @override
  String get moveDown => '[Ðöŵñ on]';

  @override
  String get moveToEnd => '[Ţö éñð on]';

  @override
  String get navigatorLabel => '[Šļîðéš one]';

  @override
  String get navigatorEmpty => '[Ñö šļîðéš one]';

  @override
  String get navigatorOpen => '[Šĥöŵ šļîðéš one]';

  @override
  String navigatorGroupSemantics(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš',
      one: '1 šļîðé',
    );
    return '[Ĝŕöûþ $title, $_temp0 one two]';
  }

  @override
  String navigatorSlideSemantics(int number, int total, String title) {
    return '[Šļîðé $number öƒ $total: $title one]';
  }

  @override
  String get notesLabel => '[Šþéåķéŕ ñöţéš one t]';

  @override
  String get notesPlaceholder => '[Çļîçķ ţö åðð šþéåķéŕ ñöţéš one two]';

  @override
  String get orderBringToFront => '[Ɓŕîñĝ ţö ƒŕöñţ one t]';

  @override
  String get orderBringForward => '[Ɓŕîñĝ ƒöŕŵåŕð one t]';

  @override
  String get orderSendBackward => '[Šéñð ƀåçķŵåŕð one t]';

  @override
  String get orderSendToBack => '[Šéñð ţö ƀåçķ one]';

  @override
  String get outlineNoTitle => '[(ñö ţîţļé) one]';

  @override
  String get pasteKeepSource => '[Ķééþ šöûŕçé ƒöŕɱåţţîñĝ one two]';

  @override
  String get pasteUseDestination => '[Ûšé ðéšţîñåţîöñ ţĥéɱé one two]';

  @override
  String get pasteChartUnlinked => '[Þåšţé çĥåŕţ ûñļîñķéð one two]';

  @override
  String get placeholderPicture => '[Þîçţûŕé one]';

  @override
  String get placeholderObject => '[Öƀĵéçţ one]';

  @override
  String get placeholderFooter => '[Ƒööţéŕ one]';

  @override
  String get placeholderSlideNumber => '[Šļîðé ñûɱƀéŕ one]';

  @override
  String get placeholderDate => '[Ðåţé on]';

  @override
  String get presentButton => '[Þŕéšéñţ one]';

  @override
  String get presentOptions => '[Þŕéšéñţîñĝ öþţîöñš one tw]';

  @override
  String get presenterLayoutStandard => '[Çûŕŕéñţ, ñéẋţ åñð ñöţéš one two]';

  @override
  String get presenterLayoutNotes => '[Ļåŕĝé ñöţéš one]';

  @override
  String get presenterLayoutNext => '[Ļåŕĝé ñéẋţ šļîðé one t]';

  @override
  String get reasonNotAvailableYet => '[Ñöţ åṽåîļåƀļé ýéţ one tw]';

  @override
  String get reasonDeckLoading =>
      '[Ţĥé þŕéšéñţåţîöñ îš šţîļļ öþéñîñĝ one two thr]';

  @override
  String get reasonViewAccess => '[Ýöû ĥåṽé ṽîéŵ åççéšš one tw]';

  @override
  String get reasonViewingMode => '[Ýöû’ŕé îñ Ṽîéŵîñĝ ɱöðé one two]';

  @override
  String get reasonFirstSlide => '[Ţĥîš îš ţĥé ƒîŕšţ šļîðé one two]';

  @override
  String get reasonLastSlide => '[Ţĥîš îš ţĥé ļåšţ šļîðé one two]';

  @override
  String get reasonNoSlides => '[Ţĥé þŕéšéñţåţîöñ ĥåš ñö šļîðéš one two th]';

  @override
  String get rewriteShorter => '[Šĥöŕţéŕ one]';

  @override
  String get rewriteLonger => '[Ļöñĝéŕ one]';

  @override
  String get rewriteClearer => '[Çļéåŕéŕ one]';

  @override
  String get rewriteFormal => '[Ṁöŕé ƒöŕɱåļ one]';

  @override
  String get rewriteGrammar => '[Ƒîẋ ĝŕåɱɱåŕ one]';

  @override
  String get rewriteCustom => '[Çûšţöɱ… one]';

  @override
  String get rotateClockwise => '[Ŕöţåţé 90° çļöçķŵîšé one two]';

  @override
  String get rotateCounterClockwise =>
      '[Ŕöţåţé 90° çöûñţéŕ-çļöçķŵîšé one two th]';

  @override
  String get routePresentTitle => '[Þŕéšéñţîñĝ one]';

  @override
  String get routePrintTitle => '[Þŕîñţ åñð ÞÐƑ one]';

  @override
  String get routeHistoryTitle => '[Ṽéŕšîöñ ĥîšţöŕý one t]';

  @override
  String get sectionText => '[Ţéẋţ on]';

  @override
  String get sectionLine => '[Ļîñé on]';

  @override
  String get sectionImage => '[Îɱåĝé on]';

  @override
  String get sectionTable => '[Ţåƀļé on]';

  @override
  String get sectionCell => '[Çéļļ on]';

  @override
  String get sectionIcon => '[Îçöñ on]';

  @override
  String get sectionCode => '[Çöðé on]';

  @override
  String get sectionChart => '[Çĥåŕţ on]';

  @override
  String get sectionFill => '[Ƒîļļ on]';

  @override
  String get sectionBorder => '[Ɓöŕðéŕ one]';

  @override
  String get sectionEffects => '[Éƒƒéçţš one]';

  @override
  String get sectionArrange => '[Åŕŕåñĝé one]';

  @override
  String get sectionLink => '[Ļîñķ on]';

  @override
  String get sectionAccessibility => '[Åççéššîƀîļîţý one t]';

  @override
  String get sectionLayout => '[Ļåýöûţ one]';

  @override
  String get sectionBackground => '[Ɓåçķĝŕöûñð one]';

  @override
  String get sectionTheme => '[Ţĥéɱé on]';

  @override
  String get sectionVisibility => '[Ṽîšîƀîļîţý one]';

  @override
  String get sectionGroup => '[Ĝŕöûþ on]';

  @override
  String get sectionInfo => '[Îñƒö on]';

  @override
  String get settingsSectionPresentations => '[Ñéŵ þŕéšéñţåţîöñš one tw]';

  @override
  String get settingsSectionEditing => '[Éðîţîñĝ one]';

  @override
  String get settingsSectionAnimations => '[Åñîɱåţîöñš & çöðé one tw]';

  @override
  String get settingsSectionPresenting => '[Þŕéšéñţîñĝ one]';

  @override
  String get settingsNewPresentations => '[Ñéŵ þŕéšéñţåţîöñš one tw]';

  @override
  String get settingsNewPresentationsHint =>
      '[Ûšéð ŵĥéñ ýöû çŕéåţé å þŕéšéñţåţîöñ. Éẋîšţîñĝ þŕéšéñţåţîöñš ķééþ ţĥéîŕ öŵñ šéţţîñĝš. one two three four five si]';

  @override
  String get settingsDefaultTheme => '[Ţĥéɱé on]';

  @override
  String get settingsDefaultAppearance => '[Åþþéåŕåñçé one]';

  @override
  String get settingsDefaultSize => '[Šļîðé šîžé one]';

  @override
  String get settingsDefaultLanguage => '[Ļåñĝûåĝé one]';

  @override
  String get settingsCharts => '[Çĥåŕţš one]';

  @override
  String get settingsChartsAutoUpdate =>
      '[Ûþðåţé ļîñķéð çĥåŕţš åûţöɱåţîçåļļý one two thr]';

  @override
  String get settingsChartsAutoUpdateHint =>
      '[Ñéŵ çĥåŕţš ƒŕöɱ Ŵöñķý Šĥééţš ƒöļļöŵ ţĥéîŕ šþŕéåðšĥééţ. one two three fou]';

  @override
  String get settingsEditing => '[Éðîţîñĝ one]';

  @override
  String get settingsUnits => '[Ûñîţš on]';

  @override
  String get settingsScrollChangesSlides => '[Šçŕöļļ ţö çĥåñĝé šļîðéš one two]';

  @override
  String get settingsSmartQuotes => '[Šɱåŕţ ǫûöţéš one]';

  @override
  String get settingsAutoformatLists =>
      '[Åûţöɱåţîçåļļý ƒöŕɱåţ ļîšţš one two t]';

  @override
  String get settingsShowRemoteCursors =>
      '[Šĥöŵ çöļļåƀöŕåţöŕ çûŕšöŕš one two t]';

  @override
  String get settingsSpelling => '[Šþéļļîñĝ one]';

  @override
  String get settingsUnderlineSpelling =>
      '[Ûñðéŕļîñé šþéļļîñĝ éŕŕöŕš one two t]';

  @override
  String get settingsAnimations => '[Åñîɱåţîöñš one]';

  @override
  String get settingsDefaultTransition => '[Ðéƒåûļţ ţŕåñšîţîöñ one tw]';

  @override
  String get settingsTransitionDuration => '[Ţŕåñšîţîöñ ðûŕåţîöñ one two]';

  @override
  String get settingsDefaultBuild => '[Ðéƒåûļţ ƀûîļð one t]';

  @override
  String get settingsPreviewOnHover =>
      '[Þŕéṽîéŵ åñîɱåţîöñš öñ ĥöṽéŕ one two t]';

  @override
  String get settingsReduceEditorMotion =>
      '[Ŕéðûçé ɱöţîöñ îñ ţĥé éðîţöŕ one two t]';

  @override
  String get settingsReduceEditorMotionHint =>
      '[Þŕéṽîéŵš šĥöŵ ţĥé éñð šţåţé îñšţéåð öƒ þļåýîñĝ. one two three]';

  @override
  String get settingsCode => '[Çöðé on]';

  @override
  String get settingsCodeFontSize => '[Ļåŕĝéšţ çöðé ƒöñţ šîžé one two]';

  @override
  String get settingsCodeLanguage => '[Ðéƒåûļţ çöðé ļåñĝûåĝé one two]';

  @override
  String get settingsTypingSpeed => '[Ţýþé-îñ šþééð one t]';

  @override
  String get settingsTypeInSound => '[Ţýþé-îñ çļîçķ šöûñð one tw]';

  @override
  String get settingsPresenting => '[Þŕéšéñţîñĝ one]';

  @override
  String get settingsPresentingHint =>
      '[Ĥöŵ ýöû þŕéšéñţ. Ţĥé åûðîéñçé ṽîéŵ ƒöļļöŵš ţĥé þŕéšéñţåţîöñ. one two three four]';

  @override
  String get settingsPresenterLayout => '[Þŕéšéñţéŕ ṽîéŵ ļåýöûţ one two]';

  @override
  String get settingsNotesSize => '[Ñöţéš ţéẋţ šîžé one t]';

  @override
  String get settingsTimerMode => '[Ţîɱéŕ on]';

  @override
  String get settingsTimerTarget => '[Çöûñţðöŵñ ļéñĝţĥ one tw]';

  @override
  String get settingsLaserColor => '[Ļåšéŕ þöîñţéŕ çöļöŕ one tw]';

  @override
  String get settingsStartFullscreen =>
      '[Šţåŕţ þŕéšéñţîñĝ îñ ƒûļļ šçŕééñ one two th]';

  @override
  String get settingsStartWithPresenterView =>
      '[Šţåŕţ ŵîţĥ þŕéšéñţéŕ ṽîéŵ one two]';

  @override
  String get settingsShowSkippedInPresenter =>
      '[Šĥöŵ šķîþþéð šļîðéš îñ þŕéšéñţéŕ ṽîéŵ one two thre]';

  @override
  String get sizeWidescreen16x9 => '[Ŵîðéšçŕééñ 16:9 one t]';

  @override
  String get sizeStandard4x3 => '[Šţåñðåŕð 4:3 one]';

  @override
  String get sizeWide16x10 => '[Ŵîðéšçŕééñ 16:10 one tw]';

  @override
  String get sizeSquare => '[Šǫûåŕé 1:1 one]';

  @override
  String get sizePortrait9x16 => '[Þöŕţŕåîţ 9:16 one t]';

  @override
  String get sizeA4 => '[Å4 ļåñðšçåþé one]';

  @override
  String get sizeLetter => '[Ļéţţéŕ ļåñðšçåþé one tw]';

  @override
  String get sizeWidth => '[Ŵîðţĥ on]';

  @override
  String get sizeHeight => '[Ĥéîĝĥţ one]';

  @override
  String get slideUntitled => '[Ûñţîţļéð šļîðé one t]';

  @override
  String get spacingSingle => '[Šîñĝļé one]';

  @override
  String get spacingDouble => '[Ðöûƀļé one]';

  @override
  String get spacingCustom => '[Çûšţöɱ… one]';

  @override
  String get spacingAddBefore => '[Åðð šþåçé ƀéƒöŕé þåŕåĝŕåþĥ one two t]';

  @override
  String get spacingAddAfter => '[Åðð šþåçé åƒţéŕ þåŕåĝŕåþĥ one two]';

  @override
  String get speedSlow => '[Šļöŵ on]';

  @override
  String get speedNormal => '[Ñöŕɱåļ one]';

  @override
  String get speedFast => '[Ƒåšţ on]';

  @override
  String get statusNoSlides => '[Ñö šļîðéš one]';

  @override
  String statusSlideOf(int number, int total) {
    return '[Šļîðé $number öƒ $total one]';
  }

  @override
  String statusSkipped(int count) {
    return '[$count šķîþþéð one]';
  }

  @override
  String get styleTitle => '[Ţîţļé on]';

  @override
  String get styleSubtitle => '[Šûƀţîţļé one]';

  @override
  String get styleHeading => '[Ĥéåðîñĝ one]';

  @override
  String get styleBody => '[Ɓöðý on]';

  @override
  String get styleBody2 => '[Ɓöðý 2 on]';

  @override
  String get styleCaption => '[Çåþţîöñ one]';

  @override
  String get styleQuote => '[Ǫûöţé on]';

  @override
  String get styleAttribution => '[Åţţŕîƀûţîöñ one]';

  @override
  String get styleBigNumber => '[Ɓîĝ ñûɱƀéŕ one]';

  @override
  String get styleLabel => '[Ļåƀéļ on]';

  @override
  String get tableInsertRowAbove => '[Îñšéŕţ ŕöŵ åƀöṽé one t]';

  @override
  String get tableInsertRowBelow => '[Îñšéŕţ ŕöŵ ƀéļöŵ one t]';

  @override
  String get tableInsertColumnLeft => '[Îñšéŕţ çöļûɱñ ļéƒţ one tw]';

  @override
  String get tableInsertColumnRight => '[Îñšéŕţ çöļûɱñ ŕîĝĥţ one tw]';

  @override
  String get textSuperscript => '[Šûþéŕšçŕîþţ one]';

  @override
  String get textSubscript => '[Šûƀšçŕîþţ one]';

  @override
  String get timerElapsed => '[Éļåþšéð ţîɱé one]';

  @override
  String get timerCountdown => '[Çöûñţðöŵñ one]';

  @override
  String get toolbarLabel => '[Šļîðéš ţööļƀåŕ one t]';

  @override
  String get toolbarUndo => '[Ûñðö on]';

  @override
  String get toolbarRedo => '[Ŕéðö on]';

  @override
  String toolbarUndoLabel(String label) {
    return '[Ûñðö $label on]';
  }

  @override
  String toolbarRedoLabel(String label) {
    return '[Ŕéðö $label on]';
  }

  @override
  String get toolbarZoom => '[Žööɱ on]';

  @override
  String get toolbarAddComment => '[Åðð çöɱɱéñţ one]';

  @override
  String get toolbarAlign => '[Åļîĝñ on]';

  @override
  String get toolbarAnimate => '[Åñîɱåţé one]';

  @override
  String get toolbarBackground => '[Ɓåçķĝŕöûñð one]';

  @override
  String get toolbarLayout => '[Ļåýöûţ one]';

  @override
  String get toolbarTheme => '[Ţĥéɱé on]';

  @override
  String get toolbarTransition => '[Ţŕåñšîţîöñ one]';

  @override
  String get unitsSu => '[Šļîðé ûñîţš one]';

  @override
  String get unitsPx => '[Þîẋéļš one]';

  @override
  String get unitsIn => '[Îñçĥéš one]';

  @override
  String get unitsCm => '[Çéñţîɱéţéŕš one]';

  @override
  String get viewNormal => '[Ñöŕɱåļ one]';

  @override
  String get viewGrid => '[Ĝŕîð on]';

  @override
  String get viewOutline => '[Öûţļîñé one]';

  @override
  String get zoomFit => '[Ƒîţ on]';

  @override
  String zoomPercent(int percent) {
    return '[$percent % o]';
  }

  @override
  String get toastUndoPartial =>
      '[Šöɱé çĥåñĝéš ŵéŕéñ’ţ ûñðöñé ƀéçåûšé å çöļļåƀöŕåţöŕ çĥåñĝéð ţĥéɱ šîñçé one two three four fi]';

  @override
  String toastChangeNotSaved(String label, String reason) {
    return '[“$label” çöûļðñ’ţ ƀé šåṽéð: $reason one two]';
  }

  @override
  String get toastChangeNoAccess =>
      '[Ýöû çåñ ñö ļöñĝéŕ éðîţ ţĥîš þŕéšéñţåţîöñ one two thre]';

  @override
  String get cmdSelectElements => '[Šéļéçţ öƀĵéçţš one t]';

  @override
  String get cmdSelectNext => '[Šéļéçţ ñéẋţ öƀĵéçţ one tw]';

  @override
  String get cmdSelectPrevious => '[Šéļéçţ þŕéṽîöûš öƀĵéçţ one two]';

  @override
  String get cmdElementMove => '[Ṁöṽé on]';

  @override
  String get cmdElementResize => '[Ŕéšîžé one]';

  @override
  String get cmdElementNudge => '[Ñûðĝé on]';

  @override
  String get cmdElementAdjust => '[Åðĵûšţ šĥåþé one]';

  @override
  String get cmdElementSetLineEnds => '[Ṁöṽé ļîñé éñð one]';

  @override
  String get cmdElementLock => '[Ļöçķ on]';

  @override
  String get cmdElementUnlock => '[Ûñļöçķ one]';

  @override
  String get cmdGuidesMove => '[Ṁöṽé ĝûîðé one]';

  @override
  String get cmdGuidesDelete => '[Ðéļéţé ĝûîðé one]';

  @override
  String get undoRotate => '[Ŕöţåţé one]';

  @override
  String get undoFlip => '[Ƒļîþ on]';

  @override
  String get reasonSelectObject => '[Šéļéçţ åñ öƀĵéçţ one t]';

  @override
  String get reasonSelectTwoObjects => '[Šéļéçţ åţ ļéåšţ 2 öƀĵéçţš one two]';

  @override
  String get reasonSelectThreeObjects => '[Šéļéçţ åţ ļéåšţ 3 öƀĵéçţš one two]';

  @override
  String get reasonObjectLocked => '[Ûñļöçķ ţĥé öƀĵéçţ ƒîŕšţ one two]';

  @override
  String get reasonInsideGroup =>
      '[Ñöţ åṽåîļåƀļé ƒöŕ öƀĵéçţš îñšîðé å ĝŕöûþ one two thre]';

  @override
  String get reasonSelectGroup => '[Šéļéçţ å ĝŕöûþ one t]';

  @override
  String get reasonNoLockedObjects =>
      '[Ñö ļöçķéð öƀĵéçţš öñ ţĥîš šļîðé one two th]';

  @override
  String get reasonNoGuides => '[Ţĥéŕé åŕé ñö ĝûîðéš one tw]';

  @override
  String get reasonNotOnCanvas => '[Ñöţ åṽåîļåƀļé ƒöŕ ţĥîš öƀĵéçţ one two t]';

  @override
  String get elementKindText => '[Ţéẋţ ƀöẋ one]';

  @override
  String get elementKindShape => '[Šĥåþé on]';

  @override
  String get elementKindLine => '[Ļîñé on]';

  @override
  String get elementKindImage => '[Îɱåĝé on]';

  @override
  String get elementKindTable => '[Ţåƀļé on]';

  @override
  String get elementKindCode => '[Çöðé on]';

  @override
  String get elementKindChart => '[Çĥåŕţ on]';

  @override
  String get elementKindIcon => '[Îçöñ on]';

  @override
  String get elementKindGroup => '[Ĝŕöûþ on]';

  @override
  String get elementKindPlaceholder => '[Þļåçéĥöļðéŕ one]';

  @override
  String canvasAnnounceSelected(String name, int index, int count) {
    return '[$name šéļéçţéð, $index öƒ $count öƀĵéçţš one two]';
  }

  @override
  String canvasAnnounceSelectedMany(int count) {
    return '[$count öƀĵéçţš šéļéçţéð one tw]';
  }

  @override
  String canvasAnnounceMoved(int x, int y) {
    return '[Ṁöṽéð ţö ẋ $x, ý $y one]';
  }

  @override
  String canvasElementSemantics(String name, String state) {
    return '[$name, $state o]';
  }

  @override
  String get canvasStateSelected => '[šéļéçţéð one]';

  @override
  String get canvasStateLocked => '[ļöçķéð one]';

  @override
  String canvasDimensions(int width, int height) {
    return '[$width × $height o]';
  }

  @override
  String canvasPosition(int x, int y) {
    return '[$x, $y o]';
  }

  @override
  String canvasAngle(int degrees) {
    return '[$degrees° o]';
  }

  @override
  String get cmdPrintPrint => '[Þŕîñţ ÞÐƑ one]';

  @override
  String get printPreviewTitle => '[Þŕîñţ þŕéṽîéŵ one t]';

  @override
  String printPreviewTitleWithName(String name) {
    return '[Þŕîñţ þŕéṽîéŵ — $name one t]';
  }

  @override
  String get printBack => '[Ɓåçķ ţö ţĥé þŕéšéñţåţîöñ one two]';

  @override
  String get printDownloadPdf => '[Ðöŵñļöåð ÞÐƑ one]';

  @override
  String get printPrint => '[Þŕîñţ on]';

  @override
  String get printSettings => '[Šéţţîñĝš one]';

  @override
  String get printShowPreview => '[Šĥöŵ þŕéṽîéŵ one]';

  @override
  String printPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count þåĝéš',
      one: '1 þåĝé',
    );
    return '[$_temp0 one]';
  }

  @override
  String get printUpdatingPreview => '[Ûþðåţîñĝ þŕéṽîéŵ… one tw]';

  @override
  String get printLoadingDeck => '[Ļöåðîñĝ þŕéšéñţåţîöñ… one two]';

  @override
  String get printPreviewFailed =>
      '[Ţĥé þŕéṽîéŵ çöûļð ñöţ ƀé çŕéåţéð one two th]';

  @override
  String get printTryAgain => '[Ţŕý åĝåîñ one]';

  @override
  String get printDownloadsDisabledTitle =>
      '[Ðöŵñļöåðš åŕé ţûŕñéð öƒƒ one two]';

  @override
  String get printDownloadsDisabledBody =>
      '[Ţĥé öŵñéŕ ĥåš ţûŕñéð öƒƒ ðöŵñļöåðîñĝ åñð þŕîñţîñĝ ƒöŕ ṽîéŵéŕš åñð çöɱɱéñţéŕš. one two three four five]';

  @override
  String get printUnavailableTitle =>
      '[Þŕîñţîñĝ îšñ\'ţ åṽåîļåƀļé ĥéŕé one two th]';

  @override
  String get printUnavailableBody =>
      '[Ðöŵñļöåð ţĥé ÞÐƑ åñð þŕîñţ îţ ƒŕöɱ ýöûŕ ÞÐƑ ṽîéŵéŕ. one two three f]';

  @override
  String get printPdfPreviewLabel => '[ÞÐƑ þŕéṽîéŵ one]';

  @override
  String get printPdfReady => '[Ţĥé ÞÐƑ îš ŕéåðý one t]';

  @override
  String printPdfReadyPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ţĥé ÞÐƑ îš ŕéåðý: $count þåĝéš',
      one: 'Ţĥé ÞÐƑ îš ŕéåðý: 1 þåĝé',
    );
    return '[$_temp0 one two three]';
  }

  @override
  String get printPdfDesktopHint =>
      '[Ðöŵñļöåð ţĥé ÞÐƑ ţö ṽîéŵ öŕ þŕîñţ îţ. one two thr]';

  @override
  String get printLayout => '[Ļåýöûţ one]';

  @override
  String get printLayoutSlides => '[Šļîðéš one]';

  @override
  String get printLayoutNotes => '[Ñöţéš þåĝéš one]';

  @override
  String get printLayoutHandouts => '[Ĥåñðöûţš one]';

  @override
  String get printPerPage => '[Šļîðéš þéŕ þåĝé one t]';

  @override
  String get printOrder => '[Öŕðéŕ on]';

  @override
  String get printOrderHorizontal => '[Åçŕöšš, ţĥéñ ðöŵñ one tw]';

  @override
  String get printOrderVertical => '[Ðöŵñ, ţĥéñ åçŕöšš one tw]';

  @override
  String get printRange => '[Šļîðéš ţö þŕîñţ one t]';

  @override
  String get printRangeAll => '[Åļļ šļîðéš one]';

  @override
  String get printRangeCurrent => '[Çûŕŕéñţ šļîðé one t]';

  @override
  String get printRangeSelection => '[Šéļéçţéð šļîðéš one t]';

  @override
  String get printRangeCustom => '[Çûšţöɱ ŕåñĝé one]';

  @override
  String get printRangeHint => '[é.ĝ. 1-3, 7 one]';

  @override
  String get printRangeInvalid =>
      '[Éñţéŕ šļîðé ñûɱƀéŕš ļîķé 1-3, 7 one two th]';

  @override
  String get printPaper => '[Þåþéŕ on]';

  @override
  String get printPaperSlide => '[Šļîðé šîžé one]';

  @override
  String get printPaperLetter => '[Ļéţţéŕ one]';

  @override
  String get printPaperLegal => '[Ļéĝåļ on]';

  @override
  String get printPaperTabloid => '[Ţåƀļöîð one]';

  @override
  String get printOrientation => '[Öŕîéñţåţîöñ one]';

  @override
  String get printOrientationAuto => '[Åûţöɱåţîç one]';

  @override
  String get printOrientationPortrait => '[Þöŕţŕåîţ one]';

  @override
  String get printOrientationLandscape => '[Ļåñðšçåþé one]';

  @override
  String get printMargins => '[Ṁåŕĝîñš one]';

  @override
  String get printMarginsNone => '[Ñöñé on]';

  @override
  String get printMarginsNarrow => '[Ñåŕŕöŵ one]';

  @override
  String get printMarginsNormal => '[Ñöŕɱåļ one]';

  @override
  String get printBuilds => '[Þŕîñţ éåçĥ ƀûîļð šţåĝé one two]';

  @override
  String get printFinalState => '[Šĥöŵ ƒîñåļ åñîɱåţîöñ šţåţé one two t]';

  @override
  String get pngDialogTitle => '[Ðöŵñļöåð ÞÑĜ one]';

  @override
  String get pngDialogHint =>
      '[Šéṽéŕåļ îɱåĝéš ðöŵñļöåð åš öñé .žîþ ƒîļé. one two three]';

  @override
  String get pngSlides => '[Šļîðéš one]';

  @override
  String get pngSlidesCurrent => '[Çûŕŕéñţ šļîðé one t]';

  @override
  String get pngSlidesSelection => '[Šéļéçţéð šļîðéš one t]';

  @override
  String get pngSlidesAll => '[Åļļ šļîðéš one]';

  @override
  String get pngSize => '[Šîžé on]';

  @override
  String pngSizeOption(int scale, int width, int height) {
    return '[$scale× · $width × $height þẋ on]';
  }

  @override
  String get pngFrames => '[Ɓûîļðš one]';

  @override
  String get pngFramesPrint => '[Åļļ çöñţéñţ (åš þŕîñţéð) one two]';

  @override
  String get pngFramesFinal => '[Åƒţéŕ ţĥé ļåšţ ƀûîļð one tw]';

  @override
  String get pngFramesBuilds =>
      '[Éåçĥ ƀûîļð šţåĝé (öñé îɱåĝé þéŕ šţéþ) one two thr]';

  @override
  String get pngTransparent => '[Ţŕåñšþåŕéñţ ƀåçķĝŕöûñð one two]';

  @override
  String get pngDownload => '[Ðöŵñļöåð one]';

  @override
  String pngEntrySlide(String number) {
    return '[Šļîðé $number on]';
  }

  @override
  String pngEntryStep(String number, int step) {
    return '[Šļîðé $number, šţéþ $step one]';
  }

  @override
  String get pngNothingToExport => '[Ţĥéŕé åŕé ñö šļîðéš ţö éẋþöŕţ one two t]';

  @override
  String get printSkipped => '[Îñçļûðé šķîþþéð šļîðéš one two]';

  @override
  String get printFrame => '[Ƒŕåɱé šļîðéš one]';

  @override
  String get printHeaderFooter => '[Ĥéåðéŕ åñð ƒööţéŕ one tw]';

  @override
  String get printSlideNumbers => '[Šļîðé ñûɱƀéŕš one t]';

  @override
  String get printBookmarks =>
      '[Ɓööķɱåŕķš ƒöŕ šéçţîöñš åñð šļîðéš one two thr]';

  @override
  String get printLinks => '[Çļîçķåƀļé ļîñķš one t]';

  @override
  String get printInkSaver => '[Îñķ šåṽéŕ (ñö šļîðé ƀåçķĝŕöûñðš) one two th]';

  @override
  String get printQuality => '[Îɱåĝé ǫûåļîţý one t]';

  @override
  String get printQualityHigh => '[Ĥîĝĥ on]';

  @override
  String get printQualityCompact => '[Çöɱþåçţ (šɱåļļéŕ ƒîļé) one two]';

  @override
  String get printWarnings => '[Åƀöûţ ţĥîš ÞÐƑ one t]';

  @override
  String get printWarningFonts =>
      '[Å ƒöñţ çöûļð ñöţ ƀé éɱƀéððéð; å šţåñðåŕð ƒöñţ ŵåš ûšéð. one two three fo]';

  @override
  String get printWarningGlyphs =>
      '[Šöɱé çĥåŕåçţéŕš ĥåṽé ñö ĝļýþĥ îñ ţĥé éɱƀéððéð ƒöñţš. one two three fo]';

  @override
  String get printWarningIcons => '[Šöɱé îçöñš çöûļð ñöţ ƀé ðŕåŵñ. one two t]';

  @override
  String get printWarningImages =>
      '[Šöɱé îɱåĝéš çöûļð ñöţ ƀé ļöåðéð. one two th]';

  @override
  String get printWarningLinks =>
      '[Ļîñķš ţö šļîðéš ţĥåţ åŕé ñöţ þŕîñţéð ŵéŕé ŕéɱöṽéð. one two three f]';

  @override
  String get printWarningPages =>
      '[Öñļý ţĥé ƒîŕšţ 500 þåĝéš ŵéŕé éẋþöŕţéð. one two thre]';

  @override
  String get printWarningEmpty =>
      '[Ñö šļîðéš ɱåţçĥ ţĥéšé šéţţîñĝš. one two th]';

  @override
  String exportedToast(String name) {
    return '[Éẋþöŕţéð “$name” one]';
  }

  @override
  String get exportFailed => '[Ţĥé éẋþöŕţ ƒåîļéð one tw]';

  @override
  String get exportFormatUnavailable =>
      '[Ţĥîš ƒöŕɱåţ îš ñöţ åṽåîļåƀļé ýéţ one two th]';

  @override
  String pdfSlide(int number) {
    return '[Šļîðé $number on]';
  }

  @override
  String pdfNotesContinued(int number) {
    return '[Ñöţéš (çöñţîñûéð) — Šļîðé $number one two]';
  }

  @override
  String pdfPageOf(int page, int count) {
    return '[Þåĝé $page öƒ $count one]';
  }

  @override
  String get pdfUntitledSection => '[Ûñţîţļéð šéçţîöñ one tw]';

  @override
  String get pdfUntitledPresentation => '[Ûñţîţļéð þŕéšéñţåţîöñ one two]';

  @override
  String get cmdGroupRename => '[Ŕéñåɱé ĝŕöûþ one]';

  @override
  String get cmdGroupMove => '[Ṁöṽé ĝŕöûþ one]';

  @override
  String get cmdGroupToggleCollapsed => '[Çöļļåþšé öŕ éẋþåñð ĝŕöûþ one two]';

  @override
  String get cmdNavSelectAllSlides => '[Šéļéçţ åļļ šļîðéš one tw]';

  @override
  String get cmdNavigatorCopy => '[Çöþý šļîðéš one]';

  @override
  String get cmdNavigatorCut => '[Çûţ šļîðéš one]';

  @override
  String get cmdNavigatorPaste => '[Þåšţé šļîðéš one]';

  @override
  String get cmdNotesZoom => '[Šþéåķéŕ ñöţéš žööɱ one tw]';

  @override
  String cmdSlideDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðéļéţé $count šļîðéš',
      one: 'Ðéļéţé šļîðé',
    );
    return '[$_temp0 one two t]';
  }

  @override
  String cmdSlideDuplicateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðûþļîçåţé $count šļîðéš',
      one: 'Ðûþļîçåţé šļîðé',
    );
    return '[$_temp0 one two thr]';
  }

  @override
  String get cmdEditNotes => '[Éðîţ šþéåķéŕ ñöţéš one tw]';

  @override
  String get reasonSelectSlides =>
      '[Šéļéçţ šļîðéš îñ ţĥé ñåṽîĝåţöŕ one two th]';

  @override
  String get reasonAlreadyGroup =>
      '[Ţĥéšé šļîðéš åŕé åļŕéåðý å ĝŕöûþ one two th]';

  @override
  String get reasonSkippedWithGroup => '[Šķîþþéð ŵîţĥ ĝŕöûþ one tw]';

  @override
  String get reasonNotInGroup => '[Ţĥé šļîðé îšñ’ţ îñ å ĝŕöûþ one two]';

  @override
  String get reasonNoGroups => '[Ţĥé þŕéšéñţåţîöñ ĥåš ñö ĝŕöûþš one two th]';

  @override
  String get reasonGroupsCantNest => '[Ĝŕöûþš çåñ’ţ ƀé ñéšţéð one two]';

  @override
  String get reasonCantMoveFurther =>
      '[Ţĥé šļîðéš çåñ’ţ ɱöṽé ƒûŕţĥéŕ one two t]';

  @override
  String get reasonClipboardNoSlides =>
      '[Çöþý šļîðéš öŕ ĝŕöûþš ƒîŕšţ one two t]';

  @override
  String get reasonAllCollapsed =>
      '[Ţĥé ĝŕöûþ îš åļŕéåðý çöļļåþšéð one two th]';

  @override
  String get reasonAllExpanded => '[Ţĥé ĝŕöûþ îš åļŕéåðý éẋþåñðéð one two t]';

  @override
  String get navigatorDropHere => '[Ðŕöþ šļîðéš ĥéŕé one t]';

  @override
  String get navigatorNewSlideLayout => '[Ñéŵ šļîðé ŵîţĥ ļåýöûţ one two]';

  @override
  String navigatorDragSlides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš',
      one: '1 šļîðé',
    );
    return '[$_temp0 one t]';
  }

  @override
  String navigatorDragGroup(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš',
      one: '1 šļîðé',
    );
    return '[$title · $_temp0 one t]';
  }

  @override
  String get navigatorGroupExpanded => '[éẋþåñðéð one]';

  @override
  String get navigatorGroupCollapsed => '[çöļļåþšéð one]';

  @override
  String get navigatorSkipped => '[šķîþþéð one]';

  @override
  String navigatorSlideInGroupSemantics(
    int number,
    int total,
    String group,
    String title,
  ) {
    return '[Šļîðé $number öƒ $total, îñ ĝŕöûþ $group: $title one tw]';
  }

  @override
  String get navigatorGroupMenu => '[Ĝŕöûþ åçţîöñš one t]';

  @override
  String get navigatorSlideMenu => '[Šļîðé åçţîöñš one t]';

  @override
  String get navigatorCollapseGroup =>
      '[Çöļļåþšé ĝŕöûþ (Åļţ+çļîçķ: åļļ ĝŕöûþš) one two thre]';

  @override
  String get navigatorExpandGroup =>
      '[Éẋþåñð ĝŕöûþ (Åļţ+çļîçķ: åļļ ĝŕöûþš) one two thre]';

  @override
  String get navigatorGroupColor => '[Ĝŕöûþ çöļöŕ one]';

  @override
  String get navigatorRenameField => '[Ĝŕöûþ ñåɱé one]';

  @override
  String get navigatorSkippedWithGroup => '[Šķîþþéð ŵîţĥ ĝŕöûþ one tw]';

  @override
  String deleteGroupTitle(String title) {
    return '[Ðéļéţé ĝŕöûþ ‘$title’? one t]';
  }

  @override
  String deleteGroupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ţĥé ĝŕöûþ çöñţåîñš $count šļîðéš.',
      one: 'Ţĥé ĝŕöûþ çöñţåîñš 1 šļîðé.',
    );
    return '[$_temp0 one two three fou]';
  }

  @override
  String deleteGroupsTitle(int count) {
    return '[Ðéļéţé $count ĝŕöûþš? one t]';
  }

  @override
  String get deleteGroupUngroupOnly => '[Ûñĝŕöûþ öñļý one]';

  @override
  String deleteGroupWithSlides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðéļéţé ĝŕöûþ åñð $count šļîðéš',
      one: 'Ðéļéţé ĝŕöûþ åñð 1 šļîðé',
    );
    return '[$_temp0 one two three]';
  }

  @override
  String get toastGroupDeleted => '[Ĝŕöûþ ðéļéţéð one t]';

  @override
  String get chooseGroupTitle => '[Åðð ţö ĝŕöûþ one]';

  @override
  String get chooseGroupLabel => '[Ĝŕöûþ on]';

  @override
  String get chooseGroupButton => '[Åðð on]';

  @override
  String get gridThumbSize => '[Ţĥûɱƀñåîļ šîžé one t]';

  @override
  String get gridOpenHint => '[Ðöûƀļé-çļîçķ å šļîðé ţö öþéñ îţ one two th]';

  @override
  String get notesBold => '[Ɓöļð on]';

  @override
  String get notesItalic => '[Îţåļîç one]';

  @override
  String get notesUnderline => '[Ûñðéŕļîñé one]';

  @override
  String get notesBulletList => '[Ɓûļļéţéð ļîšţ one t]';

  @override
  String get notesNumberedList => '[Ñûɱƀéŕéð ļîšţ one t]';

  @override
  String get notesLink => '[Ļîñķ on]';

  @override
  String get notesLinkTitle => '[Ļîñķ on]';

  @override
  String get notesLinkUrl => '[ÛŔĻ on]';

  @override
  String get notesLinkApply => '[Åþþļý on]';

  @override
  String get notesLinkRemove => '[Ŕéɱöṽé ļîñķ one]';

  @override
  String get notesLinkInvalid => '[Éñţéŕ åñ ĥţţþ öŕ ĥţţþš åððŕéšš one two t]';

  @override
  String get notesReadOnly => '[Ṽîéŵ öñļý one]';

  @override
  String get notesNoSlide => '[Ñö šļîðé šéļéçţéð one tw]';

  @override
  String get undoTyping => '[Ţýþîñĝ one]';

  @override
  String get dialogApply => '[Åþþļý on]';

  @override
  String get linkDialogTitle => '[Ļîñķ on]';

  @override
  String get linkTargetLabel => '[Ļîñķ ţö one]';

  @override
  String get linkTargetUrl => '[Ŵéƀ åððŕéšš one]';

  @override
  String get linkUrlLabel => '[Åððŕéšš one]';

  @override
  String get linkRemove => '[Ŕéɱöṽé ļîñķ one]';

  @override
  String get linkActionNext => '[Ñéẋţ šļîðé one]';

  @override
  String get linkActionPrevious => '[Þŕéṽîöûš šļîðé one t]';

  @override
  String get linkActionFirst => '[Ƒîŕšţ šļîðé one]';

  @override
  String get linkActionLast => '[Ļåšţ šļîðé one]';

  @override
  String get linkActionEnd => '[Éñð šĥöŵ one]';

  @override
  String get fontLabel => '[Ƒöñţ on]';

  @override
  String get fontSizeLabel => '[Šîžé on]';

  @override
  String get colorLabel =>
      '[Çöļöŕ (#ŔŔĜĜƁƁ öŕ ţĥéɱé:åççéñţ1; éɱþţý = åûţöɱåţîç) one two three fo]';

  @override
  String get lineHeightLabel => '[Ļîñé šþåçîñĝ one]';

  @override
  String get listStyleLabel => '[Šţýļé on]';

  @override
  String get listStartLabel => '[Šţåŕţ ñûɱƀéŕîñĝ åţ one tw]';

  @override
  String get fontThemeHeading => '[Ţĥéɱé ĥéåðîñĝ ƒöñţ one tw]';

  @override
  String get fontThemeBody => '[Ţĥéɱé ƀöðý ƒöñţ one t]';

  @override
  String get fontThemeMono => '[Ţĥéɱé ɱöñöšþåçé ƒöñţ one two]';

  @override
  String get listStyleDisc => '[Ðîšç on]';

  @override
  String get listStyleCircle => '[Çîŕçļé one]';

  @override
  String get listStyleSquare => '[Šǫûåŕé one]';

  @override
  String get listStyleDash => '[Ðåšĥ on]';

  @override
  String get listStyleArrow => '[Åŕŕöŵ on]';

  @override
  String get listStyleCheck => '[Çĥéçķ ɱåŕķ one]';

  @override
  String get listStyleStar => '[Šţåŕ on]';

  @override
  String get listStyleNone => '[Ñö ƀûļļéţ one]';

  @override
  String get cmdFormatLetterSpacing => '[Ļéţţéŕ šþåçîñĝ one t]';

  @override
  String get cmdFormatInsets => '[Ţéẋţ îñšéţš one]';

  @override
  String get cmdTextExitEditing => '[Éẋîţ ţéẋţ éðîţîñĝ one tw]';

  @override
  String get cmdTextRemoveLink => '[Ŕéɱöṽé ļîñķ ƒŕöɱ ţéẋţ one two]';

  @override
  String get reasonNotEditingText => '[Ñö ţéẋţ îš ƀéîñĝ éðîţéð one two]';

  @override
  String get reasonSelectText => '[Šéļéçţ ţéẋţ öŕ å ţéẋţ ƀöẋ one two]';

  @override
  String get reasonSelectTextOrObject => '[Šéļéçţ ţéẋţ öŕ åñ öƀĵéçţ one two]';

  @override
  String get reasonNoLink => '[Ţĥé šéļéçţîöñ ĥåš ñö ļîñķ one two]';

  @override
  String get reasonSelectPlaceholder => '[Šéļéçţ å þļåçéĥöļðéŕ one two]';

  @override
  String toastSkippedLocked(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šķîþþéð $count ţéẋţ ƀöẋéš öţĥéŕš åŕé éðîţîñĝ',
      one: 'Šķîþþéð 1 ţéẋţ ƀöẋ $name îš éðîţîñĝ',
    );
    return '[$_temp0 one two three four f]';
  }

  @override
  String validationNumberRange(String min, String max) {
    return '[Éñţéŕ å ñûɱƀéŕ ƒŕöɱ $min ţö $max one two]';
  }

  @override
  String slideNumberLabel(int number) {
    return '[Šļîðé $number on]';
  }

  @override
  String get themeColorBg1 => '[Ɓåçķĝŕöûñð 1 one]';

  @override
  String get themeColorBg2 => '[Ɓåçķĝŕöûñð 2 one]';

  @override
  String get themeColorText1 => '[Ţéẋţ 1 on]';

  @override
  String get themeColorText2 => '[Ţéẋţ 2 on]';

  @override
  String themeColorAccent(int n) {
    return '[Åççéñţ $n one]';
  }

  @override
  String get themeColorLink => '[Ļîñķ on]';

  @override
  String shapeName(String geometry) {
    String _temp0 = intl.Intl.selectLogic(geometry, {
      'rect': 'Ŕéçţåñĝļé',
      'roundRect': 'Ŕöûñðéð ŕéçţåñĝļé',
      'ellipse': 'Éļļîþšé',
      'triangle': 'Ţŕîåñĝļé',
      'rightTriangle': 'Ŕîĝĥţ ţŕîåñĝļé',
      'diamond': 'Ðîåɱöñð',
      'pentagon': 'Þéñţåĝöñ',
      'hexagon': 'Ĥéẋåĝöñ',
      'octagon': 'Öçţåĝöñ',
      'parallelogram': 'Þåŕåļļéļöĝŕåɱ',
      'trapezoid': 'Ţŕåþéžöîð',
      'donut': 'Ðöñûţ',
      'arc': 'Åŕç',
      'blockArc': 'Ɓļöçķ åŕç',
      'pie': 'Þîé',
      'chord': 'Çĥöŕð',
      'frame': 'Ƒŕåɱé',
      'halfFrame': 'Ĥåļƒ ƒŕåɱé',
      'plus': 'Þļûš',
      'cross': 'Çŕöšš',
      'cylinder': 'Çýļîñðéŕ',
      'cube': 'Çûƀé',
      'can': 'Çåñ',
      'heart': 'Ĥéåŕţ',
      'cloud': 'Çļöûð',
      'moon': 'Ṁööñ',
      'sun': 'Šûñ',
      'lightning': 'Ļîĝĥţñîñĝ ƀöļţ',
      'arrowRight': 'Ŕîĝĥţ åŕŕöŵ',
      'arrowLeft': 'Ļéƒţ åŕŕöŵ',
      'arrowUp': 'Ûþ åŕŕöŵ',
      'arrowDown': 'Ðöŵñ åŕŕöŵ',
      'arrowLeftRight': 'Ļéƒţ-ŕîĝĥţ åŕŕöŵ',
      'arrowUpDown': 'Ûþ-ðöŵñ åŕŕöŵ',
      'chevron': 'Çĥéṽŕöñ',
      'homePlate': 'Þéñţåĝöñ åŕŕöŵ',
      'notchedArrow': 'Ñöţçĥéð åŕŕöŵ',
      'curvedArrow': 'Çûŕṽéð åŕŕöŵ',
      'circularArrow': 'Çîŕçûļåŕ åŕŕöŵ',
      'uTurn': 'Û-ţûŕñ åŕŕöŵ',
      'star4': '4-þöîñţ šţåŕ',
      'star5': '5-þöîñţ šţåŕ',
      'star6': '6-þöîñţ šţåŕ',
      'star8': '8-þöîñţ šţåŕ',
      'star12': '12-þöîñţ šţåŕ',
      'burst': 'Ɓûŕšţ',
      'ribbon': 'Ŕîƀƀöñ',
      'wave': 'Ŵåṽé',
      'seal': 'Šéåļ',
      'speech': 'Šþééçĥ ƀûƀƀļé',
      'speechRound': 'Ŕöûñð šþééçĥ ƀûƀƀļé',
      'thought': 'Ţĥöûĝĥţ ƀûƀƀļé',
      'calloutRect': 'Ŕéçţåñĝûļåŕ çåļļöûţ',
      'calloutLine': 'Ļîñé çåļļöûţ',
      'banner': 'Ɓåññéŕ',
      'process': 'Þŕöçéšš',
      'decision': 'Ðéçîšîöñ',
      'terminator': 'Ţéŕɱîñåţöŕ',
      'document': 'Ðöçûɱéñţ',
      'data': 'Ðåţå',
      'manualInput': 'Ṁåñûåļ îñþûţ',
      'predefinedProcess': 'Þŕéðéƒîñéð þŕöçéšš',
      'connector': 'Çöññéçţöŕ',
      'offPage': 'Öƒƒ-þåĝé çöññéçţöŕ',
      'delay': 'Ðéļåý',
      'storage': 'Šţöŕéð ðåţå',
      'brace': 'Ɓŕåçé',
      'bracket': 'Ɓŕåçķéţ',
      'doubleBrace': 'Ðöûƀļé ƀŕåçé',
      'custom': 'Çûšţöɱ šĥåþé',
      'other': 'Šĥåþé',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four fiv]';
  }

  @override
  String shapeCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'basic': 'Ɓåšîç šĥåþéš',
      'arrows': 'Åŕŕöŵš',
      'stars': 'Šţåŕš åñð ƀåðĝéš',
      'callouts': 'Çåļļöûţš',
      'flowchart': 'Ƒļöŵçĥåŕţ',
      'brackets': 'Ɓŕåçķéţš',
      'custom': 'Çûšţöɱ',
      'other': 'Šĥåþéš',
    });
    return '[$_temp0 one two three four five]';
  }

  @override
  String iconCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'all': 'Åļļ îçöñš',
      'recent': 'Ŕéçéñţļý ûšéð',
      'arrows': 'Åŕŕöŵš',
      'business': 'Ɓûšîñéšš',
      'charts': 'Çĥåŕţš',
      'communication': 'Çöɱɱûñîçåţîöñ',
      'devices': 'Ðéṽîçéš',
      'development': 'Ðéṽéļöþɱéñţ',
      'files': 'Ƒîļéš',
      'food': 'Ƒööð åñð ðŕîñķ',
      'media': 'Ṁéðîå',
      'nature': 'Ñåţûŕé',
      'people': 'Þéöþļé',
      'security': 'Šéçûŕîţý',
      'shapes': 'Šĥåþéš',
      'text': 'Ţéẋţ',
      'clock': 'Ţîɱé',
      'tools': 'Ţööļš',
      'travel': 'Ţŕåṽéļ',
      'weather': 'Ŵéåţĥéŕ',
      'other': 'Îçöñš',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one]';
  }

  @override
  String arrowStyleName(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'none': 'Ñöñé',
      'triangle': 'Åŕŕöŵ',
      'open': 'Öþéñ åŕŕöŵ',
      'stealth': 'Šţéåļţĥ åŕŕöŵ',
      'circle': 'Çîŕçļé',
      'diamond': 'Ðîåɱöñð',
      'bar': 'Ɓåŕ',
      'other': 'Åŕŕöŵ',
    });
    return '[$_temp0 one two three four]';
  }

  @override
  String arrowSizeName(String size) {
    String _temp0 = intl.Intl.selectLogic(size, {
      's': 'Šɱåļļ',
      'm': 'Ṁéðîûɱ',
      'l': 'Ļåŕĝé',
      'other': 'Ṁéðîûɱ',
    });
    return '[$_temp0 one two]';
  }

  @override
  String dashName(String dash) {
    String _temp0 = intl.Intl.selectLogic(dash, {
      'solid': 'Šöļîð',
      'dash': 'Ðåšĥéð',
      'dot': 'Ðöţţéð',
      'dashDot': 'Ðåšĥ-ðöţ',
      'longDash': 'Ļöñĝ ðåšĥ',
      'other': 'Šöļîð',
    });
    return '[$_temp0 one two three]';
  }

  @override
  String capName(String cap) {
    String _temp0 = intl.Intl.selectLogic(cap, {
      'butt': 'Ƒļåţ',
      'round': 'Ŕöûñð',
      'square': 'Šǫûåŕé',
      'other': 'Ƒļåţ',
    });
    return '[$_temp0 one two]';
  }

  @override
  String routingName(String routing) {
    String _temp0 = intl.Intl.selectLogic(routing, {
      'straight': 'Šţŕåîĝĥţ',
      'elbow': 'Éļƀöŵ',
      'curved': 'Çûŕṽéð',
      'other': 'Šţŕåîĝĥţ',
    });
    return '[$_temp0 one two th]';
  }

  @override
  String quickStyleName(String index) {
    String _temp0 = intl.Intl.selectLogic(index, {
      '0': 'Åççéñţ 1',
      '1': 'Åççéñţ 2',
      '2': 'Åççéñţ 3',
      '3': 'Åççéñţ 4',
      '4': 'Åççéñţ 5',
      '5': 'Åççéñţ 6',
      '6': 'Öûţļîñé',
      '7': 'Šöƒţ ţîñţ',
      'other': 'Šţýļé',
    });
    return '[$_temp0 one two three four fiv]';
  }

  @override
  String strokeWidthLabel(String width) {
    return '[$width þţ o]';
  }

  @override
  String get cmdIconReplace => '[Ŕéþļåçé îçöñ… one t]';

  @override
  String get cmdIconSetStrokeWidth => '[Îçöñ šţŕöķé ŵîðţĥ one tw]';

  @override
  String get cmdElementRename => '[Ŕéñåɱé öƀĵéçţ one t]';

  @override
  String get menuChangeShape => '[Çĥåñĝé šĥåþé one]';

  @override
  String get menuQuickStyles => '[Ǫûîçķ šţýļéš one]';

  @override
  String get menuRouting => '[Ŕöûţîñĝ one]';

  @override
  String get menuWeight => '[Ŵéîĝĥţ one]';

  @override
  String get menuDash => '[Ðåšĥ on]';

  @override
  String get menuBorderColor => '[Ɓöŕðéŕ çöļöŕ one]';

  @override
  String get menuLineColor => '[Ļîñé çöļöŕ one]';

  @override
  String get menuFillColor => '[Ƒîļļ çöļöŕ one]';

  @override
  String get menuIconColor => '[Îçöñ çöļöŕ one]';

  @override
  String get colorThemeDefault => '[Ţĥéɱé ðéƒåûļţ one t]';

  @override
  String get styleLabelColor => '[Çöļöŕ on]';

  @override
  String get styleLabelWeight => '[Ŵéîĝĥţ one]';

  @override
  String get styleLabelDash => '[Ðåšĥ on]';

  @override
  String get styleLabelCap => '[Éñðš on]';

  @override
  String get styleLabelArrowSize => '[Åŕŕöŵ šîžé one]';

  @override
  String get styleLabelRouting => '[Ŕöûţîñĝ one]';

  @override
  String get styleLabelShadow => '[Šĥåðöŵ one]';

  @override
  String get styleLabelGlow => '[Ĝļöŵ on]';

  @override
  String get styleLabelOpacity => '[Öþåçîţý one]';

  @override
  String get styleLabelNoFill => '[Ñö ƒîļļ one]';

  @override
  String get styleLabelNoBorder => '[Ñö ƀöŕðéŕ one]';

  @override
  String get styleLabelGeometry => '[Šĥåþé on]';

  @override
  String get styleLabelStrokeWidth => '[Šţŕöķé ŵîðţĥ one]';

  @override
  String get styleLabelIcon => '[Îçöñ on]';

  @override
  String get styleMixed => '[Ṁîẋéð on]';

  @override
  String get arrangeLabelX => '[Ẋ o]';

  @override
  String get arrangeLabelY => '[Ý o]';

  @override
  String get arrangeLabelW => '[Ŵ o]';

  @override
  String get arrangeLabelH => '[Ĥ o]';

  @override
  String get arrangeLabelRotation => '[Ŕöţåţîöñ one]';

  @override
  String get arrangeLabelName => '[Ñåɱé on]';

  @override
  String get arrangeEditInsideGroup => '[Éðîţ îñšîðé ĝŕöûþ one tw]';

  @override
  String get arrangeLocked => '[Ļöçķéð one]';

  @override
  String get accessibilityAltText => '[Åļţ ţéẋţ one]';

  @override
  String get accessibilityAltTextHint =>
      '[Ðéšçŕîƀé ţĥé öƀĵéçţ ƒöŕ þéöþļé ûšîñĝ šçŕééñ ŕéåðéŕš one two three fo]';

  @override
  String get accessibilityDecorative => '[Ðéçöŕåţîṽé one]';

  @override
  String accessibilityReadingOrder(int position, int count) {
    return '[Ŕéåðîñĝ öŕðéŕ: $position öƒ $count one tw]';
  }

  @override
  String get altTextDialogTitle => '[Åļţ ţéẋţ one]';

  @override
  String get altTextDialogDecorative =>
      '[Ṁåŕķ åš ðéçöŕåţîṽé (šçŕééñ ŕéåðéŕš šķîþ îţ) one two three]';

  @override
  String get dialogSave => '[Šåṽé on]';

  @override
  String get iconPickerTitle => '[Îñšéŕţ îçöñ one]';

  @override
  String get iconPickerReplaceTitle => '[Ŕéþļåçé îçöñ one]';

  @override
  String get iconPickerSearch => '[Šéåŕçĥ îçöñš one]';

  @override
  String iconPickerEmpty(String query) {
    return '[Ñö îçöñš ɱåţçĥ “$query” one t]';
  }

  @override
  String iconPickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count îçöñš',
      one: '1 îçöñ',
    );
    return '[$_temp0 one]';
  }

  @override
  String get iconPickerRecentEmpty =>
      '[Îçöñš ýöû îñšéŕţ šĥöŵ ûþ ĥéŕé one two t]';

  @override
  String get iconPickerStroke => '[Šţŕöķé one]';

  @override
  String get iconPickerColor => '[Çöļöŕ on]';

  @override
  String get iconPickerCategory => '[Çåţéĝöŕý one]';

  @override
  String get iconPickerInsert => '[Îñšéŕţ one]';

  @override
  String get iconPickerReplace => '[Ŕéþļåçé one]';

  @override
  String get shapeGalleryTitle => '[Šĥåþéš one]';

  @override
  String get shapeGalleryChoose => '[Çĥööšé one]';

  @override
  String get reasonSelectShape => '[Šéļéçţ å šĥåþé one t]';

  @override
  String get reasonSelectLine => '[Šéļéçţ å ļîñé one]';

  @override
  String get reasonSelectIcon => '[Šéļéçţ åñ îçöñ one t]';

  @override
  String get reasonSelectOneObject => '[Šéļéçţ öñé öƀĵéçţ one tw]';

  @override
  String get reasonNoFill => '[Šéļéçţ å šĥåþé, ţéẋţ ƀöẋ öŕ îçöñ one two th]';

  @override
  String get reasonNoBorder =>
      '[Šéļéçţ å šĥåþé, ļîñé, ţéẋţ ƀöẋ, îɱåĝé öŕ îçöñ one two three]';

  @override
  String get reasonPlaceholdersCantGroup =>
      '[Þļåçéĥöļðéŕš çåñ\'ţ ƀé ĝŕöûþéð one two th]';

  @override
  String get reasonSameLevel => '[Šéļéçţ öƀĵéçţš îñ ţĥé šåɱé ĝŕöûþ one two th]';

  @override
  String get reasonNoStyleCopied => '[Çöþý å šţýļé ƒîŕšţ one tw]';

  @override
  String get painterArmed =>
      '[Çļîçķ åñ öƀĵéçţ ţö åþþļý ţĥé ƒöŕɱåţ one two thr]';

  @override
  String get toolArmedShape =>
      '[Çļîçķ öŕ ðŕåĝ öñ ţĥé šļîðé ţö îñšéŕţ ţĥé šĥåþé one two three]';

  @override
  String get toolArmedLine => '[Ðŕåĝ öñ ţĥé šļîðé ţö ðŕåŵ ţĥé ļîñé one two th]';

  @override
  String get colorAutomatic => '[Åûţöɱåţîç one]';

  @override
  String get inspectorMixed => '[Ṁîẋéð on]';

  @override
  String get spacingBeforeLabel => '[Šþåçé ƀéƒöŕé one]';

  @override
  String get spacingAfterLabel => '[Šþåçé åƒţéŕ one]';

  @override
  String get reasonSelectImage => '[Šéļéçţ åñ îɱåĝé one t]';

  @override
  String get reasonNoDownload =>
      '[Ðöŵñļöåðîñĝ îšñ\'ţ åļļöŵéð ƒöŕ ţĥîš þŕéšéñţåţîöñ one two three f]';

  @override
  String get reasonSelectTable => '[Šéļéçţ å ţåƀļé one t]';

  @override
  String get reasonSelectCells => '[Šéļéçţ ţåƀļé çéļļš one tw]';

  @override
  String get reasonNoMergedCells =>
      '[Ñö ɱéŕĝéð çéļļš îñ ţĥé šéļéçţîöñ one two th]';

  @override
  String get undoCropImage => '[Çŕöþ îɱåĝé one]';

  @override
  String get cmdImageCropApply => '[Åþþļý çŕöþ one]';

  @override
  String get cmdImageCropCancel => '[Çåñçéļ çŕöþ one]';

  @override
  String get cmdImageRetryUpload => '[Ŕéţŕý ûþļöåð one]';

  @override
  String get cmdImageRemoveNotUploaded => '[Ŕéɱöṽé îɱåĝé one]';

  @override
  String get cmdTableResizeAxes => '[Ŕéšîžé ŕöŵš öŕ çöļûɱñš one two]';

  @override
  String get cmdTableSetCellPadding => '[Çéļļ þåððîñĝ one]';

  @override
  String get cmdTableClearCells => '[Çļéåŕ çéļļš one]';

  @override
  String get cmdTableSelectCells => '[Šéļéçţ çéļļš one]';

  @override
  String get cmdTableMoveSelection => '[Ṁöṽé çéļļ šéļéçţîöñ one tw]';

  @override
  String get cmdTableNextCell => '[Ñéẋţ çéļļ one]';

  @override
  String get cmdTablePreviousCell => '[Þŕéṽîöûš çéļļ one t]';

  @override
  String get cmdTableEditCell => '[Éðîţ çéļļ one]';

  @override
  String get cmdTableClearCellSelection => '[Šéļéçţ ţĥé ŵĥöļé ţåƀļé one two]';

  @override
  String get imageNotAvailable =>
      '[Ţĥîš îɱåĝé îšñ\'ţ åṽåîļåƀļé ŕîĝĥţ ñöŵ. one two thre]';

  @override
  String get imagePickTitle => '[Çĥööšé îɱåĝéš one t]';

  @override
  String get imageClipboardEmpty =>
      '[Ţĥéŕé\'š ñö îɱåĝé öñ ţĥé çļîþƀöåŕð. one two thr]';

  @override
  String get imageUrlInvalid => '[Éñţéŕ åñ ĥţţþš:// îɱåĝé åððŕéšš. one two th]';

  @override
  String get imageFetchFailed => '[Çöûļðñ\'ţ ļöåð ţĥîš îɱåĝé. one two]';

  @override
  String get imageOutOfStorage => '[Ýöû\'ŕé öûţ öƒ šţöŕåĝé. one two]';

  @override
  String imageRejectedTooLarge(String name) {
    return '[Çöûļðñ\'ţ îñšéŕţ \'$name\' — îɱåĝéš çåñ ƀé åţ ɱöšţ 50 ṀƁ. one two three]';
  }

  @override
  String imageRejectedFormat(String name) {
    return '[Çöûļðñ\'ţ îñšéŕţ \'$name\' — ţĥîš îɱåĝé ţýþé îšñ\'ţ šûþþöŕţéð. one two three fo]';
  }

  @override
  String get imageInsertDialogTitle => '[Îñšéŕţ îɱåĝé one]';

  @override
  String get imageReplaceDialogTitle => '[Ŕéþļåçé îɱåĝé one t]';

  @override
  String get imageSourceLabel => '[Šöûŕçé one]';

  @override
  String get dialogContinue => '[Çöñţîñûé one]';

  @override
  String get dialogInsert => '[Îñšéŕţ one]';

  @override
  String get dialogCancel => '[Çåñçéļ one]';

  @override
  String get imageUrlDialogTitle => '[Îñšéŕţ îɱåĝé ƀý ÛŔĻ one tw]';

  @override
  String get imageUrlDialogBody =>
      '[Ţĥé îɱåĝé îš ƒéţçĥéð ţĥŕöûĝĥ Ŵöñķý Ŵöŕķ åñð šţöŕéð ŵîţĥ ţĥé þŕéšéñţåţîöñ. one two three four fiv]';

  @override
  String get imageUrlLabel => '[Îɱåĝé åððŕéšš one t]';

  @override
  String get imageMaskDialogTitle => '[Ṁåšķ ŵîţĥ šĥåþé one t]';

  @override
  String get imageMaskShape => '[Šĥåþé on]';

  @override
  String get imageMaskNone => '[Ñö ɱåšķ one]';

  @override
  String get imageDriveDialogTitle =>
      '[Îñšéŕţ îɱåĝé ƒŕöɱ Ŵöñķý Ðŕîṽé one two t]';

  @override
  String get imageDriveSearch => '[Šéåŕçĥ îɱåĝéš one t]';

  @override
  String get imageDriveImage => '[Îɱåĝé on]';

  @override
  String get imageDriveFailed =>
      '[Çöûļðñ\'ţ ļöåð ýöûŕ îɱåĝéš. Çĥéçķ ýöûŕ çöññéçţîöñ. one two three fo]';

  @override
  String get imageDriveEmpty => '[Ñö îɱåĝéš ƒöûñð. one t]';

  @override
  String get cropAspectFree => '[Ƒŕéé on]';

  @override
  String get cropAspectOriginal => '[Öŕîĝîñåļ one]';

  @override
  String get cropFill => '[Ƒîļļ on]';

  @override
  String get cropFit => '[Ƒîţ on]';

  @override
  String get cropDone => '[Ðöñé on]';

  @override
  String get imageNotUploadedOutOfStorage =>
      '[Ñöţ ûþļöåðéð — öûţ öƒ šţöŕåĝé one two t]';

  @override
  String get imageRetry => '[Ŕéţŕý on]';

  @override
  String get imageRemove => '[Ŕéɱöṽé one]';

  @override
  String tableSizeInvalid(int max) {
    return '[Éñţéŕ å ñûɱƀéŕ ƒŕöɱ 1 ţö $max. one two]';
  }

  @override
  String get tableInsertDialogTitle => '[Îñšéŕţ ţåƀļé one]';

  @override
  String get tableRows => '[Ŕöŵš on]';

  @override
  String get tableColumns => '[Çöļûɱñš one]';

  @override
  String get cmdThemeApply => '[Åþþļý ţĥéɱé one]';

  @override
  String get cmdThemeImport =>
      '[Îɱþöŕţ ţĥéɱé ƒŕöɱ å þŕéšéñţåţîöñ… one two thr]';

  @override
  String get cmdThemeRename => '[Ŕéñåɱé ţĥéɱé… one t]';

  @override
  String get cmdThemeDuplicate => '[Ðûþļîçåţé ţĥéɱé one t]';

  @override
  String get cmdThemeSetDefault => '[Šéţ åš ðéƒåûļţ ţĥéɱé one tw]';

  @override
  String get cmdThemeDelete => '[Ŕéɱöṽé ţĥéɱé one]';

  @override
  String get cmdThemeRemoveUnused => '[Ŕéɱöṽé ûñûšéð ţĥéɱéš one two]';

  @override
  String get cmdDeckSetSize => '[Çĥåñĝé šļîðé šîžé one tw]';

  @override
  String get cmdDeckSetNumbering => '[Šéţ šļîðé ñûɱƀéŕš åñð ƒööţéŕ one two t]';

  @override
  String get undoChangeSlideSize => '[Çĥåñĝé šļîðé šîžé one tw]';

  @override
  String get undoNumbering => '[Šļîðé ñûɱƀéŕš åñð ƒööţéŕ one two]';

  @override
  String get reasonThemeInUse =>
      '[Ûšéð ƀý šļîðéš — åþþļý åñöţĥéŕ ţĥéɱé ţö ţĥéɱ ƒîŕšţ one two three f]';

  @override
  String get reasonThemeIsDefault => '[Åļŕéåðý ţĥé ðéƒåûļţ ţĥéɱé one two]';

  @override
  String get reasonNoUnusedThemes => '[Éṽéŕý ţĥéɱé îš îñ ûšé one tw]';

  @override
  String get themesPanelTitle => '[Ţĥéɱéš one]';

  @override
  String get themesApplyTo => '[Åþþļý ţö one]';

  @override
  String get themesApplyAll => '[Åļļ šļîðéš one]';

  @override
  String themesApplySelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šéļéçţéð šļîðéš ($count)',
      one: 'Šéļéçţéð šļîðé',
    );
    return '[$_temp0 one two thr]';
  }

  @override
  String get themesInPresentation => '[Îñ ţĥîš þŕéšéñţåţîöñ one two]';

  @override
  String get themesBuiltIn => '[Ɓûîļţ-îñ ţĥéɱéš one t]';

  @override
  String get themesImport => '[Îɱþöŕţ ţĥéɱé ƒŕöɱ å þŕéšéñţåţîöñ… one two thr]';

  @override
  String get themesDefault => '[Ðéƒåûļţ one]';

  @override
  String themesUsedBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ûšéð ƀý $count šļîðéš',
      one: 'Ûšéð ƀý 1 šļîðé',
      zero: 'Ñöţ ûšéð',
    );
    return '[$_temp0 one two thr]';
  }

  @override
  String themesMore(String name) {
    return '[Ṁöŕé åçţîöñš ƒöŕ $name one t]';
  }

  @override
  String get themeUntitled => '[Ûñţîţļéð ţĥéɱé one t]';

  @override
  String get themePreviewSubtitle => '[Ţîţļé åñð šûƀţîţļé one tw]';

  @override
  String themeCopyName(String name) {
    return '[$name çöþý on]';
  }

  @override
  String get themeRenameTitle => '[Ŕéñåɱé ţĥéɱé one]';

  @override
  String get themeNameLabel => '[Ñåɱé on]';

  @override
  String get themeNameEmpty => '[Éñţéŕ å ñåɱé one]';

  @override
  String get themeRenameButton => '[Ŕéñåɱé one]';

  @override
  String get themeImportPickTitle =>
      '[Îɱþöŕţ ţĥéɱé ƒŕöɱ å þŕéšéñţåţîöñ one two th]';

  @override
  String get themeImportSearch => '[Šéåŕçĥ þŕéšéñţåţîöñš one two]';

  @override
  String get themeImportPresentation => '[Þŕéšéñţåţîöñ one t]';

  @override
  String get themeImportNoPresentations => '[Ñö öţĥéŕ þŕéšéñţåţîöñš one two]';

  @override
  String get themeImportOffline =>
      '[Çöññéçţ ţö ţĥé îñţéŕñéţ ţö îɱþöŕţ å ţĥéɱé one two thre]';

  @override
  String get themeImportChooseTitle => '[Çĥööšé å ţĥéɱé one t]';

  @override
  String themeImportOption(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš',
      one: '1 šļîðé',
      zero: 'ñöţ ûšéð',
    );
    return '[$name — $_temp0 one two]';
  }

  @override
  String get themeImportButton => '[Îɱþöŕţ one]';

  @override
  String themeImported(String name) {
    return '[Ţĥéɱé “$name” åððéð one t]';
  }

  @override
  String get themeApplyToAll => '[Åþþļý ţö åļļ šļîðéš one tw]';

  @override
  String get backgroundResetToLayout =>
      '[Ŕéšéţ ţö ļåýöûţ ƀåçķĝŕöûñð one two t]';

  @override
  String get pageSetupTitle => '[Þåĝé šéţûþ one]';

  @override
  String get pageSetupPreset => '[Šļîðé šîžé one]';

  @override
  String get pageSetupUnit => '[Ûñîţ on]';

  @override
  String get pageSetupContent => '[Éẋîšţîñĝ çöñţéñţ one tw]';

  @override
  String get pageSetupScale => '[Šçåļé çöñţéñţ ţö ƒîţ one tw]';

  @override
  String get pageSetupDontScale => '[Ðöñ\'ţ šçåļé one]';

  @override
  String get pageSetupPreview => '[Þŕéṽîéŵ one]';

  @override
  String get pageSetupApply => '[Åþþļý on]';

  @override
  String get pageSetupEnterSize => '[Éñţéŕ å ŵîðţĥ åñð å ĥéîĝĥţ. one two]';

  @override
  String get pageSetupSideRange =>
      '[Éåçĥ šîðé ɱûšţ ƀé ƀéţŵééñ 320 åñð 7,680 šû. one two three]';

  @override
  String get pageSetupAspectRange =>
      '[Ţĥé åšþéçţ ŕåţîö ɱûšţ ƀé ƀéţŵééñ 1:4 åñð 4:1. one two three]';

  @override
  String get sizeCustom => '[Çûšţöɱ one]';

  @override
  String get numberingTitle => '[Šļîðé ñûɱƀéŕš åñð ƒööţéŕ one two]';

  @override
  String get numberingShow => '[Šĥöŵ šļîðé ñûɱƀéŕš one tw]';

  @override
  String get numberingFirst => '[Ƒîŕšţ šļîðé ñûɱƀéŕ one tw]';

  @override
  String get numberingFirstInvalid =>
      '[Éñţéŕ å ñûɱƀéŕ ƒŕöɱ 0 ţö 9999 one two t]';

  @override
  String get numberingHideOnTitle => '[Ðöñ\'ţ šĥöŵ öñ ţîţļé šļîðéš one two]';

  @override
  String get numberingFooter => '[Ƒööţéŕ one]';

  @override
  String get numberingFooterHint => '[Éɱþţý = ñö ƒööţéŕ one t]';

  @override
  String get imageUploading => '[Ûþļöåðîñĝ… one]';

  @override
  String get imageAdjustments => '[Åðĵûšţɱéñţš one]';

  @override
  String get imageBrightness => '[Ɓŕîĝĥţñéšš one]';

  @override
  String get imageContrast => '[Çöñţŕåšţ one]';

  @override
  String get imageSaturation => '[Šåţûŕåţîöñ one]';

  @override
  String get imageTemperature => '[Ţéɱþéŕåţûŕé one]';

  @override
  String get imageBlur => '[Ɓļûŕ on]';

  @override
  String get imageGrayscale => '[Ĝŕåýšçåļé one]';

  @override
  String get imageSepia => '[Šéþîå on]';

  @override
  String get imageInvert => '[Îñṽéŕţ one]';

  @override
  String get tableStyle => '[Šţýļé on]';

  @override
  String get tableStyleTheme => '[Ţĥéɱé on]';

  @override
  String get tableStyleNone => '[Ñöñé on]';

  @override
  String get tableHeaderRow => '[Ĥéåðéŕ ŕöŵ one]';

  @override
  String get tableFirstColumn => '[Ƒîŕšţ çöļûɱñ one]';

  @override
  String get tableBandedRows => '[Ɓåñðéð ŕöŵš one]';

  @override
  String get tableBandedColumns => '[Ɓåñðéð çöļûɱñš one t]';

  @override
  String get tableTotalRow => '[Ţöţåļ ŕöŵ one]';

  @override
  String tableCellsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çéļļš šéļéçţéð',
      one: '1 çéļļ šéļéçţéð',
    );
    return '[$_temp0 one two th]';
  }

  @override
  String get tableCellFill => '[Ƒîļļ on]';

  @override
  String get tableStyleFill => '[Ţåƀļé šţýļé one]';

  @override
  String get tableVerticalAlign => '[Åļîĝñ on]';

  @override
  String get tableCellPadding => '[Þåððîñĝ one]';

  @override
  String get tableStyleDefault => '[Ðéƒåûļţ one]';

  @override
  String get tableBorders => '[Ɓöŕðéŕš one]';

  @override
  String tableBorderEdge(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'all': 'Åļļ ƀöŕðéŕš',
      'outer': 'Öûţéŕ ƀöŕðéŕš',
      'inner': 'Îññéŕ ƀöŕðéŕš',
      'horizontal': 'Îññéŕ ĥöŕîžöñţåļ ƀöŕðéŕš',
      'vertical': 'Îññéŕ ṽéŕţîçåļ ƀöŕðéŕš',
      'top': 'Ţöþ ƀöŕðéŕ',
      'bottom': 'Ɓöţţöɱ ƀöŕðéŕ',
      'left': 'Ļéƒţ ƀöŕðéŕ',
      'right': 'Ŕîĝĥţ ƀöŕðéŕ',
      'none': 'Çļéåŕ ƀöŕðéŕš',
      'other': 'Ɓöŕðéŕš',
    });
    return '[$_temp0 one two three four five six seven eight nine ten]';
  }

  @override
  String tableBorderStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'solid': 'Šöļîð',
      'dashed': 'Ðåšĥéð',
      'dotted': 'Ðöţţéð',
      'other': 'Šöļîð',
    });
    return '[$_temp0 one two]';
  }

  @override
  String get cmdPresentEnd => '[Éñð þŕéšéñţåţîöñ one tw]';

  @override
  String get cmdPresentNext => '[Ñéẋţ on]';

  @override
  String get cmdPresentPrevious => '[Þŕéṽîöûš one]';

  @override
  String get cmdPresentNextSlide => '[Ñéẋţ šļîðé one]';

  @override
  String get cmdPresentPreviousSlide => '[Þŕéṽîöûš šļîðé one t]';

  @override
  String get cmdPresentGoTo => '[Ĝö ţö šļîðé one]';

  @override
  String get cmdPresentFirst => '[Ƒîŕšţ šļîðé one]';

  @override
  String get cmdPresentLast => '[Ļåšţ šļîðé one]';

  @override
  String get cmdPresentBlank => '[Ɓļåçķ öŕ ŵĥîţé šçŕééñ one two]';

  @override
  String get cmdPresentPicker => '[Šļîðé þîçķéŕ one]';

  @override
  String get cmdPresentTool => '[Þöîñţéŕ ţööļ one]';

  @override
  String get cmdPresentClearInk => '[Çļéåŕ îñķ öñ ţĥîš šļîðé one two]';

  @override
  String get cmdPresentUndoInk => '[Ûñðö ļåšţ îñķ šţŕöķé one tw]';

  @override
  String get cmdPresentTimer => '[Þŕéšéñţéŕ ţîɱéŕ one t]';

  @override
  String get cmdPresentJoinAsAudience => '[Šĥöŵ åûðîéñçé ṽîéŵ ĥéŕé one two]';

  @override
  String get cmdPresentToggleFullscreen => '[Ƒûļļ šçŕééñ one]';

  @override
  String get cmdPresentToggleSkipped => '[Šĥöŵ šķîþþéð šļîðéš one tw]';

  @override
  String get cmdPresentNotesSize => '[Šþéåķéŕ ñöţéš šîžé one tw]';

  @override
  String get cmdPresentHelp => '[Ķéýƀöåŕð šĥöŕţçûţš one tw]';

  @override
  String get cmdDeckSetPresentSettings => '[Þŕéšéñţåţîöñ šéţţîñĝš one two]';

  @override
  String get reasonNotPresenting => '[Ñöţ þŕéšéñţîñĝ one t]';

  @override
  String get reasonPresenterViewOnly => '[Öñļý îñ ţĥé þŕéšéñţéŕ ṽîéŵ one two]';

  @override
  String get presentUnknownSlide =>
      '[Ţĥåţ šļîðé îšñ’ţ îñ ţĥîš þŕéšéñţåţîöñ one two thre]';

  @override
  String presentSlideLabel(int number, int total) {
    return '[Šļîðé $number öƒ $total one]';
  }

  @override
  String get presentEndScreen =>
      '[Éñð öƒ þŕéšéñţåţîöñ — çļîçķ ţö éẋîţ one two thr]';

  @override
  String get presentKioskExitHold => '[Ķééþ ĥöļðîñĝ Éšç ţö éẋîţ one two]';

  @override
  String get presenterReducedEffects => '[Ŕéðûçéð éƒƒéçţš one t]';

  @override
  String get presentCatchingUp => '[Çåţçĥîñĝ ûþ… one]';

  @override
  String get presentToolbarLabel => '[Þŕéšéñţåţîöñ çöñţŕöļš one two]';

  @override
  String presentCounterLabel(int number, int total) {
    return '[Šļîðé $number öƒ $total. Öþéñ ţĥé šļîðé þîçķéŕ one two th]';
  }

  @override
  String get presentToolLaser => '[Ļåšéŕ þöîñţéŕ one t]';

  @override
  String get presentToolPen => '[Þéñ on]';

  @override
  String get presentToolHighlighter => '[Ĥîĝĥļîĝĥţéŕ one]';

  @override
  String get presentToolEraser => '[Éŕåšéŕ one]';

  @override
  String get presentBlackScreen => '[Ɓļåçķ šçŕééñ one]';

  @override
  String get presentWhiteScreen => '[Ŵĥîţé šçŕééñ one]';

  @override
  String get presentEnd => '[Éñð on]';

  @override
  String presentGoToNumber(String number) {
    return '[Ĝö ţö $number on]';
  }

  @override
  String get presentHelpTitle => '[Þŕéšéñţîñĝ šĥöŕţçûţš one two]';

  @override
  String get presentHelpGoToNumber => '[Ĝö ţö šļîðé ñûɱƀéŕ one tw]';

  @override
  String get presentHelpDigits => '[1 2 3 … Éñţéŕ one]';

  @override
  String get presentHelpTemporaryLaser =>
      '[Ļåšéŕ ŵĥîļé ĥéļð (ɱöṽé ţĥé ɱöûšé) one two th]';

  @override
  String get presentTimerPause => '[Þåûšé öŕ ŕéšûɱé ţĥé ţîɱéŕ one two]';

  @override
  String get presentTimerResume => '[Ŕéšûɱé ţĥé ţîɱéŕ one t]';

  @override
  String get presentTimerReset => '[Ŕéšéţ ţĥé ţîɱéŕ one t]';

  @override
  String get presentNotesLarger => '[Ļåŕĝéŕ ñöţéš one]';

  @override
  String get presentNotesSmaller => '[Šɱåļļéŕ ñöţéš one t]';

  @override
  String get presentResume => '[Ŕéšûɱé (çļîçķéŕ Ƒ5) one tw]';

  @override
  String get presentFullscreenHint =>
      '[Þŕéšš Ƒ11 (⌃⌘Ƒ öñ Ṁåç) ƒöŕ ƒûļļ šçŕééñ one two thr]';

  @override
  String get presentFullscreenButton => '[Ƒûļļ šçŕééñ one]';

  @override
  String get presentAudienceTitle => '[Åûðîéñçé ṽîéŵ one t]';

  @override
  String get presentAudienceBody =>
      '[Ţĥîš šçŕééñ šĥöŵš ţĥé šļîðéš öƒ ýöûŕ þŕéšéñţåţîöñ. one two three fo]';

  @override
  String presentAudienceBodyFrom(String device) {
    return '[Ţĥîš šçŕééñ šĥöŵš ţĥé šļîðéš ýöû þŕéšéñţ öñ $device. one two three]';
  }

  @override
  String get presentAudienceKeys =>
      '[Å çļîçķéŕ öŕ ţĥé åŕŕöŵ ķéýš ĥéŕé åļšö ɱöṽé ţĥé þŕéšéñţåţîöñ. one two three four]';

  @override
  String get presentAudienceStay => '[Šţåý îñ ŵîñðöŵ one t]';

  @override
  String get presentGoToSlideMenu => '[Ĝö ţö šļîðé… one]';

  @override
  String get presentPickerTitle => '[Ĝö ţö šļîðé one]';

  @override
  String get presentPickerFilter => '[Ƒîļţéŕ ƀý ţîţļé öŕ ñûɱƀéŕ one two]';

  @override
  String get presentPickerClose => '[Çļöšé on]';

  @override
  String get presentPickerNoMatch => '[Ñö šļîðéš ɱåţçĥ one t]';

  @override
  String presentPickerGroup(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš',
      one: '1 šļîðé',
    );
    return '[$title, $_temp0 one t]';
  }

  @override
  String presentPickerSlide(int number, String title) {
    return '[Šļîðé $number: $title one]';
  }

  @override
  String get presentPickerSkipped => '[Šķîþþéð one]';

  @override
  String get presentOpenOnDeviceTitle => '[Öþéñ öñ åñöţĥéŕ ðéṽîçé one two]';

  @override
  String get presentOpenOnDeviceBody =>
      '[Öþéñ ţĥîš ļîñķ öñ ţĥé çöɱþûţéŕ öŕ ƀŕöŵšéŕ ţĥåţ šĥöŵš ţĥé šļîðéš — ƒöŕ éẋåɱþļé ţĥé öñé çöññéçţéð ţö ţĥé þŕöĵéçţöŕ. Šîĝñ îñ ŵîţĥ ýöûŕ åççöûñţ ţĥéŕé. one two three four five six seven eight ni]';

  @override
  String get presentOpenOnDeviceHint =>
      '[Öŕ öþéñ ţĥîš þŕéšéñţåţîöñ ţĥéŕé åñð çĥööšé “Šĥöŵ åûðîéñçé ṽîéŵ ĥéŕé”. one two three four fi]';

  @override
  String get presentAudienceLink => '[Åûðîéñçé ļîñķ one t]';

  @override
  String get presentCopyLink => '[Çöþý ļîñķ one]';

  @override
  String get presentLinkCopied => '[Çöþîéð one]';

  @override
  String get presentDone => '[Ðöñé on]';

  @override
  String get presentQrLabel => '[ǪŔ çöðé öƒ ţĥé åûðîéñçé ļîñķ one two t]';

  @override
  String get presentOfflineNoDevices =>
      '[Öƒƒļîñé — öţĥéŕ ðéṽîçéš çåñ’ţ ĵöîñ one two thr]';

  @override
  String get presentOfflineNoDevicesBody =>
      '[Ýöû çåñ ķééþ þŕéšéñţîñĝ ĥéŕé. Öţĥéŕ ðéṽîçéš ĵöîñ öñçé ýöû’ŕé ƀåçķ öñļîñé. one two three four fiv]';

  @override
  String get presentConnecting => '[Çöññéçţîñĝ… one]';

  @override
  String get presentSessionEnded =>
      '[Ñöţ çöññéçţéð ţö öţĥéŕ ðéṽîçéš one two th]';

  @override
  String presentAudienceDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öţĥéŕ ðéṽîçéš',
      one: '1 öţĥéŕ ðéṽîçé',
      zero: 'Ñö öţĥéŕ ðéṽîçéš ýéţ',
    );
    return '[$_temp0 one two three f]';
  }

  @override
  String get presentPresenterAway => '[Ŵåîţîñĝ ƒöŕ ţĥé þŕéšéñţéŕ… one two t]';

  @override
  String get presentWaitingForPresenter =>
      '[Ŵåîţîñĝ ƒöŕ ţĥé þŕéšéñţéŕ one two]';

  @override
  String get presentAudienceEndedToast => '[Ţĥé þŕéšéñţåţîöñ éñðéð one two]';

  @override
  String get presentAudienceNotFound =>
      '[Ţĥîš þŕéšéñţåţîöñ îšñ’ţ ŕûññîñĝ one two th]';

  @override
  String get presentAudienceNotFoundBody =>
      '[Åšķ ţĥé þŕéšéñţéŕ ƒöŕ å ñéŵ ļîñķ, öŕ öþéñ ţĥé þŕéšéñţåţîöñ åñð çĥööšé “Šĥöŵ åûðîéñçé ṽîéŵ ĥéŕé”. one two three four five six]';

  @override
  String get presentAudienceNoAccess =>
      '[Öñļý ţĥé þŕéšéñţéŕ çåñ šĥöŵ ţĥîš åûðîéñçé ṽîéŵ one two three]';

  @override
  String get presentTakeOverTitle => '[Ţåķé öṽéŕ ţĥé þŕéšéñţåţîöñ? one two t]';

  @override
  String get presentTakeOverBody =>
      '[Ýöû’ŕé þŕéšéñţîñĝ ţĥîš îñ åñöţĥéŕ ŵîñðöŵ. Ţåķé öṽéŕ ţĥé þŕéšéñţåţîöñ ƒŕöɱ ýöûŕ öţĥéŕ ŵîñðöŵ? one two three four five six]';

  @override
  String get presentTakeOver => '[Ţåķé öṽéŕ one]';

  @override
  String get presentTakeOverCancel => '[Þŕéšéñţ ĥéŕé öñļý one tw]';

  @override
  String get presentTakenOverToast =>
      '[Ýöûŕ þŕéšéñţåţîöñ çöñţîñûéš îñ åñöţĥéŕ ŵîñðöŵ one two three]';

  @override
  String get presentExtendedHintTitle =>
      '[Šĥöŵîñĝ ţĥé šļîðéš öñ å þŕöĵéçţöŕ? one two thr]';

  @override
  String get presentExtendedHintBody =>
      '[Öþéñ ţĥîš þŕéšéñţåţîöñ îñ å ŵîñðöŵ ţĥéŕé åñð çĥööšé “Šĥöŵ åûðîéñçé ṽîéŵ ĥéŕé” — öŕ ûšé “Öþéñ öñ åñöţĥéŕ ðéṽîçé…”. one two three four five six seven]';

  @override
  String get presenterViewTitle => '[Þŕéšéñţéŕ ṽîéŵ one t]';

  @override
  String presenterViewTitleWithName(String name) {
    return '[Þŕéšéñţéŕ ṽîéŵ — $name one t]';
  }

  @override
  String get presenterOtherDevice => '[Öţĥéŕ ðéṽîçé… one t]';

  @override
  String get presenterCurrent => '[Çûŕŕéñţ šļîðé one t]';

  @override
  String presenterCurrentStep(int step, int count) {
    return '[Çûŕŕéñţ šļîðé · šţéþ $step öƒ $count one two]';
  }

  @override
  String get presenterAudienceBlack => '[Åûðîéñçé: ƀļåçķ šçŕééñ one two]';

  @override
  String get presenterAudienceWhite => '[Åûðîéñçé: ŵĥîţé šçŕééñ one two]';

  @override
  String get presenterShowSlide => '[Šĥöŵ šļîðé one]';

  @override
  String presenterNextBuild(int step, int count) {
    return '[Ñéẋţ: ƀûîļð $step öƒ $count one t]';
  }

  @override
  String presenterNextSlide(String title) {
    return '[Ñéẋţ šļîðé: $title one]';
  }

  @override
  String get presenterNextSlideUntitled => '[Ñéẋţ šļîðé one]';

  @override
  String get presenterNextEnd => '[Éñð öƒ þŕéšéñţåţîöñ one tw]';

  @override
  String get presenterNextExit => '[Ñéẋţ: éẋîţ one]';

  @override
  String get presenterNotes => '[Šþéåķéŕ ñöţéš one t]';

  @override
  String get presenterNoNotes => '[Ñö šþéåķéŕ ñöţéš ƒöŕ ţĥîš šļîðé one two th]';

  @override
  String presenterElapsed(String time) {
    return '[Éļåþšéð $time one]';
  }

  @override
  String presenterRemaining(String time) {
    return '[Ŕéɱåîñîñĝ $time one]';
  }

  @override
  String presenterSlideOf(int number, int total) {
    return '[Šļîðé $number / $total one]';
  }

  @override
  String presenterAhead(String time) {
    return '[$time åĥéåð on]';
  }

  @override
  String presenterBehind(String time) {
    return '[$time ƀéĥîñð one]';
  }

  @override
  String get presenterStrip => '[Šļîðéš one]';

  @override
  String presentBannerTitle(String device) {
    return '[Ýöû’ŕé þŕéšéñţîñĝ öñ $device one two]';
  }

  @override
  String get presentBannerTitleNoDevice =>
      '[Ýöû’ŕé þŕéšéñţîñĝ ţĥîš þŕéšéñţåţîöñ one two thre]';

  @override
  String get presentBannerDismiss => '[Ðîšɱîšš one]';

  @override
  String get cmdEditCopy => '[Çöþý on]';

  @override
  String get cmdEditCut => '[Çûţ on]';

  @override
  String get cmdEditPaste => '[Þåšţé on]';

  @override
  String get reasonCopyNotAllowed =>
      '[Ţĥé öŵñéŕ ţûŕñéð öƒƒ çöþýîñĝ ƒöŕ ṽîéŵéŕš one two thre]';

  @override
  String get reasonPasteObjectsOnSlide => '[Þåšţé öƀĵéçţš öñ å šļîðé one two]';

  @override
  String get reasonPasteSlidesNotInCells =>
      '[Þåšţé šļîðéš îñ ţĥé šļîðé ñåṽîĝåţöŕ one two thr]';

  @override
  String get toastClipboardEmpty => '[Ţĥéŕé îš ñöţĥîñĝ ţö þåšţé one two]';

  @override
  String get toastPasteChartsUnavailable =>
      '[Çĥåŕţš ƒŕöɱ Ŵöñķý Šĥééţš çåñ\'ţ ƀé þåšţéð îñţö þŕéšéñţåţîöñš one two three four]';

  @override
  String get toastPasteClipped =>
      '[Öñļý ţĥé çéļļš ţĥåţ ƒîţ îñ ţĥé ţåƀļé ŵéŕé þåšţéð one two three]';

  @override
  String get toastPasteTruncated =>
      '[Öñļý ţĥé ƒîŕšţ 50 ŕöŵš åñð 20 çöļûɱñš ŵéŕé þåšţéð one two three]';

  @override
  String get pasteChartLinked => '[Ļîñķéð ţö ţĥé šþŕéåðšĥééţ one two]';

  @override
  String get pasteOptionsLabel => '[Þåšţé öþţîöñš one t]';

  @override
  String get cmdFindNext => '[Ƒîñð ñéẋţ one]';

  @override
  String get cmdFindPrevious => '[Ƒîñð þŕéṽîöûš one t]';

  @override
  String get cmdFindReplace => '[Ŕéþļåçé one]';

  @override
  String get cmdFindReplaceAll => '[Ŕéþļåçé åļļ one]';

  @override
  String get undoReplaceAll => '[Ŕéþļåçé åļļ one]';

  @override
  String get findClose => '[Çļöšé ƒîñð one]';

  @override
  String get findPlaceholder => '[Ƒîñð îñ þŕéšéñţåţîöñ one two]';

  @override
  String get findNoResults => '[Ñö ŕéšûļţš one]';

  @override
  String findOfCount(int current, int total) {
    return '[$current öƒ $total o]';
  }

  @override
  String findMatchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ɱåţçĥéš',
      one: '1 ɱåţçĥ',
    );
    return '[$_temp0 one t]';
  }

  @override
  String get findReplaceTitle => '[Ƒîñð åñð ŕéþļåçé one t]';

  @override
  String get findLabel => '[Ƒîñð on]';

  @override
  String get replaceLabel => '[Ŕéþļåçé ŵîţĥ one]';

  @override
  String get findMatchCase => '[Ṁåţçĥ çåšé one]';

  @override
  String get findWholeWords => '[Ŵĥöļé ŵöŕðš one]';

  @override
  String get findUseRegex => '[Ûšé ŕéĝûļåŕ éẋþŕéššîöñš one two]';

  @override
  String get findIncludeNotes => '[Îñçļûðé šþéåķéŕ ñöţéš one two]';

  @override
  String get findIncludeSkipped => '[Îñçļûðé šķîþþéð šļîðéš one two]';

  @override
  String get findScope => '[Šéåŕçĥ îñ one]';

  @override
  String get findScopeAll => '[Åļļ šļîðéš one]';

  @override
  String get findScopeCurrent => '[Çûŕŕéñţ šļîðé one t]';

  @override
  String get findScopeSelected => '[Šéļéçţéð šļîðéš one t]';

  @override
  String get findButtonPrevious => '[Þŕéṽîöûš one]';

  @override
  String get findButtonNext => '[Ñéẋţ on]';

  @override
  String get findInvalidRegex =>
      '[Ţĥîš ŕéĝûļåŕ éẋþŕéššîöñ îš ñöţ ṽåļîð one two thr]';

  @override
  String toastReplacedAll(int count, String find, String replace) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ŕéþļåçéð $count îñšţåñçéš öƒ “$find” ŵîţĥ “$replace”',
      one: 'Ŕéþļåçéð 1 îñšţåñçé öƒ “$find” ŵîţĥ “$replace”',
      zero: 'Ñöţĥîñĝ ŵåš ŕéþļåçéð',
    );
    return '[$_temp0 one two three four five si]';
  }

  @override
  String toastReplaceSkipped(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ɱåţçĥéš îñ ţéẋţ $name îš éðîţîñĝ ŵéŕé šķîþþéð',
      one: '1 ɱåţçĥ îñ ţéẋţ $name îš éðîţîñĝ ŵåš šķîþþéð',
    );
    return '[$_temp0 one two three four five]';
  }

  @override
  String toastFindBodyLocked(String name) {
    return '[$name îš éðîţîñĝ ţĥîš ţéẋţ one tw]';
  }

  @override
  String get cmdLayoutAdd => '[Ñéŵ ļåýöûţ one]';

  @override
  String get cmdLayoutDuplicate => '[Ðûþļîçåţé ļåýöûţ one tw]';

  @override
  String get cmdLayoutRename => '[Ŕéñåɱé ļåýöûţ… one t]';

  @override
  String get cmdLayoutMove => '[Ṁöṽé ļåýöûţ one]';

  @override
  String get cmdLayoutDelete => '[Ðéļéţé ļåýöûţ one t]';

  @override
  String get cmdLayoutSetBackground => '[Ļåýöûţ ƀåçķĝŕöûñð one tw]';

  @override
  String get cmdLayoutSetHideMasterElements => '[Ĥîðé ɱåšţéŕ öƀĵéçţš one tw]';

  @override
  String get cmdLayoutToggleHidden => '[Ĥîðé îñ ļåýöûţ þîçķéŕ one two]';

  @override
  String get cmdMasterAdd => '[Ñéŵ ɱåšţéŕ one]';

  @override
  String get cmdMasterDuplicate => '[Ðûþļîçåţé ɱåšţéŕ one tw]';

  @override
  String get cmdMasterRename => '[Ŕéñåɱé ɱåšţéŕ… one t]';

  @override
  String get cmdMasterDelete => '[Ðéļéţé ɱåšţéŕ one t]';

  @override
  String get cmdMasterSetBackground => '[Ṁåšţéŕ ƀåçķĝŕöûñð one tw]';

  @override
  String get cmdMastersExit => '[Çļöšé ɱåšţéŕš ṽîéŵ one tw]';

  @override
  String get cmdThemeUpdate => '[Éðîţ ţĥéɱé one]';

  @override
  String get cmdThemeDeriveDarkColors => '[Ðéŕîṽé ðåŕķ çöļöŕš one tw]';

  @override
  String get cmdThemeResetToBuiltIn => '[Ŕéšéţ ţö ƀûîļţ-îñ ţĥéɱé one two]';

  @override
  String get reasonNoLayout => '[Šéļéçţ å ļåýöûţ one t]';

  @override
  String get reasonNoMaster => '[Šéļéçţ å ɱåšţéŕ one t]';

  @override
  String get reasonLastLayout =>
      '[Å ɱåšţéŕ ñééðš åţ ļéåšţ öñé ļåýöûţ one two th]';

  @override
  String get reasonLastMaster =>
      '[Å ţĥéɱé ñééðš åţ ļéåšţ öñé ɱåšţéŕ one two th]';

  @override
  String reasonLayoutUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ûšéð ƀý $count šļîðéš — åþþļý åñöţĥéŕ ļåýöûţ ƒîŕšţ',
      one: 'Ûšéð ƀý 1 šļîðé — åþþļý åñöţĥéŕ ļåýöûţ ƒîŕšţ',
    );
    return '[$_temp0 one two three four five si]';
  }

  @override
  String reasonMasterUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ûšéð ƀý $count šļîðéš — åþþļý åñöţĥéŕ ļåýöûţ ƒîŕšţ',
      one: 'Ûšéð ƀý 1 šļîðé — åþþļý åñöţĥéŕ ļåýöûţ ƒîŕšţ',
    );
    return '[$_temp0 one two three four five si]';
  }

  @override
  String get reasonMastersOnly =>
      '[Öþéñ Éðîţ ɱåšţéŕš åñð ļåýöûţš ƒîŕšţ one two thr]';

  @override
  String get reasonNotBuiltInTheme =>
      '[Ţĥîš ţĥéɱé îšñ’ţ ƀåšéð öñ å ƀûîļţ-îñ ţĥéɱé one two three]';

  @override
  String layoutDefaultName(int n) {
    return '[Ļåýöûţ $n one]';
  }

  @override
  String masterDefaultName(int n) {
    return '[Ṁåšţéŕ $n one]';
  }

  @override
  String get layoutRenameTitle => '[Ŕéñåɱé ļåýöûţ one t]';

  @override
  String get masterRenameTitle => '[Ŕéñåɱé ɱåšţéŕ one t]';

  @override
  String get layoutDeleteTitle => '[Ðéļéţé ļåýöûţ? one t]';

  @override
  String layoutDeleteUsedBody(int count, String name, String replacement) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count šļîðéš ûšé “$name”. Åþþļý “$replacement” ţö ţĥéɱ åñð ðéļéţé ţĥé ļåýöûţ?',
      one:
          '1 šļîðé ûšéš “$name”. Åþþļý “$replacement” ţö îţ åñð ðéļéţé ţĥé ļåýöûţ?',
    );
    return '[$_temp0 one two three four five six sev]';
  }

  @override
  String get layoutDeleteApplyAndDelete => '[Åþþļý åñð ðéļéţé one t]';

  @override
  String placeholderPrompt(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'title': 'Çļîçķ ţö åðð ţîţļé',
      'subtitle': 'Çļîçķ ţö åðð šûƀţîţļé',
      'body': 'Çļîçķ ţö åðð ţéẋţ',
      'picture': 'Çļîçķ ţö åðð å þîçţûŕé',
      'chart': 'Çļîçķ ţö åðð å çĥåŕţ',
      'table': 'Çļîçķ ţö åðð å ţåƀļé',
      'code': 'Çļîçķ ţö åðð çöðé',
      'caption': 'Çļîçķ ţö åðð å çåþţîöñ',
      'bigNumber': '100%',
      'quote': 'Çļîçķ ţö åðð å ǫûöţé',
      'attribution': 'Ñåɱé, ŕöļé',
      'object': 'Çļîçķ ţö åðð åñ öƀĵéçţ',
      'other': 'Çļîçķ ţö åðð ţéẋţ',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four]';
  }

  @override
  String get inspectorLayout => '[Ļåýöûţ one]';

  @override
  String get inspectorMaster => '[Ṁåšţéŕ one]';

  @override
  String get inspectorTheme => '[Ţĥéɱé on]';

  @override
  String get mastersNavigatorLabel => '[Ṁåšţéŕš åñð ļåýöûţš one tw]';

  @override
  String mastersMasterName(String name) {
    return '[Ṁåšţéŕ · $name one]';
  }

  @override
  String get mastersHiddenInPicker => '[Ĥîððéñ îñ ļåýöûţ þîçķéŕ one two]';

  @override
  String get mastersMoveUp => '[Ṁöṽé ûþ one]';

  @override
  String get mastersMoveDown => '[Ṁöṽé ðöŵñ one]';

  @override
  String mastersBannerLayout(String name, String theme, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Éðîţîñĝ ļåýöûţ “$name” öƒ ţĥéɱé $theme — çĥåñĝéš åþþļý ţö $count šļîðéš',
      one: 'Éðîţîñĝ ļåýöûţ “$name” öƒ ţĥéɱé $theme — çĥåñĝéš åþþļý ţö 1 šļîðé',
      zero: 'Éðîţîñĝ ļåýöûţ “$name” öƒ ţĥéɱé $theme — ñö šļîðéš ûšé îţ ýéţ',
    );
    return '[$_temp0 one two three four five six seven eight nine]';
  }

  @override
  String mastersBannerMaster(String name, String theme, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Éðîţîñĝ ɱåšţéŕ “$name” öƒ ţĥéɱé $theme — çĥåñĝéš åþþļý ţö $count šļîðéš',
      one: 'Éðîţîñĝ ɱåšţéŕ “$name” öƒ ţĥéɱé $theme — çĥåñĝéš åþþļý ţö 1 šļîðé',
      zero: 'Éðîţîñĝ ɱåšţéŕ “$name” öƒ ţĥéɱé $theme — ñö šļîðéš ûšé îţ ýéţ',
    );
    return '[$_temp0 one two three four five six seven eight nine]';
  }

  @override
  String get mastersBannerNone =>
      '[Ţĥîš þŕéšéñţåţîöñ ĥåš ñö ļåýöûţš ţö éðîţ one two thre]';

  @override
  String get mastersDone => '[Ðöñé on]';

  @override
  String mastersLayoutSemantics(String name) {
    return '[Ļåýöûţ $name one]';
  }

  @override
  String mastersMasterSemantics(String name) {
    return '[Ṁåšţéŕ $name one]';
  }

  @override
  String get mastersSectionProperties => '[Þŕöþéŕţîéš one]';

  @override
  String get mastersSectionPlaceholders => '[Þļåçéĥöļðéŕš one t]';

  @override
  String get mastersNoPlaceholders => '[Ñö þļåçéĥöļðéŕš ýéţ one tw]';

  @override
  String get mastersChoosePlaceholder => '[Åðð… on]';

  @override
  String mastersOfTheme(String name) {
    return '[Ţĥéɱé $name on]';
  }

  @override
  String get mastersBackgroundUseMaster => '[Ûšé ɱåšţéŕ ƀåçķĝŕöûñð one two]';

  @override
  String get mastersBackgroundUseTheme => '[Ûšé ţĥéɱé ƀåçķĝŕöûñð one two]';

  @override
  String get themeSectionColors => '[Çöļöŕš one]';

  @override
  String get themeSectionFonts => '[Ƒöñţš on]';

  @override
  String get themeSectionTextStyles => '[Ţéẋţ šţýļéš one]';

  @override
  String get themeSectionObjects => '[Öƀĵéçţš one]';

  @override
  String get themeSectionTables => '[Ţåƀļéš one]';

  @override
  String get themeSectionCharts => '[Çĥåŕţš one]';

  @override
  String get themeEditorNoTheme =>
      '[Ţĥîš þŕéšéñţåţîöñ ĥåš ñö ţĥéɱé one two th]';

  @override
  String themeEditorBasedOn(String name) {
    return '[Ɓåšéð öñ $name one]';
  }

  @override
  String themeContrastPair(String foreground, String background) {
    return '[$foreground öñ $background o]';
  }

  @override
  String themeContrastPasses(String pair, String ratio, String required) {
    return '[$pair: çöñţŕåšţ $ratio (ñééðš $required:1) one two]';
  }

  @override
  String themeContrastFails(String pair, String ratio, String required) {
    return '[$pair: çöñţŕåšţ $ratio îš ţöö ļöŵ (ñééðš $required:1) one two th]';
  }

  @override
  String get themeEditorCustomColors => '[Çûšţöɱ çöļöŕš one t]';

  @override
  String get themeEditorCustomColorName => '[Çûšţöɱ çöļöŕ ñåɱé one tw]';

  @override
  String themeEditorCustomColorDefault(int n) {
    return '[Çûšţöɱ $n one]';
  }

  @override
  String get themeEditorAddCustomColor => '[Åðð çûšţöɱ çöļöŕ one t]';

  @override
  String themeEditorRemoveCustomColor(String name) {
    return '[Ŕéɱöṽé $name one]';
  }

  @override
  String themeEditorWeight(String weight) {
    String _temp0 = intl.Intl.selectLogic(weight, {
      '300': 'Ļîĝĥţ',
      '400': 'Ŕéĝûļåŕ',
      '500': 'Ṁéðîûɱ',
      '600': 'Šéɱîƀöļð',
      '700': 'Ɓöļð',
      '800': 'Éẋţŕå ƀöļð',
      'other': '$weight',
    });
    return '[$_temp0 one two three]';
  }

  @override
  String themeEditorFontFallback(String family, String fallback) {
    return '[$family îšñ’ţ åṽåîļåƀļé; $fallback îš ûšéð one two]';
  }

  @override
  String get themeEditorItalic => '[Îţåļîç one]';

  @override
  String get themeEditorLetterSpacing => '[Ļéţţéŕ šþåçîñĝ one t]';

  @override
  String get themeEditorCaps => '[Çåþîţåļš one]';

  @override
  String get themeEditorLists => '[Ļîšţš on]';

  @override
  String themeEditorListLevel(int n) {
    return '[Ļéṽéļ $n on]';
  }

  @override
  String get themeEditorBulletColor => '[Ɓûļļéţ çöļöŕ one]';

  @override
  String get themeEditorIndent => '[Îñðéñţ þéŕ ļéṽéļ one t]';

  @override
  String get themeEditorBackgroundNotSolid =>
      '[Ţĥé ƀåçķĝŕöûñð îš å ĝŕåðîéñţ öŕ åñ îɱåĝé; þîçķîñĝ å çöļöŕ ŕéþļåçéš îţ. one two three four fi]';

  @override
  String get themeEditorDarkBackground =>
      '[Ðîƒƒéŕéñţ îñ ðåŕķ åþþéåŕåñçé one two t]';

  @override
  String get themeEditorTextBoxes => '[Ţéẋţ ƀöẋéš one]';

  @override
  String get themeEditorShapes => '[Šĥåþéš one]';

  @override
  String get themeEditorLines => '[Ļîñéš on]';

  @override
  String get themeEditorIcons => '[Îçöñš on]';

  @override
  String get themeEditorTextColor => '[Ţéẋţ çöļöŕ one]';

  @override
  String get themeEditorShadowBlur => '[Ɓļûŕ on]';

  @override
  String get themeEditorShadowOffset => '[Öƒƒšéţ one]';

  @override
  String get themeEditorQuickStyles => '[Ǫûîçķ šţýļéš one]';

  @override
  String themeEditorQuickStyle(int n) {
    return '[Šţýļé $n on]';
  }

  @override
  String get themeEditorHeaderFill => '[Ĥéåðéŕ ƒîļļ one]';

  @override
  String get themeEditorHeaderText => '[Ĥéåðéŕ ţéẋţ one]';

  @override
  String get themeEditorBodyFill => '[Ɓöðý ƒîļļ one]';

  @override
  String get themeEditorBandFill => '[Ɓåñðéð ŕöŵš one]';

  @override
  String get themeEditorCornerRadius => '[Çöŕñéŕ ŕåðîûš one t]';

  @override
  String get themeEditorLightPalette => '[Ļîĝĥţ þåļéţţé one t]';

  @override
  String get themeEditorDarkPalette => '[Ðåŕķ þåļéţţé one]';

  @override
  String get themeEditorWindowChrome => '[Çĥŕöɱé one]';

  @override
  String get themeEditorChromeTab => '[Ţåƀ on]';

  @override
  String get themeEditorChromeWindow => '[Ŵîñðöŵ one]';

  @override
  String get themeEditorChromeCaption => '[Çåþţîöñ one]';

  @override
  String get themeEditorShadowSoft => '[Šöƒţ on]';

  @override
  String get themeEditorShadowStrong => '[Šţŕöñĝ one]';

  @override
  String themeEditorSeries(int n) {
    return '[Šéŕîéš $n one]';
  }

  @override
  String get themeEditorGridlines => '[Ĝŕîðļîñéš one]';

  @override
  String get themeEditorAxis => '[Åẋîš on]';

  @override
  String get themeEditorLighting => '[3Ð ļîĝĥţîñĝ one]';

  @override
  String get themeEditorLightingSoft => '[Šöƒţ on]';

  @override
  String get themeEditorLightingStudio => '[Šţûðîö one]';

  @override
  String get themeEditorLightingFlat => '[Ƒļåţ on]';

  @override
  String get cmdInsertCodeDescription =>
      '[Îñšéŕţ å çöðé ƀļöçķ ŵîţĥ šýñţåẋ ĥîĝĥļîĝĥţîñĝ, ļîñé šţéþš åñð ţýþé-îñ šţåţéš one two three four five]';

  @override
  String get cmdCodeSetPalette => '[Çöðé çöļöŕ ţĥéɱé one t]';

  @override
  String get cmdCodeSetText => '[Šéţ çöðé one]';

  @override
  String get cmdCodeAddStateDescription =>
      '[Åððš å çöþý öƒ ţĥé šéļéçţéð šţåţé åƒţéŕ îţ: çĥåñĝé ţĥé çöðé ţĥéŕé ţö åñîɱåţé ţĥé çĥåñĝé one two three four five s]';

  @override
  String get cmdCodeDuplicateState => '[Ðûþļîçåţé šţåţé one t]';

  @override
  String get cmdCodeDeleteState => '[Ðéļéţé šţåţé one]';

  @override
  String get cmdCodeMoveState => '[Ṁöṽé šţåţé one]';

  @override
  String get cmdCodeSelectState => '[Šĥöŵ çöðé šţåţé one t]';

  @override
  String get cmdCodeSetStateLabel => '[Ŕéñåɱé šţåţé one]';

  @override
  String get cmdCodeSetStateTransition => '[Šţåţé åŕŕîṽåļ one t]';

  @override
  String get cmdCodeSetCallout => '[Šţéþ çåļļöûţ one]';

  @override
  String get cmdCodeAddStepFromLines => '[Åðð ļîñé šţéþ one]';

  @override
  String get cmdCodePreviewStep => '[Þŕéṽîéŵ ļîñé šţéþ one tw]';

  @override
  String get cmdCodePreview => '[Þŕéṽîéŵ çöðé åñîɱåţîöñ one two]';

  @override
  String get cmdCodeToggleDiffGutter => '[Šĥöŵ çöðé çĥåñĝéš one tw]';

  @override
  String get cmdCodeCopy => '[Çöþý çöðé one]';

  @override
  String get cmdCodeConvertFromText => '[Çöñṽéŕţ ţö çöðé ƀļöçķ one two]';

  @override
  String get reasonSelectCode => '[Šéļéçţ å çöðé ƀļöçķ one tw]';

  @override
  String get reasonLastCodeState =>
      '[Å çöðé ƀļöçķ ķééþš åţ ļéåšţ öñé šţåţé one two thr]';

  @override
  String get reasonSelectTextBox => '[Šéļéçţ å ţéẋţ ƀöẋ ŵîţĥ ţéẋţ one two]';

  @override
  String get toastCodeCopied => '[Çöðé çöþîéð one]';

  @override
  String get undoEditCodeBlock => '[Éðîţ çöðé ƀļöçķ one t]';

  @override
  String get undoEditCodeState => '[Éðîţ çöðé šţåţé one t]';

  @override
  String get undoEditLineSteps => '[Éðîţ ļîñé šţéþš one t]';

  @override
  String get undoEditCallout => '[Éðîţ çåļļöûţ one]';

  @override
  String get codeLanguageLabel => '[Ļåñĝûåĝé one]';

  @override
  String get codeLanguageDialogTitle => '[Çöðé ļåñĝûåĝé one t]';

  @override
  String get codeInsertDialogTitle => '[Îñšéŕţ çöðé ƀļöçķ one tw]';

  @override
  String get codePaletteLabel => '[Çöļöŕš one]';

  @override
  String get codePaletteAuto => '[Åûţö on]';

  @override
  String codePaletteAutoNamed(String name) {
    return '[Åûţö ($name) one]';
  }

  @override
  String get codePaletteLight => '[Ţĥéɱé ļîĝĥţ one]';

  @override
  String get codePaletteDark => '[Ţĥéɱé ðåŕķ one]';

  @override
  String get codeFontSize => '[Ƒöñţ šîžé one]';

  @override
  String get codeFontSizeAuto => '[Åûţö on]';

  @override
  String get codeFontSizeRange => '[Ṁîñ – ɱåẋ one]';

  @override
  String get codeStartLine => '[Šţåŕţ åţ one]';

  @override
  String get codeWrap => '[Ŵŕåþ ļîñéš one]';

  @override
  String get codeLigatures => '[Ļîĝåţûŕéš one]';

  @override
  String get codeChrome => '[Ƒŕåɱé on]';

  @override
  String get codeChromeTheme => '[Ţĥéɱé ðéƒåûļţ one t]';

  @override
  String get codeChromeNone => '[Ñöñé on]';

  @override
  String get codeChromeTab => '[Ƒîļé ţåƀ one]';

  @override
  String get codeChromeWindow => '[Ŵîñðöŵ one]';

  @override
  String get codeChromeCaption => '[Çåþţîöñ one]';

  @override
  String get codeTitle => '[Ţîţļé on]';

  @override
  String get codeShowLanguage => '[Ļåñĝûåĝé ƀåðĝé one t]';

  @override
  String get codeCopyButton => '[Çöþý ƀûţţöñ one]';

  @override
  String get codeCopyNever => '[Ñéṽéŕ on]';

  @override
  String get codeCopyPresent => '[Îñ þŕéšéñţåţîöñš one tw]';

  @override
  String get codeCopyAlways => '[Åļŵåýš one]';

  @override
  String get codeStatesHeader => '[Šţåţéš one]';

  @override
  String codeStateChip(int index) {
    return '[Šţåţé $index on]';
  }

  @override
  String codeStateChipNamed(int index, String label) {
    return '[Šţåţé $index: $label one]';
  }

  @override
  String codeStateInfoFirst(int index, int lines) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines ļîñéš',
      one: '1 ļîñé',
    );
    return '[Šţåţé $index · $_temp0 one tw]';
  }

  @override
  String codeStateInfo(
    int index,
    int lines,
    int added,
    int changed,
    int removed,
    int previous,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines ļîñéš',
      one: '1 ļîñé',
    );
    return '[Šţåţé $index · $_temp0 · +$added ~$changed −$removed ṽš. šţåţé $previous one two th]';
  }

  @override
  String get codeMoveStateLeft => '[Ṁöṽé šţåţé éåŕļîéŕ one tw]';

  @override
  String get codeMoveStateRight => '[Ṁöṽé šţåţé ļåţéŕ one t]';

  @override
  String get codePreviewTypeIn => '[Þŕéṽîéŵ ţĥé ţýþé-îñ one tw]';

  @override
  String get codePreviewChange =>
      '[Þŕéṽîéŵ ţĥé çĥåñĝé îñţö ţĥîš šţåţé one two thr]';

  @override
  String get codeStateLabel => '[Ñåɱé on]';

  @override
  String get codeStateLabelHint => '[é.ĝ. Åðð çåçĥîñĝ one t]';

  @override
  String get codeShowChanges => '[Šĥöŵ çĥåñĝéš one]';

  @override
  String get codeTypeInHeader => '[Ţýþé-îñ one]';

  @override
  String get codeArrivalHeader => '[Åŕŕîṽåļ one]';

  @override
  String get codeArrivesBy => '[Åŕŕîṽéš ƀý one]';

  @override
  String get codeModeType => '[Ţýþîñĝ one]';

  @override
  String get codeModeMorph => '[Ṁöŕþĥ on]';

  @override
  String get codeModeInstant => '[Îñšţåñţ one]';

  @override
  String codeDurationTyped(String seconds) {
    return '[≈ $seconds š (ţýþéð) one]';
  }

  @override
  String codeDurationMorph(String seconds) {
    return '[≈ $seconds š (ɱöŕþĥ) one]';
  }

  @override
  String codeDurationInstant(String seconds) {
    return '[≈ $seconds š (çŕöššƒåðé) one t]';
  }

  @override
  String get codeMore => '[Ṁöŕé… on]';

  @override
  String codeLineStepsHeader(int index) {
    return '[Ļîñé šţéþš (šţåţé $index) one tw]';
  }

  @override
  String get codeStepsEmpty =>
      '[Ñö šţéþš: éṽéŕý ļîñé šĥöŵš ñöŕɱåļļý. one two thr]';

  @override
  String get codeStepAll => '[Åļļ ļîñéš one]';

  @override
  String codeStepRow(int index, String lines) {
    return '[Šţéþ $index: $lines on]';
  }

  @override
  String get codeEditCallout => '[Çåļļöûţ one]';

  @override
  String get codeRemoveStep => '[Ŕéɱöṽé šţéþ one]';

  @override
  String get codeHighlightStyle => '[Ĥîĝĥļîĝĥţ one]';

  @override
  String get codeStyleDim => '[Ðîɱ öţĥéŕš one]';

  @override
  String get codeStyleBlur => '[Ɓļûŕ öţĥéŕš one]';

  @override
  String get codeStyleDimBlur => '[Ðîɱ åñð ƀļûŕ one]';

  @override
  String get codeStyleBar => '[Ɓåŕ on]';

  @override
  String get codeStyleBox => '[Ɓöẋ on]';

  @override
  String get codeStyleNone => '[Ñöñé on]';

  @override
  String get codeFocus => '[Ƒöçûš on]';

  @override
  String get codeFocusScroll => '[Šçŕöļļ one]';

  @override
  String get codeFocusZoom => '[Žööɱ on]';

  @override
  String get codeFocusNone => '[Ñöñé on]';

  @override
  String get codeFitAcrossStates => '[Šåɱé šîžé îñ åļļ šţåţéš one two]';

  @override
  String get codeStepsDialogTitle => '[Ļîñé šţéþš one]';

  @override
  String get codeStepsHint =>
      '[Öñé šţéþ þéŕ çļîçķ, šéþåŕåţéð ƀý |: ļîñéš (5), ŕåñĝéš (1-3, 7-), ļîšţš (2,4); * šĥöŵš åļļ ļîñéš. one two three four five six]';

  @override
  String get codeStepsLabel => '[Šţéþš on]';

  @override
  String codeStepIssueSyntax(int index) {
    return '[Šţéþ $index: ûšé å ļîñé, å ŕåñĝé ļîķé 3-5 öŕ 7-, öŕ 4:2-9 one two three]';
  }

  @override
  String codeStepIssuePastEnd(int index) {
    return '[Šţéþ $index þöîñţš þåšţ ţĥé éñð öƒ ţĥé çöðé one two thr]';
  }

  @override
  String codeStepIssueReversed(int index) {
    return '[Šţéþ $index: å ŕåñĝé ŵåš ŕéṽéŕšéð one two]';
  }

  @override
  String codeStepIssueColumns(int index) {
    return '[Šţéþ $index: çöļûɱñš šţåŕţ åţ 1 one two]';
  }

  @override
  String codeCalloutDialogTitle(int index) {
    return '[Çåļļöûţ öƒ šţéþ $index one t]';
  }

  @override
  String get codeCalloutHint =>
      '[Šĥöŵñ ñéẋţ ţö ţĥé šţéþ\'š ļîñéš. **Ɓöļð**, *îţåļîç* åñð `çöðé` ŵöŕķ. one two three four f]';

  @override
  String get codeCalloutText => '[Ţéẋţ on]';

  @override
  String get codeCalloutSide => '[Šîðé on]';

  @override
  String get codeSideAuto => '[Åûţöɱåţîç one]';

  @override
  String get codeSideRight => '[Ŕîĝĥţ on]';

  @override
  String get codeSideLeft => '[Ļéƒţ on]';

  @override
  String get codeSideAbove => '[Åƀöṽé on]';

  @override
  String get codeSideBelow => '[Ɓéļöŵ on]';

  @override
  String get codeCalloutStyle => '[Šţýļé on]';

  @override
  String get codeCalloutStyleDefault => '[Ðéƒåûļţ one]';

  @override
  String get codeCalloutBubble => '[Ɓûƀƀļé one]';

  @override
  String get codeCalloutLabel => '[Ļåƀéļ on]';

  @override
  String get codeCalloutPill => '[Þîļļ on]';

  @override
  String get codeCalloutRemove => '[Ŕéɱöṽé çåļļöûţ one t]';

  @override
  String get codeTypingDialogTitle => '[Ţýþîñĝ šéţţîñĝš one t]';

  @override
  String get codeTypingCps => '[Šþééð (çĥåŕš/š) one t]';

  @override
  String get codeTypingRhythm => '[Ŕĥýţĥɱ one]';

  @override
  String get codeTypingDeletions => '[Ðéļéţîöñš one]';

  @override
  String get codeDeleteAuto => '[Åûţöɱåţîç one]';

  @override
  String get codeDeleteBackspace => '[Ɓåçķšþåçé one]';

  @override
  String get codeDeleteSelect => '[Šéļéçţ åñð ðéļéţé one tw]';

  @override
  String get codeTypingBackspaceMax => '[Ɓåçķšþåçé ûþ ţö (çĥåŕš) one two]';

  @override
  String get codeTypingDeleteCps => '[Ɓåçķšþåçé šþééð (çĥåŕš/š) one two t]';

  @override
  String get codeTypingCaretGlide => '[Çåŕéţ ĝļîðé (ɱš) one t]';

  @override
  String get codeTypingOrder => '[Öŕðéŕ on]';

  @override
  String get codeOrderDocument => '[Ţöþ ţö ƀöţţöɱ one]';

  @override
  String get codeOrderReverse => '[Ɓöţţöɱ ţö ţöþ one]';

  @override
  String get codeTypingPasteLines => '[Þåšţé ƒŕöɱ (ļîñéš) one tw]';

  @override
  String get codeTypingMaxDuration => '[Ļöñĝéšţ (ɱš) one]';

  @override
  String get codeTypingCaret => '[Çåŕéţ on]';

  @override
  String get codeCaretBar => '[Ɓåŕ on]';

  @override
  String get codeCaretBlock => '[Ɓļöçķ on]';

  @override
  String get codeCaretUnderline => '[Ûñðéŕļîñé one]';

  @override
  String get codeTypingAutoIndent => '[Åûţö-îñðéñţ ñéŵ ļîñéš one two]';

  @override
  String get codeTypingScrollFollow => '[Šçŕöļļ ţö ţĥé çåŕéţ one tw]';

  @override
  String get codeTypingHighlightOnArrive => '[Šĥöŵ šţéþ 1 ŵĥéñ ţýþéð one two]';

  @override
  String get codeMorphDuration => '[Ṁöŕþĥ ðûŕåţîöñ (ɱš) one tw]';

  @override
  String get codeMorphStagger => '[Ṁöŕþĥ šţåĝĝéŕ þéŕ ļîñé (ɱš) one two t]';

  @override
  String codeNumberRange(String min, String max) {
    return '[Éñţéŕ å ñûɱƀéŕ ƒŕöɱ $min ţö $max one two]';
  }

  @override
  String codeEditorSemantics(String language) {
    return '[Çöðé éðîţöŕ, $language one]';
  }

  @override
  String codeLinesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ļîñéš ĥîððéñ',
      one: '1 ļîñé ĥîððéñ',
    );
    return '[$_temp0 one two]';
  }

  @override
  String get codeOverflowHint =>
      '[Éñļåŕĝé ţĥé ƀöẋ, ļöŵéŕ ţĥé ɱîñîɱûɱ šîžé öŕ ţûŕñ öñ ŵŕåþ one two three fo]';

  @override
  String get cmdChartUpdateMany => '[Ûþðåţé çĥåŕţš one t]';

  @override
  String get cmdChartRelink => '[Çĥåñĝé ļîñķéð çĥåŕţ… one two]';

  @override
  String get cmdChartSetUseDeckTheme => '[Ṁåţçĥ þŕéšéñţåţîöñ ţĥéɱé one two]';

  @override
  String get cmdChartUpdateStyle => '[Éðîţ çĥåŕţ šţýļé one t]';

  @override
  String get cmdChartResetOverrides => '[Ŕéšéţ šţýļé öṽéŕŕîðéš one two]';

  @override
  String get cmdChartSetCamera => '[Ŕöţåţé 3Ð çĥåŕţ one t]';

  @override
  String get cmdChartAddCameraStep => '[Åðð çåɱéŕå šţéþ one t]';

  @override
  String get cmdChartViewDataTable => '[Ṽîéŵ ðåţå åš ţåƀļé one tw]';

  @override
  String get cmdChartCheckUpdates =>
      '[Çĥéçķ ļîñķéð çĥåŕţš ƒöŕ ûþðåţéš one two th]';

  @override
  String get cmdInsertChartFromSheetsDescription =>
      '[Îñšéŕţ å çĥåŕţ ƒŕöɱ å Ŵöñķý Šĥééţš šþŕéåðšĥééţ, ļîñķéð šö îţ çåñ ƀé ûþðåţéð. one two three four five]';

  @override
  String get reasonSelectChart => '[Šéļéçţ å çĥåŕţ one t]';

  @override
  String get reasonSelectLinkedChart =>
      '[Šéļéçţ å çĥåŕţ ļîñķéð ţö å šþŕéåðšĥééţ one two thre]';

  @override
  String get reasonSelect3DChart => '[Šéļéçţ å 3Ð çĥåŕţ one t]';

  @override
  String get reasonChartNoOverrides =>
      '[Ţĥé çĥåŕţ ĥåš ñö šţýļé öṽéŕŕîðéš one two th]';

  @override
  String get undoInsertChart => '[Îñšéŕţ çĥåŕţ one]';

  @override
  String get undoUpdateChart => '[Ûþðåţé çĥåŕţ one]';

  @override
  String get undoUnlinkChart => '[Ûñļîñķ çĥåŕţ one]';

  @override
  String get undoRelinkChart => '[Çĥåñĝé ļîñķéð çĥåŕţ one tw]';

  @override
  String get undoEditChartStyle => '[Éðîţ çĥåŕţ šţýļé one t]';

  @override
  String get undoRotateChart => '[Ŕöţåţé çĥåŕţ one]';

  @override
  String get chartErrOffline =>
      '[Ýöû\'ŕé öƒƒļîñé. Çöññéçţ ţö îñšéŕţ öŕ ûþðåţé çĥåŕţš ƒŕöɱ Šĥééţš. one two three four]';

  @override
  String get chartErrNoAccess =>
      '[Ýöû ðöñ\'ţ ĥåṽé åççéšš ţö ţĥîš šþŕéåðšĥééţ åñýɱöŕé. one two three fo]';

  @override
  String get chartErrTrashed =>
      '[Ţĥîš šþŕéåðšĥééţ îš îñ ţĥé ţŕåšĥ. one two th]';

  @override
  String get chartErrExportDisabled =>
      '[Ţĥé öŵñéŕ ðöéšñ\'ţ åļļöŵ ṽîéŵéŕš ţö çöþý çĥåŕţš ƒŕöɱ ţĥîš šþŕéåðšĥééţ. one two three four fi]';

  @override
  String get chartErrNotFound =>
      '[Ţĥîš çĥåŕţ ŵåš ðéļéţéð. Þîçķ åñöţĥéŕ öñé. one two three]';

  @override
  String get chartErrTooLarge =>
      '[Ţĥîš çĥåŕţ ĥåš ţöö ɱûçĥ ðåţå ţö þļåçé îñ å þŕéšéñţåţîöñ. Ŕéðûçé îţš ŕåñĝé îñ Šĥééţš. one two three four five s]';

  @override
  String get chartErrUnsupported =>
      '[Ţĥîš çĥåŕţ ŵåš ɱåðé ŵîţĥ å ñéŵéŕ ṽéŕšîöñ öƒ Ŵöñķý Šĥééţš. Ŕéļöåð ţö îñšéŕţ îţ. one two three four five]';

  @override
  String get chartErrQuota =>
      '[Ţĥéŕé îšñ\'ţ éñöûĝĥ šţöŕåĝé ƒöŕ ţĥîš çĥåŕţ. one two three]';

  @override
  String get chartErrRateLimited =>
      '[Ţöö ɱåñý çĥåŕţ ŕéǫûéšţš. Ţŕý åĝåîñ îñ å ɱîñûţé. one two three]';

  @override
  String get chartErrFailed =>
      '[Çöûļðñ\'ţ ĝéţ ţĥé çĥåŕţ. Ţŕý åĝåîñ. one two thr]';

  @override
  String get chartInsertDialogTitle =>
      '[Îñšéŕţ çĥåŕţ ƒŕöɱ Ŵöñķý Šĥééţš one two th]';

  @override
  String chartInsertFromTitle(String title) {
    return '[Îñšéŕţ çĥåŕţ ƒŕöɱ \"$title\" one tw]';
  }

  @override
  String get chartRelinkTitle => '[Çĥåñĝé ļîñķéð çĥåŕţ one tw]';

  @override
  String get chartSearchSpreadsheets => '[Šéåŕçĥ šþŕéåðšĥééţš one two]';

  @override
  String get chartSpreadsheetsLabel => '[Šþŕéåðšĥééţ one]';

  @override
  String get chartTabRecent => '[Ŕéçéñţ one]';

  @override
  String get chartTabMine => '[Ṁý ƒîļéš one]';

  @override
  String get chartTabShared => '[Šĥåŕéð ŵîţĥ ɱé one t]';

  @override
  String get chartTabStarred => '[Šţåŕŕéð one]';

  @override
  String get chartNoSpreadsheets => '[Ñö šþŕéåðšĥééţš ƒöûñð one two]';

  @override
  String get chartListFailed =>
      '[Çöûļðñ\'ţ ļöåð ţĥé ļîšţ. Ţŕý åĝåîñ. one two thr]';

  @override
  String get chartBack => '[Ɓåçķ on]';

  @override
  String get chartSearchCharts => '[Šéåŕçĥ çĥåŕţš one t]';

  @override
  String get chartPickChart => '[Çĥåŕţ on]';

  @override
  String get chartNoCharts =>
      '[Ţĥîš šþŕéåðšĥééţ ĥåš ñö çĥåŕţš. Çŕéåţé öñé îñ Ŵöñķý Šĥééţš. one two three four]';

  @override
  String get chartOpenInSheets => '[Öþéñ îñ Šĥééţš one t]';

  @override
  String get chartLinkToSpreadsheet => '[Ļîñķ ţö šþŕéåðšĥééţ one tw]';

  @override
  String get chartMatchTheme => '[Ṁåţçĥ þŕéšéñţåţîöñ ţĥéɱé one two]';

  @override
  String get chartDataNotice =>
      '[Åñýöñé ŵîţĥ åççéšš ţö ţĥîš þŕéšéñţåţîöñ ŵîļļ šéé ţĥîš çĥåŕţ\'š ðåţå. one two three four f]';

  @override
  String get chartNewerVersion => '[Ñééðš å ñéŵéŕ ṽéŕšîöñ one two]';

  @override
  String get chartSheetBadge => '[Çĥåŕţ šĥééţ one]';

  @override
  String get chart3DBadge => '[3Ð o]';

  @override
  String get chartUntitled => '[Ûñţîţļéð çĥåŕţ one t]';

  @override
  String get chartUpdateAction => '[Ûþðåţé one]';

  @override
  String chartUpdateTooltip(String source, String summary) {
    return '[$source çĥåñĝéð$summary. Ûþðåţé ţö šĥöŵ ţĥé ļåţéšţ ṽéŕšîöñ. one two three]';
  }

  @override
  String get chartStatusLinked => '[Ļîñķéð one]';

  @override
  String get chartStatusChanged => '[Ļîñķéð · Šöûŕçé çĥåñĝéð one two]';

  @override
  String get chartStatusNoAccess => '[Ļîñķéð · Ñö åççéšš one tw]';

  @override
  String get chartStatusChartDeleted => '[Šöûŕçé çĥåŕţ ðéļéţéð one two]';

  @override
  String get chartStatusTrashed => '[Šöûŕçé îñ ţŕåšĥ one t]';

  @override
  String get chartStatusDeleted => '[Šöûŕçé ðéļéţéð one t]';

  @override
  String get chartStatusUnsupported =>
      '[Ļîñķéð · Ñééðš å ñéŵéŕ ṽéŕšîöñ one two t]';

  @override
  String chartStatusOffline(String status) {
    return '[$status (öƒƒļîñé) one]';
  }

  @override
  String chartStatusUpToDate(String when) {
    return '[Ļîñķéð · Ûþ ţö ðåţé ($when) one tw]';
  }

  @override
  String chartNewerDataToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çĥåŕţš ĥåṽé ñéŵéŕ ðåţå',
      one: '1 çĥåŕţ ĥåš ñéŵéŕ ðåţå',
    );
    return '[$_temp0 one two three]';
  }

  @override
  String chartAutoUpdatedToast(String sources) {
    return '[Çĥåŕţš ûþðåţéð ƒŕöɱ $sources one tw]';
  }

  @override
  String get chartPasteNoData =>
      '[Ţĥé çĥåŕţ\'š ðåţå çöûļðñ\'ţ ƀé çöþîéð. Þåšţé îţ åĝåîñ ŵĥéñ ýöû\'ŕé öñļîñé. one two three four fi]';

  @override
  String get chartCopied => '[Çĥåŕţ çöþîéð one]';

  @override
  String get chartCopyFailed => '[Çöûļðñ\'ţ çöþý ţĥé çĥåŕţ. one two]';

  @override
  String chartDataTableTitle(String title) {
    return '[Ðåţå öƒ $title one]';
  }

  @override
  String get chartNoData => '[Ñö ðåţå one]';

  @override
  String get chartNoDataYet => '[Ţĥîš çĥåŕţ ĥåš ñö ðåţå ýéţ. one two]';

  @override
  String get chartNotLinked =>
      '[Ñöţ ļîñķéð: šĥöŵš å çöþý öƒ ţĥé ðåţå. one two thr]';

  @override
  String get chartAutoShort => '[Åûţö-ûþðåţé one]';

  @override
  String get chartUnlinkShort => '[Ûñļîñķ one]';

  @override
  String get chartStyleMode => '[Šţýļé on]';

  @override
  String get chartMatchThemeShort => '[Ṁåţçĥ ţĥéɱé one]';

  @override
  String get chartKeepSource => '[Ķééþ šöûŕçé šţýļé one tw]';

  @override
  String get chartBackground => '[Ɓåçķĝŕöûñð one]';

  @override
  String get chartBackgroundDefault => '[Ðéƒåûļţ one]';

  @override
  String get chartBackgroundTransparent => '[Ţŕåñšþåŕéñţ one]';

  @override
  String get chartBackgroundTheme => '[Šļîðé ƀåçķĝŕöûñð çöļöŕ one two]';

  @override
  String get chartBackgroundWhite => '[Ŵĥîţé on]';

  @override
  String get chartCamera => '[3Ð ṽîéŵ one]';

  @override
  String get chartCameraPreset => '[Ṽîéŵ on]';

  @override
  String get chartCameraCustom => '[Çûšţöɱ one]';

  @override
  String get chartCameraRotation => '[Ŕöţåţîöñ one]';

  @override
  String get chartCameraTilt => '[Ţîļţ on]';

  @override
  String get chartCameraPerspective => '[Þéŕšþéçţîṽé one]';

  @override
  String get chartCameraReset => '[Ŕéšéţ ṽîéŵ one]';

  @override
  String get chartCameraHint =>
      '[Ðŕåĝ ţĥé šéļéçţéð çĥåŕţ ţö öŕƀîţ îţ. Åļţ+Šĥîƒţ+åŕŕöŵš ŕöţåţé 5°. one two three four f]';

  @override
  String get chartPresetDefault => '[Ðéƒåûļţ one]';

  @override
  String get chartPresetFront => '[Ƒŕöñţ on]';

  @override
  String get chartPresetIsometric => '[Îšöɱéţŕîç one]';

  @override
  String get chartPresetTopDown => '[Ţöþ-ðöŵñ one]';

  @override
  String get chartPresetLowAngle => '[Ļöŵ åñĝļé one]';

  @override
  String get chartPresetSide => '[Šîðé on]';

  @override
  String get chartPresetDramatic => '[Ðŕåɱåţîç one]';

  @override
  String get chartPresetFlat => '[Ƒļåţ on]';

  @override
  String get chartPresetTilted => '[Ţîļţéð one]';

  @override
  String get chartPresetSteep => '[Šţééþ on]';

  @override
  String get chartPresenting => '[Þŕéšéñţîñĝ one]';

  @override
  String get chartHoverTooltips => '[Ĥöṽéŕ ṽåļûéš one]';

  @override
  String get chartOrbitInPresent => '[Ðŕåĝ ţö öŕƀîţ one]';

  @override
  String get chartCustomize => '[Çûšţöɱîžé one]';

  @override
  String chartUnusedOverrides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Öṽéŕŕîðéš öƒ $count šéŕîéš ţĥåţ ñö ļöñĝéŕ éẋîšţ',
      one: 'Öṽéŕŕîðéš öƒ 1 šéŕîéš ţĥåţ ñö ļöñĝéŕ éẋîšţš',
    );
    return '[$_temp0 one two three four five s]';
  }

  @override
  String get chartCleanUp => '[Çļéåñ ûþ one]';

  @override
  String get chartInvalidOverrides =>
      '[Šöɱé šţýļé öṽéŕŕîðéš åŕé îñṽåļîð åñð ŵéŕé îĝñöŕéð. one two three fo]';

  @override
  String chartUpdateAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ûþðåţé åļļ ($count)',
      zero: 'Ûþðåţé åļļ',
    );
    return '[$_temp0 one two]';
  }

  @override
  String get chartChecking => '[Çĥéçķîñĝ… one]';

  @override
  String get chartNoLinkedCharts =>
      '[Ţĥîš þŕéšéñţåţîöñ ĥåš ñö ļîñķéð çĥåŕţš. one two thre]';

  @override
  String chartOnSlide(int number) {
    return '[Šļîðé $number on]';
  }

  @override
  String get chartStyleTitles => '[Çĥåŕţ & åẋîš ţîţļéš one tw]';

  @override
  String get chartStyleLegend => '[Ļéĝéñð one]';

  @override
  String get chartStyleSeries => '[Šéŕîéš one]';

  @override
  String get chartStyleAxes => '[Åẋéš on]';

  @override
  String get chartStyleGridlines => '[Ĝŕîðļîñéš one]';

  @override
  String get chartStylePie => '[Þîé çĥåŕţ one]';

  @override
  String get chartStyle3D => '[3Ð o]';

  @override
  String get chartStyleLayout => '[Ļåýöûţ one]';

  @override
  String get chartStyleChartTitle => '[Çĥåŕţ ţîţļé one]';

  @override
  String get chartStyleSubtitle => '[Šûƀţîţļé one]';

  @override
  String get chartStyleHAxisTitle => '[Ĥöŕîžöñţåļ åẋîš ţîţļé one two]';

  @override
  String get chartStyleVAxisTitle => '[Ṽéŕţîçåļ åẋîš ţîţļé one tw]';

  @override
  String get chartStyleLegendPosition => '[Þöšîţîöñ one]';

  @override
  String get chartStyleColor => '[Çöļöŕ on]';

  @override
  String get chartStyleLineWidth => '[Ļîñé ŵîðţĥ one]';

  @override
  String get chartStylePointSize => '[Þöîñţ šîžé one]';

  @override
  String get chartStyleDataLabels => '[Ðåţå ļåƀéļš one]';

  @override
  String get chartStyleHAxisLine => '[Ĥöŕîžöñţåļ åẋîš ļîñé one two]';

  @override
  String get chartStyleVAxisLine => '[Ṽéŕţîçåļ åẋîš ļîñé one tw]';

  @override
  String get chartStyleNumberFormat => '[Ñûɱƀéŕ ƒöŕɱåţ one t]';

  @override
  String get chartStyleHGridlines => '[Ĥöŕîžöñţåļ åẋîš ĝŕîðļîñéš one two t]';

  @override
  String get chartStyleVGridlines => '[Ṽéŕţîçåļ åẋîš ĝŕîðļîñéš one two]';

  @override
  String get chartStyleMaximize => '[Ṁåẋîɱîžé one]';

  @override
  String get chartStyleDonutHole => '[Ðöñûţ ĥöļé one]';

  @override
  String get chartStyleSliceLabels => '[Šļîçé ļåƀéļš one]';

  @override
  String get chartStyleStartAngle => '[Šţåŕţ åñĝļé one]';

  @override
  String get chartStyleLighting => '[Ļîĝĥţîñĝ one]';

  @override
  String get chartStyleWalls => '[Ŵåļļš åñð ƒļööŕ one t]';

  @override
  String get chartStyleDepth => '[Ðéþţĥ on]';

  @override
  String get chartStyleGapDepth => '[Ĝåþ ðéþţĥ one]';

  @override
  String get chartStyleShape => '[Šĥåþé on]';

  @override
  String get chartStyleExplode => '[Éẋþļöðé one]';

  @override
  String get chartStyleAutomatic => '[Åûţöɱåţîç one]';

  @override
  String get chartStyleNone => '[Ñöñé on]';

  @override
  String get chartStyleResetField =>
      '[Ŕéšéţ ţö ţĥé šþŕéåðšĥééţ\'š ṽåļûé one two th]';

  @override
  String get chartStyleChangedHere =>
      '[Çĥåñĝéð îñ ţĥîš þŕéšéñţåţîöñ one two t]';

  @override
  String get chartStyleLegendTop => '[Ţöþ on]';

  @override
  String get chartStyleLegendBottom => '[Ɓöţţöɱ one]';

  @override
  String get chartStyleLegendLeft => '[Ļéƒţ on]';

  @override
  String get chartStyleLegendRight => '[Ŕîĝĥţ on]';

  @override
  String get chartStyleLegendInside => '[Îñšîðé one]';

  @override
  String get chartStyleSliceLabel => '[Ļåƀéļ on]';

  @override
  String get chartStyleSliceValue => '[Ṽåļûé on]';

  @override
  String get chartStyleSlicePercent => '[Þéŕçéñţåĝé one]';

  @override
  String get chartStyleSliceValuePercent => '[Ṽåļûé åñð þéŕçéñţåĝé one two]';

  @override
  String get chartStyleLightingSoft => '[Šöƒţ on]';

  @override
  String get chartStyleLightingBright => '[Ɓŕîĝĥţ one]';

  @override
  String get chartStyleLightingFlat => '[Ƒļåţ on]';

  @override
  String get chartStyleShapeBox => '[Ɓöẋ on]';

  @override
  String get chartStyleShapeCylinder => '[Çýļîñðéŕ one]';

  @override
  String get chartStyleShapeCone => '[Çöñé on]';

  @override
  String get chartStyleShapePyramid => '[Þýŕåɱîð one]';

  @override
  String animateEffectName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'appear': 'Åþþéåŕ',
      'fade': 'Ƒåðé',
      'rise': 'Ŕîšé',
      'moveIn': 'Ṁöṽé îñ',
      'scale': 'Šçåļé',
      'pop': 'Þöþ',
      'zoom': 'Žööɱ',
      'blur': 'Ɓļûŕ',
      'wipe': 'Ŵîþé',
      'iris': 'Îŕîš',
      'dissolve': 'Ðîššöļṽé',
      'drop': 'Ðŕöþ',
      'flip': 'Ƒļîþ',
      'rotate': 'Ŕöţåţé',
      'typewriter': 'Ţýþéŵŕîţéŕ',
      'lineDraw': 'Ðŕåŵ ļîñé',
      'chartGrow': 'Ĝŕöŵ',
      'codeType': 'Ţýþé çöðé',
      'shimmer': 'Šĥîɱɱéŕ',
      'disappear': 'Ðîšåþþéåŕ',
      'fadeOut': 'Ƒåðé öûţ',
      'sink': 'Šîñķ',
      'moveOut': 'Ṁöṽé öûţ',
      'scaleOut': 'Šçåļé öûţ',
      'popOut': 'Þöþ öûţ',
      'zoomOut': 'Žööɱ öûţ',
      'blurOut': 'Ɓļûŕ öûţ',
      'wipeOut': 'Ŵîþé öûţ',
      'irisOut': 'Îŕîš öûţ',
      'dissolveOut': 'Ðîššöļṽé öûţ',
      'fall': 'Ƒåļļ',
      'flipOut': 'Ƒļîþ öûţ',
      'rotateOut': 'Ŕöţåţé öûţ',
      'eraseText': 'Éŕåšé ţéẋţ',
      'lineErase': 'Éŕåšé ļîñé',
      'chartShrink': 'Šĥŕîñķ',
      'pulse': 'Þûļšé',
      'bounce': 'Ɓöûñçé',
      'shake': 'Šĥåķé',
      'blink': 'Ɓļîñķ',
      'spin': 'Šþîñ',
      'grow': 'Ĝŕöŵ / šĥŕîñķ',
      'opacityTo': 'Ţŕåñšþåŕéñçý',
      'colorChange': 'Çöļöŕ çĥåñĝé',
      'highlight': 'Ĥîĝĥļîĝĥţ',
      'chartHighlight': 'Ĥîĝĥļîĝĥţ šéŕîéš',
      'chartHighlightClear': 'Çļéåŕ ĥîĝĥļîĝĥţ',
      'chartOrbit': 'Öŕƀîţ',
      'chartCamera': 'Ŕöţåţé ţö åñĝļé',
      'codeHighlight': 'Ĥîĝĥļîĝĥţ ļîñéš',
      'codeState': 'Ñéẋţ çöðé šţåţé',
      'path': 'Ṁöţîöñ þåţĥ',
      'moveTo': 'Ţŕåñšƒöŕɱ',
      'other': '',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eigh]';
  }

  @override
  String animateEffectDescription(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'appear': 'Ţĥé öƀĵéçţ åþþéåŕš åţ öñçé.',
      'fade': 'Ţĥé öƀĵéçţ ƒåðéš îñ.',
      'rise': 'Ţĥé öƀĵéçţ ɱöṽéš ûþ å šĥöŕţ ðîšţåñçé ŵĥîļé ƒåðîñĝ îñ.',
      'moveIn': 'Ţĥé öƀĵéçţ ɱöṽéš îñ ƒŕöɱ å šîðé öŕ ƒŕöɱ öƒƒ ţĥé šļîðé.',
      'scale': 'Ţĥé öƀĵéçţ ĝŕöŵš ţö îţš šîžé ŵĥîļé ƒåðîñĝ îñ.',
      'pop': 'Ţĥé öƀĵéçţ þöþš îñ ŵîţĥ å ļîţţļé ƀöûñçé.',
      'zoom': 'Ţĥé öƀĵéçţ çöɱéš ţöŵåŕð îţš þļåçé ƒŕöɱ îñ ƒŕöñţ öƒ ţĥé ṽîéŵéŕ.',
      'blur': 'Ţĥé öƀĵéçţ çöɱéš îñţö ƒöçûš.',
      'wipe': 'Å šöƒţ éðĝé šŵééþš åçŕöšš åñð ŕéṽéåļš ţĥé öƀĵéçţ.',
      'iris': 'Å ĝŕöŵîñĝ çîŕçļé, šǫûåŕé öŕ ðîåɱöñð ŕéṽéåļš ţĥé öƀĵéçţ.',
      'dissolve': 'Ţĥé öƀĵéçţ åþþéåŕš ţĥŕöûĝĥ å ĝŕåîñ öƒ ŕåñðöɱ çéļļš.',
      'drop': 'Ţĥé öƀĵéçţ ƒåļļš îñţö þļåçé åñð ƀöûñçéš.',
      'flip': 'Ţĥé öƀĵéçţ ƒļîþš îñţö ṽîéŵ ļîķé å çåŕð.',
      'rotate': 'Ţĥé öƀĵéçţ ţûŕñš îñţö þļåçé.',
      'typewriter': 'Ţĥé ţéẋţ îš ţýþéð çĥåŕåçţéŕ ƀý çĥåŕåçţéŕ.',
      'lineDraw': 'Ţĥé öûţļîñé ðŕåŵš îţšéļƒ, ţĥéñ ţĥé ƒîļļ ƒåðéš îñ.',
      'chartGrow': 'Ɓåŕš ĝŕöŵ, ļîñéš ðŕåŵ öñ åñð ŵéðĝéš šŵééþ îñ.',
      'codeType': 'Ţĥé çöðé îš ţýþéð îñţö ţĥé ƀļöçķ.',
      'shimmer': 'Þåŕţîçļéš çöñðéñšé îñţö ţĥé ţéẋţ.',
      'disappear': 'Ţĥé öƀĵéçţ ðîšåþþéåŕš åţ öñçé.',
      'fadeOut': 'Ţĥé öƀĵéçţ ƒåðéš öûţ.',
      'sink': 'Ţĥé öƀĵéçţ ɱöṽéš ðöŵñ å šĥöŕţ ðîšţåñçé ŵĥîļé ƒåðîñĝ öûţ.',
      'moveOut': 'Ţĥé öƀĵéçţ ɱöṽéš öûţ ţö å šîðé öŕ öƒƒ ţĥé šļîðé.',
      'scaleOut': 'Ţĥé öƀĵéçţ šĥŕîñķš ŵĥîļé ƒåðîñĝ öûţ.',
      'popOut': 'Ţĥé öƀĵéçţ ĝŕöŵš å ļîţţļé, ţĥéñ çöļļåþšéš.',
      'zoomOut': 'Ţĥé öƀĵéçţ ɱöṽéš ţöŵåŕð ţĥé ṽîéŵéŕ åñð ƒåðéš åŵåý.',
      'blurOut': 'Ţĥé öƀĵéçţ ĝöéš öûţ öƒ ƒöçûš.',
      'wipeOut': 'Å šöƒţ éðĝé šŵééþš åçŕöšš åñð ĥîðéš ţĥé öƀĵéçţ.',
      'irisOut': 'Å šĥŕîñķîñĝ çîŕçļé, šǫûåŕé öŕ ðîåɱöñð ĥîðéš ţĥé öƀĵéçţ.',
      'dissolveOut': 'Ţĥé öƀĵéçţ ðîšåþþéåŕš îñţö å ĝŕåîñ öƒ ŕåñðöɱ çéļļš.',
      'fall': 'Ţĥé öƀĵéçţ ƒåļļš öƒƒ ţĥé šļîðé.',
      'flipOut': 'Ţĥé öƀĵéçţ ƒļîþš åŵåý ļîķé å çåŕð.',
      'rotateOut': 'Ţĥé öƀĵéçţ ţûŕñš åŵåý.',
      'eraseText': 'Ţĥé ţéẋţ îš éŕåšéð ƒŕöɱ ţĥé éñð, ļîķé ƀåçķšþåçîñĝ.',
      'lineErase': 'Ţĥé öûţļîñé éŕåšéš îţšéļƒ.',
      'chartShrink': 'Ɓåŕš šĥŕîñķ, ļîñéš éŕåšé åñð ŵéðĝéš šŵééþ öûţ.',
      'pulse': 'Ţĥé öƀĵéçţ ƀŕîéƒļý ĝŕöŵš åñð ŕéţûŕñš.',
      'bounce': 'Ţĥé öƀĵéçţ ĵûɱþš ûþ åñð ļåñðš.',
      'shake': 'Ţĥé öƀĵéçţ šĥåķéš ƒŕöɱ šîðé ţö šîðé.',
      'blink': 'Ţĥé öƀĵéçţ ƀļîñķš.',
      'spin': 'Ţĥé öƀĵéçţ šþîñš åñð ķééþš îţš ñéŵ åñĝļé.',
      'grow': 'Ţĥé öƀĵéçţ çĥåñĝéš îţš šîžé åñð ķééþš îţ.',
      'opacityTo': 'Ţĥé öƀĵéçţ ƀéçöɱéš ɱöŕé öŕ ļéšš ţŕåñšþåŕéñţ.',
      'colorChange': 'Ţĥé ƒîļļ, ƀöŕðéŕ öŕ ţéẋţ çĥåñĝéš çöļöŕ.',
      'highlight': 'Å ɱåŕķéŕ šŵééþš ƀéĥîñð ţĥé ţéẋţ.',
      'chartHighlight': 'Öñé šéŕîéš šţåñðš öûţ; ţĥé ŕéšţ ðîɱš.',
      'chartHighlightClear': 'Éṽéŕý šéŕîéš îš šĥöŵñ ñöŕɱåļļý åĝåîñ.',
      'chartOrbit': 'Ţĥé 3Ð çĥåŕţ ţûŕñš åŕöûñð.',
      'chartCamera': 'Ţĥé 3Ð çĥåŕţ ţûŕñš ţö å ñéŵ ṽîéŵ.',
      'codeHighlight': 'Ţĥé ñéẋţ ĥîĝĥļîĝĥţ šţéþ öƒ ţĥé çöðé îš šĥöŵñ.',
      'codeState': 'Ţĥé çöðé çĥåñĝéš ţö îţš ñéẋţ šţåţé.',
      'path': 'Ţĥé öƀĵéçţ ɱöṽéš åļöñĝ å þåţĥ.',
      'moveTo': 'Ţĥé öƀĵéçţ ɱöṽéš, ŕéšîžéš, ţûŕñš öŕ ƒåðéš ţö åñ éñð šţåţé.',
      'other': 'Åñ åñîɱåţîöñ ƒŕöɱ å ñéŵéŕ ṽéŕšîöñ.',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven e]';
  }

  @override
  String animateTransitionName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'none': 'Ñöñé',
      'fade': 'Ƒåðé',
      'dissolve': 'Ðîššöļṽé',
      'push': 'Þûšĥ',
      'slide': 'Šļîðé îñ',
      'cover': 'Çöṽéŕ',
      'uncover': 'Ûñçöṽéŕ',
      'wipe': 'Ŵîþé',
      'iris': 'Îŕîš',
      'zoom': 'Žööɱ',
      'flip': 'Ƒļîþ',
      'cube': 'Çûƀé',
      'doorway': 'Ðööŕŵåý',
      'swap': 'Šŵåþ',
      'revolve': 'Ŕéṽöļṽé',
      'magicMove': 'Ṁåĝîç Ṁöṽé',
      'other': 'Ţŕåñšîţîöñ',
    });
    return '[$_temp0 one two three four five six seven]';
  }

  @override
  String animateTransitionDescription(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'none': 'Ţĥé ñéŵ šļîðé ŕéþļåçéš ţĥé öļð öñé åţ öñçé.',
      'fade':
          'Ţĥé ñéŵ šļîðé ƒåðéš îñ öṽéŕ ţĥé öļð öñé, öŕ ƀöţĥ ƒåðé ţĥŕöûĝĥ å çöļöŕ.',
      'dissolve': 'Ţĥé ñéŵ šļîðé åþþéåŕš ţĥŕöûĝĥ å ĝŕåîñ öƒ ŕåñðöɱ çéļļš.',
      'push': 'Ţĥé ñéŵ šļîðé þûšĥéš ţĥé öļð öñé öƒƒ ţĥé šçŕééñ.',
      'slide': 'Ţĥé ñéŵ šļîðé šļîðéš îñ öṽéŕ ţĥé öļð öñé.',
      'cover': 'Ţĥé ñéŵ šļîðé šļîðéš öṽéŕ ţĥé öļð öñé, ŵĥîçĥ ðîɱš.',
      'uncover': 'Ţĥé öļð šļîðé šļîðéš åŵåý åñð ŕéṽéåļš ţĥé ñéŵ öñé.',
      'wipe': 'Å šöƒţ éðĝé šŵééþš åçŕöšš åñð ŕéṽéåļš ţĥé ñéŵ šļîðé.',
      'iris': 'Å ĝŕöŵîñĝ çîŕçļé, šǫûåŕé öŕ ðîåɱöñð ŕéṽéåļš ţĥé ñéŵ šļîðé.',
      'zoom': 'Ţĥé ñéŵ šļîðé ĝŕöŵš îñ, öŕ ţĥé öļð öñé šĥŕîñķš åŵåý.',
      'flip': 'Ţĥé šļîðé ƒļîþš öṽéŕ ļîķé å çåŕð; ţĥé ñéŵ šļîðé îš öñ îţš ƀåçķ.',
      'cube': 'Ɓöţĥ šļîðéš åŕé ƒåçéš öƒ å çûƀé ţĥåţ ţûŕñš å ǫûåŕţéŕ ţûŕñ.',
      'doorway':
          'Ţĥé öļð šļîðé öþéñš ļîķé ðöûƀļé ðööŕš; ţĥé ñéŵ öñé çöɱéš ƒöŕŵåŕð.',
      'swap': 'Ţĥé šļîðéš šŵåþ þļåçéš, ƒŕöñţ åñð ƀåçķ, öñ åñ åŕç.',
      'revolve': 'Ţĥé öļð šļîðé šŵîñĝš åŵåý öñ îţš éðĝé ļîķé å ðööŕ.',
      'magicMove':
          'Öƀĵéçţš öñ ƀöţĥ šļîðéš ɱöŕþĥ îñţö éåçĥ öţĥéŕ; ţĥé ŕéšţ ƒåðéš.',
      'other': '',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one]';
  }

  @override
  String animateParamName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'distance': 'Ðîšţåñçé',
      'fade': 'Ƒåðé',
      'direction': 'Ðîŕéçţîöñ',
      'from': 'Ƒŕöɱ',
      'to': 'Ţö',
      'origin': 'Öŕîĝîñ',
      'bounce': 'Ɓöûñçé',
      'softness': 'Šöƒţñéšš',
      'shape': 'Šĥåþé',
      'cell': 'Ĝŕåîñ',
      'height': 'Ĥéîĝĥţ',
      'bounces': 'Ɓöûñçéš',
      'axis': 'Åẋîš',
      'perspective': 'Þéŕšþéçţîṽé',
      'angle': 'Åñĝļé',
      'scale': 'Šçåļé',
      'cps': 'Çĥåŕåçţéŕš/š',
      'caret': 'Çåŕéţ',
      'jitter': 'Ĵîţţéŕ',
      'fillDelay': 'Ƒîļļ ðéļåý',
      'count': 'Ţîɱéš',
      'amplitude': 'Åɱþļîţûðé',
      'opacity': 'Öþåçîţý',
      'property': 'Þŕöþéŕţý',
      'color': 'Çöļöŕ',
      'style': 'Šţýļé',
      'target': 'Šéŕîéš',
      'dimOthers': 'Ðîɱ öţĥéŕš',
      'azimuth': 'Åžîɱûţĥ',
      'elevation': 'Éļéṽåţîöñ',
      'step': 'Šţéþ',
      'state': 'Šţåţé',
      'mode': 'Ṁöðé',
      'path': 'Þåţĥ',
      'preset': 'Þŕéšéţ',
      'orientToPath': 'Öŕîéñţ ţö þåţĥ',
      'relativeEnd': 'Ŕéļåţîṽé éñð',
      'anticipation': 'Åñţîçîþåţîöñ',
      'rotation': 'Ŕöţåţîöñ',
      'through': 'Ţĥŕöûĝĥ çöļöŕ',
      'persist': 'Ķééþ éñð šţåţé',
      'other': 'Öþţîöñ',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven eight nine ten one t]';
  }

  @override
  String animateChoiceName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'left': 'Ļéƒţ',
      'right': 'Ŕîĝĥţ',
      'top': 'Ţöþ',
      'bottom': 'Ɓöţţöɱ',
      'up': 'Ûþ',
      'down': 'Ðöŵñ',
      'topLeft': 'Ţöþ ļéƒţ',
      'topRight': 'Ţöþ ŕîĝĥţ',
      'bottomLeft': 'Ɓöţţöɱ ļéƒţ',
      'bottomRight': 'Ɓöţţöɱ ŕîĝĥţ',
      'center': 'Çéñţéŕ',
      'circle': 'Çîŕçļé',
      'rect': 'Šǫûåŕé',
      'diamond': 'Ðîåɱöñð',
      'x': 'Ĥöŕîžöñţåļ',
      'y': 'Ṽéŕţîçåļ',
      'forward': 'Ƒöŕŵåŕð',
      'backward': 'Ɓåçķŵåŕð',
      'in': 'Îñ',
      'out': 'Öûţ',
      'baseline': 'Ɓåšéļîñé',
      'fill': 'Ƒîļļ',
      'stroke': 'Ɓöŕðéŕ',
      'text': 'Ţéẋţ',
      'marker': 'Ṁåŕķéŕ',
      'underline': 'Ûñðéŕļîñé',
      'box': 'Ɓöẋ',
      'type': 'Ţýþé',
      'morph': 'Ṁöŕþĥ',
      'instant': 'Îñšţåñţ',
      'line': 'Ļîñé',
      'arc': 'Åŕç',
      'curve': 'Çûŕṽé',
      'zigzag': 'Žîĝžåĝ',
      'custom': 'Çûšţöɱ',
      'object': 'Öƀĵéçţ',
      'word': 'Ŵöŕð',
      'character': 'Çĥåŕåçţéŕ',
      'shortest': 'Šĥöŕţéšţ',
      'literal': 'Åš šéţ',
      'other': '—',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven]';
  }

  @override
  String animateTargetReason(String effect, String target) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'text': '$effect ŵöŕķš öñ ţéẋţ öñļý',
      'stroke': '$effect ŵöŕķš öñ šĥåþéš, ļîñéš åñð îçöñš',
      'colorable': '$effect ŵöŕķš öñ šĥåþéš, ţéẋţ, ļîñéš åñð îçöñš',
      'chart': '$effect ŵöŕķš öñ çĥåŕţš öñļý',
      'chart3d': '$effect ŵöŕķš öñ 3Ð çĥåŕţš öñļý',
      'code': '$effect ŵöŕķš öñ çöðé ƀļöçķš öñļý',
      'other': '$effect ðöéšñ\'ţ ŵöŕķ öñ ţĥîš öƀĵéçţ',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one t]';
  }

  @override
  String animateTriggerName(String trigger) {
    String _temp0 = intl.Intl.selectLogic(trigger, {
      'onClick': 'Öñ çļîçķ',
      'withPrevious': 'Ŵîţĥ þŕéṽîöûš',
      'afterPrevious': 'Åƒţéŕ þŕéṽîöûš',
      'other': 'Öñ çļîçķ öƒ åñ öƀĵéçţ',
    });
    return '[$_temp0 one two three four]';
  }

  @override
  String animateDeliveryName(String by) {
    String _temp0 = intl.Intl.selectLogic(by, {
      'all': 'Åļļ åţ öñçé',
      'paragraph': 'Ɓý þåŕåĝŕåþĥ',
      'paragraphGroup': 'Ɓý þåŕåĝŕåþĥ ĝŕöûþ',
      'line': 'Ɓý ļîñé',
      'word': 'Ɓý ŵöŕð',
      'character': 'Ɓý çĥåŕåçţéŕ',
      'series': 'Ɓý šéŕîéš',
      'category': 'Ɓý çåţéĝöŕý',
      'point': 'Ɓý þöîñţ',
      'chartElement': 'Ɓý çĥåŕţ éļéɱéñţ',
      'other': 'Åļļ åţ öñçé',
    });
    return '[$_temp0 one two three four five six seven eigh]';
  }

  @override
  String animateOrderName(String order) {
    String _temp0 = intl.Intl.selectLogic(order, {
      'forward': 'Ƒöŕŵåŕð',
      'backward': 'Ɓåçķŵåŕð',
      'center': 'Ƒŕöɱ ţĥé çéñţéŕ',
      'edges': 'Ƒŕöɱ ţĥé éðĝéš',
      'random': 'Ŕåñðöɱ',
      'other': 'Ƒöŕŵåŕð',
    });
    return '[$_temp0 one two three four]';
  }

  @override
  String animateAfterBuildName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'none': 'Ķééþ',
      'dim': 'Ðîɱ',
      'hide': 'Ĥîðé',
      'other': 'Ķééþ',
    });
    return '[$_temp0 one tw]';
  }

  @override
  String animateEasingName(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'smooth': 'Šɱööţĥ',
      'snappy': 'Šñåþþý',
      'bouncy': 'Ɓöûñçý',
      'gentle': 'Ĝéñţļé',
      'linear': 'Ļîñéåŕ',
      'easeIn': 'Éåšé îñ',
      'easeOut': 'Éåšé öûţ',
      'custom': 'Çûšţöɱ',
      'other': 'Çûšţöɱ',
    });
    return '[$_temp0 one two three four f]';
  }

  @override
  String animateGroupName(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'basic': 'Ɓåšîç',
      'exciting': 'Éẋçîţîñĝ',
      'emphasis': 'Éɱþĥåšîš',
      'text': 'Ţéẋţ',
      'shape': 'Šĥåþé',
      'motion': 'Ṁöţîöñ',
      'chart': 'Çĥåŕţ',
      'code': 'Çöðé',
      'threeD': '3Ð',
      'magic': 'Ṁåĝîç Ṁöṽé',
      'other': 'Ṁöŕé',
    });
    return '[$_temp0 one two three four fi]';
  }

  @override
  String animateKindTab(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'buildIn': 'Îñ',
      'action': 'Åçţîöñ',
      'buildOut': 'Öûţ',
      'other': 'Îñ',
    });
    return '[$_temp0 one t]';
  }

  @override
  String animateUnmatchedName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'together': 'Ƒåðé ŵîţĥ ţĥé ɱöṽé',
      'before': 'Ƒåðé öûţ ƒîŕšţ',
      'after': 'Ƒåðé îñ åƒţéŕ',
      'other': 'Ƒåðé ŵîţĥ ţĥé ɱöṽé',
    });
    return '[$_temp0 one two three four]';
  }

  @override
  String animatePreviewOption(String option) {
    String _temp0 = intl.Intl.selectLogic(option, {
      'autoPreview': 'Åûţö-þŕéṽîéŵ çĥåñĝéš',
      'includeTransition': 'Îñçļûðé ţŕåñšîţîöñ îñ þŕéṽîéŵ',
      'fullMotion': 'Þŕéṽîéŵ ƒûļļ ɱöţîöñ',
      'other': 'Öþţîöñ',
    });
    return '[$_temp0 one two three four five]';
  }

  @override
  String animateWarning(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'elementMissing': 'Ţĥé öƀĵéçţ ñö ļöñĝéŕ éẋîšţš.',
      'alreadyVisible': 'Ţĥé öƀĵéçţ îš åļŕéåðý ṽîšîƀļé: ţĥîš ƀûîļð îš šķîþþéð.',
      'alreadyHidden': 'Ţĥé öƀĵéçţ îš åļŕéåðý ĥîððéñ: ţĥîš ƀûîļð îš šķîþþéð.',
      'hiddenTarget':
          'Ţĥé öƀĵéçţ îš ĥîððéñ åţ ţĥîš þöîñţ: ţĥîš ƀûîļð îš šķîþþéð.',
      'unsupportedEffect':
          'Éƒƒéçţ ñöţ šûþþöŕţéð ƀý ţĥîš ṽéŕšîöñ: þļåýš åš å ƒåðé.',
      'wrongElementKind':
          'Ţĥîš éƒƒéçţ ðöéšñ\'ţ ŵöŕķ öñ ţĥîš öƀĵéçţ: îţ îš šķîþþéð.',
      'unsupportedTrigger':
          'Ţĥîš ţŕîĝĝéŕ îšñ\'ţ šûþþöŕţéð ýéţ: ţĥé ƀûîļð îš šķîþþéð.',
      'invalidOptions': 'Šöɱé öþţîöñš åŕé îñṽåļîð åñð ûšé ţĥéîŕ ðéƒåûļţš.',
      'invalidEasing': 'Ţĥé éåšîñĝ îš îñṽåļîð åñð þļåýš åš éåšé öûţ.',
      'deliveryFallback':
          'Ţĥîš öƀĵéçţ çåñ\'ţ ƀé ƀûîļţ îñ ţĥéšé þåŕţš: îţ ƀûîļðš åš å ŵĥöļé.',
      'codeStepMissing': 'Ţĥé çöðé ĥåš ñö šûçĥ ĥîĝĥļîĝĥţ šţéþ.',
      'codeStateMissing': 'Ţĥé çöðé ĥåš ñö šûçĥ šţåţé.',
      'flashLimit': 'Ɓļîñķîñĝ îš šļöŵéð ţö åţ ɱöšţ 3 ƒļåšĥéš þéŕ šéçöñð.',
      'other': 'Ţĥîš ƀûîļð þļåýš ðîƒƒéŕéñţļý ţĥåñ šéţ.',
    });
    return '[$_temp0 one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten one two three four five six seven eight nine ten]';
  }

  @override
  String get animateAddAnother => '[Åðð åñöţĥéŕ ƀûîļð one tw]';

  @override
  String get animateAdvance => '[Åðṽåñçé one]';

  @override
  String get animateAdvanceAfter => '[Åƒţéŕ on]';

  @override
  String get animateAdvanceAuto => '[Åûţöɱåţîçåļļý one t]';

  @override
  String get animateAdvanceClick => '[Öñ çļîçķ one]';

  @override
  String get animateAfterBuild => '[Åƒţéŕ ƀûîļð one]';

  @override
  String get animateAnimatedObjects => '[Åñîɱåţéð öƀĵéçţš one tw]';

  @override
  String get animateAutoBuilds => '[Þļåý ƀûîļðš åûţöɱåţîçåļļý one two t]';

  @override
  String get animateAutoReverse => '[Þļåý ƀåçķ åñð ƒöŕţĥ one tw]';

  @override
  String get animateBuildDelay => '[Ɓéţŵééñ ƀûîļðš one t]';

  @override
  String get animateDelay => '[Ðéļåý on]';

  @override
  String get animateDelivery => '[Þåŕţš on]';

  @override
  String get animateDeliveryLabel => '[Ɓûîļð on]';

  @override
  String get animateDimTo => '[Ðîɱ ţö on]';

  @override
  String get animateDuration => '[Ðûŕåţîöñ one]';

  @override
  String get animateDurationAutomatic => '[Åûţöɱåţîç one]';

  @override
  String get animateEasing => '[Éåšîñĝ one]';

  @override
  String get animateEffectUnsupported =>
      '[Éƒƒéçţ ñöţ šûþþöŕţéð ƀý ţĥîš ṽéŕšîöñ one two thr]';

  @override
  String get animateEndState => '[Éñð šţåţé one]';

  @override
  String get animateHeight => '[Ĥéîĝĥţ one]';

  @override
  String get animateHideMatches => '[Ĥîðé ɱåţçĥéš one]';

  @override
  String get animateMagicMoveFirstSlide =>
      '[Ţĥé ƒîŕšţ šļîðé ĥåš ñöţĥîñĝ ţö ɱöŕþĥ ƒŕöɱ. one two three]';

  @override
  String get animateMagicMoveNoMatches =>
      '[Ñö öƀĵéçţš ɱåţçĥ ţĥé þŕéṽîöûš šļîðé: þļåýš åš å çŕöššƒåðé. one two three four]';

  @override
  String get animateMatchByContent => '[Ṁåţçĥ îðéñţîçåļ çöñţéñţ one two]';

  @override
  String get animateMatchTextBy => '[Ṁåţçĥ ţéẋţ ƀý one]';

  @override
  String get animateMissingObject => '[Ðéļéţéð öƀĵéçţ one t]';

  @override
  String get animateMoveDown => '[Ṁöṽé ðöŵñ one]';

  @override
  String get animateMoveUp => '[Ṁöṽé ûþ one]';

  @override
  String get animateNewClick => '[Ñéŵ çļîçķ one]';

  @override
  String get animateNoSlide => '[Åñîɱåţîöñš åþþļý ţö šļîðéš. one two t]';

  @override
  String get animateOffSlide => '[Ƒŕöɱ öƒƒ ţĥé šļîðé one tw]';

  @override
  String get animateOrderListLabel => '[Ɓûîļð öŕðéŕ one]';

  @override
  String get animateOrderNone =>
      '[Ñö åñîɱåţîöñš öñ ţĥîš šļîðé ýéţ. Šéļéçţ åñ öƀĵéçţ åñð þîçķ åñ éƒƒéçţ öñ ţĥé Ɓûîļð ţåƀ. one two three four five s]';

  @override
  String get animatePartOrder => '[Öŕðéŕ on]';

  @override
  String get animatePartStart => '[Éåçĥ þåŕţ one]';

  @override
  String get animatePartsFrom => '[Þåŕţš on]';

  @override
  String get animatePartsTo => '[ţö o]';

  @override
  String get animatePathPreset => '[Þåţĥ on]';

  @override
  String get animatePlayFromSelected => '[Þļåý ƒŕöɱ šéļéçţéð one tw]';

  @override
  String get animatePreview => '[Þŕéṽîéŵ one]';

  @override
  String get animatePreviewFromHere => '[Þŕéṽîéŵ ƒŕöɱ ĥéŕé one tw]';

  @override
  String get animatePreviewFullMotion => '[Þŕéṽîéŵ ƒûļļ ɱöţîöñ one tw]';

  @override
  String get animatePreviewOptions => '[Þŕéṽîéŵ öþţîöñš one t]';

  @override
  String get animatePreviewPlaying => '[Þŕéṽîéŵîñĝ åñîɱåţîöñš one two]';

  @override
  String get animatePreviewReduced => '[Þŕéṽîéŵ ŕéðûçéð ɱöţîöñ one two]';

  @override
  String get animatePreviewStop => '[Šţöþ on]';

  @override
  String get animateReducedMotionOn =>
      '[Ŕéðûçé ɱöţîöñ îš öñ — åñîɱåţîöñš þļåý åš ƒåðéš. one two three]';

  @override
  String get animateReducedMotionSettings => '[Šéţţîñĝš one]';

  @override
  String get animateRemoveTransition => '[Ŕéɱöṽé one]';

  @override
  String get animateRepeat => '[Ŕéþéåţ one]';

  @override
  String get animateRepeatCount => '[Ţîɱéš on]';

  @override
  String get animateReturnToStart => '[Ŕéţûŕñ ţö ţĥé šţåŕţ one tw]';

  @override
  String get animateReverseOnBack =>
      '[Þļåý ƀåçķŵåŕðš ŵĥéñ ĝöîñĝ ƀåçķ one two th]';

  @override
  String get animateRotation => '[Ŕöţåţîöñ one]';

  @override
  String get animateSearchEffects => '[Šéåŕçĥ éƒƒéçţš one t]';

  @override
  String get animateSelectObject =>
      '[Šéļéçţ åñ öƀĵéçţ ţö åñîɱåţé îţ. one two th]';

  @override
  String get animateSelectObjectItem => '[Šéļéçţ öƀĵéçţ one t]';

  @override
  String get animateSetTrigger => '[Šţåŕţ on]';

  @override
  String get animateShowMatches => '[Šĥöŵ ɱåţçĥéš one]';

  @override
  String get animateShowParts => '[Šĥöŵ þåŕţš one]';

  @override
  String get animateStagger => '[Šţåĝĝéŕ one]';

  @override
  String get animateStaggerParts => '[Šţåĝĝéŕ one]';

  @override
  String get animateStart => '[Šţåŕţ on]';

  @override
  String get animateStepAutomatic => '[Åûţöɱåţîç one]';

  @override
  String get animateTiming => '[Ţîɱîñĝ one]';

  @override
  String get animateTransitionInherited =>
      '[Ûšéš ţĥé þŕéšéñţåţîöñ\'š ðéƒåûļţ ţŕåñšîţîöñ. one two three]';

  @override
  String get animateUnmatched => '[Ûñɱåţçĥéð one]';

  @override
  String get animateUntilNextClick => '[Ûñţîļ ţĥé ñéẋţ çļîçķ one tw]';

  @override
  String get animateWidth => '[Ŵîðţĥ on]';

  @override
  String get cmdAnimateBuildAllSteps => '[Ɓûîļð åļļ šţéþš one t]';

  @override
  String get cmdAnimateMoveBuilds => '[Ŕéöŕðéŕ åñîɱåţîöñš one tw]';

  @override
  String get cmdAnimateSelectBuilds => '[Šéļéçţ åñîɱåţîöñš one tw]';

  @override
  String get cmdAnimateSetMotionPath => '[Éðîţ ɱöţîöñ þåţĥ one t]';

  @override
  String get cmdAnimateSetTransformTarget => '[Šéţ éñð šţåţé one]';

  @override
  String get cmdAnimateSetTrigger => '[Šéţ åñîɱåţîöñ šţåŕţ one tw]';

  @override
  String get cmdAnimateStopPreview => '[Šţöþ þŕéṽîéŵ one]';

  @override
  String get cmdAnimateTogglePreviewOption => '[Þŕéṽîéŵ öþţîöñ one t]';

  @override
  String get cmdAnimateUpdateBuild => '[Éðîţ åñîɱåţîöñ one t]';

  @override
  String get cmdElementSetMatchKey => '[Šéţ Ṁåĝîç Ṁöṽé ÎÐ one t]';

  @override
  String get cmdTransitionApplyToAll =>
      '[Åþþļý ţŕåñšîţîöñ ţö åļļ šļîðéš one two th]';

  @override
  String get cmdTransitionPreview => '[Þŕéṽîéŵ ţŕåñšîţîöñ one tw]';

  @override
  String get cmdTransitionRemove => '[Ŕéɱöṽé ţŕåñšîţîöñ one tw]';

  @override
  String get cmdTransitionSet => '[Šéţ ţŕåñšîţîöñ one t]';

  @override
  String get cmdTransitionSetAdvance => '[Šéţ šļîðé åðṽåñçé one tw]';

  @override
  String get reasonNoBuilds => '[Ţĥîš šļîðé ĥåš ñö åñîɱåţîöñš one two t]';

  @override
  String get reasonNoBuildsCopied => '[Çöþý åñ åñîɱåţîöñ ƒîŕšţ one two]';

  @override
  String get reasonNotPreviewing => '[Ñö þŕéṽîéŵ îš þļåýîñĝ one two]';

  @override
  String get reasonObjectNoBuilds => '[Šéļéçţ öñé åñîɱåţéð öƀĵéçţ one two t]';

  @override
  String get reasonSelectBuild => '[Šéļéçţ åñ åñîɱåţîöñ one tw]';

  @override
  String get reasonSelectCodeOrChart =>
      '[Šéļéçţ å çöðé ƀļöçķ ŵîţĥ šţéþš öŕ å çĥåŕţ one two thre]';

  @override
  String get undoAddMagicMoveSlide => '[Åðð Ṁåĝîç Ṁöṽé šļîðé one tw]';

  @override
  String get undoRemoveAnimation => '[Ŕéɱöṽé åñîɱåţîöñ one tw]';

  @override
  String animateBadgeTooltip(String name, String steps) {
    return '[$name: šţéþ $steps on]';
  }

  @override
  String animateBuildsSelected(int count) {
    return '[$count åñîɱåţîöñš one]';
  }

  @override
  String animateObjectsSelected(int count) {
    return '[$count öƀĵéçţš one]';
  }

  @override
  String animateMagicMoveMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öƀĵéçţš ɱåţçĥ ţĥé þŕéṽîöûš šļîðé',
      one: '1 öƀĵéçţ ɱåţçĥéš ţĥé þŕéṽîöûš šļîðé',
    );
    return '[$_temp0 one two three four fi]';
  }

  @override
  String animateMatchTooltip(String name, int number) {
    return '[Ṁåţçĥéš “$name” öñ šļîðé $number one tw]';
  }

  @override
  String animateOrderSummary(int clicks, String seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      clicks,
      locale: localeName,
      other: '$clicks çļîçķš',
      one: '1 çļîçķ',
      zero: 'Ñö çļîçķš',
    );
    return '[$_temp0 · $seconds š one two]';
  }

  @override
  String animatePartLabel(int index, String text) {
    return '[Þåŕţ $index: $text on]';
  }

  @override
  String animatePartsCount(int count) {
    return '[$count þåŕţš on]';
  }

  @override
  String animateSettles(String seconds) {
    return '[≈ $seconds š o]';
  }

  @override
  String animateStepClick(int index) {
    return '[Çļîçķ $index on]';
  }

  @override
  String animateTransitionForSlide(int number) {
    return '[Ţŕåñšîţîöñ îñţö šļîðé $number one two]';
  }

  @override
  String animateTransitionForSlides(int count) {
    return '[Ţŕåñšîţîöñ îñţö $count šļîðéš one two]';
  }

  @override
  String get arrangeLabelMatchKey => '[Ṁåĝîç Ṁöṽé ÎÐ one]';

  @override
  String get cmdOutlineSetTitle => '[Éðîţ šļîðé ţîţļé one t]';

  @override
  String get cmdOutlineSetBody => '[Éðîţ šļîðé ţéẋţ one t]';

  @override
  String get cmdOutlineNewSlideAfter => '[Ñéŵ šļîðé åƒţéŕ ţĥîš öñé one two]';

  @override
  String get cmdOutlineNewLine => '[Ñéŵ ƀûļļéţ one]';

  @override
  String get cmdOutlineFocusBody => '[Ĝö ţö ţĥé šļîðé’š ƀûļļéţš one two]';

  @override
  String get cmdOutlineIndent => '[Îñðéñţ (ðéɱöţé) one t]';

  @override
  String get cmdOutlineOutdent => '[Öûţðéñţ (þŕöɱöţé) one tw]';

  @override
  String get cmdOutlineMoveUp => '[Ṁöṽé ûþ one]';

  @override
  String get cmdOutlineMoveDown => '[Ṁöṽé ðöŵñ one]';

  @override
  String get cmdOutlineJoinLine => '[Ĵöîñ ŵîţĥ ţĥé ļîñé åƀöṽé one two]';

  @override
  String get cmdOutlineCopyMarkdown => '[Çöþý öûţļîñé åš Ṁåŕķðöŵñ one two]';

  @override
  String get cmdArrangeSetZ => '[Ŕéöŕðéŕ one]';

  @override
  String get cmdA11ySetReadingOrder => '[Ŕéåðîñĝ öŕðéŕ one t]';

  @override
  String get cmdA11yResetReadingOrder => '[Ŕéšéţ ţö åûţöɱåţîç one tw]';

  @override
  String get cmdA11yGoTo => '[Ĝö ţö îššûé one]';

  @override
  String get cmdA11yFix => '[Ƒîẋ åççéššîƀîļîţý îššûé one two]';

  @override
  String get reasonOutlineLine =>
      '[Þļåçé ţĥé çûŕšöŕ îñ åñ öûţļîñé ļîñé one two thr]';

  @override
  String get reasonOutlineNoTitle =>
      '[Ţĥîš šļîðé’š ļåýöûţ ĥåš ñö ţîţļé one two th]';

  @override
  String get reasonOutlineNoBody =>
      '[Ţĥîš šļîðé ĥåš ñö ţéẋţ þļåçéĥöļðéŕ one two thr]';

  @override
  String get reasonReadingOrderAutomatic =>
      '[Ţĥé ŕéåðîñĝ öŕðéŕ îš åļŕéåðý åûţöɱåţîç one two thre]';

  @override
  String get reasonA11yNoFix => '[Ţĥîš îššûé ĥåš ñö åûţöɱåţîç ƒîẋ one two th]';

  @override
  String get outlineHint =>
      '[Éñţéŕ: ñéŵ šļîðé öŕ ƀûļļéţ · Ţåƀ: îñðéñţ · Šĥîƒţ+Ţåƀ: öûţðéñţ one two three four]';

  @override
  String get outlineReadOnlyHint => '[Ṽîéŵ öñļý one]';

  @override
  String outlineSlideNumber(int number) {
    return '[Šļîðé $number on]';
  }

  @override
  String outlineTitleLabel(int number) {
    return '[Ţîţļé öƒ šļîðé $number one t]';
  }

  @override
  String outlineBulletLabel(int slide, int bullet, int level) {
    return '[Šļîðé $slide, ƀûļļéţ $bullet, ļéṽéļ $level one two]';
  }

  @override
  String outlineOthers(String objects) {
    return '[+ $objects o]';
  }

  @override
  String outlineEditing(String name) {
    return '[$name îš éðîţîñĝ one]';
  }

  @override
  String get outlineCopied => '[Öûţļîñé çöþîéð åš Ṁåŕķðöŵñ one two t]';

  @override
  String get outlineTypingUndo => '[Éðîţ öûţļîñé one]';

  @override
  String get layersPanelTitle => '[Ļåýéŕš one]';

  @override
  String get layersTabLayers => '[Ļåýéŕš one]';

  @override
  String get layersTabReadingOrder => '[Ŕéåðîñĝ öŕðéŕ one t]';

  @override
  String get layersEmpty => '[Ñö öƀĵéçţš öñ ţĥîš šļîðé one two]';

  @override
  String get layersHidden => '[ĥîððéñ one]';

  @override
  String get layersLocked => '[ļöçķéð one]';

  @override
  String get layersRenameHint => '[Ñåɱé on]';

  @override
  String layersDragMany(int count) {
    return '[$count öƀĵéçţš one]';
  }

  @override
  String layersFromLayout(int count) {
    return '[Ƒŕöɱ ļåýöûţ ($count) one t]';
  }

  @override
  String get layersEditLayout => '[Éðîţ ļåýöûţ one]';

  @override
  String get layersOrderAutomatic =>
      '[Åûţöɱåţîç: ţîţļé ƒîŕšţ, ţĥéñ ţöþ ţö ƀöţţöɱ, ļéƒţ ţö ŕîĝĥţ. one two three four]';

  @override
  String get layersOrderCustom =>
      '[Çûšţöɱ öŕðéŕ. Šçŕééñ ŕéåðéŕš åñð Ţåƀ ƒöļļöŵ ţĥîš ļîšţ. one two three fou]';

  @override
  String get layersOrderEarlier => '[Ŕéåð éåŕļîéŕ one]';

  @override
  String get layersOrderLater => '[Ŕéåð ļåţéŕ one]';

  @override
  String get a11yPanelTitle => '[Åççéššîƀîļîţý one t]';

  @override
  String get a11yCheckDescription =>
      '[Çĥéçķš åļţ ţéẋţ, çöñţŕåšţ, ţîţļéš, ţéẋţ šîžé, ŕéåðîñĝ öŕðéŕ åñð ţåƀļéš one two three four fi]';

  @override
  String get a11yCheckAgain => '[Çĥéçķ åĝåîñ one]';

  @override
  String a11ySummary(int errors, int warnings, int info) {
    String _temp0 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors éŕŕöŕš',
      one: '1 éŕŕöŕ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      warnings,
      locale: localeName,
      other: '$warnings ŵåŕñîñĝš',
      one: '1 ŵåŕñîñĝ',
    );
    String _temp2 = intl.Intl.pluralLogic(
      info,
      locale: localeName,
      other: '$info ţîþš',
      one: '1 ţîþ',
    );
    return '[$_temp0 · $_temp1 · $_temp2 one two three]';
  }

  @override
  String get a11yNoIssues => '[Ñö åççéššîƀîļîţý îššûéš ƒöûñð one two th]';

  @override
  String get a11yNoIssuesBody =>
      '[Åļţ ţéẋţ, çöñţŕåšţ, ţîţļéš, ţéẋţ šîžé, ŕéåðîñĝ öŕðéŕ åñð ţåƀļéš ļööķ ĝööð. one two three four five]';

  @override
  String a11ySlideHeading(String label) {
    return '[Šļîðé $label on]';
  }

  @override
  String get a11ySeverityError => '[Éŕŕöŕ on]';

  @override
  String get a11ySeverityWarning => '[Ŵåŕñîñĝ one]';

  @override
  String get a11ySeverityInfo => '[Ţîþ on]';

  @override
  String get a11yMissingAltText => '[Ṁîššîñĝ åļţ ţéẋţ one t]';

  @override
  String a11yLowContrast(String ratio, String required) {
    return '[Ļöŵ ţéẋţ çöñţŕåšţ ($ratio:1, ñééðš $required:1) one two th]';
  }

  @override
  String get a11yContrastOverImage =>
      '[Ţéẋţ öṽéŕ åñ îɱåĝé: çĥéçķ ţĥåţ îţ îš ŕéåðåƀļé one two three]';

  @override
  String get a11yMissingTitle => '[Šļîðé ĥåš ñö ţîţļé one tw]';

  @override
  String a11yDuplicateTitle(String title) {
    return '[Åñöţĥéŕ šļîðé ĥåš ţĥé šåɱé ţîţļé “$title” one two thr]';
  }

  @override
  String a11ySmallText(int size, int min) {
    return '[Ţéẋţ šɱåļļéŕ ţĥåñ $min ($size) one tw]';
  }

  @override
  String get a11yReadingOrder =>
      '[Ţĥé çûšţöɱ ŕéåðîñĝ öŕðéŕ ðîƒƒéŕš ƒŕöɱ ţĥé ļåýöûţ one two three f]';

  @override
  String get a11yTableHeader => '[Ţåƀļé ĥåš ñö ĥéåðéŕ ŕöŵ one two]';

  @override
  String get a11yEmptyPlaceholder => '[Éɱþţý þļåçéĥöļðéŕ one tw]';

  @override
  String get a11yGoTo => '[Ĝö ţö on]';

  @override
  String get a11yFixAltText => '[Åðð åļţ ţéẋţ… one]';

  @override
  String get a11yFixDecorative => '[Ṁåŕķ ðéçöŕåţîṽé one t]';

  @override
  String get a11yFixContrast => '[Ûšé å çöñţŕåšţîñĝ çöļöŕ one two]';

  @override
  String a11yFixTextSize(int size) {
    return '[Éñļåŕĝé ţö $size one]';
  }

  @override
  String get a11yFixReadingOrder => '[Ŕéšéţ ţö åûţöɱåţîç one tw]';

  @override
  String get a11yFixTableHeader => '[Ţûŕñ öñ ĥéåðéŕ ŕöŵ one tw]';

  @override
  String get a11yFixRemovePlaceholder => '[Ŕéɱöṽé þļåçéĥöļðéŕ one tw]';

  @override
  String get a11yEditReadingOrder => '[Éðîţ ŕéåðîñĝ öŕðéŕ one tw]';

  @override
  String get animatePreviewChanged =>
      '[Ţĥé åñîɱåţîöñš çĥåñĝéð — Þŕéṽîéŵ åĝåîñ one two thre]';

  @override
  String get chartCheckNow => '[Çĥéçķ ñöŵ one]';

  @override
  String get cmdCommentsNext => '[Ñéẋţ çöɱɱéñţ one]';

  @override
  String get cmdCommentsPrevious => '[Þŕéṽîöûš çöɱɱéñţ one tw]';

  @override
  String get cmdCommentsOpenPanel => '[Öþéñ çöɱɱéñţš one t]';

  @override
  String get commentsScopeSlide => '[Ţĥîš šļîðé one]';

  @override
  String get commentsScopeAll => '[Åļļ šļîðéš one]';

  @override
  String get commentsOrphanedGroup => '[Öŕþĥåñéð one]';

  @override
  String commentsSlideHeader(int number, String title) {
    return '[$number · $title o]';
  }

  @override
  String commentSlideQuote(int number, String title) {
    return '[Šļîðé $number: $title one]';
  }

  @override
  String get commentAnchorDeleted =>
      '[Ţĥé öƀĵéçţ ţĥîš çöɱɱéñţ ŵåš öñ ŵåš ðéļéţéð one two three]';

  @override
  String commentAnchorDeletedQuote(String quote) {
    return '[$quote — ţĥé öƀĵéçţ ţĥîš çöɱɱéñţ ŵåš öñ ŵåš ðéļéţéð one two three]';
  }

  @override
  String commentPinLabel(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çöɱɱéñţš, ƒîŕšţ ƀý $name',
      one: 'Çöɱɱéñţ ƀý $name',
    );
    return '[$_temp0 one two t]';
  }

  @override
  String commentReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ŕéþļîéš',
      one: '1 ŕéþļý',
    );
    return '[$_temp0 one t]';
  }

  @override
  String commentsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çöɱɱéñţš',
      one: '1 çöɱɱéñţ',
    );
    return '[$_temp0 one tw]';
  }

  @override
  String get reasonNoComments => '[Ñö çöɱɱéñţš one]';

  @override
  String get commentsDockedClose => '[Çļöšé on]';

  @override
  String get cmdSpellingCheckDescription =>
      '[Ŵåļķ ţĥŕöûĝĥ ţĥé ɱîššþéļļéð ŵöŕðš öƒ ţĥé ŵĥöļé þŕéšéñţåţîöñ one two three four]';

  @override
  String get cmdSpellingReplace => '[Çöŕŕéçţ šþéļļîñĝ one tw]';

  @override
  String get cmdSpellingReplaceAll => '[Çöŕŕéçţ šþéļļîñĝ éṽéŕýŵĥéŕé one two t]';

  @override
  String get cmdSpellingIgnore => '[Îĝñöŕé one]';

  @override
  String get cmdSpellingAddToDictionary => '[Åðð ţö ðîçţîöñåŕý one tw]';

  @override
  String get cmdSpellingPersonalDictionary => '[Þéŕšöñåļ ðîçţîöñåŕý… one two]';

  @override
  String get undoCorrectSpelling => '[Çöŕŕéçţ šþéļļîñĝ one tw]';

  @override
  String get undoSetLanguage => '[Šéţ ļåñĝûåĝé one]';

  @override
  String get spellingNoSuggestions => '[Ñö šûĝĝéšţîöñš one t]';

  @override
  String spellingAddWordToDictionary(String word) {
    return '[Åðð “$word” ţö ðîçţîöñåŕý one tw]';
  }

  @override
  String toastPersonalDictionaryFull(int max) {
    return '[Ýöûŕ þéŕšöñåļ ðîçţîöñåŕý îš ƒûļļ ($max ŵöŕðš). one two three]';
  }

  @override
  String get reasonSpellingTextGone =>
      '[Ţĥîš ţéẋţ îš ñö ļöñĝéŕ ţĥéŕé one two t]';

  @override
  String get cmdHistoryRestoreVersion => '[Ŕéšţöŕé ţĥîš ṽéŕšîöñ one two]';

  @override
  String get cmdHistoryMakeCopy => '[Ṁåķé å çöþý one]';

  @override
  String get cmdHistoryDownload => '[Ðöŵñļöåð åš ÞÐƑ one t]';

  @override
  String get cmdHistoryToggleShowChanges => '[Šĥöŵ çĥåñĝéš one]';

  @override
  String get cmdHistoryToggleShowRemoved => '[Šĥöŵ ŕéɱöṽéð öƀĵéçţš one two]';

  @override
  String get cmdHistoryNextChange => '[Ñéẋţ çĥåñĝé one]';

  @override
  String get cmdHistoryPreviousChange => '[Þŕéṽîöûš çĥåñĝé one t]';

  @override
  String get cmdConflictsReview => '[Ŕéṽîéŵ öṽéŕŵŕîţţéñ ţéẋţ one two]';

  @override
  String get cmdConflictsRestoreMine => '[Ŕéšţöŕé ɱý ţéẋţ one t]';

  @override
  String get reasonNoVersionShown => '[Öþéñ å ṽéŕšîöñ ƒîŕšţ one tw]';

  @override
  String get reasonNoChanges => '[Ţĥîš ṽéŕšîöñ ĥåš ñö çĥåñĝéš one two t]';

  @override
  String get reasonNoConflicts =>
      '[Ñöñé öƒ ýöûŕ ţéẋţ ŵåš öṽéŕŵŕîţţéñ one two th]';

  @override
  String get versionLoading => '[Ļöåðîñĝ ţĥîš ṽéŕšîöñ… one two]';

  @override
  String get versionLoadFailed => '[Çöûļðñ’ţ ļöåð ţĥîš ṽéŕšîöñ one two t]';

  @override
  String get versionComputingChanges => '[Ƒîñðîñĝ çĥåñĝéš… one tw]';

  @override
  String get versionChangesHidden => '[Çĥåñĝéš åŕé ĥîððéñ one tw]';

  @override
  String get versionNoChanges =>
      '[Ñö çĥåñĝéš šîñçé ţĥé þŕéṽîöûš ṽéŕšîöñ one two thre]';

  @override
  String versionSlidesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš åððéð',
      one: '1 šļîðé åððéð',
    );
    return '[$_temp0 one two]';
  }

  @override
  String versionSlidesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš çĥåñĝéð',
      one: '1 šļîðé çĥåñĝéð',
    );
    return '[$_temp0 one two th]';
  }

  @override
  String versionSlidesMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš ɱöṽéð',
      one: '1 šļîðé ɱöṽéð',
    );
    return '[$_temp0 one two]';
  }

  @override
  String versionSlidesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš ðéļéţéð',
      one: '1 šļîðé ðéļéţéð',
    );
    return '[$_temp0 one two th]';
  }

  @override
  String get versionThemeChanged => '[Ţĥéɱé çĥåñĝéð one t]';

  @override
  String get versionDeckChanged => '[Þŕéšéñţåţîöñ šéţţîñĝš çĥåñĝéð one two th]';

  @override
  String get versionTagNew => '[Ñéŵ on]';

  @override
  String get versionTagMoved => '[Ṁöṽéð on]';

  @override
  String get versionTagRenamed => '[Ŕéñåɱéð one]';

  @override
  String get versionTagDeleted => '[Ðéļéţéð one]';

  @override
  String versionDeletedSlide(String title) {
    return '[Ðéļéţéð šļîðé: $title one t]';
  }

  @override
  String get versionChangesOnSlide => '[Çĥåñĝéš öñ ţĥîš šļîðé one two]';

  @override
  String get versionNoChangesOnSlide =>
      '[Ñöţĥîñĝ çĥåñĝéð öñ ţĥîš šļîðé one two t]';

  @override
  String versionChangeBy(String what, String who) {
    return '[$what — $who o]';
  }

  @override
  String versionAgentMcp(String name) {
    return '[Çļåûðé ṽîå ṀÇÞ ($name) one t]';
  }

  @override
  String versionAgentAi(String name) {
    return '[Çļåûðé ($name) one]';
  }

  @override
  String versionElementChange(String element, String what) {
    return '[$element: $what o]';
  }

  @override
  String versionElementAdded(String element) {
    return '[$element åððéð on]';
  }

  @override
  String versionElementRemoved(String element) {
    return '[$element ðéļéţéð one]';
  }

  @override
  String get versionKindText => '[ţéẋţ éðîţéð one]';

  @override
  String get versionKindFrame => '[ɱöṽéð öŕ ŕéšîžéð one t]';

  @override
  String get versionKindStyle => '[ŕéšţýļéð one]';

  @override
  String get versionKindData => '[çöñţéñţ çĥåñĝéð one t]';

  @override
  String get versionKindOrder => '[öŕðéŕ çĥåñĝéð one t]';

  @override
  String get versionKindVisibility => '[šĥöŵñ, ĥîððéñ öŕ ļöçķéð one two]';

  @override
  String get versionKindAnimation => '[åñîɱåţîöñ çĥåñĝéð one tw]';

  @override
  String get versionSlideAdded => '[Šļîðé åððéð one]';

  @override
  String get versionSlideMoved => '[Šļîðé ɱöṽéð one]';

  @override
  String get versionSlideSkipToggled =>
      '[Šļîðé šķîþþéð öŕ ûñšķîþþéð one two t]';

  @override
  String get versionSlideDeleted => '[Šļîðé ðéļéţéð one t]';

  @override
  String get versionSlideBackground => '[Ɓåçķĝŕöûñð çĥåñĝéð one tw]';

  @override
  String get versionSlideLayout => '[Ļåýöûţ çĥåñĝéð one t]';

  @override
  String get versionSlideTransition => '[Ţŕåñšîţîöñ çĥåñĝéð one tw]';

  @override
  String get versionSlideNotes => '[Šþéåķéŕ ñöţéš éðîţéð one two]';

  @override
  String get versionSlideTimings => '[Ţîɱîñĝš çĥåñĝéð one t]';

  @override
  String get versionSlideMasters =>
      '[Ṁåšţéŕ öƀĵéçţš šĥöŵñ öŕ ĥîððéñ one two th]';

  @override
  String versionAnimations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count åñîɱåţîöñš çĥåñĝéð',
      one: '1 åñîɱåţîöñ çĥåñĝéð',
    );
    return '[$_temp0 one two thre]';
  }

  @override
  String versionGroupAdded(String title) {
    return '[Šéçţîöñ “$title” åððéð one t]';
  }

  @override
  String versionGroupRemoved(String title) {
    return '[Šéçţîöñ “$title” ðéļéţéð one tw]';
  }

  @override
  String versionGroupChanged(String title) {
    return '[Šéçţîöñ “$title” çĥåñĝéð one tw]';
  }

  @override
  String versionChangeCounter(int index, int count) {
    return '[$index öƒ $count o]';
  }

  @override
  String get versionCopyTitle => '[Çöþý ţĥîš ṽéŕšîöñ one tw]';

  @override
  String get versionCopyNameLabel => '[Ñåɱé on]';

  @override
  String versionCopyName(String title) {
    return '[Çöþý öƒ $title one]';
  }

  @override
  String get versionCopyNameRequired => '[Éñţéŕ å ñåɱé one]';

  @override
  String get versionCopyComments => '[Çöþý çöɱɱéñţš one t]';

  @override
  String get versionCopySharing => '[Šĥåŕé ŵîţĥ ţĥé šåɱé þéöþļé one two]';

  @override
  String get versionOpenCopy => '[Öþéñ on]';

  @override
  String toastVersionCopied(String name) {
    return '[Çŕéåţéð “$name” one]';
  }

  @override
  String get toastVersionCopyFailed => '[Çöûļðñ’ţ çöþý ţĥîš ṽéŕšîöñ one two t]';

  @override
  String get toastVersionDownloadFailed =>
      '[Çöûļðñ’ţ ðöŵñļöåð ţĥîš ṽéŕšîöñ one two th]';

  @override
  String get conflictsTitle => '[Ýöûŕ ţéẋţ ŵåš ŕéþļåçéð one two]';

  @override
  String get conflictsDescription =>
      '[Ñéŵéŕ éðîţš ƒŕöɱ çöļļåƀöŕåţöŕš ŕéþļåçéð ţéẋţ ýöû éðîţéð ŵĥîļé öƒƒļîñé. Çĥööšé ţĥé ţéẋţš ţö þûţ ƀåçķ. one two three four five six se]';

  @override
  String conflictsRow(String where, String mine, String theirs, String who) {
    return '[$where — ýöûŕš: $mine · ñöŵ: $theirs ($who) one t]';
  }

  @override
  String conflictsDeletedBy(String where, String who, String mine) {
    return '[$where ŵåš ðéļéţéð ƀý $who · ýöûŕš: $mine one two]';
  }

  @override
  String conflictsSlideTarget(int number, String element) {
    return '[Šļîðé $number, $element one]';
  }

  @override
  String conflictsNotesTarget(int number) {
    return '[Šļîðé $number, šþéåķéŕ ñöţéš one two]';
  }

  @override
  String conflictsCellTarget(int number) {
    return '[Šļîðé $number, ţåƀļé çéļļ one tw]';
  }

  @override
  String get conflictsGoneTarget => '[Å ðéļéţéð šļîðé one t]';

  @override
  String get conflictsEmptyValue => '[(éɱþţý) one]';

  @override
  String get conflictsRestoreMine => '[Ŕéšţöŕé one]';

  @override
  String get conflictsCopyMine => '[Çöþý on]';

  @override
  String get conflictsDismissAll => '[Ðîšɱîšš åļļ one]';

  @override
  String get conflictsReview => '[Ŕéṽîéŵ one]';

  @override
  String get conflictsSeveralPeople => '[šéṽéŕåļ þéöþļé one t]';

  @override
  String toastConflicts(int count, String who) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öƒ ýöûŕ ţéẋţ éðîţš ŵéŕé',
      one: '1 öƒ ýöûŕ ţéẋţ éðîţš ŵåš',
    );
    return '[$_temp0 ŕéþļåçéð ƀý ñéŵéŕ éðîţš ƒŕöɱ $who one two three four fiv]';
  }

  @override
  String get toastConflictsCopied => '[Çöþîéð ýöûŕ ţéẋţ one t]';

  @override
  String toastVersionRestoredBy(String name) {
    return '[$name ŕéšţöŕéð å þŕéṽîöûš ṽéŕšîöñ one two t]';
  }

  @override
  String get cmdLineSetWaypoints => '[Éðîţ çöññéçţöŕ ŕöûţé one two]';

  @override
  String get aiPanelTitle => '[Åššîšţåñţ one]';

  @override
  String get aiAssistantEmptyTitle =>
      '[Åšķ åƀöûţ ţĥîš þŕéšéñţåţîöñ, öŕ åšķ ƒöŕ çĥåñĝéš one two three]';

  @override
  String get aiAssistantPrivacyNotice =>
      '[Ýöûŕ ɱéššåĝéš åñð ţĥîš þŕéšéñţåţîöñ\'š çöñţéñţ åŕé šéñţ ţö åñ ÅÎ þŕöṽîðéŕ. one two three four fiv]';

  @override
  String aiAssistantPrivacyNoticeProvider(String provider) {
    return '[Ýöûŕ ɱéššåĝéš åñð ţĥîš þŕéšéñţåţîöñ\'š çöñţéñţ åŕé šéñţ ţö $provider. one two three four]';
  }

  @override
  String get aiAssistantModeEditHint =>
      '[Çĥåñĝéš ĝö šţŕåîĝĥţ îñţö ţĥé þŕéšéñţåţîöñ one two three]';

  @override
  String get aiAssistantModeEditUnavailable =>
      '[Ýöû çåñ öñļý šûĝĝéšţ çĥåñĝéš îñ ţĥîš þŕéšéñţåţîöñ one two three f]';

  @override
  String get aiAssistantModeSuggestHint =>
      '[Çĥåñĝéš åŕé þŕéṽîéŵéð ƀéƒöŕé åñýţĥîñĝ îš åþþļîéð one two three f]';

  @override
  String get aiUnavailable => '[ÅÎ îšñ\'ţ åṽåîļåƀļé one tw]';

  @override
  String get aiTurnedOff => '[ÅÎ îš ţûŕñéð öƒƒ one t]';

  @override
  String get aiTurnOnHint => '[Ţûŕñ îţ öñ îñ Šéţţîñĝš › ÅÎ. one two]';

  @override
  String aiChipSlide(int position) {
    return '[Šļîðé $position on]';
  }

  @override
  String aiChipObjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šéļéçţéð öƀĵéçţš',
      one: '1 šéļéçţéð öƀĵéçţ',
    );
    return '[$_temp0 one two thr]';
  }

  @override
  String get aiQuickImproveSlide => '[Îɱþŕöṽé šļîðé one t]';

  @override
  String get aiQuickNotes => '[Šþéåķéŕ ñöţéš one t]';

  @override
  String get aiQuickSummarize => '[Šûɱɱåŕîžé ðéçķ one t]';

  @override
  String get aiQuickAgenda => '[Åðð åĝéñðå one]';

  @override
  String get aiQuickConsistency => '[Çĥéçķ ŵöŕðîñĝ one t]';

  @override
  String get aiQuickNewDeck => '[Ĝéñéŕåţé å þŕéšéñţåţîöñ… one two]';

  @override
  String aiUndoLabel(String summary) {
    return '[ÅÎ: $summary on]';
  }

  @override
  String get aiUndoDefault => '[Åššîšţåñţ çĥåñĝéš one tw]';

  @override
  String get aiFailed => '[Ţĥé ÅÎ ŕéǫûéšţ ƒåîļéð one two]';

  @override
  String get aiPreviewReview => '[Ŕéṽîéŵ çĥåñĝéš one t]';

  @override
  String get aiPreviewAppliedNote => '[Šûĝĝéšţéð çĥåñĝéš åþþļîéð one two t]';

  @override
  String get aiPreviewDiscardedNote =>
      '[Šûĝĝéšţéð çĥåñĝéš ðîšçåŕðéð one two t]';

  @override
  String get aiPreviewTitle => '[Šûĝĝéšţéð çĥåñĝéš one tw]';

  @override
  String get aiPreviewDescription =>
      '[Çĥööšé ţĥé çĥåñĝéš ţö åþþļý. Ñöţĥîñĝ çĥåñĝéš ûñţîļ ýöû åþþļý ţĥéɱ. one two three four f]';

  @override
  String get aiPreviewApply => '[Åþþļý šéļéçţéð one t]';

  @override
  String get aiPreviewDiscard => '[Ðîšçåŕð one]';

  @override
  String get aiPreviewBefore => '[Ɓéƒöŕé one]';

  @override
  String get aiPreviewAfter => '[Åƒţéŕ on]';

  @override
  String get aiPreviewNewSlide => '[Ñéŵ šļîðé one]';

  @override
  String get aiPreviewDeletedSlide => '[Ðéļéţéð one]';

  @override
  String aiPreviewSlide(int position) {
    return '[Šļîðé $position on]';
  }

  @override
  String get aiPreviewNoSlides =>
      '[Ţĥéšé çĥåñĝéš ðöñ\'ţ çĥåñĝé å šļîðé\'š ļööķ. one two three]';

  @override
  String aiPreviewSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ṽåļûéš šöɱéöñé çĥåñĝéð ɱéåñŵĥîļé ŵéŕé ķéþţ',
      one: '1 ṽåļûé šöɱéöñé çĥåñĝéð ɱéåñŵĥîļé ŵåš ķéþţ',
    );
    return '[$_temp0 one two three four five si]';
  }

  @override
  String get aiPreviewApplyAll => '[Åþþļý šûĝĝéšţéð çĥåñĝéš one two]';

  @override
  String get aiGenerateTitle => '[Ĝéñéŕåţé þŕéšéñţåţîöñ one two]';

  @override
  String get aiGenerateSource => '[Šöûŕçé one]';

  @override
  String get aiGenerateSourcePrompt => '[Þŕöɱþţ one]';

  @override
  String get aiGenerateSourceOutline => '[Öûţļîñé one]';

  @override
  String get aiGeneratePromptLabel =>
      '[Ŵĥåţ îš ţĥé þŕéšéñţåţîöñ åƀöûţ? one two th]';

  @override
  String get aiGeneratePromptHint =>
      '[Ǫûåŕţéŕļý ŕéṽîéŵ öƒ ţĥé Šéŕṽéŕþöð Çļöûð ļåûñçĥ ƒöŕ ţĥé ƀöåŕð… one two three four]';

  @override
  String get aiGenerateOutlineLabel => '[Ýöûŕ öûţļîñé one]';

  @override
  String get aiGenerateOutlineHint =>
      '[Þåšţé ƀûļļéţš öŕ Ṁåŕķðöŵñ ŵîţĥ öñé ĥéåðîñĝ þéŕ šļîðé one two three fo]';

  @override
  String get aiGenerateSlides => '[Šļîðéš one]';

  @override
  String get aiGenerateSlidesAuto => '[Åûţö on]';

  @override
  String get aiGenerateAudience => '[Åûðîéñçé one]';

  @override
  String get aiGenerateTone => '[Ţöñé on]';

  @override
  String get aiGenerateLanguage => '[Ļåñĝûåĝé one]';

  @override
  String get aiGenerateLanguageAuto => '[Šåɱé åš ţĥé ţéẋţ one t]';

  @override
  String get aiGenerateNotes => '[Šþéåķéŕ ñöţéš one t]';

  @override
  String get aiGenerateGroups => '[Ĝŕöûþ îñţö šéçţîöñš one tw]';

  @override
  String get aiGenerateKeepWording => '[Ķééþ ɱý ŵöŕðîñĝ one t]';

  @override
  String get aiGenerateInsert => '[Îñšéŕţ one]';

  @override
  String get aiGenerateInsertNew => '[Ñéŵ þŕéšéñţåţîöñ one tw]';

  @override
  String aiGenerateInsertAfter(int position) {
    return '[Åƒţéŕ šļîðé $position one]';
  }

  @override
  String get aiGenerateInsertEnd => '[Åţ ţĥé éñð one]';

  @override
  String get aiGenerateCreateOutline => '[Çŕéåţé öûţļîñé one t]';

  @override
  String get aiGeneratePlanning => '[Þļåññîñĝ ţĥé öûţļîñé… one two]';

  @override
  String get aiGenerateOutlineTitle => '[Ŕéṽîéŵ ţĥé öûţļîñé one tw]';

  @override
  String get aiGenerateOutlineDescription =>
      '[Éðîţ ţîţļéš åñð ŕöļéš, ŕéöŕðéŕ öŕ ðéļéţé šļîðéš, ţĥéñ çŕéåţé ţĥéɱ. one two three four f]';

  @override
  String get aiGenerateBuild => '[Çŕéåţé šļîðéš one t]';

  @override
  String get aiGenerateBack => '[Ɓåçķ on]';

  @override
  String get aiGenerateRegenerate => '[Ŕéĝéñéŕåţé one]';

  @override
  String get aiGenerateRegenerateSlide => '[Ŕéĝéñéŕåţé ţĥîš šļîðé one two]';

  @override
  String get aiGenerateRegenerateHint =>
      '[Ŵĥåţ šĥöûļð çĥåñĝé? (öþţîöñåļ) one two th]';

  @override
  String get aiGenerateAddSlide => '[Åðð šļîðé one]';

  @override
  String get aiGenerateDeleteSlide => '[Ðéļéţé šļîðé one]';

  @override
  String get aiGenerateMoveUp => '[Ṁöṽé ûþ one]';

  @override
  String get aiGenerateMoveDown => '[Ṁöṽé ðöŵñ one]';

  @override
  String get aiGenerateSlideTitle => '[Šļîðé ţîţļé one]';

  @override
  String get aiGenerateBullets => '[Ɓûļļéţš (öñé þéŕ ļîñé) one two]';

  @override
  String aiGenerateSlideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šļîðéš',
      one: '1 šļîðé',
    );
    return '[$_temp0 one t]';
  }

  @override
  String get aiGenerateRole => '[Ŕöļé on]';

  @override
  String get aiGenerateBuilding => '[Çŕéåţîñĝ šļîðéš… one tw]';

  @override
  String get aiGenerateUndo => '[Ĝéñéŕåţé šļîðéš one t]';

  @override
  String get aiGenerateNewSlide => '[Ñéŵ šļîðé one]';

  @override
  String get aiGenerateEmpty =>
      '[Ðéšçŕîƀé ţĥé þŕéšéñţåţîöñ ƒîŕšţ. one two thr]';

  @override
  String aiGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Åððéð $count šļîðéš',
      one: 'Åððéð 1 šļîðé',
    );
    return '[$_temp0 one two]';
  }

  @override
  String get aiGenerateCreated => '[Þŕéšéñţåţîöñ çŕéåţéð one two]';

  @override
  String get aiRoleTitle => '[Ţîţļé on]';

  @override
  String get aiRoleSection => '[Šéçţîöñ one]';

  @override
  String get aiRoleAgenda => '[Åĝéñðå one]';

  @override
  String get aiRoleBullets => '[Ɓûļļéţš one]';

  @override
  String get aiRoleTwoColumn => '[Ţŵö çöļûɱñš one]';

  @override
  String get aiRoleQuote => '[Ǫûöţé on]';

  @override
  String get aiRoleBigNumber => '[Ɓîĝ ñûɱƀéŕ one]';

  @override
  String get aiRoleImageText => '[Îɱåĝé åñð ţéẋţ one t]';

  @override
  String get aiRoleCode => '[Çöðé on]';

  @override
  String get aiRoleChartPlaceholder => '[Çĥåŕţ on]';

  @override
  String get aiRoleClosing => '[Çļöšîñĝ one]';

  @override
  String get aiAudienceGeneral => '[Ĝéñéŕåļ one]';

  @override
  String get aiAudienceBoard => '[Ɓöåŕð on]';

  @override
  String get aiAudienceTeam => '[Ţéåɱ on]';

  @override
  String get aiAudienceCustomers => '[Çûšţöɱéŕš one]';

  @override
  String get aiAudienceStudents => '[Šţûðéñţš one]';

  @override
  String get aiAudienceDevelopers => '[Ðéṽéļöþéŕš one]';

  @override
  String get aiToneProfessional => '[Þŕöƒéššîöñåļ one t]';

  @override
  String get aiToneFriendly => '[Ƒŕîéñðļý one]';

  @override
  String get aiToneInspiring => '[Îñšþîŕîñĝ one]';

  @override
  String get aiToneTechnical => '[Ţéçĥñîçåļ one]';

  @override
  String get aiToneConcise => '[Çöñçîšé one]';

  @override
  String get aiRewriteTitle => '[Ŕéŵŕîţé ţéẋţ one]';

  @override
  String get aiRewriteWorking => '[Ŵŕîţîñĝ… one]';

  @override
  String get aiRewriteReplace => '[Ŕéþļåçé one]';

  @override
  String get aiRewriteTryAgain => '[Ţŕý åĝåîñ one]';

  @override
  String get aiRewriteDiscard => '[Ðîšçåŕð one]';

  @override
  String get aiRewriteRefineHint => '[Ŕéƒîñé, é.ĝ. éṽéñ šĥöŕţéŕ one two]';

  @override
  String get aiRewriteRefine => '[Ŕéƒîñé one]';

  @override
  String get aiRewriteOriginal => '[Öŕîĝîñåļ one]';

  @override
  String get aiRewriteResult => '[Šûĝĝéšţîöñ one]';

  @override
  String get aiRewriteChanged =>
      '[Ţĥé ţéẋţ çĥåñĝéð ɱéåñŵĥîļé. Çöþý ţĥé šûĝĝéšţîöñ öŕ ţŕý åĝåîñ. one two three four]';

  @override
  String get aiRewriteCopy => '[Çöþý on]';

  @override
  String get aiRewriteCopied => '[Çöþîéð one]';

  @override
  String get aiRewriteCustomLabel => '[Ĥöŵ šĥöûļð ţĥé ţéẋţ çĥåñĝé? one two t]';

  @override
  String get aiRewriteCustomHint => '[Ṁåķé îţ šöûñð ɱöŕé çöñƒîðéñţ one two t]';

  @override
  String get aiRewriteUndo => '[Ŕéŵŕîţé ţéẋţ one]';

  @override
  String get aiRewriteNoText => '[Šéļéçţ å ţéẋţ ƀöẋ ŵîţĥ ţéẋţ one two]';

  @override
  String get rewritePunchier => '[Þûñçĥîéŕ one]';

  @override
  String get rewriteBullets => '[Ṁåķé ƀûļļéţš one]';

  @override
  String get rewriteParagraph => '[Ṁåķé å þåŕåĝŕåþĥ one t]';

  @override
  String get aiNotesTitle => '[Ŵŕîţé šþéåķéŕ ñöţéš one tw]';

  @override
  String get aiNotesScope => '[Šļîðéš one]';

  @override
  String get aiNotesScopeCurrent => '[Çûŕŕéñţ šļîðé one t]';

  @override
  String get aiNotesScopeSelected => '[Šéļéçţéð šļîðéš one t]';

  @override
  String get aiNotesScopeAll => '[Åļļ šļîðéš one]';

  @override
  String get aiNotesLength => '[Ļéñĝţĥ one]';

  @override
  String get aiNotesLengthBrief => '[Ɓŕîéƒ on]';

  @override
  String get aiNotesLengthStandard => '[Šţåñðåŕð one]';

  @override
  String get aiNotesLengthDetailed => '[Ðéţåîļéð one]';

  @override
  String get aiNotesStyle => '[Šţýļé on]';

  @override
  String get aiNotesStyleScript => '[Šçŕîþţ one]';

  @override
  String get aiNotesStyleBullets => '[Ɓûļļéţ þöîñţš one t]';

  @override
  String get aiNotesMode => '[Éẋîšţîñĝ ñöţéš one t]';

  @override
  String get aiNotesModeFillEmpty => '[Öñļý ŵŕîţé éɱþţý ñöţéš one two]';

  @override
  String get aiNotesModeAppend => '[Åðð ţö ţĥéɱ one]';

  @override
  String get aiNotesModeReplace => '[Ŕéþļåçé ţĥéɱ one]';

  @override
  String get aiNotesGenerate => '[Ŵŕîţé ñöţéš one]';

  @override
  String get aiNotesWorking => '[Ŵŕîţîñĝ ñöţéš… one t]';

  @override
  String get aiNotesReviewTitle => '[Ŕéṽîéŵ šþéåķéŕ ñöţéš one two]';

  @override
  String get aiNotesApply => '[Åþþļý on]';

  @override
  String get aiNotesNone => '[Ñö šļîðé ñééðš ñöţéš. one two]';

  @override
  String get aiNotesExisting => '[Çûŕŕéñţ ñöţéš one t]';

  @override
  String get aiNotesUndo => '[Ŵŕîţé šþéåķéŕ ñöţéš one tw]';

  @override
  String get aiAltTitle => '[Ĝéñéŕåţé åļţ ţéẋţ one tw]';

  @override
  String get aiAltWorking => '[Ðéšçŕîƀîñĝ öƀĵéçţš… one two]';

  @override
  String get aiAltApply => '[Åþþļý on]';

  @override
  String get aiAltNone => '[Ñöţĥîñĝ ñééðš åļţ ţéẋţ. one two]';

  @override
  String get aiAltSkippedUnsupported =>
      '[Ţĥîš ķîñð öƒ öƀĵéçţ çåñ\'ţ ƀé ðéšçŕîƀéð. one two thre]';

  @override
  String get aiAltSkippedEmpty => '[Ñö ðéšçŕîþţîöñ ŵåš þŕöþöšéð. one two t]';

  @override
  String get aiAltUndo => '[Ĝéñéŕåţé åļţ ţéẋţ one tw]';

  @override
  String aiAltObject(String kind, int position) {
    return '[$kind öñ šļîðé $position one]';
  }

  @override
  String get a11yGenerateAlt => '[Ĝéñéŕåţé ŵîţĥ ÅÎ one t]';

  @override
  String get a11yGenerateMissingAlt => '[Ĝéñéŕåţé ɱîššîñĝ åļţ ţéẋţ one two]';

  @override
  String get aiDesignTitle => '[Ðéšîĝñ îðéåš one]';

  @override
  String get aiDesignEmpty =>
      '[Ñö îðéåš ƒöŕ ţĥîš šļîðé — åðð šöɱé çöñţéñţ one two thre]';

  @override
  String get aiDesignNoSlide =>
      '[Šéļéçţ å šļîðé ţö šéé ðéšîĝñ îðéåš one two th]';

  @override
  String get aiDesignRefresh => '[Ŕéƒŕéšĥ one]';

  @override
  String get aiDesignMore => '[Ṁöŕé îðéåš one]';

  @override
  String get aiDesignRanking => '[Ŕåñķîñĝ ŵîţĥ ÅÎ… one t]';

  @override
  String get aiDesignLayoutIdeas => '[Ļåýöûţ îðéåš ƒöŕ ţĥîš šļîðé one two t]';

  @override
  String get aiDesignAiRanked => '[Ŕåñķéð ƀý ÅÎ ƒöŕ ţĥîš šļîðé one two]';

  @override
  String get aiDesignUndo => '[Åþþļý ðéšîĝñ îðéå one tw]';

  @override
  String aiDesignApply(String name) {
    return '[Åþþļý $name on]';
  }

  @override
  String get cmdAiApplyDesignIdea => '[Åþþļý ðéšîĝñ îðéå one tw]';

  @override
  String get cmdPanelDesignIdeas => '[Ðéšîĝñ îðéåš one]';

  @override
  String get cmdAiApplyPreview => '[Åþþļý šûĝĝéšţéð çĥåñĝéš one two]';

  @override
  String get cmdAiDiscardPreview => '[Ðîšçåŕð šûĝĝéšţéð çĥåñĝéš one two t]';

  @override
  String get cmdAiSetApplyMode => '[Åššîšţåñţ: éðîţ öŕ šûĝĝéšţ one two t]';

  @override
  String get reasonAiUnavailable => '[ÅÎ îšñ\'ţ åṽåîļåƀļé one tw]';

  @override
  String get reasonNoTextToRewrite => '[Šéļéçţ å ţéẋţ ƀöẋ ŵîţĥ ţéẋţ one two]';

  @override
  String get reasonNoPreview => '[Ñö šûĝĝéšţéð çĥåñĝéš ţö ŕéṽîéŵ one two th]';

  @override
  String presenceEditingLayout(String name) {
    return '[Éðîţîñĝ ļåýöûţ · $name one t]';
  }

  @override
  String get followWatchPresentation => '[Ŵåţçĥ þŕéšéñţåţîöñ one tw]';

  @override
  String presenterLive(String name) {
    return '[$name îš þŕéšéñţîñĝ one t]';
  }

  @override
  String presentMenuFollow(String name) {
    return '[Ƒöļļöŵ $name\'š þŕéšéñţåţîöñ one two]';
  }

  @override
  String followerFollowing(String name) {
    return '[Ƒöļļöŵîñĝ $name — þŕéšš Éšç ţö šţöþ one two t]';
  }

  @override
  String get followerFollowingUnknown =>
      '[Ƒöļļöŵîñĝ ţĥé þŕéšéñţéŕ — þŕéšš Éšç ţö šţöþ one two three]';

  @override
  String followerBrowsing(String name) {
    return '[Ýöû ļéƒţ $name\'š šļîðé one t]';
  }

  @override
  String get followerBrowsingUnknown =>
      '[Ýöû ļéƒţ ţĥé þŕéšéñţéŕ\'š šļîðé one two th]';

  @override
  String get followerReturn => '[Ŕéţûŕñ ţö þŕéšéñţéŕ one tw]';

  @override
  String get followerFullscreen => '[Ƒûļļ šçŕééñ one]';

  @override
  String get followerStop => '[Šţöþ ƒöļļöŵîñĝ one t]';

  @override
  String get cmdPresenceReturnToPresenter => '[Ŕéţûŕñ ţö þŕéšéñţéŕ one tw]';

  @override
  String pointerOnSlide(String name) {
    return '[$name\'š þöîñţéŕ one]';
  }

  @override
  String get errorObjectLocked => '[Ţĥîš öƀĵéçţ îš ļöçķéð. one two]';

  @override
  String get errorTooManyGuides => '[Ţĥéŕé åŕé ţöö ɱåñý ĝûîðéš one two]';

  @override
  String get errorSelectTextBox => '[Šéļéçţ å ţéẋţ ƀöẋ one t]';

  @override
  String get errorCopyFailed => '[Ţĥé çöþý çöûļðñ’ţ ƀé ɱåðé one two]';

  @override
  String get errorNothingToRestore => '[Ñöţĥîñĝ ţö ŕéšţöŕé one tw]';

  @override
  String get errorCropRemovesImage =>
      '[Ţĥé çŕöþ ŕéɱöṽéš ţĥé ŵĥöļé îɱåĝé one two th]';

  @override
  String get errorSelectSlide => '[Šéļéçţ åţ ļéåšţ öñé šļîðé one two]';

  @override
  String get errorClipboardNoSlides =>
      '[Ţĥé çļîþƀöåŕð ĥöļðš ñö šļîðéš one two t]';

  @override
  String get errorNothingToMove => '[Ñöţĥîñĝ ţö ɱöṽé ţĥéŕé one two]';

  @override
  String get errorOneEmoji => '[Öñé éɱöĵî îš éẋþéçţéð one two]';

  @override
  String get errorTextChanged => '[Ţĥé ţéẋţ ĥåš çĥåñĝéð one tw]';

  @override
  String get errorOneWord => '[Öñé ŵöŕð îš éẋþéçţéð one tw]';

  @override
  String get errorNoSlidesSelected => '[Ñö šļîðéš šéļéçţéð one tw]';

  @override
  String get errorNothingToFix => '[Ñöţĥîñĝ ţö ƒîẋ one t]';

  @override
  String get errorNothingToPaste => '[Ñöţĥîñĝ ţö þåšţé one t]';

  @override
  String get errorLineNotOnSlide =>
      '[Ţĥé ļîñé îš ñöţ öñ ţĥé çûŕŕéñţ šļîðé one two thr]';

  @override
  String get errorRouteHandlesInGroups =>
      '[Ŕöûţé ĥåñðļéš åŕé ñöţ åṽåîļåƀļé îñšîðé ĝŕöûþš one two three]';

  @override
  String get errorStraightLineWaypoints =>
      '[Šţŕåîĝĥţ ļîñéš ĥåṽé ñö ŵåýþöîñţš one two th]';
}
