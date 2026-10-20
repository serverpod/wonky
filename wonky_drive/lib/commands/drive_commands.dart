import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';

import '../features/settings/drive_settings_keys.dart';
import '../features/analytics/analytics_controller.dart';
import '../features/storage/storage_controller.dart';
import '../l10n/drive_l10n.dart';

/// Drive's view, settings and Storage page commands (Drive 04 §9):
/// `drive.view.setLayout/sort/toggleFoldersOnTop` (the shown list),
/// `drive.prefs.set` (Drive settings), `drive.storage.show` and (admins)
/// `drive.analytics.show`. View state
/// and settings are not undoable (suite 08 §2).
List<Command<CommandArgs>> driveCommands(ShellServices s) {
  DriveController? view() => s.driveView.value;

  CallbackCommand cmd(
    String id, {
    required String Function(DriveLocalizations l) title,
    required String Function(DriveLocalizations l) category,
    required Future<CommandResult> Function(CommandContext, JsonArgs) run,
    IconData? icon,
    JsonSchema args = JsonSchema.empty,
    bool Function(CommandContext, JsonArgs)? enabled,
    bool? Function(CommandContext, JsonArgs)? checked,
    bool palette = true,
  }) => CallbackCommand(
    id: id,
    title: (c) => title(driveL10n(c)),
    category: (c) => category(driveL10n(c)),
    run: run,
    icon: icon,
    argsSchema: args,
    enabled: enabled,
    checked: checked,
    showInPalette: palette,
  );

  final sortFields = [for (final f in DriveSettings.sortFields) f.name];

  return [
    cmd(
      'drive.view.setLayout',
      title: (l) => l.cmdViewSetLayout,
      category: (l) => l.categoryView,
      icon: LucideIcons.layoutGrid,
      args: const JsonSchema.object(
        properties: {
          'layout': JsonSchema.string(
            enumValues: ['grid', 'list'],
            description: 'Default: switch between grid and list.',
          ),
        },
      ),
      enabled: (ctx, a) => view() != null,
      run: (ctx, a) async {
        final c = view();
        if (c == null) return const CommandResult.cancelled();
        final layout = switch (a.string('layout')) {
          'grid' => DriveLayout.grid,
          'list' => DriveLayout.list,
          _ =>
            c.layout == DriveLayout.list ? DriveLayout.grid : DriveLayout.list,
        };
        c.setLayout(layout);
        return CommandResult.ok({'layout': layout.name});
      },
    ),
    cmd(
      'drive.view.sort',
      title: (l) => l.cmdViewSort,
      category: (l) => l.categoryView,
      icon: LucideIcons.arrowDownUp,
      args: JsonSchema.object(
        properties: {
          'field': JsonSchema.string(enumValues: sortFields),
          'descending': const JsonSchema.boolean(
            description:
                'Default: descending except for names; the current field '
                'again flips the order.',
          ),
        },
        required: const ['field'],
      ),
      enabled: (ctx, a) => view() != null,
      run: (ctx, a) async {
        final c = view();
        if (c == null) return const CommandResult.cancelled();
        final field = DriveSortField.values.asNameMap()[a.string('field')];
        if (field == null || !DriveSettings.sortFields.contains(field)) {
          return CommandResult.failed('Unknown sort field');
        }
        c.setSort(field, descending: a.boolean('descending'));
        return CommandResult.ok({
          'field': c.sortField.name,
          'descending': c.descending,
        });
      },
    ),
    cmd(
      'drive.view.toggleFoldersOnTop',
      title: (l) => l.cmdViewToggleFoldersOnTop,
      category: (l) => l.categoryView,
      icon: LucideIcons.folderUp,
      enabled: (ctx, a) => view() != null,
      checked: (ctx, a) => view()?.foldersFirst,
      run: (ctx, a) async {
        final c = view();
        if (c == null) return const CommandResult.cancelled();
        c.setFoldersFirst(!c.foldersFirst);
        return CommandResult.ok({'foldersOnTop': c.foldersFirst});
      },
    ),
    cmd(
      'drive.prefs.set',
      title: (l) => l.cmdDrivePrefsSet,
      category: (l) => l.categoryView,
      icon: LucideIcons.slidersHorizontal,
      palette: false,
      args: JsonSchema.object(
        properties: {
          'key': JsonSchema.string(
            enumValues: DriveSettings.validators.keys.toList(),
          ),
          'value': const JsonSchema.any(),
        },
        required: const ['key', 'value'],
      ),
      run: (ctx, a) async {
        final key = a.requireString('key');
        final value = a.values['value'];
        final valid = DriveSettings.validators[key];
        if (valid == null) {
          return CommandResult.failed('Unknown setting "$key"');
        }
        if (!valid(value)) {
          return CommandResult.failed('Invalid value for "$key"');
        }
        await setDriveSetting(s, key, value);
        return CommandResult.ok({'key': key, 'value': value});
      },
    ),
    cmd(
      'drive.storage.show',
      title: (l) => l.cmdStorageShow,
      category: (l) => l.categoryStorage,
      icon: LucideIcons.chartPie,
      args: JsonSchema.object(
        properties: {
          'filter': JsonSchema.string(
            enumValues: [for (final f in StorageFilter.values) f.name],
            description:
                'Rows of the table: a type, the trash, large files (1 MB '
                'or more) or items not opened in 6 months. Default: all.',
          ),
        },
      ),
      run: (ctx, a) async {
        final name = a.string('filter');
        final filter = StorageFilter.parse(name);
        if (name != null && filter.name != name) {
          return CommandResult.failed('Unknown filter "$name"');
        }
        s.router.go(storagePath(filter));
        return CommandResult.ok({'filter': filter.name});
      },
    ),
    cmd(
      'drive.analytics.show',
      title: (l) => l.cmdAnalyticsShow,
      category: (l) => l.categoryAnalytics,
      icon: LucideIcons.chartLine,
      args: JsonSchema.object(
        properties: {
          'days': JsonSchema.integer(
            minimum: analyticsPeriods.first,
            maximum: analyticsPeriods.last,
            description:
                'The period in days, ending today (UTC): one of '
                '${analyticsPeriods.join(', ')}. Default: '
                '$analyticsDefaultDays.',
          ),
          'includeAdmins': const JsonSchema.boolean(
            description: 'Count admins too. Default: false.',
          ),
        },
      ),
      // Admins only (specs/19 §1): the board's admin rule.
      enabled: (ctx, a) => BoardHub.of(s).isAdmin,
      run: (ctx, a) async {
        final days = a.integer('days') ?? analyticsDefaultDays;
        if (!analyticsPeriods.contains(days)) {
          return CommandResult.failed('Unknown period $days');
        }
        final admins = a.boolean('includeAdmins') ?? false;
        s.router.go(analyticsPath(days: days, admins: admins));
        return CommandResult.ok({'days': days, 'includeAdmins': admins});
      },
    ),
  ];
}

/// Saves one Drive setting; a new list default replaces this device's
/// remembered layout/sort and applies to the shown list at once.
Future<void> setDriveSetting(ShellServices s, String key, Object? value) async {
  await s.prefs.setDriveDefault(key, value);
  for (final k in DriveSettings.deviceOverrides[key] ?? const <String>[]) {
    await s.prefs.setDevice(k, null);
  }
  s.driveView.value?.applyViewPrefs();
}
