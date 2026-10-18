import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_revlog/codec.dart' show ChangeSet;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sync_models/ids.dart' show UuidV7IdGenerator;

import 'change_labels.dart';
import '../revlog/sheets_rev_log.dart';
import 'version_snapshots.dart';

/// *Make a copy* of a version (Sheets 10 §5.4): the snapshot's rows get new
/// ids through the core `SpaceCopier` (formulas, ranges, objects remapped)
/// and become the creation ops of a new spreadsheet created on this device
/// (RevLog spec 06 §7.1: `initialize: false`), which works offline too.
/// Returns the new item uuid and the ids of its sheets, rows and columns by
/// the version's ids (for comment anchors, see [copyVersionExtras]).
Future<(UuidValue, Map<String, String>)?> copyVersionToNewSpreadsheet(
  ShellServices services, {
  required SnapshotRows rows,
  required String sourceSpaceId,
  required String name,
}) async {
  final client = await SheetsRevLog.ready(services);
  if (client == null) throw StateError('Sheets data is not ready.');
  final file = UuidValue.fromString(const UuidV7IdGenerator().newId());
  final copy = SpaceCopier.copy(
    rows,
    sourceSpaceId: sourceSpaceId,
    targetSpaceId: file.uuid,
    ids: const UuidV7IdGenerator(),
    userId: services.me?.uuid.uuid ?? '',
    now: clock.now().toUtc(),
    title: name,
  );
  final changes = [
    for (final (t, c) in copy.rows)
      RowChange.insert(t, c[Cols.id].toString(), c),
  ];
  await client.createLocal(
    file.uuid,
    ChangeSet(
      clientOpId: const UuidV7IdGenerator().newId(),
      baseRevision: 0,
      changes: changes,
      label: SheetsChangeLabels.makeCopy,
      offline: !services.connectivity.online,
    ),
  );
  try {
    await services.drive.registerSpreadsheet(spaceUuid: file, name: name);
  } catch (e) {
    debugPrint('Creating copy $file failed: $e');
    if (!isOfflineError(e)) rethrow;
  }
  services.refreshDrive();
  unawaited(client.syncOutboxes());
  final space = file;
  const anchorTables = {
    SheetsTables.sheet,
    SheetsTables.sheetRow,
    SheetsTables.sheetColumn,
  };
  return (
    space,
    {
      for (final (t, c) in rows)
        if (anchorTables.contains(t))
          c[Cols.id].toString(): ?copy.idMap[c[Cols.id].toString()],
    },
  );
}

/// Overrides the server call of [copyVersionExtras] (tests).
@visibleForTesting
Future<void> Function(
  UuidValue source,
  UuidValue target,
  String idMapJson,
  bool comments,
  bool sharing,
)?
copyVersionExtrasOverride;

/// *Copy comments* / *Share with the same people* of a version copy
/// (Sheets 10 §5.4): the server copies the source's threads with their
/// anchors remapped through [idMap] and its sharing. Needs a connection.
Future<void> copyVersionExtras(
  ShellServices services, {
  required UuidValue source,
  required UuidValue target,
  required Map<String, String> idMap,
  required bool comments,
  required bool sharing,
}) async {
  if (!comments && !sharing) return;
  final json = jsonEncode(idMap);
  final override = copyVersionExtrasOverride;
  if (override != null) {
    return override(source, target, json, comments, sharing);
  }
  final client = services.client;
  if (client == null || Api.simulatedOffline) {
    throw const OfflineException('offline');
  }
  await client.sheetsVersion.copyExtras(
    source,
    target,
    json,
    comments,
    sharing,
  );
}
