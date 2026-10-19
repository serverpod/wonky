import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../sheet_editor/sheet_editor_controller.dart';
import '../sheet_editor/write_gate.dart';
import 'protection_dialogs.dart';
import 'protection_layer.dart';

/// One protection of the workbook with its resolved geometry.
@immutable
class ProtectionEntry {
  const ProtectionEntry({
    required this.sheet,
    required this.record,
    required this.rects,
    required this.except,
  });

  final SheetModel sheet;
  final ProtectedRangeRecord record;

  /// Protected rectangles (the whole grid for sheet protections).
  final List<GridRect> rects;

  /// Exception ranges (sheet protections).
  final List<GridRect> except;

  String get id => record.id;
  bool get isSheet => record.rangeJson == null;

  /// Editors (user UUIDs, lower case).
  Set<String> get editors => ProtectionGuard.editorsOf(record);

  /// Whether ([row], [col]) is protected by this entry.
  bool covers(int row, int col) =>
      rects.any((r) => r.contains(row, col)) &&
      !except.any((r) => r.contains(row, col));
}

/// Protected sheets and ranges of an open spreadsheet (07 §10, 03 §16):
/// enforcement of every write of the editor through a write gate, the
/// stripes layer, the "Heads up!" acknowledgement window and the queries
/// of the protection panel. Advisory (suite 06 §3): a modified client can
/// bypass it.
class ProtectionController extends ChangeNotifier {
  ProtectionController._(this.editor) {
    editor.writeGates.add(_gate);
    _layer = ProtectedRangesLayer(this);
    editor.layers.add(_layer);
    editor.model.addListener(_onBatch);
    editor.onDispose(dispose);
  }

  /// The protection controller of [editor] (created on first use).
  static ProtectionController of(SheetEditorController editor) =>
      editor.extension(ProtectionController, () {
        return ProtectionController._(editor);
      });

  final SheetEditorController editor;
  late final ProtectedRangesLayer _layer;

  /// Grace period of "Don't show this again for 5 minutes" (03 §16).
  static const warningSnooze = Duration(minutes: 5);

  DateTime? _warnUntil;
  bool _retryAcknowledged = false;
  bool _showStripes = true;
  bool _disposed = false;

  WorkbookModel get model => editor.model;

  /// The acting user (auth user UUID).
  String get userId => editor.session.userId;

  /// Owners may edit every protected cell.
  bool get isOwner =>
      editor.itemRole == Role.owner || editor.session.role.value == Role.owner;

  /// View › Show › Protected ranges (per user, default on).
  bool get showStripes => _showStripes;
  set showStripes(bool v) {
    if (v == _showStripes) return;
    _showStripes = v;
    editor.contentSignal.fire();
    notifyListeners();
  }

  void _onBatch(WorkbookChangeBatch batch) {
    if (_disposed) return;
    if (batch.events.any(
      (e) => e is RulesChanged && e.kind == RuleKind.protection,
    )) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Queries.

  /// All protections, sheets in tab order.
  List<ProtectionEntry> get entries => [
    for (final s in model.sheets)
      for (final p in s.protections.values) entry(s, p),
  ];

  /// The protections of [sheetId].
  List<ProtectionEntry> entriesOf(String sheetId) {
    final s = model.sheet(sheetId);
    if (s == null) return const [];
    return [for (final p in s.protections.values) entry(s, p)];
  }

  ProtectionEntry entry(SheetModel s, ProtectedRangeRecord p) =>
      ProtectionEntry(
        sheet: s,
        record: p,
        rects: s.ruleRects(RuleKind.protection, p.id),
        except: [
          for (final r in GridRange.parseList(p.exceptRangesJson))
            if (s.resolve(r) case final ResolvedRange rr) rr.rect,
        ],
      );

  /// The protection [id], or null.
  ProtectionEntry? byId(String id) {
    for (final s in model.sheets) {
      final p = s.protections[id];
      if (p != null) return entry(s, p);
    }
    return null;
  }

  /// Whether the user may edit cells of [p] without a warning.
  bool canEdit(ProtectedRangeRecord p) =>
      ProtectionGuard.canEdit(p, userId, isOwner: isOwner);

  /// Whether the user may change or remove [p] (owner, creator, editors).
  bool canManage(ProtectedRangeRecord p) =>
      ProtectionGuard.canManage(p, userId, isOwner: isOwner);

  /// Whether any protection restricts this user (blocks or warns).
  bool get restrictsUser {
    for (final s in model.sheets) {
      for (final p in s.protections.values) {
        // Warning-only protections warn their editors too (07 §10.1).
        if (p.warningOnly || !canEdit(p)) return true;
      }
    }
    return false;
  }

  /// Protections covering a cell (exceptions applied).
  List<ProtectionEntry> at(String sheetId, int row, int col) {
    final s = model.sheet(sheetId);
    if (s == null || s.protections.isEmpty) return const [];
    return [
      for (final id in s.rulesAt(RuleKind.protection, row, col))
        if (s.protections[id] case final ProtectedRangeRecord p)
          if (entry(s, p) case final e when e.covers(row, col)) e,
    ];
  }

  /// Whether the user may edit the cell without being blocked.
  bool canEditCell(String sheetId, int row, int col) => at(
    sheetId,
    row,
    col,
  ).every((e) => canEdit(e.record) || e.record.warningOnly);

  // ---------------------------------------------------------------------------
  // Enforcement.

  /// Checks [op] for the user (07 §10.3). Plans [op] without applying it
  /// when it isn't a structural operation.
  GuardResult check(SheetsOperation op) {
    if (op is AddProtection ||
        op is UpdateProtection ||
        op is DeleteProtection) {
      return GuardResult.allowed;
    }
    if (!restrictsUser) return GuardResult.allowed;
    final writes = WriteIntents.of(
      op,
      model,
      () =>
          SheetsMutationPlanner().plan(op, model, editor.session.planContext()),
    );
    return ProtectionCheck.ofWrites(model, writes, userId, isOwner: isOwner);
  }

  void _gate(CommandContext? ctx, SheetsOperation op) {
    final r = check(op);
    if (r.isAllowed) return;
    if (r.isBlocked) {
      throw WriteRefused(
        GuardResult.blockedMessage,
        code: kProtectedRangeErrorCode,
        show: (c) => showProtectedBlockedDialog(c),
      );
    }
    // Warning-only: agents may write (the result lists warnings, 03 §16);
    // people confirm once, or not at all for 5 minutes after opting out.
    if (ctx == null || ctx.source.isAgent || _retryAcknowledged) return;
    final until = _warnUntil;
    if (until != null && clock.now().isBefore(until)) return;
    throw WriteNeedsConfirmation(
      GuardResult.warningMessage,
      confirm: (c) async {
        final answer = await showProtectedWarningDialog(c);
        if (answer == null) return false;
        if (answer) _warnUntil = clock.now().add(warningSnooze);
        _retryAcknowledged = true;
        return true;
      },
      retryDone: () => _retryAcknowledged = false,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    editor.writeGates.remove(_gate);
    editor.model.removeListener(_onBatch);
    super.dispose();
  }
}
