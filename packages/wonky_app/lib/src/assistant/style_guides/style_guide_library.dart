import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';

import '../../data/api.dart' show errorMessage;
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/shell_services.dart';
import '../../undo/undo_service.dart';
import '../assistant_api.dart';
import '../shell_assistant.dart';

/// The ref of "no style guide" in pickers.
const noStyleGuideRef = '';

/// The style guide library of the assistant (suite 10 §7) for the dialog
/// and the apps' commands: loads the user's guides (and a document's
/// choice), and changes them as undoable steps: saving and deleting guides
/// and the organization default on the shell stack, a document's choice on
/// [documentStack].
class StyleGuideLibraryController extends ChangeNotifier {
  StyleGuideLibraryController({
    required this.services,
    required this.api,
    this.itemUuid,
    this.documentStack,
  }) {
    changes.addListener(_onExternalChange);
  }

  final ShellServices services;
  final AssistantApi api;

  /// The document whose guide is chosen (null = library only).
  final UuidValue? itemUuid;

  /// The undo stack of the document's choice (default: the shell stack).
  final UndoStackKey? documentStack;

  /// Bumped when an undo or redo changed the library, so open dialogs
  /// reload.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  StyleGuideLibrary? library;
  bool loading = false;
  String? error;
  bool _disposed = false;

  WonkyAppLocalizations get _l =>
      services.l10n ?? lookupWonkyAppLocalizations(const Locale('en'));

  List<StyleGuideView> get guides => library?.guides ?? const [];

  StyleGuideView? byRef(String? ref) {
    if (ref == null) return null;
    for (final g in guides) {
      if (g.ref == ref) return g;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onExternalChange() => unawaited(load());

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      library = await api.styleGuides(itemUuid: itemUuid);
    } on Object catch (e) {
      error = errorMessage(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  static StyleGuideInput inputOf(StyleGuideView g, {UuidValue? uuid}) =>
      StyleGuideInput(
        uuid: uuid ?? uuidOf(g.ref),
        name: g.name,
        description: g.description,
        markdown: g.markdown,
        shareWithOrg: g.sharedWithOrg,
      );

  static UuidValue? uuidOf(String ref) => ref.startsWith('custom:')
      ? UuidValue.withValidation(ref.substring(7))
      : null;

  void _push(String label, StyleGuideUndoEntry entry, {UndoStackKey? stack}) {
    final undo = services.undo;
    if (undo.isApplying) return;
    undo.push(
      UndoStep(
        id: 'style-guide-${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        entries: [entry],
      ),
      stack: stack ?? UndoStackKey.shell,
    );
  }

  /// Creates or updates a guide; returns it.
  Future<StyleGuideView> save(StyleGuideInput input) async {
    final before = input.uuid == null ? null : byRef('custom:${input.uuid}');
    final saved = await api.saveStyleGuide(input);
    _push(
      _l.undoSaveStyleGuide,
      StyleGuideUndoEntry(StyleGuideUndoOp.save, {
        'before': before == null ? null : inputOf(before).toJson(),
        'after': inputOf(saved).toJson(),
      }),
    );
    await load();
    return saved;
  }

  Future<void> delete(StyleGuideView g) async {
    final uuid = uuidOf(g.ref);
    if (uuid == null) return;
    await api.deleteStyleGuide(uuid);
    _push(
      _l.undoDeleteStyleGuide,
      StyleGuideUndoEntry(StyleGuideUndoOp.delete, {
        'before': inputOf(g).toJson(),
      }),
    );
    await load();
  }

  /// Sets the organization default ([ref] null clears it).
  Future<void> setOrgDefault(String? ref) async {
    final before = library?.orgDefaultRef;
    library = await api.setOrgStyleGuide(ref);
    _push(
      _l.undoSetOrgStyleGuide,
      StyleGuideUndoEntry(StyleGuideUndoOp.orgDefault, {
        'before': before,
        'after': ref,
      }),
    );
    await load();
  }

  /// Sets the document's guide ([ref] null clears it).
  Future<void> setDocument(String? ref) async {
    final item = itemUuid;
    if (item == null) return;
    final before = library?.documentRef;
    if (before == ref) return;
    library = await api.setDocumentStyleGuide(item, ref);
    _notify();
    _push(
      _l.undoSetDocumentStyleGuide,
      StyleGuideUndoEntry(StyleGuideUndoOp.document, {
        'item': item.uuid,
        'before': before,
        'after': ref,
      }),
      stack: documentStack,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    changes.removeListener(_onExternalChange);
    super.dispose();
  }
}

enum StyleGuideUndoOp {
  /// `{before: input?, after: input}` (before null = created).
  save,

  /// `{before: input}`.
  delete,

  /// `{before: ref?, after: ref?}`.
  orgDefault,

  /// `{item, before: ref?, after: ref?}`.
  document,
}

class StyleGuideUndoEntry extends UndoEntry {
  const StyleGuideUndoEntry(this.op, this.data);

  final StyleGuideUndoOp op;
  final Map<String, Object?> data;

  static const domainName = 'assistant.styleGuides';

  @override
  String get domain => domainName;

  @override
  UndoEntry? rebase(RemoteChange change) => this;
}

/// Applies [StyleGuideUndoEntry]s through the assistant API; a failure
/// (the guide is gone, no access) is an [UndoConflict].
class StyleGuideUndoHandler extends UndoHandler<StyleGuideUndoEntry> {
  StyleGuideUndoHandler(this.services);

  final ShellServices services;

  @override
  String get domain => StyleGuideUndoEntry.domainName;

  @override
  Future<StyleGuideUndoEntry> undo(StyleGuideUndoEntry e) =>
      _apply(e, undo: true);

  @override
  Future<StyleGuideUndoEntry> redo(StyleGuideUndoEntry e) =>
      _apply(e, undo: false);

  Future<StyleGuideUndoEntry> _apply(
    StyleGuideUndoEntry e, {
    required bool undo,
  }) async {
    final api = ShellAssistant.of(services)?.api;
    if (api == null) throw const UndoConflict('The assistant is not available');
    StyleGuideInput input(Object? json) =>
        StyleGuideInput.fromJson((json! as Map).cast<String, dynamic>());
    final side = undo ? 'before' : 'after';
    try {
      switch (e.op) {
        case StyleGuideUndoOp.save:
          final v = e.data[side];
          if (v == null) {
            final after = input(e.data['after']);
            await api.deleteStyleGuide(after.uuid!);
          } else {
            await api.saveStyleGuide(input(v));
          }
        case StyleGuideUndoOp.delete:
          final before = input(e.data['before']);
          undo
              ? await api.saveStyleGuide(before)
              : await api.deleteStyleGuide(before.uuid!);
        case StyleGuideUndoOp.orgDefault:
          await api.setOrgStyleGuide(e.data[side] as String?);
        case StyleGuideUndoOp.document:
          await api.setDocumentStyleGuide(
            UuidValue.fromString(e.data['item']! as String),
            e.data[side] as String?,
          );
      }
    } on WonkyException catch (x) {
      throw UndoConflict(x.message);
    } finally {
      StyleGuideLibraryController.changes.value++;
    }
    return e;
  }
}
