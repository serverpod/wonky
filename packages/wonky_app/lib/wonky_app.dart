/// The Wonky Work app shell (suite 03): client bootstrap, auth, routing,
/// drive, sharing, commands, keymap, undo, collaboration UI, settings.
///
/// Apps describe themselves with a [WonkyAppConfig] and run
/// `WonkyShell.run(config)`.
library;

export 'src/assistant/ai_settings_section.dart';
export 'src/assistant/assistant_adapter.dart';
export 'src/assistant/assistant_api.dart';
export 'src/assistant/assistant_controller.dart';
export 'src/assistant/assistant_markdown.dart';
export 'src/assistant/assistant_models.dart';
export 'src/assistant/assistant_panel.dart';
export 'src/assistant/shell_assistant.dart';
export 'src/auth/auth_controller.dart';
export 'src/auth/auth_repository.dart';
export 'src/bootstrap/app_urls.dart';
export 'src/bootstrap/cross_app.dart';
export 'src/bootstrap/platform.dart';
export 'src/bootstrap/wonky_client.dart';
export 'src/commands/command.dart';
export 'src/commands/command_dispatcher.dart';
export 'src/commands/command_registry.dart';
export 'src/commands/keymap_service.dart';
export 'src/commands/palette/command_palette.dart';
export 'src/commands/palette/quick_switcher.dart';
export 'src/commands/shell_commands/drive_commands.dart' show itemUrl;
export 'src/commands/shell_commands/general_commands.dart'
    show ShellPanels, mcpConnectionJson, mcpUrl;
export 'src/commands/shell_commands/shell_command_base.dart'
    show shellCommand, l10nOf;
export 'src/commands/shortcuts_help.dart';
export 'src/comments/comment_anchor.dart';
export 'src/comments/comment_thread_actions.dart';
export 'src/branding/product_icon.dart';
export 'src/comments/comments_controller.dart';
export 'src/comments/comments_host.dart';
export 'src/comments/comments_panel.dart';
export 'src/comments/comments_undo.dart';
export 'src/comments/pending_comment_ops.dart';
export 'src/config/home_scope.dart';
export 'src/config/wonky_app_config.dart';
export 'src/core/connectivity_service.dart';
export 'src/core/local_database.dart';
export 'src/core/local_store.dart';
export 'src/core/offline_storage.dart';
export 'src/core/preferences_controller.dart';
export 'src/core/stream_supervisor.dart';
export 'src/core/toasts.dart';
export 'src/board/board_commands.dart';
export 'src/board/board_hub.dart';
export 'src/board/board_repository.dart';
export 'src/board/board_undo.dart';
export 'src/board/pages/board_page.dart' show BoardPage;
export 'src/board/pages/board_routes.dart';
export 'src/board/pages/board_trail.dart'
    show BoardTab, BoardTrail, isBoardLocation, boardBackTarget, closeBoard;
export 'src/board/pages/contribute_page.dart' show BoardContributePage;
export 'src/board/pages/post_page.dart';
// The prompt lint lives in wonky_core (shared with the server, T-11).
export 'package:wonky_core/board.dart'
    show lintTaskPrompt, PromptLint, PromptLintKind;
export 'src/board/pages/task_page.dart';
export 'src/data/api.dart';
export 'src/data/cached_drive_repository.dart';
export 'src/data/collab_repositories.dart';
export 'src/data/drive_cache.dart';
export 'src/data/drive_repository.dart';
export 'src/data/file_repository.dart';
export 'src/data/models_ext.dart';
export 'src/data/sharing_repository.dart';
export 'src/data/user_repository.dart';
export 'src/document/document_controller.dart';
export 'src/drive/details_panel.dart' show DriveDetailsPanel;
export 'src/drive/drive_controller.dart';
export 'src/drive/drive_format.dart';
export 'src/drive/drive_location.dart';
export 'src/drive/home_screen.dart' show DriveHomeScreen;
export 'src/drive/home_sidebar.dart';
export 'src/drive/item_actions.dart' show itemMenuEntries;
export 'src/drive/top_bar.dart' show WonkyTopBar;
export 'src/editor/editor_scaffold.dart';
export 'src/l10n/wonky_app_localizations.dart';
export 'src/markdown/markdown_blocks.dart';
export 'src/markdown/markdown_composer.dart';
export 'src/markdown/markdown_inline.dart';
export 'src/markdown/wonky_markdown.dart';
export 'src/mcp_bridge/app_screenshot.dart';
export 'src/mcp_bridge/mcp_bridge_client.dart';
export 'src/mcp_bridge/mcp_bridge_scope.dart' show McpBridgeScope, mcpBridgeOf;
export 'src/mcp_bridge/mcp_control.dart';
export 'src/mcp_bridge/panel_describer.dart';
export 'src/mcp_bridge/shared_ui_tools.dart';
export 'src/mcp_bridge/ui_tool.dart';
export 'src/menus/menu_resolver.dart';
export 'src/menus/shell_menus.dart';
export 'src/presence/presence_session.dart';
export 'src/routing/item_routes.dart';
export 'src/routing/misc_pages.dart';
export 'src/settings/sections/offline_section.dart'
    show clearLocalData, simulateOfflinePref;
export 'src/settings/settings_catalog.dart'
    show SettingsArea, legacySettingsTarget, workSettingsSectionIds;
export 'src/settings/settings_routes.dart'
    show SettingsHandoffPage, settingsRoutes;
export 'src/settings/settings_screen.dart'
    show SettingsGroup, SettingsRow, SettingsScreen;
export 'src/sharing/share_dialog.dart';
export 'src/shell/account_menu.dart';
export 'src/shell/anchored_popover.dart';
export 'src/shell/bug_report.dart';
export 'src/shell/dialogs.dart';
export 'src/shell/form_dialog.dart';
export 'src/shell/page_frame.dart';
export 'src/shell/shell_scope.dart';
export 'src/shell/shell_services.dart';
export 'src/shell/wonky_shell.dart';
export 'src/storage/live_storage_controller.dart';
export 'src/storage/quota_dialog.dart';
export 'src/storage/quota_error_presenter.dart';
export 'src/storage/storage_banner.dart';
export 'src/storage/storage_checks.dart';
export 'src/storage/storage_controller.dart';
export 'src/storage/storage_format.dart';
export 'src/storage/storage_meter.dart';
export 'src/undo/drive_undo.dart';
export 'src/undo/undo_history.dart';
export 'src/undo/undo_service.dart';
export 'src/versions/version_history_screen.dart' show VersionHistoryScreen;
export 'src/versions/version_renderer.dart';
export 'src/versions/versions_list.dart';
export 'src/versions/versions_undo.dart';
export 'src/widgets/image_lightbox.dart';
