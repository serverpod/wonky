import 'package:wonky_core/wonky_core.dart';

import '../l10n/wonky_app_localizations.dart';

/// Ids of the shared menus and their extension points (suite 03 §3.2).
abstract final class ShellMenuIds {
  static const file = 'file';
  static const fileNew = 'file.new';
  static const fileShare = 'file.share';
  static const fileDownload = 'file.download';
  static const fileDownloadFormats = 'file.download.formats';
  static const fileVersions = 'file.versions';
  static const edit = 'edit';
  static const view = 'view';
  static const viewMode = 'view.mode';
  static const viewZoom = 'view.zoom';
  static const viewPanels = 'view.panels';
  static const viewTheme = 'view.theme';
  static const tools = 'tools';
  static const help = 'help';

  /// Tools › *Settings…* (`shell.settings.openApp`), the one settings
  /// entry (suite 04 §4.2); the v1 id of Tools › Preferences, so apps keep
  /// inserting relative to it.
  static const toolsSettings = 'tools.preferences';

  /// Help › *Report a bug* and *Suggest an improvement*
  /// (`shell.board.report {kind}`, specs/16 §4.1).
  static const helpReportBug = 'help.reportBug';
  static const helpSuggest = 'help.suggest';

  /// Separator ids apps can insert relative to.
  static const fileEndOfOpen = 'file.sep.open';
  static const fileEndOfManage = 'file.sep.manage';
  static const fileEndOfVersions = 'file.sep.versions';
  static const editEndOfClipboard = 'edit.sep.clipboard';
  static const editEndOfSelect = 'edit.sep.select';
}

/// The shared menus as a `MenuSpec` tree that each app extends
/// (`MenuRoot.insertAfter`, `appendTo`, `insertMenusBefore`).
class ShellMenus {
  ShellMenus(this.l10n);

  final WonkyAppLocalizations l10n;

  late final MenuRoot root = MenuSpec.root([file, edit, view, tools, help]);

  MenuSubmenu get file => MenuSpec.submenu(ShellMenuIds.file, l10n.menuFile, [
    MenuSpec.submenu(ShellMenuIds.fileNew, l10n.menuNew, [
      MenuSpec.command(
        'shell.file.new',
        label: l10n.menuNewDocument,
        args: {'kind': 'document'},
        id: 'file.new.document',
      ),
      MenuSpec.command(
        'shell.file.new',
        label: l10n.menuNewSpreadsheet,
        args: {'kind': 'spreadsheet'},
        id: 'file.new.spreadsheet',
      ),
      // (v2) Opens Wonky Slides' `/new` in this tab (suite 03 §3.3).
      MenuSpec.command(
        'shell.file.new',
        label: l10n.menuNewPresentation,
        args: {'kind': 'presentation'},
        id: 'file.new.presentation',
      ),
      MenuSpec.command('shell.file.newFromTemplate'),
    ]),
    MenuSpec.command('shell.file.open'),
    MenuSpec.command('shell.file.import'),
    MenuSpec.command('shell.drive.copy', label: l10n.menuMakeCopy),
    MenuSpec.separator(id: ShellMenuIds.fileEndOfOpen),
    MenuSpec.submenu(ShellMenuIds.fileShare, l10n.menuShare, [
      MenuSpec.command('shell.sharing.open'),
      MenuSpec.command('shell.sharing.copyLink'),
    ]),
    MenuSpec.submenu(ShellMenuIds.fileDownload, l10n.menuDownload, [
      MenuSpec.custom(ShellMenuIds.fileDownloadFormats),
    ]),
    MenuSpec.separator(),
    MenuSpec.command('shell.drive.rename'),
    MenuSpec.command('shell.drive.move'),
    MenuSpec.command('shell.drive.addShortcut'),
    MenuSpec.command('shell.drive.trash'),
    MenuSpec.separator(id: ShellMenuIds.fileEndOfManage),
    MenuSpec.submenu(ShellMenuIds.fileVersions, l10n.menuVersionHistory, [
      MenuSpec.command('shell.versions.nameCurrent'),
      MenuSpec.command('shell.versions.open'),
    ]),
    MenuSpec.command('shell.drive.togglePinnedOffline'),
    MenuSpec.command('shell.file.details'),
    MenuSpec.separator(id: ShellMenuIds.fileEndOfVersions),
    MenuSpec.command('shell.file.print'),
  ]);

  MenuSubmenu get edit => MenuSpec.submenu(ShellMenuIds.edit, l10n.menuEdit, [
    MenuSpec.command('shell.edit.undo'),
    MenuSpec.command('shell.edit.redo'),
    MenuSpec.separator(),
    MenuSpec.command('shell.edit.cut'),
    MenuSpec.command('shell.edit.copy'),
    MenuSpec.command('shell.edit.paste'),
    MenuSpec.command('shell.edit.pasteWithoutFormatting'),
    MenuSpec.separator(id: ShellMenuIds.editEndOfClipboard),
    MenuSpec.command('shell.edit.selectAll'),
    MenuSpec.separator(id: ShellMenuIds.editEndOfSelect),
    MenuSpec.command('shell.edit.undoHistory'),
  ]);

  MenuSubmenu get view => MenuSpec.submenu(ShellMenuIds.view, l10n.menuView, [
    MenuSpec.submenu(ShellMenuIds.viewMode, l10n.menuMode, const []),
    MenuSpec.separator(),
    MenuSpec.submenu(ShellMenuIds.viewZoom, l10n.menuZoom, [
      for (final p in const [50, 75, 90, 100, 125, 150, 200])
        MenuSpec.command(
          'shell.view.zoom',
          label: '$p%',
          args: {'percent': p},
          id: 'view.zoom.$p',
          radio: true,
        ),
    ]),
    // The rail's panels in rail order with their rail icons (suite 03
    // §3.2): Comments, the app's panels (the Assistant; apps add theirs),
    // then History.
    MenuSpec.submenu(ShellMenuIds.viewPanels, l10n.menuPanels, [
      MenuSpec.command('shell.comments.togglePanel', showIcon: true),
      MenuSpec.command('shell.ai.togglePanel', showIcon: true),
      MenuSpec.command('shell.versions.togglePanel', showIcon: true),
    ]),
    MenuSpec.submenu(ShellMenuIds.viewTheme, l10n.menuAppTheme, [
      MenuSpec.command(
        'shell.appearance.setTheme',
        label: l10n.themeSystem,
        args: {'mode': 'system'},
        id: 'view.theme.system',
        radio: true,
      ),
      MenuSpec.command(
        'shell.appearance.setTheme',
        label: l10n.themeLight,
        args: {'mode': 'light'},
        id: 'view.theme.light',
        radio: true,
      ),
      MenuSpec.command(
        'shell.appearance.setTheme',
        label: l10n.themeDark,
        args: {'mode': 'dark'},
        id: 'view.theme.dark',
        radio: true,
      ),
    ]),
  ]);

  MenuSubmenu get tools =>
      MenuSpec.submenu(ShellMenuIds.tools, l10n.menuTools, [
        MenuSpec.command('shell.ai.togglePanel', id: 'tools.assistant'),
        MenuSpec.separator(),
        // One *Settings…* entry: the settings page holds the app's and the
        // Wonky Work sections (suite 04 §4.2).
        MenuSpec.command(
          'shell.settings.openApp',
          id: ShellMenuIds.toolsSettings,
        ),
        MenuSpec.command('shell.help.shortcuts', id: 'tools.shortcuts'),
      ]);

  MenuSubmenu get help => MenuSpec.submenu(ShellMenuIds.help, l10n.menuHelp, [
    MenuSpec.command('shell.help.shortcuts'),
    MenuSpec.separator(),
    // Bugs & improvements (specs/16 §4.1): the report dialog on each kind,
    // then the board. `shell.help.reportBug` and `shell.help.feedback` stay
    // registered as aliases (palette hidden, MCP).
    MenuSpec.command(
      'shell.board.report',
      label: l10n.cmdReportBug,
      args: {'kind': 'bug'},
      id: ShellMenuIds.helpReportBug,
    ),
    MenuSpec.command(
      'shell.board.report',
      label: l10n.boardSuggestImprovement,
      args: {'kind': 'idea'},
      id: ShellMenuIds.helpSuggest,
    ),
    MenuSpec.command('shell.board.open'),
    MenuSpec.command('shell.help.about'),
  ]);
}
