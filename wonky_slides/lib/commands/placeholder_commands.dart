import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import 'slides_command.dart';

/// Every menu-, toolbar- and context-menu-bound `slides.*` command that is
/// not built yet (Slides 04 §4, §6, §11 — the canonical id registry);
/// [owner] names the work package (Slides 12 §4) that builds the handler.
///
/// Since SL-23 (M9 exit) every one of them belongs to a feature that is off
/// (`SlidesFeatures`), so none is registered and nothing in the UI or MCP
/// offers them. When a work package turns its feature on, its placeholders
/// are registered **disabled** ("Not available yet") until it adds a real
/// `SlidesCommand` with the same id to its `commands/<area>_commands.dart`
/// (listed in `commands.dart`): `slidesCommands` drops the placeholder of
/// every id that has a real registration, so this list only shrinks by
/// deletion.
List<Command<CommandArgs>> placeholderCommands(ShellServices s) => [
  SlidesCommand.placeholder(
    'slides.file.importSlides',
    label: (l) => l.cmdFileImportSlides,
    icon: LucideIcons.fileInput,
    categoryOf: SlidesCategory.file,
    mutates: true,
    owner: '04 §13.9 (P1)',
  ),
  SlidesCommand.placeholder(
    'slides.present.rehearse',
    label: (l) => l.cmdPresentRehearse,
    icon: LucideIcons.timer,
    categoryOf: SlidesCategory.present,
    owner: 'SL-41 (10, P1)',
  ),
  SlidesCommand.placeholder(
    'slides.present.remote',
    label: (l) => l.cmdPresentRemote,
    icon: LucideIcons.smartphone,
    categoryOf: SlidesCategory.present,
    owner: 'SL-41 (10, P1)',
  ),
  SlidesCommand.placeholder(
    'slides.view.toggleSnapGrid',
    label: (l) => l.cmdViewToggleSnapGrid,
    categoryOf: SlidesCategory.view,
    owner: 'SL-12 (03 §5.3, P2)',
  ),
  SlidesCommand.placeholder(
    'slides.insert.chart',
    label: (l) => l.cmdInsertChart,
    icon: LucideIcons.chartColumn,
    categoryOf: SlidesCategory.insert,
    mutates: true,
    owner: 'SL-32 (08 §11, P1)',
  ),
  SlidesCommand.placeholder(
    'slides.notifications.openSettings',
    label: (l) => l.cmdNotificationsOpenSettings,
    categoryOf: SlidesCategory.tools,
    owner: 'suite 07',
  ),
  SlidesCommand.placeholder(
    'slides.ai.codeWalkthrough',
    label: (l) => l.cmdAiCodeWalkthrough,
    categoryOf: SlidesCategory.ai,
    mutates: true,
    owner: 'SL-43 (11)',
  ),
];
